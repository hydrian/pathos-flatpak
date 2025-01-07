# Pathos: Netack Codex Flatpak Installation for Linux

## Prerequestites

* 64-bit x86_64 CPU
* Flatpak enabled [Linux distribution](https://flatpak.org/setup/)
* flatpak-builder installed
* git installed
* About 1.5GB free space in your $HOME directory

## Building

This is a temporary step. Once the development team gets Pathos on Flathub, this step will be unessessary. The following instructions builds and installs the flatpak image of Pathos.

```bash
flatpak install org.freedesktop.Sdk/x86_64/24.08 org.winehq.Wine/x86_64/stable-24.08 org.freedesktop.Platform.Compat.i386/x86_64/24.08
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
flatpak run net.azurewebsites.pathos
```

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
rm -Rf ~/git/pathos-flatpak/.flatpak 
