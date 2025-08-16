{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: {
    packages =
      builtins.mapAttrs
      (system: pkgs:
        builtins.mapAttrs
        (name: feed:
          pkgs.fetchzip {
            name = "${name}.docset";
            inherit (feed) url hash;
          })
        (import ./feeds.nix))
      nixpkgs.legacyPackages;
  };
}
