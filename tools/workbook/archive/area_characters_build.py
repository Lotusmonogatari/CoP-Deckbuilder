#!/usr/bin/env python3
"""Area Characters (2026-11-25, Cameron): the tab for the open-world people who speak in venues and appear over a venue's background.
IDs carry a prefix: VEN## (one venue or a few, named in Site), CA## (Capital Area), CB## (Capitol interior; CP is taken by the Cosmetic
Packages) and DI## (District). Site is blank for a zone person (the whole zone) or names venues (VN04; VN06) to narrow them; a VEN row
must have a Site. One row to start: VEN01, the speech coach (formerly SPEECH_COACH), whose name came from two Text rows.
Run once from the repo root: python3 tools/workbook/archive/area_characters_build.py, then python3 tools/export_data.py."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import add_sheet

HEAD = ["Character ID", "Name", "Name JP", "Romaji", "Title", "Site", "Note"]
ROWS = [["VEN01", "Masayuki Katō", "加藤正幸", "Katō Masayuki", "Speech Coach", "VN04",
         "The speech coach (formerly SPEECH_COACH). Picture assets/characters/area/VEN01.png."]]
add_sheet("design/Game_Workbook.xlsx", "Area Characters", HEAD, ROWS, [14, 22, 18, 22, 22, 18, 60])
print("Area Characters tab added")
