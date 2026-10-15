#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p build/godot
GODOT="${GODOT:-godot}"
timeout 120 "$GODOT" --headless --path godot --editor --import > build/godot/import-report.txt 2>&1
! grep -E 'SCRIPT ERROR|Parse Error|ERROR:' build/godot/import-report.txt
for suite in round scene; do
  timeout 120 "$GODOT" --headless --path godot --script "res://tests/test_${suite}.gd" 2>&1 | tee "build/godot/${suite}-report.txt"
  ! grep -E 'SCRIPT ERROR|ERROR:|FAIL:|[1-9][0-9]* failures' "build/godot/${suite}-report.txt"
  grep -Eq '(MODEL|SCENE): [0-9]+ checks, 0 failures' "build/godot/${suite}-report.txt"
done
