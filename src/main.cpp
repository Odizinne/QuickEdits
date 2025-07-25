#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QSettings>
#include <QFontDatabase>

int main(int argc, char *argv[])
{
    qputenv("QT_QUICK_CONTROLS_MATERIAL_VARIANT", "Dense");

    QGuiApplication app(argc, argv);

    qint32 fontId = QFontDatabase::addApplicationFont(":/fonts/Roboto-Regular.ttf");
    QStringList fontList = QFontDatabase::applicationFontFamilies(fontId);
    QString family = fontList.first();

    app.setFont(QFont(family));
    app.setOrganizationName("Odizinne");
    app.setApplicationName("QuickEdits");

#ifdef Q_OS_WASM
    QSettings::setDefaultFormat(QSettings::WebLocalStorageFormat);
#endif

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("Odizinne.QuickEdits", "Main");

    return app.exec();
}
