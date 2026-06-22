#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonObject>
#include <QTimer>

class NetworkManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit NetworkManager(QObject *parent = nullptr);

    enum HttpMethod {
        GET,
        POST
    };

    Q_ENUM(HttpMethod)

    Q_INVOKABLE void sendRequest(
        const QString &requestKey,
        const QString &url,
        HttpMethod method,
        const QJsonObject &body = QJsonObject(),
        const QVariantMap &headers = QVariantMap()
    );

signals:
    void requestFinished(QString requestKey, QJsonObject response);
    void requestError(QString requestKey, int code, QString message);
    void timeout(QString requestKey);
    void downloadProgress(QString requestKey, qint64 bytesReceived, qint64 bytesTotal);

private:
    void setHeaders(QNetworkRequest &request, const QVariantMap &headers);

private:
    QNetworkAccessManager m_manager;
};