-- feline statusline in the tokyo-snow palette (~/.config/tokyo-snow.theme)
local tokyo_snow = {
    fg = '#ebe0b3',        -- snow
    bg = '#1c1c1a',        -- night
    black = '#2a2a28',     -- shadow
    skyblue = '#849675',   -- pine
    cyan = '#b9bc8f',      -- sage
    green = '#a2aa7f',     -- moss
    oceanblue = '#3a3933', -- slate
    magenta = '#b85940',   -- neon
    orange = '#cb7d50',    -- ember
    red = '#824a3e',       -- brick
    violet = '#d19e63',    -- amber
    white = '#ebe0b3',     -- snow
    yellow = '#d5b67b',    -- gold
}

return {
  'feline-nvim/feline.nvim',
  priority = 1001,
  enabled = true,
  config = function() require('feline').setup({ theme = tokyo_snow }) end,
}
