<p align="center">
  <a href="https://github.com/vinberg88/fedora">
    <img src="https://github.com/user-attachments/assets/cb352c48-80e6-4223-8238-027f36bd013d" alt="Fedora Linux" width="1006" />
  </a>
</p>

<h1 align="center">Fedora Linux on WSL</h1>
<p align="center"><strong>Your Linux desktop. Your Windows workspace.</strong><br />Desktop setups, screenshots and practical guides by Mattias Vinberg.</p>

<p align="center">
  <img src="https://img.shields.io/badge/Windows_11-WSL_2-0078D4?style=flat-square" alt="Windows 11 with WSL 2" />
  <img src="https://img.shields.io/badge/Fedora_44-KDE_Plasma_6-51A2DA?style=flat-square" alt="Fedora 44 with KDE Plasma 6" />
  <img src="https://img.shields.io/badge/X410-X11_desktop-294172?style=flat-square" alt="X11 desktop through X410" />
  <img src="https://img.shields.io/badge/Desktop_collection-1_tested_%2B_8_coming-6C5CE7?style=flat-square" alt="One tested desktop and eight coming" />
</p>

<p align="center">
  <a href="#-kde-plasma-6--fedora-44">KDE desktop</a> ·
  <a href="#-start-kde-with-x410">Start guide</a> ·
  <a href="#-desktop-collection">Desktop collection</a> ·
  <a href="DESKTOPS.md">Roadmap</a> ·
  <a href="https://github.com/vinberg88">More WSL projects</a>
</p>

## 💙 Welcome to Fedora 39 to 45

Fedora is a community-developed Linux distribution sponsored by Red Hat, built around free and open-source software. This repository brings together my Fedora desktop experiments on **Windows 11 with WSL 2** — with screenshots, installation notes and scripts you can use in your own setup.

The collection is intended to cover **Fedora 39–45**, with each desktop documented as it is added. The working setup below is **Fedora 44 with KDE Plasma 6**; the version range does not mean every release has been tested or is still supported.

## 🖥️ KDE Plasma 6 and Fedora 44 for WSL

How to install KDE 6 via FEOORA 44 and WSL for WINDOWS 11.

<p align="center">
  <a href="https://github.com/vinberg88/fedora/blob/main/Fedora44-KDE6.txt">
    <img width="1920" height="1080" alt="Fedora44 and KDE6" src="https://github.com/user-attachments/assets/14f4c7d6-95ea-4865-9d81-c83963399f5e" />
  </a>
</p>

How to install KDE 6 via FEOORA 44 -  https://github.com/vinberg88/fedora/blob/main/Fedora44-KDE6.txt

Video is COMMING via YOUTUBE: COOMING SONE


<p align="center"><em>One command takes the setup from health check to a full KDE Plasma desktop.</em></p>

A full Plasma desktop with a familiar panel, application launcher and plenty of room to make it your own. The launcher directs the KDE session to **X410** and uses the **WSLg audio socket** when available.

| Component | Setup |
| :--- | :--- |
| Linux distribution | Fedora 44 in WSL 2 |
| Desktop | KDE Plasma 6, X11 session |
| Display server | X410 running in Windows |
| Audio connection | WSLg PulseAudio socket |
| Launcher | `kde6-x410` · version 0.2.0 |
| Desktop startup | Confirmed working on my setup |

