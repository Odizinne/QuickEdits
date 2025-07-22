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
    opacity: Qt.platform.os === "wasm" ? 0 : 1
    Behavior on opacity {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InQuad
        }
    }

    property real zoomFactor: 1.0
    property real minZoom: 0.1
    property real maxZoom: 3.0
    property real zoomStep: 0.1

    property real effectiveImageWidth: {
        if (currentImageSource !== "" && loadedImage.sourceSize.width > 0) {
            var angle = Math.abs(imageRotation % 180)
            if (angle === 90) {
                return loadedImage.sourceSize.height
            }
            return loadedImage.sourceSize.width
        }
        return 0
    }

    property real effectiveImageHeight: {
        if (currentImageSource !== "" && loadedImage.sourceSize.height > 0) {
            var angle = Math.abs(imageRotation % 180)
            if (angle === 90) {
                return loadedImage.sourceSize.width
            }
            return loadedImage.sourceSize.height
        }
        return 0
    }

    // Calculate the minimum zoom to fit the rotated image in the available area
    property real fitZoom: {
        if (currentImageSource !== "" && imageFlickable.width > 0 && imageFlickable.height > 0) {
            if (effectiveImageWidth > 0 && effectiveImageHeight > 0) {
                var scaleX = imageFlickable.width / effectiveImageWidth
                var scaleY = imageFlickable.height / effectiveImageHeight
                return Math.min(scaleX, scaleY)
            }
        }
        return minZoom
    }

    // Dynamic minimum zoom - never go below fit zoom
    property real effectiveMinZoom: Math.max(minZoom, fitZoom)

    function zoomIn() {
        if (zoomFactor < maxZoom) {
            zoomFactor = Math.min(maxZoom, zoomFactor + zoomStep)
        }
    }

    function zoomOut() {
        if (zoomFactor > effectiveMinZoom) {
            zoomFactor = Math.max(effectiveMinZoom, zoomFactor - zoomStep)
        }
    }

    function resetZoom() {
        zoomFactor = Math.max(1.0, effectiveMinZoom)
    }

    function fitToScreen() {
        zoomFactor = fitZoom
    }

    property string currentImageSource: ""
    property var selectedTextItem: null
    property real imageRotation: 0

    header: ToolBar {
        height: 50
        RowLayout {
            anchors.fill: parent
            anchors.rightMargin: 15
            spacing: 0
            property int buttonWidth: Math.max(fileBtn.implicitWidth, layersBtn.implicitWidth, fontsBtn.implicitWidth) + 20
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
                            ImageExporter.openSaveDialog(scaledContent)
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
                            var textItem = textComponent.createObject(scaledContent, {
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

            ToolButton {
                id: fontsBtn
                text: "Fonts"
                Layout.preferredHeight: 50
                Layout.preferredWidth: parent.buttonWidth
                icon.source: "qrc:/icons/font.svg"
                icon.color: "white"
                Material.foreground: "white"
                icon.width: 16
                icon.height: 16
                onClicked: fontsMenu.visible = !fontsMenu.visible


                Menu {
                    id: fontsMenu
                    y: 50

                    MenuItem {
                        text: "Manage Fonts..."
                        onClicked: {
                            fontManagerDialog.open()
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                id: downloadButton
                text: qsTr("Desktop App")
                icon.source: "qrc:/icons/download.svg"
                Layout.preferredWidth: implicitWidth + 20
                icon.color: "white"
                icon.width: 20
                icon.height: 20
                flat: true
                visible: Qt.platform.os === "wasm"
                Material.foreground: "white"
                onClicked: {
                    downloadPopup.open()
                }
            }

            ToolSeparator {
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                visible: Qt.platform.os === "wasm"
                contentItem: Rectangle {
                    implicitWidth: 1
                    implicitHeight: 38
                    color: "#FFFFFF"
                    opacity: 0.3
                }
            }

            Button {
                id: githubButton
                text: qsTr("Github")
                icon.source: "qrc:/icons/github.svg"
                Layout.preferredWidth: parent.rightButtonWidth
                Material.foreground: "white"
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
                Material.foreground: "white"
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
                contentItem: Rectangle {
                    implicitWidth: 1
                    implicitHeight: 38
                    color: "#FFFFFF"
                    opacity: 0.3
                }
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
        function onSaveFileSelected(fileName, originalWidth, originalHeight) {
            console.log("QML: Save file selected:", fileName, "Resolution:", originalWidth + "x" + originalHeight)
            saveNamingDialog.setFileName(fileName)
            saveNamingDialog.setOriginalResolution(originalWidth, originalHeight)
            saveNamingDialog.open()
        }
    }

    Connections {
        target: FileHandler
        function onFileSelected(filePath) {
            console.log("QML: Main image file selected:", filePath)
            mainWindow.currentImageSource = filePath
            imageContainer.visible = true

            // Auto-fit the image when loaded
            Qt.callLater(function() {
                mainWindow.fitToScreen()
            })
        }

        function onLayerImageSelected(filePath) {
            console.log("QML: Layer image file selected:", filePath)
            var imageItem = imageComponent.createObject(scaledContent, {
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

        onFileNameAccepted: function(fileName, width, height) {
            console.log("QML: Save dialog accepted with filename:", fileName, "Resolution:", width + "x" + height)

            if (Qt.platform.os === "wasm") {
                // WebAssembly: grab and save directly
                ImageExporter.grabImageAndSave(fileName, width, height)
            } else {
                // Native: grab first, then open file dialog
                ImageExporter.grabImageAndSave(fileName, width, height)
                Qt.callLater(function() {
                    saveFileDialog.currentFile = Qt.resolvedUrl(saveFileDialog.currentFolder + "/" + fileName)
                    saveFileDialog.open()
                })
            }

            donatePopup.visible = UserSettings.displayDonate
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

            // Auto-fit the image when loaded
            Qt.callLater(function() {
                mainWindow.fitToScreen()
            })
        }
    }

    FileDialog {
        id: layerImageDialog
        title: "Select image for layer"
        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.bmp *.webp)"]
        onAccepted: {
            var imageItem = imageComponent.createObject(scaledContent, {
                                                            x: 50,
                                                            y: 50,
                                                            source: selectedFile
                                                        })
            mainWindow.addItemToModel(imageItem)
            mainWindow.selectItem(imageItem)
        }
    }

    FileDialog {
        id: saveFileDialog
        title: "Save image as..."
        fileMode: FileDialog.SaveFile
        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
        nameFilters: ["PNG files (*.png)", "JPEG files (*.jpg *.jpeg)", "BMP files (*.bmp)", "WebP files (*.webp)", "All files (*)"]
        defaultSuffix: "png"

        onAccepted: {
            // This will use the grabbed image since it's stored in ImageExporter
            ImageExporter.saveImage(null, selectedFile)
        }
    }

    Component.onCompleted: {
        mainLyt.opacity = 1
        Qt.fontFamilies()
    }

    FontManagerDialog {
        id: fontManagerDialog
        anchors.centerIn: parent
    }

    DonatePopup {
        id: donatePopup
        anchors.centerIn: parent
    }

    DownloadPopup {
        id: downloadPopup
        anchors.centerIn: parent
    }

    RowLayout {
        id: mainLyt
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15
        visible: mainWindow.currentImageSource !== ""

        // Left panel - controls
        Pane {
            Material.background: Colors.paneColor
            Material.elevation: 6
            Material.roundedScale: Material.ExtraSmallScale
            Layout.preferredWidth: 325
            Layout.fillHeight: true

            ScrollView {
                id: scrlView
                anchors.fill: parent
                ScrollBar.vertical.policy: controlsLyt.implicitHeight > height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                clip: true
                property bool sbVisible: ScrollBar.vertical.policy === ScrollBar.AlwaysOn

                ColumnLayout {
                    id: controlsLyt
                    width: scrlView.sbVisible ? scrlView.width - 25 : scrlView.width
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

                    ColumnLayout {
                        visible: mainWindow.currentImageSource !== ""
                        spacing: 8

                        Label {
                            text: "Zoom: " + Math.round(mainWindow.zoomFactor * 100) + "%"
                            font.pixelSize: 12
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Slider {
                                id: zoomSlider
                                Layout.fillWidth: true
                                from: mainWindow.effectiveMinZoom
                                to: mainWindow.maxZoom
                                value: mainWindow.zoomFactor
                                stepSize: 0.05

                                onValueChanged: {
                                    if (mainWindow.zoomFactor !== value) {
                                        mainWindow.zoomFactor = value
                                    }
                                }

                                Connections {
                                    target: mainWindow
                                    function onZoomFactorChanged() {
                                        if (zoomSlider.value !== mainWindow.zoomFactor) {
                                            zoomSlider.value = mainWindow.zoomFactor
                                        }
                                    }
                                }
                            }

                            MaterialButton {
                                text: "Reset"
                                Layout.preferredWidth: 60
                                onClicked: {
                                    mainWindow.resetZoom()
                                }
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
                        id: txtPropsLyt
                        spacing: 10
                        visible: mainWindow.selectedTextItem !== null && mainWindow.selectedTextItem.hasOwnProperty('textContent')
                        property int checkBoxWidth: Math.max(boldCheck.implicitWidth, italicCheck.implicitWidth, underlineCheck.implicitWidth, strikeoutCheck.implicitWidth) + 20

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
                                model: FontManager.availableFonts
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
                                Layout.preferredWidth: txtPropsLyt.checkBoxWidth
                                text: "Bold"
                                onCheckedChanged: {
                                    if (mainWindow.selectedTextItem && mainWindow.selectedTextItem.hasOwnProperty('fontBold'))
                                    mainWindow.selectedTextItem.fontBold = checked
                                }
                            }
                            CheckBox {
                                id: italicCheck
                                Layout.preferredWidth: txtPropsLyt.checkBoxWidth
                                text: "Italic"
                                onCheckedChanged: {
                                    if (mainWindow.selectedTextItem && mainWindow.selectedTextItem.hasOwnProperty('fontItalic'))
                                    mainWindow.selectedTextItem.fontItalic = checked
                                }
                            }
                        }

                        RowLayout {
                            CheckBox {
                                id: underlineCheck
                                Layout.preferredWidth: txtPropsLyt.checkBoxWidth
                                text: "Underline"
                                onCheckedChanged: {
                                    if (mainWindow.selectedTextItem && mainWindow.selectedTextItem.hasOwnProperty('fontUnderline'))
                                    mainWindow.selectedTextItem.fontUnderline = checked
                                }
                            }
                            CheckBox {
                                id: strikeoutCheck
                                Layout.preferredWidth: txtPropsLyt.checkBoxWidth
                                text: "Strikeout"
                                onCheckedChanged: {
                                    if (mainWindow.selectedTextItem && mainWindow.selectedTextItem.hasOwnProperty('fontStrikeout'))
                                    mainWindow.selectedTextItem.fontStrikeout = checked
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

                        // Position Section
                        MenuSeparator { Layout.fillWidth: true }

                        Label {
                            text: "Position"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        RowLayout {
                            Label { text: "X:" }
                            Slider {
                                id: xPositionSlider
                                Layout.fillWidth: true
                                from: 0
                                to: scaledContent.width - (mainWindow.selectedTextItem ? mainWindow.selectedTextItem.width : 0)
                                value: mainWindow.selectedTextItem ? mainWindow.selectedTextItem.x : 0
                                onValueChanged: {
                                    if (mainWindow.selectedTextItem && value !== mainWindow.selectedTextItem.x) {
                                        mainWindow.selectedTextItem.x = value
                                    }
                                }
                            }
                            Label { text: Math.round(xPositionSlider.value) }
                        }

                        RowLayout {
                            Label { text: "Y:" }
                            Slider {
                                id: yPositionSlider
                                Layout.fillWidth: true
                                from: 0
                                to: scaledContent.height - (mainWindow.selectedTextItem ? mainWindow.selectedTextItem.height : 0)
                                value: mainWindow.selectedTextItem ? mainWindow.selectedTextItem.y : 0
                                onValueChanged: {
                                    if (mainWindow.selectedTextItem && value !== mainWindow.selectedTextItem.y) {
                                        mainWindow.selectedTextItem.y = value
                                    }
                                }
                            }
                            Label { text: Math.round(yPositionSlider.value) }
                        }

                        Connections {
                            target: mainWindow.selectedTextItem
                            function onWidthChanged() {
                                if (mainWindow.selectedTextItem && mainWindow.selectedTextItem.hasOwnProperty('textContent')) {
                                    xPositionSlider.to = scaledContent.width - mainWindow.selectedTextItem.width
                                    // Clamp current position if it's now out of bounds
                                    if (xPositionSlider.value > xPositionSlider.to) {
                                        mainWindow.selectedTextItem.x = xPositionSlider.to
                                    }
                                }
                            }
                            function onHeightChanged() {
                                if (mainWindow.selectedTextItem && mainWindow.selectedTextItem.hasOwnProperty('textContent')) {
                                    yPositionSlider.to = scaledContent.height - mainWindow.selectedTextItem.height
                                    // Clamp current position if it's now out of bounds
                                    if (yPositionSlider.value > yPositionSlider.to) {
                                        mainWindow.selectedTextItem.y = yPositionSlider.to
                                    }
                                }
                            }
                        }

                        // Align Section
                        MenuSeparator { Layout.fillWidth: true }

                        Label {
                            text: "Align"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            MaterialButton {
                                text: "H Center"
                                Layout.fillWidth: true
                                onClicked: {
                                    if (mainWindow.selectedTextItem) {
                                        var centerX = (scaledContent.width - mainWindow.selectedTextItem.width) / 2
                                        mainWindow.selectedTextItem.x = centerX
                                    }
                                }
                            }

                            MaterialButton {
                                text: "V Center"
                                Layout.fillWidth: true
                                onClicked: {
                                    if (mainWindow.selectedTextItem) {
                                        var centerY = (scaledContent.height - mainWindow.selectedTextItem.height) / 2
                                        mainWindow.selectedTextItem.y = centerY
                                    }
                                }
                            }
                        }

                        // Anchors Section
                        MenuSeparator { Layout.fillWidth: true }


                        RowLayout {
                            Label {
                                text: "Anchors"
                                font.pixelSize: 16
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Grid {
                                columns: 3
                                spacing: 4

                                AnchorsButton {
                                    imageSource: "qrc:/icons/corner.svg"
                                    imageRotation: 0
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = 0
                                            mainWindow.selectedTextItem.y = 0
                                        }
                                    }
                                }

                                AnchorsButton {
                                    imageSource: "qrc:/icons/side.svg"
                                    imageRotation: 90
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = (scaledContent.width - mainWindow.selectedTextItem.width) / 2
                                            mainWindow.selectedTextItem.y = 0
                                        }
                                    }
                                }

                                AnchorsButton {
                                    imageSource: "qrc:/icons/corner.svg"
                                    imageRotation: 90
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = scaledContent.width - mainWindow.selectedTextItem.width
                                            mainWindow.selectedTextItem.y = 0
                                        }
                                    }
                                }

                                AnchorsButton {
                                    imageSource: "qrc:/icons/side.svg"
                                    imageRotation: 0
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = 0
                                            mainWindow.selectedTextItem.y = (scaledContent.height - mainWindow.selectedTextItem.height) / 2
                                        }
                                    }
                                }

                                AnchorsButton {
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = (scaledContent.width - mainWindow.selectedTextItem.width) / 2
                                            mainWindow.selectedTextItem.y = (scaledContent.height - mainWindow.selectedTextItem.height) / 2
                                        }
                                    }
                                }

                                AnchorsButton {
                                    imageSource: "qrc:/icons/side.svg"
                                    imageRotation: 180
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = scaledContent.width - mainWindow.selectedTextItem.width
                                            mainWindow.selectedTextItem.y = (scaledContent.height - mainWindow.selectedTextItem.height) / 2
                                        }
                                    }
                                }

                                AnchorsButton {
                                    imageSource: "qrc:/icons/corner.svg"
                                    imageRotation: 270
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = 0
                                            mainWindow.selectedTextItem.y = scaledContent.height - mainWindow.selectedTextItem.height
                                        }
                                    }
                                }

                                AnchorsButton {
                                    imageSource: "qrc:/icons/side.svg"
                                    imageRotation: 270
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = (scaledContent.width - mainWindow.selectedTextItem.width) / 2
                                            mainWindow.selectedTextItem.y = scaledContent.height - mainWindow.selectedTextItem.height
                                        }
                                    }
                                }

                                AnchorsButton {
                                    imageSource: "qrc:/icons/corner.svg"
                                    imageRotation: 180
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = scaledContent.width - mainWindow.selectedTextItem.width
                                            mainWindow.selectedTextItem.y = scaledContent.height - mainWindow.selectedTextItem.height
                                        }
                                    }
                                }
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

                        // Position Section for Images
                        Label {
                            text: "Position"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        RowLayout {
                            Label { text: "X:" }
                            Slider {
                                id: imgXPositionSlider
                                Layout.fillWidth: true
                                from: 0
                                to: scaledContent.width - (mainWindow.selectedTextItem ? mainWindow.selectedTextItem.width : 0)
                                value: mainWindow.selectedTextItem ? mainWindow.selectedTextItem.x : 0
                                onValueChanged: {
                                    if (mainWindow.selectedTextItem && value !== mainWindow.selectedTextItem.x) {
                                        mainWindow.selectedTextItem.x = value
                                    }
                                }
                            }
                            Label { text: Math.round(imgXPositionSlider.value) }
                        }

                        RowLayout {
                            Label { text: "Y:" }
                            Slider {
                                id: imgYPositionSlider
                                Layout.fillWidth: true
                                from: 0
                                to: scaledContent.height - (mainWindow.selectedTextItem ? mainWindow.selectedTextItem.height : 0)
                                value: mainWindow.selectedTextItem ? mainWindow.selectedTextItem.y : 0
                                onValueChanged: {
                                    if (mainWindow.selectedTextItem && value !== mainWindow.selectedTextItem.y) {
                                        mainWindow.selectedTextItem.y = value
                                    }
                                }
                            }
                            Label { text: Math.round(imgYPositionSlider.value) }
                        }

                        Connections {
                            target: mainWindow.selectedTextItem
                            function onWidthChanged() {
                                if (mainWindow.selectedTextItem && !mainWindow.selectedTextItem.hasOwnProperty('textContent')) {
                                    imgXPositionSlider.to = scaledContent.width - mainWindow.selectedTextItem.width
                                    // Clamp current position if it's now out of bounds
                                    if (imgXPositionSlider.value > imgXPositionSlider.to) {
                                        mainWindow.selectedTextItem.x = imgXPositionSlider.to
                                    }
                                }
                            }
                            function onHeightChanged() {
                                if (mainWindow.selectedTextItem && !mainWindow.selectedTextItem.hasOwnProperty('textContent')) {
                                    imgYPositionSlider.to = scaledContent.height - mainWindow.selectedTextItem.height
                                    // Clamp current position if it's now out of bounds
                                    if (imgYPositionSlider.value > imgYPositionSlider.to) {
                                        mainWindow.selectedTextItem.y = imgYPositionSlider.to
                                    }
                                }
                            }
                        }

                        // Align Section for Images
                        MenuSeparator { Layout.fillWidth: true }

                        Label {
                            text: "Align"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            MaterialButton {
                                text: "H Center"
                                Layout.fillWidth: true
                                onClicked: {
                                    if (mainWindow.selectedTextItem) {
                                        var centerX = (scaledContent.width - mainWindow.selectedTextItem.width) / 2
                                        mainWindow.selectedTextItem.x = centerX
                                    }
                                }
                            }

                            MaterialButton {
                                text: "V Center"
                                Layout.fillWidth: true
                                onClicked: {
                                    if (mainWindow.selectedTextItem) {
                                        var centerY = (scaledContent.height - mainWindow.selectedTextItem.height) / 2
                                        mainWindow.selectedTextItem.y = centerY
                                    }
                                }
                            }
                        }

                        // Anchors Section for Images
                        MenuSeparator { Layout.fillWidth: true }

                        RowLayout {
                            Label {
                                text: "Anchors"
                                font.pixelSize: 16
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Grid {
                                Layout.fillWidth: true
                                columns: 3
                                spacing: 4

                                AnchorsButton {
                                    imageSource: "qrc:/icons/corner.svg"
                                    imageRotation: 0
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = 0
                                            mainWindow.selectedTextItem.y = 0
                                        }
                                    }
                                }

                                AnchorsButton {
                                    imageSource: "qrc:/icons/side.svg"
                                    imageRotation: 90
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = (scaledContent.width - mainWindow.selectedTextItem.width) / 2
                                            mainWindow.selectedTextItem.y = 0
                                        }
                                    }
                                }

                                AnchorsButton {
                                    imageSource: "qrc:/icons/corner.svg"
                                    imageRotation: 90
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = scaledContent.width - mainWindow.selectedTextItem.width
                                            mainWindow.selectedTextItem.y = 0
                                        }
                                    }
                                }

                                AnchorsButton {
                                    imageSource: "qrc:/icons/side.svg"
                                    imageRotation: 0
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = 0
                                            mainWindow.selectedTextItem.y = (scaledContent.height - mainWindow.selectedTextItem.height) / 2
                                        }
                                    }
                                }

                                AnchorsButton {
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = (scaledContent.width - mainWindow.selectedTextItem.width) / 2
                                            mainWindow.selectedTextItem.y = (scaledContent.height - mainWindow.selectedTextItem.height) / 2
                                        }
                                    }
                                }

                                AnchorsButton {
                                    imageSource: "qrc:/icons/side.svg"
                                    imageRotation: 180
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = scaledContent.width - mainWindow.selectedTextItem.width
                                            mainWindow.selectedTextItem.y = (scaledContent.height - mainWindow.selectedTextItem.height) / 2
                                        }
                                    }
                                }

                                AnchorsButton {
                                    imageSource: "qrc:/icons/corner.svg"
                                    imageRotation: 270
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = 0
                                            mainWindow.selectedTextItem.y = scaledContent.height - mainWindow.selectedTextItem.height
                                        }
                                    }
                                }

                                AnchorsButton {
                                    imageSource: "qrc:/icons/side.svg"
                                    imageRotation: 270
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = (scaledContent.width - mainWindow.selectedTextItem.width) / 2
                                            mainWindow.selectedTextItem.y = scaledContent.height - mainWindow.selectedTextItem.height
                                        }
                                    }
                                }

                                AnchorsButton {
                                    imageSource: "qrc:/icons/corner.svg"
                                    imageRotation: 180
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        if (mainWindow.selectedTextItem) {
                                            mainWindow.selectedTextItem.x = scaledContent.width - mainWindow.selectedTextItem.width
                                            mainWindow.selectedTextItem.y = scaledContent.height - mainWindow.selectedTextItem.height
                                        }
                                    }
                                }
                            }
                        }

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

            Flickable {
                id: imageFlickable
                anchors.fill: parent
                visible: mainWindow.currentImageSource !== ""
                property bool allowDrag: true

                interactive: allowDrag
                contentWidth: imageContainer.width
                contentHeight: imageContainer.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.horizontal: ScrollBar {
                    policy: imageFlickable.contentWidth > imageFlickable.width ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                }
                ScrollBar.vertical: ScrollBar {
                    policy: imageFlickable.contentHeight > imageFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                }

                // Add wheel handling for zoom
                WheelHandler {
                    acceptedModifiers: Qt.ControlModifier
                    onWheel: function(event) {
                        if (Qt.platform.os === "wasm") return

                        if (event.angleDelta.y > 0) {
                            mainWindow.zoomIn()
                        } else {
                            mainWindow.zoomOut()
                        }
                    }
                }

                Item {
                    id: imageContainer
                    width: Math.max(imageFlickable.width, mainWindow.effectiveImageWidth * mainWindow.zoomFactor)
                    height: Math.max(imageFlickable.height, mainWindow.effectiveImageHeight * mainWindow.zoomFactor)

                    // Add smooth animation to container size
                    Behavior on width {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }

                    // Handle deselection on background click
                    MouseArea {
                        anchors.fill: parent
                        onPressed: {
                            // Allow flickable to drag only if press is on background
                            imageFlickable.allowDrag = true
                        }

                        onClicked: {
                            // Deselect all items
                            for (var i = 0; i < scaledContent.children.length; i++) {
                                var child = scaledContent.children[i]
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

                    Item {
                        id: scaledContent
                        anchors.centerIn: parent
                        width: mainWindow.effectiveImageWidth
                        height: mainWindow.effectiveImageHeight

                        transform: [
                            Scale {
                                xScale: mainWindow.zoomFactor
                                yScale: mainWindow.zoomFactor
                                origin.x: scaledContent.width / 2
                                origin.y: scaledContent.height / 2

                                Behavior on xScale {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                    }
                                }

                                Behavior on yScale {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                    }
                                }
                            }
                        ]

                        Image {
                            id: loadedImage
                            anchors.centerIn: parent
                            source: mainWindow.currentImageSource
                            fillMode: Image.PreserveAspectFit
                            z: -1000
                            width: sourceSize.width
                            height: sourceSize.height

                            // Move rotation here instead of on scaledContent
                            transform: Rotation {
                                angle: mainWindow.imageRotation
                                origin.x: loadedImage.width / 2
                                origin.y: loadedImage.height / 2
                            }

                            onStatusChanged: {
                                if (status === Image.Ready && mainWindow.zoomFactor === 1.0) {
                                    mainWindow.fitToScreen()
                                }
                            }

                            Rectangle {
                                objectName: "imageBorder"
                                anchors.fill: parent
                                color: "transparent"
                                border.width: 2 / mainWindow.zoomFactor
                                border.color: Colors.accentColor
                            }
                        }

                        // All text and image components will be children of scaledContent
                        // and will follow the zoom but NOT the rotation
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

    Label {
        text: "Import an image to start"
        opacity: 0.5
        font.pixelSize: 18
        anchors.centerIn: parent
        visible: mainWindow.currentImageSource === ""
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
            property alias fontUnderline: textEdit.font.underline
            property alias fontStrikeout: textEdit.font.strikeout
            property alias textColor: textEdit.color
            property real textRotation: 0
            property alias itemLayer: textRect.z
            property bool selected: false

            // Update position sliders when item position changes
            onXChanged: {
                if (mainWindow.selectedTextItem === textRect) {
                    xPositionSlider.value = x
                }
            }

            onYChanged: {
                if (mainWindow.selectedTextItem === textRect) {
                    yPositionSlider.value = y
                }
            }

            // Container that rotates with the content
            Item {
                id: rotatingContainer
                anchors.fill: parent
                anchors.margins: 2 / mainWindow.zoomFactor
                rotation: textRect.textRotation

                // Selection border - fixed sizes, compensated for zoom
                Rectangle {
                    anchors.fill: parent
                    color: textRect.selected ? Colors.accentColorDimmed : "transparent"
                    border.width: textRect.selected ? 2 / mainWindow.zoomFactor : 0
                    border.color: Colors.accentColor
                    radius: Material.ExtraSmallScale / mainWindow.zoomFactor
                }

                Text {
                    id: textEdit
                    anchors.fill: parent
                    anchors.margins: 10
                    text: "Sample Text"
                    font.family: "Arial"
                    font.pixelSize: 24
                    color: Colors.placeholderColor
                    //selectByMouse: false
                    wrapMode: TextEdit.Wrap
                }

                // Main mouse area for dragging and selection
                MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: 8 / mainWindow.zoomFactor
                    anchors.bottomMargin: 8 / mainWindow.zoomFactor
                    anchors.topMargin: 15 / mainWindow.zoomFactor // Leave space for rotation handle
                    drag.target: textRect
                    drag.minimumX: 0
                    drag.maximumX: scaledContent.width - textRect.width
                    drag.minimumY: 0
                    drag.maximumY: scaledContent.height - textRect.height

                    onPressed: {
                        imageFlickable.allowDrag = false
                        mainWindow.selectItem(textRect)
                    }

                    onReleased: {
                        imageFlickable.allowDrag = true
                    }

                    onDoubleClicked: {
                        textEdit.focus = true
                    }
                }

                // Rotation handle - fixed size compensated for zoom
                MouseArea {
                    id: rotationHandle
                    width: 12 / mainWindow.zoomFactor
                    height: 12 / mainWindow.zoomFactor
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: -6 / mainWindow.zoomFactor
                    visible: textRect.selected
                    cursorShape: Qt.OpenHandCursor

                    property real centerX
                    property real centerY
                    property real startAngle

                    onPressed: {
                        imageFlickable.allowDrag = false
                        centerX = textRect.width/2
                        centerY = textRect.height/2

                        var localMouse = mapToItem(textRect, mouseX, mouseY)
                        startAngle = Math.atan2(localMouse.y - centerY, localMouse.x - centerX) * 180 / Math.PI - textRect.textRotation

                        cursorShape = Qt.ClosedHandCursor
                    }

                    onReleased: {
                        imageFlickable.allowDrag = true
                        cursorShape = Qt.OpenHandCursor
                    }

                    onPositionChanged: {
                        if (pressed) {
                            var localMouse = mapToItem(textRect, mouseX, mouseY)
                            var currentAngle = Math.atan2(localMouse.y - centerY, localMouse.x - centerX) * 180 / Math.PI

                            textRect.textRotation = currentAngle - startAngle
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Colors.accentColor
                        border.color: "#ffffff"
                        border.width: 1 / mainWindow.zoomFactor
                    }
                }

                // Resize handle - fixed size compensated for zoom
                MouseArea {
                    id: resizeHandle
                    width: 10 / mainWindow.zoomFactor
                    height: 10 / mainWindow.zoomFactor
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    visible: textRect.selected
                    cursorShape: Qt.SizeFDiagCursor

                    property real lastMouseX
                    property real lastMouseY

                    onPressed: {
                        imageFlickable.allowDrag = false
                        lastMouseX = mouseX
                        lastMouseY = mouseY
                    }

                    onReleased: {
                        imageFlickable.allowDrag = true
                    }

                    onPositionChanged: {
                        if (pressed) {
                            var deltaX = mouseX - lastMouseX
                            var deltaY = mouseY - lastMouseY

                            var newWidth = Math.max(100, textRect.width + deltaX)
                            var newHeight = Math.max(40, textRect.height + deltaY)

                            // Check bounds - prevent resizing beyond the scaledContent boundaries
                            if (textRect.x + newWidth <= scaledContent.width) {
                                textRect.width = newWidth
                            }

                            if (textRect.y + newHeight <= scaledContent.height) {
                                textRect.height = newHeight
                            }

                            lastMouseX = mouseX
                            lastMouseY = mouseY
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Colors.accentColor
                        bottomRightRadius: Material.ExtraSmallScale / mainWindow.zoomFactor
                    }
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

            // Update position sliders when item position changes
            onXChanged: {
                if (mainWindow.selectedTextItem === imageRect) {
                    imgXPositionSlider.value = x
                }
            }

            onYChanged: {
                if (mainWindow.selectedTextItem === imageRect) {
                    imgYPositionSlider.value = y
                }
            }

            // Container that rotates with the content
            Item {
                id: rotatingContainer
                anchors.fill: parent
                anchors.margins: 2 / mainWindow.zoomFactor
                rotation: imageRect.imageRotation

                // Selection border - fixed size compensated for zoom
                Rectangle {
                    anchors.centerIn: parent
                    width: layerImage.paintedWidth + 4 / mainWindow.zoomFactor
                    height: layerImage.paintedHeight + 4 / mainWindow.zoomFactor
                    color: imageRect.selected ? Colors.accentColorDimmed : "transparent"
                    border.width: imageRect.selected ? 2 / mainWindow.zoomFactor : 0
                    border.color: Colors.accentColor
                    radius: Material.ExtraSmallScale / mainWindow.zoomFactor
                }

                Image {
                    id: layerImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    anchors.margins: 2 / mainWindow.zoomFactor
                }

                // Main mouse area for dragging and selection
                MouseArea {
                    anchors.centerIn: parent
                    width: layerImage.paintedWidth
                    height: layerImage.paintedHeight
                    anchors.rightMargin: 8 / mainWindow.zoomFactor
                    anchors.bottomMargin: 8 / mainWindow.zoomFactor
                    anchors.topMargin: 15 / mainWindow.zoomFactor
                    drag.target: imageRect
                    drag.minimumX: 0
                    drag.maximumX: scaledContent.width - imageRect.width
                    drag.minimumY: 0
                    drag.maximumY: scaledContent.height - imageRect.height

                    onPressed: {
                        imageFlickable.allowDrag = false
                        mainWindow.selectItem(imageRect)
                    }

                    onReleased: {
                        imageFlickable.allowDrag = true
                    }
                }

                // Rotation handle - fixed size compensated for zoom
                MouseArea {
                    id: rotationHandle
                    width: 12 / mainWindow.zoomFactor
                    height: 12 / mainWindow.zoomFactor
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: (parent.height - layerImage.paintedHeight) / 2 - 6 / mainWindow.zoomFactor
                    visible: imageRect.selected
                    cursorShape: Qt.OpenHandCursor

                    property real centerX
                    property real centerY
                    property real startAngle

                    onPressed: {
                        imageFlickable.allowDrag = false
                        centerX = imageRect.width/2
                        centerY = imageRect.height/2

                        var localMouse = mapToItem(imageRect, mouseX, mouseY)
                        startAngle = Math.atan2(localMouse.y - centerY, localMouse.x - centerX) * 180 / Math.PI - imageRect.imageRotation

                        cursorShape = Qt.ClosedHandCursor
                    }

                    onReleased: {
                        imageFlickable.allowDrag = true
                        cursorShape = Qt.OpenHandCursor
                    }

                    onPositionChanged: {
                        if (pressed) {
                            var localMouse = mapToItem(imageRect, mouseX, mouseY)
                            var currentAngle = Math.atan2(localMouse.y - centerY, localMouse.x - centerX) * 180 / Math.PI

                            imageRect.imageRotation = currentAngle - startAngle
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Colors.accentColor
                        border.color: "#ffffff"
                        border.width: 1 / mainWindow.zoomFactor
                    }
                }

                // Resize handle - fixed size compensated for zoom
                MouseArea {
                    id: resizeHandle
                    width: 10 / mainWindow.zoomFactor
                    height: 10 / mainWindow.zoomFactor
                    x: parent.width / 2 + layerImage.paintedWidth / 2 + 2 / mainWindow.zoomFactor - width
                    y: parent.height / 2 + layerImage.paintedHeight / 2 + 2 / mainWindow.zoomFactor - height
                    visible: imageRect.selected
                    cursorShape: Qt.SizeFDiagCursor

                    property real lastMouseX
                    property real lastMouseY

                    onPressed: {
                        imageFlickable.allowDrag = false
                        lastMouseX = mouseX
                        lastMouseY = mouseY
                    }

                    onReleased: {
                        imageFlickable.allowDrag = true
                    }

                    onPositionChanged: {
                        if (pressed) {
                            var deltaX = mouseX - lastMouseX
                            var deltaY = mouseY - lastMouseY

                            var newWidth = Math.max(100, imageRect.width + deltaX)
                            var newHeight = Math.max(40, imageRect.height + deltaY)

                            // Check bounds - prevent resizing beyond the scaledContent boundaries
                            if (imageRect.x + newWidth <= scaledContent.width) {
                                imageRect.width = newWidth
                            }

                            if (imageRect.y + newHeight <= scaledContent.height) {
                                imageRect.height = newHeight
                            }

                            lastMouseX = mouseX
                            lastMouseY = mouseY
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Colors.accentColor
                        bottomRightRadius: Material.ExtraSmallScale / mainWindow.zoomFactor
                    }
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
            if (Qt.platform.os === "wasm") {
                preview = "Imported image"
            } else {
                var fileName = item.source.toString().split('/').pop()
                preview = fileName.length > 20 ? fileName.substring(0, 20) + "..." : fileName
            }
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
                    if (Qt.platform.os === "wasm") {
                        preview = "Imported image"
                    } else {
                        var fileName = item.source.toString().split('/').pop()
                        preview = fileName.length > 20 ? fileName.substring(0, 20) + "..." : fileName
                    }
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
        for (var j = 0; j < scaledContent.children.length; j++) {
            var child = scaledContent.children[j]
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
            underlineCheck.checked = selectedTextItem.fontUnderline
            strikeoutCheck.checked = selectedTextItem.fontStrikeout
            colorPicker.selectedColor = selectedTextItem.textColor

            // Update position sliders
            xPositionSlider.from = 0
            xPositionSlider.to = scaledContent.width - selectedTextItem.width
            xPositionSlider.value = selectedTextItem.x

            yPositionSlider.from = 0
            yPositionSlider.to = scaledContent.height - selectedTextItem.height
            yPositionSlider.value = selectedTextItem.y
        } else if (selectedTextItem && !selectedTextItem.hasOwnProperty('textContent')) {
            // Image item
            imgXPositionSlider.from = 0
            imgXPositionSlider.to = scaledContent.width - selectedTextItem.width
            imgXPositionSlider.value = selectedTextItem.x

            imgYPositionSlider.from = 0
            imgYPositionSlider.to = scaledContent.height - selectedTextItem.height
            imgYPositionSlider.value = selectedTextItem.y
        } else {
            // Clear controls when nothing is selected
            textContent.text = ""
            fontFamily.currentIndex = -1
            fontSize.value = 24
            boldCheck.checked = false
            italicCheck.checked = false
            underlineCheck.checked = false
            strikeoutCheck.checked = false
            colorPicker.selectedColor = Colors.placeholderColor
        }
    }
}
