# lazycat-hermes-studio

LazyCat LPK: **Hermes Studio** + 持久化 `~/`

## 解决什么问题

容器重启或镜像升级后，通过 `uv tool install` 安装的工具（nmem 等）丢失。
本项目通过持久化整个 `~/` 解决：装一次，永远在。

## 架构

- **镜像**: `ekkoye8888/hermes-web-ui:latest`（仅附加 setup-once.sh）
- **持久化**: `/lzcapp/var/home` → `/home/agent`（整个 home）
- **Docker Socket**: 挂载到容器内，支持 Docker-in-Docker
- **setup-once.sh**: 首次启动自动安装 `nmem-cli` 到 `~/.local/bin/`

## 安装新工具

进容器后直接：
```bash
uv tool install <package-name>
```

装到 `~/.local/bin/`，重启不丢，升级镜像不丢。

## 安装 LPK

```bash
lzc-cli lpk install hermes-studio-v0.0.1.lpk
```
