# 擴展指南

本指南幫助開發者擴展和自定義 Neovim AI 工具整合系統。

## 🔧 系統概述

系統採用模組化設計，主要組件：
- **Terminal Manager** - 協調器，管理所有終端
- **Adapters** - 各 AI 工具的適配器
- **Core Services** - 核心功能（狀態管理、安全、UI）
- **Unified API** - 統一的對外介面

## 🚀 添加新的 AI 工具

### 1. 創建適配器模組

創建 `lua/utils/terminal/adapters/newtool.lua`：

```lua
-- Terminal NewTool Adapter
local M = {}

-- 載入必要的模組
local state = require('utils.terminal.state')
local core = require('utils.terminal.core')
local error_handler = require('utils.error-handler')

-- 工具特定配置
local NEWTOOL_CONFIG = {
  name = "newtool",
  command = "/path/to/newtool", -- 工具的可執行檔路徑
  title = "NewTool AI Assistant",
  ui_config = {
    width = 0.8,
    height = 0.8,
    border = "rounded"
  }
}

-- 【必需】開啟終端
function M.open(options)
  options = options or {}
  local config = vim.tbl_deep_extend("force", NEWTOOL_CONFIG, options)
  
  -- 檢查工具是否可用
  if not M.is_tool_available() then
    vim.notify("❌ NewTool 未安裝或無法執行", vim.log.levels.ERROR)
    return false
  end
  
  -- 如果已經開啟，顯示現有終端
  if M.is_visible() then
    return M.show_existing()
  end
  
  -- 使用核心 API 創建終端
  local success, result = core.open_terminal(config)
  if success then
    -- 更新狀態
    state.set_terminal_state("newtool", {
      buf = result.buf,
      win = result.win,
      job_id = result.job_id,
      created_at = vim.fn.localtime()
    })
    
    vim.notify("✅ NewTool 已開啟", vim.log.levels.INFO)
    return true
  else
    vim.notify("❌ NewTool 開啟失敗: " .. (result or "未知錯誤"), vim.log.levels.ERROR)
    return false
  end
end

-- 【必需】關閉終端
function M.close()
  local terminal_state = state.get_terminal_state("newtool")
  if not terminal_state then
    return true -- 已經關閉
  end
  
  local success = core.close_terminal("newtool")
  if success then
    state.remove_terminal_state("newtool")
    vim.notify("NewTool 已關閉", vim.log.levels.INFO)
  end
  
  return success
end

-- 【必需】切換顯示狀態
function M.toggle(options)
  if M.is_visible() then
    return M.hide()
  else
    return M.show(options)
  end
end

-- 【必需】檢查是否可見
function M.is_visible()
  local terminal_state = state.get_terminal_state("newtool")
  if not terminal_state or not terminal_state.win then
    return false
  end
  
  return state.is_win_valid(terminal_state.win)
end

-- 【必需】健康檢查
function M.health_check()
  local issues = {}
  local health_ok = true
  
  -- 檢查工具可用性
  if not M.is_tool_available() then
    table.insert(issues, "NewTool 工具未安裝或無法執行")
    health_ok = false
  end
  
  -- 檢查終端狀態
  local terminal_state = state.get_terminal_state("newtool")
  if terminal_state then
    if terminal_state.buf and not state.is_buf_valid(terminal_state.buf) then
      table.insert(issues, "NewTool buffer 無效")
      health_ok = false
    end
    
    if terminal_state.win and not state.is_win_valid(terminal_state.win) then
      table.insert(issues, "NewTool window 無效")
      health_ok = false
    end
  end
  
  return health_ok, issues
end

-- 【必需】獲取狀態
function M.get_status()
  local terminal_state = state.get_terminal_state("newtool") or {}
  
  return {
    name = "newtool",
    available = M.is_tool_available(),
    visible = M.is_visible(),
    buf = terminal_state.buf,
    win = terminal_state.win,
    job_id = terminal_state.job_id,
    created_at = terminal_state.created_at,
    last_active = terminal_state.last_active
  }
end

-- 輔助函數：檢查工具可用性
function M.is_tool_available()
  local handle = io.popen("which " .. NEWTOOL_CONFIG.command .. " 2>/dev/null")
  if not handle then
    return false
  end
  
  local result = handle:read("*a")
  handle:close()
  
  return result and result:match("%S") ~= nil
end

-- 輔助函數：顯示現有終端
function M.show_existing()
  local terminal_state = state.get_terminal_state("newtool")
  if not terminal_state or not terminal_state.buf then
    return false
  end
  
  -- 重新創建浮動視窗
  local ui = require('utils.terminal.ui')
  local win = ui.create_floating_window(terminal_state.buf, NEWTOOL_CONFIG.ui_config)
  
  if win then
    state.set_terminal_state("newtool", { win = win })
    return true
  end
  
  return false
end

-- 輔助函數：隱藏終端
function M.hide()
  local terminal_state = state.get_terminal_state("newtool")
  if terminal_state and terminal_state.win and state.is_win_valid(terminal_state.win) then
    vim.api.nvim_win_close(terminal_state.win, true)
    state.set_terminal_state("newtool", { win = nil })
  end
  return true
end

-- 輔助函數：顯示終端
function M.show(options)
  return M.open(options)
end

-- 【可選】銷毀終端
function M.destroy()
  M.close()
  return true
end

-- 【可選】版本遷移
function M.migrate_from_old_version()
  -- 如果有舊版本的配置需要遷移，在這裡處理
  return true
end

return M
```

