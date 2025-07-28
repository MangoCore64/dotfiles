return {
    'rmagatti/auto-session',
    config = function()
        local auto_session = require('auto-session')
        
        auto_session.setup({
            auto_restore = false,
            suppressed_dirs = { "~/" }
        })

        local keymap = vim.keymap

        keymap.set("n", "<leader>sl", "<cmd>SessionRestore<cr>", { desc = "Restore Session" })
        keymap.set("n", "<leader>ss", "<cmd>SessionSave<cr>", { desc = "Save Session" })
    end,
}
