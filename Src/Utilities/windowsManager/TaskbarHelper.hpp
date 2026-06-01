#pragma once
#include <QObject>
#include <QColor>
#include <QtQmlIntegration>
#include <QWindow>
#include <windows.h>
#include <shobjidl.h>

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
    HICON createTintedIcon(const QColor &tintColor) const;
    void applyInfoToAllWindows();
    void  setWindowIcons(HWND hwnd);
    void  setWindowTitles(HWND hwnd);

    bool isValidHwnd(HWND hwnd) const;

private:
    static TaskbarHelper *s_instance;

    QColor m_color;
    QString m_repoName;

    HICON  m_currentIcon = nullptr;
};
