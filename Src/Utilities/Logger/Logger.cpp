#include "Logger.h"

#include "ConsoleSink.h"
#include "FileSink.h"
#include "SignalHandler.h"

#include <QCoreApplication>
#include <QDir>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QSysInfo>
#include <QThread>

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <exception>
#include <mutex>
#include <optional>
#include <utility>

#if defined(Q_OS_WIN)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#elif defined(Q_OS_LINUX)
#include <csignal>
#endif

namespace Log
{
    namespace
    {
        const char *const kInternalCategory = "Logger";

        // True on the worker thread, to avoid waiting for ourselves
        thread_local bool t_inWorker = false;

        // True while the Qt message handler runs, to break feedback loops
        thread_local bool t_inQtHandler = false;

        QtMessageHandler s_previousQtHandler = nullptr;
        std::terminate_handler s_previousTerminate = nullptr;

#if defined(Q_OS_WIN)
        LPTOP_LEVEL_EXCEPTION_FILTER s_previousExceptionFilter = nullptr;

        LONG WINAPI unhandledExceptionFilter(EXCEPTION_POINTERS *info)
        {
            DWORD code = 0;
            quintptr address = 0;

            if(info != nullptr && info->ExceptionRecord != nullptr)
            {
                code = info->ExceptionRecord->ExceptionCode;
                address = reinterpret_cast<quintptr>(info->ExceptionRecord->ExceptionAddress);
            }

            const QString message = QStringLiteral("Unhandled exception 0x%1 at address 0x%2")
                                        .arg(static_cast<qulonglong>(code), 8, 16, QLatin1Char('0'))
                                        .arg(static_cast<qulonglong>(address), 0, 16);

            Logger::instance().log(Level::Fatal, "crash", message);

            if(s_previousExceptionFilter != nullptr)
            {
                return s_previousExceptionFilter(info);
            }

            return EXCEPTION_CONTINUE_SEARCH;
        }
#endif

#if defined(Q_OS_LINUX)
        // Runs from the fatal signal handler after the crash report was written, under a short
        // alarm(). It is not async-signal-safe on purpose, it only tries to get the queued
        // records onto the disk.
        void onFatalSignal(int signalNumber)
        {
            Logger &logger = Logger::instance();

            if(signalNumber == SIGABRT)
            {
                // abort() is reached through qFatal(), LOGGER_FATAL and std::terminate(), which
                // already logged the reason, so only make sure the queue reaches the disk
                logger.flush(2000);
                return;
            }

            const QString name = QString::fromLatin1(SignalHandler::signalName(signalNumber));
            const QString message = QStringLiteral("Fatal signal %1 (%2), see the crash log")
                                        .arg(signalNumber)
                                        .arg(name);

            logger.log(Level::Fatal, "crash", message);
        }
#endif

        // Case sensitive glob match, '*' matches any (possibly empty) run of characters
        bool wildcardMatch(const char *pattern, const char *text)
        {
            const char *star = nullptr;
            const char *resume = nullptr;

            while(*text != '\0')
            {
                if(*pattern == '*')
                {
                    star = pattern;
                    ++pattern;
                    resume = text;
                }
                else if(*pattern == *text)
                {
                    ++pattern;
                    ++text;
                }
                else if(star != nullptr)
                {
                    pattern = star + 1;
                    ++resume;
                    text = resume;
                }
                else
                {
                    return false;
                }
            }

            while(*pattern == '*')
            {
                ++pattern;
            }

            return *pattern == '\0';
        }

        void shutdownAtExit()
        {
            Logger::instance().shutdown();
        }

        void registerExitHook()
        {
            std::atexit(shutdownAtExit);
        }

        QString fileBaseName(const char *path)
        {
            const QString full = QString::fromUtf8(path);
            const int separator = std::max(full.lastIndexOf(QLatin1Char('/')),
                                           full.lastIndexOf(QLatin1Char('\\')));

            return separator < 0 ? full : full.mid(separator + 1);
        }

        QString sanitizeFileName(const QString &name)
        {
            QString result;
            result.reserve(name.size());

            for(const QChar character : name)
            {
                const bool allowed = character.isLetterOrNumber()
                    || character == QLatin1Char('-')
                    || character == QLatin1Char('_');

                if(allowed)
                {
                    result.append(character);
                }
                else
                {
                    result.append(QLatin1Char('_'));
                }
            }

            return result;
        }
    } // namespace

