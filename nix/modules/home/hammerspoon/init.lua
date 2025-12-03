-- Hammerspoon Config: Auto-adjust IDE font sizes based on active display
-- Detects whether built-in display or external monitor is active
-- Monitors display changes and system wake events
-- Lua 5.3 compatible with best practices applied

-- Enable IPC for CLI debugging (hs command)
require("hs.ipc")

-- Show alert on config load for debugging
hs.alert.show("Hammerspoon config loaded", 2)

local log = hs.logger.new('display-font-adjuster', 'info')

-------------------------------------------------------------------------------
-- Configuration Management
-------------------------------------------------------------------------------

--- Load configuration from settings or use defaults
local function loadConfig()
  local defaults = {
    fontSizeWithMonitor = 15,
    fontSizeWithoutMonitor = 12,
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
    wakeDelaySeconds = 1.0,
    pollIntervalSeconds = 5.0,
  }

  -- Load saved settings
  local saved = hs.settings.get("displayFontAdjuster")
  if saved then
    -- Merge saved settings with defaults (to handle new settings)
    for key, value in pairs(saved) do
      defaults[key] = value
    end
  end

  return defaults
end

--- Save configuration to persistent settings
local function saveConfig(config)
  hs.settings.set("displayFontAdjuster", config)
  log.i("Configuration saved")
end

-- Load initial configuration
local config = loadConfig()

-- Module state
local screenWatcher = nil
local caffeineWatcher = nil
local pollTimer = nil
local lastScreenCount = 0
local lastScreenSignature = ""

-------------------------------------------------------------------------------
-- Utility Functions
-------------------------------------------------------------------------------

--- Safely read a file with proper error handling and resource cleanup
-- @param filepath The path to the file to read
-- @return content, error Content string on success, nil on failure
-- @return error nil on success, error string on failure
local function safeReadFile(filepath)
  local file, err = io.open(filepath, "r")
  if not file then
    return nil, string.format("Failed to open file: %s", err)
  end

  local content
  local success, readErr = pcall(function()
    content = file:read("*all")
  end)

  -- Ensure file is always closed, even if an error occurred
  local closeSuccess, closeErr = pcall(function()
    file:close()
  end)

  if not closeSuccess then
    log.w(string.format("Failed to close file %s: %s", filepath, closeErr))
  end

  if not success then
    return nil, string.format("Failed to read file: %s", readErr)
  end

  return content, nil
end

--- Safely write a file with proper error handling and resource cleanup
-- @param filepath The path to the file to write
-- @param content The content to write to the file
-- @return success, error true on success, false on failure
-- @return error nil on success, error string on failure
local function safeWriteFile(filepath, content)
  local file, err = io.open(filepath, "w")
  if not file then
    return false, string.format("Failed to open file for writing: %s", err)
  end

  local success, writeErr = pcall(function()
    file:write(content)
  end)

  -- Ensure file is always closed, even if an error occurred
  local closeSuccess, closeErr = pcall(function()
    file:close()
  end)

  if not closeSuccess then
    log.w(string.format("Failed to close file %s: %s", filepath, closeErr))
  end

  if not success then
    return false, string.format("Failed to write file: %s", writeErr)
  end

  return true, nil
end

--- Get JetBrains base path with validation
-- @return path The full path to JetBrains directory, or nil if not found
local function getJetBrainsPath()
  local home = os.getenv("HOME")
  if not home or home == "" then
    log.w("HOME environment variable not set")
    return nil
  end

  local path = home .. config.jetbrainsBasePath

  -- Check if directory exists using hs.fs
  local attrs = hs.fs.attributes(path)
  if not attrs or attrs.mode ~= "directory" then
    log.w(string.format("JetBrains directory not found: %s", path))
    return nil
  end

  return path
end

--- Find IDE directories using hs.fs (more efficient than shell find)
-- @param basePath The base directory to search in
-- @param pattern Shell glob pattern (e.g., "GoLand*")
-- @return results Array of matching directory paths
local function findIDEDirectories(basePath, pattern)
  local results = {}

  -- Convert shell glob pattern to Lua pattern
  local luaPattern = "^" .. pattern:gsub("%*", ".*") .. "$"

  local iter, dirObj = hs.fs.dir(basePath)
  if not iter then
    log.w(string.format("Cannot iterate directory: %s", basePath))
    return results
  end

  for entry in iter, dirObj do
    if entry ~= "." and entry ~= ".." then
      if entry:match(luaPattern) then
        local fullPath = basePath .. "/" .. entry
        local attrs = hs.fs.attributes(fullPath)
        if attrs and attrs.mode == "directory" then
          table.insert(results, fullPath)
        end
      end
    end
  end

  return results
