import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    // See micdroid's ConfigAudio.qml for why this plain `title` property is
    // needed (KCM page title binding quirk).
    property string title: i18n("General")

    // Index order must match main.qml's targetTypes() and config/main.xml.
    readonly property var targetLabels: [
        i18n("Sleep"),
        i18n("Screen lock"),
        i18n("Both (default)"),
        i18n("None")
    ]

    property alias cfg_leftClickTarget: leftCombo.currentIndex
    property alias cfg_middleClickTarget: middleCombo.currentIndex
    property alias cfg_autoExpireMinutes: expireSpin.value
    property alias cfg_rainbowMode: rainbowCheck.checked
    readonly property int cfg_leftClickTargetDefault: 2
    readonly property int cfg_middleClickTargetDefault: 3
    readonly property int cfg_autoExpireMinutesDefault: 120
    readonly property bool cfg_rainbowModeDefault: false

    // Owned by ConfigVisuals.qml; declared here only because Plasma requires
    // every cfg_* property on every config page.
    property int cfg_animationMode
    property int cfg_animationFps
    property int cfg_hoverStyle
    property int cfg_animationModeDefault: 0
    property int cfg_animationFpsDefault: 2
    property int cfg_hoverStyleDefault: 0

    QQC2.ComboBox {
        id: leftCombo
        Kirigami.FormData.label: i18n("Left click blocks:")
        model: page.targetLabels
    }

    QQC2.ComboBox {
        id: middleCombo
        Kirigami.FormData.label: i18n("Middle click blocks:")
        model: page.targetLabels
    }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Right click isn't configurable - Plasma reserves it for this widget's context menu (Configure, Remove, ...).")
        wrapMode: Text.WordWrap
        font.italic: true
    }

    Kirigami.Separator { Kirigami.FormData.isSection: true }

    RowLayout {
        Kirigami.FormData.label: i18n("Auto-release after:")
        spacing: Kirigami.Units.smallSpacing
        QQC2.SpinBox {
            id: expireSpin
            from: 0
            to: 1440
            stepSize: 5
            textFromValue: (value) => value === 0 ? i18n("Never") : i18n("%1 min", value)
            valueFromText: (text) => {
                const n = parseInt(text, 10)
                return isNaN(n) ? 0 : n
            }
        }
    }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Safety net: any inhibition started from this widget turns itself back off after this many minutes, even if you forget. 0 disables the timeout.")
        wrapMode: Text.WordWrap
        font.italic: true
    }

    Kirigami.Separator { Kirigami.FormData.isSection: true }

    QQC2.CheckBox {
        id: rainbowCheck
        Kirigami.FormData.label: i18n("Bolt color:")
        text: i18n("Rainbow mode")
    }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Cycles the bolt through the hue wheel while active, instead of a flat color.")
        wrapMode: Text.WordWrap
        font.italic: true
    }
}
