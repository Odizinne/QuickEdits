pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Universal
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1200
    height: 800
    title: "Image Text Editor"
    Universal.theme: Universal.Dark

    property string currentImageSource: ""
    property var selectedTextItem: null
    property real imageRotation: 0

    FileDialog {
        id: fileDialog
        title: "Select an image"
        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.bmp *.gif)"]
        onAccepted: {
            mainWindow.currentImageSource = selectedFile
            imageContainer.visible = true
        }
    }

    FileDialog {
        id: saveFileDialog
        title: "Save image as..."
        fileMode: FileDialog.SaveFile
        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
        nameFilters: ["PNG files (*.png)", "JPEG files (*.jpg)", "All files (*)"]
        defaultSuffix: "png"
        onAccepted: {
            ImageExporter.saveImage(imageContainer, selectedFile)
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Left panel - controls
        Frame {
            Layout.preferredWidth: 300
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 15

                Button {
                    Layout.fillWidth: true
                    text: "Upload Image"
                    onClicked: fileDialog.open()
                }

                Button {
                    Layout.fillWidth: true
                    text: "Save Image"
                    enabled: mainWindow.currentImageSource !== ""
                    onClicked: saveFileDialog.open()
                }

                Button {
                    Layout.fillWidth: true
                    text: "Add Text"
                    enabled: mainWindow.currentImageSource !== ""
                    onClicked: {
                        var textItem = textComponent.createObject(imageContainer, {
                            x: 50,
                            y: 50
                        })
                        mainWindow.selectedTextItem = textItem
                    }
                }

                GroupBox {
                    Layout.fillWidth: true
                    title: "Image Controls"
                    visible: mainWindow.currentImageSource !== ""

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        Label { text: "Rotate Image:" }
                        RowLayout {
                            Button {
                                text: "↺ -90°"
                                onClicked: {
                                    mainWindow.imageRotation -= 90
                                }
                            }
                            Button {
                                text: "↻ +90°"
                                onClicked: {
                                    mainWindow.imageRotation += 90
                                }
                            }
                            Button {
                                text: "Reset"
                                onClicked: {
                                    mainWindow.imageRotation = 0
                                }
                            }
                        }
                    }
                }

                MenuSeparator {
                    Layout.fillWidth: true
                    visible: mainWindow.selectedTextItem !== null
                }

                // Text editing controls
                GroupBox {
                    Layout.fillWidth: true
                    title: "Text Properties"
                    visible: mainWindow.selectedTextItem !== null

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        Label { text: "Text Content:" }
                        TextArea {
                            id: textContent
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60
                            wrapMode: TextArea.Wrap
                            onTextChanged: {
                                if (mainWindow.selectedTextItem)
                                    mainWindow.selectedTextItem.textContent = text
                            }
                        }

                        Label { text: "Font Family:" }
                        ComboBox {
                            id: fontFamily
                            Layout.fillWidth: true
                            model: Qt.fontFamilies()
                            onCurrentTextChanged: {
                                if (mainWindow.selectedTextItem)
                                    mainWindow.selectedTextItem.fontFamily = currentText
                            }
                        }

                        Label { text: "Font Size:" }
                        SpinBox {
                            id: fontSize
                            Layout.fillWidth: true
                            from: 8
                            to: 200
                            value: 24
                            onValueChanged: {
                                if (mainWindow.selectedTextItem)
                                    mainWindow.selectedTextItem.fontSize = value
                            }
                        }

                        RowLayout {
                            CheckBox {
                                id: boldCheck
                                text: "Bold"
                                onCheckedChanged: {
                                    if (mainWindow.selectedTextItem)
                                        mainWindow.selectedTextItem.fontBold = checked
                                }
                            }
                            CheckBox {
                                id: italicCheck
                                text: "Italic"
                                onCheckedChanged: {
                                    if (mainWindow.selectedTextItem)
                                        mainWindow.selectedTextItem.fontItalic = checked
                                }
                            }
                        }

                        Label { text: "Text Color:" }

                        Button {
                            id: colorButton
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            text: "Choose Color"
                            onClicked: colorDialog.open()

                            // Calculate text color based on background brightness
                            property real backgroundLuminance: 0.299 * colorPicker.selectedColor.r +
                                                              0.587 * colorPicker.selectedColor.g +
                                                              0.114 * colorPicker.selectedColor.b

                            contentItem: Text {
                                text: colorButton.text
                                font: colorButton.font
                                color: colorButton.backgroundLuminance > 0.5 ? "#000000" : "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                color: colorPicker.selectedColor
                                border.color: "#999"
                                border.width: 1
                            }
                        }

                        ColorPicker {
                            id: colorPicker
                            Layout.fillWidth: true
                            onSelectedColorChanged: {
                                if (mainWindow.selectedTextItem)
                                    mainWindow.selectedTextItem.textColor = selectedColor
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "Delete Selected Text"
                            enabled: mainWindow.selectedTextItem !== null
                            onClicked: {
                                if (mainWindow.selectedTextItem) {
                                    mainWindow.selectedTextItem.destroy()
                                    mainWindow.selectedTextItem = null
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }

        // Right panel - image area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                id: imageContainer
                anchors.fill: parent
                anchors.margins: 10
                visible: false

                Image {
                    id: loadedImage
                    anchors.fill: parent
                    source: mainWindow.currentImageSource
                    fillMode: Image.PreserveAspectFit
                    rotation: mainWindow.imageRotation

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            mainWindow.selectedTextItem = null
                            mainWindow.updateControls()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: textComponent

        Item {
            id: textRect
            width: 200
            height: 60

            property alias textContent: textEdit.text
            property alias fontFamily: textEdit.font.family
            property alias fontSize: textEdit.font.pixelSize
            property alias fontBold: textEdit.font.bold
            property alias fontItalic: textEdit.font.italic
            property alias textColor: textEdit.color
            property bool selected: false

            // Selection border
            Item {
                anchors.fill: parent
                visible: parent.selected

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 2
                    color: "#007acc"
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 2
                    color: "#007acc"
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 2
                    color: "#007acc"
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 2
                    color: "#007acc"
                }
            }

            TextEdit {
                id: textEdit
                anchors.fill: parent
                anchors.margins: 10
                text: "Sample Text"
                font.family: "Arial"
                font.pixelSize: 24
                color: "white"
                selectByMouse: true
                wrapMode: TextEdit.Wrap
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 8
                anchors.bottomMargin: 8

                property bool isDragging: false
                property real startMouseX
                property real startMouseY
                property real startItemX
                property real startItemY

                onPressed: function(mouse) {
                    isDragging = true
                    startMouseX = mouse.x
                    startMouseY = mouse.y
                    startItemX = textRect.x
                    startItemY = textRect.y
                }

                onPositionChanged: function(mouse) {
                    if (isDragging) {
                        var deltaX = mouse.x - startMouseX
                        var deltaY = mouse.y - startMouseY
                        textRect.x = startItemX + deltaX
                        textRect.y = startItemY + deltaY
                    }
                }

                onReleased: {
                    isDragging = false
                }

                onClicked: {
                    mainWindow.selectedTextItem = textRect
                    mainWindow.updateControls()
                    textRect.selected = true

                    for (var i = 0; i < imageContainer.children.length; i++) {
                        var child = imageContainer.children[i]
                        if (child !== textRect && child.hasOwnProperty('selected')) {
                            child.selected = false
                        }
                    }
                }

                onDoubleClicked: {
                    textEdit.focus = true
                    textEdit.selectAll()
                }
            }

            // Resize handle
            MouseArea {
                width: 8
                height: 8
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                visible: parent.selected
                cursorShape: Qt.SizeFDiagCursor

                property real lastMouseX
                property real lastMouseY

                onPressed: {
                    lastMouseX = mouseX
                    lastMouseY = mouseY
                }

                onPositionChanged: {
                    if (pressed) {
                        var deltaX = mouseX - lastMouseX
                        var deltaY = mouseY - lastMouseY

                        textRect.width = Math.max(100, textRect.width + deltaX)
                        textRect.height = Math.max(40, textRect.height + deltaY)

                        lastMouseX = mouseX
                        lastMouseY = mouseY
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#007acc"
                }
            }
        }
    }

    ColorDialog {
        id: colorDialog
        title: "Choose text color"
        onAccepted: {
            colorPicker.selectedColor = colorDialog.selectedColor
        }
    }

    function updateControls() {
        if (selectedTextItem) {
            textContent.text = selectedTextItem.textContent
            fontFamily.currentIndex = fontFamily.find(selectedTextItem.fontFamily)
            fontSize.value = selectedTextItem.fontSize
            boldCheck.checked = selectedTextItem.fontBold
            italicCheck.checked = selectedTextItem.fontItalic
            colorPicker.selectedColor = selectedTextItem.textColor
        }
    }
}
