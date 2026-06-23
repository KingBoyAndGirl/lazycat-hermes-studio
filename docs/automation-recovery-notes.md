# 自动升级与发布链路修复记录（2026-06-23）

这份记录用于沉淀 `lazycat-hermes-studio` 在 2026-06-23 完成的一次真实修复链路，覆盖：

- 自动升级 workflow 恢复 `workflow_dispatch`
- 上游镜像同步到 ACR 的稳定化
- 自动创建 / 更新升级 PR 的恢复
- 自动发布 LPK 后的远端 release 资产校验补强

目标不是复述所有试错细节，而是保留 **下次最容易再次踩坑的关键机制与最终可用方案**。

---

## 一、最终稳定状态

截至 2026-06-23，仓库已经实现：

1. `.github/workflows/check-hermes-studio-upgrade.yml`
   - 能被 GitHub 正常识别 `workflow_dispatch`
   - 能检查上游 `EKKOLearnAI/hermes-studio` 最新 semver tag
   - 能把上游镜像同步到 ACR
   - 能自动创建或更新升级 PR

2. `.github/workflows/release-lpk.yml`
   - 在 `main` push 后自动构建 LPK
   - 自动创建 / 更新 GitHub Release
   - 自动上传 `.lpk` 资产
   - **上传后会重新回读远端 release 资产并验包**

---

## 二、`workflow_dispatch` 消失的真实根因

### 现象

GitHub API 对 upgrade workflow 返回：

```text
422 Unprocessable Entity
Workflow does not have 'workflow_dispatch' trigger
```

即使 workflow 文件在 `main` 上肉眼可见包含 `workflow_dispatch:`。

同时，push 后常伴随一种假失败：

- `event = push`
- `conclusion = failure`
- `jobs = []`

这说明失败发生在 **job 创建之前**，不是 shell step 或 Python 脚本执行失败。

### 最终根因

真正的问题不是整个 `peter-evans/create-pull-request@v7` action 本体，而是它的这些字段：

- `commit-message`
- `branch`
- `title`

当这些字段里使用基于 `steps.check.outputs.*` 的表达式插值时，GitHub 会把该 workflow 异常地注册成“不具备 workflow_dispatch”。

### 最终方案

不要继续和 `create-pull-request@v7` 的这组动态输入搏斗。

改为：

- shell 里处理 git branch / commit / push
- Python 通过 GitHub REST API 创建或更新 PR
- 把 `pull-request-number` 写回 `GITHUB_OUTPUT`

这是当前仓库已经验证成功的稳定路径。

---

## 三、ACR 镜像同步的稳定方案

### 被证伪的旧方案

以下方案在 GitHub hosted runner 上都不可靠：

1. `docker buildx imagetools create --tag <acr> <upstream:tag>`
   - 真实发生过 900 秒超时

2. 即便先过滤掉 `unknown/unknown` attestation manifests，
   再只同步 `linux/amd64` / `linux/arm64` runtime digests，
   `docker buildx imagetools create --tag ...` 仍可能在 runner 上超时。

### 当前稳定方案

改为使用：

```bash
skopeo copy --all \
  --dest-creds "$ACR_USERNAME:$ACR_PASSWORD" \
  docker://ekkoye8888/hermes-web-ui:<tag> \
  docker://registry.cn-shanghai.aliyuncs.com/wtjking/hermes-web-ui:<tag>
```

### 关键结论

- GitHub `ubuntu-24.04` runner 自带 `skopeo`
- 对这个仓库，`skopeo copy --all` 比 `docker buildx imagetools create` 更稳定
- **不要再默认回退到 buildx create 路线**，除非你已经有新的实测证据证明它重新稳定了

---

## 四、自动更新已有升级 PR 时的关键坑

当升级分支已经存在（例如 `automation/hermes-webui-v0.6.19`）时，重跑 workflow 会进入“更新已有 PR”的路径。

### 两个真实坑

1. `git push --force-with-lease` 报 `stale info`
2. 从 `main` 切到已有远端 automation branch 时，Git 发现当前工作树里已经有 step 3 改出来的文件，拒绝 checkout：

```text
Your local changes to the following files would be overwritten by checkout:
CHANGELOG.md
lzc-manifest.yml
package.yml
```

### 当前稳定方案

在 step 4 里采用这条顺序：

1. 先 `git checkout -B "$BRANCH"`
2. `git fetch origin "$BRANCH" || true`
3. 如果远端分支已存在：
   - `git stash push --include-untracked ...`
   - `git reset --hard "refs/remotes/origin/$BRANCH"`
   - `git stash pop || true`
4. 再 `git add` / `git commit` / `git push`

这条路径已经通过真实 run 验证成功。

---

## 五、自动建 PR 的权限坑

即使 workflow/job YAML 里已经声明了 `contents: write`、`pull-requests: write`，也不一定足够。

如果仓库设置里没有开启：

- **Allow GitHub Actions to create and approve pull requests**

那么 workflow 可能会：

- 成功 push automation branch
- 但在 `POST /repos/{owner}/{repo}/pulls` 时收到 `HTTP 403 Forbidden`

### 当前仓库已验证可用的设置

仓库 Actions workflow permissions 应为：

- `default_workflow_permissions = write`
- `can_approve_pull_request_reviews = true`

---

## 六、release workflow 现在多了一层远端资产验收

之前的 `release-lpk.sh` 只验证：

- 本地 LPK 是否构建成功
- 本地包里是否有 `manifest.yml` / `package.yml` / `compose.override.yml`
- 本地 `manifest.yml` 是否指向 ACR 镜像

这会留下一个盲区：

> 本地包是对的，但 GitHub Release 上最终用户真正下载到的远端资产可能不对。

### 当前补强后的做法

上传之后，脚本现在会：

1. 用 `gh api repos/$GITHUB_REPOSITORY/releases/tags/$TAG` 读取 release 资产
2. 找到目标 `.lpk`
3. 校验远端资产 `size` 与本地 `SIZE` 一致
4. 下载远端 `.lpk`
5. 校验远端 `SHA256` 与本地一致
6. 再解包检查远端资产中：
   - `manifest.yml`
   - `package.yml`
   - `compose.override.yml`
7. 再确认远端 `manifest.yml` 指向 ACR `hermes-web-ui` 镜像

如果任一步失败，release workflow 应直接失败。

---

## 七、建议的后续维护顺序

以后如果再遇到自动升级链路异常，优先按这个顺序判断：

1. **先看是不是 trigger / workflow registration 问题**
   - `workflow_dispatch` 是否还能触发
   - 失败 run 是否 `jobs=[]`

2. **再看是不是 ACR 镜像同步问题**
   - 默认优先检查 `skopeo copy --all` 路径

3. **再看是不是 PR 创建/更新问题**
   - repo Actions PR 权限
   - 已有 automation branch 的 stash/reset/pop 路径

4. **最后再看 release 发布问题**
   - release workflow 是否 green
   - 远端 release asset 校验是否通过

---

## 八、这次已经真实验证成功的结果

以下结果均已在真实仓库中发生：

- 自动升级 workflow 成功 run
- 自动更新 / 创建升级 PR 成功
- 升级 PR #33 成功合并到 `main`
- `v2026.06.23` GitHub Release 成功创建
- `community.lazycat.app.hermes-studio-v2026.06.23.lpk` 已上传
- 远端 release 资产已手工下载并验包成功
- release 脚本现已内建远端资产回读校验

