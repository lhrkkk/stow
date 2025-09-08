-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- resurrect.wezterm 插件
local resurrect = nil

-- 直接加载插件文件（绕过 wezterm.plugin API）
do
  local HOME = os.getenv("HOME") or ""
  local plugin_dir = HOME .. "/.config/wezterm/plugins/resurrect.wezterm/plugin"

  -- 设置加载路径
  package.path = plugin_dir .. "/?.lua;" .. plugin_dir .. "/resurrect/?.lua;" .. package.path

  -- 设置全局 wezterm 对象供插件使用
  _G.wezterm = wezterm

  -- 尝试加载插件
  local ok, plugin = pcall(function()
    return dofile(plugin_dir .. "/init.lua")
  end)

  if ok and plugin then
    resurrect = plugin
    -- 配置插件
    if resurrect.state_manager then
      resurrect.state_manager.set_max_nlines(2000)
      -- 暂时禁用周期性保存，先让基本功能工作
      -- resurrect.state_manager.periodic_save({ interval_seconds = 900, save_workspaces = true, save_windows = true, save_tabs = true })
    end
    wezterm.log_info("resurrect.wezterm 已加载（直接加载）")
  else
    wezterm.log_error("resurrect.wezterm 加载失败: " .. tostring(plugin))
  end
end

config.color_scheme = "Selenized Light (Gogh)"
-- config.color_scheme = "Catppuccin Latte"

config.max_fps = 120
-- 动态读取当前主题的背景色，用于标签栏与标题栏配色（方案B）
local schemes = wezterm.get_builtin_color_schemes()
-- local scheme = schemes["Selenized Light (Gogh)"]
local scheme = schemes[config.color_scheme]
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
-- config.colors.foreground = "#53676d"
-- config.colors.background = "#fbf3db"
config.colors.cursor_bg = "#53676d"
config.colors.cursor_fg = "#fbf3db"

-- 光标设置
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500
config.cursor_thickness = 2
config.force_reverse_video_cursor = true


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
  saturation = 0.95,
  brightness = 0.95,
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
-- 调试：测试配置是否加载
table.insert(config.keys, {
  key = "t",
  mods = "CMD|CTRL",
  action = wezterm.action_callback(function(window, pane)
    -- 输出为注释，避免 shell 解释
    if resurrect then
      pane:send_text("\necho '✅ WezTerm 插件已加载'\n")
    else
      pane:send_text("\necho '❌ WezTerm 插件未加载'\n")
    end
  end),
})
-- Save workspace (Cmd+Option+S)
table.insert(config.keys, {
  key = "s",
  mods = "CMD|OPT",
  action = wezterm.action_callback(function(win, pane)
    if resurrect and resurrect.state_manager then
      local ok, err = pcall(function()
        resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
      end)
      if ok then
        pane:send_text("\necho '✅ 工作区已保存'\n")
      else
        pane:send_text("\necho '❌ 保存失败: " .. tostring(err):gsub("'", "") .. "'\n")
      end
    else
      pane:send_text("\necho '❌ 插件未加载'\n")
    end
  end),
})
-- Restore (Cmd+Option+R)
table.insert(config.keys, {
  key = "r",
  mods = "CMD|OPT",
  action = wezterm.action_callback(function(win, pane)
    if resurrect and resurrect.fuzzy_loader then
      local opts = { relative = true, restore_text = true }
      resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
        local type = id:match("^([^/]+)")
        id = id:match("([^/]+)$")
        id = (id and id:match("(.+)%.%w+$")) or id
        if type == "workspace" then
          local state = resurrect.state_manager.load_state(id, "workspace")
          resurrect.workspace_state.restore_workspace(state, opts)
        elseif type == "window" then
          local state = resurrect.state_manager.load_state(id, "window")
          resurrect.window_state.restore_window(pane:window(), state, opts)
        elseif type == "tab" then
          local state = resurrect.state_manager.load_state(id, "tab")
          resurrect.tab_state.restore_tab(pane:tab(), state, opts)
        end
      end, { title = "Load state" })
    else
      pane:send_text("\necho '❌ 插件未加载'\n")
    end
  end),
})

-- 不关闭终端
config.quit_when_all_windows_are_closed = false

-- and finally, return the configuration to wezterm
return config
