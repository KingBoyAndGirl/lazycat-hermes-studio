# Changelog

## v2026.06.20-caddy-routing

- 添加 Caddy 反向代理服务，支持子域名端口前缀访问
- `8648-1-hermes-studio.nasw.heiyu.space` 路由到 hermes-webui:8648
- `hermes-studio.nasw.heiyu.space/preview/*` 路由到 hermes-webui:8651
- `hermes-studio.nasw.heiyu.space/xai-oauth/*` 路由到 hermes-webui:56121
- 使用标准 `caddy:2-alpine` 镜像
- 修复路径路由：使用 `handle_path` 自动剥离 `/preview/` 和 `/xai-oauth/` 前缀

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
