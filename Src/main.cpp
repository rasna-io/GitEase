#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>

#include <QtQml/QQmlContext>
#include <QtQuick/QQuickWindow>
#include <git2/global.h>

#include <Logger/Logger.h>
#include <Logger/QmlBridge.h>

#include "Git/Async/GitAsyncRunner.h"

int main(int argc, char *argv[])
{
    git_libgit2_init();

#if defined(Q_OS_LINUX)
    if(!qEnvironmentVariableIsSet("QT_QPA_PLATFORM"))
    {
        qputenv("QT_QPA_PLATFORM", "xcb;wayland");
    }
#endif

    QGuiApplication app(argc, argv);
    app.setApplicationVersion(QStringLiteral(GITEASE_VERSION));

    Log::Config logConfig;
    logConfig.appName = QStringLiteral("GitEase");
    Log::Logger::instance().start(logConfig);
    Log::registerQmlTypes();

    LOGGER_INFO("App") << "GitEase" << GITEASE_VERSION << "started";

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
    if(!win) {
        LOGGER_CRITICAL("App") << "the main window could not be created";
        Log::Logger::instance().shutdown();
        return -1;
    }

    win->setIcon(app.windowIcon());

    const int exitCode = app.exec();

    GitAsyncRunner::shutdown();

    LOGGER_INFO("App") << "exiting with code" << exitCode;
    Log::Logger::instance().shutdown();

    return exitCode;
}
