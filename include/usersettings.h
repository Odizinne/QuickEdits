#ifndef USERSETTINGS_H
#define USERSETTINGS_H

#include <QObject>
#include <QtQml/qqml.h>

class UserSettings : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool displayDonate READ displayDonate WRITE setDisplayDonate NOTIFY displayDonateChanged)
    Q_PROPERTY(bool darkMode READ darkMode WRITE setDarkMode NOTIFY darkModeChanged)

public:
    static UserSettings* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    bool displayDonate() const { return m_displayDonate; }
    void setDisplayDonate(bool value);

    bool darkMode() const { return m_darkMode; }
    void setDarkMode(bool value);

signals:
    void displayDonateChanged();
    void darkModeChanged();

private:
    explicit UserSettings(QObject *parent = nullptr);
    void loadSettings();
    void saveSettings();

    bool m_displayDonate = true;
    bool m_darkMode = true;
};

#endif // USERSETTINGS_H
