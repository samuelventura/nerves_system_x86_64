PLAN

- compile default kernel + icu + mesa3d
- manually add erlang + wx/webview packages
- test in qemu and qemu-virgil

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
#nerves_system_x86_64-portable-1.19.0-0098FAC.tar.gz
#nerves_system_x86_64-portable-1.20.0-3796BF2.tar.gz
#nerves_system_x86_64-portable-1.20.0-CBD5942.tar.gz
#nerves_system_x86_64-portable-1.20.0-6ECBFFC.tar.gz
#nerves_system_x86_64-portable-1.20.0-FE304C2.tar.gz
#nerves_system_x86_64-portable-1.20.0-7F23366.tar.gz
#nerves_system_x86_64-portable-1.20.0-2B723DD.tar.gz
#nerves_system_x86_64-portable-1.20.0-D322672.tar.gz
#nerves_system_x86_64-portable-1.20.0-42F9B85.tar.gz
#nerves_system_x86_64-portable-1.20.0-1A6EF7F.tar.gz
#nerves_system_x86_64-portable-1.20.0-C1B11C5.tar.gz
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
#ensure /data has free space
truncate -s 1G image.img

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
System.cmd("gtk3-demo", [], stderr_to_stdout: true, env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}, {"GDK_BACKEND", "wayland"}, {"WAYLAND_DISPLAY", "wayland-1"}])
System.cmd("weston-terminal", [], stderr_to_stdout: true, env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}, {"WAYLAND_DISPLAY", "wayland-1"}])
#https://wayland.freedesktop.org/building.html weston deps, rtenv, and demos
#working demos: weston-flower, weston-smoke

#BROADWAY
System.cmd("broadwayd", [":1"], env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}])
System.cmd("gtk3-demo", [], stderr_to_stdout: true, env: [{"GTK_DEBUG", "all"}, {"GDK_DEBUG", "all"}, {"XDG_RUNTIME_DIR", "/data/xdg_rt"}, {"GDK_BACKEND", "broadway"}, {"BROADWAY_DISPLAY", ":1"}, {"UBUNTU_MENUPROXY", ""}, {"LIBOVERLAY_SCROLLBAR", "0"}])

iex(20)> cmd "gtk3-demo --version"       
gtk3-demo 3.24.33

#https://manpages.ubuntu.com/manpages/bionic/man1/broadwayd.1.html
#https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
System.cmd("broadwayd", [":1"], env: [{"XDG_RUNTIME_DIR", "/root"}])
cmd "killall broadwayd"
#Gtk-WARNING cannot open display:
#Gdk-Message: Trying broadway backend
#Gdk-Message: Unable to init Broadway server: Could not connect: Connection refused
System.cmd("gtk3-demo", [], env: [{"XDG_RUNTIME_DIR", "/root"}, {"GDK_BACKEND", "broadway"}, {"GDK_DEBUG", "all"}, {"BROADWAY_DISPLAY", ":1"}])
#--version {"gtk3-demo 3.24.33\n", 0}
#GLib-GIO-ERROR: Settings schema 'org.gnome.desktop.interface' is not installed
#requires package gsettings-desktop-schemas
#Failed to create /root/.config/glib-2.0/settings: No space left on device
System.cmd("granite-demo", [], env: [{"XDG_RUNTIME_DIR", "/root"}, {"GDK_BACKEND", "broadway"}, {"BROADWAY_DISPLAY", ":1"}])
#EGLUT failed to initialize native display
System.cmd("es2gears_wayland", [], env: [{"XDG_RUNTIME_DIR", "/data"}, {"GDK_BACKEND", "broadway"}, {"BROADWAY_DISPLAY", ":1"}])
File.write("/root/touch.txt", "touch")
{:error, :enospc}
#pango-view: When running GraphicsMagick 'gm display' command: Failed to execute child process *gm* (No such file or directory)
System.cmd("pango-view", ["/root/touch.txt"], env: [{"XDG_RUNTIME_DIR", "/root"}, {"XDG_DATA_DIRS", "/usr/local/share:/usr/share"}, {"GDK_BACKEND", "broadway"}, {"GDK_DEBUG", "all"}, {"BROADWAY_DISPLAY", ":1"}])
http://127.0.0.1:8081/
#works on kubuntu, both demos crash on qemu
#Could not load pixbuf from /org/gtk/libgtk/theme/Adwaita/assets/bullet-symbolic.svg
#That may indicate that pixbuf loaders or the mime database could not be found
System.cmd("gtk3-icon-browser", [], env: [{"XDG_RUNTIME_DIR", "/root"}, {"XDG_DATA_DIRS", "/usr/local/share:/usr/share"}, {"GDK_BACKEND", "broadway"}, {"GDK_DEBUG", "all"}, {"BROADWAY_DISPLAY", ":1"}])
cmd "find /usr -name *bullet*"

