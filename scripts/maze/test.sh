#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p build/maze
GODOT="${GODOT:-godot}"
timeout 120 "$GODOT" --headless --path maze-godot --editor --import > build/maze/import-report.txt 2>&1
if rg -n 'SCRIPT ERROR|Parse Error|ERROR:' build/maze/import-report.txt; then exit 1; fi
for suite in model scene; do
  timeout 120 "$GODOT" --headless --fixed-fps 60 --path maze-godot --script "res://tests/test_${suite}.gd" > "build/maze/${suite}-report.txt" 2>&1
  cat "build/maze/${suite}-report.txt"
  if rg -n 'SCRIPT ERROR|ERROR:|FAIL:' "build/maze/${suite}-report.txt"; then exit 1; fi
  rg -q '(MODEL|SCENE): [0-9]+ checks, 0 failures' "build/maze/${suite}-report.txt"
done
