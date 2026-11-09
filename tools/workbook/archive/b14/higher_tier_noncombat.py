"""Higher-tier non-combat levels (Cameron, 2026-11-09). Six families, each
with a Tier 1 level (2 stages) and a Tier 2 level (3 stages): 12 levels
(LV102-LV113) and 15 stages (ST274-ST288). Built by copying the nearest Tier 0
row. All names and purpose lines are Claude's draft for Cameron to rewrite.
Run from the repo root:  python3 tools/workbook/archive/b14/higher_tier_noncombat.py
Fixed by hand after the first run: the Office Hours copies (ST274-276, ST281, ST282) got Background ID OFFICE, and Weekend OK is No.
Archived copy: not runnable as it stands once applied (IDs would clash)."""
import sys, re
sys.path.insert(0, "tools/workbook")
from wbx import WB

w = WB("design/Game_Workbook.xlsx")

# Shared stages: (id, EN, JP, romaji, hours, xp, jiban, rep, party, awD, awN, count)
SHARED = {
 "follow": ("ST274", "Follow-Up Office Hours", "追加の陳情", "Tsuika no Chinjō", 2, 30, 2, 0, 0, 1, 0, 5),
 "receive": ("ST275", "Receiving Line", "来賓の出迎え", "Raihin no Demukae", 2, 40, 2, 0, 0, 1, 0, 4),
 "closing": ("ST276", "Closing Reception", "閉会の懇親会", "Heikai no Konshinkai", 2, 50, 3, 1, 1, 1, 1, 5),
}
# Family main stages: tier -> (EN, JP, romaji, hours, xp, jiban, yen, rep, party, awD, awN, count)
FAM = {
 "meet": {"analog": "ST267", "t1": ("Ward Tour", "区内巡回", "Kunai Junkai", 4, 100, 6, 20000, 1, 0, 2, 0, 8),
          "t2": ("District Tour", "選挙区一周", "Senkyoku Isshū", 6, 130, 6, 60000, 2, 1, 3, 1, 10)},
 "festival": {"analog": "ST264", "t1": ("Regional Festival", "地域の祭り", "Chiiki no Matsuri", 5, 120, 7, 30000, 1, 0, 3, 1, 10),
          "t2": ("Grand Festival", "大祭", "Taisai", 7, 150, 7, 100000, 2, 1, 3, 1, 12)},
 "open": {"analog": "ST07", "t1": ("Extended Office Hours", "拡大陳情日", "Kakudai Chinjō-bi", 4, 100, 5, 20000, 1, 0, 2, 0, 8),
          "t2": ("Open House Day", "事務所開放日", "Jimusho Kaihō-bi", 6, 130, 6, 60000, 2, 1, 3, 1, 10)},
 "health": {"analog": "ST268", "t1": ("Health Fair", "健康フェア", "Kenkō Fea", 4, 110, 6, 20000, 2, 1, 2, 0, 8),
          "t2": ("Regional Health Forum", "地域医療フォーラム", "Chiiki Iryō Fōramu", 6, 140, 6, 60000, 3, 2, 3, 1, 10)},
 "schools": {"analog": "ST269", "t1": ("Education Forum", "教育フォーラム", "Kyōiku Fōramu", 4, 100, 4, 20000, 2, 1, 2, 1, 8),
          "t2": ("Graduation Ceremony", "卒業式", "Sotsugyōshiki", 6, 130, 5, 60000, 3, 2, 3, 1, 10)},
 "trade": {"analog": "ST270", "t1": ("Trade Fair", "商談会", "Shōdankai", 5, 120, 4, 50000, 1, 0, 2, 1, 10),
          "t2": ("Export Expo", "輸出博覧会", "Yushutsu Hakurankai", 7, 150, 5, 120000, 2, 1, 3, 2, 12)},
}
# Level data per family and tier: purpose, cooldown, host org, seasons, org deltas
LV = {
 "meet": {"t1": ("A ward-by-ward walk with the local leaders, and a conversation for each corner.", 48, "BO06", None, {"BO18": "2-4", "BO06": "1-2"}),
          "t2": ("A tour of the whole district. Everyone you pass will compare it with the last candidate's.", 96, "BO03", None, {"BO18": "3-5", "BO03": "2-3", "BO04": "1-2"})},
 "festival": {"t1": ("A big regional festival draws people from several towns. Be seen, and stay for the speeches.", 72, None, "Summer; Autumn", {"BO06": "2-4", "BO15": "1-2"}),
          "t2": ("The great festival of the year. The shrine, the towns and the press will all be there.", 144, "BO20", None, {"BO06": "3-5", "BO20": "2-3", "BO15": "1-2"})},
 "open": {"t1": ("A long open day at your office, and a longer line at the door.", 48, "BO18", None, {"BO18": "2-4", "BO12": "1-2"}),
          "t2": ("The doors are open to everyone for a day, and the town leaders have been invited to watch.", 96, "BO04", None, {"BO18": "3-5", "BO04": "2-3", "BO06": "1-2"})},
 "health": {"t1": ("A health fair with the clinic, the care workers and the families who rely on them.", 60, "BO21", None, {"BO21": "2-4", "BO12": "1-2"}),
          "t2": ("A forum on local care, with hospital staff, patients and carers on one stage.", 120, "BO26", None, {"BO21": "3-5", "BO12": "2-3", "BO19": "1-2"})},
 "schools": {"t1": ("An education forum with teachers, parents and students, all of whom have opinions.", 60, "BO11", None, {"BO11": "2-4", "BO12": "1-2"}),
          "t2": ("A graduation ceremony, and a speech the families will quote for years.", 120, "BO15", None, {"BO11": "3-5", "BO12": "2-3", "BO15": "1-2"})},
 "trade": {"t1": ("A trade fair where local makers and buyers meet. Listen for what they cannot get done.", 72, "BO25", None, {"BO25": "2-4", "BO30": "1-2"}),
          "t2": ("A large export expo with growers, makers and buyers from beyond the district.", 144, "BO13", None, {"BO25": "3-5", "BO30": "2-3", "BO10": "1-2"})},
}
UNLOCK = {"t1": (60, 50, 40, 30), "t2": (120, 100, 80, 60)}

