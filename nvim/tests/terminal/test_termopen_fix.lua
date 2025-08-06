-- 測試 termopen 錯誤修復
-- 驗證 "Vim:jobstart(...,{term=true}) requires unmodified buffer" 是否已修復

-- 設定測試環境路徑
package.path = package.path .. ';' .. vim.fn.expand('~/.config/nvim/lua') .. '/?.lua'

-- 測試函數
local function test_termopen_fix()
  print("🧪 測試 termopen 錯誤修復...")
  
  -- 模擬有修改的 buffer 環境
  local test_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(test_buf)
  
  -- 模擬 buffer 有修改
  vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {"test content"})
  vim.bo[test_buf].modified = true
  
  print("  📝 當前 buffer 狀態:")
  print("    - Buffer ID: " .. test_buf)
  print("    - Modified: " .. tostring(vim.bo[test_buf].modified))
  
  -- 嘗試使用 Gemini 終端
  print("  🚀 嘗試開啟 Gemini 終端...")
  
  local success, gemini = pcall(require, 'utils.terminal.adapters.gemini')
  if not success then
    print("  ❌ 無法載入 Gemini 模組: " .. tostring(gemini))
    return false
  end
  
  -- 測試 show 功能
  local show_success = pcall(gemini.show)
  if show_success then
    print("  ✅ Gemini 終端開啟成功 (termopen 錯誤已修復)")
    
    -- 清理測試
    pcall(gemini.hide)
    return true
  else
    print("  ❌ Gemini 終端開啟失敗")
    return false
  end
end

-- 測試核心 API
local function test_core_api_fix()
  print("\n🔧 測試核心 API 修復...")
  
  local success, core = pcall(require, 'utils.terminal.core')
  if not success then
    print("  ❌ 無法載入核心模組: " .. tostring(core))
    return false
  end
  
  -- 創建測試配置
  local test_config = {
    name = "test_terminal",
    command = "gemini",
    title = "Test Terminal"
  }
  
  -- 模擬修改過的 buffer 環境
  local current_buf = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_is_valid(current_buf) then
    vim.bo[current_buf].modified = true
    print("  📝 設置當前 buffer 為已修改狀態")
  end
  
  -- 測試核心 API
  local api_success = pcall(core.open_terminal, test_config)
  if api_success then
    print("  ✅ 核心 API 測試成功")
    
    -- 清理
    pcall(core.close_terminal, "test_terminal")
    return true
  else
    print("  ❌ 核心 API 測試失敗")
    return false
  end
end

-- 運行所有測試
local function run_all_tests()
  print("🎯 開始 termopen 修復驗證測試...\n")
  
  local gemini_test = test_termopen_fix()
  local core_test = test_core_api_fix()
  
  print("\n📊 測試結果:")
  print("  Gemini 終端測試: " .. (gemini_test and "✅ 通過" or "❌ 失敗"))
  print("  核心 API 測試: " .. (core_test and "✅ 通過" or "❌ 失敗"))
  
  if gemini_test and core_test then
    print("\n🎉 所有測試通過！'termopen requires unmodified buffer' 錯誤已修復")
    return true
  else
    print("\n⚠️ 部分測試失敗，可能仍存在問題")
    return false
  end
end

-- 如果直接執行此文件，運行測試
if ... == nil then
  local success = run_all_tests()
  os.exit(success and 0 or 1)
end

return {
  test_termopen_fix = test_termopen_fix,
  test_core_api_fix = test_core_api_fix,
  run_all_tests = run_all_tests
}