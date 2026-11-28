import QtQuick

import GitEase_Style
import GitEaseSyntaxColors

/*! ***********************************************************************************************
 * Colorizer
 * Loaded by the host for the diff and commit file views. colorize() handles one line;
 * colorizeLines() handles a whole file so block comments and strings span lines correctly.
 * ************************************************************************************************/
Item {
    id: root

    visible: false

    function colorize(text, filePath) {
        return engine.colorize(text || "", filePath || "")
    }

    function colorizeLines(lines, filePath) {
        return engine.colorizeLines(lines || [], filePath || "")
    }

    SyntaxColorizer {
        id: engine
        dark: Style.theme === Style.Theme.Dark
        plainColor: Style.colors.editorForeground
    }
}
