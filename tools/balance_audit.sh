#!/usr/bin/env bash
# The dynamic half of the balance audit (design/BALANCE_AUDIT_PROCESS.md).
#
#   tools/balance_audit.sh [out_dir]      (default design/bench/balance)
#
# Runs the playtest bot headless in several isolated processes (each gets its
# own XDG_DATA_HOME so their saves cannot contaminate each other):
#   - four full runs, one per protagonist (economy, standings, card usage);
#   - stage-trial sweeps: every Combat stage, starter kit (opening deck only)
#     several times over different random decks, and the full kit.
# Then tools/balance_audit.py turns the logs plus the static data into the
# report. Takes 15-25 minutes on four cores.
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-.tools/godot}"
OUT="${1:-design/bench/balance}"
mkdir -p "$OUT"
run() {  # name, env...
  local name="$1"; shift
  local home; home="$(mktemp -d)"
  env XDG_DATA_HOME="$home" HOME="$home" "$@" "$GODOT" --headless --path . tools/playtest_optimal.tscn > "$OUT/$name.log" 2>&1
  rm -rf "$home"
}
# Batch 1: the four full runs in parallel.
for pc in PC01 PC02 PC03 PC04; do
  run "full_$pc" PLAYTEST_PROTAGONIST=$pc &
done
wait
# Batch 2: sweeps in parallel (four at a time).
run sweep_starter_a PLAYTEST_TRIAL_SWEEP=25 PLAYTEST_TRIAL_KIT=starter PLAYTEST_PROTAGONIST=PC01 &
run sweep_starter_b PLAYTEST_TRIAL_SWEEP=25 PLAYTEST_TRIAL_KIT=starter PLAYTEST_PROTAGONIST=PC02 &
run sweep_starter_c PLAYTEST_TRIAL_SWEEP=25 PLAYTEST_TRIAL_KIT=starter PLAYTEST_PROTAGONIST=PC03 &
run sweep_starter_d PLAYTEST_TRIAL_SWEEP=25 PLAYTEST_TRIAL_KIT=starter PLAYTEST_PROTAGONIST=PC04 &
wait
run sweep_full_a PLAYTEST_TRIAL_SWEEP=25 PLAYTEST_TRIAL_KIT=full PLAYTEST_PROTAGONIST=PC01 &
run sweep_full_b PLAYTEST_TRIAL_SWEEP=25 PLAYTEST_TRIAL_KIT=full PLAYTEST_PROTAGONIST=PC03 &
wait
echo "logs in $OUT"
