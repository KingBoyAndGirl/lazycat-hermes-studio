# lazycat-hermes-studio

LazyCat LPK: **Hermes Studio + Nowledge Mem (nmem)**

## 解决什么问题

容器重启导致 `nmem` 和插件丢失。本项目通过嵌入镜像 + 全量持久化 `~/` 解决。

## 文件结构

| 文件 | 作用 |
|------|------|
| `Dockerfile.lzcapp` | `FROM ekkoye8888/hermes-web-ui:latest` + 安装 nmem |
| `lzc-build.yml` | embed 镜像定义 |
| `lzc-manifest.yml` | 服务配置，`~/` → `/lzcapp/var/home` 持久化 |
| `setup-once.sh` | 首次启动初始化 + 自愈 |
| `package.yml` | 包元数据 v0.0.1 |

## 构建 LPK

```bash
npm install -g @lazycatcloud/lzc-cli
lzc-cli project build
lzc-cli project release -o hermes-studio-v0.0.1.lpk
```

## 安装

```bash
lzc-cli lpk install hermes-studio-v0.0.1.lpk
```

## 首次启动后配置

访问 `http://<设备IP>:8648`，如需配置 Nowledge Mem 远程服务：

```bash
nmem config client set --url <URL> --api-key <KEY>
```
