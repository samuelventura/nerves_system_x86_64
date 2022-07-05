#/bin/bash -ex

# mix archive.install hex nerves_bootstrap
# mix nerves.system.shell
# make menuconfig
# make savedefconfig
# make
# exit

rm -fr deps/ .nerves/ _build/
mix deps.get
mix compile
mix nerves.artifact
ls
mv *.tar.gz ~/.nerves/artifacts/
