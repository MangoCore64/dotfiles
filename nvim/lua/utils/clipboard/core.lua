-- 核心業務邏輯模組
-- 負責剪貼板操作的核心邏輯、內容處理和流程控制

local M = {}

-- 模組依賴
local config = require('utils.clipboard.config')
local security = require('utils.clipboard.security')
local state = require('utils.clipboard.state')

-- 支援函數：獲取視覺選擇
local function get_visual_selection()
    -- 獲取最後選擇的標記
    local line_start = vim.fn.line("'<")
    local line_end = vim.fn.line("'>")
    
    -- 檢查標記是否有效
    if line_start > 0 and line_end > 0 and line_start <= line_end then
        local lines = vim.fn.getline(line_start, line_end)
        -- 檢查是否實際獲取到內容
        if lines and #lines > 0 then
            return lines, line_start, line_end
        end
    end
    
    -- 備用方案：獲取當前行
    local current_line = vim.fn.line('.')
    local current_content = vim.fn.getline(current_line)
    return {current_content}, current_line, current_line
end

-- 異步模式切換函數
local function ensure_normal_mode_async(callback)
    if vim.fn.mode():match('[vV\22]') then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'n', false)
        -- 使用 vim.schedule 確保在下一個事件循環中執行回调
        vim.schedule(callback)
    else
        callback()
    end
end

-- 優化的分段處理函數
function M.segment_content(content, segment_size)
    segment_size = segment_size or 2000
    
    if type(content) == "table" then
        content = table.concat(content, "\n")
    end
    
    local content_length = #content
    if content_length <= segment_size then
        return {content}, false
    end
    
    local segments = {}
    local start_pos = 1
    
    while start_pos <= content_length do
        local end_pos = math.min(start_pos + segment_size - 1, content_length)
        
        -- 嘗試在合適的位置分割（避免分割在單詞中間）
        if end_pos < content_length then
            local better_end = content:find("\n", end_pos - 100)
            if better_end and better_end > start_pos + segment_size / 2 then
                end_pos = better_end
            end
        end
        
        local segment = content:sub(start_pos, end_pos)
        table.insert(segments, segment)
        
        start_pos = end_pos + 1
    end
    
    return segments, #segments > 1
end

-- 內容處理選項
function M.process_selection(options) 
    options = options or {} 

    local lines, line_start, line_end = get_visual_selection() 
    if not lines or #lines == 0 then 
        return nil, "No content selected" 
    end 

    local processed_lines = {} 
    for i, line in ipairs(lines) do 
        local current_line_content = line 

        if options.compressed then 
            -- 壓縮模式：移除多餘空格 
            if current_line_content:match("^%s*$") then 
                current_line_content = "" -- 空行保持為空行 
            else 
                current_line_content = current_line_content:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ") 
            end 
        end 

        -- 重新加入行號 
        table.insert(processed_lines, (line_start + i - 1) .. ": " .. current_line_content) 
    end 

    local content = table.concat(processed_lines, "\n") 

    if options.add_metadata then 
        local filename = vim.fn.expand('%:p') 
        local metadata = string.format("File: %s\nLines: %d-%d (%d lines)\n%s\n%s", 
            filename, line_start, line_end, line_end - line_start + 1, 
            string.rep("=", 50), content) 
        content = metadata 
    end 

    -- 分段處理 
    local segments, is_segmented = M.segment_content(content, options.segment_size) 

    if is_segmented then 
        return segments, "segmented", { 
            total_segments = #segments, 
            original_size = #content, 
            line_range = {line_start, line_end} 
        } 
    else 
        return segments, "single", { 
            size = #content, 
            line_range = {line_start, line_end} 
        } 
    end 
end


-- 安全檢測包裝器
function M.check_content_security(content)
    local start_time = vim.uv.hrtime()
    
    local result = security.scan_content(content, config.get())
    
    -- 性能監控
    if config.get('performance_monitoring') then
        local elapsed = (vim.uv.hrtime() - start_time) / 1e6
        if elapsed > 20 then
            vim.notify(string.format("⚠️ 安全檢測耗時: %.2fms", elapsed), vim.log.levels.INFO)
        end
    end
    
    return result.safe, result.reason or "Security check failed"
end

