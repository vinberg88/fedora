# Fedora WSL desktop roadmap

Nine Fedora desktop experiences are planned for this collection. Each desktop gets its own launcher, diagnostics, Windows shortcut, screenshot and guide before it is marked as tested.

> **Current focus:** KDE Plasma 6 is working. GNOME is next.

## Status legend

| Status | Meaning |
| :--- | :--- |
| ✅ Tested | Desktop startup has been confirmed on Fedora 44 in WSL 2 |
| 🚧 In progress | Installation and launcher work has started |
| 🔜 Next | Next desktop scheduled for implementation |
| 🗓️ Coming soon | Queued behind the current desktop |
| 🧪 Planned experiment | Package, display-server or session compatibility still needs research |

## Rollout order

### 1. KDE Plasma 6

**Status:** ✅ Tested

- [x] X410 desktop startup
- [x] `doctor`, `start`, `stop` and `log` commands
- [x] One-click Windows shortcut
- [x] Screenshot and animated demo
- [x] Fedora 44 guide

**[Open the KDE start guide](README.md#-start-kde-with-x410)**

### 2. GNOME

**Status:** 🔜 Next desktop

- [ ] Confirm Fedora 44 packages and session command
- [ ] Test the desktop through X410
- [ ] Build a safe GNOME launcher and diagnostics
- [ ] Add a Windows shortcut
- [ ] Add screenshots, animated demo and guide

### 3. XFCE

**Status:** 🗓️ Coming soon

- [ ] Confirm packages and session command
- [ ] Test X410 startup and shutdown
- [ ] Add launcher, shortcut, visuals and guide

### 4. Cinnamon

**Status:** 🗓️ Coming soon

- [ ] Confirm packages and session command
- [ ] Test X410 startup and shutdown
- [ ] Add launcher, shortcut, visuals and guide

### 5. Budgie

**Status:** 🗓️ Coming soon

- [ ] Confirm packages and session command
- [ ] Test X410 startup and shutdown
- [ ] Add launcher, shortcut, visuals and guide

### 6. MATE

**Status:** 🗓️ Coming soon

- [ ] Confirm packages and session command
- [ ] Test X410 startup and shutdown
- [ ] Add launcher, shortcut, visuals and guide

### 7. LXQt

**Status:** 🗓️ Coming soon

- [ ] Confirm packages and session command
- [ ] Test X410 startup and shutdown
- [ ] Add launcher, shortcut, visuals and guide

### 8. Deepin

**Status:** 🧪 Planned experiment

- [ ] Research current Fedora package availability
- [ ] Identify a compatible session and display path
- [ ] Test startup before publishing installation commands
- [ ] Add launcher, shortcut, visuals and guide if confirmed working

### 9. COSMIC

**Status:** 🧪 Planned experiment

- [ ] Research current Fedora package availability
- [ ] Evaluate display-server requirements under WSL
- [ ] Test startup before publishing installation commands
- [ ] Add launcher, shortcut, visuals and guide if confirmed working

## Definition of tested

A desktop moves to **✅ Tested** only after all of these checks pass:

1. The required packages install successfully on Fedora 44.
2. The desktop starts from a normal WSL user without running the launcher as root.
3. The launcher can detect missing dependencies and display problems.
4. Start and stop operations affect only the session created by the launcher.
5. The Windows shortcut starts the correct Fedora WSL distribution.
6. Audio, logs and repeat startup behavior are checked.
7. The README contains tested commands, a screenshot and an animated demo.

---

**KDE first. GNOME next. More Fedora desktops on the way.**
