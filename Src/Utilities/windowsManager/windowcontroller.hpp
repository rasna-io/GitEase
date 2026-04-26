#pragma once
#include "borderlesswindowhelper.h"

#include <QtCore/QObject>
#include <QtGui/QWindow>
#include <QQmlEngine>

class WindowController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QWindow* window READ window WRITE setWindow NOTIFY windowChanged)
public:
    explicit WindowController(QObject* parent = nullptr)
        : QObject(parent)
    {
    }

    explicit WindowController(QWindow* window, QObject* parent = nullptr)
        : QObject(parent)
    {
        setWindow(window);
    }

    QWindow* window() const { return m_window; }

    void setWindow(QWindow* window) {
        if (m_window == window)
            return;

        m_window = window;
        if (m_helper) {
            delete m_helper;
            m_helper = nullptr;
        }

        if (m_window)
            m_helper = new BorderlessWindowHelper(m_window, this);

        emit windowChanged();
    }

    Q_INVOKABLE void minimize() {
        if (m_window)
            m_window->showMinimized();
    }
    Q_INVOKABLE void toggleMaxRestore() {
        if (!m_window)
            return;
        if (m_window->windowState() & Qt::WindowMaximized)
            m_window->showNormal();
        else
            m_window->showMaximized();
    }
    Q_INVOKABLE void closeWindow() {
        if (m_window)
            m_window->close();
    }

    // Drag the window natively (preserves snap & shake)
    Q_INVOKABLE void startSystemMove() {
        if (m_window)
            m_window->startSystemMove();
    }

    // start native resize
    Q_INVOKABLE void startSystemResize(int edges) {
        if (m_window)
                m_window->startSystemResize(static_cast<Qt::Edges>(edges));
    }

    Q_INVOKABLE void setMinimumSize(double w, double h) {
        if (m_helper)
            m_helper->setMinimumSize(QSize(w,h));
    }

signals:
    void titleBarHeightChanged();
    void windowChanged();

private:
    QPointer<QWindow> m_window;

    BorderlessWindowHelper *m_helper = nullptr;
};
