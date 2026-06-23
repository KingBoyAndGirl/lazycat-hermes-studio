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

VERSION="$(python3 - <<'PY2'
from pathlib import Path
import re
text = Path('package.yml').read_text(encoding='utf-8')
match = re.search(r'^version:\s*(\S+)', text, re.MULTILINE)
if not match:
    raise SystemExit('package.yml missing version')
print(match.group(1))
PY2
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

python3 - "$LPK_PATH" <<'PY2'
import sys, tarfile
lpk = sys.argv[1]
with tarfile.open(lpk, 'r:*') as tf:
    manifest = tf.extractfile('manifest.yml')
    if manifest is None:
        raise SystemExit('manifest.yml missing in LPK')
    text = manifest.read().decode('utf-8')
if 'registry.cn-shanghai.aliyuncs.com/wtjking/hermes-web-ui:' not in text:
    raise SystemExit('LPK manifest does not point at the ACR hermes-web-ui image')
print('LPK manifest image check passed')
PY2

SHA256="$(sha256sum "$LPK_PATH" | awk '{print $1}')"
SIZE="$(stat -c '%s' "$LPK_PATH")"

python3 - "$VERSION" <<'PY2'
from pathlib import Path
import re, sys
version = sys.argv[1]
text = Path('CHANGELOG.md').read_text(encoding='utf-8')
pattern = re.compile(rf"^## v{re.escape(version)}\n.*?(?=^---$\n\n^## v|\Z)", re.MULTILINE | re.DOTALL)
match = pattern.search(text)
if not match:
    raise SystemExit(f'CHANGELOG.md missing section for v{version}')
Path('release-notes.md').write_text(match.group(0).strip() + '\n', encoding='utf-8')
PY2

if gh release view "$TAG" >/dev/null 2>&1; then
  echo "更新 Release: ${TAG}"
  gh release edit "$TAG" --title "$TAG" --notes-file release-notes.md
else
  echo "创建 Release: ${TAG}"
  gh release create "$TAG" --target "$GITHUB_SHA" --title "$TAG" --notes-file release-notes.md
fi

echo "上传/覆盖 LPK: ${LPK_PATH}"
gh release upload "$TAG" "$LPK_PATH" --clobber

echo "回读远端 Release 资产并校验"
REMOTE_VERIFY_DIR="$(mktemp -d)"
REMOTE_LPK_PATH="${REMOTE_VERIFY_DIR}/${LPK_NAME}"
cleanup_remote_verify() {
  rm -rf "$REMOTE_VERIFY_DIR"
}
trap cleanup_remote_verify EXIT

REMOTE_ASSET_JSON="$(gh api "repos/${GITHUB_REPOSITORY}/releases/tags/${TAG}")"
REMOTE_ASSET_INFO="$(REMOTE_ASSET_JSON="$REMOTE_ASSET_JSON" python3 - "$LPK_NAME" <<'PY2'
import json, os, sys
release = json.loads(os.environ['REMOTE_ASSET_JSON'])
name = sys.argv[1]
for asset in release.get('assets', []):
    if asset.get('name') == name:
        print(asset.get('browser_download_url', ''))
        print(asset.get('size', ''))
        break
else:
    raise SystemExit(f'release asset not found: {name}')
PY2
)"
REMOTE_ASSET_URL="$(printf '%s\n' "$REMOTE_ASSET_INFO" | sed -n '1p')"
REMOTE_ASSET_SIZE="$(printf '%s\n' "$REMOTE_ASSET_INFO" | sed -n '2p')"

if [[ -z "$REMOTE_ASSET_URL" || -z "$REMOTE_ASSET_SIZE" ]]; then
  echo "::error::无法从 GitHub Release 读取远端资产信息"
  exit 1
fi

if [[ "$REMOTE_ASSET_SIZE" != "$SIZE" ]]; then
  echo "::error::远端资产大小不匹配：remote=${REMOTE_ASSET_SIZE} local=${SIZE}"
  exit 1
fi

curl -L --fail --silent --show-error -o "$REMOTE_LPK_PATH" "$REMOTE_ASSET_URL"
REMOTE_SHA256="$(sha256sum "$REMOTE_LPK_PATH" | awk '{print $1}')"
if [[ "$REMOTE_SHA256" != "$SHA256" ]]; then
  echo "::error::远端资产 SHA256 不匹配：remote=${REMOTE_SHA256} local=${SHA256}"
  exit 1
fi

python3 - "$REMOTE_LPK_PATH" <<'PY2'
import sys, tarfile
lpk = sys.argv[1]
with tarfile.open(lpk, 'r:*') as tf:
    names = set(tf.getnames())
    for required in ('manifest.yml', 'package.yml', 'compose.override.yml'):
        if required not in names:
            raise SystemExit(f'{required} missing in remote release asset')
    manifest = tf.extractfile('manifest.yml')
    if manifest is None:
        raise SystemExit('manifest.yml missing in remote release asset')
    text = manifest.read().decode('utf-8')
if 'registry.cn-shanghai.aliyuncs.com/wtjking/hermes-web-ui:' not in text:
    raise SystemExit('Remote release asset manifest does not point at the ACR hermes-web-ui image')
print('Remote release asset verification passed')
PY2

{
  echo "LPK=${LPK_PATH}"
  echo "TAG=${TAG}"
  echo "SHA256=${SHA256}"
  echo "SIZE=${SIZE}"
} >> "$GITHUB_OUTPUT"
