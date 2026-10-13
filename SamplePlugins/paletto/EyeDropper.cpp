#include "EyeDropper.h"

#include <QCursor>
#include <QEvent>
#include <QFont>
#include <QGuiApplication>
#include <QImage>
#include <QKeyEvent>
#include <QMouseEvent>
#include <QPainter>
#include <QPixmap>
#include <QRasterWindow>
#include <QScreen>

namespace {

constexpr int kGrid     = 15;                 // magnified pixels per side (odd: one is the center)
constexpr int kCell     = 9;                  // device-independent size of one magnified pixel
constexpr int kLoupe    = kGrid * kCell;
constexpr int kPad      = 8;
constexpr int kPanelW   = kLoupe + 2 * kPad;
constexpr int kLineH    = 17;
constexpr int kPanelH   = kPad + kLoupe + kPad + 18 + 8 + 3 * kLineH + kPad;
constexpr int kOffset   = 26;                 // distance of the panel from the cursor

//! A small eyedropper whose tip is the hot spot.
QCursor dropperCursor()
{
    QPixmap pixmap(32, 32);
    pixmap.fill(Qt::transparent);

    QPainter p(&pixmap);
    p.setRenderHint(QPainter::Antialiasing);

    const QPointF tip(4, 28);
    const QPointF top(20, 12);

    p.setPen(QPen(QColor(0, 0, 0, 230), 8, Qt::SolidLine, Qt::RoundCap));
    p.drawLine(tip + QPointF(1.5, -1.5), top);
    p.setPen(QPen(QColor(245, 245, 245), 5, Qt::SolidLine, Qt::RoundCap));
    p.drawLine(tip + QPointF(1.5, -1.5), top);

    p.setPen(QPen(QColor(0, 0, 0, 230), 2));
    p.setBrush(QColor(70, 74, 86));
    p.drawEllipse(QPointF(23, 9), 6.5, 6.5);

    p.setPen(QPen(QColor(0, 0, 0, 230), 1.5));
    p.setBrush(Qt::white);
    p.drawEllipse(tip, 1.8, 1.8);
    p.end();

    return QCursor(pixmap, 4, 28);
}

QString hexOf(const QColor &c)
{
    return c.name(QColor::HexRgb);
}

} // namespace

/*! One of these covers each screen. */
class DropperWindow : public QRasterWindow
{
public:
    DropperWindow(EyeDropper *owner, QScreen *screen, const QImage &shot)
        : m_owner(owner), m_shot(shot)
    {
        setScreen(screen);
        setGeometry(screen->geometry());
        setFlags(Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint | Qt::Tool);
        setCursor(dropperCursor());

        const QPoint local = QCursor::pos() - screen->geometry().topLeft();
        if(QRect(QPoint(0, 0), screen->geometry().size()).contains(local)) {
            m_pos = local;
            m_inside = true;
        }
    }

    bool containsCursor() const
    {
        return m_inside;
    }

    QColor currentColor() const
    {
        return colorAt(m_pos);
    }

protected:
    void paintEvent(QPaintEvent *) override
    {
        QPainter p(this);
        p.drawImage(QRect(QPoint(0, 0), size()), m_shot);

        if(!m_inside) {
            return;
        }

        const qreal ratio = m_shot.devicePixelRatio();
        const int sx = qBound(0, int(m_pos.x() * ratio), m_shot.width() - 1);
        const int sy = qBound(0, int(m_pos.y() * ratio), m_shot.height() - 1);
        const QColor color = QColor::fromRgb(m_shot.pixel(sx, sy));

        // Panel position: bottom right of the cursor, flipped near the edges.
        int px = m_pos.x() + kOffset;
        int py = m_pos.y() + kOffset;
        if(px + kPanelW > width() - 4) {
            px = m_pos.x() - kOffset - kPanelW;
        }
        if(py + kPanelH > height() - 4) {
            py = m_pos.y() - kOffset - kPanelH;
        }
        px = qMax(4, px);
        py = qMax(4, py);

        p.setRenderHint(QPainter::Antialiasing);
        p.setPen(QPen(QColor(255, 255, 255, 40), 1));
        p.setBrush(QColor(20, 22, 28, 238));
        p.drawRoundedRect(QRectF(px + 0.5, py + 0.5, kPanelW, kPanelH), 10, 10);

        // Magnifier: each source pixel drawn as a kCell square, no smoothing.
        const QRect loupe(px + kPad, py + kPad, kLoupe, kLoupe);
        p.setRenderHint(QPainter::SmoothPixmapTransform, false);
        p.fillRect(loupe, QColor(40, 42, 50));
        const int half = kGrid / 2;
        p.setClipRect(loupe);
        p.drawImage(loupe, m_shot, QRect(sx - half, sy - half, kGrid, kGrid));
        p.setClipping(false);

        // Frame and center marker.
        p.setBrush(Qt::NoBrush);
        p.setPen(QPen(QColor(255, 255, 255, 70), 1));
        p.drawRect(loupe);
        const QRect center(loupe.x() + half * kCell, loupe.y() + half * kCell, kCell, kCell);
        p.setPen(QPen(QColor(0, 0, 0), 2));
        p.drawRect(center.adjusted(-1, -1, 1, 1));
        p.setPen(QPen(QColor(255, 255, 255), 1));
        p.drawRect(center);

        // Swatch and values.
        int y = py + kPad + kLoupe + kPad;
        p.setPen(QPen(QColor(255, 255, 255, 60), 1));
        p.setBrush(color);
        p.drawRoundedRect(QRectF(px + kPad + 0.5, y + 0.5, kLoupe - 1, 18), 5, 5);
        y += 18 + 8;

        QFont mono(QStringLiteral("JetBrains Mono"));
        mono.setStyleHint(QFont::Monospace);
        mono.setPixelSize(12);
        p.setFont(mono);

        const int hue = qMax(0, color.hslHue());
        const QStringList lines = {
            hexOf(color).toUpper(),
            QStringLiteral("RGB  %1, %2, %3").arg(color.red()).arg(color.green()).arg(color.blue()),
            QStringLiteral("HSL  %1°, %2%, %3%")
                .arg(hue)
                .arg(qRound(color.hslSaturationF() * 100))
                .arg(qRound(color.lightnessF() * 100)),
        };
        p.setPen(QColor(235, 238, 245));
        for(int i = 0; i < lines.size(); ++i) {
            QFont f = mono;
            f.setBold(i == 0);
            p.setFont(f);
            p.drawText(QRect(px + kPad, y + i * kLineH, kLoupe, kLineH),
                       Qt::AlignVCenter | Qt::AlignLeft, lines.at(i));
        }
    }

