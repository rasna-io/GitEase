#include "TextDirectionManager.h"

#include <QSignalBlocker>
#include <QTextBlock>
#include <QTextBlockFormat>
#include <QTextCursor>
#include <QTextDocument>

static constexpr const char* KEEPER_NAME = "TextDirectionManager.keeper";

TextDirectionManager::TextDirectionManager(QObject *parent)
    : QObject(parent)
{
}

void TextDirectionManager::keepLeftToRight(QQuickTextDocument *document)
{
    QTextDocument *textDocument = document ? document->textDocument() : nullptr;
    if (!textDocument)
        return;

    {
        // The editor would report the new direction as a textChanged() with the same text.
        const QSignalBlocker blocker(textDocument);
        pinLines(textDocument);
    }

    if (textDocument->findChild<QObject *>(QLatin1String(KEEPER_NAME), Qt::FindDirectChildrenOnly))
        return;

    // A child of the document, so the connection ends with it.
    auto *keeper = new QObject(textDocument);
    keeper->setObjectName(QLatin1String(KEEPER_NAME));

    // A new text arrives with lines of automatic direction, and so do the lines the user adds.
    connect(textDocument, &QTextDocument::contentsChange, keeper,
            [textDocument](int position, int /*charsRemoved*/, int charsAdded) {
                pinLines(textDocument, position, charsAdded);
            });
}

void TextDirectionManager::pinLines(QTextDocument *document, int from, int length)
{
    if (!document)
        return;

    const int to = length < 0 ? document->characterCount() : from + length;

    QTextBlock block = document->findBlock(from);
    while (block.isValid() && block.position() <= to
           && block.blockFormat().layoutDirection() == Qt::LeftToRight)
        block = block.next();

    if (!block.isValid() || block.position() > to)
        return;

    const bool freshText   = !document->isUndoAvailable();
    const bool undoEnabled = document->isUndoRedoEnabled();
    if (freshText)
        document->setUndoRedoEnabled(false);

    QTextBlockFormat leftToRight;
    leftToRight.setLayoutDirection(Qt::LeftToRight);

    QTextCursor cursor(document);
    if (freshText)
        cursor.beginEditBlock();
    else
        cursor.joinPreviousEditBlock();

    for (; block.isValid() && block.position() <= to; block = block.next()) {
        if (block.blockFormat().layoutDirection() == Qt::LeftToRight)
            continue;

        cursor.setPosition(block.position());
        cursor.mergeBlockFormat(leftToRight);
    }

    cursor.endEditBlock();

    if (freshText)
        document->setUndoRedoEnabled(undoEnabled);
}
