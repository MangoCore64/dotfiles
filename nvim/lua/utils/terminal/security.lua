-- 終端安全管理模組 - 分層安全策略
-- 根據用戶配置提供不同級別的安全檢查
-- 
-- 安全級別：
-- - "basic": 基礎PATH檢查 (預設)
-- - "standard": 標準安全檢查 + 基本路徑驗證
-- - "paranoid": 企業級嚴格安全檢查
--
-- 設計理念：平衡安全性與可用性，符合Neovim生態系統慣例

local M = {}

-- 🔧 獲取用戶配置的安全級別
local function get_security_level()
  -- 支援多種配置方式
  return vim.g.terminal_security_level or 
         vim.g.terminal_security_mode or 
         os.getenv("NVIM_SECURITY_LEVEL") or
         "standard"  -- 預設為標準模式
end

-- 📦 動態載入對應的安全模組 (帶緩存最佳化)
local security_module_cache = {}
local function load_security_module()
  local level = get_security_level()
  
  -- 緩存檢查，提升效能
  if security_module_cache[level] then
    return security_module_cache[level]
  end
  
  local module
  if level == "basic" or level == "core" then
    module = require('utils.terminal.security-core')
  elseif level == "paranoid" or level == "strict" then
    module = require('utils.terminal.security-paranoid')
  else
    -- 標準模式：使用增強版的core模組
    module = require('utils.terminal.security-core')
  end
  
  -- 緩存載入的模組
  security_module_cache[level] = module
  return module
end

-- 🔒 統一的命令驗證介面
function M.validate_command(cmd_name)
  local security_module = load_security_module()
  local level = get_security_level()
  
  local valid, result, message = security_module.validate_command(cmd_name)
  
  -- 添加安全級別資訊到診斷訊息
  if not valid and message then
    message = string.format("[%s 模式] %s", level:upper(), message)
  end
  
  return valid, result, message
end

-- 🔒 統一的路徑驗證介面  
function M.validate_path_security(file_path)
  local security_module = load_security_module()
  return security_module.validate_path_security(file_path)
end

-- 🏥 統一的健康檢查介面
function M.health_check()
  local security_module = load_security_module()
  local level = get_security_level()
  
  local results = security_module.health_check()
  
  -- 添加安全級別資訊
  results._security_level = level
  results._module = security_module
  
  return results
end

-- 🔧 配置管理
function M.get_security_config()
  local level = get_security_level()
  local security_module = load_security_module()
  
  local config = {
    level = level,
    module = level == "paranoid" and "security-paranoid" or "security-core"
  }
  
  -- 如果模組支援，添加詳細配置
  if security_module.get_security_config then
    local module_config = security_module.get_security_config()
    config = vim.tbl_extend("force", config, module_config)
  end
  
  return config
end

-- 🔧 設定安全級別
function M.set_security_level(level)
  local valid_levels = { "basic", "core", "standard", "paranoid", "strict" }
  
  if not vim.tbl_contains(valid_levels, level) then
    vim.notify(string.format("無效的安全級別: %s。有效選項: %s", 
      level, table.concat(valid_levels, ", ")), vim.log.levels.ERROR)
    return false
  end
  
  vim.g.terminal_security_level = level
  
  -- 清除模組緩存以強制重新載入
  package.loaded['utils.terminal.security-core'] = nil
  package.loaded['utils.terminal.security-paranoid'] = nil
  security_module_cache = {} -- 清空本地緩存
  
  vim.notify(string.format("🔒 安全級別已設定為: %s", level:upper()), vim.log.levels.INFO)
  return true
end

-- 🔍 安全級別資訊
function M.get_security_info()
  local level = get_security_level()
  local info = {
    current_level = level,
    available_levels = {
      { name = "basic", description = "基礎PATH檢查，最高相容性" },
      { name = "standard", description = "標準安全檢查，平衡安全性與易用性 (預設)" },
      { name = "paranoid", description = "企業級嚴格檢查，最高安全性" }
    },
    config_methods = {
      "vim.g.terminal_security_level = 'standard'",
      "vim.g.terminal_security_mode = 'standard'", 
      "export NVIM_SECURITY_LEVEL=standard"
    }
  }
  
  return info
end

-- 🛡️ 安全審計功能
function M.security_audit()
  local level = get_security_level()
  local security_module = load_security_module()
  
  vim.notify(string.format("🔍 開始終端安全審計 [%s 模式]...", level:upper()), vim.log.levels.INFO)
  
  -- 執行模組特定的審計
  if security_module.security_audit then
    return security_module.security_audit()
  else
    -- 基礎審計
    local health = M.health_check()
    local all_ok = true
    
    for tool, result in pairs(health) do
      if type(result) == "table" and result.available ~= nil then
        if not result.available then
          all_ok = false
          vim.notify(string.format("⚠️  工具 '%s' 不可用: %s", tool, result.error), vim.log.levels.WARN)
        end
      end
    end
    
    if all_ok then
      vim.notify("✅ 安全審計通過：所有工具正常", vim.log.levels.INFO)
    end
    
    return all_ok, {}
  end
end

-- 🔒 統一的安全配置驗證介面
function M.validate_security_config()
  local security_module = load_security_module()
  local level = get_security_level()
  
  if security_module.validate_security_config then
    local valid, issues = security_module.validate_security_config()
    -- 添加安全級別資訊到診斷結果
    if not valid and issues then
      for i, issue in ipairs(issues) do
        issues[i] = string.format("[%s模式] %s", level:upper(), issue)
      end
    end
    return valid, issues
  else
    -- 基礎實現：簡單的健康檢查
    local health = M.health_check()
    local issues = {}
    
    if health._health_status ~= "healthy" then
      for tool, status in pairs(health) do
        if type(status) == "table" and status.available == false then
          table.insert(issues, string.format("工具 '%s' 不可用: %s", tool, status.error))
        end
      end
    end
    
    return #issues == 0, issues
  end
end

-- 向後相容性：提供舊API的別名
M.get_safe_command = function(cmd_name)
  local security_module = load_security_module()
  if security_module.get_safe_command then
    return security_module.get_safe_command(cmd_name)
  else
    -- 基本實現
    local valid, result = M.validate_command(cmd_name)
    if valid then
      return result, nil
    else
      return nil, result
    end
  end
end

return M