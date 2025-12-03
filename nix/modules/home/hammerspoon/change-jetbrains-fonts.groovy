#!/usr/bin/env groovy

/**
 * JetBrains IDE Font Size Adjuster
 *
 * Dynamically updates font sizes in a running JetBrains IDE without restart.
 * Updates three font settings:
 * - Application-level editor font (Editor > Font)
 * - All color scheme fonts (synced to match default)
 * - UI/menu fonts
 *
 * Font size is read from temp file: $TMPDIR/jetbrains-font-size.txt
 * Fallback: FONT_SIZE environment variable (default: 15)
 */

import com.intellij.ide.ui.LafManager
import com.intellij.ide.ui.UISettings
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.editor.EditorFactory
import com.intellij.openapi.editor.colors.EditorColorsManager
import com.intellij.openapi.editor.colors.EditorColorsScheme
import com.intellij.openapi.editor.colors.impl.AppEditorFontOptions

import groovy.transform.Field

// Constants
@Field static final int DEFAULT_FONT_SIZE = 15
@Field static final int MIN_FONT_SIZE = 8
@Field static final int MAX_FONT_SIZE = 72

/**
 * Get font size from temp file with fallback to environment variable
 * @return validated font size
 */
static int getFontSize() {
    int fontSize = DEFAULT_FONT_SIZE

    // Try reading from temp file first (more reliable than env vars with ideScript)
    File tempFile = new File(System.getProperty('java.io.tmpdir'), 'jetbrains-font-size.txt')
    if (tempFile.exists()) {
        try {
            String content = tempFile.text.trim()
            if (content.isInteger()) {
                fontSize = content.toInteger()
            }
        } catch (IOException ex) {
            System.err.println("Could not read font size from temp file: ${ex.message}")
        }
    }

    // Fallback to environment variable
    if (fontSize == DEFAULT_FONT_SIZE) {
        String fontSizeStr = System.getenv('FONT_SIZE')
        if (fontSizeStr?.isInteger()) {
            fontSize = fontSizeStr.toInteger()
        }
    }

    if (fontSize < MIN_FONT_SIZE || fontSize > MAX_FONT_SIZE) {
        System.err.println("Warning: Font size ${fontSize} outside valid range [${MIN_FONT_SIZE}-${MAX_FONT_SIZE}], using ${DEFAULT_FONT_SIZE}")
        return DEFAULT_FONT_SIZE
    }

    return fontSize
}

/**
 * Update application-level editor font preferences
 * @param fontSize the font size to set
 */
static void updateEditorFontOptions(int fontSize) {
    def fontOptions = AppEditorFontOptions.getInstance()
    def fontPrefs = fontOptions?.fontPreferences

    if (fontPrefs) {
        def fontFamily = fontPrefs.fontFamily
        fontPrefs.setSize(fontFamily, fontSize as float)
    } else {
        System.err.println('Warning: Could not access editor font preferences')
    }
}

/**
 * Reset color schemes to use application default font
 * Updates the color scheme font size to match app default since
 * we cannot uncheck "Use color scheme font" programmatically
 * @param fontSize the font size to set
 */
static void syncColorSchemeFonts(int fontSize) {
    def editorColorsManager = EditorColorsManager.getInstance()

    // Update all schemes to match the app default font size
    editorColorsManager?.allSchemes?.each { EditorColorsScheme scheme ->
        if (scheme && !scheme.readOnly) {
            try {
                scheme.setEditorFontSize(fontSize)
            } catch (Exception ex) {
                System.err.println("Could not set font size for scheme ${scheme.name}: ${ex.message}")
            }
        }
    }

    // Also for global scheme
    def globalScheme = editorColorsManager?.globalScheme
    if (globalScheme && !globalScheme.readOnly) {
        try {
            globalScheme.setEditorFontSize(fontSize)
        } catch (Exception ex) {
            System.err.println("Could not set font size for global scheme: ${ex.message}")
        }
    }
}

/**
 * Update UI font settings
 * @param fontSize the font size to set
 */
static void updateUIFontSettings(int fontSize) {
    def uiSettings = UISettings.getInstance()

    if (uiSettings) {
        uiSettings.overrideLafFonts = true
        uiSettings.fontSize = fontSize as float
    } else {
        System.err.println('Warning: Could not access UI settings')
    }
}

/**
 * Trigger UI and editor refresh to apply changes immediately
 */
static void refreshUIAndEditors() {
    // Refresh UI (menus, tool windows)
    LafManager.getInstance()?.updateUI()

    // Refresh all open editors to apply font changes
    def editorFactory = EditorFactory.getInstance()
    if (editorFactory) {
        try {
            editorFactory.refreshAllEditors()
        } catch (Exception ex) {
            System.err.println("Could not refresh editors: ${ex.message}")
        }
    }

    // Notify that color scheme changed
    def editorColorsManager = EditorColorsManager.getInstance()
    if (editorColorsManager) {
        try {
            ApplicationManager.application.messageBus
                .syncPublisher(EditorColorsManager.TOPIC)
                .globalSchemeChange(editorColorsManager.globalScheme)
        } catch (Exception ex) {
            System.err.println("Could not notify scheme change: ${ex.message}")
        }
    }
}

/**
 * Main execution logic
 */
static void updateFontSizes() {
    def fontSize = getFontSize()

    try {
        updateEditorFontOptions(fontSize)
        syncColorSchemeFonts(fontSize)
        updateUIFontSettings(fontSize)
        refreshUIAndEditors()
    } catch (Exception ex) {
        System.err.println("Error updating font sizes: ${ex.message}")
        ex.printStackTrace()
    }
}

// Execute on Event Dispatch Thread
ApplicationManager.application?.invokeLater {
    updateFontSizes()
}
