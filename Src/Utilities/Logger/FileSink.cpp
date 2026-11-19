#include "FileSink.h"

#include <QDir>
#include <QFileInfo>
#include <QMap>
#include <QRegularExpression>

#include <algorithm>
#include <cstdio>
#include <utility>

namespace Log
{
    FileSink::FileSink(const Options &options, std::shared_ptr<IFormatter> formatter)
        : m_options(options)
        , m_formatter(std::move(formatter))
    {
        if(m_options.maxLines < 0)
        {
            m_options.maxLines = 0;
        }

        if(m_options.maxFileSize < 1024)
        {
            m_options.maxFileSize = 1024;
        }

        if(m_options.maxSessions < 1)
        {
            m_options.maxSessions = 1;
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

    qint64 FileSink::countLines(const QString &path)
    {
        QFile file(path);

        if(!file.open(QIODevice::ReadOnly))
        {
            return 0;
        }

        qint64 lines = 0;

        while(!file.atEnd())
        {
            const QByteArray chunk = file.read(64 * 1024);
            lines += std::count(chunk.constBegin(), chunk.constEnd(), '\n');
        }

        return lines;
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

        // A file left by a session that started in the same second is continued, not restarted
        m_fileSize = m_file.size();
        m_lineCount = m_fileSize > 0 ? countLines(path) : 0;

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

        QByteArray text = m_formatter->format(record).toUtf8();
        text.append('\n');

        // A record with a multi-line message counts as several lines
        const qint64 lines = std::count(text.constBegin(), text.constEnd(), '\n');

        const bool tooManyLines = m_options.maxLines > 0
            && m_lineCount > 0
            && m_lineCount + lines > m_options.maxLines;
        const bool tooBig = m_fileSize > 0 && m_fileSize + text.size() > m_options.maxFileSize;

        if(tooManyLines || tooBig)
        {
            ++m_fileIndex;

            if(!openNextFile())
            {
                return;
            }

            cleanupOldFiles();
        }

        const qint64 written = m_file.write(text);

        if(written > 0)
        {
            m_fileSize += written;
            m_lineCount += lines;
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
        const QFileInfoList files = directory.entryInfoList(filters, QDir::Files, QDir::NoSort);

        // "<baseName>_<yyyyMMdd_HHmmss>[.<n>].log", the stamp identifies the session
        const QString expression = QStringLiteral("^%1_(\\d{8}_\\d{6})(?:\\.\\d+)?\\.log$")
                                       .arg(QRegularExpression::escape(m_options.baseName));
        const QRegularExpression namePattern(expression);

        // The stamp sorts chronologically, so the map is ordered from the oldest session
        QMap<QString, QFileInfoList> sessions;

        for(const QFileInfo &info : files)
        {
            const QRegularExpressionMatch match = namePattern.match(info.fileName());

            if(match.hasMatch())
            {
                sessions[match.captured(1)].append(info);
            }
        }

        QDateTime threshold;

        if(m_options.maxAgeDays > 0)
        {
            threshold = QDateTime::currentDateTime().addDays(-m_options.maxAgeDays);
        }

        // Newest session first. The current one is always kept and takes one of the slots.
        int keptSessions = 0;

        for(auto it = sessions.crbegin(); it != sessions.crend(); ++it)
        {
            const QFileInfoList &sessionFiles = it.value();

            if(it.key() == m_sessionStamp)
            {
                ++keptSessions;
                continue;
            }

            QDateTime lastWrite;

            for(const QFileInfo &info : sessionFiles)
            {
                lastWrite = std::max(lastWrite, info.lastModified());
            }

            const bool tooMany = keptSessions >= m_options.maxSessions;
            const bool tooOld = threshold.isValid() && lastWrite < threshold;

            if(!tooMany && !tooOld)
            {
                ++keptSessions;
                continue;
            }

            for(const QFileInfo &info : sessionFiles)
            {
                QFile::remove(info.absoluteFilePath());
            }
        }
    }
} // namespace Log
