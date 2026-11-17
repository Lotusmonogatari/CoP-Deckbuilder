#!/bin/bash
# Runs the text sweep (tools/text_sweep.gd) for the three text sizes in parallel and joins
# the files. Usage: tools/text_sweep.sh [out.csv] [shots_dir]
# Exit 1 when any screen has letter-stacking or off-screen text (overlap and small buttons
# are report only). About a minute on four cores.
cd "$(dirname "$0")/.."
OUT="${1:-audit/text_sweep.csv}"
SHOTS="${2:-}"
GODOT="${GODOT:-.tools/godot}"
WORK="$(mktemp -d)"
for t in small normal large; do
  (
    SWEEP_TEXT=$t SWEEP_OUT="$WORK/$t.csv" SWEEP_SHOTS="$SHOTS" \
    xvfb-run -a --server-args="-screen 0 1080x2340x24" "$GODOT" --path . tools/text_sweep.tscn > "$WORK/$t.log" 2>&1
    echo $? > "$WORK/$t.status"
  ) &
done
wait
echo "screen,shape,text_size,control,problem,detail" > "$OUT"
for t in small normal large; do tail -n +2 "$WORK/$t.csv" >> "$OUT" 2>/dev/null; done
status=0
for t in small normal large; do
  grep "TEXT SWEEP" "$WORK/$t.log"
  if [ "$(cat "$WORK/$t.status")" != "0" ]; then status=1; fi
done
echo "wrote $OUT ($(($(wc -l < "$OUT") - 1)) rows)"
exit $status
