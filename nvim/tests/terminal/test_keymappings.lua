-- 測試終端快捷鍵映射功能
-- 驗證 Plan A 重構後的快捷鍵是否正常工作

local M = {}

function M.test_keymappings()
  vim.notify("🧪 開始測試終端快捷鍵映射...", vim.log.levels.INFO)
  
  local results = {
    total_tests = 0,
    passed_tests = 0,
    failed_tests = 0,
    issues = {}
  }
  
  local function test_assert(condition, message)
    results.total_tests = results.total_tests + 1
    if condition then
      results.passed_tests = results.passed_tests + 1
      vim.notify("✅ " .. message, vim.log.levels.INFO)
      return true
    else
      results.failed_tests = results.failed_tests + 1
      table.insert(results.issues, message)
      vim.notify("❌ " .. message, vim.log.levels.ERROR)
      return false
    end
  end
  
  -- 檢查快捷鍵映射是否存在
  local mappings = vim.api.nvim_get_keymap('n')
  local found_mappings = {}
  
  for _, mapping in ipairs(mappings) do
    if mapping.lhs then
      if mapping.lhs:match('<Space>cc') then
        found_mappings['<leader>cc'] = true
      elseif mapping.lhs:match('<Space>gm') then
        found_mappings['<leader>gm'] = true
      elseif mapping.lhs:match('<Space>tt') then
        found_mappings['<leader>tt'] = true
      end
    end
  end
  
  test_assert(found_mappings['<leader>cc'], "Claude Code 快捷鍵 <leader>cc 已映射")
  test_assert(found_mappings['<leader>gm'], "Gemini 快捷鍵 <leader>gm 已映射")
  test_assert(found_mappings['<leader>tt'], "終端切換快捷鍵 <leader>tt 已映射")
  
  -- 測試快捷鍵功能
  local manager_ok, manager = pcall(require, 'utils.terminal.manager')
  test_assert(manager_ok, "終端管理器模組載入成功")
  
  if manager_ok then
    -- 測試 toggle_claude_code 函數
    test_assert(type(manager.toggle_claude_code) == "function", "toggle_claude_code 函數存在")
    
    -- 測試 toggle_gemini 函數
    test_assert(type(manager.toggle_gemini) == "function", "toggle_gemini 函數存在")
    
    -- 測試 switch_terminal 函數
    test_assert(type(manager.switch_terminal) == "function", "switch_terminal 函數存在")
    
    -- 實際執行快捷鍵功能測試（不開啟UI）
    local claude_success = pcall(function()
      local status_before = manager.get_status()
      manager.toggle_claude_code()
      local status_after = manager.get_status()
      return true
    end)
    test_assert(claude_success, "Claude Code 切換功能運行")
    
    local gemini_success = pcall(function()
      local status_before = manager.get_status()
      manager.toggle_gemini()
      local status_after = manager.get_status()
      return true
    end)
    test_assert(gemini_success, "Gemini 切換功能運行")
    
    local switch_success = pcall(function()
      manager.switch_terminal()
      return true
    end)
    test_assert(switch_success, "智能終端切換功能運行")
  end
  
  -- 生成報告
  local success_rate = results.total_tests > 0 and 
    (results.passed_tests / results.total_tests * 100) or 0
  
  local report = string.format([[
🧪 快捷鍵映射測試報告
═══════════════════════════════════════
📊 測試結果：
   • 總測試數：%d
   • 通過測試：%d
   • 失敗測試：%d
   • 成功率：%.1f%%

🎯 快捷鍵狀態：
   • <leader>cc (Claude Code)：%s
   • <leader>gm (Gemini CLI)：%s
   • <leader>tt (智能切換)：%s

%s
════════════════════════════════════════
]], results.total_tests, results.passed_tests, results.failed_tests, success_rate,
    found_mappings['<leader>cc'] and "✅ 已配置" or "❌ 缺失",
    found_mappings['<leader>gm'] and "✅ 已配置" or "❌ 缺失", 
    found_mappings['<leader>tt'] and "✅ 已配置" or "❌ 缺失",
    success_rate == 100 and "🎉 所有快捷鍵映射正常工作！" or "⚠️ 部分快捷鍵有問題，請檢查。"
  )
  
  if #results.issues > 0 then
    report = report .. "\n❌ 發現的問題：\n"
    for i, issue in ipairs(results.issues) do
      report = report .. string.format("   %d. %s\n", i, issue)
    end
  end
  
  vim.notify(report, vim.log.levels.INFO)
  
  return results
end

return M