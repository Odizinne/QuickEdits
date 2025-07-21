pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.QuickEdits

Dialog {
    id: root
    title: "Choose Color"
    modal: true
    width: 350
    anchors.centerIn: parent
    Material.roundedScale: Material.ExtraSmallScale

    property color selectedColor: Colors.placeholderColor
    property color currentColor: Colors.placeholderColor

    standardButtons: Dialog.Ok | Dialog.Cancel

    signal colorAccepted()
    signal colorRejected()

    onAccepted: {
        selectedColor = currentColor
        colorAccepted()
    }

    onRejected: {
        currentColor = selectedColor
        colorRejected()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 15

        Rectangle {
            radius: Material.ExtraSmallScale
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: root.currentColor
            border.color: "#999"
            border.width: 1
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 15

            Rectangle {
                id: svRect
                Layout.fillWidth: true
                Layout.preferredHeight: width

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.hsva(svRect.getCurrentHue(), 0, 1, 1) // Top-left: white
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.hsva(svRect.getCurrentHue(), 1, 1, 1) // Top-right: pure hue
                    }
                    orientation: Gradient.Horizontal
                }

                // Add vertical gradient overlay for the brightness variation
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: "#ff000000" }
                    }
                }

                function getCurrentHue() {
                    if (hueCursor.parent && hueCursor.parent.height > hueCursor.height) {
                        return (hueCursor.y + hueCursor.height/2) / hueCursor.parent.height
                    }
                    return 0
                }

                Rectangle {
                    id: svCursor
                    width: 18
                    height: 18
                    radius: width / 2
                    color: root.currentColor
                    border.color: Colors.handleColor
                    border.width: 2
                    x: parent.width - width/2
                    y: -height/2

                    onXChanged: root.updateColorFromCursors()
                    onYChanged: root.updateColorFromCursors()

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        drag.target: parent
                        drag.axis: Drag.XAndYAxis
                        drag.minimumX: -parent.width/2
                        drag.maximumX: parent.parent.width - parent.width/2
                        drag.minimumY: -parent.height/2
                        drag.maximumY: parent.parent.height - parent.height/2
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: {
                        var newX = Math.max(-svCursor.width/2, Math.min(width - svCursor.width/2, mouseX - svCursor.width/2))
                        var newY = Math.max(-svCursor.height/2, Math.min(height - svCursor.height/2, mouseY - svCursor.height/2))
                        svCursor.x = newX
                        svCursor.y = newY
                    }
                    onPositionChanged: {
                        if (pressed) {
                            var newX = Math.max(-svCursor.width/2, Math.min(width - svCursor.width/2, mouseX - svCursor.width/2))
                            var newY = Math.max(-svCursor.height/2, Math.min(height - svCursor.height/2, mouseY - svCursor.height/2))
                            svCursor.x = newX
                            svCursor.y = newY
                        }
                    }
                }
            }

            Rectangle {
                radius: Material.ExtraSmallScale
                Layout.preferredWidth: 10
                Layout.fillHeight: true

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#ff0000" }
                    GradientStop { position: 0.17; color: "#ffff00" }
                    GradientStop { position: 0.34; color: "#00ff00" }
                    GradientStop { position: 0.5; color: "#00ffff" }
                    GradientStop { position: 0.67; color: "#0000ff" }
                    GradientStop { position: 0.84; color: "#ff00ff" }
                    GradientStop { position: 1.0; color: "#ff0000" }
                }

                Rectangle {
                    id: hueCursor
                    width: 18
                    height: 18
                    radius: width / 2
                    color: {
                        var currentHue = (y + height/2) / parent.height
                        return Qt.hsva(currentHue, 1, 1, 1)
                    }
                    border.color: Colors.handleColor
                    border.width: 2
                    x: (parent.width - width) / 2
                    y: -height/2

                    onYChanged: {
                        root.updateColorFromCursors()
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        drag.target: parent
                        drag.axis: Drag.YAxis
                        drag.minimumY: -parent.height/2
                        drag.maximumY: parent.parent.height - parent.height/2
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: {
                        var newY = Math.max(-hueCursor.height/2, Math.min(height - hueCursor.height/2, mouseY - hueCursor.height/2))
                        hueCursor.y = newY
                    }
                    onPositionChanged: {
                        if (pressed) {
                            var newY = Math.max(-hueCursor.height/2, Math.min(height - hueCursor.height/2, mouseY - hueCursor.height/2))
                            hueCursor.y = newY
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            TextField {
                id: hexField
                Layout.fillWidth: true
                text: Colors.placeholderColor
                validator: RegularExpressionValidator { regularExpression: /^#[0-9A-Fa-f]{6}$/ }
                onTextChanged: {
                    if (acceptableInput && !root.updatingFromCursors) {
                        root.currentColor = text
                        root.updateCursorsFromColor()
                    }
                }
            }
        }
    }

    property bool updatingFromCursors: false

    function updateColorFromCursors() {
        if (hueCursor.parent && svRect.width > 0 && svRect.height > 0) {
            updatingFromCursors = true

            var hue = (hueCursor.y + hueCursor.height/2) / hueCursor.parent.height
            var sat = (svCursor.x + svCursor.width/2) / svRect.width
            var val = 1.0 - ((svCursor.y + svCursor.height/2) / svRect.height)

            hue = Math.max(0, Math.min(1, hue))
            sat = Math.max(0, Math.min(1, sat))
            val = Math.max(0, Math.min(1, val))

            root.currentColor = Qt.hsva(hue, sat, val, 1)
            hexField.text = root.currentColor.toString()

            updatingFromCursors = false
        }
    }

    function updateCursorsFromColor() {
        if (!updatingFromCursors && hueCursor.parent && svRect.width > 0) {
            var r = root.currentColor.r
            var g = root.currentColor.g
            var b = root.currentColor.b

            var max = Math.max(r, Math.max(g, b))
            var min = Math.min(r, Math.min(g, b))
            var delta = max - min

            var h = 0, s = 0, v = max

            if (delta > 0) {
                s = delta / max

                if (max === r) {
                    h = ((g - b) / delta) % 6
                } else if (max === g) {
                    h = (b - r) / delta + 2
                } else {
                    h = (r - g) / delta + 4
                }
                h = h / 6
                if (h < 0) h += 1
            }

            hueCursor.y = h * hueCursor.parent.height - hueCursor.height/2
            svCursor.x = s * svRect.width - svCursor.width/2
            svCursor.y = (1.0 - v) * svRect.height - svCursor.height/2
        }
    }

    Component.onCompleted: {
        currentColor = selectedColor
        updateCursorsFromColor()
    }

    onSelectedColorChanged: {
        if (!updatingFromCursors) {
            currentColor = selectedColor
            updateCursorsFromColor()
        }
    }
}
