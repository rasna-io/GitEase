#pragma once

#include <QtCore/QObject>
#include <QtCore/QPointer>
#include <QtCore/QAbstractNativeEventFilter>
#include <QtGui/QWindow>

#ifdef Q_OS_WIN
#  include <windows.h>
#  include <dwmapi.h>
#endif

class BorderlessWindowHelper final
    : public QObject
    , public QAbstractNativeEventFilter
{
    Q_OBJECT
public:
    explicit BorderlessWindowHelper(QWindow* window, QObject* parent = nullptr);
    ~BorderlessWindowHelper() override = default;

    bool nativeEventFilter(const QByteArray& eventType, void* message, qintptr* result) override;

    QSize minimumSize() const;
    void setMinimumSize(const QSize &newSize);

private:
#ifdef Q_OS_WIN
    void attach();
    void ensureWindowStyles();
    void setupDwmShadow();
    static UINT dpiForWindow(HWND h);
    static int smForDpi(int index, UINT dpi);
    static int resizeBorderThicknessX(HWND h);
    static int resizeBorderThicknessY(HWND h);

    void applyBorderlessNow();
#endif

private:
    QPointer<QWindow> m_window;

    QSize m_minimumSize;
#ifdef Q_OS_WIN
    HWND m_hwnd = nullptr;
#endif
};
