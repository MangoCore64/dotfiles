-- E2E 基本工作流程測試 (簡化版)
-- 專注於核心功能的端對端測試

print("🔬 E2E 基本工作流程測試")
print("=" .. string.rep("=", 50))

-- 載入測試模組
local manager = require('utils.terminal.manager')
local state = require('utils.terminal.state')

-- 測試計數器
local test_count = 0
local pass_count = 0

local function test_assert(condition, name)
  test_count = test_count + 1
  if condition then
    pass_count = pass_count + 1
    print(string.format("  ✅ %s", name))
  else
    print(string.format("  ❌ %s", name))
  end
end

-- 清理環境
print("\n1. 🧹 環境準備")
manager.reset()
vim.wait(50)

-- 測試 1: 初始狀態
print("\n2. 🔍 初始狀態檢查")
local initial_status = manager.get_status()
test_assert(not initial_status.busy, "系統未忙碌")
test_assert(not initial_status.claude_code.visible, "Claude Code 未顯示")
test_assert(not initial_status.gemini.visible, "Gemini 未顯示")

-- 測試 2: 基本開關功能
print("\n3. 🤖 Claude Code 基本功能")
local claude_toggle_1 = manager.toggle_claude_code()
test_assert(claude_toggle_1, "Claude Code 開啟")

vim.wait(100)
local claude_status_1 = manager.get_status()
test_assert(claude_status_1.claude_code.visible, "Claude Code 可見")

local claude_toggle_2 = manager.toggle_claude_code()
test_assert(claude_toggle_2, "Claude Code 關閉")

vim.wait(50)
local claude_status_2 = manager.get_status()
test_assert(not claude_status_2.claude_code.visible, "Claude Code 已隱藏")

-- 測試 3: Gemini 基本功能
print("\n4. 💎 Gemini 基本功能")
local gemini_toggle_1 = manager.toggle_gemini()
test_assert(gemini_toggle_1, "Gemini 開啟")

vim.wait(100)
local gemini_status_1 = manager.get_status()
test_assert(gemini_status_1.gemini.visible, "Gemini 可見")

local gemini_toggle_2 = manager.toggle_gemini()
test_assert(gemini_toggle_2, "Gemini 隱藏")

-- 測試 4: 智能切換
print("\n5. 🔄 智能切換測試")
manager.reset()
vim.wait(50)

-- 空狀態切換
local switch_1 = manager.switch_terminal()
test_assert(switch_1, "空狀態切換成功")

vim.wait(100)
local switch_status_1 = manager.get_status()
test_assert(switch_status_1.claude_code.visible or switch_status_1.gemini.visible, "切換後有終端顯示")

-- 再次切換
local switch_2 = manager.switch_terminal()
test_assert(switch_2, "二次切換成功")

-- 測試 5: 並發保護
print("\n6. 🔒 並發保護測試")
state.set_busy(true)
local busy_result = manager.toggle_claude_code()
test_assert(not busy_result, "忙碌時操作被阻止")

state.set_busy(false)
local after_busy = manager.toggle_claude_code()
test_assert(after_busy, "解除忙碌後操作正常")

-- 測試 6: 狀態管理
print("\n7. 💾 狀態管理測試")
manager.toggle_gemini()
vim.wait(50)

local status_before = manager.get_status()
local last_active_before = status_before.last_active

manager.cleanup()
vim.wait(50)

local status_after = manager.get_status()
test_assert(status_after.last_active == last_active_before, "清理後狀態保持")

-- 測試 7: 重置功能
print("\n8. 🔄 重置功能測試")
manager.toggle_claude_code()
manager.toggle_gemini()
vim.wait(100)

manager.reset()
vim.wait(50)

local reset_status = manager.get_status()
test_assert(not reset_status.claude_code.visible, "重置後 Claude Code 已隱藏")
test_assert(not reset_status.gemini.visible, "重置後 Gemini 已隱藏")
test_assert(not reset_status.busy, "重置後系統不忙碌")

-- 測試 8: 統一 API
print("\n9. 🔌 統一 API 測試")
local unified_api = require('utils.terminal.init')

local system_info = unified_api.get_system_info()
test_assert(system_info ~= nil, "系統資訊獲取")
test_assert(system_info.version ~= nil, "版本資訊存在")

local registered_terminals = unified_api.list_registered_terminals()
test_assert(type(registered_terminals) == "table", "註冊終端列表")

-- 最終清理
print("\n10. 🏁 最終清理")
manager.reset()

-- 結果統計
print(string.rep("=", 50))
print("📊 測試結果")
print(string.rep("=", 50))

local success_rate = test_count > 0 and (pass_count / test_count * 100) or 0

print(string.format("總測試數: %d", test_count))
print(string.format("通過測試: %d", pass_count))
print(string.format("失敗測試: %d", test_count - pass_count))
print(string.format("成功率: %.1f%%", success_rate))

if pass_count == test_count then
  print("\n🎉 所有基本功能測試通過！")
  print("✅ 系統工作正常")
else
  print(string.format("\n⚠️ %d 個測試失敗", test_count - pass_count))
end

-- 性能評估
local rating = "優秀"
if success_rate < 80 then
  rating = "需要改善"
elseif success_rate < 95 then
  rating = "良好" 
end

print(string.format("🎯 整體評估: %s", rating))

return {
  success = pass_count == test_count,
  success_rate = success_rate,
  total_tests = test_count,
  passed_tests = pass_count,
  failed_tests = test_count - pass_count
}