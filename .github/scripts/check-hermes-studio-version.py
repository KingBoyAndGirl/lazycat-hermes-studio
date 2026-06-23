#!/usr/bin/env python3
"""Check upstream Hermes Web UI releases and prepare a LazyCat LPK upgrade PR.

This workflow intentionally does not merge or publish. It only:
- finds the latest upstream Hermes Web UI tag
- mirrors the official Docker Hub image to the configured ACR namespace
- updates package.yml, lzc-manifest.yml, and CHANGELOG.md
- leaves the actual PR creation to create-pull-request@v7
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional

UPSTREAM_REPO = os.environ.get("UPSTREAM_REPO", "EKKOLearnAI/hermes-studio").strip()
UPSTREAM_IMAGE = os.environ.get("UPSTREAM_IMAGE", "ekkoye8888/hermes-web-ui").strip()
ACR_REGISTRY = os.environ.get("ACR_REGISTRY", "registry.cn-shanghai.aliyuncs.com").strip()
ACR_NAMESPACE = os.environ.get("ACR_NAMESPACE", "wtjking").strip()
APP_IMAGE_NAME = os.environ.get("APP_IMAGE_NAME", "hermes-web-ui").strip()
MANIFEST_PATH = Path(os.environ.get("MANIFEST_PATH", "lzc-manifest.yml"))
CHANGELOG_PATH = Path(os.environ.get("CHANGELOG_PATH", "CHANGELOG.md"))
PACKAGE_PATH = Path(os.environ.get("PACKAGE_PATH", "package.yml"))
DRY_RUN = os.environ.get("DRY_RUN", "false").lower() in {"1", "true", "yes"}
PACKAGE_VERSION_TIMEZONE = timezone(timedelta(hours=8))

SEMVER_RE = re.compile(r"^v?(\d+)\.(\d+)\.(\d+)$")


def run(
    cmd: list[str],
    *,
    check: bool = True,
    timeout: Optional[float] = None,
) -> subprocess.CompletedProcess[str]:
    print("+ " + " ".join(cmd))
    proc = subprocess.run(
        cmd,
        check=check,
        text=True,
        capture_output=True,
        timeout=timeout,
    )
    if proc.stdout:
        print(proc.stdout, end="" if proc.stdout.endswith("\n") else "\n")
    if proc.stderr:
        print(proc.stderr, file=sys.stderr, end="" if proc.stderr.endswith("\n") else "\n")
    return proc


def run_with_input(
    cmd: list[str],
    *,
    input_text: str,
    check: bool = True,
    timeout: Optional[float] = None,
) -> subprocess.CompletedProcess[str]:
    print("+ " + " ".join(cmd))
    proc = subprocess.run(
        cmd,
        check=check,
        text=True,
        capture_output=True,
        input=input_text,
        timeout=timeout,
    )
    if proc.stdout:
        print(proc.stdout, end="" if proc.stdout.endswith("\n") else "\n")
    if proc.stderr:
        print(proc.stderr, file=sys.stderr, end="" if proc.stderr.endswith("\n") else "\n")
    return proc


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: Path, text: str) -> None:
    print(f"write {path}")
    path.write_text(text, encoding="utf-8")


def semver_key(tag: str) -> Optional[tuple[int, int, int]]:
    match = SEMVER_RE.match(tag)
    if not match:
        return None
    return tuple(int(part) for part in match.groups())  # type: ignore[return-value]


def latest_upstream_tag() -> str:
    url = f"https://github.com/{UPSTREAM_REPO}.git"
    proc = run(["git", "ls-remote", "--tags", "--refs", url, "v*"])
    candidates: list[tuple[tuple[int, int, int], str]] = []
    for line in proc.stdout.splitlines():
        parts = line.split()
        if len(parts) < 2:
            continue
        tag = parts[1].rsplit("/", 1)[-1]
        key = semver_key(tag)
        if key:
            candidates.append((key, tag))
    if not candidates:
        raise RuntimeError(f"没有找到 {UPSTREAM_REPO} 的语义化版本 tag")
    candidates.sort(key=lambda item: item[0])
    return candidates[-1][1]


def current_manifest_image() -> str:
    text = read_text(MANIFEST_PATH)
    escaped_image = re.escape(f"{ACR_REGISTRY}/{ACR_NAMESPACE}/{APP_IMAGE_NAME}")
    match = re.search(rf"^\s*image:\s*({escaped_image}:[^\s]+)", text, re.MULTILINE)
    if not match:
        image_lines = [line.strip() for line in text.splitlines() if line.strip().startswith("image:")]
        found = "; ".join(image_lines) if image_lines else "<none>"
        raise RuntimeError(
            f"未在 {MANIFEST_PATH} 找到期望的 ACR 镜像行，"
            f"期望前缀为 {ACR_REGISTRY}/{ACR_NAMESPACE}/{APP_IMAGE_NAME}: ，"
            f"实际 image 行：{found}"
        )
    return match.group(1)


def image_version(image: str) -> str:
    match = re.search(rf"{re.escape(APP_IMAGE_NAME)}:([^:\s]+)", image)
    if not match:
        raise RuntimeError(f"无法从镜像 {image} 解析版本")
    return match.group(1)


def docker_image_exists(image: str, *, timeout: float = 120) -> bool:
    try:
        proc = run(
            ["docker", "buildx", "imagetools", "inspect", image],
            check=False,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(f"检查镜像是否存在超时（>{timeout}s）：{image}") from exc
    return proc.returncode == 0


def login_acr() -> None:
    username = os.environ.get("ACR_USERNAME", "").strip()
    password = os.environ.get("ACR_PASSWORD", "").strip()
    if not username or not password:
        raise RuntimeError("缺少 ACR_USERNAME 或 ACR_PASSWORD，无法推送新镜像")
    proc = run_with_input(
        ["docker", "login", ACR_REGISTRY, "--username", username, "--password-stdin"],
        input_text=password + "\n",
        check=False,
    )
    if proc.returncode != 0:
        stderr = (proc.stderr or proc.stdout or "").strip()
        detail = f": {stderr}" if stderr else ""
        raise RuntimeError(f"docker login {ACR_REGISTRY} 失败{detail}")


def mirror_image(version: str) -> str:
    upstream = f"{UPSTREAM_IMAGE}:{version}"
    acr_image = f"{ACR_REGISTRY}/{ACR_NAMESPACE}/{APP_IMAGE_NAME}:{version}"

    print(f"验证 upstream 镜像是否存在：{upstream}")
    try:
        run(["docker", "buildx", "imagetools", "inspect", upstream], timeout=180)
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(f"检查 upstream 镜像超时（>180s）：{upstream}") from exc

    print(f"检查 ACR 目标镜像是否已存在：{acr_image}")
    if docker_image_exists(acr_image, timeout=120):
        print(f"ACR 镜像已存在，跳过推送：{acr_image}")
        return acr_image

    if DRY_RUN:
        print(f"[dry-run] 将同步镜像：{upstream} -> {acr_image}")
        return acr_image

    print(f"准备登录 ACR：{ACR_REGISTRY}")
    login_acr()
    print(f"再次确认 ACR 目标镜像是否已存在：{acr_image}")
    if docker_image_exists(acr_image, timeout=120):
        print(f"ACR 镜像已存在，跳过推送：{acr_image}")
        return acr_image

    print(f"开始同步镜像到 ACR：{upstream} -> {acr_image}")
    try:
        run(["docker", "buildx", "imagetools", "create", "--tag", acr_image, upstream], timeout=900)
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(f"同步镜像到 ACR 超时（>900s）：{upstream} -> {acr_image}") from exc

    print(f"验证 ACR 目标镜像是否已可见：{acr_image}")
    if not docker_image_exists(acr_image, timeout=180):
        raise RuntimeError(f"推送后仍无法检查 ACR 镜像：{acr_image}")
    return acr_image


def update_package_version(date_version: str) -> None:
    text = read_text(PACKAGE_PATH)
    updated = re.sub(r"^version:\s*.*$", f"version: {date_version}", text, count=1, flags=re.MULTILINE)
    if updated == text:
        raise RuntimeError(f"未在 {PACKAGE_PATH} 找到 version 字段")
    write_text(PACKAGE_PATH, updated)


def update_manifest(old_image: str, new_image: str) -> None:
    text = read_text(MANIFEST_PATH)
    updated = text.replace(old_image, new_image)
    if updated == text:
        raise RuntimeError("manifest 镜像没有变化")
    write_text(MANIFEST_PATH, updated)


def update_changelog(date_version: str, upstream_version: str, acr_image: str) -> None:
    upstream_display = upstream_version if upstream_version.startswith("v") else f"v{upstream_version}"
    section = (
        f"## v{date_version}\n\n"
        "### 变更\n"
        f"- Hermes Web UI 镜像升级到官方 `{upstream_display}`\n"
        f"- LazyCat 入口镜像改为 `{acr_image}`\n"
        "\n"
        "---\n"
    )
    text = read_text(CHANGELOG_PATH)
    pattern = re.compile(
        rf"^## v{re.escape(date_version)}\n.*?(?=^---$\n\n^## v|\Z)",
        re.MULTILINE | re.DOTALL,
    )
    if pattern.search(text):
        updated = pattern.sub(section, text, count=1)
    else:
        updated = section + "\n" + text
    write_text(CHANGELOG_PATH, updated)


def write_github_output(values: dict[str, str]) -> None:
    output_path = os.environ.get("GITHUB_OUTPUT")
    if not output_path:
        return
    with Path(output_path).open("a", encoding="utf-8") as handle:
        for key, value in values.items():
            handle.write(f"{key}={value}\n")


def main() -> int:
    required = [MANIFEST_PATH, CHANGELOG_PATH, PACKAGE_PATH]
    missing = [str(path) for path in required if not path.exists()]
    if missing:
        raise RuntimeError(f"缺少文件：{', '.join(missing)}")

    upstream_version = latest_upstream_tag()
    current_image = current_manifest_image()
    current_version = image_version(current_image)
    current_key = semver_key(current_version)
    upstream_key = semver_key(upstream_version)
    if not current_key or not upstream_key:
        raise RuntimeError("当前镜像版本或上游最新版本不是语义化版本")

    acr_image = f"{ACR_REGISTRY}/{ACR_NAMESPACE}/{APP_IMAGE_NAME}:{upstream_version}"
    date_version = datetime.now(PACKAGE_VERSION_TIMEZONE).strftime("%Y.%m.%d")

    print(f"当前 manifest 镜像：{current_image}")
    print(f"上游最新版本：{upstream_version}")
    print(f"目标 ACR 镜像：{acr_image}")

    if upstream_key <= current_key:
        print("当前 LPK 已是最新 upstream 版本，无需创建升级 PR")
        write_github_output(
            {
                "changed": "false",
                "current_version": current_version,
                "upstream_version": upstream_version,
            }
        )
        return 0

    if not DRY_RUN:
        mirror_image(upstream_version)

    update_package_version(date_version)
    update_manifest(current_image, acr_image)
    update_changelog(date_version, upstream_version, acr_image)

    print("已准备升级变更，等待 create-pull-request 创建 PR")
    write_github_output(
        {
            "changed": "true",
            "current_version": current_version,
            "upstream_version": upstream_version,
            "package_version": date_version,
            "acr_image": acr_image,
        }
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001 - GitHub Actions 需要明确失败原因
        print(f"::error::{exc}", file=sys.stderr)
        raise
