return function(userConfigDir)
    hl.window_rule({ name = "float-by-default", match = { class = ".*" }, float = true })
    -- Config verification runs without loading plugins.
    if not hl.plugin.hyprbars then return end

    hl.window_rule({
        name = "gtk-native-headers",
        match = { class = "org[.]gnome[.](Nautilus|TextEditor)" },
        ["hyprbars:no_bar"] = true,
    })

    -- Noctalia writes this module when its Hyprland template is enabled.
    local ok, theme = pcall(require, userConfigDir .. "/noctalia.lua")
    local colors = {
        surface = "rgb(24273a)", on_surface = "rgb(cad3f5)",
        primary = "rgb(c6a0f6)", secondary = "rgb(b7bdf8)", error = "rgb(ed8796)",
    }
    if ok then
        theme.apply_theme()
        colors = theme.colors
    end

    hl.config({
        plugin = {
            hyprbars = {
                bar_height            = 30,
                bar_color             = colors.surface,
                bar_text_size         = 11,
                bar_text_font         = "Adwaita Sans",
                bar_text_align        = "left",
                bar_padding           = 12,
                bar_button_padding    = 8,
                bar_part_of_window    = true,
                inactive_button_color = colors.secondary,
                ["col.text"]          = colors.on_surface,
                on_double_click       = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
            },
        },
    })

    hl.plugin.hyprbars.add_button({ bg_color = colors.error, fg_color = colors.surface, size = 14, icon = "×", action = "hyprctl dispatch 'hl.dsp.window.close()'" })
    hl.plugin.hyprbars.add_button({ bg_color = colors.primary, fg_color = colors.surface, size = 14, icon = "+", action = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']] })
    hl.plugin.hyprbars.add_button({ bg_color = colors.secondary, fg_color = colors.surface, size = 14, icon = "~", action = [[hyprctl dispatch 'hl.dsp.window.float({ action = "toggle" })']] })
end