samuel@p3420:~$ broadwayd :5
Listening on /run/user/1000/broadway6.socket
samuel@p3420:~$ GDK_BACKEND=broadway BROADWAY_DISPLAY=:5 gtk3-demo
http://localhost:8085/

#qemu-virgil with udevd
cmd "libinput list-devices"
Device:           Power Button
Kernel:           /dev/input/event0
Group:            1
Seat:             seat0, default
Capabilities:     keyboard 
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      n/a
Nat.scrolling:    n/a
Middle emulation: n/a
Calibration:      n/a
Scroll methods:   none
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   n/a
Rotation:         n/a

Device:           AT Translated Set 2 keyboard
Kernel:           /dev/input/event1
Group:            2
Seat:             seat0, default
Capabilities:     keyboard 
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      n/a
Nat.scrolling:    n/a
Middle emulation: n/a
Calibration:      n/a
Scroll methods:   none
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   n/a
Rotation:         n/a

Device:           ImExPS/2 Generic Explorer Mouse
Kernel:           /dev/input/event2
Group:            3
Seat:             seat0, default
Capabilities:     pointer 
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      disabled
Nat.scrolling:    disabled
Middle emulation: disabled
Calibration:      n/a
Scroll methods:   button
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   flat *adaptive
Rotation:         n/a

0

#from weston env > /data/env.txt
iex(27)> cmd "cat /data/env.txt"
LANGUAGE=en
HOME=/root
ERL_INETRC=/etc/erl_inetrc
EMU=beam
PROGNAME=erlexec
COLORTERM=xterm
BINDIR=/srv/erlang/erts-13.0.2/bin
HEART_BEAT_TIMEOUT=30
WAYLAND_DISPLAY=wayland-1
ERL_CRASH_DUMP=/root/crash.dump
RELEASE_TMP=/tmp
RELEASE_SYS_CONFIG=/srv/erlang/releases/0.1.0/sys
TERM=xterm
WESTON_CONFIG_FILE=
BOOT_IMAGE=(hd0,msdos2)/boot/bzImage
PATH=/srv/erlang/erts-13.0.2/bin:/srv/erlang/bin:/usr/sbin:/usr/bin:/sbin:/bin
RELEASE_ROOT=/srv/erlang
XDG_RUNTIME_DIR=/data/xdg_rt
LANG=en_US.UTF-8
ROOTDIR=/srv/erlang
PWD=/srv/erlang
0

#fatal: failed to create a compositor backend option 'seat', udev device property ID_SEAT
#https://gitlab.freedesktop.org/wayland/weston
#https://wayland.freedesktop.org/libinput/doc/latest/seats.html
#https://manpages.ubuntu.com/manpages/bionic/man1/libinput-list-devices.1.html

System.cmd("weston", ["--tty=1", "--device=/dev/fb0"], env: [{"XDG_RUNTIME_DIR", "/data/xdg_rt"}])
#could not get launcher fd from environment
#https://elinux.org/images/9/93/The-Modern-Linux-Graphics-Stack-on-Embedded-Systems-Michael-Tretter-Pengutronix.pdf
#https://www.youtube.com/watch?v=GOvbEoOBH98

samuel@p3420:~/src/nerves_system_x86_64/example$ sudo blkid
/dev/sdc1: SEC_TYPE="msdos" UUID="0021-7A00" TYPE="vfat" PARTUUID="04030201-01"
/dev/sdc2: TYPE="squashfs" PARTUUID="04030201-02"
/dev/sdc3: PARTUUID="04030201-03"

#pull latest changes
git remote add upstream git@github.com:nerves-project/nerves_system_x86_64.git
git fetch upstream
git merge upstream/main main

ISSUES AND OBSERVATIONS:

- No serial output to stdio
- No custom logo shown
- No nerves shell history in qemu (brix history ok)
- Crash dump on cmd "poweroff" (qemu direct usb)
- cmd "mkdir /root/.cache" no space left on device (qemu)
- Boots in brix without nic detection and same locale warning
- Waiting for root device PARTUUID=04030201-02... (for certain qemu cmd line params)
- Error handling file /root/.cache/erlang-history/erlang-shell-log.siz. Reason: enoent
- kex_exchange_identification: read: Connection reset by peer (not happening here)
- erlinit: Cannot mount /dev/rootdisk0p4 at /root: Invalid argument (FIXED ON REBOOT)
- warning: the VM is running with native name encoding of latin1 which may cause Elixir 
    to malfunction as it expects utf8. Please ensure your locale is set to UTF-8
    (which can be verified by runnig "locale" in your shell): 
    solved with BR2_GENERATE_LOCALE="en_US.UTF-8"
- no keyboard input gets to nano (removed)
- screen says Must be connected to terminal (removed)
- sqlite3 wont start (removed)
- broadwayd+gtk3-demo: only 2 ssh connections allowed, slow keyboard, sudden reboot
- weston fb backend was deprecated in v10
- openvt is part of kbd: confirmed

