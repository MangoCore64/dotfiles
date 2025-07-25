require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set
local clipboard = require("utils.clipboard")

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- ============================================================================
-- 智能剪貼板系統按鍵映射
-- ============================================================================
-- 
-- 🎯 推薦工作流程：
-- 1. 優先使用：<leader>cpr (檔案引用) - 大幅節省 token
-- 2. 如果 AI 無法存取檔案：<leader>cp (完整內容)
--
-- 📋 按鍵映射總覽：
-- <leader>cpr  - 檔案引用 (簡潔): /path/file.pl:62-110
-- <leader>cpR  - 檔案引用 (詳細): 包含工作目錄等上下文
-- <leader>cp   - 完整內容 (自動分段): 傳統複製模式
-- <leader>cpc  - 壓縮格式: 移除多餘空格
-- <leader>cpf  - 僅存檔案: 不複製到剪貼板
-- <leader>cps  - 下一段: 分段模式後使用
-- <leader>cs   - 發送到 Claude Code
-- ============================================================================

-- 檔案引用模式（推薦優先使用）
map("v", "<leader>cpr", function() clipboard.copy_file_reference(false) end, { desc = "Copy file reference (path:lines) - saves tokens!" })
map("v", "<leader>cpR", function() clipboard.copy_file_reference(true) end, { desc = "Copy detailed file reference with context" })

-- 完整內容模式（後備方案）
map("v", "<leader>cp", clipboard.copy_with_path, { desc = "Copy selection with full content (auto-segment if large)" })
map("v", "<leader>cs", clipboard.send_to_claude, { desc = "Send selection to Claude Code" })
map("v", "<leader>cpc", clipboard.copy_with_path_compressed, { desc = "Copy selection in compressed format" })
map("v", "<leader>cpf", clipboard.copy_to_file_only, { desc = "Save selection to file only" })

-- 輔助功能
map("n", "<leader>cps", clipboard.copy_next_segment, { desc = "Copy next segment (after segmented copy)" })
map("n", "<leader>cd", clipboard.diagnose_clipboard, { desc = "Diagnose clipboard support" })

-- 其他原有快捷鍵保留
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
