#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>

#include <QtQml/QQmlContext>
#include <QtQuick/QQuickWindow>
#include <git2/global.h>

int main(int argc, char *argv[])
{
    git_libgit2_init();

    QGuiApplication app(argc, argv);

    app.setWindowIcon(QIcon(":/GitEase/Resources/Images/LogoSVG.svg"));

    QQmlApplicationEngine engine;

    engine.addImportPath(":/");
    engine.addImportPath(qApp->applicationDirPath() + "/Qml/");
    const QUrl url(u"qrc:/GitEase/Qml/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);

    engine.load(url);

    auto* win = qobject_cast<QQuickWindow*>(engine.rootObjects().value(0));
    if (!win)
        return -1;

    win->setIcon(app.windowIcon());

    return app.exec();
}
