#Nerves QEMU latest nerves_system_x86_64 with QT5 webengine qml

#brew install fwup squashfs coreutils xz pkg-config
#https://apple.stackexchange.com/questions/373888/how-do-i-start-the-docker-daemon-on-macos
#brew install docker colima
#colima start
#https://github.com/abiosoft/colima

git clone git@github.com:samuelventura/nerves_system_x86_64.git
cd nerves_system_x86_64
mix archive.install hex nerves_bootstrap #required before example
mix deps.get
mix nerves.system.shell
make menuconfig
make savedefconfig
make
exit
mix nerves.artifact
cp *.tar.gz ~/.nerves/artifacts

mix nerves.new example #no deps
cd example
#update app and host names qtwebeng
#update nerves_system_x86_64 path ../
MIX_TARGET=x86_64 mix deps.get
MIX_TARGET=x86_64 mix firmware
MIX_TARGET=x86_64 mix burn -d image.img
chown samuel:samuel image.img

qemu-virgil -enable-kvm -m 512M -device virtio-vga,virgl=on \
    -display sdl,gl=on -netdev user,id=ethernet.0,hostfwd=tcp::8022-:22 \
    -device rtl8139,netdev=ethernet.0 image.img

ssh localhost -p 8022


/home/samuel/src/nerves_system_x86_64/.nerves/artifacts/nerves_system_x86_64-portable-1.19.0/host/opt/ext-toolchain/bin/../lib/gcc/x86_64-buildroot-linux-gnu/11.2.0/../../../../x86_64-buildroot-linux-gnu/bin/ld: /home/samuel/src/nerves_system_x86_64/.nerves/artifacts/nerves_system_x86_64-portable-1.19.0/build/qt5webengine-5.15.8/src/core/release/obj/content/browser/libbrowser.a: error adding symbols: malformed archive
collect2: error: ld returned 1 exit status
make[5]: *** [Makefile.core_module:90: ../../lib/libQt5WebEngineCore.so.5.15.8] Error 1
make[4]: *** [Makefile:124: sub-core_module-pro-make_first] Error 2
make[3]: *** [Makefile:79: sub-core-make_first] Error 2
make[2]: *** [Makefile:49: sub-src-make_first] Error 2
make[1]: *** [package/pkg-generic.mk:293: /home/samuel/src/nerves_system_x86_64/.nerves/artifacts/nerves_system_x86_64-portable-1.19.0/build/qt5webengine-5.15.8/.stamp_built] Error 2
make: *** [Makefile:23: _all] Error 2

#qt5webengine compilation is starving resources, need to pass -j4 to ninja BR2_JLEVEL=4


#sudo apt install libicu-dev
In file included from ../../3rdparty/chromium/v8/src/regexp/gen-regexp-special-case.cc:10:
../../3rdparty/chromium/v8/src/regexp/special-case.h:12:10: fatal error: unicode/uchar.h: No such file or directory
   12 | #include "unicode/uchar.h"
      |          ^~~~~~~~~~~~~~~~~
compilation terminated.
[7743/21974] CXX v8_snapshot/obj/v8/torque/torque.o
ninja: build stopped: subcommand failed.
make[5]: *** [Makefile.gn_run:370: run_ninja] Error 1
make[4]: *** [Makefile:82: sub-gn_run-pro-make_first] Error 2
make[3]: *** [Makefile:79: sub-core-make_first] Error 2
make[2]: *** [Makefile:49: sub-src-make_first] Error 2
make[1]: *** [package/pkg-generic.mk:293: /home/samuel/nerves/nerves_system_x86_64/.nerves/artifacts/nerves_system_x86_64-portable-1.19.0/build/qt5webengine-5.15.8/.stamp_built] Error 2
make: *** [Makefile:23: _all] Error 2

#ninja error filename too long 257 bytes
#had to move nerves folder to home, create a link, and clean recompile qt5webengine
Done. Made 14252 targets from 2186 files in 5662ms
ninja -j9  -C /home/samuel/github/nerves/nerves_system_x86_64/.nerves/artifacts/nerves_system_x86_64-portable-1.19.0/build/qt5webengine-5.15.8/src/core/release QtWebEngineCore
ninja: Entering directory `/home/samuel/github/nerves/nerves_system_x86_64/.nerves/artifacts/nerves_system_x86_64-portable-1.19.0/build/qt5webengine-5.15.8/src/core/release'
ninja: warning: -jN forced on command line; ignoring GNU make jobserver.
[439/21974] ACTION //third_party/blink/renderer/mod...9.0/build/qt5webengine-5.15.8/src/toolchain:target)ninja: error: WriteFile(__third_party_blink_renderer_modules_mediacapturefromelement_mediacapturefromelement__jumbo_merge__home_samuel_github_nerves_nerves_system_x86_64_.nerves_artifacts_nerves_system_x86_64-portable-1.19.0_build_qt5webengine-5.15.8_src_toolchain_target__rule.rsp): Unable to create file. File name too long

ninja: build stopped: .
make[5]: *** [Makefile.gn_run:370: run_ninja] Error 1
make[4]: *** [Makefile:82: sub-gn_run-pro-make_first] Error 2
make[3]: *** [Makefile:79: sub-core-make_first] Error 2
make[2]: *** [Makefile:49: sub-src-make_first] Error 2
make[1]: *** [package/pkg-generic.mk:293: /home/samuel/github/nerves/nerves_system_x86_64/.nerves/artifacts/nerves_system_x86_64-portable-1.19.0/build/qt5webengine-5.15.8/.stamp_built] Error 2
make: *** [Makefile:23: _all] Error 2

#macos docket with colimna
samuel@macpro nerves_system_x86_64 % mix nerves.system.shell
==> nerves
stty sane rows 78 cols 110; stty -echo
export PS1=""; export PS2=""
start() {
echo -e "\e[25F\e[0J\e[1;7m
  Preparing Nerves Shell  \e[0m"
echo -e "\e]0;Nerves Shell\a"
export PS1="\e[1;7m Nerves \e[0;1m \W > \e[0m"
export PS2="\e[1;7m Nerves \e[0;1m \W ..\e[0m"
echo Updating build directory.
echo This will take a while if it is the first time...
/nerves/env/platform/create-build.sh /nerves/env/nerves_system_x86_64/nerves_defconfig /nerves/build >/dev/null
stty echo
}; start
docker: Error response from daemon: failed to create shim: OCI runtime create failed: invalid mount {Destination::/ssh-agent Type:bind Source:/var/lib/docker/volumes/0eccc3b6ffaf3f98ba3437bbaa111b2e8941824b590d3c083686ac127a11e2a9/_data Options:[rbind]}: mount destination :/ssh-agent not absolute: unknown.
ERRO[0000] error waiting for container: context canceled
