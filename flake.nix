{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    forAllSystems = f: builtins.mapAttrs f nixpkgs.legacyPackages;
  in {
    packages = forAllSystems (system: pkgs: let
      mkDocset = name: info:
        pkgs.runCommand "${name}.docset" {
          src = pkgs.fetchzip {inherit (info) url hash;};
          inherit (info) extra;
        } ''
          mkdir -p "$out"
          cp -rT "$src" "$out"
          cp -rT "$extra" "$out"
        '';
    in
      builtins.mapAttrs mkDocset (import ./docsets));
  };
}
