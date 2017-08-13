## exe-thumbnailer 0.10.0

- gnome-exe-thumbnailer is now exe-thumbnailer (this project is unaffiliated with GNOME and has supported other desktops for quite a while now.)
- Added support for icon theme fetching on Xfce, MATE, and Cinnamon.
- exe-thumbnailer now supports relative paths for .lnk files, and uses lnkinfo instead of wine-tools for parsing.
- Updated Moka icon set, from Alfredo Hernández (https://bugs.launchpad.net/ubuntu/+source/gnome-exe-thumbnailer/+bug/1404744)
- Removed fallback icon generation with the first two characters of the filename. If thumbnailing fails, the default icon from the current icon theme will be used instead.
- exe-thumbnailer now writes thumbnails to XDG_CACHE_HOME instead of ~/.thumbnails, which is deprecated.
- Miscellaneous code cleanup

----

For changes between older versions of gnome-exe-thumbnailer, consult the CHANGELOG.old file instead.
