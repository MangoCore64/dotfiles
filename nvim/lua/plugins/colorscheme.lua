local colorscheme = "cyberdream"

return {
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("tokyonight").setup({
                style = "moon", -- "storm", "moon", "night", "day"
            })

            vim.cmd.colorscheme(colorscheme)
        end,
    },
    {
        "rebelot/kanagawa.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("kanagawa").setup({
                background = {
                    dark = "dragon", -- "wave", "dragon", "lotus"
                    light = "lotus",
                }
            })
        end,
    },
    {
        "scottmckendry/cyberdream.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("cyberdream").setup({
                transparent = true,
                italic_comments = true,
		terminal_colors = true,
            })
        end,
    }
}

