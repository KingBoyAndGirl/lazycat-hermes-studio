#!/bin/bash
# /opt/setup-once.sh — runs as root before entrypoint (LazyCat setup_script)
set -euo pipefail

AGENT_HOME="/home/agent"
HERMES_HOME="$AGENT_HOME/.hermes"
PLUGIN_DIR="$HERMES_HOME/plugins/nowledge-mem"
DEFAULT_PLUGIN="/opt/nowledge-mem-default"
MARKER="$AGENT_HOME/.lzc-init-done"

# ── First-boot initialization ──
if [ ! -f "$MARKER" ]; then
  echo "[setup-once] First boot — initializing persistent home..."
  mkdir -p "$HERMES_HOME/plugins"
  mkdir -p "$AGENT_HOME/.local/bin"
  mkdir -p "$AGENT_HOME/.nowledge-mem"

  chown -R 1000:1000 "$AGENT_HOME"
  touch "$MARKER"
  chown 1000:1000 "$MARKER"
  echo "[setup-once] Initialization complete."
fi

# ── Ensure nmem symlink ──
if [ ! -x "$AGENT_HOME/.local/bin/nmem" ] && [ -x "/usr/local/bin/nmem" ]; then
  mkdir -p "$AGENT_HOME/.local/bin"
  ln -sf /usr/local/bin/nmem "$AGENT_HOME/.local/bin/nmem"
  chown -R 1000:1000 "$AGENT_HOME/.local/bin"
  echo "[setup-once] Linked nmem."
fi

# ── Ensure Nowledge Mem plugin exists ──
if [ ! -f "$PLUGIN_DIR/plugin.yaml" ]; then
  mkdir -p "$PLUGIN_DIR"
  # Try image stash first
  if [ -d "$DEFAULT_PLUGIN" ] && [ "$(ls -A "$DEFAULT_PLUGIN" 2>/dev/null)" ]; then
    cp -a "$DEFAULT_PLUGIN/." "$PLUGIN_DIR/"
    echo "[setup-once] Installed plugin from image stash."
  else
    # Download and install at runtime
    INSTALL_DIR=$(mktemp -d)
    if curl -fsSL https://nowledge-mem.nasw.heiyu.space/install/hermes-setup.sh \
       | HERMES_HOME="$INSTALL_DIR/.hermes" bash 2>/dev/null; then
      if [ -d "$INSTALL_DIR/.hermes/plugins/nowledge-mem" ]; then
        cp -a "$INSTALL_DIR/.hermes/plugins/nowledge-mem/." "$PLUGIN_DIR/"
        echo "[setup-once] Installed plugin from remote."
      fi
    fi
    rm -rf "$INSTALL_DIR"
  fi
  chown -R 1000:1000 "$PLUGIN_DIR" 2>/dev/null || true
fi

echo "[setup-once] Done."
