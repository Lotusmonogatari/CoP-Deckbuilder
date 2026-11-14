#!/usr/bin/env bash
# Audit Phase 4: runs the seeded harness for both policies, both kits and the
# four protagonists (and Relaxed and Harder for the greedy starter kit).
#   audit/tests/run_sims.sh            (about 5 minutes on 4 cores)
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-.tools/godot}"
OUT="audit/tests/results"; mkdir -p "$OUT"
work="$(mktemp -d)"
run() {  # policy kit pc trials seed pressure
  XDG_DATA_HOME="$work/$1_$2_$3_$5_$6" AUDIT_POLICY=$1 AUDIT_KIT=$2 AUDIT_PC=$3 AUDIT_TRIALS=$4 AUDIT_SEED=$5 \
  AUDIT_PRESSURE=$6 AUDIT_OUT="$PWD/$OUT/sim_$1_$2_$3_$6_s$5.json" \
  "$GODOT" --headless --path . audit/tests/sim_harness.tscn 2>/dev/null | grep "AUDIT SIM"
}
export -f run; export GODOT OUT work
{
  # A different base seed for each protagonist, so the four runs are four
  # independent samples (100 distinct fights per room for the starter kit).
  n=10
  for pc in PC01 PC02 PC03 PC04; do
    n=$((n+1)); echo "greedy starter $pc 25 $n standard"; echo "random starter $pc 25 $n standard"
  done
  echo "greedy full PC01 25 21 standard"; echo "greedy full PC02 25 22 standard"
  echo "random full PC01 25 21 standard"; echo "random full PC02 25 22 standard"
  # Same seed as the Standard PC02 run, so the three pressures are compared like for like.
  echo "greedy starter PC02 25 12 relaxed"; echo "greedy starter PC02 25 12 harder"
} | xargs -P "${JOBS:-4}" -L 1 bash -c 'run "$@"' _
rm -rf "$work"