-- 主要複製操作
function M.copy_with_path(options)
    options = options or {}
    
    ensure_normal_mode_async(function()
        local segments, segment_type, metadata = M.process_selection(options)
        
        if not segments then
            vim.notify("無法獲取選擇的內容", vim.log.levels.WARN)
            return
        end
        
        local content = segments[1] -- 使用第一個分段進行安全檢查
        local file_path = vim.fn.expand('%:p')
        content = file_path .. "\n" .. content
        
        -- 安全檢測
        local is_safe, security_reason = M.check_content_security(content)
        if not is_safe then
            vim.notify("🚫 內容包含敏感資訊，已阻止複製: " .. security_reason, vim.log.levels.WARN)
            state.record_operation("copy_with_path", false, {
                reason = "security_blocked",
                security_reason = security_reason,
                bytes_processed = #content
            })
            return
        end
        
        -- 處理分段內容
        if segment_type == "segmented" then
            state.set_segments(segments)
            vim.notify(string.format("內容已分為 %d 段，使用 <leader>cn 複製下一段", #segments), vim.log.levels.INFO)
            
            -- 複製第一段
            M._copy_to_transport(segments[1])
            state.record_operation("copy_with_path", true, {
                segment_type = "first_of_many",
                total_segments = #segments,
                bytes_processed = #segments[1]
            })
        else
            -- 單段複製
            M._copy_to_transport(content)
            state.record_operation("copy_with_path", true, {
                segment_type = "single",
                bytes_processed = #content
            })
        end
    end)
end

-- 複製檔案引用
function M.copy_file_reference(detailed)
    ensure_normal_mode_async(function()
        local filename = vim.fn.expand('%:p')
        local lines, line_start, line_end = get_visual_selection()

        -- 獲取 working directory 上下文
        local cwd = vim.fn.getcwd()
        local relative_path = vim.fn.fnamemodify(filename, ':.')

        local content
        if detailed then
            -- 詳細模式：包含完整內容
            local file_content = lines and table.concat(lines, "\n") or ""
            content = string.format("%s:%d-%d\n%s\n%s\n%s", 
                relative_path, line_start, line_end,
                string.rep("=", 50),
                file_content,
                string.rep("=", 50))
        else
            -- 簡潔模式：僅檔案引用
            content = string.format("%s:%d-%d", relative_path, line_start, line_end)
        end
        
        M._copy_to_transport(content)
        
        local mode_text = detailed and "詳細格式" or "緊湊格式"
        vim.notify(string.format("檔案引用已複製 (%s)\n行: %d-%d (%d 行)", 
            mode_text, line_start, line_end, line_end - line_start + 1), vim.log.levels.INFO)
        
        state.record_operation("copy_file_reference", true, {
            mode = detailed and "detailed" or "compact",
            line_range = {line_start, line_end},
            bytes_processed = #content
        })
    end)
end

-- 複製下一個分段
function M.copy_next_segment()
    local current_segments = state.get('segments')
    if not current_segments then
        vim.notify("沒有可用的分段。請先使用 <leader>cp", vim.log.levels.WARN)
        return
    end
    
    local success, current_index = state.next_segment()
    if not success then
        vim.notify("所有分段已複製完成", vim.log.levels.INFO)
        state.reset_segments()
        return
    end
    
    local segment = state.get_current_segment()
    if segment then
        M._copy_to_transport(segment)
        vim.notify(string.format("已複製分段 %d/%d", current_index, #current_segments), vim.log.levels.INFO)
        
        state.record_operation("copy_next_segment", true, {
            segment_index = current_index,
            total_segments = #current_segments,
            bytes_processed = #segment
        })
    end
end

-- 壓縮格式複製
function M.copy_compressed()
    ensure_normal_mode_async(function()
        local lines, line_start, line_end = get_visual_selection()

        if not lines or #lines == 0 then
            vim.notify("無法獲取選擇的內容", vim.log.levels.WARN)
            return
        end

        -- 1. 將所有行合併為一個字串
        local content = table.concat(lines, "\n")

        -- 2. 執行壓縮 (移除前導/尾隨空格和多餘的空行)
        content = content:gsub("^%s+", ""):gsub("%s+$", "")
        content = content:gsub("\n%s*\n", "\n")

        -- 3. 安全檢測
        local is_safe, security_reason = M.check_content_security(content)
        if not is_safe then
            vim.notify("🚫 內容包含敏感資訊: " .. security_reason, vim.log.levels.WARN)
            return
        end

        -- 4. 傳輸，不分段
        M._copy_to_transport(content)
        vim.notify("已複製（壓縮格式，無元數據）", vim.log.levels.INFO)
        
        state.record_operation("copy_compressed", true, {
            bytes_processed = #content,
            line_range = {line_start, line_end}
        })
    end)
end


-- 內部傳輸函數（將連接到傳輸層）
function M._copy_to_transport(content)
    -- 這裡將連接到傳輸管理模組
    -- 目前使用基本的系統剪貼板
    local success = pcall(function()
        vim.fn.setreg('+', content)
        vim.fn.setreg('"', content)
    end)
    
    if not success then
        vim.notify("複製到剪貼板失敗", vim.log.levels.ERROR)
        return false
    end
    
    return true
end

-- 獲取選擇資訊
function M.get_selection_info()
    local lines, line_start, line_end = get_visual_selection()
    if not lines then
        return nil
    end
    
    local content = table.concat(lines, "\n")
    local segments, is_segmented = M.segment_content(content)
    
    return {
        line_range = {line_start, line_end},
        line_count = line_end - line_start + 1,
        char_count = #content,
        byte_count = #content,
        will_segment = is_segmented,
        segment_count = #segments,
        filename = vim.fn.expand('%:p'),
        relative_path = vim.fn.fnamemodify(vim.fn.expand('%:p'), ':.'),
    }
end

-- 診斷功能
function M.diagnose()
    local info = M.get_selection_info()
    local stats = state.get_stats()
    local config_summary = config.get_summary()
    
    return {
        selection = info,
        session_stats = stats,
        config = config_summary,
        security_scanners = security.get_scanners()
    }
end

return M
