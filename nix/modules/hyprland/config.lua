-- https://wiki.hypr.land/configuring/core/monitors/
-- Descriptions match by prefix. Hyprland drops commas and shows a bare PNP ID
-- for vendors hwdata does not know, so these differ from Niri's output names.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.monitor({
    output   = "desc:BNQ BenQ RD280UG EMP7T00043087",
    mode     = "3840x2560@119.991",
    position = "auto",
    scale    = 2,
    vrr      = 2,
})

hl.monitor({
    output   = "desc:Guangxi Century Innovation Display Electronics Co. Ltd 27C1U-D 0000000000001",
    mode     = "3840x2160@60",
    position = "auto",
    scale    = 2,
})

hl.monitor({
    output   = "desc:AU Optronics 0x233D",
    mode     = "1920x1080@60.049",
    position = "auto",
    scale    = 1.333333,
})

hl.monitor({
    output   = "desc:Samsung Display Corp. 0x41AA",
    mode     = "2880x1800@120.001",
    position = "auto",
    scale    = 2,
    vrr      = 1,
})

hl.monitor({
    output   = "desc:Samsung Display Corp. ATNA40CT06-0",
    mode     = "1920x1200@60.003",
    position = "auto",
    scale    = 1.25,
})

-- https://wiki.hypr.land/configuring/core/environment-variables/
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")

-- https://wiki.hypr.land/configuring/core/config-options/
hl.config({
    input = {
        kb_options   = "ctrl:nocaps",
        follow_mouse = 1,

        touchpad = {
            tap_to_click         = true,
            disable_while_typing = true,
            natural_scroll       = true,
            clickfinger_behavior = true,
        },

        touchdevice = {
            output = "eDP-1",
        },
    },

    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 0,
        layout      = "dwindle",
    },

    dwindle = {
        preserve_split = true,
    },

    decoration = {
        rounding = 10,

        shadow = {
            enabled      = true,
            range        = 30,
            render_power = 3,
            offset       = "0 5",
            color        = "rgba(00000077)",
        },

        blur = {
            enabled = true,
        },
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        focus_on_activate        = true,
    },
})

-- Workspaces stack vertically, as they do in Niri.
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "default", style = "slidevert" })
hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })

-- https://wiki.hypr.land/configuring/core/autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("vicinae server")
end)

-- https://wiki.hypr.land/configuring/core/binds/
local function focus_other_layer()
    local window = hl.get_active_window()

    if window and window.floating then
        hl.dispatch(hl.dsp.window.cycle_next({ tiled = true }))
    else
        hl.dispatch(hl.dsp.window.cycle_next({ floating = true }))
    end
end

-- Resizes by a fraction of the focused monitor, like Niri's percentage steps.
-- A tiled resize moves the split, so a window right of or below it shrinks.
local function resize_by(x, y)
    return function()
        local monitor = hl.get_active_monitor()
        if not monitor then
            return
        end

        hl.dispatch(hl.dsp.window.resize({
            x        = math.floor(monitor.width / monitor.scale * x),
            y        = math.floor(monitor.height / monitor.scale * y),
            relative = true,
        }))
    end
end

-- Launcher
hl.bind("SUPER + T", hl.dsp.exec_cmd("ghostty"), { description = "Open a Terminal" })
hl.bind("SUPER + Space", hl.dsp.exec_cmd("vicinae open"), { description = "Open Vicinae" })

-- Windows
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Close window" })

-- Focus movement
hl.bind("SUPER + Left", hl.dsp.focus({ direction = "left" }), { description = "Focus window left" })
hl.bind("SUPER + Down", hl.dsp.focus({ direction = "down" }), { description = "Focus window down" })
hl.bind("SUPER + Up", hl.dsp.focus({ direction = "up" }), { description = "Focus window up" })
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "right" }), { description = "Focus window right" })
hl.bind("SUPER + H", hl.dsp.focus({ direction = "left" }), { description = "Focus window left" })
hl.bind("SUPER + J", hl.dsp.focus({ direction = "down" }), { description = "Focus window down" })
hl.bind("SUPER + K", hl.dsp.focus({ direction = "up" }), { description = "Focus window up" })
hl.bind("SUPER + L", hl.dsp.focus({ direction = "right" }), { description = "Focus window right" })

