#!/usr/bin/env python3
"""Checks for the P20 exporter rules (2026-11-26): Election Cycles, Campaign Staff, the new Decision Scenes and Event Choices columns, the new
Activates kinds and the venue Unlock `scene`. Run by tools/verify.sh: python3 tools/test_campaign_exporter.py. Feeds the check functions
small tables and reads what they report."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_data  # noqa: E402


class Report:
    def __init__(self):
        self.errors, self.warnings = [], []

    def error(self, where, message):
        self.errors.append((where, message))

    def warn(self, where, message):
        self.warnings.append((where, message))


def cycle(cycle_id, banners, open_day, day, runs="Y"):
    return {"cycle_id": cycle_id, "banners_date": banners, "campaign_open_date": open_day, "election_day": day, "player_runs": runs}


GOOD_CYCLES = [cycle("EC01", "21.10.11", "21.11.30", "21.12.12"), cycle("EC02", "24.10.07", "24.11.26", "24.12.08"),
               cycle("EC03", "27.10.11", "27.11.30", "27.12.12", "N")]


def run_cycles(rows):
    report = Report()
    export_data.check_election_cycles({"election_cycles": rows}, report)
    return report


def staff(staff_id, **over):
    base = {"staff_id": staff_id, "role": "Campaign Organizer", "starting_tier": 0, "highest_tier": 1, "available": "office", "gift_likes": None, "gift_dislikes": None}
    base.update(over)
    return base


def run_staff(rows):
    report = Report()
    export_data.check_campaign_staff({"campaign_staff": rows, "shop": [{"item_id": "SH04"}]}, report)
    return report


def scene(scene_id, **over):
    base = {"scene_id": scene_id, "event_id": "EV120", "kind": "Mandatory", "card": None, "opens": "18.11.01", "closes": None, "office": "District",
            "speaker": None, "second_speaker": None, "speaker_face": None, "scene_picture": [], "follows": None, "delay": None, "follow_if": [],
            "activates": None, "weight": None, "weight_late": None, "repeat": None, "cooldown_weeks": None, "phase": [], "needs": []}
    base.update(over)
    return base


def run_scenes(scenes, events=None, extra=None):
    data = {"decision_scenes": scenes, "events": events or [{"event_id": "EV120", "trigger": "Dated", "on_date": "18.11.01", "location": "District"}],
            "opponents": [{"opp_id": "OP01"}], "staff": [{"staff_id": "SF01"}], "visitors": [], "campaign_staff": [{"staff_id": "CS02"}, {"staff_id": "CS04"}],
            "venues": [{"venue_id": "VN10"}], "venue_activities": [{"activity_id": "CM01", "kind": "campaign_fundraise"}, {"activity_id": "VA01", "kind": "chat"}],
            "event_choices": [{"event_id": "EV120", "choice": "A"}, {"event_id": "EV120", "choice": "B"}], "levels": [], "stages": [], "floor_votes": {},
            "strings": [], "rules": {}}
    if extra:
        data.update(extra)
    report = Report()
    export_data.check_decision_scenes(data, report)
    return report


def random_scene(scene_id, **over):
    base = {"event_id": "EV121", "kind": "Random", "opens": None, "weight": 3, "phase": ["building"], "needs": ["office_open"]}
    base.update(over)
    return scene(scene_id, **base)


RANDOM_EVENTS = [{"event_id": "EV121", "trigger": "Campaign", "location": "District"}]


def main():
    failures = []

    def expect(ok, what):
        print(("  ok  " if ok else "  X   ") + what)
        if not ok:
            failures.append(what)

    # --- Election Cycles
    expect(not run_cycles(GOOD_CYCLES).errors, "the three real cycles pass")
    expect(any("EC01" in w and "order" in m for w, m in run_cycles([cycle("EC01", "21.12.01", "21.11.30", "21.12.12")]).errors), "dates out of order fail")
    expect(any("EC01" in w and "YY.MM.DD" in m for w, m in run_cycles([cycle("EC01", "21.13.01", "21.11.30", "21.12.12")]).errors), "an unreal date fails")
    expect(any("Player Runs" in m for w, m in run_cycles([cycle("EC01", "21.10.11", "21.11.30", "21.12.12", "Maybe")]).errors), "Player Runs must be Y or N")
    two_n = [cycle("EC01", "21.10.11", "21.11.30", "21.12.12", "N"), cycle("EC02", "24.10.07", "24.11.26", "24.12.08", "N")]
    expect(any("At most one" in m for w, m in run_cycles(two_n).errors), "two cycles with Player Runs N fail")
    not_last = [cycle("EC01", "21.10.11", "21.11.30", "21.12.12", "N"), cycle("EC02", "24.10.07", "24.11.26", "24.12.08")]
    expect(any("must be the last" in m for w, m in run_cycles(not_last).errors), "Player Runs N must be on the last cycle")
    overlap = [cycle("EC01", "21.10.11", "21.11.30", "21.12.12"), cycle("EC02", "21.12.01", "22.01.10", "22.02.01")]
    expect(any("EC02" in w and "after the Election Day" in m for w, m in run_cycles(overlap).errors), "a cycle that starts before the last one ends fails")

    # --- Campaign Staff
    expect(not run_staff([staff("CS01"), staff("CS02", highest_tier=2, available="chain")]).errors, "valid campaign staff pass")
    expect(any("CS03" in w and "Role" in m for w, m in run_staff([staff("CS03", role="Media Spokesperson")]).errors), "a regular staff role fails")
    expect(any("CS04" in w and "Tier" in m for w, m in run_staff([staff("CS04", starting_tier=2, highest_tier=1)]).errors), "starting above highest fails")
    expect(any("CS05" in w and "Tier" in m for w, m in run_staff([staff("CS05", highest_tier=3)]).errors), "a tier above 2 fails")
    expect(any("CS06" in w and "Available" in m for w, m in run_staff([staff("CS06", available="soon")]).errors), "Available must be office or chain")
    expect(any("CS07" in w and "Shop" in m for w, m in run_staff([staff("CS07", gift_likes=["SH99"])]).errors), "a gift that is not a shop item fails")
    expect(not run_staff([staff("CS08", gift_likes=["SH04"])]).errors, "a real shop item passes")

    # --- Decision Scenes: the Random kind and the new columns
    expect(not run_scenes([scene("DS11")]).errors, "a Mandatory campaign scene on a Dated event passes")
    expect(not run_scenes([random_scene("DS12")], RANDOM_EVENTS + [{"event_id": "EV120", "trigger": "Dated", "on_date": "18.11.01", "location": "District"}]).errors,
           "a Random scene with a Campaign event, a Weight, a Phase and a Need passes")
    wrong_trigger = run_scenes([random_scene("DS12", event_id="EV120")])
    expect(any("must be Campaign" in m for w, m in wrong_trigger.errors), "a Random scene's event must have Trigger Campaign")
    expect(any("only a Random scene" in m for w, m in run_scenes([scene("DS11")], [{"event_id": "EV120", "trigger": "Campaign"}]).errors),
           "Trigger Campaign belongs to Random scenes only")
    expect(any("Weight" in m for w, m in run_scenes([random_scene("DS12", weight=None)], RANDOM_EVENTS).errors), "a Random scene needs a Weight")
    expect(any("is only for Random" in m for w, m in run_scenes([scene("DS11", weight=2)]).errors), "Weight on a Mandatory scene fails")
    expect(any("Phase" in m for w, m in run_scenes([random_scene("DS12", phase=["later"])], RANDOM_EVENTS).errors), "an unknown Phase fails")
    expect(any("Needs" in m for w, m in run_scenes([random_scene("DS12", needs=["a_van"])], RANDOM_EVENTS).errors), "an unknown Need fails")
    expect(any("Card" in m for w, m in run_scenes([scene("DS11", card="Gossip")]).errors), "an unknown Card fails")
    expect(not any("Card" in m for w, m in run_scenes([scene("DS11", card="Campaign")]).errors), "Card Campaign passes")
    expect(any("Opens" in m or "no Opens" in m for w, m in run_scenes([random_scene("DS12", opens="18.11.01")], RANDOM_EVENTS).errors), "a Random scene has no Opens")
    expect(not any("is not an opponent" in m for w, m in run_scenes([scene("DS11", speaker="CS02")]).errors), "a campaign staff speaker passes")
    expect(not any("is not an opponent" in m for w, m in run_scenes([scene("DS11", speaker="colleague")]).errors), "the colleague speaker passes")
    expect(any("is not an opponent" in m for w, m in run_scenes([scene("DS11", speaker="CS99")]).errors), "an unknown speaker fails")

    # --- Activates kinds
    for cell, ok, what in [("venue:VN10", True, "venue:VN10 passes"), ("venue:VN99", False, "an unknown venue fails"),
                           ("campaign_staff:CS02@A", True, "campaign_staff:CS02@A passes"), ("campaign_staff:CS99", False, "an unknown campaign staff ID fails"),
                           ("challenge:CM01x3in14@A", True, "challenge:CM01x3in14 passes"), ("challenge:CM01x0in14", False, "a challenge of zero actions fails"),
                           ("challenge:VA01x3in14", False, "a challenge on a non-campaign activity fails"), ("challenge:soon", False, "a malformed challenge fails")]:
        report = run_scenes([scene("DS11", activates=cell)])
        expect((not [e for e in report.errors if "Activates" in e[0]]) == ok, what)

    # --- Follow If challenge_met needs a challenge on the parent
    chain_events = [{"event_id": "EV120", "trigger": "Dated", "on_date": "18.11.01", "location": "District"},
                    {"event_id": "EV121", "trigger": "Followup", "location": "District"}]
    parent = scene("DS16", activates="challenge:CM01x3in14@A")
    child = scene("DS17", event_id="EV121", follows="DS16", opens=None, delay=14, follow_if=["challenge_met"])
    expect(not [e for e in run_scenes([parent, child], chain_events).errors if "Follow If" in e[1]], "Follow If challenge_met after a challenge passes")
    plain = scene("DS16")
    expect(any("needs DS16 to start a challenge" in m for w, m in run_scenes([plain, child], chain_events).errors), "challenge_met without a challenge fails")

    # --- Event Choices columns
    def run_choices(rows):
        report = Report()
        export_data.check_campaign_choices({"event_choices": rows}, report)
        return report
    expect(not run_choices([{"event_id": "EV131", "choice": "A", "needs": ["campaign_staff_free"], "favor_owed": "Y", "donate_funds": 50000, "lend_weeks": 2}]).errors,
           "valid campaign choice columns pass")
    expect(any("Needs" in m for w, m in run_choices([{"event_id": "EV131", "choice": "A", "needs": ["a_van"]}]).errors), "an unknown choice Need fails")
    expect(any("Favor Owed" in m for w, m in run_choices([{"event_id": "EV131", "choice": "A", "favor_owed": "yes"}]).errors), "Favor Owed must be Y")
    expect(any("Donate" in m for w, m in run_choices([{"event_id": "EV131", "choice": "A", "donate_funds": -1}]).errors), "a negative donation fails")
    expect(any("Lend" in m for w, m in run_choices([{"event_id": "EV131", "choice": "A", "lend_weeks": 0}]).errors), "lending for zero weeks fails")

    # --- Venues: Unlock scene
    def run_venue(unlock):
        data = {"venues": [{"venue_id": "VN10", "zone": "District", "order": 10, "unlock": unlock}], "venue_activities": [], "venue_lines": [],
                "opponents": [], "staff": [], "visitors": [], "stages": [], "floor_votes": {}, "rules": {}, "strings": []}
        report = Report()
        export_data.check_venues(data, report)
        return report
    expect(not run_venue("scene").errors, "Unlock scene passes")
    expect(any("only value is 'scene'" in m for w, m in run_venue("always").errors), "another Unlock value fails")

    print("CAMPAIGN EXPORTER TEST: " + ("PASS" if not failures else f"{len(failures)} failed"))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
