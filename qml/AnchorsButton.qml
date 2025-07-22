import QtQuick
import QtQuick.Controls.impl
import Odizinne.QuickEdits

MaterialButton {
    id: root

    property string imageSource: ""
    property real imageRotation: 0

    IconImage {
        visible: root.imageSource !== ""
        source: root.imageSource
        anchors.centerIn: parent
        rotation: root.imageRotation
        width: Math.min(parent.width * 0.6, parent.height * 0.6)
        height: width
        fillMode: Image.PreserveAspectFit
        color: Colors.accentColor
        z: 1
    }

    IconImage {
        source: "qrc:/icons/center.svg"
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.6, parent.height * 0.6)
        height: width
        fillMode: Image.PreserveAspectFit
        color: Colors.accentColorDimmed
        z: 0
    }
}