-- Window movement
hl.bind("SUPER + CTRL + Left", hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })
hl.bind("SUPER + CTRL + Down", hl.dsp.window.move({ direction = "down" }), { description = "Move window down" })
hl.bind("SUPER + CTRL + Up", hl.dsp.window.move({ direction = "up" }), { description = "Move window up" })
hl.bind("SUPER + CTRL + Right", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })
hl.bind("SUPER + CTRL + H", hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })
hl.bind("SUPER + CTRL + J", hl.dsp.window.move({ direction = "down" }), { description = "Move window down" })
hl.bind("SUPER + CTRL + K", hl.dsp.window.move({ direction = "up" }), { description = "Move window up" })
hl.bind("SUPER + CTRL + L", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

-- Monitor focus
hl.bind("SUPER + SHIFT + Left", hl.dsp.focus({ monitor = "l" }), { description = "Focus monitor left" })
hl.bind("SUPER + SHIFT + Down", hl.dsp.focus({ monitor = "d" }), { description = "Focus monitor down" })
hl.bind("SUPER + SHIFT + Up", hl.dsp.focus({ monitor = "u" }), { description = "Focus monitor up" })
hl.bind("SUPER + SHIFT + Right", hl.dsp.focus({ monitor = "r" }), { description = "Focus monitor right" })
hl.bind("SUPER + SHIFT + H", hl.dsp.focus({ monitor = "l" }), { description = "Focus monitor left" })
hl.bind("SUPER + SHIFT + J", hl.dsp.focus({ monitor = "d" }), { description = "Focus monitor down" })
hl.bind("SUPER + SHIFT + K", hl.dsp.focus({ monitor = "u" }), { description = "Focus monitor up" })
hl.bind("SUPER + SHIFT + L", hl.dsp.focus({ monitor = "r" }), { description = "Focus monitor right" })

-- Move window to monitor
hl.bind("SUPER + SHIFT + CTRL + Left", hl.dsp.window.move({ monitor = "l" }), { description = "Move window to monitor left" })
hl.bind("SUPER + SHIFT + CTRL + Down", hl.dsp.window.move({ monitor = "d" }), { description = "Move window to monitor down" })
hl.bind("SUPER + SHIFT + CTRL + Up", hl.dsp.window.move({ monitor = "u" }), { description = "Move window to monitor up" })
hl.bind("SUPER + SHIFT + CTRL + Right", hl.dsp.window.move({ monitor = "r" }), { description = "Move window to monitor right" })
hl.bind("SUPER + SHIFT + CTRL + H", hl.dsp.window.move({ monitor = "l" }), { description = "Move window to monitor left" })
hl.bind("SUPER + SHIFT + CTRL + J", hl.dsp.window.move({ monitor = "d" }), { description = "Move window to monitor down" })
hl.bind("SUPER + SHIFT + CTRL + K", hl.dsp.window.move({ monitor = "u" }), { description = "Move window to monitor up" })
hl.bind("SUPER + SHIFT + CTRL + L", hl.dsp.window.move({ monitor = "r" }), { description = "Move window to monitor right" })

-- Workspace focus
hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "r+1" }), { description = "Focus workspace down" })
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "r-1" }), { description = "Focus workspace up" })
hl.bind("SUPER + U", hl.dsp.focus({ workspace = "r+1" }), { description = "Focus workspace down" })
hl.bind("SUPER + I", hl.dsp.focus({ workspace = "r-1" }), { description = "Focus workspace up" })

-- Move window to workspace
hl.bind("SUPER + CTRL + Page_Down", hl.dsp.window.move({ workspace = "r+1" }), { description = "Move window to workspace down" })
hl.bind("SUPER + CTRL + Page_Up", hl.dsp.window.move({ workspace = "r-1" }), { description = "Move window to workspace up" })
hl.bind("SUPER + CTRL + U", hl.dsp.window.move({ workspace = "r+1" }), { description = "Move window to workspace down" })
hl.bind("SUPER + CTRL + I", hl.dsp.window.move({ workspace = "r-1" }), { description = "Move window to workspace up" })

-- Workspace by index
hl.bind("SUPER + 1", hl.dsp.focus({ workspace = 1 }), { description = "Focus workspace 1" })
hl.bind("SUPER + 2", hl.dsp.focus({ workspace = 2 }), { description = "Focus workspace 2" })
hl.bind("SUPER + 3", hl.dsp.focus({ workspace = 3 }), { description = "Focus workspace 3" })
hl.bind("SUPER + 4", hl.dsp.focus({ workspace = 4 }), { description = "Focus workspace 4" })
hl.bind("SUPER + 5", hl.dsp.focus({ workspace = 5 }), { description = "Focus workspace 5" })
hl.bind("SUPER + 6", hl.dsp.focus({ workspace = 6 }), { description = "Focus workspace 6" })
hl.bind("SUPER + 7", hl.dsp.focus({ workspace = 7 }), { description = "Focus workspace 7" })
hl.bind("SUPER + 8", hl.dsp.focus({ workspace = 8 }), { description = "Focus workspace 8" })
hl.bind("SUPER + 9", hl.dsp.focus({ workspace = 9 }), { description = "Focus workspace 9" })
hl.bind("SUPER + CTRL + 1", hl.dsp.window.move({ workspace = 1 }), { description = "Move window to workspace 1" })
hl.bind("SUPER + CTRL + 2", hl.dsp.window.move({ workspace = 2 }), { description = "Move window to workspace 2" })
hl.bind("SUPER + CTRL + 3", hl.dsp.window.move({ workspace = 3 }), { description = "Move window to workspace 3" })
hl.bind("SUPER + CTRL + 4", hl.dsp.window.move({ workspace = 4 }), { description = "Move window to workspace 4" })
hl.bind("SUPER + CTRL + 5", hl.dsp.window.move({ workspace = 5 }), { description = "Move window to workspace 5" })
hl.bind("SUPER + CTRL + 6", hl.dsp.window.move({ workspace = 6 }), { description = "Move window to workspace 6" })
hl.bind("SUPER + CTRL + 7", hl.dsp.window.move({ workspace = 7 }), { description = "Move window to workspace 7" })
hl.bind("SUPER + CTRL + 8", hl.dsp.window.move({ workspace = 8 }), { description = "Move window to workspace 8" })
hl.bind("SUPER + CTRL + 9", hl.dsp.window.move({ workspace = 9 }), { description = "Move window to workspace 9" })

