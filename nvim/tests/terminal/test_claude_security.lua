-- Claude 終端安全修復專項測試
local test_utils = require('tests.test_utils')

local M = {}

-- 測試命令存在性驗證
local function test_command_existence_validation()
    -- 模擬載入 Claude 模組
    local claude = require('utils.terminal.adapters.claude')
    
    -- 這個測試檢查是否會在命令不存在時正確處理
    -- 由於我們無法直接測試 ClaudeCode 命令，我們檢查程式碼邏輯
    local claude_file_path = vim.fn.stdpath("config") .. "/lua/utils/terminal/adapters/claude.lua"
    local content = vim.fn.readfile(claude_file_path)
    local full_content = table.concat(content, "\n")
    
    -- 檢查是否有命令存在性檢查
    local has_command_check = full_content:find("ClaudeCode 命令不存在") ~= nil
    test_utils.assert_true(has_command_check, "應該檢查 ClaudeCode 命令是否存在")
    
    print("✓ 命令存在性驗證已實施")
end

-- 測試安全驗證流程
local function test_security_validation_flow()
    local claude_file_path = vim.fn.stdpath("config") .. "/lua/utils/terminal/adapters/claude.lua"
    local content = vim.fn.readfile(claude_file_path)
    local full_content = table.concat(content, "\n")
    
    -- 檢查安全驗證流程
    local has_validation_call = full_content:find("validate_claude_command()") ~= nil
    test_utils.assert_true(has_validation_call, "應該調用安全驗證函數")
    
    -- 檢查是否在驗證失敗時停止執行
    local has_validation_check = full_content:find("if not valid then") ~= nil
    test_utils.assert_true(has_validation_check, "應該在驗證失敗時停止執行")
    
    print("✓ 安全驗證流程已建立")
end

-- 測試模式匹配安全性
local function test_pattern_matching_security()
    local claude = require('utils.terminal.adapters.claude')
    
    -- 測試舊的不安全模式是否已被移除
    local claude_file_path = vim.fn.stdpath("config") .. "/lua/utils/terminal/adapters/claude.lua"
    local content = vim.fn.readfile(claude_file_path)
    local full_content = table.concat(content, "\n")
    
    -- 檢查是否不再使用寬鬆模式（如 '[Cc]laude' 而不是 '^[Cc]laude$'）
    local has_loose_pattern = full_content:find("'%[Cc%]laude'") ~= nil
    test_utils.assert_false(has_loose_pattern, "不應該使用寬鬆的模式匹配")
    
    -- 檢查是否使用嚴格的錨點匹配
    local has_strict_pattern = full_content:find("%^%[Cc%]laude%$") ~= nil
    test_utils.assert_true(has_strict_pattern, "應該使用嚴格的錨點匹配")
    
    print("✓ 模式匹配安全性已提升")
end

-- 測試錯誤訊息安全性
local function test_error_message_security()
    local claude_file_path = vim.fn.stdpath("config") .. "/lua/utils/terminal/adapters/claude.lua"
    local content = vim.fn.readfile(claude_file_path)
    local full_content = table.concat(content, "\n")
    
    -- 檢查錯誤訊息是否適當（不洩露敏感資訊）
    local has_safe_error_msg = full_content:find("安全檢查失敗") ~= nil
    test_utils.assert_true(has_safe_error_msg, "應該有安全的錯誤訊息")
    
    -- 檢查是否避免詳細的系統資訊洩露
    local avoids_system_info = not full_content:find("系統路徑") and not full_content:find("詳細錯誤")
    test_utils.assert_true(avoids_system_info, "錯誤訊息不應洩露詳細系統資訊")
    
    print("✓ 錯誤訊息安全性已改善")
end

-- 測試防禦性程式設計
local function test_defensive_programming()
    local claude = require('utils.terminal.adapters.claude')
    
    -- 測試 API 的健壯性
    local api_functions = {
        'find_claude_terminal',
        'is_visible', 
        'toggle',
        'open',
        'close'
    }
    
    for _, func_name in ipairs(api_functions) do
        test_utils.assert_not_nil(claude[func_name], string.format("%s 函數應該存在", func_name))
        test_utils.assert_equals("function", type(claude[func_name]), string.format("%s 應該是函數", func_name))
    end
    
    print("✓ 防禦性程式設計檢查通過")
end

-- 運行所有測試
function M.run_all()
    local results = {
        total = 0,
        passed = 0,
        failed = 0,
        errors = {}
    }
    
    local tests = {
        { name = "command_existence_validation", func = test_command_existence_validation },
        { name = "security_validation_flow", func = test_security_validation_flow },
        { name = "pattern_matching_security", func = test_pattern_matching_security },
        { name = "error_message_security", func = test_error_message_security },
        { name = "defensive_programming", func = test_defensive_programming }
    }
    
    for _, test in ipairs(tests) do
        results.total = results.total + 1
        
        local success, err = pcall(test.func)
        if success then
            results.passed = results.passed + 1
            print(string.format("✓ %s 通過", test.name))
        else
            results.failed = results.failed + 1
            results.errors[test.name] = err
            print(string.format("✗ %s 失敗: %s", test.name, tostring(err)))
        end
    end
    
    print(string.format("\n=== Claude 安全專項測試結果 ==="))
    print(string.format("總測試數: %d", results.total))
    print(string.format("通過: %d", results.passed))
    print(string.format("失敗: %d", results.failed))
    print(string.format("成功率: %.1f%%", results.total > 0 and (results.passed / results.total * 100) or 0))
    
    return results
end

-- 如果作為腳本直接運行，執行測試
if not pcall(debug.getlocal, 4, 1) then
    M.run_all()
end

return M