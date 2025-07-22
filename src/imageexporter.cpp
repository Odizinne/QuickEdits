#include "imageexporter.h"
#include <QQuickItemGrabResult>
#include <QSharedPointer>
#include <QDebug>
#include <QBuffer>
#include <QStandardPaths>
#include <QDateTime>

#ifdef Q_OS_WASM
#include <emscripten.h>
#include <emscripten/html5.h>

static ImageExporter* g_imageExporter = nullptr;

extern "C" {
EMSCRIPTEN_KEEPALIVE void saveFileSelectedCallback(const char* fileName) {
    qDebug() << "saveFileSelectedCallback called with:" << fileName;
    if (g_imageExporter) {
        QString fileNameStr = QString::fromUtf8(fileName);
        emit g_imageExporter->saveFileSelected(fileNameStr, 1920, 1080);
    }
}
}
#endif

// Static instance
ImageExporter* ImageExporter::m_instance = nullptr;

ImageExporter::ImageExporter(QObject *parent)
    : QObject(parent), m_imageContainer(nullptr)
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

    // Store the container for later use
    m_imageContainer = imageContainer;

    // Get the actual size of the content
    int width = static_cast<int>(imageContainer->width());
    int height = static_cast<int>(imageContainer->height());

    // Generate suggested filename and emit signal with dimensions
    QString suggestedName = QString("quickedits_export_%1")
                                .arg(QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss"));

    emit saveFileSelected(suggestedName, width, height);
}

void ImageExporter::grabImageAndSave(const QString& fileName, int targetWidth, int targetHeight)
{
    if (!m_imageContainer) {
        qWarning() << "No image container stored";
        return;
    }

    // Store original selection states and hide all selections
    QList<QQuickItem*> textItems;
    QList<bool> originalSelectionStates;

    for (int i = 0; i < m_imageContainer->childItems().size(); ++i) {
        QQuickItem* child = m_imageContainer->childItems().at(i);
        if (child->property("selected").isValid()) {
            textItems.append(child);
            originalSelectionStates.append(child->property("selected").toBool());
            child->setProperty("selected", false);
        }
    }

    bool originalBorderVisibility = true;
    QQuickItem* imageBorder = m_imageContainer->findChild<QQuickItem*>("imageBorder");
    if (imageBorder) {
        originalBorderVisibility = imageBorder->isVisible();
        imageBorder->setVisible(false);
    }

    // Calculate scale factor and create target size
    QSize targetSize(targetWidth, targetHeight);

    // Grab the image container without selections at the target resolution
    QSharedPointer<QQuickItemGrabResult> grabResult = m_imageContainer->grabToImage(targetSize);

    connect(grabResult.data(), &QQuickItemGrabResult::ready, [this, grabResult, textItems, originalSelectionStates, imageBorder, originalBorderVisibility, fileName]() {
        // Store the grabbed image (already scaled to target resolution)
        m_grabbedImage = grabResult->image();

        // Restore original selection states and border visibility
        for (int i = 0; i < textItems.size(); ++i) {
            textItems.at(i)->setProperty("selected", originalSelectionStates.at(i));
        }

        if (imageBorder) {
            imageBorder->setVisible(originalBorderVisibility);
        }

        // Now proceed with saving
#ifdef Q_OS_WASM
        saveGrabbedImage(fileName);
#endif

        // Clear the container reference
        m_imageContainer = nullptr;
    });
}

void ImageExporter::saveGrabbedImage(const QString& fileName)
{
    if (m_grabbedImage.isNull()) {
        qWarning() << "No grabbed image to save";
        return;
    }

#ifdef Q_OS_WASM
    // WebAssembly: create blob and trigger download
    QByteArray imageData;
    QBuffer buffer(&imageData);
    buffer.open(QIODevice::WriteOnly);

    // Extract file extension to determine format
    QString format = "PNG";
    QString mimeType = "image/png";

    QString lowerPath = fileName.toLower();
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

    if (m_grabbedImage.save(&buffer, format.toUtf8().constData())) {
        QString base64Data = imageData.toBase64();

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

        qDebug() << "Image download initiated with filename:" << fileName;
    } else {
        qWarning() << "Failed to create image data for download in format:" << format;
    }
#else
    // Native platforms: this shouldn't be called, but handle it just in case
    qWarning() << "saveGrabbedImage called on native platform";
#endif

    // Clear the grabbed image
    m_grabbedImage = QImage();
}

void ImageExporter::saveImage(QQuickItem* imageContainer, const QUrl& fileUrl)
{
    // If we have a grabbed image, use that instead of grabbing again
    if (!m_grabbedImage.isNull()) {
        QString filePath = fileUrl.toLocalFile();
        if (filePath.isEmpty()) {
            filePath = fileUrl.toString();
        }

        QString format = "PNG";
        QString lowerPath = filePath.toLower();
        if (lowerPath.endsWith(".jpg") || lowerPath.endsWith(".jpeg")) {
            format = "JPEG";
        } else if (lowerPath.endsWith(".bmp")) {
            format = "BMP";
        } else if (lowerPath.endsWith(".webp")) {
            format = "WEBP";
        }

        if (m_grabbedImage.save(filePath, format.toUtf8().constData())) {
            qDebug() << "Grabbed image saved successfully to:" << filePath << "in format:" << format;
        } else {
            qWarning() << "Failed to save grabbed image to:" << filePath << "in format:" << format;
        }

        // Clear the grabbed image after saving
        m_grabbedImage = QImage();
        return;
    }

    // Fallback: original grab and save logic (shouldn't be needed with new workflow)
    if (!imageContainer) {
        qWarning() << "No image container provided and no grabbed image available";
        return;
    }

    QString filePath = fileUrl.toLocalFile();
    if (filePath.isEmpty()) {
        filePath = fileUrl.toString();
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

        // Extract format from file extension
        QString format = "PNG";
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
    });
}
