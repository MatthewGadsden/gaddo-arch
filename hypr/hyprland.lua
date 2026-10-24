-- Hyprland Lua configuration
-- ~/.config/hypr/hyprland.lua
-- API reference: /usr/share/hypr/stubs/hl.meta.lua, example: /usr/share/hypr/hyprland.lua

-- ============================================================================
-- PROGRAMS
-- ============================================================================

local terminal = "alacritty"
local fileManager = "dolphin"
local menu = "wofi --show drun"
local mainMod = "SUPER"

-- ============================================================================
-- ENVIRONMENT
-- ============================================================================

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- ============================================================================
-- MONITORS
-- ============================================================================

hl.monitor({
    output = "eDP-1",
    mode = "3840x2160@60",
    position = "auto",
    scale = 1.5,
})

-- External monitors are matched by model, not port: the connector names differ
-- between machines. The Dell sits on the left, the 144Hz AOC on the right.
local left_monitor = "desc:Dell Inc. DELL U2721DE B4NRS83"
local right_monitor = "desc:AOC Q27G2SG4B+ OGJMAHA016182"

hl.monitor({
    output = left_monitor,
    mode = "2560x1440@60",
    position = "0x0",
    scale = 1,
})

hl.monitor({
    output = right_monitor,
    mode = "2560x1440@144",
    position = "2560x0",
    scale = 1,
})

-- ============================================================================
-- AUTOSTART
-- ============================================================================

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hyprlock")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("1password --silent")
    -- Use the desktop's front-panel mic jack (a no-op where that source doesn't exist)
    hl.exec_cmd("pactl set-source-port alsa_input.pci-0000_00_1f.3.analog-stereo analog-input-front-mic")
    -- Workspaces 1-6 are bound to the external monitors, so the laptop screen
    -- would otherwise boot onto the first unbound workspace (7)
    hl.dispatch(hl.dsp.focus({ workspace = 1 }))
end)

-- ============================================================================
-- LOOK AND FEEL
-- ============================================================================

-- Colours are the tokyo-snow palette (~/.config/tokyo-snow.theme)
hl.config({
    general = {
        gaps_in = 1,
        gaps_out = 4,

        border_size = 1,

        col = {
            active_border = { colors = { "rgba(cb7d50ee)", "rgba(d5b67bee)" }, angle = 45 }, -- ember -> gold
            inactive_border = "rgba(797562aa)", -- dim
        },

        resize_on_border = false,
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = 2,
        rounding_power = 2,

        active_opacity = 0.98,
        inactive_opacity = 0.9,

        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1c1c1aee)", -- night
        },

        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    },
})

-- ============================================================================
-- ANIMATIONS
-- ============================================================================

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

-- ============================================================================
-- INPUT
-- ============================================================================

hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",

        follow_mouse = 1,
        sensitivity = -0.6,
        accel_profile = "flat",

        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.device({
    name = "logitech-usb-receiver",
    sensitivity = -0.7,
})

-- Three-finger horizontal swipe switches workspaces
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

-- ============================================================================
-- WINDOW RULES
-- ============================================================================

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- Firefox should not have inactive opacity applied.
hl.window_rule({
    name = "firefox-opaque",
    match = { class = "^(firefox)$" },
    opacity = "1.0 override",
})

-- ============================================================================
-- WORKSPACES
-- ============================================================================

-- Pinned by port name, not model like the monitor rules above: waybar only shows
-- a persistent workspace when the rule's monitor equals its output name exactly.
-- These are the desktop's ports (AOC on DP-1 on the right, Dell on DP-2 on the left).
for _, ws in ipairs({ "1", "2", "3" }) do
    hl.workspace_rule({ workspace = ws, monitor = "DP-1", persistent = true })
end

for _, ws in ipairs({ "4", "5", "6" }) do
    hl.workspace_rule({ workspace = ws, monitor = "DP-2", persistent = true })
end

-- ============================================================================
-- KEYBINDINGS
-- ============================================================================

-- Applications
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))

hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + CTRL + F", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + CTRL + X", hl.dsp.exec_cmd("1password"))
hl.bind(mainMod .. " + CTRL + D", hl.dsp.exec_cmd("discord"))
hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd("spotify-launcher"))
hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd(terminal .. " -e nvim"))
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd("grimshot --notify save area"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("~/.config/rofi/launchers/type-4/launcher.sh"))

-- Window management
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + TAB", hl.dsp.layout("togglesplit"))

-- Focus (vim keys)
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume / brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })

-- Media keys (requires playerctl)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
