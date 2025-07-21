#include "usersettings.h"
#include <QDebug>

#ifdef Q_OS_WASM
#include <emscripten.h>
#endif

UserSettings::UserSettings(QObject *parent)
    : QObject(parent)
{
    loadSettings();
}

UserSettings* UserSettings::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)
    static UserSettings* instance = new UserSettings();
    return instance;
}

void UserSettings::setDisplayDonate(bool value)
{
    if (m_displayDonate != value) {
        m_displayDonate = value;
        saveSettings();
        emit displayDonateChanged();
    }
}

void UserSettings::setDarkMode(bool value)
{
    if (m_darkMode != value) {
        m_darkMode = value;
        saveSettings();
        emit darkModeChanged();
    }
}

void UserSettings::loadSettings()
{
#ifdef Q_OS_WASM
    // Use localStorage in WASM
    EM_ASM({
        var displayDonate = localStorage.getItem('displayDonate');
        var darkMode = localStorage.getItem('darkMode');

        if (displayDonate !== null) {
            Module.displayDonateFromJS = displayDonate === 'true';
        }
        if (darkMode !== null) {
            Module.darkModeFromJS = darkMode === 'true';
        }
    });

    // These would be set by the EM_ASM above if values exist
    // You'd need additional C++ code to retrieve these values
#else
    // Use QSettings for native platforms
    QSettings settings;
    m_displayDonate = settings.value("displayDonate", true).toBool();
    m_darkMode = settings.value("darkMode", true).toBool();
#endif

    qDebug() << "Settings loaded - displayDonate:" << m_displayDonate << "darkMode:" << m_darkMode;
}

void UserSettings::saveSettings()
{
#ifdef Q_OS_WASM
    EM_ASM({
        localStorage.setItem('displayDonate', $0 ? 'true' : 'false');
        localStorage.setItem('darkMode', $1 ? 'true' : 'false');
    }, m_displayDonate, m_darkMode);
#else
    QSettings settings;
    settings.setValue("displayDonate", m_displayDonate);
    settings.setValue("darkMode", m_darkMode);
#endif

    qDebug() << "Settings saved - displayDonate:" << m_displayDonate << "darkMode:" << m_darkMode;
}
