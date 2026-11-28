#include "WindowCornerMaskLinux.hpp"

#include <QtGui/QSurfaceFormat>
#include <QtQuick/QQuickWindow>
#include <QtQuick/QSGFlatColorMaterial>
#include <QtQuick/QSGGeometryNode>
#include <QtQuick/QSGVertexColorMaterial>

#include <algorithm>
#include <array>
#include <cmath>

namespace {

constexpr qreal kPi = 3.14159265358979323846;

// Stays above everything else in the window, including the Controls overlay (popups, tooltips).
constexpr qreal kTopMostZ = 1.0e12;

// One rounded corner: the arc around `center` from angle `from` to `to` (radians, y pointing down),
// listed clockwise starting at the top-left so consecutive corners form a closed outline.
struct Corner
{
    QPointF center;
    qreal   from;
    qreal   to;
};

std::array<Corner, 4> cornersOf(qreal width, qreal height, qreal radius)
{
    return {{
        { QPointF(radius,         radius),          kPi,        1.5 * kPi },
        { QPointF(width - radius, radius),          1.5 * kPi,  2.0 * kPi },
        { QPointF(width - radius, height - radius), 0.0,        0.5 * kPi },
        { QPointF(radius,         height - radius), 0.5 * kPi,  kPi       },
    }};
}

QPointF pointOnArc(const Corner& corner, qreal radius, qreal angle)
{
    return corner.center + QPointF(std::cos(angle), std::sin(angle)) * radius;
}

qreal angleAt(const Corner& corner, int step, int segments)
{
    return corner.from + (corner.to - corner.from) * step / segments;
}

/*! Triangles covering, in each corner, the area between the window's square corner and the arc. The
 *  arc is pulled slightly inwards so every pixel the border's outer anti-aliasing touches is cleared
 *  first; otherwise the opaque content would show through those half-covered pixels. */
void fillClearGeometry(QSGGeometry* geometry, const std::array<Corner, 4>& corners,
                       qreal radius, qreal devicePixel, int segments)
{
    const qreal arcRadius = radius - 0.4 * devicePixel;

    // Per corner: a fan around the square corner over the points edge, arc (segments + 1), edge.
    const int pointsPerCorner = segments + 3;
    geometry->allocate(4 * (pointsPerCorner - 1) * 3);
    QSGGeometry::Point2D* vertex = geometry->vertexDataAsPoint2D();

    for (const Corner& corner : corners) {
        const QPointF squareCorner = corner.center
                                     + QPointF(std::cos(corner.from) + std::cos(corner.to),
                                               std::sin(corner.from) + std::sin(corner.to)) * radius;

        auto fanPoint = [&](int index) {
            if (index == 0)
                return pointOnArc(corner, radius, corner.from);
            if (index == pointsPerCorner - 1)
                return pointOnArc(corner, radius, corner.to);
            return pointOnArc(corner, arcRadius, angleAt(corner, index - 1, segments));
        };

        for (int i = 0; i + 1 < pointsPerCorner; ++i) {
            const QPointF a = fanPoint(i);
            const QPointF b = fanPoint(i + 1);
            (vertex++)->set(squareCorner.x(), squareCorner.y());
            (vertex++)->set(a.x(), a.y());
            (vertex++)->set(b.x(), b.y());
        }
    }
}

/*! A 1 device-pixel border along the rounded outline, anti-aliased on both sides: three outlines at
 *  -0.5, +0.5 and +1.5 device pixels from the edge, transparent / solid / transparent, joined by
 *  triangle strips. */
void fillBorderGeometry(QSGGeometry* geometry, const std::array<Corner, 4>& corners,
                        qreal radius, qreal devicePixel, int segments, const QColor& color)
{
    struct Outline { qreal inset; qreal alpha; };
    const std::array<Outline, 3> outlines{{
        { -0.5 * devicePixel, 0.0 },
        {  0.5 * devicePixel, 1.0 },
        {  1.5 * devicePixel, 0.0 },
    }};

    const int pointsPerOutline = 4 * (segments + 1);
    const int strips = int(outlines.size()) - 1;
    geometry->allocate(int(outlines.size()) * pointsPerOutline, strips * pointsPerOutline * 6);

    QSGGeometry::ColoredPoint2D* vertex = geometry->vertexDataAsColoredPoint2D();
    for (const Outline& outline : outlines) {
        // Vertex colors are premultiplied.
        const qreal alpha = outline.alpha * color.alphaF();
        const auto r = uchar(qRound(color.red()   * alpha));
        const auto g = uchar(qRound(color.green() * alpha));
        const auto b = uchar(qRound(color.blue()  * alpha));
        const auto a = uchar(qRound(255 * alpha));

        for (const Corner& corner : corners) {
            for (int step = 0; step <= segments; ++step) {
                const QPointF p = pointOnArc(corner, radius - outline.inset,
                                             angleAt(corner, step, segments));
                (vertex++)->set(float(p.x()), float(p.y()), r, g, b, a);
            }
        }
    }

    quint16* index = geometry->indexDataAsUShort();
    for (int strip = 0; strip < strips; ++strip) {
        const int outer = strip * pointsPerOutline;
        const int inner = outer + pointsPerOutline;
        for (int i = 0; i < pointsPerOutline; ++i) {
            const int next = (i + 1) % pointsPerOutline;
            *index++ = quint16(outer + i);
            *index++ = quint16(inner + i);
            *index++ = quint16(outer + next);
            *index++ = quint16(outer + next);
            *index++ = quint16(inner + i);
            *index++ = quint16(inner + next);
        }
    }
}

} // namespace

