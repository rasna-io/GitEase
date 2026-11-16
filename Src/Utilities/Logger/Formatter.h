#pragma once

#include "Record.h"

#include <QList>
#include <QString>

#include <memory>

namespace Log
{
    /** \brief Turns a Record into text, implementations must be thread-safe */
    class IFormatter
    {
    public:
        virtual ~IFormatter() = default;

        virtual QString format(const Record &record) const = 0;
    };

    /**
     * \brief Formats one record per entry from a pattern string
     *
     * Tokens:
     *   %{time}           local time, "yyyy-MM-dd HH:mm:ss.zzz"
     *   %{time:<format>}  local time with a QDateTime format, e.g. %{time:HH:mm:ss.zzz}
     *   %{level}          5 character level, e.g. "WARN "
     *   %{category}       logging category
     *   %{message}        message text
     *   %{thread}         thread id (hexadecimal)
     *   %{pid}            process id
     *   %{file}           source file name without directories
     *   %{line}           source line
     *   %{function}       function signature
     *
     * Unknown tokens are written as they are. The lines after the first one of a multi-line
     * message are indented.
     */
    class PatternFormatter final : public IFormatter
    {
    public:
        explicit PatternFormatter(const QString &pattern = defaultPattern());

        static QString defaultPattern();

        QString format(const Record &record) const override;

    private:
        enum class Token
        {
            Literal,
            Time,
            Level,
            Category,
            Message,
            Thread,
            ProcessId,
            File,
            Line,
            Function
        };

        struct Part
        {
            Token token = Token::Literal;
            QString text;
        };

        void parse(const QString &pattern);

        QList<Part> m_parts;
    };

    /** \brief One compact JSON object per record ("JSON lines") */
    class JsonFormatter final : public IFormatter
    {
    public:
        QString format(const Record &record) const override;
    };
} // namespace Log
