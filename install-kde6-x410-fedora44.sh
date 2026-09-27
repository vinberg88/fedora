#!/usr/bin/env bash
# Fedora 44 KDE Plasma 6 / X410 installer, version 0.1.0
set -euo pipefail
[[ $EUID -ne 0 ]] || { echo 'Run as your normal Linux user, without sudo. The installer requests sudo for packages.'; exit 1; }
. /etc/os-release
[[ ${ID:-} == fedora && ${VERSION_ID:-} == 44 ]] || { echo 'This installer is intended for Fedora 44.'; exit 1; }
grep -qi microsoft /proc/sys/kernel/osrelease || { echo 'This installer requires WSL.'; exit 1; }
sudo dnf install -y plasma-workspace-x11 kwin-x11 dbus-x11 xdpyinfo iproute util-linux procps-ng
command -v kwriteconfig6 >/dev/null || { echo 'Missing kwriteconfig6: install KDE Plasma first.'; exit 1; }
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cat > "$tmp" <<'LAUNCHER'
#!/usr/bin/env bash
set -euo pipefail
VERSION=0.1.0
[[ $EUID -ne 0 ]] || { echo 'Run kde6-x410 as your normal user, without sudo.'; exit 1; }
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/kde6-x410-fedora44"
umask 077
mkdir -p "$STATE"
[[ -O $STATE && -w $STATE ]] || { echo "Not owned/writable by your user: $STATE"; exit 1; }
LOG="$STATE/session.log"
SELF=$(readlink -f "$0")
fail() { echo "[ERROR] $*" >&2; exit 1; }
# A private session ID and process start time prevent unrelated processes being stopped.
alive() {
  [[ -r $STATE/session.pid ]] || return 1
  read -r PID STAMP < "$STATE/session.pid" || return 1
  [[ $PID =~ ^[0-9]+$ && $STAMP =~ ^[0-9]+$ && -r /proc/$PID/stat ]] || return 1
  [[ $(stat -c %u "/proc/$PID") == "$UID" ]] || return 1
  [[ $(awk '{print $22}' "/proc/$PID/stat") == "$STAMP" ]] || return 1
  [[ $(ps -o sid= -p "$PID" | tr -d ' ') == "$PID" ]]
}
probe() { timeout 3 xdpyinfo -display "$1" >/dev/null 2>&1; }
choose_display() {
  command -v xdpyinfo >/dev/null || return 1
  if [[ -n ${X410_DISPLAY:-} ]]; then
    DISPLAY=$X410_DISPLAY; export DISPLAY; probe "$DISPLAY"; return
  fi
  local host candidate
  host=$(ip -4 route show default | awk 'NR==1 {print $3}')
  for candidate in "${host:+$host:0.0}" 127.0.0.1:0.0; do
    [[ -n $candidate ]] || continue
    if probe "$candidate"; then DISPLAY=$candidate; export DISPLAY; return 0; fi
  done
  return 1
}
components() {
  pgrep -u "$UID" -s "$PID" -x kwin_x11 >/dev/null &&
  pgrep -u "$UID" -s "$PID" -x plasmashell >/dev/null
}
case "${1:-start}" in
  _session)
    printf '%s %s\n' "$$" "$(awk '{print $22}' /proc/$$/stat)" > "$STATE/session.pid"
    unset DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID WAYLAND_DISPLAY WAYLAND_SOCKET SESSION_MANAGER
    export XDG_SESSION_TYPE=x11 XDG_CURRENT_DESKTOP=KDE XDG_SESSION_DESKTOP=KDE
    export DESKTOP_SESSION=plasma KDE_FULL_SESSION=true KDE_SESSION_VERSION=6
    export QT_QPA_PLATFORM=xcb GDK_BACKEND=x11 SDL_VIDEODRIVER=x11
    export QT_AUTO_SCREEN_SCALE_FACTOR=0
    if [[ -S /mnt/wslg/PulseServer ]]; then export PULSE_SERVER=unix:/mnt/wslg/PulseServer; fi
    exec dbus-run-session -- startplasma-x11
    ;;
  doctor)
    printf '\n   Fedora 44 KDE6 X410 %s\n===============================================\n' "$VERSION"
    . /etc/os-release
    printf '%-24s %s\n' Distribution: "$PRETTY_NAME" User: "$(id -un) (UID $UID)" 'PID 1:' "$(ps -p 1 -o comm=)"
    missing=0
    for cmd in startplasma-x11 kwin_x11 plasmashell dbus-run-session xdpyinfo kwriteconfig6; do
      path=$(command -v "$cmd" || true)
      printf '%-24s %s\n' "$cmd:" "${path:-MISSING}"
      [[ -n $path ]] || missing=1
    done
    rpm -q plasma-workspace-x11 kwin-x11 || true
    if choose_display; then printf '%-24s %s\n' 'X410 DISPLAY:' "$DISPLAY" X410: reachable; else echo 'X410: NOT REACHABLE (start X410 in Windows)'; missing=1; fi
    if [[ -S /mnt/wslg/PulseServer ]]; then echo 'WSLg audio socket:       yes'; else echo 'WSLg audio socket:       no'; fi
    printf 'User systemd:            '; systemctl --user is-system-running 2>/dev/null || true
    if alive; then
      if components; then echo 'Plasma session:          RUNNING'; else echo 'Plasma session:          STARTING / INCOMPLETE'; missing=1; fi
    else echo 'Plasma session:          stopped'; fi
    if (( missing == 0 )); then echo 'Status:                  READY'; else echo 'Status:                  NEEDS ATTENTION'; fi
    echo "Log: $LOG"
    exit "$missing"
    ;;
  start)
    exec 9>"$STATE/control.lock"
    flock -n 9 || fail 'Another start/stop is in progress.'
    if alive; then echo 'Session already exists. Use kde6-x410 doctor or stop.'; exit 0; fi
    for cmd in startplasma-x11 kwin_x11 plasmashell dbus-run-session xdpyinfo kwriteconfig6; do command -v "$cmd" >/dev/null || fail "Missing $cmd; run the installer again."; done
    # Avoid attaching to KDE processes left over from an earlier manual launch.
    if pgrep -u "$UID" -x plasmashell >/dev/null || pgrep -u "$UID" -x kwin_x11 >/dev/null; then
      fail 'An existing KDE session was found. Log out of it first, or restart this WSL distribution from Windows.'
    fi
    choose_display || fail 'X410 is unreachable. Start X410, allow WSL access in X410/Windows Firewall, then retry. Override with X410_DISPLAY=HOST:0.0 kde6-x410 start'
    export XDG_RUNTIME_DIR="/run/user/$UID"
    [[ -d $XDG_RUNTIME_DIR && -O $XDG_RUNTIME_DIR && -w $XDG_RUNTIME_DIR ]] || fail 'User runtime directory is unavailable. Enable systemd in WSL and restart the distribution.'
    # Save the existing config once; classic startup keeps KDE on this private bus.
    cfg="${XDG_CONFIG_HOME:-$HOME/.config}/startkderc"
    mkdir -p "$(dirname "$cfg")"
    if [[ -f $cfg && ! -e $STATE/startkderc.before-x410 ]]; then cp -p "$cfg" "$STATE/startkderc.before-x410"; fi
    kwriteconfig6 --file startkderc --group General --key systemdBoot false
    [[ ! -f $LOG ]] || mv -f "$LOG" "$LOG.previous"
    rm -f "$STATE/session.pid"
    echo "[OK] X410 responds on DISPLAY=$DISPLAY"
    nohup setsid "$SELF" _session > "$LOG" 2>&1 < /dev/null 9>&- &
    for (( i=0; i<30; i++ )); do
      if alive && components; then echo '[OK] KDE Plasma 6 is running.'; echo "Log: $LOG"; exit 0; fi
      sleep 1
    done
    echo '[WARNING] KDE did not become ready within 30 seconds. Inspect doctor/log before retrying.'
    tail -n 60 "$LOG"
    exit 1
    ;;
  stop)
    exec 9>"$STATE/control.lock"
    flock -n 9 || fail 'Another start/stop is in progress.'
    if alive; then
      # Stop only processes in the session created by this launcher.
      pkill -TERM -u "$UID" -s "$PID" || true
      echo 'Stop requested. Run kde6-x410 doctor to check the result.'
    else echo 'No tracked session is running.'; fi
    ;;
  log) [[ -f $LOG ]] && tail -n 100 "$LOG" || echo 'No session log yet.' ;;
  *) echo 'Usage: kde6-x410 {start|stop|doctor|log}'; exit 2 ;;
esac
LAUNCHER
bash -n "$tmp"
if [[ -e /usr/local/bin/kde6-x410 ]]; then
  sudo cp -p /usr/local/bin/kde6-x410 "/usr/local/bin/kde6-x410.backup-$(date +%Y%m%d-%H%M%S)"
fi
sudo install -m 0755 "$tmp" /usr/local/bin/kde6-x410
printf '\nInstalled Fedora 44 KDE6 X410 0.1.0\nStart X410 in Windows using Desktop mode.\nThen, as your normal user:\n  kde6-x410 doctor\n  kde6-x410 start\n\nThis launcher sets General/systemdBoot=false in your user startkderc\nto keep Plasma on its private X11 D-Bus session. Existing config is backed up on first start.\n'