buildroot/build/webkitgtk-2.36.3/Source/JavaScriptCore/buildroot/build/webkitgtk-2.36.3/Source/JavaScriptCore/assembler/X86Assembler.h:4055: undefined reference to `operationReallocateButterflyToGrowPropertyStorage'
/home/samuel/src/nerves_system_x86_64/.nerves/artifacts/nerves_system_x86_64-portable-1.20.0/host/opt/ext-toolchain/bin/../lib/gcc/x86_64-buildroot-linux-gnu/11.2.0/../../../../x86_64-buildroot-linux-gnu/bin/ld: CMakeFiles/JavaScriptCore.dir/__/__/JavaScriptCore/DerivedSources/unified-sources/UnifiedSource-f0a787a9-1.cpp.o: relocation R_X86_64_PC32 against undefined hidden symbol `operationReallocateButterflyToGrowPropertyStorage' can not be used when making a shared object
/home/samuel/src/nerves_system_x86_64/.nerves/artifacts/nerves_system_x86_64-portable-1.20.0/host/opt/ext-toolchain/bin/../lib/gcc/x86_64-buildroot-linux-gnu/11.2.0/../../../../x86_64-buildroot-linux-gnu/bin/ld: final link failed: bad value
collect2: error: ld returned 1 exit status
make[4]: *** [Source/JavaScriptCore/CMakeFiles/JavaScriptCore.dir/build.make:4099: lib/libjavascriptcoregtk-4.0.so.18.20.7] Error 1
make[3]: *** [CMakeFiles/Makefile2:754: Source/JavaScriptCore/CMakeFiles/JavaScriptCore.dir/all] Error 2
make[2]: *** [Makefile:171: all] Error 2
make[1]: *** [package/pkg-generic.mk:293: /home/samuel/src/nerves_system_x86_64/.nerves/artifacts/nerves_system_x86_64-portable-1.20.0/build/webkitgtk-2.36.3/.stamp_built] Error 2
make: *** [Makefile:23: _all] Error 2

EXT4-fs (vda4): VFS: Can't find ext4 filesystem
erlinit: Cannot mount /dev/rootdisk0p4 at /root: Invalid argument
EXT4-fs (vda4): mounted filesystem without journal. Opts: (null)
ext4 filesystem being mounted at /root supports timestamps until 2038 (0x7fffffff)
#https://blog.merovius.de/posts/2013-10-20-ext4-mysterious-no-space-left-on/

samuel@p3420:~/src/nerves_system_x86_64/example/rootfs_overlay/etc$ openssl genrsa -out tls.key 2048
Generating RSA private key, 2048 bit long modulus (2 primes)
.....+++++
............................................+++++
e is 65537 (0x010001)
samuel@p3420:~/src/nerves_system_x86_64/example/rootfs_overlay/etc$ openssl req -new -key tls.key -out tls.csr
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:MX
State or Province Name (full name) [Some-State]:SLP
Locality Name (eg, city) []:SLP
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Yeico
Organizational Unit Name (eg, section) []:Yeico
Common Name (e.g. server FQDN or YOUR name) []:Yeico
Email Address []:nerves@yeico.com

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
samuel@p3420:~/src/nerves_system_x86_64/example/rootfs_overlay/etc$ openssl x509 -req -days 365 -signkey tls.key -in tls.csr -out tls.crt
Signature ok
subject=C = MX, ST = SLP, L = SLP, O = Yeico, OU = Yeico, CN = Yeico, emailAddress = nerves@yeico.com
Getting Private key

iex(18)> cmd "df -h"                 
Filesystem                Size      Used Available Use% Mounted on
/dev/root               110.9M    110.9M         0 100% /
devtmpfs                  1.0M         0      1.0M   0% /dev
tmpfs                    49.0M      8.0K     48.9M   0% /tmp
tmpfs                    24.5M      4.0K     24.5M   0% /run
/dev/rootdisk0p1         15.1M      3.0K     15.1M   0% /boot/grub
/dev/rootdisk0p4        121.0K     18.0K     95.0K  16% /root

