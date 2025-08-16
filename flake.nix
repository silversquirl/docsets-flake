{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: {
    packages =
      builtins.mapAttrs
      (system: pkgs:
        builtins.mapAttrs
        (name: docset:
          pkgs.fetchzip {
            name = "${name}.docset";
            inherit (docset) url hash;
          })
        (import ./docsets.nix))
      nixpkgs.legacyPackages;
  };
}
