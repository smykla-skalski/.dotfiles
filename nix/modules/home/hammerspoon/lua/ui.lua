-- Configuration UI for Hammerspoon display font adjuster
-- Provides a webview-based settings interface
--
-- @module ui
-- @version 1.0

local M = {}

-- Module state
local configWindow = nil
local originalFocusedWindow = nil
local checkTimer = nil

-------------------------------------------------------------------------------
-- HTML Template Generation
-------------------------------------------------------------------------------

-- Default IDE patterns available in the UI
local DEFAULT_PATTERNS = {
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

--- Generate the HTML template for the configuration UI
-- @param config Current configuration table
-- @return string HTML content
local function generateHtml(config)
  -- Build table header for default patterns
  local defaultHeadersHtml = ""
  for _, pattern in ipairs(DEFAULT_PATTERNS) do
    local escapedPattern = pattern:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
    defaultHeadersHtml = defaultHeadersHtml .. string.format('<th>%s</th>', escapedPattern)
  end

  -- Build checkboxes row for default patterns
  local defaultCheckboxesHtml = ""
  for _, pattern in ipairs(DEFAULT_PATTERNS) do
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
      '<td><input type="checkbox" class="default-ide" value="%s"%s><span class="custom-checkbox"></span></td>',
      escapedPattern, checkedAttr
    )
  end

  -- Build custom patterns as table cells
  local customPatternRows = {}
  for _, pattern in ipairs(config.idePatterns) do
    local isDefault = false
    for _, defaultPattern in ipairs(DEFAULT_PATTERNS) do
      if pattern == defaultPattern then
        isDefault = true
        break
      end
    end

    if not isDefault then
      local escapedPattern = pattern:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
      local escapedForJs = escapedPattern:gsub("'", "\\'")
      table.insert(customPatternRows, {pattern = escapedPattern, escapedForJs = escapedForJs})
    end
  end

  -- Build custom pattern rows with cells
  local customPatternsHtml = ""
  local numCols = #DEFAULT_PATTERNS
  local i = 1
  while i <= #customPatternRows do
    customPatternsHtml = customPatternsHtml .. '<tr><td class="pattern-type">Custom</td>'

    for _ = 1, numCols do
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

  return string.format([[
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
      box-shadow: 0 4px 20px rgba(0,0,0,0.15);
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
    .settings-row .config-item.quarter-width {
      flex: 0 0 calc(25%% - 22.5px);
      max-width: calc(25%% - 22.5px);
    }
    h2 {
      margin-top: 0;
      margin-bottom: 25px;
      color: #333;
      font-size: 28px;
      border-bottom: 3px solid #1ABC9C;
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
      height: 44px;
      padding: 0 14px;
      border: 1px solid #ddd;
      border-radius: 6px;
      font-size: 18px;
      text-align: center;
      font-family: 'Menlo', 'Consolas', 'Courier New', monospace;
    }
    input:focus {
      outline: none;
      border-color: #1ABC9C;
    }
    .checkbox-wrapper {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 12px 14px;
      border: 1px solid #ddd;
      border-radius: 6px;
      background: white;
      cursor: pointer;
      position: relative;
    }
    .checkbox-wrapper:hover {
      background: #f8f9fa;
    }
    .checkbox-wrapper input[type="checkbox"] {
      position: absolute;
      opacity: 0;
      cursor: pointer;
      width: 0;
      height: 0;
    }
    .checkbox-wrapper .custom-checkbox {
      width: 24px;
      height: 24px;
      border: 2px solid #ccc;
      border-radius: 4px;
      background: white;
      flex-shrink: 0;
      position: relative;
      transition: all 0.2s;
    }
    .checkbox-wrapper input[type="checkbox"]:checked + .custom-checkbox {
      background: #1ABC9C;
      border-color: #1ABC9C;
    }
    .checkbox-wrapper .custom-checkbox::after {
      content: "";
      position: absolute;
      display: none;
      left: 50%%;
      top: 50%%;
      width: 5px;
      height: 10px;
      border: solid white;
      border-width: 0 2.5px 2.5px 0;
      transform: translate(-50%%, -60%%) rotate(45deg);
    }
    .checkbox-wrapper input[type="checkbox"]:checked + .custom-checkbox::after {
      display: block;
    }
    .checkbox-wrapper label {
      margin: 0;
      cursor: pointer;
      flex: 1;
    }
    .ide-patterns-table {
      width: 100%%;
      border-collapse: separate;
      border-spacing: 0;
      margin: 15px 0;
      background: white;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .ide-patterns-table th {
      background: #1ABC9C;
      color: white;
      padding: 12px 10px;
      font-size: 14px;
      font-weight: 600;
      text-align: center;
      border-right: 1px solid rgba(255,255,255,0.2);
      white-space: nowrap;
    }
    .ide-patterns-table th:first-child {
      background: #16A085;
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
      cursor: pointer;
      user-select: none;
      transition: background-color 0.15s ease;
    }
    .ide-patterns-table td:hover {
      background: #f5f7fa;
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
      position: absolute;
      opacity: 0;
      cursor: pointer;
      width: 0;
      height: 0;
    }
    .ide-patterns-table .custom-checkbox {
      width: 20px;
      height: 20px;
      border: 2px solid #ccc;
      border-radius: 4px;
      background: white;
      display: inline-block;
      position: relative;
      transition: all 0.2s;
      cursor: pointer;
    }
    .ide-patterns-table input[type="checkbox"]:checked + .custom-checkbox {
      background: #1ABC9C;
      border-color: #1ABC9C;
    }
    .ide-patterns-table .custom-checkbox::after {
      content: "";
      position: absolute;
      display: none;
      left: 50%%;
      top: 50%%;
      width: 4px;
      height: 8px;
      border: solid white;
      border-width: 0 2px 2px 0;
      transform: translate(-50%%, -60%%) rotate(45deg);
    }
    .ide-patterns-table input[type="checkbox"]:checked + .custom-checkbox::after {
      display: block;
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
      background: #1ABC9C;
      color: white;
      border: none;
      border-radius: 6px;
      cursor: pointer;
      font-size: 16px;
      font-weight: 500;
    }
    button:hover {
      background: #16A085;
    }
    button:active {
      background: #148F77;
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
    .save-btn {
      background: #1ABC9C;
      position: relative;
    }
    .save-btn:hover {
      background: #16A085;
    }
    .save-btn:active {
      background: #148F77;
    }
    .save-btn.saving {
      pointer-events: none;
      opacity: 0.8;
      color: transparent;
    }
    .save-btn.saving::after {
      content: "";
      position: absolute;
      width: 16px;
      height: 16px;
      top: 50%%;
      left: 50%%;
      margin-left: -8px;
      margin-top: -8px;
      border: 2px solid white;
      border-top-color: transparent;
      border-radius: 50%%;
      animation: spin 0.8s linear infinite;
    }
    @keyframes spin {
      to { transform: rotate(360deg); }
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
    <div style="display: flex; gap: 40px; margin: 20px 0;">
      <!-- JetBrains IDE Group -->
      <div style="flex: 1;">
        <div style="font-size: 15px; font-weight: 600; color: #333; margin-bottom: 20px;">JetBrains IDE</div>
        <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px;">
          <!-- Built-in Display -->
          <div style="display: flex; flex-direction: column; gap: 8px;">
            <div style="font-size: 12px; color: #888; margin-bottom: 2px;">Built-in Display</div>
            <input type="number" id="fontSizeWithoutMonitor" min="8" max="30" value="%d">
          </div>
          <!-- External Monitor -->
          <div style="display: flex; flex-direction: column; gap: 8px;">
            <div style="font-size: 12px; color: #888; margin-bottom: 2px;">External Monitor</div>
            <input type="number" id="fontSizeWithMonitor" min="8" max="30" value="%d">
          </div>
        </div>
      </div>

      <!-- Vertical Separator -->
      <div style="width: 1px; background: rgba(0,0,0,0.06);"></div>

      <!-- Ghostty Terminal Group -->
      <div style="flex: 1;">
        <div style="font-size: 15px; font-weight: 600; color: #333; margin-bottom: 20px;">Ghostty Terminal</div>
        <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px;">
          <!-- Built-in Display -->
          <div style="display: flex; flex-direction: column; gap: 8px;">
            <div style="font-size: 12px; color: #888; margin-bottom: 2px;">Built-in Display</div>
            <input type="number" id="ghosttyFontSizeWithoutMonitor" min="8" max="30" value="%d">
          </div>
          <!-- External Monitor -->
          <div style="display: flex; flex-direction: column; gap: 8px;">
            <div style="font-size: 12px; color: #888; margin-bottom: 2px;">External Monitor</div>
            <input type="number" id="ghosttyFontSizeWithMonitor" min="8" max="30" value="%d">
          </div>
        </div>
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
      <div class="config-item">
        <label>Ghostty Config Overlay Path</label>
        <input type="text" id="ghosttyConfigOverlayPath" value="%s">
        <div class="description">Path to Ghostty config overlay file (writable)</div>
      </div>
      <div class="config-item">
        <label>Debug Mode</label>
        <div class="checkbox-wrapper">
          <input type="checkbox" id="debugMode" %s>
          <span class="custom-checkbox"></span>
          <label for="debugMode">Enable Debug Mode</label>
        </div>
        <div class="description">Shows verbose logging and startup alerts (requires reload)</div>
      </div>
    </div>
    <div class="settings-row">
      <div class="config-item quarter-width">
        <label>Window Position Aware (Ghostty)</label>
        <div class="checkbox-wrapper">
          <input type="checkbox" id="ghosttyPerWindowFontSizing" %s>
          <span class="custom-checkbox"></span>
          <label for="ghosttyPerWindowFontSizing">Enable Window Position Tracking</label>
        </div>
        <div class="description">Use smaller font if any Ghostty window is on built-in display; larger font only when all windows are on external</div>
      </div>
    </div>

    <div class="buttons">
      <button class="cancel-btn" onclick="cancel()">Cancel</button>
      <button class="save-btn" id="saveBtn" onclick="saveConfig()">Save</button>
    </div>
  </div>

  <script>
    const HOME_DIR = '%s';

    function replaceHomeWithTilde(path) {
      if (path && path.startsWith(HOME_DIR)) {
        return '~' + path.substring(HOME_DIR.length);
      }
      return path;
    }

    function expandTildeToHome(path) {
      if (path && path.startsWith('~')) {
        return HOME_DIR + path.substring(1);
      }
      return path;
    }

    window.addEventListener('DOMContentLoaded', function() {
      const pathInput = document.getElementById('ghosttyConfigOverlayPath');
      if (pathInput) {
        pathInput.value = replaceHomeWithTilde(pathInput.value);
      }
    });

    function removeCustomIDE(pattern) {
      const tbody = document.getElementById('idePatternsBody');
      const wrappers = tbody.querySelectorAll('.custom-pattern-wrapper');

      wrappers.forEach(wrapper => {
        if (wrapper.getAttribute('data-pattern') === pattern) {
          const cell = wrapper.parentElement;
          // Use safe DOM method: remove all children
          while (cell.firstChild) {
            cell.removeChild(cell.firstChild);
          }

          const row = cell.parentElement;
          const cells = row.querySelectorAll('td');
          let isEmpty = true;
          for (let i = 1; i < cells.length; i++) {
            if (cells[i].textContent.trim()) {
              isEmpty = false;
              break;
            }
          }

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

      const defaultCheckboxes = document.querySelectorAll('.default-ide');
      for (let checkbox of defaultCheckboxes) {
        if (checkbox.value === pattern) {
          alert('This pattern already exists in default patterns');
          return;
        }
      }

      const customWrappers = document.querySelectorAll('.custom-pattern-wrapper');
      for (let wrapper of customWrappers) {
        if (wrapper.getAttribute('data-pattern') === pattern) {
          alert('Pattern already exists');
          return;
        }
      }

      const tbody = document.getElementById('idePatternsBody');
      const numCols = 10;

      let lastCustomRow = null;
      const rows = tbody.querySelectorAll('tr');
      for (let i = rows.length - 1; i >= 0; i--) {
        const typeCell = rows[i].querySelector('.pattern-type');
        if (typeCell && typeCell.textContent === 'Custom') {
          lastCustomRow = rows[i];
          break;
        }
      }

      let targetCell = null;

      if (lastCustomRow) {
        const cells = lastCustomRow.querySelectorAll('td');
        for (let i = 1; i < cells.length; i++) {
          if (!cells[i].textContent.trim()) {
            targetCell = cells[i];
            break;
          }
        }
      }

      if (!targetCell) {
        const tr = document.createElement('tr');

        const tdType = document.createElement('td');
        tdType.className = 'pattern-type';
        tdType.textContent = 'Custom';
        tr.appendChild(tdType);

        for (let i = 0; i < numCols; i++) {
          const td = document.createElement('td');
          td.className = 'custom-pattern-cell';
          if (i === 0) {
            targetCell = td;
          }
          tr.appendChild(td);
        }

        tbody.appendChild(tr);
      }

      // Use safe DOM methods instead of innerHTML
      const wrapper = document.createElement('div');
      wrapper.className = 'custom-pattern-wrapper';
      wrapper.setAttribute('data-pattern', pattern);

      const textNode = document.createTextNode(pattern);
      wrapper.appendChild(textNode);

      const deleteBtn = document.createElement('button');
      deleteBtn.className = 'delete-btn';
      deleteBtn.textContent = '\u00D7';  // multiplication sign
      deleteBtn.onclick = function() { removeCustomIDE(pattern); };

      wrapper.appendChild(deleteBtn);
      targetCell.appendChild(wrapper);

      input.value = '';
    }

    function saveConfig() {
      const saveBtn = document.getElementById('saveBtn');
      saveBtn.classList.add('saving');

      const idePatterns = [];

      document.querySelectorAll('.default-ide:checked').forEach(checkbox => {
        idePatterns.push(checkbox.value);
      });

      const customWrappers = document.querySelectorAll('.custom-pattern-wrapper');
      customWrappers.forEach(wrapper => {
        const pattern = wrapper.getAttribute('data-pattern');
        if (pattern) {
          idePatterns.push(pattern);
        }
      });

      const config = {
        debugMode: document.getElementById('debugMode').checked,
        ghosttyPerWindowFontSizing: document.getElementById('ghosttyPerWindowFontSizing').checked,
        fontSizeWithMonitor: parseInt(document.getElementById('fontSizeWithMonitor').value),
        fontSizeWithoutMonitor: parseInt(document.getElementById('fontSizeWithoutMonitor').value),
        ghosttyFontSizeWithMonitor: parseInt(document.getElementById('ghosttyFontSizeWithMonitor').value),
        ghosttyFontSizeWithoutMonitor: parseInt(document.getElementById('ghosttyFontSizeWithoutMonitor').value),
        ghosttyConfigOverlayPath: expandTildeToHome(document.getElementById('ghosttyConfigOverlayPath').value),
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

    document.addEventListener('DOMContentLoaded', function() {
      const checkboxWrappers = document.querySelectorAll('.checkbox-wrapper');
      checkboxWrappers.forEach(wrapper => {
        wrapper.addEventListener('click', function(e) {
          if (e.target === wrapper || e.target.classList.contains('custom-checkbox')) {
            const checkbox = wrapper.querySelector('input[type="checkbox"]');
            if (checkbox) {
              checkbox.checked = !checkbox.checked;
            }
          }
        });
      });

      const table = document.querySelector('.ide-patterns-table');
      if (table) {
        table.addEventListener('click', function(e) {
          const td = e.target.closest('td');
          if (td && td.querySelector('input[type="checkbox"]')) {
            const checkbox = td.querySelector('input[type="checkbox"]');
            if (e.target !== checkbox) {
              checkbox.checked = !checkbox.checked;
            }
          }
        });
      }
    });
  </script>
</body>
</html>
  ]],
    config.fontSizeWithoutMonitor,
    config.fontSizeWithMonitor,
    config.ghosttyFontSizeWithoutMonitor,
    config.ghosttyFontSizeWithMonitor,
    defaultHeadersHtml,
    defaultCheckboxesHtml,
    customPatternsHtml,
    config.wakeDelaySeconds,
    config.pollIntervalSeconds,
    config.ghosttyConfigOverlayPath,
    config.debugMode and 'checked="checked"' or '',
    config.ghosttyPerWindowFontSizing and 'checked="checked"' or '',
    os.getenv("HOME")
  )
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

--- Show configuration UI
-- @param config Current configuration table
-- @param callbacks Table with onSave(newConfig), onClose() callbacks
-- @param log Logger instance (optional)
function M.show(config, callbacks, log)
  -- Clean up existing window if present
  if configWindow then
    pcall(function() configWindow:delete() end)
    configWindow = nil
  end

  if checkTimer then
    checkTimer:stop()
    checkTimer = nil
  end

  -- Save the currently focused window to restore later
  originalFocusedWindow = hs.window.focusedWindow()

  if log then
    log.i("Creating configuration UI window")
  end

  local html = generateHtml(config)

  -- Calculate window size based on screen (centered)
  local screen = hs.screen.mainScreen()
  local screenFrame = screen:frame()
  local windowWidth = 1350
  local windowHeight = math.min(math.floor(screenFrame.h * 0.90), 1100)
  local windowX = screenFrame.x + math.floor((screenFrame.w - windowWidth) / 2)
  local windowY = screenFrame.y + math.floor((screenFrame.h - windowHeight) / 2)

  configWindow = hs.webview.new({x=windowX, y=windowY, w=windowWidth, h=windowHeight})
    :windowStyle({"titled", "closable", "resizable", "miniaturizable"})
    :allowTextEntry(true)
    :allowGestures(true)
    :windowTitle("Hammerspoon Configuration")
    :html(html)
    :level(hs.drawing.windowLevels.floating)

  -- JavaScript bridge polling
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
      if not result or result == "null" or result == "" then
        return
      end

      local success, action = pcall(hs.json.decode, result)
      if not success then
        if log then
          log.e(string.format("Failed to parse action: %s", action))
        end

        return
      end

      if action.type == "save" then
        if log then
          log.i("Save button clicked")
        end

        -- Clean up UI
        if checkTimer then
          checkTimer:stop()
          checkTimer = nil
        end

        configWindow:delete()
        configWindow = nil

        -- Call save callback
        if callbacks and callbacks.onSave then
          callbacks.onSave(action.data, originalFocusedWindow)
        end

        originalFocusedWindow = nil
      elseif action.type == "close" then
        if log then
          log.i("Closing configuration UI")
        end

        if checkTimer then
          checkTimer:stop()
          checkTimer = nil
        end

        configWindow:delete()
        configWindow = nil

        -- Call close callback
        if callbacks and callbacks.onClose then
          callbacks.onClose(originalFocusedWindow)
        end

        originalFocusedWindow = nil
      end
    end)
  end)

  configWindow:show()
  configWindow:bringToFront(true)
end

--- Close the configuration UI if open
function M.close()
  if checkTimer then
    checkTimer:stop()
    checkTimer = nil
  end

  if configWindow then
    pcall(function() configWindow:delete() end)
    configWindow = nil
  end

  originalFocusedWindow = nil
end

--- Check if configuration UI is currently open
-- @return boolean true if UI is open
function M.isOpen()
  return configWindow ~= nil
end

return M
