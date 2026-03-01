# Hammerspoon Display Font Adjuster

Adjusts JetBrains IDE and Ghostty terminal font sizes based on your display configuration. Use the configuration UI to set font sizes for built-in vs. external monitors, then manually apply settings via Save or Reload.

## Features

- **Display Detection**: Detects built-in vs. external monitors
- **Manual Font Control**: Apply font settings via config UI (no automatic triggers)
- **Multi-IDE Support**: Works with all JetBrains IDEs (GoLand, WebStorm, IntelliJ, etc.)
- **Ghostty Terminal**: Per-window font sizing based on display position
- **Live Updates**: Updates fonts in running IDEs without restart
- **Configuration UI**: Easy-to-use GUI for customizing settings
- **Save/Reload Toggle**: Button shows "Save" when changes pending, "Reload" to apply current config
- **Debug Mode**: Optional verbose logging for troubleshooting

## Quick Start

1. **Launch Hammerspoon**: The configuration loads automatically
2. **Open Config UI**: Press `Cmd+Alt+Ctrl+H`
3. **Configure Font Sizes**: Set sizes for built-in display and external monitor
4. **Select IDEs**: Choose which JetBrains IDEs to update
5. **Apply Settings**: Click "Save" to save and apply, or "Reload" to apply current config

## Manual Workflow

This configuration uses a **manual-only** approach:

- **No automatic font changes** on display connect/disconnect
- **No background polling** for display changes
- **User-initiated only**: Open config UI and click Save/Reload to apply fonts

This gives you full control over when font sizes change.

## Debug Mode

Debug mode provides verbose logging and helps troubleshoot issues. It's **disabled by default** to keep your console clean.

### Enabling Debug Mode

Choose one of these methods:

#### 1. Via Configuration UI (Recommended)

1. Press `Cmd+Alt+Ctrl+H` to open settings
2. Check "Enable Debug Mode" under Advanced Settings
3. Click "Save"
4. Reload Hammerspoon: `Cmd+Ctrl+Alt+R` or from menu

#### 2. Via IPC/Console

```bash
# Toggle debug mode
hs -c "toggleDebugMode()"

# Check debug mode status
hs -c "debugModeStatus()"
```

#### 3. Via Environment Variable

```bash
# Launch Hammerspoon with debug mode
DEBUG_MODE=true hs
```

### What Debug Mode Shows

When enabled, debug mode provides:

- **Startup Alert**: "Hammerspoon config loaded (Debug Mode ON)"
- **Verbose Logging**: All debug-level log messages
- **Display Detection Details**: Information about connected displays
- **Font Update Operations**: Details of IDE font changes
- **Configuration Changes**: Logs when settings are modified

### Debug Mode in Groovy Script

The JetBrains font adjustment script also supports debug mode:

```bash
# Enable debug mode for the Groovy script
export DEBUG_MODE=true

# Now when fonts are adjusted, you'll see detailed logs
```

Debug output includes:

- Font size source (temp file vs. environment variable)
- Font family being updated
- UI refresh operations
- Any errors encountered

## Configuration

### Font Sizes

**JetBrains IDE:**

- **Font Size with External Monitor**: Larger font for external displays (default: 15)
- **Font Size without External Monitor**: Smaller font for built-in display (default: 12)

**Ghostty Terminal:**

- **Font Size with External Monitor**: Larger font for external displays (default: 20)
- **Font Size without External Monitor**: Smaller font for built-in display (default: 15)

### JetBrains IDE Patterns

Select which IDEs to update:

**Default Patterns** (check to enable):

- GoLand
- WebStorm
- RustRover
- IntelliJ IDEA
- PyCharm
- CLion
- DataGrip
- PhpStorm
- Rider
- AppCode

**Custom Patterns**: Add custom IDE patterns using wildcards (e.g., `AndroidStudio*`)

### Advanced Settings

