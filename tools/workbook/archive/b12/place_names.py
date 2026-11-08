"""Real Aomori and Hokkaido place names for the 2026-11-08 casework batch
(Cameron, 2026-11-08: any real town, landmark or geographic name in Aomori or
Hokkaido may be used). Rewrites question texts (Visitor Questions column C),
event flavor (Events column C) and a few follow-up lines so the stories sit in
real places and the follow-ups point back to the same town. Claude's draft.
Archived copy: not runnable as it stands once applied."""
import sys
sys.path.insert(0, "tools/workbook")

QUESTIONS = {
 "VQ398": "The pothole on the road into Hakodate's morning market cracks a van axle a month. Will someone fill it?",
 "VQ399": "Crows tear open the garbage bags in Kotoni every collection day. Can we get nets?",
 "VQ400": "New tenants in Niseko keep putting bottles out on burnables day. Can the rules come in more languages?",
 "VQ401": "Snow slides off the shop roofs on Otaru's Sakaimachi Street. It nearly buried me last week.",
 "VQ402": "My mother died abroad and my passport is stuck at the Sapporo office. The funeral is in ten days.",
 "VQ403": "My pension did not come this month. The Kushiro office says to wait. I cannot wait.",
 "VQ404": "A coast guard veteran from Nemuro has waited a year on his medical claim. Will you ask why?",
 "VQ405": "My mother turns one hundred next week, here in Hirosaki. Would you send her a few words?",
 "VQ406": "The dog next door barks from dawn. Its owner works nights at the Asahikawa depot and sleeps through it.",
 "VQ407": "The dogs need somewhere to run. Can one corner of Nakajima Park be fenced?",
 "VQ408": "Our station on the Gonō Line has stairs only. I have not taken a train in two years.",
 "VQ409": "Commuters chain their bicycles across my door by Hachinohe Station. Customers climb over them.",
 "VQ410": "An empty house in Imabetsu is falling in. Animals live in it. Nobody knows the owner.",
 "VQ411": "The old bathhouse next to my shop in Muroran may close. Half the street washes there.",
 "VQ412": "The ward says my sign on Tanukikōji breaks the rules. Without it, nobody finds the bakery.",
 "VQ413": "The Shari harbor ice machine broke in the middle of salmon season. Fish are spoiling.",
 "VQ414": "Our old science teacher taught three generations in Takikawa. Can the park by the Ishikari River carry her name?",
 "VQ415": "The Nibutani museum's Ainu robes sit in a cracked case. Dust gets in every day.",
 "VQ416": "The warehouse that stored our Neputa float in Hirosaki is coming down. Where does it go this winter?",
 "VQ417": "The path up to the temple graves in Esashi is too steep for our elderly visitors. Can we get a handrail?",
 "VQ418": "My nephew is applying to the prefectural office in Aomori City. A letter from you would help.",
 "VQ419": "I keep getting tax letters for someone who left years ago. The Kita Ward office won't listen.",
 "VQ420": "Three of my clients in Obihiro nearly sent their savings to phone scammers this month.",
 "VQ421": "The fish plant beside the school in Monbetsu smells all summer. The children eat lunch indoors.",
 "VQ422": "They want a wind turbine on the ridge above my pasture near Cape Sōya. Nobody asked the sheep, or me.",
 "VQ423": "Half the valley road out of Yūbari has no phone signal. Twice this year I couldn't call the hospital.",
}

KEPT = {  # (question, column) -> promise kept text
 ("VQ398", "AC"): "You press the Hakodate ward office until the market-road pothole is on this month's repair list.",
 ("VQ410", "AC"): "You get the town office to trace the owner of the empty house in Imabetsu. A letter goes to a nephew in Sapporo.",
 ("VQ420", "AC"): "You hold a warning session at the Obihiro community hall. The room fills with seniors and their notebooks.",
 ("VQ422", "AC"): "You hold the meeting in the village hall near Cape Sōya, and the company answers questions for two hours.",
}

FLAVOR = {
 "EV66": "The neighborhood association in Furano is honoring every resident over eighty and asks you to hand out the certificates.",
 "EV67": "After a week of cherry-blossom parties, Hirosaki Park is buried in cans and paper.",
 "EV68": "A rusted car has sat outside the apartment blocks in Ebetsu for half a year. The residents want it gone.",
 "EV69": "Last night's storm took out the only road to six farms near Biei. The co-op asks whether you will come and see it.",
 "EV70": "The poster boards from the last campaign are still up on three corners in Chitose, your own face among them, peeling.",
 "EV71": "An elder of the Local Kōenkai invites you to her grandson's wedding reception in Hachinohe this weekend.",
 "EV72": "Every heavy rain, the drainage ditch behind the housing estate in Iwamizawa overflows into the gardens, and the mosquitoes follow.",
 "EV73": "The organizers of a charity run around Lake Ōnuma for the children's hospital ask whether they can list you as an honorary patron.",
 "EV74": "Hanako Okuda writes: the corner light came on last night. She asks whether the next corner could be next.",
 "EV75": "Chihiro Endo's passport arrived two days before the flight. A reporter from the Hokkaido evening paper has heard about it and wants the story.",
 "EV76": "The nets work on Hanako Okuda's street in Kotoni. The crows have moved to the next one, and its association is at your door.",
 "EV77": "The pothole on the road into Hakodate's morning market is filled. The delivery drivers have left a thank-you note and a box of doughnuts at your office.",
 "EV78": "The ministry has approved the Nemuro coast guard veteran's claim. The Veterans' Association invites you to a small celebration at its hall.",
 "EV79": "The town has traced the owner of the empty house in Imabetsu to Sapporo. He wants to sell, but not to pay for the demolition.",
 "EV80": "A carrier will survey the Yūbari valley road for a tower, if the town provides the land at no charge.",
 "EV81": "Ayako Kudo calls from Obihiro: since your session, two of her clients hung up on scammers. A third was not there, and lost her savings.",
 "EV82": "The village hall below Cape Sōya is full. The company has brought a model of the turbine, and the sheep farmers have brought their questions.",
}

CHOICE_TEXT = {  # (event, letter) -> (column, text)
 ("EV81", "A"): ("C", "Hold a second session in Kushiro"),
 ("EV82", "A"): ("C", "Ask the company to move it one ridge further from the cape"),
}


def main():
    from wbx import WB
    w = WB("design/Game_Workbook.xlsx")
    for qid, text in QUESTIONS.items():
        w.set_cell("Visitor Questions", w.find_row("Visitor Questions", qid), "C", text)
    for (qid, col), text in KEPT.items():
        w.set_cell("Visitor Questions", w.find_row("Visitor Questions", qid), col, text)
    for eid, text in FLAVOR.items():
        w.set_cell("Events", w.find_row("Events", eid), "C", text)
    rows = w.rows("Event Choices")
    for (eid, letter), (col, text) in CHOICE_TEXT.items():
        row = next(k for k, v in rows.items() if v.get("A") == eid and v.get("B") == letter)
        w.set_cell("Event Choices", row, col, text)
    w.save()
    print("places written:", len(QUESTIONS), "questions,", len(FLAVOR), "events")


if __name__ == "__main__":
    main()
