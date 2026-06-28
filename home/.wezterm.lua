local wezterm = require("wezterm")

local config = wezterm.config_builder()

local is_windows = os.getenv("OS") and os.getenv("OS"):lower():find("windows")
local is_macos = wezterm.target_triple:lower():find("darwin") ~= nil
local font = wezterm.font("ZedMono Nerd Font Mono", { weight = "Medium" })

-- ░▒▓ Cyberpunk / hacker-man palette ▓▒░
local palette = {
 bg    = "#050608", -- near-black void
 bg_alt  = "#0a0e14", -- panel background
 bg_dim  = "#0d1117", -- inactive surfaces
 fg    = "#c8ffe0", -- soft phosphor text
 green  = "#00ff9c", -- neon matrix green (primary accent)
 green_dim = "#00b36b",
 cyan   = "#00d4ff", -- electric cyan
 magenta = "#ff2e88", -- hot neon pink
 purple  = "#bd00ff", -- ultraviolet
 amber  = "#ffb000", -- warning amber
 red   = "#ff3355", -- alert red
 muted  = "#3b4a52", -- dim chrome
}

-- Color scheme (fully custom neon terminal palette)
config.max_fps = 120
config.colors = {
 foreground = palette.fg,
 background = palette.bg,

 cursor_bg = palette.green,
 cursor_fg = palette.bg,
 cursor_border = palette.green,

 selection_fg = palette.bg,
 selection_bg = palette.cyan,

 scrollbar_thumb = palette.muted,
 split = palette.green_dim,

 ansi = {
  palette.bg_alt, -- black
  palette.red,   -- red
  palette.green,  -- green
  palette.amber,  -- yellow
  palette.cyan,  -- blue
  palette.magenta, -- magenta
  palette.cyan,  -- cyan
  palette.fg,   -- white
 },
 brights = {
  palette.muted,  -- bright black
  palette.red,   -- bright red
  palette.green,  -- bright green
  palette.amber,  -- bright yellow
  palette.purple, -- bright blue
  palette.magenta, -- bright magenta
  palette.cyan,  -- bright cyan
 "#ffffff",    -- bright white
 },

 tab_bar = {
  background = palette.bg,
  new_tab = { bg_color = palette.bg, fg_color = palette.muted },
  new_tab_hover = { bg_color = palette.bg_alt, fg_color = palette.green },
  active_tab = { bg_color = palette.bg_alt, fg_color = palette.green, intensity = "Bold" },
  inactive_tab = { bg_color = palette.bg, fg_color = palette.muted },
  inactive_tab_hover = { bg_color = palette.bg_dim, fg_color = palette.cyan },
 },
}

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
  font = wezterm.font("ZedMono Nerd Font Mono", { weight = "Medium"}),
 },
}

-- Cursor (glowing neon bar)
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 450
config.cursor_blink_ease_in = "EaseOut"
config.cursor_blink_ease_out = "EaseOut"

-- Window aesthetics
config.initial_cols = 120
config.initial_rows = 30
config.window_decorations = "INTEGRATED_BUTTONS | RESIZE"
config.window_background_opacity = 0.82
config.text_background_opacity = 0.95
config.window_padding = {
 left = 18,
 right = 18,
 top = 12,
 bottom = 10,
}
config.window_frame = {
 font = wezterm.font("ZedMono Nerd Font Mono", { weight = "Bold" }),
 font_size = 12.0,
 active_titlebar_bg = palette.bg,
 inactive_titlebar_bg = palette.bg,
}
config.inactive_pane_hsb = {
 saturation = 0.7,
 brightness = 0.55,
}

config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.integrated_title_button_style = "Windows"
config.integrated_title_button_alignment = "Right"
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false
config.show_tab_index_in_tab_bar = false
config.tab_max_width = 20

-- Always confirm before closing a pane/tab/window (no instant close)
config.window_close_confirmation = "AlwaysPrompt"
config.skip_close_confirmation_for_processes_named = {}

