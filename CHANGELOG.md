# Changelog

## v0.0.8 (2026-06-19)
**实验性：SYS_ADMIN + overlay 持久化 /usr**

- 添加 `cap_add: [SYS_ADMIN]` 到 compose_override（参考 Totoro LPK）
- setup_script 使用 kernel overlay mount 将 `/usr` 映射到持久化层
  - lowerdir: 镜像的 /usr（只读）
  - upperdir: `/lzcapp/cache/overlay/usr-upper`（持久化，用户写入层）
  - workdir: `/lzcapp/cache/overlay/usr-work`
- 用户通过 apt/npm/pip 安装的任何工具自动持久化到 upper 层
- 重启后 overlay 自动重新挂载，工具不丢失
- 无需首次复制、无需备份、无需包列表重装
- 新增 bind: `/lzcapp/var/cache:/lzcapp/cache` 确保 upper 层持久化

### 变更文件
- `lzc-manifest.yml`: 更新 setup_script，添加 overlay mount 逻辑
- `lzc-build.yml`: compose_override 添加 cap_add SYS_ADMIN
- `package.yml`: version 0.0.7 → 0.0.8
- `CHANGELOG.md`: 新增

## v0.0.7 (2026-06-19)
- setup_script 设置 npm prefix 到 `/home/agent/.local`，解决 codex/claude 安装后重启丢失

## v0.0.6 (2026-06-18)
- 硬编码端口（8648/8651/56121），去掉 deploy_params 模板变量

## v0.0.1 - v0.0.5
- 初始版本迭代，最终 v0.0.6 可用

## v0.0.9 (2026-06-19)
**修复：setup_script grep 匹配错误**

- 修复 `mount | grep "overlay on /usr"` 误匹配系统 `/usr/share/zoneinfo/Etc/UTC` 的 overlay
- 改用 `mount | grep "overlay on /usr type"` 精确匹配
- v0.0.8 的 overlay 方案已验证可行，仅此 grep 匹配 bug 需要修复

## v0.1.0 (2026-06-19)
**全 rootfs overlay 持久化**

- overlay 从 `/usr` 扩展到 `/` — 整个 rootfs 持久化
- 解决 `/etc/alternatives/` 重启丢失问题（vim 等 alternatives 链接）
- 同时持久化 dpkg 数据库、系统配置等所有 rootfs 变更
- 使用 `rootfs-upper` 目录名区分旧的 `usr-upper`

## v0.1.1 (2026-06-19)
**overlay 双层方案：/usr + /etc**

- 回退 v0.1.0 的 `/` overlay（嵌套 overlay 写入不生效）
- 改为 `/usr` + `/etc` 双 overlay 方案
- `/usr` overlay：持久化所有安装的二进制、库、头文件
- `/etc` overlay：持久化 alternatives 链接、dpkg conffiles
- 解决 vim 等需要 alternatives 的包重启后丢失问题

## v0.1.2 (2026-06-19)
**修复：overlay /etc 导致 DNS 失败**

- v0.1.1 overlay 整个 /etc 导致 resolv.conf 被覆盖，DNS 解析失败
- 改为只 overlay /etc/alternatives（窄范围，不影响系统）
- /usr overlay + /etc/alternatives overlay = 完整持久化
