-- Hammerspoon Config: Manual IDE font size configuration via UI
-- Modular architecture with display detection, JetBrains/Ghostty font management
--
-- @module display-font-adjuster
-- @version 3.0
-- @author Bart Smykla
-- @license MIT

-------------------------------------------------------------------------------
-- Debug Mode Configuration
-------------------------------------------------------------------------------
-- To enable debug mode, use one of these methods:
--   1. Set environment variable: DEBUG_MODE=true hs
--   2. Run in Hammerspoon console: toggleDebugMode()
--   3. Use config UI: Cmd+Alt+Ctrl+H and enable Debug Mode
--   4. Via IPC: hs -c "toggleDebugMode()"
--
-- See README.md for complete documentation

-- Check environment variable for debug mode
local debugModeFromEnv = os.getenv("DEBUG_MODE") == "true"

-- Enable IPC for CLI debugging (hs command)
require("hs.ipc")

-- Initialize logger with appropriate level (will be updated after config loads)
local log = hs.logger.new('display-font-adjuster', 'warning')

-------------------------------------------------------------------------------
-- Module Imports
-------------------------------------------------------------------------------

-- Add lua module directory to package path
local home = os.getenv("HOME")
package.path = home .. "/.hammerspoon/lua/?.lua;" .. package.path

local configModule = require("config")
local display = require("display")
local jetbrains = require("jetbrains")
local ghostty = require("ghostty")
local ui = require("ui")

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-- Alert duration in seconds
local ALERT_DURATION = 2

-- Hotkey code for 'H' key
local HOTKEY_H = 4

-------------------------------------------------------------------------------
-- Configuration
-------------------------------------------------------------------------------

-- Load initial configuration
local config = configModule.load(log, debugModeFromEnv)

-- Apply debug mode settings
configModule.updateLoggerLevel(log, config.debugMode)

-- Show alert on config load only if debug mode is enabled
if config.debugMode then
  hs.alert.show("Hammerspoon config loaded (Debug Mode ON)", ALERT_DURATION)
  log.d("Configuration loaded with debug mode enabled")
end

-------------------------------------------------------------------------------
-- Global Functions (accessible via IPC and console)
-------------------------------------------------------------------------------

--- Toggle debug mode (callable from IPC or console)
function toggleDebugMode()
  config.debugMode = not config.debugMode
  configModule.updateLoggerLevel(log, config.debugMode)
  configModule.save(config, log)

  local status = config.debugMode and "enabled" or "disabled"
  hs.alert.show(string.format("Debug mode %s", status), ALERT_DURATION)
  log.i(string.format("Debug mode toggled: %s", status))
end

--- Check debug mode status (callable from IPC or console)
function debugModeStatus()
  local status = config.debugMode and "enabled" or "disabled"
  hs.alert.show(string.format("Debug mode is %s", status), ALERT_DURATION)
  return config.debugMode
end

