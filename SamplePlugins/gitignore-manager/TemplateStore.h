#pragma once

#include "IgnoreFile.h"

#include <QList>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

/*!
 * The template catalog: the templates bundled in the plugin, the ones the user wrote and the
 * customized copies of bundled ones. User data lives in the roaming app data next to the
 * notifications, in a "gitignore-templates" folder.
 */
namespace TemplateStore {

struct Info
{
    QString id;
    QString name;
    QString category;
    QString description;
};

//! Custom templates first, then the bundled ones.
QList<Info> index();

//! Text of the template \a id as it is used: the customized copy when there is one.
QString read(const QString &id);

//! Text a bundled template ships with, ignoring any customization; empty for custom ones.
QString readDefault(const QString &id);

//! The catalog for QML: { id, name, category, description, rules, custom, customized }.
QVariantList catalog();

//! Ids of the templates that have a marker section in \a lines.
QStringList appliedIds(const QStringList &lines);

struct ApplyResult
{
    QStringList applied;
    QStringList skipped;
    int         addedRules = 0;
};

/*!
 * Appends the templates \a ids as marked sections to \a file (in memory). Patterns the file
 * already has, and templates that are already applied, are skipped.
 */
ApplyResult applyTo(IgnoreFile &file, const QStringList &ids);

//! Stores a template of the user. Keys: success, errorMessage, id.
QVariantMap saveCustom(const QString &name, const QString &content);

//! Deletes the user's template \a id ("user:" + name).
QVariantMap deleteCustom(const QString &id);

//! Keeps \a content as the customized copy of the bundled template \a id.
QVariantMap saveOverride(const QString &id, const QString &content);

//! Drops the customized copy of the bundled template \a id.
QVariantMap resetOverride(const QString &id);

} // namespace TemplateStore
