#ifndef IMAGEEXPORTER_H
#define IMAGEEXPORTER_H

#include <QObject>
#include <QQuickItem>
#include <QUrl>
#include <QtQml/qqml.h>

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

signals:
    void saveFileSelected(const QString& fileName);

private:
    explicit ImageExporter(QObject *parent = nullptr);
    static ImageExporter* m_instance;
    QQuickItem* m_pendingImageContainer;
};

#endif // IMAGEEXPORTER_H
