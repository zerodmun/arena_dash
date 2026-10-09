#!/usr/bin/env bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$TASK_ROOT"
python3 tools/build_web_shell.py
mkdir -p build/web
godot --headless --path "$TASK_ROOT" --export-release Web build/web/index.html
