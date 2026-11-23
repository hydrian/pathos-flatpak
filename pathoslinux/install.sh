#!/usr/bin/env bash
set -euo pipefail

PACKAGE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PATHOS_INSTALLER="$PACKAGE_DIR/payload/Pathos-installer.exe"
DOTNET_VERSION=10.0.5
DOTNET_FILE="windowsdesktop-runtime-${DOTNET_VERSION}-win-x64.exe"
DOTNET_URL="https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/${DOTNET_VERSION}/${DOTNET_FILE}"
DOTNET_SHA512="cbb1ad53aecc54264488cc5c0be938991770750209cf4acd383bbe8af57db679f4d5988e6281a6d6a46b4e141db3d3d539ea764250b4ab48871972a610944b40"
WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
export WINEPREFIX

if [[ $EUID -eq 0 ]]; then
  echo "Run this installer as your normal user, not as root." >&2
  exit 1
fi

missing_tools=()
for tool in wine wineboot winetricks sha512sum python3 wget cabextract; do
  command -v "$tool" >/dev/null 2>&1 || missing_tools+=("$tool")
done

if ((${#missing_tools[@]})); then
  printf 'Missing host tools: %s\n' "${missing_tools[*]}"
  read -r -p 'Install Wine, Winetricks, and the required helper tools now? [y/N] ' answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Install the missing tools and rerun this installer." >&2
    exit 1
  fi
  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required to install host packages." >&2
    exit 1
  fi
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y wine winetricks wget cabextract curl python3 coreutils desktop-file-utils xdg-utils
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y wine winetricks wget cabextract curl python3 coreutils desktop-file-utils xdg-utils
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --needed wine winetricks wget cabextract curl python coreutils desktop-file-utils xdg-utils
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper --non-interactive install wine winetricks wget cabextract curl python3 coreutils desktop-file-utils xdg-utils
  else
    echo "No supported package manager found (apt, dnf, pacman, zypper). Install the missing tools manually." >&2
    exit 1
  fi

  for tool in wine wineboot winetricks sha512sum python3 wget cabextract; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      echo "Required command still missing after package installation: $tool" >&2
      exit 1
    fi
  done
fi
if [[ ! -f "$PATHOS_INSTALLER" ]]; then
  echo "Pathos installer is missing: $PATHOS_INSTALLER" >&2
  exit 1
fi

mkdir -p "$WINEPREFIX/drive_c/windows/temp"
echo "Initializing Wine prefix at $WINEPREFIX"
wineboot -u

installed_verbs="$(winetricks list-installed 2>/dev/null || true)"
missing_verbs=()
for verb in corefonts renderer=gdi win10; do
  if grep -Fxq -- "$verb" <<<"$installed_verbs"; then
    printf 'Already configured: %s\n' "$verb"
  else
    missing_verbs+=("$verb")
  fi
done
if ((${#missing_verbs[@]})); then
  printf 'Configuring Wine components: %s\n' "${missing_verbs[*]}"
  winetricks --unattended "${missing_verbs[@]}"
fi

IE8_LOG="$WINEPREFIX/drive_c/windows/ie8_main.log"
IE8_EXE="$WINEPREFIX/drive_c/Program Files (x86)/Internet Explorer/iexplore.exe"
IE8_HTML="$WINEPREFIX/drive_c/windows/system32/mshtml.dll"
if [[ -f "$IE8_LOG" && -f "$IE8_EXE" && -s "$IE8_HTML" ]] \
  && grep -Fq 'Installer return value: hr=0x00000000' "$IE8_LOG" \
  && grep -Fq 'Setup exit code: 0x00000000.' "$IE8_LOG"; then
  echo "Internet Explorer 8 is already installed."
else
  echo "Installing Internet Explorer 8 with Winetricks"
  if ! winetricks --unattended ie8; then
    # IE8 requests a reboot; Wine cannot complete the native reboot, so Winetricks
    # can return nonzero even when Microsoft's setup log records success.
    if [[ ! -f "$IE8_LOG" || ! -f "$IE8_EXE" || ! -s "$IE8_HTML" ]] \
      || ! grep -Fq 'Installer return value: hr=0x00000000' "$IE8_LOG" \
      || ! grep -Fq 'Setup exit code: 0x00000000.' "$IE8_LOG"; then
      echo "Winetricks reported failure and IE8 setup did not record a successful installation." >&2
      exit 1
    fi
    echo "IE8 setup completed successfully; Winetricks returned nonzero for Wine's unsupported reboot."
  fi
fi

# The ie8 verb temporarily selects Windows Server 2003 while running setup.
# Reapply Windows 10 so later installers and the game see the intended version.
winetricks --unattended win10

DOTNET_PATH="$WINEPREFIX/drive_c/windows/temp/$DOTNET_FILE"
if [[ ! -d "$WINEPREFIX/drive_c/Program Files/dotnet/shared/Microsoft.WindowsDesktop.App/$DOTNET_VERSION" ]]; then
  if [[ ! -f "$DOTNET_PATH" ]] || ! printf '%s  %s\n' "$DOTNET_SHA512" "$DOTNET_PATH" | sha512sum --check --status; then
    rm -f "$DOTNET_PATH"
    echo "Downloading the .NET $DOTNET_VERSION Windows Desktop Runtime"
    if command -v curl >/dev/null 2>&1; then
      curl --fail --location --output "$DOTNET_PATH" "$DOTNET_URL"
    elif command -v wget >/dev/null 2>&1; then
      wget --output-document="$DOTNET_PATH" "$DOTNET_URL"
    else
      echo "Install curl or wget to download the .NET Desktop Runtime." >&2
      exit 1
    fi
  fi
  printf '%s  %s\n' "$DOTNET_SHA512" "$DOTNET_PATH" | sha512sum --check
  wine "$DOTNET_PATH" /quiet
fi

# Install into the same C:\Games\Pathos location used by this package.
GAME="$WINEPREFIX/drive_c/Games/Pathos/PathosGame.exe"
if [[ -f "$GAME" ]]; then
  echo "Pathos is already installed at $GAME; keeping the existing game files and saves."
else
  wine "$PATHOS_INSTALLER" /silent '/dir=C:\Games\Pathos' /LOG /DoNotLaunchGame
  if [[ ! -f "$GAME" ]]; then
    echo "The Pathos installer finished, but PathosGame.exe was not found at $GAME" >&2
    exit 1
  fi
fi

LOCAL_BIN="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$LOCAL_BIN" "$APP_DIR" "$ICON_DIR"
python3 - "$LOCAL_BIN/pathoslinux-launch" "$WINEPREFIX" <<'PY'
import shlex
import sys
from pathlib import Path

prefix = shlex.quote(sys.argv[2])
launcher = f'''#!/usr/bin/env bash
set -euo pipefail
WINEPREFIX="${{WINEPREFIX:-{prefix}}}"
GAME="$WINEPREFIX/drive_c/Games/Pathos/PathosGame.exe"
if [[ ! -f "$GAME" ]]; then
  echo "Pathos was not found at $GAME" >&2
  exit 1
fi
exec env WINEPREFIX="$WINEPREFIX" wine "$GAME" windowed-mode
'''
Path(sys.argv[1]).write_text(launcher, encoding='utf-8')
PY
chmod 755 "$LOCAL_BIN/pathoslinux-launch"
cp "$PACKAGE_DIR/assets/pathos.svg" "$ICON_DIR/pathoslinux.svg"

python3 - "$APP_DIR/pathoslinux.desktop" "$LOCAL_BIN/pathoslinux-launch" <<'PY'
import sys
from pathlib import Path

def quote_exec_arg(value):
    return '"' + value.replace('\\', '\\\\').replace('"', '\\"').replace('`', '\\`').replace('$', '\\$') + '"'

entry = (
    '[Desktop Entry]\n'
    'Version=1.0\n'
    'Type=Application\n'
    'Name=Pathos\n'
    'Comment=Play Pathos with Wine\n'
    f'Exec={quote_exec_arg(sys.argv[2])}\n'
    'Icon=pathoslinux\n'
    'Terminal=false\n'
    'StartupNotify=true\n'
    'Categories=Game;RolePlaying;\n'
)
Path(sys.argv[1]).write_text(entry, encoding='utf-8')
PY
chmod 644 "$APP_DIR/pathoslinux.desktop"
if command -v xdg-user-dir >/dev/null 2>&1; then
  DESKTOP_DIR="$(xdg-user-dir DESKTOP)"
  if [[ -n "$DESKTOP_DIR" && -d "$DESKTOP_DIR" ]]; then
    cp "$APP_DIR/pathoslinux.desktop" "$DESKTOP_DIR/Pathos.desktop"
    chmod 755 "$DESKTOP_DIR/Pathos.desktop"
  fi
fi

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$APP_DIR/pathoslinux.desktop"
fi
printf '\nPathos is installed. Find it in the Games menu or run: %s\n' "$LOCAL_BIN/pathoslinux-launch"
printf 'The Wine prefix is %s. IE8 was installed by Winetricks for the game browser panel.\n' "$WINEPREFIX"
