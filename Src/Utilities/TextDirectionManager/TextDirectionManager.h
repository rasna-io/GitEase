#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QQuickTextDocument>

class QTextDocument;

/**
 * @brief Keeps the code in the diff and conflict editors laid out left to right.
 *
 * A TextEdit takes the direction of a line from its first letter. A line without letters, such
 * as "{", "}" or "2", falls back to the keyboard layout, so under a Persian or Arabic layout it is
 * laid out right to left: brackets come out mirrored and, in an editor wider than its text, the
 * line is pushed to the far edge, out of view. Code reads left to right whatever the keyboard.
 */
class TextDirectionManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit TextDirectionManager(QObject *parent = nullptr);

    /**
     * @brief Lays out every line of @p document left to right, now and as lines come in.
     *
     * Call it once per editor when the editor is created, from its Component.onCompleted with its
     * textDocument. The text and the undo history stay as they are, and the editor reports no
     * textChanged() for it.
     */
    Q_INVOKABLE void keepLeftToRight(QQuickTextDocument *document);

    /**
     * @brief Lays out the lines of @p document that touch [@p from, @p from + @p length] left to
     * right. A negative @p length runs to the end of the document.
     */
    static void pinLines(QTextDocument *document, int from = 0, int length = -1);
};
