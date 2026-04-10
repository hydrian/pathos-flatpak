
WINEPREFIX='/var/data/wineprefix'
PATHOS_WIN_DIR='c:/Games/Pathos'
PATHOS_WINE_DIR="${WINEPREFIX}/drive_c/Games/Pathos"
PATHOS_WIN_EXE="${PATHOS_WIN_DIR}/PathosGame.exe"
PATHOS_WINE_EXE="${PATHOS_WINE_DIR}/PathosGame.exe"
PATHOSMAKER_WINE_EXE="${PATHOS_WINE_DIR}/PathosMaker.exe"
PATHOSMAKER_WIN_EXE="${PATHOS_WIN_DIR}/PathosMaker.exe"
GUI_BIN=$(which zenity)
if [ $? -ne 0 ] ; then
  echo "Could not find zenity binary" 1>&2
  exit 2
fi
function show_message {
  MSG="${1}"
  LEVEL="${2:-normal}"
  #echo "### ${MSG} ###" | tee  --output-error=exit -a "${FIFO_FILE}" 
  NOTIFY_ID=$(notify-send --urgency="${LEVEL}" -i /app/share/icons/hicolor/scalable/apps/net.azurewebsites.pathos.pathos.svg  "${MSG}" -p 2>/dev/null & )
  return 0
}

### Setting Wine Environment
function setup_wine {
  $GUI_BIN \
    --button=Ok:0 \
    --text-info \
    --auto-scroll \
    --tail \
    --wrap \
    --auto-close \
    --title="Pathos Wine Environment Setup"  < "${FIFO_FILE}" & 
  show_message "Setting up Windows (Wine) is being setup. This may take a while."
  
  ( echo "Setting-up wine prefix..." 2>&1 | tee --output-error=exit -a "${FIFO_FILE}")  
  ( echo "WINEPREIX: ${WINEPREFIX}" 2>&1 | tee --output-error=exit -a "${FIFO_FILE}" ) 
  ( WINEDLLOVERRIDES='mscoree=d;mshtml=d' /app/bin/wine 'wineboot' )  

  if [ $? -eq 0 ] ; then 
    echo "Wineboot complete"  
  else 
    show_message "Wineboot failed"
    return 3
  fi
  echo "Setting up WineTricks"
  ( winetricks '--unattended' 'corefonts' 'dotnet48' 'renderer=gdi' 'win10' 2>&1  ) 
  if [ $? -ne 0 ] ; then
    show_message "Winetricks failed to setup"
    return 4
  fi

	### Installing .Net 10.0.5 Desktop Runtime environment
	WINE_TEMP_DIR="${WINEPREFIX}/drive_c/windows/temp"
	DOTNET10_FILENAME='windowsdesktop-runtime-10.0.5-win-x64.exe'
	DOTNET10_CHECKSUM='cbb1ad53aecc54264488cc5c0be938991770750209cf4acd383bbe8af57db679f4d5988e6281a6d6a46b4e141db3d3d539ea764250b4ab48871972a610944b40'
	if [ ! -d "${WINEPREFIX}/drive_c/Program Files/dotnet/shared/Microsoft.WindowsDesktop.App/10.0.5" ] ; then
		pushd $WINE_TEMP_DIR 1>/dev/null
		show_message "Installing .Net 10.0.5 manually"
		show_message "Downloading .Net 10.0.5"
		if (wget -O "./${DOTNET10_FILENAME}" "https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/10.0.5/windowsdesktop-runtime-10.0.5-win-x64.exe") ; then
			show_message "Download complete"
		else
			show_message "Download failed!"
			return 5
		fi
		echo "${DOTNET10_CHECKSUM} windowsdesktop-runtime-10.0.5-win-x64.exe" | sha512sum --check - 1>/dev/null
		if [ $? -ne 0 ] ; then	
			show_message ".Net 10 Download failed validation. Download corrupt or fraudulant."
		  return 6
		fi 
		show_message "Running .Net 10 installer"
		wine "./${DOTNET10_FILENAME}" /quiet
		if [ $? -ne 0 ] ; then
			show_message ".Net 10 Desktop Runtime installer failed"
			return 7
		fi 		
		popd 1>/dev/null

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
  INSTALLER_FILE="/app/share/${FLATPAK_ID}/pathos-installer.exe"
  echo "Running Pathos installer..."
  wine "${INSTALLER_FILE}" "/silent" "/dir=${PATHOS_WIN_DIR}" "/LOG" "/DoNotLaunchGame"
  if [ $? -eq 0 ] ; then
    show_message "Pathos installer successful" low
  else
    show_message "PathosSetup.exe installer failed"
    return 2
  fi

  FLATPAK_PERSIT_CONFIG_DIRS=(
    "Settings"
    "Profiles"
  )
  for DIR in "${FLATPAK_PERSIT_CONFIG_DIRS[@]}" ; do
    FLATPAK_DIR="/var/config/Pathos/${DIR}"
    WIN_DIR="${PATHOS_WINE_DIR}/${DIR}"
    test ! -d "${FLATPAK_DIR}" && mkdir -p "${FLATPAK_DIR}"
    test -e "${WIN_DIR}" && rm -Rf "${WIN_DIR}"
    pushd "${PATHOS_WINE_DIR}" 1>/dev/null
    ln -s "${FLATPAK_DIR}" "${DIR}"
  done 

  FLATPAK_PERSIST_DATA_DIRS=(
    "Adventures"
    "Bones"
    "Campaigns"
    "Glyphs"
    "Logs"   
    "Quests"
    "Sonics"
    "Tracks"
    "Vanities"  
  )
  for DIR in "${FLATPAK_PERSIST_DATA_DIRS[@]}" ; do
    FLATPAK_DIR="/var/data/Pathos/${DIR}"
    WIN_DIR="${PATHOS_WINE_DIR}/${DIR}"
    test ! -d "${FLATPAK_DIR}" && mkdir -p "${FLATPAK_DIR}"
    test -e "${WIN_DIR}" && rm -Rf "${WIN_DIR}"
    pushd "${PATHOS_WINE_DIR}" 1>/dev/null
    ln -s "${FLATPAK_DIR}" "${DIR}"
  done
  return 0
}

#####################
### Update Pathos ###
#####################
function update_pathos {
  return 0
}
