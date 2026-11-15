#include "Formatter.h"

#include <QJsonDocument>
#include <QJsonObject>

namespace Log
{
    namespace
    {
        const QString kDefaultTimeFormat = QStringLiteral("yyyy-MM-dd HH:mm:ss.zzz");
        const QString kContinuationIndent = QStringLiteral("    ");

        QString normalizeMessage(const QString &message)
        {
            QString text = message;
            text.replace(QStringLiteral("\r\n"), QStringLiteral("\n"));
            text.replace(QLatin1Char('\r'), QLatin1Char('\n'));

            while(text.endsWith(QLatin1Char('\n')))
            {
                text.chop(1);
            }

            return text;
        }

        QString indentContinuationLines(const QString &text)
        {
            if(!text.contains(QLatin1Char('\n')))
            {
                return text;
            }

            QString result = text;
            result.replace(QLatin1Char('\n'), QLatin1Char('\n') + kContinuationIndent);
            return result;
        }
    } // namespace

    PatternFormatter::PatternFormatter(const QString &pattern)
    {
        parse(pattern.isEmpty() ? defaultPattern() : pattern);
    }

    QString PatternFormatter::defaultPattern()
    {
        return QStringLiteral("%{time} [%{level}] [%{category}] %{message}");
    }

    void PatternFormatter::parse(const QString &pattern)
    {
        m_parts.clear();

        QString literal;
        int index = 0;

        auto flushLiteral = [this, &literal]()
        {
            if(literal.isEmpty())
            {
                return;
            }

            Part part;
            part.token = Token::Literal;
            part.text = literal;
            m_parts.append(part);
            literal.clear();
        };

        while(index < pattern.size())
        {
            const bool startsToken = pattern.at(index) == QLatin1Char('%')
                && index + 1 < pattern.size()
                && pattern.at(index + 1) == QLatin1Char('{');

            if(!startsToken)
            {
                literal.append(pattern.at(index));
                ++index;
                continue;
            }

            const int end = pattern.indexOf(QLatin1Char('}'), index + 2);

            if(end < 0)
            {
                literal.append(pattern.mid(index));
                break;
            }

            const QString body = pattern.mid(index + 2, end - index - 2);
            const int separator = body.indexOf(QLatin1Char(':'));
            const QString name = separator < 0 ? body : body.left(separator);
            const QString argument = separator < 0 ? QString() : body.mid(separator + 1);

            Part part;
            bool known = true;

            if(name == QLatin1String("time"))
            {
                part.token = Token::Time;
                part.text = argument.isEmpty() ? kDefaultTimeFormat : argument;
            }
            else if(name == QLatin1String("level"))
            {
                part.token = Token::Level;
            }
            else if(name == QLatin1String("category"))
            {
                part.token = Token::Category;
            }
            else if(name == QLatin1String("message"))
            {
                part.token = Token::Message;
            }
            else if(name == QLatin1String("thread"))
            {
                part.token = Token::Thread;
            }
            else if(name == QLatin1String("pid"))
            {
                part.token = Token::ProcessId;
            }
            else if(name == QLatin1String("file"))
            {
                part.token = Token::File;
            }
            else if(name == QLatin1String("line"))
            {
                part.token = Token::Line;
            }
            else if(name == QLatin1String("function"))
            {
                part.token = Token::Function;
            }
            else
            {
                known = false;
            }

            if(known)
            {
                flushLiteral();
                m_parts.append(part);
            }
            else
            {
                literal.append(pattern.mid(index, end - index + 1));
            }

            index = end + 1;
        }

        flushLiteral();
    }

    QString PatternFormatter::format(const Record &record) const
    {
        QString output;
        output.reserve(96 + record.message.size());

        for(const Part &part : m_parts)
        {
            switch(part.token)
            {
            case Token::Literal:
                output.append(part.text);
                break;
            case Token::Time:
                output.append(record.timestamp.toString(part.text));
                break;
            case Token::Level:
                output.append(levelShortName(record.level));
                break;
            case Token::Category:
                output.append(record.category);
                break;
            case Token::Message:
                output.append(indentContinuationLines(normalizeMessage(record.message)));
                break;
            case Token::Thread:
                output.append(QStringLiteral("0x%1").arg(record.threadId, 0, 16));
                break;
            case Token::ProcessId:
                output.append(QString::number(record.processId));
                break;
            case Token::File:
                output.append(record.file);
                break;
            case Token::Line:
                output.append(QString::number(record.line));
                break;
            case Token::Function:
                output.append(record.function);
                break;
            }
        }

        return output;
    }

    QString JsonFormatter::format(const Record &record) const
    {
        QJsonObject object;
        object.insert(QStringLiteral("time"), record.timestamp.toUTC().toString(Qt::ISODateWithMs));
        object.insert(QStringLiteral("level"), levelName(record.level));
        object.insert(QStringLiteral("category"), record.category);
        object.insert(QStringLiteral("message"), record.message);
        object.insert(QStringLiteral("thread"), QStringLiteral("0x%1").arg(record.threadId, 0, 16));
        object.insert(QStringLiteral("pid"), record.processId);

        if(!record.file.isEmpty())
        {
            object.insert(QStringLiteral("file"), record.file);
            object.insert(QStringLiteral("line"), record.line);
        }

        if(!record.function.isEmpty())
        {
            object.insert(QStringLiteral("function"), record.function);
        }

        return QString::fromUtf8(QJsonDocument(object).toJson(QJsonDocument::Compact));
    }
} // namespace Log
