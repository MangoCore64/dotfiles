-- 終端管理模組統一 API 入口
-- 提供標準化的終端管理介面，隱藏內部實現細節
--
-- 設計特色：
-- - 統一的 API 介面：所有終端操作通過此模組
-- - 依賴注入：支援不同的終端實現
-- - 版本相容：向後相容的 API 設計
-- - 錯誤處理：統一的錯誤處理和回饋機制

local M = {}

-- 安全載入核心模組（增強錯誤處理）
local function safe_require(module_path)
  local success, module_or_error = pcall(require, module_path)
  if not success then
    vim.notify(string.format("❌ 模組載入失敗: %s - %s", module_path, tostring(module_or_error)), vim.log.levels.ERROR)
    return nil, module_or_error
  end
  return module_or_error, nil
end

local core, core_error = safe_require('utils.terminal.core')
local security, security_error = safe_require('utils.terminal.security')
local ui, ui_error = safe_require('utils.terminal.ui')
local state, state_error = safe_require('utils.terminal.state')

-- 檢查關鍵模組載入狀態
local CRITICAL_MODULES_STATUS = {
  core = {module = core, error = core_error},
  security = {module = security, error = security_error},
  ui = {module = ui, error = ui_error},
  state = {module = state, error = state_error}
}

-- 驗證關鍵模組可用性
local function validate_critical_modules()
  local missing_modules = {}
  for name, info in pairs(CRITICAL_MODULES_STATUS) do
    if not info.module then
      table.insert(missing_modules, {name = name, error = info.error})
    end
  end
  return #missing_modules == 0, missing_modules
end

-- API 版本
M.VERSION = "3.0.0"

-- 模組資訊
M.INFO = {
  name = "Terminal Management System",
  version = M.VERSION,
  description = "統一的終端管理系統，支援多種終端類型的安全管理",
  author = "Terminal Refactor Team",
  license = "MIT"
}

-- 支援的終端類型註冊表
local terminal_registry = {}

-- 標準終端配置結構
local TerminalConfig = {
  name = "",           -- 終端名稱 (必需)
  command = "",        -- 執行命令 (必需) 
  title = "",          -- 視窗標題 (可選)
  security_level = "high", -- 安全等級 (high/medium/low)
  ui_config = {}       -- UI 配置 (可選)
}

-- 註冊終端類型
function M.register_terminal(name, adapter_module)
  if not name or not adapter_module then
    error("註冊終端需要提供名稱和適配器模組")
  end
  
  -- 驗證適配器介面
  local required_methods = {"open", "close", "toggle", "is_visible", "get_status"}
  for _, method in ipairs(required_methods) do
    if type(adapter_module[method]) ~= "function" then
      error(string.format("適配器 %s 缺少必需方法: %s", name, method))
    end
  end
  
  terminal_registry[name] = adapter_module
  vim.notify(string.format("✅ 終端類型 '%s' 註冊成功", name), vim.log.levels.INFO)
end

-- 取消註冊終端類型
function M.unregister_terminal(name)
  if terminal_registry[name] then
    terminal_registry[name] = nil
    vim.notify(string.format("📋 終端類型 '%s' 已取消註冊", name), vim.log.levels.INFO)
    return true
  end
  return false
end

-- 獲取已註冊的終端類型
function M.list_registered_terminals()
  local terminals = {}
  for name, _ in pairs(terminal_registry) do
    table.insert(terminals, name)
  end
  return terminals
end

-- 統一的終端操作 API
function M.open_terminal(name, config)
  local adapter = terminal_registry[name]
  if not adapter then
    vim.notify(string.format("❌ 未知的終端類型: %s", name), vim.log.levels.ERROR)
    return false
  end
  
  return adapter.open(config)
end

function M.close_terminal(name)
  local adapter = terminal_registry[name]
  if not adapter then
    vim.notify(string.format("❌ 未知的終端類型: %s", name), vim.log.levels.ERROR)
    return false
  end
  
  return adapter.close()
end

function M.toggle_terminal(name, config)
  local adapter = terminal_registry[name]
  if not adapter then
    vim.notify(string.format("❌ 未知的終端類型: %s", name), vim.log.levels.ERROR)
    return false
  end
  
  return adapter.toggle(config)
end

function M.is_terminal_visible(name)
  local adapter = terminal_registry[name]
  if not adapter then
    return false
  end
  
  return adapter.is_visible()
end

function M.get_terminal_status(name)
  local adapter = terminal_registry[name]
  if not adapter then
    return {
      name = name,
      exists = false,
      visible = false,
      error = "未註冊的終端類型"
    }
  end
  
  return adapter.get_status()
end

-- 批次操作 API
function M.close_all_terminals()
  local results = {}
  for name, adapter in pairs(terminal_registry) do
    local success = adapter.close()
    results[name] = success
  end
  return results
end

