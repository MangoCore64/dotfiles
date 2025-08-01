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

-- 自動設定已安裝的 LSP servers
mason_lspconfig.setup_handlers({
  -- 預設處理器：為所有伺服器套用基本設定
  function(server_name)
    require("lspconfig")[server_name].setup({
      -- 可以在這裡添加全域的 LSP 設定
      on_attach = function(client, bufnr)
        -- LSP 按鍵映射和功能在這裡設定
        -- NvChad 已經提供了預設的 on_attach 功能
      end,
    })
  end,
  
  -- 特定伺服器的自訂設定
  ["vtsls"] = function()
    require("lspconfig").vtsls.setup({
      -- TypeScript/JavaScript 特定設定
      settings = {
        typescript = {
          inlayHints = {
            includeInlayParameterNameHints = "all",
            includeInlayFunctionParameterTypeHints = true,
          },
        },
      },
    })
  end,
})

-- 已移除錯誤的 vim.lsp.enable(servers) 調用
-- LSP 伺服器會透過 mason_lspconfig.setup_handlers 自動啟動

-- read :h vim.lsp.config for changing options of lsp servers 
