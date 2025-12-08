-- Display detection for Hammerspoon
-- Handles built-in vs external monitor detection
--
-- @module display
-- @version 1.0

local M = {}

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

--- Built-in display name patterns for detection
M.BUILTIN_DISPLAY_PATTERNS = {
  "^Built%-in",  -- "Built-in Retina Display"
  "^Color LCD",  -- Older MacBooks
}

-------------------------------------------------------------------------------
-- Display Detection Functions
-------------------------------------------------------------------------------

--- Get a unique signature for current screen configuration
-- Creates a deterministic string based on screen UUIDs
-- @return string Comma-separated sorted list of screen UUIDs
function M.getScreenSignature()
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

--- Check if a single screen is a built-in display
-- @param screen hs.screen object to check
-- @param log Logger instance (optional)
-- @return boolean true if the screen is built-in, false otherwise
function M.isBuiltinScreen(screen, log)
  if not screen then
    if log then
      log.w("isBuiltinScreen called with nil screen")
    end

    return false
  end

  local screenName = screen:name()

  -- First try getInfo() if available (most reliable method)
  local screenInfo = screen:getInfo()
  if screenInfo and screenInfo.builtin ~= nil then
    if log then
      log.d(string.format("Screen '%s' builtin status from getInfo(): %s", screenName, tostring(screenInfo.builtin)))
    end

    return screenInfo.builtin
  end

  -- Fallback: check screen name against known built-in patterns
  for _, pattern in ipairs(M.BUILTIN_DISPLAY_PATTERNS) do
    if screenName:match(pattern) then
      if log then
        log.d(string.format("Screen '%s' matched built-in pattern: %s", screenName, pattern))
      end

      return true
    end
  end

  if log then
    log.d(string.format("Screen '%s' identified as external", screenName))
  end

  return false
end

--- Detect if an external monitor is connected
-- Checks all screens to see if any external monitor is present
-- @param log Logger instance (optional)
-- @return boolean true if any external monitor is connected
function M.isExternalMonitorActive(log)
  local allScreens = hs.screen.allScreens()

  if not allScreens or #allScreens == 0 then
    if log then
      log.w("No screens found")
    end

    return false
  end

  local externalCount = 0
  local builtinCount = 0

  -- Count built-in and external monitors
  for _, screen in ipairs(allScreens) do
    local screenName = screen:name()
    local isBuiltIn = M.isBuiltinScreen(screen)

    if isBuiltIn then
      builtinCount = builtinCount + 1

      if log then
        log.d(string.format("Built-in display detected: %s", screenName))
      end
    else
      externalCount = externalCount + 1

      if log then
        log.d(string.format("External monitor detected: %s", screenName))
      end
    end
  end

  -- External monitor detected (with or without built-in)
  if externalCount > 0 then
    if log then
      log.d(string.format("External monitor(s) active: %d external, %d built-in", externalCount, builtinCount))
    end

    return true
  end

  -- Only built-in display
  if log then
    log.d("Only built-in display detected")
  end

  return false
end

return M
