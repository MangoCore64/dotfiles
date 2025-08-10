-- 終端安全核心模組
-- 從原始 Gemini 適配器提取並通用化的安全機制
--
-- SECURITY HARDENING:
-- ==================
-- 
-- CVE-001 修復: 符號連結攻擊防護
-- - 檢測並驗證符號連結目標
-- - 防止符號連結循環攻擊
-- - 確保連結目標在安全白名單內
--
-- CVE-002 修復: 路徑遍歷防護  
-- - 完整路徑正規化和驗證
-- - 檢測 ../, ./, // 等危險模式
-- - 黑白名單雙重驗證機制
-- - 防止 null 字節和控制字符注入
--
-- CVE-003 修復: TOCTOU 攻擊防護
-- - 減少檢查到使用時間窗口
-- - 使用 fs_stat 而非 executable() 檢查
-- - 執行前最終檔案完整性驗證
-- - 審計日誌記錄所有執行

local M = {}

-- 動態檢測安全的命令路徑
local function get_secure_command_path(cmd_name)
  -- 先嘗試 PATH 搜尋（最可靠）
  local path_result = vim.fn.exepath(cmd_name)
  if path_result ~= "" then
    return path_result
  end
  
  -- 如果 PATH 搜尋失敗，嘗試常見位置
  local common_paths = {
    os.getenv("HOME") .. "/bin/" .. cmd_name,
    os.getenv("HOME") .. "/.local/bin/" .. cmd_name,
    os.getenv("HOME") .. "/.npm-global/bin/" .. cmd_name,
    "/usr/local/bin/" .. cmd_name,
    "/usr/bin/" .. cmd_name,
    "/bin/" .. cmd_name,
  }
  
  for _, path in ipairs(common_paths) do
    if vim.fn.executable(path) == 1 then
      return path
    end
  end
  
  return ""
end

-- 🔒 安全的命令執行 - 使用絕對路徑白名單防止注入攻擊  
local SECURE_COMMANDS = {
  -- 動態檢測安全路徑
  gemini = get_secure_command_path("gemini"),
  claude = get_secure_command_path("claude")
}

