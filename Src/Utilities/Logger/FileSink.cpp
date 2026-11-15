#include "FileSink.h"

#include <QDir>
#include <QFileInfo>

#include <algorithm>
#include <cstdio>
#include <utility>

namespace Log
{
    FileSink::FileSink(const Options &options, std::shared_ptr<IFormatter> formatter)
        : m_options(options)
        , m_formatter(std::move(formatter))
    {
        if(m_options.maxFileSize < 1024)
        {
            m_options.maxFileSize = 1024;
        }

        if(m_options.maxFiles < 1)
        {
            m_options.maxFiles = 1;
        }
    }

    FileSink::~FileSink()
    {
        if(m_file.isOpen())
        {
            m_file.flush();
            m_file.close();
        }
    }

    bool FileSink::open()
    {
        if(!QDir().mkpath(m_options.directory))
        {
            std::fprintf(stderr,
                         "[Logger] cannot create log directory '%s'\n",
                         qPrintable(m_options.directory));
            return false;
        }

        m_sessionStamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd_HHmmss"));
        m_fileIndex = 0;

        if(!openNextFile())
        {
            return false;
        }

        cleanupOldFiles();
        return true;
    }

    QString FileSink::currentFilePath() const
    {
        std::lock_guard<std::mutex> lock(m_pathMutex);
        return m_currentPath;
    }

    QString FileSink::fileNameFor(int index) const
    {
        if(index == 0)
        {
            return QStringLiteral("%1_%2.log").arg(m_options.baseName, m_sessionStamp);
        }

        return QStringLiteral("%1_%2.%3.log").arg(m_options.baseName, m_sessionStamp).arg(index);
    }

    bool FileSink::openNextFile()
    {
        if(m_file.isOpen())
        {
            m_file.flush();
            m_file.close();
        }

        const QString path = QDir(m_options.directory).absoluteFilePath(fileNameFor(m_fileIndex));

        m_file.setFileName(path);

        if(!m_file.open(QIODevice::WriteOnly | QIODevice::Append))
        {
            std::fprintf(stderr,
                         "[Logger] cannot open log file '%s': %s\n",
                         qPrintable(path),
                         qPrintable(m_file.errorString()));
            return false;
        }

        m_fileSize = m_file.size();

        std::lock_guard<std::mutex> lock(m_pathMutex);
        m_currentPath = path;
        return true;
    }

    void FileSink::write(const Record &record)
    {
        if(!m_file.isOpen() || !m_formatter)
        {
            return;
        }

        QByteArray line = m_formatter->format(record).toUtf8();
        line.append('\n');

        if(m_fileSize > 0 && m_fileSize + line.size() > m_options.maxFileSize)
        {
            ++m_fileIndex;

            if(!openNextFile())
            {
                return;
            }

            cleanupOldFiles();
        }

        const qint64 written = m_file.write(line);

        if(written > 0)
        {
            m_fileSize += written;
        }
    }

    void FileSink::flush()
    {
        if(m_file.isOpen())
        {
            m_file.flush();
        }
    }

    void FileSink::cleanupOldFiles()
    {
        const QDir directory(m_options.directory);
        const QStringList filters { QStringLiteral("%1_*.log").arg(m_options.baseName) };

        QFileInfoList files = directory.entryInfoList(filters, QDir::Files, QDir::NoSort);

        // Newest first, so everything after maxFiles entries is the oldest
        auto newerFirst = [](const QFileInfo &a, const QFileInfo &b)
        {
            return a.lastModified() > b.lastModified();
        };

        std::sort(files.begin(), files.end(), newerFirst);

        const QString current = currentFilePath();
        QDateTime threshold;

        if(m_options.maxAgeDays > 0)
        {
            threshold = QDateTime::currentDateTime().addDays(-m_options.maxAgeDays);
        }

        int kept = 0;

        for(const QFileInfo &info : std::as_const(files))
        {
            // The file in use is never removed and always takes one of the maxFiles slots
            if(info.absoluteFilePath() == current)
            {
                continue;
            }

            const bool tooMany = kept >= m_options.maxFiles - 1;
            const bool tooOld = threshold.isValid() && info.lastModified() < threshold;

            if(tooMany || tooOld)
            {
                QFile::remove(info.absoluteFilePath());
            }
            else
            {
                ++kept;
            }
        }
    }
} // namespace Log
