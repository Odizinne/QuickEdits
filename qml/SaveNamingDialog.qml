pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: root
    title: "Save Image As"
    modal: true
    width: 450
    anchors.centerIn: parent
    Material.roundedScale: Material.ExtraSmallScale

    property string suggestedFileName: "quickedits_export"
    property string finalFileName: ""
    property real originalWidth: 1920
    property real originalHeight: 1080
    property real aspectRatio: originalWidth / originalHeight
    property bool updatingResolution: false

    signal fileNameAccepted(string fileName, int width, int height)
    signal fileNameRejected()

    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        var fileName = fileNameField.text.trim()
        if (fileName.length === 0) {
            fileName = suggestedFileName
        }

        // Get selected format
        var selectedExtension = formatCombo.currentText.toLowerCase()

        // Remove any existing extension
        var nameWithoutExt = fileName
        var knownExtensions = ['.png', '.jpg', '.jpeg', '.bmp', '.webp']
        for (var i = 0; i < knownExtensions.length; i++) {
            if (fileName.toLowerCase().endsWith(knownExtensions[i])) {
                nameWithoutExt = fileName.substring(0, fileName.length - knownExtensions[i].length)
                break
            }
        }

        // Add selected extension
        fileName = nameWithoutExt + '.' + selectedExtension

        finalFileName = fileName
        fileNameAccepted(fileName, widthSpinBox.value, heightSpinBox.value)
    }

    onRejected: {
        fileNameRejected()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 15

        Label {
            Layout.fillWidth: true
            text: "Enter a filename for your image:"
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            TextField {
                Layout.preferredHeight: 35
                id: fileNameField
                Layout.fillWidth: true
                placeholderText: qsTr("File name...")
                text: root.suggestedFileName
                selectByMouse: true

                Component.onCompleted: {
                    selectAll()
                    forceActiveFocus()
                }

                Keys.onReturnPressed: root.accept()
                Keys.onEnterPressed: root.accept()
            }

            Label {
                text: "."
                opacity: 0.7
            }

            ComboBox {
                Layout.preferredHeight: 35
                id: formatCombo
                Layout.preferredWidth: 80
                model: ["png", "jpg", "bmp", "webp"]
                currentIndex: 0
            }
        }

        MenuSeparator {
            Layout.fillWidth: true
        }

        Label {
            Layout.fillWidth: true
            text: "Resolution:"
            font.bold: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text: "Width:"
            }

            SpinBox {
                id: widthSpinBox
                Layout.preferredWidth: 120
                Layout.preferredHeight: 35
                from: 1
                to: root.originalWidth
                value: root.originalWidth
                editable: true

                textFromValue: function(value, locale) {
                    return value.toString()
                }

                onValueChanged: {
                    if (!root.updatingResolution && value > 0) {
                        root.updatingResolution = true
                        var newHeight = Math.round(value / root.aspectRatio)
                        if (newHeight <= heightSpinBox.to) {
                            heightSpinBox.value = newHeight
                        } else {
                            // If calculated height exceeds max, adjust width instead
                            value = Math.round(heightSpinBox.to * root.aspectRatio)
                        }
                        root.updatingResolution = false
                    }
                }
            }

            Label {
                text: "×"
                opacity: 0.7
            }

            Label {
                text: "Height:"
            }

            SpinBox {
                id: heightSpinBox
                Layout.preferredWidth: 120
                Layout.preferredHeight: 35
                from: 1
                to: root.originalHeight
                value: root.originalHeight
                editable: true

                textFromValue: function(value, locale) {
                    return value.toString()
                }

                onValueChanged: {
                    if (!root.updatingResolution && value > 0) {
                        root.updatingResolution = true
                        var newWidth = Math.round(value * root.aspectRatio)
                        if (newWidth <= widthSpinBox.to) {
                            widthSpinBox.value = newWidth
                        } else {
                            // If calculated width exceeds max, adjust height instead
                            value = Math.round(widthSpinBox.to / root.aspectRatio)
                        }
                        root.updatingResolution = false
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MaterialButton {
                text: "Reset to Original"
                Layout.preferredWidth: implicitWidth + 20
                onClicked: {
                    root.updatingResolution = true
                    widthSpinBox.value = root.originalWidth
                    heightSpinBox.value = root.originalHeight
                    root.updatingResolution = false
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }

    function setFileName(fileName) {
        // Remove extension for editing and detect format
        var nameWithoutExt = fileName
        var detectedFormat = "png" // default

        var knownExtensions = [
            {ext: '.png', format: 'png'},
            {ext: '.jpg', format: 'jpg'},
            {ext: '.jpeg', format: 'jpg'},
            {ext: '.bmp', format: 'bmp'},
            {ext: '.webp', format: 'webp'}
        ]

        for (var i = 0; i < knownExtensions.length; i++) {
            if (fileName.toLowerCase().endsWith(knownExtensions[i].ext)) {
                nameWithoutExt = fileName.substring(0, fileName.length - knownExtensions[i].ext.length)
                detectedFormat = knownExtensions[i].format
                break
            }
        }

        suggestedFileName = nameWithoutExt
        fileNameField.text = nameWithoutExt

        // Set the format combo to match detected format
        var formatIndex = formatCombo.model.indexOf(detectedFormat)
        if (formatIndex !== -1) {
            formatCombo.currentIndex = formatIndex
        }

        fileNameField.selectAll()
    }

    function setOriginalResolution(width, height) {
        originalWidth = width
        originalHeight = height
        aspectRatio = width / height

        updatingResolution = true
        widthSpinBox.to = width
        heightSpinBox.to = height
        widthSpinBox.value = width
        heightSpinBox.value = height
        updatingResolution = false
    }
}
