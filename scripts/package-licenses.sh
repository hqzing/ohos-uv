#!/bin/sh
set -eu

SRC=$1
REPO=$2
OUT=$3

mkdir -p "$OUT/native" "$SRC/target"
cd "$SRC"
cargo about generate --locked \
    --config "$REPO/licenses/about.toml" \
    --output-file "$OUT/THIRD_PARTY_LICENSES.html" \
    "$REPO/licenses/about.hbs"

METADATA=$SRC/target/uv-license-metadata.json
cargo metadata --format-version 1 --locked > "$METADATA"
trap 'rm -f "$METADATA"' EXIT

manifest() {
    jq -r --arg name "$1" 'first(.packages[] | select(.name == $name) | .manifest_path)' "$METADATA"
}

copy_native() {
    package=$1
    source=$2
    destination=$3
    root=$(dirname "$(manifest "$package")")
    if [ ! -f "$root/$source" ]; then
        echo "missing native license: $root/$source" >&2
        exit 1
    fi
    cp "$root/$source" "$OUT/native/$destination"
}

copy_native aws-lc-sys LICENSE aws-lc-sys.LICENSE
copy_native aws-lc-sys aws-lc/LICENSE aws-lc.LICENSE
copy_native aws-lc-sys aws-lc/third_party/fiat/LICENSE fiat-crypto.LICENSE
copy_native zstd-sys LICENSE zstd-sys.LICENSE
copy_native zstd-sys LICENSE.BSD-3-Clause zstd-sys.LICENSE.BSD-3-Clause
copy_native zstd-sys zstd/COPYING zstd.COPYING
copy_native zstd-sys zstd/LICENSE zstd.LICENSE
copy_native libmimalloc-sys LICENSE.txt libmimalloc-sys.LICENSE.txt
copy_native libmimalloc-sys c_src/mimalloc/v2/LICENSE mimalloc-v2.LICENSE
copy_native libmimalloc-sys c_src/mimalloc/v3/LICENSE mimalloc-v3.LICENSE

printf 'third-party licenses: %s\n' "$OUT"
