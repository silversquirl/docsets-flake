{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    forAllSystems = f: builtins.mapAttrs f nixpkgs.legacyPackages;
  in {
    packages = forAllSystems (system: pkgs: let
      mkDocset = name: info:
        pkgs.stdenvNoCC.mkDerivation {
          name = "${name}.docset";
          src = pkgs.fetchzip {inherit (info) url hash;};
          inherit (info) extra;
          nativeBuildInputs = [pkgs.sqlite];
          buildCommand = ''
            mkdir -p "$out"
            echo "Copying docset"
            cp -rT "$src" "$out"
            echo "Adding icons and metadata"
            cp -rT "$extra" "$out"
            echo "Creating search index"
            cp "$src/Contents/Resources/docSet.dsidx" docSet.dsidx
            chmod +w docSet.dsidx
            sqlite3 docSet.dsidx '
              CREATE INDEX IF NOT EXISTS __zi_name0001 ON searchIndex (name COLLATE NOCASE);
            '
            chmod +w "$out/Contents/Resources/docSet.dsidx"
            cp docSet.dsidx "$out/Contents/Resources/"
          '';
        };
    in
      builtins.mapAttrs mkDocset (import ./docsets));
  };
}
