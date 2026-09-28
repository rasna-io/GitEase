#pragma once

#include <QColor>
#include <QList>
#include <QRegularExpression>
#include <QSet>
#include <QString>
#include <QStringList>

namespace CodeViewer {

//! Highlighting categories. Themes assign a colour to each one.
enum Token : quint8 {
    Plain,
    Keyword,
    Type,
    Builtin,
    Function,
    String,
    Escape,
    Number,
    Comment,
    Constant,
    Variable,
    Property,
    Operator,
    Punctuation,
    Annotation,
    Tag,
    Attribute,
    Heading,
    Link,
    Inserted,
    Deleted,
    Code,
    Bracket1,
    Bracket2,
    Bracket3,
    TokenCount
};

//! Region spanning lines, e.g. a block comment or a triple-quoted string.
struct Block
{
    QString start;
    QString end;
    Token   token     = Comment;
    bool    escapes   = false;
    bool    lineStart = false;   //!< Only opens when nothing but whitespace precedes it
};

//! Regex painted after scanning, e.g. preprocessor lines, decorators or markup tags.
struct Overlay
{
    QRegularExpression pattern;
    Token              token        = Plain;
    int                group        = 0;
    bool               overStrings  = false;
    bool               overComments = false;
};

struct Language
{
    QString       id;
    QString       name;
    QColor        color;
    QStringList   extensions;
    QStringList   fileNames;

    QStringList   lineComments;
    QList<Block>  blocks;
    QStringList   quotes;
    QSet<QString> keywords;
    QSet<QString> types;
    QSet<QString> builtins;
    QSet<QString> literals;
    QList<Overlay> overlays;

    QString identExtra;          //!< Extra identifier characters, e.g. "$" or "-"
    bool    scan              = true;
    bool    caseInsensitive   = false;
    bool    upperTypes        = false;   //!< Capitalised identifiers are types
    bool    functions         = true;    //!< identifier( is a function call
    bool    members           = true;    //!< .identifier is a property
    bool    numbers           = true;
    bool    operators         = true;
    bool    brackets          = true;
    bool    commentNeedsSpace = false;   //!< Line comments must follow whitespace (shell "#")
    bool    stringEscapes     = true;    //!< Backslash escapes inside strings
};

struct Theme
{
    QString id;
    QString name;
    bool    dark = true;

    QColor background;
    QColor foreground;
    QColor gutter;
    QColor gutterText;
    QColor gutterActive;
    QColor currentLine;
    QColor selection;
    QColor panel;
    QColor border;
    QColor accent;
    QColor searchMatch;

    QColor tokens[TokenCount];
    bool   italicComments = true;
    bool   boldKeywords   = false;
};

const QList<Language> &languages();
const Language        *findLanguage(const QString &id);
QString                detectLanguage(const QString &fileName, const QString &firstLine);

const QList<Theme> &themes();
const Theme        &findTheme(const QString &id);

} // namespace CodeViewer