### 2. 註冊新工具

在 `lua/utils/terminal/init.lua` 中添加自動註冊：

```lua
-- 在 auto_register_terminals 函數中添加
local function auto_register_terminals()
  -- 現有的 Claude 和 Gemini 註冊...
  
  -- 註冊 NewTool
  local newtool_ok, newtool_adapter = pcall(require, 'utils.terminal/adapters/newtool')
  if newtool_ok then
    M.register_terminal('newtool', newtool_adapter)
  end
end
```

### 3. 添加快捷鍵

在 `lua/mappings.lua` 中添加：

```lua
-- 添加到 terminal 相關映射區域
map("n", "<leader>nt", function()
  require("utils.terminal/adapters/newtool").toggle()
end, { desc = "Toggle NewTool" })

-- 或者使用統一 API
map("n", "<leader>nt", function()
  local terminal_api = require("utils.terminal.init")
  terminal_api.toggle_terminal("newtool")
end, { desc = "Toggle NewTool" })
```

### 4. 測試新工具

創建測試檔案 `tests/terminal/test_newtool.lua`：

```lua
-- NewTool 適配器測試
local newtool = require('utils.terminal/adapters/newtool')
local state = require('utils.terminal.state')

-- 測試基本功能
print("🧪 測試 NewTool 適配器")

-- 1. 健康檢查
local health_ok, issues = newtool.health_check()
print("健康檢查:", health_ok and "✅" or "❌")
if not health_ok then
  for _, issue in ipairs(issues) do
    print("  問題:", issue)
  end
end

-- 2. 狀態測試
local status = newtool.get_status()
print("工具可用:", status.available and "✅" or "❌")
print("當前可見:", status.visible and "✅" or "❌")

-- 3. 開關測試（如果工具可用）
if status.available then
  print("\n開始開關測試...")
  
  local open_success = newtool.open()
  print("開啟測試:", open_success and "✅" or "❌")
  
  vim.wait(1000) -- 等待 1 秒
  
  local close_success = newtool.close()
  print("關閉測試:", close_success and "✅" or "❌")
end

print("NewTool 測試完成")
```

## 🔧 自定義現有功能

### 1. 修改 UI 設計

創建自定義 UI 配置：

```lua
-- 在 lua/configs/ui-custom.lua
local M = {}

-- 自定義浮動視窗樣式
M.terminal_ui_styles = {
  -- 全螢幕模式
  fullscreen = {
    relative = "editor",
    width = 1.0,
    height = 1.0,
    border = "none"
  },
  
  -- 緊湊模式
  compact = {
    relative = "cursor",
    width = 60,
    height = 20,
    border = "single"
  },
  
  -- 分割模式
  split = {
    split = "vertical",
    size = 0.5
  }
}

-- 動態選擇樣式
function M.get_ui_config(style_name)
  return M.terminal_ui_styles[style_name] or M.terminal_ui_styles.default
end

return M
```

### 2. 添加自定義命令

在 `lua/utils/custom-commands.lua`：

