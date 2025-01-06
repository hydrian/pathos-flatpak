#/bin/bash -x
WINEPREFIX='/var/data/wineprefix'
PATHOS_WIN_DIR='c:/Games/Pathos'
PATHOS_WINE_DIR="${WINEPREFIX}/drive_c/Games/Pathos"
PATHOS_WIN_EXE="${PATHOS_WIN_DIR}/PathosGame.exe"
PATHOS_WINE_EXE="${PATHOS_WINE_DIR}/PathosGame.exe"

function setup_wine {
  echo "Setting up Wine... This may take a while..."
  echo "Setting-up wine prefix..."
  echo "WINEPREIX: ${WINEPREFIX}"
  WINEDLLOVERRIDES='mscoree=d;mshtml=d' /app/bin/wine64 wineboot
  if [ $? -eq 0 ] ; then 
    echo "Wineboot complete"
  else 
    echo "Wineboot failed"
    return 3
  fi
  echo "Setting up WineTricks"
  winetricks --unattended 'corefonts' 'dotnet48' 'renderer=gdi'
  return $?
}
#########################
### Installing Pathos ###
#########################
function install_pathos {
  echo "Installing Pathos"
  test ! -d "${WINEPREFIX}" && mkdir -p "${WINEPREFIX}"
  WINE_ADVENTURES_DIR="${PATHOS_WINE_DIR}/Adventures"
  FLATPAK_ADVENTURES_DIR='/var/data/adventures'
  INSTALLER_FILE="/var/cache/PathosSetup.exe"
  echo "Downloading Pathos installer..."
  curl -L --progress-bar --output "${INSTALLER_FILE}" "https://www.dropbox.com/scl/fi/s4vrz7uixwltygqcltjcn/PathosSetup.exe?rlkey=0w7ar56sh8c5643gsbrmdrsj9&st=goqhhy2n&dl=1"
  echo "Running Pathos installer..."
  wine64 "${INSTALLER_FILE}" "/verysilent" "/dir=${PATHOS_WIN_DIR}" "/LOG" "/DoNotLaunchGame"
  if [ $? -eq 0 ] ; then
    echo "Pathos installer successful"
  else
    echo "Failed to run Pathos installer successfully"
  fi

  test ! -d "${FLATPAK_ADVENTURES_DIR}" && mkdir -p "${FLATPAK_ADVENTURES_DIR}"
  if [ -e "${WINE_ADVENTURES_DIR}" ] ; then
    echo "Removing stock Adventures directory" 
    rm -Rf "${WINE_ADVENTURES_DIR}"
  fi
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
############
### MAIN ###
############
echo "Paramters: ${@}"
if [ ! -d "${WINEPREFIX}" ] ; then
  setup_wine 
  if [ $? -eq 0 ] ; then
    echo "wine_setup successfull"
  else
    echo "wine_setup failed" 1>&2 
    exit 2
  fi
fi

if [ ! -e "${PATHOS_WINE_EXE}" ] ; then
  install_pathos
  if [[ $? != 0 ]] ; then
      echo "Pathos Installation failed, abort."
      exit 1
  fi
fi
wine64 "${PATHOS_WIN_EXE}" 'windowed-mode' 
exit $?