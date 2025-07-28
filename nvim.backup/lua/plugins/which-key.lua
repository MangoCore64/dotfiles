return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 500
  end,
  opts = {
    -- 在這裡放置您的配置
    -- 或者留空以使用默認設置
    -- 請參考下面的配置部分
  },
}
