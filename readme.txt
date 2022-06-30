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
    -net user,hostfwd=tcp::8022-:22,hostfwd=tcp::8081-:8081 \
    -serial stdio

#works as well
sudo qemu-system-x86_64 \
    -drive file=/dev/sdc,if=virtio,format=raw \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::8022-:22 \
    -serial stdio

#SSH works on first boot (not sure if delayed)
ssh localhost -p 8022
NervesMOTD.print

#https://manpages.ubuntu.com/manpages/bionic/man1/broadwayd.1.html
cmd "/usr/bin/broadwayd :1"
#Gtk-WARNING cannot open display:
System.cmd("gtk3-demo", [], env: [{"XDG_RUNTIME_DIR", "/root"}, {"GDK_BACKEND", "broadway"}, {"BROADWAY_DISPLAY", ":1"}])
#GLib-GIO-ERROR: Settings schema 'org.gnome.desktop.interface' is not installed
#requires package gsettings-desktop-schemas
#Failed to create /root/.config/glib-2.0/settings: No space left on device
System.cmd("granite-demo", [], env: [{"XDG_RUNTIME_DIR", "/root"}, {"GDK_BACKEND", "broadway"}, {"BROADWAY_DISPLAY", ":1"}])
#EGLUT failed to initialize native display
System.cmd("es2gears_wayland", [], env: [{"XDG_RUNTIME_DIR", "/data"}, {"GDK_BACKEND", "broadway"}, {"BROADWAY_DISPLAY", ":1"}])
File.write("/root/touch.txt", "touch")
{:error, :enospc}
http://127.0.0.1:8081/
#works on kubuntu, both demos crash on qemu

#https://elinux.org/images/9/93/The-Modern-Linux-Graphics-Stack-on-Embedded-Systems-Michael-Tretter-Pengutronix.pdf
#https://www.youtube.com/watch?v=GOvbEoOBH98
System.cmd("weston", ["--tty=/dev/tty7", "--backend=fbdev-backend.so"], env: [{"XDG_RUNTIME_DIR", "/data"}])
System.cmd("weston", ["--tty=/dev/tty7"], env: [{"XDG_RUNTIME_DIR", "/data"}])

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
