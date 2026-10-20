import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../anim"

Kirigami.FormLayout {
    id: page

    property string title: i18n("Visuals/Performance")

    property alias cfg_animationMode: modeCombo.currentIndex
    property alias cfg_animationFps: fpsCombo.currentIndex
    property alias cfg_hoverStyle: hoverCombo.currentIndex
    readonly property int cfg_animationModeDefault: 0
    readonly property int cfg_animationFpsDefault: 2
    readonly property int cfg_hoverStyleDefault: 0

    // Owned by ConfigGeneral.qml; declared here only because Plasma requires
    // every cfg_* property on every config page.
    property int cfg_leftClickTarget
    property int cfg_middleClickTarget
    property int cfg_autoExpireMinutes
    property bool cfg_rainbowMode
    property int cfg_leftClickTargetDefault: 2
    property int cfg_middleClickTargetDefault: 3
    property int cfg_autoExpireMinutesDefault: 120
    property bool cfg_rainbowModeDefault: false

    QQC2.ComboBox {
        id: modeCombo
        Kirigami.FormData.label: i18n("Active animation:")
        model: AnimationOptions.modeLabels
    }
    QQC2.ComboBox {
        id: fpsCombo
        Kirigami.FormData.label: i18n("Frame rate:")
        model: AnimationOptions.fpsLabels
        enabled: modeCombo.currentIndex === 1
    }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Static plays one short animation when the widget turns on and then stays still, using no CPU/GPU. Continuous keeps the bolt breathing (and the rainbow cycling) and forces the panel to repaint every frame, so keep the frame rate low.")
        wrapMode: Text.WordWrap
        font.italic: true
    }

    Kirigami.Separator { Kirigami.FormData.isSection: true }

    QQC2.ComboBox {
        id: hoverCombo
        Kirigami.FormData.label: i18n("Hover effect:")
        model: AnimationOptions.hoverStyleLabels
    }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Brief feedback when hovering or pressing the icon. Nothing runs while idle.")
        wrapMode: Text.WordWrap
        font.italic: true
    }
}
