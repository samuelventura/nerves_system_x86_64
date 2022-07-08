PLAN

- compile default kernel + icu + mesa3d
- manually add webkitgtk
- test in qemu and qemu-virgil

#https://stackoverflow.com/questions/19783795/how-to-add-my-own-software-to-a-buildroot-linux-package
#https://wiki.st.com/stm32mpu/wiki/Create_a_simple_hello-world_application
#https://www.levien.com/gimp/hello.html

NOTICE: Since nerves_system_x86_64 dependency has the nerves compile flag enabled it is better
    to trigger the image compile from the example folder with the firmware task.

#https://github.com/nerves-project/nerves_system_x86_64
#https://github.com/samuelventura/nerves_system_x86_64/blob/qt5webengine/readme.txt
#https://github.com/samuelventura/kiosk_system_x86_64/blob/master/nerves_defconfig


git clone git@github.com:samuelventura/nerves_system_x86_64.git
cd nerves_system_x86_64
rm -fr deps/ .nerves/ _build/
mix archive.install hex nerves_bootstrap
mix deps.get
mix nerves.system.shell
make menuconfig
make savedefconfig
make
exit
mix nerves.artifact
mv *.tar.gz ~/.nerves/artifacts/

mix nerves.new example #no deps
cd example
rm -fr deps/ .nerves/ _build/
MIX_TARGET=x86_64 mix deps.unlock --all
#update app and host names wxkiosk
#update nerves_system_x86_64 path ../
MIX_TARGET=x86_64 mix deps.get
MIX_TARGET=x86_64 mix firmware
MIX_TARGET=x86_64 mix burn
MIX_TARGET=x86_64 mix burn -d image.img
chown samuel:samuel image.img
truncate -s 1G image.img

rsync -av build:src/nerves_system_x86_64/example/image.img ~/Downloads/

#from https://github.com/nerves-project/nerves_system_x86_64/issues/129
qemu-system-x86_64 -enable-kvm -m 512M \
    -drive file=image.img,if=virtio,format=raw \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::8022-:22 \
    -serial stdio

#works as well
sudo qemu-system-x86_64 \
    -drive file=/dev/sdc,if=virtio,format=raw \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::8022-:22 \
    -serial stdio

qemu-virgil -enable-kvm -m 512M \
    -device virtio-vga,virgl=on -display sdl,gl=on \
    -drive file=image.img,if=virtio,format=raw \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::8022-:22,hostfwd=tcp::8081-:8081,hostfwd=tcp::3389-:3389 \
    -serial stdio

#SSH works on first boot (not sure if delayed)
ssh localhost -p 8022
ssh p3420 -p 8022
NervesMOTD.print

#WESTON RDP
cd rootfs_overlay/etc
openssl genrsa -out tls.key 2048
openssl req -new -key tls.key -out tls.csr
openssl x509 -req -days 365 -signkey tls.key -in tls.csr -out tls.crt
File.mkdir("/data/xdg_rt")
File.chmod("/data/xdg_rt", 0o700)
System.cmd("weston", ["--backend=rdp-backend.so", "--rdp-tls-key=/etc/tls.key", "--rdp-tls-cert=/etc/tls.crt"], env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}])
cmd "killall weston"
#multiple sessions connect to same shell
xfreerdp /sec:tls /v:localhost 
Certificate details for localhost:3389 (RDP-Server):
        Common Name: Yeico
        Subject:     C = MX, ST = SLP, L = SLP, O = Yeico, OU = Yeico, CN = Yeico, emailAddress = nerves@yeico.com
        Issuer:      C = MX, ST = SLP, L = SLP, O = Yeico, OU = Yeico, CN = Yeico, emailAddress = nerves@yeico.com
        Thumbprint:  cf:c9:3f:e8:cd:70:cf:a8:76:ea:60:67:4f:f9:e4:0c:24:b3:3e:d3:e2:52:46:5b:3b:75:a7:df:71:33:8c:be
The above X.509 certificate could not be verified, possibly because you do not have
the CA certificate in your certificate store, or the certificate has expired.
Please look at the OpenSSL documentation on how to add a private CA to the store.
#Do you trust the above certificate? (Y/T/N) Y
#shows a shell with right-top corner date and a left-top (working) terminal shortcut
#from weston terminal:
echo $XDG_RUNTIME_DIR -> /data/xdg_rt
gtk3-demo #works from weston terminal
granite-demo #segfault settings.vala:87 could not connect: no such file or directory

#WESTON DRM with udevd
System.cmd("weston", ["--version"])                                                              
{"weston 10.0.0\n", 0}
File.mkdir("/data/xdg_rt")
File.chmod("/data/xdg_rt", 0o700)
:os.cmd('udevd -d')
:os.cmd('udevadm trigger --type=subsystems --action=add')
:os.cmd('udevadm trigger --type=devices --action=add')
:os.cmd('udevadm settle --timeout=30')
cmd "libinput list-devices" #must work at this point
#openvt -e nofork -s switch to vt -w wait cmd finish -c 1 busy
System.cmd("openvt", ["-v", "-s", "--", "weston", "--backend=drm-backend.so"], env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}])
#from ssh works as well with:
System.cmd("weston-terminal", [], stderr_to_stdout: true, env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}, {"WAYLAND_DISPLAY", "wayland-1"}])
System.cmd("gtk3-demo", [], stderr_to_stdout: true, env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}, {"GDK_BACKEND", "wayland"}, {"WAYLAND_DISPLAY", "wayland-1"}])
cmd "killall weston"

#from weston terminal
>gtkiosk
Could not determine the accessibility bus address
Couldn't open libGL.so.1 or libOpenGL.so.0
Aborted

