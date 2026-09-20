#include "ProxyManager.h"

#include <QHostAddress>
#include <QNetworkProxy>
#include <QNetworkProxyFactory>
#include <QPair>
#include <QPointer>
#include <QStringList>
#include <QTcpSocket>
#include <QUrl>

namespace {

const char *kLocalV2RayHost = "127.0.0.1";
const int   kLocalV2RayPort = 10808;

void resolveEffectiveHostPort(const ProxyManager &pm, QString &outHost, int &outPort)
{
    if (pm.proxyType() == ProxyManager::VMess || pm.proxyType() == ProxyManager::VLess) {
        outHost = QString::fromLatin1(kLocalV2RayHost);
        outPort = kLocalV2RayPort;
    } else {
        outHost = pm.host();
        outPort = pm.port();
    }
}

class ProxyNetworkFactory : public QNetworkProxyFactory
{
public:
    explicit ProxyNetworkFactory(ProxyManager *pm) : m_pm(pm) {}

    QList<QNetworkProxy> queryProxy(const QNetworkProxyQuery &query) override
    {
        if (!m_pm || m_pm->proxyType() == ProxyManager::None)
            return { QNetworkProxy(QNetworkProxy::NoProxy) };

        const QString host = query.peerHostName();
        if (!host.isEmpty() && ProxyManager::isHostBypassed(host, m_pm->noProxyList()))
            return { QNetworkProxy(QNetworkProxy::NoProxy) };

        return { m_pm->buildQNetworkProxy() };
    }

private:
    QPointer<ProxyManager> m_pm;
};

ProxyManager *s_active = nullptr;

} // namespace

ProxyManager *ProxyManager::active()
{
    return s_active;
}

ProxyManager::ProxyManager(QObject *parent)
    : QObject(parent)
{
    if (!s_active)
        s_active = this;
}

ProxyManager::~ProxyManager()
{
    if (s_active == this)
        s_active = nullptr;
}

int ProxyManager::proxyType() const
{
    return m_proxyType;
}

QString ProxyManager::host() const
{
    return m_host;
}

int ProxyManager::port() const
{
    return m_port;
}

bool ProxyManager::requiresAuth() const
{
    return m_requiresAuth;
}

QString ProxyManager::username() const
{
    return m_username;
}

QString ProxyManager::noProxyList() const
{
    return m_noProxyList;
}

void ProxyManager::setProxyType(int type)
{
    if (m_proxyType == type)
        return;

    m_proxyType = type;

    emit proxyTypeChanged();
    applyToQtNetwork();
}

void ProxyManager::setHost(const QString &host)
{
    if (m_host == host)
        return;

    m_host = host;

    emit hostChanged();
    applyToQtNetwork();
}

void ProxyManager::setPort(int port)
{
    if (m_port == port)
        return;

    m_port = port;

    emit portChanged();
    applyToQtNetwork();
}

void ProxyManager::setRequiresAuth(bool requiresAuth)
{
    if (m_requiresAuth == requiresAuth)
        return;

    m_requiresAuth = requiresAuth;

    emit requiresAuthChanged();
    applyToQtNetwork();
}

void ProxyManager::setUsername(const QString &username)
{
    if (m_username == username)
        return;

    m_username = username;

    emit usernameChanged();
    applyToQtNetwork();
}

void ProxyManager::setNoProxyList(const QString &list)
{
    if (m_noProxyList == list)
        return;

    m_noProxyList = list;

    emit noProxyListChanged();
    // No need to rebuild the QNetworkProxy object itself - both the Qt factory
    // and GitProxyOptions read this value live on every query/operation.
}

QVariantMap ProxyManager::serialize() const
{
    QVariantMap data;
    data[QStringLiteral("proxyType")]    = m_proxyType;
    data[QStringLiteral("host")]         = m_host;
    data[QStringLiteral("port")]         = m_port;
    data[QStringLiteral("requiresAuth")] = m_requiresAuth;
    data[QStringLiteral("username")]     = m_username;
    data[QStringLiteral("password")]     = m_password;
    data[QStringLiteral("noProxyList")]  = m_noProxyList;
    return data;
}

void ProxyManager::deserialize(const QVariantMap &data)
{
    setProxyType(data.value(QStringLiteral("proxyType"), None).toInt());
    setHost(data.value(QStringLiteral("host")).toString());
    setPort(data.value(QStringLiteral("port"), 0).toInt());
    setRequiresAuth(data.value(QStringLiteral("requiresAuth"), false).toBool());
    setUsername(data.value(QStringLiteral("username")).toString());
    setPassword(data.value(QStringLiteral("password")).toString());
    setNoProxyList(data.value(QStringLiteral("noProxyList")).toString());
}

bool ProxyManager::hasPassword() const
{
    return !m_password.isEmpty();
}

