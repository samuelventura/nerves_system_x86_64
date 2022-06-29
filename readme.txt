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

#from https://github.com/nerves-project/nerves_system_x86_64/issues/129
qemu-system-x86_64 \
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

#SSH works on first boot (not sure if delayed)
ssh localhost -p 8022
NervesMOTD.print

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
- Boots in brix without nic detection and same locale warning
- Waiting for root device PARTUUID=04030201-02... (for certain qemu cmd line params)
- Error handling file /root/.cache/erlang-history/erlang-shell-log.siz. Reason: enoent
- kex_exchange_identification: read: Connection reset by peer (not happening here)
- erlinit: Cannot mount /dev/rootdisk0p4 at /root: Invalid argument (FIXED ON REBOOT)
- warning: the VM is running with native name encoding of latin1 which may cause Elixir 
    to malfunction as it expects utf8. Please ensure your locale is set to UTF-8
    (which can be verified by runnig "locale" in your shell)
