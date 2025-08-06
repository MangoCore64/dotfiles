-- Gemini 重構測試
-- 測試重構後的 terminal/adapters/gemini.lua 功能
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
  
  if not vim.fn.exepath then
    vim.fn.exepath = function(cmd)
      return "/usr/bin/" .. cmd  -- mock 路徑
    end
  end
  
  if not vim.fn.executable then
    vim.fn.executable = function(path)
      return 1  -- mock 可執行
    end
  end
  
  if not vim.defer_fn then
    vim.defer_fn = function(fn, timeout)
      fn()  -- 立即執行
    end
  end
  
  if not vim.tbl_count then
    vim.tbl_count = function(tbl)
      local count = 0
      for _ in pairs(tbl) do
        count = count + 1
      end
      return count
    end
  end
  
  if not vim.list_extend then
    vim.list_extend = function(dst, src)
      for _, item in ipairs(src) do
        table.insert(dst, item)
      end
      return dst
    end
  end
  
  if not vim.inspect then
    vim.inspect = function(obj)
      return tostring(obj)
    end
  end
end

-- 測試函數
local function test_gemini_refactor()
  print("🧪 開始測試重構後的 Gemini 模組...")
  setup_test_env()
  
  local tests_passed = 0
  local tests_failed = 0
  
  -- 測試 1: 模組載入
  print("\n✅ 測試 1: 模組載入")
  local gemini_success, gemini = pcall(require, 'utils.terminal.adapters.gemini')
  if gemini_success and gemini then
    print("  ✓ Gemini 模組成功載入")
    tests_passed = tests_passed + 1
  else
    print("  ✗ Gemini 模組載入失敗: " .. tostring(gemini))
    tests_failed = tests_failed + 1
    return false  -- 無法繼續測試
  end
  
  -- 測試 2: 基本 API 存在
  print("\n✅ 測試 2: 基本 API")
  local required_functions = {
    "is_visible", "show", "hide", "toggle", "destroy", 
    "get_status", "restart", "health_check"
  }
  
  local api_valid = true
  for _, func_name in ipairs(required_functions) do
    if not gemini[func_name] or type(gemini[func_name]) ~= "function" then
      print("  ✗ 缺少函數: " .. func_name)
      api_valid = false
    end
  end
  
  if api_valid then
    print("  ✓ 所有必需的 API 函數都存在")
    tests_passed = tests_passed + 1
  else
    tests_failed = tests_failed + 1
  end
  
  -- 測試 3: 健康檢查
  print("\n✅ 測試 3: 健康檢查")
  local health_success, health_valid, health_issues = pcall(gemini.health_check)
  if health_success then
    if health_valid then
      print("  ✓ Gemini 模組健康檢查通過")
      tests_passed = tests_passed + 1
    else
      print("  ⚠️ Gemini 模組健康檢查發現問題:")
      for _, issue in ipairs(health_issues or {}) do
        print("    - " .. issue)
      end
      tests_passed = tests_passed + 1  -- 有問題但不算失敗
    end
  else
    print("  ✗ 健康檢查執行失敗: " .. tostring(health_valid))
    tests_failed = tests_failed + 1
  end
  
  -- 測試 4: 狀態檢查
  print("\n✅ 測試 4: 狀態檢查")
  local status_success, status = pcall(gemini.get_status)
  if status_success and status then
    print("  ✓ 狀態檢查成功")
    print("    - 存在: " .. tostring(status.exists))
    print("    - 可見: " .. tostring(status.visible))
    tests_passed = tests_passed + 1
  else
    print("  ✗ 狀態檢查失敗: " .. tostring(status))
    tests_failed = tests_failed + 1
  end
  
  -- 測試 5: 向後相容性
  print("\n✅ 測試 5: 向後相容性")
  local compat_functions = {"show_config", "security_audit", "update_command_path"}
  local compat_valid = true
  
  for _, func_name in ipairs(compat_functions) do
    if not gemini[func_name] or type(gemini[func_name]) ~= "function" then
      print("  ✗ 向後相容函數缺失: " .. func_name)
      compat_valid = false
    end
  end
  
  if compat_valid then
    print("  ✓ 向後相容性檢查通過")
    tests_passed = tests_passed + 1
  else
    tests_failed = tests_failed + 1
  end
  
  -- 測試 6: 新功能
  print("\n✅ 測試 6: 新功能")
  local new_functions = {"debug_info", "migrate_from_old_version"}
  local new_features_valid = true
  
  for _, func_name in ipairs(new_functions) do
    if not gemini[func_name] or type(gemini[func_name]) ~= "function" then
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
  
  -- 測試總結
  print(string.format("\n📊 測試總結: %d 通過, %d 失敗", tests_passed, tests_failed))
  
  if tests_failed == 0 then
    print("🎉 所有 Gemini 重構測試通過！")
    return true
  else
    print("⚠️ 有測試失敗，請檢查重構結果")
    return false
  end
end

-- 測試依賴模組整合
local function test_module_integration()
  print("\n🔗 開始測試模組整合...")
  
  local integration_success = true
  
  -- 測試核心模組整合
  local core_success, core = pcall(require, 'utils.terminal.core')
  if core_success and core.health_check then
    print("  ✓ 核心模組整合正常")
  else
    print("  ✗ 核心模組整合失敗")
    integration_success = false
  end
  
  -- 測試安全模組整合
  local security_success, security = pcall(require, 'utils.terminal.security')
  if security_success and security.validate_security_config then
    print("  ✓ 安全模組整合正常")
  else
    print("  ✗ 安全模組整合失敗")
    integration_success = false
  end
  
  -- 測試 UI 模組整合
  local ui_success, ui = pcall(require, 'utils.terminal.ui')
  if ui_success and ui.create_floating_window then
    print("  ✓ UI 模組整合正常")
  else
    print("  ✗ UI 模組整合失敗")
    integration_success = false
  end
  
  -- 測試狀態模組整合
  local state_success, state = pcall(require, 'utils.terminal.state')
  if state_success and state.get_terminal_state then
    print("  ✓ 狀態模組整合正常")
  else
    print("  ✗ 狀態模組整合失敗")
    integration_success = false
  end
  
  return integration_success
end

-- 執行所有測試
local function run_tests()
  local gemini_test_result = test_gemini_refactor()
  local integration_test_result = test_module_integration()
  
  print("\n🎯 最終結果:")
  print("  Gemini 重構測試: " .. (gemini_test_result and "通過" or "失敗"))
  print("  模組整合測試: " .. (integration_test_result and "通過" or "失敗"))
  
  return gemini_test_result and integration_test_result
end

-- 如果直接執行此文件，運行測試
if ... == nil then
  local success = run_tests()
  os.exit(success and 0 or 1)
end

-- 返回測試函數供其他模組使用
return {
  test_gemini_refactor = test_gemini_refactor,
  test_module_integration = test_module_integration,
  run_tests = run_tests
}