return {
  "greggh/claude-code.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for git operations
  },
  config = function()
    require("claude-code").setup({
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
    
    -- Key mappings
    local keymap = vim.keymap
    
    -- 主要切換按鍵 (替代官方的 <C-,>)
    keymap.set('n', '<leader>cc', '<cmd>ClaudeCode<CR>', { desc = 'Toggle Claude Code terminal' })
    keymap.set('t', '<leader>cc', '<cmd>ClaudeCode<CR>', { desc = 'Toggle Claude Code terminal' })
    
    -- 快速開啟按鍵
    keymap.set('n', '<leader>ai', '<cmd>ClaudeCode<CR>', { desc = 'Open Claude Code AI assistant' })
    
    -- 備用按鍵
    keymap.set('n', '<F12>', '<cmd>ClaudeCode<CR>', { desc = 'Claude Code (F12)' })
    
    -- 如果你想要模仿官方的逗號概念
    keymap.set('n', '<leader>,', '<cmd>ClaudeCode<CR>', { desc = 'Claude Code (comma alternative)' })
  end
}
