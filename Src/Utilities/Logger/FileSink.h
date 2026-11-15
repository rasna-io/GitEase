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
     * \brief Writes records to UTF-8 log files with size based rotation and clean-up
     *
     * Every session gets its own file, "<baseName>_<yyyyMMdd_HHmmss>.log". When a file would grow
     * past maxFileSize the sink continues in "<baseName>_<yyyyMMdd_HHmmss>.<n>.log". Files matching
     * "<baseName>_*.log" are removed when more than maxFiles exist or when they are older than
     * maxAgeDays. The file being written is never removed.
     */
    class FileSink final : public ISink
    {
    public:
        struct Options
        {
            QString directory;
            QString baseName = QStringLiteral("app");
            qint64 maxFileSize = 10 * 1024 * 1024;
            int maxFiles = 10;
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

        Options m_options;
        std::shared_ptr<IFormatter> m_formatter;

        QFile m_file;
        qint64 m_fileSize = 0;
        int m_fileIndex = 0;
        QString m_sessionStamp;

        mutable std::mutex m_pathMutex;
        QString m_currentPath;
    };
} // namespace Log
