#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QGuiApplication>

#include <QtQml/QQmlContext>
#include <QtQuick/QQuickWindow>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);


    QQmlApplicationEngine engine;

    engine.addImportPath(":/");
    engine.addImportPath(qApp->applicationDirPath() + "/Qml/");
    const QUrl url(u"qrc:/GitEase/Qml/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.load(url);



    return app.exec();
}
