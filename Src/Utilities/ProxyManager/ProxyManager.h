#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QVariantMap>

class QNetworkProxy;

/**
 * @brief App-wide proxy configuration, exposed to both QML and pure C++ callers.
 *
 * Mirrors NetworkManager: a plain QML_ELEMENT wrapped by Qml/Core/Controllers/ProxyController.qml,
 * which UiSession.qml owns (like the other controllers) and which mirrors the live state to the
 * ProxySettings model owned by AppSettings.qml, so it is persisted with AppModel's JSON config.
 *
 * Pure-C++ callers with no QML handle (Src/Git/*) use active(), which returns the
 * live instance (the first one constructed). The app creates exactly one.
 *
 * The password is kept in memory and mirrored by ProxyController into ProxySettings, so it
 * ends up in plaintext in AppModel's JSON config alongside the other proxy fields. It is not
 * encrypted and not written to QSettings.
 *
 * VMess/VLess: libgit2 and QNetworkProxy don't speak these, so for those types the
 * effective proxy is a socks5://host:port to a local V2Ray/Xray SOCKS inbound.
 */
class ProxyManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int     proxyType     READ proxyType     WRITE setProxyType     NOTIFY proxyTypeChanged     FINAL)
    Q_PROPERTY(QString host          READ host          WRITE setHost          NOTIFY hostChanged          FINAL)
    Q_PROPERTY(int     port          READ port          WRITE setPort          NOTIFY portChanged          FINAL)
    Q_PROPERTY(bool    requiresAuth  READ requiresAuth  WRITE setRequiresAuth  NOTIFY requiresAuthChanged  FINAL)
    Q_PROPERTY(QString username      READ username      WRITE setUsername      NOTIFY usernameChanged      FINAL)
    Q_PROPERTY(QString noProxyList   READ noProxyList   WRITE setNoProxyList   NOTIFY noProxyListChanged   FINAL)
    Q_PROPERTY(QString password      READ password      WRITE setPassword      NOTIFY passwordChanged      FINAL)
    Q_PROPERTY(bool    hasPassword   READ hasPassword                          NOTIFY hasPasswordChanged   FINAL)

public:
    enum ProxyType {
        None   = 0,
        Http   = 1,
        Socks5 = 2,
        VMess  = 3,
        VLess  = 4,
        Auto   = 5
    };
    Q_ENUM(ProxyType)

    explicit ProxyManager(QObject *parent = nullptr);
    ~ProxyManager() override;

public:
    static ProxyManager *active();

    int proxyType() const;
    void setProxyType(int type);

    QString host() const;
    void setHost(const QString &host);

    int port() const;
    void setPort(int port);

    bool requiresAuth() const;
    void setRequiresAuth(bool requiresAuth);

    QString username() const;
    void setUsername(const QString &username);

    QString noProxyList() const;
    void setNoProxyList(const QString &list);

    bool hasPassword() const;

    /** @brief Set the proxy password. Pass an empty string to clear it. */
    Q_INVOKABLE void setPassword(const QString &password);

    /** @brief The proxy password in plaintext. Empty when none is set. */
    Q_INVOKABLE QString password() const;

    /**
     * @brief Try to connect to 127.0.0.1:10808 (V2Ray/Xray's default local SOCKS inbound).
     * @return true if a local V2Ray/Xray client appears to be listening there.
     */
    Q_INVOKABLE bool detectLocalV2Ray();

    /** @brief Point this proxy config at the local V2Ray/Xray SOCKS inbound (127.0.0.1:10808). */
    Q_INVOKABLE void useLocalV2Ray();

    /**
     * @brief Build the effective outbound proxy URL for the current settings, e.g.
     *        "http://user:pass@host:port" or "socks5://host:port". Empty when
     *        proxyType() == None or Auto (Auto has no URL of ours to give -
     *        see GitProxyOptions::apply() for how GIT_PROXY_AUTO is set instead).
     *        For VMess/VLess this is always the local SOCKS inbound URL (see
     *        class docs).
     */
    Q_INVOKABLE QString effectiveProxyUrl() const;

    /**
     * @brief Build a QNetworkProxy from the current live settings. The single
     *        source of truth for "current settings -> QNetworkProxy" - shared by
     *        applyToQtNetwork() (and its bypass-aware QNetworkProxyFactory) and by
     *        NetworkManager (so plugin/update HTTP traffic gets the same proxy)
     *        instead of each rebuilding this logic themselves.
     */
    QNetworkProxy buildQNetworkProxy() const;

    /**
     * @brief Push the current proxy configuration into Qt's application-wide
     *        QNetworkProxy (and installs a bypass-aware QNetworkProxyFactory).
     *        Called automatically from every setter, and once from main() at
     *        startup. Safe to call any time.
     */
    Q_INVOKABLE void applyToQtNetwork();

    /**
     * @brief Shared bypass-list matcher used by both the Qt-side factory and the
     *        libgit2-side GitProxyOptions helper - the single source of truth for
     *        "no proxy for" matching so the two never drift apart.
     *
     * Supports:
     *  - exact hostname match ("internal.example.com")
     *  - wildcard suffix match ("*.example.com")
     *  - CIDR match ("10.0.0.0/8", "192.168.1.0/24")
     *
     * @param host Bare hostname (no scheme/port), e.g. from QUrl::host().
     * @param noProxyList Comma-separated list of the patterns above.
     */
    static bool isHostBypassed(const QString &host, const QString &noProxyList);

    /**
     * @brief Serialize the persisted fields - password included - to a QVariantMap,
     *        for ProxyController to store into AppSettings' ProxySettings model
     *        (written out by AppModel.save()).
     */
    Q_INVOKABLE QVariantMap serialize() const;

    /**
     * @brief Restore the persisted connection fields from a QVariantMap previously
     *        produced by serialize(), for ProxyController to push the loaded
     *        settings into the live proxy. Missing keys fall back to their defaults.
     */
    Q_INVOKABLE void deserialize(const QVariantMap &data);

signals:
    void proxyTypeChanged();
    void hostChanged();
    void portChanged();
    void requiresAuthChanged();
    void usernameChanged();
    void noProxyListChanged();
    void passwordChanged();
    void hasPasswordChanged();

private:
    int     m_proxyType    = None;
    QString m_host;
    int     m_port         = 0;
    bool    m_requiresAuth = false;
    QString m_username;
    QString m_password;
    QString m_noProxyList;
};
