-- 狀態管理模組
-- 負責集中狀態管理、記憶體安全和資料持久化

local M = {}

-- 使用弱引用表避免記憶體洩漏
local state = setmetatable({}, {__mode = "v"})

-- 狀態訂閱者（弱引用表）
local subscribers = setmetatable({}, {__mode = "v"})

-- 記憶體池管理
local memory_pools = {
    segments = setmetatable({}, {__mode = "v"}),
    history = setmetatable({}, {__mode = "v"}),
    temp_data = setmetatable({}, {__mode = "v"})
}

-- 清理定時器
local cleanup_timers = {}

-- 記憶體監控
local memory_stats = {
    allocations = 0,
    deallocations = 0,
    max_memory_usage = 0,
    last_gc_time = 0
}

-- 預設狀態
local DEFAULT_STATE = {
    segments = nil,
    current_index = 1,
    last_operation = nil,
    operation_history = {},
    session_stats = {
        operations_count = 0,
        bytes_processed = 0,
        errors_count = 0,
        start_time = vim.uv.hrtime()
    },
    last_cleanup = 0
}

-- 初始化狀態
function M.init()
    state = vim.deepcopy(DEFAULT_STATE)
    
    -- 設定自動清理
    M._setup_auto_cleanup()
    
    -- 設定記憶體管理
    M.setup_memory_management()
    
    return true
end

-- 獲取狀態
function M.get(key)
    if key then
        return state[key]
    end
    return vim.deepcopy(state)
end

-- 更新狀態
function M.set(key, value)
    local old_value = state[key]
    state[key] = value
    
    -- 通知訂閱者
    M._notify_subscribers(key, old_value, value)
    
    return true
end

-- 狀態訂閱系統
function M.subscribe(key, callback)
    if not subscribers[key] then
        subscribers[key] = {}
    end
    
    table.insert(subscribers[key], callback)
    
    -- 返回取消訂閱函數
    return function()
        M.unsubscribe(key, callback)
    end
end

-- 取消訂閱
function M.unsubscribe(key, callback)
    local key_subscribers = subscribers[key]
    if not key_subscribers then return false end
    
    for i, sub in ipairs(key_subscribers) do
        if sub == callback then
            table.remove(key_subscribers, i)
            return true
        end
    end
    
    return false
end

-- 通知訂閱者
function M._notify_subscribers(key, old_value, new_value)
    local key_subscribers = subscribers[key] or {}
    for _, callback in ipairs(key_subscribers) do
        local success, err = pcall(callback, old_value, new_value, key)
        if not success then
            vim.notify(string.format("State subscriber error: %s", err), vim.log.levels.ERROR)
        end
    end
end

-- 記錄操作歷史
function M.record_operation(operation, result, metadata)
    metadata = metadata or {}
    
    local record = {
        timestamp = os.time(),
        operation = operation,
        result = result,
        metadata = metadata,
        session_time = (vim.uv.hrtime() - state.session_stats.start_time) / 1e9
    }
    
    -- 添加到歷史記錄
    state.operation_history = state.operation_history or {}
    table.insert(state.operation_history, record)
    
    -- 限制歷史記錄數量（記憶體管理）
    if #state.operation_history > 100 then
        -- 移除最舊的記錄
        table.remove(state.operation_history, 1)
    end
    
    -- 更新統計資訊
    state.session_stats.operations_count = state.session_stats.operations_count + 1
    
    if metadata.bytes_processed then
        state.session_stats.bytes_processed = state.session_stats.bytes_processed + metadata.bytes_processed
    end
    
    if not result then
        state.session_stats.errors_count = state.session_stats.errors_count + 1
    end
    
    -- 記錄最後操作
    state.last_operation = {
        name = operation,
        timestamp = record.timestamp,
        result = result
    }
    
    -- 通知訂閱者
    M._notify_subscribers("operation_history", nil, record)
    M._notify_subscribers("session_stats", nil, state.session_stats)
end

-- 分段管理
function M.set_segments(segments)
    -- 安全清理舊分段
    if state.segments then
        M._secure_clear_segments()
    end
    
    state.segments = segments
    state.current_index = 1
    
    M._notify_subscribers("segments", nil, segments)
    
    -- 設定分段過期清理
    if segments and #segments > 0 then
        M._schedule_segment_cleanup(300) -- 5分鐘後清理
    end
end

-- 獲取當前分段
function M.get_current_segment()
    if not state.segments or state.current_index > #state.segments then
        return nil
    end
    
    return state.segments[state.current_index]
end

-- 移動到下一個分段
function M.next_segment()
    if not state.segments then
        return false, "No segments available"
    end
    
    if state.current_index >= #state.segments then
        return false, "No more segments"
    end
    
    state.current_index = state.current_index + 1
    M._notify_subscribers("current_index", state.current_index - 1, state.current_index)
    
    return true, state.current_index
end

