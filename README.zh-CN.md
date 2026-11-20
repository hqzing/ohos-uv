<div align="center">
<p><a href="README.md">English</a> | 简体中文</p>
</div>

# ohos-uv

为 OpenHarmony 平台构建的 uv。

## 下载与安装

```sh
curl -fLO https://github.com/ohos-python/ohos-uv/releases/download/v0.13.9-1/uv-0.13.9-1-aarch64-unknown-linux-ohos.tar.gz
# 中国大陆用户可使用 AtomGit 镜像加速下载：
# curl -fLO https://atomgit.com/ohos-python/ohos-uv/releases/download/v0.13.9-1/uv-0.13.9-1-aarch64-unknown-linux-ohos.tar.gz

tar -zxf uv-*.tar.gz -C "$HOME"
export PATH="$HOME/uv:$PATH"
uv --version
```

## 安装 Python

默认从 [ohos-python](https://github.com/ohos-python/ohos-python) 的 GitHub Releases 下载 CPython 解释器，无需任何配置：

```sh
uv python install 3.14
uv python list

# 中国大陆用户可使用 AtomGit 镜像加速下载：
# export UV_PYTHON_INSTALL_MIRROR=https://atomgit.com/ohos-python/ohos-python/releases/download
# uv python install 3.14
```

CPython 3.14 和 3.15 也提供 free-threaded 构建：

```sh
uv python install 3.14+freethreaded
uv python install 3.15+freethreaded
```

## 自行构建

需要一台能跑[鸿蒙容器](https://github.com/hqzing/dockerharmony)的 aarch64 Linux 主机：

```sh
git clone https://github.com/ohos-python/ohos-uv.git
cd ohos-uv

docker pull ghcr.io/hqzing/dockerharmony:latest
docker run -dit --name ohos-uv \
  -v "$PWD":/workdir -w /workdir \
  ghcr.io/hqzing/dockerharmony:latest
docker exec -it ohos-uv sh

./build.sh  # 产物在 dist/ 目录下
```

## License

本项目自身编写的代码及补丁文件采用 BSD Zero Clause License。

制品包含 uv 及其第三方组件，相关许可证和版权通知见制品内 `uv/licenses/`。
