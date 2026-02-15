#pragma once

#include <QString>
#include <QUrl>

/**
 * @brief Utility class for detecting Git repository protocols.
 *
 * Provides functionality to determine whether a Git URL uses SSH, HTTP, or HTTPS protocols,
 * and other Git URL parsing utilities.
 */
class GitProtocolDetector
{
public:
    /**
     * @brief Enumeration for Git protocols
     */
    enum class GitProtocol {
        Unknown = 0,  ///< Unknown or unsupported protocol
        SSH = 1,      ///< SSH protocol (git@ or ssh://)
        HTTP = 2,     ///< HTTP protocol
        HTTPS = 3     ///< HTTPS protocol
    };

    /**
     * @brief Detect the protocol used in a Git repository URL.
     *
     * Supports the following URL formats:
     * - SSH: git@github.com:owner/repo.git
     * - SSH: ssh://git@github.com/owner/repo.git
     * - HTTPS: https://github.com/owner/repo.git
     * - HTTP: http://github.com/owner/repo.git
     *
     * @param url The Git repository URL
     * @return The detected protocol, or Unknown if the URL format is not recognized
     */
    static GitProtocol detectProtocol(const QString& url);

    /**
     * @brief Check if a URL uses SSH protocol.
     *
     * @param url The Git repository URL
     * @return true if the URL is an SSH URL, false otherwise
     */
    static bool isSshUrl(const QString& url);

    /**
     * @brief Check if a URL uses HTTPS protocol.
     *
     * @param url The Git repository URL
     * @return true if the URL is an HTTPS URL, false otherwise
     */
    static bool isHttpsUrl(const QString& url);

    /**
     * @brief Check if a URL uses HTTP protocol.
     *
     * @param url The Git repository URL
     * @return true if the URL is an HTTP URL, false otherwise
     */
    static bool isHttpUrl(const QString& url);

    /**
     * @brief Extract the repository name from a Git URL.
     *
     * Extracts the repository name (last path segment) from a Git URL,
     * removing the .git extension if present.
     *
     * @param url The Git repository URL
     * @return The repository name, or an empty string if extraction fails
     */
    static QString extractRepositoryName(const QString& url);
};
