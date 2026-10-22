#pragma once

#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

/*!
 * Edits the rules of the root .gitignore. Functions that write take the repository \a root and
 * return an OperationResult map. Taking files out of the index is the host's job (GitIgnore).
 */
namespace RuleEditor {

//! Appends the patterns that are not already in the file. Keys: success, added, skipped.
QVariantMap addPatterns(const QString &root, const QStringList &patterns);

/*!
 * Groups the rules that ignore \a paths into one entry per rule. \a hits is the data of
 * GitIgnore::checkIgnore(): a list of { path, source, line, pattern }.
 * Keys: success, rules ({ line, pattern, source, editable, paths }), unresolved.
 * Only rules of the root .gitignore are editable.
 */
QVariantMap planUnignore(const QStringList &paths, const QVariantList &hits);

//! Deletes rules ({ line, pattern }). Refuses when the file changed since planUnignore().
QVariantMap removeRules(const QString &root, const QVariantList &rules);

} // namespace RuleEditor
