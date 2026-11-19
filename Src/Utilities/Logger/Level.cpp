#include "Level.h"

namespace Log
{
    QString levelName(Level level)
    {
        switch(level)
        {
        case Level::Trace:
            return QStringLiteral("TRACE");
        case Level::Debug:
            return QStringLiteral("DEBUG");
        case Level::Info:
            return QStringLiteral("INFO");
        case Level::Warning:
            return QStringLiteral("WARNING");
        case Level::Error:
            return QStringLiteral("ERROR");
        case Level::Critical:
            return QStringLiteral("CRITICAL");
        case Level::Fatal:
            return QStringLiteral("FATAL");
        case Level::Off:
            return QStringLiteral("OFF");
        }

        return QStringLiteral("UNKNOWN");
    }

    QString levelShortName(Level level)
    {
        switch(level)
        {
        case Level::Trace:
            return QStringLiteral("TRACE");
        case Level::Debug:
            return QStringLiteral("DEBUG");
        case Level::Info:
            return QStringLiteral("INFO ");
        case Level::Warning:
            return QStringLiteral("WARN ");
        case Level::Error:
            return QStringLiteral("ERROR");
        case Level::Critical:
            return QStringLiteral("CRIT ");
        case Level::Fatal:
            return QStringLiteral("FATAL");
        case Level::Off:
            return QStringLiteral("OFF  ");
        }

        return QStringLiteral("?????");
    }

    std::optional<Level> parseLevel(QStringView text)
    {
        const QString value = text.trimmed().toString().toLower();

        if(value == QLatin1String("trace"))
        {
            return Level::Trace;
        }

        if(value == QLatin1String("debug"))
        {
            return Level::Debug;
        }

        if(value == QLatin1String("info"))
        {
            return Level::Info;
        }

        if(value == QLatin1String("warn") || value == QLatin1String("warning"))
        {
            return Level::Warning;
        }

        if(value == QLatin1String("error"))
        {
            return Level::Error;
        }

        if(value == QLatin1String("crit") || value == QLatin1String("critical"))
        {
            return Level::Critical;
        }

        if(value == QLatin1String("fatal"))
        {
            return Level::Fatal;
        }

        if(value == QLatin1String("off") || value == QLatin1String("none"))
        {
            return Level::Off;
        }

        return std::nullopt;
    }

    Level levelFromQtMsgType(QtMsgType type)
    {
        switch(type)
        {
        case QtDebugMsg:
            return Level::Debug;
        case QtInfoMsg:
            return Level::Info;
        case QtWarningMsg:
            return Level::Warning;
        case QtCriticalMsg:
            return Level::Error;
        case QtFatalMsg:
            return Level::Fatal;
        }

        return Level::Info;
    }

    const char *levelAnsiColor(Level level)
    {
        switch(level)
        {
        case Level::Trace:
            return "\x1b[90m";
        case Level::Debug:
            return "\x1b[36m";
        case Level::Info:
            return "\x1b[32m";
        case Level::Warning:
            return "\x1b[33m";
        case Level::Error:
            return "\x1b[31m";
        case Level::Critical:
            return "\x1b[1;31m";
        case Level::Fatal:
            return "\x1b[1;37;41m";
        case Level::Off:
            break;
        }

        return "";
    }
} // namespace Log
