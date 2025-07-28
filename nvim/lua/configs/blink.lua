-- Blink.cmp 配置 - 與 NvChad 完全整合
-- 遵循官方最佳實踐和 NvChad 風格指南

local opts = {
  -- 按鍵映射：自定義 IDE 風格（避免系統衝突）
  keymap = { 
    preset = 'default',
    -- 導航按鍵
    ['<C-j>'] = { 'select_next', 'fallback' },
    ['<C-k>'] = { 'select_prev', 'fallback' },
    -- 手動觸發補全（避免 Ctrl-Space 衝突）
    ['<C-n>'] = { 'show', 'fallback' },
    -- 文檔切換
    ['<C-d>'] = { 'show_documentation', 'hide_documentation' },
    -- 取消補全
    ['<C-e>'] = { 'hide', 'fallback' },
    -- 接受補全
    ['<Tab>'] = { 'accept', 'snippet_forward', 'fallback' },
    ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
  },

  -- 外觀設定：與 NvChad 主題系統整合
  appearance = {
    nerd_font_variant = 'mono',  -- 使用 mono 字體
    kind_icons = {
      Text = '󰉿',
      Method = '󰆧',
      Function = '󰊕',
      Constructor = '',
      Field = '󰜢',
      Variable = '󰀫',
      Class = '󰠱',
      Interface = '',
      Module = '',
      Property = '󰜢',
      Unit = '󰑭',
      Value = '󰎠',
      Enum = '',
      Keyword = '󰌋',
      Snippet = '',
      Color = '󰏘',
      File = '󰈙',
      Reference = '󰈇',
      Folder = '󰉋',
      EnumMember = '',
      Constant = '󰏿',
      Struct = '󰙅',
      Event = '',
      Operator = '󰆕',
      TypeParameter = '',
    },
  },

  -- 來源配置：使用官方推薦的預設來源並自定義提供者設定
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
    providers = {
      lsp = {
        min_keyword_length = 1,
        score_offset = 0,
        timeout_ms = 2000,
      },
      path = {
        min_keyword_length = 3,
      },
      snippets = {
        min_keyword_length = 2,
      },
      buffer = {
        min_keyword_length = 4,
        max_items = 5,
      },
    },
  },

  -- 命令列補全設定（暫時禁用以避免 TreeSitter 衝突）
  cmdline = {
    enabled = false,
  },

  -- 補全窗口設定：NvChad 風格
  completion = {
    list = {
      max_items = 200,  -- 最大項目數設定在這裡
    },
    menu = {
      border = 'single',  -- 使用單線邊框與 NvChad 一致
      scrolloff = 2,
      scrollbar = true,
      window = {
        winhighlight = 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
      },
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 500,
      window = {
        border = 'single',
        winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc',
      },
    },
    ghost_text = {
      enabled = true,
    },
  },

  -- 模糊匹配優化：使用 Rust 實現獲得最佳效能
  fuzzy = {
    max_typos = function(keyword)
      return math.floor(#keyword / 4)  -- 動態拼寫容錯
    end,
    use_frecency = true,         -- 頻率 + 最近使用
    use_proximity = true,        -- 接近度匹配
    sorts = { 'label', 'kind', 'score' },
  },
}

return opts