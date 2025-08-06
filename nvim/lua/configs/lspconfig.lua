require("nvchad.configs.lspconfig").defaults()

-- LSP 伺服器列表（用於參考和文檔）
local servers = { 
  "html", 
  "cssls", 
  "jsonls", 
  "eslint", 
  "vtsls", 
  "phpactor", 
  "perlnavigator", 
  "vuels" 
}

-- Mason 自動安裝設定
local mason_lspconfig = require("mason-lspconfig")

-- 確保 LSP servers 自動安裝
-- 注意：mason-lspconfig 需要 LSP server 名稱，不是 Mason package 名稱
mason_lspconfig.setup({
  ensure_installed = {
    "html",        -- HTML language server
    "cssls",       -- CSS language server  
    "jsonls",      -- JSON language server
    "eslint",      -- ESLint language server
    "vtsls",       -- TypeScript/JavaScript language server (替代 tsserver)
    "phpactor",    -- PHP language server
    "perlnavigator", -- Perl language server
    "vuels"        -- Vue language server
  },
  automatic_installation = true,
})

-- 增強的 LSP 設定處理器
mason_lspconfig.setup_handlers({
  -- 預設處理器：為所有伺服器套用基本設定
  function(server_name)
    require("lspconfig")[server_name].setup({
      -- 全域 LSP 設定
      on_attach = function(client, bufnr)
        -- 啟用診斷自動顯示
        vim.diagnostic.config({
          virtual_text = {
            prefix = "●",
            source = "if_many",
          },
          signs = true,
          update_in_insert = false,
          underline = true,
          severity_sort = true,
          float = {
            focusable = false,
            style = "minimal",
            border = "rounded",
            source = "always",
            header = "",
            prefix = "",
          },
        })
        
        -- 診斷符號設定
        local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
        for type, icon in pairs(signs) do
          local hl = "DiagnosticSign" .. type
          vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
        end
      end,
      
      -- 能力設定
      capabilities = vim.tbl_deep_extend("force", 
        vim.lsp.protocol.make_client_capabilities(),
        require("blink.cmp").get_lsp_capabilities()
      ),
    })
  end,
  
  -- TypeScript/JavaScript 增強設定
  ["vtsls"] = function()
    require("lspconfig").vtsls.setup({
      settings = {
        typescript = {
          inlayHints = {
            includeInlayParameterNameHints = "all",
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
          },
          preferences = {
            includePackageJsonAutoImports = "auto",
          },
        },
        javascript = {
          inlayHints = {
            includeInlayParameterNameHints = "all",
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
          },
        },
      },
    })
  end,
  
  -- Vue 專用設定
  ["vuels"] = function()
    require("lspconfig").vuels.setup({
      settings = {
        vetur = {
          useWorkspaceDependencies = false,
          validation = {
            template = true,
            style = true,
            script = true,
          },
          completion = {
            autoImport = true,
            useScaffoldSnippets = true,
            tagCasing = "kebab",
          },
        },
      },
    })
  end,
  
  -- PHP 專用設定
  ["phpactor"] = function()
    require("lspconfig").phpactor.setup({
      settings = {
        phpactor = {
          completion = {
            insertUseDeclaration = true,
          },
        },
      },
    })
  end,
})

-- 已移除錯誤的 vim.lsp.enable(servers) 調用
-- LSP 伺服器會透過 mason_lspconfig.setup_handlers 自動啟動

-- read :h vim.lsp.config for changing options of lsp servers 
