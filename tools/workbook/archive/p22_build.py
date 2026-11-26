#!/usr/bin/env python3
"""P22 (2026-11-26, Cameron): the two campaign skins' tokens in the UI Styles tab and the Rules rows that choose and colour them. Tokens are the
design spec's table (design/proposals/p22/P22_SPEC.md) plus the briefing tokens (brief_*) the shared Office frame reads, so one skin is a complete
style for the screens it covers; any token not listed is taken from woodblock. Cameron's answers (2026-11-26): the default skin is Samurai always;
the accent family (below, `party / accent_family`) takes the player's party colour, the listed hex staying as the fallback; the phase banners'
nobori take the colours of the player's party, Keizaijiyuutou and the Yezo Heritage Party. Run once from the repo root, then
python3 tools/export_data.py --accept-wording."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

NOTE = "P22 (2026-11-26, Cameron): campaign skin token from the design spec."
w = WB("design/Game_Workbook.xlsx")

# token table: (group, token) -> (samurai, gladiator)
T = [
    ("colour", "ground", "#EDE3CF", "#E6DCC6"), ("colour", "paper", "#F7F0E1", "#F3ECDD"), ("colour", "ink", "#16130F", "#221A12"),
    ("colour", "ink_quiet", "#4E463C", "#54473A"), ("colour", "accent", "#A61E1E", "#7E1F1A"), ("colour", "on_accent", "#F7F0E1", "#F3ECDD"),
    ("colour", "tab_on", "#A61E1E", "#8C5A2B"), ("colour", "button", "#16130F", "#7E1F1A"), ("colour", "button_ink", "#F1D58C", "#F3ECDD"),
    ("colour", "shadow", "#16130F", "#8C5A2B"), ("colour", "bar_fill", "#A61E1E", "#7E1F1A"), ("colour", "bar_track", "#DDD0B6", "#D6CBB2"),
    ("colour", "phase_bar", "#16130F", "#7E1F1A"), ("colour", "phase_bar_ink", "#F1D58C", "#F3ECDD"), ("colour", "phase_rule", "#A61E1E", "#8C5A2B"),
    ("colour", "card_label", "#A61E1E", "#8C5A2B"), ("colour", "card_label_ink", "#F7F0E1", "#F3ECDD"), ("colour", "emblem_fill", "#F7F0E1", "#F3ECDD"),
    ("colour", "emblem_ink", "#16130F", "#F1D9A0"), ("colour", "stamp", "#A61E1E", "#7E1F1A"), ("colour", "jp", "#6B5F50", "#6E6050"),
    # the briefing palette the shared Office frame reads: a skin is these ten, mapped from the spec's tokens
    ("colour", "brief_ground", "#EDE3CF", "#E6DCC6"), ("colour", "brief_on_ground", "#16130F", "#221A12"), ("colour", "brief_on_ground_muted", "#4E463C", "#54473A"),
    ("colour", "brief_card", "#F7F0E1", "#F3ECDD"), ("colour", "brief_ink", "#16130F", "#221A12"), ("colour", "brief_muted", "#4E463C", "#54473A"),
    ("colour", "brief_tile", "#EDE3CF", "#E6DCC6"), ("colour", "brief_accent", "#A61E1E", "#7E1F1A"), ("colour", "brief_on_accent", "#F7F0E1", "#F3ECDD"),
    ("colour", "brief_hot", "#16130F", "#8C5A2B"),
    ("font", "display", "Antaka Brush Display", "Shippori Mincho B1"),
    ("type", "title_case", "as_written", "upper"), ("type", "title_tracking_em", "0", "0.14"), ("type", "heading_tracking_em", "0", "0.12"),
    ("type", "numerals", "arabic", "roman"),
    ("art", "emblem", "crest", "laurel"), ("art", "banner", "nobori", "arena"), ("art", "van", "van_samurai", "van_gladiator"),
    ("art", "texture", "fibers", "stone"), ("art", "texture_direction", "vertical", "horizontal"), ("art", "texture_step", "7", "11"),
    ("art", "texture_alpha", "0.07", "0.06"),
    ("shape", "stamp_tilt_deg", "-6", "0"),
    # which colour tokens take the player's party colour (the hex above is the fallback when there is no party)
    ("party", "accent_family", "accent;tab_on;bar_fill;card_label;stamp;phase_rule;brief_accent", "accent;tab_on;bar_fill;card_label;stamp;phase_rule;brief_accent"),
]
have = {(c.get("B"), c.get("C"), c.get("D")) for c in w.rows("UI Styles").values()}
last = w.last_data_row("UI Styles")
number = last
for style, column in (("campaign_samurai", 2), ("campaign_gladiator", 3)):
    for entry in T:
        group, token, value = entry[0], entry[1], entry[column]
        if (style, group, token) in have:
            continue
        number += 1
        note = NOTE
        if group == "party":
            note = "P22 (2026-11-26, Cameron's answer): these colour tokens take the player's party colour; the hex values stay as the fallback."
        w.append_row("UI Styles", {"A": "US%03d" % number, "B": style, "C": group, "D": token, "E": value, "F": note}, style_row=number - 1)

# Rules rows
def rule(key, value, options, question, notes):
    if key in {c.get("A") for c in w.rows("Rules").values()}:
        return
    w.append_row("Rules", {"A": key, "B": value, "C": options, "D": question, "F": notes})

rule("campaign_skin", "samurai", '["phase", "samurai", "gladiator", "off"]',
     "Which skin do the campaign screens wear? phase: Samurai except Gladiator during Gladiators of War Unleashed; samurai or gladiator: that one always; off: the player's own look.",
     "P22 (2026-11-26, Cameron): Samurai always. The skin replaces the player's look on the campaign screens only.")
rule("campaign_banner_parties", "PT05;PT02", "party IDs separated by semicolons",
     "Which parties' colours, after the player's own, the three nobori on the phase banners take (Keizaijiyuutou and the Yezo Heritage Party).",
     "P22 (2026-11-26, Cameron).")
rule("campaign_banner_spare_party", "PT03", "a party ID",
     "The party whose colour fills a nobori when the player's own party is one of the others (the Frontier Party).",
     "P22 (2026-11-26, Cameron's answer to edge case 1).")
w.save()
print("rows to", number)