void ProxyManager::setPassword(const QString &password)
{
    if (m_password == password)
        return;

    const bool hadPassword = hasPassword();

    m_password = password;

    applyToQtNetwork();

    emit passwordChanged();

    if (hadPassword != hasPassword())
        emit hasPasswordChanged();
}

QString ProxyManager::password() const
{
    return m_password;
}

bool ProxyManager::detectLocalV2Ray()
{
    QTcpSocket socket;
    socket.connectToHost(QString::fromLatin1(kLocalV2RayHost), kLocalV2RayPort);
    const bool connected = socket.waitForConnected(300);
    if (connected)
        socket.disconnectFromHost();
    return connected;
}

void ProxyManager::useLocalV2Ray()
{
    setProxyType(Socks5);
    setHost(QString::fromLatin1(kLocalV2RayHost));
    setPort(kLocalV2RayPort);
    setRequiresAuth(false);
}

QString ProxyManager::effectiveProxyUrl() const
{
    const int type = proxyType();
    if (type == None || type == Auto)
        return QString();

    QString host;
    int port = 0;
    resolveEffectiveHostPort(*this, host, port);

    if (host.isEmpty())
        return QString();

    QString scheme;
    switch (type) {
        case Http:
            scheme = QStringLiteral("http");
            break;
        case Socks5:
        case VMess:
        case VLess:
            scheme = QStringLiteral("socks5");
            break;
        default:
            return QString();
    }

    QString auth;
    const bool authApplies = requiresAuth() && type != VMess && type != VLess;
    if (authApplies) {
        const QString user = QString::fromUtf8(QUrl::toPercentEncoding(username()));
        const QString pass = QString::fromUtf8(QUrl::toPercentEncoding(password()));
        if (!user.isEmpty() || !pass.isEmpty())
            auth = user + QStringLiteral(":") + pass + QStringLiteral("@");
    }

    return QStringLiteral("%1://%2%3:%4").arg(scheme, auth, host, QString::number(port));
}

QNetworkProxy ProxyManager::buildQNetworkProxy() const
{
    const int type = proxyType();

    if (type == None)
        return QNetworkProxy(QNetworkProxy::NoProxy);

    if (type == Auto) {
        const QList<QNetworkProxy> candidates = QNetworkProxyFactory::systemProxyForQuery();
        for (const QNetworkProxy &candidate : candidates) {
            if (candidate.type() != QNetworkProxy::NoProxy)
                return candidate;
        }
        return QNetworkProxy(QNetworkProxy::NoProxy);
    }

    QString host;
    int port = 0;
    resolveEffectiveHostPort(*this, host, port);

    if (host.isEmpty())
        return QNetworkProxy(QNetworkProxy::NoProxy);

    const QNetworkProxy::ProxyType qtType = (type == Http)
                                                 ? QNetworkProxy::HttpProxy
                                                 : QNetworkProxy::Socks5Proxy;

    QNetworkProxy proxy(qtType, host, static_cast<quint16>(port));

    const bool authApplies = requiresAuth() && type != VMess && type != VLess;
    if (authApplies) {
        proxy.setUser(username());
        proxy.setPassword(password());
    }

    return proxy;
}

void ProxyManager::applyToQtNetwork()
{
    QNetworkProxy::setApplicationProxy(buildQNetworkProxy());
    QNetworkProxyFactory::setApplicationProxyFactory(new ProxyNetworkFactory(this));
}

bool ProxyManager::isHostBypassed(const QString &host, const QString &noProxyList)
{
    if (host.isEmpty() || noProxyList.trimmed().isEmpty())
        return false;

    const QString normalizedHost = host.trimmed().toLower();
    const QStringList patterns = noProxyList.split(QLatin1Char(','), Qt::SkipEmptyParts);

    for (const QString &rawPattern : patterns) {
        const QString pattern = rawPattern.trimmed();
        if (pattern.isEmpty())
            continue;

        if (pattern.contains(QLatin1Char('/'))) {
            const QPair<QHostAddress, int> subnet = QHostAddress::parseSubnet(pattern);
            if (subnet.second < 0)
                continue;

            const QHostAddress hostAddr(normalizedHost);
            if (!hostAddr.isNull() && hostAddr.isInSubnet(subnet))
                return true;

            continue;
        }

        const QString normalizedPattern = pattern.toLower();

        if (normalizedPattern.startsWith(QStringLiteral("*."))) {
            const QString bareDomain = normalizedPattern.mid(2);      // "example.com"
            const QString dotSuffix  = normalizedPattern.mid(1);      // ".example.com"
            if (normalizedHost == bareDomain || normalizedHost.endsWith(dotSuffix))
                return true;

            continue;
        }

        if (normalizedHost == normalizedPattern)
            return true;
    }

    return false;
}
