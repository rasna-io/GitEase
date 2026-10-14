#pragma once

#include <QString>
#include <QVariantMap>

/*!
 * Results handed to QML are plain maps: { success: true, ... } on success and
 * { success: false, errorMessage } on failure.
 */
namespace OperationResult {

//! { success: false, errorMessage: \a message }.
QVariantMap failure(const QString &message);

//! { success: true }, to which callers add their own keys.
QVariantMap success();

} // namespace OperationResult