-- Bell (neon pulse instead of beep)
config.audible_bell = "Disabled"
config.visual_bell = {
 fade_in_duration_ms = 75,
 fade_out_duration_ms = 150,
 fade_in_function = "EaseIn",
 fade_out_function = "EaseOut",
 target = "CursorColor",
}

if is_windows then
 local zed_mono = wezterm.font("ZedMono Nerd Font", { weight = "Medium", stretch = "Expanded" })
 config.font = zed_mono
 config.font_rules = {
  { intensity = "Bold", italic = false, font = zed_mono },
  { italic = true, font = wezterm.font("ZedMono Nerd Font", { weight = "Medium", stretch = "Expanded" }) },
 }
 config.default_prog = { "pwsh.exe", "-NoLogo" }
 config.win32_system_backdrop = "Acrylic"
 config.window_background_opacity = 0.78
 config.window_frame.font_size = 10.5
 config.font_size = 11.0
end

if is_macos then
 config.window_background_opacity = 0.8
 config.macos_window_background_blur = 50
 config.font_size = 12.5
 config.window_frame.font_size = 12.0
end

-- Key bindings (iTerm2-style pane splits + navigation)
local mod = is_macos and "CMD" or "CTRL"
config.keys = {
 -- Split panes
 { key = "d", mods = mod, action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
 { key = "d", mods = mod .. "|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },

 -- Close current pane: single mod+W confirms; double mod+W (within ~1s) closes without confirm
 {
  key = "w",
  mods = mod,
  action = wezterm.action.Multiple({
   wezterm.action.ActivateKeyTable({
    name = "close_pane",
    one_shot = true,
    timeout_milliseconds = 1000,
   }),
   wezterm.action.CloseCurrentPane({ confirm = true }),
  }),
 },
 { key = "w", mods = mod .. "|SHIFT", action = wezterm.action.CloseCurrentTab({ confirm = true }) },

 { key = "Backspace", mods = mod, action = wezterm.action.SendKey({ key = "w", mods = "CTRL" }) },

 -- Switch tabs
 { key = "t", mods = mod, action = wezterm.action.SpawnTab("CurrentPaneDomain") },
 {
  key = "e",
  mods = mod,
  action = wezterm.action.PromptInputLine({
   description = wezterm.format({
    { Foreground = { Color = "#00ff9c" } },
    { Attribute = { Intensity = "Bold" } },
    { Text = "Rename tab:" },
   }),
   action = wezterm.action_callback(function(window, _, line)
    if line then
     window:active_tab():set_title(line)
    end
   end),
  }),
 },
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

-- One-shot table: a second mod+W (within the timeout) closes the current pane, no confirm
config.key_tables = {
 close_pane = {
  { key = "w", mods = mod, action = wezterm.action.CloseCurrentPane({ confirm = false }) },
 },
}

-- ▓▒░ Powerline tab titles: "▐ 2 folder ▌" with neon glow ░▒▓
local SOLID_LEFT = wezterm.nerdfonts.pl_left_hard_divider
local SOLID_RIGHT = wezterm.nerdfonts.pl_right_hard_divider

wezterm.on("format-tab-title", function(tab, tabs, panes, conf, hover, max_width)
 local title = tab.tab_title
 if title and #title > 0 then
  -- Manually renamed tab: show verbatim
 else
  -- Fall back to the process/pane title, reduced to its last path segment
  title = tab.active_pane.title:gsub("[/\\]+$", ""):gsub(".*[/\\]", "")
 end
 local index = tab.tab_index + 1

 local fg = tab.is_active and palette.green or palette.muted
 local edge_bg = palette.bg
 local cell_bg = tab.is_active and palette.bg_alt or palette.bg_dim

 return {
  { Background = { Color = edge_bg } },
  { Foreground = { Color = cell_bg } },
  { Text = SOLID_RIGHT },
  { Background = { Color = cell_bg } },
  { Foreground = { Color = fg } },
  { Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
  { Text = string.format(" %d %s ", index, title) },
  { Background = { Color = edge_bg } },
  { Foreground = { Color = cell_bg } },
  { Text = SOLID_LEFT },
 }

end)

return config