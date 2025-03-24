# Pathos: Netack Codex Flatpak Installation for Linux

## Prerequestites

* 64-bit x86_64 CPU
* Flatpak enabled [Linux distribution](https://flatpak.org/setup/)
* flatpak-builder installed
* git installed
* About 1.5GB free space in your $HOME directory

## Building

This is a temporary step. Once the development team gets Pathos on Flathub, this step will become unnecessary. The following instructions builds and installs the flatpak image of Pathos.

> [!IMPORTANT]
> Recently, the default branch changed from `main` to `stable`. If you have an older git checkout, you may need to update the remotes or just delete and reclone the git repository.

```bash
cd ~/git
git clone https://github.com/hydrian/pathos-flatpak.git
cd ~/git/pathos-flatpak
./flatpak-build.sh
```

<!-- ## Installation

Install flatpak application

```
flatpack install net.azurewebsites.pathos
``` -->

## Running the Application

The first time you run the the flatpak it will have to setup a wine environment. This may take a while depending on your hardware.  

You should have a 'Pathos' entry in your applciation menu.

If you have issues, try running it from the command line. This may help diagnose some issues.

```bash
flatpak run net.azurewebsites.pathos.pathos
```

> [!IMPORTANT]
> The flatpak id has changed. This change was required to get this package published  to Flathub.
> You can remove the old flatpak ID net.azurewebsites.pathos.flatpak


## Caveats

### No Modding support

Do to the lack of Microsoft Visual Studio or Build Tools on Wine or native Linux, this cannot be supported.

### Full-Screen is Wrong Sized

Do to Wine a issue, full-screen mode won't be supported as a default. Maxized window is recommended. If you want full-screen mode, take a look at [Work Arounds](#work-arounds)

### No i386 Support

The flatpak package only supports x86_64 even though the native Windows installer supports both i386 and x86_64. If there is enough demand, I may create an i386 build if there is enough demnd. Also, PR's are accepted for this feature.

## Work Arounds

* Full-screen mode can be supported with custom configuration. See [#3](https://github.com/hydrian/pathos-flatpak/issues/3#issuecomment-2578002145)

## Troubleshooting

### Failed to Build image

You get this error:

```text
Exporting net.azurewebsites.pathos to repo
FB: Running: flatpak build-export --arch=x86_64 '--exclude=/lib/debug/*' --include=/lib/debug/app '--exclude=/share/runtime/locale/*/*' '/home/hydrian@TYGERCLAN.LAN/git/pathos-flatpak/.flatpak/repo' .flatpak/build main
error: opening repo: opendir(objects): No such file or directory
Export failed: Child process exited with code 1
FB: Unmounting read-only fs: fusermount -uz /home/hydrian@TYGERCLAN.LAN/git/pathos-flatpak/.flatpak/state/rofiles/rofiles-ImiZGI
Failed to build image
```

You have a messed up repo directory. Delete the build directory and rerun the `flatpak-build.sh` script.

```bash
rm -Rf ~/git/pathos-flatpak/.flatpak/repo ~/git/pathos-flatpak/.flatpak-builder 
