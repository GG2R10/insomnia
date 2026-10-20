import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Full representation: a simple status readout + per-type buttons, for when
// a click target is set to "None" on all three mouse buttons (or you just
// want to see/toggle sleep and screen lock independently without memorizing
// the click mapping). The panel icon itself never opens this automatically -
// CompactView's MouseArea handles every click directly.
Item {
    id: popup

    implicitWidth: Kirigami.Units.gridUnit * 14
    implicitHeight: Kirigami.Units.gridUnit * 8

    property bool sleepActive: false
    property bool idleActive: false

    signal toggleSleep()
    signal toggleIdle()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.gridUnit
        spacing: Kirigami.Units.largeSpacing

        PlasmaComponents.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            font.weight: Font.Bold
            text: i18n("Insomnia")
        }

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: i18n("Sleep")
            }
            PlasmaComponents.Label {
                text: popup.sleepActive ? i18n("Blocked") : i18n("Allowed")
                color: popup.sleepActive ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
            }
            PlasmaComponents.Button {
                text: popup.sleepActive ? i18n("Release") : i18n("Block")
                onClicked: popup.toggleSleep()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: i18n("Screen lock")
            }
            PlasmaComponents.Label {
                text: popup.idleActive ? i18n("Blocked") : i18n("Allowed")
                color: popup.idleActive ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
            }
            PlasmaComponents.Button {
                text: popup.idleActive ? i18n("Release") : i18n("Block")
                onClicked: popup.toggleIdle()
            }
        }

        Item { Layout.fillHeight: true }
    }
}
