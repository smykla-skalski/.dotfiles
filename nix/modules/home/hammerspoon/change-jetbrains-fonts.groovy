#!/usr/bin/env groovy

/**
 * JetBrains IDE Font Size Adjuster
 *
 * Dynamically updates font sizes in a running JetBrains IDE without restart.
 * Updates two font settings:
 * - Application-level editor font (Editor > Font)
 * - UI/menu fonts
 *
 * Note: Color scheme fonts are intentionally NOT modified to preserve custom
 * file status colors (like FILESTATUS_UNKNOWN). The application-level editor
 * font setting is sufficient for consistent font sizing across displays.
 *
 * Font size is read from temp file: $TMPDIR/jetbrains-font-size.txt
 * Fallback: FONT_SIZE environment variable (default: 15)
 *
 * Debug mode: Set DEBUG_MODE=true environment variable for verbose output
 *
 * @author Hammerspoon Display Font Adjuster
 * @version 2.1
 */

import com.intellij.ide.ui.LafManager
import com.intellij.ide.ui.UISettings
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.editor.EditorFactory
import com.intellij.openapi.editor.colors.impl.AppEditorFontOptions

import groovy.transform.Field

// Constants
@Field static final int DEFAULT_FONT_SIZE = 15
@Field static final int MIN_FONT_SIZE = 8
@Field static final int MAX_FONT_SIZE = 72
@Field static final String FONT_SIZE_FILE = 'jetbrains-font-size.txt'
@Field static final String DEBUG_ENV_VAR = 'DEBUG_MODE'

// Debug mode flag
@Field static final boolean DEBUG_MODE = System.getenv(DEBUG_ENV_VAR) == 'true'

/**
 * Log debug message if debug mode is enabled
 * @param message The message to log
 */
static void logDebug(String message) {
    if (DEBUG_MODE) {
        System.err.println("[DEBUG] ${message}")
    }
}

/**
 * Log info message (always shown)
 * @param message The message to log
 */
static void logInfo(String message) {
    System.err.println("[INFO] ${message}")
}

/**
 * Log error message (always shown)
 * @param message The message to log
 */
static void logError(String message) {
    System.err.println("[ERROR] ${message}")
}

/**
 * Get font size from temp file with fallback to environment variable
 * @return validated font size (guaranteed to be within valid range)
 */
static int getFontSize() {
    int fontSize = DEFAULT_FONT_SIZE

    // Try reading from temp file first (more reliable than env vars with ideScript)
    File tempFile = new File(System.getProperty('java.io.tmpdir'), FONT_SIZE_FILE)
    logDebug("Checking for font size in: ${tempFile.absolutePath}")

    if (tempFile.exists()) {
        try {
            String content = tempFile.text.trim()
            logDebug("Read content from file: '${content}'")

            if (content.isInteger()) {
                fontSize = content.toInteger()
                logDebug("Parsed font size from file: ${fontSize}")
            } else {
                logError("Invalid font size in file (not an integer): '${content}'")
            }
        } catch (IOException ex) {
            logError("Could not read font size from temp file: ${ex.message}")
        }
    } else {
        logDebug("Temp file not found, trying environment variable")
    }

    // Fallback to environment variable
    if (fontSize == DEFAULT_FONT_SIZE) {
        String fontSizeStr = System.getenv('FONT_SIZE')
        if (fontSizeStr?.isInteger()) {
            fontSize = fontSizeStr.toInteger()
            logDebug("Using font size from environment variable: ${fontSize}")
        }
    }

    // Validate font size range
    if (fontSize < MIN_FONT_SIZE || fontSize > MAX_FONT_SIZE) {
        logError("Font size ${fontSize} outside valid range [${MIN_FONT_SIZE}-${MAX_FONT_SIZE}], using ${DEFAULT_FONT_SIZE}")
        return DEFAULT_FONT_SIZE
    }

    logInfo("Using font size: ${fontSize}")
    return fontSize
}

/**
 * Update application-level editor font preferences
 * @param fontSize the font size to set
 */
static void updateEditorFontOptions(int fontSize) {
    logDebug("Updating editor font options to size: ${fontSize}")

    def fontOptions = AppEditorFontOptions.getInstance()
    def fontPrefs = fontOptions?.fontPreferences

    if (fontPrefs) {
        def fontFamily = fontPrefs.fontFamily
        logDebug("Current font family: ${fontFamily}")
        fontPrefs.setSize(fontFamily, fontSize as float)
        logDebug("Editor font size updated successfully")
    } else {
        logError('Could not access editor font preferences')
    }
}

/**
 * Update UI font settings
 * @param fontSize the font size to set
 */
static void updateUIFontSettings(int fontSize) {
    logDebug("Updating UI font settings to size: ${fontSize}")

    def uiSettings = UISettings.getInstance()

    if (uiSettings) {
        uiSettings.overrideLafFonts = true
        uiSettings.fontSize = fontSize as float
        logDebug("UI font size updated successfully")
    } else {
        logError('Could not access UI settings')
    }
}

/**
 * Trigger UI and editor refresh to apply changes immediately
 */
static void refreshUIAndEditors() {
    logDebug("Refreshing UI and editors to apply changes")

    // Refresh UI (menus, tool windows)
    def lafManager = LafManager.getInstance()
    if (lafManager) {
        lafManager.updateUI()
        logDebug("UI refreshed successfully")
    } else {
        logError("Could not get LafManager instance")
    }

    // Refresh all open editors to apply font changes
    def editorFactory = EditorFactory.getInstance()
    if (editorFactory) {
        try {
            editorFactory.refreshAllEditors()
            logDebug("All editors refreshed successfully")
        } catch (Exception ex) {
            logError("Could not refresh editors: ${ex.message}")
        }
    } else {
        logError("Could not get EditorFactory instance")
    }

    // NOTE: globalSchemeChange() notification removed - this triggers a full
    // color scheme reload which resets custom colors like FILESTATUS_UNKNOWN.
    // The UI and editor refresh above is sufficient to apply font changes.
}

/**
 * Main execution logic - orchestrates all font update operations
 */
static void updateFontSizes() {
    logInfo("Starting font size update process")

    def fontSize = getFontSize()

    try {
        updateEditorFontOptions(fontSize)
        // NOTE: updateColorSchemeFonts() removed - modifying color scheme fonts
        // triggers scheme reload which resets FILESTATUS_UNKNOWN color
        updateUIFontSettings(fontSize)
        refreshUIAndEditors()

        logInfo("Font size update completed successfully")
    } catch (Exception ex) {
        logError("Error updating font sizes: ${ex.message}")
        if (DEBUG_MODE) {
            ex.printStackTrace()
        }
    }
}

// Execute on Event Dispatch Thread to ensure thread-safety
logDebug("Scheduling font update on EDT")
ApplicationManager.application?.invokeLater {
    updateFontSizes()
}
