#include "borderlesswindowhelper.h"

#include <QtCore/QCoreApplication>
#include <QtCore/QOperatingSystemVersion>


#ifdef Q_OS_WIN
#include <windowsx.h>
#  pragma comment(lib, "dwmapi.lib")
#endif

BorderlessWindowHelper::BorderlessWindowHelper(QWindow* window, QObject* parent)
    : QObject(parent)
    , m_window(window)
{
    if (!m_window)
        return;

    // Ensure native handle exists.
    m_window->create();
#ifdef Q_OS_WIN

    m_hwnd = reinterpret_cast<HWND>(m_window->winId());

    attach();

    applyBorderlessNow();
#endif

#ifdef Q_OS_LINUX
    m_window->setFlags(Qt::Window | Qt::FramelessWindowHint);
#endif
}

#ifdef Q_OS_WIN

void BorderlessWindowHelper::attach()
{
    ensureWindowStyles();
    setupDwmShadow();

    // Install app-wide native filter once.
    qApp->installNativeEventFilter(this);

}
#endif

#ifdef Q_OS_WIN
void BorderlessWindowHelper::ensureWindowStyles()
{
    if (!m_hwnd) return;

    // Keep normal overlapped window styles so Windows still treats it as a standard resizable window
    // (snap, shake, system behaviors depend on these).
    LONG_PTR style = ::GetWindowLongPtrW(m_hwnd, GWL_STYLE);
    // style |= WS_OVERLAPPEDWINDOW; // includes WS_CAPTION, WS_THICKFRAME, WS_MINIMIZEBOX, WS_MAXIMIZEBOX, WS_SYSMENU
    style |= (WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
    style &= ~WS_CAPTION; // <- crucial: no native title bar even when maximized
    ::SetWindowLongPtrW(m_hwnd, GWL_STYLE, style);

    LONG_PTR ex = ::GetWindowLongPtrW(m_hwnd, GWL_EXSTYLE);
    // Keep WS_EX_APPWINDOW, drop toolwindow-ness if any
    ex &= ~WS_EX_TOOLWINDOW;
    ex |= WS_EX_APPWINDOW;
    ::SetWindowLongPtrW(m_hwnd, GWL_EXSTYLE, ex);

    // Tell Windows styles changed (recalc non-client)
    ::SetWindowPos(m_hwnd, nullptr, 0,0,0,0,
                   SWP_FRAMECHANGED | SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER);
}
#endif

#ifdef Q_OS_WIN
void BorderlessWindowHelper::setupDwmShadow()
{
    if (!m_hwnd) return;

    BOOL comp = FALSE;
    if (SUCCEEDED(::DwmIsCompositionEnabled(&comp)) && comp)
    {
        // Tell DWM to consider this window for non-client rendering (shadows, transitions).
        // Then extend a *tiny* frame into the client area to keep the native shadow.
        const MARGINS m{1,1,1,1}; // 1px is enough to keep the shadow alive
        ::DwmExtendFrameIntoClientArea(m_hwnd, &m);

        const int enable = 1;
        ::DwmSetWindowAttribute(m_hwnd, DWMWA_NCRENDERING_ENABLED, (void*)&enable, sizeof(enable));

        // niceties (Windows 11 backdrop). Harmless on older versions:
        const int backdrop = 2; // DWMSBT_MAINWINDOW (if available)
        ::DwmSetWindowAttribute(m_hwnd, 38 /*DWMWA_SYSTEMBACKDROP_TYPE*/, (void*)&backdrop, sizeof(backdrop));
    }
}
#endif

#ifdef Q_OS_WIN
UINT BorderlessWindowHelper::dpiForWindow(HWND h)
{
    // Try GetDpiForWindow (Win10+), else fallback to DC DPI.
    HMODULE user32 = ::GetModuleHandleW(L"user32.dll");
    auto pGetDpiForWindow = reinterpret_cast<UINT (WINAPI*)(HWND)>(::GetProcAddress(user32, "GetDpiForWindow"));
    if (pGetDpiForWindow)
        return pGetDpiForWindow(h);

    HDC hdc = ::GetDC(h);
    const UINT dpi = static_cast<UINT>(::GetDeviceCaps(hdc, LOGPIXELSX));
    ::ReleaseDC(h, hdc);
    return dpi ? dpi : 96;
}
#endif

#ifdef Q_OS_WIN
int BorderlessWindowHelper::smForDpi(int index, UINT dpi)
{
    HMODULE user32 = ::GetModuleHandleW(L"user32.dll");
    auto pGetSystemMetricsForDpi =
        reinterpret_cast<int (WINAPI*)(int, UINT)>(::GetProcAddress(user32, "GetSystemMetricsForDpi"));
    if (pGetSystemMetricsForDpi)
        return pGetSystemMetricsForDpi(index, dpi);
    return ::GetSystemMetrics(index);
}
#endif

#ifdef Q_OS_WIN

int BorderlessWindowHelper::resizeBorderThicknessX(HWND h)
{
    const UINT dpi = dpiForWindow(h);
    // sizeframe + padded border = effective resize thickness
    return smForDpi(SM_CXSIZEFRAME, dpi) + smForDpi(SM_CXPADDEDBORDER, dpi);
}
#endif

#ifdef Q_OS_WIN
int BorderlessWindowHelper::resizeBorderThicknessY(HWND h)
{
    const UINT dpi = dpiForWindow(h);
    return smForDpi(SM_CYSIZEFRAME, dpi) + smForDpi(SM_CXPADDEDBORDER, dpi);
}
#endif

#ifdef Q_OS_WIN
void BorderlessWindowHelper::applyBorderlessNow()
{

    if (!m_hwnd) return;

    // Re-assert styles (no caption, keep thickframe/system boxes)
    ensureWindowStyles();

    // Force Windows to recalc the non-client area right now
    ::SetWindowPos(m_hwnd, nullptr, 0,0,0,0,
                   SWP_FRAMECHANGED | SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER);

    // Set DWM margins based on current state (no 1px leak in max/fullscreen)
    const bool maximized  = !!::IsZoomed(m_hwnd);
    const bool fullscreen = m_window && (m_window->windowState() & Qt::WindowFullScreen);
    const MARGINS m = (maximized || fullscreen) ? MARGINS{0,0,0,0} : MARGINS{1,1,1,1};
    ::DwmExtendFrameIntoClientArea(m_hwnd, &m);

}
#endif

QSize BorderlessWindowHelper::minimumSize() const
{
    return m_minimumSize;
}

void BorderlessWindowHelper::setMinimumSize(const QSize &newSize)
{
    m_minimumSize = newSize;
}


bool BorderlessWindowHelper::nativeEventFilter(const QByteArray& eventType, void* message, qintptr* result)
{
#ifdef Q_OS_WIN
    if (!m_window || !m_hwnd)
        return false;

    if (eventType != "windows_generic_MSG" && eventType != "windows_dispatcher_MSG")
        return false;

    MSG* msg = static_cast<MSG*>(message);

    switch (msg->message)
    {
    case WM_NCCALCSIZE:
    {
        // Make the client area cover the whole window (hide native titlebar/borders),
        // but keep normal window styles so OS features still apply.
        if (msg->wParam) {
            auto* p = reinterpret_cast<NCCALCSIZE_PARAMS*>(msg->lParam);
            RECT& r = p->rgrc[0];

            if (::IsZoomed(m_hwnd)) {
                HMONITOR mon = ::MonitorFromWindow(m_hwnd, MONITOR_DEFAULTTONEAREST);
                MONITORINFO mi{ sizeof(MONITORINFO) };
                ::GetMonitorInfoW(mon, &mi);

                // Full client = monitor work area (no extra tweaks)
                r = mi.rcWork;
            }
        }
        *result = 0;
        return true;
    }

    case WM_STYLECHANGING:
    {
        if (msg->wParam == GWL_STYLE) {
            auto* ss = reinterpret_cast<STYLESTRUCT*>(msg->lParam);
            ss->styleNew |= (WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
            ss->styleNew &= ~WS_CAPTION; // never allow the native title
        }
        return false;
    }

    case WM_STYLECHANGED:
    {
        // belt-and-suspenders: force a frame recalculation if styles changed
        ::SetWindowPos(m_hwnd, nullptr, 0,0,0,0,
                       SWP_FRAMECHANGED | SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER);
        return false;
    }

    case WM_SHOWWINDOW:
    {
        if (msg->wParam) { // becoming visible
            // Reassert styles and framecalc
            ensureWindowStyles();
            ::SetWindowPos(m_hwnd, nullptr, 0,0,0,0,
                           SWP_FRAMECHANGED | SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER);

            // Set initial DWM margins based on state (no leaks)
            const bool maximized  = !!(::IsZoomed(m_hwnd));
            const bool fullscreen = m_window && (m_window->windowState() & Qt::WindowFullScreen);
            const MARGINS m = (maximized || fullscreen) ? MARGINS{0,0,0,0} : MARGINS{1,1,1,1};
            ::DwmExtendFrameIntoClientArea(m_hwnd, &m);


            DWORD borderColor = RGB(0,0,0);
            ::DwmSetWindowAttribute(m_hwnd, 34, &borderColor, sizeof(borderColor));
        }
        return false;
    }

    case WM_NCHITTEST:
    {
        // Provide native resize borders. We *don’t* return HTCAPTION here,
        // because we want QML to initiate move via startSystemMove(), so buttons remain clickable.
        // This keeps resizing 100% native while your header logic stays in QML.
        const LONG x = GET_X_LPARAM(msg->lParam);
        const LONG y = GET_Y_LPARAM(msg->lParam);

        RECT wr{};
        ::GetWindowRect(m_hwnd, &wr);

        const int borderX = resizeBorderThicknessX(m_hwnd);
        const int borderY = resizeBorderThicknessY(m_hwnd);

        const bool left   = x >= wr.left  && x < wr.left + borderX;
        const bool right  = x <= wr.right && x > wr.right - borderX;
        const bool top    = y >= wr.top   && y < wr.top  + borderY;
        const bool bottom = y <= wr.bottom&& y > wr.bottom- borderY;

        if (top && left)    { *result = HTTOPLEFT;  return true; }
        if (top && right)   { *result = HTTOPRIGHT; return true; }
        if (bottom && left) { *result = HTBOTTOMLEFT; return true; }
        if (bottom && right){ *result = HTBOTTOMRIGHT; return true; }
        if (left)           { *result = HTLEFT;     return true; }
        if (right)          { *result = HTRIGHT;    return true; }
        if (top)            { *result = HTTOP;      return true; }
        if (bottom)         { *result = HTBOTTOM;   return true; }

        // Interior: normal client (QML handles clicks/drags; use startSystemMove())
        return false;
    }

    case WM_GETMINMAXINFO:
    {
        // Ensure maximize uses the work area (not the monitor bounds), since we removed the standard frame.
        auto* mmi = reinterpret_cast<MINMAXINFO*>(msg->lParam);
        HMONITOR mon = ::MonitorFromWindow(m_hwnd, MONITOR_DEFAULTTONEAREST);
        MONITORINFO mi{ sizeof(MONITORINFO) };
        ::GetMonitorInfoW(mon, &mi);

        const RECT wa = mi.rcWork;
        const RECT mm = mi.rcMonitor;

        mmi->ptMaxPosition.x = wa.left - mm.left;
        mmi->ptMaxPosition.y = wa.top  - mm.top;
        mmi->ptMaxSize.x     = wa.right  - wa.left;
        mmi->ptMaxSize.y     = wa.bottom - wa.top;

        if (m_minimumSize.width()  > 0)
            mmi->ptMinTrackSize.x = std::max<LONG>(mmi->ptMinTrackSize.x, m_minimumSize.width());
        if (m_minimumSize.height() > 0)
            mmi->ptMinTrackSize.y = std::max<LONG>(mmi->ptMinTrackSize.y, m_minimumSize.height());


        *result = 0;
        return true;
    }

    case WM_NCACTIVATE:
        // Prevent the default non-client painting flicker.
        *result = TRUE;
        return true;

    // Prevent any non-client painting (belt-and-suspenders)
    case WM_NCPAINT:
        *result = 0;
        return true;

    // Undocumented but used by the theme helper to draw caption/frame on Win10/11
    case 0x00AE: /* WM_NCUAHDRAWCAPTION */
    case 0x00AF: /* WM_NCUAHDRAWFRAME */
        *result = 0;
        return true;

    case WM_SIZE:
    {
        const bool maximized = (msg->wParam == SIZE_MAXIMIZED);
        const bool fullscreen = m_window && (m_window->windowState() & Qt::WindowFullScreen);
        const MARGINS m = (maximized || fullscreen) ? MARGINS{0,0,0,0} : MARGINS{1,1,1,1};
        ::DwmExtendFrameIntoClientArea(m_hwnd, &m);
        return false;
    }

    default:
        break;
    }
#endif

    return false;
}

