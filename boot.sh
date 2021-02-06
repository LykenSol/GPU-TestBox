#!/usr/bin/env bash

# NOTE(eddyb) most of this is copied from https://nixos.wiki/wiki/Netboot

nix build -f netboot.nix --out-link ./netboot

cmdline=$(grep -o 'init=.*' ./netboot/netboot.ipxe | sed 's/ initrd=initrd//')

if [ -n "$GPU_TEST_BOX_MAC" ]; then
  wol $GPU_TEST_BOX_MAC
fi

if [ -n "$GPU_TEST_BOX_IP" ]; then
  ssh nixos@$GPU_TEST_BOX_IP -o StrictHostKeyChecking=no sudo reboot
fi

# NOTE(eddyb) required configuration, under `networking.firewall`
# (or `networking.firewall.interfaces.<specific interface name>`):
#   allowedTCPPorts = [ 42069 ];
#   allowedUDPPorts = [ 67 69 4011 ];
sudo pixiecore boot ./netboot/bzImage ./netboot/initrd \
  --cmdline "$cmdline" \
  --debug --dhcp-no-bind --port 42069 --status-port 42069
