#pragma once

#include <QColor>
#include <QList>
#include <QObject>
#include <QPointer>
#include <QString>

class QWindow;
class DropperWindow;

/*!
 * \brief Picks a color from anywhere on the screen.
 *
 * start() takes a snapshot of every screen and covers each one with a frameless full-screen
 * window that shows it again. The mouse cursor becomes an eyedropper and a magnifier next to it
 * shows the pixel under the cursor with its Hex, RGB and HSL values while the mouse moves.
 * A left click picks, Esc or a right click cancels. Afterwards the window that had the focus
 * before is activated again.
 *
 * Working from a snapshot means the picked color is the one that was visible when the picker
 * was started, and that any window of any application can be picked from, GitEase included.
 */
class EyeDropper : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)

public:
    explicit EyeDropper(QObject *parent = nullptr);
    ~EyeDropper() override;

    bool active() const;

    //! Starts picking; does nothing while a pick is already running.
    Q_INVOKABLE void start();

    //! Ends picking without a result.
    Q_INVOKABLE void cancel();

signals:
    //! The user clicked a pixel. \a hex is "#rrggbb".
    void picked(const QString &hex, int red, int green, int blue);

    //! The color under the cursor changed (live, while picking).
    void hovered(const QString &hex);

    //! Picking ended without a color.
    void canceled();

    void activeChanged();

private:
    friend class DropperWindow;

    void finish(const QColor &color);
    void abort();
    void hover(const QColor &color);
    void closeWindows();

    QList<QPointer<DropperWindow>> m_windows;
    QPointer<QWindow>              m_previous;
    bool                           m_active = false;
};