- **Ghostty Config Overlay Path**: Path to Ghostty config overlay file (writable)
- **Debug Mode**: Enable verbose logging and startup alerts
- **Window Position Aware (Ghostty)**: Per-window font sizing based on display position

## Keyboard Shortcuts

- `Cmd+Alt+Ctrl+H`: Open configuration UI

## Troubleshooting

### Hotkey Not Working

1. Check Accessibility Permissions:
   - Go to System Settings > Privacy & Security > Accessibility
   - Ensure Hammerspoon is enabled
2. Enable debug mode to see if hotkey is detected
3. Try reloading Hammerspoon configuration

### Fonts Not Updating

1. **Enable debug mode** to see what's happening
2. Check if your IDE is in the patterns list
3. Verify JetBrains directory path:
   - System: `/Library/Application Support/JetBrains`
   - Toolbox: `~/Library/Application Support/JetBrains`
   - Apps: `/Applications/` and `~/Applications/`
4. Ensure IDE configuration directories exist

### Display Detection Issues

1. Enable debug mode to see display detection logs
2. Verify external monitor is properly connected
3. Open config UI and check "Reload" applies correct font size

## Architecture

### Components

1. **init.lua**: Main Hammerspoon configuration
   - Display detection
   - Font size coordination
   - Configuration management
   - GUI interface

2. **lua/**: Modular components (for future use)
   - `config.lua`: Configuration management
   - `display.lua`: Display detection
   - `jetbrains.lua`: JetBrains IDE font updates
   - `ghostty.lua`: Ghostty terminal font updates
   - `ui.lua`: Configuration UI

3. **change-jetbrains-fonts.groovy**: JetBrains IDE font adjuster
   - Updates fonts in running IDEs
   - No restart required
   - Updates UI and editor fonts

### Font Update Flow

```text
User Opens Config UI (Cmd+Alt+Ctrl+H)
  ↓
Configure Font Sizes
  ↓
Click Save or Reload
  ↓
Detect Current Display Type
  ↓
Calculate Appropriate Font Size
  ↓
Update JetBrains Config Files
  ↓
Apply to Running IDEs (via Groovy script)
  ↓
Update Ghostty Windows
```

## Log Levels

| Level   | When Shown          | Purpose                        |
|---------|---------------------|--------------------------------|
| Debug   | Debug mode only     | Detailed troubleshooting info  |
| Info    | Debug mode only     | General operational messages   |
| Warning | Always              | Potential issues               |
| Error   | Always              | Failures and errors            |

## IPC Commands

Hammerspoon IPC allows command-line interaction:

```bash
# Toggle debug mode
hs -c "toggleDebugMode()"

# Check debug status
hs -c "debugModeStatus()"

# Show configuration UI
hs -c "showConfigUI()"

# Apply font settings for current display
hs -c "applyFontSettings()"
```

## File Locations

- **Configuration**: `~/.hammerspoon/init.lua`
- **Lua Modules**: `~/.hammerspoon/lua/`
- **Groovy Script**: `~/.hammerspoon/change-jetbrains-fonts.groovy`
- **Settings Storage**: Hammerspoon persistent settings (managed automatically)
- **Temp Font Size**: `$TMPDIR/jetbrains-font-size.txt`
- **JetBrains Configs**: `~/Library/Application Support/JetBrains/[IDE]/options/other.xml`
- **Ghostty Overlay**: `~/.config/ghostty/config.local` (configurable)

## Best Practices

1. **Keep Debug Mode Off**: Only enable when troubleshooting
2. **Use Configuration UI**: Safer than manual config file editing
3. **Check Logs**: Use Console.app or `hs -c` to view Hammerspoon logs
4. **Backup Settings**: Configuration is stored in Hammerspoon settings

## Version Information

- **Lua Configuration**: 3.0
- **Groovy Script**: 2.0
- **Lua Version**: 5.3+
- **Hammerspoon**: Compatible with latest stable release

## License

Part of smykla-skalski dotfiles configuration.
