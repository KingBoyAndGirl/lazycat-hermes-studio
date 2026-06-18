#!/bin/bash
# /opt/setup-once.sh — runs as root before entrypoint
# Installs nmem-cli into persisted ~/ on first boot.
set -euo pipefail

AGENT_HOME="/home/agent"
NMEM_BIN="$AGENT_HOME/.local/bin/nmem"
MARKER="$AGENT_HOME/.lzc-init-done"

if [ ! -f "$MARKER" ]; then
  echo "[setup-once] First boot — initializing..."
  mkdir -p "$AGENT_HOME/.local/bin"
  mkdir -p "$AGENT_HOME/.nowledge-mem"
  chown -R 1000:1000 "$AGENT_HOME"
  touch "$MARKER"
  chown 1000:1000 "$MARKER"
fi

# Install nmem if not present (survives in ~/ after first install)
if [ ! -x "$NMEM_BIN" ]; then
  echo "[setup-once] Installing nmem-cli..."
  uv tool install nmem-cli --no-cache 2>&1 || true
  # uv puts it in $HOME/.local/bin which is /home/agent/.local/bin
  if [ -x "$NMEM_BIN" ]; then
    echo "[setup-once] nmem-cli installed."
  else
    # If HOME was root during install, link it
    if [ -x "/root/.local/bin/nmem" ]; then
      mkdir -p "$AGENT_HOME/.local/bin"
      ln -sf /root/.local/bin/nmem "$NMEM_BIN"
      echo "[setup-once] nmem-cli linked from /root/.local/bin."
    fi
  fi
fi

# Ensure ownership
chown -R 1000:1000 "$AGENT_HOME/.local" 2>/dev/null || true
chown 1000:1000 "$MARKER" 2>/dev/null || true

echo "[setup-once] Done."
