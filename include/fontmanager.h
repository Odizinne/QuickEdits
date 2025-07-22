#ifndef FONTMANAGER_H
#define FONTMANAGER_H

#include <QObject>
#include <QtQml/qqml.h>
#include <QStringList>
#include <QSettings>

class FontManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QStringList availableFonts READ availableFonts NOTIFY availableFontsChanged)
    Q_PROPERTY(QStringList customFontFamilies READ customFontFamilies NOTIFY customFontFamiliesChanged)

public:
    static FontManager* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    QStringList availableFonts() const { return m_availableFonts; }
    QStringList customFontFamilies() const { return m_customFontFamilies; }

public slots:
    void openFontDialog();
    void loadCustomFont(const QString& fontData);
    void removeCustomFont(const QString& fontFamily);
    void loadCustomFontFromFile(const QUrl& fileUrl);

signals:
    void availableFontsChanged();
    void fontLoaded(const QString& fontFamily);
    void fontRemoved(const QString& fontFamily);
    void customFontFamiliesChanged();

private:
    explicit FontManager(QObject *parent = nullptr);
    void refreshAvailableFonts();
    void loadStoredFonts();
    void saveFontToStorage(const QString& fontFamily, const QByteArray& fontData);
    QByteArray loadFontFromStorage(const QString& fontFamily);

    QStringList m_availableFonts;
    QStringList m_customFontFamilies;
};

#endif // FONTMANAGER_H
