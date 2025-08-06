-- 簡化的錯誤處理機制
-- 輕量級包裝器，使用 Neovim 內建的 vim.notify

local M = {}

-- 錯誤級別映射
M.LEVELS = {
  DEBUG = vim.log.levels.DEBUG,
  INFO = vim.log.levels.INFO,
  WARN = vim.log.levels.WARN,
  ERROR = vim.log.levels.ERROR,
}

-- 敏感資訊過濾器
local function sanitize_content(content)
  if type(content) ~= "string" then
    return content
  end
  
  -- 敏感關鍵字模式（擴展版）
  local sensitive_patterns = {
    -- API keys 和 tokens
    { pattern = "sk%-[%w%-_]+", replacement = "sk-***" },
    { pattern = "ghp_[%w_]+", replacement = "ghp_***" },
    { pattern = "gho_[%w_]+", replacement = "gho_***" },
    { pattern = "ghu_[%w_]+", replacement = "ghu_***" },
    { pattern = "ghs_[%w_]+", replacement = "ghs_***" },
    { pattern = "ghr_[%w_]+", replacement = "ghr_***" },
    { pattern = "akia[%w]+", replacement = "AKIA***" },
    { pattern = "xoxb%-[%w%-]+", replacement = "xoxb-***" },
    { pattern = "xoxa%-[%w%-]+", replacement = "xoxa-***" },
    { pattern = "xoxp%-[%w%-]+", replacement = "xoxp-***" },
    
    -- 密碼和連接字串
    { pattern = "password%s*[=:]%s*[\"']([^\"']+)[\"']", replacement = "password=***" },
    { pattern = "passwd%s*[=:]%s*[\"']([^\"']+)[\"']", replacement = "passwd=***" },
    { pattern = "secret%s*[=:]%s*[\"']([^\"']+)[\"']", replacement = "secret=***" },
    { pattern = "token%s*[=:]%s*[\"']([^\"']+)[\"']", replacement = "token=***" },
    
    -- 數據庫連接字串
    { pattern = "postgres://[^:]+:[^@]+@([^/]+)", replacement = "postgres://***:***@%1" },
    { pattern = "mysql://[^:]+:[^@]+@([^/]+)", replacement = "mysql://***:***@%1" },
    { pattern = "mongodb://[^:]+:[^@]+@([^/]+)", replacement = "mongodb://***:***@%1" },
    
    -- JWT tokens
    { pattern = "eyJ[%w%-_]+%.eyJ[%w%-_]+%.[%w%-_]+", replacement = "eyJ***.eyJ***.***" },
    
    -- 私鑰標記
    { pattern = "%-%-%-%-%-BEGIN[^%-]+PRIVATE KEY%-%-%-%-%-", replacement = "-----BEGIN *** PRIVATE KEY-----" },
    { pattern = "%-%-%-%-%-END[^%-]+PRIVATE KEY%-%-%-%-%-", replacement = "-----END *** PRIVATE KEY-----" },
  }
  
  local sanitized = content
  for _, filter in ipairs(sensitive_patterns) do
    sanitized = sanitized:gsub(filter.pattern, filter.replacement)
  end
  
  return sanitized
end

-- 遞歸過濾 context 中的敏感資訊
local function sanitize_context(context)
  if type(context) ~= "table" then
    return sanitize_content(context)
  end
  
  local sanitized = {}
  for k, v in pairs(context) do
    local sanitized_key = sanitize_content(tostring(k))
    local sanitized_value
    
    if type(v) == "table" then
      sanitized_value = sanitize_context(v)  -- 遞歸處理
    else
      sanitized_value = sanitize_content(tostring(v))
    end
    
    sanitized[sanitized_key] = sanitized_value
  end
  
  return sanitized
end

-- 主要錯誤處理函數 - 增強版敏感資訊過濾
function M.handle(level, message, context, options)
  options = options or {}
  
  -- 過濾敏感資訊
  local safe_message = sanitize_content(message)
  local safe_context = context and sanitize_context(context) or nil
  
  -- 格式化訊息
  local formatted_message = safe_message
  if safe_context then
    formatted_message = formatted_message .. "\nContext: " .. vim.inspect(safe_context)
  end
  
  -- 使用 vim.notify 顯示
  if not options.silent then
    vim.notify(formatted_message, level)
  end
  
  -- 可選：記錄到檔案（未來擴展）
  if options.log_to_file then
    -- TODO: 實現日誌檔案記錄
  end
end

-- 便利函數
function M.debug(message, context)
  M.handle(M.LEVELS.DEBUG, message, context)
end

function M.info(message, context)
  M.handle(M.LEVELS.INFO, message, context)
end

function M.warn(message, context, options)
  M.handle(M.LEVELS.WARN, message, context, options)
end

function M.error(message, context, options)
  M.handle(M.LEVELS.ERROR, message, context, options)
end

-- 安全包裝函數
function M.safe_call(func, error_message, context)
  local success, result = pcall(func)
  if not success then
    M.error(error_message or "Function call failed", 
      vim.tbl_extend("force", context or {}, { error = result }))
    return nil, result
  end
  return result
end

-- 特定類型的錯誤處理（保持 API 兼容性）
function M.plugin_error(message, plugin_name, context)
  local full_context = { plugin = plugin_name }
  if context then
    for k, v in pairs(context) do
      full_context[k] = v
    end
  end
  M.error(message, full_context)
end

function M.security_error(message, context)
  M.error("🚫 " .. message, context)
end

function M.config_error(message, config_path, context)
  local full_context = { config_file = config_path }
  if context then
    for k, v in pairs(context) do
      full_context[k] = v
    end
  end
  M.error(message, full_context)
end

return M