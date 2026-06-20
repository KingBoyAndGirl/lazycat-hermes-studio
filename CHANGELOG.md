1|# Changelog
2|
3|## v2026.06.20-caddy-routing
4|
5|- 添加 Caddy 反向代理服务，支持子域名端口前缀访问
6|- `8648-1-hermes-studio.nasw.heiyu.space` 路由到 hermes-webui:8648
7|- `hermes-studio.nasw.heiyu.space/preview/*` 路由到 hermes-webui:8651
8|- `hermes-studio.nasw.heiyu.space/xai-oauth/*` 路由到 hermes-webui:56121
9|- 使用标准 `caddy:2-alpine` 镜像
10|- 修复路径路由：使用 `handle_path` 自动剥离 `/preview/` 和 `/xai-oauth/` 前缀
11|- 修复 X-Forwarded-Host 被 Caddy 覆盖为 `caddy:80` 导致 WebSocket 连接失败
12|- 修复启动竞态：添加 `lb_try_duration 30s` 重试，解决 hermes-webui 启动期间 502
13|
14|## v2026.06.20
15|
16|- 开启 `document.private` 权限
17|- `/home/agent` 绑定到 `/lzcapp/documents/<uid>`，用户可在懒猫文件管理器的"应用文稿"中直接浏览
18|- 首次启动自动迁移 `/lzcapp/var/home` 数据到应用文稿目录
19|- 保持 rootfs overlay 持久化架构不变（base+upper 分离）
20|
21|## v2026.06.19
22|
23|- 正式发布版本
24|- 全 rootfs 持久化（base+upper overlay 分离）
25|- 镜像指纹检测（overlay lowerdir hash）
26|- bash history 自动配置
27|- 切换到上游镜像 ekkoye8888/hermes-web-ui:latest
28|- AGPL-3.0 许可证
29|