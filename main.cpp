#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "sf.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    StudentFinance backend;

    engine.rootContext()->setContextProperty("cppBackend", &backend);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

    // This exact name must match your CMake URI for the UI to load
    engine.loadFromModule("AiStudentFinanceApp", "Main");

    return app.exec();
}