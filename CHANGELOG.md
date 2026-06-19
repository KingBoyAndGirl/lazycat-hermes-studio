# Changelog

## v0.5.5 (2026-06-20)
**bash history 持久化**

- setup_script 自动配置 ~/.bashrc：每条命令执行后立即写盘
- 容器重启/kill 不丢 history
- 幂等：只在首次写入，不覆盖用户自定义
## v0.5.3 (2026-06-20)
**修复指纹检测 + nmem PATH**

- 修复 overlay lowerdir 指纹 grep 匹配错误（`/ rw,relatime - overlay` 而非 `/ overlay`）
- setup_script 自动将 nmem 从 ~/.local/bin 复制到 /usr/local/bin

## v0.5.2 (2026-06-20)
**切换到上游镜像**

- 镜像从 fork `path-fix-0.0.3` 切换到上游 `ekkoye8888/hermes-web-ui:latest`
- rootfs 持久化后不再需要 PATH fix fork
- overlay lowerdir hash 检测 works for latest tag

## v0.5.1 (2026-06-20)
**清理 npm prefix workaround**

- 删除 `npm config set prefix /home/agent/.local`（/usr/local 在 overlay 里自动持久化）
- 删除 PATH 中的 `~/.local/bin`
- 关闭 PR #1669（不再需要上游 PATH fix）

## v0.5.0 (2026-06-20)
**Totoro 风格 base+upper 分离**

- 参考 Totoro manager 的 BaseVersionStatus + RootFSUser 架构
- 分离 base 快照（镜像内容）和 upper 层（用户变更）
- 首次启动：snapshot 镜像到 base/，记录镜像指纹
- apt install 的包写入 upper/ 层（overlay copy-up）
- 镜像更新时：检测指纹变化 → 重新 snapshot base/ → upper/ 用户包保留

## v0.4.1 (2026-06-20)
**关键修复：compose.override.yml 缺失**

- 根因：手动 zip 打包不会处理 lzc-build.yml 的 compose_override 段
- 修复：用 lzc-cli project release 打包，LPK 直接包含 compose.override.yml
- 添加 /dev/fuse 设备（参考 Totoro）

## v0.4.0 (2026-06-20)
**overlay + 预填充 upper 层**

- v0.3.0 bind mount permission denied → 改用 overlay mount
- 预填充 upper 层避免 dpkg-divert 跨层 rename 失败
- 覆盖 /etc /opt /root /srv /usr /var — apt install 全路径持久化

## v0.3.0 (2026-06-20)
**全 rootfs bind mount 持久化**

- 首次启动 snapshot 整个 rootfs 到 btrfs 持久化卷
- 后续启动逐目录 bind mount 回来

## v0.2.0 (2026-06-19)
**overlay → bind mount 重构**

- overlay dpkg-divert 跨层 rename 失败 → 改用 bind mount

## v0.1.0 - v0.1.2 (2026-06-19)
**overlay 变体探索**（全部失败：嵌套 overlay / DNS / dpkg-divert）

## v0.0.8 - v0.0.9 (2026-06-19)
**SYS_ADMIN + overlay /usr 持久化**（实验性）

## v0.0.7 (2026-06-19)
- npm prefix 到 ~/.local（已被 v0.5.1 移除）

## v0.0.6 (2026-06-18)
- 硬编码端口，去掉 deploy_params

## v0.0.1 - v0.0.5
- 初始版本迭代
