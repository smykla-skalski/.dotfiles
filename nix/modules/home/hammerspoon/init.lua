-- Hammerspoon Config: Auto-adjust IDE font sizes based on active display
-- Detects whether built-in display or external monitor is active
-- Monitors display changes and system wake events
-- Lua 5.3 compatible with best practices applied

local log = hs.logger.new('display-font-adjuster', 'info')

-- Configuration
local config = {
  -- Font sizes
  fontSizeWithMonitor = 15,
  fontSizeWithoutMonitor = 12,

  -- JetBrains IDE patterns (ProductName + Version)
  idePatterns = {
    "GoLand*",
    "WebStorm*",
    "RustRover*",
    "IntelliJIdea*",
    "PyCharm*",
    "CLion*",
    "DataGrip*",
  },

  -- Paths
  jetbrainsBasePath = "/Library/Application Support/JetBrains",

  -- Timing
  wakeDelaySeconds = 1.0,
}

-- Module state
local screenWatcher = nil
local caffeineWatcher = nil

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
  local hasExternalMonitor = isExternalMonitorActive()
  local displayType = hasExternalMonitor and "external monitor connected" or "built-in only"

  log.i(string.format("Screen configuration changed. Display: %s", displayType))

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

--- Handle system wake from sleep
-- Called by caffeinate watcher when system power state changes
-- @param eventType The caffeinate watcher event type
local function systemWoke(eventType)
  if eventType == hs.caffeinate.watcher.systemDidWake then
    log.i("System woke from sleep - checking display configuration")
    -- Small delay to allow display detection to stabilize
    hs.timer.doAfter(config.wakeDelaySeconds, screenChanged)
  end
end

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

-- Stop existing watchers if present (prevents memory leak on reload)
if screenWatcher then
  screenWatcher:stop()
  screenWatcher = nil
end

if caffeineWatcher then
  caffeineWatcher:stop()
  caffeineWatcher = nil
end

-- Set up screen watcher
screenWatcher = hs.screen.watcher.new(screenChanged)
screenWatcher:start()

-- Set up caffeine watcher for wake events
caffeineWatcher = hs.caffeinate.watcher.new(systemWoke)
caffeineWatcher:start()

local hasExternalMonitor = isExternalMonitorActive()
local displayType = hasExternalMonitor and "external monitor connected" or "built-in only"
log.i(string.format("Display font adjuster loaded. Display: %s", displayType))

-- Perform initial font size adjustment based on current display configuration
-- This ensures fonts are correct when Hammerspoon starts up
screenChanged()
