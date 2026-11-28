#pragma once

#include "Level.h"

#include <QObject>
#include <QString>

namespace Log
{
    /**
     * \brief QML singleton, available as `Log` after `import Logger`
     *
     * \code
     *   Log.info("Git", "repository opened")
     *   Log.warning("something odd")    // the category defaults to "qml"
     *   Log.level = Log.Debug
     * \endcode
     *
     * console.log() and friends need no bridge, they are Qt messages and are captured by the
     * message handler.
     */
    class QmlLog : public QObject
    {
        Q_OBJECT
        Q_PROPERTY(int level READ level WRITE setLevel NOTIFY levelChanged)
        Q_PROPERTY(QString currentLogFile READ currentLogFile)
        Q_PROPERTY(QString logDirectory READ logDirectory)

    public:
        enum Level
        {
            Trace = static_cast<int>(Log::Level::Trace),
            Debug = static_cast<int>(Log::Level::Debug),
            Info = static_cast<int>(Log::Level::Info),
            Warning = static_cast<int>(Log::Level::Warning),
            Error = static_cast<int>(Log::Level::Error),
            Critical = static_cast<int>(Log::Level::Critical),
            Off = static_cast<int>(Log::Level::Off)
        };
        Q_ENUM(Level)

        static QmlLog *instance();

        int level() const;
        void setLevel(int level);

        QString currentLogFile() const;
        QString logDirectory() const;

        Q_INVOKABLE void log(int level, const QString &category, const QString &message);

        Q_INVOKABLE void trace(const QString &category, const QString &message);
        Q_INVOKABLE void trace(const QString &message);
        Q_INVOKABLE void debug(const QString &category, const QString &message);
        Q_INVOKABLE void debug(const QString &message);
        Q_INVOKABLE void info(const QString &category, const QString &message);
        Q_INVOKABLE void info(const QString &message);
        Q_INVOKABLE void warning(const QString &category, const QString &message);
        Q_INVOKABLE void warning(const QString &message);
        Q_INVOKABLE void error(const QString &category, const QString &message);
        Q_INVOKABLE void error(const QString &message);
        Q_INVOKABLE void critical(const QString &category, const QString &message);
        Q_INVOKABLE void critical(const QString &message);

        Q_INVOKABLE void flush();

    signals:
        void levelChanged();

    private:
        explicit QmlLog(QObject *parent = nullptr);
    };

    /**
     * \brief Registers the `Logger` QML module (singleton `Log` and the `LogModel` type)
     *
     * Call it once, before the QML engine loads a file that imports the module.
     */
    void registerQmlTypes();
} // namespace Log
