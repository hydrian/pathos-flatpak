#!/usr/bin/env -S bash -x 
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
FLATPAK_BUILDER='flatpak run  org.flatpak.Builder'
FLATPAK_BUILDER_LINT='flatpak run  --command=flatpak-builder-lint org.flatpak.Builder'
PATHOS_INSTALLER_FILE='Pathos-installer.exe'

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
	'app/org.flatpak.Builder/x86_64/stable'
  'runtime/org.freedesktop.Platform/x86_64/25.08'
  'runtime/org.freedesktop.Sdk/x86_64/25.08'
	'app/org.winehq.Wine/x86_64/wow64-25.08'
  'runtime/org.freedesktop.Platform.GL.default/x86_64/25.08'
	
)

echo "Adding Flathub flatpak repo as a user if not already added"
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
if [ $? -ne 0 ] ; then
	exit $?
fi

for DEP in "${FLATPAK_DEPENDENCIES[@]}" ; do
	flatpak info "${DEP}" 1>/dev/null 2>/dev/null
  if [ $? -ne 0 ] ; then  
    echo "Installing dependency $DEP"
    flatpak install flathub $DEP --noninteractive --user  
  fi
done 
$FLATPAK_BUILDER_LINT  manifest net.azurewebsites.pathos.pathos.yml
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
${FLATPAK_BUILDER} --verbose .flatpak/build \
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
  $FLATPAK_BUILDER --command=flatpak-builder-lint repo repo
	if [ $? -ne 0 ] ; then
		echo "Failed flatpak publishing lint"
		exit 2
	fi
fi
exit 0
