#!/usr/bin/env -S bash -x
FLATPAK_ID='net.azurewebsites.pathos.pathos'
INSTALL_DIR="$(dirname $(realpath "${0}"))"
FIFO_FILE=/tmp/setup.fifo
test -e "${FIFO_FILE}" && rm "${FIFO_FILE}" 
mkfifo "${FIFO_FILE}"

source "${INSTALL_DIR}/${FLATPAK_ID}.common.sh"
if [ $? -ne 0 ] ; then
  echo "Failed to load ${FLATPAK_ID}.common.sh"
  exit 2
fi

############
### MAIN ###
############
echo "Paramters: ${@}"
if [ "${1}" == 'shell' ] ; then
  /bin/bash
  exit $?
fi
if [ ! -d "${WINEPREFIX}" ] || [ "${1}" == 'wine-reinstall' ] ; then
  test -d "${WINEPREFIX}" && rm -Rf "${WINEPREFIX}"
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
