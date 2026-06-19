# lazycat-hermes-studio

Hermes AI 智能体 Web 管理界面 — 全 rootfs 持久化

## 解决什么问题

容器重启或镜像升级后，apt/pip/npm 安装的工具丢失。
通过 base+upper overlay 架构，rootfs 变更持久化到 btrfs 卷，装一次永远在。

## 原理

```
首次启动：snapshot 镜像 rootfs → /lzcapp/cache/rootfs/base/（持久化）
用户安装：apt install vim → 写入 /lzcapp/cache/rootfs/upper/（overlay copy-up）
镜像更新：检测 lowerdir hash 变化 → re-snapshot base → upper 用户包保留
```

## 安装

下载最新 LPK，通过懒猫 Web UI 安装。

## 装工具

进容器后直接：
```bash
apt install vim git curl htop     # → /usr/bin/，重启不丢
pip install <package>              # → /usr/lib/python*/，重启不丢
npm install -g <package>           # → /usr/local/bin/，重启不丢
uv tool install <package>          # → ~/.local/bin/，重启不丢
```

重启不丢，镜像升级也不丢。

## 版本日志

见 [CHANGELOG.md](CHANGELOG.md)

## License

[AGPL-3.0](LICENSE)
