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
