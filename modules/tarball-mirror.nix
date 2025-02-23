# This module mirrors most tarballs reachable from Nixpkgs's
# release.nix to the content-addressed tarball cache at
# tarballs.nixos.org.
#
# Note: this service expects AWS credentials for uploading to
# s3://nixpkgs-tarballs in /home/tarball-mirror/.aws/credentials.

{ config, lib, pkgs, ... }:

with lib;

let
  # Determine the NixPkgs branch to mirror from.
  # We take the current pirmary stable release.
  inherit (import ../channels.nix) channels;
  branches = lib.filter (p: p != null) (
    lib.mapAttrsToList
      (name: v: if v.variant or null == "primary" && v.status or null == "stable"
        then name else null)
      (import ../channels.nix).channels
  );
  branch = assert lib.length branches == 1; head branches;
in

{

  users.extraUsers.tarball-mirror =
    { description = "Nixpkgs tarball mirroring user";
      home = "/home/tarball-mirror";
      isNormalUser = true;
    };

  systemd.services.mirror-tarballs =
    { description = "Mirror Nixpkgs Tarballs";
      path  = [ config.nix.package pkgs.git pkgs.bash ];
      environment.NIX_REMOTE = "daemon";
      serviceConfig.User = "tarball-mirror";
      serviceConfig.Type = "oneshot";
      serviceConfig.PrivateTmp = true;
      script =
        ''
          dir=/home/tarball-mirror/nixpkgs
          if ! [[ -e $dir ]]; then
            git clone https://github.com/NixOS/nixpkgs.git $dir
          fi
          cd $dir
          git remote update origin
          git checkout origin/${branch}
          # FIXME: use IAM role.
          export AWS_ACCESS_KEY_ID=$(sed 's/aws_access_key_id=\(.*\)/\1/ ; t; d' ~/.aws/credentials)
          export AWS_SECRET_ACCESS_KEY=$(sed 's/aws_secret_access_key=\(.*\)/\1/ ; t; d' ~/.aws/credentials)
          NIX_PATH=nixpkgs=. ./maintainers/scripts/copy-tarballs.pl \
            --expr 'import <nixpkgs/maintainers/scripts/all-tarballs.nix>' \
            --exclude 'registry.npmjs.org|mirror://kde|mirror://xorg|mirror://kernel|mirror://hackage|mirror://gnome|mirror://apache|mirror://mozilla|pypi.python.org'
        '';
      startAt = "05:30";
    };

}
