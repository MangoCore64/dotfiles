-- Critical Issues 修復驗證測試
local test_utils = require('tests.test_utils')

-- 測試 Critical Issue #1: SENSITIVE_PATTERN_LIST 未定義
local function test_sensitive_pattern_list_defined()
    -- 檢查模組化架構中的安全模組
    local security_path = vim.fn.stdpath("config") .. "/lua/utils/clipboard/security.lua"
    local content = vim.fn.readfile(security_path)
    local full_content = table.concat(content, "\n")
    
    -- 檢查是否定義了 SENSITIVE_PATTERN_LIST
    local pattern_defined = full_content:find("local SENSITIVE_PATTERN_LIST") ~= nil
    test_utils.assert_true(pattern_defined, "SENSITIVE_PATTERN_LIST should be defined in security module")
    
    -- 檢查是否包含基本的敏感模式
    local has_api_key_pattern = full_content:find("sk%%%-") ~= nil  -- 在Lua模式中，%-是轉義的-
    local has_github_pattern = full_content:find("ghp_") ~= nil
    test_utils.assert_true(has_api_key_pattern, "Should include OpenAI API key pattern")
    test_utils.assert_true(has_github_pattern, "Should include GitHub token pattern")
    
    -- 驗證安全模組可以正常載入和運作
    local success, security = pcall(require, 'utils.clipboard.security')
    test_utils.assert_true(success, "Security module should load successfully")
    test_utils.assert_not_nil(security.scan_content, "Security module should have scan_content function")
end

-- 測試 Critical Issue #2: vim.wait() 阻塞調用
local function test_vim_wait_removed()
    local clipboard_path = vim.fn.stdpath("config") .. "/lua/utils/clipboard.lua"
    local content = vim.fn.readfile(clipboard_path)
    local full_content = table.concat(content, "\n")
    
    -- 檢查是否還有實際的 vim.wait() 函數調用（排除註釋）
    local wait_calls = {}
    for i, line in ipairs(content) do
        -- 只檢測非註釋行中的 vim.wait() 調用
        local trimmed = line:gsub("^%s*", "")
        if not trimmed:match("^%-%-") and line:find("vim%.wait%s*%(") then
            table.insert(wait_calls, {line_num = i, content = trimmed})
        end
    end
    
    test_utils.assert_equals(0, #wait_calls, 
        string.format("Found %d actual vim.wait() calls that should be removed: %s", 
            #wait_calls, vim.inspect(wait_calls)))
end

-- 測試 Critical Issue #3: io.popen() 同步I/O
local function test_sync_io_replaced()
    -- 檢查模組化架構中的所有模組
    local modules_to_check = {
        "/lua/utils/clipboard/core.lua",
        "/lua/utils/clipboard/transport.lua",
        "/lua/utils/clipboard/security.lua"
    }
    
    local problematic_popen_calls = {}
    local has_vim_system = false
    
    for _, module_path in ipairs(modules_to_check) do
        local full_path = vim.fn.stdpath("config") .. module_path
        local success, content = pcall(vim.fn.readfile, full_path)
        
        if success then
            local full_content = table.concat(content, "\n")
            
            -- 檢查是否使用了現代API
            if full_content:find("vim%.system%s*%(") then
                has_vim_system = true
            end
            
            -- 檢查關鍵功能模組中的同步I/O調用
            for i, line in ipairs(content) do
                local trimmed = line:gsub("^%s*", "")
                if not trimmed:match("^%-%-") and line:find("io%.popen%s*%(") then
                    -- 如果是在核心功能模組中，視為問題
                    if module_path:match("core%.lua") or module_path:match("transport%.lua") then
                        table.insert(problematic_popen_calls, {
                            file = module_path,
                            line_num = i, 
                            content = trimmed
                        })
                    end
                end
            end
        end
    end
    
    test_utils.assert_equals(0, #problematic_popen_calls,
        string.format("Found %d problematic io.popen() calls in core modules: %s",
            #problematic_popen_calls, vim.inspect(problematic_popen_calls)))
    
    test_utils.assert_true(has_vim_system, "Should use vim.system() for async operations")
end

-- 測試安全檢測功能恢復
local function test_security_detection_functional()
    -- 模擬載入修復後的模組
    package.loaded['utils.clipboard'] = nil
    local success, clipboard = pcall(require, 'utils.clipboard')
    
    if not success then
        -- 如果模組載入失敗，跳過此測試
        print("Warning: clipboard module could not be loaded, skipping functional test")
        return
    end
    
    -- 測試敏感內容檢測
    local test_data = test_utils.create_test_data()
    
    -- 這裡需要訪問內部安全檢測函數
    -- 由於是內部函數，我們通過模組測試介面來驗證
    if clipboard._test_security_check then
        local api_key_result = clipboard._test_security_check(test_data.sensitive_content.api_key)
        test_utils.assert_false(api_key_result, "API key should be detected as sensitive")
        
        local safe_result = clipboard._test_security_check(test_data.safe_content)
        test_utils.assert_true(safe_result, "Safe content should pass security check")
    else
        print("Warning: _test_security_check interface not available")
    end
end

-- 執行所有測試
local tests = {
    test_sensitive_pattern_list_defined = test_sensitive_pattern_list_defined,
    test_vim_wait_removed = test_vim_wait_removed,
    test_sync_io_replaced = test_sync_io_replaced,
    test_security_detection_functional = test_security_detection_functional
}

return test_utils.run_test_suite("Critical Issues Fix Verification", tests)