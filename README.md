## exe-thumbnailer

**exe-thumbnailer** (formerly gnome-exe-thumbnailer) is a simple program that generates thumbnails for Windows executable files (.exe, .lnk, .msi, and .dll). It supports numerous file managers, including Nautilus, Caja, Nemo, Thunar (when Tumbler is installed), and PCManFM.

exe-thumbnailer originates from ideas found in Ubuntu Brainstorm, and was originally written as part of the Karmic-Wine-Integration spec: https://wiki.ubuntu.com/karmic-wine-integration

![exe-thumbnailer demo screenshot](exe-thumbnailer.png)

### Dependencies
- icoutils
- imagemagick
- gsettings (`libglib2.0-bin` on Debian/Ubuntu)

#### Optional Dependencies
- For .lnk thumbnailing: lnkinfo (`liblnk-utils`) and Wine
- For .msi thumbnailing: msitools
