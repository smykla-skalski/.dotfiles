-- Ghostty terminal font management for Hammerspoon
-- Handles per-window font sizing and config overlay updates
--
-- @module ghostty
-- @version 1.0

local M = {}

-- Module state
M.windowStates = {}  -- Map of windowId -> {fontSize, screenName, isBuiltin, lastUpdate}

-------------------------------------------------------------------------------
-- Accessibility Tree Utilities
-------------------------------------------------------------------------------

--- Count elements with a specific role in the accessibility tree
-- @param element AXUIElement to search
-- @param targetRole Role to count (e.g., "AXTextArea", "AXTabGroup")
-- @return number Count of elements with the target role
local function countAXRole(element, targetRole)
  if not element then return 0 end

  local role = element:attributeValue("AXRole")
  local count = (role == targetRole) and 1 or 0
  local children = element:attributeValue("AXChildren") or {}
  for _, child in ipairs(children) do
    count = count + countAXRole(child, targetRole)
  end

  return count
end

--- Find first element with a specific role in the accessibility tree
-- @param element AXUIElement to search
-- @param targetRole Role to find
-- @return AXUIElement or nil
local function findAXElement(element, targetRole)
  if not element then return nil end

  local role = element:attributeValue("AXRole")
  if role == targetRole then return element end

  local children = element:attributeValue("AXChildren") or {}
  for _, child in ipairs(children) do
    local found = findAXElement(child, targetRole)
    if found then return found end
  end

  return nil
end

--- Collect all elements with a specific role in the accessibility tree
-- @param element AXUIElement to search
-- @param targetRole Role to collect
-- @param results Table to accumulate results (optional, created if nil)
-- @return table Array of matching AXUIElements
local function collectAXElements(element, targetRole, results)
  results = results or {}
  if not element then return results end

  local role = element:attributeValue("AXRole")
  if role == targetRole then
    table.insert(results, element)
  end

  local children = element:attributeValue("AXChildren") or {}
  for _, child in ipairs(children) do
    collectAXElements(child, targetRole, results)
  end

  return results
end

-------------------------------------------------------------------------------
-- Window Analysis Functions
-------------------------------------------------------------------------------

--- Get the index of the currently focused split in a Ghostty window
-- Uses macOS accessibility APIs to find which AXTextArea has focus
-- @param window hs.window object
-- @return number Index of focused split (1-based), or 1 if not determinable
function M.getFocusedSplitIndex(window)
  if not window then return 1 end

  local ax = hs.axuielement.windowElement(window)
  if not ax then return 1 end

  -- Collect all AXTextArea elements (each split has one)
  local textAreas = collectAXElements(ax, "AXTextArea")
  if #textAreas == 0 then return 1 end

  -- Find which one has focus
  for i, textArea in ipairs(textAreas) do
    local focused = textArea:attributeValue("AXFocused")
    if focused then
      return i
    end
  end

  -- Fallback: check if any child has focus
  for i, textArea in ipairs(textAreas) do
    local children = textArea:attributeValue("AXChildren") or {}
    for _, child in ipairs(children) do
      local focused = child:attributeValue("AXFocused")
      if focused then
        return i
      end
    end
  end

  return 1
end

