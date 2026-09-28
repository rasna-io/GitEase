#pragma once

#include <QColor>
#include <QObject>
#include <QStringList>

namespace CodeViewer { struct Language; }

/*!
 * \brief Turns source lines into rich text for the host diff and file views.
 *
 * The language comes from the file name (extension, well-known names such as Makefile, or the
 * shebang). Dark host themes use the One Dark palette and light ones GitHub Light.
 */
class SyntaxColorizer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool   dark            READ dark            WRITE setDark            NOTIFY changed)
    Q_PROPERTY(QColor plainColor      READ plainColor      WRITE setPlainColor      NOTIFY changed)
    Q_PROPERTY(bool   rainbowBrackets READ rainbowBrackets WRITE setRainbowBrackets NOTIFY changed)

public:
    explicit SyntaxColorizer(QObject *parent = nullptr);

    bool   dark() const { return m_dark; }
    void   setDark(bool dark);
    QColor plainColor() const { return m_plainColor; }
    void   setPlainColor(const QColor &color);
    bool   rainbowBrackets() const { return m_rainbow; }
    void   setRainbowBrackets(bool enabled);

    //! One line in isolation; multi-line comments and strings are only known to colorizeLines().
    Q_INVOKABLE QString colorize(const QString &text, const QString &filePath) const;

    //! Whole file, carrying multi-line comments, strings and bracket depth from line to line.
    Q_INVOKABLE QStringList colorizeLines(const QStringList &lines, const QString &filePath) const;

    //! Display name of the language used for \a filePath, e.g. "TypeScript".
    Q_INVOKABLE QString languageName(const QString &filePath) const;

signals:
    void changed();

private:
    const CodeViewer::Language &languageFor(const QString &filePath, const QString &firstLine) const;

    bool   m_dark    = false;
    bool   m_rainbow = true;
    QColor m_plainColor;

    mutable QString                     m_cachedPath;
    mutable const CodeViewer::Language *m_cachedLanguage = nullptr;
};
