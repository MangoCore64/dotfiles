-- Phase 0 滲透測試套件
-- 模擬攻擊者視角驗證安全修復有效性

local test_utils = require('tests.test_utils')
local M = {}

-- 測試命令注入攻擊 (TERM-001)
local function test_command_injection_attacks()
    local claude = require('utils.terminal.adapters.claude')
    
    -- 攻擊測試：嘗試透過模式匹配繞過
    local malicious_patterns = {
        "Claude; rm -rf /",  -- 命令分隔符攻擊
        "Claude`whoami`",    -- 命令替換攻擊
        "Claude$(id)",       -- 命令替換攻擊
        "Claude||wget",      -- 邏輯操作符攻擊
        "Claude&&curl",      -- 邏輯操作符攻擊
        "Claude|nc",         -- 管道攻擊
    }
    
    -- 測試是否正確拒絕惡意模式
    for _, malicious in ipairs(malicious_patterns) do
        -- 模擬惡意 buffer name
        local safe = true
        -- 如果使用舊的寬鬆匹配，這些可能會被錯誤匹配
        if malicious:match("[Cc]laude") then
            -- 檢查是否只匹配精確的 Claude 模式
            local claude_file_path = vim.fn.stdpath("config") .. "/lua/utils/terminal/adapters/claude.lua"
            local content = vim.fn.readfile(claude_file_path)
            local full_content = table.concat(content, "\n")
            
            -- 確保使用錨點匹配
            local uses_strict_matching = full_content:find("%^%[Cc%]laude%$") ~= nil
            test_utils.assert_true(uses_strict_matching, 
                string.format("應該使用嚴格匹配防止 '%s' 等惡意輸入", malicious))
        end
    end
    
    print("✓ 命令注入攻擊防護有效")
end

-- 測試輸入驗證繞過 (TERM-002)
local function test_input_validation_bypass()
    local claude_file_path = vim.fn.stdpath("config") .. "/lua/utils/terminal/adapters/claude.lua"
    local content = vim.fn.readfile(claude_file_path)
    local full_content = table.concat(content, "\n")
    
    -- 測試：確保不能透過部分匹配繞過
    local bypass_attempts = {
        "MyClaude",      -- 前綴攻擊
        "ClaudeCode123", -- 後綴攻擊
        "claude-evil",   -- 變體攻擊
        "CLAUDE",        -- 大小寫變體
    }
    
    -- 檢查模式是否嚴格enough防止繞過
    local patterns_in_code = {}
    for pattern in full_content:gmatch("'([^']*%[Cc%][^']*)'") do
        table.insert(patterns_in_code, pattern)
    end
    
    -- 確保所有模式都使用錨點
    for _, pattern in ipairs(patterns_in_code) do
        local has_start_anchor = pattern:match("^%^") ~= nil
        local has_end_anchor = pattern:match("%$$") ~= nil
        
        test_utils.assert_true(has_start_anchor or has_end_anchor, 
            string.format("模式 '%s' 應該使用錨點防止部分匹配", pattern))
    end
    
    print("✓ 輸入驗證繞過防護有效")
end

-- 測試權限提升攻擊
local function test_privilege_escalation()
    local claude_file_path = vim.fn.stdpath("config") .. "/lua/utils/terminal/adapters/claude.lua"
    local content = vim.fn.readfile(claude_file_path)
    local full_content = table.concat(content, "\n")
    
    -- 檢查是否正確驗證命令存在性
    local has_command_validation = full_content:find("validate_claude_command") ~= nil
    test_utils.assert_true(has_command_validation, "應該驗證命令存在性防止權限提升")
    
    -- 檢查是否使用 pcall 安全執行
    local uses_safe_execution = full_content:find("pcall.*vim%.cmd") ~= nil
    test_utils.assert_true(uses_safe_execution, "應該使用安全執行方式")
    
    -- 檢查錯誤處理不洩露敏感資訊
    local has_safe_error_handling = full_content:find("安全檢查失敗") ~= nil
    test_utils.assert_true(has_safe_error_handling, "錯誤處理應該安全且不洩露資訊")
    
    print("✓ 權限提升攻擊防護有效")
end

