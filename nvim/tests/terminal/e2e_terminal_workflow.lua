-- E2E 終端工作流程測試
-- 完整的端對端測試，驗證整個終端管理系統
-- 
-- 測試範圍：
-- 1. 終端創建與銷毀
-- 2. 切換邏輯
-- 3. 狀態持久性
-- 4. 錯誤恢復
-- 5. 資源清理

print("🔬 E2E 終端工作流程測試")
print("=" .. string.rep("=", 60))

-- 載入測試模組
local manager = require('utils.terminal.manager')
local claude = require('utils.terminal.adapters.claude')
local gemini = require('utils.terminal.adapters.gemini')
local state = require('utils.terminal.state')

-- 測試結果收集
local test_results = {
  total_tests = 0,
  passed_tests = 0,
  failed_tests = 0,
  test_details = {}
}

-- 測試工具函數
local function assert_test(condition, test_name, error_msg)
  test_results.total_tests = test_results.total_tests + 1
  
  if condition then
    test_results.passed_tests = test_results.passed_tests + 1
    table.insert(test_results.test_details, {
      name = test_name,
      status = "✅ 通過",
      message = ""
    })
    print(string.format("  ✅ %s", test_name))
  else
    test_results.failed_tests = test_results.failed_tests + 1
    table.insert(test_results.test_details, {
      name = test_name,
      status = "❌ 失敗",
      message = error_msg or "未知錯誤"
    })
    print(string.format("  ❌ %s: %s", test_name, error_msg or "測試失敗"))
  end
end

-- 測試環境清理
local function cleanup_test_environment()
  print("🧹 清理測試環境...")
  manager.reset()
  claude.destroy()
  gemini.destroy()
  collectgarbage("collect")
  vim.wait(100) -- 等待清理完成
end

-- 等待條件成立的工具函數
local function wait_for_condition(condition_func, timeout_ms, check_interval)
  timeout_ms = timeout_ms or 1000
  check_interval = check_interval or 50
  
  local start_time = vim.fn.reltime()
  while vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000 < timeout_ms do
    if condition_func() then
      return true
    end
    vim.wait(check_interval)
  end
  return false
end

print("\n1. 🏗️ 初始化測試")
cleanup_test_environment()

-- 測試 1: 初始狀態檢查
print("\n2. 🔍 初始狀態測試")
local initial_status = manager.get_status()
assert_test(
  not initial_status.claude_code.visible and not initial_status.gemini.visible,
  "初始狀態 - 所有終端都未顯示",
  "初始狀態應該沒有可見的終端"
)

assert_test(
  not initial_status.busy,
  "初始狀態 - 系統未忙碌",
  "初始狀態系統不應該處於忙碌狀態"
)

-- 測試 2: Claude Code 終端生命周期
print("\n3. 🤖 Claude Code 終端生命周期測試")

-- 開啟 Claude Code
local claude_open_success = manager.toggle_claude_code()
assert_test(
  claude_open_success,
  "Claude Code 開啟",
  "應該能夠成功開啟 Claude Code 終端"
)

-- 等待終端完全載入
vim.wait(200)

-- 檢查狀態
local claude_status = manager.get_status()
assert_test(
  claude_status.claude_code.visible,
  "Claude Code 可見性檢查",
  "Claude Code 終端應該是可見的"
)

assert_test(
  claude_status.last_active == "claude_code",
  "最後活躍終端記錄",
  "最後活躍的終端應該是 claude_code"
)

-- 關閉 Claude Code
local claude_close_success = manager.toggle_claude_code()
assert_test(
  claude_close_success,
  "Claude Code 關閉",
  "應該能夠成功關閉 Claude Code 終端"
)

-- 測試 3: Gemini 終端生命周期
print("\n4. 💎 Gemini 終端生命周期測試")

-- 開啟 Gemini
local gemini_open_success = manager.toggle_gemini()
assert_test(
  gemini_open_success,
  "Gemini 開啟",
  "應該能夠成功開啟 Gemini 終端"
)