--- Get the number of tabs and splits in a Ghostty window
-- Uses macOS accessibility APIs to count UI elements
-- @param window hs.window object
-- @return tabCount, splitCount (both integers, minimum 1)
function M.getTabsAndSplits(window)
  if not window then return 1, 1 end

  local ax = hs.axuielement.windowElement(window)
  if not ax then return 1, 1 end

  -- Count tabs: look for AXTabGroup children
  local tabCount = 1
  local tabGroup = findAXElement(ax, "AXTabGroup")
  if tabGroup then
    local tabs = tabGroup:attributeValue("AXTabs") or tabGroup:attributeValue("AXChildren") or {}
    tabCount = math.max(1, #tabs)
  end

  -- Count splits: count AXTextArea elements (each split has one)
  local splitCount = math.max(1, countAXRole(ax, "AXTextArea"))

  return tabCount, splitCount
end

-------------------------------------------------------------------------------
-- Font Adjustment Functions
-------------------------------------------------------------------------------

--- Adjust font size for a specific Ghostty window using keystroke simulation
-- Sends cmd+= (increase) or cmd+- (decrease) keystrokes to change font size
-- @param window hs.window object to adjust
-- @param targetSize Target font size (integer)
-- @param currentSize Current font size (integer)
-- @param log Logger instance (optional)
-- @return boolean true if adjustment was attempted, false if skipped
function M.adjustWindowFontSize(window, targetSize, currentSize, log)
  if not window or not window:isStandard() then
    if log then
      log.w("adjustWindowFontSize called with invalid window")
    end

    return false
  end

  if type(targetSize) ~= "number" or type(currentSize) ~= "number" then
    if log then
      log.e(string.format("Invalid font sizes: target=%s, current=%s", tostring(targetSize), tostring(currentSize)))
    end

    return false
  end

  local delta = targetSize - currentSize
  if delta == 0 then
    if log then
      log.d(string.format("Window %d already at target size %d, skipping adjustment", window:id(), targetSize))
    end

    return false
  end

  -- Store original focused window to restore later
  local originalWindow = hs.window.focusedWindow()

  -- Focus the target window
  if not window:focus() then
    if log then
      log.w(string.format("Failed to focus window %d for font adjustment", window:id()))
    end

    return false
  end

  -- Wait for focus to settle
  hs.timer.usleep(50000) -- 50ms

  -- Send keystrokes to adjust font size
  local keystroke = delta > 0 and "=" or "-"
  local absoluteDelta = math.abs(delta)

  if log then
    log.d(string.format("Adjusting window %d font: %d -> %d (delta: %+d, keystrokes: %d×%s)",
      window:id(), currentSize, targetSize, delta, absoluteDelta, keystroke))
  end

  for _ = 1, absoluteDelta do
    hs.eventtap.keyStroke({"cmd"}, keystroke, 0)
    hs.timer.usleep(20000) -- 20ms between keystrokes
  end

  -- Restore original focus
  if originalWindow and originalWindow ~= window then
    pcall(function() originalWindow:focus() end)
  end

  return true
end

--- Clean up windowStates table by removing entries for closed windows
-- This prevents memory leaks from accumulating state for windows that no longer exist
-- @param log Logger instance (optional)
function M.cleanupWindowStates(log)
  if not M.windowStates or type(M.windowStates) ~= "table" then
    if log then
      log.w("cleanupWindowStates called but windowStates is not a table")
    end

    return
  end

  -- Get all current Ghostty window IDs
  local ghosttyFilter = hs.window.filter.new(false):setAppFilter('Ghostty')
  local currentWindows = ghosttyFilter:getWindows()
  local currentWindowIds = {}

  for _, window in ipairs(currentWindows) do
    currentWindowIds[window:id()] = true
  end

  -- Remove state entries for windows that no longer exist
  local removedCount = 0
  for windowId, _ in pairs(M.windowStates) do
    -- Skip special keys like _lastAppliedSize
    if type(windowId) == "number" and not currentWindowIds[windowId] then
      M.windowStates[windowId] = nil
      removedCount = removedCount + 1

      if log then
        log.d(string.format("Removed state for closed window ID: %d", windowId))
      end
    end
  end

  if removedCount > 0 and log then
    log.i(string.format("Cleaned up %d closed window state(s)", removedCount))
  end
end

-------------------------------------------------------------------------------
-- Keystroke Sequencing
-------------------------------------------------------------------------------

--- Send keystrokes to Ghostty window sequentially with proper async delays
-- This ensures each keystroke is processed before the next one is sent
-- @param window hs.window - Ghostty window to send keystrokes to
-- @param totalSplits number - Total number of splits to process
-- @param windowIndex number - Index of this window for logging
-- @param callback function - Called when all keystrokes are sent
-- @param log Logger instance (optional)
local function sendKeystrokesSequentially(window, totalSplits, windowIndex, callback, log)
  local keystrokeDelay = 0.075  -- 75ms between keystrokes for Ghostty to process
  local currentSplit = 0

  -- Step 1: Reload config
  if log then
    log.d(string.format("Window %d: Sending reload_config (cmd+shift+,)", windowIndex))
  end

  hs.eventtap.keyStroke({"cmd", "shift"}, ",", 0)

  -- Step 2: After reload, cycle through splits
  hs.timer.doAfter(0.15, function()  -- 150ms for config reload
    local function processNextSplit()
      currentSplit = currentSplit + 1

      if currentSplit > totalSplits then
        -- All splits processed
        if log then
          log.d(string.format("Sent reload + %d reset_font_size to window %d", totalSplits, windowIndex))
        end

        callback()
        return
      end

      -- Reset font size on current split
      if log then
        log.d(string.format("Window %d: Split %d/%d - sending reset_font_size (cmd+0)", windowIndex, currentSplit, totalSplits))
      end

      hs.eventtap.keyStroke({"cmd"}, "0", 0)

      -- Move to next split after a delay
      hs.timer.doAfter(keystrokeDelay, function()
        if log then
          log.d(string.format("Window %d: Split %d/%d - sending goto_split:next (cmd+])", windowIndex, currentSplit, totalSplits))
        end

        hs.eventtap.keyStroke({"cmd"}, "]", 0)

        -- Process next split after another delay
        hs.timer.doAfter(keystrokeDelay, processNextSplit)
      end)
    end

    processNextSplit()
  end)
end

-------------------------------------------------------------------------------
-- Main Font Update Functions
-------------------------------------------------------------------------------

--- Update Ghostty terminal font size via config file modification and reload
-- @param fontSize number - target font size
-- @param config Configuration table with ghosttyConfigOverlayPath
-- @param log Logger instance (optional)
-- @param onComplete function - optional callback when all keystrokes complete
function M.updateFontSize(fontSize, config, log, onComplete)
  if log then
    log.i(string.format("Updating Ghostty font size to %d via config overlay", fontSize))
  end

  -- Path to Ghostty config overlay (writable, not managed by Nix)
  local overlayPath = config.ghosttyConfigOverlayPath

  -- Create overlay content with just the font-size setting
  local overlayContent = string.format("font-size = %d\n", fontSize)

  -- Write overlay config
  local file = io.open(overlayPath, "w")
  if not file then
    if log then
      log.e(string.format("Cannot write Ghostty config overlay: %s", overlayPath))
    end

    return
  end

  file:write(overlayContent)
  file:close()

  if log then
    log.i(string.format("Updated font-size in overlay: %s", overlayPath))
  end

  -- Use window filter to find ALL Ghostty windows (more reliable across spaces)
  local windows = hs.window.filter.new(false):setAppFilter('Ghostty'):getWindows()

  if not windows or #windows == 0 then
    if log then
      log.w("No Ghostty windows found to send reload command")
    end

    return
  end

  if log then
    log.d(string.format("Found %d Ghostty window(s) via window filter", #windows))
  end

  -- Get Ghostty application object
  local ghostty = hs.application.get("Ghostty")
  if not ghostty then
    if log then
      log.w("Ghostty application not found, but windows exist - using fallback")
    end

    ghostty = windows[1]:application()
  end

  -- Activate Ghostty application first (ensures it's frontmost)
  ghostty:activate()

  -- Process windows sequentially (one at a time, not in parallel)
  local windowIndex = 0
  local function processNextWindow()
    windowIndex = windowIndex + 1

    if windowIndex > #windows then
      -- All windows processed
      if log then
        log.i(string.format("Sent reload_config to %d Ghostty window(s)", #windows))
      end

      -- Call completion callback if provided
      if onComplete then
        onComplete()
      end

      return
    end

    local window = windows[windowIndex]

    -- Focus this window (works even if on different space)
    window:focus()

    -- Wait for focus to settle, then get split info and send keystrokes
    hs.timer.doAfter(0.1, function()  -- 100ms for space switching and focus
      -- Get actual tab and split counts via accessibility API
      local tabCount, totalSplits = M.getTabsAndSplits(window)
      local splitsPerTab = math.ceil(totalSplits / tabCount)

      if log then
        log.d(string.format("Window %d: %d tabs, %d total splits (~%d per tab)", windowIndex, tabCount, totalSplits, splitsPerTab))
      end

      -- Send keystrokes sequentially with async delays
      sendKeystrokesSequentially(window, totalSplits, windowIndex, processNextWindow, log)
    end)
  end

  -- Start processing first window after activation delay
  hs.timer.doAfter(0.1, processNextWindow)
end

--- Check if any Ghostty window is on a built-in display
-- @param display Display module with isBuiltinScreen function
-- @param log Logger instance (optional)
-- @return boolean true if any window is on built-in, false if all on external (or no windows)
function M.anyWindowOnBuiltin(display, log)
  local allWindows = hs.window.filter.new(false):setAppFilter('Ghostty'):getWindows()

  if not allWindows or #allWindows == 0 then
    if log then
      log.d("No Ghostty windows found for position check")
    end

    return false -- No windows = treat as external (use larger font)
  end

  for _, window in ipairs(allWindows) do
    if window:isStandard() then
      local screen = window:screen()
      if screen and display.isBuiltinScreen(screen, log) then
        if log then
          log.d(string.format("Window %d is on built-in screen '%s'", window:id(), screen:name()))
        end

        return true
      end
    end
  end

  if log then
    log.d(string.format("All %d Ghostty window(s) are on external displays", #allWindows))
  end

  return false
end

--- Update all Ghostty windows based on window positions (hybrid approach)
-- Uses smaller font if ANY window is on built-in display
-- Uses larger font only if ALL windows are on external displays
-- @param config Configuration table
-- @param display Display module
-- @param log Logger instance (optional)
function M.updateAllWindows(config, display, log)
  local hasBuiltinWindow = M.anyWindowOnBuiltin(display, log)
  local fontSize = hasBuiltinWindow and config.ghosttyFontSizeWithoutMonitor or config.ghosttyFontSizeWithMonitor

  -- Track last applied size to avoid unnecessary reloads
  local lastSize = M.windowStates._lastAppliedSize
  if lastSize == fontSize then
    if log then
      log.d(string.format("Ghostty font size unchanged (%d), skipping reload", fontSize))
    end

    return
  end

  if log then
    log.i(string.format("Ghostty windows: %s on built-in → applying font size %d via config reload",
      hasBuiltinWindow and "some" or "none", fontSize))
  end

  -- Use global config+reload approach (works for all splits)
  M.updateFontSize(fontSize, config, log)

  -- Remember applied size
  M.windowStates._lastAppliedSize = fontSize
end

return M
