#pragma once

#include "IGitAuth.h"
#include <QString>


/**
 * @brief SSH authentication using SSH agent or default keys.
 */
class GitSshAuth : public IGitAuth
{

private:
    QString m_privateKeyPath;

    static int credentialsCallback(
        git_cred** out,
        const char* url,
        const char* username_from_url,
        unsigned int allowed_types,
        void* payload
        );

public:

    explicit GitSshAuth(const QString& privateKeyPath = "",
                        QObject* parent = nullptr);

    ~GitSshAuth() override = default;

    void apply(git_fetch_options& fetchOpts) override;
};
