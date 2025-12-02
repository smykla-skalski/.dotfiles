-- Hammerspoon Config: Auto-adjust IDE font sizes based on external display
-- Monitors display connection/disconnection events
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
    "DataGrip*"
  },

  -- Paths
  jetbrainsBasePath = "/Library/Application Support/JetBrains",
}

-- Module state
local screenWatcher = nil

-------------------------------------------------------------------------------
-- Utility Functions
-------------------------------------------------------------------------------

-- Safely read a file with proper error handling and resource cleanup
local function safeReadFile(filepath)
  local file, err = io.open(filepath, "r")
  if not file then
    return nil, string.format("Failed to open file: %s", err)
  end

  local success, content = pcall(function()
    return file:read("*all")
  end)

  file:close()

  if not success then
    return nil, string.format("Failed to read file: %s", content)
  end

  return content, nil
end

-- Safely write a file with proper error handling and resource cleanup
local function safeWriteFile(filepath, content)
  local file, err = io.open(filepath, "w")
  if not file then
    return false, string.format("Failed to open file for writing: %s", err)
  end

  local success, writeErr = pcall(function()
    file:write(content)
  end)

  file:close()

  if not success then
    return false, string.format("Failed to write file: %s", writeErr)
  end

  return true, nil
end

-- Get JetBrains base path with validation
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

-- Find IDE directories using hs.fs (more efficient than shell find)
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

-- Get all connected screens count
local function getScreenCount()
  return #hs.screen.allScreens()
end

-- Update font size in a single editor.xml file
local function updateEditorXmlFile(xmlPath, fontSize)
  -- Read file
  local content, readErr = safeReadFile(xmlPath)
  if not content then
    log.w(string.format("Cannot read %s: %s", xmlPath, readErr))
    return false
  end

  -- Update FONT_SIZE values
  local modified = false
  local newContent = content

  -- Update FONT_SIZE (declare count as local to avoid global pollution)
  local count
  newContent, count = string.gsub(
    newContent,
    '(<option name="FONT_SIZE" value=")%d+(")',
    '%1' .. fontSize .. '%2'
  )
  if count > 0 then
    modified = true
  end

  -- Update FONT_SIZE_2D
  newContent, count = string.gsub(
    newContent,
    '(<option name="FONT_SIZE_2D" value=")%d+%.?%d*(")',
    '%1' .. fontSize .. '.0%2'
  )
  if count > 0 then
    modified = true
  end

  -- Write back if modified
  if modified then
    local success, writeErr = safeWriteFile(xmlPath, newContent)
    if success then
      log.i(string.format("Updated: %s", xmlPath))
      return true
    else
      log.e(string.format("Failed to write %s: %s", xmlPath, writeErr))
      return false
    end
  end

  return false
end

-- Update font size in JetBrains IDE editor.xml files
local function updateJetBrainsIDEFontSize(fontSize)
  local jetbrainsPath = getJetBrainsPath()
  if not jetbrainsPath then
    log.w("Cannot update IDE fonts: JetBrains directory not accessible")
    return
  end

  log.i(string.format("Updating JetBrains IDE font sizes to %d", fontSize))

  local updateCount = 0

  -- Find all JetBrains IDE directories
  for _, pattern in ipairs(config.idePatterns) do
    local ideDirs = findIDEDirectories(jetbrainsPath, pattern)

    for _, ideDir in ipairs(ideDirs) do
      local editorXmlPath = ideDir .. "/options/editor.xml"

      -- Check if editor.xml exists
      local attrs = hs.fs.attributes(editorXmlPath)
      if attrs and attrs.mode == "file" then
        if updateEditorXmlFile(editorXmlPath, fontSize) then
          updateCount = updateCount + 1
        end
      end
    end
  end

  -- Show notification only if files were updated
  if updateCount > 0 then
    hs.notify.new({
      title = "IDE Font Size Updated",
      informativeText = string.format("Updated %d file(s) to font size %d", updateCount, fontSize)
    }):send()
  else
    log.i("No IDE configuration files found to update")
  end
end

-- Handle screen configuration changes
local function screenChanged()
  local screenCount = getScreenCount()
  log.i(string.format("Screen configuration changed. Total screens: %d", screenCount))

  if screenCount > 1 then
    -- External monitor connected
    log.i(string.format("External monitor detected - setting font size to %d", config.fontSizeWithMonitor))
    updateJetBrainsIDEFontSize(config.fontSizeWithMonitor)
  else
    -- Only built-in display
    log.i(string.format("Single display detected - setting font size to %d", config.fontSizeWithoutMonitor))
    updateJetBrainsIDEFontSize(config.fontSizeWithoutMonitor)
  end
end

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

-- Stop existing watcher if present (prevents memory leak on reload)
if screenWatcher then
  screenWatcher:stop()
  screenWatcher = nil
end

-- Set up screen watcher
screenWatcher = hs.screen.watcher.new(screenChanged)
screenWatcher:start()

log.i(string.format("Display font adjuster loaded. Monitoring %d screen(s)", getScreenCount()))

-- Show initial notification
hs.notify.new({
  title = "Hammerspoon Loaded",
  informativeText = "Display font adjuster is active"
}):send()

-- Optional: Set initial font size based on current configuration
-- Uncomment the next line if you want to adjust fonts on Hammerspoon load
-- screenChanged()