    Logger &Logger::instance()
    {
        // Intentionally leaked, the logger must stay usable while other statics are destroyed
        static Logger *logger = new Logger();
        return *logger;
    }

    bool Logger::start(const Config &requested)
    {
        std::lock_guard<std::mutex> lifecycle(m_lifecycleMutex);

        if(m_running.load())
        {
            return false;
        }

        Config config = requested;

        const QString envLevel = qEnvironmentVariable("LOGGER_LEVEL");

        if(!envLevel.isEmpty())
        {
            const std::optional<Level> parsed = parseLevel(envLevel);

            if(parsed.has_value())
            {
                config.level = *parsed;
            }
        }

        const QString envRules = qEnvironmentVariable("LOGGER_RULES");

        if(!envRules.isEmpty())
        {
            config.filterRules = envRules;
        }

        const QString envDirectory = qEnvironmentVariable("LOGGER_DIR");

        if(!envDirectory.isEmpty())
        {
            config.directory = envDirectory;
        }

        if(config.appName.isEmpty())
        {
            config.appName = QCoreApplication::applicationName();
        }

        config.appName = sanitizeFileName(config.appName);

        if(config.appName.isEmpty())
        {
            config.appName = QStringLiteral("app");
        }

        if(config.directory.isEmpty())
        {
            QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);

            if(base.isEmpty())
            {
                base = QDir::tempPath() + QLatin1Char('/') + config.appName;
            }

            config.directory = base + QStringLiteral("/logs");
        }

        config.directory = QDir::cleanPath(config.directory);

        std::shared_ptr<IFormatter> formatter;

        if(config.json)
        {
            formatter = std::make_shared<JsonFormatter>();
        }
        else
        {
            formatter = std::make_shared<PatternFormatter>(config.pattern);
        }

        {
            std::lock_guard<std::mutex> lock(m_sinksMutex);
            m_directory = config.directory;
        }

        if(config.console)
        {
            auto consoleSink = std::make_shared<ConsoleSink>(formatter);

            std::lock_guard<std::mutex> lock(m_sinksMutex);
            m_consoleSink = consoleSink;
            m_sinks.push_back(consoleSink);
        }

        if(config.file)
        {
            FileSink::Options options;
            options.directory = config.directory;
            options.baseName = config.appName;
            options.maxFileSize = config.maxFileSize;
            options.maxFiles = config.maxFiles;
            options.maxAgeDays = config.maxAgeDays;

            auto fileSink = std::make_shared<FileSink>(options, formatter);

            if(fileSink->open())
            {
                std::lock_guard<std::mutex> lock(m_sinksMutex);
                m_fileSink = fileSink;
                m_sinks.push_back(fileSink);
            }
        }

        m_level.store(static_cast<int>(config.level));
        setFilterRules(config.filterRules);
        m_chainPrevious = config.chainPreviousHandler;

        {
            std::lock_guard<std::mutex> lock(m_queueMutex);
            m_queue.clear();
            m_enqueued = 0;
            m_processed = 0;
            m_capacity = static_cast<size_t>(std::max(16, config.queueCapacity));
            m_stopRequested = false;
        }

        m_dropped.store(0);
        m_droppedReported.store(0);

        m_running.store(true);
        m_worker = std::thread(&Logger::workerLoop, this);

        installHooks(config);

        static std::once_flag exitHookFlag;
        std::call_once(exitHookFlag, registerExitHook);

        const QString started = QStringLiteral("Session started: %1 %2 | pid %3 | Qt %4 | %5 | "
                                               "level %6 | logs in %7")
                                    .arg(QCoreApplication::applicationName(),
                                         QCoreApplication::applicationVersion(),
                                         QString::number(QCoreApplication::applicationPid()),
                                         QString::fromLatin1(qVersion()),
                                         QSysInfo::prettyProductName(),
                                         levelName(config.level),
                                         config.directory);

        log(Level::Info, kInternalCategory, started);

