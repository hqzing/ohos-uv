#!/bin/sh
# Bootstrap the build environment inside a bare DockerHarmony container
# (ghcr.io/hqzing/dockerharmony): install ohos-zsh, then Harmonybrew, then
# put brew on PATH. Idempotent — does nothing when brew is already present.
# Helper tools live in .tools/ inside the repo; nothing is written elsewhere.
set -eu

REPO=$(cd "$(dirname "$0")/.." && pwd)
TOOLS=$REPO/.tools

prefix=/storage/Users/currentUser/.harmonybrew
brew=$prefix/bin/brew

if [ -x "$brew" ]; then
    eval "$("$brew" shellenv)"
    echo "Harmonybrew already installed: $prefix"
    return 0 2>/dev/null || exit 0
fi

if ! command -v zsh >/dev/null 2>&1; then
    echo "=== install ohos-zsh ==="
    mkdir -p "$TOOLS"
    curl -fL -o "$TOOLS/zsh-5.9-ohos-arm64.tar.gz" https://github.com/Harmonybrew/ohos-zsh/releases/download/5.9/zsh-5.9-ohos-arm64.tar.gz
    tar -zxf "$TOOLS/zsh-5.9-ohos-arm64.tar.gz" -C "$TOOLS"
    rm "$TOOLS/zsh-5.9-ohos-arm64.tar.gz"
    ZSH=$TOOLS/zsh-5.9-ohos-arm64/bin/zsh
    # brew is a zsh script (#!/usr/bin/zsh): the symlink is as much a part of
    # the toolchain as the brew install itself, so it stays. The payload
    # still lives in .tools/ inside the repo.
    ln -sf "$ZSH" /usr/bin/zsh
else
    ZSH=zsh
fi

echo "=== install Harmonybrew ==="
export NONINTERACTIVE=1
"$ZSH" -c "$(curl -fsSL https://harmonybrew.atomgit.com/install.sh)"

[ -x "$brew" ] || { echo "brew not found after install" >&2; exit 1; }
eval "$("$brew" shellenv)"
# persist for interactive shells
if ! grep -q 'harmonybrew/bin/brew shellenv' "$HOME/.profile" 2>/dev/null; then
    printf 'eval "$(%s/bin/brew shellenv)"\n' "$prefix" >> "$HOME/.profile"
fi
echo "Harmonybrew installed: $prefix"