--- Apply font settings based on current display configuration
-- Called manually from config UI to apply font sizes to all applications
-- Determines which displays are active and applies appropriate font size
-- Fully async: returns immediately, all updates happen in background
-- Always restores original focus after all updates complete
function applyFontSettings()
  local allScreens = hs.screen.allScreens()
  local hasExternalMonitor = display.isExternalMonitorActive(log)
  local displayType = hasExternalMonitor and "external monitor connected" or "built-in only"

  log.i(string.format(
    "Applying font settings. Display: %s (screen count: %d)",
    displayType,
    #allScreens
  ))

  -- Capture original focus to restore after all updates
  local originalWindow = hs.window.focusedWindow()
  local originalApp = hs.application.frontmostApplication()

  -- Determine font sizes based on display configuration
  local jetbrainsFontSize = hasExternalMonitor and config.fontSizeWithMonitor or config.fontSizeWithoutMonitor
  local ghosttyFontSize = hasExternalMonitor and config.ghosttyFontSizeWithMonitor or config.ghosttyFontSizeWithoutMonitor

  log.i(string.format("Using font sizes: JetBrains=%d, Ghostty=%d", jetbrainsFontSize, ghosttyFontSize))

  -- Helper to restore original focus
  local function restoreOriginalFocus()
    hs.timer.doAfter(0.1, function()
      if originalWindow and originalWindow:isVisible() then
        pcall(function() originalWindow:focus() end)
        log.d("Restored focus to original window")
      elseif originalApp then
        pcall(function() originalApp:activate() end)
        log.d("Restored focus to original app")
      end
    end)
  end

  -- Store timers in global variables to prevent garbage collection during init
  -- See: https://github.com/Hammerspoon/hammerspoon/issues/3102

  -- Start JetBrains update first (fast file ops, ideScript runs async via hs.task)
  _G._jetbrainsTimer = hs.timer.doAfter(0, function()
    _G._jetbrainsTimer = nil  -- Allow GC after firing
    log.d("Starting JetBrains update (async)")
    jetbrains.updateFontSize(jetbrainsFontSize, config, log)
  end)

  -- Start Ghostty update after a short delay (needs uninterrupted keystroke sending)
  _G._ghosttyTimer = hs.timer.doAfter(0.2, function()
    _G._ghosttyTimer = nil  -- Allow GC after firing
    log.d("Starting Ghostty update (async)")
    local success, err = pcall(function()
      log.i(string.format("Updating Ghostty font size to %d", ghosttyFontSize))
      -- Pass callback to restore focus only AFTER all keystrokes complete
      ghostty.updateFontSize(ghosttyFontSize, config, log, restoreOriginalFocus)
    end)
    if not success then
      log.e(string.format("Ghostty update failed: %s", tostring(err)))
      -- Restore focus even on error
      restoreOriginalFocus()
    end
  end)

  log.d("Screen change handlers scheduled (async)")
end

--- Show configuration UI (global for IPC debugging)
function showConfigUI()
  log.i("Opening configuration UI")

  -- Define callbacks for UI actions
  local callbacks = {
    onSave = function(newConfig, originalWindow)
      log.i("Save action from UI")
      log.d(string.format("New config: fontWithMonitor=%d, fontWithout=%d, ghosttyWithMonitor=%d, ghosttyWithout=%d",
        newConfig.fontSizeWithMonitor, newConfig.fontSizeWithoutMonitor,
        newConfig.ghosttyFontSizeWithMonitor, newConfig.ghosttyFontSizeWithoutMonitor))

      -- Capture the original window passed from UI (captured before UI opened)
      local windowToRestore = originalWindow

      -- Track which settings actually changed
      local debugModeChanged = config.debugMode ~= newConfig.debugMode
      local jetbrainsChanged = config.fontSizeWithMonitor ~= newConfig.fontSizeWithMonitor or
                               config.fontSizeWithoutMonitor ~= newConfig.fontSizeWithoutMonitor

      -- Check if IDE patterns changed
      local idePatternsChanged = #config.idePatterns ~= #newConfig.idePatterns
      if not idePatternsChanged then
        for i, pattern in ipairs(config.idePatterns) do
          if pattern ~= newConfig.idePatterns[i] then
            idePatternsChanged = true
            break
          end
        end
      end
      jetbrainsChanged = jetbrainsChanged or idePatternsChanged

      local ghosttyChanged = config.ghosttyFontSizeWithMonitor ~= newConfig.ghosttyFontSizeWithMonitor or
                             config.ghosttyFontSizeWithoutMonitor ~= newConfig.ghosttyFontSizeWithoutMonitor or
                             config.ghosttyConfigOverlayPath ~= newConfig.ghosttyConfigOverlayPath

      -- Update config with new values
      for key, value in pairs(newConfig) do
        config[key] = value
      end

      -- Update logger level if debug mode changed
      if debugModeChanged then
        configModule.updateLoggerLevel(log, config.debugMode)
      end

      -- Save to persistent storage
      configModule.save(config, log)

      -- Apply font settings based on what changed
      local hasExternalMonitor = display.isExternalMonitorActive(log)

      -- Helper to restore original focus
      local function restoreOriginalFocus()
        hs.timer.doAfter(0.1, function()
          if windowToRestore and windowToRestore:isVisible() then
            pcall(function() windowToRestore:focus() end)
            log.d("Restored focus to original window")
          end
        end)
      end

      if jetbrainsChanged then
        local fontSize = hasExternalMonitor and config.fontSizeWithMonitor or config.fontSizeWithoutMonitor
        log.i(string.format("Applying JetBrains font size %d", fontSize))
        jetbrains.updateFontSize(fontSize, config, log)
      end

      if ghosttyChanged then
        local fontSize = hasExternalMonitor and config.ghosttyFontSizeWithMonitor or config.ghosttyFontSizeWithoutMonitor
        log.i(string.format("Applying Ghostty font size %d", fontSize))
        ghostty.updateFontSize(fontSize, config, log, restoreOriginalFocus)
      elseif jetbrainsChanged then
        -- If only JetBrains changed, restore focus after a delay
        restoreOriginalFocus()
      else
        -- No font changes, restore focus immediately
        restoreOriginalFocus()
      end
    end,

    onReload = function(originalWindow)
      log.i("Reload action from UI (apply settings without saving)")

      -- Capture the original window passed from UI (captured before UI opened)
      local windowToRestore = originalWindow

      local hasExternalMonitor = display.isExternalMonitorActive(log)
      local jetbrainsFontSize = hasExternalMonitor and config.fontSizeWithMonitor or config.fontSizeWithoutMonitor
      local ghosttyFontSize = hasExternalMonitor and config.ghosttyFontSizeWithMonitor or config.ghosttyFontSizeWithoutMonitor

      log.i(string.format("Using font sizes: JetBrains=%d, Ghostty=%d", jetbrainsFontSize, ghosttyFontSize))

      -- Helper to restore original focus
      local function restoreOriginalFocus()
        hs.timer.doAfter(0.1, function()
          if windowToRestore and windowToRestore:isVisible() then
            pcall(function() windowToRestore:focus() end)
            log.d("Restored focus to original window")
          end
        end)
      end

      -- Start JetBrains update
      hs.timer.doAfter(0, function()
        log.d("Starting JetBrains update (async)")
        jetbrains.updateFontSize(jetbrainsFontSize, config, log)
      end)

      -- Start Ghostty update after delay, then restore focus
      hs.timer.doAfter(0.2, function()
        log.d("Starting Ghostty update (async)")
        ghostty.updateFontSize(ghosttyFontSize, config, log, restoreOriginalFocus)
      end)
    end,

    onClose = function(originalWindow)
      log.i("Configuration UI closed")

      -- Restore focus to original window
      if originalWindow and originalWindow:isVisible() then
        hs.timer.doAfter(0.1, function()
          pcall(function() originalWindow:focus() end)
          log.d("Restored focus to original window")
        end)
      end
    end
  }

  ui.show(config, callbacks, log)
