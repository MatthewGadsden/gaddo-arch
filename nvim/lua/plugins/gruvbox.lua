-- gruvbox-flat, recoloured with the tokyo-snow palette (~/.config/tokyo-snow.theme)
local tokyo_snow = {
    night = '#1c1c1a',
    shadow = '#2a2a28',
    slate = '#3a3933',
    dim = '#7d7860',
    snow = '#f1e4b5',
    brick = '#96402e',
    neon = '#d5583d',
    ember = '#db814c',
    amber = '#e1b568',
    gold = '#ecd08f',
    sage = '#c4c88e',
    moss = '#a6d46c',
    pine = '#6fc28a',
}

return {
    'eddyekofo94/gruvbox-flat.nvim',
    priority = 1000,
    enabled = true,
    init = function()
        vim.g.gruvbox_flat_style = "dark"
        local c = tokyo_snow
        -- applied after the style's own derived colours, so popups/sidebars are set here too
        vim.g.gruvbox_colors = {
            bg = c.shadow,
            bg2 = c.night,
            bg_popup = c.night,
            bg_statusline = c.night,
            bg_sidebar = c.night,
            bg_float = c.night,
            bg_visual = c.slate,
            bg_highlight = c.slate,
            bg_search = c.slate,
            line_cursor = c.slate,
            border = c.dim,
            prompt_border = c.slate,
            fg = c.gold,
            fg_light = c.snow,
            fg_dark = c.gold,
            fg_sidebar = c.gold,
            tree_normal = c.moss,
            comment = c.dim,
            fg_gutter = c.dim,
            dark5 = c.dim,
            blue = c.pine,
            aqua = c.sage,
            purple = c.amber,
            orange = c.ember,
            yellow = c.amber,
            yellow2 = c.gold,
            bg_yellow = c.brick,
            green = c.moss,
            red = c.neon,
            red1 = c.brick,
            black = c.night,
            error = c.neon,
            warning = c.amber,
            info = c.pine,
            hint = c.sage,
        }
    end,
    config = function()
        vim.cmd([[colorscheme gruvbox-flat]])
    end,
}
