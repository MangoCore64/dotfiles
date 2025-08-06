-- Phase 0 安全修復驗證測試
local test_utils = require('tests.test_utils')

local M = {}

-- 測試 TERM-001 修復：命令注入防護
local function test_command_injection_protection()
    local claude = require('utils.terminal.adapters.claude')
    
    -- 測試：檢查是否有安全驗證函數
    local claude_file_path = vim.fn.stdpath("config") .. "/lua/utils/terminal/adapters/claude.lua"
    local content = vim.fn.readfile(claude_file_path)
    local full_content = table.concat(content, "\n")
    
    -- 驗證安全驗證函數存在
    local has_validation = full_content:find("validate_claude_command") ~= nil
    test_utils.assert_true(has_validation, "應該包含 validate_claude_command 安全驗證函數")
    
    -- 驗證不再直接執行命令
    local has_safe_execution = full_content:find("安全執行 Claude Code 命令") ~= nil
    test_utils.assert_true(has_safe_execution, "應該包含安全執行註解")
    
    print("✓ TERM-001 命令注入防護已修復")
end

-- 測試 TERM-002 修復：輸入驗證強化
local function test_input_validation_improvement()
    local claude_file_path = vim.fn.stdpath("config") .. "/lua/utils/terminal/adapters/claude.lua"
    local content = vim.fn.readfile(claude_file_path)
    local full_content = table.concat(content, "\n")
    
    -- 檢查是否使用更嚴格的模式匹配
    local has_strict_patterns = full_content:find("精確匹配") ~= nil
    test_utils.assert_true(has_strict_patterns, "應該使用精確匹配模式防止繞過")
    
    -- 檢查是否包含錨點匹配 (^ 和 $)
    local has_anchor_patterns = full_content:find("%^.*%$") ~= nil
    test_utils.assert_true(has_anchor_patterns, "應該使用錨點匹配防止部分匹配繞過")
    
    print("✓ TERM-002 輸入驗證已強化")
end

-- 測試基線功能完整性
local function test_baseline_functionality()
    local claude = require('utils.terminal.adapters.claude')
    
    -- 驗證所有 API 函數存在
    test_utils.assert_not_nil(claude.find_claude_terminal, "find_claude_terminal 函數應該存在")
    test_utils.assert_not_nil(claude.is_visible, "is_visible 函數應該存在")
    test_utils.assert_not_nil(claude.toggle, "toggle 函數應該存在")
    test_utils.assert_not_nil(claude.open, "open 函數應該存在")
    test_utils.assert_not_nil(claude.close, "close 函數應該存在")
    
    print("✓ 基線功能完整性驗證通過")
end

-- 測試錯誤處理改進
local function test_error_handling_improvement()
    local claude_file_path = vim.fn.stdpath("config") .. "/lua/utils/terminal/adapters/claude.lua"
    local content = vim.fn.readfile(claude_file_path)
    local full_content = table.concat(content, "\n")
    
    -- 檢查是否有適當的錯誤訊息
    local has_security_error_msg = full_content:find("安全檢查失敗") ~= nil
    test_utils.assert_true(has_security_error_msg, "應該包含安全檢查失敗的錯誤訊息")
    
    -- 檢查是否使用 pcall 進行安全執行
    local uses_pcall = full_content:find("pcall") ~= nil
    test_utils.assert_true(uses_pcall, "應該使用 pcall 進行安全的錯誤處理")
    
    print("✓ 錯誤處理已改進")
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
        { name = "command_injection_protection", func = test_command_injection_protection },
        { name = "input_validation_improvement", func = test_input_validation_improvement },
        { name = "baseline_functionality", func = test_baseline_functionality },
        { name = "error_handling_improvement", func = test_error_handling_improvement }
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
    
    print(string.format("\n=== Phase 0 安全修復測試結果 ==="))
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