end

-------------------------------------------------------------------------------
-- Hotkey Registration
-------------------------------------------------------------------------------

-- Check if Hammerspoon has accessibility permissions
if not hs.accessibilityState() then
  hs.alert.show("Hammerspoon needs Accessibility permissions!\nGo to System Preferences > Privacy & Security > Accessibility")
  log.w("Hammerspoon does not have accessibility permissions. Hotkey may not work in all apps.")
end

-- Global for IPC debugging
configHotkeyTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
  local success, result = pcall(function()
    local flags = event:getFlags()
    local keyCode = event:getKeyCode()

    -- Check for Cmd+Alt+Ctrl+H
    -- Must have exactly cmd, alt, and ctrl (no shift or fn)
    if keyCode == HOTKEY_H and
       flags.cmd and
       flags.alt and
       flags.ctrl and
       not flags.shift and
       not flags.fn then
      log.i("Hotkey detected: Cmd+Alt+Ctrl+H")
      showConfigUI()
      return true  -- Consume the event so apps don't see it
    end

    return false  -- Let other events pass through
  end)

  if not success then
    log.e(string.format("Error in eventtap callback: %s", result))
    return false
  end

  return result
end)

configHotkeyTap:start()
log.i(string.format("Eventtap started: %s", configHotkeyTap:isEnabled()))

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

-- Log startup status (no automatic font changes - manual only via config UI)
local allScreens = hs.screen.allScreens()
local hasExternalMonitor = display.isExternalMonitorActive(log)
local displayType = hasExternalMonitor and "external monitor connected" or "built-in only"
log.i(string.format(
  "Display font adjuster loaded (manual mode). Display: %s (screen count: %d)",
  displayType,
  #allScreens
))

log.i("Configuration UI ready. Press Cmd+Alt+Ctrl+H to open settings.")
log.i("Note: If hotkey doesn't work, ensure Hammerspoon has Accessibility permissions in System Preferences.")
