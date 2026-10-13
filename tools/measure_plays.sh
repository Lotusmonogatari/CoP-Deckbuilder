#!/bin/bash
# Measures how many cards a well-equipped player plays and how many turns end
# in one fight of each stage (the playtest bot, 20 fights, PC01), and writes
# design/bench/plays_per_stage.json. tools/content_depth.py reads it to size
# content: a room needs at least three times what a run is likely to meet.
# Usage: tools/measure_plays.sh ST05 ST09 ...   (default: every Combat stage)
cd "$(dirname "$0")/.."
GODOT="${GODOT:-.tools/godot}"
stages="$@"
if [ -z "$stages" ]; then
  stages=$(python3 -c "import json;print(' '.join(s['stage_id'] for s in json.load(open('data/stages.json')) if s.get('mode')=='Combat'))")
fi
out=design/bench/plays_per_stage.json
mkdir -p design/bench
[ -f "$out" ] || echo '{}' > "$out"
for st in $stages; do
  line=$(PLAYTEST_STAGE_TRIAL="$st:20" PLAYTEST_PROTAGONIST=PC01 xvfb-run -a "$GODOT" --headless --path . tools/playtest_optimal.tscn 2>&1 | grep "TRIAL PLAYS")
  python3 - "$st" "$line" "$out" <<'PY'
import sys,re,json
st,line,out=sys.argv[1:4]
m=re.search(r'([\d.]+) cards and ([\d.]+) turns',line)
if m:
    d=json.load(open(out)); d[st]={"cards":float(m.group(1)),"turns":float(m.group(2))}
    json.dump(d,open(out,'w'),indent=1,sort_keys=True); print(st,d[st])
PY
done
