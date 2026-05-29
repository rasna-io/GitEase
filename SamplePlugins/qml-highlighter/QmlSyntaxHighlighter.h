#pragma once

#include <QSyntaxHighlighter>
#include <QTextCharFormat>
#include <QRegularExpression>
#include <QObject>
#include <QQuickTextDocument>

class QmlSyntaxHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT
    // Bind directly to TextEdit/TextArea.textDocument in QML
    Q_PROPERTY(QQuickTextDocument* textDocument
               READ  textDocument
               WRITE setTextDocument
               NOTIFY textDocumentChanged)

public:
    explicit QmlSyntaxHighlighter(QObject* parent = nullptr);

    QQuickTextDocument* textDocument() const;
    void setTextDocument(QQuickTextDocument* doc);

signals:
    void textDocumentChanged();

protected:
    void highlightBlock(const QString& text) override;

private:
    struct Rule {
        QRegularExpression pattern;
        QTextCharFormat    format;
    };

    void addKeywords(const QStringList& words, const QTextCharFormat& fmt);

    QList<Rule>         m_rules;

    // Multi-line comment state
    QTextCharFormat     m_multiLineCommentFmt;
    QRegularExpression  m_commentStart { QStringLiteral("/\\*") };
    QRegularExpression  m_commentEnd   { QStringLiteral("\\*/") };

    QQuickTextDocument* m_quickDoc = nullptr;
};
