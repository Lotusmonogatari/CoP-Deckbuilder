# Benchmark results

Saved by `tools/bench.sh <label>` (see `tools/benchmark.gd` for what each number means).
`tools/bench.sh --compare baseline <label>` prints a before/after table.

- `baseline.json`: 2026-10-11, before any performance work.

Each file has two modes: `headless` (no display) and `display` (virtual display, so texture memory is real).
Timings on this shared build machine wander 20-70% between identical runs; memory is steady. Trust memory, and only large timing changes.
