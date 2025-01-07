#!/usr/bin/env -S bash
INSTALL_DIR="$(dirname $(realpath "${0}"))"
source "${INSTALL_DIR}/${FLATPAK_ID}.common.sh"

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