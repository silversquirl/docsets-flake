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

          buildPhase = ''
            runHook preBuild

            echo 'Copy icons and metadata'
            cp -rT "$extra" .

            echo 'Create search index'
            db=Contents/Resources/docSet.dsidx
            #chmod +w "$db"
            hasSearchIndex=$(sqlite3 "$db" '
              SELECT 1 FROM sqlite_master WHERE type="table" AND name="searchIndex" COLLATE NOCASE;
            ')
            if [ -n "$hasSearchIndex" ]; then
              sqlite3 "$db" '
                CREATE INDEX IF NOT EXISTS __zi_name0001 ON searchIndex (name COLLATE NOCASE);
              '
            else
              sqlite3 "$db" '
                --CREATE INDEX IF NOT EXISTS __zi_name0001 ON ztoken (ztokenname COLLATE NOCASE);
                CREATE VIEW IF NOT EXISTS searchIndex AS
                  SELECT
                    ztokenname AS name,
                    ztypename AS type,
                    zpath AS path,
                    zanchor AS fragment
                  FROM ztoken
                  INNER JOIN ztokenmetainformation
                    ON ztoken.zmetainformation = ztokenmetainformation.z_pk
                  INNER JOIN zfilepath
                    ON ztokenmetainformation.zfile = zfilepath.z_pk
                  INNER JOIN ztokentype
                    ON ztoken.ztokentype = ztokentype.z_pk;
              '
            fi

            runHook postBuild
          '';

          doCheck = true;
          checkPhase = ''
            runHook preCheck
            sqlite3 "$db" 'SELECT * FROM searchIndex LIMIT 1;'
            runHook postCheck
          '';

          installPhase = ''
            runHook preInstall
            cp -r . "$out"
            runHook postInstall
          '';
        };
    in
      builtins.mapAttrs mkDocset (import ./docsets));
  };
}
