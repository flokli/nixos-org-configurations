{ config, pkgs, lib, inputs, ... }:

{
  imports =
    [
      ./hardware.nix
      inputs.srvos.nixosModules.server
      inputs.srvos.nixosModules.hardware-hetzner-online-amd
      ../../modules/first-time-contribution-tagger.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.loader.grub.mirroredBoots = [
    { path = "/boot-1"; devices = [ "/dev/disk/by-id/nvme-SAMSUNG_MZQL23T8HCLS-00A07_S64HNJ0T508051" ]; }
    { path = "/boot-2"; devices = [ "/dev/disk/by-id/nvme-SAMSUNG_MZQL23T8HCLS-00A07_S64HNJ0T508053" ]; }
  ];
  boot.loader.grub.useOSProber = true;

  networking = {
    hostName = "caliban";
    domain = "nixos.org";
    hostId = "745b334a";
  };

  disko.devices = import ./disko.nix;

  # Set your time zone.
  time.timeZone = "UTC";

  environment.systemPackages = with pkgs; [
    neovim
  ];

  services.openssh.enable = true;

  networking.firewall.allowedTCPPorts = [ ];
  networking.firewall.allowedUDPPorts = [ ];

  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f9:5a:186c::2";

  users.users.root.openssh.authorizedKeys.keys = (import ../../../ssh-keys.nix).infra;

  system.stateVersion = "23.05";

}