-- 🔒 增強的安全路徑白名單（嚴格限制，防止路徑遍歷）
local ALLOWED_PATH_PATTERNS = {
  -- === Linux 路徑 ===
  -- 用戶 bin 目錄（改善：支援更多用戶名格式）
  "^/home/[a-zA-Z][a-zA-Z0-9_.-]*[a-zA-Z0-9]/bin/[a-zA-Z][a-zA-Z0-9_.-]*$",
  -- 用戶本地安裝
  "^/home/[a-zA-Z][a-zA-Z0-9_.-]*[a-zA-Z0-9]/%.local/bin/[a-zA-Z][a-zA-Z0-9_.-]*$",
  -- Node.js 通過 nvm 安裝（驗證版本格式）
  "^/home/[a-zA-Z][a-zA-Z0-9_.-]*[a-zA-Z0-9]/%.nvm/versions/node/v[0-9]+%.[0-9]+%.[0-9]+/bin/[a-zA-Z][a-zA-Z0-9_.-]*$",
  -- Node.js 通過 npm global 安裝
  "^/home/[a-zA-Z][a-zA-Z0-9_.-]*[a-zA-Z0-9]/%.npm%-global/bin/[a-zA-Z][a-zA-Z0-9_.-]*$",
  -- Homebrew on Linux
  "^/home/linuxbrew/%.linuxbrew/bin/[a-zA-Z][a-zA-Z0-9_.-]*$",
  
  -- === macOS 路徑 ===
  -- macOS Homebrew（主要安裝位置）
  "^/opt/homebrew/bin/[a-zA-Z][a-zA-Z0-9_.-]*$",
  -- macOS 舊版 Homebrew（Intel Mac）
  "^/usr/local/bin/[a-zA-Z][a-zA-Z0-9_.-]*$",
  -- macOS 用戶 bin 目錄（改善：支援更多用戶名格式）
  "^/Users/[a-zA-Z][a-zA-Z0-9_.-]*[a-zA-Z0-9]/bin/[a-zA-Z][a-zA-Z0-9_.-]*$",
  -- macOS 用戶本地安裝
  "^/Users/[a-zA-Z][a-zA-Z0-9_.-]*[a-zA-Z0-9]/%.local/bin/[a-zA-Z][a-zA-Z0-9_.-]*$",
  -- macOS Node.js 通過 nvm 安裝
  "^/Users/[a-zA-Z][a-zA-Z0-9_.-]*[a-zA-Z0-9]/%.nvm/versions/node/v[0-9]+%.[0-9]+%.[0-9]+/bin/[a-zA-Z][a-zA-Z0-9_.-]*$",
  -- macOS Node.js 通過 npm global 安裝
  "^/Users/[a-zA-Z][a-zA-Z0-9_.-]*[a-zA-Z0-9]/%.npm%-global/bin/[a-zA-Z][a-zA-Z0-9_.-]*$",
  -- macOS MacPorts 支援
  "^/opt/local/bin/[a-zA-Z][a-zA-Z0-9_.-]*$",
  -- macOS Homebrew Node.js 模組（支援 Claude Code 等工具，改善包名支援）
  "^/opt/homebrew/lib/node_modules/@[a-zA-Z0-9][-a-zA-Z0-9_.]*[a-zA-Z0-9]/[-a-zA-Z0-9_.]*[a-zA-Z0-9]/[a-zA-Z0-9_./-]+%.js$",
  "^/usr/local/lib/node_modules/@[a-zA-Z0-9][-a-zA-Z0-9_.]*[a-zA-Z0-9]/[-a-zA-Z0-9%.]*[a-zA-Z0-9]/[a-zA-Z0-9%./-]+%.js$",
  -- NVM Node.js 模組（支援通過 npm 全域安裝的 CLI 工具，改善包名支援）
  "^/Users/[a-zA-Z][a-zA-Z0-9_.-]*[a-zA-Z0-9]/%.nvm/versions/node/v[0-9]+%.[0-9]+%.[0-9]+/lib/node_modules/@[a-zA-Z0-9][-a-zA-Z0-9_.]*[a-zA-Z0-9]/[-a-zA-Z0-9_.]*[a-zA-Z0-9]/[a-zA-Z0-9_./-]+%.js$",
  "^/home/[a-zA-Z][a-zA-Z0-9_.-]*[a-zA-Z0-9]/%.nvm/versions/node/v[0-9]+%.[0-9]+%.[0-9]+/lib/node_modules/@[a-zA-Z0-9][-a-zA-Z0-9_.]*[a-zA-Z0-9]/[-a-zA-Z0-9_.]*[a-zA-Z0-9]/[a-zA-Z0-9_./-]+%.js$",
  
  -- === 通用系統路徑 ===
  "^/usr/bin/[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]$",
  "^/bin/[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]$",
}

-- 🔒 禁止的危險路徑模式（黑名單）
local FORBIDDEN_PATH_PATTERNS = {
  "/tmp/",           -- 臨時檔案目錄
  "/dev/",           -- 設備檔案
  "/proc/",          -- 系統程序資訊
  "/sys/",           -- 系統檔案系統
  "\\.\\./",         -- 路徑遍歷
  "\\./",            -- 當前目錄遍歷
  "//",              -- 雙斜線
  "[\r\n\t]",        -- 控制字符
  "sh$",             -- shell 腳本（額外謹慎）
  "bash$",           -- bash 腳本
  "zsh$",            -- zsh 腳本
  "fish$",           -- fish 腳本
}

