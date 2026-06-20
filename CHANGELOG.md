# Changelog

## v2026.06.20

### 子域名端口路由
- 替换 Caddy 为 Nginx（`nginx:alpine`），支持动态端口前缀路由
- Nginx `map` + 命名捕获组实现 `9090-1-hermesstudio → hermes-webui:9090`
- 子域名从 `hermes-studio` 改为 `hermesstudio`（兼容 ingress 端口前缀解析）
- WebSocket 代理支持（`Upgrade` + `Connection` 头）
- `/preview/*` → hermes-webui:8651
- `/xai-oauth/*` → hermes-webui:56121

### 平台级健康检查
- `application.health_check.test_url: http://hermes-webui:8648`
- `start_period: 60s`：overlay 挂载期间 ingress 不对外暴露，消除启动 502
- Docker 级 healthcheck：`curl -f http://localhost:8648`

### document.private + 应用文稿
- 开启 `document.private` 权限
- `/home/agent` 绑定到 `/lzcapp/documents/<uid>`，用户可在懒猫文件管理器的"应用文稿"中直接浏览
- 首次启动自动迁移 `/lzcapp/var/home` 数据到应用文稿目录

### 核心
- 全 rootfs 持久化（base+upper overlay 分离）
- 镜像指纹检测（overlay lowerdir hash）
- bash history 自动配置
- 切换到上游镜像 ekkoye8888/hermes-web-ui:latest
- AGPL-3.0 许可证

## v2026.06.19

- 正式发布版本
- 全 rootfs 持久化（base+upper overlay 分离）
- 镜像指纹检测（overlay lowerdir hash）
- bash history 自动配置
- 切换到上游镜像 ekkoye8888/hermes-web-ui:latest
- AGPL-3.0 许可证