iex(15)> cmd "tune2fs -l /dev/rootdisk0p4"
tune2fs 1.46.5 (30-Dec-2021)
Filesystem volume name:   <none>
Last mounted on:          /root
Filesystem UUID:          3041e38d-615b-48d4-affb-a7787b5c4c39
Filesystem magic number:  0xEF53
Filesystem revision #:    1 (dynamic)
Filesystem features:      ext_attr resize_inode dir_index filetype extent flex_bg sparse_super uninit_bg dir_nlink extra_isize
Filesystem flags:         signed_directory_hash 
Default mount options:    user_xattr acl
Filesystem state:         not clean
Errors behavior:          Continue
Filesystem OS type:       Linux
Inode count:              16
Block count:              128
Reserved block count:     6
Overhead clusters:        7
Free blocks:              102
Free inodes:              0
First block:              1
Block size:               1024
Fragment size:            1024
Blocks per group:         8192
Fragments per group:      8192
Inodes per group:         16
Inode blocks per group:   2
Flex block group size:    16
Filesystem created:       Thu Jun 30 01:16:47 2022
Last mount time:          Thu Jun 30 01:29:12 2022
Last write time:          Thu Jun 30 01:29:12 2022
Mount count:              2
Maximum mount count:      -1
Last checked:             Thu Jun 30 01:16:47 2022
Check interval:           0 (<none>)
Lifetime writes:          33 kB
Reserved blocks uid:      0 (user root)
Reserved blocks gid:      0 (group root)
First inode:              11
Inode size:               128
Default directory hash:   half_md4
Directory Hash Seed:      2e30d0e4-1944-4766-b50b-78c3e2fa5a02
0
iex(20)> cmd "umount /root"
0
iex(23)> cmd "e2fsck -vfy /dev/rootdisk0p4"
e2fsck 1.46.5 (30-Dec-2021)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information

          15 inodes used (93.75%, out of 16)
           0 non-contiguous files (0.0%)
           0 non-contiguous directories (0.0%)
             # of inodes with ind/dind/tind blocks: 0/0/0
             Extent depth histogram: 6
          25 blocks used (19.53%, out of 128)
           0 bad blocks
           0 large files

           2 regular files
           4 directories
           0 character device files
           0 block device files
           0 fifos
           0 links
           0 symbolic links (0 fast symbolic links)
           0 sockets
------------
           6 files
0

iex(1)> cmd "ps"
  PID USER       VSZ STAT COMMAND
    1 root      2580 S    /sbin/init
    2 root         0 SW   [kthreadd]
    3 root         0 IW<  [rcu_gp]
    4 root         0 IW<  [rcu_par_gp]
    5 root         0 IW   [kworker/0:0-eve]
    6 root         0 IW<  [kworker/0:0H-kb]
    7 root         0 IW   [kworker/u2:0-fl]
    8 root         0 IW<  [mm_percpu_wq]
    9 root         0 SW   [ksoftirqd/0]
   10 root         0 IW   [rcu_preempt]
   11 root         0 SW   [migration/0]
   12 root         0 SW   [cpuhp/0]
   13 root         0 SW   [kdevtmpfs]
   14 root         0 IW<  [netns]
   15 root         0 SW   [rcu_tasks_kthre]
   16 root         0 IW   [kworker/0:1-eve]
   17 root         0 SW   [oom_reaper]
   18 root         0 IW<  [writeback]
   19 root         0 SW   [kcompactd0]
   20 root         0 IW   [kworker/u2:1]
   30 root         0 IW<  [kblockd]
   31 root         0 IW<  [ata_sff]
   32 root         0 SW   [watchdogd]
   33 root         0 SW   [kswapd0]
   34 root         0 IW<  [acpi_thermal_pm]
   35 root         0 IW<  [kworker/0:1H-kb]
   36 root         0 IW<  [ipv6_addrconf]
   37 root         0 IW   [kworker/0:2]
   38 root     1653m S    /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_ti
   39 root         0 SW   [jbd2/vda4-8]
   40 root         0 IW<  [ext4-rsv-conver]
   45 root      2548 S    erl_child_setup 1024
   60 root      2416 S    heart -pid 38 -ht 30
   64 root     80064 S    /usr/sbin/rngd
   66 root      2448 S    {nerves_runtime} kmsg_tailer
   67 root      2580 S    {nerves_runtime} uevent modprobe
   75 root      2420 S    /srv/erlang/lib/muontrap-1.0.0/priv/muontrap -- /usr
   76 root      2784 S    /usr/sbin/ntpd -n -S /srv/erlang/lib/nerves_time-0.4
   77 root      2592 S    /srv/erlang/lib/vintage_net-0.12.1/priv/if_monitor
   89 root      2420 S    /srv/erlang/lib/muontrap-1.0.0/priv/muontrap -- /sbi
   90 root      2784 S    /sbin/udhcpc -f -i eth0 -x hostname:wxkiosk-3456 -s
  110 root      2784 R    ps
0

