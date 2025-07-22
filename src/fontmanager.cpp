#include "fontmanager.h"
#include <QFontDatabase>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QSettings>
#include <QDebug>

#ifdef Q_OS_WASM
#include <emscripten.h>
#include <emscripten/html5.h>

static FontManager* g_fontManager = nullptr;

extern "C" {
EMSCRIPTEN_KEEPALIVE void fontSelectedCallback(const char* dataUrl) {
    qDebug() << "fontSelectedCallback called";
    if (g_fontManager) {
        QString fontData = QString::fromUtf8(dataUrl);
        qDebug() << "Emitting fontSelected signal with data length:" << fontData.length();
        // Extract base64 from data URL (remove "data:font/...;base64," prefix)
        int commaIndex = fontData.indexOf(',');
        if (commaIndex != -1) {
            QString base64Data = fontData.mid(commaIndex + 1);
            g_fontManager->loadCustomFont(base64Data);
        }
    }
}
}
#endif

FontManager::FontManager(QObject *parent) : QObject(parent)
{
#ifdef Q_OS_WASM
    g_fontManager = this;
#endif
    loadStoredFonts();
    refreshAvailableFonts();
}

FontManager* FontManager::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)
    static FontManager* instance = new FontManager();
    return instance;
}

void FontManager::openFontDialog()
{
#ifdef Q_OS_WASM
    qDebug() << "Opening WebAssembly font dialog";
    EM_ASM({
        console.log("EM_ASM block executing for font");
        var input = document.getElementById('fontInput');
        if (!input) {
            console.log("Creating new font input");
            input = document.createElement('input');
            input.type = 'file';
            input.id = 'fontInput';
            input.accept = '.ttf,.otf,.woff,.woff2';
            input.style.display = 'none';
            document.body.appendChild(input);
        }

        input.onchange = function(e) {
            console.log("Font file selected:", e.target.files[0]);
            var file = e.target.files[0];
            if (file) {
                var reader = new FileReader();
                reader.onload = function(event) {
                    console.log("Font file read, calling callback");
                    var dataUrl = event.target.result;
                    var len = lengthBytesUTF8(dataUrl) + 1;
                    var ptr = _malloc(len);
                    stringToUTF8(dataUrl, ptr, len);
                    Module._fontSelectedCallback(ptr);
                    _free(ptr);
                };
                reader.readAsDataURL(file);  // This gives you base64 data URL
            }
        };
        input.click();
    });
#else
    qDebug() << "Not WebAssembly platform";
#endif
}

void FontManager::loadCustomFont(const QString& fontData)
{
    QByteArray data = QByteArray::fromBase64(fontData.toUtf8());

    int fontId = QFontDatabase::addApplicationFontFromData(data);
    if (fontId != -1) {
        QStringList fontFamilies = QFontDatabase::applicationFontFamilies(fontId);
        if (!fontFamilies.isEmpty()) {
            QString fontFamily = fontFamilies.first();

            // Save to persistent storage
            saveFontToStorage(fontFamily, data);
            m_customFontFamilies.append(fontFamily);

            refreshAvailableFonts();
            emit customFontFamiliesChanged();
            emit fontLoaded(fontFamily);
            qDebug() << "Font loaded:" << fontFamily;
        }
    } else {
        qWarning() << "Failed to load font from data";
    }
}

void FontManager::saveFontToStorage(const QString& fontFamily, const QByteArray& fontData)
{
    QSettings settings("Odizinne", "QuickEdits");
    settings.beginGroup("CustomFonts");
    settings.setValue(fontFamily, fontData.toBase64());
    settings.endGroup();

    // Also keep track of custom font names
    QStringList customFonts = settings.value("CustomFontsList", QStringList()).toStringList();
    if (!customFonts.contains(fontFamily)) {
        customFonts.append(fontFamily);
        settings.setValue("CustomFontsList", customFonts);
    }
}

void FontManager::loadStoredFonts()
{
    QSettings settings("Odizinne", "QuickEdits");
    QStringList customFonts = settings.value("CustomFontsList", QStringList()).toStringList();

    settings.beginGroup("CustomFonts");
    for (const QString& fontFamily : customFonts) {
        QByteArray fontData = QByteArray::fromBase64(settings.value(fontFamily).toByteArray());

        if (!fontData.isEmpty()) {
            int fontId = QFontDatabase::addApplicationFontFromData(fontData);
            if (fontId != -1) {
                m_customFontFamilies.append(fontFamily);
            }
        }
    }
    settings.endGroup();

    if (!m_customFontFamilies.isEmpty()) {
        emit customFontFamiliesChanged();
    }
}

void FontManager::removeCustomFont(const QString& fontFamily)
{
    if (m_customFontFamilies.contains(fontFamily)) {
        QSettings settings("Odizinne", "QuickEdits");
        settings.beginGroup("CustomFonts");
        settings.remove(fontFamily);
        settings.endGroup();

        QStringList customFonts = settings.value("CustomFontsList", QStringList()).toStringList();
        customFonts.removeAll(fontFamily);
        settings.setValue("CustomFontsList", customFonts);

        m_customFontFamilies.removeAll(fontFamily);

        emit customFontFamiliesChanged();
        emit fontRemoved(fontFamily);
    }
}

void FontManager::refreshAvailableFonts()
{
    QStringList allFonts = QFontDatabase::families();

    for (const QString& customFont : m_customFontFamilies) {
        allFonts.removeAll(customFont);
    }

    m_availableFonts = m_customFontFamilies + allFonts;

    emit availableFontsChanged();
}

void FontManager::loadCustomFontFromFile(const QUrl& fileUrl)
{
#ifndef Q_OS_WASM
    QString filePath = fileUrl.toLocalFile();
    QFile file(filePath);

    if (file.open(QIODevice::ReadOnly)) {
        QByteArray fontData = file.readAll();
        file.close();

        int fontId = QFontDatabase::addApplicationFontFromData(fontData);
        if (fontId != -1) {
            QStringList fontFamilies = QFontDatabase::applicationFontFamilies(fontId);
            if (!fontFamilies.isEmpty()) {
                QString fontFamily = fontFamilies.first();

                // Save to persistent storage
                saveFontToStorage(fontFamily, fontData);
                m_customFontFamilies.append(fontFamily);

                refreshAvailableFonts();
                emit customFontFamiliesChanged();
                emit fontLoaded(fontFamily);
                qDebug() << "Font loaded from file:" << fontFamily;
            }
        } else {
            qWarning() << "Failed to load font from file:" << filePath;
        }
    } else {
        qWarning() << "Could not open font file:" << filePath;
    }
#endif
}
