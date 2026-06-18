#!/bin/bash
# /opt/setup-once.sh — runs as root before entrypoint (LazyCat setup_script)
set -euo pipefail

AGENT_HOME="/home/agent"
HERMES_HOME="$AGENT_HOME/.hermes"
PLUGIN_DIR="$HERMES_HOME/plugins/nowledge-mem"
DEFAULT_PLUGIN="/opt/nowledge-mem-default"
MARKER="$AGENT_HOME/.lzc-init-done"

if [ ! -f "$MARKER" ]; then
  echo "[setup-once] First boot — initializing persistent home..."
  mkdir -p "$HERMES_HOME/plugins"
  mkdir -p "$AGENT_HOME/.local/bin"
  mkdir -p "$AGENT_HOME/.nowledge-mem"

  if [ ! -f "$PLUGIN_DIR/plugin.yaml" ] && [ -d "$DEFAULT_PLUGIN" ] && [ "$(ls -A "$DEFAULT_PLUGIN" 2>/dev/null)" ]; then
    cp -a "$DEFAULT_PLUGIN" "$PLUGIN_DIR"
    echo "[setup-once] Installed Nowledge Mem plugin."
  fi

  if [ ! -x "$AGENT_HOME/.local/bin/nmem" ] && [ -x "/usr/local/bin/nmem" ]; then
    ln -sf /usr/local/bin/nmem "$AGENT_HOME/.local/bin/nmem"
    echo "[setup-once] Linked nmem."
  fi

  chown -R 1000:1000 "$AGENT_HOME"
  touch "$MARKER"
  chown 1000:1000 "$MARKER"
  echo "[setup-once] Initialization complete."
else
  echo "[setup-once] Already initialized."
fi

# Self-heal
if [ ! -x "$AGENT_HOME/.local/bin/nmem" ] && [ -x "/usr/local/bin/nmem" ]; then
  mkdir -p "$AGENT_HOME/.local/bin"
  ln -sf /usr/local/bin/nmem "$AGENT_HOME/.local/bin/nmem"
  chown -R 1000:1000 "$AGENT_HOME/.local/bin"
  echo "[setup-once] Restored nmem symlink."
fi

if [ ! -f "$PLUGIN_DIR/plugin.yaml" ] && [ -d "$DEFAULT_PLUGIN" ] && [ "$(ls -A "$DEFAULT_PLUGIN" 2>/dev/null)" ]; then
  mkdir -p "$PLUGIN_DIR"
  cp -a "$DEFAULT_PLUGIN" "$PLUGIN_DIR"
  chown -R 1000:1000 "$PLUGIN_DIR"
  echo "[setup-once] Restored plugin."
fi

echo "[setup-once] Done."