iex(16)> cmd "ps -wlT"      
S   UID   PID  PPID   VSZ   RSS TTY   STIME TIME     CMD
S     0     1     0  2580   248 tty1  02:16 00:00:00 /sbin/init
S     0     2     0     0     0 0:0   02:16 00:00:00 [kthreadd]
I     0     3     2     0     0 0:0   02:16 00:00:00 [rcu_gp]
I     0     4     2     0     0 0:0   02:16 00:00:00 [rcu_par_gp]
I     0     5     2     0     0 0:0   02:16 00:00:00 [kworker/0:0-eve]
I     0     6     2     0     0 0:0   02:16 00:00:00 [kworker/0:0H-kb]
I     0     7     2     0     0 0:0   02:16 00:00:00 [kworker/u2:0-fl]
I     0     8     2     0     0 0:0   02:16 00:00:00 [mm_percpu_wq]
S     0     9     2     0     0 0:0   02:16 00:00:00 [ksoftirqd/0]
I     0    10     2     0     0 0:0   02:16 00:00:00 [rcu_preempt]
S     0    11     2     0     0 0:0   02:16 00:00:00 [migration/0]
S     0    12     2     0     0 0:0   02:16 00:00:00 [cpuhp/0]
S     0    13     2     0     0 0:0   02:16 00:00:00 [kdevtmpfs]
I     0    14     2     0     0 0:0   02:16 00:00:00 [netns]
S     0    15     2     0     0 0:0   02:16 00:00:00 [rcu_tasks_kthre]
I     0    16     2     0     0 0:0   02:16 00:00:00 [kworker/0:1-eve]
S     0    17     2     0     0 0:0   02:16 00:00:00 [oom_reaper]
I     0    18     2     0     0 0:0   02:16 00:00:00 [writeback]
S     0    19     2     0     0 0:0   02:16 00:00:00 [kcompactd0]
I     0    20     2     0     0 0:0   02:16 00:00:00 [kworker/u2:1]
I     0    30     2     0     0 0:0   02:16 00:00:00 [kblockd]
I     0    31     2     0     0 0:0   02:16 00:00:00 [ata_sff]
S     0    32     2     0     0 0:0   02:16 00:00:00 [watchdogd]
S     0    33     2     0     0 0:0   02:16 00:00:00 [kswapd0]
I     0    34     2     0     0 0:0   02:16 00:00:00 [acpi_thermal_pm]
I     0    35     2     0     0 0:0   02:16 00:00:00 [kworker/0:1H-kb]
I     0    36     2     0     0 0:0   02:16 00:00:00 [ipv6_addrconf]
I     0    37     2     0     0 0:0   02:16 00:00:00 [kworker/0:2]
S     0    38     1 1655m  114m tty1  02:16 00:00:00 /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp -sbwt none -sbwtdc
S     0    42     1 1655m  114m tty1  02:16 00:00:00 {sys_sig_dispatc} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp 
S     0    43     1 1655m  114m tty1  02:16 00:00:00 {sys_msg_dispatc} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp 
S     0    44     1 1655m  114m tty1  02:16 00:00:00 {async_1} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp -sbwt no
S     0    46     1 1655m  114m tty1  02:16 00:00:02 {1_scheduler} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp -sbw
S     0    47     1 1655m  114m tty1  02:16 00:00:00 {1_dirty_cpu_sch} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp 
S     0    48     1 1655m  114m tty1  02:16 00:00:00 {1_dirty_io_sche} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp 
S     0    49     1 1655m  114m tty1  02:16 00:00:00 {2_dirty_io_sche} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp 
S     0    50     1 1655m  114m tty1  02:16 00:00:00 {3_dirty_io_sche} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp 
S     0    51     1 1655m  114m tty1  02:16 00:00:00 {4_dirty_io_sche} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp 
S     0    52     1 1655m  114m tty1  02:16 00:00:00 {5_dirty_io_sche} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp 
S     0    53     1 1655m  114m tty1  02:16 00:00:00 {6_dirty_io_sche} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp 
S     0    54     1 1655m  114m tty1  02:16 00:00:00 {7_dirty_io_sche} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp 
S     0    55     1 1655m  114m tty1  02:16 00:00:00 {8_dirty_io_sche} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp 
S     0    56     1 1655m  114m tty1  02:16 00:00:00 {9_dirty_io_sche} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp 
S     0    57     1 1655m  114m tty1  02:16 00:00:00 {10_dirty_io_sch} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp 
S     0    58     1 1655m  114m tty1  02:16 00:00:00 {1_aux} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp -sbwt none
S     0    59     1 1655m  114m tty1  02:16 00:00:00 {0_poller} /srv/erlang/erts-13.0.2/bin/beam.smp -Bc -C multi_time_warp -sbwt n
S     0    39     2     0     0 0:0   02:16 00:00:00 [jbd2/vda4-8]
I     0    40     2     0     0 0:0   02:16 00:00:00 [ext4-rsv-conver]
S     0    45    38  2548  1428 0:0   02:16 00:00:00 erl_child_setup 1024
S     0    60    45  2416   244 0:0   02:16 00:00:00 heart -pid 38 -ht 30
S     0    64     1 80064  1460 0:0   02:16 00:00:00 /usr/sbin/rngd
S     0    71     1 80064  1460 0:0   02:16 00:00:06 /usr/sbin/rngd
S     0    66    45  2448   264 0:0   02:16 00:00:00 {nerves_runtime} kmsg_tailer
S     0    67    45  2580   260 0:0   02:16 00:00:00 {nerves_runtime} uevent modprobe
S     0    75    45  2420   248 0:0   02:16 00:00:00 /srv/erlang/lib/muontrap-1.0.0/priv/muontrap -- /usr/sbin/ntpd -n -S /srv/erla
S     0    76    75  2784   264 0:0   02:16 00:00:00 /usr/sbin/ntpd -n -S /srv/erlang/lib/nerves_time-0.4.5/priv/ntpd_script -p 0.p
S     0    77    45  2592   260 0:0   02:16 00:00:00 /srv/erlang/lib/vintage_net-0.12.1/priv/if_monitor
S     0    89    45  2420   248 0:0   02:16 00:00:00 /srv/erlang/lib/muontrap-1.0.0/priv/muontrap -- /sbin/udhcpc -f -i eth0 -x hos
S     0    90    89  2784   264 0:0   02:16 00:00:00 /sbin/udhcpc -f -i eth0 -x hostname:wxkiosk-3456 -s /srv/erlang/lib/beam_notif
R     0   126    45  2784   260 0:0   02:19 00:00:00 ps -wlT
0

