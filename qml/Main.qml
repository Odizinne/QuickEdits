pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Universal
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import Odizinne.QuickEdits

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1400
    height: 805
    minimumWidth: 1400
    minimumHeight: 805
    title: "QuickEdits"
    Universal.theme: Universal.Dark

    property string currentImageSource: ""
    property var selectedTextItem: null
    property real imageRotation: 0

    Connections {
        target: ImageExporter
        function onSaveFileSelected(fileName) {
            console.log("QML: Save file selected:", fileName)
            if (Qt.platform.os === "wasm") {
                // For WebAssembly, directly save with the selected name
                ImageExporter.saveImage(imageContainer, fileName)
            } else {
                // For native, open the save dialog with suggested name
                saveFileDialog.currentFile = Qt.resolvedUrl(saveFileDialog.currentFolder + "/" + fileName)
                saveFileDialog.open()
            }
        }
    }

    Connections {
        target: FileHandler
        function onFileSelected(filePath) {
            console.log("QML: Main image file selected:", filePath)
            mainWindow.currentImageSource = filePath
            imageContainer.visible = true
        }

        function onLayerImageSelected(filePath) {
            console.log("QML: Layer image file selected:", filePath)
            var imageItem = imageComponent.createObject(imageContainer, {
                x: 50,
                y: 50,
                source: filePath
            })
            mainWindow.addItemToModel(imageItem)
            mainWindow.selectItem(imageItem)
        }
    }

    ListModel {
        id: itemsModel
    }

    FileDialog {
        id: fileDialog
        title: "Select an image"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.bmp *.webp)"]

        Component.onCompleted: {
            // Only set currentFolder for non-WASM platforms
            if (Qt.platform.os !== "wasm") {
                currentFolder = StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
            }
        }

        onAccepted: {
            mainWindow.currentImageSource = selectedFile
            imageContainer.visible = true
        }
    }

    FileDialog {
        id: layerImageDialog
        title: "Select image for layer"
        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.bmp *.webp)"]
        onAccepted: {
            var imageItem = imageComponent.createObject(imageContainer, {
                x: 50,
                y: 50,
                source: selectedFile
            })
            mainWindow.addItemToModel(imageItem)
            mainWindow.selectItem(imageItem)  // Explicitly select the new item
        }
    }

    FileDialog {
        id: saveFileDialog
        title: "Save image as..."
        fileMode: FileDialog.SaveFile
        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
        nameFilters: ["PNG files (*.png)", "JPEG files (*.jpg *.jpeg)", "BMP files (*.bmp)", "WebP files (*.webp)", "All files (*)"]
        defaultSuffix: "png"

        Component.onCompleted: {
            generateFileName()
        }

        function generateFileName() {
            if (mainWindow.currentImageSource !== "") {
                var sourcePath = mainWindow.currentImageSource.toString()
                var fileName = sourcePath.split('/').pop() // Get filename
                var nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'))
                var extension = fileName.substring(fileName.lastIndexOf('.'))

                var newFileName = nameWithoutExt + "_edited" + extension
                currentFile = Qt.resolvedUrl(currentFolder + "/" + newFileName)
            }
        }

        onAccepted: {
            ImageExporter.saveImage(imageContainer, selectedFile)
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Left panel - controls
        Frame {
            Layout.preferredWidth: 300
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                Button {
                    Layout.fillWidth: true
                    text: "Upload Image"
                    onClicked: {
                        console.log("Upload button clicked, platform:", Qt.platform.os)
                        if (Qt.platform.os === "wasm") {
                            console.log("Using FileHandler")
                            FileHandler.openFileDialog()
                        } else {
                            console.log("Using native file dialog")
                            fileDialog.open()
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    text: "Save Image"
                    enabled: mainWindow.currentImageSource !== ""
                    onClicked: {
                        if (Qt.platform.os === "wasm") {
                            ImageExporter.openSaveDialog(imageContainer)
                        } else {
                            saveFileDialog.generateFileName()
                            saveFileDialog.open()
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    text: "Add Text Layer"
                    enabled: mainWindow.currentImageSource !== ""
                    onClicked: {
                        var textItem = textComponent.createObject(imageContainer, {
                            x: 50,
                            y: 50
                        })
                        mainWindow.addItemToModel(textItem)
                        mainWindow.selectItem(textItem)  // Explicitly select the new item
                    }
                }

                Button {
                    Layout.fillWidth: true
                    text: "Add Image Layer"
                    enabled: mainWindow.currentImageSource !== ""
                    onClicked: {
                        if (Qt.platform.os === "wasm") {
                            FileHandler.openLayerImageDialog()
                        } else {
                            layerImageDialog.open()
                        }
                    }
                }

                RowLayout {
                    visible: mainWindow.currentImageSource !== ""
                    property int buttonWidth: Math.max(rtLeftBtn.implicitHeight, rtRightBtn.implicitHeight, rtResetBtn.implicitHeight)

                    Button {
                        id: rtLeftBtn
                        text: "↺ Left"
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.buttonWidth
                        onClicked: {
                            mainWindow.imageRotation -= 90
                        }
                    }
                    Button {
                        id: rtRightBtn
                        text: "↻ Right"
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.buttonWidth
                        onClicked: {
                            mainWindow.imageRotation += 90
                        }
                    }
                    Button {
                        id: rtResetBtn
                        text: "Reset"
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.buttonWidth
                        onClicked: {
                            mainWindow.imageRotation = 0
                        }
                    }
                }

                MenuSeparator {
                    Layout.fillWidth: true
                    visible: mainWindow.selectedTextItem !== null
                }

                Label {
                    font.pixelSize: 20
                    font.bold: true
                    text: "Text Properties"
                    visible: mainWindow.selectedTextItem !== null && mainWindow.selectedTextItem.hasOwnProperty('textContent')
                }

                ColumnLayout {
                    spacing: 10
                    visible: mainWindow.selectedTextItem !== null && mainWindow.selectedTextItem.hasOwnProperty('textContent')


                    Label { text: "Text Content:" }
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100

                        TextArea {
                            id: textContent
                            wrapMode: TextArea.Wrap
                            onTextChanged: {
                                if (mainWindow.selectedTextItem && mainWindow.selectedTextItem.hasOwnProperty('textContent')) {
                                    mainWindow.selectedTextItem.textContent = text
                                    mainWindow.updateItemPreview(mainWindow.selectedTextItem)
                                }
                            }
                        }
                    }

                    Label { text: "Font:" }

                    RowLayout {
                        ComboBox {
                            id: fontFamily
                            Layout.fillWidth: true
                            model: Qt.fontFamilies()
                            onCurrentTextChanged: {
                                if (mainWindow.selectedTextItem && mainWindow.selectedTextItem.hasOwnProperty('fontFamily')) {
                                    mainWindow.selectedTextItem.fontFamily = currentText
                                    mainWindow.updateItemPreview(mainWindow.selectedTextItem)
                                }
                            }
                        }

                        SpinBox {
                            id: fontSize
                            editable: true
                            from: 8
                            to: 200
                            value: 24
                            onValueChanged: {
                                if (mainWindow.selectedTextItem && mainWindow.selectedTextItem.hasOwnProperty('fontSize')) {
                                    mainWindow.selectedTextItem.fontSize = value
                                    mainWindow.updateItemPreview(mainWindow.selectedTextItem)
                                }
                            }
                        }
                    }

                    RowLayout {
                        CheckBox {
                            id: boldCheck
                            text: "Bold"
                            onCheckedChanged: {
                                if (mainWindow.selectedTextItem && mainWindow.selectedTextItem.hasOwnProperty('fontBold'))
                                mainWindow.selectedTextItem.fontBold = checked
                            }
                        }
                        CheckBox {
                            id: italicCheck
                            text: "Italic"
                            onCheckedChanged: {
                                if (mainWindow.selectedTextItem && mainWindow.selectedTextItem.hasOwnProperty('fontItalic'))
                                mainWindow.selectedTextItem.fontItalic = checked
                            }
                        }
                    }

                    Label { text: "Text Color:" }

                    Button {
                        id: colorButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        text: "Custom Color"
                        onClicked: {
                            colorDialog.selectedColor = colorPicker.selectedColor
                            colorDialog.currentColor = colorPicker.selectedColor
                            colorDialog.open()
                        }

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
                            if (mainWindow.selectedTextItem && mainWindow.selectedTextItem.hasOwnProperty('textColor'))
                            mainWindow.selectedTextItem.textColor = selectedColor
                        }
                    }

                    Button {
                        id: textResetBtn
                        text: "Reset rotation"
                        Layout.fillWidth: true
                        onClicked: {
                            if (mainWindow.selectedTextItem) {
                                mainWindow.selectedTextItem.textRotation = 0
                            }
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "Delete Selected Item"
                        enabled: mainWindow.selectedTextItem !== null
                        onClicked: {
                            if (mainWindow.selectedTextItem) {
                                mainWindow.deleteItem(mainWindow.selectedTextItem)
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                Label {
                    text: "Image Properties"
                    visible: mainWindow.selectedTextItem !== null && !mainWindow.selectedTextItem.hasOwnProperty('textContent')
                    font.pixelSize: 20
                    font.bold: true
                }

                ColumnLayout {
                    spacing: 10
                    visible: mainWindow.selectedTextItem !== null && !mainWindow.selectedTextItem.hasOwnProperty('textContent')

                    Button {
                        id: imgResetBtn
                        text: "Reset rotation"
                        Layout.fillWidth: true
                        onClicked: {
                            if (mainWindow.selectedTextItem) {
                                mainWindow.selectedTextItem.imageRotation = 0
                            }
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "Delete Selected Item"
                        enabled: mainWindow.selectedTextItem !== null
                        onClicked: {
                            if (mainWindow.selectedTextItem) {
                                mainWindow.deleteItem(mainWindow.selectedTextItem)
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }

        // Center panel - image area
        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                id: imageContainer
                anchors.fill: parent
                visible: false

                Image {
                    id: loadedImage
                    anchors.fill: parent
                    source: mainWindow.currentImageSource
                    fillMode: Image.PreserveAspectFit
                    rotation: mainWindow.imageRotation
                    z: -1000

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            // Deselect all items
                            for (var i = 0; i < imageContainer.children.length; i++) {
                                var child = imageContainer.children[i]
                                if (child.hasOwnProperty('selected')) {
                                    child.selected = false
                                }
                            }

                            // Update model selection states
                            for (var j = 0; j < itemsModel.count; j++) {
                                itemsModel.setProperty(j, "isSelected", false)
                            }

                            // Clear selected item and update controls
                            mainWindow.selectedTextItem = null
                            mainWindow.updateControls()
                        }
                    }
                }
            }

            Label {
                text: "Import an image to start"
                opacity: 0.5
                font.pixelSize: 18

                anchors.centerIn: parent
                visible: mainWindow.currentImageSource === ""
            }
        }

        // Right panel - items list sidebar
        Frame {
            Layout.preferredWidth: 250
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                ScrollView {
                    id: lyrScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ScrollBar.vertical.policy: itemListView.contentHeight > height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff

                    property bool sbVisible: ScrollBar.vertical.policy === ScrollBar.AlwaysOn
                    ListView {
                        id: itemListView
                        model: itemsModel
                        spacing: 8

                        delegate: Item {
                            id: delegateRoot
                            width: lyrScroll.sbVisible ? itemListView.width - 20 : itemListView.width
                            height: 70

                            required property var model
                            required property int index

                            RowLayout {
                                anchors.fill: parent
                                spacing: 4

                                Rectangle {
                                    id: rightRect
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: delegateRoot.model.isSelected ? "#40007acc" : "transparent"
                                    border.color: delegateRoot.model.isSelected ? "#007acc" : "#333"
                                    border.width: 2

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                                        onClicked: function(mouse) {
                                            if (mouse.button === Qt.LeftButton) {
                                                mainWindow.selectItem(delegateRoot.model.item)
                                            } else if (mouse.button === Qt.RightButton) {
                                                contextMenu.itemToDelete = delegateRoot.model.item
                                                contextMenu.popup()
                                            }
                                        }

                                        Menu {
                                            id: contextMenu
                                            property var itemToDelete: null

                                            MenuItem {
                                                text: "Delete"
                                                onTriggered: {
                                                    if (contextMenu.itemToDelete) {
                                                        mainWindow.deleteItem(contextMenu.itemToDelete)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 4

                                        Text {
                                            Layout.fillWidth: true
                                            text: delegateRoot.model.preview
                                            color: Universal.foreground
                                            font.weight: delegateRoot.model.isSelected ? Font.Bold : Font.Normal
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: delegateRoot.model.type + " - " + delegateRoot.model.details
                                            color: Universal.accent
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.preferredWidth: 35
                                    Layout.fillHeight: true
                                    spacing: 2

                                    Button {
                                        Layout.preferredHeight: 25
                                        text: "▲"
                                        enabled: delegateRoot.index > 0
                                        font.pixelSize: 8

                                        onClicked: {
                                            mainWindow.moveItemUp(delegateRoot.model.item)
                                        }
                                    }

                                    Button {
                                        Layout.preferredHeight: 25
                                        text: "▼"
                                        enabled: delegateRoot.index < itemsModel.count - 1
                                        font.pixelSize: 8

                                        onClicked: {
                                            mainWindow.moveItemDown(delegateRoot.model.item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Label {
                text: "Layers"
                font.pixelSize: 18
                opacity: 0.5
                anchors.centerIn: parent
                visible: itemsModel.count === 0
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
            property alias textRotation: textRect.rotation
            property alias itemLayer: textRect.z
            property bool selected: false

            // Selection border
            Item {
                anchors.fill: parent
                visible: parent.selected

                Rectangle {
                    anchors.fill: parent
                    color: "#40007acc"
                    border.width: 2
                    border.color: "#007acc"
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
                wrapMode: TextEdit.Wrap
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 8
                anchors.bottomMargin: 8
                anchors.topMargin: 15 // Leave space for rotation handle
                drag.target: parent

                onPressed: {
                    mainWindow.selectItem(textRect)
                }

                onDoubleClicked: {
                    textEdit.focus = true
                }
            }

            // Rotation handle for text component
            MouseArea {
                id: rotationHandle
                width: 12
                height: 12
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: -6
                visible: parent.selected
                cursorShape: Qt.OpenHandCursor

                property real centerX
                property real centerY
                property real startAngle

                onPressed: {
                    // Get the center point of the text item in global coordinates
                    var globalCenter = textRect.mapToItem(textRect.parent, textRect.width/2, textRect.height/2)
                    centerX = globalCenter.x
                    centerY = globalCenter.y

                    // Calculate initial angle from center to mouse position
                    var globalMouse = mapToItem(textRect.parent, mouseX, mouseY)
                    startAngle = Math.atan2(globalMouse.y - centerY, globalMouse.x - centerX) * 180 / Math.PI - textRect.rotation

                    cursorShape = Qt.ClosedHandCursor
                }

                onReleased: {
                    cursorShape = Qt.OpenHandCursor
                }

                onPositionChanged: {
                    if (pressed) {
                        // Calculate current angle from center to mouse position
                        var globalMouse = mapToItem(textRect.parent, mouseX, mouseY)
                        var currentAngle = Math.atan2(globalMouse.y - centerY, globalMouse.x - centerX) * 180 / Math.PI

                        // Set rotation based on angle difference
                        textRect.rotation = currentAngle - startAngle
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "#007acc"
                    border.color: "#ffffff"
                    border.width: 1
                }
            }

            // Resize handle
            MouseArea {
                id: resizeHandle
                width: 10
                height: 10
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

    Component {
        id: imageComponent

        Item {
            id: imageRect
            width: 300
            height: 200

            property alias source: layerImage.source
            property alias itemLayer: imageRect.z
            property real imageRotation: 0
            property bool selected: false

            // Selection border
            Item {
                anchors.fill: parent
                visible: parent.selected

                Rectangle {
                    anchors.fill: parent
                    color: "#40007acc"
                    border.width: 2
                    border.color: "#007acc"
                }
            }

            Image {
                id: layerImage
                anchors.fill: parent
                anchors.margins: 2
                fillMode: Image.PreserveAspectFit
                rotation: imageRect.imageRotation
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 8
                anchors.bottomMargin: 8
                anchors.topMargin: 15 // Leave space for rotation handle
                drag.target: parent

                onPressed: {
                    mainWindow.selectItem(imageRect)
                }
            }

            // Rotation handle for image component
            MouseArea {
                id: rotationHandle
                width: 12
                height: 12
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: -6
                visible: parent.selected
                cursorShape: Qt.OpenHandCursor

                property real centerX
                property real centerY
                property real startAngle

                onPressed: {
                    // Get the center point of the image item in global coordinates
                    var globalCenter = imageRect.mapToItem(imageRect.parent, imageRect.width/2, imageRect.height/2)
                    centerX = globalCenter.x
                    centerY = globalCenter.y

                    // Calculate initial angle from center to mouse position
                    var globalMouse = mapToItem(imageRect.parent, mouseX, mouseY)
                    startAngle = Math.atan2(globalMouse.y - centerY, globalMouse.x - centerX) * 180 / Math.PI - imageRect.imageRotation

                    cursorShape = Qt.ClosedHandCursor
                }

                onReleased: {
                    cursorShape = Qt.OpenHandCursor
                }

                onPositionChanged: {
                    if (pressed) {
                        // Calculate current angle from center to mouse position
                        var globalMouse = mapToItem(imageRect.parent, mouseX, mouseY)
                        var currentAngle = Math.atan2(globalMouse.y - centerY, globalMouse.x - centerX) * 180 / Math.PI

                        // Set rotation based on angle difference
                        imageRect.imageRotation = currentAngle - startAngle
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "#007acc"
                    border.color: "#ffffff"
                    border.width: 1
                }
            }

            // Resize handle
            MouseArea {
                id: resizeHandle
                width: 10
                height: 10
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

                        imageRect.width = Math.max(100, imageRect.width + deltaX)
                        imageRect.height = Math.max(40, imageRect.height + deltaY)

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

    CustomColorDialog {
        id: colorDialog
        selectedColor: colorPicker.selectedColor
        onColorAccepted: {
            colorPicker.selectedColor = selectedColor
        }
    }

    function moveItemUp(item) {
        var currentIndex = -1

        // Find current index
        for (var i = 0; i < itemsModel.count; i++) {
            if (itemsModel.get(i).item === item) {
                currentIndex = i
                break
            }
        }

        if (currentIndex > 0) {
            // Swap with item above
            var itemAbove = itemsModel.get(currentIndex - 1)
            var currentItem = itemsModel.get(currentIndex)

            var tempLayer = itemAbove.layer
            itemAbove.item.itemLayer = currentItem.layer
            currentItem.item.itemLayer = tempLayer

            // Update model
            itemsModel.setProperty(currentIndex - 1, "layer", currentItem.layer)
            itemsModel.setProperty(currentIndex, "layer", tempLayer)

            // Move in model (swap positions)
            itemsModel.move(currentIndex, currentIndex - 1, 1)
        }
    }

    function moveItemDown(item) {
        var currentIndex = -1

        // Find current index
        for (var i = 0; i < itemsModel.count; i++) {
            if (itemsModel.get(i).item === item) {
                currentIndex = i
                break
            }
        }

        if (currentIndex < itemsModel.count - 1 && currentIndex >= 0) {
            // Swap with item below
            var itemBelow = itemsModel.get(currentIndex + 1)
            var currentItem = itemsModel.get(currentIndex)

            var tempLayer = itemBelow.layer
            itemBelow.item.itemLayer = currentItem.layer
            currentItem.item.itemLayer = tempLayer

            // Update model
            itemsModel.setProperty(currentIndex + 1, "layer", currentItem.layer)
            itemsModel.setProperty(currentIndex, "layer", tempLayer)

            // Move in model (swap positions)
            itemsModel.move(currentIndex, currentIndex + 1, 1)
        }
    }

    function addItemToModel(item) {
        var preview, type, details

        if (item.hasOwnProperty('textContent')) {
            // Text item
            preview = item.textContent.length > 20 ?
                        item.textContent.substring(0, 20) + "..." :
                        item.textContent
            type = "Text"
            details = item.fontFamily + " " + item.fontSize + "pt"
        } else {
            // Image item
            var fileName = item.source.toString().split('/').pop()
            preview = fileName.length > 20 ? fileName.substring(0, 20) + "..." : fileName
            type = "Image"
            details = Math.round(item.width) + "×" + Math.round(item.height)
        }

        // Find the highest z value and increment by 1
        var highestZ = 0
        for (var i = 0; i < itemsModel.count; i++) {
            var existingItem = itemsModel.get(i)
            if (existingItem.layer > highestZ) {
                highestZ = existingItem.layer
            }
        }

        // Set new item's layer to be on top
        var newLayer = highestZ + 1
        item.itemLayer = newLayer

        // Insert at the beginning (top of list = highest z)
        itemsModel.insert(0, {
            item: item,
            preview: preview || "Empty",
            type: type,
            details: details,
            layer: newLayer,
            isSelected: true
        })

        // Deselect all other items
        for (var j = 1; j < itemsModel.count; j++) {
            itemsModel.setProperty(j, "isSelected", false)
        }
    }

    function updateItemPreview(item) {
        for (var i = 0; i < itemsModel.count; i++) {
            var modelItem = itemsModel.get(i)
            if (modelItem.item === item) {
                var preview, details

                if (item.hasOwnProperty('textContent')) {
                    preview = item.textContent.length > 20 ?
                                item.textContent.substring(0, 20) + "..." :
                                item.textContent
                    details = item.fontFamily + " " + item.fontSize + "pt"
                } else {
                    var fileName = item.source.toString().split('/').pop()
                    preview = fileName.length > 20 ? fileName.substring(0, 20) + "..." : fileName
                    details = Math.round(item.width) + "×" + Math.round(item.height)
                }

                itemsModel.setProperty(i, "preview", preview || "Empty")
                itemsModel.setProperty(i, "details", details)
                itemsModel.setProperty(i, "layer", item.itemLayer)
                break
            }
        }
    }

    function selectItem(item) {
        // Deselect all items first
        for (var j = 0; j < imageContainer.children.length; j++) {
            var child = imageContainer.children[j]
            if (child.hasOwnProperty('selected')) {
                child.selected = false
            }
        }

        // Update model selection states
        for (var i = 0; i < itemsModel.count; i++) {
            var isSelected = itemsModel.get(i).item === item
            itemsModel.setProperty(i, "isSelected", isSelected)
        }

        // Select the target item
        if (item && item.hasOwnProperty('selected')) {
            item.selected = true
        }

        mainWindow.selectedTextItem = item
        mainWindow.updateControls()
    }

    function deleteItem(item) {
        // Remove from model
        for (var i = 0; i < itemsModel.count; i++) {
            if (itemsModel.get(i).item === item) {
                itemsModel.remove(i)
                break
            }
        }

        // Clear selection if this was selected
        if (mainWindow.selectedTextItem === item) {
            mainWindow.selectedTextItem = null
            mainWindow.updateControls()
        }

        // Destroy the item
        item.destroy()
    }

    function updateControls() {
        if (selectedTextItem && selectedTextItem.hasOwnProperty('textContent')) {
            textContent.text = selectedTextItem.textContent
            fontFamily.currentIndex = fontFamily.find(selectedTextItem.fontFamily)
            fontSize.value = selectedTextItem.fontSize
            boldCheck.checked = selectedTextItem.fontBold
            italicCheck.checked = selectedTextItem.fontItalic
            colorPicker.selectedColor = selectedTextItem.textColor
        } else {
            // Clear controls when nothing is selected or image is selected
            textContent.text = ""
            fontFamily.currentIndex = -1
            fontSize.value = 24
            boldCheck.checked = false
            italicCheck.checked = false
            colorPicker.selectedColor = "black"
        }
    }
}
