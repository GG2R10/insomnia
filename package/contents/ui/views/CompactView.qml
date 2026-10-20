import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami
import "../anim" as Anim

// Compact panel representation: a can (contents/icons/can.svg) with an empty
// bolt-shaped cutout in the middle, and the bolt itself (energy.svg) as a
// second layer rendered directly on top. Both share the same 1024x1024
// viewBox and were drawn to align at identical size/position, so no manual
// offset is needed - just stack them. The bolt is invisible at rest (the can
// reads as "empty") and fades/pulses in the moment the widget is active -
// either a flat color or, in rainbow mode, a hue-cycling gradient.
Item {
    id: compact

    implicitWidth: Kirigami.Units.gridUnit * 1.8
    implicitHeight: Kirigami.Units.gridUnit * 1.8

    // Set by main.qml.
    property bool active: false
    property bool sleepActive: false
    property bool idleActive: false
    property bool rainbowMode: false
    // 0 = static (one short transition on activation), 1 = continuous.
    property int animationMode: 0
    property int animationFps: 2
    property int hoverStyle: 0

    readonly property color boltColor: "#88ff00"

    // Animation policy: static by default, continuous opt-in and fps-capped
    // (see anim/README.md). Nothing runs at rest.
    Anim.AnimationController {
        id: anim
        active: compact.active
        mode: compact.animationMode
        fpsIndex: compact.animationFps
        transitionDuration: 1200
    }

    // Rainbow hue shift, as HueSaturation.hue (-1..1 maps to -180..180 deg,
    // so one full turn is 0..2 wrapped). Continuous mode loops every 4 s;
    // static mode sweeps one full turn on activation, then parks at 0.
    // Quantized to 1/48 turn (12 changes/s at a 4 s loop): finer steps are
    // invisible on a ~30px icon and each change costs a shader pass.
    readonly property real hueTurn: anim.continuous
        ? anim.turns(4000)
        : (anim.transitioning ? anim.easeOut(anim.transitionProgress) : 0)
    readonly property real hueShift: {
        const h = Math.floor(hueTurn * 48) / 48 * 2
        return h > 1 ? h - 2 : h
    }

    // Local hover / press state.
    property bool hovered: false
    property bool pressed: false

    // Emitted per mouse button - main.qml resolves each to a configured
    // target (Sleep/Screen/Both/None) and decides what to toggle. Right
    // click is deliberately NOT handled here: Plasma reserves it for the
    // applet's context menu (Configure/Remove/...), and accepting it in
    // this MouseArea would swallow that menu.
    signal leftClicked()
    signal middleClicked()

    // Hover/press pill + scale/tilt, driven by our own MouseArea below
    // (we need middle click, which HoverFeedback's built-in one ignores).
    Anim.HoverFeedback {
        id: fb
        anchors.fill: parent
        style: compact.hoverStyle
        useMouseArea: false
        hovered: compact.hovered
        pressed: compact.pressed
    }

    // Wraps both layers so hover/press affects the can+bolt as one unit.
    Item {
        id: artwork
        anchors.centerIn: parent
        // Same 10% inset per side as micdroid (80% of the slot).
        width: Math.min(compact.width, compact.height) * 0.7
        height: width

        scale: fb.scaleFactor
        rotation: fb.tilt
        transformOrigin: Item.Center

        // Base layer: the can, with its own baked-in shading (three grays) -
        // rendered as-is, not tinted, same reasoning as gamemode-status's
        // multicolor icons (isMask would flatten the highlight/shadow art).
        // Plain Image, not Kirigami.Icon: Icon snaps its render size to
        // discrete icon sizes (16/22/32...), so artwork.width changes between
        // those steps had no visible effect. Image renders at exact size.
        Image {
            id: canIcon
            anchors.fill: parent
            source: Qt.resolvedUrl("../../icons/can.svg")
            sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }

        // Overlay layer: the bolt that fills the can's empty cutout. Same
        // viewBox/size/position as canIcon by design, so it drops in aligned
        // with no offset math. Wraps both bolt render modes so the fade-in
        // and breathing animation apply identically regardless of which one
        // is showing.
        Item {
            id: boltLayer
            anchors.fill: parent
            opacity: compact.active ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            // Breathing as a reminder it's still holding a lock. Static mode:
            // a single pop when activated, then still. Continuous mode:
            // endless breathing at the configured fps. Time-based, so speed
            // is the same at any fps.
            scale: !compact.active ? 1.0
                : anim.continuous ? 0.92 + 0.14 * anim.wave(1800)
                : 1.0 + 0.14 * Math.sin(Math.PI * anim.transitionProgress)

            // Alpha mask for the bolt shape. A plain Kirigami.Icon with
            // isMask:true + an explicit `color` silently ignores that color
            // once hosted in a real Plasma panel (confirmed live - it stays
            // white, even though the same QML renders tinted correctly
            // standalone). Routing everything through GraphicalEffects'
            // LinearGradient-as-mask instead is what actually works in
            // Plasma, so it's used unconditionally now, even for the flat
            // "solid" look - which is just a gradient whose stops all match.
            Image {
                id: boltMaskSource
                anchors.fill: parent
                source: Qt.resolvedUrl("../../icons/energy.svg")
                sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }
            // The gradient has static stops and is only re-rendered when they change;
            // rainbow motion is only HueSaturation.hue, a single uniform, so
            // no gradient texture is regenerated per frame.
            LinearGradient {
                id: boltGradient
                anchors.fill: boltMaskSource
                source: boltMaskSource
                start: Qt.point(0, 0)
                end: Qt.point(width, height)
                gradient: Gradient {
                    GradientStop { position: 0/6; color: compact.rainbowMode ? Qt.hsva(0/6, 1, 1, 1) : compact.boltColor }
                    GradientStop { position: 1/6; color: compact.rainbowMode ? Qt.hsva(1/6, 1, 1, 1) : compact.boltColor }
                    GradientStop { position: 2/6; color: compact.rainbowMode ? Qt.hsva(2/6, 1, 1, 1) : compact.boltColor }
                    GradientStop { position: 3/6; color: compact.rainbowMode ? Qt.hsva(3/6, 1, 1, 1) : compact.boltColor }
                    GradientStop { position: 4/6; color: compact.rainbowMode ? Qt.hsva(4/6, 1, 1, 1) : compact.boltColor }
                    GradientStop { position: 5/6; color: compact.rainbowMode ? Qt.hsva(5/6, 1, 1, 1) : compact.boltColor }
                    GradientStop { position: 6/6; color: compact.rainbowMode ? Qt.hsva(6/6, 1, 1, 1) : compact.boltColor }
                }
            }
            HueSaturation {
                anchors.fill: boltGradient
                source: boltGradient
                hue: compact.rainbowMode ? compact.hueShift : 0
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onEntered: compact.hovered = true
        onExited: compact.hovered = false
        onPressed: compact.pressed = true
        onReleased: compact.pressed = false
        onCanceled: compact.pressed = false
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) compact.leftClicked()
            else if (mouse.button === Qt.MiddleButton) compact.middleClicked()
        }
    }
}