iex(11)> cmd "/sbin/udevadm info -p /dev/char/13:64"
P: /devices/LNXSYSTM:00/LNXPWRBN:00/input/input0/event0
N: input/event0
E: DEVNAME=/dev/input/event0
E: DEVPATH=/devices/LNXSYSTM:00/LNXPWRBN:00/input/input0/event0
E: MAJOR=13
E: MINOR=64
E: SUBSYSTEM=input

0
iex(12)> cmd "/sbin/udevadm info -p /dev/char/13:65"
P: /devices/platform/i8042/serio0/input/input1/event1
N: input/event1
E: DEVNAME=/dev/input/event1
E: DEVPATH=/devices/platform/i8042/serio0/input/input1/event1
E: MAJOR=13
E: MINOR=65
E: SUBSYSTEM=input

0
iex(13)> cmd "/sbin/udevadm info -p /dev/char/13:66"
P: /devices/platform/i8042/serio1/input/input3/event2
N: input/event2
E: DEVNAME=/dev/input/event2
E: DEVPATH=/devices/platform/i8042/serio1/input/input3/event2
E: MAJOR=13
E: MINOR=66
E: SUBSYSTEM=input

0

samuel@p3420:~/src/nerves_system_x86_64/example$ ls -l /sys/dev/char/ | grep event3
lrwxrwxrwx 1 root root 0 jun 29 16:24 13:67 -> ../../devices/pci0000:00/0000:00:14.0/usb1/1-5/1-5:1.0/0003:046D:C077.0001/input/input6/event3
samuel@p3420:~/src/nerves_system_x86_64/example$ udevadm info -a -p dev/char/13:67

