-- 所有插件已鎖定穩定版本以確保相容性和安全性
-- 更新插件版本時請先在測試環境驗證
return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    tag = "v8.1.0",  -- 鎖定穩定版本
    opts = require "configs.conform",
  },

  -- Mason: LSP server installer
  {
    "williamboman/mason.nvim",
    tag = "v1.10.0",  -- 鎖定穩定版本
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗"
        }
      }
    },
  },

  -- Mason LSP Config: Bridge between mason and lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    tag = "v1.29.0",  -- 鎖定穩定版本
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "html-lsp",
        "css-lsp", 
        "json-lsp",
        "eslint-lsp",
        "typescript-language-server",
        "phpactor",
        "perlnavigator",
        "volar"
      },
      automatic_installation = true,
    },
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    tag = "v1.2.0",  -- 鎖定穩定版本
    dependencies = { "williamboman/mason-lspconfig.nvim" },
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
        local terminal_manager = require('utils.terminal-manager-v2')
        
        -- 主要切換按鍵 (智能檢測版本)
        map('n', '<leader>cc', function()
          terminal_manager.toggle_claude_code()
        end, { desc = 'Toggle Claude Code (smart detection)' })
        
        -- 終端模式支援 - 使用逃脫序列
        map('t', '<leader>cc', function()
          vim.cmd('stopinsert')
          terminal_manager.toggle_claude_code()
        end, { desc = 'Toggle Claude Code from terminal mode' })
        
        -- 快速開啟按鍵
        map('n', '<leader>ai', function()
          terminal_manager.toggle_claude_code()
        end, { desc = 'Open Claude Code AI assistant' })
        
        -- 備用按鍵
        map('n', '<F12>', function()
          terminal_manager.toggle_claude_code()
        end, { desc = 'Claude Code (F12)' })
        
        -- 終端之間切換 (核心功能)
        map('n', '<leader>tt', function()
          terminal_manager.switch_terminal()
        end, { desc = 'Switch between Claude Code and Gemini' })
        
        -- 終端模式下的切換支援
        map('t', '<leader>tt', function()
          vim.cmd('stopinsert')
          terminal_manager.switch_terminal()
        end, { desc = 'Switch terminals from terminal mode' })
        
        -- 使用 Ctrl+Q 隱藏當前終端
        map('t', '<C-q>', function()
          vim.cmd('stopinsert')
          -- 智能檢測當前終端並關閉
          local status = terminal_manager.get_status()
          
          -- 優先檢查是否在當前視窗
          if status.claude_code.active and status.claude_code.is_current then
            terminal_manager.toggle_claude_code()
          elseif status.gemini.active then
            -- 檢查當前 buffer 是否為 gemini
            local current_buf = vim.api.nvim_get_current_buf()
            if current_buf == status.gemini.buf then
              terminal_manager.toggle_gemini()
            else
              terminal_manager.toggle_claude_code() -- 預設嘗試關閉 Claude Code
            end
          else
            terminal_manager.toggle_claude_code() -- 預設嘗試關閉 Claude Code
          end
        end, { desc = 'Hide current terminal' })
        
        -- 狀態管理功能
        map('n', '<leader>ts', function()
          local status = terminal_manager.get_status()
          print(vim.inspect(status))
        end, { desc = 'Terminal status check' })
        
        map('n', '<leader>tr', function()
          terminal_manager.fix_state()
        end, { desc = 'Reset and fix terminal state' })
      end, 100) -- 100ms 延遲確保命令已註冊
    end
  },

  -- Gemini CLI Integration
  {
    "JonRoosevelt/gemini.nvim",
    lazy = false,
    config = function()
      -- 基本設定，但不使用其內建的 toggle 功能
      require("gemini").setup({
        -- 禁用內建按鍵映射
        keymaps = {
          toggle = false,
        }
      })
      
      -- 設定我們自己的按鍵映射
      vim.defer_fn(function()
        local map = vim.keymap.set
        local terminal_manager = require('utils.terminal-manager-v2')
        
        -- 主要切換按鍵（使用新的管理器）
        map('n', '<leader>og', function()
          terminal_manager.toggle_gemini()
        end, { desc = 'Toggle Gemini CLI (smart detection)' })
        
        -- 終端模式支援
        map('t', '<leader>og', function()
          vim.cmd('stopinsert')
          terminal_manager.toggle_gemini()
        end, { desc = 'Toggle Gemini from terminal mode' })
        
        -- 備用按鍵
        map('n', '<leader>gm', function()
          terminal_manager.toggle_gemini()
        end, { desc = 'Toggle Gemini CLI' })
        
        -- 兼容 Shift+F12 作為 Gemini 的快捷鍵
        map('n', '<S-F12>', function()
          terminal_manager.toggle_gemini()
        end, { desc = 'Gemini CLI (Shift+F12)' })
        
        -- 保留發送選取文字到 Gemini 的功能
        map('v', '<leader>sg', '<cmd>lua require("gemini").send_to_gemini()<CR>', { desc = 'Send selection to Gemini' })
      end, 100)
    end
  },

  -- Persistence: 2024 現代會話管理 (專為 Neovim 設計)
  {
    'folke/persistence.nvim',
    event = "BufReadPre",  -- 提前載入確保會話恢復
    opts = {
      dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"), -- 會話存儲目錄
      branch = true,  -- 基於 git 分支的獨立會話 (關鍵功能!)
      need = 1,       -- 至少需要 1 個有效 buffer 才保存會話
    },
    keys = {
      -- 自訂保存函數，清理目錄 buffer 後保存
      {
        "<leader>ps",
        function() 
          -- 清理無效的 buffer（目錄、空 buffer 等）
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local buf_name = vim.api.nvim_buf_get_name(buf)
            local buf_type = vim.api.nvim_buf_get_option(buf, 'buftype')
            local is_directory = vim.fn.isdirectory(buf_name) == 1
            local is_empty = buf_name == ""
            local is_dotfiles_dir = string.match(buf_name, "dotfiles/?$")
            
            -- 移除目錄 buffer、空 buffer 和 dotfiles 目錄
            if (is_directory or is_empty or is_dotfiles_dir or buf_type ~= "") and vim.api.nvim_buf_is_loaded(buf) then
              pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end
          end
          
          -- 確保還有有效的 buffer 才保存
          local valid_buffers = 0
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local buf_name = vim.api.nvim_buf_get_name(buf)
            local buf_type = vim.api.nvim_buf_get_option(buf, 'buftype')
            if vim.api.nvim_buf_is_loaded(buf) and buf_name ~= "" and buf_type == "" then
              valid_buffers = valid_buffers + 1
            end
          end
          
          if valid_buffers > 0 then
            require("persistence").save()
            print("Session saved with " .. valid_buffers .. " valid buffers")
          else
            print("No valid buffers to save")
          end
        end,
        desc = "Save current session (clean)"
      },
      {
        "<leader>pl",
        function() 
          require("persistence").load()
          -- 載入後也清理一次，確保沒有目錄 buffer
          vim.defer_fn(function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              local buf_name = vim.api.nvim_buf_get_name(buf)
              local buf_type = vim.api.nvim_buf_get_option(buf, 'buftype')
              local is_directory = vim.fn.isdirectory(buf_name) == 1
              local is_empty = buf_name == ""
              local is_dotfiles_dir = string.match(buf_name, "dotfiles/?$")
              
              if (is_directory or is_empty or is_dotfiles_dir or buf_type ~= "") and vim.api.nvim_buf_is_loaded(buf) then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
              end
            end
            
            -- 顯示載入的有效 buffer 數量
            local valid_buffers = 0
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              local buf_name = vim.api.nvim_buf_get_name(buf)
              local buf_type = vim.api.nvim_buf_get_option(buf, 'buftype')
              if vim.api.nvim_buf_is_loaded(buf) and buf_name ~= "" and buf_type == "" then
                valid_buffers = valid_buffers + 1
              end
            end
            print("Session loaded with " .. valid_buffers .. " valid buffers")
          end, 100)
        end,
        desc = "Load session for current directory (clean)"
      },
      {
        "<leader>pL",
        function() require("persistence").load({ last = true }) end,
        desc = "Load last session"
      },
      {
        "<leader>pd",
        function() require("persistence").stop() end,
        desc = "Stop persistence (don't save on exit)"
      },
    },
  },

  -- Telescope: 覆蓋 NvChad 預設配置以修復 C-j/C-k 導航
  {
    "nvim-telescope/telescope.nvim",
    opts = function()
      return require "configs.telescope"
    end,
  },

  -- Blink.cmp: 使用 NvChad 官方整合
  { import = "nvchad.blink.lazyspec" },
  
  -- GitHub Copilot: AI 程式碼建議
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        -- 停用預設 suggestion 讓 blink.cmp 處理
        suggestion = { enabled = false },
        -- 停用預設 panel 讓 blink.cmp 處理
        panel = { enabled = false },
        -- Copilot 設定
        copilot_node_command = 'node', -- Node.js 路徑
        server_opts_overrides = {},
      })
    end,
  },

  -- Blink-Copilot: blink.cmp 與 Copilot 整合
  {
    "fang2hou/blink-copilot",
    dependencies = { "zbirenbaum/copilot.lua", "saghen/blink.cmp" },
    event = "InsertEnter",
    config = function()
      require("blink-copilot").setup({
        -- 基本配置參數
        trigger = "manual",  -- 手動觸發 copilot 建議
        accept = "tab",      -- 使用 Tab 接受建議
      })
    end,
  },

  -- Blink.cmp 自定義配置
  {
    "saghen/blink.cmp",
    opts = function()
      return require "configs.blink"
    end,
  },

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
