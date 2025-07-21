import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick
import Odizinne.QuickEdits

Dialog {
    id: downloadPopup
    modal: true
    visible: false
    width: 350
    height: implicitHeight + 30
    Material.background: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"
    Material.roundedScale: Material.SmallScale
    focus: true
    standardButtons: Dialog.Close

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 20

        Label {
            text: qsTr("Download Desktop App")
            Layout.fillWidth: true
            font.bold: true
            font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter
            color: UserSettings.darkMode ? "#FFFFFF" : "#000000"
        }

        Label {
            text: qsTr("Get the full desktop experience with native performance.")
            Layout.fillWidth: true
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: UserSettings.darkMode ? "#CCCCCC" : "#333333"
            lineHeight: 1.2
        }

        RowLayout {
            id: btnLyt
            Layout.fillWidth: true
            spacing: 10
            Layout.alignment: Qt.AlignHCenter
            property int buttonWidth: Math.max(winBtn.implicitWidth, linBtn.implicitWidth) + 20

            ColumnLayout {
                spacing: 15

                Image {
                    source: "qrc:/icons/windows.svg"
                    sourceSize.height: 64
                    sourceSize.width: 64
                    Layout.alignment: Qt.AlignHCenter
                }

                MaterialButton {
                    id: winBtn
                    text: qsTr("Windows")
                    Layout.preferredWidth: btnLyt.buttonWidth
                    onClicked: {
                        Qt.openUrlExternally("https://github.com/odizinne/QuickEdits/releases/latest/download/QuickEdits_win64_msvc2022.zip")
                        downloadPopup.close()
                    }
                }
            }

            ToolSeparator { Layout.fillHeight: true }

            ColumnLayout {
                spacing: 15
                Image {
                    source: "qrc:/icons/linux.svg"
                    sourceSize.height: 64
                    sourceSize.width: 64
                    Layout.alignment: Qt.AlignHCenter
                }

                MaterialButton {
                    id: linBtn
                    text: qsTr("Linux")
                    Layout.preferredWidth: btnLyt.buttonWidth
                    onClicked: {
                        Qt.openUrlExternally("https://github.com/odizinne/QuickEdits/releases/latest/download/QuickEdits_linux64_gcc.zip")
                        downloadPopup.close()
                    }
                }
            }
        }
    }
}
