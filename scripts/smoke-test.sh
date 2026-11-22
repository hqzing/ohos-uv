#!/bin/sh
# Smoke-test a freshly built uv: verify its OHOS target and libc, and select
# regular and free-threaded ohos entries from python-downloads JSON.
# Pass an OHOS Python as $2 to also test exact build API wheel tags.
set -eu

UV=$1
PYTHON=${2:-}

"$UV" --version
"$UV" --version | grep -q 'linux-ohos' || {
    echo "FAIL: uv --version does not report the ohos triple" >&2
    exit 1
}

TMP=${TMPDIR:-/tmp}/uv-smoke-$$
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

# Minimal uv python-downloads metadata with one ohos entry and one musl
# entry for the same version: only the ohos one may match this platform.
cat > "$TMP/downloads.json" <<'EOF'
{
  "cpython-3.14.7-linux-aarch64-ohos": {
    "name": "cpython",
    "arch": {"family": "aarch64", "variant": null},
    "os": "linux",
    "libc": "ohos",
    "major": 3,
    "minor": 14,
    "patch": 7,
    "prerelease": null,
    "url": "https://example.invalid/cpython-3.14.7+20260912-aarch64-unknown-linux-ohos-install_only.tar.gz",
    "sha256": null,
    "variant": null,
    "build": null
  },
  "cpython-3.14.7+freethreaded-linux-aarch64-ohos": {
    "name": "cpython",
    "arch": {"family": "aarch64", "variant": null},
    "os": "linux",
    "libc": "ohos",
    "major": 3,
    "minor": 14,
    "patch": 7,
    "prerelease": null,
    "url": "https://github.com/ohos-python/ohos-python/releases/download/20260912/cpython-3.14.7%2B20260912-aarch64-unknown-linux-ohos-freethreaded-install_only.tar.gz",
    "sha256": null,
    "variant": "freethreaded",
    "build": "20260912"
  },
  "cpython-3.14.7-linux-aarch64-musl": {
    "name": "cpython",
    "arch": {"family": "aarch64", "variant": null},
    "os": "linux",
    "libc": "musl",
    "major": 3,
    "minor": 14,
    "patch": 7,
    "prerelease": null,
    "url": "https://example.invalid/cpython-3.14.7+20260912-aarch64-unknown-linux-musl-install_only.tar.gz",
    "sha256": null,
    "variant": null,
    "build": null
  }
}
EOF

UV_PYTHON_DOWNLOADS_JSON_URL="file://$TMP/downloads.json" \
    "$UV" python list --only-downloads > "$TMP/list.txt"

grep -q 'cpython-3.14.7-linux-aarch64-ohos' "$TMP/list.txt" || {
    echo "FAIL: ohos download entry not matched on this platform" >&2
    cat "$TMP/list.txt" >&2
    exit 1
}
if grep -q 'musl' "$TMP/list.txt"; then
    echo "FAIL: musl download entry must not match ohos" >&2
    cat "$TMP/list.txt" >&2
    exit 1
fi
echo "platform detection: linux-aarch64-ohos, musl entry correctly excluded"

UV_PYTHON_DOWNLOADS_JSON_URL="file://$TMP/downloads.json" \
    "$UV" python list --only-downloads '3.14+freethreaded' > "$TMP/free-list.txt"
grep -q 'cpython-3.14.7+freethreaded-linux-aarch64-ohos' "$TMP/free-list.txt" || {
    echo "FAIL: free-threaded download entry not selected" >&2
    cat "$TMP/free-list.txt" >&2
    exit 1
}
if grep -q 'cpython-3.14.7-linux-aarch64-ohos' "$TMP/free-list.txt"; then
    echo "FAIL: GIL-enabled entry must not match a free-threaded request" >&2
    cat "$TMP/free-list.txt" >&2
    exit 1
fi
echo "free-threaded variant selection: OK"

if [ -z "$PYTHON" ]; then
    echo OK
    exit 0
fi

BUILD_API=$("$PYTHON" -c 'import sysconfig; print(sysconfig.get_config_var("OHOS_API_LEVEL"))')
case $BUILD_API in
    ''|*[!0-9]*)
        echo "FAIL: invalid OHOS build API: $BUILD_API" >&2
        exit 1
        ;;
esac

"$PYTHON" - "$TMP" "$BUILD_API" <<'PY'
import sys
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

root = Path(sys.argv[1])
api_level = int(sys.argv[2])
tag = f"ohos_{api_level}_aarch64"
filename = f"ohos_smoke-0.1-py3-none-{tag}.whl"
with ZipFile(root / filename, "w", compression=ZIP_DEFLATED) as wheel:
    wheel.writestr("ohos_smoke/__init__.py", 'API_TAG = "ohos"\n')
    wheel.writestr(
        "ohos_smoke-0.1.dist-info/METADATA",
        "Metadata-Version: 2.1\nName: ohos-smoke\nVersion: 0.1\n",
    )
    wheel.writestr(
        "ohos_smoke-0.1.dist-info/WHEEL",
        f"Wheel-Version: 1.0\nGenerator: ohos-uv-smoke\n"
        f"Root-Is-Purelib: false\nTag: py3-none-{tag}\n",
    )
    wheel.writestr("ohos_smoke-0.1.dist-info/RECORD", "")
PY

"$UV" venv --python "$PYTHON" "$TMP/venv"
EXACT_WHEEL=$TMP/ohos_smoke-0.1-py3-none-ohos_${BUILD_API}_aarch64.whl
"$UV" pip install --python "$TMP/venv/bin/python" "$EXACT_WHEEL"
"$TMP/venv/bin/python" -c 'import ohos_smoke; assert ohos_smoke.API_TAG == "ohos"'
echo "exact OHOS build API wheel: ohos_${BUILD_API}_aarch64 OK"
echo OK