Udevadm info starts with the device specified by the devpath and then
walks up the chain of parent devices. It prints for every device
found, all possible attributes in the udev rules key format.
A rule to match, can be composed by the attributes of the device
and the attributes from one single parent device.

  looking at device '/devices/pci0000:00/0000:00:14.0/usb1/1-5/1-5:1.0/0003:046D:C077.0001/input/input6/event3':
    KERNEL=="event3"
    SUBSYSTEM=="input"
    DRIVER==""

  looking at parent device '/devices/pci0000:00/0000:00:14.0/usb1/1-5/1-5:1.0/0003:046D:C077.0001/input/input6':
    KERNELS=="input6"
    SUBSYSTEMS=="input"
    DRIVERS==""
    ATTRS{properties}=="0"
    ATTRS{uniq}==""
    ATTRS{inhibited}=="0"
    ATTRS{phys}=="usb-0000:00:14.0-5/input0"
    ATTRS{name}=="Logitech USB Optical Mouse"

  looking at parent device '/devices/pci0000:00/0000:00:14.0/usb1/1-5/1-5:1.0/0003:046D:C077.0001':
    KERNELS=="0003:046D:C077.0001"
    SUBSYSTEMS=="hid"
    DRIVERS=="hid-generic"
    ATTRS{country}=="00"

  looking at parent device '/devices/pci0000:00/0000:00:14.0/usb1/1-5/1-5:1.0':
    KERNELS=="1-5:1.0"
    SUBSYSTEMS=="usb"
    DRIVERS=="usbhid"
    ATTRS{bInterfaceClass}=="03"
    ATTRS{bInterfaceNumber}=="00"
    ATTRS{bNumEndpoints}=="01"
    ATTRS{bAlternateSetting}==" 0"
    ATTRS{bInterfaceProtocol}=="02"
    ATTRS{supports_autosuspend}=="1"
    ATTRS{authorized}=="1"
    ATTRS{bInterfaceSubClass}=="01"

  looking at parent device '/devices/pci0000:00/0000:00:14.0/usb1/1-5':
    KERNELS=="1-5"
    SUBSYSTEMS=="usb"
    DRIVERS=="usb"
    ATTRS{authorized}=="1"
    ATTRS{speed}=="1.5"
    ATTRS{configuration}==""
    ATTRS{rx_lanes}=="1"
    ATTRS{avoid_reset_quirk}=="0"
    ATTRS{maxchild}=="0"
    ATTRS{quirks}=="0x0"
    ATTRS{devnum}=="2"
    ATTRS{bDeviceProtocol}=="00"
    ATTRS{tx_lanes}=="1"
    ATTRS{bcdDevice}=="7200"
    ATTRS{bmAttributes}=="a0"
    ATTRS{bNumConfigurations}=="1"
    ATTRS{product}=="USB Optical Mouse"
    ATTRS{bConfigurationValue}=="1"
    ATTRS{bNumInterfaces}==" 1"
    ATTRS{bMaxPower}=="100mA"
    ATTRS{bMaxPacketSize0}=="8"
    ATTRS{bDeviceClass}=="00"
    ATTRS{ltm_capable}=="no"
    ATTRS{devpath}=="5"
    ATTRS{urbnum}=="374200"
    ATTRS{idVendor}=="046d"
    ATTRS{bDeviceSubClass}=="00"
    ATTRS{version}==" 2.00"
    ATTRS{idProduct}=="c077"
    ATTRS{manufacturer}=="Logitech"
    ATTRS{busnum}=="1"
    ATTRS{removable}=="removable"

  looking at parent device '/devices/pci0000:00/0000:00:14.0/usb1':
    KERNELS=="usb1"
    SUBSYSTEMS=="usb"
    DRIVERS=="usb"
    ATTRS{interface_authorized_default}=="1"
    ATTRS{serial}=="0000:00:14.0"
    ATTRS{bmAttributes}=="e0"
    ATTRS{manufacturer}=="Linux 5.13.0-51-generic xhci-hcd"
    ATTRS{bConfigurationValue}=="1"
    ATTRS{ltm_capable}=="no"
    ATTRS{speed}=="480"
    ATTRS{bMaxPower}=="0mA"
    ATTRS{maxchild}=="16"
    ATTRS{bMaxPacketSize0}=="64"
    ATTRS{busnum}=="1"
    ATTRS{idVendor}=="1d6b"
    ATTRS{devnum}=="1"
    ATTRS{avoid_reset_quirk}=="0"
    ATTRS{tx_lanes}=="1"
    ATTRS{removable}=="unknown"
    ATTRS{authorized_default}=="1"
    ATTRS{urbnum}=="68"
    ATTRS{idProduct}=="0002"
    ATTRS{bDeviceProtocol}=="01"
    ATTRS{authorized}=="1"
    ATTRS{configuration}==""
    ATTRS{bNumConfigurations}=="1"
    ATTRS{bNumInterfaces}==" 1"
    ATTRS{bDeviceSubClass}=="00"
    ATTRS{rx_lanes}=="1"
    ATTRS{version}==" 2.00"
    ATTRS{devpath}=="0"
    ATTRS{quirks}=="0x0"
    ATTRS{product}=="xHCI Host Controller"
    ATTRS{bcdDevice}=="0513"
    ATTRS{bDeviceClass}=="09"

  looking at parent device '/devices/pci0000:00/0000:00:14.0':
    KERNELS=="0000:00:14.0"
    SUBSYSTEMS=="pci"
    DRIVERS=="xhci_hcd"
    ATTRS{enable}=="1"
    ATTRS{local_cpus}=="ff"
    ATTRS{subsystem_vendor}=="0x1028"
    ATTRS{numa_node}=="-1"
    ATTRS{msi_bus}=="1"
    ATTRS{revision}=="0x31"
    ATTRS{ari_enabled}=="0"
    ATTRS{power_state}=="D0"
    ATTRS{dma_mask_bits}=="64"
    ATTRS{subsystem_device}=="0x06c7"
    ATTRS{local_cpulist}=="0-7"
    ATTRS{broken_parity_status}=="0"
    ATTRS{device}=="0xa12f"
    ATTRS{consistent_dma_mask_bits}=="64"
    ATTRS{irq}=="123"
    ATTRS{d3cold_allowed}=="1"
    ATTRS{dbc}=="disabled"
    ATTRS{class}=="0x0c0330"
    ATTRS{driver_override}=="(null)"
    ATTRS{vendor}=="0x8086"

  looking at parent device '/devices/pci0000:00':
    KERNELS=="pci0000:00"
    SUBSYSTEMS==""
    DRIVERS==""
    ATTRS{waiting_for_supplier}=="0"

