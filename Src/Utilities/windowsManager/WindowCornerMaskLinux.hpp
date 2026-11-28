#pragma once

#include <QtCore/QPointer>
#include <QtGui/QColor>
#include <QtQuick/QQuickItem>

class QQuickWindow;

/*! ***********************************************************************************************
 * WindowCornerMaskLinux
 * Gives an opaque frameless QQuickWindow the Windows 11 window shape on Linux, where the window
 * manager does not round it for us: an anti-aliased rounded outline with a 1px border, and square
 * corners while maximized or fullscreen.
 *
 * It sits on top of the whole scene and
 *  - overwrites the pixels outside the rounded outline with full transparency (an opaque, non-blended
 *    draw, so the depth buffer also keeps everything below it out of those pixels), and
 *  - strokes the border along the outline, which also anti-aliases the cut edge.
 * The window needs an alpha channel for the cleared pixels to show the desktop.
 * ************************************************************************************************/
class WindowCornerMaskLinux final : public QQuickItem
{
    Q_OBJECT
public:
    explicit WindowCornerMaskLinux(QQuickWindow* window);

    /*! Requests an alpha channel for \a window; call before its platform window is created. */
    static void requestAlphaChannel(QWindow* window);

protected:
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) override;
    void itemChange(ItemChange change, const ItemChangeData& value) override;

private:
    void syncWithWindow();

private:
    QPointer<QQuickWindow> m_window;

    qreal  m_radius      = 8.0;             // Windows 11 window corner radius (logical px)
    QColor m_borderColor = QColor(0, 0, 0); // matches DWMWA_BORDER_COLOR in BorderlessWindowHelper
};
