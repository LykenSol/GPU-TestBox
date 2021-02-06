# NOTE(eddyb) most of this is copied from https://nixos.wiki/wiki/Netboot

let
  bootSystem = import <nixpkgs/nixos> {
    configuration = { config, pkgs, lib, ... }: with lib; {
      imports = [
        <nixpkgs/nixos/modules/installer/netboot/netboot-base.nix>
      ];

      # HACK(eddyb) `hardware.{amdgpu,nvidia}` only work with `"amdgpu"`/`"nvidia"`
      # as entries in `services.xserver.videoDrivers`.
      services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];

      nixpkgs.config.allowUnfree = true;
      hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.vulkan_beta.overrideAttrs ({...}: {
        # HACK(eddyb) `libGLX_nvidia.so` needs X while `libEGL_nvidia.so` is portable.
        preFixup = ''
          sed -i 's/libGLX_nvidia/libEGL_nvidia/' {$lib32,$out}/share/vulkan/icd.d/nvidia_icd*.json
        '';
      });

      # Headless Vulkan (Nvidia+RADV)
      boot.kernelParams = [ "radeon.si_support=0" "amdgpu.si_support=1" ];
      boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_drm" ];
      services.udev.extraRules = ''
        # HACK(eddyb) harcoding 0 instead of %n because nvidia GPUs have their own numbering
        KERNEL=="card*", SUBSYSTEM=="drm", DRIVERS=="nvidia", RUN+="${pkgs.runtimeShell} -c 'mknod -m 666 /dev/nvidia0 c $$(grep nvidia-frontend /proc/devices | cut -d \  -f 1) 0'"
      '';
      hardware.nvidia.prime = {
        offload.enable = true;
        # HACK(eddyb) these are needed to avoid an assertion but aren't actually
        # used outside of adding configuration to X (which is disabled anyway).
        nvidiaBusId = "N/A";
        intelBusId = "N/A";
      };
      hardware.opengl = {
        enable = true;
        driSupport32Bit = true;
      };

      # Graphical (X11) configuration.
      # services.xserver = {
      #   enable = true;
      #   libinput.enable = true;
      #   displayManager.sddm = {
      #     enable = true;
      #     settings = {
      #       Autologin = {
      #         User = "nixos";
      #         Session = "plasma.desktop";
      #       };
      #     };
      #   };
      #   desktopManager.plasma5.enable = true;
      # };

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
