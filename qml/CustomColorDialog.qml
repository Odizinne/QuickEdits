pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: root
    title: "Choose Color"
    modal: true
    width: 350
    anchors.centerIn: parent
    Material.roundedScale: Material.ExtraSmallScale

    property color selectedColor: "white"
    property color currentColor: "white"

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

        // Preview
        Rectangle {
            radius: Material.ExtraSmallScale
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: root.currentColor
            border.color: "#999"
            border.width: 1
        }


        // Color picker area
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Saturation-Value square
            Rectangle {
                radius: Material.ExtraSmallScale
                id: svRect
                //Layout.preferredWidth: 200
                Layout.fillWidth: true
                Layout.preferredHeight: width
                color: "#00000000"
                border.color: root.palette.window
                border.width: 1

                // Black to transparent overlay for value (top to bottom - REVERTED)
                Rectangle {
                    radius: Material.ExtraSmallScale
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#00000000" }  // Transparent at top
                        GradientStop { position: 1.0; color: "#ff000000" }  // Black at bottom
                    }
                }

                // White to transparent overlay for saturation (right to left - KEPT)
                Rectangle {
                    radius: Material.ExtraSmallScale
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#ffffffff" }  // Full white on left
                        GradientStop { position: 1.0; color: "#00ffffff" }  // Transparent white on right
                    }
                }

                Rectangle {
                    id: svCursor
                    width: 18
                    height: 18
                    radius: width / 2
                    color: root.currentColor
                    border.color: "#ffffff"
                    border.width: 2
                    x: parent.width - width
                    y: 0

                    onXChanged: root.updateColorFromCursors()
                    onYChanged: root.updateColorFromCursors()

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        drag.target: parent
                        drag.axis: Drag.XAndYAxis
                        drag.minimumX: 0
                        drag.maximumX: parent.parent.width - parent.width
                        drag.minimumY: 0
                        drag.maximumY: parent.parent.height - parent.height
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: {
                        svCursor.x = Math.max(0, Math.min(width - svCursor.width, mouseX - svCursor.width/2))
                        svCursor.y = Math.max(0, Math.min(height - svCursor.height, mouseY - svCursor.height/2))
                    }
                    onPositionChanged: {
                        if (pressed) {
                            svCursor.x = Math.max(0, Math.min(width - svCursor.width, mouseX - svCursor.width/2))
                            svCursor.y = Math.max(0, Math.min(height - svCursor.height, mouseY - svCursor.height/2))
                        }
                    }
                }
            }

            // Vertical hue gradient bar
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
                        // Get current hue value
                        var currentHue = y / (parent.height - height)
                        return Qt.hsva(currentHue, 1, 1, 1)  // Max saturation and value
                    }
                    border.color: "#ffffff"
                    border.width: 2
                    x: (parent.width - width) / 2  // Center horizontally
                    y: 0

                    onYChanged: root.updateColorFromCursors()

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        drag.target: parent
                        drag.axis: Drag.YAxis
                        drag.minimumY: 0
                        drag.maximumY: parent.parent.height - parent.height
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: {
                        hueCursor.y = Math.max(0, Math.min(height - hueCursor.height, mouseY - hueCursor.height/2))
                    }
                    onPositionChanged: {
                        if (pressed) {
                            hueCursor.y = Math.max(0, Math.min(height - hueCursor.height, mouseY - hueCursor.height/2))
                        }
                    }
                }
            }
        }

        // Hex input
        RowLayout {
            Layout.fillWidth: true

            TextField {
                id: hexField
                Layout.fillWidth: true
                text: "#ffffff"
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

            var hue = hueCursor.y / (hueCursor.parent.height - hueCursor.height)
            var sat = svCursor.x / (svRect.width - svCursor.width)
            var val = 1.0 - (svCursor.y / (svRect.height - svCursor.height))

            hue = Math.max(0, Math.min(1, hue))
            sat = Math.max(0, Math.min(1, sat))
            val = Math.max(0, Math.min(1, val))

            root.currentColor = Qt.hsva(hue, sat, val, 1)
            hexField.text = root.currentColor.toString()

            // Update SV rect background color based on hue
            svRect.color = Qt.hsva(hue, 1, 1, 1)

            updatingFromCursors = false
        }
    }

    function updateCursorsFromColor() {
        if (!updatingFromCursors && hueCursor.parent && svRect.width > 0) {
            // Manual HSV conversion since Qt.colorToHsva might not be available
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

            hueCursor.y = h * (hueCursor.parent.height - hueCursor.height)
            svCursor.x = s * (svRect.width - svCursor.width)
            svCursor.y = (1.0 - v) * (svRect.height - svCursor.height)

            // Update SV rect background
            svRect.color = Qt.hsva(h, 1, 1, 1)
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
