-- Claude 升級測試
-- 測試升級後的 terminal/adapters/claude.lua 功能
local Path = require('plenary.path')

-- 設定測試環境路徑
package.path = package.path .. ';' .. vim.fn.expand('~/.config/nvim/lua') .. '/?.lua'

-- 測試用的 mock vim API
local function setup_test_env()
  if not vim.o then
    vim.o = {
      columns = 120,
      lines = 40
    }
  end
  
  if not vim.log then
    vim.log = {
      levels = {
        WARN = 2,
        ERROR = 3,
        INFO = 1
      }
    }
  end
  
  if not vim.notify then
    vim.notify = function(msg, level)
      print(string.format("[%d] %s", level or 1, msg))
    end
  end
  
  if not vim.fn then
    vim.fn = {}
  end
  
  if not vim.fn.localtime then
    vim.fn.localtime = function()
      return os.time()
    end
  end
  
  if not vim.api then
    vim.api = {}
  end
  
  -- Mock vim.api.nvim_get_commands 返回空的 ClaudeCode 命令
  if not vim.api.nvim_get_commands then
    vim.api.nvim_get_commands = function()
      return {}  -- 模擬沒有 ClaudeCode 命令的情況
    end
  end
  
  if not vim.api.nvim_list_bufs then
    vim.api.nvim_list_bufs = function()
      return {}  -- 模擬沒有 buffer 的情況
    end
  end
  
  if not vim.api.nvim_list_wins then
    vim.api.nvim_list_wins = function()
      return {}  -- 模擬沒有視窗的情況
    end
  end
  
  if not vim.api.nvim_get_current_win then
    vim.api.nvim_get_current_win = function()
      return 1
    end
  end
  
  if not vim.api.nvim_get_current_buf then
    vim.api.nvim_get_current_buf = function()
      return 1
    end
  end
  
  if not vim.defer_fn then
    vim.defer_fn = function(fn, timeout)
      fn()  -- 立即執行
    end
  end
  
  if not vim.inspect then
    vim.inspect = function(obj)
      return tostring(obj)
    end
  end
  
  if not vim.cmd then
    vim.cmd = function(command)
      -- Mock 命令執行
      if command == 'ClaudeCode' then
        -- 模擬 ClaudeCode 命令成功
        return
      end
    end
  end
end

