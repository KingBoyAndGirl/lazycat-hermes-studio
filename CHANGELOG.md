# Changelog

## v2026.06.20-nginx-routing

- 替换 Caddy 为 Nginx（`nginx:alpine`），支持动态端口前缀路由
- Nginx `map` + 命名捕获组实现 `9090-1-hermesstudio → hermes-webui:9090`
- 子域名从 `hermes-studio` 改为 `hermesstudio`（兼容 ingress 端口前缀解析）
- WebSocket 代理支持（`Upgrade` + `Connection` 头）
- `/preview/*` → hermes-webui:8651
- `/xai-oauth/*` → hermes-webui:56121

## v2026.06.20

- 开启 `document.private` 权限
- `/home/agent` 绑定到 `/lzcapp/documents/<uid>`，用户可在懒猫文件管理器的"应用文稿"中直接浏览
- 首次启动自动迁移 `/lzcapp/var/home` 数据到应用文稿目录
- 保持 rootfs overlay 持久化架构不变（base+upper 分离）

## v2026.06.19

- 正式发布版本
- 全 rootfs 持久化（base+upper overlay 分离）
- 镜像指纹检测（overlay lowerdir hash）
- bash history 自动配置
- 切换到上游镜像 ekkoye8888/hermes-web-ui:latest
- AGPL-3.0 许可证