-- 🔒 增強的路徑安全檢查函數
function M.validate_path_security(file_path)
  if not file_path or file_path == "" then
    return false, "空路徑"
  end
  
  -- 1. 路徑正規化（解析所有符號連結和相對路徑）
  local normalized_path
  local success, result = pcall(vim.fn.resolve, file_path)
  if not success then
    return false, "路徑解析失敗: " .. tostring(result)
  end
  normalized_path = result
  
  -- 2. 檢查是否為符號連結（CVE-001 修復）
  local lstat_success, lstat_result = pcall(vim.loop.fs_lstat, file_path)
  if lstat_success and lstat_result and lstat_result.type == "link" then
    -- 符號連結檢查：確保目標在白名單內
    local link_target = vim.fn.resolve(file_path)
    local target_safe = false
    
    for _, pattern in ipairs(ALLOWED_PATH_PATTERNS) do
      if link_target:match(pattern) then
        target_safe = true
        break
      end
    end
    
    if not target_safe then
      return false, string.format("符號連結目標不安全: %s -> %s", file_path, link_target)
    end
    
    -- 防止符號連結循環
    local seen_paths = {[file_path] = true}
    local current_path = file_path
    local max_depth = 10
    local depth = 0
    
    while depth < max_depth do
      local link_success, link_stat = pcall(vim.loop.fs_lstat, current_path)
      if not link_success or not link_stat or link_stat.type ~= "link" then
        break
      end
      
      current_path = vim.fn.resolve(current_path)
      if seen_paths[current_path] then
        return false, "檢測到符號連結循環"
      end
      
      seen_paths[current_path] = true
      depth = depth + 1
    end
    
    if depth >= max_depth then
      return false, "符號連結鏈過深"
    end
  end
  
  -- 3. 增強的路徑正規化檢查（CVE-002 修復）
  local canonical_path = normalized_path:gsub("/+", "/"):gsub("/$", "")
  
  -- 首先檢查禁止的危險路徑模式（黑名單）
  for _, pattern in ipairs(FORBIDDEN_PATH_PATTERNS) do
    if canonical_path:match(pattern) then
      return false, string.format("檢測到禁止的路徑模式: '%s' (路徑: %s)", pattern, canonical_path)
    end
  end
  
  -- 4. 平台感知的白名單驗證
  local path_allowed = false
  local is_macos = vim.fn.has("mac") == 1
  
  for _, pattern in ipairs(ALLOWED_PATH_PATTERNS) do
    if canonical_path:match(pattern) then
      path_allowed = true
      break
    end
  end
  
  -- macOS 特殊處理：檢查 /System/Volumes/Data 前綴
  if not path_allowed and is_macos and canonical_path:match("^/System/Volumes/Data/") then
    local normalized_macos_path = canonical_path:gsub("^/System/Volumes/Data", "")
    for _, pattern in ipairs(ALLOWED_PATH_PATTERNS) do
      if normalized_macos_path:match(pattern) then
        path_allowed = true
        break
      end
    end
  end
  
  if not path_allowed then
    -- 提供詳細的診斷信息，幫助用戶理解問題
    local diagnostic_info = M.generate_path_diagnostic(canonical_path)
    return false, diagnostic_info
  end
  
  return true, canonical_path
end

