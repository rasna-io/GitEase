#include "SyntaxColorizer.h"

#include "Tokenizer.h"

using namespace CodeViewer;

namespace {

void appendEscaped(QString &out, QStringView text)
{
    for (const QChar c : text) {
        switch (c.unicode()) {
        case '&':  out += QLatin1String("&amp;");  break;
        case '<':  out += QLatin1String("&lt;");   break;
        case '>':  out += QLatin1String("&gt;");   break;
        case '"':  out += QLatin1String("&quot;"); break;
        case ' ':  out += QLatin1String("&nbsp;"); break;
        case '\t': out += QLatin1String("&nbsp;&nbsp;&nbsp;&nbsp;"); break;
        case '\r': break;
        default:   out += c;
        }
    }
}

QString toRichText(const QString &text, const QVector<Token> &tokens, const Theme &theme, const QColor &plain)
{
    QString out;
    out.reserve(text.size() * 3);

    int runStart = 0;
    for (int k = 1; k <= text.size(); ++k) {
        if (k < text.size() && tokens[k] == tokens[runStart])
            continue;

        const Token token = tokens[runStart];
        const QStringView run = QStringView(text).mid(runStart, k - runStart);
        const QColor color = token == Plain ? plain : theme.tokens[token];
        const bool italic = token == Comment && theme.italicComments;
        const bool bold = (token == Keyword && theme.boldKeywords) || token == Heading;

        if (bold)
            out += QLatin1String("<b>");
        if (italic)
            out += QLatin1String("<i>");
        if (color.isValid()) {
            out += QLatin1String("<font color=\"") + color.name() + QLatin1String("\">");
            appendEscaped(out, run);
            out += QLatin1String("</font>");
        } else {
            appendEscaped(out, run);
        }
        if (italic)
            out += QLatin1String("</i>");
        if (bold)
            out += QLatin1String("</b>");

        runStart = k;
    }
    return out;
}

} // namespace

SyntaxColorizer::SyntaxColorizer(QObject *parent)
    : QObject(parent)
{
}

void SyntaxColorizer::setDark(bool dark)
{
    if (m_dark == dark)
        return;
    m_dark = dark;
    emit changed();
}

void SyntaxColorizer::setPlainColor(const QColor &color)
{
    if (m_plainColor == color)
        return;
    m_plainColor = color;
    emit changed();
}

void SyntaxColorizer::setRainbowBrackets(bool enabled)
{
    if (m_rainbow == enabled)
        return;
    m_rainbow = enabled;
    emit changed();
}

const Language &SyntaxColorizer::languageFor(const QString &filePath, const QString &firstLine) const
{
    if (!m_cachedLanguage || m_cachedPath != filePath) {
        const QString fileName = filePath.section(QLatin1Char('/'), -1).section(QLatin1Char('\\'), -1);
        m_cachedLanguage = findLanguage(detectLanguage(fileName, firstLine));
        if (!m_cachedLanguage)
            m_cachedLanguage = findLanguage(QStringLiteral("plaintext"));
        m_cachedPath = filePath;
    }
    return *m_cachedLanguage;
}

QString SyntaxColorizer::colorize(const QString &text, const QString &filePath) const
{
    const Language &language = languageFor(filePath, QString());
    const Theme &theme = findTheme(m_dark ? QStringLiteral("one-dark") : QStringLiteral("github-light"));
    LineState state;
    return toRichText(text, tokenizeLine(language, text, state, m_rainbow), theme, m_plainColor);
}

QStringList SyntaxColorizer::colorizeLines(const QStringList &lines, const QString &filePath) const
{
    m_cachedLanguage = nullptr;
    const Language &language = languageFor(filePath, lines.isEmpty() ? QString() : lines.first());
    const Theme &theme = findTheme(m_dark ? QStringLiteral("one-dark") : QStringLiteral("github-light"));

    QStringList out;
    out.reserve(lines.size());
    LineState state;
    for (const QString &line : lines)
        out.append(toRichText(line, tokenizeLine(language, line, state, m_rainbow), theme, m_plainColor));
    return out;
}

QString SyntaxColorizer::languageName(const QString &filePath) const
{
    return languageFor(filePath, QString()).name;
}
