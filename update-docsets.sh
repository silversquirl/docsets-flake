#!/usr/bin/env nix
#!nix shell
#!nix nixpkgs#alejandra
#!nix nixpkgs#bash
#!nix nixpkgs#busybox
#!nix nixpkgs#curl
#!nix nixpkgs#jq
#!nix nixpkgs#nix
#!nix -i --inputs-from . -c bash
# shellcheck shell=bash disable=SC2266

index_url=https://api.zealdocs.org/v1/docsets
download_base_url=https://kapeli.com/feeds

err() {
    printf '\e[31merror: failed to %s docset %s\e[0m\n' "$1" "$2" >&2
    exit 1
}
fetch_docset() {
    IFS=' ' read -r name icon icon2x meta

    url=$download_base_url/$name.tgz
    shasum=$(nix-prefetch-url --unpack --type sha256 "$url" 2>/dev/null) || err fetch "$name"
    hash=$(nix-hash --to-sri --type sha256 "$shasum") || err hash "$name"
    printf '"%s" = { extra = ./%s; url = "%s"; hash = "%s"; };\n' "$name" "$name" "$url" "$hash"

    out=docsets/$name
    mkdir -p "$out"
    base64 -d <<<"$icon" >"$out/icon.png" || err 'decode icon' "$name"
    base64 -d <<<"$icon2x" >"$out/icon@2x.png" || err 'decode icon@2x' "$name"
    echo "$meta" >"$out/meta.json"
}

rm -rf docsets
mkdir -p docsets

mapfile -t docsets < <(curl -sL "$index_url" | jq -r '
    def metadata:
        {
            name, title, feed_url, urls, extra,
            version: .versions[0],
            revision: .revision | select(. > 0),
        }[] //= empty;

    [.[]] | sort_by(.name)[] |
    "\(.name) \(.icon) \(.icon2x) \(.metadata | @json)"
')

finished=0
status() {
    fmt='\e[K  %d/%d \t%s\r'
    [ -t 2 ] || fmt='%d/%d\t%s\n'
    # shellcheck disable=SC2059
    printf "$fmt" "$finished" "${#docsets[@]}" "$1" >&2
}

{
    echo '{'
    for docset_json in "${docsets[@]}"; do
        status "${docset_json%% *}"
        (fetch_docset) <<<"$docset_json"
        ((finished += 1))
    done
    echo '}'
} >docsets/default.nix
status
echo

alejandra -q docsets/default.nix
