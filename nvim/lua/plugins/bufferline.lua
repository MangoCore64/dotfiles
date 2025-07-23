return {
    'akinsho/bufferline.nvim', 
    event = "VeryLazy", -- 改為延遲載入
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    version = "*", 
    opts = {
        options = {
            mode = "buffers",
            separator_style = "slant",
        },
    },
}
