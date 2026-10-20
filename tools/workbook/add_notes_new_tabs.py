"""Gives tabs that have NO notes part yet their first header notes.

add_notes.py can only append to a tab that already has a comments part and a
VML drawing. A tab created with wbx.add_sheet has neither, so this builds both
(plus the sheet's relationships file, its <legacyDrawing> element and the
content-type entry) and writes every note for that tab in one go. Every other
part of the .xlsx is copied byte for byte. Run once per new tab:

    python3 tools/workbook/add_notes_new_tabs.py
"""
import os
import re
import sys
import zipfile
from xml.sax.saxutils import escape

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from wbx import col2n  # noqa: E402
from add_notes import _sheet_part  # noqa: E402

PATH = "design/CoP_Starter_Card_Stage_Data.xlsx"

NOTES = {
    "Bill Components": [
        ("A", "Component ID, CBxxx: the owner's organization number then a slot digit (CB051). Never reused. Content rows (Stage Questions, Player Cues, Opponent Cues, Transition Dialogue) point at a component through their own Component ID column."),
        ("B", "Owner: the Booster ID (BOxx) of the non-party organization this component belongs to. The exporter rejects a party-body owner (Party Headquarters, Party Faction, Party Activists, Selection Committee follow the player's party, not a patron)."),
        ("C", "Slot: X or Y = the two parts of the owner's Favor bill; V = a spare Favor part used when X or Y is already law or the player amends; Z and W = the owner's own Flagship parts (no spare); A, B, C, D = offers the owner lends to an ally's Flagship (an ally needs one per Flagship naming it, plus a spare). A swap always stays inside its pool: Favor (X,Y,V), Flagship (Z,W), offer (A-D)."),
        ("D", "Short Label: a few words for lists. Not shown in the bill's name."),
        ("E", "Phrase: written to finish 'A bill to ...' (lower case, no full stop). A bill's name joins its parts' phrases, so each must read on its own and in a list of two or three."),
        ("F", "Description: one sentence for the Request and Draft panels. Plain English, no clock words."),
        ("G", "Hearing Stage: the committee stage (STxx) this component's level opens its hearing in. The exporter checks it is a real stage."),
        ("H", "Value Tags: 'Dimension +weight; Dimension -weight' using the 34 dimension names on the Party Values tab, weights -1 to 1. Each party's lean on the bill is the sum of tag x that party's salience; a lean of 30 or more takes a side. The exporter rejects an unknown dimension."),
        ("I", "Gains: who is pleased if this passes, as 'BOxx +N' (semicolon list). Scaled by Balance 'Custom Law Scale %' when a bill is voted."),
        ("J", "Loses: who is annoyed if this passes, as 'BOxx -N'. Negative numbers only."),
        ("K", "Excludes: component IDs that cannot share a bill with this one (Draft a Bill refuses the mix). Blank = none."),
        ("L", "Each Level Effect: reserved. The game does not read this column yet; leave blank."),
        ("M", "Amend Options: reserved. The game does not read this column; Amend always offers the other unused parts of the same pool (Favor: the spare V; Flagship: another of the ally's offers)."),
    ],
    "Patron Bills": [
        ("A", "Patron Bill ID, PBxx: organization number + 1 (Favor) or 2 (Flagship) (PB051 / PB052). One Favor and one Flagship per organization."),
        ("B", "Organization: the owner's Booster ID. The request appears when this organization's standing reaches the threshold."),
        ("C", "Kind: Favor (the owner's two parts, asked at Balance 'Patron Favor Threshold') or Flagship (the owner's Z and W plus one offer from the ally, asked at the Flagship threshold, and only after the Favor is resolved)."),
        ("D", "Threshold: standing needed for this request. Blank = the Balance default for its kind."),
        ("E", "Components: the component IDs in the bill, semicolon list. A Favor uses the owner's X and Y; a Flagship the owner's Z, W and one ally offer. The exporter checks the slots."),
        ("F", "Ally: a Flagship's partner organization (Booster ID) whose offer is part of the bill and who is also pleased on a pass. Blank on a Favor."),
        ("G", "Template ID: the Bill Level Templates row that builds the level's stages (BT01 Favor, BT02 Flagship)."),
        ("H", "Request Line: the Request panel's opening sentence. Fill {org} and {bill}."),
        ("I", "Accept Line: said when the player carries the bill. Fill {org}."),
        ("J", "Decline Line: said when the player declines. Fill {org}."),
        ("K", "Pass Line: said when the bill passes. Fill {org}."),
        ("L", "Fail Line: said when the bill fails. Fill {org}."),
        ("M", "Note: for the designer; never shown."),
    ],
    "Bill Level Templates": [
        ("A", "Template ID, BTxx. Patron bills name one in their Template ID column."),
        ("B", "Kind: Favor or Flagship. BT01 and BT02 serve the organizations' requests; BT03 and BT04 are the two Draft a Bill shapes (two parts = Favor shape, three = Flagship shape)."),
        ("C", "Level Tier: the tier the level counts as for rewards and display."),
        ("D", "Stage 1: a stage token. Tokens: PATRON_VISIT (the organization's representative asks two questions), HEARING (the lead component's committee), PUBLIC (Town Hall for a Constituency organization, Press Conference for a National one), CAUCUS (your own Party Caucus), MP_VISIT (an optional member visit), LOBBYIST_TRADE (an optional lobbyist trade), VOTE (the Floor Vote). An STxx writes that stage directly."),
        ("E", "Stage 2: as Stage 1, played after it."),
        ("F", "Stage 3: as Stage 1."),
        ("G", "Stage 4: as Stage 1."),
        ("H", "Stage 5: as Stage 1."),
        ("I", "Stage 6: as Stage 1."),
        ("J", "Stage 7: as Stage 1."),
        ("K", "Stage 8: as Stage 1. Leave unused stages blank; the last used stage must be VOTE."),
        ("L", "Visit Parties: party IDs (PTxx, semicolon list) the optional member visit may call on, tried in order until one still has seats the player can win over."),
        ("M", "Note: for the designer; never shown."),
    ],
    "Party Values": [
        ("A", "Party ID, PTxx: one of the six parties."),
        ("B", "Dimension: one of the 34 policy dimensions (Civil Liberties through Japan Alignment). The same names are used in Bill Components' Value Tags."),
        ("C", "Value: where the party stands on this dimension; negative is against, positive is for (today -45 to 42)."),
        ("D", "Priority: how much the party cares, 0 to 5."),
        ("E", "Salience: Value x Priority (kept in step by hand; the game reads this column). A bill's lean for a party is the sum over its tags of tag weight x Salience. Reference copy: design/reference/party_values.tsv."),
    ],
}


