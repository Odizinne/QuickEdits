pragma Singleton
import QtQuick
import Odizinne.QuickEdits

QtObject {
    id: root

    readonly property color accentColor: isDarkTheme ? "#F48FB1" : "#D81B60"
    readonly property color accentColorDimmed: isDarkTheme ? "#40F48FB1" : "#40D81B60"

    readonly property bool isDarkTheme: UserSettings.darkMode
    readonly property color primaryColor: isDarkTheme ? "#BB86FC" : "#6200EE"
    readonly property color backgroundColor: isDarkTheme ? "#1C1C1C" : "#E3E3E3"
    readonly property color handleColor: !isDarkTheme ? "#1C1C1C" : "#E3E3E3"
    readonly property color paneColor: isDarkTheme ? "#2B2B2B" : "#FFFFFF"
}
