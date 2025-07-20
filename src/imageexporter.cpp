#include "ImageExporter.h"
#include <QQuickItemGrabResult>
#include <QSharedPointer>
#include <QDebug>

// Static instance
ImageExporter* ImageExporter::m_instance = nullptr;

ImageExporter::ImageExporter(QObject *parent)
    : QObject(parent)
{
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

void ImageExporter::saveImage(QQuickItem* imageContainer, const QUrl& fileUrl)
{
    if (!imageContainer) {
        qWarning() << "No image container provided";
        return;
    }

    QString filePath = fileUrl.toLocalFile();

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
        // Restore original selection states
        for (int i = 0; i < textItems.size(); ++i) {
            textItems.at(i)->setProperty("selected", originalSelectionStates.at(i));
        }

        if (grabResult->saveToFile(filePath)) {
            qDebug() << "Image saved successfully to:" << filePath;
        } else {
            qWarning() << "Failed to save image to:" << filePath;
        }
    });
}