end

-------------------------------------------------------------------------------
-- Core Functionality
-------------------------------------------------------------------------------

--- Get a unique signature for current screen configuration
-- Creates a deterministic string based on screen UUIDs
-- @return string Comma-separated sorted list of screen UUIDs
local function getScreenSignature()
  local screens = hs.screen.allScreens()
  local uuids = {}

  for _, screen in ipairs(screens) do
    local uuid = screen:getUUID()
    if uuid then
      table.insert(uuids, uuid)
    end
  end

  table.sort(uuids)
  return table.concat(uuids, ",")
end

--- Detect if an external monitor is connected
-- Checks all screens to see if any external monitor is present
-- When multiple displays are active, we want to use the larger font
-- @return boolean true if any external monitor is connected
local function isExternalMonitorActive()
  local allScreens = hs.screen.allScreens()

  if not allScreens or #allScreens == 0 then
    log.w("No screens found")
    return false
  end

  -- Known built-in display name patterns
  local builtInPatterns = {
    "^Built%-in",  -- "Built-in Retina Display"
    "^Color LCD",  -- Older MacBooks
  }

  -- Check if any screen is an external monitor
  for _, screen in ipairs(allScreens) do
    local screenName = screen:name()
    local isBuiltIn = false

    -- First try getInfo() if available
    local screenInfo = screen:getInfo()
    if screenInfo and screenInfo.builtin ~= nil then
      isBuiltIn = screenInfo.builtin
    else
      -- Fallback: check screen name against known built-in patterns
      for _, pattern in ipairs(builtInPatterns) do
        if screenName:match(pattern) then
          isBuiltIn = true
          break
        end
      end
    end

    if not isBuiltIn then
      -- Found an external monitor
      log.d(string.format(
        "External monitor detected: %s",
        screenName
      ))
      return true
    end
  end

  -- No external monitors found, only built-in display
  log.d("Only built-in display detected")
  return false
end

