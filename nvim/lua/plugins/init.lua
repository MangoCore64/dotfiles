-- ===================================================================
-- Plugin 版本管理策略 - 混合策略平衡穩定性與功能更新
-- ===================================================================
-- 
-- 🔒 嚴格鎖定（核心功能）：
--    - NvChad framework, LSP, Mason, Blink.cmp
--    - 維持當前版本，只在測試驗證後手動更新
--
-- 🔧 適度靈活（工具插件）：
--    - Claude Code, Gemini → 鎖定當前穩定版本，允許手動更新
--    - 提供更新通知但不自動應用
--
-- 🚀 靈活更新（成熟插件）：
--    - Telescope, Persistence, Conform → 允許小版本自動更新
--    - 提供更新通知和回滾機制
--
-- ⚠️  更新流程：
--    1. 在測試環境驗證新版本
--    2. 檢查更新日誌和破壞性變更
--    3. 漸進式更新，每次只更新幾個插件
--    4. 保持配置備份以便回滾
-- ===================================================================

return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    tag = "v8.1.0",  -- 嚴格鎖定（核心功能）
    opts = require "configs.conform",
  },

  -- Mason: LSP server installer
  {
    "williamboman/mason.nvim",
    tag = "v1.10.0",  -- 嚴格鎖定（核心功能）
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
    tag = "v1.29.0",  -- 嚴格鎖定（核心功能）
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
    tag = "v1.2.0",  -- 嚴格鎖定（核心功能）
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Claude Code AI Assistant
  {
    "greggh/claude-code.nvim",
    commit = "c9a31e51069977edaad9560473b5d031fcc5d38b", -- 適度靈活（工具插件）
    event = "VeryLazy", -- 延遲載入提高啟動效能（從 lazy = false 改進）
    cmd = "ClaudeCode", -- 命令觸發載入
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
        local terminal_manager = require('utils.terminal.manager')
        
        -- 主要切換按鍵 (Claude Code - 語義清晰)
        map('n', '<leader>cc', function()
          terminal_manager.toggle_claude_code()
        end, { desc = 'Toggle Claude Code AI' })
        
        -- 終端模式支援 - 使用逃脫序列
        map('t', '<leader>cc', function()
          vim.cmd('stopinsert')
          terminal_manager.toggle_claude_code()
        end, { desc = 'Toggle Claude Code from terminal mode' })
        
        -- 保留 F12 作為快速鍵
        map('n', '<F12>', function()
          terminal_manager.toggle_claude_code()
        end, { desc = 'Claude Code (F12)' })
        
        -- 終端之間切換 (核心功能) - 使用 Terminal Toggle 語義
        map('n', '<leader>tt', function()
          terminal_manager.switch_terminal()
        end, { desc = 'Switch between AI terminals' })
        
        -- 終端模式下的切換支援
        map('t', '<leader>tt', function()
          vim.cmd('stopinsert')
          terminal_manager.switch_terminal()
        end, { desc = 'Switch AI terminals from terminal mode' })
        
        -- 使用 Ctrl+Q 隱藏當前終端
        map('t', '<C-q>', function()
          vim.cmd('stopinsert')
          -- 智能檢測當前終端並關閉
          local status = terminal_manager.get_status()
          
          -- 優先檢查是否在當前視窗
          if status.claude_code.visible and status.claude_code.is_current then
            terminal_manager.toggle_claude_code()
          elseif status.gemini.visible then
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
        
        -- 終端管理功能 (使用 Terminal Status 命名空間)
        map('n', '<leader>ts', function()
          local status = terminal_manager.get_status()
          print(vim.inspect(status))
        end, { desc = 'Terminal status check' })
        
        map('n', '<leader>tr', function()
          terminal_manager.cleanup()
        end, { desc = 'Cleanup terminal state' })
        
        map('n', '<leader>tR', function()
          terminal_manager.reset()
        end, { desc = 'Reset all terminals' })
      end, 100) -- 100ms 延遲確保命令已註冊
    end
  },

  -- Gemini CLI Integration
  {
    "JonRoosevelt/gemini.nvim",
    commit = "d86251d8950011b35930641c8a9b7ad75317e65a", -- 適度靈活（工具插件）
    event = "VeryLazy", -- 延遲載入提高啟動效能（從 lazy = false 改進）
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
        local terminal_manager = require('utils.terminal.manager')
        
        -- 主要切換按鍵（語義化改進 - 避免與 "agent" 混淆）
        map('n', '<leader>gm', function()
          terminal_manager.toggle_gemini()
        end, { desc = 'Toggle Gemini AI' })
        
        -- 終端模式支援
        map('t', '<leader>gm', function()
          vim.cmd('stopinsert')
          terminal_manager.toggle_gemini()
        end, { desc = 'Toggle Gemini from terminal mode' })
        
        -- 兼容 Shift+F12 作為 Gemini 的快捷鍵
        map('n', '<S-F12>', function()
          terminal_manager.toggle_gemini()
        end, { desc = 'Gemini AI (Shift+F12)' })
        
        -- 保留發送選取文字到 Gemini 的功能
        map('v', '<leader>sg', '<cmd>lua require("gemini").send_to_gemini()<CR>', { desc = 'Send selection to Gemini' })
      end, 100)
    end
  },

  -- Persistence: 2024 現代會話管理 (專為 Neovim 設計)
  {
    'folke/persistence.nvim',
    tag = "v1.0.0",        -- 靈活更新（成熟插件）
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
            local buf_type = vim.bo[buf].buftype  -- 使用新的 API 替代已棄用的 nvim_buf_get_option
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
            local buf_type = vim.bo[buf].buftype  -- 使用新的 API 替代已棄用的 nvim_buf_get_option
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
              local buf_type = vim.bo[buf].buftype  -- 使用新的 API 替代已棄用的 nvim_buf_get_option
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
              local buf_type = vim.bo[buf].buftype  -- 使用新的 API 替代已棄用的 nvim_buf_get_option
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
    -- 靈活更新（成熟插件）- 由 NvChad 管理版本
    opts = function()
      return require "configs.telescope"
    end,
  },

  -- Blink.cmp: 使用 NvChad 官方整合
  { import = "nvchad.blink.lazyspec" }, -- 嚴格鎖定（核心功能）- 由 NvChad 管理
  
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
        -- 文件類型控制：避免在敏感文件中啟用
        filetypes = {
          yaml = false,
          markdown = true,      -- 允許在 markdown 中使用
          help = true,          -- 允許在 help 文件中使用
          gitcommit = false,    -- 禁用於 git commit
          gitrebase = false,    -- 禁用於 git rebase
          hgcommit = false,     -- 禁用於 mercurial commit
          svn = false,          -- 禁用於 svn
          cvs = false,          -- 禁用於 cvs
          ["."] = false,        -- 禁用於點文件
          [".env"] = false,     -- 明確禁用於環境變數文件
          ["*"] = true,         -- 其他文件類型默認啟用
        },
      })
    end,
  },

  -- Blink-Copilot: blink.cmp 與 Copilot 整合
  {
    "fang2hou/blink-copilot",
    commit = "41e91a659bd9b8cba9ba2ea68a69b52ba5a9ebd8", -- 適度靈活（工具插件）
    dependencies = { "zbirenbaum/copilot.lua", "saghen/blink.cmp" },
    event = "InsertEnter",
    config = function()
      require("blink-copilot").setup({
        -- 官方推薦的完整配置參數
        max_completions = 3,      -- 支援多個候選項（默認：3）
        max_attempts = 4,         -- 最大重試次數（默認：4）
        debounce = 200,          -- 防抖延遲，優化性能（默認：200ms）
        kind_name = "Copilot",   -- 補全項目類型名稱
        kind_icon = " ",         -- Copilot 圖示
        kind_hl = false,         -- 是否高亮顯示類型
        auto_refresh = {         -- 自動刷新設定
          backward = true,       -- 向後移動時刷新
          forward = true         -- 向前移動時刷新
        },
      })
    end,
  },

  -- Blink.cmp 自定義配置
  {
    "saghen/blink.cmp",
    opts = function()
        require('render-markdown').setup({
           completions = { blink = { enabled = true } },
        })
      return require "configs.blink"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    -- 靈活更新（成熟插件）- 由 NvChad 管理，允許語法更新
    opts = {
      ensure_installed = {
        -- 核心開發語言
        "perl", "php", "phpdoc",
        "html", "css", "javascript", "typescript",
        "vue",
        
        -- 配置檔案
        "json", "yaml", "sql", "markdown",
        
        -- Git 與版本控制
        "git_config", "git_rebase", "gitcommit", "gitignore",
        
        -- Shell 與系統
        "bash", "tmux",
        
        -- Neovim 配置
        "vim", "vimdoc", "lua"
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = { enable = true },
    },
  },
   {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown', 'quarto' }, -- 延遲載入優化
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
    config = function()
      require('configs.render-markdown').setup()
    end,
   }
}
