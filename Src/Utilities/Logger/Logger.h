#pragma once

#include "Formatter.h"
#include "Level.h"
#include "Record.h"
#include "Sink.h"

#include <QByteArray>
#include <QDebug>
#include <QString>

#include <atomic>
#include <condition_variable>
#include <deque>
#include <memory>
#include <mutex>
#include <shared_mutex>
#include <thread>
#include <vector>

namespace Log
{
    class FileSink;

    /** \brief Everything Logger::start() needs, every field has a sensible default */
    struct Config
    {
        // Used in the log file names, defaults to QCoreApplication::applicationName()
        QString appName;

        // Defaults to "<AppDataLocation>/logs", overridden by the LOGGER_DIR variable
        QString directory;

        // Global threshold, overridden by the LOGGER_LEVEL variable
#if defined(QT_NO_DEBUG)
        Level level = Level::Info;
#else
        Level level = Level::Debug;
#endif

        // Per category thresholds as "pattern=level" entries separated by ';' or new lines,
        // e.g. "Git=trace;qt.*=warning;qml=off". Overridden by the LOGGER_RULES variable.
        QString filterRules;

        bool console = true;
        bool file = true;

        // One JSON object per line instead of the text pattern
        bool json = false;

        // See PatternFormatter, ignored when json is set
        QString pattern = PatternFormatter::defaultPattern();

        // Start a new file after this many lines, 0 disables the limit
        int maxLinesPerFile = 2000;

        // Safety cap for a single file in bytes, for records with very long lines
        qint64 maxFileSize = 10 * 1024 * 1024;

        // Sessions kept on disk. A session spans several files when it passes maxLinesPerFile.
        int maxSessions = 5;

        // Sessions older than this are removed, 0 disables the limit
        int maxAgeDays = 30;

        // Route qDebug(), qWarning(), qCDebug() and QML console.log() into the logger
        bool captureQtMessages = true;

        // Keep calling the Qt message handler that was installed before the logger
        bool chainPreviousHandler = true;

        // Log std::terminate(), unhandled exceptions on Windows and fatal signals on Linux.
        // On Linux the signal report goes to stderr and to "<app>.crash.log" in the log directory.
        bool installCrashHandlers = true;

        // Records kept in memory while the worker thread is busy, the oldest ones are dropped
        int queueCapacity = 20000;
    };

    /**
     * \brief Process wide, thread-safe, asynchronous logger
     *
     * Calling threads only build a Record and push it on a bounded queue. A worker thread formats
     * and writes the records to the sinks, so logging never blocks on disk I/O. Records of level
     * Critical and above are flushed before log() returns, so the last words before a crash reach
     * the disk.
     *
     * \code
     *   QGuiApplication app(argc, argv);
     *   Log::Logger::instance().start();
     *
     *   LOGGER_INFO("Git") << "opened" << path;
     *
     *   Log::Logger::instance().shutdown();
     * \endcode
     */
    class Logger
    {
    public:
        static Logger &instance();

        Logger(const Logger &) = delete;
        Logger &operator=(const Logger &) = delete;

        /**
         * \brief Creates the sinks, starts the worker thread and installs the Qt message handler
         *
         * Call it after the QCoreApplication exists, so the application name and the data location
         * are known. A file that cannot be opened is reported on stderr and the logger goes on
         * without it.
         * \return false when the logger is already running
         */
        bool start(const Config &config = Config());

        /**
         * \brief Drains the queue, flushes and removes the sinks and uninstalls all hooks
         *
         * The logger can be started again afterwards. It is also called at process exit.
         */
        void shutdown();

        bool isRunning() const;

        void setLevel(Level level);
        Level level() const;

        /** \brief Adds a "pattern=level" rule, later rules win and '*' matches any characters */
        void setCategoryLevel(const QString &pattern, Level level);

        /** \brief Replaces all category rules, e.g. "a=debug;b.*=off" */
        void setFilterRules(const QString &rules);
        void clearFilterRules();

        /** \brief Cheap check used by the macros, so disabled messages cost almost nothing */
        bool isEnabled(Level level, const char *category) const;

        void addSink(std::shared_ptr<ISink> sink);
        void removeSink(const std::shared_ptr<ISink> &sink);

        /** \brief File written by the built-in file sink, empty when there is none */
        QString currentLogFile() const;
        QString logDirectory() const;

