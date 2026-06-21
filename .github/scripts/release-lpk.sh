#!/usr/bin/env bash
set -euo pipefail

cd "${GITHUB_WORKSPACE:-$(pwd)}"

if ! command -v lzc-cli >/dev/null 2>&1; then
  echo "::error::lzc-cli not found. Install @lazycatcloud/lzc-cli before running this workflow."
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "::error::gh CLI not found. GitHub-hosted runners include gh by default."
  exit 1
fi

VERSION="$(python3 - <<'PY'
from pathlib import Path
import re
text = Path('package.yml').read_text(encoding='utf-8')
match = re.search(r'^version:\s*(\S+)', text, re.MULTILINE)
if not match:
    raise SystemExit('package.yml missing version')
print(match.group(1))
PY
)"

if [[ -z "$VERSION" ]]; then
  echo "::error::无法读取 package.yml version"
  exit 1
fi

TODAY="$(date +%Y.%m.%d)"
if [[ "$VERSION" != "$TODAY" ]]; then
  echo "::error::package.yml version (${VERSION}) 必须等于当前日期 (${TODAY})。请更新 PR 后重新合并。"
  exit 1
fi

TAG="v${VERSION}"
LPK_NAME="community.lazycat.app.hermes-studio-${TAG}.lpk"
LPK_PATH="lpk/${LPK_NAME}"

rm -rf lpk
mkdir -p lpk

echo "打包 LPK: ${LPK_NAME}"
lzc-cli project release --file lzc-build.yml

if [[ ! -f "$LPK_PATH" ]]; then
  echo "::error::未找到 LPK: ${LPK_PATH}"
  exit 1
fi

tar -tf "$LPK_PATH" | grep -qx 'manifest.yml'
tar -tf "$LPK_PATH" | grep -qx 'package.yml'
tar -tf "$LPK_PATH" | grep -qx 'compose.override.yml'

python3 - "$LPK_PATH" <<'PY'
from pathlib import Path
import sys, tarfile
lpk = Path(sys.argv[1])
with tarfile.open(lpk, 'r:*') as tf:
    manifest = tf.extractfile('manifest.yml')
    if manifest is None:
        raise SystemExit('manifest.yml missing in LPK')
    text = manifest.read().decode('utf-8')
if 'registry.cn-shanghai.aliyuncs.com/wtjking/hermes-web-ui:' not in text:
    raise SystemExit('LPK manifest does not point at the ACR hermes-web-ui image')
print('LPK manifest image check passed')
PY

SHA256="$(sha256sum "$LPK_PATH" | awk '{print $1}')"
SIZE="$(stat -c '%s' "$LPK_PATH")"

python3 - "$VERSION" <<'PY'
from pathlib import Path
import re, sys
version = sys.argv[1]
text = Path('CHANGELOG.md').read_text(encoding='utf-8')
pattern = re.compile(rf"^## v{re.escape(version)}\n.*?(?=^---$\n\n^## v|\Z)", re.MULTILINE | re.DOTALL)
match = pattern.search(text)
if not match:
    raise SystemExit(f'CHANGELOG.md missing section for v{version}')
Path('release-notes.md').write_text(match.group(0).strip() + '\n', encoding='utf-8')
PY

if gh release view "$TAG" >/dev/null 2>&1; then
  echo "更新 Release: ${TAG}"
  gh release edit "$TAG" --title "$TAG" --notes-file release-notes.md
else
  echo "创建 Release: ${TAG}"
  gh release create "$TAG" --target "$GITHUB_SHA" --title "$TAG" --notes-file release-notes.md
fi

echo "上传/覆盖 LPK: ${LPK_PATH}"
gh release upload "$TAG" "$LPK_PATH" --clobber

{
  echo "LPK=${LPK_PATH}"
  echo "TAG=${TAG}"
  echo "SHA256=${SHA256}"
  echo "SIZE=${SIZE}"
} >> "$GITHUB_OUTPUT"
