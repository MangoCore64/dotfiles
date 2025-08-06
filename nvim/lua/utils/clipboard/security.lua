-- 安全檢測模組
-- 負責多層防禦安全檢測、敏感內容識別和威脅防護

local M = {}

-- 敏感模式列表（從主模組移植）
local SENSITIVE_PATTERN_LIST = {
    -- OpenAI API keys
    "sk%-[a-zA-Z0-9._%-]{48,}",
    
    -- GitHub Personal Access Tokens  
    "ghp_[a-zA-Z0-9_]{36}",
    
    -- Slack tokens
    "xox[abp]%-[a-zA-Z0-9%-]{72}",
    
    -- JWT tokens (Base64 URL-safe pattern)
    "eyJ[a-zA-Z0-9_%-]+%.eyJ[a-zA-Z0-9_%-]+%.[a-zA-Z0-9_%-]+",
    
    -- Private keys
    "-----BEGIN[^-]*PRIVATE KEY-----",
    
    -- Credit card numbers (basic pattern)
    "%d%d%d%d[%s%-]?%d%d%d%d[%s%-]?%d%d%d%d[%s%-]?%d%d%d%d",
    
    -- Database connection strings
    "postgres://[^:]+:[^@]+@[^/]+",
    "mysql://[^:]+:[^@]+@[^/]+", 
    "mongodb://[^:]+:[^@]+@[^/]+",
    "redis://[^:]+:[^@]+@[^/]+",
    
    -- Additional common sensitive patterns
    "aws_access_key_id[%s]*=[%s]*[A-Z0-9]{20}",
    "aws_secret_access_key[%s]*=[%s]*[A-Za-z0-9/+=]{40}",
    "AKIA[0-9A-Z]{16}",  -- AWS Access Key ID
    
    -- Azure patterns
    "azure_[a-zA-Z0-9_]*[%s]*=[%s]*[a-zA-Z0-9+/=%-_]{20,}",
    
    -- Google API keys
    "AIza[0-9A-Za-z%-_]{35}",
    
    -- Discord bot tokens
    "[MN][A-Za-z%d]{23}%.[A-Za-z%d%-_]{6}%.[A-Za-z%d%-_]{27}",
    
    -- Stripe keys
    "sk_live_[0-9a-zA-Z]{24,}",
    "pk_live_[0-9a-zA-Z]{24,}",
    
    -- SendGrid API keys
    "SG%.[0-9A-Za-z%-_]{22}%.[0-9A-Za-z%-_]{43}"
}

-- 敏感關鍵詞列表
local SENSITIVE_KEYWORDS = {
    -- 通用敏感詞
    "password", "passwd", "pwd", "secret", "token", "api_key", "apikey", "auth",
    "private_key", "privatekey", "credential", "cred", "key", "certificate", "cert",
    -- API keys 前綴
    "sk%-", "ghp_", "gho_", "ghu_", "ghs_", "ghr_", "akia", "xoxb%-", "xoxa%-", "xoxp%-",
    "ya29%.", "1//", "AIza", "_key", "bearer ", "oauth", "jwt",
    -- 雲服務
    "aws_access_key", "aws_secret", "azure_", "gcp_", "google_", "firebase_",
    -- 數據庫
    "db_password", "database_url", "connection_string", "dsn",
    -- 其他
    "slack_", "discord_", "telegram_", "stripe_", "paypal_", "sendgrid_"
}

-- 可插拔的安全掃描器
local scanners = {}

-- 預設掃描器 - 關鍵詞檢測
local KeywordScanner = {
    name = "keyword_scanner",
    priority = 1,
    enabled = true
}

function KeywordScanner:scan(content, config)
    local lower_content = content:lower()
    for _, keyword in ipairs(SENSITIVE_KEYWORDS) do
        -- 使用轉義的關鍵詞進行安全搜索
        local escaped_keyword = keyword:gsub("([%^%$%(%)%%%%%.%[%]%*%+%-%?%{%}])", "%%%1")
        if lower_content:find(escaped_keyword, 1, true) then
            return {
                safe = false, 
                reason = "Sensitive keyword detected: " .. keyword,
                scanner = self.name,
                confidence = 0.8
            }
        end
    end
    return {safe = true, scanner = self.name}
end

-- 預設掃描器 - 模式匹配
local PatternScanner = {
    name = "pattern_scanner", 
    priority = 2,
    enabled = true
}

