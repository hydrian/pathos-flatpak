#!/usr/bin/env -S bash 
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
FLATPAK_BUILDER=$(which flatpak-builder)
PATHOS_INSTALLER_FILE='Pathos-installer.exe'
if [ $? -ne 0 ] ; then
  echo "flatpak-builder is not installed." 1>&2 
  exit 2
fi

function getSHASum {
  local SOURCE=$1
  if [ ! -e ${SOURCE} ] ; then
    echo "Could not find ${SOURCE} file"
    return 2
  fi 
  SOURCE_SUM=$(sha256sum "${SOURCE}"|cut -f 1 -d \  )
  SOURCE_RET=$?
  if [ $SOURCE_RET -eq 0 ] ; then
    echo $SOURCE_SUM
    return 0
  fi
  return $SOURCE_RET
}

SCRIPT_FILE=$(realpath "${0}")
GIT_ROOT_DIR=$(realpath "$(dirname "${SCRIPT_FILE}")") 
echo "Building Flatpak image..."
pushd "$GIT_ROOT_DIR" 1>/dev/null
FLATPAK_DEPENDENCIES=(
  'org.freedesktop.Platform/x86_64/24.08'
  'org.freedesktop.Sdk/x86_64/24.08'
	'org.winehq.Wine/x86_64/stable-24.08'
  'org.freedesktop.Platform.GL.default/x86_64/24.08'
)

for DEP in "${FLATPAK_DEPENDENCIES[@]}" ; do
#  DEP_SHORTNAME=$(echo "${DEP}"|cut -f1 -d / )
#  flatpak show "${DEP_SHORTNAME}" >/dev/null
  if [ $? -ne 0 ] ; then  
    echo "Installing dependency $DEP"
    flatpak install --user flathub $DEP
  fi
done 
flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest net.azurewebsites.pathos.pathos.yml
if [ $? -ne 0 ] ; then
  echo "Did not pass lint tests" 1>&2
  exit 2
fi
echo 'cleaning up from previous build'
find ~/.local -iname net.azurewebsites.pathos.pathos\*\.desktop -delete
rm -Rf .flatpak .flatpak-builder repo
test ! -d .flatpak && mkdir -p .flatpak
if [ "$1" == 'update' ] ; then 
  echo "Updating Pathos Install"
  UPDATE_TEMP=$(mktemp -d)
  OLD_INSTALLER_FILE=$(realpath "./installer/${PATHOS_INSTALLER_FILE}")
  OLD_INSTALLER_SUM=$(getSHASum "${OLD_INSTALLER_FILE}")
  pushd "${UPDATE_TEMP}" 1>/dev/null
  wget -O "url.txt" "https://pathos.azurewebsites.net/PathosSetup.txt"
  wget -O "${PATHOS_INSTALLER_FILE}" "$(cat url.txt)"
  NEW_INSTALLER_SUM=$(getSHASum "${PATHOS_INSTALLER_FILE}")
  if [ "${OLD_INSTALLER_SUM}" != "${NEW_INSTALLER_SUM}" ] ; then
    echo "Installer file needs updating"
    cp "${PATHOS_INSTALLER_FILE}" "${OLD_INSTALLER_FILE}"
    if [ $? -eq 0 ] ; then
      echo "Installer file updated"
    else 
      echo "Failed to update installer file" 1>&2
      exit 2
    fi
  else 
    echo "Installer is the same. Does not need to be updated"
  fi
  rm -Rf "${UPDATE_TEMP}"
  popd 1>/dev/null
fi
echo "Running ${FLATPAK_BUILDER}"
"${FLATPAK_BUILDER}" --verbose .flatpak/build \
	--default-branch="${GIT_BRANCH}" \
  --force-clean \
  --keep-build-dirs \
  --state-dir=.flatpak/state \
  --repo=repo  \
  net.azurewebsites.pathos.pathos.yml \
  --install \
  --user 
if [ $? -ne 0 ] ; then
  echo "Failed to build image" 1>&2
  exit 2
fi
popd 1>/dev/null
echo "Flatpak image built successfully"
if [ "$1" == 'publish' ] ; then
	echo 'Running flatpak linter for publishing'
  flatpak run --command=flatpak-builder-lint org.flatpak.Builder repo repo
	if [ $? -ne 0 ] ; then
		echo "Failed flatpak publishing lint"
		exit 2
	fi
fi
exit 0
