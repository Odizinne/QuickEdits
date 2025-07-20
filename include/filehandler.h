#ifndef FILEHANDLER_H
#define FILEHANDLER_H

#include <QObject>
#include <QtQml/qqml.h>

class FileHandler : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    static FileHandler* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

public slots:
    void openFileDialog();
    void openLayerImageDialog();

signals:
    void fileSelected(const QString& filePath);
    void layerImageSelected(const QString& filePath);

private:
    explicit FileHandler(QObject *parent = nullptr);
};

#endif // FILEHANDLER_H
