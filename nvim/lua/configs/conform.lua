local options = {
  formatters_by_ft = {
    -- Lua
    lua = { "stylua" },
    
    -- Web 開發
    html = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    vue = { "prettier" },
    json = { "prettier" },
    
    -- 後端語言
    php = { "php_cs_fixer" },
    python = { "black", "isort" },
    
    -- 配置檔案
    yaml = { "prettier" },
    markdown = { "prettier" },
    
    -- Shell
    sh = { "shfmt" },
    bash = { "shfmt" },
  },

  -- 可選：啟用保存時自動格式化
  -- format_on_save = {
  --   timeout_ms = 1000,
  --   lsp_fallback = true,
  -- },
  
  -- 格式化器特定設定
  formatters = {
    prettier = {
      prepend_args = { "--single-quote", "--trailing-comma", "es5" },
    },
    stylua = {
      prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
    },
    shfmt = {
      prepend_args = { "-i", "2", "-ci" },  -- 2 空格縮排，switch case 縮排
    },
  },
}

return options
