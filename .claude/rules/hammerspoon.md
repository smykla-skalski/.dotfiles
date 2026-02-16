# Hammerspoon Debugging & IPC

Config: `nix/modules/home/hammerspoon/init.lua` → `~/.hammerspoon/init.lua` (symlinked by home-manager)

**Console**: Hammerspoon menubar → "Console..." (view errors/logs)

## IPC Command Best Practices

**CRITICAL**: Always use `-q` (quiet mode) and `-t` timeout to prevent hanging:

```bash
hs -q -t 2 -c "return 'value'"           # CORRECT: return + quiet + timeout
hs -c "print('value')"                   # WRONG: hangs, buffers in console
```

**Why commands hang**:

- `print()` redirects to Hammerspoon console, can buffer/block IPC
- Rapid command succession invalidates message port ([#2974](https://github.com/Hammerspoon/hammerspoon/issues/2974))
- Missing timeout causes indefinite wait for Hammerspoon idle state
- `hs.reload()` invalidates IPC port (exit code 69 is normal)

**Flags**:

- `-q`: Quiet mode, only outputs final result (prevents console buffer issues)
- `-t SEC`: Timeout in seconds (default can hang indefinitely)
- `-P`: Mirror print() to Hammerspoon console (debugging only)

## Status Checks

```bash
hs -q -t 2 -c "return tostring(config ~= nil)"                    # Config loaded?
hs -q -t 2 -c "return type(updateGhosttyFontSize)"               # Function exists?
hs -q -t 2 -c "return tostring(config.ghosttyFontSizeWithMonitor)" # Check values
hs -c "hs.reload()" 2>&1                                          # Reload (ignore port errors)
```

## Debug Mode

Enable verbose logging, startup alerts, display detection:

```bash
hs -q -t 2 -c "toggleDebugMode(); return 'toggled'"  # Toggle via IPC
# OR: Cmd+Alt+Ctrl+H → Enable Debug Mode → Save → Reload
# OR: DEBUG_MODE=true hs
```

## View Logs

```bash
hs -q -t 5 -c "return hs.console.getConsole()"  # Console output (increase timeout)
hs -q -t 2 -c "log.printHistory()"              # Logger history
```

## Troubleshooting

**"config is nil"** → init.lua failed to load:

1. Check Console (menubar → Console...) for Lua errors
2. `ls -la ~/.hammerspoon/init.lua` (verify symlink)
3. `home-manager switch --flake $DOTFILES_PATH/nix#home-bart` (rebuild)
4. `hs -c "hs.reload()"`

**"message port invalid"** → Normal during reload, ignore

**Docs**: [hs.ipc](https://www.hammerspoon.org/docs/hs.ipc.html) · [hs.logger](https://www.hammerspoon.org/docs/hs.logger.html) · [hs.console](https://www.hammerspoon.org/docs/hs.console.html) · [CLI Usage](https://stackoverflow.com/questions/69711165/how-to-use-the-hammerspoon-cli)