```lua
-- 自定義命令集
local M = {}

-- 創建命令
function M.setup()
  -- AI 工具管理命令
  vim.api.nvim_create_user_command('ClaudeToggle', function()
    require('utils.terminal.manager').toggle_claude_code()
  end, { desc = 'Toggle Claude Code terminal' })
  
  vim.api.nvim_create_user_command('GeminiToggle', function()
    require('utils.terminal.manager').toggle_gemini()
  end, { desc = 'Toggle Gemini terminal' })
  
  vim.api.nvim_create_user_command('AISwitch', function()
    require('utils.terminal.manager').switch_terminal()
  end, { desc = 'Smart switch between AI terminals' })
  
  -- 健康檢查命令
  vim.api.nvim_create_user_command('AIHealth', function()
    require('utils.terminal.manager').health_check()
  end, { desc = 'Run AI terminal health check' })
  
  -- 性能報告命令
  vim.api.nvim_create_user_command('AIPerf', function()
    require('utils.performance-monitor').show_report()
  end, { desc = 'Show AI terminal performance report' })
end

return M
```

在 `init.lua` 中載入：

```lua
-- 載入自定義命令
require('utils.custom-commands').setup()
```

### 3. 擴展剪貼板功能

創建 `lua/utils/clipboard-extensions.lua`：

```lua
-- 剪貼板擴展功能
local M = {}
local clipboard = require('utils.clipboard')

-- 代碼塊增強複製
function M.copy_code_block_enhanced()
  local selection = clipboard.get_visual_selection()
  if not selection.content then
    return
  end
  
  -- 添加語言標記
  local filetype = vim.bo.filetype
  local enhanced_content = string.format("```%s\n%s\n```", filetype, selection.content)
  
  -- 複製到剪貼板
  vim.fn.setreg('+', enhanced_content)
  vim.notify(string.format("✅ 複製代碼塊 (%s 行)", selection.line_count), vim.log.levels.INFO)
end

-- 函數文檔複製
function M.copy_function_with_docs()
  -- 找到函數開始和結束
  local start_line = vim.fn.search('^\\s*function\\|^\\s*local function', 'bn')
  local end_line = vim.fn.search('^end$', 'n')
  
  if start_line == 0 or end_line == 0 then
    vim.notify("❌ 找不到函數邊界", vim.log.levels.WARN)
    return
  end
  
  -- 獲取函數內容
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local content = table.concat(lines, '\n')
  
  -- 添加檔案資訊
  local filename = vim.fn.expand('%:t')
  local enhanced_content = string.format("-- From %s:%d-%d\n%s", filename, start_line, end_line, content)
  
  vim.fn.setreg('+', enhanced_content)
  vim.notify("✅ 複製函數和文檔", vim.log.levels.INFO)
end

-- 快捷鍵設置
function M.setup_keymaps()
  vim.keymap.set('v', '<leader>cb', M.copy_code_block_enhanced, { desc = 'Copy code block enhanced' })
  vim.keymap.set('n', '<leader>cf', M.copy_function_with_docs, { desc = 'Copy function with docs' })
end

return M
```

## 🔍 除錯和診斷

### 1. 添加除錯模式

創建 `lua/utils/debug-helpers.lua`：

```lua
-- 除錯輔助工具
local M = {}

-- 全局除錯開關
M.debug_enabled = false

-- 啟用除錯模式
function M.enable_debug()
  M.debug_enabled = true
  vim.notify("🐛 除錯模式已啟用", vim.log.levels.INFO)
end

-- 除錯日誌
function M.debug_log(module, message, data)
  if not M.debug_enabled then
    return
  end
  
  local timestamp = os.date("%H:%M:%S")
  local log_message = string.format("[%s] %s: %s", timestamp, module, message)
  
  if data then
    log_message = log_message .. "\n" .. vim.inspect(data)
  end
  
  print(log_message)
end

-- 狀態快照
function M.capture_state_snapshot()
  local snapshot = {
    timestamp = os.date("%Y-%m-%d %H:%M:%S"),
    terminal_manager = require('utils.terminal.manager').get_status(),
    terminal_state = require('utils.terminal.state').get_status(),
    performance = require('utils.performance-monitor').get_performance_stats(),
  }
  
  local filename = string.format("/tmp/nvim_debug_%s.json", os.date("%Y%m%d_%H%M%S"))
  local file = io.open(filename, "w")
  if file then
    file:write(vim.json.encode(snapshot))
    file:close()
    vim.notify("🔍 狀態快照已保存: " .. filename, vim.log.levels.INFO)
  end
  
  return snapshot
end

return M
```

### 2. 性能分析工具

