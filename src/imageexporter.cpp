#include "imageexporter.h"
#include <QQuickItemGrabResult>
#include <QSharedPointer>
#include <QDebug>
#include <QBuffer>

#ifdef Q_OS_WASM
#include <emscripten.h>
#include <emscripten/html5.h>

static ImageExporter* g_imageExporter = nullptr;

extern "C" {
EMSCRIPTEN_KEEPALIVE void saveFileSelectedCallback(const char* fileName) {
    qDebug() << "saveFileSelectedCallback called with:" << fileName;
    if (g_imageExporter) {
        QString fileNameStr = QString::fromUtf8(fileName);
        emit g_imageExporter->saveFileSelected(fileNameStr);
    }
}
}
#endif

// Static instance
ImageExporter* ImageExporter::m_instance = nullptr;

ImageExporter::ImageExporter(QObject *parent)
    : QObject(parent), m_pendingImageContainer(nullptr)
{
#ifdef Q_OS_WASM
    g_imageExporter = this;
#endif
}

ImageExporter* ImageExporter::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)

    return instance();
}

ImageExporter* ImageExporter::instance()
{
    if (!m_instance) {
        m_instance = new ImageExporter();
    }
    return m_instance;
}

void ImageExporter::openSaveDialog(QQuickItem* imageContainer)
{
    if (!imageContainer) {
        qWarning() << "No image container provided";
        return;
    }

    m_pendingImageContainer = imageContainer;

#ifdef Q_OS_WASM
    qDebug() << "Opening WebAssembly save dialog";
    EM_ASM({
        console.log("Opening save file dialog");

        // Create a temporary link to trigger download
        var link = document.createElement('a');
        link.download = 'quickedits_export.png';

        // For now, we'll use a simple prompt for filename
        var fileName = prompt("Enter filename (without extension):", "quickedits_export");
        if (fileName) {
            if (!fileName.endsWith('.png')) {
                fileName += '.png';
            }
            var len = lengthBytesUTF8(fileName) + 1;
            var ptr = _malloc(len);
            stringToUTF8(fileName, ptr, len);
            Module._saveFileSelectedCallback(ptr);
            _free(ptr);
        }
    });
#else
    // For native platforms, emit with a default name - the QML will handle the FileDialog
    emit saveFileSelected("quickedits_export.png");
#endif
}

void ImageExporter::saveImage(QQuickItem* imageContainer, const QUrl& fileUrl)
{
    if (!imageContainer) {
        qWarning() << "No image container provided";
        return;
    }

    QString filePath = fileUrl.toLocalFile();
    if (filePath.isEmpty()) {
        filePath = fileUrl.toString(); // For WebAssembly, this might be just the filename
    }

    // Store original selection states and hide all selections
    QList<QQuickItem*> textItems;
    QList<bool> originalSelectionStates;

    for (int i = 0; i < imageContainer->childItems().size(); ++i) {
        QQuickItem* child = imageContainer->childItems().at(i);
        if (child->property("selected").isValid()) {
            textItems.append(child);
            originalSelectionStates.append(child->property("selected").toBool());
            child->setProperty("selected", false);
        }
    }

    // Grab the image container without selections
    QSharedPointer<QQuickItemGrabResult> grabResult = imageContainer->grabToImage();

    connect(grabResult.data(), &QQuickItemGrabResult::ready, [grabResult, filePath, textItems, originalSelectionStates]() {
        // Restore original selection states first
        for (int i = 0; i < textItems.size(); ++i) {
            textItems.at(i)->setProperty("selected", originalSelectionStates.at(i));
        }

#ifdef Q_OS_WASM
        // In WebAssembly, create a blob and trigger download
        QByteArray imageData;
        QBuffer buffer(&imageData);
        buffer.open(QIODevice::WriteOnly);

        if (grabResult->image().save(&buffer, "PNG")) {
            // Convert to base64 for JavaScript
            QString base64Data = imageData.toBase64();

            // Extract just the filename from the path
            QString fileName = filePath;
            if (fileName.contains('/')) {
                fileName = fileName.split('/').last();
            }
            if (fileName.contains('\\')) {
                fileName = fileName.split('\\').last();
            }

            EM_ASM({
                var base64Data = UTF8ToString($0);
                var fileName = UTF8ToString($1);

                console.log("Downloading file as:", fileName);

                // Convert base64 to blob
                var byteCharacters = atob(base64Data);
                var byteNumbers = new Array(byteCharacters.length);
                for (var i = 0; i < byteCharacters.length; i++) {
                    byteNumbers[i] = byteCharacters.charCodeAt(i);
                }
                var byteArray = new Uint8Array(byteNumbers);
                var blob = new Blob([byteArray], {type: 'image/png'});

                // Create download link
                var link = document.createElement('a');
                link.href = URL.createObjectURL(blob);
                link.download = fileName;
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                URL.revokeObjectURL(link.href);
            }, base64Data.toUtf8().constData(), fileName.toUtf8().constData());

            qDebug() << "Image download initiated with filename:" << fileName;
        } else {
            qWarning() << "Failed to create image data for download";
        }
#else
        // Native platforms: save to specified location
        if (grabResult->saveToFile(filePath)) {
            qDebug() << "Image saved successfully to:" << filePath;
        } else {
            qWarning() << "Failed to save image to:" << filePath;
        }
#endif
    });
}
