-- Simplified Test Runner for Clipboard Functionality
-- Follows Linus principle: "Do one thing well"

local test_runner = {}

-- Setup test environment
function test_runner.setup()
    -- Ensure test mode
    _G.TEST_MODE = true
    
    -- Add project root to runtime path
    local config_dir = vim.fn.stdpath("config")
    vim.opt.rtp:prepend(config_dir)
    
    print("Simplified test environment initialized")
end

-- Available clipboard tests
local clipboard_tests = {
    "tests/clipboard/test_critical_fixes.lua",
    "tests/clipboard/test_security_hardening.lua", 
    "tests/clipboard/test_api_compatibility.lua",
    "tests/clipboard/test_modular_refactor.lua"
}

-- Run clipboard tests
function test_runner.run_clipboard_tests()
    test_runner.setup()
    
    print("Running clipboard functionality tests...")
    
    local passed = 0
    local total = #clipboard_tests
    
    for _, test_file in ipairs(clipboard_tests) do
        local file_path = vim.fn.stdpath("config") .. "/" .. test_file
        if vim.fn.filereadable(file_path) == 1 then
            print("Running: " .. test_file)
            local ok, result = pcall(dofile, file_path)
            if ok then
                passed = passed + 1
                print("✓ PASSED: " .. test_file)
            else
                print("✗ FAILED: " .. test_file .. " - " .. tostring(result))
            end
        else
            print("⚠ SKIPPED: " .. test_file .. " (file not found)")
        end
    end
    
    print(string.format("\nTest Results: %d/%d passed", passed, total))
    return passed == total
end

-- Run all available tests (currently just clipboard)
function test_runner.run_all()
    return test_runner.run_clipboard_tests()
end

-- Health check function
function test_runner.health_check()
    test_runner.setup()
    
    print("Performing configuration health check...")
    
    -- Check if clipboard module exists
    local clipboard_ok = pcall(require, "utils.clipboard")
    if clipboard_ok then
        print("✓ Clipboard module loaded successfully")
    else
        print("✗ Clipboard module failed to load")
        return false
    end
    
    -- Check if essential files exist
    local config_dir = vim.fn.stdpath("config")
    local essential_files = {
        "lua/utils/clipboard.lua",
        "lua/mappings.lua",
        "lua/plugins/init.lua"
    }
    
    for _, file in ipairs(essential_files) do
        if vim.fn.filereadable(config_dir .. "/" .. file) == 1 then
            print("✓ " .. file .. " exists")
        else
            print("✗ " .. file .. " missing")
            return false
        end
    end
    
    print("✓ Health check passed")
    return true
end

-- Main entry point
function test_runner.main()
    local args = vim.fn.argv()
    
    if vim.tbl_contains(args, "--health") then
        test_runner.health_check()
    elseif vim.tbl_contains(args, "--clipboard") then
        test_runner.run_clipboard_tests()
    else
        test_runner.run_all()
    end
end

-- Auto-run if called directly
if not _G.TEST_MODE then
    test_runner.main()
end

return test_runner