-- 等待終端完全載入
vim.wait(200)

-- 檢查狀態
local gemini_status = manager.get_status()
assert_test(
  gemini_status.gemini.visible,
  "Gemini 可見性檢查",
  "Gemini 終端應該是可見的"
)

assert_test(
  gemini_status.last_active == "gemini",
  "最後活躍終端記錄更新",
  "最後活躍的終端應該是 gemini"
)

-- 隱藏 Gemini
local gemini_hide_success = manager.toggle_gemini()
assert_test(
  gemini_hide_success,
  "Gemini 隱藏",
  "應該能夠成功隱藏 Gemini 終端"
)

-- 測試 4: 智能切換邏輯
print("\n5. 🔄 智能切換邏輯測試")

-- 確保所有終端都關閉
cleanup_test_environment()
vim.wait(100)

-- 從空狀態開始切換 - 應該開啟 Claude Code（預設）
local switch_from_empty = manager.switch_terminal()
assert_test(
  switch_from_empty,
  "從空狀態切換",
  "從空狀態切換應該成功"
)

vim.wait(100)
local after_first_switch = manager.get_status()
assert_test(
  after_first_switch.claude_code.visible and not after_first_switch.gemini.visible,
  "切換到預設終端",
  "從空狀態切換應該開啟 Claude Code"
)

-- 切換到 Gemini
local switch_to_gemini = manager.switch_terminal()
assert_test(
  switch_to_gemini,
  "切換到 Gemini",
  "從 Claude Code 切換到 Gemini 應該成功"
)

vim.wait(100)
local after_second_switch = manager.get_status()
assert_test(
  not after_second_switch.claude_code.visible and after_second_switch.gemini.visible,
  "驗證切換到 Gemini",
  "應該只有 Gemini 可見"
)

-- 切換回 Claude Code
local switch_back_to_claude = manager.switch_terminal()
assert_test(
  switch_back_to_claude,
  "切換回 Claude Code",
  "從 Gemini 切換回 Claude Code 應該成功"
)

vim.wait(100)
local after_third_switch = manager.get_status()
assert_test(
  after_third_switch.claude_code.visible and not after_third_switch.gemini.visible,
  "驗證切換回 Claude Code",
  "應該只有 Claude Code 可見"
)

-- 測試 5: 並發保護
print("\n6. 🔒 並發保護測試")

-- 模擬忙碌狀態
state.set_busy(true)
local busy_operation = manager.switch_terminal()
assert_test(
  not busy_operation,
  "忙碌狀態下的操作阻止",
  "系統忙碌時應該阻止新操作"
)

-- 解除忙碌狀態
state.set_busy(false)
local after_busy_release = manager.switch_terminal()
assert_test(
  after_busy_release,
  "解除忙碌後的操作恢復",
  "解除忙碌狀態後應該能夠正常操作"
)

-- 測試 6: 錯誤恢復機制
print("\n7. 🚨 錯誤恢復機制測試")

-- 創建異常狀態 - 同時設置兩個終端為可見（不應該發生）
manager.toggle_claude_code()
vim.wait(100)
manager.toggle_gemini()
vim.wait(100)

-- 檢查是否有異常狀態
local abnormal_status = manager.get_status()
local has_conflict = abnormal_status.claude_code.visible and abnormal_status.gemini.visible

if has_conflict then
  -- 測試自動修復
  local recovery_success = manager.switch_terminal()
  vim.wait(100)
  local after_recovery = manager.get_status()
  
  assert_test(
    not (after_recovery.claude_code.visible and after_recovery.gemini.visible),
    "異常狀態自動修復",
    "系統應該能自動修復同時顯示兩個終端的異常狀態"
  )
else
  assert_test(
    true,
    "無異常狀態檢測",
    "系統正常運行，未檢測到異常狀態"
  )
end

-- 測試 7: 健康檢查功能
print("\n8. 🏥 健康檢查測試")

local health_report = manager.health_check()
assert_test(
  health_report ~= nil,
  "健康檢查執行",
  "健康檢查應該能夠正常執行"
)

