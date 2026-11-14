#!/usr/bin/env bash
# Audit Phase 6: runs every edge case in its own process and collects what it
# printed plus any script errors into audit/tests/results/edge_cases.json.
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-.tools/godot}"
out="audit/tests/results/edge_cases.json"; mkdir -p audit/tests/results
cases=$(grep -A8 '^const CASES' audit/tests/edge_probe.gd | grep -o '"[a-z_]*"' | tr -d '"')
python3 - "$GODOT" $cases <<'PY'
import json, os, subprocess, sys, tempfile
godot, cases = sys.argv[1], sys.argv[2:]
result = {}
for case in cases:
    work = tempfile.mkdtemp()
    env = dict(os.environ, AUDIT_CASE=case, XDG_DATA_HOME=work)
    try:
        p = subprocess.run([godot, "--headless", "--path", ".", "audit/tests/edge_probe.tscn"],
                           capture_output=True, text=True, timeout=120, env=env)
        text, code = p.stdout + p.stderr, p.returncode
    except subprocess.TimeoutExpired as e:
        text, code = (e.stdout or b"").decode() if isinstance(e.stdout, bytes) else (e.stdout or ""), "TIMEOUT"
    lines = text.splitlines()
    said, errors, k = [], [], 0
    while k < len(lines):
        l = lines[k]
        if l.startswith("EDGE "):
            said.append(l)
            while k + 1 < len(lines) and lines[k + 1].startswith("    "):
                k += 1; said[-1] += "\n" + lines[k]
        elif "SCRIPT ERROR" in l or l.startswith("ERROR:") and "NavigationServer" not in l and "audio" not in l.lower() and "init_output_device" not in l:
            if "NavigationServer" not in l and "gut" not in l:
                errors.append(l.strip() + (" || " + lines[k + 1].strip() if k + 1 < len(lines) else ""))
        k += 1
    result[case] = {"said": said, "errors": errors[:8], "exit": code}
    print(case, "->", len(said), "lines,", len(errors), "errors, exit", code)
json.dump(result, open("audit/tests/results/edge_cases.json", "w"), indent=1)
PY