-- 測試函數
local function test_claude_upgrade()
  print("🧪 開始測試升級後的 Claude 模組...")
  setup_test_env()
  
  local tests_passed = 0
  local tests_failed = 0
  
  -- 測試 1: 模組載入
  print("\n✅ 測試 1: 模組載入")
  local claude_success, claude = pcall(require, 'utils.terminal.adapters.claude')
  if claude_success and claude then
    print("  ✓ Claude 模組成功載入")
    tests_passed = tests_passed + 1
  else
    print("  ✗ Claude 模組載入失敗: " .. tostring(claude))
    tests_failed = tests_failed + 1
    return false  -- 無法繼續測試
  end
  
  -- 測試 2: 向後相容 API
  print("\n✅ 測試 2: 向後相容 API")
  local compat_functions = {
    "find_claude_terminal", "is_visible", "toggle", "open", "close"
  }
  
  local compat_valid = true
  for _, func_name in ipairs(compat_functions) do
    if not claude[func_name] or type(claude[func_name]) ~= "function" then
      print("  ✗ 向後相容函數缺失: " .. func_name)
      compat_valid = false
    end
  end
  
  if compat_valid then
    print("  ✓ 向後相容 API 檢查通過")
    tests_passed = tests_passed + 1
  else
    tests_failed = tests_failed + 1
  end
  
  -- 測試 3: 新增功能
  print("\n✅ 測試 3: 新增功能")
  local new_functions = {
    "get_status", "restart", "health_check", "debug_info", 
    "migrate_from_old_version", "use_core_api_only"
  }
  
  local new_features_valid = true
  for _, func_name in ipairs(new_functions) do
    if not claude[func_name] or type(claude[func_name]) ~= "function" then
      print("  ✗ 新功能函數缺失: " .. func_name)
      new_features_valid = false
    end
  end
  
  if new_features_valid then
    print("  ✓ 新功能檢查通過")
    tests_passed = tests_passed + 1
  else
    tests_failed = tests_failed + 1
  end
  
  -- 測試 4: 狀態檢查
  print("\n✅ 測試 4: 狀態檢查")
  local status_success, status = pcall(claude.get_status)
  if status_success and status then
    print("  ✓ 狀態檢查成功")
    print("    - 名稱: " .. tostring(status.name))
    print("    - 存在: " .. tostring(status.exists))
    print("    - 可見: " .. tostring(status.visible))
    print("    - 方法: " .. tostring(status.method))
    tests_passed = tests_passed + 1
  else
    print("  ✗ 狀態檢查失敗: " .. tostring(status))
    tests_failed = tests_failed + 1
  end
  
  -- 測試 5: 健康檢查
  print("\n✅ 測試 5: 健康檢查")
  local health_success, health_valid, health_issues = pcall(claude.health_check)
  if health_success then
    if health_valid then
      print("  ✓ Claude 模組健康檢查通過")
    else
      print("  ⚠️ Claude 模組健康檢查發現問題:")
      for _, issue in ipairs(health_issues or {}) do
        print("    - " .. issue)
      end
    end
    tests_passed = tests_passed + 1
  else
    print("  ✗ 健康檢查執行失敗: " .. tostring(health_valid))
    tests_failed = tests_failed + 1
  end
  
  -- 測試 6: 終端檢測
  print("\n✅ 測試 6: 終端檢測")
  local find_success, find_result = pcall(claude.find_claude_terminal)
  if find_success then
    print("  ✓ 終端檢測功能正常")
    if find_result then
      print("    - 找到 Claude 終端")
    else
      print("    - 未找到 Claude 終端（正常，測試環境）")
    end
    tests_passed = tests_passed + 1
  else
    print("  ✗ 終端檢測失敗: " .. tostring(find_result))
    tests_failed = tests_failed + 1
  end
  
  -- 測試總結
  print(string.format("\n📊 測試總結: %d 通過, %d 失敗", tests_passed, tests_failed))
  
  if tests_failed == 0 then
    print("🎉 所有 Claude 升級測試通過！")
    return true
  else
    print("⚠️ 有測試失敗，請檢查升級結果")
    return false
  end
end

-- 測試依賴模組整合
local function test_module_integration()
  print("\n🔗 開始測試 Claude 模組整合...")
  
  local integration_success = true
  
  -- 測試與各模組的整合
  local modules_to_test = {
    {'utils.terminal.core', 'Core'},
    {'utils.terminal.security', 'Security'}, 
    {'utils.terminal.ui', 'UI'},
    {'utils.terminal.state', 'State'}
  }
  
  for _, module_info in ipairs(modules_to_test) do
    local module_path, module_name = module_info[1], module_info[2]
    local success, module = pcall(require, module_path)
    if success and module then
      print("  ✓ " .. module_name .. " 模組整合正常")
    else
      print("  ✗ " .. module_name .. " 模組整合失敗")
      integration_success = false
    end
  end
  
  return integration_success
end

-- 執行所有測試
local function run_tests()
  local claude_test_result = test_claude_upgrade()
  local integration_test_result = test_module_integration()
  
  print("\n🎯 最終結果:")
  print("  Claude 升級測試: " .. (claude_test_result and "通過" or "失敗"))
  print("  模組整合測試: " .. (integration_test_result and "通過" or "失敗"))
  
  return claude_test_result and integration_test_result
end

-- 如果直接執行此文件，運行測試
if ... == nil then
  local success = run_tests()
  os.exit(success and 0 or 1)
end

-- 返回測試函數供其他模組使用
return {
  test_claude_upgrade = test_claude_upgrade,
  test_module_integration = test_module_integration,
  run_tests = run_tests
}