#!/bin/bash
rm /tmp/temp.gpg
gpg  --keyring /tmp/temp.gpg  --no-default-keyring --import "$@"
gpg  --keyring /tmp/temp.gpg  --no-default-keyring  --export -a >/tmp/1.gpg
cp /tmp/1.gpg "$@"
