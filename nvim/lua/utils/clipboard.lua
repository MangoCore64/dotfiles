-- 智能剪貼板工具模組
-- 支援 OSC 52、分段處理、文件引用等功能

local M = {}

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
    
    -- 如果標記無效，使用當前行作為後備
    local current_line = vim.fn.line('.')
    local current_content = vim.fn.getline(current_line)
    return {current_content}, current_line, current_line
end

-- 分段處理函數（改用行數分段確保完整性）
local function split_content(content, segment_size)
    local segments = {}
    local all_lines = vim.split(content, '\n')
    
    -- 第一行是檔案路徑，後續是代碼行
    local file_path = all_lines[1] or ""
    local code_lines = {}
    for i = 2, #all_lines do
        if all_lines[i] ~= "" then  -- 跳過空行
            table.insert(code_lines, all_lines[i])
        end
    end
    
    -- 計算每段的行數限制（基於字符數估算）
    local avg_line_length = 50  -- 估算平均行長度
    local lines_per_segment = math.max(10, math.floor(segment_size / avg_line_length))
    
    local segment_count = 1
    local current_line_index = 1
    
    while current_line_index <= #code_lines do
        local segment_lines = {}
        local segment_size_check = #file_path + 20  -- 檔案路徑 + 標記的基本長度
        
        -- 收集這一段的行
        for i = current_line_index, math.min(current_line_index + lines_per_segment - 1, #code_lines) do
            local line = code_lines[i]
            segment_size_check = segment_size_check + #line + 1
            
            -- 如果加入這行會超過大小限制，且已經有其他行，則停止
            if segment_size_check > segment_size and #segment_lines > 0 then
                break
            end
            
            table.insert(segment_lines, line)
            current_line_index = i + 1
        end
        
        -- 組建段落內容
        if #segment_lines > 0 then
            local segment_content = file_path .. "\n" .. table.concat(segment_lines, "\n")
            table.insert(segments, string.format("[Part %d] %s", segment_count, segment_content))
            segment_count = segment_count + 1
        else
            -- 如果單行都太長，強制包含
            if current_line_index <= #code_lines then
                local long_line = code_lines[current_line_index]
                local segment_content = file_path .. "\n" .. long_line
                table.insert(segments, string.format("[Part %d] %s", segment_count, segment_content))
                current_line_index = current_line_index + 1
                segment_count = segment_count + 1
            end
        end
    end
    
    -- 驗證是否所有行都被包含
    local total_lines_in_segments = 0
    for _, segment in ipairs(segments) do
        local segment_lines = vim.split(segment, '\n')
        total_lines_in_segments = total_lines_in_segments + (#segment_lines - 2)  -- 減去標記行和檔案路徑行
    end
    
    if total_lines_in_segments ~= #code_lines then
        vim.notify(string.format("Warning: Line count mismatch. Original: %d, Segmented: %d", #code_lines, total_lines_in_segments), vim.log.levels.WARN)
    end
    
    return segments, true
end

-- 全域設定
local M_config = {
    enable_osc52 = true,  -- 設為 false 可禁用 OSC 52 以提高安全性
    security_check = true -- 啟用敏感內容檢查
}

-- 內容處理選項
local function process_selection(options)
    options = options or {}
    local segment_size = options.segment_size or 2000 -- 預設分段大小
    local compress = options.compress or false
    
    local filename = vim.fn.expand('%:p')
    local lines, line_start, line_end = get_visual_selection()
    
    -- 調試輸出：顯示選取範圍
    vim.notify(string.format("Selected: lines %d-%d (%d lines)", line_start, line_end, #lines), vim.log.levels.INFO)
    
    -- 組合結果
    local result = filename .. "\n"
    for i, line in ipairs(lines) do
        local content = line
        if compress then
            -- 壓縮模式：移除多餘空格，但保留空行結構
            if line:match("^%s*$") then
                content = ""  -- 空行保持為空行
            else
                content = line:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
            end
        end
        result = result .. (line_start + i - 1) .. ": " .. content .. "\n"
    end
    
    -- 調試輸出：顯示結果統計
    vim.notify(string.format("Content: %d bytes, %d lines", #result, #lines + 1), vim.log.levels.INFO)
    
    -- 檢查是否需要分段
    if #result > segment_size then
        return split_content(result, segment_size)
    else
        return {result}, false -- 單段內容，不需分段
    end
end

-- 剪貼板複製核心函數（共享函數）
local function copy_to_clipboard(content)
        -- OSC 52 剪貼板 (支援 VM 到宿主機)
        local function try_osc52()
            -- 檢查是否啟用 OSC 52
            if not M_config.enable_osc52 then
                return false
            end
            
            -- 安全警告：檢查內容是否可能包含敏感資訊
            if M_config.security_check then
                local content_lower = content:lower()
                if content_lower:match("password") or content_lower:match("secret") or 
                   content_lower:match("token") or content_lower:match("key") or
                   content_lower:match("api_key") or content_lower:match("auth") then
                    vim.notify("⚠️  警告：內容可能包含敏感資訊，OSC 52 將透過終端傳輸", vim.log.levels.WARN)
                    vim.notify("如有疑慮請使用本地剪貼板工具", vim.log.levels.INFO)
                    -- 對於敏感內容，跳過 OSC 52
                    return false
                end
            end
            
            -- 檢查內容大小限制 (大多數終端限制約 100KB)
            if #content > 100000 then
                vim.notify("Content too large for OSC 52 (" .. #content .. " bytes)", vim.log.levels.WARN)
                return false
            end
            
            local base64_content = vim.base64.encode(content)
            
            -- 安全性：驗證 base64 內容只包含有效字符
            local function sanitize_base64(b64_content)
                -- 僅保留 base64 有效字符：A-Z, a-z, 0-9, +, /, =
                return b64_content:gsub('[^A-Za-z0-9+/=]', '')
            end
            
            base64_content = sanitize_base64(base64_content)
            
            local term_program = os.getenv('TERM_PROGRAM') or ''
            local tmux = os.getenv('TMUX') or ''
            
            -- 檢查終端是否支援 OSC 52
            if term_program ~= 'iTerm.app' and term_program ~= 'Apple_Terminal' and not term_program:match('tmux') then
                return false
            end
            
            -- 選擇最佳 OSC 序列
            local osc_seq = '\027]52;c;' .. base64_content .. '\027\\'
            
            -- TMUX 包裝
            if tmux ~= '' then
                osc_seq = '\027Ptmux;\027' .. osc_seq:gsub('\027', '\027\027') .. '\027\\'
            end
            
            -- 發送序列並等待
            io.write(osc_seq)
            io.flush()
            
            -- 等待終端處理
            vim.wait(100)
            
            return true
        end
        
        -- 傳統剪貼板方法
        local function try_system_clipboard()
            local os_name = vim.loop.os_uname().sysname
            local cmd = nil
            
            if os_name == "Darwin" then
                cmd = 'pbcopy'
            elseif os_name == "Linux" then
                if vim.fn.executable('xclip') == 1 then
                    cmd = 'xclip -selection clipboard'
                elseif vim.fn.executable('xsel') == 1 then
                    cmd = 'xsel --clipboard --input'
                end
            elseif os_name == "Windows_NT" then
                cmd = 'clip'
            end
            
            if cmd then
                local handle = io.popen(cmd, 'w')
                if handle then
                    handle:write(content)
                    local success = handle:close()
                    return success
                end
            end
            return false
        end
        
        -- 暫存檔案後備方案
        local function save_to_file()
            local temp_dir = vim.fn.has('win32') == 1 and os.getenv('TEMP') or '/tmp'
            local temp_file = temp_dir .. '/nvim_clipboard.txt'
            return pcall(vim.fn.writefile, vim.split(content, '\n'), temp_file), temp_file
        end
        
        -- 暫時禁用系統剪貼板以避免衝突
        local original_clipboard = vim.opt.clipboard:get()
        vim.opt.clipboard = ""
        
        -- 依序嘗試剪貼板方法（不並行執行）
        local success = false
        local method = ""
        
        -- 1. 首先嘗試 OSC 52
        if try_osc52() then
            success = true
            method = "OSC 52"
        end
        
        -- 2. 如果 OSC 52 失敗，嘗試系統剪貼板
        if not success and try_system_clipboard() then
            success = true
            method = "system clipboard"
        end
        
        -- 3. 設定 vim 暫存器（作為後備）
        vim.fn.setreg('+', content)
        vim.fn.setreg('"', content)
        vim.fn.setreg('*', content)
        
        -- 4. 最後存到檔案
        local file_success, temp_file = save_to_file()
        
        -- 恢復原始剪貼板設定
        vim.defer_fn(function()
            vim.opt.clipboard = original_clipboard
        end, 200)
        
        -- 提供用戶反饋
        if success then
            vim.notify("Copied via " .. method .. " (" .. #content .. " bytes)")
            -- 顯示內容預覽（前50個字符）
            local preview = content:gsub("\n", " "):sub(1, 50) .. (#content > 50 and "..." or "")
            vim.notify("Preview: " .. preview, vim.log.levels.INFO)
        elseif file_success then
            vim.notify("Saved to registers and file: " .. temp_file)
        else
            vim.notify("Failed to copy - check :messages", vim.log.levels.ERROR)
        end
end

-- 檔案引用複製函數
function M.copy_file_reference(detailed)
    -- 確保退出 visual mode
    if vim.fn.mode():match('[vV\22]') then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'n', false)
        vim.wait(10)
    end
    
    vim.schedule(function()
        local filename = vim.fn.expand('%:p')
        local lines, line_start, line_end = get_visual_selection()
        
        -- 獲取 working directory 上下文
        local cwd = vim.fn.getcwd()
        local relative_path = vim.fn.fnamemodify(filename, ':.')
        
        local reference_text
        if detailed then
            -- 詳細格式
            reference_text = string.format(
                "File: %s\nLines: %d-%d (%d lines selected)\nWorking Directory: %s\nRelative Path: %s",
                filename,
                line_start,
                line_end,
                #lines,
                cwd,
                relative_path
            )
        else
            -- 簡潔格式
            reference_text = string.format("%s:%d-%d", filename, line_start, line_end)
        end
        
        -- 複製到剪貼板
        copy_to_clipboard(reference_text)
        
        -- 用戶反饋
        local format_type = detailed and "detailed" or "compact"
        vim.notify(string.format("File reference copied (%s format)", format_type), vim.log.levels.INFO)
        vim.notify(string.format("Lines: %d-%d (%d lines)", line_start, line_end, #lines), vim.log.levels.INFO)
        
        -- 提示後備選項
        if not detailed then
            vim.notify("Tip: Use <leader>cp for full content if AI can't access file", vim.log.levels.INFO)
        end
    end)
end

-- copy_with_path 函數：標準複製功能
function M.copy_with_path()
    -- 確保退出 visual mode（如果還在的話）
    if vim.fn.mode():match('[vV\22]') then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'n', false)
        vim.wait(10) -- 短暫等待模式切換完成
    end
    
    -- 實際複製執行函數
    local function execute_copy(options)
        options = options or {}
        
        vim.schedule(function()
            local segments, is_segmented = process_selection(options)
            if not segments or #segments == 0 then return end
            
            if is_segmented then
                -- 分段模式：只複製第一段，其餘顯示訊息
                local first_segment = segments[1]
                copy_to_clipboard(first_segment)
                
                vim.notify(string.format("Content split into %d parts. Copied Part 1.", #segments), vim.log.levels.WARN)
                vim.notify("Use <leader>cps to copy all segments sequentially", vim.log.levels.INFO)
                
                -- 將所有段落儲存到全域變數供後續使用
                _G.clipboard_segments = segments
                _G.current_segment_index = 2
            else
                -- 單段模式：正常複製
                copy_to_clipboard(segments[1])
            end
        end)
    end
    
    execute_copy()
end

-- 分段複製函數 - 複製下一段
function M.copy_next_segment()
    if not _G.clipboard_segments or not _G.current_segment_index then
        vim.notify("No segments available. Use <leader>cp first.", vim.log.levels.WARN)
        return
    end
    
    if _G.current_segment_index > #_G.clipboard_segments then
        vim.notify("All segments copied.", vim.log.levels.INFO)
        return
    end
    
    local segment = _G.clipboard_segments[_G.current_segment_index]
    copy_to_clipboard(segment)
    
    vim.notify(string.format("Copied Part %d/%d", _G.current_segment_index, #_G.clipboard_segments), vim.log.levels.INFO)
    _G.current_segment_index = _G.current_segment_index + 1
end

-- 壓縮格式複製函數
function M.copy_with_path_compressed()
    -- 確保退出 visual mode（如果還在的話）
    if vim.fn.mode():match('[vV\22]') then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'n', false)
        vim.wait(10) -- 短暫等待模式切換完成
    end
    
    -- 使用壓縮選項執行複製
    local function execute_copy_compressed()
        vim.schedule(function()
            local segments, is_segmented = process_selection({compress = true, segment_size = 3000})
            if not segments or #segments == 0 then return end
            
            copy_to_clipboard(segments[1])
            
            if is_segmented then
                vim.notify(string.format("Compressed & split into %d parts. Copied Part 1.", #segments), vim.log.levels.WARN)
                _G.clipboard_segments = segments
                _G.current_segment_index = 2
            else
                vim.notify("Copied in compressed format", vim.log.levels.INFO)
            end
        end)
    end
    
    execute_copy_compressed()
end

-- 檔案輸出函數
function M.copy_to_file_only()
    -- 確保退出 visual mode
    if vim.fn.mode():match('[vV\22]') then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'n', false)
        vim.wait(10)
    end
    
    vim.schedule(function()
        local segments, is_segmented = process_selection()
        if not segments or #segments == 0 then return end
        
        local content = table.concat(segments, "\n--- SEGMENT BREAK ---\n")
        local temp_dir = vim.fn.has('win32') == 1 and os.getenv('TEMP') or '/tmp'
        local temp_file = temp_dir .. '/nvim_clipboard.txt'
        
        local success, err = pcall(vim.fn.writefile, vim.split(content, '\n'), temp_file)
        if success then
            vim.notify("Content saved to: " .. temp_file, vim.log.levels.INFO)
            vim.notify("File contains " .. #segments .. " segment(s)", vim.log.levels.INFO)
        else
            vim.notify("Failed to save file: " .. tostring(err), vim.log.levels.ERROR)
        end
    end)
end

-- 發送到 Claude Code
function M.send_to_claude()
    -- 先複製代碼到剪貼板
    M.copy_with_path()
    
    -- 等待剪貼板操作完成
    vim.defer_fn(function()
        -- 檢查 ClaudeCode 命令是否可用
        local claude_available = false
        local commands = vim.api.nvim_get_commands({})
        
        for cmd_name, _ in pairs(commands) do
            if cmd_name == "ClaudeCode" then
                claude_available = true
                break
            end
        end
        
        if claude_available then
            -- 開啟 Claude Code
            vim.cmd('ClaudeCode')
            vim.notify("Code copied to clipboard. Paste with Cmd/Ctrl+V", vim.log.levels.INFO)
        else
            vim.notify("ClaudeCode command not available. Try <leader>cc manually or restart nvim.", vim.log.levels.WARN)
            vim.notify("Code has been copied to clipboard for manual pasting.", vim.log.levels.INFO)
        end
    end, 500) -- 增加延遲時間確保插件完全載入
end

-- 診斷剪貼板功能
function M.diagnose_clipboard()
    local term = os.getenv('TERM') or ''
    local term_program = os.getenv('TERM_PROGRAM') or ''
    local tmux = os.getenv('TMUX') or ''
    local ssh = os.getenv('SSH_TTY') or ''
    
    local info = "=== Clipboard Diagnosis ===\n"
    info = info .. "TERM: " .. term .. "\n"
    info = info .. "TERM_PROGRAM: " .. term_program .. "\n"
    info = info .. "TMUX: " .. (tmux ~= '' and "YES" or "NO") .. "\n"
    info = info .. "SSH: " .. (ssh ~= '' and "YES" or "NO") .. "\n\n"
    
    info = info .. "=== Recommendations ===\n"
    if term_program == "iTerm.app" then
        info = info .. "✓ iTerm2 detected - OSC 52 should work\n"
        info = info .. "Enable: Preferences > General > Selection > Applications in terminal may access clipboard\n"
    elseif term_program == "Apple_Terminal" then
        info = info .. "⚠ Terminal.app - OSC 52 support limited\n"
        info = info .. "Recommend switching to iTerm2\n"
    else
        info = info .. "? Unknown terminal: " .. term_program .. "\n"
        info = info .. "Check terminal OSC 52 support\n"
    end
    
    if tmux ~= '' then
        info = info .. "⚠ TMUX detected - may need: set -s set-clipboard on\n"
    end
    
    if ssh ~= '' then
        info = info .. "⚠ SSH connection - terminal must forward OSC sequences\n"
    end
    
    print(info)
    vim.notify("Clipboard diagnosis printed to messages")
end

-- 設定控制函數
function M.configure(config)
    if config.enable_osc52 ~= nil then
        M_config.enable_osc52 = config.enable_osc52
        vim.notify("OSC 52 " .. (config.enable_osc52 and "已啟用" or "已禁用"), vim.log.levels.INFO)
    end
    if config.security_check ~= nil then
        M_config.security_check = config.security_check
        vim.notify("安全檢查 " .. (config.security_check and "已啟用" or "已禁用"), vim.log.levels.INFO)
    end
end

-- 顯示當前設定
function M.show_config()
    local config_info = "=== 剪貼板安全設定 ===\n"
    config_info = config_info .. "OSC 52: " .. (M_config.enable_osc52 and "啟用" or "禁用") .. "\n"
    config_info = config_info .. "安全檢查: " .. (M_config.security_check and "啟用" or "禁用") .. "\n"
    config_info = config_info .. "\n使用方法：\n"
    config_info = config_info .. "require('utils.clipboard').configure({enable_osc52 = false}) -- 禁用 OSC 52\n"
    config_info = config_info .. "require('utils.clipboard').configure({security_check = false}) -- 禁用安全檢查"
    
    print(config_info)
    vim.notify("剪貼板設定已輸出到訊息")
end

return M