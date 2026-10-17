#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>

/*!
 * \brief QML-facing helper of the Paletto page.
 *
 * The page edits the host's color tokens live from QML; this class does the parts QML cannot:
 * listing the tokens of a Colors object, validating colors, keeping the library of saved palettes
 * and reading / writing palette files.
 *
 * A palette is { name, base, colors }. "base" is the theme it was made from and "colors" holds
 * only the tokens that differ from that theme, as "#rrggbb" or "#aarrggbb".
 */
class PalettoEngine : public QObject
{
    Q_OBJECT

public:
    explicit PalettoEngine(QObject *parent = nullptr);

    // -- Tokens --------------------------------------------------------------------------------

    /*!
     * Every color property of \a colors in declaration order, as { name, label, group, value }.
     * Empty when \a colors is null.
     */
    Q_INVOKABLE QVariantList tokens(QObject *colors) const;

    //! name -> "#rrggbb" / "#aarrggbb" for every color property of \a colors.
    Q_INVOKABLE QVariantMap snapshot(QObject *colors) const;

    //! Canonical form of a color text ("#rgb", "#rrggbb", "#aarrggbb" or a name); empty when invalid.
    Q_INVOKABLE QString normalizeColor(const QString &text) const;

    //! The groups tokens are sorted into, in display order.
    Q_INVOKABLE QStringList groups() const;

    // -- Library -------------------------------------------------------------------------------

    //! Saved palettes: { name, base, colors, count }. Sorted by name.
    Q_INVOKABLE QVariantList palettes() const;

    //! Stores or replaces the palette \a name. Keys: success, errorMessage.
    Q_INVOKABLE QVariantMap savePalette(const QString &name, const QString &base,
                                        const QVariantMap &colors);

    //! Removes the palette \a name. Keys: success, errorMessage.
    Q_INVOKABLE QVariantMap deletePalette(const QString &name);

    // -- Files ---------------------------------------------------------------------------------

    //! Writes a palette file. Keys: success, errorMessage.
    Q_INVOKABLE QVariantMap exportPalette(const QString &path, const QString &name,
                                          const QString &base, const QVariantMap &colors) const;

    //! Reads a palette file. Keys: success, errorMessage, name, base, colors, skipped.
    Q_INVOKABLE QVariantMap importPalette(const QString &path) const;

    //! Local file path of a file dialog result (also accepts plain paths).
    Q_INVOKABLE QString localPath(const QUrl &url) const;

    //! "My Palette" -> "My-Palette.paletto.json"
    Q_INVOKABLE QString suggestedFileName(const QString &name) const;

    //! Suggested save location for the export dialog: the documents folder plus the file name.
    Q_INVOKABLE QUrl suggestedExportUrl(const QString &name) const;

private:
    QString libraryPath() const;
    QVariantList readLibrary() const;
    bool writeLibrary(const QVariantList &library, QString *error) const;
};
