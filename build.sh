#!/bin/sh
# Build uv for OpenHarmony (aarch64-unknown-linux-ohos), natively inside a
# DockerHarmony container.
#
#   ./build.sh [uv-version] [--jobs N]
#
# Applies patches/*.patch to the upstream uv release and builds with the
# toolchain from Harmonybrew (rust, cmake, git). Produces
# dist/uv-<version>-aarch64-unknown-linux-ohos.tar.gz (+ SHA256SUMS).
set -eu

REPO=$(cd "$(dirname "$0")" && pwd)
VERSION=$(cat "$REPO/version.txt")
REVISION=$(cat "$REPO/revision.txt")
CARGO_PROFILE_RELEASE_LTO=${CARGO_PROFILE_RELEASE_LTO:-off}
export CARGO_PROFILE_RELEASE_LTO
JOBS=$(nproc 2>/dev/null || echo 4)

while [ $# -gt 0 ]; do
    case "$1" in
        --jobs) JOBS=$2; shift 2 ;;
        -*)     echo "unknown option: $1" >&2; exit 2 ;;
        *)      VERSION=$1; shift ;;
    esac
done

PACKAGE_VERSION=$VERSION-$REVISION
TRIPLE=aarch64-unknown-linux-ohos
WORK=$REPO/.build/uv-$VERSION
SRC=$WORK/src
DIST=$REPO/dist

log() { printf '\n=== %s ===\n' "$*"; }

log "bootstrap build environment (Harmonybrew)"
"$REPO/scripts/setup-env.sh"
# setup-env.sh runs in a subshell; pick up brew on PATH here as well.
BREW=/storage/Users/currentUser/.harmonybrew/bin/brew
if [ ! -x "$BREW" ]; then
    "$REPO/scripts/setup-env.sh"
fi
eval "$("$BREW" shellenv)"
brew install -y devel-base git rust cmake jq
if ! command -v cargo-about >/dev/null 2>&1; then
    cargo install --locked --features cli cargo-about@0.9.3
fi

log "fetch uv $VERSION"
mkdir -p "$WORK" "$DIST"
if [ ! -d "$SRC" ]; then
    git clone --depth 1 --branch "$VERSION" https://github.com/astral-sh/uv "$SRC"
fi
cd "$SRC"

log "apply ohos patches"
for p in "$REPO"/patches/*.patch; do
    if git apply --check "$p" 2>/dev/null; then
        git apply "$p"
        echo "applied $(basename "$p")"
    elif git apply --reverse --check "$p" 2>/dev/null; then
        echo "$(basename "$p") already applied"
    else
        echo "error: patch $(basename "$p") does not apply to uv $VERSION" >&2
        exit 1
    fi
done

log "inject ohos download metadata"
# Embed the ohos-python catalog so `uv python install` works without
# UV_PYTHON_DOWNLOADS_JSON_URL. Canonical GitHub URLs are required for
# CPYTHON_DOWNLOADS_URL_PREFIX and optional AtomGit mirror rewriting.
curl -fL --retry 3 \
    https://github.com/ohos-python/ohos-python/releases/latest/download/python-downloads.json \
    > "$SRC/crates/uv-python-managed/download-metadata.json"

log "cargo build --release -p uv (jobs=$JOBS)"
# cmake is needed by aws-lc-sys; jemalloc is excluded on ohos by the patch.
cargo build --release --locked -p uv --jobs "$JOBS"

BINS=uv
[ -f target/release/uvx ] && BINS="uv uvx"

log "smoke test"
"$REPO/scripts/smoke-test.sh" "$SRC/target/release/uv"

log "package"
rm -rf "$WORK/package"
mkdir -p "$WORK/package/uv"
"$REPO/scripts/package-licenses.sh" "$SRC" "$REPO" "$WORK/package/uv/licenses"
for b in $BINS; do cp "target/release/$b" "$WORK/package/uv/$b"; done
cp LICENSE-APACHE LICENSE-MIT "$WORK/package/uv/licenses/"
ARTIFACT=uv-$PACKAGE_VERSION-$TRIPLE.tar.gz
tar -C "$WORK/package" -czf "$DIST/$ARTIFACT" uv
(cd "$DIST" && sha256sum "$ARTIFACT" >> SHA256SUMS)
echo
echo "artifact: $DIST/$ARTIFACT"