-- Wheel scrolling
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "r+1" }), { description = "Focus workspace down" })
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "r-1" }), { description = "Focus workspace up" })
hl.bind("SUPER + CTRL + mouse_down", hl.dsp.window.move({ workspace = "r+1" }), { description = "Move window to workspace down" })
hl.bind("SUPER + CTRL + mouse_up", hl.dsp.window.move({ workspace = "r-1" }), { description = "Move window to workspace up" })
hl.bind("SUPER + mouse_right", hl.dsp.focus({ direction = "right" }), { description = "Focus window right" })
hl.bind("SUPER + mouse_left", hl.dsp.focus({ direction = "left" }), { description = "Focus window left" })
hl.bind("SUPER + CTRL + mouse_right", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })
hl.bind("SUPER + CTRL + mouse_left", hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })
hl.bind("SUPER + SHIFT + mouse_down", hl.dsp.focus({ direction = "right" }), { description = "Focus window right" })
hl.bind("SUPER + SHIFT + mouse_up", hl.dsp.focus({ direction = "left" }), { description = "Focus window left" })
hl.bind("SUPER + CTRL + SHIFT + mouse_down", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })
hl.bind("SUPER + CTRL + SHIFT + mouse_up", hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })

-- Splits
hl.bind("SUPER + R", hl.dsp.layout("togglesplit"), { description = "Toggle split direction" })
hl.bind("SUPER + SHIFT + R", hl.dsp.layout("swapsplit"), { description = "Swap split sides" })

-- Sizing
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "Maximize window" })
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Fullscreen window" })
hl.bind("SUPER + C", hl.dsp.window.center(), { description = "Center floating window" })
hl.bind("SUPER + Minus", resize_by(-0.1, 0), { repeating = true, description = "Resize window width by -10%" })
hl.bind("SUPER + Equal", resize_by(0.1, 0), { repeating = true, description = "Resize window width by +10%" })
hl.bind("SUPER + SHIFT + Minus", resize_by(0, -0.1), { repeating = true, description = "Resize window height by -10%" })
hl.bind("SUPER + SHIFT + Equal", resize_by(0, 0.1), { repeating = true, description = "Resize window height by +10%" })

-- Floating / tabbed
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle window floating" })
hl.bind("SUPER + SHIFT + V", focus_other_layer, { description = "Switch focus between floating and tiling" })
hl.bind("SUPER + W", hl.dsp.group.toggle(), { description = "Toggle tabbed group" })
hl.bind("SUPER + BracketLeft", hl.dsp.window.move({ direction = "left", group_aware = true }), { description = "Move window left into or out of a group" })
hl.bind("SUPER + BracketRight", hl.dsp.window.move({ direction = "right", group_aware = true }), { description = "Move window right into or out of a group" })
hl.bind("SUPER + Comma", hl.dsp.group.prev(), { description = "Focus previous tab" })
hl.bind("SUPER + Period", hl.dsp.group.next(), { description = "Focus next tab" })

-- System
hl.bind("SUPER + Escape", hl.dsp.submap("passthrough"), { description = "Pass shortcuts to the window" })
hl.define_submap("passthrough", function()
    hl.bind("SUPER + Escape", hl.dsp.submap("reset"), { description = "Stop passing shortcuts to the window" })
end)
hl.bind("SUPER + SHIFT + E", hl.dsp.exit(), { description = "Quit" })
hl.bind("CTRL + ALT + Delete", hl.dsp.exit(), { description = "Quit" })

-- https://wiki.hypr.land/configuring/core/rules/
hl.window_rule({
    name             = "chrome-open-unfocused",
    match            = { class = "(?i)^google-chrome(-.*)?$" },
    no_initial_focus = true,
})

hl.window_rule({
    name  = "firefox-picture-in-picture",
    match = { class = "firefox$", title = "^Picture-in-Picture$" },
    float = true,
    pin   = true,
})

hl.window_rule({
    name            = "hide-password-managers-from-capture",
    match           = { class = "^org\\.(keepassxc\\.KeePassXC|gnome\\.World\\.Secrets)$" },
    no_screen_share = true,
})
