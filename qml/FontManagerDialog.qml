import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import Odizinne.QuickEdits

Dialog {
    id: fontManagerDialog
    title: "Font Manager"
    modal: true
    width: 450
    height: 500
    anchors.centerIn: parent
    Material.roundedScale: Material.ExtraSmallScale
    Material.background: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"

    standardButtons: Dialog.Close

    ColumnLayout {
        anchors.fill: parent
        spacing: 15

        Label {
            text: "Custom Fonts"
            font.pixelSize: 16
            font.bold: true
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true

            MaterialButton {
                text: "Import Font..."
                icon.source: "qrc:/icons/file.svg"
                icon.width: 16
                icon.height: 16
                Layout.preferredWidth: implicitWidth + 20
                onClicked: {
                    if (Qt.platform.os === "wasm") {
                        FontManager.openFontDialog()
                    } else {
                        fontFileDialog.open()
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Label {
                text: fontListView.count + " custom fonts"
                opacity: 0.7
                font.pixelSize: 12
            }
        }

        ScrollView {
            id: fontScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            property bool sbVisible: ScrollBar.vertical.policy === ScrollBar.AlwaysOn
            ScrollBar.vertical.policy: fontListView.contentHeight > height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff

            ListView {
                id: fontListView
                model: FontManager.customFontFamilies
                spacing: 8
                width: fontScrollView.sbVisible ? fontScrollView.width - 20 : fontScrollView.width

                delegate: Rectangle {
                    id: fontItem
                    width: fontListView.width
                    height: 80
                    color: "transparent"
                    border.color: UserSettings.darkMode ? "#444444" : "#CCCCCC"
                    border.width: 1
                    radius: Material.ExtraSmallScale

                    required property string modelData
                    required property int index

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 15

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            Label {
                                text: fontItem.modelData
                                font.family: fontItem.modelData
                                font.pixelSize: 16
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                color: UserSettings.darkMode ? "#FFFFFF" : "#000000"
                            }

                            Label {
                                text: "The quick brown fox jumps over the lazy dog"
                                font.family: fontItem.modelData
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                opacity: 0.8
                                color: UserSettings.darkMode ? "#CCCCCC" : "#333333"
                            }
                        }

                        MaterialButton {
                            text: "Remove"
                            Layout.preferredWidth: 80
                            Material.accent: Material.Red
                            onClicked: {
                                removeConfirmDialog.fontToRemove = fontItem.modelData
                                removeConfirmDialog.open()
                            }
                        }
                    }
                }

                // Empty state
                Label {
                    anchors.centerIn: parent
                    text: "No custom fonts imported\nClick 'Import Font...' to add fonts"
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.5
                    visible: fontListView.count === 0
                    color: UserSettings.darkMode ? "#CCCCCC" : "#666666"
                }
            }
        }

        MenuSeparator {
            Layout.fillWidth: true
        }

        Label {
            text: "Supported formats: TTF, OTF, WOFF, WOFF2"
            font.pixelSize: 11
            opacity: 0.6
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: UserSettings.darkMode ? "#CCCCCC" : "#666666"
        }
    }

    // Confirmation dialog for font removal
    Dialog {
        id: removeConfirmDialog
        title: "Remove Font"
        modal: true
        anchors.centerIn: parent
        Material.roundedScale: Material.ExtraSmallScale
        Material.background: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"

        property string fontToRemove: ""

        standardButtons: Dialog.Yes | Dialog.No

        Label {
            text: "Are you sure you want to remove the font '" + removeConfirmDialog.fontToRemove + "'?\n\nThis action cannot be undone."
            wrapMode: Text.WordWrap
            color: UserSettings.darkMode ? "#FFFFFF" : "#000000"
        }

        onAccepted: {
            FontManager.removeCustomFont(fontToRemove)
        }
    }

    // File dialog for desktop platforms
    FileDialog {
        id: fontFileDialog
        title: "Select a font file"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Font files (*.ttf *.otf *.woff *.woff2)", "All files (*)"]

        onAccepted: {
            FontManager.loadCustomFontFromFile(selectedFile)
        }
    }

    Connections {
        target: FontManager

        function onFontLoaded(fontFamily) {
            console.log("Font loaded:", fontFamily)
            // Could add a toast notification here
        }

        function onFontRemoved(fontFamily) {
            console.log("Font removed:", fontFamily)
            // Could add a toast notification here
        }
    }
}
