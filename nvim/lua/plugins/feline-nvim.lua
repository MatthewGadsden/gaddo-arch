-- feline statusline in the tokyo-snow palette (~/.config/tokyo-snow.theme)
local tokyo_snow = {
    fg = '#f1e4b5',        -- snow
    bg = '#1c1c1a',        -- night
    black = '#2a2a28',     -- shadow
    skyblue = '#6fc28a',   -- pine
    cyan = '#c4c88e',      -- sage
    green = '#a6d46c',     -- moss
    oceanblue = '#3a3933', -- slate
    magenta = '#d5583d',   -- neon
    orange = '#db814c',    -- ember
    red = '#96402e',       -- brick
    violet = '#e1b568',    -- amber
    white = '#f1e4b5',     -- snow
    yellow = '#ecd08f',    -- gold
}

return {
  'feline-nvim/feline.nvim',
  priority = 1001,
  enabled = true,
  config = function() require('feline').setup({ theme = tokyo_snow }) end,
}
