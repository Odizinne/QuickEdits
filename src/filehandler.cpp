#include "filehandler.h"
#include <QDebug>

#ifdef Q_OS_WASM
#include <emscripten.h>
#include <emscripten/html5.h>

static FileHandler* g_fileHandler = nullptr;

extern "C" {
EMSCRIPTEN_KEEPALIVE void fileSelectedCallback(const char* dataUrl) {
    qDebug() << "fileSelectedCallback called";
    if (g_fileHandler) {
        QString fileData = QString::fromUtf8(dataUrl);
        qDebug() << "Emitting fileSelected signal with data length:" << fileData.length();
        emit g_fileHandler->fileSelected(fileData);
    }
}

EMSCRIPTEN_KEEPALIVE void layerImageSelectedCallback(const char* dataUrl) {
    qDebug() << "layerImageSelectedCallback called";
    if (g_fileHandler) {
        QString fileData = QString::fromUtf8(dataUrl);
        qDebug() << "Emitting layerImageSelected signal with data length:" << fileData.length();
        emit g_fileHandler->layerImageSelected(fileData);
    }
}
}
#endif

FileHandler::FileHandler(QObject *parent) : QObject(parent)
{
#ifdef Q_OS_WASM
    g_fileHandler = this;
    qDebug() << "FileHandler created, g_fileHandler set";
#endif
}

FileHandler* FileHandler::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)
    static FileHandler* instance = new FileHandler();
    qDebug() << "FileHandler::create called, returning instance:" << instance;
    return instance;
}

void FileHandler::openFileDialog()
{
    qDebug() << "openFileDialog called";
#ifdef Q_OS_WASM
    qDebug() << "Opening WebAssembly file dialog";
    EM_ASM({
        console.log("EM_ASM block executing for main image");
        var input = document.getElementById('fileInput');
        if (!input) {
            console.log("Creating new file input");
            input = document.createElement('input');
            input.type = 'file';
            input.id = 'fileInput';
            input.accept = 'image/*';
            input.style.display = 'none';
            document.body.appendChild(input);
        }

        input.onchange = function(e) {
            console.log("Main image file selected:", e.target.files[0]);
            var file = e.target.files[0];
            if (file) {
                var reader = new FileReader();
                reader.onload = function(event) {
                    console.log("Main image file read, calling callback");
                    var dataUrl = event.target.result;
                    var len = lengthBytesUTF8(dataUrl) + 1;
                    var ptr = _malloc(len);
                    stringToUTF8(dataUrl, ptr, len);
                    Module._fileSelectedCallback(ptr);
                    _free(ptr);
                };
                reader.readAsDataURL(file);
            }
        };
        input.click();
    });
#else
    qDebug() << "Not WebAssembly platform";
#endif
}

void FileHandler::openLayerImageDialog()
{
    qDebug() << "openLayerImageDialog called";
#ifdef Q_OS_WASM
    qDebug() << "Opening WebAssembly layer image dialog";
    EM_ASM({
        console.log("EM_ASM block executing for layer image");
        var input = document.getElementById('layerFileInput');
        if (!input) {
            console.log("Creating new layer file input");
            input = document.createElement('input');
            input.type = 'file';
            input.id = 'layerFileInput';
            input.accept = 'image/*';
            input.style.display = 'none';
            document.body.appendChild(input);
        }

        input.onchange = function(e) {
            console.log("Layer image file selected:", e.target.files[0]);
            var file = e.target.files[0];
            if (file) {
                var reader = new FileReader();
                reader.onload = function(event) {
                    console.log("Layer image file read, calling callback");
                    var dataUrl = event.target.result;
                    var len = lengthBytesUTF8(dataUrl) + 1;
                    var ptr = _malloc(len);
                    stringToUTF8(dataUrl, ptr, len);
                    Module._layerImageSelectedCallback(ptr);
                    _free(ptr);
                };
                reader.readAsDataURL(file);
            }
        };
        input.click();
    });
#else
    qDebug() << "Not WebAssembly platform";
#endif
}
