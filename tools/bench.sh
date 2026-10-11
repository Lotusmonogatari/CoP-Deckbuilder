#!/usr/bin/env bash
# Performance benchmark (tools/benchmark.gd). Not part of verify.sh: timings
# depend on the machine, so use it to compare before and after a change.
#
#   tools/bench.sh <label>            run both modes, save design/bench/<label>.json
#   tools/bench.sh --compare A B      compare design/bench/A.json with B.json
#
# Two modes: "headless" (no display; logic, scene building, memory) and
# "display" (a virtual X display via xvfb-run, so textures really reach the
# renderer and texture memory is measured). The display mode is skipped when
# xvfb-run is missing.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-.tools/godot}"
RUNS="${BENCH_RUNS:-9}"
mkdir -p design/bench

if [[ "${1:-}" == "--compare" ]]; then
  python3 - "$2" "$3" <<'PY'
import json, sys
a = json.load(open(f"design/bench/{sys.argv[1]}.json"))
b = json.load(open(f"design/bench/{sys.argv[2]}.json"))
def flat(d, prefix=""):
    out = {}
    for k, v in d.items():
        key = f"{prefix}{k}"
        if isinstance(v, dict): out.update(flat(v, key + "."))
        elif isinstance(v, (int, float)) and not isinstance(v, bool): out[key] = v
    return out
fa, fb = flat(a), flat(b)
print(f"{'measurement':58} {sys.argv[1]:>12} {sys.argv[2]:>12} {'change':>9}")
worse = 0
for k in sorted(set(fa) | set(fb)):
    x, y = fa.get(k), fb.get(k)
    if x is None or y is None: continue
    ch = "" if x == 0 else f"{(y - x) / x * 100:+.0f}%"
    flag = ""
    # Lower is better for times and memory; a counter like cards_played is info only.
    # Timings are noisy on a shared machine (20-70% run to run), memory is not:
    # flag a timing only past 30%, memory past 5%.
    limit = 0.05 if "_mb" in k else 0.30
    if (k.endswith("_ms") or "_mb" in k) and "_max_" not in k and x > 0 and (y - x) / x > limit and (y - x) > 1:
        flag = "  WORSE"; worse += 1
    print(f"{k:58} {x:>12} {y:>12} {ch:>9}{flag}")
print(f"\n{worse} measurement(s) worse than the noise limit (timings 30%, memory 5%).")
PY
  exit 0
fi

LABEL="${1:?usage: tools/bench.sh <label> | --compare A B}"
TMP="$(mktemp -d)"
echo "Benchmark '$LABEL' ($RUNS runs per measurement)"
BENCH_RUNS="$RUNS" BENCH_OUT="$TMP/headless.json" "$GODOT" --headless --path . tools/benchmark.tscn >/dev/null 2>&1
if command -v xvfb-run >/dev/null; then
  BENCH_RUNS="$RUNS" BENCH_OUT="$TMP/display.json" xvfb-run -a --server-args="-screen 0 1080x2340x24" \
    "$GODOT" --path . tools/benchmark.tscn >/dev/null 2>&1 || echo "  (display mode failed; headless only)"
fi
python3 - "$TMP" "design/bench/$LABEL.json" <<'PY'
import json, os, sys
tmp, out = sys.argv[1], sys.argv[2]
result = {}
for mode in ("headless", "display"):
    path = os.path.join(tmp, mode + ".json")
    if os.path.exists(path): result[mode] = json.load(open(path))
json.dump(result, open(out, "w"), indent=2, sort_keys=True)
print("  saved", out, "modes:", ", ".join(result))
PY
rm -rf "$TMP"
