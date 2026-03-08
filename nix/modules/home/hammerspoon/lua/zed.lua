-- Zed IDE font size management for Hammerspoon display font adjuster
-- Uses pattern-based replacement to update settings.json while preserving comments
--
-- @module zed
-- @version 1.0

local M = {}

local function setTopLevelKey(content, key, value)
  local escaped = key:gsub("%-", "%%-")
  local pattern = '("' .. escaped .. '"%s*:%s*)%-?%d+%.?%d*'
  local replacement = '%1' .. string.format("%.1f", value)
  local newContent, count = content:gsub(pattern, replacement, 1)
  if count == 0 then
    -- key absent: insert before final closing brace
    newContent = content:gsub(
      '}(%s*)$',
      string.format(',\n  "%s": %.1f\n}%%1', key, value)
    )
  end
  return newContent
end

local function setTerminalFontSize(content, value)
  local formatted = string.format("%.1f", value)
  -- Case 1: terminal block has font_size → update it
  local updated, count = content:gsub(
    '("terminal"%s*:%s*{[^}]-)("font_size"%s*:%s*)%-?%d+%.?%d*',
    '%1%2' .. formatted, 1
  )
  if count > 0 then return updated end
  -- Case 2: terminal block exists, no font_size → insert it
  updated, count = content:gsub(
    '("terminal"%s*:%s*{)([^}]*)(})',
    function(open, inner, close)
      local comma = (inner:match('%S') and not inner:match(',%s*$')) and ',' or ''
      return open .. inner .. comma .. '\n    "font_size": ' .. formatted .. '\n  ' .. close
    end, 1
  )
  if count > 0 then return updated end
  -- Case 3: no terminal object → add before final closing brace
  return content:gsub(
    '}(%s*)$',
    string.format(',\n  "terminal": {\n    "font_size": %s\n  }\n}%%1', formatted)
  )
end

function M.updateFontSize(bufferSize, uiSize, terminalSize, config, log)
  local path = config.zedConfigPath
  if log then
    log.i(string.format("Updating Zed fonts: buffer=%d ui=%d terminal=%d → %s",
      bufferSize, uiSize, terminalSize, path))
  end
  local file = io.open(path, "r")
  if not file then
    if log then log.e("Cannot open Zed settings: " .. path) end
    return false
  end
  local content = file:read("*a")
  file:close()

  content = setTopLevelKey(content, "buffer_font_size", bufferSize)
  content = setTopLevelKey(content, "ui_font_size", uiSize)
  -- sync agent fonts to ui_font_size only if already present (don't create them)
  if content:find('"agent_buffer_font_size"') then
    content = setTopLevelKey(content, "agent_buffer_font_size", uiSize)
  end
  if content:find('"agent_ui_font_size"') then
    content = setTopLevelKey(content, "agent_ui_font_size", uiSize)
  end
  content = setTerminalFontSize(content, terminalSize)

  local out = io.open(path, "w")
  if not out then
    if log then log.e("Cannot write Zed settings: " .. path) end
    return false
  end
  out:write(content)
  out:close()
  if log then log.i("Zed settings updated (Zed will hot-reload)") end
  return true
end

return M
