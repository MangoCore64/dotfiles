-- Clipboard 模組化主入口
-- 統一的公共API，保持向後兼容性

local M = {}

-- 延遲載入子模組
local core = nil
local config = nil
local state = nil
local transport = nil
local security = nil

-- 延遲載入函數
local function load_modules()
    if not core then
        core = require('utils.clipboard.core')
        config = require('utils.clipboard.config')
        state = require('utils.clipboard.state')
        transport = require('utils.clipboard.transport')
        security = require('utils.clipboard.security')
    end
end

-- 初始化模組
local function init_modules()
    load_modules()
    
    -- 連接核心模組與傳輸層
    core._copy_to_transport = function(content)
        local success, results = transport.send_content(content)
        if success then
            -- 記錄成功的傳輸
            local successful_transports = {}
            for name, result in pairs(results) do
                if result.success then
                    table.insert(successful_transports, name)
                end
            end
            
            if config.get('performance_monitoring') then
                vim.notify(string.format("已複製至: %s", table.concat(successful_transports, ", ")), vim.log.levels.DEBUG)
            end
            
            return true
        else
            -- 處理傳輸失敗
            local error_messages = {}
            for name, result in pairs(results) do
                if not result.success and not result.skipped then
                    table.insert(error_messages, string.format("%s: %s", name, result.message))
                end
            end
            
            vim.notify("剪貼板傳輸失敗:\n" .. table.concat(error_messages, "\n"), vim.log.levels.ERROR)
            return false
        end
    end
end

-- 向後兼容的公共API

-- 標準複製功能
function M.copy_with_path()
    load_modules()
    return core.copy_with_path()
end

-- 檔案引用複製
function M.copy_file_reference(detailed)
    load_modules()
    return core.copy_file_reference(detailed)
end

-- 分段複製
function M.copy_next_segment()
    load_modules()
    return core.copy_next_segment()
end

-- 純文字壓縮複製 (無元數據)
function M.copy_compressed()
    load_modules()
    return core.copy_compressed()
end

-- 壓縮格式複製
function M.copy_with_path_compressed()
    load_modules()
    return core.copy_compressed()
end

