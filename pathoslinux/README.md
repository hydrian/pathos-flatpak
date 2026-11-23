# Pathos Linux installer (Wine)

This optional package installs Pathos directly through Wine. It configures a
Wine prefix, installs the Windows game, and creates a Linux application menu
entry and desktop shortcut.

## Requirements

- 64-bit Linux
- Network access for Wine components and the .NET runtime download

The installer checks for Wine, Winetricks, Python 3, a downloader, and checksum
tools. If anything is missing, it offers one `Y` confirmation to install the
host packages using apt, dnf, pacman, or zypper. The package manager may request
your normal sudo password. If you decline, it prints the missing prerequisites.

## Install

After extracting the release archive, run from its folder:

```sh
./install.sh
```

The installer checks which Winetricks verbs are already present and applies
only missing ones. It skips the .NET runtime download if .NET 10.0.5 is already
installed. By default it uses `~/.wine`; set `WINEPREFIX=/some/path` before
running it to select another prefix.

It configures Internet Explorer 8 for Pathos's embedded browser content
(including updates), Windows 10 mode, GDI rendering, and the
.NET 10.0.5 Windows Desktop Runtime. It installs Pathos to C:\\Games\\Pathos
inside the chosen prefix and creates the Games menu entry.

The first run of Winetricks may take several minutes while it downloads
Microsoft components. Keep the installer running until it completes.

## Build the release archive

From a repository checkout, run `python3 pathoslinux/package.py`. It creates
`pathoslinux/dist/PathosLinuxInstaller.tar.gz` containing the setup script, documentation,
icon, checksums, and the already tracked Windows Pathos installer. The generated
archive is a release artifact and is not committed to Git.
