#include "WindowResizerLinux.hpp"

#include <QtGui/QMouseEvent>

namespace {

// Same band as the Windows hit test (SM_CXSIZEFRAME + SM_CXPADDEDBORDER at 100% scale); corners are
// where two bands overlap, 8x8 like on Windows.
constexpr qreal kBorder = 8.0;

Qt::CursorShape cursorFor(Qt::Edges edges)
{
    const bool left   = edges & Qt::LeftEdge;
    const bool right  = edges & Qt::RightEdge;
    const bool top    = edges & Qt::TopEdge;
    const bool bottom = edges & Qt::BottomEdge;

    if ((top && left) || (bottom && right))
        return Qt::SizeFDiagCursor;
    if ((top && right) || (bottom && left))
        return Qt::SizeBDiagCursor;
    if (left || right)
        return Qt::SizeHorCursor;
    return Qt::SizeVerCursor;
}

} // namespace

WindowResizerLinux::WindowResizerLinux(QWindow* window, QObject* parent)
    : QObject(parent)
    , m_window(window)
{
    if (m_window)
        m_window->installEventFilter(this);
}

WindowResizerLinux::~WindowResizerLinux()
{
    if (m_window) {
        restoreCursor();
        m_window->removeEventFilter(this);
    }
}

bool WindowResizerLinux::isResizable() const
{
    if (!m_window)
        return false;

    // Like Windows: no resize borders while maximized or fullscreen.
    if (m_window->windowStates() & (Qt::WindowMaximized | Qt::WindowFullScreen | Qt::WindowMinimized))
        return false;

    const QSize min = m_window->minimumSize();
    const QSize max = m_window->maximumSize();
    return min.width() < max.width() || min.height() < max.height();
}

Qt::Edges WindowResizerLinux::edgesAt(const QPointF& position) const
{
    if (!isResizable())
        return {};

    const qreal x = position.x();
    const qreal y = position.y();
    const qreal w = m_window->width();
    const qreal h = m_window->height();

    Qt::Edges edges;
    if (x < kBorder)      edges |= Qt::LeftEdge;
    if (x >= w - kBorder) edges |= Qt::RightEdge;
    if (y < kBorder)      edges |= Qt::TopEdge;
    if (y >= h - kBorder) edges |= Qt::BottomEdge;

    return edges;
}

void WindowResizerLinux::showResizeCursor(Qt::Edges edges)
{
    // Remember what the scene had set (I-beam, pointing hand...) to put it back on the way out.
    if (!m_cursorOverridden) {
        m_savedCursor      = m_window->cursor();
        m_cursorOverridden = true;
    }
    m_window->setCursor(cursorFor(edges));
}

void WindowResizerLinux::restoreCursor()
{
    if (!m_cursorOverridden)
        return;

    m_cursorOverridden = false;
    if (m_window)
        m_window->setCursor(m_savedCursor);
}

bool WindowResizerLinux::eventFilter(QObject* watched, QEvent* event)
{
    if (watched != m_window)
        return false;

    switch (event->type()) {
    case QEvent::MouseMove:
    {
        auto* mouse = static_cast<QMouseEvent*>(event);

        // Leave drags that started inside the window (text selection, splitters...) alone.
        if (mouse->buttons() != Qt::NoButton)
            return false;

        const Qt::Edges edges = edgesAt(mouse->position());
        if (!edges) {
            restoreCursor();
            return false;
        }

        // Keep the scene from hovering items under the band and swapping the cursor back.
        showResizeCursor(edges);
        return true;
    }

    case QEvent::MouseButtonPress:
    case QEvent::MouseButtonDblClick:
    {
        auto* mouse = static_cast<QMouseEvent*>(event);
        if (mouse->button() != Qt::LeftButton)
            return false;

        const Qt::Edges edges = edgesAt(mouse->position());
        if (!edges)
            return false;

        if (event->type() == QEvent::MouseButtonPress)
            m_window->startSystemResize(edges);

        // The band belongs to the frame, as on Windows: nothing underneath gets the click.
        return true;
    }

    case QEvent::Leave:
    case QEvent::WindowStateChange:
        restoreCursor();
        return false;

    default:
        return false;
    }
}
