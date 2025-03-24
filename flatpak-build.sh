#!/usr/bin/env -S bash
FLATPAK_BUILDER=$(which flatpak-builder)
if [ $? -ne 0 ] ; then
  echo "flatpak-builder is not installed." 1>&2 
  exit 2
fi

SCRIPT_FILE=$(realpath "${0}")
GIT_ROOT_DIR=$(realpath "$(dirname "${SCRIPT_FILE}")") 
echo "Building Flatpak image..."
pushd "$GIT_ROOT_DIR" 1>/dev/null
FLATPAK_DEPENDENCIES=(
  'org.freedesktop.Platform/x86_64/24.08'
  'org.freedesktop.Sdk/x86_64/24.08'
  'org.winehq.Wine/x86_64/stable-24.08'
)
for DEP in "${FLATPAK_DEPENDENCIES[@]}" ; do
  echo "Installing dependency $DEP"
  flatpak install $DEP
done 
flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest net.azurewebsites.pathos.pathos.yml
if [ $? -ne 0 ] ; then
  echo "Did not pass lint tests" 1>&2
  exit 2
fi
find ~/.local -iname net.azurewebsites.pathos.pathos\*\.desktop -delete
test ! -d .flatpak && mkdir -p .flatpak
"${FLATPAK_BUILDER}" --verbose .flatpak/build \
	--default-branch=main \
  --force-clean \
  --keep-build-dirs \
  --state-dir=.flatpak/state \
  --repo=.flatpak/repo  \
  net.azurewebsites.pathos.pathos.yml \
  --install \
  --user 
if [ $? -ne 0 ] ; then
  echo "Failed to build image" 1>&2
  exit 2
fi
popd 1>/dev/null
echo "Flatpak image built successfully"
exit 0