**[View the installer](install-kde6-x410-fedora44.sh)** · **[Download the installer](https://raw.githubusercontent.com/vinberg88/fedora/main/install-kde6-x410-fedora44.sh)**

## 🚀 Start KDE with X410

This is the **desktop startup step** for an existing Fedora 44 WSL installation with KDE Plasma installed. It is not a Fedora image builder or a complete base-installation guide.

Before starting, have **systemd enabled in WSL**, log in as your normal Linux user with `sudo` access, and start **X410 in Windows using Desktop mode**. X410 must allow connections from your WSL instance. Log out of any KDE session you already started manually.

### 1. Download and install the launcher

Run inside Fedora 44:

```bash
curl -fL https://raw.githubusercontent.com/vinberg88/fedora/main/install-kde6-x410-fedora44.sh -o install-kde6-x410-fedora44.sh
bash install-kde6-x410-fedora44.sh
```

Run the script **without `sudo`**. It requests elevated privileges when installing the required packages and launcher.

### 2. Check and start

```bash
kde6-x410 doctor
kde6-x410 start
```

For a manual start, **start X410 first**. The Windows shortcut in the next step starts it for you.

### 3. Add a one-click Windows shortcut

After confirming that `kde6-x410 start` works, create a shortcut on your Windows Desktop:

```bash
kde6-x410 shortcut
```

The shortcut starts **X410 in Desktop mode**, waits briefly for it to become available and then starts KDE in the current Fedora WSL distribution. If a shortcut with the same name already exists, it is preserved as a timestamped backup.

The Microsoft Store version of X410 should have its `x410.exe` app execution alias enabled in Windows. Standalone X410 installations may need the alias or executable path configured separately.

| Command | Purpose |
| :--- | :--- |
| `kde6-x410 doctor` | Check packages, X410, the audio socket and session status |
| `kde6-x410 start` | Start KDE Plasma on X410 |
| `kde6-x410 stop` | Request shutdown of the session started by this launcher |
| `kde6-x410 log` | Show the latest session log |
| `kde6-x410 shortcut` | Create a one-click launcher on the Windows Desktop |

<details>
<summary><strong>Troubleshooting and configuration</strong></summary>

If X410 is not detected, check that it is running and that X410 access settings and Windows Firewall allow the WSL connection. To choose the display explicitly, substitute your Windows host address:

```bash
X410_DISPLAY=YOUR_WINDOWS_HOST_IP:0.0 kde6-x410 start
```

The launcher sets `General/systemdBoot=false` in your user's `startkderc` so Plasma uses its separate D-Bus session. An existing configuration is backed up on first start.

Logs and the configuration backup are stored under:

```text
~/.local/state/kde6-x410-fedora44/
```

If reporting a problem, include the output of `kde6-x410 doctor` and the relevant lines from `kde6-x410 log`.

If the Windows shortcut opens Fedora but cannot start X410, verify that `x410.exe` is available from a Windows terminal and that the X410 app execution alias is enabled.

</details>

## 🧩 Desktop collection

| Fedora | Desktop | Status | Guide |
| :--- | :--- | :--- | :--- |
| 44 | KDE Plasma 6 · X410 | ✅ Desktop startup tested | [Start guide](#-start-kde-with-x410) |
| 44 | GNOME · X410 | 🔜 Next desktop | [Roadmap](DESKTOPS.md#2-gnome) |
| 44 | XFCE · X410 | 🗓️ Coming soon | [Roadmap](DESKTOPS.md#3-xfce) |
| 44 | Cinnamon · X410 | 🗓️ Coming soon | [Roadmap](DESKTOPS.md#4-cinnamon) |
| 44 | Budgie · X410 | 🗓️ Coming soon | [Roadmap](DESKTOPS.md#5-budgie) |
| 44 | MATE · X410 | 🗓️ Coming soon | [Roadmap](DESKTOPS.md#6-mate) |
| 44 | LXQt · X410 | 🗓️ Coming soon | [Roadmap](DESKTOPS.md#7-lxqt) |
| 44 | Deepin · display testing pending | 🧪 Planned experiment | [Roadmap](DESKTOPS.md#8-deepin) |
| 44 | COSMIC · display testing pending | 🧪 Planned experiment | [Roadmap](DESKTOPS.md#9-cosmic) |

KDE is the working reference implementation. GNOME comes next, followed by XFCE, Cinnamon, Budgie, MATE, LXQt, Deepin and COSMIC. See the **[desktop roadmap](DESKTOPS.md)** for the rollout order and test checklist.

---

<p align="center">
  <strong>Fedora freedom. Windows convenience.</strong><br />
  Built and tested by <a href="https://github.com/vinberg88">Mattias Vinberg</a><br />
  <sub>Personal community project · Not an official Fedora or Red Hat project.</sub>
</p>
