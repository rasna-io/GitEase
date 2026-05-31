#include "taskbarhelper.hpp"

#include <QGuiApplication>
#include <QSvgRenderer>
#include <QPainter>
#include <QPixmap>
#include <QImage>

TaskbarHelper *TaskbarHelper::s_instance = nullptr;

TaskbarHelper::TaskbarHelper(QObject *parent)
    : QObject(parent)
    , m_color(QColor(0, 0, 255, 127))
    , m_repoName("main")
{
    s_instance = this;
}

TaskbarHelper::~TaskbarHelper() {
    if (m_currentIcon) {
        DestroyIcon(m_currentIcon);
        m_currentIcon = nullptr;
    }
}

void TaskbarHelper::setRepoInfo(const QColor &color, const QString &name) {
    m_repoName = name;
    m_color = color;

    HICON newIcon = createTintedIcon(m_color);
    if (!newIcon)
        return;

    if (m_currentIcon) {
        DestroyIcon(m_currentIcon);
    }
    m_currentIcon = newIcon;

    applyInfoToAllWindows();
}

bool TaskbarHelper::isValidHwnd(HWND hwnd) const {
    return hwnd && IsWindow(hwnd);
}

HICON TaskbarHelper::createTintedIcon(const QColor &tintColor) const {
    constexpr int SIZE = 256;

    QSvgRenderer renderer(QStringLiteral(":/GitEase/Resources/Images/LogoSVG.svg"));
    if (!renderer.isValid())
        return nullptr;

    QPixmap pixmap(SIZE, SIZE);
    pixmap.fill(Qt::transparent);

    {
        QPainter svgPainter(&pixmap);
        renderer.render(&svgPainter);
    }

    {
        QPainter tintPainter(&pixmap);
        tintPainter.setCompositionMode(QPainter::CompositionMode_SourceAtop);

        QColor overlay = tintColor;
        overlay.setAlphaF(1);
        tintPainter.fillRect(pixmap.rect(), overlay);
    }

    QImage img = pixmap.toImage().convertToFormat(QImage::Format_ARGB32);
    if (img.isNull())
        return nullptr;

    HICON icon = img.toHICON();
    return icon;
}

void TaskbarHelper::setWindowIcons(HWND hwnd) {
    if (!isValidHwnd(hwnd))
        return;

    if(!m_currentIcon)
        return;

    const LPARAM lparam = reinterpret_cast<LPARAM>(m_currentIcon);

    SendMessage(hwnd, WM_SETICON, ICON_BIG, lparam);
    SendMessage(hwnd, WM_SETICON, ICON_SMALL, lparam);
    SendMessage(hwnd, WM_SETICON, ICON_SMALL2, lparam);
}

void TaskbarHelper::setWindowTitles(HWND hwnd)
{
    if (!isValidHwnd(hwnd))
        return;

    int len = GetWindowTextLengthW(hwnd);
    if (len <= 0)
        return;

    std::wstring current(len + 1, L'\0');
    GetWindowTextW(hwnd, current.data(), len + 1);
    current.resize(len);

    QString newTitle = QString::fromStdWString(current);

    newTitle = newTitle.remove(QRegularExpression(R"(\s*\[.*?\])")).trimmed();

    newTitle += QString(" [%1]").arg(m_repoName);

    SetWindowTextW(hwnd, newTitle.toStdWString().c_str());
}

void TaskbarHelper::applyInfoToAllWindows() {
    const auto windows = QGuiApplication::allWindows();
    for (QWindow *win : windows) {
        applyInfoToWindow(win);
    }
}

void TaskbarHelper::applyInfoToWindow(QWindow *window) {
    if (!window)
        return;

    HWND hwnd = reinterpret_cast<HWND>(window->winId());

    if (isValidHwnd(hwnd)) {
        setWindowIcons(hwnd);
        setWindowTitles(hwnd);
    }
}

