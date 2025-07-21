pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls.impl
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
    Material.theme: UserSettings.darkMode ? Material.Dark : Material.Light
    color: Colors.backgroundColor

    property string currentImageSource: ""
    property var selectedTextItem: null
    property real imageRotation: 0

    header: ToolBar {
        height: 50
        RowLayout {
            anchors.fill: parent
            anchors.rightMargin: 15
            spacing: 0
            property int buttonWidth: Math.max(fileBtn.implicitWidth, layersBtn.implicitWidth) + 20
            property int rightButtonWidth: Math.max(donateButton.implicitWidth, githubButton.implicitWidth) + 20


            ToolButton {
                id: fileBtn
                text: "File"
                Layout.preferredHeight: 50
                Layout.preferredWidth: parent.buttonWidth
                icon.source: "qrc:/icons/file.svg"
                icon.color: "white"
                Material.foreground: "white"
                icon.width: 16
                icon.height: 16
                onClicked: fileMenu.visible = !fileMenu.visible

                Menu {
                    id: fileMenu
                    y: 50
                    MenuItem {
                        text: "Upload Image"
                        onClicked: {
                            if (Qt.platform.os === "wasm") {
                                FileHandler.openFileDialog()
                            } else {
                                fileDialog.open()
                            }
                        }
                    }

                    MenuItem {
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
                }
            }

            ToolButton {
                id: layersBtn
                text: "Layers"
                Layout.preferredHeight: 50
                Layout.preferredWidth: parent.buttonWidth
                icon.source: "qrc:/icons/layer.svg"
                icon.color: "white"
                Material.foreground: "white"
                icon.width: 16
                icon.height: 16
                onClicked: layersMenu.visible = !layersMenu.visible


                Menu {
                    id: layersMenu
                    y: 50
                    MenuItem {
                        text: "Add Text Layer"
                        enabled: mainWindow.currentImageSource !== ""
                        onClicked: {
                            var textItem = textComponent.createObject(imageContainer, {
                                x: 50,
                                y: 50
                            })
                            mainWindow.addItemToModel(textItem)
                            mainWindow.selectItem(textItem)
                        }
                    }

                    MenuItem {
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
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                id: githubButton
                text: qsTr("Github")
                icon.source: "qrc:/icons/github.svg"
                Layout.preferredWidth: parent.rightButtonWidth
                icon.color: "white"
                icon.width: 20
                icon.height: 20
                flat: true
                onClicked: {
                    Qt.openUrlExternally("https://github.com/odizinne/quickedits")
                    donatePopup.close()
                }
            }

            Button {
                id: donateButton
                text: qsTr("Donate")
                Layout.leftMargin: 8
                icon.source: "qrc:/icons/donate.svg"
                Layout.preferredWidth: parent.rightButtonWidth
                icon.color: Material.accent
                icon.width: 20
                icon.height: 20
                font.bold: true
                flat: true
                onClicked: {
                    Qt.openUrlExternally("https://ko-fi.com/odizinne")
                    donatePopup.close()
                }
            }

            ToolSeparator {
                Layout.leftMargin: 10
                Layout.rightMargin: 10
            }

            Item {
                Layout.preferredHeight: 24
                Layout.preferredWidth: 24

                IconImage {
                    id: sunImage
                    anchors.fill: parent
                    source: "qrc:/icons/sun.png"
                    color: "#ffca38"
                    opacity: !themeSwitch.checked ? 1 : 0
                    rotation: themeSwitch.checked ? 360 : 0
                    mipmap: true

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.OutQuad
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 500 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: themeSwitch.checked = !themeSwitch.checked
                    }
                }

                Image {
                    anchors.fill: parent
                    id: moonImage
                    source: "qrc:/icons/moon.png"
                    opacity: themeSwitch.checked ? 1 : 0
                    rotation: themeSwitch.checked ? 360 : 0
                    mipmap: true

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.OutQuad
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 100 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: themeSwitch.checked = !themeSwitch.checked
                    }
                }
            }

            Switch {
                id: themeSwitch
                checked: UserSettings.darkMode
                onClicked: UserSettings.darkMode = checked
                Layout.rightMargin: -10
            }
        }
    }

    Connections {
        target: ImageExporter
        function onSaveFileSelected(fileName) {
            console.log("QML: Save file selected:", fileName)
            if (Qt.platform.os === "wasm") {
                // For WebAssembly, show our custom naming dialog
                saveNamingDialog.setFileName(fileName)
                saveNamingDialog.open()
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

    SaveNamingDialog {
        id: saveNamingDialog

        onFileNameAccepted: function(fileName) {
            console.log("QML: Save dialog accepted with filename:", fileName)
            ImageExporter.saveImage(imageContainer, fileName)
            donatePopup.visible = UserSettings.displayDonate
        }

        onFileNameRejected: {
            console.log("QML: Save dialog cancelled")
        }
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

    Component.onCompleted: {
        mainLyt.opacity = 1
        Qt.fontFamilies()
    }

    DonatePopup {
        id: donatePopup
        anchors.centerIn: parent
    }

    FontLoader {
        id: customFont1
        source: "qrc:/fonts/RUNE.ttf"
    }

    FontLoader {
        id: customFont2
        source: "qrc:/fonts/CloisterBlack.ttf"
    }

    FontLoader {
        id: customFont3
        source: "qrc:/fonts/MessySketch-Regular.ttf"
    }

    RowLayout {
        id: mainLyt
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15
        opacity: Qt.platform.os === "wasm" ? 0 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InQuad
            }
        }

        // Left panel - controls
        Pane {
            Material.background: Colors.paneColor
            Material.elevation: 6
            Material.roundedScale: Material.ExtraSmallScale
            Layout.preferredWidth: 300
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                Label {
                    font.pixelSize: 18
                    font.bold: true
                    text: "Background Properties"
                    visible: mainWindow.currentImageSource !== ""
                }

                RowLayout {
                    visible: mainWindow.currentImageSource !== ""
                    property int buttonWidth: Math.max(rtLeftBtn.implicitHeight, rtRightBtn.implicitHeight, rtResetBtn.implicitHeight)

                    MaterialButton {
                        id: rtLeftBtn
                        text: "↺ Left"
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.buttonWidth
                        onClicked: {
                            mainWindow.imageRotation -= 90
                        }
                    }
                    MaterialButton {
                        id: rtRightBtn
                        text: "↻ Right"
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.buttonWidth
                        onClicked: {
                            mainWindow.imageRotation += 90
                        }
                    }
                    MaterialButton {
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
                    font.pixelSize: 18
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
                            Layout.preferredWidth: 110
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

                    MaterialButton {
                        id: colorButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        text: "Text Color"
                        onClicked: {
                            colorDialog.selectedColor = colorPicker.selectedColor
                            colorDialog.currentColor = colorPicker.selectedColor
                            colorDialog.open()
                        }

                        // Calculate text color based on background brightness
                        property real backgroundLuminance: 0.299 * colorPicker.selectedColor.r +
                                                           0.587 * colorPicker.selectedColor.g +
                                                           0.114 * colorPicker.selectedColor.b

                        contentItem: Label {
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
                            radius: Material.ExtraSmallScale
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

                    MaterialButton {
                        id: textResetBtn
                        text: "Reset rotation"
                        Layout.fillWidth: true
                        onClicked: {
                            if (mainWindow.selectedTextItem) {
                                mainWindow.selectedTextItem.textRotation = 0
                            }
                        }
                    }

                    MaterialButton {
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
                    font.pixelSize: 18
                    font.bold: true
                }

                ColumnLayout {
                    spacing: 10
                    visible: mainWindow.selectedTextItem !== null && !mainWindow.selectedTextItem.hasOwnProperty('textContent')

                    MaterialButton {
                        id: imgResetBtn
                        text: "Reset rotation"
                        Layout.fillWidth: true
                        onClicked: {
                            if (mainWindow.selectedTextItem) {
                                mainWindow.selectedTextItem.imageRotation = 0
                            }
                        }
                    }

                    MaterialButton {
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

            Label {
                text: "Controls"
                opacity: 0.5
                font.pixelSize: 18
                anchors.centerIn: parent
                visible: mainWindow.currentImageSource === ""
            }
        }

        // Center panel - image area
        Pane {
            Material.background: Colors.paneColor
            Material.elevation: 6
            Material.roundedScale: Material.ExtraSmallScale
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
        Pane {
            Material.background: Colors.paneColor
            Material.elevation: 6
            Material.roundedScale: Material.ExtraSmallScale
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
                                    color: delegateRoot.model.isSelected ? Colors.accentColorDimmed : "transparent"
                                    border.color: delegateRoot.model.isSelected ? Colors.accentColor : "#333"
                                    border.width: 2
                                    radius: Material.ExtraSmallScale

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

                                        Label {
                                            Layout.fillWidth: true
                                            text: delegateRoot.model.preview
                                            color: Material.foreground
                                            font.weight: delegateRoot.model.isSelected ? Font.Bold : Font.Normal
                                            elide: Text.ElideRight
                                            font.pixelSize: 12
                                        }

                                        Label {
                                            Layout.fillWidth: true
                                            text: delegateRoot.model.type + " - " + delegateRoot.model.details
                                            font.pixelSize: 11
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.preferredWidth: 35
                                    Layout.fillHeight: true
                                    spacing: 2

                                    MaterialButton {
                                        Layout.preferredHeight: 25
                                        Layout.preferredWidth: 25
                                        text: "▲"
                                        enabled: delegateRoot.index > 0
                                        font.pixelSize: 8

                                        onClicked: {
                                            mainWindow.moveItemUp(delegateRoot.model.item)
                                        }
                                    }

                                    MaterialButton {
                                        Layout.preferredHeight: 25
                                        Layout.preferredWidth: 25
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
                    color: Colors.accentColorDimmed
                    border.width: 2
                    border.color: Colors.accentColor
                    radius: Material.ExtraSmallScale
                }
            }

            TextEdit {
                id: textEdit
                anchors.fill: parent
                anchors.margins: 10
                text: "Sample Text"
                font.family: "Arial"
                font.pixelSize: 24
                color: Colors.placeholderColor
                selectByMouse: false
                wrapMode: TextEdit.Wrap
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 8
                anchors.bottomMargin: 8
                anchors.topMargin: 15 // Leave space for rotation handle
                drag.target: parent
                drag.minimumX: 0
                drag.maximumX: imageContainer.width - parent.width
                drag.minimumY: 0
                drag.maximumY: imageContainer.height - parent.height

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
                    color: Colors.accentColor
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
                    color: Colors.accentColor
                    bottomRightRadius: Material.ExtraSmallScale
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

            // Container that rotates with the content
            Item {
                id: rotatingContainer
                anchors.fill: parent
                anchors.margins: 2
                rotation: imageRect.imageRotation

                // Selection border - now rotates with content
                Rectangle {
                    anchors.fill: parent
                    color: imageRect.selected ? Colors.accentColorDimmed : "transparent"
                    border.width: imageRect.selected ? 2 : 0
                    border.color: Colors.accentColor
                    radius: Material.ExtraSmallScale
                }

                Image {
                    id: layerImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 8
                anchors.bottomMargin: 8
                anchors.topMargin: 15 // Leave space for rotation handle
                drag.target: parent
                drag.minimumX: 0
                drag.maximumX: imageContainer.width - parent.width
                drag.minimumY: 0
                drag.maximumY: imageContainer.height - parent.height

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
                    color: Colors.accentColor
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
                    color: Colors.accentColor
                    bottomRightRadius: Material.ExtraSmallScale
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
            colorPicker.selectedColor = Colors.placeholderColor
        }
    }
}
