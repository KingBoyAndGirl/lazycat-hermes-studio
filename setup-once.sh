#!/bin/bash
# /opt/setup-once.sh — runs as root before entrypoint (LazyCat setup_script)
# Initializes persistent ~/ volume on first boot.

set -euo pipefail

AGENT_HOME="/home/agent"
HERMES_HOME="$AGENT_HOME/.hermes"
PLUGIN_DIR="$HERMES_HOME/plugins/nowledge-mem"
DEFAULT_PLUGIN="/opt/nowledge-mem-default"
MARKER="$AGENT_HOME/.lzc-init-done"

# ── First-boot initialization ──
if [ ! -f "$MARKER" ]; then
  echo "[setup-once] First boot detected — initializing persistent home..."

  # Ensure directory structure exists
  mkdir -p "$HERMES_HOME/plugins"
  mkdir -p "$AGENT_HOME/.local/bin"
  mkdir -p "$AGENT_HOME/.nowledge-mem"

  # Copy Nowledge Mem plugin from image stash if not present
  if [ ! -d "$PLUGIN_DIR/plugin.yaml" ] && [ -d "$DEFAULT_PLUGIN" ] && [ "$(ls -A "$DEFAULT_PLUGIN" 2>/dev/null)" ]; then
    cp -a "$DEFAULT_PLUGIN" "$PLUGIN_DIR"
    echo "[setup-once] Installed Nowledge Mem plugin from image default."
  fi

  # Symlink nmem into user-local bin if not already there
  if [ ! -x "$AGENT_HOME/.local/bin/nmem" ] && [ -x "/opt/hermes/.venv/bin/nmem" ]; then
    ln -sf /opt/hermes/.venv/bin/nmem "$AGENT_HOME/.local/bin/nmem"
    echo "[setup-once] Linked nmem to ~/.local/bin/nmem"
  fi

  # Ensure correct ownership
  chown -R 1000:1000 "$AGENT_HOME"

  # Mark initialization complete
  touch "$MARKER"
  chown 1000:1000 "$MARKER"
  echo "[setup-once] Initialization complete."
else
  echo "[setup-once] Already initialized, skipping."
fi

# ── Ensure nmem binary is always available ──
# Even if the home volume was wiped, the image binary is at /opt/hermes/.venv/bin/nmem
if [ ! -x "$AGENT_HOME/.local/bin/nmem" ] && [ -x "/opt/hermes/.venv/bin/nmem" ]; then
  mkdir -p "$AGENT_HOME/.local/bin"
  ln -sf /opt/hermes/.venv/bin/nmem "$AGENT_HOME/.local/bin/nmem"
  chown -R 1000:1000 "$AGENT_HOME/.local/bin"
  echo "[setup-once] Restored nmem symlink."
fi

# ── Ensure plugin exists ──
if [ ! -f "$PLUGIN_DIR/plugin.yaml" ] && [ -d "$DEFAULT_PLUGIN" ] && [ "$(ls -A "$DEFAULT_PLUGIN" 2>/dev/null)" ]; then
  mkdir -p "$PLUGIN_DIR"
  cp -a "$DEFAULT_PLUGIN" "$PLUGIN_DIR"
  chown -R 1000:1000 "$PLUGIN_DIR"
  echo "[setup-once] Restored Nowledge Mem plugin."
fi

echo "[setup-once] Done."