function PatternScanner:scan(content, config)
    for _, pattern in ipairs(SENSITIVE_PATTERN_LIST) do
        if content:find(pattern) then
            return {
                safe = false,
                reason = "Sensitive pattern detected: " .. pattern,
                scanner = self.name,
                confidence = 0.9
            }
        end
    end
    return {safe = true, scanner = self.name}
end

-- 預設掃描器 - 高熵檢測
local EntropyScanner = {
    name = "entropy_scanner",
    priority = 3, 
    enabled = true
}

function EntropyScanner:scan(content, config)
    if not config.enable_detailed_scan then
        return {safe = true, scanner = self.name, reason = "Entropy scan disabled"}
    end
    
    -- 優化的高熵檢測（O(n)複雜度）
    local suspicious_strings = {}
    
    -- 檢查Base64類似的字串
    for match in content:gmatch("[A-Za-z0-9+/=]{32,}") do
        local entropy = M._calculate_entropy(match)
        if entropy > 4.5 and #match > 40 then  -- 高熵值閾值
            table.insert(suspicious_strings, {
                string = match:sub(1, 20) .. "...",
                entropy = entropy,
                length = #match
            })
        end
    end
    
    if #suspicious_strings > 0 then
        return {
            safe = false,
            reason = string.format("High entropy strings detected: %d suspicious patterns", #suspicious_strings),
            scanner = self.name,
            confidence = 0.7,
            details = suspicious_strings
        }
    end
    
    return {safe = true, scanner = self.name}
end

-- 註冊預設掃描器
scanners["keyword"] = KeywordScanner
scanners["pattern"] = PatternScanner
scanners["entropy"] = EntropyScanner

-- 威脅響應處理器
local threat_handlers = {
    block = function(threat_result)
        return false, "BLOCKED: " .. threat_result.reason
    end,
    warn_and_block = function(threat_result)
        vim.notify("🚨 安全威脅已阻止: " .. threat_result.reason, vim.log.levels.WARN)
        return false, "BLOCKED: " .. threat_result.reason
    end,
    warn = function(threat_result)
        vim.notify("⚠️ 安全警告: " .. threat_result.reason, vim.log.levels.WARN)
        return true, "WARNING: " .. threat_result.reason
    end,
    log_only = function(threat_result)
        vim.notify("📝 安全日誌: " .. threat_result.reason, vim.log.levels.DEBUG)
        return true, "LOGGED: " .. threat_result.reason
    end
}

-- 內容清理函數
local function sanitize_content(content, profile)
    if not profile.content_sanitization then
        return content
    end
    
    -- 移除潛在危險的控制字符（保留正常的制表符、換行符、回車符）
    local cleaned_content = ""
    for i = 1, #content do
        local char = content:sub(i, i)
        local byte = string.byte(char)
        -- 保留可見字符和正常空白字符
        if byte >= 32 or byte == 9 or byte == 10 or byte == 13 then
            cleaned_content = cleaned_content .. char
        end
    end
    content = cleaned_content
    
    -- 移除ANSI escape序列
    content = content:gsub('\027%[[0-9;]*[mKHfJ]', '')
    
    -- 限制長度
    if #content > profile.max_content_size then
        content = content:sub(1, profile.max_content_size) .. "\n[內容已截斷]"
    end
    
    return content
end

-- 審計日誌記錄
local audit_log = {}
local function log_security_event(event_type, details)
    table.insert(audit_log, {
        timestamp = os.time(),
        type = event_type,
        details = details
    })
    
    -- 保持日誌大小在合理範圍內
    if #audit_log > 1000 then
        table.remove(audit_log, 1)
    end
end

-- 主要安全檢測函數（增強版）
function M.scan_content(content, config)
    config = config or require('utils.clipboard.config').get()
    
    if not config.security_check then
        return {safe = true, reason = "Security check disabled"}
    end
    
    -- 獲取安全配置檔案
    local security_profile = config.security_profiles[config.current_security_profile] or {}
    
    -- 內容預處理和清理
    local original_content = content
    content = sanitize_content(content, security_profile)
    
    -- 大小檢查
    if #content > security_profile.max_content_size then
        local threat_result = {
            safe = false,
            reason = string.format("Content size exceeds limit: %d > %d", #content, security_profile.max_content_size),
            scanner = "size_checker",
            confidence = 1.0
        }
        
        if security_profile.audit_logging then
            log_security_event("size_violation", threat_result)
        end
        
        local handler = threat_handlers[security_profile.threat_response] or threat_handlers.warn
        local allowed, message = handler(threat_result)
        return {safe = allowed, reason = message, audit_logged = security_profile.audit_logging}
    end
    
    -- 按優先級排序掃描器
    local sorted_scanners = {}
    for _, scanner in pairs(scanners) do
        if scanner.enabled then
            table.insert(sorted_scanners, scanner)
        end
    end
    
    table.sort(sorted_scanners, function(a, b) return a.priority < b.priority end)
    
    -- 執行掃描
    local scan_results = {}
    local scan_start_time = vim.uv.hrtime()
    
    for _, scanner in ipairs(sorted_scanners) do
        local scanner_start = vim.uv.hrtime()
        local result = scanner:scan(content, security_profile)
        local scanner_duration = (vim.uv.hrtime() - scanner_start) / 1e6
        
        result.scan_time = scanner_duration
        table.insert(scan_results, result)
        
        -- 如果檢測到威脅
        if not result.safe then
            if security_profile.audit_logging then
                log_security_event("threat_detected", {
                    scanner = result.scanner,
                    reason = result.reason,
                    confidence = result.confidence,
                    scan_time = scanner_duration
                })
            end
            
            -- 立即阻止模式
            if security_profile.block_heuristic then
                local handler = threat_handlers[security_profile.threat_response] or threat_handlers.block
                local allowed, message = handler(result)
                return {
                    safe = allowed,
                    reason = message,
                    scanner = result.scanner,
                    confidence = result.confidence,
                    all_results = scan_results,
                    audit_logged = security_profile.audit_logging,
                    total_scan_time = (vim.uv.hrtime() - scan_start_time) / 1e6
                }
            end
        end
    end
    
    local total_scan_time = (vim.uv.hrtime() - scan_start_time) / 1e6
    
    -- 綜合評估（如果不是立即阻止模式）
    local threat_count = 0
    local highest_confidence = 0
    local primary_threat = nil
    
    for _, result in ipairs(scan_results) do
        if not result.safe then
            threat_count = threat_count + 1
            if result.confidence and result.confidence > highest_confidence then
                highest_confidence = result.confidence
                primary_threat = result
            end
        end
    end
    
    -- 多重威脅評估邏輯
    if threat_count > 1 or highest_confidence > 0.8 then
        local aggregate_threat = {
            safe = false,
            reason = primary_threat and primary_threat.reason or "Multiple security threats detected",
            scanner = "multi_scanner",
            confidence = highest_confidence,
            threat_count = threat_count
        }
        
        if security_profile.audit_logging then
            log_security_event("multiple_threats", aggregate_threat)
        end
        
        local handler = threat_handlers[security_profile.threat_response] or threat_handlers.warn
        local allowed, message = handler(aggregate_threat)
        return {
            safe = allowed,
            reason = message,
            scanner = "multi_scanner",
            confidence = highest_confidence,
            threat_count = threat_count,
            all_results = scan_results,
            audit_logged = security_profile.audit_logging,
            total_scan_time = total_scan_time
        }
    end
    
    -- 通過所有檢查
    if security_profile.audit_logging then
        log_security_event("scan_passed", {
            scanners_run = #sorted_scanners,
            total_scan_time = total_scan_time,
            content_size = #content
        })
    end
    
    return {
        safe = true,
        reason = "Content passed all security checks",
        scanned_by = #sorted_scanners,
        all_results = scan_results,
        audit_logged = security_profile.audit_logging,
        total_scan_time = total_scan_time,
        content_sanitized = content ~= original_content
    }
end

-- 註冊自定義掃描器
function M.register_scanner(name, scanner)
    if type(scanner.scan) ~= "function" then
        error("Scanner must implement scan(content, config) method")
    end
    
    scanner.name = scanner.name or name
    scanner.priority = scanner.priority or 10
    scanner.enabled = scanner.enabled ~= false
    
    scanners[name] = scanner
    return true
end

-- 啟用/禁用掃描器
function M.set_scanner_enabled(name, enabled)
    if scanners[name] then
        scanners[name].enabled = enabled
        return true
    end
    return false
end

-- 獲取掃描器列表
function M.get_scanners()
    local result = {}
    for name, scanner in pairs(scanners) do
        result[name] = {
            name = scanner.name,
            priority = scanner.priority,
            enabled = scanner.enabled
        }
    end
    return result
end

-- 計算字串熵值（內部函數）
function M._calculate_entropy(str)
    if #str == 0 then return 0 end
    
    local char_count = {}
    local total_chars = #str
    
    -- 計算字符頻率
    for i = 1, total_chars do
        local char = str:sub(i, i)
        char_count[char] = (char_count[char] or 0) + 1
    end
    
    -- 計算熵值
    local entropy = 0
    for _, count in pairs(char_count) do
        local probability = count / total_chars
        entropy = entropy - (probability * math.log(probability, 2))
    end
    
    return entropy
end

-- 測試介面（用於單元測試）
function M._test_security_check(content)
    local result = M.scan_content(content)
    return result.safe
end

-- 獲取安全審計日誌
function M.get_audit_log(limit)
    limit = limit or 100
    local recent_logs = {}
    local start_index = math.max(1, #audit_log - limit + 1)
    
    for i = start_index, #audit_log do
        table.insert(recent_logs, audit_log[i])
    end
    
    return recent_logs
end

-- 清除審計日誌
function M.clear_audit_log()
    audit_log = {}
    return true
end

-- 設置安全檔案
function M.set_security_profile(profile_name)
    local config = require('utils.clipboard.config')
    local available_profiles = config.get().security_profiles
    
    if not available_profiles[profile_name] then
        return false, "Unknown security profile: " .. profile_name
    end
    
    config.update({current_security_profile = profile_name})
    
    log_security_event("profile_changed", {
        old_profile = config.get().current_security_profile,
        new_profile = profile_name
    })
    
    return true, "Security profile updated to: " .. profile_name
end

-- 獲取威脅統計
function M.get_threat_stats()
    local stats = {
        total_events = #audit_log,
        threats_detected = 0,
        threats_blocked = 0,
        scans_passed = 0,
        by_scanner = {},
        by_hour = {}
    }
    
    local current_hour = math.floor(os.time() / 3600)
    
    for _, event in ipairs(audit_log) do
        local event_hour = math.floor(event.timestamp / 3600)
        stats.by_hour[event_hour] = (stats.by_hour[event_hour] or 0) + 1
        
        if event.type == "threat_detected" then
            stats.threats_detected = stats.threats_detected + 1
            local scanner_name = event.details.scanner or "unknown"
            stats.by_scanner[scanner_name] = (stats.by_scanner[scanner_name] or 0) + 1
        elseif event.type == "multiple_threats" then
            stats.threats_blocked = stats.threats_blocked + 1
        elseif event.type == "scan_passed" then
            stats.scans_passed = stats.scans_passed + 1
        end
    end
    
    return stats
end

-- 動態威脅檢測（實驗性）
function M.dynamic_threat_scan(content)
    local threat_indicators = 0
    local risk_score = 0
    
    -- 異常字符分析
    local control_chars = content:gsub('[%c]', ''):len()
    if control_chars < #content then
        threat_indicators = threat_indicators + 1
        risk_score = risk_score + 0.3
    end
    
    -- 重複模式檢測
    local patterns = {}
    for match in content:gmatch('[%w%+/=]{8,}') do
        patterns[match] = (patterns[match] or 0) + 1
        if patterns[match] > 3 then
            threat_indicators = threat_indicators + 1
            risk_score = risk_score + 0.2
        end
    end
    
    -- 異常比例檢測
    local special_chars = #content - content:gsub('[^%w%s]', ''):len()
    local special_ratio = special_chars / #content
    if special_ratio > 0.4 then
        threat_indicators = threat_indicators + 1
        risk_score = risk_score + 0.4
    end
    
    return {
        risk_score = math.min(risk_score, 1.0),
        threat_indicators = threat_indicators,
        safe = risk_score < 0.7,
        reason = threat_indicators > 0 and "Dynamic analysis detected suspicious patterns" or "Content passed dynamic analysis"
    }
end

-- 診斷安全狀態
function M.diagnose()
    local config = require('utils.clipboard.config').get()
    local current_profile = config.security_profiles[config.current_security_profile] or {}
    
    return {
        scanners = M.get_scanners(),
        config = config,
        current_profile = current_profile,
        audit_log_size = #audit_log,
        threat_stats = M.get_threat_stats(),
        memory_usage = collectgarbage("count"),
        system_info = {
            platform = vim.uv.os_uname(),
            nvim_version = vim.version()
        }
    }
end

-- 記憶體安全清理（增強版）
function M.secure_cleanup()
    -- 清除敏感資料
    for i = 1, #audit_log do
        if audit_log[i].details then
            for key, value in pairs(audit_log[i].details) do
                if type(value) == "string" and (#value > 50 or key:match("content")) then
                    audit_log[i].details[key] = "[REDACTED]"
                end
            end
        end
    end
    
    -- 觸發垃圾回收
    collectgarbage("collect")
    
    log_security_event("secure_cleanup", {
        memory_freed = collectgarbage("count"),
        timestamp = os.time()
    })
    
    return true
end

return M