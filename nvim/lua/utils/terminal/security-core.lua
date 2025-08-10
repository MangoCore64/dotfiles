-- 簡化的終端安全核心模組
-- 20行簡潔方案：提供基礎安全檢查，符合Neovim生態系統慣例
-- 
-- 設計原則：
-- 1. 信任用戶判斷，提供基本保護
-- 2. 使用Neovim內建功能優先
-- 3. 簡潔易維護，避免過度工程化

local M = {}

-- 🔧 簡化的命令路徑檢測
function M.get_safe_command(cmd_name)
  if not cmd_name or cmd_name == "" then
    return nil, "命令名稱為空"
  end
  
  -- 使用 Neovim 內建的 exepath() - 最可靠的方法
  local cmd_path = vim.fn.exepath(cmd_name)
  if cmd_path == "" then
    return nil, string.format("命令 '%s' 未安裝或不在 PATH 中", cmd_name)
  end
  
  return cmd_path, nil
end

-- 🔒 基礎安全驗證
function M.validate_command(cmd_name)
  local path, err = M.get_safe_command(cmd_name)
  if not path then
    return false, err
  end
  
  -- 基本可執行性檢查
  if vim.fn.executable(path) ~= 1 then
    return false, "命令不可執行"
  end
  
  -- 簡單的路徑安全檢查：禁止明顯危險的路徑
  local dangerous_paths = { "/tmp/", "/dev/", "/proc/", "/sys/" }
  for _, danger in ipairs(dangerous_paths) do
    if path:match(danger) then
      return false, string.format("不安全的路徑位置: %s", danger)
    end
  end
  
  return true, path
end

-- 🔍 增強的用戶友好錯誤提示
function M.user_friendly_error(cmd_name, error_details)
  local os_type = vim.fn.has("mac") == 1 and "macOS" or "Linux"
  local suggestions = {}
  
  -- 針對特定命令的安裝建議
  if cmd_name == "claude" then
    table.insert(suggestions, "• npm: npm install -g @anthropic-ai/claude-code")
    if os_type == "macOS" then
      table.insert(suggestions, "• Homebrew: brew install anthropics/claude/claude")
    end
  elseif cmd_name == "gemini" then
    table.insert(suggestions, "• npm: npm install -g @google-ai/generativelanguage")
    if os_type == "macOS" then
      table.insert(suggestions, "• Homebrew: brew install google/cloud-sdk/google-cloud-sdk")  
    end
  else
    -- 通用建議
    table.insert(suggestions, string.format("• %s: brew install %s", os_type, cmd_name))
    table.insert(suggestions, string.format("• npm: npm install -g %s", cmd_name))
  end
  
  table.insert(suggestions, "• 手動: 確保命令在 PATH 中")
  
  local message = string.format([[
❌ 命令 '%s' 不可用

%s建議安裝方式：
%s

🔍 診斷命令: which %s
💡 檢查PATH: echo $PATH | tr ':' '\n'
]], cmd_name, error_details and ("錯誤詳情: " .. error_details .. "\n\n") or "", 
    table.concat(suggestions, "\n"), cmd_name)
  
  return message
end

-- 🏥 增強的健康檢查系統
function M.health_check()
  local tools = { "claude", "gemini" }
  local results = {
    _timestamp = os.date("%Y-%m-%d %H:%M:%S"),
    _security_level = "core",
    _platform = vim.fn.has("mac") == 1 and "macOS" or "Linux",
    _total_tools = #tools,
    _available_count = 0
  }
  
  for _, tool in ipairs(tools) do
    local valid, path_or_error = M.validate_command(tool)
    results[tool] = {
      available = valid,
      path = valid and path_or_error or nil,
      error = not valid and path_or_error or nil,
      suggestion = not valid and M.user_friendly_error(tool, path_or_error) or nil
    }
    
    if valid then
      results._available_count = results._available_count + 1
      -- 嘗試獲取版本資訊
      local version_cmd = string.format('%s --version 2>/dev/null', path_or_error)
      local version_success, version_output = pcall(vim.fn.system, version_cmd)
      if version_success and version_output and version_output ~= "" then
        results[tool].version = version_output:gsub("[\r\n]", ""):sub(1, 50) -- 限制長度
      end
    end
  end
  
  results._health_status = results._available_count == results._total_tools and "healthy" or
                          results._available_count > 0 and "partial" or "unhealthy"
  
  return results
end

-- 🔍 詳細診斷功能
function M.diagnose_command(cmd_name)
  print(string.format("🔍 診斷命令: %s", cmd_name))
  print("=" .. string.rep("=", 40))
  
  -- 基本檢查
  local path = vim.fn.exepath(cmd_name)
  print(string.format("PATH 檢查: %s", path ~= "" and ("✅ " .. path) or "❌ 未在PATH中找到"))
  
  -- 常見位置檢查
  local common_paths = {
    "/usr/local/bin/" .. cmd_name,
    "/opt/homebrew/bin/" .. cmd_name,
    os.getenv("HOME") .. "/.local/bin/" .. cmd_name,
    os.getenv("HOME") .. "/.nvm/versions/node/*/bin/" .. cmd_name,
  }
  
  print("\n📂 常見位置檢查:")
  for _, check_path in ipairs(common_paths) do
    local clean_path = check_path:gsub("%*", "latest")
    local exists = vim.fn.filereadable(clean_path) == 1
    print(string.format("  %s %s", exists and "✅" or "❌", check_path))
  end
  
  -- 環境變數檢查  
  print(string.format("\n🔧 PATH 環境變數: %s", os.getenv("PATH") and "✅ 已設定" or "❌ 未設定"))
  
  -- 安裝建議
  if path == "" then
    print("\n" .. M.user_friendly_error(cmd_name))
  end
end

-- 🔧 向後相容性：提供與paranoid模式相同的介面
function M.validate_path_security(file_path)
  if not file_path or file_path == "" then
    return false, "空路徑"
  end
  
  -- 基本檢查：檔案存在性
  if vim.fn.filereadable(file_path) ~= 1 then
    return false, "檔案不存在或不可讀"
  end
  
  return true, file_path
end

-- 🔒 檢查安全配置完整性 (基礎版本)
function M.validate_security_config()
  local issues = {}
  
  -- 基礎模式：檢查關鍵系統命令的可用性
  local critical_commands = {"bash", "sh"}
  
  for _, cmd_name in ipairs(critical_commands) do
    local valid, error_msg = M.validate_command(cmd_name)
    if not valid then
      table.insert(issues, string.format("關鍵命令 '%s' 不可用: %s", cmd_name, error_msg))
    end
  end
  
  -- 檢查AI工具的可用性（非關鍵，只警告）
  local ai_tools = {"claude", "gemini"}
  local ai_issues = 0
  
  for _, tool in ipairs(ai_tools) do
    local valid = M.validate_command(tool)
    if not valid then
      ai_issues = ai_issues + 1
    end
  end
  
  if ai_issues > 0 then
    table.insert(issues, string.format("AI工具可用性警告: %d/%d 工具不可用", ai_issues, #ai_tools))
  end
  
  return #issues == 0, issues
end

return M