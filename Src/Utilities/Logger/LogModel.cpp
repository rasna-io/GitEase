#include "LogModel.h"

#include "Logger.h"

#include <QMetaObject>

#include <algorithm>
#include <mutex>
#include <vector>

namespace Log
{
    // Bridges the worker thread and the model's thread. The sink only collects records, the
    // model pulls them on its own thread when the queued call arrives.
    class LogModelSink final : public ISink
    {
    public:
        explicit LogModelSink(LogModel *model)
            : m_model(model)
        {
        }

        // Called by the model's destructor, so late records never touch a dead object
        void detach()
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            m_model = nullptr;
            m_pending.clear();
        }

        std::vector<Record> takePending()
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            m_scheduled = false;

            std::vector<Record> records;
            records.swap(m_pending);
            return records;
        }

        void write(const Record &record) override
        {
            std::lock_guard<std::mutex> lock(m_mutex);

            if(m_model == nullptr)
            {
                return;
            }

            m_pending.push_back(record);

            if(m_scheduled)
            {
                return;
            }

            m_scheduled = true;

            LogModel *model = m_model;

            auto drain = [model]()
            {
                model->drainPending();
            };

            QMetaObject::invokeMethod(model, drain, Qt::QueuedConnection);
        }

    private:
        std::mutex m_mutex;
        LogModel *m_model = nullptr;
        std::vector<Record> m_pending;
        bool m_scheduled = false;
    };

    LogModel::LogModel(QObject *parent)
        : QAbstractListModel(parent)
        , m_sink(std::make_shared<LogModelSink>(this))
    {
        Logger::instance().addSink(m_sink);
    }

    LogModel::~LogModel()
    {
        Logger::instance().removeSink(m_sink);
        m_sink->detach();
    }

    int LogModel::rowCount(const QModelIndex &parent) const
    {
        if(parent.isValid())
        {
            return 0;
        }

        return static_cast<int>(m_records.size());
    }

    QVariant LogModel::data(const QModelIndex &index, int role) const
    {
        if(!index.isValid() || index.row() < 0 || index.row() >= rowCount())
        {
            return QVariant();
        }

        const Record &record = m_records[static_cast<size_t>(index.row())];

        switch(role)
        {
        case TimeRole:
            return record.timestamp;
        case LevelRole:
            return static_cast<int>(record.level);
        case LevelNameRole:
            return levelName(record.level);
        case CategoryRole:
            return record.category;
        case MessageRole:
            return record.message;
        case ThreadRole:
            return QStringLiteral("0x%1").arg(record.threadId, 0, 16);
        case FileRole:
            return record.file;
        case LineRole:
            return record.line;
        case Qt::DisplayRole:
        case TextRole:
            return m_formatter.format(record);
        default:
            break;
        }

        return QVariant();
    }

    QHash<int, QByteArray> LogModel::roleNames() const
    {
        return {
            { TimeRole, "time" },
            { LevelRole, "level" },
            { LevelNameRole, "levelName" },
            { CategoryRole, "category" },
            { MessageRole, "message" },
            { ThreadRole, "thread" },
            { FileRole, "file" },
            { LineRole, "line" },
            { TextRole, "text" },
        };
    }

    int LogModel::capacity() const
    {
        return m_capacity;
    }

    void LogModel::setCapacity(int capacity)
    {
        capacity = std::max(1, capacity);

        if(capacity == m_capacity)
        {
            return;
        }

        m_capacity = capacity;

        const int overflow = rowCount() - m_capacity;

        if(overflow > 0)
        {
            beginRemoveRows(QModelIndex(), 0, overflow - 1);

            for(int i = 0; i < overflow; ++i)
            {
                m_records.pop_front();
            }

            endRemoveRows();
            emit countChanged();
        }

        emit capacityChanged();
    }

    int LogModel::count() const
    {
        return rowCount();
    }

    void LogModel::clear()
    {
        if(m_records.empty())
        {
            return;
        }

        beginResetModel();
        m_records.clear();
        endResetModel();

        emit countChanged();
    }

    void LogModel::drainPending()
    {
        std::vector<Record> incoming = m_sink->takePending();

        if(incoming.empty())
        {
            return;
        }

        if(static_cast<int>(incoming.size()) > m_capacity)
        {
            incoming.erase(incoming.begin(),
                           incoming.begin() + (static_cast<int>(incoming.size()) - m_capacity));
        }

        const int overflow = rowCount() + static_cast<int>(incoming.size()) - m_capacity;

        if(overflow > 0)
        {
            beginRemoveRows(QModelIndex(), 0, overflow - 1);

            for(int i = 0; i < overflow; ++i)
            {
                m_records.pop_front();
            }

            endRemoveRows();
        }

        const int first = rowCount();
        const int last = first + static_cast<int>(incoming.size()) - 1;

        beginInsertRows(QModelIndex(), first, last);

        for(Record &record : incoming)
        {
            m_records.push_back(std::move(record));
        }

        endInsertRows();

        emit countChanged();
    }
} // namespace Log
