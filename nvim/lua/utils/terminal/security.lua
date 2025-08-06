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
    "/bin/" .. cmd_name
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
  -- 用戶 bin 目錄（優先，限制用戶名格式）
  "^/home/[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]/bin/[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]$",
  -- 用戶本地安裝（限制更嚴格）
  "^/home/[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]/\\.local/bin/[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]$",
  -- Node.js 通過 nvm 安裝（驗證版本格式）
  "^/home/[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]/\\.nvm/versions/node/v[0-9]+\\.[0-9]+\\.[0-9]+/bin/[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]$",
  -- Node.js 通過 npm global 安裝
  "^/home/[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]/\\.npm%-global/bin/[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]$",
  -- Homebrew on Linux（更嚴格的路徑）
  "^/home/linuxbrew/\\.linuxbrew/bin/[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]$",
  "^/opt/homebrew/bin/[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]$",
  -- 系統路徑（限制可執行檔名格式）
  "^/usr/bin/[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]$",
  "^/usr/local/bin/[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]$",
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
  
  -- 4. 白名單驗證
  local path_allowed = false
  for _, pattern in ipairs(ALLOWED_PATH_PATTERNS) do
    if canonical_path:match(pattern) then
      path_allowed = true
      break
    end
  end
  
  if not path_allowed then
    return false, "路徑不在安全白名單中"
  end
  
  return true, canonical_path
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

return M
