-- 模組化重構測試
local test_utils = require('tests.test_utils')

-- 測試模組載入
local function test_modules_load()
    -- 測試所有子模組可以正確載入
    local modules = {
        'utils.clipboard',
        'utils.clipboard.init',
        'utils.clipboard.config',
        'utils.clipboard.security', 
        'utils.clipboard.state',
        'utils.clipboard.core',
        'utils.clipboard.transport',
        'utils.clipboard.utils'
    }
    
    for _, module_name in ipairs(modules) do
        local success, module = pcall(require, module_name)
        test_utils.assert_true(success, 
            string.format("Module %s should load successfully", module_name))
        test_utils.assert_not_nil(module,
            string.format("Module %s should not be nil", module_name))
    end
end

-- 測試API向後兼容性
local function test_backward_compatibility()
    -- 測試主模組和init模組的API一致性
    local clipboard = require('utils.clipboard')
    local clipboard_init = require('utils.clipboard.init')
    
    -- 檢查是否為同一個表（應該是）
    test_utils.assert_equals(clipboard, clipboard_init,
        "clipboard.lua should return the same table as clipboard/init.lua")
    
    -- 檢查所有公共API是否存在
    local required_apis = {
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
    
    for _, api_name in ipairs(required_apis) do
        test_utils.assert_not_nil(clipboard[api_name],
            string.format("API %s should exist", api_name))
        test_utils.assert_equals(type(clipboard[api_name]), "function",
            string.format("API %s should be a function", api_name))
    end
end

-- 測試配置管理
local function test_config_module()
    local config = require('utils.clipboard.config')
    
    -- 測試獲取配置
    local current_config = config.get()
    test_utils.assert_not_nil(current_config, "Config should return current configuration")
    test_utils.assert_not_nil(current_config.version, "Config should have version")
    
    -- 測試更新配置
    local original_value = config.get('security_check')
    local changes = config.update({security_check = not original_value})
    test_utils.assert_not_nil(changes.security_check, "Config update should return changes")
    
    -- 恢復原始值
    config.update({security_check = original_value})
    
    -- 測試配置驗證
    local invalid_changes = config.update({max_osc52_size = -1})
    test_utils.assert_nil(invalid_changes.max_osc52_size, 
        "Invalid config should not be accepted")
end

-- 測試狀態管理
local function test_state_module()
    local state = require('utils.clipboard.state')
    
    -- 測試狀態獲取和設置
    state.set('test_key', 'test_value')
    test_utils.assert_equals(state.get('test_key'), 'test_value',
        "State should store and retrieve values")
    
    -- 測試操作記錄
    state.record_operation('test_operation', true, {test = true})
    local stats = state.get_stats()
    test_utils.assert_true(stats.operations_count > 0,
        "Stats should track operations")
    
    -- 測試分段管理
    state.set_segments({'segment1', 'segment2', 'segment3'})
    test_utils.assert_equals(state.get_current_segment(), 'segment1',
        "Should get first segment")
    
    local success, index = state.next_segment()
    test_utils.assert_true(success, "Should move to next segment")
    test_utils.assert_equals(index, 2, "Should be at segment 2")
    
    -- 清理
    state.reset_segments()
end

-- 測試安全模組
local function test_security_module()
    local security = require('utils.clipboard.security')
    local config = require('utils.clipboard.config')
    
    -- 確保使用嚴格安全模式進行測試
    config.update({current_security_profile = "strict"})
    
    -- 測試安全掃描
    local test_data = test_utils.create_test_data()
    
    -- 測試安全內容
    local safe_result = security.scan_content(test_data.safe_content)
    test_utils.assert_true(safe_result.safe, "Safe content should pass security scan")
    
    -- 測試敏感內容檢測（在嚴格模式下應該被阻止）
    local api_key_result = security.scan_content(test_data.sensitive_content.api_key)
    test_utils.assert_false(api_key_result.safe, "API key should be detected and blocked in strict mode")
    test_utils.assert_not_nil(api_key_result.reason, "Should provide threat reason")
    
    -- 測試掃描器管理
    local scanners = security.get_scanners()
    test_utils.assert_not_nil(scanners.keyword, "Keyword scanner should exist")
    test_utils.assert_not_nil(scanners.pattern, "Pattern scanner should exist")  
    test_utils.assert_not_nil(scanners.entropy, "Entropy scanner should exist")
    
    -- 測試安全檔案功能
    local profile_success, profile_msg = security.set_security_profile("balanced")
    test_utils.assert_true(profile_success, "Should successfully switch security profile")
    
    -- 恢復預設設定
    config.update({current_security_profile = "balanced"})
end

-- 測試傳輸模組
local function test_transport_module()
    local transport = require('utils.clipboard.transport')
    
    -- 測試可用傳輸方式
    local available = transport.get_available_transports()
    test_utils.assert_not_nil(available.vim_register, 
        "Vim register transport should always be available")
    
    -- 測試傳輸內容
    local test_content = "Test clipboard content"
    local success, results = transport.send_content(test_content)
    
    -- 至少應該有vim_register成功
    test_utils.assert_true(success or (results.vim_register and results.vim_register.success),
        "At least vim register transport should succeed")
end

-- 測試核心模組
local function test_core_module()
    local core = require('utils.clipboard.core')
    
    -- 測試內容分段
    local long_content = string.rep("This is a test line.\n", 200)
    local segments, is_segmented = core.segment_content(long_content, 1000)
    
    test_utils.assert_true(is_segmented, "Long content should be segmented")
    test_utils.assert_true(#segments > 1, "Should have multiple segments")
    
    -- 測試內容安全檢查
    local is_safe, reason = core.check_content_security("Normal content")
    test_utils.assert_true(is_safe, "Normal content should be safe")
end

-- 測試工具模組
local function test_utils_module()
    local utils = require('utils.clipboard.utils')
    
    -- 測試路徑驗證
    local valid, error = utils.validate_file_path("/tmp/test.txt")
    test_utils.assert_true(valid, "Valid temp path should pass validation")
    
    local invalid, error2 = utils.validate_file_path("/etc/../etc/passwd")
    test_utils.assert_false(invalid, "Path traversal should be detected")
    
    -- 測試字串工具
    local escaped = utils.escape_lua_pattern("test.pattern[*]")
    test_utils.assert_true(escaped:find("%%%["), "Should escape pattern characters")
    
    -- 測試格式化工具
    local bytes_str = utils.format_bytes(1536)
    test_utils.assert_equals(bytes_str, "1.5 KB", "Should format bytes correctly")
    
    -- 測試系統資訊
    local sys_info = utils.get_system_info()
    test_utils.assert_not_nil(sys_info.os, "Should get OS info")
    test_utils.assert_not_nil(sys_info.nvim_version, "Should get Neovim version")
end

-- 測試整合功能
local function test_integration()
    local clipboard = require('utils.clipboard')
    
    -- 測試配置更新影響
    clipboard.configure({performance_monitoring = false})
    
    -- 測試複製操作（不會實際執行視覺選擇）
    local success = pcall(clipboard.copy_with_path)
    test_utils.assert_true(success, "Copy operation should not throw errors")
    
    -- 測試診斷功能
    local diag_success = pcall(clipboard.diagnose_clipboard)
    test_utils.assert_true(diag_success, "Diagnose should not throw errors")
    
    -- 恢復配置
    clipboard.configure({performance_monitoring = true})
end

-- 執行所有測試
local tests = {
    test_modules_load = test_modules_load,
    test_backward_compatibility = test_backward_compatibility,
    test_config_module = test_config_module,
    test_state_module = test_state_module,
    test_security_module = test_security_module,
    test_transport_module = test_transport_module,
    test_core_module = test_core_module,
    test_utils_module = test_utils_module,
    test_integration = test_integration
}

return test_utils.run_test_suite("Modular Refactor Tests", tests)