#include "GitProxyOptions.h"

#include "ProxyManager.h"

GitProxyOptions::GitProxyOptions(const QString &remoteHost)
    : m_mode(GIT_PROXY_NONE)
{
    const ProxyManager *pmPtr = ProxyManager::active();
    if (!pmPtr)
        return;

    const ProxyManager &pm = *pmPtr;

    const bool proxyConfigured = pm.proxyType() != ProxyManager::None;
    const bool bypassed = ProxyManager::isHostBypassed(remoteHost, pm.noProxyList());

    if (!proxyConfigured || bypassed)
        return;

    if (pm.proxyType() == ProxyManager::Auto) {
        m_mode = GIT_PROXY_AUTO;
        return;
    }

    m_url = pm.effectiveProxyUrl().toUtf8();
    if (!m_url.isEmpty())
        m_mode = GIT_PROXY_SPECIFIED;
}

void GitProxyOptions::apply(git_proxy_options &opts) const
{
    opts.type = m_mode;
    opts.url  = (m_mode == GIT_PROXY_SPECIFIED && !m_url.isEmpty()) ? m_url.constData() : nullptr;
}

bool GitProxyOptions::isEnabled() const
{
    return m_mode != GIT_PROXY_NONE;
}
