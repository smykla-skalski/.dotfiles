#!/usr/bin/env groovy

/**
 * JetBrains IDE Font Size Adjuster
 *
 * Dynamically updates font sizes in a running JetBrains IDE without restart.
 * Updates three font settings:
 * <ul>
 *   <li>Application-level editor font (Editor > Font)</li>
 *   <li>UI/menu fonts</li>
 *   <li>Terminal font</li>
 * </ul>
 *
 * <p>Note: Color scheme fonts are intentionally NOT modified to preserve custom
 * file status colors (like FILESTATUS_UNKNOWN). The application-level editor
 * font setting is sufficient for consistent font sizing across displays.</p>
 *
 * <p>Font size is read from temp file: {@code $TMPDIR/jetbrains-font-size.txt}<br>
 * Fallback: {@code FONT_SIZE} environment variable (default: 15)</p>
 *
 * <p>Debug mode: Set {@code DEBUG_MODE=true} environment variable for verbose output</p>
 *
 * @author Hammerspoon Display Font Adjuster
 * @version 2.2
 */

import com.intellij.ide.ui.LafManager
import com.intellij.ide.ui.UISettings
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.editor.EditorFactory
import com.intellij.openapi.editor.colors.impl.AppEditorFontOptions

import groovy.transform.CompileStatic
import groovy.transform.Field

import java.lang.reflect.Method

// =============================================================================
// Constants
// =============================================================================

@Field static final int DEFAULT_FONT_SIZE = 15
@Field static final int MIN_FONT_SIZE = 8
@Field static final int MAX_FONT_SIZE = 72
@Field static final String FONT_SIZE_FILE = 'jetbrains-font-size.txt'
@Field static final String DEBUG_ENV_VAR = 'DEBUG_MODE'
@Field static final String FONT_SIZE_ENV_VAR = 'FONT_SIZE'
@Field static final String TERMINAL_SERVICE_CLASS = 'org.jetbrains.plugins.terminal.TerminalFontSettingsService'

@Field static final boolean DEBUG_MODE = System.getenv(DEBUG_ENV_VAR) == 'true'

// =============================================================================
// Logging
// =============================================================================

/**
 * Logs a debug message if debug mode is enabled.
 *
 * @param message the message to log
 */
static void logDebug(String message) {
    if (DEBUG_MODE) {
        System.err.println("[DEBUG] ${message}")
    }
}

/**
 * Logs an info message (always shown).
 *
 * @param message the message to log
 */
static void logInfo(String message) {
    System.err.println("[INFO] ${message}")
}

/**
 * Logs an error message (always shown).
 *
 * @param message the message to log
 */
static void logError(String message) {
    System.err.println("[ERROR] ${message}")
}

// =============================================================================
// Font Size Resolution
// =============================================================================

/**
 * Reads font size from the temp file.
 *
 * @return the font size from file, or {@code null} if not available
 */
static Integer readFontSizeFromFile() {
    File tempFile = new File(System.getProperty('java.io.tmpdir'), FONT_SIZE_FILE)
    logDebug("Checking for font size in: ${tempFile.absolutePath}")

    if (!tempFile.exists()) {
        logDebug('Temp file not found')
        return null
    }

    try {
        String content = tempFile.text.trim()
        logDebug("Read content from file: '${content}'")

        if (content.isInteger()) {
            int size = content.toInteger()
            logDebug("Parsed font size from file: ${size}")
            return size
        }

        logError("Invalid font size in file (not an integer): '${content}'")
        return null
    } catch (IOException ex) {
        logError("Could not read font size from temp file: ${ex.message}")
        return null
    }
}

/**
 * Reads font size from environment variable.
 *
 * @return the font size from environment, or {@code null} if not available
 */
static Integer readFontSizeFromEnv() {
    String fontSizeStr = System.getenv(FONT_SIZE_ENV_VAR)

    if (fontSizeStr?.isInteger()) {
        int size = fontSizeStr.toInteger()
        logDebug("Using font size from environment variable: ${size}")
        return size
    }

    return null
}

/**
 * Validates that the font size is within acceptable bounds.
 *
 * @param fontSize the font size to validate
 * @return {@code true} if valid, {@code false} otherwise
 */
static boolean isValidFontSize(int fontSize) {
    return fontSize >= MIN_FONT_SIZE && fontSize <= MAX_FONT_SIZE
}

/**
 * Gets font size from temp file with fallback to environment variable.
 *
 * @return validated font size (guaranteed to be within valid range)
 */
static int getFontSize() {
    // Try temp file first (more reliable than env vars with ideScript)
    Integer fontSize = readFontSizeFromFile()

    // Fallback to environment variable
    if (fontSize == null) {
        logDebug('Trying environment variable')
        fontSize = readFontSizeFromEnv()
    }

    // Use default if nothing found
    if (fontSize == null) {
        logDebug("No font size configured, using default: ${DEFAULT_FONT_SIZE}")
        fontSize = DEFAULT_FONT_SIZE
    }

    // Validate range
    if (!isValidFontSize(fontSize)) {
        logError("Font size ${fontSize} outside valid range " +
                "[${MIN_FONT_SIZE}-${MAX_FONT_SIZE}], using ${DEFAULT_FONT_SIZE}")
        return DEFAULT_FONT_SIZE
    }

    logInfo("Using font size: ${fontSize}")
    return fontSize
}