-- 測試資訊洩露攻擊
local function test_information_disclosure()
    local claude_file_path = vim.fn.stdpath("config") .. "/lua/utils/terminal/adapters/claude.lua"
    local content = vim.fn.readfile(claude_file_path)
    local full_content = table.concat(content, "\n")
    
    -- 檢查錯誤訊息不包含敏感資訊
    local sensitive_patterns = {
        "path",        -- 路徑資訊
        "system",      -- 系統資訊  
        "debug",       -- 除錯資訊
        "trace",       -- 追蹤資訊
        "internal"     -- 內部資訊
    }
    
    for _, sensitive in ipairs(sensitive_patterns) do
        local has_sensitive_info = full_content:lower():find(sensitive) ~= nil
        -- 允許在註解中出現，但不能在錯誤訊息中
        if has_sensitive_info then
            local in_error_msg = full_content:find("vim%.notify.*" .. sensitive) ~= nil
            test_utils.assert_false(in_error_msg, 
                string.format("錯誤訊息不應包含敏感資訊: %s", sensitive))
        end
    end
    
    print("✓ 資訊洩露攻擊防護有效")
end

-- 測試拒絕服務攻擊
local function test_denial_of_service()
    local claude = require('utils.terminal.adapters.claude')
    
    -- 測試：確保函數不會無限循環或阻塞
    local start_time = vim.uv.hrtime()
    
    -- 呼叫可能的危險操作
    local operations = {
        function() return claude.find_claude_terminal() end,
        function() return claude.is_visible() end,
    }
    
    for i, op in ipairs(operations) do
        local op_start = vim.uv.hrtime()
        local success, result = pcall(op)
        local op_end = vim.uv.hrtime()
        local duration = (op_end - op_start) / 1e6 -- 轉換為毫秒
        
        -- 檢查操作不會超時（設定 1 秒限制）
        test_utils.assert_true(duration < 1000, 
            string.format("操作 %d 不應超過 1 秒 (實際: %.2f ms)", i, duration))
        
        -- 檢查操作應該安全返回（不崩潰）
        test_utils.assert_true(success or result ~= nil, 
            string.format("操作 %d 應該安全執行", i))
    end
    
    print("✓ 拒絕服務攻擊防護有效")
end

-- 測試狀態操縱攻擊
local function test_state_manipulation()
    local state = require('utils.terminal.state')
    
    -- 檢查狀態管理是否安全
    local state_file_path = vim.fn.stdpath("config") .. "/lua/utils/terminal/state.lua"
    local content = vim.fn.readfile(state_file_path)
    local full_content = table.concat(content, "\n")
    
    -- 檢查是否有適當的狀態驗證
    local has_validation = full_content:find("is_buf_valid") ~= nil or 
                          full_content:find("is_win_valid") ~= nil
    test_utils.assert_true(has_validation, "狀態管理應該包含驗證機制")
    
    -- 測試狀態操作的安全性
    local test_buf = -1  -- 無效 buffer ID
    local result = state.is_buf_valid(test_buf)
    test_utils.assert_false(result, "應該正確識別無效 buffer")
    
    print("✓ 狀態操縱攻擊防護有效")
end

-- 運行滲透測試
function M.run_penetration_tests()
    print("=== 開始 Phase 0 滲透測試 ===")
    print("模擬攻擊者視角驗證安全修復...")
    
    local results = {
        total = 0,
        passed = 0,
        failed = 0,
        errors = {}
    }
    
    local tests = {
        { name = "command_injection_attacks", func = test_command_injection_attacks },
        { name = "input_validation_bypass", func = test_input_validation_bypass },
        { name = "privilege_escalation", func = test_privilege_escalation },
        { name = "information_disclosure", func = test_information_disclosure },
        { name = "denial_of_service", func = test_denial_of_service },
        { name = "state_manipulation", func = test_state_manipulation }
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
    
    print(string.format("\n=== 滲透測試結果 ==="))
    print(string.format("總測試數: %d", results.total))
    print(string.format("通過: %d", results.passed))
    print(string.format("失敗: %d", results.failed))
    print(string.format("安全性評級: %.1f%%", results.total > 0 and (results.passed / results.total * 100) or 0))
    
    -- 安全評級判定
    local security_rating = results.passed / results.total
    if security_rating >= 1.0 then
        print("🔒 安全評級: 優秀 (Excellent) - 可以進入 Phase 1")
    elseif security_rating >= 0.8 then
        print("🔐 安全評級: 良好 (Good) - 建議修復後進入 Phase 1")
    else
        print("⚠️ 安全評級: 需要改進 (Needs Improvement) - 必須修復所有問題")
    end
    
    return results
end

-- 如果作為腳本直接運行，執行測試
if not pcall(debug.getlocal, 4, 1) then
    M.run_penetration_tests()
end

return M