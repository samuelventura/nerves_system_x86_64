#/bin/bash -ex

rsync -avr build:.nerves/artifacts/*.tar.gz ~/.nerves/artifacts/
