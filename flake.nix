{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: {
    packages =
      builtins.mapAttrs
      (system: pkgs: builtins.mapAttrs (name: pkgs.fetchzip) (import ./feeds.nix))
      nixpkgs.legacyPackages;
  };
}