sudo apt install libinput-tools
sudo libinput list-devices
Device:           Power Button
Kernel:           /dev/input/event2
Group:            1
Seat:             seat0, default
Capabilities:     keyboard 
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      n/a
Nat.scrolling:    n/a
Middle emulation: n/a
Calibration:      n/a
Scroll methods:   none
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   n/a
Rotation:         n/a

Device:           Power Button
Kernel:           /dev/input/event1
Group:            2
Seat:             seat0, default
Capabilities:     keyboard 
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      n/a
Nat.scrolling:    n/a
Middle emulation: n/a
Calibration:      n/a
Scroll methods:   none
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   n/a
Rotation:         n/a

Device:           Sleep Button
Kernel:           /dev/input/event0
Group:            3
Seat:             seat0, default
Capabilities:     keyboard 
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      n/a
Nat.scrolling:    n/a
Middle emulation: n/a
Calibration:      n/a
Scroll methods:   none
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   n/a
Rotation:         n/a

Device:           HDA NVidia HDMI/DP,pcm=3
Kernel:           /dev/input/event9
Group:            4
Seat:             seat0, default
Capabilities:     
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      n/a
Nat.scrolling:    n/a
Middle emulation: n/a
Calibration:      n/a
Scroll methods:   none
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   n/a
Rotation:         n/a

Device:           HDA NVidia HDMI/DP,pcm=7
Kernel:           /dev/input/event10
Group:            4
Seat:             seat0, default
Capabilities:     
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      n/a
Nat.scrolling:    n/a
Middle emulation: n/a
Calibration:      n/a
Scroll methods:   none
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   n/a
Rotation:         n/a

Device:           HDA NVidia HDMI/DP,pcm=8
Kernel:           /dev/input/event11
Group:            4
Seat:             seat0, default
Capabilities:     
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      n/a
Nat.scrolling:    n/a
Middle emulation: n/a
Calibration:      n/a
Scroll methods:   none
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   n/a
Rotation:         n/a

Device:           HDA NVidia HDMI/DP,pcm=9
Kernel:           /dev/input/event12
Group:            4
Seat:             seat0, default
Capabilities:     
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      n/a
Nat.scrolling:    n/a
Middle emulation: n/a
Calibration:      n/a
Scroll methods:   none
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   n/a
Rotation:         n/a

Device:           HDA NVidia HDMI/DP,pcm=10
Kernel:           /dev/input/event13
Group:            4
Seat:             seat0, default
Capabilities:     
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      n/a
Nat.scrolling:    n/a
Middle emulation: n/a
Calibration:      n/a
Scroll methods:   none
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   n/a
Rotation:         n/a

Device:           Logitech USB Optical Mouse
Kernel:           /dev/input/event3
Group:            5
Seat:             seat0, default
Capabilities:     pointer 
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      disabled
Nat.scrolling:    disabled
Middle emulation: disabled
Calibration:      n/a
Scroll methods:   button
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   flat *adaptive
Rotation:         n/a

Device:           Corsair Corsair Gaming K65 RGB RAPIDFIRE Keyboard 
Kernel:           /dev/input/event4
Group:            6
Seat:             seat0, default
Capabilities:     keyboard 
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      n/a
Nat.scrolling:    n/a
Middle emulation: n/a
Calibration:      n/a
Scroll methods:   none
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   n/a
Rotation:         n/a

Device:           Corsair Corsair Gaming K65 RGB RAPIDFIRE Keyboard  Keyboard
Kernel:           /dev/input/event5
Group:            6
Seat:             seat0, default
Capabilities:     keyboard pointer 
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      n/a
Nat.scrolling:    disabled
Middle emulation: n/a
Calibration:      n/a
Scroll methods:   none
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   n/a
Rotation:         n/a

Device:           HDA Intel PCH Headphone Mic
Kernel:           /dev/input/event14
Group:            4
Seat:             seat0, default
Capabilities:     
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      n/a
Nat.scrolling:    n/a
Middle emulation: n/a
Calibration:      n/a
Scroll methods:   none
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   n/a
Rotation:         n/a

Device:           HDA Intel PCH Line Out
Kernel:           /dev/input/event15
Group:            4
Seat:             seat0, default
Capabilities:     
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      n/a
Nat.scrolling:    n/a
Middle emulation: n/a
Calibration:      n/a
Scroll methods:   none
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   n/a
Rotation:         n/a

Device:           Dell WMI hotkeys
Kernel:           /dev/input/event8
Group:            7
Seat:             seat0, default
Capabilities:     keyboard 
Tap-to-click:     n/a
Tap-and-drag:     n/a
Tap drag lock:    n/a
Left-handed:      n/a
Nat.scrolling:    n/a
Middle emulation: n/a
Calibration:      n/a
Scroll methods:   none
Click methods:    none
Disable-w-typing: n/a
Accel profiles:   n/a
Rotation:         n/a

