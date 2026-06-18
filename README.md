# lazycat-hermes-studio

LazyCat LPK: **Hermes Studio + Nowledge Mem (nmem)**

## 解决什么问题

容器重启导致 nmem 丢失。本项目通过 `compose.override.yml` 将 nmem 作为独立 sidecar 容器运行，数据持久化到 `/lzcapp/var/nowledge-mem`。

## 文件结构

| 文件 | 作用 |
|------|------|
| `manifest.yml` | 应用配置：服务、端口、反向代理 |
| `lzc-build.yml` | 构建配置：icon、deploy_params、compose_override |
| `compose.override.yml` | nmem sidecar 容器定义 |
| `deploy_params.yml` | 部署参数（端口） |
| `package.yml` | 包元数据 v0.0.1 |
| `hermes-studio-v0.0.1.lpk` | 预构建 LPK，可直接安装 |

## 安装

```bash
lzc-cli lpk install hermes-studio-v0.0.1.lpk
```

## 架构

```
┌─────────────────┐     ┌─────────────────┐
│  hermes-webui   │────▶│  knowlege-mem   │
│  (hermes-studio)│     │  (nmem serve)   │
│  :8648          │     │  /data          │
└─────────────────┘     └─────────────────┘
        │                       │
        ▼                       ▼
/lzcapp/var/hermes      /lzcapp/var/nowledge-mem
/lzcapp/var/hermes-web-ui
```
