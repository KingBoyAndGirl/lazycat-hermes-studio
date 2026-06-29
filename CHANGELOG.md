## v2026.06.29

### 变更
- Hermes Web UI 镜像升级到官方 `v0.6.22`
- LazyCat 入口镜像改为 `registry.cn-shanghai.aliyuncs.com/wtjking/hermes-web-ui:v0.6.22`
- 同步 `package.yml` 包版本到 `2026.06.29`

---

## v2026.06.25

### 变更
- Hermes Web UI 镜像升级到官方 `v0.6.21`
- LazyCat 入口镜像改为 `registry.cn-shanghai.aliyuncs.com/wtjking/hermes-web-ui:v0.6.21`

---

## v2026.06.24

### 变更
- 在 `setup_script` 中补写 `/home/agent/.profile` 与 `/home/agent/.bash_profile` 的 PATH 导出
- 让登录 shell 快照稳定包含 `/home/agent/.local/bin`，避免 `lzc-cli` 等用户级 CLI 在部分终端上下文中丢失

---

## v2026.06.23

### 变更
- Hermes Web UI 镜像升级到官方 `v0.6.19`
- LazyCat 入口镜像改为 `registry.cn-shanghai.aliyuncs.com/wtjking/hermes-web-ui:v0.6.19`

---

## v2026.06.22

### 变更
- 延长平台级与 `hermes-webui` 容器级健康检查宽限期到 600 秒，避免首次启动 / overlay snapshot / bootstrap 阶段被过早判失败

---

# Hermes Studio 懒猫微服版 更新日志

## v2026.06.21

### 变更
- Hermes Web UI 镜像升级到官方 `v0.6.18`
- LazyCat 入口镜像改为 `registry.cn-shanghai.aliyuncs.com/wtjking/hermes-web-ui:v0.6.18`
- 移除上传文件大小限制（nginx + hermes-webui）
- nginx: `client_max_body_size 0`（无限制）
- hermes-webui: `MAX_UPLOAD_SIZE` 默认 0（无限制），可通过环境变量 `MAX_UPLOAD_SIZE` 覆盖

---

## v2026.06.20

### 子域名端口路由
- Nginx 动态端口前缀路由：`9090-hermesstudio → hermes-webui:9090`
- WebSocket 代理支持
- `/preview/*` → hermes-webui:8651
- `/xai-oauth/*` → hermes-webui:56121

### 平台级健康检查
- `application.health_check.test_url: http://hermes-webui:8648`
- 消除启动 502 错误

### document.private + 应用文稿
- `/home/agent` 在懒猫文件管理器"应用文稿"中可见

### 核心
- 全 rootfs 持久化（base+upper overlay 分离）
- 镜像切换到阿里云 ACR
- AGPL-3.0 许可证

---

## v2026.06.19

### 首次正式发布
- Hermes Agent Web UI 部署到懒猫微服
- 全家目录持久化 (`/lzcapp/var/home:/home/agent`)
- rootfs overlay 持久化（base+upper 分离）
- document.private 支持
- AGPL-3.0 许可证