    void mouseMoveEvent(QMouseEvent *event) override
    {
        m_pos = event->position().toPoint();
        m_inside = true;
        update();
        m_owner->hover(colorAt(m_pos));
    }

    void mouseReleaseEvent(QMouseEvent *event) override
    {
        // Picked on release: the press is swallowed here, so the click cannot reach the window
        // below.
        if(event->button() == Qt::LeftButton) {
            m_owner->finish(colorAt(event->position().toPoint()));
        } else if(event->button() == Qt::RightButton) {
            m_owner->abort();
        }
    }

    void keyPressEvent(QKeyEvent *event) override
    {
        if(event->key() == Qt::Key_Escape) {
            m_owner->abort();
        } else {
            QRasterWindow::keyPressEvent(event);
        }
    }

    bool event(QEvent *event) override
    {
        if(event->type() == QEvent::Leave) {
            m_inside = false;
            update();
        }
        return QRasterWindow::event(event);
    }

private:
    QColor colorAt(const QPoint &pos) const
    {
        const qreal ratio = m_shot.devicePixelRatio();
        const int x = qBound(0, int(pos.x() * ratio), m_shot.width() - 1);
        const int y = qBound(0, int(pos.y() * ratio), m_shot.height() - 1);
        return QColor::fromRgb(m_shot.pixel(x, y));
    }

    EyeDropper *m_owner;
    QImage      m_shot;
    QPoint      m_pos;
    bool        m_inside = false;
};

EyeDropper::EyeDropper(QObject *parent)
    : QObject(parent)
{
}

EyeDropper::~EyeDropper()
{
    closeWindows();
}

bool EyeDropper::active() const
{
    return m_active;
}

void EyeDropper::start()
{
    if(m_active) {
        return;
    }

    const QList<QScreen *> screens = QGuiApplication::screens();
    if(screens.isEmpty()) {
        return;
    }

    m_previous = QGuiApplication::focusWindow();

    // Snapshot first, then show: the overlays must not be part of the picture.
    struct Shot { QScreen *screen; QImage image; };
    QList<Shot> shots;
    for(QScreen *screen : screens) {
        QImage image = screen->grabWindow(0).toImage();
        if(!image.isNull()) {
            shots.append({ screen, image });
        }
    }
    if(shots.isEmpty()) {
        return;
    }

    m_active = true;
    emit activeChanged();

    DropperWindow *under = nullptr;
    for(const Shot &shot : std::as_const(shots)) {
        auto *window = new DropperWindow(this, shot.screen, shot.image);
        m_windows.append(window);
        window->showFullScreen();
        if(window->containsCursor()) {
            under = window;
        }
    }

    DropperWindow *focus = under ? under : m_windows.first().data();
    if(focus) {
        focus->raise();
        focus->requestActivate();
        emit hovered(hexOf(focus->currentColor()));
    }
}

void EyeDropper::cancel()
{
    abort();
}

void EyeDropper::hover(const QColor &color)
{
    emit hovered(hexOf(color));
}

void EyeDropper::closeWindows()
{
    for(const QPointer<DropperWindow> &window : std::as_const(m_windows)) {
        if(window) {
            window->close();
            window->deleteLater();
        }
    }
    m_windows.clear();
}

void EyeDropper::finish(const QColor &color)
{
    if(!m_active) {
        return;
    }

    closeWindows();
    m_active = false;
    emit activeChanged();

    // Back to the program that asked for the color.
    if(m_previous) {
        m_previous->raise();
        m_previous->requestActivate();
    }

    emit picked(hexOf(color), color.red(), color.green(), color.blue());
}

void EyeDropper::abort()
{
    if(!m_active) {
        return;
    }

    closeWindows();
    m_active = false;
    emit activeChanged();

    if(m_previous) {
        m_previous->raise();
        m_previous->requestActivate();
    }
    emit canceled();
}
