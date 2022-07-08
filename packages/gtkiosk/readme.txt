
#http://snarvaez.poweredbygnulinux.com/notes/gtk3_001.html

#pkg-config requires this host packages
apt install libgtk-3-dev libwebkit2gtk-4.0-dev

pkg-config --list-all
pkg-config --variable pc_path pkg-config

pkg-config --cflags gtk+-3.0
pkg-config --cflags webkit2gtk-4.0
pkg-config --libs gtk+-3.0
pkg-config --libs webkit2gtk-4.0

- use vala ?
- why buildroot pkg-config points to host headers ?
