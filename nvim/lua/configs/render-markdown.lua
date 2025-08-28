-- render-markdown.nvim 配置
-- 基於 NvChad 框架，針對 AI 開發工作流程優化

local M = {}

M.setup = function()
  require('render-markdown').setup({
    -- 核心設定
    enabled = true,
    max_file_size = 5.0, -- MB - 針對大型文檔優化性能
    debounce = 150, -- 渲染延遲 (ms)
    
    -- 渲染模式 - 在 normal, command 模式下啟用
    render_modes = { 'n', 'c' },
    
    -- Anti-conceal - 游標所在行隱藏渲染標記
    anti_conceal = {
      enabled = true,
      ignore = {
        code_background = true, -- 保持代碼背景
        sign = true, -- 保持符號欄標記
      },
    },
    
    -- 文件類型支援
    file_types = { 'markdown', 'quarto' },
    
    -- 標題配置 - 支援 6 級標題圖標
    heading = {
      enabled = true,
      sign = true,
      position = 'overlay',
      icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
      signs = { '󰌕' },
      width = 'full',
      backgrounds = {
        'RenderMarkdownH1Bg',
        'RenderMarkdownH2Bg',
        'RenderMarkdownH3Bg',
        'RenderMarkdownH4Bg',
        'RenderMarkdownH5Bg',
        'RenderMarkdownH6Bg',
      },
    },
    
    -- 代碼塊配置
    code = {
      enabled = true,
      sign = true,
      style = 'full',
      position = 'left',
      language_pad = 0,
      disable_background = { 'diff' },
      width = 'full',
      left_margin = 0,
      left_pad = 0,
      right_pad = 0,
      min_width = 0,
      highlight = 'RenderMarkdownCode',
    },
    
    -- 分隔線
    dash = {
      enabled = true,
      icon = '─',
      width = 'full',
      highlight = 'RenderMarkdownDash',
    },
    
    -- 項目符號
    bullet = {
      enabled = true,
      icons = { '●', '○', '◆', '◇' },
      highlight = 'RenderMarkdownBullet',
    },
    
    -- 核取方塊
    checkbox = {
      enabled = true,
      unchecked = { icon = '󰄱 ', highlight = 'RenderMarkdownUnchecked' },
      checked = { icon = '󰱒 ', highlight = 'RenderMarkdownChecked' },
      custom = {
        todo = { raw = '[-]', rendered = '󰥔 ', highlight = 'RenderMarkdownTodo' },
      },
    },
    
    -- 引用塊
    quote = {
      enabled = true,
      icon = '▎',
      highlight = 'RenderMarkdownQuote',
    },
    
    -- 管道表格
    pipe_table = {
      enabled = true,
      render_modes = false,
      style = 'full',
      cell = 'padded', -- 改為 overlay 模式，完全控制渲染，不解析 Markdown 語法
      min_width = 0,
      border = {
        '┌', '┬', '┐',
        '├', '┼', '┤',
        '└', '┴', '┘',
        '│', '─',
      },
      border_enabled = true,
      border_virtual = false,
      alignment_indicator = '━',
      head = 'RenderMarkdownTableHead',
      row = 'RenderMarkdownTableRow',
      filler = 'RenderMarkdownTableFill',
    },
    
    -- 連結
    link = {
      enabled = true,
      image = '󰥶 ',
      email = '󰀓 ',
      hyperlink = '󰌹 ',
      highlight = 'RenderMarkdownLink',
      wiki = { icon = '󱗖 ', highlight = 'RenderMarkdownWikiLink' },
      custom = {
        web = { pattern = 'https?://[%w%.]', icon = '󰖟 ', highlight = 'RenderMarkdownLink' },
      },
    },
    
    -- 符號欄設定
    sign = {
      enabled = true,
      highlight = 'RenderMarkdownSign',
    },
    
    -- Callout 支援 (類似 Obsidian)
    callout = {
      note = { raw = '[!NOTE]', rendered = '󰋽 Note', highlight = 'RenderMarkdownInfo' },
      tip = { raw = '[!TIP]', rendered = '󰌶 Tip', highlight = 'RenderMarkdownSuccess' },
      important = { raw = '[!IMPORTANT]', rendered = '󰅾 Important', highlight = 'RenderMarkdownHint' },
      warning = { raw = '[!WARNING]', rendered = '󰀪 Warning', highlight = 'RenderMarkdownWarn' },
      caution = { raw = '[!CAUTION]', rendered = '󰳦 Caution', highlight = 'RenderMarkdownError' },
    },
    
    -- 窗口選項
    win_options = {
      conceallevel = { default = vim.o.conceallevel, rendered = 2 }, -- 降低隱藏級別
      concealcursor = { default = vim.o.concealcursor, rendered = '' }, -- 清空游標隱藏
    },
  })
end

return M
