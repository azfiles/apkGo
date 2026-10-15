#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
python3 scripts/godot/android-smoke.py | tee build/godot/android-report.txt
