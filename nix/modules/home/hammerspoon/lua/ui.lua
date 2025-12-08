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
    input[type="text"] {
      width: 100%%;
      height: 50px;
      padding: 0 14px;
      border: 1px solid #ddd;
      border-radius: 6px;
      font-size: 18px;
      font-family: 'Menlo', 'Consolas', 'Courier New', monospace;
      text-align: left;
    }
    input[type="text"]:focus {
      outline: none;
      border-color: #1ABC9C;
    }
    /* Custom number input wrapper */
    .number-input-wrapper {
      display: flex;
      align-items: stretch;
      height: 50px;
      border: 1px solid #ddd;
      border-radius: 6px;
      overflow: hidden;
      background: white;
    }
    .number-input-wrapper:focus-within {
      border-color: #1ABC9C;
    }
    .number-input-wrapper input[type="number"] {
      flex: 1;
      height: 100%%;
      padding: 0 10px;
      border: none;
      border-radius: 0;
      font-size: 18px;
      font-family: 'Menlo', 'Consolas', 'Courier New', monospace;
      text-align: center;
      background: transparent;
      -moz-appearance: textfield;
    }
    .number-input-wrapper input[type="number"]::-webkit-outer-spin-button,
    .number-input-wrapper input[type="number"]::-webkit-inner-spin-button {
      -webkit-appearance: none;
      margin: 0;
    }
    .number-input-wrapper input[type="number"]:focus {
      outline: none;
    }
    .number-input-arrows {
      display: flex;
      flex-direction: column;
      width: 32px;
      border-left: 1px solid #ddd;
      user-select: none;
      -webkit-user-select: none;
    }
    .number-input-arrow {
      flex: 1;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #f8f9fa;
      cursor: default;
      user-select: none;
      -webkit-user-select: none;
      transition: background-color 0.1s;
    }
    .number-input-arrow:first-child {
      border-bottom: 1px solid #ddd;
    }
    .number-input-arrow:hover {
      background: #e9ecef;
    }
    .number-input-arrow:active {
      background: #dee2e6;
    }
    .number-input-arrow svg {
      width: 12px;
      height: 12px;
      fill: #666;
    }
    .number-input-arrow:hover svg {
      fill: #333;
    }
    .checkbox-wrapper {
      display: flex;
      align-items: center;
      gap: 12px;
      height: 50px;
      padding: 0 14px;
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
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
    }
    .save-btn:hover {
      background: #16A085;
    }
    .save-btn:active {
      background: #148F77;
    }
    .save-btn.reload-btn {
      background: #007AFF;
    }
    .save-btn.reload-btn:hover {
      background: #0056b3;
    }
    .save-btn.reload-btn:active {
      background: #004499;
    }
    .save-btn.loading {
      pointer-events: none;
      opacity: 0.8;
    }
    .save-btn.loading .btn-text,
    .save-btn.loading .btn-icon {
      visibility: hidden;
    }
    .save-btn.loading::after {
      content: "";
      position: absolute;
      width: 20px;
      height: 20px;
      top: 50%%;
      left: 50%%;
      margin-left: -10px;
      margin-top: -10px;
      border: 2.5px solid white;
      border-top-color: transparent;
      border-radius: 50%%;
      animation: spin 0.8s linear infinite;
    }
    .btn-icon {
      width: 20px;
      height: 20px;
      flex-shrink: 0;
    }
    .btn-icon svg {
      width: 100%%;
      height: 100%%;
      fill: currentColor;
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
            <div class="number-input-wrapper">
              <input type="number" id="fontSizeWithoutMonitor" min="8" max="30" value="%d">
              <div class="number-input-arrows">
                <div class="number-input-arrow" data-input="fontSizeWithoutMonitor" data-dir="up"></div>
                <div class="number-input-arrow" data-input="fontSizeWithoutMonitor" data-dir="down"></div>
              </div>
            </div>
          </div>
          <!-- External Monitor -->
          <div style="display: flex; flex-direction: column; gap: 8px;">
            <div style="font-size: 12px; color: #888; margin-bottom: 2px;">External Monitor</div>
            <div class="number-input-wrapper">
              <input type="number" id="fontSizeWithMonitor" min="8" max="30" value="%d">
              <div class="number-input-arrows">
                <div class="number-input-arrow" data-input="fontSizeWithMonitor" data-dir="up"></div>
                <div class="number-input-arrow" data-input="fontSizeWithMonitor" data-dir="down"></div>
              </div>
            </div>
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
            <div class="number-input-wrapper">
              <input type="number" id="ghosttyFontSizeWithoutMonitor" min="8" max="30" value="%d">
              <div class="number-input-arrows">
                <div class="number-input-arrow" data-input="ghosttyFontSizeWithoutMonitor" data-dir="up"></div>
                <div class="number-input-arrow" data-input="ghosttyFontSizeWithoutMonitor" data-dir="down"></div>
              </div>
            </div>
          </div>
          <!-- External Monitor -->
          <div style="display: flex; flex-direction: column; gap: 8px;">
            <div style="font-size: 12px; color: #888; margin-bottom: 2px;">External Monitor</div>
            <div class="number-input-wrapper">
              <input type="number" id="ghosttyFontSizeWithMonitor" min="8" max="30" value="%d">
              <div class="number-input-arrows">
                <div class="number-input-arrow" data-input="ghosttyFontSizeWithMonitor" data-dir="up"></div>
                <div class="number-input-arrow" data-input="ghosttyFontSizeWithMonitor" data-dir="down"></div>
              </div>
            </div>
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

    <div class="buttons">
      <button class="cancel-btn" onclick="cancel()">Cancel</button>
      <button class="save-btn" id="saveBtn" onclick="saveConfig()">
        <span class="btn-icon" id="saveBtnIcon">
          <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M17 3H5c-1.11 0-2 .9-2 2v14c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V7l-4-4zm-5 16c-1.66 0-3-1.34-3-3s1.34-3 3-3 3 1.34 3 3-1.34 3-3 3zm3-10H5V5h10v4z"/>
          </svg>
        </span>
        <span class="btn-text" id="saveBtnText">Save</span>
      </button>
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

    // State tracking for Save/Reload toggle
    let originalConfig = null;
    let isDirty = false;

    // Get current form state as object for comparison
    function getFormState() {
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

      return {
        debugMode: document.getElementById('debugMode').checked,
        fontSizeWithMonitor: parseInt(document.getElementById('fontSizeWithMonitor').value),
        fontSizeWithoutMonitor: parseInt(document.getElementById('fontSizeWithoutMonitor').value),
        ghosttyFontSizeWithMonitor: parseInt(document.getElementById('ghosttyFontSizeWithMonitor').value),
        ghosttyFontSizeWithoutMonitor: parseInt(document.getElementById('ghosttyFontSizeWithoutMonitor').value),
        ghosttyConfigOverlayPath: expandTildeToHome(document.getElementById('ghosttyConfigOverlayPath').value),
        idePatterns: idePatterns.sort()
      };
    }

    // Compare two config objects for equality
    function configsEqual(a, b) {
      if (!a || !b) return false;

      // Compare simple values
      if (a.debugMode !== b.debugMode) return false;
      if (a.fontSizeWithMonitor !== b.fontSizeWithMonitor) return false;
      if (a.fontSizeWithoutMonitor !== b.fontSizeWithoutMonitor) return false;
      if (a.ghosttyFontSizeWithMonitor !== b.ghosttyFontSizeWithMonitor) return false;
      if (a.ghosttyFontSizeWithoutMonitor !== b.ghosttyFontSizeWithoutMonitor) return false;
      if (a.ghosttyConfigOverlayPath !== b.ghosttyConfigOverlayPath) return false;

      // Compare IDE patterns arrays
      if (a.idePatterns.length !== b.idePatterns.length) return false;
      for (let i = 0; i < a.idePatterns.length; i++) {
        if (a.idePatterns[i] !== b.idePatterns[i]) return false;
      }

      return true;
    }

    // Create SVG icon element safely using DOM methods
    function createSaveIcon() {
      const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      svg.setAttribute('viewBox', '0 0 24 24');
      const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      path.setAttribute('d', 'M17 3H5c-1.11 0-2 .9-2 2v14c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V7l-4-4zm-5 16c-1.66 0-3-1.34-3-3s1.34-3 3-3 3 1.34 3 3-1.34 3-3 3zm3-10H5V5h10v4z');
      svg.appendChild(path);
      return svg;
    }

    function createReloadIcon() {
      const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      svg.setAttribute('viewBox', '0 0 24 24');
      const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      path.setAttribute('d', 'M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z');
      svg.appendChild(path);
      return svg;
    }

    // Check if form has changes and update button accordingly
    function checkForChanges() {
      const currentConfig = getFormState();
      isDirty = !configsEqual(currentConfig, originalConfig);

      const saveBtn = document.getElementById('saveBtn');
      const btnIcon = document.getElementById('saveBtnIcon');
      const btnText = document.getElementById('saveBtnText');

      // Clear existing icon
      while (btnIcon.firstChild) {
        btnIcon.removeChild(btnIcon.firstChild);
      }

      if (isDirty) {
        btnText.textContent = 'Save';
        btnIcon.appendChild(createSaveIcon());
        saveBtn.classList.remove('reload-btn');
      } else {
        btnText.textContent = 'Reload';
        btnIcon.appendChild(createReloadIcon());
        saveBtn.classList.add('reload-btn');
      }
    }

    // Attach change listeners to all form inputs
    function attachChangeListeners() {
      // Number and text inputs
      const inputs = document.querySelectorAll('input[type="number"], input[type="text"]');
      inputs.forEach(input => {
        input.addEventListener('input', checkForChanges);
        input.addEventListener('change', checkForChanges);
      });

      // Checkboxes
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      checkboxes.forEach(checkbox => {
        checkbox.addEventListener('change', checkForChanges);
      });
    }

    window.addEventListener('DOMContentLoaded', function() {
      const pathInput = document.getElementById('ghosttyConfigOverlayPath');
      if (pathInput) {
        pathInput.value = replaceHomeWithTilde(pathInput.value);
      }

      // Capture original config state after path normalization
      // Use setTimeout to ensure all DOM updates are complete
      setTimeout(function() {
        originalConfig = getFormState();
        // Initial state is clean - show Reload button
        checkForChanges();
        attachChangeListeners();
      }, 0);
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

      // Trigger change detection after removing pattern
      checkForChanges();
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

      // Trigger change detection after adding pattern
      checkForChanges();
    }

    function saveConfig() {
      const saveBtn = document.getElementById('saveBtn');
      saveBtn.classList.add('loading');

      // Get current form state using shared function
      const config = getFormState();

      // Determine action type based on whether form is dirty
      // If dirty: save config and apply settings
      // If clean: just reload/apply current settings without saving
      const actionType = isDirty ? 'save' : 'reload';

      window.__pendingAction = {
        type: actionType,
        data: config
      };
    }

    function cancel() {
      window.__pendingAction = {
        type: 'close'
      };
    }

    // Create up/down arrow SVG icons for number inputs
    function createUpArrowIcon() {
      const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      svg.setAttribute('viewBox', '0 0 24 24');
      const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      path.setAttribute('d', 'M7 14l5-5 5 5z');
      svg.appendChild(path);
      return svg;
    }

    function createDownArrowIcon() {
      const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      svg.setAttribute('viewBox', '0 0 24 24');
      const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      path.setAttribute('d', 'M7 10l5 5 5-5z');
      svg.appendChild(path);
      return svg;
    }

    // Handle number input arrow clicks
    function setupNumberInputArrows() {
      const arrows = document.querySelectorAll('.number-input-arrow');
      arrows.forEach(arrow => {
        // Add icon
        const dir = arrow.getAttribute('data-dir');
        if (dir === 'up') {
          arrow.appendChild(createUpArrowIcon());
        } else {
          arrow.appendChild(createDownArrowIcon());
        }

        // Prevent text selection on mousedown
        arrow.addEventListener('mousedown', function(e) {
          e.preventDefault();
        });

        // Add click handler
        arrow.addEventListener('click', function(e) {
          e.preventDefault();
          const inputId = this.getAttribute('data-input');
          const input = document.getElementById(inputId);
          if (!input) return;

          const min = parseInt(input.getAttribute('min')) || 0;
          const max = parseInt(input.getAttribute('max')) || 100;
          let value = parseInt(input.value) || min;

          if (dir === 'up') {
            value = Math.min(value + 1, max);
          } else {
            value = Math.max(value - 1, min);
          }

          input.value = value;
          // Dispatch events to trigger change detection
          input.dispatchEvent(new Event('input', { bubbles: true }));
          input.dispatchEvent(new Event('change', { bubbles: true }));
        });
      });
    }

    document.addEventListener('DOMContentLoaded', function() {
      // Setup custom number input arrows
      setupNumberInputArrows();

      const checkboxWrappers = document.querySelectorAll('.checkbox-wrapper');
      checkboxWrappers.forEach(wrapper => {
        wrapper.addEventListener('click', function(e) {
          if (e.target === wrapper || e.target.classList.contains('custom-checkbox')) {
            const checkbox = wrapper.querySelector('input[type="checkbox"]');
            if (checkbox) {
              checkbox.checked = !checkbox.checked;
              // Trigger change detection
              checkbox.dispatchEvent(new Event('change', { bubbles: true }));
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
              // Trigger change detection
              checkbox.dispatchEvent(new Event('change', { bubbles: true }));
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
    config.ghosttyConfigOverlayPath,
    config.debugMode and 'checked="checked"' or '',
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
      elseif action.type == "reload" then
        if log then
          log.i("Reload button clicked (apply settings without saving)")
        end

        -- Stop polling but keep window open until work completes
        if checkTimer then
          checkTimer:stop()
          checkTimer = nil
        end

        -- Create close callback for when work is done
        local function closeUI()
          if configWindow then
            configWindow:delete()
            configWindow = nil
          end

          originalFocusedWindow = nil
        end

        -- Call reload callback with close function
        if callbacks and callbacks.onReload then
          callbacks.onReload(originalFocusedWindow, closeUI)
        else
          -- No callback, close immediately
          closeUI()
        end
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
