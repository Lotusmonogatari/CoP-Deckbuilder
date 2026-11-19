"""Shared text scanning: office cues, place types, real names."""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lexicon import *

_CAP = [re.compile(p, re.I) for p in CAPITOL_CUES]
_DIS = [re.compile(p, re.I) for p in DISTRICT_CUES]
_GEN = compile_all(GENERIC)
_UNC = compile_all(UNCATALOGED)
_REAL = {name: re.compile(r"(?<![A-Za-zĀ-ſ])" + re.escape(name) + r"(?![A-Za-zĀ-ſ])") for name in REAL_PLACES}
_BRAND = {pat: re.compile(pat) for pat in REAL_BRANDS}


def office_cues(text):
    cap = sorted({m.group(0).lower() for rx in _CAP for m in rx.finditer(text)})
    dis = sorted({m.group(0).lower() for rx in _DIS for m in rx.finditer(text)})
    return cap, dis


def propose_office(cap, dis):
    """(office, confidence) from the cue words found."""
    c, d = len(cap), len(dis)
    if d >= c + 3 or (d >= 2 and c == 0):
        return "District", "high" if d >= c + 3 else "medium"
    if c >= d + 3 or (c >= 2 and d == 0):
        return "Capitol", "high" if c >= d + 3 else "medium"
    if d > c:
        return "District", "low"
    if c > d:
        return "Capitol", "low"
    return "Either", "medium" if (c == 0 and d == 0) else "low"


_WEAK = {re.compile(p, re.I).pattern for p in WEAK}


def generic_places(text, strong_only=False):
    """{archetype: [matched words]} for the spec's 24 types (strong_only drops people/activity words)."""
    out = {}
    for kind, rxs in _GEN.items():
        found = sorted({m.group(0).lower() for rx in rxs if not (strong_only and rx.pattern in _WEAK) for m in rx.finditer(text)})
        if found:
            out[kind] = found
    return out


def uncataloged_places(text):
    out = {}
    for kind, rxs in _UNC.items():
        found = sorted({m.group(0).lower() for rx in rxs for m in rx.finditer(text)})
        if found:
            out[kind] = found
    return out


def real_places(text):
    """[(name, archetype, note)] for real place names found."""
    return [(name, REAL_PLACES[name][0], REAL_PLACES[name][1]) for name, rx in _REAL.items() if rx.search(text)]


def real_brands(text):
    out = []
    for pat, rx in _BRAND.items():
        m = rx.search(text)
        if m:
            out.append((m.group(0),) + REAL_BRANDS[pat])
    return out
