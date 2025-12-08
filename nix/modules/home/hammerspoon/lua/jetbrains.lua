-- JetBrains IDE font management for Hammerspoon
-- Handles finding IDE directories and updating font configurations
--
-- @module jetbrains
-- @version 1.0

local M = {}

-------------------------------------------------------------------------------
-- File I/O Utilities
-------------------------------------------------------------------------------

--- Safely read a file with proper error handling and resource cleanup
-- @param filepath The path to the file to read
-- @param log Logger instance (optional)
-- @return content, error Content string on success, nil on failure
function M.safeReadFile(filepath, log)
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

  if not closeSuccess and log then
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
-- @param log Logger instance (optional)
-- @return success, error true on success, false on failure
function M.safeWriteFile(filepath, content, log)
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

  if not closeSuccess and log then
    log.w(string.format("Failed to close file %s: %s", filepath, closeErr))
  end

  if not success then
    return false, string.format("Failed to write file: %s", writeErr)
  end

  return true, nil
end

-------------------------------------------------------------------------------
-- JetBrains Directory Functions
-------------------------------------------------------------------------------

--- Get JetBrains base path with validation
-- @param basePath The relative path from HOME to JetBrains directory
-- @param log Logger instance (optional)
-- @return path The full path to JetBrains directory, or nil if not found
function M.getJetBrainsPath(basePath, log)
  local home = os.getenv("HOME")
  if not home or home == "" then
    if log then
      log.w("HOME environment variable not set")
    end

    return nil
  end

  local path = home .. basePath

  -- Check if directory exists using hs.fs
  local attrs = hs.fs.attributes(path)
  if not attrs or attrs.mode ~= "directory" then
    if log then
      log.w(string.format("JetBrains directory not found: %s", path))
    end

    return nil
  end

  return path
end

--- Find IDE directories using hs.fs (more efficient than shell find)
-- @param basePath The base directory to search in
-- @param pattern Shell glob pattern (e.g., "GoLand*")
-- @param log Logger instance (optional)
-- @return results Array of matching directory paths
function M.findIDEDirectories(basePath, pattern, log)
  local results = {}

  -- Convert shell glob pattern to Lua pattern
  local luaPattern = "^" .. pattern:gsub("%*", ".*") .. "$"

  local iter, dirObj = hs.fs.dir(basePath)
  if not iter then
    if log then
      log.w(string.format("Cannot iterate directory: %s", basePath))
    end

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
-- Font Update Functions
-------------------------------------------------------------------------------

--- Update font size in a single other.xml file (creates if doesn't exist)
-- @param xmlPath The full path to the other.xml file
-- @param fontSize The font size to set (must be positive integer)
-- @param log Logger instance (optional)
-- @return boolean true if file was modified and saved, false otherwise
function M.updateOtherXmlFile(xmlPath, fontSize, log)
  -- Validate fontSize
  if type(fontSize) ~= "number" or fontSize <= 0 then
    if log then
      log.e(string.format("Invalid fontSize: %s", tostring(fontSize)))
    end

    return false
  end

  local content, _ = M.safeReadFile(xmlPath, log)
  local newContent
  local modified = false

  if not content then
    -- File doesn't exist, create it with NotRoamableUiSettings
    if log then
      log.i(string.format("Creating new other.xml: %s", xmlPath))
    end

    -- Ensure the options directory exists
    local optionsDir = xmlPath:match("(.*/)")
    if optionsDir then
      local dirAttrs = hs.fs.attributes(optionsDir)
      if not dirAttrs then
        -- Create options directory if it doesn't exist
        local success = hs.execute(string.format('mkdir -p "%s"', optionsDir))
        if not success then
          if log then
            log.e(string.format("Failed to create directory: %s", optionsDir))
          end

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
    local success, writeErr = M.safeWriteFile(xmlPath, newContent, log)
    if success then
      if log then
        log.i(string.format("Updated UI font in: %s", xmlPath))
      end

      return true
    else
      if log then
        log.e(string.format("Failed to write %s: %s", xmlPath, writeErr))
      end

      return false
    end
  end

  return false
end

--- Update font size in all JetBrains IDE configuration files
-- Updates UI fonts (other.xml) only
-- Editor fonts are handled by ideScript
-- @param fontSize The font size to apply to all IDEs
-- @param config Configuration table with jetbrainsBasePath and idePatterns
-- @param log Logger instance (optional)
function M.updateFontSize(fontSize, config, log)
  local jetbrainsPath = M.getJetBrainsPath(config.jetbrainsBasePath, log)
  if not jetbrainsPath then
    if log then
      log.w("Cannot update IDE fonts: JetBrains directory not accessible")
    end

    return
  end

  if log then
    log.i(string.format("Updating JetBrains IDE font sizes to %d", fontSize))
  end

  local uiUpdateCount = 0

  -- Find all JetBrains IDE directories
  for _, pattern in ipairs(config.idePatterns) do
    local ideDirs = M.findIDEDirectories(jetbrainsPath, pattern, log)

    for _, ideDir in ipairs(ideDirs) do
      -- Update UI font in other.xml (both local and settingsSync locations)
      local locations = {"/options/other.xml", "/settingsSync/options/other.xml"}
      for _, location in ipairs(locations) do
        local otherXmlPath = ideDir .. location
        if M.updateOtherXmlFile(otherXmlPath, fontSize, log) then
          uiUpdateCount = uiUpdateCount + 1
        end
      end
    end
  end

  -- Apply font changes to running IDEs without restart (async to avoid blocking)
  if uiUpdateCount > 0 then
    local runningApps = hs.application.runningApplications()
    local scriptPath = os.getenv("HOME") .. "/.hammerspoon/change-jetbrains-fonts.groovy"
    local home = os.getenv("HOME")

    for _, app in ipairs(runningApps) do
      local appName = app:name()

      -- Safely get app path - some system processes don't have valid bundles
      local success, appPath = pcall(function() return app:path() end)
      if not success then
        appPath = nil
      end

      -- Check if this is a JetBrains IDE
      -- Filter: must be in Applications (system or user) and have exact IDE name
      if appPath and (appPath:match("/Applications/") or appPath:match(home .. "/Applications/")) then
        for _, pattern in ipairs(config.idePatterns) do
          local ideBaseName = pattern:gsub("%*", "")
          -- Exact match for IDE name (not partial match to avoid system services)
          if appName == ideBaseName then
            if log then
              log.i(string.format("Applying font changes to %s via ideScript", appName))
            end

            -- Get the IDE's command-line launcher name
            local ideLauncher = ideBaseName:lower()

            -- Write font size to temp file for ideScript to read
            local tempFile = os.getenv("TMPDIR") .. "jetbrains-font-size.txt"
            local file = io.open(tempFile, "w")
            if file then
              file:write(tostring(fontSize))
              file:close()
            end

            -- Execute ideScript asynchronously (doesn't need focus, runs in background)
            local executable = app:path() .. "/Contents/MacOS/" .. ideLauncher
            local task = hs.task.new(executable, function(exitCode, _, stdErr)
              if exitCode ~= 0 then
                if log then
                  log.w(string.format("Failed to reload fonts in %s: %s", appName, stdErr or "unknown error"))
                end
              else
                if log then
                  log.d(string.format("Font reload completed for %s", appName))
                end
              end
            end, {"ideScript", scriptPath})
            task:start()

            break  -- Don't check other patterns for this app
          end
        end
      end
    end

    if log then
      log.i(string.format("Updated %d UI font(s) to size %d", uiUpdateCount, fontSize))
    end
  else
    if log then
      log.i("No IDE configuration files found to update")
    end
  end
end

return M
