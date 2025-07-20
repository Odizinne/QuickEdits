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

private:
    explicit ImageExporter(QObject *parent = nullptr);
    static ImageExporter* m_instance;
};

#endif // IMAGEEXPORTER_H
