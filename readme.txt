PLAN

- compile default kernel + icu + qt5webengine
- manually add webengine_kiosk + input_event
- test in qemu and qemu-virgil

- https://github.com/nerves-web-kiosk
- https://github.com/samuelventura/nerves_system_x86_64

rm -fr deps/ .nerves/ _build/
mix archive.install hex nerves_bootstrap
mix deps.get
mix nerves.system.shell
make menuconfig
make savedefconfig

Anticipating cross compiling issues

fatal error: unicode/uchar.h: No such file or directory
sudo apt-get install libicu-dev

Since the target libraries may not actually be ABI compatible with host
system binaries (e.g. target has an old libc), this can cause crashes
or other errors.

The dev-qt/qtwebengine-5.13.2 build finally succeeded when I switched from gcc 8 to 9.  
I suspect qtwebengine-5.12.5 will also build properly under gcc 9.

qt5webengine 5.15.8
qt5webengine-chromium 0ad2814370799a2161057d92231fe3ee00e2fe98

Still failing on killed g++ process...
