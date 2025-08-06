-- 配置管理模組
-- 負責統一配置管理、版本控制和熱更新

local M = {}

-- 預設配置
local DEFAULT_CONFIG = {
    version = "2.1.0",
    enable_osc52 = false,
    security_check = true,
    max_osc52_size = 32768,
    strict_validation = true,
    performance_monitoring = true,
    -- 可插拔配置
    transport_priority = {"osc52", "system", "vim_register"},
    security_profiles = {
        enterprise = {
            enable_detailed_scan = true, 
            block_heuristic = true,
            threat_response = "block",
            audit_logging = true,
            memory_protection = true,
            content_sanitization = true,
            max_content_size = 16384,
            scan_depth = "deep"
        },
        strict = {
            enable_detailed_scan = true, 
            block_heuristic = true,
            threat_response = "warn_and_block",
            audit_logging = false,
            memory_protection = true,
            content_sanitization = false,
            max_content_size = 32768,
            scan_depth = "standard"
        },
        balanced = {
            enable_detailed_scan = true, 
            block_heuristic = false,
            threat_response = "warn",
            audit_logging = false,
            memory_protection = false,
            content_sanitization = false,
            max_content_size = 65536,
            scan_depth = "standard"
        },
        permissive = {
            enable_detailed_scan = false, 
            block_heuristic = false,
            threat_response = "log_only",
            audit_logging = false,
            memory_protection = false,
            content_sanitization = false,
            max_content_size = 131072,
            scan_depth = "basic"
        }
    },
    current_security_profile = "balanced"
}

-- 全域配置實例
local M_config = vim.deepcopy(DEFAULT_CONFIG)

-- 配置變更監聽器
local change_listeners = {}

-- 配置驗證規則
local validation_rules = {
    enable_osc52 = function(value) return type(value) == "boolean" end,
    security_check = function(value) return type(value) == "boolean" end,
    max_osc52_size = function(value) return type(value) == "number" and value > 0 and value <= 1024000 end,
    current_security_profile = function(value) 
        return type(value) == "string" and M_config.security_profiles[value] ~= nil 
    end,
    transport_priority = function(value)
        if type(value) ~= "table" then return false end
        local valid_transports = {osc52 = true, system = true, vim_register = true}
        for _, transport in ipairs(value) do
            if not valid_transports[transport] then return false end
        end
        return true
    end
}

-- 獲取配置值
function M.get(key)
    if key then
        return M_config[key]
    end
    return vim.deepcopy(M_config)
end

-- 更新配置
function M.update(updates)
    local changes = {}
    local old_config = vim.deepcopy(M_config)
    
    for key, value in pairs(updates) do
        if M._validate_config_change(key, value) then
            local old_value = M_config[key]
            M_config[key] = value
            changes[key] = {old = old_value, new = value}
        else
            vim.notify(string.format("⚠️ 無效的配置值: %s = %s", key, vim.inspect(value)), vim.log.levels.WARN)
        end
    end
    
    -- 通知變更監聽器
    for key, change in pairs(changes) do
        local listeners = change_listeners[key] or {}
        for _, listener in ipairs(listeners) do
            local success, err = pcall(listener, change.old, change.new)
            if not success then
                vim.notify(string.format("配置監聽器錯誤: %s", err), vim.log.levels.ERROR)
            end
        end
    end
    
    return changes
end

-- 註冊配置變更監聽器
function M.on_change(key, listener)
    if not change_listeners[key] then
        change_listeners[key] = {}
    end
    table.insert(change_listeners[key], listener)
end

-- 重置為預設配置
function M.reset()
    local old_config = vim.deepcopy(M_config)
    M_config = vim.deepcopy(DEFAULT_CONFIG)
    
    -- 通知所有監聽器
    for key, new_value in pairs(M_config) do
        local old_value = old_config[key]
        if old_value ~= new_value then
            local listeners = change_listeners[key] or {}
            for _, listener in ipairs(listeners) do
                pcall(listener, old_value, new_value)
            end
        end
    end
    
    return true
end

-- 驗證配置變更
function M._validate_config_change(key, value)
    local rule = validation_rules[key]
    if rule and not rule(value) then
        return false
    end
    return true
end

-- 配置遷移（版本兼容性）
function M.migrate_config(old_config)
    local migrators = {
        ["1.0.0"] = function(config) 
            -- 從 1.0.0 遷移到 2.1.0
            config.transport_priority = {"osc52", "system", "vim_register"}
            config.security_profiles = DEFAULT_CONFIG.security_profiles
            config.current_security_profile = "balanced"
            return config
        end,
        ["2.0.0"] = function(config)
            -- 從 2.0.0 遷移到 2.1.0
            if not config.current_security_profile then
                config.current_security_profile = "balanced"
            end
            return config
        end
    }
    
    local version = old_config.version or "1.0.0"
    local migrator = migrators[version]
    if migrator then
        old_config = migrator(old_config)
        old_config.version = DEFAULT_CONFIG.version
    end
    
    return old_config
end

-- 獲取配置摘要（用於顯示）
function M.get_summary()
    local profile = M_config.security_profiles[M_config.current_security_profile] or {}
    
    return {
        version = M_config.version,
        osc52_status = M_config.enable_osc52 and "✅ 啟用" or "❌ 禁用",
        security_status = M_config.security_check and "✅ 啟用" or "❌ 禁用",
        size_limit = M_config.max_osc52_size .. " bytes",
        validation = M_config.strict_validation and "✅ 啟用" or "❌ 禁用",
        monitoring = M_config.performance_monitoring and "✅ 啟用" or "❌ 禁用",
        security_profile = M_config.current_security_profile,
        transport_order = table.concat(M_config.transport_priority, " → ")
    }
end

-- 驗證完整配置
function M.validate()
    local errors = {}
    
    for key, value in pairs(M_config) do
        if not M._validate_config_change(key, value) then
            table.insert(errors, string.format("無效配置 %s: %s", key, vim.inspect(value)))
        end
    end
    
    return #errors == 0, errors
end

return M