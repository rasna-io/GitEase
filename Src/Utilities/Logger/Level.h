#pragma once

#include <QString>
#include <QStringView>
#include <QtGlobal>

#include <optional>

namespace Log
{
    /**
     * \brief Severity of a record, from the most verbose to the most severe
     *
     * Off is only a threshold value that disables a category or the whole logger, it is not a
     * valid record level. Fatal records are never suppressed.
     */
    enum class Level : int
    {
        Trace = 0,
        Debug,
        Info,
        Warning,
        Error,
        Critical,
        Fatal,
        Off
    };

    /** \brief Upper-case name, e.g. "WARNING" */
    QString levelName(Level level);

    /** \brief Upper-case name padded to 5 characters, e.g. "WARN " */
    QString levelShortName(Level level);

    /** \brief Case-insensitive parse, "warn" and "warning" are both accepted */
    std::optional<Level> parseLevel(QStringView text);

    /**
     * \brief Maps a Qt message type to a level
     *
     * QtCriticalMsg becomes Level::Error, because Qt uses it for ordinary runtime errors.
     * Level::Critical is reserved for explicit use through the logger API.
     */
    Level levelFromQtMsgType(QtMsgType type);

    /** \brief ANSI foreground color escape sequence used by the console sink */
    const char *levelAnsiColor(Level level);
} // namespace Log
