local wezterm = require("wezterm")

local config = wezterm.config_builder()

local is_windows = os.getenv("OS") and os.getenv("OS"):lower():find("windows")
local is_macos = wezterm.target_triple:lower():find("darwin") ~= nil
local font = wezterm.font("ZedMono Nerd Font Mono", { weight = "Medium" })

-- Color scheme
config.color_scheme = "Tokyo Night Storm"
config.max_fps = 120

-- Font
config.font = font
config.line_height = 1.1
config.cell_width = 0.95
config.font_rules = {
  {
    intensity = "Bold",
    italic = false,
    font = wezterm.font("ZedMono Nerd Font Mono", { weight = "Bold" }),
  },
  {
    italic = true,
    font = wezterm.font("ZedMono Nerd Font Mono", { weight = "Medium", italic = true }),
  },
}

-- Cursor
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "EaseOut"
config.cursor_blink_ease_out = "EaseOut"

-- Window aesthetics
config.window_decorations = "TITLE | RESIZE"
config.window_padding = {
  left = 14,
  right = 14,
  top = 8,
  bottom = 8,
}
config.window_frame = {
  font = wezterm.font("ZedMono Nerd Font Mono", { weight = "Bold" }),
  font_size = 12.0,
  active_titlebar_bg = "#1a1b26",
  inactive_titlebar_bg = "#16161e",
}
config.inactive_pane_hsb = {
  saturation = 0.85,
  brightness = 0.65,
}

config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.show_tab_index_in_tab_bar = false
config.tab_max_width = 20

-- Always confirm before closing a pane/tab/window (no instant close)
config.window_close_confirmation = "AlwaysPrompt"
config.skip_close_confirmation_for_processes_named = {}

config.colors = {
  tab_bar = {
    background = "#16161e",
    new_tab = { bg_color = "#16161e", fg_color = "#565f89" },
    active_tab = { bg_color = "#1a1b26", fg_color = "#7aa2f7", intensity = "Bold" },
    inactive_tab = { bg_color = "#16161e", fg_color = "#565f89" },
    inactive_tab_hover = { bg_color = "#1a1b26", fg_color = "#7aa2f7" },
  },
}

-- Bell (subtle visual glow instead of beep)
config.audible_bell = "Disabled"
config.visual_bell = {
  fade_in_duration_ms = 75,
  fade_out_duration_ms = 150,
  fade_in_function = "EaseIn",
  fade_out_function = "EaseOut",
  target = "CursorColor",
}

if is_windows then
  config.win32_system_backdrop = "Acrylic"
  config.window_background_opacity = 0.7
  config.window_frame.font_size = 10.0
end

if is_macos then
  config.window_background_opacity = 0.85
  config.macos_window_background_blur = 60
  config.font_size = 12.5
  config.window_frame.font_size = 12.0
end

-- Key bindings (iTerm2-style pane splits + navigation)
local mod = is_macos and "CMD" or "CTRL"
config.keys = {
  -- Split panes
  { key = "d", mods = mod, action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "d", mods = mod .. "|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- Close current pane
  { key = "w", mods = mod, action = wezterm.action.CloseCurrentPane({ confirm = true }) },

  { key = "Backspace", mods = mod, action = wezterm.action.SendKey({ key = "w", mods = "CTRL" }) },

  -- Switch tabs
  { key = "LeftArrow", mods = mod .. "|ALT", action = wezterm.action.ActivateTabRelative(-1) },
  { key = "RightArrow", mods = mod .. "|ALT", action = wezterm.action.ActivateTabRelative(1) },

  -- Navigate panes (vim-style)
  { key = "h", mods = mod .. "|ALT", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "l", mods = mod .. "|ALT", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "k", mods = mod .. "|ALT", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "j", mods = mod .. "|ALT", action = wezterm.action.ActivatePaneDirection("Down") },

  -- Resize panes
  { key = "LeftArrow", mods = mod .. "|SHIFT", action = wezterm.action.AdjustPaneSize({ "Left", 3 }) },
  { key = "RightArrow", mods = mod .. "|SHIFT", action = wezterm.action.AdjustPaneSize({ "Right", 3 }) },
  { key = "UpArrow", mods = mod .. "|SHIFT", action = wezterm.action.AdjustPaneSize({ "Up", 3 }) },
  { key = "DownArrow", mods = mod .. "|SHIFT", action = wezterm.action.AdjustPaneSize({ "Down", 3 }) },

  -- Toggle pane zoom (fullscreen the active pane)
  { key = "Enter", mods = mod .. "|SHIFT", action = wezterm.action.TogglePaneZoomState },
}

-- Cleaner tab titles: "  2 · folder  "
wezterm.on("format-tab-title", function(tab)
  local title = tab.tab_title
  if not title or #title == 0 then
    title = tab.active_pane.title
  end
  -- Keep just the last path segment if it looks like a path
  title = title:gsub("[/\\]+$", ""):gsub(".*[/\\]", "")
  local index = tab.tab_index + 1
  return string.format("  %d · %s  ", index, title)
end)

-- Elegant right-status clock
wezterm.on("update-right-status", function(window)
  local date = wezterm.strftime("%a %b %-d  %H:%M")
  window:set_right_status(wezterm.format({
    { Foreground = { Color = "#7aa2f7" } },
    { Text = wezterm.nerdfonts.md_clock_outline .. "  " .. date .. "   " },
  }))
end)

return config