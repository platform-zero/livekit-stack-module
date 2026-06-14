#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
test -f "$repo_root/stack.module.json"
python3 - "$repo_root/stack.module.json" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
for path in data.get("overlays", []):
    import pathlib
    if not (pathlib.Path(sys.argv[1]).parent / path).exists():
        raise SystemExit(f"missing overlay: {path}")
PY