def stage_over(sid, en, jp, ro, hrs, xp, jiban, yen, rep, party, awd, awn, count):
    return {"A": sid, "B": en, "C": jp, "D": ro, "Y": jiban, "Z": yen, "AA": rep, "AB": xp, "AC": party,
            "AM": count, "AY": hrs, "AZ": awd, "BA": awn if awn else None}

def build():
    # shared stages (copies of ST07, Office Hours)
    for key, (sid, en, jp, ro, hrs, xp, jiban, rep, party, awd, awn, count) in SHARED.items():
        w.copy_row("Stages", "ST07", stage_over(sid, en, jp, ro, hrs, xp, jiban, 0, rep, party, awd, awn, count))
    next_stage, next_level = 277, 102
    main_ids = {}
    for fam, d in FAM.items():
        for tier in ("t1", "t2"):
            sid = "ST%d" % next_stage; next_stage += 1
            en, jp, ro, hrs, xp, jiban, yen, rep, party, awd, awn, count = d[tier]
            w.copy_row("Stages", d["analog"], stage_over(sid, en, jp, ro, hrs, xp, jiban, yen, rep, party, awd, awn, count))
            main_ids[(fam, tier)] = sid
    for fam, d in FAM.items():
        for tier in ("t1", "t2"):
            lid = "LV%d" % next_level; next_level += 1
            purpose, cooldown, host, seasons, deltas = LV[fam][tier]
            main = main_ids[(fam, tier)]
            parts = [main, SHARED["follow"][0]] if tier == "t1" else [SHARED["receive"][0], main, SHARED["closing"][0]]
            over = {"A": lid, "B": d[tier][0], "C": cooldown, "D": 1 if tier == "t1" else 2,
                    "E": UNLOCK[tier][0], "F": UNLOCK[tier][1], "G": UNLOCK[tier][2], "H": UNLOCK[tier][3],
                    "BK": purpose, "BL": "District Representative", "BF": "No"}  # too long for a weekend day (4 hours)
            for i, col in enumerate("IJKLMNOPQR"):
                over[col] = parts[i] if i < len(parts) else "N/A"
            # clear the analog's org deltas, then set ours (headers "Win ΔBOnn")
            hdr = w.rows("Levels")[1]
            by = {v: k for k, v in hdr.items()}
            for n in range(1, 33):
                over[by["Win ΔBO%02d" % n]] = 0
            for bo, rng in deltas.items():
                over[by["Win Δ" + bo]] = rng
            if host: over["BG"] = "Yes"; over["BH"] = host
            if seasons: over["BI"] = seasons
            w.copy_row("Levels", "LV87", over)
    return main_ids

main_ids = build()

# Seat people: every new stage joins the Stage cell of the visitors who serve
# its analog (the family's own people for a main stage; the Office Hours
# people for the shared stages).
def add_stage(analog, new_ids):
    for row, v in w.rows("Visitors").items():
        if row == 1: continue
        stages = [x.strip() for x in str(v.get("F", "")).split(";") if x.strip()]
        if analog in stages:
            for n in new_ids:
                if n not in stages: stages.append(n)
            w.set_cell("Visitors", row, "F", "; ".join(stages))
add_stage("ST07", [x[0] for x in SHARED.values()] + [main_ids[("open", "t1")], main_ids[("open", "t2")]])
for fam, d in FAM.items():
    if fam != "open":
        add_stage(d["analog"], [main_ids[(fam, "t1")], main_ids[(fam, "t2")]])
w.save()
print("stages", main_ids)
