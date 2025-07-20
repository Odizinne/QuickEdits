pragma ComponentBehavior: Bound
import QtQuick

Rectangle {
    id: root
    height: Math.ceil(repeater.count / grid.columns) * (25 + grid.spacing) - grid.spacing
    color: "transparent"

    property color selectedColor: "black"

    Grid {
        id: grid
        anchors.fill: parent
        columns: 8
        spacing: 2

        Repeater {
            id: repeater
            model: ListModel {
                ListElement { color: "#000000" }
                ListElement { color: "#333333" }
                ListElement { color: "#666666" }
                ListElement { color: "#999999" }
                ListElement { color: "#cccccc" }
                ListElement { color: "#ffffff" }
                ListElement { color: "#ff0000" }
                ListElement { color: "#00ff00" }
                ListElement { color: "#0000ff" }
                ListElement { color: "#ffff00" }
                ListElement { color: "#ff00ff" }
                ListElement { color: "#00ffff" }
                ListElement { color: "#800000" }
                ListElement { color: "#008000" }
                ListElement { color: "#000080" }
                ListElement { color: "#808000" }
                ListElement { color: "#800080" }
                ListElement { color: "#008080" }
                ListElement { color: "#ffa500" }
                ListElement { color: "#ffc0cb" }
                ListElement { color: "#a52a2a" }
                ListElement { color: "#dda0dd" }
                ListElement { color: "#98fb98" }
                ListElement { color: "#f0e68c" }
            }

            Rectangle {
                width: (root.width - (grid.columns - 1) * grid.spacing) / grid.columns
                height: 25
                color: model.color
                border.color: "#999"
                border.width: 1

                required property var model

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.selectedColor = parent.color
                    }
                }
            }
        }
    }
}