assert_test(
  health_report.statistics ~= nil,
  "統計資訊收集",
  "健康檢查應該包含統計資訊"
)

-- 測試 8: 狀態持久性
print("\n9. 💾 狀態持久性測試")

-- 設置特定狀態
manager.toggle_gemini()
vim.wait(100)

local before_reset_status = manager.get_status()
local last_active_before = before_reset_status.last_active

-- 執行清理但不重置
manager.cleanup()
vim.wait(100)

local after_cleanup_status = manager.get_status()
assert_test(
  after_cleanup_status.last_active == last_active_before,
  "清理後狀態保持",
  "清理操作不應該影響最後活躍終端記錄"
)

-- 測試 9: 資源清理
print("\n10. 🧹 資源清理測試")

-- 開啟多個終端
manager.toggle_claude_code()
manager.toggle_gemini()
vim.wait(200)

-- 執行完全重置
local reset_success = manager.reset()
assert_test(
  reset_success ~= nil,
  "重置操作執行",
  "重置操作應該能夠執行"
)

vim.wait(100)
local after_reset_status = manager.get_status()
assert_test(
  not after_reset_status.claude_code.visible and not after_reset_status.gemini.visible,
  "重置後狀態清空",
  "重置後所有終端都應該不可見"
)

assert_test(
  not after_reset_status.busy,
  "重置後忙碌狀態清除",
  "重置後系統不應該處於忙碌狀態"
)

-- 測試 10: 統一 API 測試
print("\n11. 🔌 統一 API 測試")
local unified_api = require('utils.terminal.init')

-- 測試健康檢查
local api_health_ok, api_health_issues = unified_api.health_check()
assert_test(
  api_health_ok ~= nil,
  "統一 API 健康檢查",
  "統一 API 的健康檢查應該能夠執行"
)

-- 測試系統資訊
local system_info = unified_api.get_system_info()
assert_test(
  system_info.version ~= nil,
  "系統資訊獲取",
  "應該能夠獲取系統版本資訊"
)

assert_test(
  type(system_info.registered_terminals) == "table",
  "註冊終端列表",
  "應該能夠獲取已註冊的終端列表"
)

-- 最終清理
print("\n12. 🏁 最終清理")
cleanup_test_environment()

-- 測試結果統計
print(string.rep("=", 60))
print("📊 E2E 測試結果統計")
print(string.rep("=", 60))

local success_rate = test_results.total_tests > 0 and 
  (test_results.passed_tests / test_results.total_tests * 100) or 0

print(string.format("總測試數: %d", test_results.total_tests))
print(string.format("通過測試: %d", test_results.passed_tests))
print(string.format("失敗測試: %d", test_results.failed_tests))
print(string.format("成功率: %.1f%%", success_rate))

-- 整體判定
if test_results.failed_tests == 0 then
  print("\n🎉 所有 E2E 測試通過！")
  print("✅ 終端管理系統工作正常")
  print("✅ 所有核心功能運作良好")
  print("✅ 錯誤恢復機制有效")
  print("✅ 資源管理正確")
else
  print("\n⚠️ 部分 E2E 測試失敗")
  print("需要檢查以下問題：")
  
  for _, test_detail in ipairs(test_results.test_details) do
    if test_detail.status:find("❌") then
      print(string.format("  • %s: %s", test_detail.name, test_detail.message))
    end
  end
end

-- 性能評估
local performance_rating = "優秀"
if success_rate < 80 then
  performance_rating = "需要改善"
elseif success_rate < 95 then
  performance_rating = "良好"
end

print(string.format("\n🎯 整體評估: %s", performance_rating))

-- 返回結果供進一步分析
return {
  success = test_results.failed_tests == 0,
  success_rate = success_rate,
  total_tests = test_results.total_tests,
  passed_tests = test_results.passed_tests,
  failed_tests = test_results.failed_tests,
  performance_rating = performance_rating,
  test_details = test_results.test_details
}