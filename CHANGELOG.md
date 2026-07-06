## v2026.07.06-fix-nvme

### 修复
- 🔧 rootfs cache 绑定从 HDD 改为 NVMe (`/lzcsys/var/cache/hermes-studio`)
- 解决 02 机器首次安装 `cp -a /usr` (1.5GB) 耗时 50+ 分钟的问题

### 文件变更
- `lzc-manifest.yml`: binds 改为 `/lzcsys/var/cache/hermes-studio:/lzcapp/cache`
- `package.yml`: 版本号 `2026.07.06-fix-nvme`


## v2026.07.06

### 版本信息
- **Hermes Studio**: v0.6.26（基于上游 EKKOLearnAI/hermes-studio v0.6.26）
- **Hermes CLI**: v0.18.0 (2026.7.1)，支持 journey 命令
- **Docker 镜像**: registry.cn-shanghai.aliyuncs.com/wtjking/hermes-web-ui:2026.07.06
- **LPK 包**: community.lazycat.app.hermes-studio-v2026.07.06.lpk

### 上游合并
- 🔄 基于上游 v0.6.26 官方发布版
- 🆕 新增 Ekko Agent runtime（本地 agent 运行时）
- 🆕 新增 group chat baseline/approval/streaming 测试
- 🛠️ ChatInput 高度设置、Codex 上下文稳定性改进

### 保留修复
- 🧩 包含上游未合并 PR：
  - PR #1903：coding agent session 导出
  - PR #1918：定时任务 model 选择修复
  - PR #1924：文件面板 session workspace 支持

### 变更文件
- Fork: KingBoyAndGirl/hermes-studio main（merge upstream v0.6.26）
- Dockerfile：BASE_IMAGE=nousresearch/hermes-agent:latest
- lzc-manifest.yml：镜像 tag → wtjking/hermes-web-ui:2026.07.06
- package.yml：版本号 → 2026.07.06

## v2026.07.05

### 版本信息
- **Hermes Studio**: v0.6.25（基于上游 EKKOLearnAI/hermes-studio v0.6.25）
- **Hermes CLI**: v0.18.0 (2026.7.1)，支持 journey 命令
- **Docker 镜像**: registry.cn-shanghai.aliyuncs.com/wtjking/hermes-web-ui:2026.07.05
- **LPK 包**: community.lazycat.app.hermes-studio-v2026.07.05.lpk

### 核心修复
- 🔼 **Hermes CLI 升级**：基础镜像 nousresearch/hermes-agent:latest 自动解析至 v0.18.0，新增 journey 子命令支持，修复学习轨迹 API 500 错误
- 🧩 **包含上游未合并 PR**：
  - PR #1903：coding agent session 导出
  - PR #1918：定时任务 model 选择修复  
  - PR #1924：文件面板 session workspace 支持

### 变更文件
- Dockerfile：BASE_IMAGE 重新拉取（Hermes v0.17.0 → v0.18.0）
- lzc-manifest.yml：镜像 tag → wtjking/hermes-web-ui:2026.07.05
- package.yml：版本号 → 2026.07.05

### 构建信息
- 源码：KingBoyAndGirl/hermes-studio main 分支（HEAD: 21ec9e87）
- 构建时间：2026-07-05 12:42 UTC

## v2026.07.04

### 变更
- 测试包：Hermes Web UI 镜像切到 `v0.6.25-pr1903-1918-1921-20260704`
- 测试镜像 = 官方 `v0.6.25` base + PR #1903 / #1918 / #1921 源码组合构建的头部分
- PR #1918 新增：定时任务编辑时 provider/model 持久化修复 + 卡片显示 provider/与中文模型标签
- 构建时间：2026-07-04 03:12:19
- 仅用于安装验证，不代表上游正式发布版本

---

## v2026.07.04

### 变更
- 测试包：Hermes Web UI 镜像切到 `v0.6.25-pr1903-1918-1921-20260703`
- 该测试镜像包含上游未合并 PR #1903 / #1918 / #1921 的组合构建
- 仅用于安装验证，不代表上游正式发布版本

---

## v2026.07.03

### 变更
- Hermes Web UI 镜像升级到官方 `v0.6.25`
- LazyCat 入口镜像改为 `registry.cn-shanghai.aliyuncs.com/wtjking/hermes-web-ui:v0.6.25`
- 同步 `package.yml` 包版本到 `2026.07.03`
- 显式设置 `WORKSPACE_BASE=/home/agent`，让工作区目录选择器可在安全边界内选择 `.hermes`、`.config`、`.codex` 等目录

---

## v2026.07.01

### 变更
- Hermes Web UI 镜像升级到官方 `v0.6.23`
- LazyCat 入口镜像改为 `registry.cn-shanghai.aliyuncs.com/wtjking/hermes-web-ui:v0.6.23`
- 同步 `package.yml` 包版本到 `2026.07.01`

---

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