-- 檔案輸出功能
function M.copy_to_file_only()
    load_modules()
    
    local segments, segment_type, metadata = core.process_selection()
    if not segments or #segments == 0 then 
        vim.notify("無法獲取選擇的內容", vim.log.levels.WARN)
        return 
    end
    
    local content = table.concat(segments, "\n--- SEGMENT BREAK ---\n")
    
    -- 生成暫存檔案名
    local temp_dir = os.getenv("TMPDIR") or os.getenv("XDG_RUNTIME_DIR") or "/tmp"
    local random_suffix = tostring(os.time()) .. '_' .. tostring(math.random(10000, 99999))
    local temp_file = temp_dir .. '/nvim_clipboard_' .. random_suffix .. '.txt'
    
    -- 安全檢查檔案路徑
    if not temp_file:match('^[%w%/%._-]+$') then
        vim.notify("生成的暫存檔案路徑包含非法字符", vim.log.levels.ERROR)
        return
    end
    
    local success, write_err = pcall(vim.fn.writefile, vim.split(content, '\n'), temp_file)
    if success then
        vim.notify("內容已儲存至: " .. temp_file, vim.log.levels.INFO)
        vim.notify("檔案包含 " .. #segments .. " 個分段", vim.log.levels.INFO)
        
        state.record_operation("copy_to_file_only", true, {
            file_path = temp_file,
            segments = #segments,
            bytes_processed = #content
        })
    else
        vim.notify("檔案儲存失敗: " .. tostring(write_err), vim.log.levels.ERROR)
        state.record_operation("copy_to_file_only", false, {
            error = tostring(write_err)
        })
    end
end

-- 發送到 Claude Code
function M.send_to_claude()
    -- 先複製代碼到剪貼板
    M.copy_with_path()
    
    -- 等待剪貼板操作完成
    vim.defer_fn(function()
        -- 檢查 ClaudeCode 命令是否可用
        if vim.fn.exists(':ClaudeCode') == 2 then
            vim.cmd('ClaudeCode')
        else
            -- 嘗試手動啟動
            local claude_commands = {'claude-code', 'claude_code', 'ClaudeCode'}
            local found = false
            
            for _, cmd in ipairs(claude_commands) do
                if vim.fn.executable(cmd) == 1 then
                    vim.fn.system(cmd .. ' &')
                    found = true
                    break
                end
            end
            
            if not found then
                vim.notify("Claude Code 未找到，請確保已安裝", vim.log.levels.WARN)
            end
        end
    end, 500)
end

-- 診斷功能
function M.diagnose_clipboard()
    load_modules()
    
    local diagnosis = core.diagnose()
    local transport_info = transport.diagnose()
    
    -- 環境資訊
    local env_info = {
        term = os.getenv('TERM') or 'unknown',
        term_program = os.getenv('TERM_PROGRAM') or 'unknown',
        tmux = os.getenv('TMUX') and 'YES' or 'NO',
        ssh = os.getenv('SSH_CLIENT') and 'YES' or 'NO'
    }
    
    -- 格式化輸出
    local info_lines = {
        "=== Clipboard Diagnosis ===",
        string.format("TERM: %s", env_info.term),
        string.format("TERM_PROGRAM: %s", env_info.term_program),
        string.format("TMUX: %s", env_info.tmux),
        string.format("SSH: %s", env_info.ssh),
        "",
        "=== Performance Info ===",
        string.format("Performance monitoring: %s", 
            diagnosis.config.monitoring == "✅ 啟用" and "ENABLED" or "DISABLED"),
        string.format("Security check: %s", 
            diagnosis.config.security_status == "✅ 啟用" and "ENABLED" or "DISABLED"),
        "",
        "=== Recommendations ==="
    }
    
    -- 添加建議
    if env_info.term_program == 'unknown' then
        table.insert(info_lines, "? Unknown terminal: " .. env_info.term)
        table.insert(info_lines, "Check terminal OSC 52 support")
    end
    
    if env_info.tmux == 'YES' then
        table.insert(info_lines, "⚠ TMUX detected - may need: set -s set-clipboard on")
    end
    
    local info = table.concat(info_lines, "\n")
    print(info)
    vim.notify("Clipboard diagnosis printed to messages")
    
    state.record_operation("diagnose_clipboard", true, {})
end

-- 安全啟用 OSC 52
function M.enable_osc52_safely()
    load_modules()
    
    local available_transports = transport.get_available_transports()
    
    if available_transports.osc52 and available_transports.osc52.available then
        config.update({enable_osc52 = true})
        vim.notify("✅ OSC 52 已安全啟用", vim.log.levels.INFO)
        return true
    else
        local reason = available_transports.osc52 and available_transports.osc52.reason or "OSC 52 不可用"
        vim.notify("❌ 無法啟用 OSC 52: " .. reason, vim.log.levels.WARN)
        
        -- 提供互動式確認
        local choice = vim.fn.confirm(
            "您的終端可能不支援 OSC 52。仍要啟用嗎？", 
            "&是\n&否", 
            2
        )
        
        if choice == 1 then
            config.update({enable_osc52 = true})
            vim.notify("⚠️ OSC 52 已強制啟用（實驗性）", vim.log.levels.WARN)
            return true
        else
            vim.notify("❌ OSC 52 保持禁用狀態", vim.log.levels.INFO)
            return false
        end
    end
end

-- 配置管理
function M.configure(new_config)
    load_modules()
    
    local changes = config.update(new_config)
    
    if next(changes) then
        local change_messages = {}
        for key, change in pairs(changes) do
            local message = ""
            if key == "enable_osc52" then
                message = "OSC 52: " .. (change.new and "啟用" or "禁用")
            elseif key == "security_check" then
                message = "安全檢查: " .. (change.new and "啟用" or "禁用")
            else
                message = string.format("%s: %s", key, tostring(change.new))
            end
            table.insert(change_messages, message)
        end
        
        vim.notify("🔧 剪貼板配置已更新:\n" .. table.concat(change_messages, "\n"), vim.log.levels.INFO)
        
        state.record_operation("configure", true, {
            changes = changes
        })
    else
        vim.notify("無有效的配置變更", vim.log.levels.WARN)
    end
end

-- 顯示配置
function M.show_config()
    load_modules()
    
    local summary = config.get_summary()
    
    local config_lines = {
        "=== 🔐 剪貼板安全設定 ===",
        string.format("OSC 52: %s", summary.osc52_status),
        string.format("安全檢查: %s", summary.security_status),
        string.format("大小限制: %s", summary.size_limit),
        string.format("嚴格驗證: %s", summary.validation),
        string.format("效能監控: %s", summary.monitoring),
        "",
        "=== 🛠️  控制指令 ===",
        ":lua require('utils.clipboard').enable_osc52_safely() -- 安全啟用 OSC 52",
        ":lua require('utils.clipboard').configure({enable_osc52 = false}) -- 禁用 OSC 52",
        ":lua require('utils.clipboard').configure({security_check = false}) -- 禁用安全檢查",
        ":lua require('utils.clipboard').configure({performance_monitoring = true}) -- 啟用效能監控",
        ":lua require('utils.clipboard').diagnose_clipboard() -- 診斷剪貼板功能"
    }
    
    local config_info = table.concat(config_lines, "\n")
    print(config_info)
    vim.notify("剪貼板設定已輸出到 :messages")
end

-- 擴展API：註冊自定義傳輸方式
function M.register_transport(name, transport_impl)
    load_modules()
    return transport.register_transport(name, transport_impl)
end

-- 擴展API：註冊自定義安全掃描器
function M.register_security_scanner(name, scanner, priority)
    load_modules()
    return security.register_scanner(name, scanner)
end

-- 擴展API：獲取狀態資訊
function M.get_state()
    load_modules()
    return state.get()
end

-- 擴展API：獲取統計資訊
function M.get_stats()
    load_modules()
    return state.get_stats()
end

-- 清理函數（VimLeavePre 時調用）
function M.cleanup()
    if state then
        state.cleanup_on_exit()
    end
    if security then
        security.secure_cleanup()
    end
end

-- 自動設置 VimLeavePre 清理
vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        M.cleanup()
    end,
    desc = "Clipboard module cleanup on exit"
})

-- 初始化模組（延遲執行）
vim.defer_fn(function()
    init_modules()
end, 10)

return M