#include "QmlSyntaxHighlighter.h"
#include <QFont>

// ── VSCode dark+ colour palette ───────────────────────────────────────────────
static constexpr auto CLR_KEYWORD  = "#569CD6"; // blue       — import, property …
static constexpr auto CLR_TYPE     = "#4EC9B0"; // teal       — Rectangle, Item …
static constexpr auto CLR_PROP     = "#9CDCFE"; // light blue — anchors.fill, id …
static constexpr auto CLR_STRING   = "#CE9178"; // salmon     — "text"
static constexpr auto CLR_NUMBER   = "#B5CEA8"; // pale green — 42, 3.14
static constexpr auto CLR_COMMENT  = "#6A9955"; // green      — // …   /* … */
static constexpr auto CLR_SPECIAL  = "#DCDCAA"; // yellow     — console, Math …
static constexpr auto CLR_SIGNAL   = "#C586C0"; // purple     — onClicked, onCompleted

QmlSyntaxHighlighter::QmlSyntaxHighlighter(QObject* parent)
    : QSyntaxHighlighter(parent)
{
    // ── 1. QML type names  (UpperCamelCase) ── teal ──────────────────────────
    {
        QTextCharFormat fmt;
        fmt.setForeground(QColor(CLR_TYPE));
        m_rules.append({ QRegularExpression(QStringLiteral("\\b[A-Z][a-zA-Z0-9]*\\b")), fmt });
    }

    // ── 2. Property / id names  (identifier before colon) ── light blue ──────
    {
        QTextCharFormat fmt;
        fmt.setForeground(QColor(CLR_PROP));
        // matches  anchors.fill:   id:   Layout.fillWidth:
        m_rules.append({
            QRegularExpression(QStringLiteral("\\b[a-z][a-zA-Z0-9.]*(?=\\s*:)")),
            fmt
        });
    }

    // ── 3. Built-in JS objects ── yellow ──────────────────────────────────────
    {
        QTextCharFormat fmt;
        fmt.setForeground(QColor(CLR_SPECIAL));
        addKeywords({ "console", "Math", "JSON", "Date", "Qt", "Object",
                      "Array", "parseInt", "parseFloat", "isNaN" }, fmt);
    }

    // ── 4. Signal handlers  (on + Uppercase) ── purple ───────────────────────
    {
        QTextCharFormat fmt;
        fmt.setForeground(QColor(CLR_SIGNAL));
        m_rules.append({
            QRegularExpression(QStringLiteral("\\bon[A-Z][a-zA-Z0-9]*\\b")),
            fmt
        });
    }

    // ── 5. Keywords ── blue bold ──────────────────────────────────────────────
    {
        QTextCharFormat fmt;
        fmt.setForeground(QColor(CLR_KEYWORD));
        fmt.setFontWeight(QFont::Bold);
        addKeywords({
            "import", "property", "signal", "function", "var", "let", "const",
            "if", "else", "for", "while", "do", "break", "continue", "return",
            "switch", "case", "default", "try", "catch", "finally", "throw",
            "new", "delete", "typeof", "instanceof", "in", "of",
            "true", "false", "null", "undefined", "this",
            "readonly", "required", "pragma", "as", "alias"
        }, fmt);
    }

    // ── 6. Numbers ── pale green ──────────────────────────────────────────────
    {
        QTextCharFormat fmt;
        fmt.setForeground(QColor(CLR_NUMBER));
        m_rules.append({
            QRegularExpression(QStringLiteral("\\b(0x[0-9A-Fa-f]+|\\d+\\.?\\d*)\\b")),
            fmt
        });
    }

    // ── 7. Strings  (double & single quote, last wins so they beat keywords) ─
    {
        QTextCharFormat fmt;
        fmt.setForeground(QColor(CLR_STRING));
        m_rules.append({ QRegularExpression(QStringLiteral("\"(?:[^\"\\\\]|\\\\.)*\"")), fmt });
        m_rules.append({ QRegularExpression(QStringLiteral("'(?:[^'\\\\]|\\\\.)*'")),   fmt });
        // Template literals
        m_rules.append({ QRegularExpression(QStringLiteral("`[^`]*`")), fmt });
    }

    // ── 8. Single-line comment  //  (overrides everything above) ─────────────
    {
        QTextCharFormat fmt;
        fmt.setForeground(QColor(CLR_COMMENT));
        fmt.setFontItalic(true);
        m_rules.append({ QRegularExpression(QStringLiteral("//[^\n]*")), fmt });
    }

    // ── Multi-line comment format  /* … */ ────────────────────────────────────
    m_multiLineCommentFmt.setForeground(QColor(CLR_COMMENT));
    m_multiLineCommentFmt.setFontItalic(true);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

void QmlSyntaxHighlighter::addKeywords(const QStringList& words,
                                        const QTextCharFormat& fmt)
{
    for (const QString& w : words)
        m_rules.append({ QRegularExpression(QStringLiteral("\\b") + w + QStringLiteral("\\b")), fmt });
}

// ── textDocument property ─────────────────────────────────────────────────────

QQuickTextDocument* QmlSyntaxHighlighter::textDocument() const { return m_quickDoc; }

void QmlSyntaxHighlighter::setTextDocument(QQuickTextDocument* doc)
{
    if (m_quickDoc == doc) return;
    m_quickDoc = doc;
    QSyntaxHighlighter::setDocument(doc ? doc->textDocument() : nullptr);
    emit textDocumentChanged();
}

// ── Core highlighting ─────────────────────────────────────────────────────────

void QmlSyntaxHighlighter::highlightBlock(const QString& text)
{
    // Apply rules in order (later rules override earlier ones for same chars)
    for (const auto& rule : std::as_const(m_rules)) {
        auto it = rule.pattern.globalMatch(text);
        while (it.hasNext()) {
            const auto m = it.next();
            setFormat(m.capturedStart(), m.capturedLength(), rule.format);
        }
    }

    // ── Multi-line comment state machine ─────────────────────────────────────
    setCurrentBlockState(0);
    int start = (previousBlockState() == 1) ? 0
                : text.indexOf(m_commentStart);

    while (start >= 0) {
        const auto endMatch = m_commentEnd.match(text, start);
        const int  end      = endMatch.hasMatch() ? endMatch.capturedStart() : -1;

        if (end == -1) {
            setCurrentBlockState(1);
            setFormat(start, text.length() - start, m_multiLineCommentFmt);
            break;
        }
        const int len = end - start + endMatch.capturedLength();
        setFormat(start, len, m_multiLineCommentFmt);
        start = text.indexOf(m_commentStart, start + len);
    }
}
