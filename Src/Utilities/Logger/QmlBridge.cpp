#include "QmlBridge.h"

#include "LogModel.h"
#include "Logger.h"

#include <QtQml/qqml.h>

namespace Log
{
    namespace
    {
        const QString kDefaultCategory = QStringLiteral("qml");

        Log::Level toLevel(int value)
        {
            return static_cast<Log::Level>(qBound(static_cast<int>(Log::Level::Trace),
                                                  value,
                                                  static_cast<int>(Log::Level::Off)));
        }
    } // namespace

    QmlLog::QmlLog(QObject *parent)
        : QObject(parent)
    {
    }

    QmlLog *QmlLog::instance()
    {
        // Created on first use (in the GUI thread) and owned by the C++ side
        static QmlLog *bridge = new QmlLog();
        return bridge;
    }

    int QmlLog::level() const
    {
        return static_cast<int>(Logger::instance().level());
    }

    void QmlLog::setLevel(int level)
    {
        const Log::Level converted = toLevel(level);

        if(converted == Logger::instance().level())
        {
            return;
        }

        Logger::instance().setLevel(converted);
        emit levelChanged();
    }

    QString QmlLog::currentLogFile() const
    {
        return Logger::instance().currentLogFile();
    }

    QString QmlLog::logDirectory() const
    {
        return Logger::instance().logDirectory();
    }

    void QmlLog::log(int level, const QString &category, const QString &message)
    {
        Logger::instance().log(toLevel(level), category, message);
    }

    void QmlLog::trace(const QString &category, const QString &message)
    {
        Logger::instance().log(Log::Level::Trace, category, message);
    }

    void QmlLog::trace(const QString &message)
    {
        Logger::instance().log(Log::Level::Trace, kDefaultCategory, message);
    }

    void QmlLog::debug(const QString &category, const QString &message)
    {
        Logger::instance().log(Log::Level::Debug, category, message);
    }

    void QmlLog::debug(const QString &message)
    {
        Logger::instance().log(Log::Level::Debug, kDefaultCategory, message);
    }

    void QmlLog::info(const QString &category, const QString &message)
    {
        Logger::instance().log(Log::Level::Info, category, message);
    }

    void QmlLog::info(const QString &message)
    {
        Logger::instance().log(Log::Level::Info, kDefaultCategory, message);
    }

    void QmlLog::warning(const QString &category, const QString &message)
    {
        Logger::instance().log(Log::Level::Warning, category, message);
    }

    void QmlLog::warning(const QString &message)
    {
        Logger::instance().log(Log::Level::Warning, kDefaultCategory, message);
    }

    void QmlLog::error(const QString &category, const QString &message)
    {
        Logger::instance().log(Log::Level::Error, category, message);
    }

    void QmlLog::error(const QString &message)
    {
        Logger::instance().log(Log::Level::Error, kDefaultCategory, message);
    }

    void QmlLog::critical(const QString &category, const QString &message)
    {
        Logger::instance().log(Log::Level::Critical, category, message);
    }

    void QmlLog::critical(const QString &message)
    {
        Logger::instance().log(Log::Level::Critical, kDefaultCategory, message);
    }

    void QmlLog::flush()
    {
        Logger::instance().flush();
    }

    void registerQmlTypes()
    {
        qmlRegisterSingletonInstance("Logger", 1, 0, "Log", QmlLog::instance());
        qmlRegisterType<LogModel>("Logger", 1, 0, "LogModel");
    }
} // namespace Log