def build(path):
    z = zipfile.ZipFile(path)
    names = z.namelist()
    parts = {n: z.read(n) for n in names}
    infos = {i.filename: i for i in z.infolist()}
    order = list(names)
    comment_n = 1 + max(int(re.search(r"comments(\d+)", n).group(1)) for n in names if re.match(r"xl/comments\d+\.xml", n))
    vml_n = 1 + max(int(re.search(r"vmlDrawing(\d+)", n).group(1)) for n in names if re.match(r"xl/drawings/vmlDrawing\d+\.vml", n))
    idmap = 1 + max(int(i) for n in names if n.endswith(".vml") for i in re.findall(r'idmap v:ext="edit" data="(\d+)"', parts[n].decode()))
    shape_id = 1 + max(int(i) for n in names if n.endswith(".vml") for i in re.findall(r'<v:shape id="_x0000_s(\d+)"', parts[n].decode()))
    ct = parts["[Content_Types].xml"].decode()
    for sheet, notes in NOTES.items():
        sp = _sheet_part(z, sheet)
        rels_name = sp.replace("worksheets/", "worksheets/_rels/") + ".rels"
        if rels_name in parts:
            print("skip (already has relationships):", sheet)
            continue
        cm, vm = "xl/comments%d.xml" % comment_n, "xl/drawings/vmlDrawing%d.vml" % vml_n
        comments = ""
        shapes = ""
        for z_index, (col, text) in enumerate(notes, 1):
            comments += ('<comment ref="%s1" authorId="0"><text><r><rPr><sz val="10"/><color theme="1"/>'
                         '<rFont val="Calibri"/><family val="2"/></rPr><t xml:space="preserve">%s</t></r></text></comment>'
                         % (col, escape(text)))
            n = col2n(col) - 1
            height = 40 + 12 * (len(text) // 38 + 1)
            shapes += ('<v:shape id="_x0000_s%d" type="#_x0000_t202" style=\'position:absolute;margin-left:80pt;'
                       'margin-top:2pt;width:240pt;height:%dpt;z-index:%d;visibility:hidden\' fillcolor="infoBackground [80]" '
                       'o:insetmode="auto"><v:fill color2="infoBackground [80]"/><v:shadow on="t" color="none [81]" obscured="t"/>'
                       '<v:path o:connecttype="none"/><v:textbox style=\'mso-direction-alt:auto\'><div style=\'text-align:left\'></div>'
                       '</v:textbox><x:ClientData ObjectType="Note"><x:MoveWithCells/><x:SizeWithCells/>'
                       '<x:Anchor>%d, 15, 0, 2, %d, 15, %d, 4</x:Anchor><x:AutoFill>False</x:AutoFill><x:Row>0</x:Row>'
                       '<x:Column>%d</x:Column></x:ClientData></v:shape>'
                       % (shape_id, height, z_index, n + 1, n + 5, height // 13 + 2, n))
            shape_id += 1
        parts[cm] = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
                     '<comments xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><authors><author>Claude</author></authors>'
                     '<commentList>%s</commentList></comments>' % comments).encode()
        parts[vm] = ('<xml xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office" '
                     'xmlns:x="urn:schemas-microsoft-com:office:excel"><o:shapelayout v:ext="edit"><o:idmap v:ext="edit" data="%d"/>'
                     '</o:shapelayout><v:shapetype id="_x0000_t202" coordsize="21600,21600" o:spt="202" path="m,l,21600r21600,l21600,xe">'
                     '<v:stroke joinstyle="miter"/><v:path gradientshapeok="t" o:connecttype="rect"/></v:shapetype>%s</xml>'
                     % (idmap, shapes)).encode()
        parts[rels_name] = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
                            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                            '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments" Target="../comments%d.xml"/>'
                            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/vmlDrawing" Target="../drawings/vmlDrawing%d.vml"/>'
                            '</Relationships>' % (comment_n, vml_n)).encode()
        sheet_xml = parts[sp].decode()
        assert "<legacyDrawing" not in sheet_xml
        parts[sp] = sheet_xml.replace("</worksheet>", '<legacyDrawing r:id="rId1"/></worksheet>').encode()
        ct = ct.replace("</Types>", '<Override PartName="/%s" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.comments+xml"/></Types>' % cm)
        order += [rels_name, cm, vm]
        comment_n += 1
        vml_n += 1
        idmap += 1
        print("notes added:", sheet, len(notes))
    parts["[Content_Types].xml"] = ct.encode()
    z.close()
    tmp = path + ".tmp"
    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as out:
        for name in order:
            if name in infos:
                out.writestr(infos[name], parts[name], compress_type=zipfile.ZIP_DEFLATED)
            else:
                out.writestr(name, parts[name])
    os.replace(tmp, path)


if __name__ == "__main__":
    build(PATH)