function M.get_all_terminal_status()
  local results = {}
  for name, adapter in pairs(terminal_registry) do
    results[name] = adapter.get_status()
  end
  return results
end

-- 系統健康檢查
function M.health_check()
  local issues = {}
  local total_checks = 0
  local passed_checks = 0
  
  -- 檢查核心模組
  local core_modules = {
    {name = "core", module = core},
    {name = "security", module = security},
    {name = "ui", module = ui},
    {name = "state", module = state}
  }
  
  for _, mod_info in ipairs(core_modules) do
    total_checks = total_checks + 1
    if mod_info.module and type(mod_info.module.health_check) == "function" then
      local mod_ok, mod_issues = mod_info.module.health_check()
      if mod_ok then
        passed_checks = passed_checks + 1
      else
        vim.list_extend(issues, mod_issues or {})
      end
    else
      table.insert(issues, string.format("模組 %s 缺少健康檢查功能", mod_info.name))
    end
  end
  
  -- 檢查已註冊的終端
  for name, adapter in pairs(terminal_registry) do
    total_checks = total_checks + 1
    if type(adapter.health_check) == "function" then
      local adapter_ok, adapter_issues = adapter.health_check()
      if adapter_ok then
        passed_checks = passed_checks + 1
      else
        table.insert(issues, string.format("終端 %s 健康檢查失敗", name))
        vim.list_extend(issues, adapter_issues or {})
      end
    else
      table.insert(issues, string.format("終端 %s 缺少健康檢查功能", name))
    end
  end
  
  -- 檢查系統狀態
  total_checks = total_checks + 1
  local state_valid, state_message = state.validate_state_isolation()
  if state_valid then
    passed_checks = passed_checks + 1
  else
    table.insert(issues, "狀態隔離問題: " .. state_message)
  end
  
  local health_ok = #issues == 0
  local health_score = total_checks > 0 and (passed_checks / total_checks * 100) or 0
  
  return health_ok, issues, {
    total_checks = total_checks,
    passed_checks = passed_checks,
    health_score = health_score
  }
end

-- 安全審計
function M.security_audit()
  return security.security_audit()
end

-- 性能診斷
function M.performance_diagnostic()
  local results = {}
  
  -- 測試終端創建時間
  local start_time = vim.fn.reltime()
  local test_config = {
    name = "performance_test",
    command = "echo",
    title = "Performance Test"
  }
  
  local create_success = core.open_terminal(test_config)
  local create_time = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000 -- ms
  
  if create_success then
    core.destroy_terminal("performance_test")
  end
  
  results.terminal_creation_time_ms = create_time
  results.performance_rating = create_time < 100 and "優秀" or create_time < 200 and "良好" or "需要優化"
  
  -- 記憶體使用情況
  results.memory_usage_kb = collectgarbage("count")
  
  return results
end

-- 獲取系統資訊
function M.get_system_info()
  local info = {
    version = M.VERSION,
    module_info = M.INFO,
    registered_terminals = M.list_registered_terminals(),
    core_modules = {
      core = core ~= nil,
      security = security ~= nil,
      ui = ui ~= nil,
      state = state ~= nil
    },
    health_status = {}
  }
  
  -- 執行健康檢查
  local health_ok, health_issues, health_stats = M.health_check()
  info.health_status = {
    status = health_ok and "健康" or "有問題",
    score = health_stats.health_score,
    issues_count = #health_issues,
    total_checks = health_stats.total_checks,
    passed_checks = health_stats.passed_checks
  }
  
  return info
end

-- 除錯功能
function M.debug_info()
  local debug_data = {
    system_info = M.get_system_info(),
    performance = M.performance_diagnostic(),
    all_terminal_status = M.get_all_terminal_status()
  }
  
  vim.notify("🐛 終端管理系統除錯資訊:", vim.log.levels.INFO)
  vim.notify(vim.inspect(debug_data), vim.log.levels.INFO)
  
  return debug_data
end

-- 配置驗證工具
function M.validate_terminal_config(config)
  local required_fields = {"name", "command"}
  local issues = {}
  
  for _, field in ipairs(required_fields) do
    if not config[field] or config[field] == "" then
      table.insert(issues, string.format("缺少必需欄位: %s", field))
    end
  end
  
  -- 檢查安全等級
  if config.security_level then
    local valid_levels = {"high", "medium", "low"}
    local valid = false
    for _, level in ipairs(valid_levels) do
      if config.security_level == level then
        valid = true
        break
      end
    end
    if not valid then
      table.insert(issues, "無效的安全等級: " .. config.security_level)
    end
  end
  
  return #issues == 0, issues
end

