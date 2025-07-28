require "nvchad.options"

-- add yours here!

local o = vim.o

-- Tab settings
o.tabstop = 4        -- Number of spaces tabs count for
o.shiftwidth = 4     -- Size of an indent
o.expandtab = true   -- Use spaces instead of tabs
o.softtabstop = 4    -- Number of spaces tabs count for in insert mode

-- Key timeout settings for better multi-key mapping experience
o.timeoutlen = 500   -- Time to wait for a mapped sequence to complete (ms)
o.ttimeoutlen = 10   -- Time to wait for a key code sequence to complete (ms)

-- o.cursorlineopt ='both' -- to enable cursorline!
