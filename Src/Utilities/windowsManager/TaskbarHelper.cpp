#include "TaskbarHelper.hpp"

#include <QCoreApplication>
#include <QGuiApplication>
#include <QSvgRenderer>
#include <QPainter>
#include <QPixmap>
#include <QImage>
#include <QProcess>
#include <QRegularExpression>

#ifdef Q_OS_WIN
#include <QSvgRenderer>

#include <objbase.h>
#include <propkey.h>
#include <propsys.h>
#include <shellapi.h>
#endif

namespace {

#ifdef Q_OS_WIN
class ScopedComInitialization
{
public:
    ScopedComInitialization()
        : m_result(CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED))
    {
    }

    ~ScopedComInitialization()
    {
        if (SUCCEEDED(m_result))
            CoUninitialize();
    }

    bool isUsable() const
    {
        return SUCCEEDED(m_result) || m_result == RPC_E_CHANGED_MODE;
    }

private:
    HRESULT m_result;
};
#endif

} // namespace

TaskbarHelper *TaskbarHelper::s_instance = nullptr;

TaskbarHelper::TaskbarHelper(QObject *parent)
    : QObject(parent)
    , m_color(QColor(0, 0, 255, 127))
    , m_repoName("main")
{
#ifdef Q_OS_WIN
    initializeProcessTaskbarIdentity();
#endif
    s_instance = this;
}

TaskbarHelper::~TaskbarHelper()
{
#ifdef Q_OS_WIN
    if (m_currentIcon) {
        DestroyIcon(m_currentIcon);
        m_currentIcon = nullptr;
    }
#endif
}

void TaskbarHelper::setRepoInfo(const QColor &color, const QString &name)
{
    m_repoName = name;
    m_color = color;

#ifdef Q_OS_WIN
    HICON newIcon = createTintedIcon(m_color);
    if (!newIcon)
        return;

    if (m_currentIcon)
        DestroyIcon(m_currentIcon);

    m_currentIcon = newIcon;

    applyInfoToAllWindows();
#endif
}

QString TaskbarHelper::appUserModelId() const
{
#ifdef Q_OS_WIN
    return QStringLiteral("GitEase.Instance.%1").arg(GetCurrentProcessId());
#else
    return {};
#endif
}

#ifdef Q_OS_WIN

void TaskbarHelper::initializeProcessTaskbarIdentity() const
{
    const std::wstring appId = appUserModelId().toStdWString();
    SetCurrentProcessExplicitAppUserModelID(appId.c_str());
}
#endif

#ifdef Q_OS_WIN
bool TaskbarHelper::isValidHwnd(HWND hwnd) const
{
    return hwnd && IsWindow(hwnd);
}
#endif

#ifdef Q_OS_WIN
HICON TaskbarHelper::createTintedIcon(const QColor &tintColor) const
{
    constexpr int SIZE = 256;

    QSvgRenderer renderer(QStringLiteral(":/GitEase/Resources/Images/LogoSVG.svg"));
    if (!renderer.isValid())
        return nullptr;

    QPixmap pixmap(SIZE, SIZE);
    pixmap.fill(Qt::transparent);

    QPainter svgPainter(&pixmap);
    renderer.render(&svgPainter);

    QPainter tintPainter(&pixmap);
    tintPainter.setCompositionMode(QPainter::CompositionMode_SourceAtop);

    QColor overlay = tintColor;
    overlay.setAlphaF(1.0);
    tintPainter.fillRect(pixmap.rect(), overlay);

    QImage img = pixmap.toImage().convertToFormat(QImage::Format_ARGB32);
    if (img.isNull())
        return nullptr;

    return img.toHICON();
}
#endif

#ifdef Q_OS_WIN
void TaskbarHelper::setWindowIcons(HWND hwnd)
{
    if (!isValidHwnd(hwnd) || !m_currentIcon)
        return;

    LPARAM lparam = reinterpret_cast<LPARAM>(m_currentIcon);

    SendMessage(hwnd, WM_SETICON, ICON_BIG, lparam);
    SendMessage(hwnd, WM_SETICON, ICON_SMALL, lparam);
    SendMessage(hwnd, WM_SETICON, ICON_SMALL2, lparam);
}
#endif

#ifdef Q_OS_WIN
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
#endif

#ifdef Q_OS_WIN
void TaskbarHelper::applyInfoToAllWindows()
{
    const auto windows = QGuiApplication::allWindows();
    for (QWindow *win : windows)
        applyInfoToWindow(win);
}
#endif

#ifdef Q_OS_WIN
void TaskbarHelper::setWindowAppUserModelId(HWND hwnd) const
{
    if (!isValidHwnd(hwnd))
        return;

    ScopedComInitialization com;
    if (!com.isUsable())
        return;

    IPropertyStore *propertyStore = nullptr;
    HRESULT result = SHGetPropertyStoreForWindow(
        hwnd,
        IID_IPropertyStore,
        reinterpret_cast<void **>(&propertyStore));

    if (FAILED(result) || !propertyStore)
        return;

    const std::wstring appId = appUserModelId().toStdWString();

    PROPVARIANT value = {};
    value.vt = VT_LPWSTR;
    value.pwszVal = const_cast<PWSTR>(appId.c_str());

    result = propertyStore->SetValue(PKEY_AppUserModel_ID, value);
    if (SUCCEEDED(result))
        propertyStore->Commit();

    propertyStore->Release();
}
#endif

void TaskbarHelper::applyInfoToWindow(QWindow *window)
{
    if (!window)
        return;

#ifdef Q_OS_WIN
    HWND hwnd = reinterpret_cast<HWND>(window->winId());

    if (isValidHwnd(hwnd)) {
        setWindowAppUserModelId(hwnd);
        setWindowIcons(hwnd);
        setWindowTitles(hwnd);
    }
#endif
}

void TaskbarHelper::launchNewInstance(const QString &repoPath)
{
    if (repoPath.isEmpty())
        return;

    QString pathArg = QString("--path=%1").arg(repoPath);
    QProcess::startDetached(QCoreApplication::applicationFilePath(), {pathArg});
}