# lazycat-hermes-studio

LazyCat LPK 包装项目：**Hermes Studio + Nowledge Mem (nmem)**

## 解决什么问题

在 LazyCat LPK 部署中，容器重启会导致 `nmem` CLI 和 Nowledge Mem 插件丢失。
本项目通过以下方式解决：

1. **嵌入镜像**：基于 `ekkoye8888/hermes-web-ui:latest`，在镜像内预装 `nmem-cli` 和 Nowledge Mem Hermes 插件
2. **持久化整个 `~/`**：整个 home 目录绑定到 `/lzcapp/var/home`，重启不丢失
3. **首次启动自愈**：`setup-once.sh` 在首次启动时自动初始化持久化卷，确保插件和 nmem 链接完好

## 文件结构

```
├── Dockerfile.lzcapp     # 镜像构建：继承 hermes-web-ui + 安装 nmem
├── lzc-build.yml         # LazyCat 构建配置：定义 embed 镜像
├── lzc-manifest.yml      # LazyCat 清单：服务、端口、持久化绑定
├── package.yml           # LazyCat 包元数据
├── setup-once.sh         # 首次启动初始化脚本
├── icon.png              # 应用图标
└── README.md
```

## 构建 LPK

```bash
# 安装 LazyCat CLI
npm install -g @lazycatcloud/lzc-cli

# 构建 release 包
lzc-cli project build
lzc-cli project release -o release.lpk

# 查看包信息
lzc-cli lpk info release.lpk
```

## 安装测试

```bash
lzc-cli lpk install release.lpk
```

## 持久化说明

| 路径 | LazyCat 映射 | 说明 |
|------|-------------|------|
| `/home/agent` | `/lzcapp/var/home` | 整个 home 目录持久化 |
| `/home/agent/.hermes` | 同上（子目录） | Hermes 配置、session、skills |
| `/home/agent/.hermes-web-ui` | 同上（子目录） | Web UI 状态 |
| `/home/agent/.nowledge-mem` | 同上（子目录） | nmem 客户端配置 |
| `/home/agent/.hermes/plugins/nowledge-mem` | 同上（子目录） | Nowledge Mem Hermes 插件 |

`nmem` 二进制文件安装在镜像的 `/opt/hermes/.venv/bin/nmem`（系统路径），
不受 home 持久化影响，容器重建后仍然可用。`setup-once.sh` 会自动创建
`~/.local/bin/nmem` 符号链接。

## 首次启动后的配置

1. 访问 Web UI `http://<设备IP>:8648`
2. 配置 Hermes 模型（`hermes model` 或 Web UI 设置）
3. 如果使用 Nowledge Mem 远程服务，配置 API：
   ```bash
   nmem config client set --url <YOUR_NMEM_URL> --api-key <YOUR_API_KEY>
   ```
