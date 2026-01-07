#include "GitResult.h"

#include "GitUtils.h"

GitResult::GitResult()
{}

GitResult::GitResult(bool success, const QVariant &data, const QString &errorMessage)
    :   m_success(success),
        m_errorMessage(errorMessage),
        m_data(data)
{
    if (!m_success && m_errorMessage.isEmpty()) {
        m_errorMessage = GitUtils::getLastError();
    } else if (!m_success && !m_errorMessage.isEmpty()) {
        m_errorMessage.append(" | " + GitUtils::getLastError());
    }
}

bool GitResult::success() const
{
    return m_success;
}



QString GitResult::errorMessage() const
{
    return m_errorMessage;
}


QVariant GitResult::data() const
{
    return m_data;
}




