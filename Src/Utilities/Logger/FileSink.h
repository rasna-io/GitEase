#pragma once

#include "Formatter.h"
#include "Sink.h"

#include <QDateTime>
#include <QFile>
#include <QString>

#include <memory>
#include <mutex>

namespace Log
{
    /**
     * \brief Writes records to UTF-8 log files with rotation and clean-up
     *
     * Every session starts a file, "<baseName>_<yyyyMMdd_HHmmss>.log". When a file would pass
     * maxLines lines (or maxFileSize bytes) the sink continues in
     * "<baseName>_<yyyyMMdd_HHmmss>.<n>.log", so one long session can span several files.
     *
     * The clean-up counts sessions, not files. Only the newest maxSessions sessions are kept, with
     * all of their files, and sessions older than maxAgeDays are removed. The current session is
     * never removed.
     */
    class FileSink final : public ISink
    {
    public:
        struct Options
        {
            QString directory;
            QString baseName = QStringLiteral("app");
            // Lines per file, 0 disables the limit
            int maxLines = 2000;
            // Safety cap in bytes, for records with very long lines
            qint64 maxFileSize = 10 * 1024 * 1024;
            int maxSessions = 5;
            int maxAgeDays = 30;
        };

        FileSink(const Options &options, std::shared_ptr<IFormatter> formatter);
        ~FileSink() override;

        /** \brief Creates the directory and opens the session file, false when that fails */
        bool open();

        /** \brief Absolute path of the file being written, safe to call from any thread */
        QString currentFilePath() const;

        void write(const Record &record) override;
        void flush() override;

    private:
        bool openNextFile();
        void cleanupOldFiles();
        QString fileNameFor(int index) const;
        static qint64 countLines(const QString &path);

        Options m_options;
        std::shared_ptr<IFormatter> m_formatter;

        QFile m_file;
        qint64 m_fileSize = 0;
        qint64 m_lineCount = 0;
        int m_fileIndex = 0;
        QString m_sessionStamp;

        mutable std::mutex m_pathMutex;
        QString m_currentPath;
    };
} // namespace Log
