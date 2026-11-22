-- Noctalia
hl.bind("SUPER + D", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"), { description = "Open App Launcher" })
hl.bind("SUPER + O", hl.dsp.exec_cmd("noctalia msg window-switcher open"), { description = "Open Window Switcher" })
hl.bind("SUPER + S", hl.dsp.exec_cmd("noctalia msg screenshot-region"), { description = "Take a Screenshot" })
hl.bind("SUPER + ALT + L", hl.dsp.exec_cmd("noctalia msg session lock"), { description = "Lock the Screen" })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up 5"), { locked = true, repeating = true, description = "Raise volume" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down 5"), { locked = true, repeating = true, description = "Lower volume" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true, description = "Mute volume" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true, description = "Mute microphone" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true, description = "Play or pause media" })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("noctalia msg media stop"), { locked = true, description = "Stop media" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("noctalia msg media previous"), { locked = true, description = "Previous track" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("noctalia msg media next"), { locked = true, description = "Next track" })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("noctalia msg brightness-up 5"), { locked = true, repeating = true, description = "Raise brightness" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down 5"), { locked = true, repeating = true, description = "Lower brightness" })

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("noctalia msg screenshot-region"), { description = "Screenshot a region" })
hl.bind("CTRL + Print", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"), { description = "Screenshot the screen" })
hl.bind("ALT + Print", hl.dsp.exec_cmd("noctalia msg screenshot-window"), { description = "Screenshot the window" })

hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("noctalia msg session lock-and-suspend"), { locked = true, description = "Lock and suspend" })

-- Floating Noctalia settings window.
hl.window_rule({
    name  = "noctalia-settings",
    match = { class = "dev.noctalia.Noctalia" },
    float = true,
    size  = { 1080, 920 },
})

-- Noctalia animates its own surfaces; Hyprland's layer animations tear them.
hl.layer_rule({
    name    = "noctalia-no-anim",
    match   = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
    no_anim = true,
})

hl.layer_rule({
    name         = "noctalia-blur",
    match        = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
    ignore_alpha = 0.5,
    blur         = true,
    blur_popups  = true,
})
