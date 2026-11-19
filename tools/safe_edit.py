#!/usr/bin/env python3
"""Safe scripted edits to text files (2026-11-19).

WHY THIS EXISTS. Twice a scripted edit corrupted a test file. Both times the script cut a block of text out
with `text[text.index(first) : text.index(last)]` and then called `text.replace(block, new)`. When `last`
turned up BEFORE `first` (or the same line twice), the slice was empty, and Python's `"abc".replace("", "X")`
puts X between every character. The file compiled to nonsense and a full verify run timed out on it.

These helpers refuse the cases that did the damage:

  * the text to replace must not be empty;
  * it must occur EXACTLY once (not zero times, not twice);
  * a block between two markers must have the start marker before the stop marker, and each marker must be
    unique, and the block must be short (so a stray marker cannot swallow half the file);
  * the file is written only after every check has passed, so a refused edit leaves it untouched;
  * the new file's length is checked against what the edit should have produced.

Use from another script:

    import sys; sys.path.insert(0, "tools")
    from safe_edit import replace_once, replace_block
    replace_once("tests/test_x.gd", "assert_eq(named, 42)", "assert_eq(named, 51)")
    replace_block("tests/x_driver.gd", "## The old heading", "\\tvar choice := ", new_text)

For a one-line change in an editor session, prefer the Edit tool, which has the same exactly-once rule built in.
Run `python3 tools/safe_edit.py --selftest` to check these helpers (tools/verify.sh does).
"""
import sys
import tempfile
from pathlib import Path

DEFAULT_MAX_BLOCK_LINES = 60


class EditError(Exception):
    """An edit was refused. The file has not been changed."""


def _read(path):
    return Path(path).read_text(encoding="utf-8")


def _write(path, text):
    Path(path).write_text(text, encoding="utf-8")


def replace_once(path, old, new):
    """Replace `old` with `new` in the file, which must contain `old` exactly once."""
    if not old:
        raise EditError("the text to replace is empty (that would insert the new text between every character)")
    if old == new:
        raise EditError("the new text is the same as the old text")
    text = _read(path)
    found = text.count(old)
    if found != 1:
        raise EditError("%s: the text to replace occurs %d times, not exactly once: %r" % (path, found, old[:60]))
    start = text.index(old)
    result = text[:start] + new + text[start + len(old):]
    if len(result) != len(text) - len(old) + len(new):  # cannot happen; a guard against a future edit of this file
        raise EditError("%s: the result is not the length this edit should give" % path)
    _write(path, result)


def replace_block(path, start_marker, stop_marker, new, max_lines=DEFAULT_MAX_BLOCK_LINES):
    """Replace the block from `start_marker` (included) up to `stop_marker` (not included) with `new`.

    Each marker must occur exactly once in the file, the start must come before the stop, the block must not be
    empty, and it must be no longer than `max_lines` lines."""
    for name, marker in (("start", start_marker), ("stop", stop_marker)):
        if not marker:
            raise EditError("the %s marker is empty" % name)
    text = _read(path)
    for name, marker in (("start", start_marker), ("stop", stop_marker)):
        found = text.count(marker)
        if found != 1:
            raise EditError("%s: the %s marker occurs %d times, not exactly once: %r" % (path, name, found, marker[:60]))
    first = text.index(start_marker)
    last = text.index(stop_marker)
    if last <= first:
        raise EditError("%s: the stop marker comes before the start marker, so the block would be empty or backwards" % path)
    block = text[first:last]
    if block.count("\n") > max_lines:
        raise EditError("%s: the block is %d lines long (the limit is %d); check the markers" % (path, block.count("\n"), max_lines))
    result = text[:first] + new + text[last:]
    if len(result) != len(text) - len(block) + len(new):
        raise EditError("%s: the result is not the length this edit should give" % path)
    _write(path, result)


def _selftest():
    failures = []

    def expect_refused(what, call, path, before):
        try:
            call()
        except EditError:
            if Path(path).read_text(encoding="utf-8") != before:
                failures.append("%s: the file changed although the edit was refused" % what)
            return
        failures.append("%s: the edit was not refused" % what)

    with tempfile.TemporaryDirectory() as folder:
        path = str(Path(folder) / "sample.txt")
        original = "alpha\nbeta\ngamma\nbeta\ndelta\n"
        _write(path, original)

        expect_refused("an empty old text", lambda: replace_once(path, "", "X"), path, original)
        expect_refused("a missing old text", lambda: replace_once(path, "omega", "X"), path, original)
        expect_refused("a text that occurs twice", lambda: replace_once(path, "beta", "X"), path, original)
        expect_refused("old equal to new", lambda: replace_once(path, "alpha", "alpha"), path, original)
        expect_refused("a reversed block (the original mistake)", lambda: replace_block(path, "delta", "alpha", "X"), path, original)
        expect_refused("a stop marker that is also the start", lambda: replace_block(path, "alpha", "alpha", "X"), path, original)
        expect_refused("a start marker that occurs twice", lambda: replace_block(path, "beta", "delta", "X"), path, original)
        expect_refused("a block that is too long", lambda: replace_block(path, "alpha", "delta", "X", max_lines=2), path, original)

        replace_once(path, "gamma", "GAMMA")
        if _read(path) != "alpha\nbeta\nGAMMA\nbeta\ndelta\n":
            failures.append("a plain replace gave the wrong text")
        replace_block(path, "alpha", "delta", "one\ntwo\n")
        if _read(path) != "one\ntwo\ndelta\n":
            failures.append("a block replace gave the wrong text")

        # The mistake itself, shown: this is what the bare Python call does with an empty block.
        if "abc".replace("", "-") != "-a-b-c-":
            failures.append("Python's behavior on an empty string changed; revisit the guard")

    if failures:
        print("safe_edit self-test FAILED:")
        for line in failures:
            print("  X " + line)
        return 1
    print("safe_edit self-test: ok (8 refusals, 2 edits)")
    return 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(_selftest())
    print(__doc__)
