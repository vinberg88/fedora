#!/usr/bin/env bash
# Fedora 44 KDE Plasma 6 / X410 installer, version 0.2.0
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
VERSION=0.2.0
[[ $EUID -ne 0 ]] || { echo 'Run kde6-x410 as your normal user, without sudo.'; exit 1; }
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/kde6-x410-fedora44"
umask 077
mkdir -p "$STATE"
[[ -O $STATE && -w $STATE ]] || { echo "Not owned/writable by your user: $STATE"; exit 1; }
LOG="$STATE/session.log"
SELF=$(readlink -f "$0")
fail() { echo "[ERROR] $*" >&2; exit 1; }
if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
  BLUE=$'\033[38;2;81;162;218m'; CYAN=$'\033[38;2;85;203;255m'
  GREEN=$'\033[38;2;91;224;144m'; YELLOW=$'\033[38;2;255;189;46m'
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
  BLUE=''; CYAN=''; GREEN=''; YELLOW=''; BOLD=''; DIM=''; RESET=''
fi
banner() {
  printf '\n%s╭──────────────────────────────────────────╮%s\n' "$BLUE" "$RESET"
  printf '%s│%s  %sFedora 44 · KDE Plasma 6 · X410%s         %s│%s\n' "$BLUE" "$RESET" "$BOLD" "$RESET" "$BLUE" "$RESET"
  printf '%s│%s  %sWSL Desktop Launcher v%-16s%s  %s│%s\n' "$BLUE" "$RESET" "$CYAN" "$VERSION" "$RESET" "$BLUE" "$RESET"
  printf '%s╰──────────────────────────────────────────╯%s\n\n' "$BLUE" "$RESET"
}
ok() { printf '%s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
note() { printf '%s›%s %s\n' "$CYAN" "$RESET" "$*"; }
warn() { printf '%s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
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
create_shortcut() {
  command -v powershell.exe >/dev/null || fail 'Windows PowerShell is unavailable. Check that WSL Windows interop is enabled.'
  command -v wslpath >/dev/null || fail 'wslpath is unavailable in this WSL installation.'
  [[ -n ${WSL_DISTRO_NAME:-} ]] || fail 'WSL_DISTRO_NAME is unavailable; run this command inside your Fedora WSL distribution.'
  command -v x410.exe >/dev/null || warn 'x410.exe was not found in the WSL PATH. Enable the X410 app execution alias in Windows if the shortcut cannot start X410.'
  local script windows_script
  script="$STATE/create-windows-shortcut.ps1"
  cat > "$script" <<'POWERSHELL'
param(
  [Parameter(Mandatory = $true)][string]$Distro,
  [string]$Name = 'Fedora 44 KDE Plasma 6'
)
$ErrorActionPreference = 'Stop'
$desktop = [Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory)
if (-not $desktop -or -not (Test-Path -LiteralPath $desktop)) {
  throw 'Windows Desktop folder could not be located.'
}
$wsl = Join-Path $env:WINDIR 'System32\wsl.exe'
if (-not (Test-Path -LiteralPath $wsl)) { throw 'wsl.exe could not be located.' }
$path = Join-Path $desktop ($Name + '.lnk')
if (Test-Path -LiteralPath $path) {
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $backup = Join-Path $desktop ($Name + '.backup-' + $stamp + '.lnk')
  Move-Item -LiteralPath $path -Destination $backup
  Write-Output ('Previous shortcut backed up: ' + $backup)
}
$safeDistro = $Distro.Replace('"', '')
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($path)
$shortcut.TargetPath = $wsl
$shortcut.Arguments = '-d "' + $safeDistro + '" -- bash -lc "x410.exe /desktop >/dev/null 2>&1 & sleep 2; kde6-x410 start"'
$shortcut.WorkingDirectory = $env:USERPROFILE
$shortcut.IconLocation = $wsl + ',0'
$shortcut.Description = 'Start Fedora 44 KDE Plasma 6 in X410 through WSL 2'
$shortcut.WindowStyle = 7
$shortcut.Save()
Write-Output ('Shortcut created: ' + $path)
POWERSHELL
  chmod 600 "$script"
  windows_script=$(wslpath -w "$script")
  powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$windows_script" -Distro "$WSL_DISTRO_NAME" | tr -d '\r'
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
    banner
    . /etc/os-release
    note "Distribution  $PRETTY_NAME"
    note "User          $(id -un) (UID $UID)"
    note "PID 1         $(ps -p 1 -o comm=)"
    printf '\n%sDependency check%s\n' "$BOLD" "$RESET"
    missing=0
    for cmd in startplasma-x11 kwin_x11 plasmashell dbus-run-session xdpyinfo kwriteconfig6; do
      path=$(command -v "$cmd" || true)
      if [[ -n $path ]]; then ok "$cmd"; else warn "$cmd is missing"; missing=1; fi
    done
    printf '\n%sConnection check%s\n' "$BOLD" "$RESET"
    if choose_display; then ok "X410 is reachable on DISPLAY=$DISPLAY"; else warn 'X410 is not reachable — start X410 in Windows'; missing=1; fi
    if [[ -S /mnt/wslg/PulseServer ]]; then ok 'WSLg audio socket is available'; else warn 'WSLg audio socket is unavailable'; fi
    systemd_state=$(systemctl --user is-system-running 2>/dev/null || true)
    [[ -n $systemd_state ]] && note "User systemd  $systemd_state"
    if alive; then
      if components; then ok 'Plasma session is running'; else warn 'Plasma session is starting or incomplete'; missing=1; fi
    else note 'Plasma session is stopped'; fi
    printf '\n'
    if (( missing == 0 )); then ok 'READY — your desktop can start'; else warn 'NEEDS ATTENTION — check the messages above'; fi
    printf '%sLog: %s%s\n' "$DIM" "$LOG" "$RESET"
    exit "$missing"
    ;;
  start)
    banner
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
    ok "X410 responds on DISPLAY=$DISPLAY"
    note 'Starting a private KDE Plasma session…'
    nohup setsid "$SELF" _session > "$LOG" 2>&1 < /dev/null 9>&- &
    for (( i=0; i<30; i++ )); do
      if alive && components; then ok 'KDE Plasma 6 is running'; printf '%sLog: %s%s\n' "$DIM" "$LOG" "$RESET"; exit 0; fi
      sleep 1
    done
    warn 'KDE did not become ready within 30 seconds. Inspect doctor/log before retrying.'
    tail -n 60 "$LOG"
    exit 1
    ;;
  stop)
    banner
    exec 9>"$STATE/control.lock"
    flock -n 9 || fail 'Another start/stop is in progress.'
    if alive; then
      # Stop only processes in the session created by this launcher.
      pkill -TERM -u "$UID" -s "$PID" || true
      echo 'Stop requested. Run kde6-x410 doctor to check the result.'
    else echo 'No tracked session is running.'; fi
    ;;
  log) [[ -f $LOG ]] && tail -n 100 "$LOG" || echo 'No session log yet.' ;;
  shortcut)
    banner
    create_shortcut
    ok 'Double-click the new Windows Desktop shortcut to start X410 and KDE'
    ;;
  *) echo 'Usage: kde6-x410 {start|stop|doctor|log|shortcut}'; exit 2 ;;
esac
LAUNCHER
bash -n "$tmp"
if [[ -e /usr/local/bin/kde6-x410 ]]; then
  sudo cp -p /usr/local/bin/kde6-x410 "/usr/local/bin/kde6-x410.backup-$(date +%Y%m%d-%H%M%S)"
fi
sudo install -m 0755 "$tmp" /usr/local/bin/kde6-x410
printf '\nInstalled Fedora 44 KDE6 X410 0.2.0\nStart X410 in Windows using Desktop mode.\nThen, as your normal user:\n  kde6-x410 doctor\n  kde6-x410 start\n\nOptional one-click Windows launcher:\n  kde6-x410 shortcut\n\nThis launcher sets General/systemdBoot=false in your user startkderc\nto keep Plasma on its private X11 D-Bus session. Existing config is backed up on first start.\n'