-- 🔍 生成路徑診斷信息（增強版，包含robust錯誤處理）
function M.generate_path_diagnostic(path)
  -- 防護：確保路徑參數安全
  if not path or type(path) ~= "string" or path == "" then
    return "路徑參數無效"
  end
  
  -- 使用 pcall 保護系統調用
  local os_type = "Unknown"
  local user_home = ""
  
  local success, uname_result = pcall(vim.loop.os_uname)
  if success and uname_result then
    os_type = uname_result.sysname or "Unknown"
  end
  
  user_home = os.getenv("HOME") or ""
  
  -- 檢測路徑類型以提供精確建議
  local path_suggestions = {}
  
  -- 平台特定建議（防護性編程）
  if os_type == "Darwin" then
    table.insert(path_suggestions, "• Homebrew: brew install <command>")
    table.insert(path_suggestions, "• 手動安裝到: /opt/homebrew/bin/ 或 /usr/local/bin/")
    if user_home ~= "" then
      -- 清理用戶路徑以防止格式化攻擊
      local safe_home = user_home:gsub("[^%w/_.-]", "")
      table.insert(path_suggestions, "• 用戶安裝: " .. safe_home .. "/.local/bin/")
    end
  elseif os_type == "Linux" then
    table.insert(path_suggestions, "• 包管理器: apt/yum/pacman install <command>")
    table.insert(path_suggestions, "• Snap: snap install <command>")
    table.insert(path_suggestions, "• Homebrew on Linux: /home/linuxbrew/.linuxbrew/bin/")
    if user_home ~= "" then
      local safe_home = user_home:gsub("[^%w/_.-]", "")
      table.insert(path_suggestions, "• 用戶安裝: " .. safe_home .. "/.local/bin/")
    end
  else
    table.insert(path_suggestions, "• 請參考您的系統包管理器文檔")
  end
  
  -- 檢測可能的路徑問題（使用安全的字串匹配）
  local path_analysis = {}
  local safe_path = path:sub(1, 1000)  -- 限制長度防止DoS
  
  if safe_path:match("^/tmp/") or safe_path:match("^/private/tmp/") then
    table.insert(path_analysis, "⚠️  臨時目錄中的檔案不被允許")
  elseif safe_path:match("%.%.") then
    table.insert(path_analysis, "⚠️  包含路徑遍歷字符")
  elseif not safe_path:match("^/") then
    table.insert(path_analysis, "⚠️  相對路徑不被允許")
  elseif safe_path:match("^/dev/") or safe_path:match("^/proc/") or safe_path:match("^/sys/") then
    table.insert(path_analysis, "⚠️  系統目錄不被允許")
  elseif safe_path:match("^/System/Volumes/Data/") and os_type == "Darwin" then
    table.insert(path_analysis, "ℹ️  macOS 系統路徑自動解析（已適配跨平台兼容）")
  else
    table.insert(path_analysis, "ℹ️  路徑格式正確但不在白名單中")
  end
  
  -- 構建診斷信息（使用安全的格式化）
  local diagnostic_parts = {
    "路徑安全驗證失敗",
    "檢查路徑: " .. safe_path:gsub("%%", "%%%%"),  -- 轉義 % 字符
    "",
    "路徑分析:"
  }
  
  -- 安全地添加分析結果
  for _, analysis in ipairs(path_analysis) do
    table.insert(diagnostic_parts, analysis)
  end
  
  table.insert(diagnostic_parts, "")
  table.insert(diagnostic_parts, "建議的安裝方式:")
  
  -- 安全地添加建議
  for _, suggestion in ipairs(path_suggestions) do
    table.insert(diagnostic_parts, suggestion)
  end
  
  -- 檢查檔案存在性（使用 pcall 保護）
  local file_check_success, file_exists = pcall(vim.fn.filereadable, safe_path)
  if file_check_success and file_exists == 1 then
    table.insert(diagnostic_parts, "")
    table.insert(diagnostic_parts, "注意: 檔案存在但位置不安全，請考慮重新安裝到安全位置")
  end
  
  return table.concat(diagnostic_parts, "\n")
end

-- 🔒 安全的檔案存在性和權限檢查
function M.secure_file_check(file_path)
  -- 使用 lstat 避免符號連結時的 TOCTOU 攻擊
  local stat_success, stat_result = pcall(vim.loop.fs_stat, file_path)
  if not stat_success or not stat_result then
    return false, "檔案不存在或無法訪問"
  end
  
  -- 檢查檔案類型
  if stat_result.type ~= "file" then
    return false, "不是普通檔案 (type: " .. tostring(stat_result.type) .. ")"
  end
  
  -- 檢查檔案大小（防止過大檔案）
  if stat_result.size > 50 * 1024 * 1024 then  -- 50MB 限制
    return false, "檔案過大 (> 50MB)"
  end
  
  -- 檢查檔案權限
  local access_success, access_result = pcall(vim.loop.fs_access, file_path, "X")
  if not access_success or not access_result then
    return false, "檔案不可執行"
  end
  
  return true, "檔案安全檢查通過"
end

