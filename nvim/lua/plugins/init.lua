-- 所有插件已鎖定穩定版本以確保相容性和安全性
-- 更新插件版本時請先在測試環境驗證
return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    tag = "v8.1.0",  -- 鎖定穩定版本
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    tag = "v1.2.0",  -- 鎖定穩定版本
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Claude Code AI Assistant
  {
    "greggh/claude-code.nvim",
    -- 移除無效的 commit，使用最新穩定版本
    lazy = false,  -- 確保立即載入，不延遲
    priority = 100, -- 提高優先級確保早期載入
    config = function()
      -- 確保插件正確設置
      local claude_code = require("claude-code")
      claude_code.setup({
        window = {
          position = "float",
          float = {
            width = "90%",      -- Take up 90% of the editor width
            height = "90%",     -- Take up 90% of the editor height
            row = "center",     -- Center vertically
            col = "center",     -- Center horizontally
            relative = "editor",
            border = "double",  -- Use double border style
          },
        },
      })
      
      -- 延遲註冊按鍵映射，確保命令已註冊
      vim.defer_fn(function()
        local map = vim.keymap.set
        
        -- 主要切換按鍵 (替代官方的 <C-,>)
        map('n', '<leader>cc', '<cmd>ClaudeCode<CR>', { desc = 'Toggle Claude Code terminal' })
        map('t', '<leader>cc', '<cmd>ClaudeCode<CR>', { desc = 'Toggle Claude Code terminal' })
        
        -- 快速開啟按鍵
        map('n', '<leader>ai', '<cmd>ClaudeCode<CR>', { desc = 'Open Claude Code AI assistant' })
        
        -- 備用按鍵
        map('n', '<F12>', '<cmd>ClaudeCode<CR>', { desc = 'Claude Code (F12)' })
        
        -- 如果你想要模仿官方的逗號概念
        map('n', '<leader>,', '<cmd>ClaudeCode<CR>', { desc = 'Claude Code (comma alternative)' })
      end, 100) -- 100ms 延遲確保命令已註冊
    end
  },

  -- Auto-Session: Automatic session management
  {
    'rmagatti/auto-session',
    tag = "v3.2.0",  -- 鎖定穩定版本
    config = function()
      require('auto-session').setup({
        auto_restore = false,   -- 不自動恢復會話，讓用戶手動選擇
        suppressed_dirs = { "~/" }, -- 排除主目錄
        -- 其他有用選項
        auto_save = true,       -- 自動保存會話
        auto_create = true,     -- 自動創建會話文件
      })

      -- Key mappings for session management
      local map = vim.keymap.set
      
      map("n", "<leader>sl", "<cmd>SessionRestore<cr>", { desc = "Restore Session" })
      map("n", "<leader>ss", "<cmd>SessionSave<cr>", { desc = "Save Session" })
      map("n", "<leader>sd", "<cmd>SessionDelete<cr>", { desc = "Delete Session" })
      map("n", "<leader>sS", "<cmd>SessionSearch<cr>", { desc = "Search Sessions" })
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
}
