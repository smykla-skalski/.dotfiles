-- Configuration management for Hammerspoon display font adjuster
-- Handles loading, saving, and defaults for persistent settings
--
-- @module config
-- @version 1.0

local M = {}

-------------------------------------------------------------------------------
-- Default Configuration
-------------------------------------------------------------------------------

--- Default configuration values
-- Used when no saved settings exist or as fallback for missing keys
M.defaults = {
  debugMode = false,
  fontSizeWithMonitor = 15,
  fontSizeWithoutMonitor = 12,
  ghosttyFontSizeWithMonitor = 20,
  ghosttyFontSizeWithoutMonitor = 15,
  ghosttyConfigOverlayPath = os.getenv("HOME") .. "/.config/ghostty/config.local",
  idePatterns = {
    "GoLand*",
    "WebStorm*",
    "RustRover*",
    "IntelliJIdea*",
    "PyCharm*",
    "CLion*",
    "DataGrip*",
  },
  jetbrainsBasePath = "/Library/Application Support/JetBrains",
}

-------------------------------------------------------------------------------
-- Configuration Functions
-------------------------------------------------------------------------------

--- Load configuration from settings or use defaults
-- @param log Logger instance for logging messages
-- @param debugModeFromEnv Whether debug mode was set via environment variable
-- @return table Configuration table with all settings
function M.load(log, debugModeFromEnv)
  -- Create a copy of defaults
  local config = {}
  for key, value in pairs(M.defaults) do
    if type(value) == "table" then
      -- Deep copy for tables (like idePatterns)
      config[key] = {}
      for i, v in ipairs(value) do
        config[key][i] = v
      end
    else
      config[key] = value
    end
  end

  -- Load saved settings
  local saved = hs.settings.get("displayFontAdjuster")
  if saved then
    -- Merge saved settings with defaults (to handle new settings)
    for key, value in pairs(saved) do
      config[key] = value
    end

    if log then
      log.d("Loaded saved configuration")
    end
  end

  -- Override with environment variable if set
  if debugModeFromEnv then
    config.debugMode = true

    if log then
      log.d("Debug mode enabled via environment variable")
    end
  end

  return config
end

--- Save configuration to persistent settings
-- @param config Configuration table to save
-- @param log Logger instance for logging messages (optional)
function M.save(config, log)
  hs.settings.set("displayFontAdjuster", config)

  if log then
    log.i("Configuration saved")
  end
end

--- Update logger level based on debug mode
-- @param log Logger instance to update
-- @param enabled Whether debug mode is enabled
function M.updateLoggerLevel(log, enabled)
  if not log then
    return
  end

  if enabled then
    log.setLogLevel('debug')
    log.d("Debug mode enabled - verbose logging active")
  else
    log.setLogLevel('warning')
    log.i("Debug mode disabled - only warnings and errors will be logged")
  end
end

return M
