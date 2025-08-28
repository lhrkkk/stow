-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.color_scheme = "Selenized Light (Gogh)"

config.max_fps = 120
-- 动态读取当前主题的背景色，用于标签栏与标题栏配色（方案B）
local schemes = wezterm.get_builtin_color_schemes()
local scheme = schemes["Selenized Light (Gogh)"]
local bg = (scheme and scheme.background) or "#fbf3db"

-- 让标签栏更浅色且跟随主题渲染
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.colors = {
  tab_bar = {
    -- 整体标签栏背景使用主题背景色，做到与内容区一致
    background = bg,

    -- 活动/非活动标签也统一为同底色，文字颜色做轻微区分
    active_tab = {
      bg_color = bg,
      fg_color = "#333333",
      intensity = "Normal",
      underline = "None",
      italic = false,
      strikethrough = false,
    },
    inactive_tab = {
      bg_color = bg,
      fg_color = "#666666",
    },
    inactive_tab_hover = {
      bg_color = bg,
      fg_color = "#333333",
      italic = true,
    },
    new_tab = {
      bg_color = bg,
      fg_color = "#666666",
    },
    new_tab_hover = {
      bg_color = bg,
      fg_color = "#333333",
      italic = true,
    },
  },
}

-- Theme consistency with Ghostty's Selenized Light custom palette
config.colors = config.colors or {}
config.colors.foreground = "#53676d"
config.colors.background = "#fbf3db"
config.colors.cursor_bg = "#53676d"
config.colors.cursor_fg = "#fbf3db"
config.colors.selection_bg = "#ece3cc"
config.colors.selection_fg = "#00978a"
config.colors.ansi = {
  "#ece3cc", "#d2212d", "#489100", "#ad8900",
  "#0072d4", "#ca4898", "#009c8f", "#909995",
}
config.colors.brights = {
  "#d5cdb6", "#cc1729", "#428b00", "#a78300",
  "#006dce", "#c44392", "#00978a", "#3a4d53",
}

config.font = wezterm.font_with_fallback({
  "JetBrainsMono Nerd Font",
  "MesloLGS Nerd Font Mono",
  "Symbols Nerd Font Mono"
})
config.font_size = 15

-- config.enable_tab_bar = false

config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

-- 集成浅色标题栏（与主题背景一致）
config.window_frame = {
  active_titlebar_bg = bg,
  inactive_titlebar_bg = bg,
  active_titlebar_fg = "#333333",
  inactive_titlebar_fg = "#666666",
}

-- Usability
config.scrollback_lines = 20000
config.audible_bell = "Disabled"

-- 关闭非激活 pane 的变暗
config.inactive_pane_hsb = {
  saturation = 1.0,
  brightness = 1.0,
}

-- Performance
config.animation_fps = 120
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

-- config.window_background_opacity = 0.8
-- config.macos_window_background_blur = 10

-- key bindings
config.keys = {
  -- Close current pane (with confirmation) via Cmd+W instead of closing the whole tab
  { key = "w", mods = "CMD",  action = wezterm.action.CloseCurrentPane { confirm = true } },
  -- Close current pane via Ctrl+W (Linux/Windows-style alternative)
  -- { key = "w", mods = "CTRL", action = wezterm.action.CloseCurrentPane { confirm = true } },
  -- Split pane right 50% via Ctrl+Space
  { key = "Space", mods = "CTRL", action = wezterm.action.SplitPane { direction = "Right", size = { Percent = 50 } } },
  -- Split pane horizontally 50% via Ctrl+S
  { key = "s", mods = "CTRL", action = wezterm.action.SplitPane { direction = "Down", size = { Percent = 50 } } },
  -- Split pane vertically 50% via Ctrl+V
  { key = "v", mods = "CTRL", action = wezterm.action.SplitPane { direction = "Right", size = { Percent = 50 } } }
}

-- Extra key bindings
config.keys = config.keys or {}
table.insert(config.keys, { key = "Enter", mods = "CMD", action = wezterm.action.ToggleFullScreen })
table.insert(config.keys, { key = "r", mods = "CMD|SHIFT", action = wezterm.action.ReloadConfiguration })

-- 不关闭终端
config.quit_when_all_windows_are_closed = false

-- and finally, return the configuration to wezterm
return config
