<p align="center">
  <img src="assets/icon.png" width="96" height="96" alt="Insomnia Plasmoid Icon">
  <h1 align="center">Insomnia, Plasmoid for KDE Plasma</h1>
</p>

<p align="center">
  A one-click panel toggle to block <b>sleep/hibernation</b> and/or <b>screen locking</b>, for a set time or indefinitely, without digging into System Settings' power management page.
</p>

---

## Features

* **Two independent blockers:** *Sleep* (suspend/hibernate) and *Screen lock* (dim/blank/lock) are tracked separately; any click or keybind can target either one, or both.
* **Configurable clicks:** pick what left and middle click toggle (Sleep / Screen lock / Both / None). Right click stays reserved for Plasma's context menu.
* **Safety auto-release:** inhibitions started from the widget turn themselves off after N minutes (default 120, `0` = never), so a forgotten toggle can't keep your PC awake forever.
* **Global keybind:** `toggle.sh` shares the widget's state, so a keyboard shortcut and the panel icon always stay in sync.
* **Rainbow mode:** optional hue-cycling bolt instead of the flat green one.

---

## How It Works & Efficiency

Instead of KDE's cookie-based `PolicyAgent.AddInhibition` (which releases itself the instant the calling D-Bus connection closes, so a one-shot script can't hold it open), each inhibition is a backgrounded `systemd-inhibit` process, and the widget is **100% event-driven**:

* **Two holders:** `--what=sleep` and `--what=idle` run as separate processes (`$XDG_RUNTIME_DIR/insomnia-<uid>/{sleep,idle}.pid`). Together they match the native "Manually block sleep and screen locking" checkbox.
* **Auto-release by systemd:** the holder's payload is a plain `sleep N` instead of `sleep infinity`; a detached `tail --pid` reaper (no polling loop) notices when it exits and republishes the state.
* **State lives in a file:** `control.sh` appends a full snapshot (`sleep:on|idle:off`) to `state.data` on every change, and every widget instance follows it with `tail -F`.
* **0% Idle CPU Usage:** readers block in the kernel and only wake when a line is appended. It also survives plasmashell restarts: the widget re-syncs from the pidfiles on startup.

---

## Visuals/Performance

Animations come from [plasma-anim-kit](https://github.com/GG2R10/plasma-anim-kit) (vendored in `package/contents/ui/anim/`) and are configurable under *Visuals/Performance* in the widget's settings:

* **Active animation:** *Static* (default) plays one short pop when the blocker turns on and then nothing runs, so the widget costs no CPU/GPU at rest. *Continuous* keeps the bolt breathing / rainbow cycling.
* **Frame rate** (continuous only): 12 / 24 / 30 / 60 fps or the display's native refresh rate.
* **Hover effect:** Pop, Soft, Lift, Wiggle or None.

Animations are skipped entirely when Plasma's animation speed is set to instant.

---

## Global Keybind

```bash
package/contents/code/toggle.sh [sleep|idle|both] [minutes]
```

Bind it in *System Settings → Shortcuts → Custom Shortcuts*. It reads and writes the same state as the widget, so the panel icon updates automatically. Target defaults to `both`, minutes to `0` (indefinite).

---

## Installation

### Option 1: Manual Installation from Repository

Clone the repository and copy the contents of the `package/` folder into your local Plasma applets directory:

```bash
mkdir -p ~/.local/share/plasma/plasmoids/com.github.GG2R10.insomnia/
cp -r package/* ~/.local/share/plasma/plasmoids/com.github.GG2R10.insomnia/
```

Then add it to a panel via *Add Widgets…*.

### Option 2: Install Local Package

1. Compress the contents of the `package/` directory into a `.zip` file (or rename it to `.plasmoid`).
2. Open *Add Widgets… → Get New Widgets… → Install from local file…*
3. Select your compressed archive.

> Note: you may need to restart plasmashell (`plasmashell --replace &`) for Plasma to detect the new widget.

### Development

`./dev.sh` installs or upgrades `package/` with `kpackagetool6`; add `-r` to restart plasmashell, `-v` to open it in `plasmoidviewer`, or `-u` to uninstall.

---

## Icon

Two-layer custom art in `package/contents/icons/`: `can.svg` (always visible, with an empty bolt-shaped cutout) and `energy.svg` (the bolt, stacked directly on top). Both share the same 1024x1024 viewBox so they align with no offset math. The bolt is invisible at rest and pops in when active; that's the whole "is it on" indicator.

---

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
