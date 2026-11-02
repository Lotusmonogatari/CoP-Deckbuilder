#!/bin/bash
# Runs the strategy playtest (tools/strategy_playtest.gd) for many strategies and
# seeds, four at a time, appending one JSON line per run to the output file.
#   tools/strategy_runs.sh OUT.jsonl "seeds" "protagonists" strategy [strategy ...]
#   tools/strategy_runs.sh design/bench/strategy_runs.jsonl "1 2 3" "PC02" baseline hoarder
#   tools/strategy_runs.sh OUT.jsonl "1 2 3" "PC02" all     (every named strategy)
# PLAYTEST_WEEKS (default 30) sets how many game weeks each run lasts.
# PLAYTEST_DIFFICULTY (relaxed, standard or harder) sets Campaign Pressure.
cd "$(dirname "$0")/.."
GODOT="${GODOT:-.tools/godot}"
out="$1"; seeds="$2"; protagonists="$3"; shift 3
strategies="$@"
if [ "$strategies" = "all" ]; then
  strategies=$(python3 - <<'PY'
import re
src=open('tools/strategy_playtest.gd').read()
block=src.split('const STRATEGIES := {')[1].split('\n}\n')[0]
print(' '.join(re.findall(r'^\t"(\w+)":',block,re.M)))
PY
)
fi
mkdir -p "$(dirname "$out")" "$out.parts"
jobs=()
for st in $strategies; do for pc in $protagonists; do for sd in $seeds; do
  jobs+=("$st $pc $sd")
done; done; done
printf '%s\n' "${jobs[@]}" | xargs -P 4 -L 1 bash -c '
  PLAYTEST_STRATEGY=$0 PLAYTEST_PROTAGONIST=$1 PLAYTEST_SEED=$2 PLAYTEST_WEEKS=${PLAYTEST_WEEKS:-30} PLAYTEST_DIFFICULTY=${PLAYTEST_DIFFICULTY:-standard} \
  PLAYTEST_OUT='"$out"'.parts/$0_$1_$2.json timeout 600 '"$GODOT"' --headless --path . tools/strategy_playtest.tscn > /dev/null 2>&1
  echo "done $0 $1 $2"'
cat "$out".parts/*.json >> "$out" 2>/dev/null; rm -rf "$out".parts
