require "nvchad.options"

-- add yours here!

local o = vim.o

-- Tab settings
o.tabstop = 4        -- Number of spaces tabs count for
o.shiftwidth = 4     -- Size of an indent
o.expandtab = true   -- Use spaces instead of tabs
o.softtabstop = 4    -- Number of spaces tabs count for in insert mode

-- Key timeout settings for better multi-key mapping experience
o.timeoutlen = 300   -- Optimized: reduced from 500ms for faster response
o.ttimeoutlen = 5    -- Optimized: reduced from 10ms for faster key codes

-- Dynamic timeout adjustment: shorter in normal mode, longer in insert mode
local function adaptive_timeout()
  if vim.fn.mode() == 'i' then
    vim.o.timeoutlen = 400  -- Insert mode: longer timeout to avoid accidental triggers
  else
    vim.o.timeoutlen = 300  -- Normal mode: faster response
  end
end

-- Auto-adjust timeout based on mode
vim.api.nvim_create_autocmd({'InsertEnter', 'InsertLeave'}, {
  group = vim.api.nvim_create_augroup('AdaptiveTimeout', { clear = true }),
  callback = adaptive_timeout,
  desc = 'Adjust timeout based on current mode'
})

-- o.cursorlineopt ='both' -- to enable cursorline!

-- Session options for persistence.nvim - 只保存實際的檔案 buffer
o.sessionoptions = "buffers,curdir,folds,tabpages,winsize,winpos"
