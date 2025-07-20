pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: root
    title: "Save Image As"
    modal: true
    width: 450
    height: 220
    anchors.centerIn: parent
    Material.roundedScale: Material.ExtraSmallScale

    property string suggestedFileName: "quickedits_export"
    property string finalFileName: ""

    signal fileNameAccepted(string fileName)
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
        fileNameAccepted(fileName)
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
                id: fileNameField
                Layout.fillWidth: true
                placeholderText: root.suggestedFileName
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
                id: formatCombo
                Layout.preferredWidth: 80
                model: ["png", "jpg", "bmp", "webp"]
                currentIndex: 0
            }
        }

        Label {
            Layout.fillWidth: true
            text: "Choose your preferred image format from the dropdown"
            font.pixelSize: 11
            opacity: 0.7
            wrapMode: Text.Wrap
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
}
