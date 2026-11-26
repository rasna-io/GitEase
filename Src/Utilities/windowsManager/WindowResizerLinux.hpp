#pragma once

#include <QtCore/QObject>
#include <QtCore/QPointer>
#include <QtGui/QCursor>
#include <QtGui/QWindow>

/*! ***********************************************************************************************
 * WindowResizerLinux
 * Resize borders for a frameless window on Linux. On Windows the helper answers WM_NCHITTEST so the
 * system resizes the window from an 8px band along its edges; a frameless Linux window has no such
 * band, so this watches the window's mouse events and does the same: the resize cursor over the
 * band, and a press there hands the resize to the window manager (QWindow::startSystemResize), which
 * keeps it native, including the window's minimum size.
 * ************************************************************************************************/
class WindowResizerLinux final : public QObject
{
    Q_OBJECT
public:
    explicit WindowResizerLinux(QWindow* window, QObject* parent = nullptr);
    ~WindowResizerLinux() override;

protected:
    bool eventFilter(QObject* watched, QEvent* event) override;

private:
    Qt::Edges edgesAt(const QPointF& position) const;
    bool isResizable() const;

    void showResizeCursor(Qt::Edges edges);
    void restoreCursor();

private:
    QPointer<QWindow> m_window;

    bool    m_cursorOverridden = false;
    QCursor m_savedCursor;
};
