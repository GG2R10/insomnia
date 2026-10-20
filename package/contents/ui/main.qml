import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import "views"

// Root applet: owns all state + logic. The UI lives in views/CompactView.qml,
// which receives state via properties and reports clicks back through
// signals. fullRepresentation (StatusPopup) exists mainly as a fallback/manual
// status view - CompactView's MouseArea consumes every click itself and never
// toggles Plasmoid.expanded, so the popup never auto-opens from a click.
PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    property bool sleepActive: false
    property bool idleActive: false
    readonly property bool active: root.sleepActive || root.idleActive

    toolTipMainText: !root.active
        ? i18n("Insomnia: inactive")
        : (root.sleepActive && root.idleActive
            ? i18n("Sleep and screen lock blocked")
            : (root.sleepActive ? i18n("Sleep blocked") : i18n("Screen lock blocked")))

    toolTipSubText: (root.active && Plasmoid.configuration.autoExpireMinutes > 0)
        ? i18n("Auto-releases after %1 min unless toggled off first", Plasmoid.configuration.autoExpireMinutes)
        : ""

    // Editor-agnostic path to the per-user runtime data file (must match
    // control.sh's BASE computation). Waits for the file to exist first:
    // `tail -F` launched before creation silently swallows appends, so
    // watching from creation guarantees every later transition is delivered.
    function dataFile() {
        return 'sh -c \'f="$XDG_RUNTIME_DIR/insomnia-$(id -u)/state.data"; ' +
            'n=0; while [ ! -e "$f" ] && [ $n -lt 100 ]; do sleep 0.05; n=$((n+1)); done; ' +
            'exec tail -n0 -F "$f" | { IFS= read -r line && echo "$line"; }\''
    }

    function codePath(file) {
        return Qt.resolvedUrl("../code/" + file).toString().replace(/^file:\/\//, "")
    }

    // ------------------------------------------------------------------
    // One-shot shell for control commands (start/stop/sync). Disconnected
    // after each command completes so the same source can run again.
    // ------------------------------------------------------------------
    Plasma5Support.DataSource {
        id: control
        engine: "executable"
        connectedSources: []
        function run(script) {
            control.connectSource(script)
        }
        onNewData: (source, data) => {
            control.disconnectSource(source)
        }
    }

    // ------------------------------------------------------------------
    // Status reader, armed as exactly ONE blocking one-shot at a time:
    //   armCurrent() : tail -n1  -> snapshot of the current combined state
    //   armStream()  : tail -F -n0 | read -> waits for the next appended
    //                   line (0% CPU while idle), then exits and re-arms.
    // Line format: "sleep:<on|off>|idle:<on|off>" - always a full snapshot,
    // never a delta, so a single line is enough to resync completely.
    // ------------------------------------------------------------------
    Plasma5Support.DataSource {
        id: status
        engine: "executable"

        function armCurrent() {
            Qt.callLater(function() {
                status.connectSource(
                    'sh -c \'tail -n1 "$XDG_RUNTIME_DIR/insomnia-$(id -u)/state.data" 2>/dev/null\'')
            })
        }

        function armStream() {
            // Defer so connecting from within onNewData can't execute the
            // new command synchronously and recurse into onNewData again.
            Qt.callLater(function() {
                status.connectSource(root.dataFile())
            })
        }

        onNewData: (source, data) => {
            const value = (data["stdout"] || "").trim()
            status.disconnectSource(source)
            if (value === "") {
                status.armStream()
                return
            }
            for (const part of value.split("|")) {
                const seg = part.split(":")
                if (seg.length !== 2) continue
                const on = seg[1] === "on"
                if (seg[0] === "sleep") root.sleepActive = on
                else if (seg[0] === "idle") root.idleActive = on
            }
            status.armStream()
        }
    }

    // ------------------------------------------------------------------
    // Click policy: resolve a click-target index (0=Sleep,1=Screen,2=Both,
    // 3=None, see config/main.xml) to the affected type(s), then toggle as a
    // group - fully on only when ALL of them are already active turns them
    // all off; otherwise turns on whichever of them isn't active yet (never
    // relaunches a holder that's already running).
    // ------------------------------------------------------------------
    function targetTypes(index) {
        switch (index) {
            case 0: return ["sleep"]
            case 1: return ["idle"]
            case 2: return ["sleep", "idle"]
            default: return []
        }
    }

    function isTypeActive(type) {
        return type === "sleep" ? root.sleepActive : root.idleActive
    }

    function handleClick(targetIndex) {
        const types = root.targetTypes(targetIndex)
        if (types.length === 0) {
            return // "None" - this button is deliberately inert
        }
        const minutes = Plasmoid.configuration.autoExpireMinutes
        const allActive = types.every(t => root.isTypeActive(t))
        for (const t of types) {
            if (allActive) {
                control.run(codePath("control.sh") + " stop " + t)
            } else if (!root.isTypeActive(t)) {
                control.run(codePath("control.sh") + " start " + t + " " + minutes)
            }
        }
    }

    // Idempotent bootstrap: publish the real current state (picks up an
    // inhibition still running from before a plasmashell crash/restart) and
    // arm the reactive reader. Deferred one tick so both DataSources exist.
    property bool bootstrapped: false
    function bootstrap() {
        if (root.bootstrapped) {
            return
        }
        root.bootstrapped = true
        control.run(codePath("control.sh") + " sync")
        status.armCurrent()
    }

    Timer {
        id: rootTimer
        interval: 0
        repeat: false
        onTriggered: root.bootstrap()
    }

    Component.onCompleted: rootTimer.start()

    compactRepresentation: CompactView {
        active: root.active
        sleepActive: root.sleepActive
        idleActive: root.idleActive
        rainbowMode: Plasmoid.configuration.rainbowMode
        animationMode: Plasmoid.configuration.animationMode
        animationFps: Plasmoid.configuration.animationFps
        hoverStyle: Plasmoid.configuration.hoverStyle
        onLeftClicked: root.handleClick(Plasmoid.configuration.leftClickTarget)
        onMiddleClicked: root.handleClick(Plasmoid.configuration.middleClickTarget)
        Component.onCompleted: root.bootstrap()
    }

    fullRepresentation: StatusPopup {
        sleepActive: root.sleepActive
        idleActive: root.idleActive
        onToggleSleep: root.handleClick(0)  // 0 = Sleep, see targetTypes()
        onToggleIdle: root.handleClick(1)   // 1 = Screen, see targetTypes()
    }
}
