#!/usr/bin/env nix
#!nix shell -i --inputs-from . nixpkgs#bash nixpkgs#busybox nixpkgs#curl nixpkgs#nix nixpkgs#alejandra -c bash
# shellcheck shell=bash disable=SC2266
set -e
trap wait INT TERM

max_jobs=16
out=feeds.nix
tarball=https://github.com/Kapeli/feeds/archive/refs/heads/master.tar.gz
feed_base_url=https://kapeli.com/feeds

fetch_feed_inner() {
    name=$1
    url=$feed_base_url/$name.tgz
    shasum=$(nix-prefetch-url --unpack --type sha256 "$url" 2>/dev/null) || return
    hash=$(nix-hash --to-sri --type sha256 "$shasum") || return

    exec >>"$out"
    flock 1
    printf '"%s" = { url = "%s"; hash = "%s"; };\n' "$name" "$url" "$hash"
}
fetch_feed() {
    fetch_feed_inner "$@" ||
        printf '\e[31merror: failed to fetch feed %s\e[0m\n' "$1" >&2
}

mapfile -t filenames < <(curl -sL "$tarball" | tar tz | sed -E 's/.*\/([^.]+)\.xml/\1/;t;d')

finished=0
status() {
    jobs -p | printf '\r\e[K  %d+%d/%d\r' "$finished" "$(wc -l)" "${#filenames[@]}" >&2
}

: >"$out"
for name in "${filenames[@]}"; do
    status
    while jobs -p | [ "$(wc -l)" -ge "$max_jobs" ]; do
        wait -n
        ((finished += 1))
    done
    fetch_feed "$name" &
done
status

wait
status
echo

sorted=$(sort <"$out")
printf '%s\n' \{ "$sorted" \} >"$out"

alejandra -q "$out"
