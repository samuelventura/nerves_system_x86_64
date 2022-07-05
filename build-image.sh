#/bin/bash -ex

# mix archive.install hex nerves_bootstrap
# mix nerves.system.shell
# make menuconfig
# make savedefconfig
# make
# exit

cd example
rm -fr deps/ .nerves/ _build/
MIX_TARGET=x86_64 mix deps.get
MIX_TARGET=x86_64 mix firmware
MIX_TARGET=x86_64 mix burn -d image.img
chown samuel:samuel image.img
truncate -s 1G image.img
