<div align="center">
<p>English | <a href="README.zh-CN.md">简体中文</a></p>
</div>

# ohos-uv

uv builds for OpenHarmony.

## Download and install

```sh
curl -fLO https://github.com/ohos-python/ohos-uv/releases/download/v0.13.9-6/uv-0.13.9-6-aarch64-unknown-linux-ohos.tar.gz
# Users in mainland China can use the AtomGit mirror for faster downloads:
# curl -fLO https://atomgit.com/ohos-python/ohos-uv/releases/download/v0.13.9-6/uv-0.13.9-6-aarch64-unknown-linux-ohos.tar.gz

tar -zxf uv-*.tar.gz -C "$HOME"
export PATH="$HOME/uv:$PATH"
uv --version
```

## Install Python

By default, uv downloads CPython from [ohos-python](https://github.com/ohos-python/ohos-python)'s GitHub Releases, with no configuration required:

```sh
uv python install 3.15
uv python list

# Users in mainland China can use the AtomGit mirror for faster downloads:
# export UV_PYTHON_INSTALL_MIRROR=https://atomgit.com/ohos-python/ohos-python/releases/download
# uv python install 3.15
```

Free-threaded CPython 3.14 and 3.15 are also available:

```sh
uv python install 3.14+freethreaded
uv python install 3.15+freethreaded
```

CPython 3.16.0a2 preview builds are available in both variants:

```sh
uv python install 3.16.0a2
uv python install 3.16.0a2+freethreaded
```

## Build locally

An aarch64 Linux host capable of running [DockerHarmony](https://github.com/hqzing/dockerharmony) is required:

```sh
git clone https://github.com/ohos-python/ohos-uv.git
cd ohos-uv

docker pull ghcr.io/hqzing/dockerharmony:latest
docker run -dit --name ohos-uv \
  -v "$PWD":/workdir -w /workdir \
  ghcr.io/hqzing/dockerharmony:latest
docker exec -it ohos-uv sh

./build.sh  # Artifacts are written to dist/
```

## License

The project's original code and patch files are licensed under the BSD Zero Clause License.

The archives contain uv and third-party components. See `uv/licenses/` for their license texts and copyright notices.
