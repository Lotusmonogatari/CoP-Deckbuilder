"""Checks the workbook's formula records the way Excel's repair step does.

Reports (1) a shared formula whose ref range does not contain its own cell or
one of its children, and (2) calcChain entries naming a cell with no formula.
Excel removes those records and shows "Excel completed file level validation
and repair" when a workbook has them. Usage: python3 tools/workbook/check_formulas.py [path]
"""
import re
import sys
import zipfile

PATH = "design/Game_Workbook.xlsx"


def col2n(col):
    n = 0
    for ch in col:
        n = n * 26 + ord(ch) - 64
    return n


def cell_xy(ref):
    m = re.match(r"([A-Z]+)(\d+)$", ref)
    return col2n(m.group(1)), int(m.group(2))


def inside(ref_range, cell):
    parts = ref_range.split(":")
    (c1, r1), (c2, r2) = cell_xy(parts[0]), cell_xy(parts[-1])
    c, r = cell_xy(cell)
    return c1 <= c <= c2 and r1 <= r <= r2


def sheet_parts(z):
    wb = z.read("xl/workbook.xml").decode()
    rels = z.read("xl/_rels/workbook.xml.rels").decode()
    out = []
    for index, m in enumerate(re.finditer(r'<sheet [^>]*name="([^"]+)"[^>]*r:id="([^"]+)"', wb), start=1):
        t = re.search(r'Id="%s"[^>]*Target="([^"]+)"|Target="([^"]+)"[^>]*Id="%s"' % (m.group(2), m.group(2)), rels)
        out.append((index, m.group(1), "xl/" + (t.group(1) or t.group(2)).lstrip("/").replace("xl/", "")))
    return out


def problems(path):
    z = zipfile.ZipFile(path)
    found = []
    formula_cells = {}
    for index, name, part in sheet_parts(z):
        xml = z.read(part).decode()
        cells = set()
        masters = {}
        for m in re.finditer(r'<c r="([A-Z]+\d+)"[^>]*>(.*?)</c>', xml, re.S):
            body = m.group(2)
            f = re.search(r"<f([^>]*)(/>|>)", body)
            if not f:
                continue
            cells.add(m.group(1))
            attrs = f.group(1)
            si = re.search(r'si="(\d+)"', attrs)
            ref = re.search(r'ref="([^"]+)"', attrs)
            if "shared" in attrs and ref and si:
                masters[si.group(1)] = (m.group(1), ref.group(1))
                if not inside(ref.group(1), m.group(1)):
                    found.append(f"{name}: shared formula at {m.group(1)} claims {ref.group(1)}")
        for m in re.finditer(r'<c r="([A-Z]+\d+)"[^>]*><f[^>]*t="shared"[^>]*si="(\d+)"[^>]*/>', xml):
            if m.group(2) in masters and not inside(masters[m.group(2)][1], m.group(1)):
                found.append(f"{name}: {m.group(1)} is outside its shared range {masters[m.group(2)][1]}")
        formula_cells[index] = (name, cells)
    if "xl/calcChain.xml" in z.namelist():
        current = None
        for m in re.finditer(r'<c r="([A-Z]+\d+)"(?: i="(\d+)")?[^>]*/>', z.read("xl/calcChain.xml").decode()):
            if m.group(2):
                current = int(m.group(2))
            if current in formula_cells and m.group(1) not in formula_cells[current][1]:
                found.append(f"calcChain: {formula_cells[current][0]}!{m.group(1)} has no formula")
    return found


if __name__ == "__main__":
    issues = problems(sys.argv[1] if len(sys.argv) > 1 else PATH)
    for line in issues[:40]:
        print(line)
    print(f"{len(issues)} problem(s)")
    sys.exit(1 if issues else 0)
