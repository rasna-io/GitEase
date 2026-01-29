#pragma once

#include "IGitAuth.h"
#include <QString>

/**
 * @brief HTTPS authentication using username + token/password.
 */
class GitHttpsAuth : public IGitAuth
{
private:
    QString m_username;
    QString m_password;

    static int credentialsCallback(
        git_cred** out,
        const char* url,
        const char* username_from_url,
        unsigned int allowed_types,
        void* payload
        );

public:
    GitHttpsAuth(const QString& username,
                 const QString& password,
                 QObject* parent = nullptr);

    ~GitHttpsAuth() override = default;

    void apply(git_fetch_options& fetchOpts) override;


};
