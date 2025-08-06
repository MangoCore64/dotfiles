-- UI 模組測試
-- 測試 terminal/ui.lua 的功能
local Path = require('plenary.path')

-- 設定測試環境路徑
package.path = package.path .. ';' .. vim.fn.expand('~/.config/nvim/lua') .. '/?.lua'

-- 載入模組
local ui = require('utils.terminal.ui')

-- 測試用的 mock vim API（因為在測試環境中可能沒有完整的 vim API）
local function setup_test_env()
  -- 模擬基本的 vim 設置
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
end

-- 測試函數
local function test_ui_module()
  print("🧪 開始測試 UI 模組...")
  setup_test_env()
  
  local tests_passed = 0
  local tests_failed = 0
  
  -- 測試 1: 檢查模組載入
  print("\n✅ 測試 1: 模組載入")
  if ui and type(ui.create_floating_window) == "function" then
    print("  ✓ UI 模組成功載入")
    tests_passed = tests_passed + 1
  else
    print("  ✗ UI 模組載入失敗")
    tests_failed = tests_failed + 1
  end
  
  -- 測試 2: 健康檢查
  print("\n✅ 測試 2: 健康檢查")
  local health_valid, health_issues = ui.health_check()
  if health_valid then
    print("  ✓ UI 模組健康檢查通過")
    tests_passed = tests_passed + 1
  else
    print("  ✗ UI 模組健康檢查失敗:")
    for _, issue in ipairs(health_issues or {}) do
      print("    - " .. issue)
    end
    tests_failed = tests_failed + 1
  end
  
  -- 測試 3: 支援的選項
  print("\n✅ 測試 3: 支援的選項")
  local options = ui.get_supported_options()
  if options and options.default_config and options.border_styles and options.functions then
    print("  ✓ 支援的選項獲取成功")
    print("    - 預設配置項目: " .. tostring(vim.tbl_count(options.default_config)))
    print("    - 邊框樣式: " .. tostring(vim.tbl_count(options.border_styles)))
    print("    - 可用函數: " .. tostring(#options.functions))
    tests_passed = tests_passed + 1
  else
    print("  ✗ 支援的選項獲取失敗")
    tests_failed = tests_failed + 1
  end
  
  -- 測試 4: 邊框樣式驗證
  print("\n✅ 測試 4: 邊框樣式")
  local styles = {"none", "single", "double", "rounded", "solid", "shadow"}
  local styles_valid = true
  for _, style in ipairs(styles) do
    local options = ui.get_supported_options()
    if not options.border_styles[style] then
      print("  ✗ 邊框樣式 " .. style .. " 不存在")
      styles_valid = false
    end
  end
  if styles_valid then
    print("  ✓ 所有預期的邊框樣式都存在")
    tests_passed = tests_passed + 1
  else
    tests_failed = tests_failed + 1
  end
  
  -- 測試 5: 配置驗證（無需實際創建視窗）
  print("\n✅ 測試 5: 配置結構")
  local default_config = ui.get_supported_options().default_config
  local required_keys = {"width_ratio", "height_ratio", "min_width", "min_height", "border"}
  local config_valid = true
  
  for _, key in ipairs(required_keys) do
    if default_config[key] == nil then
      print("  ✗ 預設配置缺少 " .. key)
      config_valid = false
    end
  end
  
  if config_valid then
    print("  ✓ 預設配置結構完整")
    tests_passed = tests_passed + 1
  else
    tests_failed = tests_failed + 1
  end
  
  -- 測試總結
  print(string.format("\n📊 測試總結: %d 通過, %d 失敗", tests_passed, tests_failed))
  
  if tests_failed == 0 then
    print("🎉 所有 UI 模組測試通過！")
    return true
  else
    print("⚠️ 有測試失敗，請檢查 UI 模組")
    return false
  end
end

-- 模組測試功能
local function test_ui_integration()
  print("\n🔗 開始測試 UI 模組整合...")
  
  -- 測試模組間的相依性
  local core_success, core_module = pcall(require, 'utils.terminal.core')
  if core_success then
    print("  ✓ Core 模組成功載入 UI 模組")
    
    -- 測試 core 模組的健康檢查是否包含 UI 檢查
    local health_valid, health_issues = core_module.health_check()
    if health_valid then
      print("  ✓ Core 模組健康檢查（包含 UI）通過")
    else
      print("  ⚠️ Core 模組健康檢查發現問題:")
      for _, issue in ipairs(health_issues or {}) do
        print("    - " .. issue)
      end
    end
  else
    print("  ✗ Core 模組載入失敗: " .. tostring(core_module))
  end
  
  return core_success
end

-- 執行測試
local function run_tests()
  local ui_test_result = test_ui_module()
  local integration_test_result = test_ui_integration()
  
  return ui_test_result and integration_test_result
end

-- 如果直接執行此文件，運行測試
if ... == nil then
  local success = run_tests()
  os.exit(success and 0 or 1)
end

-- 返回測試函數供其他模組使用
return {
  test_ui_module = test_ui_module,
  test_ui_integration = test_ui_integration,
  run_tests = run_tests
}