-- 基於 plenary.nvim 的測試運行器
local plenary_dir = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
vim.opt.rtp:prepend(plenary_dir)

local test_runner = {}

-- 設置測試環境
function test_runner.setup()
    -- 確保測試模式
    _G.TEST_MODE = true
    
    -- 添加項目根目錄到運行時路徑
    local config_dir = vim.fn.stdpath("config")
    vim.opt.rtp:prepend(config_dir)
    
    -- 禁用不需要的插件
    vim.g.loaded_clipboard_test = true
    
    print("Test environment initialized")
end

-- 運行所有測試
function test_runner.run_all()
    test_runner.setup()
    
    local test_files = {
        "tests/clipboard/test_critical_fixes.lua",
        "tests/clipboard/test_security.lua", 
        "tests/clipboard/test_performance.lua",
        "tests/clipboard/test_api_compatibility.lua",
        -- 新增終端管理測試
        "tests/terminal/test_security_fixes.lua",
        "tests/terminal/test_claude_security.lua",
        "tests/terminal/test_baseline_backup.lua"
    }
    
    local results = {}
    local total_tests = 0
    local passed_tests = 0
    
    for _, test_file in ipairs(test_files) do
        print(string.format("\n=== Running %s ===", test_file))
        
        local test_path = vim.fn.stdpath("config") .. "/" .. test_file
        if vim.fn.filereadable(test_path) == 1 then
            local success, test_result = pcall(dofile, test_path)
            if success and test_result then
                results[test_file] = test_result
                total_tests = total_tests + (test_result.total or 0)
                passed_tests = passed_tests + (test_result.passed or 0)
            else
                print(string.format("Failed to run test: %s", test_file))
                results[test_file] = {total = 0, passed = 0, errors = {success and "Unknown error" or test_result}}
            end
        else
            print(string.format("Test file not found: %s", test_file))
        end
    end
    
    -- 輸出總結
    print(string.format("\n=== Test Summary ==="))
    print(string.format("Total tests: %d", total_tests))
    print(string.format("Passed: %d", passed_tests))
    print(string.format("Failed: %d", total_tests - passed_tests))
    print(string.format("Success rate: %.1f%%", total_tests > 0 and (passed_tests / total_tests * 100) or 0))
    
    return results
end

-- 終端測試分類（更新以支援所有階段）
local terminal_test_categories = {
    -- 基本分類
    security = {
        "tests/terminal/test_security_fixes.lua",
        "tests/terminal/test_claude_security.lua"
    },
    baseline = {
        "tests/terminal/test_baseline_backup.lua"
    },
    state = {
        "tests/terminal/test_state_management.lua",
        "tests/terminal/test_state_isolation.lua"
    },
    compatibility = {
        "tests/terminal/test_backward_compatibility.lua"
    },
    core = {
        "tests/terminal/test_ui_module.lua"
    },
    api = {
        "tests/terminal/test_phase2_complete.lua"
    },
    gemini = {
        "tests/terminal/test_gemini_refactor.lua"
    },
    claude = {
        "tests/terminal/test_claude_upgrade.lua"
    },
    consistency = {
        "tests/terminal/test_backward_compatibility.lua"
    },
    integration = {
        "tests/terminal/integration/"
    },
    manager = {
        "tests/terminal/integration/"
    },
    performance = {
        "tests/terminal/performance/"
    },
    monitoring = {
        "tests/terminal/monitoring/"
    },
    
    -- 階段性測試
    phase0 = {
        "tests/terminal/test_security_fixes.lua",
        "tests/terminal/test_claude_security.lua", 
        "tests/terminal/test_baseline_backup.lua"
    },
    phase1 = {
        "tests/terminal/test_state_management.lua",
        "tests/terminal/test_state_isolation.lua",
        "tests/terminal/test_backward_compatibility.lua"
    },
    phase2 = {
        "tests/terminal/test_ui_module.lua",
        "tests/terminal/test_phase2_complete.lua"
    },
    phase3 = {
        "tests/terminal/test_gemini_refactor.lua"
    },
    phase4 = {
        "tests/terminal/test_claude_upgrade.lua",
        "tests/terminal/test_backward_compatibility.lua"
    },
    phase5 = {
        "tests/terminal/integration/"
    },
    phase6 = {
        "tests/terminal/monitoring/"
    },
    
    -- 綜合測試
    final = {
        "tests/terminal/test_security_fixes.lua",
        "tests/terminal/test_claude_security.lua", 
        "tests/terminal/test_baseline_backup.lua",
        "tests/terminal/test_state_management.lua",
        "tests/terminal/test_state_isolation.lua",
        "tests/terminal/test_backward_compatibility.lua",
        "tests/terminal/test_ui_module.lua",
        "tests/terminal/test_phase2_complete.lua",
        "tests/terminal/test_gemini_refactor.lua",
        "tests/terminal/test_claude_upgrade.lua",
        "tests/terminal/integration/",
        "tests/terminal/monitoring/"
    }
}

-- 運行特定測試
function test_runner.run_test(test_name)
    test_runner.setup()
    local test_path = vim.fn.stdpath("config") .. "/tests/clipboard/" .. test_name .. ".lua"
    
    if vim.fn.filereadable(test_path) == 1 then
        print(string.format("Running test: %s", test_name))
        return dofile(test_path)
    else
        error(string.format("Test file not found: %s", test_path))
    end
end

-- 運行終端測試分類
function test_runner.run_terminal_category(category)
    test_runner.setup()
    
    local test_files = terminal_test_categories[category]
    if not test_files then
        error(string.format("Unknown terminal test category: %s", category))
    end
    
    local results = {}
    local total_tests = 0
    local passed_tests = 0
    
    print(string.format("\n=== Running Terminal Tests: %s ===", category))
    
    for _, test_file in ipairs(test_files) do
        print(string.format("\n--- Running %s ---", test_file))
        
        local test_path = vim.fn.stdpath("config") .. "/" .. test_file
        if vim.fn.filereadable(test_path) == 1 then
            local success, test_result = pcall(dofile, test_path)
            if success and test_result then
                results[test_file] = test_result
                total_tests = total_tests + (test_result.total or 0)
                passed_tests = passed_tests + (test_result.passed or 0)
            else
                print(string.format("Failed to run test: %s", test_file))
                results[test_file] = {total = 0, passed = 0, errors = {success and "Unknown error" or test_result}}
            end
        else
            print(string.format("Test file not found: %s", test_file))
        end
    end
    
    -- 輸出分類總結
    print(string.format("\n=== Terminal Test Category '%s' Summary ===", category))
    print(string.format("Total tests: %d", total_tests))
    print(string.format("Passed: %d", passed_tests))
    print(string.format("Failed: %d", total_tests - passed_tests))
    print(string.format("Success rate: %.1f%%", total_tests > 0 and (passed_tests / total_tests * 100) or 0))
    
    return results
end

return test_runner