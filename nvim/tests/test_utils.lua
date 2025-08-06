-- 測試工具模組
local test_utils = {}

-- 簡單的斷言函數
function test_utils.assert_true(condition, message)
    if not condition then
        error(message or "Assertion failed: expected true")
    end
end

function test_utils.assert_false(condition, message)
    if condition then
        error(message or "Assertion failed: expected false")
    end
end

function test_utils.assert_equals(expected, actual, message)
    if expected ~= actual then
        error(string.format("%s: expected '%s', got '%s'", 
            message or "Assertion failed", tostring(expected), tostring(actual)))
    end
end

function test_utils.assert_not_nil(value, message)
    if value == nil then
        error(message or "Assertion failed: expected not nil")
    end
end

function test_utils.assert_nil(value, message)
    if value ~= nil then
        error(string.format("%s: expected nil, got '%s'", 
            message or "Assertion failed", tostring(value)))
    end
end

-- 性能測試工具
function test_utils.measure_time(func, ...)
    local start_time = vim.uv.hrtime()
    local result = func(...)
    local end_time = vim.uv.hrtime()
    local duration = (end_time - start_time) / 1e6 -- 轉換為毫秒
    return result, duration
end

-- 執行測試套件
function test_utils.run_test_suite(name, tests)
    local results = {
        name = name,
        total = 0,
        passed = 0,
        failed = 0,
        errors = {}
    }
    
    print(string.format("Running test suite: %s", name))
    
    for test_name, test_func in pairs(tests) do
        results.total = results.total + 1
        
        local success, error_msg = pcall(test_func)
        if success then
            results.passed = results.passed + 1
            print(string.format("  ✓ %s", test_name))
        else
            results.failed = results.failed + 1
            results.errors[test_name] = error_msg
            print(string.format("  ✗ %s: %s", test_name, error_msg))
        end
    end
    
    print(string.format("Results: %d/%d passed", results.passed, results.total))
    return results
end

-- Mock 系統函數
function test_utils.mock_system_calls()
    local original_system = vim.system
    local original_fn_system = vim.fn.system
    
    local mock_responses = {}
    
    local mock = {
        -- 設置 mock 響應
        set_response = function(command, response)
            mock_responses[command] = response
        end,
        
        -- 恢復原始函數
        restore = function()
            vim.system = original_system
            vim.fn.system = original_fn_system
        end
    }
    
    -- Mock vim.system
    vim.system = function(cmd, opts, callback)
        local command_str = table.concat(cmd, " ")
        local response = mock_responses[command_str] or {code = 0, stdout = "", stderr = ""}
        
        if callback then
            vim.schedule(function()
                callback(response)
            end)
        else
            return response
        end
    end
    
    -- Mock vim.fn.system
    vim.fn.system = function(cmd)
        local response = mock_responses[cmd] or ""
        return response
    end
    
    return mock
end

-- 創建測試數據
function test_utils.create_test_data()
    return {
        safe_content = [[
function hello_world()
    print("Hello, World!")
    return true
end
        ]],
        
        sensitive_content = {
            api_key = "sk-abcdefghijklmnopqrstuvwxyz123456789012345678901234",
            github_token = "ghp_abcdefghijklmnopqrstuvwxyz123456789012",
            slack_token = "xoxb-FAKE-1234567890-1234567890123-abcdefghijklmnopqrstuvwx",
            database_url = "postgres://user:password@localhost:5432/database",
            private_key = "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFA...",
            jwt_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        },
        
        large_content = string.rep("line " .. string.rep("content ", 100) .. "\n", 1000)
    }
end

return test_utils
