#include "OperationResult.h"

namespace OperationResult {

QVariantMap failure(const QString &message)
{
    QVariantMap result;
    result[QStringLiteral("success")] = false;
    result[QStringLiteral("errorMessage")] = message;
    return result;
}

QVariantMap success()
{
    QVariantMap result;
    result[QStringLiteral("success")] = true;
    return result;
}

} // namespace OperationResult
