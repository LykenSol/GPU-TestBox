#!/usr/bin/env bash

# NOTE(eddyb) most of this is copied from https://nixos.wiki/wiki/Netboot
set -euo pipefail

nix-build netboot.nix --out-link ./netboot

init=$(grep -ohP 'init=\S+' ./netboot/netboot.ipxe)

# NOTE(eddyb) required configuration, under `networking.firewall`
# (or `networking.firewall.interfaces.<specific interface name>`):
#   allowedTCPPorts = [ 42069 ];
#   allowedUDPPorts = [ 67 69 4011 ];
sudo pixiecore boot ./netboot/bzImage ./netboot/initrd \
  --cmdline "$init loglevel=4" \
  --debug --dhcp-no-bind --port 42069 --status-port 42069
