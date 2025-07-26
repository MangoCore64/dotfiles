-- Telescope 自訂配置 - 修復 C-j/C-k 導航問題
-- 基於 NvChad 預設配置，加入自訂按鍵綁定

local conf = require "nvconfig".ui.telescope

-- Telescope 動作和主題配置
local actions = require "telescope.actions"
local themes = require "telescope.themes"

-- 合併 NvChad 預設設定和自訂按鍵綁定
local options = {
  defaults = {
    prompt_prefix = "   ",
    selection_caret = " ",
    entry_prefix = " ",
    sorting_strategy = "ascending",
    layout_strategy = "horizontal",
    layout_config = {
      horizontal = {
        prompt_position = "top",
        preview_width = 0.55,
      },
      width = 0.87,
      height = 0.80,
    },
    -- 自訂按鍵綁定 - 修復 C-j/C-k 問題
    mappings = {
      i = {  -- insert 模式
        ["<C-j>"] = actions.move_selection_next,     -- 向下移動
        ["<C-k>"] = actions.move_selection_previous, -- 向上移動
        ["<C-n>"] = actions.move_selection_next,     -- 向下移動 (備用)
        ["<C-p>"] = actions.move_selection_previous, -- 向上移動 (備用)
        ["<Down>"] = actions.move_selection_next,    -- 方向鍵向下
        ["<Up>"] = actions.move_selection_previous,  -- 方向鍵向上
        ["<C-c>"] = actions.close,                   -- 關閉
        ["<C-u>"] = actions.preview_scrolling_up,    -- 預覽向上捲動
        ["<C-d>"] = actions.preview_scrolling_down,  -- 預覽向下捲動
        ["<C-x>"] = actions.select_horizontal,       -- 水平分割開啟
        ["<C-v>"] = actions.select_vertical,         -- 垂直分割開啟
        ["<C-t>"] = actions.select_tab,              -- 新分頁開啟
      },
      n = {  -- normal 模式
        ["<C-j>"] = actions.move_selection_next,     -- 向下移動
        ["<C-k>"] = actions.move_selection_previous, -- 向上移動
        ["j"] = actions.move_selection_next,         -- vim 風格向下
        ["k"] = actions.move_selection_previous,     -- vim 風格向上
        ["<Down>"] = actions.move_selection_next,    -- 方向鍵向下
        ["<Up>"] = actions.move_selection_previous,  -- 方向鍵向上
        ["gg"] = actions.move_to_top,                -- 跳到頂部
        ["G"] = actions.move_to_bottom,              -- 跳到底部
        ["q"] = actions.close,                       -- 關閉
        ["<Esc>"] = actions.close,                   -- ESC 關閉
        ["<C-u>"] = actions.preview_scrolling_up,    -- 預覽向上捲動
        ["<C-d>"] = actions.preview_scrolling_down,  -- 預覽向下捲動
        ["<C-x>"] = actions.select_horizontal,       -- 水平分割開啟
        ["<C-v>"] = actions.select_vertical,         -- 垂直分割開啟
        ["<C-t>"] = actions.select_tab,              -- 新分頁開啟
      },
    },
  },

  extensions_list = { "themes", "terms" },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  },
}

-- 如果存在 NvChad 的 telescope 配置，合併它們
if conf then
  options = vim.tbl_deep_extend("force", options, conf)
end

return options