WindowCornerMaskLinux::WindowCornerMaskLinux(QQuickWindow* window)
    : QQuickItem(window->contentItem())
    , m_window(window)
{
    setFlag(ItemHasContents);
    setAcceptedMouseButtons(Qt::NoButton);
    setZ(kTopMostZ);

    connect(window, &QWindow::widthChanged,       this, &WindowCornerMaskLinux::syncWithWindow);
    connect(window, &QWindow::heightChanged,      this, &WindowCornerMaskLinux::syncWithWindow);
    connect(window, &QWindow::windowStateChanged, this, &WindowCornerMaskLinux::syncWithWindow);

    syncWithWindow();
}

void WindowCornerMaskLinux::requestAlphaChannel(QWindow* window)
{
    QSurfaceFormat format = window->requestedFormat();
    if (format.alphaBufferSize() >= 8)
        return;

    format.setAlphaBufferSize(8);
    window->setFormat(format);
}

void WindowCornerMaskLinux::syncWithWindow()
{
    if (!m_window)
        return;

    setSize(m_window->size());

    // Like Windows 11: square corners once the window fills the screen.
    setVisible(!(m_window->windowStates() & (Qt::WindowMaximized | Qt::WindowFullScreen)));

    update();
}

void WindowCornerMaskLinux::itemChange(ItemChange change, const ItemChangeData& value)
{
    if (change == ItemDevicePixelRatioHasChanged)
        update();

    QQuickItem::itemChange(change, value);
}

QSGNode* WindowCornerMaskLinux::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData*)
{
    const qreal radius = std::min({ m_radius, width() / 2, height() / 2 });
    if (!m_window || radius <= 0) {
        delete oldNode;
        return nullptr;
    }

    QSGNode*         root       = oldNode;
    QSGGeometryNode* clearNode  = nullptr;
    QSGGeometryNode* borderNode = nullptr;

    if (!root) {
        root = new QSGNode;

        // Writes (0,0,0,0) without blending. Clearing the Blending flag also puts the node in the
        // renderer's opaque pass, whose depth writes keep the content underneath out of the corners.
        auto* clearMaterial = new QSGFlatColorMaterial;
        clearMaterial->setColor(Qt::transparent);
        clearMaterial->setFlag(QSGMaterial::Blending, false);

        clearNode = new QSGGeometryNode;
        clearNode->setGeometry(new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), 0));
        clearNode->geometry()->setDrawingMode(QSGGeometry::DrawTriangles);
        clearNode->setMaterial(clearMaterial);
        clearNode->setFlags(QSGNode::OwnsGeometry | QSGNode::OwnsMaterial);

        borderNode = new QSGGeometryNode;
        borderNode->setGeometry(new QSGGeometry(QSGGeometry::defaultAttributes_ColoredPoint2D(), 0, 0,
                                                QSGGeometry::UnsignedShortType));
        borderNode->geometry()->setDrawingMode(QSGGeometry::DrawTriangles);
        borderNode->setMaterial(new QSGVertexColorMaterial);
        borderNode->setFlags(QSGNode::OwnsGeometry | QSGNode::OwnsMaterial);

        // Border after the clear so it blends over the cleared pixels.
        root->appendChildNode(clearNode);
        root->appendChildNode(borderNode);
    } else {
        clearNode  = static_cast<QSGGeometryNode*>(root->firstChild());
        borderNode = static_cast<QSGGeometryNode*>(clearNode->nextSibling());
    }

    const qreal devicePixelRatio = m_window->effectiveDevicePixelRatio();
    const qreal devicePixel      = 1.0 / devicePixelRatio;
    const int   segments         = std::clamp(int(std::ceil(radius * devicePixelRatio)), 8, 48);
    const auto  corners          = cornersOf(width(), height(), radius);

    fillClearGeometry(clearNode->geometry(), corners, radius, devicePixel, segments);
    clearNode->markDirty(QSGNode::DirtyGeometry);

    fillBorderGeometry(borderNode->geometry(), corners, radius, devicePixel, segments, m_borderColor);
    borderNode->markDirty(QSGNode::DirtyGeometry);

    return root;
}
