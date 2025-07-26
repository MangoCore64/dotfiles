require("nvchad.configs.lspconfig").defaults()

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
mason_lspconfig.setup({
  ensure_installed = {
    "html",
    "cssls", 
    "jsonls",
    "eslint",
    "vtsls",
    "phpactor",
    "perlnavigator",
    "vuels"
  },
  automatic_installation = true,
})

-- 自動設定已安裝的 LSP servers
mason_lspconfig.setup_handlers({
  -- 預設處理器：為所有伺服器套用基本設定
  function(server_name)
    require("lspconfig")[server_name].setup({})
  end,
  
  -- 特定伺服器的自訂設定可在此加入
  -- 例如：
  -- ["tsserver"] = function()
  --   require("lspconfig").tsserver.setup({
  --     -- 自訂設定
  --   })
  -- end,
})

vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
