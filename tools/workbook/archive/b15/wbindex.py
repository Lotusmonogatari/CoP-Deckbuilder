"""Finds the workbook cell behind a ledger row (writing review, 2026-11-09).

A ledger row names a data file, an ID and a JSON field, and quotes the cell's
current text. The cell is the one, in an exported tab, whose text equals that
quote, in a row that also holds the ID (or one part of a composite ID such as
"EV41/A" or "LV99#247"), and, when the field maps to a known column of that
tab, in that column. Anything not found exactly once is reported, never guessed.
"""
import re, sys
sys.path.insert(0, "tools/workbook"); sys.path.insert(0, "tools")
from wbx import WB
import export_data as ED


def norm(s):
    return re.sub(r"\s+", " ", str(s or "").replace(" ", " ")).strip()


class Index:
    def __init__(self, path="design/Game_Workbook.xlsx"):
        self.w = WB(path)
        self.rows = {}
        self.field_cols = {}          # tab -> {json key: column letter}
        self.by_text = {}             # normalised text -> [(tab, row, col)]
        for tab, cfg in ED.SHEETS.items():
            if tab not in self.w.sheet:
                continue
            rows = self.w.rows(tab)
            self.rows[tab] = rows
            header = rows.get(1, {})
            hmap = {ED.normalise_header(v): c for c, v in header.items()}
            fc = {}
            for col in cfg.get("columns", []):
                c = hmap.get(ED.normalise_header(col[0]))
                if c:
                    fc[col[1]] = c
            self.field_cols[tab] = fc
            for r, cells in rows.items():
                if r == 1:
                    continue
                for c, v in cells.items():
                    self.by_text.setdefault(norm(v), []).append((tab, r, c))

    def text(self, tab, row, col):
        return self.rows[tab].get(row, {}).get(col)

    def locate(self, id_, field, original):
        """Returns ((tab, row, col), how) or (None, reason)."""
        cands = self.by_text.get(norm(original), [])
        if not cands:
            return None, "original text not found in the workbook"
        tokens = [t.strip() for t in re.split(r"[/#;]", id_) if t.strip()]
        tokens += [t.split(".")[0] for t in tokens if "." in t and re.match(r"^[A-Z]+\d+\.", t)]
        hits = []
        for tab, r, c in cands:
            vals = set(norm(v) for v in self.rows[tab][r].values())
            if any(t in vals for t in tokens):
                fc = self.field_cols.get(tab, {})
                if field in fc and fc[field] != c:
                    continue
                hits.append((tab, r, c))
        hits = sorted(set(hits))
        if len(hits) == 1:
            return hits[0], "id+text"
        if len(hits) > 1:
            return None, f"text found {len(hits)} times in rows holding the ID"
        return None, f"text found {len(cands)} times but never in a row holding the ID"
