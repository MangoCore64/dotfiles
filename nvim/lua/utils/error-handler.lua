-- 統一錯誤處理機制
-- 提供一致的錯誤處理和用戶反饋

local M = {}

-- 錯誤級別定義
M.LEVELS = {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  CRITICAL = 4
}

-- 錯誤類型定義
M.TYPES = {
  API_ERROR = "API_ERROR",
  PLUGIN_ERROR = "PLUGIN_ERROR",
  CONFIG_ERROR = "CONFIG_ERROR",
  SECURITY_ERROR = "SECURITY_ERROR",
  PERFORMANCE_WARNING = "PERFORMANCE_WARNING"
}

-- 配置選項
local config = {
  log_file = vim.fn.stdpath("data") .. "/error.log",
  max_log_size = 1024 * 1024, -- 1MB
  enable_notifications = true,
  enable_logging = true,
  min_log_level = M.LEVELS.WARN
}

-- 內部日誌緩衝區
local log_buffer = {}
local buffer_size = 100

-- 格式化錯誤訊息
local function format_message(level, type, message, context)
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local level_name = ""
  
  for name, value in pairs(M.LEVELS) do
    if value == level then
      level_name = name
      break
    end
  end
  
  local formatted = string.format("[%s] [%s] [%s] %s", 
    timestamp, level_name, type or "UNKNOWN", message)
  
  if context then
    formatted = formatted .. "\nContext: " .. vim.inspect(context)
  end
  
  return formatted
end

-- 寫入日誌文件
local function write_to_log(formatted_message)
  if not config.enable_logging then
    return
  end
  
  -- 檢查文件大小
  local stat = vim.loop.fs_stat(config.log_file)
  if stat and stat.size > config.max_log_size then
    -- 備份舊日誌並創建新文件
    local backup_file = config.log_file .. ".old"
    vim.loop.fs_rename(config.log_file, backup_file)
  end
  
  -- 寫入日誌
  local success, err = pcall(function()
    local file = io.open(config.log_file, "a")
    if file then
      file:write(formatted_message .. "\n")
      file:close()
    end
  end)
  
  if not success then
    vim.notify("Failed to write log: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- 添加到內存緩衝區
local function add_to_buffer(formatted_message)
  table.insert(log_buffer, formatted_message)
  
  -- 保持緩衝區大小限制
  if #log_buffer > buffer_size then
    table.remove(log_buffer, 1)
  end
end

-- 主要錯誤處理函數
function M.handle(level, type, message, context, options)
  options = options or {}
  
  -- 檢查最低日誌級別
  if level < config.min_log_level then
    return
  end
  
  local formatted_message = format_message(level, type, message, context)
  
  -- 添加到內存緩衝區
  add_to_buffer(formatted_message)
  
  -- 寫入日誌文件
  write_to_log(formatted_message)
  
  -- 用戶通知
  if config.enable_notifications and not options.silent then
    local notify_level = vim.log.levels.INFO
    
    if level >= M.LEVELS.CRITICAL then
      notify_level = vim.log.levels.ERROR
    elseif level >= M.LEVELS.ERROR then
      notify_level = vim.log.levels.ERROR
    elseif level >= M.LEVELS.WARN then
      notify_level = vim.log.levels.WARN
    end
    
    -- 添加圖標
    local icon = ""
    if level >= M.LEVELS.CRITICAL then
      icon = "🚨 "
    elseif level >= M.LEVELS.ERROR then
      icon = "❌ "
    elseif level >= M.LEVELS.WARN then
      icon = "⚠️ "
    else
      icon = "ℹ️ "
    end
    
    vim.notify(icon .. message, notify_level)
  end
end

-- 便利函數
function M.debug(message, context)
  M.handle(M.LEVELS.DEBUG, M.TYPES.API_ERROR, message, context)
end

function M.info(message, context)
  M.handle(M.LEVELS.INFO, M.TYPES.API_ERROR, message, context)
end

function M.warn(message, context, options)
  M.handle(M.LEVELS.WARN, M.TYPES.API_ERROR, message, context, options)
end

function M.error(message, context, options)
  M.handle(M.LEVELS.ERROR, M.TYPES.API_ERROR, message, context, options)
end

function M.critical(message, context)
  M.handle(M.LEVELS.CRITICAL, M.TYPES.API_ERROR, message, context)
end

-- 特定類型的錯誤處理
function M.plugin_error(message, plugin_name, context)
  local full_context = { plugin = plugin_name }
  if context then
    for k, v in pairs(context) do
      full_context[k] = v
    end
  end
  M.handle(M.LEVELS.ERROR, M.TYPES.PLUGIN_ERROR, message, full_context)
end

function M.config_error(message, config_path, context)
  local full_context = { config_file = config_path }
  if context then
    for k, v in pairs(context) do
      full_context[k] = v
    end
  end
  M.handle(M.LEVELS.ERROR, M.TYPES.CONFIG_ERROR, message, full_context)
end

function M.security_error(message, context)
  M.handle(M.LEVELS.ERROR, M.TYPES.SECURITY_ERROR, message, context)
end

function M.performance_warning(message, context)
  M.handle(M.LEVELS.WARN, M.TYPES.PERFORMANCE_WARNING, message, context)
end

-- 安全包裝函數
function M.safe_call(func, error_message, context)
  local success, result = pcall(func)
  if not success then
    M.error(error_message or "Function call failed", vim.tbl_extend("force", 
      context or {}, { error = result }))
    return nil, result
  end
  return result
end

-- 獲取最近的錯誤
function M.get_recent_errors(count)
  count = count or 10
  local recent = {}
  local start_index = math.max(1, #log_buffer - count + 1)
  
  for i = start_index, #log_buffer do
    table.insert(recent, log_buffer[i])
  end
  
  return recent
end

-- 清理日誌
function M.clear_logs()
  log_buffer = {}
  if vim.fn.filereadable(config.log_file) == 1 then
    vim.fn.delete(config.log_file)
  end
  M.info("Error logs cleared")
end

-- 顯示錯誤統計
function M.show_stats()
  local stats = {
    total_entries = #log_buffer,
    log_file = config.log_file,
    log_file_exists = vim.fn.filereadable(config.log_file) == 1,
    config = config
  }
  
  print("=== Error Handler Statistics ===")
  print(vim.inspect(stats))
end

-- 配置更新
function M.configure(new_config)
  for key, value in pairs(new_config) do
    if config[key] ~= nil then
      config[key] = value
    end
  end
  M.info("Error handler configuration updated")
end

-- 健康檢查
function M.health_check()
  local issues = {}
  
  -- 檢查日誌文件權限
  local log_dir = vim.fn.fnamemodify(config.log_file, ":h")
  if vim.fn.isdirectory(log_dir) == 0 then
    table.insert(issues, "Log directory does not exist: " .. log_dir)
  end
  
  -- 檢查磁盤空間（簡單檢查）
  local stat = vim.loop.fs_stat(config.log_file)
  if stat and stat.size > config.max_log_size * 2 then
    table.insert(issues, "Log file is very large: " .. stat.size .. " bytes")
  end
  
  if #issues == 0 then
    M.info("Error handler health check passed")
    return true
  else
    for _, issue in ipairs(issues) do
      M.warn("Health check issue: " .. issue)
    end
    return false
  end
end

return M