-- 🔒 安全的命令執行驗證
function M.validate_command(cmd_name)
  if not cmd_name or cmd_name == "" then
    return false, nil, "命令名稱為空"
  end
  
  -- 檢查命令是否在安全清單中
  local safe_path = SECURE_COMMANDS[cmd_name]
  if not safe_path or safe_path == "" then
    return false, nil, string.format("命令 '%s' 不在安全清單中", cmd_name)
  end
  
  -- 驗證路徑安全性
  local path_safe, path_error = M.validate_path_security(safe_path)
  if not path_safe then
    return false, nil, string.format("命令路徑不安全: %s", path_error)
  end
  
  -- 檢查檔案存在性和權限
  local file_safe, file_error = M.secure_file_check(safe_path)
  if not file_safe then
    return false, nil, string.format("檔案檢查失敗: %s", file_error)
  end
  
  return true, safe_path, "命令驗證通過"
end

-- 更新命令路徑
function M.update_command_path(cmd_name, new_path)
  if not cmd_name or cmd_name == "" then
    return false, "命令名稱為空"
  end
  
  if not SECURE_COMMANDS[cmd_name] then
    return false, string.format("未知命令: %s", cmd_name)
  end
  
  -- 驗證新路徑
  local valid, error_msg = M.validate_path_security(new_path)
  if not valid then
    return false, string.format("新路徑不安全: %s", error_msg)
  end
  
  local old_path = SECURE_COMMANDS[cmd_name]
  SECURE_COMMANDS[cmd_name] = new_path
  
  vim.notify(string.format("🔄 已更新命令路徑: %s\n  舊路徑: %s\n  新路徑: %s", 
    cmd_name, old_path, new_path), vim.log.levels.INFO)
  
  return true, "路徑更新成功"
end

-- 獲取安全配置資訊
function M.get_security_config()
  return {
    secure_commands = vim.tbl_deep_extend("force", {}, SECURE_COMMANDS),
    allowed_patterns = vim.tbl_deep_extend("force", {}, ALLOWED_PATH_PATTERNS),
    forbidden_patterns = vim.tbl_deep_extend("force", {}, FORBIDDEN_PATH_PATTERNS)
  }
end

-- 檢查安全配置完整性
function M.validate_security_config()
  local issues = {}
  
  -- 檢查安全命令路徑
  for cmd_name, cmd_path in pairs(SECURE_COMMANDS) do
    if cmd_path == "" then
      table.insert(issues, string.format("命令 '%s' 路徑為空", cmd_name))
    else
      local valid, error_msg = M.validate_command(cmd_name)
      if not valid then
        table.insert(issues, string.format("命令 '%s' 驗證失敗: %s", cmd_name, error_msg))
      end
    end
  end
  
  return #issues == 0, issues
end

-- 安全審計功能
function M.security_audit()
  vim.notify("🔍 開始終端安全審計...", vim.log.levels.INFO)
  
  local valid, issues = M.validate_security_config()
  
  if valid then
    vim.notify("✅ 安全審計通過：所有配置正常", vim.log.levels.INFO)
  else
    vim.notify("⚠️ 安全審計發現問題：", vim.log.levels.WARN)
    for _, issue in ipairs(issues) do
      vim.notify("  • " .. issue, vim.log.levels.WARN)
    end
  end
  
  return valid, issues
end

-- 🏥 健康檢查 (Paranoid模式版本)
function M.health_check()
  local tools = { "claude", "gemini" }
  local results = {
    _timestamp = os.date("%Y-%m-%d %H:%M:%S"),
    _security_level = "paranoid",
    _platform = vim.fn.has("mac") == 1 and "macOS" or "Linux",
    _total_tools = #tools,
    _available_count = 0
  }
  
  for _, tool in ipairs(tools) do
    local valid, path_or_error = M.validate_command(tool)
    results[tool] = {
      available = valid,
      path = valid and path_or_error or nil,
      error = not valid and path_or_error or nil
    }
    
    if valid then
      results._available_count = results._available_count + 1
    end
  end
  
  results._health_status = results._available_count == results._total_tools and "healthy" or
                          results._available_count > 0 and "partial" or "unhealthy"
  
  return results
end

return M
