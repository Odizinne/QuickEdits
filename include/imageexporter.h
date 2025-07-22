#ifndef IMAGEEXPORTER_H
#define IMAGEEXPORTER_H

#include <QObject>
#include <QQuickItem>
#include <QUrl>
#include <QtQml/qqml.h>
#include <QImage>

class ImageExporter : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    static ImageExporter* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);
    static ImageExporter* instance();

public slots:
    void saveImage(QQuickItem* imageContainer, const QUrl& fileUrl);
    void openSaveDialog(QQuickItem* imageContainer);
    void saveGrabbedImage(const QString& fileName);
    void grabImageAndSave(const QString& fileName, int targetWidth, int targetHeight);

signals:
    void saveFileSelected(const QString& fileName, int originalWidth, int originalHeight);

private:
    explicit ImageExporter(QObject *parent = nullptr);
    static ImageExporter* m_instance;
    QImage m_grabbedImage;
    QQuickItem* m_imageContainer;
};

#endif // IMAGEEXPORTER_H
