require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- ============================================================================
-- 智能剪貼板系統按鍵映射 (優化版 - 按功能分組)
-- ============================================================================
-- 
-- 🎯 推薦工作流程：
-- 1. 優先使用：<leader>cr (檔案引用) - 大幅節省 token
-- 2. 如果 AI 無法存取檔案：<leader>cp (完整內容)
--
-- 📋 主要操作 (Core - 日常使用)：
-- <leader>cr   - 檔案引用 (簡潔): /path/file.pl:62-110
-- <leader>cp   - 完整內容 (自動分段): 傳統複製模式  
-- <leader>cs   - 發送到 Claude Code
--
-- 📋 進階選項 (Advanced - 特殊需求)：
-- <leader>cR   - 檔案引用 (詳細): 包含工作目錄等上下文
-- <leader>cC   - 壓縮格式: 移除多餘空格
-- <leader>cf   - 僅存檔案: 不複製到剪貼板
--
-- 📋 輔助工具 (Utils)：
-- <leader>cn   - 下一段: 分段模式後使用
-- <leader>cd   - 診斷剪貼板支援
-- ============================================================================

-- ============================================================================
-- Markdown 渲染控制 (render-markdown.nvim)
-- ============================================================================
map("n", "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", { desc = "Toggle markdown rendering" })
map("n", "<leader>me", "<cmd>RenderMarkdown enable<cr>", { desc = "Enable markdown rendering" })
map("n", "<leader>md", "<cmd>RenderMarkdown disable<cr>", { desc = "Disable markdown rendering" })
map("n", "<leader>mc", "<cmd>RenderMarkdown config<cr>", { desc = "Show markdown config diff" })

-- 主要操作 (Core Operations) - 80% 使用場景，延遲載入 clipboard 模組
map("v", "<leader>cr", function() 
  local clipboard = require("utils.clipboard")
  clipboard.copy_file_reference(false) 
end, { desc = "Copy file reference (saves tokens!)" })

map("v", "<leader>cp", function()
  local clipboard = require("utils.clipboard")
  clipboard.copy_with_path()
end, { desc = "Copy with full content (auto-segment)" })

map("v", "<leader>cs", function()
  local clipboard = require("utils.clipboard")
  clipboard.send_to_claude()
end, { desc = "Send to Claude Code" })

-- 進階選項 (Advanced Options) - 特殊需求
map("v", "<leader>cR", function() 
  local clipboard = require("utils.clipboard")
  clipboard.copy_file_reference(true) 
end, { desc = "Copy detailed file reference" })

map("v", "<leader>cC", function()
  local clipboard = require("utils.clipboard")
  clipboard.copy_compressed()
end, { desc = "Copy in compressed format (no metadata)" })

map("v", "<leader>cf", function()
  local clipboard = require("utils.clipboard")
  clipboard.copy_to_file_only()
end, { desc = "Save to file only" })

-- 輔助工具 (Utilities)
map("n", "<leader>cn", function()
  local clipboard = require("utils.clipboard")
  clipboard.copy_next_segment()
end, { desc = "Copy next segment" })

map("n", "<leader>cd", function()
  local clipboard = require("utils.clipboard")
  clipboard.diagnose_clipboard()
end, { desc = "Diagnose clipboard support" })

-- ============================================================================
-- GitHub Copilot 按鍵映射 (優化版 - 合併為智能切換)
-- ============================================================================
-- 
-- 🤖 Copilot 管理 (優化至 2 個按鍵)：
-- <leader>co   - 智能切換 Copilot (檢查狀態 → 切換)
-- <leader>cO   - Copilot 設定選單 (狀態/認證/重啟)
-- ============================================================================

-- 智能 Copilot 切換
local function toggle_copilot()
  -- 先檢查狀態
  vim.cmd("Copilot status")
  
  -- 延遲執行切換邏輯，讓狀態顯示完成
  vim.defer_fn(function()
    -- 簡單的切換邏輯：假設大部分時候使用者想要切換狀態
    local copilot_enabled = vim.g.copilot_enabled ~= false
    if copilot_enabled then
      vim.cmd("Copilot disable")
      vim.notify("Copilot disabled", vim.log.levels.INFO)
    else
      vim.cmd("Copilot enable")
      vim.notify("Copilot enabled", vim.log.levels.INFO)
    end
  end, 500)
end

-- Copilot 設定選單
local function copilot_menu()
  local choices = {
    "1. Check Status",
    "2. Enable",
    "3. Disable", 
    "4. Authenticate",
    "5. Restart"
  }
  
  vim.ui.select(choices, {
    prompt = "Copilot Management:",
  }, function(choice)
    if not choice then return end
    
    local cmd_map = {
      ["1. Check Status"] = "Copilot status",
      ["2. Enable"] = "Copilot enable",
      ["3. Disable"] = "Copilot disable",
      ["4. Authenticate"] = "Copilot auth", 
      ["5. Restart"] = "Copilot restart"
    }
    
    if cmd_map[choice] then
      vim.cmd(cmd_map[choice])
    end
  end)
end

map("n", "<leader>co", toggle_copilot, { desc = "Toggle Copilot (smart)" })
map("n", "<leader>cO", copilot_menu, { desc = "Copilot management menu" })

