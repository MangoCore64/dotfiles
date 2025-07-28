return {
  "github/copilot.vim",
  event = "InsertEnter",
  config = function()
    -- Copilot 基本設定
    vim.g.copilot_no_tab_map = true
    vim.g.copilot_assume_mapped = true
    vim.g.copilot_tab_fallback = ""
    
    -- 啟用的檔案類型
    vim.g.copilot_filetypes = {
      ["*"] = true,
      ["gitcommit"] = false,
      ["gitrebase"] = false,
      ["hgcommit"] = false,
      ["svn"] = false,
      ["cvs"] = false,
      ["."] = false,
    }
    
    -- 自定義鍵位綁定
    local keymap = vim.keymap.set
    
    -- 接受建議：Tab 鍵
    keymap("i", "<Tab>", function()
      if vim.fn["copilot#Accept"]("") ~= "" then
        return vim.fn["copilot#Accept"]("")
      else
        return "<Tab>"
      end
    end, { expr = true, replace_keycodes = false })
    
    -- 接受建議：Ctrl-J
    keymap("i", "<C-J>", 'copilot#Accept("\\<CR>")', {
      expr = true,
      replace_keycodes = false
    })
    
    -- 下一個建議：Alt-]
    keymap("i", "<M-]>", "<Plug>(copilot-next)")
    
    -- 上一個建議：Alt-[
    keymap("i", "<M-[>", "<Plug>(copilot-previous)")
    
    -- 關閉建議：Ctrl-]
    keymap("i", "<C-]>", "<Plug>(copilot-dismiss)")
    
    -- 手動觸發建議：Ctrl-\
    keymap("i", "<C-\\>", "<Plug>(copilot-suggest)")
    
    -- 接受整行：Ctrl-Right
    keymap("i", "<C-Right>", "<Plug>(copilot-accept-line)")
    
    -- 接受單詞：Ctrl-L
    keymap("i", "<C-L>", "<Plug>(copilot-accept-word)")
  end,
}