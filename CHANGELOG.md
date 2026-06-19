# Changelog

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
