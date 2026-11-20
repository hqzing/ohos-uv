#!/bin/sh
# Smoke-test a freshly built uv: verify its OHOS target and libc, and select
# regular and free-threaded ohos entries from python-downloads JSON.
set -eu

UV=$1

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
echo OK
