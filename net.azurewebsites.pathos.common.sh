
WINEPREFIX='/var/data/wineprefix'
PATHOS_WIN_DIR='c:/Games/Pathos'
PATHOS_WINE_DIR="${WINEPREFIX}/drive_c/Games/Pathos"
PATHOS_WIN_EXE="${PATHOS_WIN_DIR}/PathosGame.exe"
PATHOS_WINE_EXE="${PATHOS_WINE_DIR}/PathosGame.exe"
PATHOSMAKER_WINE_EXE="${PATHOS_WINE_DIR}/PathosMaker.exe"
PATHOSMAKER_WIN_EXE="${PATHOS_WIN_DIR}/PathosMaker.exe"
function show_message {
  MSG="${1}"
  LEVEL="${2:-normal}"
  echo "### ${MSG} ###"
  NOTIFY_ID=$(notify-send --urgency="${LEVEL}" -i /app/share/icons/hicolor/scalable/apps/net.azurewebsites.pathos.svg  "${MSG}" -p 2>/dev/null)
  return 0
}

### Setting Wine Environment
function setup_wine {
  show_message "Setting up Windows (Wine) is being setup. This may take a while."
  echo "Setting-up wine prefix..."
  echo "WINEPREIX: ${WINEPREFIX}"
  WINEDLLOVERRIDES='mscoree=d;mshtml=d' /app/bin/wine64 wineboot
  if [ $? -eq 0 ] ; then 
    echo "Wineboot complete"
  else 
    show_message "Wineboot failed"
    return 3
  fi
  echo "Setting up WineTricks"
  winetricks --unattended 'corefonts' 'dotnet48' 'renderer=gdi'
  if [ $? -ne 0 ] ; then
    show_message "Winetricks failed to setup"
    return 4
  fi
  show_message "Windows (Wine) environment setup successfully" low
  return 0
}
#########################
### Installing Pathos ###
#########################
function install_pathos {
  show_message "Installing Pathos"
  test ! -d "${WINEPREFIX}" && mkdir -p "${WINEPREFIX}"
  WINE_ADVENTURES_DIR="${PATHOS_WINE_DIR}/Adventures"
  FLATPAK_ADVENTURES_DIR='/var/data/adventures'
  INSTALLER_FILE="/var/cache/PathosSetup.exe"
  echo "Downloading Pathos installer..."
  curl -L --progress-bar --output "${INSTALLER_FILE}" "https://www.dropbox.com/scl/fi/s4vrz7uixwltygqcltjcn/PathosSetup.exe?rlkey=0w7ar56sh8c5643gsbrmdrsj9&st=goqhhy2n&dl=1"
  echo "Running Pathos installer..."
  wine64 "${INSTALLER_FILE}" "/verysilent" "/dir=${PATHOS_WIN_DIR}" "/LOG" "/DoNotLaunchGame"
  if [ $? -eq 0 ] ; then
    show_message "Pathos installer successful" low
  else
    show_message "PathosSetup.exe installer failed"
    return 2
  fi

  test ! -d "${FLATPAK_ADVENTURES_DIR}" && mkdir -p "${FLATPAK_ADVENTURES_DIR}"
  if [ -e "${WINE_ADVENTURES_DIR}" ] ; then
    echo "Removing stock Adventures directory" 
    rm -Rf "${WINE_ADVENTURES_DIR}"
  fi
  FLATPAK_PERSIT_CONFIG_DIRS=(
    "Settings"
    "Profiles"
  )
  FLATPAK_PERSIST_DATA_DIRS=(
    "Quests"
    "Adventures"
    "Tracks"
    "Sonics"
  )
  ln -s "${FLATPAK_ADVENTURES_DIR}" "${WINE_ADVENTURES_DIR}"
  if [ $? -ne 0 ] ; then 
    echo "Failed to make symlink for adventures" 1>&2
    return 2
  fi
  return 0
}

#####################
### Update Pathos ###
#####################
function update_pathos {
  return 0
}
