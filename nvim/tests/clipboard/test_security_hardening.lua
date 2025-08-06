-- 安全強化測試
local test_utils = require('tests.test_utils')

-- 測試進階安全模式
local function test_advanced_security_modes()
    local config = require('utils.clipboard.config')
    local security = require('utils.clipboard.security')
    
    -- 測試企業級安全模式
    config.update({current_security_profile = "enterprise"})
    local profile = config.get().security_profiles.enterprise
    
    test_utils.assert_true(profile.enable_detailed_scan, "Enterprise mode should enable detailed scan")
    test_utils.assert_true(profile.block_heuristic, "Enterprise mode should use block heuristic")
    test_utils.assert_equals(profile.threat_response, "block", "Enterprise mode should block threats")
    test_utils.assert_true(profile.audit_logging, "Enterprise mode should enable audit logging")
    test_utils.assert_true(profile.memory_protection, "Enterprise mode should enable memory protection")
    test_utils.assert_true(profile.content_sanitization, "Enterprise mode should enable content sanitization")
end

-- 測試威脅響應處理
local function test_threat_response_handling()
    local config = require('utils.clipboard.config')
    local security = require('utils.clipboard.security')
    local test_data = test_utils.create_test_data()
    
    -- 測試嚴格模式的威脅響應
    config.update({current_security_profile = "strict"})
    local result = security.scan_content(test_data.sensitive_content.api_key)
    
    test_utils.assert_false(result.safe, "Strict mode should detect API key threat")
    test_utils.assert_not_nil(result.reason, "Should provide threat reason")
    test_utils.assert_not_nil(result.total_scan_time, "Should track scan time")
    
    -- 測試寬鬆模式
    config.update({current_security_profile = "permissive"})
    local permissive_result = security.scan_content(test_data.sensitive_content.api_key)
    
    test_utils.assert_true(permissive_result.safe, "Permissive mode should allow with log only")
end

-- 測試內容清理功能
local function test_content_sanitization()
    local config = require('utils.clipboard.config')
    local security = require('utils.clipboard.security')
    
    -- 啟用內容清理
    config.update({current_security_profile = "enterprise"})
    
    -- 測試控制字符清理
    local malicious_content = "normal text\x00\x08\x1b[31mmalicious\x07clean text"
    local result = security.scan_content(malicious_content)
    
    test_utils.assert_not_nil(result.content_sanitized, "Should indicate if content was sanitized")
end

-- 測試審計日誌記錄
local function test_audit_logging()
    local config = require('utils.clipboard.config')
    local security = require('utils.clipboard.security')
    local test_data = test_utils.create_test_data()
    
    -- 清理現有日誌
    security.clear_audit_log()
    
    -- 啟用審計日誌
    config.update({current_security_profile = "enterprise"})
    
    -- 執行掃描觸發日誌記錄
    security.scan_content(test_data.safe_content)
    security.scan_content(test_data.sensitive_content.api_key)
    
    -- 檢查日誌
    local audit_log = security.get_audit_log(10)
    test_utils.assert_true(#audit_log > 0, "Should have audit log entries")
    
    -- 檢查威脅統計
    local stats = security.get_threat_stats()
    test_utils.assert_not_nil(stats.total_events, "Should have event statistics")
    test_utils.assert_true(stats.threats_detected >= 0, "Should track detected threats")
end

-- 測試動態威脅檢測
local function test_dynamic_threat_detection()
    local security = require('utils.clipboard.security')
    
    -- 測試高熵內容
    local high_entropy_content = string.rep("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=", 5)
    local result = security.dynamic_threat_scan(high_entropy_content)
    
    test_utils.assert_not_nil(result.risk_score, "Should calculate risk score")
    test_utils.assert_not_nil(result.threat_indicators, "Should count threat indicators")
    test_utils.assert_true(result.risk_score >= 0 and result.risk_score <= 1.0, "Risk score should be between 0 and 1")
    
    -- 測試正常內容
    local normal_content = "This is normal text content without any suspicious patterns."
    local normal_result = security.dynamic_threat_scan(normal_content)
    
    test_utils.assert_true(normal_result.safe, "Normal content should be considered safe")
    test_utils.assert_true(normal_result.risk_score < 0.7, "Normal content should have low risk score")
end

-- 測試安全檔案切換
local function test_security_profile_switching()
    local security = require('utils.clipboard.security')
    
    -- 測試切換到嚴格模式
    local success, message = security.set_security_profile("strict")
    test_utils.assert_true(success, "Should successfully switch to strict profile")
    test_utils.assert_not_nil(message, "Should provide confirmation message")
    
    -- 測試無效檔案
    local invalid_success, invalid_message = security.set_security_profile("nonexistent")
    test_utils.assert_false(invalid_success, "Should fail with invalid profile")
    test_utils.assert_not_nil(invalid_message, "Should provide error message")
end

-- 測試記憶體安全管理
local function test_memory_safety()
    local state = require('utils.clipboard.state')
    
    -- 測試記憶體池分配
    local data_id = state.allocate_from_pool("test_pool", "test data")
    test_utils.assert_not_nil(data_id, "Should allocate memory pool object")
    
    -- 測試記憶體統計
    local stats = state.get_memory_stats()
    test_utils.assert_not_nil(stats.current_usage_kb, "Should provide current memory usage")
    test_utils.assert_not_nil(stats.allocations, "Should track allocations")
    test_utils.assert_true(stats.allocations > 0, "Should have recorded allocations")
    
    -- 測試記憶體清理
    local cleanup_result = state.force_memory_cleanup()
    test_utils.assert_not_nil(cleanup_result.freed, "Should report freed memory")
    
    -- 測試記憶體洩漏檢測
    local leaks = state.detect_memory_leaks()
    test_utils.assert_not_nil(leaks, "Should return leak detection results")
end

-- 測試整合安全功能
local function test_integrated_security()
    local config = require('utils.clipboard.config')
    local security = require('utils.clipboard.security')
    local state = require('utils.clipboard.state')
    
    -- 設定企業級安全模式
    config.update({current_security_profile = "enterprise"})
    
    -- 清理狀態
    security.clear_audit_log()
    state.force_memory_cleanup()
    
    -- 執行綜合測試
    local test_data = test_utils.create_test_data()
    
    -- 掃描安全內容
    local safe_result = security.scan_content(test_data.safe_content)
    test_utils.assert_true(safe_result.safe, "Safe content should pass")
    test_utils.assert_true(safe_result.audit_logged, "Should log safe scan in enterprise mode")
    
    -- 掃描危險內容
    local threat_result = security.scan_content(test_data.sensitive_content.api_key)
    test_utils.assert_false(threat_result.safe, "Threat should be blocked in enterprise mode")
    
    -- 驗證審計記錄
    local audit_log = security.get_audit_log()
    test_utils.assert_true(#audit_log >= 2, "Should have multiple audit entries")
    
    -- 驗證記憶體管理
    local memory_stats = state.get_memory_stats()
    test_utils.assert_not_nil(memory_stats.current_usage_kb, "Should track memory usage")
end

-- 執行所有測試
local tests = {
    test_advanced_security_modes = test_advanced_security_modes,
    test_threat_response_handling = test_threat_response_handling,
    test_content_sanitization = test_content_sanitization,
    test_audit_logging = test_audit_logging,
    test_dynamic_threat_detection = test_dynamic_threat_detection,
    test_security_profile_switching = test_security_profile_switching,
    test_memory_safety = test_memory_safety,
    test_integrated_security = test_integrated_security
}

return test_utils.run_test_suite("Security Hardening Tests", tests)