        void log(Level level,
                 const char *category,
                 const QString &message,
                 const char *file = nullptr,
                 int line = 0,
                 const char *function = nullptr);

        /** \brief Overload for callers that own the category as a string (QML, plugins) */
        void log(Level level,
                 const QString &category,
                 const QString &message,
                 const char *file = nullptr,
                 int line = 0,
                 const char *function = nullptr);

        /** \brief Blocks until every record logged before this call reached the sinks */
        bool flush(int timeoutMs = 5000);

        /** \brief Number of records discarded because the queue was full */
        quint64 droppedCount() const;

    private:
        Logger() = default;
        ~Logger() = default;

        struct Rule
        {
            QByteArray pattern;
            Level level = Level::Info;
        };

        void enqueue(Record &&record);
        void workerLoop();
        void installHooks(const Config &config);
        void removeHooks();
        Level effectiveLevel(const char *category) const;
        std::vector<std::shared_ptr<ISink>> sinksSnapshot() const;

        static void qtMessageHandler(QtMsgType type,
                                     const QMessageLogContext &context,
                                     const QString &message);
        static void terminateHandler();

        std::atomic<bool> m_running { false };
        std::atomic<int> m_level { static_cast<int>(Level::Debug) };
        std::atomic<bool> m_hasRules { false };

        mutable std::shared_mutex m_rulesMutex;
        std::vector<Rule> m_rules;

        mutable std::mutex m_sinksMutex;
        std::vector<std::shared_ptr<ISink>> m_sinks;
        std::shared_ptr<ISink> m_consoleSink;
        std::shared_ptr<FileSink> m_fileSink;
        QString m_directory;

        std::mutex m_lifecycleMutex;
        std::mutex m_queueMutex;
        std::condition_variable m_queueCv;
        std::condition_variable m_processedCv;
        std::deque<Record> m_queue;
        quint64 m_enqueued = 0;
        quint64 m_processed = 0;
        std::atomic<quint64> m_dropped { 0 };
        std::atomic<quint64> m_droppedReported { 0 };
        size_t m_capacity = 20000;
        bool m_stopRequested = false;

        std::thread m_worker;

        bool m_qtHandlerInstalled = false;
        bool m_crashHandlersInstalled = false;
        bool m_chainPrevious = true;
    };

    /**
     * \brief Streaming front-end of the LOGGER_* macros
     *
     * Collects the message with QDebug, so every type that supports `qDebug() <<` works, and
     * submits it when the temporary is destroyed.
     */
    class LogStream
    {
    public:
        LogStream(Level level,
                  const char *category,
                  const char *file,
                  int line,
                  const char *function);
        ~LogStream();

        LogStream(const LogStream &) = delete;
        LogStream &operator=(const LogStream &) = delete;

        template<typename T>
        LogStream &operator<<(const T &value)
        {
            *m_debug << value;
            return *this;
        }

        /** \brief Switches off the automatic space between streamed values */
        LogStream &nospace();

    private:
        Level m_level;
        const char *m_category;
        const char *m_file;
        int m_line;
        const char *m_function;
        QString m_buffer;
        std::unique_ptr<QDebug> m_debug;
    };
} // namespace Log

// LOGGER_INFO("Category") << "text" << value;
//
// The streamed expressions are not evaluated when the level is disabled.
#define LOGGER_AT(level, category) \
    if(!::Log::Logger::instance().isEnabled((level), (category))) \
    { \
    } \
    else \
        ::Log::LogStream((level), (category), __FILE__, __LINE__, Q_FUNC_INFO)

#define LOGGER_TRACE(category) LOGGER_AT(::Log::Level::Trace, category)
#define LOGGER_DEBUG(category) LOGGER_AT(::Log::Level::Debug, category)
#define LOGGER_INFO(category) LOGGER_AT(::Log::Level::Info, category)
#define LOGGER_WARNING(category) LOGGER_AT(::Log::Level::Warning, category)
#define LOGGER_ERROR(category) LOGGER_AT(::Log::Level::Error, category)
#define LOGGER_CRITICAL(category) LOGGER_AT(::Log::Level::Critical, category)

// Logs, flushes and aborts the process, like qFatal()
#define LOGGER_FATAL(category) LOGGER_AT(::Log::Level::Fatal, category)
