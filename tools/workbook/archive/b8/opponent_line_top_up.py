"""Top-up of 33 opponent bill lines after Cameron's 2026-11-07 workbook update
(the new party positions shifted which sides draw from which pools, so 33
pools were one line short; tools/cue_coverage.py --list names them).
Each line below is one new row in the Opponent Cues tab. All are drafts for
Cameron to rewrite. Usage: python3 top_up_batch.py [--write]
Archived copy: not runnable as it stands (see ../../README.md)."""
import json, re, sys
sys.path.insert(0, "tools/workbook")

# (bill, suit, move, side) -> line. Side Neutral writes no side tag.
LINES = [
 ("BI02","Earnest","attack","For","Voting down the Agricultural Price Stabilization Act leaves rice and dairy farmers where they started. Say that to them plainly."),
 ("BI02","Emotional","attack","Neutral","People who care about farm incomes and the co-op are watching you right now!"),
 ("BI02","Data Driven","attack","Neutral","Where is your evidence on overproduction paid for by the treasury?"),
 ("BI02","Duplicitous","attack","Neutral","People are saying things about farm incomes and the co-op. I could not possibly repeat them."),
 ("BI04","Earnest","block","Neutral","That does not settle the Hokkaido Shinkansen Acceleration Act for me. Not yet."),
 ("BI04","Earnest","gain","Neutral","I came to hear what the Hokkaido Shinkansen Acceleration Act really costs, and I will vote on that."),
 ("BI04","Emotional","attack","Neutral","Answer me! Who will you face at home after the Hokkaido Shinkansen Acceleration Act?"),
 ("BI04","Emotional","gain","Neutral","Whatever we decide on the Hokkaido Shinkansen Acceleration Act, decide it for the towns along the line!"),
 ("BI04","Appeal","attack","Neutral","Friends, let us talk about stations and timetables along the line. It matters to us all."),
 ("BI04","Divisive","block","Neutral","That is a talking point from the other camp."),
 ("BI10","Emotional","attack","Neutral","How can you speak about the Candidate Gender Parity Act without a word for anyone it touches?"),
 ("BI10","Duplicitous","attack","Neutral","Who drafted your answer on the Candidate Gender Parity Act? It sounds borrowed."),
 ("BI12","Earnest","block","For","Delay does not keep politics out of the courts. It leaves appointments exactly where they are today."),
 ("BI12","Emotional","block","Neutral","Do not lecture me while people who care about public trust in the courts wait for answers!"),
 ("BI12","Appeal","attack","For","Friends, we all want courts that answer to the law, not to a party. Why block that?"),
 ("BI13","Earnest","attack","Neutral","I want a straight answer: what does the Temple and Shrine Heritage Act actually do?"),
 ("BI13","Earnest","gain","Neutral","My vote goes to whoever answers the hard questions on tax relief and restoration grants for temples and shrines."),
 ("BI13","Appeal","attack","Neutral","Friends, let us talk about old roofs, festivals and visiting trade. It matters to us all."),
 ("BI13","Appeal","gain","Neutral","Friends, whatever we decide on the Temple and Shrine Heritage Act, let us decide it together."),
 ("BI13","Data Driven","attack","Neutral","Where is your evidence on favoring some faiths over others?"),
 ("BI13","Data Driven","gain","Neutral","Let us settle the Temple and Shrine Heritage Act with evidence, not volume."),
 ("BI13","Data Driven","block","Neutral","One example is not a trend. Try again."),
 ("BI14","Earnest","attack","For","Say no if you must. Then tell every district why its member should go home empty-handed."),
 ("BI14","Earnest","block","Neutral","That is not an answer about small projects paid for by the member's grant. Try again."),
 ("BI14","Emotional","attack","Neutral","How can you speak about the Constituency Development Grants Act without a word for anyone it touches?"),
 ("BI14","Emotional","block","Neutral","I will not let you make the Constituency Development Grants Act sound simple!"),
 ("BI14","Data Driven","attack","For","Name one figure showing an annual district grant for every Assembly member would fail. I will wait."),
 ("BI20","Earnest","block","Against","Promises will not shield dairy and rural producers from foreign dairy undercutting local farms."),
 ("BI20","Data Driven","attack","For","Your objection has no numbers. The case for exporters and shoppers does."),
 ("BI20","Data Driven","block","For","Your worry about foreign dairy undercutting local farms is speculation. The gains for exporters and shoppers are measured."),
 ("BI29","Earnest","block","Against","Promises will not shield students and teachers with other views from the state teaching one view of virtue."),
 ("BI29","Emotional","gain","Against","Think of students and teachers with other views tonight, worried sick! That is the Moral Education Curriculum Act!"),
 ("BI29","Duplicitous","attack","For","Odd that anyone would stand against schools and families who want a shared moral base. Unless they owe someone."),
]
GAME_TERMS = re.compile(r"\b(level|stage)s?\b", re.I)


def main():
    cues = json.load(open("data/opponent_cues.json"))
    existing = {r[f"cue_{i}"].strip() for r in cues for i in range(1, 6) if r.get(f"cue_{i}")}
    assert len(LINES) == 33
    for bill, suit, verb, side, text in LINES:
        assert len(text.split()) <= 20, text
        assert not GAME_TERMS.search(text), text
        assert text not in existing, "already in the workbook: " + text
    print(len(LINES), "lines ready; longest", max(len(t.split()) for *_, t in LINES), "words")
    if "--write" in sys.argv:
        from wbx import WB
        w = WB("design/Game_Workbook.xlsx")
        tab = "Opponent Cues"
        ids = [int(re.sub(r"\D", "", v.get("A") or "0") or 0) for k, v in w.rows(tab).items() if k > 1]
        next_id = max(ids) + 1
        style = w.last_data_row(tab)
        for bill, suit, verb, side, text in LINES:
            cells = {"A": f"OC{next_id}", "B": suit, "C": verb, "K": bill, "E": text}
            if side != "Neutral":
                cells["M"] = side
            w.append_row(tab, cells, style_row=style)
            next_id += 1
        w.save()
        print("written through", f"OC{next_id - 1}")


if __name__ == "__main__":
    main()