// =============================================================================
// Font Update Operations
// =============================================================================

/**
 * Updates application-level editor font preferences.
 *
 * @param fontSize the font size to set
 * @return {@code true} if successful, {@code false} otherwise
 */
static boolean updateEditorFontOptions(int fontSize) {
    logDebug("Updating editor font options to size: ${fontSize}")

    def fontOptions = AppEditorFontOptions.getInstance()
    def fontPrefs = fontOptions?.fontPreferences

    if (fontPrefs == null) {
        logError('Could not access editor font preferences')
        return false
    }

    String fontFamily = fontPrefs.fontFamily
    logDebug("Current font family: ${fontFamily}")
    fontPrefs.setSize(fontFamily, fontSize as float)
    logDebug('Editor font size updated successfully')
    return true
}

/**
 * Updates UI font settings.
 *
 * @param fontSize the font size to set
 * @return {@code true} if successful, {@code false} otherwise
 */
static boolean updateUIFontSettings(int fontSize) {
    logDebug("Updating UI font settings to size: ${fontSize}")

    UISettings uiSettings = UISettings.getInstance()

    if (uiSettings == null) {
        logError('Could not access UI settings')
        return false
    }

    uiSettings.overrideLafFonts = true
    uiSettings.fontSize = fontSize as float
    logDebug('UI font size updated successfully')
    return true
}

/**
 * Updates terminal font settings using reflection.
 *
 * <p>Uses reflection because the terminal plugin may not be available in all IDEs,
 * and the API may vary between versions.</p>
 *
 * @param fontSize the font size to set
 * @return {@code true} if successful, {@code false} otherwise
 */
static boolean updateTerminalFontSettings(int fontSize) {
    logDebug("Updating terminal font settings to size: ${fontSize}")

    try {
        Class<?> serviceClass = Class.forName(TERMINAL_SERVICE_CLASS)
        Method getInstanceMethod = serviceClass.getMethod('getInstance')
        Object terminalFontService = getInstanceMethod.invoke(null)

        if (terminalFontService == null) {
            logError('Could not get TerminalFontSettingsService instance')
            return false
        }

        Method getFontPreferencesMethod = serviceClass.getMethod('getFontPreferences')
        Object fontPrefs = getFontPreferencesMethod.invoke(terminalFontService)

        if (fontPrefs == null) {
            logError('Could not access terminal font preferences')
            return false
        }

        String fontFamily = fontPrefs.fontFamily
        logDebug("Current terminal font family: ${fontFamily}")
        fontPrefs.setSize(fontFamily, fontSize as float)
        logDebug('Terminal font size updated successfully')

        // Trigger settings change notification
        Method fireStateChangedMethod = serviceClass.getMethod('fireStateChanged')
        fireStateChangedMethod.invoke(terminalFontService)
        logDebug('Terminal settings change notification fired')

        return true
    } catch (ClassNotFoundException ignored) {
        logDebug('Terminal plugin not available')
        return false
    } catch (NoSuchMethodException ex) {
        logDebug("Terminal font API not available: ${ex.message}")
        return false
    } catch (Exception ex) {
        logError("Could not update terminal font settings: ${ex.message}")
        if (DEBUG_MODE) {
            ex.printStackTrace()
        }
        return false
    }
}

// =============================================================================
// UI Refresh
// =============================================================================

/**
 * Triggers UI and editor refresh to apply changes immediately.
 *
 * <p>Note: globalSchemeChange() notification is intentionally not called as it
 * triggers a full color scheme reload which resets custom colors like
 * FILESTATUS_UNKNOWN.</p>
 */
static void refreshUIAndEditors() {
    logDebug('Refreshing UI and editors to apply changes')

    refreshLookAndFeel()
    refreshEditors()
}

/**
 * Refreshes the Look and Feel (menus, tool windows).
 */
private static void refreshLookAndFeel() {
    LafManager lafManager = LafManager.getInstance()

    if (lafManager == null) {
        logError('Could not get LafManager instance')
        return
    }

    lafManager.updateUI()
    logDebug('UI refreshed successfully')
}

/**
 * Refreshes all open editors to apply font changes.
 */
private static void refreshEditors() {
    EditorFactory editorFactory = EditorFactory.getInstance()

    if (editorFactory == null) {
        logError('Could not get EditorFactory instance')
        return
    }

    try {
        editorFactory.refreshAllEditors()
        logDebug('All editors refreshed successfully')
    } catch (Exception ex) {
        logError("Could not refresh editors: ${ex.message}")
    }
}

// =============================================================================
// Main Entry Point
// =============================================================================

/**
 * Main execution logic - orchestrates all font update operations.
 */
static void updateFontSizes() {
    logInfo('Starting font size update process')

    int fontSize = getFontSize()

    try {
        updateEditorFontOptions(fontSize)
        updateUIFontSettings(fontSize)
        updateTerminalFontSettings(fontSize)
        refreshUIAndEditors()

        logInfo('Font size update completed successfully')
    } catch (Exception ex) {
        logError("Error updating font sizes: ${ex.message}")
        if (DEBUG_MODE) {
            ex.printStackTrace()
        }
    }
}

// Execute on Event Dispatch Thread to ensure thread-safety
logDebug('Scheduling font update on EDT')
ApplicationManager.application?.invokeLater {
    updateFontSizes()
}
