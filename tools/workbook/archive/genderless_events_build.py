#!/usr/bin/env python3
"""Genderless event text (2026-11-25, Cameron's playtest note): unless a text is tied to a specific, named character it must not say he, she, him,
her or his, nor man, girl or grandson. 83 rows about unnamed people (passengers, shopkeepers, officials) are reworded with the person's role or
a singular "they"; Hanako Okuda (EV74), Ayako Kudo (EV81) and Minister Resu (EV114, EV115) are named characters and keep their pronouns.
All rewording is Claude's draft for Cameron. Run once: python3 tools/workbook/archive/genderless_events_build.py, then export with --accept-wording."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

R = [  # (old text, new text), exact cell text
 ("The owner of a small hotel in Noboribetsu waits until the end of your office hours. Two floors are shut because she cannot hire anyone, and the visitors keep coming.", None),
]