-- ============================================================================
-- 🔍 效能監控系統
-- ============================================================================
-- 
-- 快速存取效能狀態和分析工具：
-- <leader>pf   - 效能狀態 (即時資訊) - 避免與 session 衝突
-- <leader>pr   - 效能報告 (詳細分析)
-- <leader>pb   - 執行效能基準測試
-- <leader>pm   - 切換監控狀態 (啟用/停用)
-- ============================================================================

-- 效能監控快速操作 - 延遲載入避免啟動開銷
map("n", "<leader>pf", function()
  local perf_monitor = require('utils.performance-monitor')
  perf_monitor.show_status()
end, { desc = "Performance Status" })

map("n", "<leader>pr", function()
  local perf_monitor = require('utils.performance-monitor')
  perf_monitor.show_report()
end, { desc = "Performance Report" })

map("n", "<leader>pb", function()
  local perf_monitor = require('utils.performance-monitor')
  perf_monitor.run_benchmarks()
end, { desc = "Performance Benchmarks" })

map("n", "<leader>pm", function()
  local perf_monitor = require('utils.performance-monitor')
  perf_monitor.toggle_monitoring()
end, { desc = "Toggle performance Monitoring" })

-- ============================================================================
-- 🛠️ 按鍵映射管理工具
-- ============================================================================
-- 
-- 按鍵映射衝突檢測和管理：
-- <leader><leader>m - 檢查 leader 映射
-- <leader><leader>l - 切換 leader key (空白鍵 ↔ 逗號)
-- <leader><leader>t - 測試按鍵延遲
-- ============================================================================

-- 檢查所有 leader 映射
local function check_leader_mappings()
  local mappings = vim.api.nvim_get_keymap('n')
  local leader_mappings = {}
  
  for _, mapping in ipairs(mappings) do
    if mapping.lhs and (mapping.lhs:match('^<Space>') or mapping.lhs:match('^ ')) then
      local desc = mapping.desc or 'No description'
      local rhs = mapping.rhs or '[Function]'
      table.insert(leader_mappings, string.format("%-20s -> %s", mapping.lhs, desc))
    end
  end
  
  -- 使用 vim.notify 顯示結果
  if #leader_mappings > 0 then
    vim.notify("Leader Key Mappings:\n" .. table.concat(leader_mappings, '\n'), vim.log.levels.INFO)
  else
    vim.notify("No leader mappings found", vim.log.levels.WARN)
  end
end

-- Leader key 切換功能
local function toggle_leader()
  if vim.g.mapleader == " " then
    vim.g.mapleader = ","
    vim.notify("Leader key changed to ',' (comma)", vim.log.levels.INFO)
  else
    vim.g.mapleader = " "
    vim.notify("Leader key changed to '<Space>' (space)", vim.log.levels.INFO)
  end
  
  -- 提示使用者重新載入配置
  vim.notify("Note: Restart Neovim or reload config for full effect", vim.log.levels.WARN)
end

-- 測試按鍵延遲
local function test_key_delay()
  local start_time = vim.loop.hrtime()
  
  vim.defer_fn(function()
    local end_time = vim.loop.hrtime()
    local delay_ms = (end_time - start_time) / 1000000
    vim.notify(string.format("Current timeoutlen: %dms\nActual delay: %.1fms", vim.o.timeoutlen, delay_ms), vim.log.levels.INFO)
  end, vim.o.timeoutlen + 50)
  
  vim.notify("Press any key within " .. vim.o.timeoutlen .. "ms...", vim.log.levels.INFO)
end

map("n", "<leader><leader>m", check_leader_mappings, { desc = "Check leader mappings" })
map("n", "<leader><leader>l", toggle_leader, { desc = "Toggle leader key" })
map("n", "<leader><leader>t", test_key_delay, { desc = "Test key delay" })

-- ============================================================================
-- 🚀 Terminal Management System (Plan A - Lightweight Adapter Architecture)
-- ============================================================================
-- 
-- 終端快捷鍵映射 - 重構後的輕量適配器架構
-- <leader>cc   - 切換 Claude Code 終端
-- <leader>gm   - 切換 Gemini CLI 終端  
-- <leader>tt   - 智能終端切換 (Claude ↔ Gemini)
-- ============================================================================

-- 終端管理映射 - 延遲載入管理器
map("n", "<leader>cc", function()
  local manager = require('utils.terminal.manager')
  manager.toggle_claude_code()
end, { desc = "Toggle Claude Code Terminal" })

map("n", "<leader>gm", function()
  local manager = require('utils.terminal.manager')
  manager.toggle_gemini()
end, { desc = "Toggle Gemini CLI Terminal" })

map("n", "<leader>tt", function()
  local manager = require('utils.terminal.manager')
  manager.switch_terminal()
end, { desc = "Smart Terminal Switch (Claude ↔ Gemini)" })

-- 其他原有快捷鍵保留
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- ===========================================================================
-- Buffer Navigation
-- ===========================================================================
--
-- Switch between buffers using <Leader> + number
-- e.g., <Leader>1 switches to the first buffer
-- ===========================================================================

for i = 1, 9, 1 do
  vim.keymap.set("n", string.format("<Leader>%s", i), function()
    -- Check if the buffer exists before switching
    if vim.t.bufs and vim.t.bufs[i] then
      vim.api.nvim_set_current_buf(vim.t.bufs[i])
    else
      vim.notify("Buffer " .. i .. " does not exist", vim.log.levels.WARN)
    end
  end, { desc = "Switch to buffer " .. i })
end
