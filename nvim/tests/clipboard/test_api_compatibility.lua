-- API 兼容性測試
local test_utils = require('tests.test_utils')

-- 測試所有公共API函數是否可用
local function test_public_api_available()
    local clipboard = require('utils.clipboard')
    
    -- 檢查所有公共函數是否存在
    local required_functions = {
        "copy_with_path",
        "copy_file_reference", 
        "copy_next_segment",
        "copy_with_path_compressed",
        "copy_to_file_only",
        "send_to_claude",
        "diagnose_clipboard",
        "enable_osc52_safely",
        "configure",
        "show_config"
    }
    
    for _, func_name in ipairs(required_functions) do
        test_utils.assert_not_nil(clipboard[func_name], 
            string.format("Public API function '%s' should be available", func_name))
        test_utils.assert_true(type(clipboard[func_name]) == "function",
            string.format("'%s' should be a function, got %s", func_name, type(clipboard[func_name])))
    end
end

-- 測試API調用不會出錯
local function test_api_calls_no_errors()
    local clipboard = require('utils.clipboard')
    
    -- 測試無參數調用
    test_utils.assert_true(pcall(clipboard.copy_with_path), 
        "copy_with_path() should not throw errors")
    
    test_utils.assert_true(pcall(clipboard.copy_file_reference), 
        "copy_file_reference() should not throw errors")
    
    test_utils.assert_true(pcall(clipboard.show_config), 
        "show_config() should not throw errors")
    
    test_utils.assert_true(pcall(clipboard.diagnose_clipboard), 
        "diagnose_clipboard() should not throw errors")
end

-- 測試配置API
local function test_config_api()
    local clipboard = require('utils.clipboard')
    
    -- 測試設置配置
    local success = pcall(clipboard.configure, {
        enable_osc52 = false,
        security_check = true
    })
    test_utils.assert_true(success, "configure should work with valid config")
    
    -- 測試顯示配置
    test_utils.assert_true(pcall(clipboard.show_config), 
        "show_config should work after set_config")
end

-- 測試現代API使用情況
local function test_modern_api_usage()
    -- 檢查模組化架構中的所有模組
    local modules_to_check = {
        "/lua/utils/clipboard/core.lua",
        "/lua/utils/clipboard/transport.lua", 
        "/lua/utils/clipboard/security.lua",
        "/lua/utils/clipboard/state.lua",
        "/lua/utils/clipboard/utils.lua"
    }
    
    local has_modern_hrtime = false
    local has_modern_os_uname = false
    local has_vim_system = false
    local has_deprecated_loop = false
    
    for _, module_path in ipairs(modules_to_check) do
        local full_path = vim.fn.stdpath("config") .. module_path
        local success, content = pcall(vim.fn.readfile, full_path)
        
        if success then
            local full_content = table.concat(content, "\n")
            
            -- 檢查現代API使用
            if full_content:find("vim%.uv%.hrtime") then
                has_modern_hrtime = true
            end
            if full_content:find("vim%.uv%.os_uname") then
                has_modern_os_uname = true
            end
            if full_content:find("vim%.system") then
                has_vim_system = true
            end
            
            -- 檢查是否有過時的API
            if full_content:find("vim%.loop%.") then
                has_deprecated_loop = true
            end
        end
    end
    
    -- 檢查是否使用現代API
    test_utils.assert_true(has_modern_hrtime, 
        "Should use vim.uv.hrtime() in at least one module")
    
    test_utils.assert_true(has_modern_os_uname, 
        "Should use vim.uv.os_uname() in at least one module")
    
    test_utils.assert_true(has_vim_system, 
        "Should use vim.system() for async operations")
    
    -- 確保沒有使用過時的API
    test_utils.assert_false(has_deprecated_loop, 
        "Should not use any deprecated vim.loop APIs")
end

-- 測試異步操作
local function test_async_operations()
    local clipboard = require('utils.clipboard')
    
    -- 模擬異步環境
    local async_completed = false
    vim.schedule(function()
        -- 測試異步調用不會阻塞
        local start_time = vim.uv.hrtime()
        clipboard.copy_with_path()
        local elapsed = (vim.uv.hrtime() - start_time) / 1e6
        
        -- 異步操作應該立即返回（不超過10ms）
        if elapsed < 10 then
            async_completed = true
        end
    end)
    
    -- 等待異步操作完成
    local timeout = 0
    while not async_completed and timeout < 100 do
        vim.wait(10, function() return async_completed end)
        timeout = timeout + 10
    end
    
    test_utils.assert_true(async_completed, "Async operations should complete without blocking")
end

-- 執行所有測試
local tests = {
    test_public_api_available = test_public_api_available,
    test_api_calls_no_errors = test_api_calls_no_errors,
    test_config_api = test_config_api,
    test_modern_api_usage = test_modern_api_usage,
    test_async_operations = test_async_operations
}

return test_utils.run_test_suite("API Compatibility Tests", tests)