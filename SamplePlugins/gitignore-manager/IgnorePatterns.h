#pragma once

#include <QString>
#include <QStringList>
#include <QVariantList>

/*! Turns files and folders into the rules that would ignore them. */
namespace IgnorePatterns {

/*!
 * Rules that ignore \a entries ({ path, isDir } maps), without duplicates.
 *
 * \a mode is one of:
 *  - "exact"     /dir/file.txt
 *  - "name"      file.txt, anywhere
 *  - "extension" *.txt (falls back to exact for folders and files without an extension)
 *  - "folder"    /dir/ (falls back to exact for files in the root)
 */
QStringList build(const QVariantList &entries, const QString &mode);

} // namespace IgnorePatterns