創建 `lua/utils/profiler.lua`：

```lua
-- 簡單的性能分析器
local M = {}

-- 分析數據存儲
M.profiles = {}

-- 開始分析
function M.start_profile(name)
  M.profiles[name] = {
    start_time = vim.loop.hrtime(),
    name = name
  }
end

-- 結束分析
function M.end_profile(name)
  local profile = M.profiles[name]
  if not profile then
    return
  end
  
  local end_time = vim.loop.hrtime()
  local duration_ms = (end_time - profile.start_time) / 1e6
  
  print(string.format("⏱️ %s: %.2fms", name, duration_ms))
  
  M.profiles[name] = nil
  return duration_ms
end

-- 包裝函數進行分析
function M.profile_function(name, func)
  M.start_profile(name)
  local result = func()
  M.end_profile(name)
  return result
end

return M
```

## 📊 監控和指標

### 1. 自定義指標收集

創建 `lua/utils/custom-metrics.lua`：

```lua
-- 自定義指標收集
local M = {}

-- 指標存儲
M.metrics = {
  ai_interactions = 0,
  code_snippets_sent = 0,
  terminal_switches = 0,
  errors_recovered = 0,
}

-- 記錄 AI 互動
function M.record_ai_interaction(tool_name)
  M.metrics.ai_interactions = M.metrics.ai_interactions + 1
  M.metrics[tool_name .. "_interactions"] = (M.metrics[tool_name .. "_interactions"] or 0) + 1
end

-- 記錄代碼片段發送
function M.record_code_snippet_sent(lines_count)
  M.metrics.code_snippets_sent = M.metrics.code_snippets_sent + 1
  M.metrics.total_lines_sent = (M.metrics.total_lines_sent or 0) + lines_count
end

-- 獲取指標報告
function M.get_metrics_report()
  local report = "📊 使用統計報告\n"
  report = report .. string.format("AI 互動次數: %d\n", M.metrics.ai_interactions)
  report = report .. string.format("代碼片段發送: %d\n", M.metrics.code_snippets_sent)
  report = report .. string.format("終端切換次數: %d\n", M.metrics.terminal_switches)
  report = report .. string.format("錯誤恢復次數: %d\n", M.metrics.errors_recovered)
  
  return report
end

-- 重置指標
function M.reset_metrics()
  M.metrics = {
    ai_interactions = 0,
    code_snippets_sent = 0,
    terminal_switches = 0,
    errors_recovered = 0,
  }
end

return M
```

## 🧪 測試框架

### 1. 單元測試模板

創建 `tests/template_test.lua`：

```lua
-- 測試模板
local function run_test_suite(module_name, test_functions)
  print(string.format("🧪 開始測試 %s", module_name))
  
  local passed = 0
  local failed = 0
  
  for test_name, test_func in pairs(test_functions) do
    local success, error_msg = pcall(test_func)
    
    if success then
      print(string.format("  ✅ %s", test_name))
      passed = passed + 1
    else
      print(string.format("  ❌ %s: %s", test_name, error_msg))
      failed = failed + 1
    end
  end
  
  print(string.format("📊 %s 測試完成: %d 通過, %d 失敗", module_name, passed, failed))
  return failed == 0
end

-- 測試輔助函數
local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(message or string.format("Expected %s, got %s", expected, actual))
  end
end

local function assert_true(condition, message)
  if not condition then
    error(message or "Assertion failed")
  end
end

-- 導出測試工具
return {
  run_test_suite = run_test_suite,
  assert_equal = assert_equal,
  assert_true = assert_true,
}
```

## 🎯 最佳實踐

### 1. 錯誤處理
- 使用 `pcall` 包裝可能失敗的操作
- 提供有意義的錯誤訊息
- 實現優雅的降級機制

### 2. 性能考量
- 避免阻塞操作
- 使用異步 API
- 適當的緩存策略

### 3. 用戶體驗
- 提供即時回饋
- 保持操作一致性
- 優雅的錯誤恢復

### 4. 可維護性
- 遵循現有的代碼風格
- 添加適當的文檔
- 編寫測試用例

## 📝 貢獻指南

1. **Fork 專案**並創建功能分支
2. **遵循代碼規範**和現有架構
3. **添加測試**確保功能正確
4. **更新文檔**反映變更
5. **提交 Pull Request**

記住：好的擴展應該與現有系統無縫整合，提升而不是複雜化用戶體驗！