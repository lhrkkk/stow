local wezterm = require("wezterm")

local M = {}

local function load_plugin()
  local HOME = os.getenv("HOME") or ""
  local plugin_dir = HOME .. "/.config/wezterm/plugins/resurrect.wezterm/plugin"

  -- 扩展加载路径以便直接 require 插件模块
  package.path = plugin_dir .. "/?.lua;" .. plugin_dir .. "/resurrect/?.lua;" .. package.path

  -- 向插件暴露 wezterm（兼容不同注入方式）
  _G.wezterm = wezterm

  local ok, plugin = pcall(function()
    return dofile(plugin_dir .. "/init.lua")
  end)
  if ok and plugin then
    return plugin
  else
    wezterm.log_error("resurrect.wezterm 加载失败: " .. tostring(plugin))
    return nil
  end
end

local function add_key(config, key, mods, action)
  config.keys = config.keys or {}
  table.insert(config.keys, { key = key, mods = mods, action = action })
end

function M.setup(config)
  local resurrect = load_plugin()

  -- 即便插件未加载，部分绑定仍能正常“关闭”等；保存将被跳过
  if resurrect and resurrect.state_manager then
    resurrect.state_manager.set_max_nlines(4000)
    local auto_save = os.getenv("WEZ_RES_AUTO_SAVE")
    if auto_save and auto_save:lower() ~= "0" and auto_save:lower() ~= "false" then
      local interval = tonumber(os.getenv("WEZ_RES_AUTO_SAVE_INTERVAL" or "")) or 600
      local aw = os.getenv("WEZ_RES_AUTO_SAVE_WINDOWS")
      local at = os.getenv("WEZ_RES_AUTO_SAVE_TABS")
      resurrect.state_manager.periodic_save({
        interval_seconds = interval,
        save_workspaces = true,
        save_windows = (aw and aw:lower() ~= "0" and aw:lower() ~= "false") or false,
        save_tabs = (at and at:lower() ~= "0" and at:lower() ~= "false") or false,
      })
    end
  end

  -- 恢复上次标记的工作区；启动时清理旧状态（可选）
  wezterm.on("gui-startup", function(_)
    if resurrect and resurrect.state_manager then
      local ok, err = resurrect.state_manager.resurrect_on_gui_startup()
      if not ok and err then
        wezterm.log_warn("resurrect_on_gui_startup failed: " .. tostring(err))
      end
    end
    local prune_days = tonumber(os.getenv("WEZ_RES_PRUNE_DAYS" or ""))
    if prune_days and prune_days > 0 and resurrect and resurrect.state_manager then
      local dir = resurrect.state_manager.save_state_dir or ((os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/wezterm/resurrect/")
      if wezterm.target_triple:find("darwin") or wezterm.target_triple:find("linux") then
        local cmd = { "/bin/sh", "-lc", string.format("find %q -type f -name '*.json' -mtime +%d -delete", dir, prune_days) }
        local ok, _, stderr = wezterm.run_child_process(cmd)
        if not ok and stderr and #stderr > 0 then
          wezterm.log_warn("prune states failed: " .. tostring(stderr))
        end
      end
    end
  end)

  -- 关闭窗口时自动保存窗口快照（带时间戳）
  wezterm.on("window-destroyed", function(win)
    local onclose = os.getenv("WEZ_RES_AUTO_SAVE_ON_CLOSE")
    if onclose and (onclose:lower() == "0" or onclose:lower() == "false") then
      return
    end
    if not (resurrect and resurrect.state_manager and resurrect.window_state) then
      return
    end
    local ok = pcall(function()
      local mw = win and win:mux_window()
      if not mw then return end
      local state = resurrect.window_state.get_window_state(mw)
      local base = state.title or "untitled-window"
      local ts = os.date("%Y%m%d-%H%M%S")
      local opt_name = string.format("%s-%s", base, ts)
      resurrect.state_manager.save_state(state, opt_name)
    end)
    if not ok then
      -- ignore errors
    end
  end)

  -- 快捷键与操作（全部集中在此）

  -- Cmd+W：保存时间戳标签快照后关闭标签
  add_key(config, "w", "CMD", wezterm.action_callback(function(win, pane)
    if resurrect and resurrect.state_manager and resurrect.tab_state then
      local tab = pane:tab()
      local state = resurrect.tab_state.get_tab_state(tab)
      local base = tab:get_title()
      if not base or base == "" then base = "untitled" end
      local ts = os.date("%Y%m%d-%H%M%S")
      local opt_name = string.format("%s-%s", base, ts)
      pcall(function() resurrect.state_manager.save_state(state, opt_name) end)
    end
    win:perform_action(wezterm.action.CloseCurrentTab({ confirm = true }), pane)
  end))

  -- 保存当前工作区并标记下次自动恢复：Cmd+Opt+S
  add_key(config, "s", "CMD|OPT", wezterm.action_callback(function(win, pane)
    if resurrect and resurrect.state_manager and resurrect.workspace_state then
      local ok, err = pcall(function()
        local ws_state = resurrect.workspace_state.get_workspace_state()
        resurrect.state_manager.save_state(ws_state)
        local ws_name = wezterm.mux.get_active_workspace() or ws_state.workspace or "default"
        resurrect.state_manager.write_current_state(ws_name, "workspace")
      end)
      if ok then pane:send_text("\necho '✅ 工作区已保存并设为下次自动恢复'\n")
      else pane:send_text("\necho '❌ 保存失败: " .. tostring(err):gsub("'", "") .. "'\n") end
    else
      pane:send_text("\necho '❌ 插件未加载'\n")
    end
  end)))

  -- 交互恢复（带时间戳展示）：Cmd+Opt+R
  add_key(config, "r", "CMD|OPT", wezterm.action_callback(function(win, pane)
    if resurrect and resurrect.fuzzy_loader then
      local opts = { relative = true, restore_text = true, on_pane_restore = resurrect.tab_state.default_on_pane_restore, show_state_with_date = true }
      resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, _)
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
  end)))

  -- 保存窗口/标签
  if resurrect then
    add_key(config, "w", "CMD|OPT|SHIFT", resurrect.window_state.save_window_action())
    add_key(config, "t", "CMD|OPT|SHIFT", resurrect.tab_state.save_tab_action())
  end

  -- 快速恢复上次标记的工作区：Cmd+Opt+L
  add_key(config, "l", "CMD|OPT", wezterm.action_callback(function(_, pane)
    if resurrect and resurrect.state_manager then
      local ok, err = resurrect.state_manager.resurrect_on_gui_startup()
      if not ok then
        pane:send_text("\necho '❌ 快速恢复失败: " .. tostring(err):gsub("'", "") .. "'\n")
      end
    else
      pane:send_text("\necho '❌ 插件未加载'\n")
    end
  end)))

  -- 删除已保存状态（选择器）：Cmd+Opt+D
  add_key(config, "d", "CMD|OPT", wezterm.action_callback(function(win, pane)
    if resurrect and resurrect.fuzzy_loader and resurrect.state_manager then
      resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, _)
        resurrect.state_manager.delete_state(id) -- id 形如 "workspace/foo.json"
        pane:send_text("\necho '🗑 已删除: " .. id:gsub("'", "") .. "'\n")
      end, { title = "Delete state", show_state_with_date = true })
    else
      pane:send_text("\necho '❌ 插件未加载'\n")
    end
  end)))

  -- 工作区管理：重命名（Cmd+Opt+Ctrl+R）、切换/创建（Cmd+Opt+Ctrl+G）
  add_key(config, "r", "CMD|OPT|CTRL", wezterm.action.PromptInputLine({
    description = "Rename current workspace",
    action = wezterm.action_callback(function(_, _, line)
      if line and #line > 0 then
        local old = wezterm.mux.get_active_workspace()
        wezterm.mux.rename_workspace(old, line)
      end
    end),
  }))

  add_key(config, "g", "CMD|OPT|CTRL", wezterm.action.PromptInputLine({
    description = "Switch/create workspace",
    action = wezterm.action_callback(function(_, _, line)
      if line and #line > 0 then
        wezterm.mux.set_active_workspace(line)
      end
    end),
  }))

  -- 保存工作区快照（时间戳）：Cmd+Opt+Shift+S
  add_key(config, "S", "CMD|OPT|SHIFT", wezterm.action_callback(function(_, pane)
    if resurrect and resurrect.state_manager and resurrect.workspace_state then
      local ws_state = resurrect.workspace_state.get_workspace_state()
      local ws_name = wezterm.mux.get_active_workspace() or ws_state.workspace or "default"
      local ts = os.date("%Y%m%d-%H%M%S")
      local opt_name = string.format("%s-%s", ws_name, ts)
      local ok, err = pcall(function()
        resurrect.state_manager.save_state(ws_state, opt_name)
      end)
      if ok then
        pane:send_text("\necho '✅ 已保存工作区快照: " .. opt_name .. "'\n")
      else
        pane:send_text("\necho '❌ 保存失败: " .. tostring(err):gsub("'", "") .. "'\n")
      end
    else
      pane:send_text("\necho '❌ 插件未加载'\n")
    end
  end)))

  -- 保存工作区快照（自定义名）：Cmd+Opt+Ctrl+S
  add_key(config, "S", "CMD|OPT|CTRL", wezterm.action.PromptInputLine({
    description = "Save workspace snapshot as...",
    action = wezterm.action_callback(function(window, pane, line)
      if not (resurrect and resurrect.state_manager and resurrect.workspace_state) then
        pane:send_text("\necho '❌ 插件未加载'\n")
        return
      end
      if line and #line > 0 then
        local ws_state = resurrect.workspace_state.get_workspace_state()
        local ok, err = pcall(function()
          resurrect.state_manager.save_state(ws_state, line)
        end)
        if ok then
          pane:send_text("\necho '✅ 已保存工作区快照为: " .. line:gsub("'", "") .. "'\n")
        else
          pane:send_text("\necho '❌ 保存失败: " .. tostring(err):gsub("'", "") .. "'\n")
        end
      end
    end),
  }))

  -- 先保存再关闭标签：Cmd+Opt+W
  add_key(config, "w", "CMD|OPT", wezterm.action_callback(function(win, pane)
    if resurrect and resurrect.state_manager and resurrect.tab_state then
      local tab = pane:tab()
      local title = tab:get_title()
      local function close_tab()
        win:perform_action(wezterm.action.CloseCurrentTab({ confirm = false }), pane)
      end
      if not title or title == "" then
        win:perform_action(
          wezterm.action.PromptInputLine({
            description = "Save+Close: 输入标签标题",
            action = wezterm.action_callback(function(window, cb_pane, line)
              if line and #line > 0 then
                cb_pane:tab():set_title(line)
                local state = resurrect.tab_state.get_tab_state(cb_pane:tab())
                pcall(function() resurrect.state_manager.save_state(state) end)
              end
              window:perform_action(wezterm.action.CloseCurrentTab({ confirm = false }), cb_pane)
            end),
          }),
          pane
        )
      else
        local state = resurrect.tab_state.get_tab_state(tab)
        pcall(function() resurrect.state_manager.save_state(state) end)
        close_tab()
      end
    else
      win:perform_action(wezterm.action.CloseCurrentTab({ confirm = false }), pane)
    end
  end)))

  -- 先保存再关闭窗口：Cmd+Shift+W（逐个关闭该窗口的所有标签）
  add_key(config, "W", "CMD|SHIFT", wezterm.action_callback(function(_, pane)
    if resurrect and resurrect.state_manager and resurrect.window_state then
      local mw = pane:window()
      local state = resurrect.window_state.get_window_state(mw)
      pcall(function() resurrect.state_manager.save_state(state) end)
      local count = #mw:tabs()
      for _ = 1, count do
        mw:gui_window():perform_action(wezterm.action.CloseCurrentTab({ confirm = false }), mw:active_pane())
      end
    else
      pane:send_text("\necho '❌ 插件未加载'\n")
    end
  end)))

  -- 重新打开最近保存的标签：Cmd+Shift+L
  add_key(config, "L", "CMD|SHIFT", wezterm.action_callback(function(_, pane)
    local base_dir
    if resurrect and resurrect.state_manager then
      base_dir = resurrect.state_manager.save_state_dir
    else
      base_dir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/wezterm/resurrect/"
    end
    local tab_dir = (base_dir or "") .. "tab"
    local cmd = string.format("ls -t %q/*.json 2>/dev/null | head -n 1", tab_dir)
    local ok, stdout, _ = wezterm.run_child_process({ "/bin/sh", "-lc", cmd })
    if not ok or not stdout or stdout == "" then
      pane:send_text("\necho 'ℹ️ 没有可恢复的标签快照'\n")
      return
    end
    local latest_path = stdout:gsub("\n", "")
    local name = latest_path:match("([^/]+)%.json$")
    if not (resurrect and resurrect.state_manager and resurrect.tab_state) then
      pane:send_text("\necho '❌ 插件未加载'\n")
      return
    end
    local state = resurrect.state_manager.load_state(name, "tab")
    if not state or not state.pane_tree then
      pane:send_text("\necho '❌ 读取标签状态失败'\n")
      return
    end
    local spawn_tab_args = { cwd = state.pane_tree.cwd }
    if state.pane_tree.domain then
      spawn_tab_args.domain = { DomainName = state.pane_tree.domain }
    end
    local tab, _, _ = pane:window():spawn_tab(spawn_tab_args)
    local opts = { relative = true, restore_text = true, on_pane_restore = resurrect.tab_state.default_on_pane_restore }
    resurrect.tab_state.restore_tab(tab, state, opts)
    if state.is_zoomed then
      tab:set_zoomed(true)
    end
    pane:send_text("\necho '✅ 已恢复最近保存的标签: " .. (state.title or name):gsub("'", "") .. "'\n")
  end)))

  return resurrect
end

return M

