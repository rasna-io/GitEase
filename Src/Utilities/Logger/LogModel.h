#pragma once

#include "Formatter.h"
#include "Record.h"

#include <QAbstractListModel>

#include <deque>
#include <memory>

namespace Log
{
    class LogModelSink;

    /**
     * \brief List model of the most recent log records, e.g. for an in-app log viewer
     *
     * Creating a model attaches it to the logger and destroying it detaches it. Records arrive on
     * the worker thread and are delivered to the model's thread in batches, so the model can be
     * used from QML as it is. Only the last `capacity` records are kept.
     *
     * \code
     *   import Logger
     *
     *   ListView {
     *       model: LogModel { capacity: 2000 }
     *       delegate: Text { text: model.text }
     *   }
     * \endcode
     */
    class LogModel : public QAbstractListModel
    {
        Q_OBJECT
        Q_PROPERTY(int capacity READ capacity WRITE setCapacity NOTIFY capacityChanged)
        Q_PROPERTY(int count READ count NOTIFY countChanged)

    public:
        enum Role
        {
            TimeRole = Qt::UserRole + 1,
            LevelRole,
            LevelNameRole,
            CategoryRole,
            MessageRole,
            ThreadRole,
            FileRole,
            LineRole,
            TextRole
        };
        Q_ENUM(Role)

        explicit LogModel(QObject *parent = nullptr);
        ~LogModel() override;

        int rowCount(const QModelIndex &parent = QModelIndex()) const override;
        QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
        QHash<int, QByteArray> roleNames() const override;

        int capacity() const;
        void setCapacity(int capacity);

        int count() const;

        Q_INVOKABLE void clear();

    signals:
        void capacityChanged();
        void countChanged();

    private:
        friend class LogModelSink;

        void drainPending();

        std::deque<Record> m_records;
        int m_capacity = 5000;
        PatternFormatter m_formatter;
        std::shared_ptr<LogModelSink> m_sink;
    };
} // namespace Log
