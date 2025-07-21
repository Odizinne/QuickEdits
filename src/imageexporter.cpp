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
    qDebug() << "Opening custom save dialog for WebAssembly";
    // Generate a suggested filename based on current time
    QString suggestedName = QString("quickedits_export_%1")
                                .arg(QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss"));

    emit saveFileSelected(suggestedName);
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

    bool originalBorderVisibility = true;

    QQuickItem* imageBorder = imageContainer->findChild<QQuickItem*>("imageBorder");
    if (imageBorder) {
        originalBorderVisibility = imageBorder->isVisible();
        imageBorder->setVisible(false);
    }
    // Grab the image container without selections
    QSharedPointer<QQuickItemGrabResult> grabResult = imageContainer->grabToImage();

    connect(grabResult.data(), &QQuickItemGrabResult::ready, [grabResult, filePath, textItems, originalSelectionStates, imageBorder, originalBorderVisibility]() {
        // Restore original selection states and border visibility
        for (int i = 0; i < textItems.size(); ++i) {
            textItems.at(i)->setProperty("selected", originalSelectionStates.at(i));
        }

        if (imageBorder) {
            imageBorder->setVisible(originalBorderVisibility);
        }

#ifdef Q_OS_WASM
        // In WebAssembly, create a blob and trigger download
        QByteArray imageData;
        QBuffer buffer(&imageData);
        buffer.open(QIODevice::WriteOnly);

        // Extract file extension to determine format
        QString format = "PNG"; // default
        QString mimeType = "image/png"; // default

        QString lowerPath = filePath.toLower();
        if (lowerPath.endsWith(".jpg") || lowerPath.endsWith(".jpeg")) {
            format = "JPEG";
            mimeType = "image/jpeg";
        } else if (lowerPath.endsWith(".bmp")) {
            format = "BMP";
            mimeType = "image/bmp";
        } else if (lowerPath.endsWith(".webp")) {
            format = "WEBP";
            mimeType = "image/webp";
        }

        if (grabResult->image().save(&buffer, format.toUtf8().constData())) {
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
                var mimeType = UTF8ToString($2);

                console.log("Downloading file as:", fileName, "with mime type:", mimeType);

                // Convert base64 to blob
                var byteCharacters = atob(base64Data);
                var byteNumbers = new Array(byteCharacters.length);
                for (var i = 0; i < byteCharacters.length; i++) {
                    byteNumbers[i] = byteCharacters.charCodeAt(i);
                }
                var byteArray = new Uint8Array(byteNumbers);
                var blob = new Blob([byteArray], {type: mimeType});

                // Create download link
                var link = document.createElement('a');
                link.href = URL.createObjectURL(blob);
                link.download = fileName;
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                URL.revokeObjectURL(link.href);
            }, base64Data.toUtf8().constData(), fileName.toUtf8().constData(), mimeType.toUtf8().constData());

            qDebug() << "Image download initiated with filename:" << fileName << "format:" << format;
        } else {
            qWarning() << "Failed to create image data for download in format:" << format;
        }
#else
        // Native platforms: save to specified location
        // Extract format from file extension for native saving too
        QString format = "PNG"; // default
        QString lowerPath = filePath.toLower();
        if (lowerPath.endsWith(".jpg") || lowerPath.endsWith(".jpeg")) {
            format = "JPEG";
        } else if (lowerPath.endsWith(".bmp")) {
            format = "BMP";
        } else if (lowerPath.endsWith(".webp")) {
            format = "WEBP";
        }

        if (grabResult->image().save(filePath, format.toUtf8().constData())) {
            qDebug() << "Image saved successfully to:" << filePath << "in format:" << format;
        } else {
            qWarning() << "Failed to save image to:" << filePath << "in format:" << format;
        }
#endif
    });
}
