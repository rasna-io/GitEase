#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonObject>
#include <QTimer>
#include <QVariantMap>

#include "ProxyManager.h"

class NetworkManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(ProxyManager* proxyManager READ proxyManager WRITE setProxyManager NOTIFY proxyManagerChanged)

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
    Q_INVOKABLE void downloadRequest(
        const QString &requestKey,
        const QString &url,
        const QVariantMap &headers = QVariantMap()
    );

    ProxyManager *proxyManager() const;
    void setProxyManager(ProxyManager *proxyManager);

signals:
    void requestFinished(QString requestKey, QJsonObject response);
    void requestError(QString requestKey, int code, QString message);
    void timeout(QString requestKey);
    void downloadProgress(QString requestKey, qint64 bytesReceived, qint64 bytesTotal);
    void proxyManagerChanged();

private:
    void setHeaders(QNetworkRequest &request, const QVariantMap &headers);
    void applyProxyForUrl(const QString &url);

private:
    QNetworkAccessManager m_manager;
    ProxyManager *m_proxyManager = nullptr;
};
