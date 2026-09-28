#include "Tokenizer.h"

namespace CodeViewer {

namespace {

constexpr int kMaxDepth = 0xFFFF;

const QRegularExpression &numberPattern()
{
    static const QRegularExpression re(QStringLiteral(
        R"(0[xX][0-9a-fA-F_]+[uUlLnN]*|0[bB][01_]+[uUlLnN]*|0[oO][0-7_]+|(?:\d[\d_']*)?\.?\d[\d_']*(?:[eE][+-]?\d+)?[a-zA-Z%]*)"));
    return re;
}

bool startsWithAt(const QString &text, int pos, const QString &needle)
{
    return !needle.isEmpty() && QStringView(text).mid(pos).startsWith(needle);
}

bool isAllCaps(QStringView word)
{
    bool letter = false;
    for (const QChar c : word) {
        if (c.isLower())
            return false;
        if (c.isLetter())
            letter = true;
    }
    return letter && word.size() > 1;
}

void scan(const Language &lang, const QString &text, QVector<Token> &tokens, LineState &state, bool rainbow)
{
    const int n = text.size();
    int i = 0;

    auto fill = [&tokens](int from, int to, Token token) {
        for (int k = from; k < to; ++k)
            tokens[k] = token;
    };

    auto isIdentChar = [&lang](QChar c) {
        return c.isLetterOrNumber() || c == QLatin1Char('_') || lang.identExtra.contains(c);
    };
    auto isIdentStart = [&lang](QChar c) {
        return c.isLetter() || c == QLatin1Char('_') || (lang.identExtra.contains(c) && !c.isDigit());
    };

    // End of a block when the search starts at `from`; -1 when it continues on the next line.
    auto blockEnd = [&text, n](const Block &block, int from) {
        int j = from;
        while (j < n) {
            if (block.escapes && text[j] == QLatin1Char('\\')) {
                j += 2;
                continue;
            }
            if (startsWithAt(text, j, block.end))
                return j + int(block.end.size());
            ++j;
        }
        return -1;
    };

    auto markEscapes = [&](int from, int to) {
        if (!lang.stringEscapes)
            return;
        for (int k = from; k < to - 1; ++k) {
            if (text[k] == QLatin1Char('\\')) {
                tokens[k] = Escape;
                tokens[k + 1] = Escape;
                ++k;
            }
        }
    };

    // Continue a region opened on a previous line
    if (state.block >= 0 && state.block < lang.blocks.size()) {
        const Block &block = lang.blocks[state.block];
        const int end = blockEnd(block, 0);
        if (end < 0) {
            fill(0, n, block.token);
            if (block.token == String && block.escapes)
                markEscapes(0, n);
            return;
        }
        fill(0, end, block.token);
        if (block.token == String && block.escapes)
            markEscapes(0, end);
        i = end;
    }
    state.block = -1;

    while (i < n) {
        const QChar c = text[i];

        // Multi-line regions (checked first so "--[[" beats the "--" line comment)
        bool matched = false;
        for (int b = 0; b < lang.blocks.size(); ++b) {
            const Block &block = lang.blocks[b];
            if (!startsWithAt(text, i, block.start))
                continue;
            if (block.lineStart && !QStringView(text).left(i).trimmed().isEmpty())
                continue;
            const int end = blockEnd(block, i + int(block.start.size()));
            const int stop = end < 0 ? n : end;
            fill(i, stop, block.token);
            if (block.token == String && block.escapes)
                markEscapes(i + int(block.start.size()), stop);
            if (end < 0)
                state.block = b;
            i = stop;
            matched = true;
            break;
        }
        if (matched)
            continue;

        // Line comments
        for (const QString &comment : lang.lineComments) {
            if (!startsWithAt(text, i, comment))
                continue;
            if (lang.commentNeedsSpace && i > 0 && !text[i - 1].isSpace())
                continue;
            fill(i, n, Comment);
            i = n;
            matched = true;
            break;
        }
        if (matched)
            break;

        // Single-line strings
        for (const QString &quote : lang.quotes) {
            if (!startsWithAt(text, i, quote))
                continue;
            int j = i + int(quote.size());
            while (j < n) {
                if (lang.stringEscapes && text[j] == QLatin1Char('\\')) {
                    j += 2;
                    continue;
                }
                if (startsWithAt(text, j, quote)) {
                    j += int(quote.size());
                    break;
                }
                ++j;
            }
            j = qMin(j, n);
            fill(i, j, String);
            markEscapes(i + 1, j - 1);
            i = j;
            matched = true;
            break;
        }
        if (matched)
            continue;

        // Numbers
        if (lang.numbers && (c.isDigit() || (c == QLatin1Char('.') && i + 1 < n && text[i + 1].isDigit()))
            && (i == 0 || !isIdentChar(text[i - 1]))) {
            const auto m = numberPattern().match(text, i, QRegularExpression::NormalMatch,
                                                 QRegularExpression::AnchorAtOffsetMatchOption);
            if (m.hasMatch() && m.capturedLength() > 0) {
                fill(i, i + m.capturedLength(), Number);
                i += m.capturedLength();
                continue;
            }
        }

        // Identifiers and keywords
        if (isIdentStart(c)) {
            int j = i + 1;
            while (j < n && isIdentChar(text[j]))
                ++j;
            const QStringView word = QStringView(text).mid(i, j - i);
            const QString key = lang.caseInsensitive ? word.toString().toLower() : word.toString();

            int next = j;
            while (next < n && text[next] == QLatin1Char(' '))
                ++next;
            int prev = i - 1;
            while (prev >= 0 && text[prev] == QLatin1Char(' '))
                --prev;

            Token token = Plain;
            if (lang.keywords.contains(key))
                token = Keyword;
            else if (lang.literals.contains(key))
                token = Constant;
            else if (lang.types.contains(key))
                token = Type;
            else if (lang.builtins.contains(key))
                token = Builtin;
            else if (lang.functions && next < n && text[next] == QLatin1Char('('))
                token = Function;
            else if (lang.members && prev >= 0 && text[prev] == QLatin1Char('.')
                     && !(prev > 0 && text[prev - 1] == QLatin1Char('.')))
                token = Property;
            else if (isAllCaps(word))
                token = Constant;
            else if (lang.upperTypes && word.front().isUpper())
                token = Type;

            fill(i, j, token);
            i = j;
            continue;
        }

        // Brackets, operators and punctuation
        if (lang.brackets && (c == QLatin1Char('(') || c == QLatin1Char('[') || c == QLatin1Char('{'))) {
            tokens[i] = rainbow ? Token(Bracket1 + state.depth % 3) : Punctuation;
            state.depth = qMin(state.depth + 1, kMaxDepth);
        } else if (lang.brackets && (c == QLatin1Char(')') || c == QLatin1Char(']') || c == QLatin1Char('}'))) {
            state.depth = qMax(state.depth - 1, 0);
            tokens[i] = rainbow ? Token(Bracket1 + state.depth % 3) : Punctuation;
        } else if (lang.operators && QStringLiteral("+-*/%=&|^!~<>?:@").contains(c)) {
            tokens[i] = Operator;
        } else if (lang.operators && QStringLiteral(",;.").contains(c)) {
            tokens[i] = Punctuation;
        }
        ++i;
    }
}

} // namespace

QVector<Token> tokenizeLine(const Language &language, const QString &text, LineState &state, bool rainbow)
{
    QVector<Token> tokens(text.size(), Plain);

    if (language.scan)
        scan(language, text, tokens, state, rainbow);

    for (const Overlay &overlay : language.overlays) {
        auto it = overlay.pattern.globalMatch(text);
        while (it.hasNext()) {
            const auto m = it.next();
            const int start = qMax(0, int(m.capturedStart(overlay.group)));
            const int end = qMin(int(tokens.size()), int(m.capturedEnd(overlay.group)));
            for (int k = start; k < end; ++k) {
                const Token current = tokens[k];
                const bool protectedString = (current == String || current == Escape || current == Code) && !overlay.overStrings;
                const bool protectedComment = current == Comment && !overlay.overComments;
                if (!protectedString && !protectedComment)
                    tokens[k] = overlay.token;
            }
        }
    }
    return tokens;
}

} // namespace CodeViewer
