#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-godot}"
mkdir -p build/maze3d/reports
export XDG_DATA_HOME="$PWD/build/maze3d/test-data"
timeout 120 "$GODOT" --headless --path maze3d --editor --import > build/maze3d/reports/import.txt 2>&1
if grep -nE 'SCRIPT ERROR|ERROR:' build/maze3d/reports/import.txt; then exit 1; fi
for suite in model scene jump character; do
  timeout 240 "$GODOT" --headless --fixed-fps 60 --audio-driver Dummy --path maze3d --script "res://tests/${suite}_test.gd" > "build/maze3d/reports/${suite}.txt" 2>&1
  cat "build/maze3d/reports/${suite}.txt"
  if grep -nE 'SCRIPT ERROR|ERROR:' "build/maze3d/reports/${suite}.txt"; then exit 1; fi
  grep -Eq '(MODEL|SCENE|JUMP|CHARACTER): [0-9]+ checks, 0 failures' "build/maze3d/reports/${suite}.txt"
done
