# Changelog

## v2026.06.19 (2026-06-19)
**正式发布 — 全 rootfs 持久化 + 上游镜像**

### 核心特性
- base+upper overlay 分离：镜像更新不丢用户包
- 切换到上游镜像 `ekkoye8888/hermes-web-ui:latest`
- overlay lowerdir hash 指纹检测（支持 latest tag）
- bash history 自动配置（重启不丢命令历史）

### 持久化范围
- `/usr` `/var` `/etc` `/opt` `/root` `/srv` — overlay mounted（base lower + user upper）
- `/home/agent` — bind mount 到 `/lzcapp/var/home`
- `apt install` 的包重启后保留
- `uv tool install` / `npm install -g` 的工具重启后保留

### 依赖
- `privileged: true` + `cap_add: SYS_ADMIN`
- `/dev/fuse` 设备
- docker.sock 挂载

### 已验证
- ✅ Overlay 6 目录挂载
- ✅ htop 安装 → 重启 → 保留
- ✅ 指纹变化 → re-snapshot base → upper 用户包保留
- ✅ nmem + Working Memory + Hermes memory provider
- ✅ bash history 重启后保留
- ✅ claude 2.1.183 / codex 0.141.0 可用