        return true;
    }

    void Logger::shutdown()
    {
        std::lock_guard<std::mutex> lifecycle(m_lifecycleMutex);

        if(!m_running.load())
        {
            return;
        }

        log(Level::Info, kInternalCategory, QStringLiteral("Session ended"));

        // Stop receiving new Qt messages first, then let the worker drain what is left
        removeHooks();
        m_running.store(false);

        {
            std::lock_guard<std::mutex> lock(m_queueMutex);
            m_stopRequested = true;
        }

        m_queueCv.notify_all();

        if(m_worker.joinable())
        {
            m_worker.join();
        }

        // Remove the sinks created by start(), the ones added through addSink() belong to their
        // owners (e.g. a LogModel) and stay attached
        std::vector<std::shared_ptr<ISink>> sinks;

        {
            std::lock_guard<std::mutex> lock(m_sinksMutex);

            const std::shared_ptr<ISink> fileSink = m_fileSink;

            m_sinks.erase(std::remove(m_sinks.begin(), m_sinks.end(), m_consoleSink),
                          m_sinks.end());
            m_sinks.erase(std::remove(m_sinks.begin(), m_sinks.end(), fileSink), m_sinks.end());

            m_consoleSink.reset();
            m_fileSink.reset();
            sinks = m_sinks;
        }

        for(const std::shared_ptr<ISink> &sink : sinks)
        {
            sink->flush();
        }
    }

    bool Logger::isRunning() const
    {
        return m_running.load();
    }

    void Logger::installHooks(const Config &config)
    {
        if(config.captureQtMessages)
        {
            s_previousQtHandler = qInstallMessageHandler(&Logger::qtMessageHandler);
            m_qtHandlerInstalled = true;
        }

        if(config.installCrashHandlers)
        {
            s_previousTerminate = std::set_terminate(&Logger::terminateHandler);

#if defined(Q_OS_WIN)
            s_previousExceptionFilter = SetUnhandledExceptionFilter(&unhandledExceptionFilter);
#elif defined(Q_OS_LINUX)
            // The report goes to stderr and, when there is a file sink, to "<app>.crash.log" in
            // the log directory. That name does not match the "<app>_*.log" clean-up pattern.
            QString crashFile;

            if(config.file)
            {
                QDir().mkpath(config.directory);
                crashFile = QStringLiteral("%1/%2.crash.log").arg(config.directory, config.appName);
            }

            SignalHandler::install(crashFile, &onFatalSignal);
#endif

            m_crashHandlersInstalled = true;
        }
    }

    void Logger::removeHooks()
    {
        if(m_qtHandlerInstalled)
        {
            const QtMessageHandler current = qInstallMessageHandler(s_previousQtHandler);

            // Somebody installed a handler after us, leave theirs in place
            if(current != &Logger::qtMessageHandler)
            {
                qInstallMessageHandler(current);
            }

            m_qtHandlerInstalled = false;
        }

        if(m_crashHandlersInstalled)
        {
            if(s_previousTerminate != nullptr)
            {
                const std::terminate_handler current = std::set_terminate(s_previousTerminate);

                if(current != &Logger::terminateHandler)
                {
                    std::set_terminate(current);
                }
            }

#if defined(Q_OS_WIN)
            const LPTOP_LEVEL_EXCEPTION_FILTER current =
                SetUnhandledExceptionFilter(s_previousExceptionFilter);

            if(current != &unhandledExceptionFilter)
            {
                SetUnhandledExceptionFilter(current);
            }
#elif defined(Q_OS_LINUX)
            SignalHandler::uninstall();
#endif

            m_crashHandlersInstalled = false;
        }
    }

    void Logger::setLevel(Level level)
    {
        m_level.store(static_cast<int>(level));
    }

    Level Logger::level() const
    {
        return static_cast<Level>(m_level.load());
    }

    void Logger::setCategoryLevel(const QString &pattern, Level level)
    {
        Rule rule;
        rule.pattern = pattern.trimmed().toUtf8();
        rule.level = level;

        if(rule.pattern.isEmpty())
        {
            return;
        }

        std::unique_lock<std::shared_mutex> lock(m_rulesMutex);
        m_rules.push_back(rule);
        m_hasRules.store(true);
    }

    void Logger::setFilterRules(const QString &rules)
    {
        std::vector<Rule> parsed;

        const QStringList entries = rules.split(QRegularExpression(QStringLiteral("[;\\r\\n]+")),
                                                Qt::SkipEmptyParts);

        for(const QString &entry : entries)
        {
            const int equals = entry.indexOf(QLatin1Char('='));

            if(equals <= 0)
            {
                continue;
            }

            const std::optional<Level> level = parseLevel(QStringView(entry).mid(equals + 1));

            if(!level.has_value())
            {
                continue;
            }

            Rule rule;
            rule.pattern = entry.left(equals).trimmed().toUtf8();
            rule.level = *level;

            if(!rule.pattern.isEmpty())
            {
                parsed.push_back(rule);
            }
        }

        std::unique_lock<std::shared_mutex> lock(m_rulesMutex);
        m_rules = std::move(parsed);
        m_hasRules.store(!m_rules.empty());
    }

    void Logger::clearFilterRules()
    {
        setFilterRules(QString());
    }

    Level Logger::effectiveLevel(const char *category) const
    {
        const Level global = static_cast<Level>(m_level.load());

        if(!m_hasRules.load())
        {
            return global;
        }

        const char *name = category != nullptr ? category : "";

        std::shared_lock<std::shared_mutex> lock(m_rulesMutex);

        // The last matching rule wins, like QLoggingCategory filter rules
        for(auto it = m_rules.rbegin(); it != m_rules.rend(); ++it)
        {
            if(wildcardMatch(it->pattern.constData(), name))
            {
                return it->level;
            }
        }

        return global;
    }

    bool Logger::isEnabled(Level level, const char *category) const
    {
        if(level == Level::Fatal)
        {
            return true;
        }

        if(!m_running.load())
        {
            return false;
        }

        return static_cast<int>(level) >= static_cast<int>(effectiveLevel(category));
    }

    void Logger::addSink(std::shared_ptr<ISink> sink)
    {
        if(!sink)
        {
            return;
        }

        std::lock_guard<std::mutex> lock(m_sinksMutex);
        m_sinks.push_back(std::move(sink));
    }

    void Logger::removeSink(const std::shared_ptr<ISink> &sink)
    {
        std::lock_guard<std::mutex> lock(m_sinksMutex);
        m_sinks.erase(std::remove(m_sinks.begin(), m_sinks.end(), sink), m_sinks.end());
    }

    std::vector<std::shared_ptr<ISink>> Logger::sinksSnapshot() const
    {
        std::lock_guard<std::mutex> lock(m_sinksMutex);
        return m_sinks;
    }

    QString Logger::currentLogFile() const
    {
        std::lock_guard<std::mutex> lock(m_sinksMutex);

        if(!m_fileSink)
        {
            return QString();
        }

        return m_fileSink->currentFilePath();
    }

    QString Logger::logDirectory() const
    {
        std::lock_guard<std::mutex> lock(m_sinksMutex);
        return m_directory;
    }

    void Logger::log(Level level,
                     const char *category,
                     const QString &message,
                     const char *file,
                     int line,
                     const char *function)
    {
        if(!isEnabled(level, category))
        {
            return;
        }

        if(!m_running.load())
        {
            // Only a fatal record gets here, make sure it is not lost silently
            std::fprintf(stderr,
                         "[FATAL] [%s] %s\n",
                         category != nullptr ? category : "",
                         qPrintable(message));
            return;
        }

        static const qint64 processId = QCoreApplication::applicationPid();

        Record record;
        record.timestamp = QDateTime::currentDateTime();
        record.level = level;
        record.category = category != nullptr ? QString::fromUtf8(category) : QString();
        record.message = message;
        record.line = line;
        record.threadId = reinterpret_cast<quintptr>(QThread::currentThreadId());
        record.processId = processId;

        if(file != nullptr)
        {
            record.file = fileBaseName(file);
        }

        if(function != nullptr)
        {
            record.function = QString::fromUtf8(function);
        }

        enqueue(std::move(record));

        if(static_cast<int>(level) >= static_cast<int>(Level::Critical))
        {
            flush(3000);
        }
    }

    void Logger::log(Level level,
                     const QString &category,
                     const QString &message,
                     const char *file,
                     int line,
                     const char *function)
    {
        const QByteArray utf8 = category.toUtf8();
        log(level, utf8.constData(), message, file, line, function);
    }

    void Logger::enqueue(Record &&record)
    {
        {
            std::lock_guard<std::mutex> lock(m_queueMutex);

            if(m_queue.size() >= m_capacity)
            {
                m_queue.pop_front();
                ++m_processed;
                m_dropped.fetch_add(1);
            }

            m_queue.push_back(std::move(record));
            ++m_enqueued;
        }

        m_queueCv.notify_one();
    }

    bool Logger::flush(int timeoutMs)
    {
        if(!m_running.load())
        {
            return true;
        }

        // The worker thread cannot wait for itself
        if(t_inWorker)
        {
            return false;
        }

        std::unique_lock<std::mutex> lock(m_queueMutex);
        const quint64 target = m_enqueued;
        const std::chrono::milliseconds timeout(std::max(0, timeoutMs));

        auto processed = [this, target]()
        {
            return m_processed >= target;
        };

        return m_processedCv.wait_for(lock, timeout, processed);
    }

    quint64 Logger::droppedCount() const
    {
        return m_dropped.load();
    }

    void Logger::workerLoop()
    {
        t_inWorker = true;

        std::deque<Record> batch;

        for(;;)
        {
            {
                std::unique_lock<std::mutex> lock(m_queueMutex);

                auto hasWork = [this]()
                {
                    return !m_queue.empty() || m_stopRequested;
                };

                m_queueCv.wait(lock, hasWork);

                if(m_queue.empty())
                {
                    break;
                }

                batch.swap(m_queue);
            }

            const std::vector<std::shared_ptr<ISink>> sinks = sinksSnapshot();

            const quint64 dropped = m_dropped.load();
            const quint64 reported = m_droppedReported.load();

            if(dropped > reported)
            {
                Record notice;
                notice.timestamp = QDateTime::currentDateTime();
                notice.level = Level::Warning;
                notice.category = QString::fromLatin1(kInternalCategory);
                notice.message = QStringLiteral("%1 log record(s) were dropped, the queue was full")
                                     .arg(dropped - reported);
                notice.threadId = reinterpret_cast<quintptr>(QThread::currentThreadId());
                notice.processId = QCoreApplication::applicationPid();

                for(const std::shared_ptr<ISink> &sink : sinks)
                {
                    try
                    {
                        sink->write(notice);
                    }
                    catch(...)
                    {
                    }
                }

                m_droppedReported.store(dropped);
            }

            for(const Record &record : batch)
            {
                for(const std::shared_ptr<ISink> &sink : sinks)
                {
                    try
                    {
                        sink->write(record);
                    }
                    catch(...)
                    {
                    }
                }
            }

            for(const std::shared_ptr<ISink> &sink : sinks)
            {
                try
                {
                    sink->flush();
                }
                catch(...)
                {
                }
            }

            {
                std::lock_guard<std::mutex> lock(m_queueMutex);
                m_processed += batch.size();
            }

            m_processedCv.notify_all();
            batch.clear();
        }

        t_inWorker = false;
    }

    void Logger::qtMessageHandler(QtMsgType type,
                                  const QMessageLogContext &context,
                                  const QString &message)
    {
        if(t_inQtHandler)
        {
            // The logger itself triggered a Qt message while handling one, do not recurse
            std::fprintf(stderr, "%s\n", qPrintable(message));
            return;
        }

        struct ReentrancyGuard
        {
            ReentrancyGuard()
            {
                t_inQtHandler = true;
            }

            ~ReentrancyGuard()
            {
                t_inQtHandler = false;
            }
        } guard;

        Logger &logger = instance();

        if(logger.m_running.load())
        {
            logger.log(levelFromQtMsgType(type),
                       context.category,
                       message,
                       context.file,
                       context.line,
                       context.function);
        }

        if(logger.m_chainPrevious && s_previousQtHandler != nullptr)
        {
            s_previousQtHandler(type, context, message);
        }
    }

    void Logger::terminateHandler()
    {
        QString what = QStringLiteral("std::terminate() called");

        const std::exception_ptr pending = std::current_exception();

        if(pending)
        {
            try
            {
                std::rethrow_exception(pending);
            }
            catch(const std::exception &error)
            {
                what += QStringLiteral(": ") + QString::fromUtf8(error.what());
            }
            catch(...)
            {
                what += QStringLiteral(" with an unknown exception");
            }
        }

        // A fatal record is flushed synchronously by log()
        instance().log(Level::Fatal, "crash", what);

        if(s_previousTerminate != nullptr)
        {
            s_previousTerminate();
        }

        std::abort();
    }

    LogStream::LogStream(Level level,
                         const char *category,
                         const char *file,
                         int line,
                         const char *function)
        : m_level(level)
        , m_category(category)
        , m_file(file)
        , m_line(line)
        , m_function(function)
        , m_debug(std::make_unique<QDebug>(&m_buffer))
    {
        m_debug->noquote();
    }

    LogStream::~LogStream()
    {
        // QDebug writes into the string when it is destroyed, so it has to go first
        m_debug.reset();

        while(m_buffer.endsWith(QLatin1Char(' ')))
        {
            m_buffer.chop(1);
        }

        Logger &logger = Logger::instance();
        logger.log(m_level, m_category, m_buffer, m_file, m_line, m_function);

        if(m_level == Level::Fatal)
        {
            logger.flush();
            std::abort();
        }
    }

    LogStream &LogStream::nospace()
    {
        m_debug->nospace();
        return *this;
    }
} // namespace Log