--- Update font size in a single other.xml file (creates if doesn't exist)
-- @param xmlPath The full path to the other.xml file
-- @param fontSize The font size to set (must be positive integer)
-- @return boolean true if file was modified and saved, false otherwise
local function updateOtherXmlFile(xmlPath, fontSize)
  -- Validate fontSize
  if type(fontSize) ~= "number" or fontSize <= 0 then
    log.e(string.format("Invalid fontSize: %s", tostring(fontSize)))
    return false
  end

  local content, readErr = safeReadFile(xmlPath)
  local newContent
  local modified = false

  if not content then
    -- File doesn't exist, create it with NotRoamableUiSettings
    log.i(string.format("Creating new other.xml: %s", xmlPath))

    -- Ensure the options directory exists
    local optionsDir = xmlPath:match("(.*/)")
    if optionsDir then
      local dirAttrs = hs.fs.attributes(optionsDir)
      if not dirAttrs then
        -- Create options directory if it doesn't exist
        local success = hs.execute(string.format('mkdir -p "%s"', optionsDir))
        if not success then
          log.e(string.format("Failed to create directory: %s", optionsDir))
          return false
        end
      end
    end

    newContent = string.format([[<application>
  <component name="NotRoamableUiSettings">
    <option name="fontSize" value="%s.0" />
  </component>
</application>
]], fontSize)
    modified = true
  else
    newContent = content

    -- Try to update existing fontSize
    local count
    newContent, count = string.gsub(
      newContent,
      '(<option name="fontSize" value=")%d+%.?%d*(")',
      '%1' .. fontSize .. '.0%2'
    )

    if count > 0 then
      modified = true
    else
      -- fontSize doesn't exist, check if NotRoamableUiSettings component exists
      if newContent:match('<component name="NotRoamableUiSettings">') then
        -- Component exists, add fontSize option to it
        newContent, count = string.gsub(
          newContent,
          '(<component name="NotRoamableUiSettings">)',
          '%1\n    <option name="fontSize" value="' .. fontSize .. '.0" />'
        )
        modified = count > 0
      else
        -- Component doesn't exist, add it before </application>
        newContent, count = string.gsub(
          newContent,
          '(</application>)',
          '  <component name="NotRoamableUiSettings">\n    <option name="fontSize" value="' .. fontSize .. '.0" />\n  </component>\n%1'
        )
        modified = count > 0
      end
    end
  end

  -- Write if modified or newly created
  if modified then
    local success, writeErr = safeWriteFile(xmlPath, newContent)
    if success then
      log.i(string.format("Updated UI font in: %s", xmlPath))
      return true
    else
      log.e(string.format("Failed to write %s: %s", xmlPath, writeErr))
      return false
    end
  end

  return false
end

--- Update font size in all JetBrains IDE configuration files
-- Updates UI fonts (other.xml) only
-- Editor fonts are handled by ideScript which sets the default font and
-- disables "Use color scheme font" checkbox
-- @param fontSize The font size to apply to all IDEs
local function updateJetBrainsIDEFontSize(fontSize)
  local jetbrainsPath = getJetBrainsPath()
  if not jetbrainsPath then
    log.w("Cannot update IDE fonts: JetBrains directory not accessible")
    return
  end

  log.i(string.format("Updating JetBrains IDE font sizes to %d", fontSize))

  local uiUpdateCount = 0

  -- Find all JetBrains IDE directories
  for _, pattern in ipairs(config.idePatterns) do
    local ideDirs = findIDEDirectories(jetbrainsPath, pattern)

    for _, ideDir in ipairs(ideDirs) do
      -- Update UI font in other.xml (both local and settingsSync locations)
      local locations = {"/options/other.xml", "/settingsSync/options/other.xml"}
      for _, location in ipairs(locations) do
        local otherXmlPath = ideDir .. location
        if updateOtherXmlFile(otherXmlPath, fontSize) then
          uiUpdateCount = uiUpdateCount + 1
        end
      end
    end
  end

  -- Apply font changes to running IDEs without restart
  if uiUpdateCount > 0 then
    local runningApps = hs.application.runningApplications()
    local scriptPath = os.getenv("HOME") .. "/.hammerspoon/change-jetbrains-fonts.groovy"

    for _, app in ipairs(runningApps) do
      local appName = app:name()
      local appPath = app:path()

      -- Check if this is a JetBrains IDE
      -- Filter: must be in Applications and have exact IDE name (not system services)
      if appPath and appPath:match("/Applications/") then
        for _, pattern in ipairs(config.idePatterns) do
          local ideBaseName = pattern:gsub("%*", "")
          -- Exact match for IDE name (not partial match to avoid system services)
          if appName == ideBaseName then
            log.i(string.format("Applying font changes to %s via ideScript", appName))

            -- Get the IDE's command-line launcher name
            local ideLauncher = ideBaseName:lower()

            -- Write font size to temp file for ideScript to read
            local tempFile = os.getenv("TMPDIR") .. "jetbrains-font-size.txt"
            local file = io.open(tempFile, "w")
            if file then
              file:write(tostring(fontSize))
              file:close()
            end

            -- Execute ideScript to change fonts without restart
            local cmd = string.format(
              '"%s" ideScript "%s" 2>&1',
              app:path() .. "/Contents/MacOS/" .. ideLauncher,
              scriptPath
            )

            local output, status = hs.execute(cmd)
            if not status then
              log.w(string.format("Failed to reload fonts in %s: %s", appName, output or "unknown error"))
            end

            break  -- Don't check other patterns for this app
          end
        end
      end
    end

    log.i(string.format("Updated %d UI font(s) to size %d", uiUpdateCount, fontSize))
  else
    log.i("No IDE configuration files found to update")
  end
end

--- Handle screen configuration changes
-- Called when display configuration changes or system wakes from sleep
-- Determines which displays are active and applies appropriate font size
local function screenChanged()
  local allScreens = hs.screen.allScreens()
  local currentScreenCount = #allScreens
  local currentSignature = getScreenSignature()
  local hasExternalMonitor = isExternalMonitorActive()
  local displayType = hasExternalMonitor and "external monitor connected" or "built-in only"

  log.i(string.format(
    "Screen configuration changed. Display: %s (screen count: %d, signature: %s)",
    displayType,
    currentScreenCount,
    currentSignature:sub(1, 40) .. "..."  -- Log first 40 chars of signature
  ))

  -- Update last screen state
  lastScreenCount = currentScreenCount
  lastScreenSignature = currentSignature

  if hasExternalMonitor then
    -- External monitor connected (use larger font for external or dual display)
    log.i(string.format("Using larger font size %d for external monitor", config.fontSizeWithMonitor))
    updateJetBrainsIDEFontSize(config.fontSizeWithMonitor)
  else
    -- Only built-in display
    log.i(string.format("Using smaller font size %d for built-in display", config.fontSizeWithoutMonitor))
    updateJetBrainsIDEFontSize(config.fontSizeWithoutMonitor)
  end
end

--- Polling-based screen detection (fallback for when watcher fails)
-- Checks if screen signature has changed and triggers screenChanged if needed
-- Uses UUID-based signature to detect actual configuration changes, not just count
local function pollScreens()
  local currentSignature = getScreenSignature()

  -- Check if screen configuration actually changed (not just false positive)
  if currentSignature ~= lastScreenSignature then
    local allScreens = hs.screen.allScreens()
    local currentScreenCount = #allScreens

    log.i(string.format(
      "Poll detected screen configuration change (count: %d -> %d)",
      lastScreenCount,
      currentScreenCount
    ))
    screenChanged()
  end
end

--- Restart polling timer to ensure reliability after wake
-- Addresses community-reported issue where timers can become unreliable
local function restartPollTimer()
  if pollTimer then
    pollTimer:stop()
    pollTimer = nil
  end

  -- Create fresh timer instance to avoid long-running timer reliability issues
  pollTimer = hs.timer.doEvery(config.pollIntervalSeconds, pollScreens)
  log.d("Polling timer restarted")
end

--- Handle system wake and power state changes
-- Called by caffeinate watcher when system power state changes
-- Handles multiple wake events for maximum reliability
-- @param eventType The caffeinate watcher event type
local function systemWoke(eventType)
  -- Handle multiple wake event types for reliability
  if eventType == hs.caffeinate.watcher.systemDidWake then
    log.i("System woke from sleep - checking display configuration")
    restartPollTimer()
    hs.timer.doAfter(config.wakeDelaySeconds, screenChanged)
  elseif eventType == hs.caffeinate.watcher.screensDidUnlock then
    log.i("Screens unlocked - checking display configuration")
    restartPollTimer()
    hs.timer.doAfter(config.wakeDelaySeconds, screenChanged)
  elseif eventType == hs.caffeinate.watcher.screensaverDidStop then
    log.i("Screensaver stopped - checking display configuration")
    hs.timer.doAfter(config.wakeDelaySeconds, screenChanged)
  elseif eventType == hs.caffeinate.watcher.sessionDidBecomeActive then
    log.i("Session became active - checking display configuration")
    hs.timer.doAfter(config.wakeDelaySeconds, screenChanged)
  end
end

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

-- Stop existing watchers and timers if present (prevents memory leak on reload)
if screenWatcher then
  screenWatcher:stop()
  screenWatcher = nil
end

if caffeineWatcher then
  caffeineWatcher:stop()
  caffeineWatcher = nil
end

if pollTimer then
  pollTimer:stop()
  pollTimer = nil
end

-- Set up screen watcher (primary detection method)
screenWatcher = hs.screen.watcher.new(screenChanged)
screenWatcher:start()

-- Set up caffeine watcher for wake events
caffeineWatcher = hs.caffeinate.watcher.new(systemWoke)
caffeineWatcher:start()

-- Set up polling timer as fallback (detects changes that watcher might miss)
-- This is especially important for monitor unplug events which can be missed
pollTimer = hs.timer.doEvery(config.pollIntervalSeconds, pollScreens)

-- Initialize screen state tracking
local allScreens = hs.screen.allScreens()
lastScreenCount = #allScreens
lastScreenSignature = getScreenSignature()
local hasExternalMonitor = isExternalMonitorActive()
local displayType = hasExternalMonitor and "external monitor connected" or "built-in only"
log.i(string.format(
  "Display font adjuster loaded. Display: %s (screen count: %d, signature: %s)",
  displayType,
  lastScreenCount,
  lastScreenSignature:sub(1, 40) .. "..."
))

-- Perform initial font size adjustment based on current display configuration
-- This ensures fonts are correct when Hammerspoon starts up
screenChanged()

-------------------------------------------------------------------------------
-- Configuration UI
-------------------------------------------------------------------------------

local configWindow = nil

--- Show configuration UI (global for IPC debugging)
function showConfigUI()
  -- Clean up existing window if present
  if configWindow then
    pcall(function() configWindow:delete() end)
    configWindow = nil
  end

  log.i("Creating configuration UI window")

  -- Default IDE patterns available
  local defaultPatterns = {
    "GoLand*",
    "WebStorm*",
    "RustRover*",
    "IntelliJIdea*",
    "PyCharm*",
    "CLion*",
    "DataGrip*",
    "PhpStorm*",
    "Rider*",
    "AppCode*",
  }

  -- Build table header for default patterns
  local defaultHeadersHtml = ""
  for _, pattern in ipairs(defaultPatterns) do
    local escapedPattern = pattern:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
    defaultHeadersHtml = defaultHeadersHtml .. string.format('<th>%s</th>', escapedPattern)
  end

  -- Build checkboxes row for default patterns
  local defaultCheckboxesHtml = ""
  for _, pattern in ipairs(defaultPatterns) do
    local isChecked = false
    for _, selectedPattern in ipairs(config.idePatterns) do
      if selectedPattern == pattern then
        isChecked = true
        break
      end
    end
    local checkedAttr = isChecked and ' checked="checked"' or ''
    local escapedPattern = pattern:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
    defaultCheckboxesHtml = defaultCheckboxesHtml .. string.format(
      '<td><input type="checkbox" class="default-ide" value="%s"%s></td>',
      escapedPattern, checkedAttr
    )
  end

  -- Build custom patterns as table cells (similar to default patterns)
  local customPatternRows = {}
  local customCount = 0
  for _, pattern in ipairs(config.idePatterns) do
    local isDefault = false
    for _, defaultPattern in ipairs(defaultPatterns) do
      if pattern == defaultPattern then
        isDefault = true
        break
      end
    end
    if not isDefault then
      local escapedPattern = pattern:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
      local escapedForJs = escapedPattern:gsub("'", "\\'")
      table.insert(customPatternRows, {pattern = escapedPattern, escapedForJs = escapedForJs})
      customCount = customCount + 1
    end
  end

  -- Build custom pattern rows with cells (max defaultPatterns columns per row)
  local customPatternsHtml = ""
  local numCols = #defaultPatterns
  local i = 1
  while i <= #customPatternRows do
    customPatternsHtml = customPatternsHtml .. '<tr><td class="pattern-type">Custom</td>'

    for col = 1, numCols do
      if i <= #customPatternRows then
        local item = customPatternRows[i]
        customPatternsHtml = customPatternsHtml .. string.format(
          '<td class="custom-pattern-cell"><div class="custom-pattern-wrapper" data-pattern="%s">%s<button class="delete-btn" onclick="removeCustomIDE(\'%s\')">×</button></div></td>',
          item.pattern, item.pattern, item.escapedForJs
        )
        i = i + 1
      else
        customPatternsHtml = customPatternsHtml .. '<td></td>'
      end
    end

    customPatternsHtml = customPatternsHtml .. '</tr>'
  end

  local html = string.format([[
<!DOCTYPE html>
<html>
<head>
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      padding: 0;
      margin: 0;
      background: #c8c8c8;
      font-size: 16px;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .container {
      max-width: 1200px;
      width: calc(100%% - 80px);
      background: white;
      padding: 35px 40px 30px 40px;
      border-radius: 10px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.2);
      border: 1px solid #bbb;
      margin: 40px;
    }
    .settings-row {
      display: flex;
      gap: 30px;
      flex-wrap: wrap;
    }
    .settings-row .config-item {
      flex: 1;
      min-width: 200px;
    }
    h2 {
      margin-top: 0;
      margin-bottom: 25px;
      color: #333;
      font-size: 28px;
      border-bottom: 3px solid #007AFF;
      padding-bottom: 15px;
    }
    h3 {
      margin-top: 28px;
      margin-bottom: 16px;
      color: #555;
      font-size: 20px;
      font-weight: 600;
    }
    .config-item {
      margin: 16px 0;
    }
    label {
      display: block;
      margin-bottom: 8px;
      color: #666;
      font-size: 15px;
      font-weight: 500;
    }
    input[type="number"], input[type="text"] {
      width: 100%%;
      padding: 12px 14px;
      border: 1px solid #ddd;
      border-radius: 6px;
      font-size: 15px;
    }
    input:focus {
      outline: none;
      border-color: #007AFF;
      box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.1);
    }
    .ide-patterns-table {
      width: 100%%;
      border-collapse: collapse;
      margin: 15px 0;
      background: white;
      border: 1px solid #ddd;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 4px rgba(0,0,0,0.08);
    }
    .ide-patterns-table th {
      background: #007AFF;
      color: white;
      padding: 12px 10px;
      font-size: 14px;
      font-weight: 600;
      text-align: center;
      border-right: 1px solid rgba(255,255,255,0.2);
      white-space: nowrap;
    }
    .ide-patterns-table th:first-child {
      background: #0051D5;
      min-width: 80px;
      font-size: 15px;
    }
    .ide-patterns-table th:last-child {
      border-right: none;
    }
    .ide-patterns-table td {
      padding: 12px 10px;
      text-align: center;
      vertical-align: middle;
      border-right: 1px solid #eee;
      border-top: 1px solid #eee;
      background: white;
    }
    .ide-patterns-table td:last-child {
      border-right: none;
    }
    .ide-patterns-table td.pattern-type {
      background: #f8f9fa;
      font-weight: 600;
      color: #555;
      font-size: 15px;
    }
    .ide-patterns-table td.custom-pattern-cell {
      text-align: center;
      padding: 10px 8px;
      position: relative;
    }
    .custom-pattern-wrapper {
      position: relative;
      display: inline-block;
      padding: 4px 8px;
      font-size: 15px;
      color: #333;
      font-weight: 500;
    }
    .custom-pattern-wrapper .delete-btn {
      display: none;
      position: absolute;
      top: 50%%;
      right: -25px;
      transform: translateY(-50%%);
      width: 24px;
      height: 24px;
      padding: 0;
      background: #FF3B30;
      color: white;
      border: none;
      border-radius: 50%%;
      font-size: 18px;
      line-height: 1;
      cursor: pointer;
      font-weight: bold;
    }
    .custom-pattern-wrapper:hover .delete-btn {
      display: block;
    }
    .custom-pattern-wrapper .delete-btn:hover {
      background: #E02020;
    }
    .ide-patterns-table input[type="checkbox"] {
      width: 20px;
      height: 20px;
      cursor: pointer;
      margin: 0;
    }
    .add-custom-ide {
      display: flex;
      gap: 10px;
      margin-top: 15px;
    }
    .add-custom-ide input {
      flex: 1;
    }
    button {
      padding: 12px 20px;
      background: #007AFF;
      color: white;
      border: none;
      border-radius: 6px;
      cursor: pointer;
      font-size: 16px;
      font-weight: 500;
    }
    button:hover {
      cursor: pointer;
    }
    button:hover {
      background: #0051D5;
    }
    button:active {
      background: #004FC4;
    }
    .ide-item button {
      padding: 8px 16px;
      background: #FF3B30;
      font-size: 14px;
    }
    .ide-item button:hover {
      background: #E02020;
    }
    .add-ide-btn {
      background: #34C759;
      width: 100%%;
      margin-top: 12px;
    }
    .add-ide-btn:hover {
      background: #2FB54A;
    }
    .buttons {
      display: flex;
      gap: 20px;
      margin-top: 30px;
      padding-top: 25px;
      border-top: 1px solid #eee;
    }
    .buttons button {
      flex: 1;
      padding: 16px 28px;
      font-size: 17px;
      font-weight: 600;
    }
    .cancel-btn {
      background: #8E8E93;
    }
    .cancel-btn:hover {
      background: #757579;
    }
    .description {
      color: #999;
      font-size: 14px;
      margin-top: 6px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h2>Display Font Adjuster Configuration</h2>

    <h3>Font Sizes</h3>
    <div class="settings-row">
      <div class="config-item">
        <label>Font Size with External Monitor</label>
        <input type="number" id="fontSizeWithMonitor" min="8" max="30" value="%d">
        <div class="description">Larger font for external or dual display mode</div>
      </div>
      <div class="config-item">
        <label>Font Size without External Monitor</label>
        <input type="number" id="fontSizeWithoutMonitor" min="8" max="30" value="%d">
        <div class="description">Smaller font for built-in display only</div>
      </div>
    </div>

    <h3>JetBrains IDE Patterns</h3>
    <table class="ide-patterns-table">
      <thead>
        <tr>
          <th>Type</th>
          %s
        </tr>
      </thead>
      <tbody id="idePatternsBody">
        <tr>
          <td class="pattern-type">Default</td>
          %s
        </tr>
        %s
      </tbody>
    </table>
    <div class="add-custom-ide">
      <input type="text" id="newIdePattern" placeholder="e.g. AndroidStudio*">
      <button onclick="addCustomIDE()">Add Custom Pattern</button>
    </div>

    <h3>Advanced Settings</h3>
    <div class="settings-row">
      <div class="config-item">
        <label>Wake Delay (seconds)</label>
        <input type="number" id="wakeDelaySeconds" min="0.1" max="10" step="0.1" value="%.1f">
        <div class="description">Delay before checking display after system wakes</div>
      </div>
      <div class="config-item">
        <label>Poll Interval (seconds)</label>
        <input type="number" id="pollIntervalSeconds" min="1" max="60" step="1" value="%.1f">
        <div class="description">How often to check for display changes (fallback)</div>
      </div>
    </div>

    <div class="buttons">
      <button class="cancel-btn" onclick="cancel()">Cancel</button>
      <button onclick="saveConfig()">Save Configuration</button>
    </div>
  </div>

  <script>
    // Communication bridge with Hammerspoon
    function removeCustomIDE(pattern) {
      const tbody = document.getElementById('idePatternsBody');
      const wrappers = tbody.querySelectorAll('.custom-pattern-wrapper');

      wrappers.forEach(wrapper => {
        if (wrapper.getAttribute('data-pattern') === pattern) {
          const cell = wrapper.parentElement;
          cell.innerHTML = ''; // Clear the cell

          // Check if the entire row is now empty (except Type column)
          const row = cell.parentElement;
          const cells = row.querySelectorAll('td');
          let isEmpty = true;
          for (let i = 1; i < cells.length; i++) { // Skip first cell (Type)
            if (cells[i].textContent.trim()) {
              isEmpty = false;
              break;
            }
          }

          // Remove the row if completely empty
          if (isEmpty) {
            row.remove();
          }
        }
      });
    }

    function addCustomIDE() {
      const input = document.getElementById('newIdePattern');
      const pattern = input.value.trim();

      if (!pattern) {
        alert('Please enter a pattern');
        return;
      }

      // Check if already exists in default patterns
      const defaultCheckboxes = document.querySelectorAll('.default-ide');
      for (let checkbox of defaultCheckboxes) {
        if (checkbox.value === pattern) {
          alert('This pattern already exists in default patterns');
          return;
        }
      }

      // Check if already exists in custom patterns
      const customWrappers = document.querySelectorAll('.custom-pattern-wrapper');
      for (let wrapper of customWrappers) {
        if (wrapper.getAttribute('data-pattern') === pattern) {
          alert('Pattern already exists');
          return;
        }
      }

      const tbody = document.getElementById('idePatternsBody');
      const numCols = 10; // Number of default pattern columns

      // Find the last Custom row or create a new one
      let lastCustomRow = null;
      const rows = tbody.querySelectorAll('tr');
      for (let i = rows.length - 1; i >= 0; i--) {
        const typeCell = rows[i].querySelector('.pattern-type');
        if (typeCell && typeCell.textContent === 'Custom') {
          lastCustomRow = rows[i];
          break;
        }
      }

      // Check if we need a new row or can add to existing
      let targetCell = null;

      if (lastCustomRow) {
        // Check if there's an empty cell in the last custom row
        const cells = lastCustomRow.querySelectorAll('td');
        for (let i = 1; i < cells.length; i++) { // Skip first cell (Type)
          if (!cells[i].textContent.trim()) {
            targetCell = cells[i];
            break;
          }
        }
      }

      // If no empty cell found, create a new row
      if (!targetCell) {
        const tr = document.createElement('tr');

        const tdType = document.createElement('td');
        tdType.className = 'pattern-type';
        tdType.textContent = 'Custom';
        tr.appendChild(tdType);

        // Create cells for each column
        for (let i = 0; i < numCols; i++) {
          const td = document.createElement('td');
          if (i === 0) {
            td.className = 'custom-pattern-cell';
            targetCell = td;
          } else {
            td.className = 'custom-pattern-cell';
          }
          tr.appendChild(td);
        }

        tbody.appendChild(tr);
      }

      // Add the pattern to the target cell
      const wrapper = document.createElement('div');
      wrapper.className = 'custom-pattern-wrapper';
      wrapper.setAttribute('data-pattern', pattern);
      wrapper.textContent = pattern;

      const deleteBtn = document.createElement('button');
      deleteBtn.className = 'delete-btn';
      deleteBtn.textContent = '×';
      deleteBtn.onclick = function() { removeCustomIDE(pattern); };

      wrapper.appendChild(deleteBtn);
      targetCell.appendChild(wrapper);

      input.value = '';
    }

    function saveConfig() {
      const idePatterns = [];

      // Get checked default patterns
      document.querySelectorAll('.default-ide:checked').forEach(checkbox => {
        idePatterns.push(checkbox.value);
      });

      // Get custom patterns from wrappers
      const customWrappers = document.querySelectorAll('.custom-pattern-wrapper');
      customWrappers.forEach(wrapper => {
        const pattern = wrapper.getAttribute('data-pattern');
        if (pattern) {
          idePatterns.push(pattern);
        }
      });

      const config = {
        fontSizeWithMonitor: parseInt(document.getElementById('fontSizeWithMonitor').value),
        fontSizeWithoutMonitor: parseInt(document.getElementById('fontSizeWithoutMonitor').value),
        idePatterns: idePatterns,
        wakeDelaySeconds: parseFloat(document.getElementById('wakeDelaySeconds').value),
        pollIntervalSeconds: parseFloat(document.getElementById('pollIntervalSeconds').value)
      };

      window.__pendingAction = {
        type: 'save',
        data: config
      };
    }

    function cancel() {
      window.__pendingAction = {
        type: 'close'
      };
    }
  </script>
</body>
</html>
  ]],
    config.fontSizeWithMonitor,
    config.fontSizeWithoutMonitor,
    defaultHeadersHtml,
    defaultCheckboxesHtml,
    customPatternsHtml,
    config.wakeDelaySeconds,
    config.pollIntervalSeconds
  )

  -- Calculate window size based on screen (centered)
  local screen = hs.screen.mainScreen()
  local screenFrame = screen:frame()
  local windowWidth = 1350  -- Fit all IDE patterns comfortably
  local windowHeight = 920  -- Fixed height to show all content without scroll
  -- Center on screen (account for screen origin)
  local windowX = screenFrame.x + math.floor((screenFrame.w - windowWidth) / 2)
  local windowY = screenFrame.y + math.floor((screenFrame.h - windowHeight) / 2)

  configWindow = hs.webview.new({x=windowX, y=windowY, w=windowWidth, h=windowHeight})
    :windowStyle({"titled", "closable", "resizable", "miniaturizable"})
    :allowTextEntry(true)
    :allowGestures(true)
    :windowTitle("Hammerspoon Configuration")
    :html(html)
    :level(hs.drawing.windowLevels.floating)  -- Float above other windows

  -- Expose Lua functions to JavaScript via evaluateJavaScript polling
  -- We'll use a simple approach: inject a bridge object that JavaScript can call
  local checkTimer
  checkTimer = hs.timer.doEvery(0.1, function()
    if not configWindow then
      if checkTimer then
        checkTimer:stop()
        checkTimer = nil
      end
      return
    end

    configWindow:evaluateJavaScript([[
      (function() {
        if (window.__pendingAction) {
          var action = window.__pendingAction;
          window.__pendingAction = null;
          return JSON.stringify(action);
        }
        return null;
      })();
    ]], function(result)
      -- Ignore error parameter - Hammerspoon returns empty table even on success
      if not result or result == "null" or result == "" then
        return
      end

      local success, action = pcall(hs.json.decode, result)
      if not success then
        log.e(string.format("Failed to parse action: %s", action))
        return
      end

      if action.type == "save" then
        log.i("Save button clicked")
        local newConfig = action.data

        log.i(string.format("New config: fontWithMonitor=%d, fontWithout=%d",
          newConfig.fontSizeWithMonitor, newConfig.fontSizeWithoutMonitor))

        -- Update config with new values
        config.fontSizeWithMonitor = newConfig.fontSizeWithMonitor
        config.fontSizeWithoutMonitor = newConfig.fontSizeWithoutMonitor
        config.idePatterns = newConfig.idePatterns
        config.wakeDelaySeconds = newConfig.wakeDelaySeconds
        config.pollIntervalSeconds = newConfig.pollIntervalSeconds

        -- Save to persistent storage
        saveConfig(config)

        -- Restart poll timer with new interval
        restartPollTimer()

        -- Apply new font settings immediately
        screenChanged()

        -- Close window without notification
        if checkTimer then
          checkTimer:stop()
          checkTimer = nil
        end
        configWindow:delete()
        configWindow = nil
      elseif action.type == "close" then
        log.i("Closing configuration UI")
        if checkTimer then
          checkTimer:stop()
          checkTimer = nil
        end
        configWindow:delete()
        configWindow = nil
      elseif action.type == "updateIDEs" then
        log.i("Updating IDE patterns")
        config.idePatterns = action.data
        if checkTimer then
          checkTimer:stop()
          checkTimer = nil
        end
        showConfigUI()
      end
    end)
  end)

  configWindow:show()
  configWindow:bringToFront(true)  -- Force to front even over fullscreen apps
end

-- Register hotkey to open configuration UI using eventtap for better Firefox compatibility
-- This captures the keyboard event at system level before apps can intercept it

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

    -- Check for Cmd+Alt+Ctrl+H (keyCode 4 is 'H')
    -- Must have exactly cmd, alt, and ctrl (no shift or fn)
    if keyCode == 4 and
       flags.cmd and
       flags.alt and
       flags.ctrl and
       not flags.shift and
       not flags.fn then
      log.i("Hotkey detected: Cmd+Alt+Ctrl+H")
      -- Open UI immediately instead of delayed
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

log.i("Configuration UI ready. Press Cmd+Alt+Ctrl+H to open settings.")
log.i("Note: If hotkey doesn't work, ensure Hammerspoon has Accessibility permissions in System Preferences.")
