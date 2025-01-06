# Pathos Netack Codex Flatpak Installation for Linux



## Requriments
* 64-bit x86_64 CPU 
* Flatpak enabled [Linux distribution](https://flatpak.org/setup/) 
* flatpak-builder installed 

## Building

This is a temporary step. Once the development team gets Pathos on Flathub, this step will be unessessary. Thus builds and installs the image. 

```
cd ~/git
git clone https://github.com/callanh/pathos-official.git
cd ~/git/pathos-offical
./flatpak/flatpak-build.sh
```

<!-- ## Installation

Install flatpak application

```
flatpack install net.azurewebsites.pathos
``` -->

## Running the application
The first time you run the the flatpak it will have to setup a wine environment. This may take a while depending on your hardware.  

```
flatpak run net.azurewebsites.pathos
```


##