-- 增強的自動註冊終端類型
local function auto_register_terminals()
  local registration_results = {}
  local adapters = {
    {name = 'claude', path = 'utils.terminal.adapters.claude'},
    {name = 'gemini', path = 'utils.terminal.adapters.gemini'}
  }
  
  for _, adapter_info in ipairs(adapters) do
    local success, adapter_or_error = pcall(require, adapter_info.path)
    
    if success then
      -- 驗證適配器介面完整性
      local required_methods = {"open", "close", "toggle", "is_visible", "get_status"}
      local missing_methods = {}
      
      for _, method in ipairs(required_methods) do
        if type(adapter_or_error[method]) ~= "function" then
          table.insert(missing_methods, method)
        end
      end
      
      if #missing_methods == 0 then
        local register_success, register_error = pcall(M.register_terminal, adapter_info.name, adapter_or_error)
        if register_success then
          registration_results[adapter_info.name] = {success = true, message = "註冊成功"}
        else
          registration_results[adapter_info.name] = {success = false, error = register_error, reason = "註冊失敗"}
        end
      else
        registration_results[adapter_info.name] = {
          success = false, 
          error = "介面不完整", 
          missing_methods = missing_methods,
          reason = "缺少必需方法"
        }
      end
    else
      registration_results[adapter_info.name] = {
        success = false, 
        error = adapter_or_error, 
        reason = "模組載入失敗"
      }
    end
  end
  
  return registration_results
end

-- 增強的初始化統一API
function M.setup(options)
  options = options or {}
  local verbose = options.verbose ~= false  -- 預設為verbose模式
  
  vim.notify("🚀 初始化終端管理系統 v" .. M.VERSION, vim.log.levels.INFO)
  
  -- 第一階段：驗證關鍵模組
  local modules_ok, missing_modules = validate_critical_modules()
  if not modules_ok then
    local error_msg = "❌ 關鍵模組載入失敗：\n"
    for _, mod in ipairs(missing_modules) do
      error_msg = error_msg .. string.format("  • %s: %s\n", mod.name, tostring(mod.error))
    end
    vim.notify(error_msg, vim.log.levels.ERROR)
    return false, "關鍵模組載入失敗"
  end
  
  if verbose then
    vim.notify("✅ 關鍵模組載入完成", vim.log.levels.INFO)
  end
  
  -- 第二階段：自動註冊終端
  local registration_results = auto_register_terminals()
  local successful_registrations = 0
  local total_adapters = 0
  
  for name, result in pairs(registration_results) do
    total_adapters = total_adapters + 1
    if result.success then
      successful_registrations = successful_registrations + 1
      if verbose then
        vim.notify(string.format("✅ %s 終端註冊成功", name), vim.log.levels.INFO)
      end
    else
      vim.notify(string.format("⚠️ %s 終端註冊失敗: %s", name, result.reason), vim.log.levels.WARN)
      if verbose and result.missing_methods then
        vim.notify("  缺少方法: " .. table.concat(result.missing_methods, ", "), vim.log.levels.WARN)
      end
    end
  end
  
  -- 第三階段：執行健康檢查
  local health_ok, health_issues, health_stats = M.health_check()
  
  -- 第四階段：報告初始化結果
  local init_success = modules_ok and successful_registrations > 0
  
  if init_success then
    local status_msg = string.format(
      "✅ 終端管理系統初始化完成\n" ..
      "  • 註冊終端: %d/%d\n" ..
      "  • 健康分數: %.1f%%\n" ..
      "  • 系統狀態: %s",
      successful_registrations, total_adapters,
      health_stats.health_score,
      health_ok and "健康" or "有警告"
    )
    vim.notify(status_msg, health_ok and vim.log.levels.INFO or vim.log.levels.WARN)
  else
    vim.notify("❌ 終端管理系統初始化失敗", vim.log.levels.ERROR)
  end
  
  -- 輸出健康問題（如果有且verbose模式）
  if verbose and not health_ok then
    vim.notify(string.format("發現 %d 個健康問題：", #health_issues), vim.log.levels.WARN)
    for _, issue in ipairs(health_issues) do
      vim.notify("  • " .. issue, vim.log.levels.WARN)
    end
  end
  
  return init_success, {
    modules_loaded = modules_ok,
    terminals_registered = successful_registrations,
    total_terminals = total_adapters,
    health_ok = health_ok,
    health_score = health_stats.health_score,
    registration_details = registration_results
  }
end

-- 安全暴露核心模組（用於進階使用，帶錯誤檢查）
if core then M.core = core end
if security then M.security = security end
if ui then M.ui = ui end
if state then M.state = state end

-- 提供模組可用性檢查
function M.get_module_availability()
  return {
    core = core ~= nil,
    security = security ~= nil,
    ui = ui ~= nil,
    state = state ~= nil
  }
end

-- 獲取載入錯誤詳情
function M.get_loading_errors()
  local errors = {}
  for name, info in pairs(CRITICAL_MODULES_STATUS) do
    if not info.module and info.error then
      errors[name] = tostring(info.error)
    end
  end
  return errors
end

-- 暴露配置結構（用於文檔）
M.TerminalConfig = TerminalConfig

return M