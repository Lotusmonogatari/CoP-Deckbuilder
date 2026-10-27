"""Adds header notes (cell comments) to a column header in the design workbook.

The workbook already has a comments part and a VML drawing per tab; this
appends one <comment> and one VML note shape to each, leaving every other part
of the .xlsx byte-for-byte untouched (never save the workbook with openpyxl).

    python3 tools/workbook/add_notes.py        # applies NOTES below
or  from add_notes import add_notes; add_notes(path, [(sheet, "AD", "text"), ...])

Only tabs that already have notes are supported (all content tabs do).
"""
import re
import sys
import zipfile
from xml.sax.saxutils import escape

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from wbx import col2n  # noqa: E402

PATH = "design/Game_Workbook.xlsx"


def _sheet_part(z, name):
    wb = z.read("xl/workbook.xml").decode()
    rels = z.read("xl/_rels/workbook.xml.rels").decode()
    rid = re.search(r'<sheet [^>]*name="%s"[^>]*r:id="([^"]+)"' % re.escape(escape(name, {'"': "&quot;"})), wb).group(1)
    m = re.search(r'Id="%s"[^>]*Target="([^"]+)"|Target="([^"]+)"[^>]*Id="%s"' % (rid, rid), rels)
    return "xl/" + (m.group(1) or m.group(2)).lstrip("/").replace("xl/", "")


def add_notes(path, notes):
    z = zipfile.ZipFile(path)
    parts = {n: z.read(n) for n in z.namelist()}
    infos = {i.filename: i for i in z.infolist()}
    order = z.namelist()
    z.close()
    zz = zipfile.ZipFile(path)
    for sheet, col, text in notes:
        sp = _sheet_part(zz, sheet)
        rels = parts[sp.replace("worksheets/", "worksheets/_rels/") + ".rels"].decode()
        cm = "xl/" + re.search(r'Target="\.\./(comments\d+\.xml)"', rels).group(1)
        vm = "xl/drawings/" + re.search(r'Target="\.\./drawings/(vmlDrawing\d+\.vml)"', rels).group(1)
        c = parts[cm].decode()
        if 'ref="%s1"' % col in c:
            continue  # already has a note
        comment = ('<comment ref="%s1" authorId="0"><text><r><rPr><sz val="10"/><color theme="1"/>'
                   '<rFont val="Calibri"/><family val="2"/></rPr><t xml:space="preserve">%s</t></r></text></comment>'
                   % (col, escape(text)))
        parts[cm] = c.replace("</commentList>", comment + "</commentList>").encode()
        v = parts[vm].decode()
        ids = [int(i) for i in re.findall(r'<v:shape id="_x0000_s(\d+)"', v)]
        zs = [int(i) for i in re.findall(r"z-index:(\d+)", v)]
        n = col2n(col) - 1
        height = 40 + 12 * (len(text) // 38 + 1)
        shape = ('<v:shape id="_x0000_s%d" type="#_x0000_t202" style=\'position:absolute;margin-left:80pt;'
                 'margin-top:2pt;width:240pt;height:%dpt;z-index:%d;visibility:hidden\' fillcolor="infoBackground [80]" '
                 'o:insetmode="auto"><v:fill color2="infoBackground [80]"/><v:shadow on="t" color="none [81]" obscured="t"/>'
                 '<v:path o:connecttype="none"/><v:textbox style=\'mso-direction-alt:auto\'><div style=\'text-align:left\'></div>'
                 '</v:textbox><x:ClientData ObjectType="Note"><x:MoveWithCells/><x:SizeWithCells/>'
                 '<x:Anchor>%d, 15, 0, 2, %d, 15, %d, 4</x:Anchor><x:AutoFill>False</x:AutoFill><x:Row>0</x:Row>'
                 '<x:Column>%d</x:Column></x:ClientData></v:shape>'
                 % (max(ids) + 1, height, max(zs) + 1, n + 1, n + 5, height // 13 + 2, n))
        parts[vm] = v.replace("</xml>", shape + "</xml>").encode()
    zz.close()
    tmp = path + ".tmp"
    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as out:
        for name in order:
            out.writestr(infos[name], parts[name], compress_type=zipfile.ZIP_DEFLATED)
    import os
    os.replace(tmp, path)