-- 重置分段狀態
function M.reset_segments()
    M._secure_clear_segments()
    state.segments = nil
    state.current_index = 1
    
    M._notify_subscribers("segments", state.segments, nil)
end

-- 安全清理分段（防止敏感資料洩漏）
function M._secure_clear_segments()
    if state.segments then
        for i = 1, #state.segments do
            -- 覆寫敏感資料而非僅設為 nil
            if type(state.segments[i]) == "string" then
                state.segments[i] = string.rep('\0', math.min(#state.segments[i], 1000))
            end
            state.segments[i] = nil
        end
    end
end

-- 獲取統計資訊
function M.get_stats()
    local current_time = vim.uv.hrtime()
    local session_duration = (current_time - state.session_stats.start_time) / 1e9
    
    return {
        operations_count = state.session_stats.operations_count,
        bytes_processed = state.session_stats.bytes_processed,
        errors_count = state.session_stats.errors_count,
        session_duration = session_duration,
        error_rate = state.session_stats.operations_count > 0 and 
                    (state.session_stats.errors_count / state.session_stats.operations_count * 100) or 0,
        avg_bytes_per_operation = state.session_stats.operations_count > 0 and
                                (state.session_stats.bytes_processed / state.session_stats.operations_count) or 0
    }
end

-- 獲取最近操作歷史
function M.get_recent_operations(count)
    count = count or 10
    local history = state.operation_history or {}
    local start_index = math.max(1, #history - count + 1)
    
    local recent = {}
    for i = start_index, #history do
        table.insert(recent, history[i])
    end
    
    return recent
end

-- 自動清理設置
function M._setup_auto_cleanup()
    -- 清理過期分段（每5分鐘）
    cleanup_timers.segments = vim.fn.timer_start(300000, function()
        M._cleanup_expired_segments()
    end, {['repeat'] = -1})
    
    -- 清理操作歷史（每小時）
    cleanup_timers.history = vim.fn.timer_start(3600000, function()
        M._cleanup_old_history()
    end, {['repeat'] = -1})
    
    -- 記憶體強制清理（每10分鐘）
    cleanup_timers.memory = vim.fn.timer_start(600000, function()
        collectgarbage("collect")
    end, {['repeat'] = -1})
end

-- 清理過期分段
function M._cleanup_expired_segments()
    local current_time = os.time()
    
    -- 如果分段超過5分鐘未使用，清理它們
    if state.segments and state.last_cleanup > 0 and (current_time - state.last_cleanup) > 300 then
        M.reset_segments()
        state.last_cleanup = current_time
        
        if require('utils.clipboard.config').get('performance_monitoring') then
            vim.notify("🧹 剪貼板敏感資料已安全清理", vim.log.levels.DEBUG)
        end
    end
end

-- 清理舊歷史記錄
function M._cleanup_old_history()
    if not state.operation_history then return end
    
    local current_time = os.time()
    local max_age = 3600 -- 1小時
    
    -- 移除超過1小時的記錄
    local new_history = {}
    for _, record in ipairs(state.operation_history) do
        if (current_time - record.timestamp) <= max_age then
            table.insert(new_history, record)
        end
    end
    
    state.operation_history = new_history
end

-- 排程分段清理
function M._schedule_segment_cleanup(delay_seconds)
    if cleanup_timers.pending_segment then
        vim.fn.timer_stop(cleanup_timers.pending_segment)
    end
    
    cleanup_timers.pending_segment = vim.fn.timer_start(delay_seconds * 1000, function()
        M._cleanup_expired_segments()
        cleanup_timers.pending_segment = nil
    end)
end

-- 重置狀態
function M.reset()
    M._secure_clear_segments()
    
    -- 停止所有定時器
    for _, timer_id in pairs(cleanup_timers) do
        if timer_id then
            vim.fn.timer_stop(timer_id)
        end
    end
    
    -- 重置狀態
    state = vim.deepcopy(DEFAULT_STATE)
    subscribers = {}
    cleanup_timers = {}
    
    -- 重新初始化
    M._setup_auto_cleanup()
    
    return true
end

-- 狀態持久化（可選）
function M.export_state()
    -- 導出非敏感狀態（排除 segments）
    return {
        operation_history = state.operation_history,
        session_stats = state.session_stats,
        last_operation = state.last_operation
    }
end

-- 導入狀態
function M.import_state(exported_state)
    if exported_state.operation_history then
        state.operation_history = exported_state.operation_history
    end
    
    if exported_state.session_stats then
        state.session_stats = exported_state.session_stats
    end
    
    if exported_state.last_operation then
        state.last_operation = exported_state.last_operation
    end
    
    return true
end

-- 記憶體安全管理功能

-- 分配記憶體池物件
function M.allocate_from_pool(pool_name, data)
    if not memory_pools[pool_name] then
        memory_pools[pool_name] = setmetatable({}, {__mode = "v"})
    end
    
    local pool = memory_pools[pool_name]
    local id = tostring(vim.uv.hrtime())
    pool[id] = data
    
    memory_stats.allocations = memory_stats.allocations + 1
    
    -- 監控記憶體使用
    local current_memory = collectgarbage("count")
    if current_memory > memory_stats.max_memory_usage then
        memory_stats.max_memory_usage = current_memory
    end
    
    return id
end

-- 從記憶體池釋放物件
function M.deallocate_from_pool(pool_name, id)
    local pool = memory_pools[pool_name]
    if pool and pool[id] then
        pool[id] = nil
        memory_stats.deallocations = memory_stats.deallocations + 1
        return true
    end
    return false
end

-- 清理記憶體池
function M.clear_memory_pool(pool_name)
    if memory_pools[pool_name] then
        memory_pools[pool_name] = setmetatable({}, {__mode = "v"})
        collectgarbage("collect")
        return true
    end
    return false
end

-- 獲取記憶體統計
function M.get_memory_stats()
    local current_time = vim.uv.hrtime()
    local current_memory = collectgarbage("count")
    
    return {
        current_usage_kb = current_memory,
        max_usage_kb = memory_stats.max_memory_usage,
        allocations = memory_stats.allocations,
        deallocations = memory_stats.deallocations,
        pool_sizes = {
            segments = #vim.tbl_keys(memory_pools.segments or {}),
            history = #vim.tbl_keys(memory_pools.history or {}),
            temp_data = #vim.tbl_keys(memory_pools.temp_data or {})
        },
        last_gc_time = memory_stats.last_gc_time,
        time_since_last_gc = (current_time - memory_stats.last_gc_time) / 1e6
    }
end

-- 強制記憶體回收和清理
function M.force_memory_cleanup()
    local before_memory = collectgarbage("count")
    
    -- 清理所有記憶體池
    for pool_name, _ in pairs(memory_pools) do
        M.clear_memory_pool(pool_name)
    end
    
    -- 清理過期歷史記錄
    M._cleanup_old_history()
    
    -- 執行垃圾回收
    collectgarbage("collect")
    
    local after_memory = collectgarbage("count")
    local freed_memory = before_memory - after_memory
    
    memory_stats.last_gc_time = vim.uv.hrtime()
    
    if require('utils.clipboard.config').get('performance_monitoring') then
        vim.notify(string.format("🧹 記憶體清理完成：釋放 %.1f KB", freed_memory), vim.log.levels.DEBUG)
    end
    
    return {
        before = before_memory,
        after = after_memory,
        freed = freed_memory
    }
end

-- 記憶體洩漏檢測
function M.detect_memory_leaks()
    local leaks = {}
    local threshold = 1000 -- 1MB
    
    local current_memory = collectgarbage("count")
    
    -- 檢查記憶體池大小
    for pool_name, pool in pairs(memory_pools) do
        local pool_size = #vim.tbl_keys(pool)
        if pool_size > 100 then  -- 超過100個物件
            table.insert(leaks, {
                type = "memory_pool",
                pool = pool_name,
                size = pool_size,
                severity = "warning"
            })
        end
    end
    
    -- 檢查總記憶體使用
    if current_memory > threshold then
        table.insert(leaks, {
            type = "high_memory_usage",
            usage = current_memory,
            threshold = threshold,
            severity = "critical"
        })
    end
    
    -- 檢查長期未清理的分段
    if state.segments and state.last_cleanup > 0 then
        local age = os.time() - state.last_cleanup
        if age > 600 then  -- 10分鐘
            table.insert(leaks, {
                type = "stale_segments",
                age = age,
                severity = "warning"
            })
        end
    end
    
    return leaks
end

-- 自動記憶體管理
function M.setup_memory_management()
    -- 設定自動記憶體清理（每30秒）
    cleanup_timers.memory_management = vim.fn.timer_start(30000, function()
        local leaks = M.detect_memory_leaks()
        
        if #leaks > 0 then
            for _, leak in ipairs(leaks) do
                if leak.severity == "critical" then
                    M.force_memory_cleanup()
                    break
                end
            end
        end
        
        -- 定期垃圾回收
        if (vim.uv.hrtime() - memory_stats.last_gc_time) > 300000 then -- 5分鐘
            collectgarbage("collect")
            memory_stats.last_gc_time = vim.uv.hrtime()
        end
    end, {['repeat'] = -1})
end

-- VimLeavePre 清理回調（增強版）
function M.cleanup_on_exit()
    M._secure_clear_segments()
    
    -- 清理所有記憶體池
    for pool_name, _ in pairs(memory_pools) do
        M.clear_memory_pool(pool_name)
    end
    
    -- 停止所有定時器
    for _, timer_id in pairs(cleanup_timers) do
        if timer_id then
            vim.fn.timer_stop(timer_id)
        end
    end
    
    -- 強制垃圾回收
    collectgarbage("collect")
    
    if require('utils.clipboard.config').get('performance_monitoring') then
        vim.notify("🔒 剪貼板模組已安全關閉", vim.log.levels.DEBUG)
    end
end

-- 初始化模組
M.init()

return M