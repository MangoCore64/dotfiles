-- 工具模組 
-- 負責輔助功能、檔案操作和通用工具函數

local M = {}

-- 安全的檔案路徑驗證
function M.validate_file_path(path)
    -- 正規化路徑
    local normalized = vim.fn.resolve(vim.fn.fnamemodify(path, ":p"))
    
    -- 檢查目錄遍歷攻擊
    if normalized:match("%.%./") or normalized:match("\\%.%./") then
        return false, "路徑遍歷攻擊檢測"
    end
    
    -- 確保路徑在允許的目錄內
    local allowed_prefixes = {
        "/tmp/",
        os.getenv("XDG_RUNTIME_DIR") or "/tmp/",
        os.getenv("TMPDIR") or "/tmp/"
    }
    
    local path_allowed = false
    for _, prefix in ipairs(allowed_prefixes) do
        if normalized:sub(1, #prefix) == prefix then
            path_allowed = true
            break
        end
    end
    
    if not path_allowed then
        return false, "路徑不在允許的目錄範圍內"
    end
    
    return true, nil
end

-- 安全的暫存檔案創建
function M.create_secure_temp_file(prefix, suffix)
    prefix = prefix or "nvim_clipboard_"
    suffix = suffix or ".txt"
    
    -- 使用更安全的隨機性
    local random_part = tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
    
    -- 嘗試獲取更好的隨機性（使用現代異步API）
    if vim.system then
        local result = vim.system({"uuidgen"}, {timeout = 1000})
        if result and result.code == 0 and result.stdout then
            local uuid = result.stdout:gsub("%s+", "")
            if #uuid > 10 then
                random_part = uuid:sub(1, 32)
            end
        else
            -- 回退到Python UUID
            local py_result = vim.system({"python3", "-c", "import uuid; print(uuid.uuid4())"}, {timeout = 1000})
            if py_result and py_result.code == 0 and py_result.stdout then
                local uuid = py_result.stdout:gsub("%s+", "")
                if #uuid > 10 then
                    random_part = uuid:sub(1, 32)
                end
            end
        end
    end
    
    local temp_dir = os.getenv("XDG_RUNTIME_DIR") or os.getenv("TMPDIR") or "/tmp"
    local temp_file = temp_dir .. "/" .. prefix .. random_part .. suffix
    
    -- 驗證路徑安全性
    local valid, error_msg = M.validate_file_path(temp_file)
    if not valid then
        return nil, error_msg
    end
    
    -- 檢查檔案是否已存在（防止競態條件）
    local file_handle = io.open(temp_file, "r")
    if file_handle then
        file_handle:close()
        return nil, "檔案已存在，可能的競態條件攻擊"
    end
    
    return temp_file, nil
end

-- 安全的字串轉義
function M.escape_lua_pattern(str)
    -- 轉義所有 Lua pattern 特殊字符
    return str:gsub("([%^%$%(%)%%%%%.%[%]%*%+%-%?%{%}])", "%%%1")
end

-- 格式化位元組大小
function M.format_bytes(bytes)
    if bytes < 1024 then
        return string.format("%d B", bytes)
    elseif bytes < 1024 * 1024 then
        return string.format("%.1f KB", bytes / 1024)
    elseif bytes < 1024 * 1024 * 1024 then
        return string.format("%.1f MB", bytes / (1024 * 1024))
    else
        return string.format("%.1f GB", bytes / (1024 * 1024 * 1024))
    end
end

-- 格式化時間持續
function M.format_duration(seconds)
    if seconds < 60 then
        return string.format("%.1fs", seconds)
    elseif seconds < 3600 then
        local minutes = math.floor(seconds / 60)
        local remaining_seconds = seconds % 60
        return string.format("%dm %.1fs", minutes, remaining_seconds)
    else
        local hours = math.floor(seconds / 3600)
        local remaining_minutes = math.floor((seconds % 3600) / 60)
        return string.format("%dh %dm", hours, remaining_minutes)
    end
end

-- 截斷長字串
function M.truncate_string(str, max_length, suffix)
    max_length = max_length or 100
    suffix = suffix or "..."
    
    if #str <= max_length then
        return str
    end
    
    return str:sub(1, max_length - #suffix) .. suffix
end

-- 安全的深拷貝（避免循環引用）
function M.deep_copy(original, seen)
    seen = seen or {}
    
    if type(original) ~= 'table' then
        return original
    end
    
    if seen[original] then
        return seen[original]
    end
    
    local copy = {}
    seen[original] = copy
    
    for key, value in pairs(original) do
        copy[M.deep_copy(key, seen)] = M.deep_copy(value, seen)
    end
    
    return setmetatable(copy, getmetatable(original))
end

-- 合併表（深度合併）
function M.merge_tables(target, source, seen)
    seen = seen or {}
    
    if seen[source] then
        return target
    end
    seen[source] = true
    
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then
            M.merge_tables(target[key], value, seen)
        else
            target[key] = value
        end
    end
    
    return target
end

-- 檢查值是否為空
function M.is_empty(value)
    if value == nil then
        return true
    elseif type(value) == "string" then
        return value == "" or value:match("^%s*$")
    elseif type(value) == "table" then
        return vim.tbl_isempty(value)
    else
        return false
    end
end

-- 安全的JSON編碼
function M.safe_json_encode(data)
    local success, result = pcall(vim.json.encode, data)
    if success then
        return result
    else
        -- 回退到簡單字串表示
        return vim.inspect(data)
    end
end

-- 安全的JSON解碼
function M.safe_json_decode(json_str)
    if M.is_empty(json_str) then
        return nil, "Empty JSON string"
    end
    
    local success, result = pcall(vim.json.decode, json_str)
    if success then
        return result, nil
    else
        return nil, "JSON decode failed: " .. tostring(result)
    end
end

-- 建立安全的回調包裝器
function M.safe_callback(callback, context)
    context = context or "unknown"
    
    return function(...)
        local success, result = pcall(callback, ...)
        if not success then
            vim.notify(string.format("Callback error in %s: %s", context, result), vim.log.levels.ERROR)
            return nil
        end
        return result
    end
end

-- 防抖動函數
function M.debounce(func, delay)
    local timer_id = nil
    
    return function(...)
        local args = {...}
        
        if timer_id then
            vim.fn.timer_stop(timer_id)
        end
        
        timer_id = vim.fn.timer_start(delay, function()
            func(unpack(args))
            timer_id = nil
        end)
    end
end

-- 節流函數
function M.throttle(func, delay)
    local last_call = 0
    
    return function(...)
        local now = vim.uv.hrtime() / 1e6 -- 轉換為毫秒
        
        if now - last_call >= delay then
            last_call = now
            return func(...)
        end
    end
end

-- 重試機制
function M.retry(func, max_attempts, delay, backoff_factor)
    max_attempts = max_attempts or 3
    delay = delay or 100
    backoff_factor = backoff_factor or 2
    
    local attempt = 1
    local current_delay = delay
    
    local function try_func()
        local success, result = pcall(func)
        
        if success then
            return result
        elseif attempt < max_attempts then
            attempt = attempt + 1
            
            vim.defer_fn(try_func, current_delay)
            current_delay = current_delay * backoff_factor
        else
            error("Max retry attempts exceeded: " .. tostring(result))
        end
    end
    
    return try_func()
end

-- 創建弱引用表
function M.create_weak_table(mode)
    mode = mode or "v" -- 預設為弱值
    return setmetatable({}, {__mode = mode})
end

-- 安全的模組載入
function M.safe_require(module_name, fallback)
    local success, module = pcall(require, module_name)
    if success then
        return module
    else
        if fallback then
            return fallback
        else
            vim.notify(string.format("Failed to load module: %s", module_name), vim.log.levels.WARN)
            return nil
        end
    end
end

-- 檢查Neovim版本
function M.check_nvim_version(required_version)
    local current = vim.version()
    local required = vim.version.parse(required_version)
    
    return vim.version.cmp(current, required) >= 0
end

-- 獲取系統資訊
function M.get_system_info()
    return {
        os = vim.uv.os_uname(),
        nvim_version = vim.version(),
        has_clipboard = vim.fn.has('clipboard') == 1,
        term = os.getenv('TERM'),
        term_program = os.getenv('TERM_PROGRAM'),
        is_tmux = os.getenv('TMUX') ~= nil,
        is_ssh = os.getenv('SSH_CLIENT') ~= nil or os.getenv('SSH_TTY') ~= nil
    }
end

-- 記憶體使用情況
function M.get_memory_usage()
    local before = collectgarbage("count")
    collectgarbage("collect")
    local after = collectgarbage("count")
    
    return {
        before_gc = before,
        after_gc = after,
        freed = before - after
    }
end

-- 效能測試工具
function M.benchmark(func, iterations)
    iterations = iterations or 1000
    
    local start_time = vim.uv.hrtime()
    
    for i = 1, iterations do
        func()
    end
    
    local end_time = vim.uv.hrtime()
    local total_time = (end_time - start_time) / 1e6 -- 毫秒
    
    return {
        total_time = total_time,
        average_time = total_time / iterations,
        iterations = iterations
    }
end

return M