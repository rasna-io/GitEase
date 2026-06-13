#pragma once

#include <QObject>
#include <QColor>
#include <QtQmlIntegration>
#include <QWindow>

#ifdef Q_OS_WIN
#include <windows.h>
#include <shobjidl.h>
#endif

class TaskbarHelper final : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    static TaskbarHelper *instance() { return s_instance; }

public:
    explicit TaskbarHelper(QObject *parent = nullptr);
    ~TaskbarHelper() override;

    Q_INVOKABLE void setRepoInfo(const QColor &color, const QString &name);

    void applyInfoToWindow(QWindow *window);

    Q_INVOKABLE void launchNewInstance(const QString &repoPath);

private:
    QString appUserModelId() const;

#ifdef Q_OS_WIN
    HICON createTintedIcon(const QColor &tintColor) const;
    void initializeProcessTaskbarIdentity() const;
    void applyInfoToAllWindows();
    void setWindowAppUserModelId(HWND hwnd) const;
    void setWindowIcons(HWND hwnd);
    void setWindowTitles(HWND hwnd);

    bool isValidHwnd(HWND hwnd) const;
#endif

private:
    static TaskbarHelper *s_instance;

    QColor m_color;
    QString m_repoName;

#ifdef Q_OS_WIN
    HICON m_currentIcon = nullptr;
#endif
};