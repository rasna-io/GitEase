#pragma once

#include <QByteArray>
#include <QString>

#include <git2.h>

/**
 * @brief Builds a libgit2 `git_proxy_options` from the app-wide ProxyManager (ProxyManager::active()).
 *
 * Mirrors the style of GitProtocolDetector: a small, focused helper living in
 * Src/Git/Utilities. Reads the live proxy configuration for a given remote host,
 * honors the no-proxy/bypass list, and produces a `git_proxy_options` the caller
 * can hand directly to git_clone / git_remote_fetch / git_remote_push.
 *
 * IMPORTANT lifetime note: `apply()` sets `opts.url` to point into this instance's
 * internal buffer (m_url). The GitProxyOptions instance MUST be kept alive on the
 * stack for the entire duration of the libgit2 call that uses those options -
 * exactly like GitRepository::GitPayload is kept alive for its callbacks.
 */
class GitProxyOptions
{
public:
    /**
     * @brief Resolve the effective proxy configuration for a remote host.
     * @param remoteHost The hostname (not full URL) of the remote being contacted,
     *                    e.g. QUrl(url).host() or QUrl(git_remote_url(remote)).host().
     */
    explicit GitProxyOptions(const QString &remoteHost);

    /**
     * @brief Apply the resolved proxy configuration to libgit2 proxy options.
     *
     * Sets opts.type/opts.url to one of:
     *  - GIT_PROXY_SPECIFIED, opts.url pointing at this instance's internal URL
     *    buffer - an explicit Http/Socks5/VMess/VLess proxy applies.
     *  - GIT_PROXY_AUTO, opts.url null - ProxyManager::Auto: let libgit2 detect
     *    the proxy itself from the git configuration/environment.
     *  - GIT_PROXY_NONE, opts.url null - no proxy configured, or this host is
     *    bypassed via the no-proxy list.
     * Does not touch credentials/certificate_check/payload.
     */
    void apply(git_proxy_options &opts) const;

    /** @brief Whether a proxy will actually be used for this host. */
    bool isEnabled() const;

private:
    QByteArray  m_url;
    git_proxy_t m_mode;
};
