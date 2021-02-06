# NOTE(eddyb) most of this is copied from https://nixos.wiki/wiki/Netboot

let
  bootSystem = import <nixpkgs/nixos> {
    configuration = { config, pkgs, lib, ... }: with lib; {
      imports = [
        <nixpkgs/nixos/modules/installer/netboot/netboot-base.nix>
      ];

      nixpkgs.config.allowUnfree = true;

      hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.vulkan_beta;

      services.xserver = {
        enable = true;
        videoDrivers = [ "nvidia" ];
        libinput.enable = true;
        displayManager.sddm = {
          enable = true;
          settings = {
            Autologin = {
              User = "nixos";
              Session = "plasma.desktop";
            };
          };
        };
        desktopManager.plasma5.enable = true;
      };

      environment.systemPackages = with pkgs; [
        vulkan-tools
      ];

      users.users.nixos.openssh.authorizedKeys.keyFiles = attrValues (
        mapAttrs (user: hash: "${builtins.fetchurl {
          url = "https://github.com/${user}.keys";
          sha256 = hash;
        }}") {
          # HACK(eddyb) make the list of users configurable.
          eddyb = "0jlja2icnskalgxn9pzhcn6rvzlypwpv299ayhaf3p59c3p5iahc";
        }
      );
    };
  };

  pkgs = import <nixpkgs> {};
in
  # FIXME(eddyb) this is kind of silly, it could generate `boot.sh` instead
  pkgs.symlinkJoin {
    name = "netboot";
    paths = with bootSystem.config.system.build; [
      netbootRamdisk
      kernel
      netbootIpxeScript
    ];
    preferLocalBuild = true;
  }
