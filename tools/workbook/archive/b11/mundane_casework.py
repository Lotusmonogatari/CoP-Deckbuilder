"""Mundane casework batch (2026-11-08, Cameron): small requests modelled on
real Japanese and American constituency casework, spoken by existing
visitors, plus random events and follow-ups chained from the choices.
26 Visitor Questions (VQ398-VQ423), 8 Random events (EV66-EV73) and 9
Followup events (EV74-EV82); VQ01 A now schedules EV74. All text is Claude's
draft for Cameron to rewrite. Run from the repo root:
    python3 tools/workbook/archive/b11/mundane_casework.py [--write]
Archived copy: not runnable as it stands once applied (IDs would clash)."""
import re, sys, math
sys.path.insert(0, "tools/workbook")

# Each question: id, visitor, question, choices A-D, effects A-D,
# responses A-D, reactions A-D, commitments A-D, promise kept texts A-D.
Q = [
 ("VQ398", "VI115", "The pothole on the market road cracks a van axle a month. Will someone fill it?",
  ["I'll press the ward to repair it this month.", "Roads get fixed in order; the list is fair.",
   "I'll ask for a cone and a warning sign today.", "Drive around it until spring."],
  ["BO14 +3; BO25 +1; BO23 -1", "BO23 +2; BO14 -2", "BO14 +1; BO23 -1", "BO14 -3; BO25 -1"],
  ["Then I'll stop swerving into the bus lane.", "It has been on the list since winter.",
   "A cone beats a broken axle.", "Around it is a canal."],
  ["Jingles the van keys.", "Shrugs.", "Nods once.", "Laughs without humor."],
  ["Promise Hours 1 within 48; Followup EV77 after 120", "", "", ""],
  ["You press the ward office about the market-road pothole until it is on this month's repair list.", "", "", ""]),
 ("VQ399", "VI01", "Crows tear open the garbage bags every collection day. Can we get nets?",
  ["I'll get the ward to supply nets for every point.", "Households can buy their own nets.",
   "I'll ask whether collection can start earlier.", "Crows are clever. Nothing really works."],
  ["BO06 +3; BO27 +1; BO23 -1", "BO23 +2; BO06 -2", "BO06 +1; BO23 -1", "BO06 -3; BO27 -1"],
  ["Then I'll stop sweeping up eggshells at six.", "Most of them are pensioners.",
   "Earlier would beat the crows.", "Nets work. I have seen them."],
  ["Writes it in her notebook.", "Frowns.", "Considers it.", "Snaps the notebook shut."],
  ["Promise Hours 1 within 48; Followup EV76 after 168", "", "Promise Hours 1 within 72", ""],
  ["You get the ward to send nets for every collection point on the street.", "",
   "You ask the ward about an earlier pickup and pass the answer on.", ""]),
 ("VQ400", "VI78", "New tenants keep putting bottles out on burnables day. Can the rules come in more languages?",
  ["I'll get the calendar printed in several languages.", "Fines for wrong sorting will teach it fastest.",
   "I'll ask about a sorting class for new residents.", "They will learn it the way everyone did."],
  ["BO27 +3; BO06 +1; BO23 -1", "BO06 +2; BO27 -2", "BO27 +1; BO23 -1", "BO27 -3; BO06 -1"],
  ["A picture calendar would help everyone.", "Fines land on the landlord, not the tenant.",
   "A Saturday class might work.", "Everyone else had a grandmother to teach them."],
  ["Unfolds a crumpled calendar.", "Winces.", "Nods.", "Sighs."],
  ["Promise Hours 1 within 48", "", "", ""],
  ["You get the garbage calendar printed in several languages, with pictures, for every collection point.", "", "", ""]),
 ("VQ401", "VI120", "Snow slides off the shop roofs onto the sidewalk. It nearly buried me last week.",
  ["I'll push for grants to fit snow guards on those roofs.", "Shops can't control the weather; walk on the far side.",
   "I'll ask the shops to put out warning signs.", "Winter is winter. Wear a good hat."],
  ["BO06 +3; BO21 +1; BO23 -1", "BO25 +2; BO06 -2", "BO06 +1; BO25 -1", "BO06 -3; BO21 -1"],
  ["Then I can buy radishes without praying.", "The far side has no sidewalk.",
   "A sign is something.", "A hat, against a roof of snow?"],
  ["Grips the cart handle.", "Purses lips.", "Nods slowly.", "Stares."],
  ["Promise Hours 1 within 48", "", "", ""],
  ["You find the snow-guard grant and walk the shop owners through the form.", "", "", ""]),
 ("VQ402", "VI141", "My mother died abroad and my passport renewal is stuck. The funeral is in ten days.",
  ["I'll call the ministry myself today.", "Everyone waits the same; I can't jump the queue.",
   "I'll have a staff member chase it tomorrow.", "Ask the embassy; they know the rules."],
  ["BO12 +3; BO18 +1; BO23 -1", "BO23 +2; BO12 -2", "BO12 +1; BO23 -1", "BO12 -3; BO18 -1"],
  ["Thank you. I didn't know who else to ask.", "Then I'll miss her funeral.",
   "Tomorrow is better than nothing.", "I asked them. They sent me to you."],
  ["Holds back tears.", "Looks down.", "Grips the folder.", "Turns away."],
  ["Hours 1; Followup EV75 after 96", "", "", ""],
  ["", "", "", ""]),
 ("VQ403", "VI126", "My pension did not come this month. The office says to wait. I cannot wait.",
  ["I'll go to the pension office with you.", "The office will sort it; delays happen.",
   "I'll write to the pension office today.", "Your family can help until it comes."],
  ["BO21 +3; BO07 +1; BO23 -1", "BO23 +2; BO21 -2", "BO21 +1; BO23 -1", "BO21 -3; BO07 -1"],
  ["With you there, they will open the file.", "Delays do not pay the rent.",
   "A letter from you will move it.", "My family is the sea."],
  ["Straightens his back, wincing.", "Rubs his back.", "Nods.", "Looks at the floor."],
  ["Promise Hours 1 within 48", "", "", ""],
  ["You sit with him at the pension office until they find the missing payment.", "", "", ""]),
 ("VQ404", "VI66", "A coast guard veteran's medical claim has sat on a desk for a year. Will you ask why?",
  ["I'll raise it with the ministry and follow it through.", "Every claim gets reviewed in turn.",
   "Send me the file and I'll pass it on.", "The association can appeal on its own."],
  ["BO22 +3; BO15 +1; BO23 -1", "BO23 +2; BO22 -2", "BO22 +1; BO23 -1", "BO22 -3; BO15 -1"],
  ["He served thirty years. He deserves an answer.", "His turn has come and gone twice.",
   "Passing it on is a start.", "We have. Three times."],
  ["Salutes, half joking.", "Jaw tightens.", "Hands over a folder.", "Stands up."],
  ["Promise Hours 1 within 72; Followup EV78 after 168", "", "", ""],
  ["You raise the veteran's claim with the ministry and keep asking until it reaches the right desk.", "", "", ""]),
 ("VQ405", "VI114", "My mother turns one hundred next week. Would you send her a few words?",
  ["I'll bring her a letter myself on the day.", "I'll ask the mayor to send the town's card.",
   "I'll mail her a signed card this week.", "I don't write personal letters, I'm afraid."],
  ["BO06 +3; BO12 +1; BO02 -1", "BO04 +2; BO06 -2", "BO06 +1; BO02 -1", "BO06 -3; BO12 -1"],
  ["She will talk about it for a year.", "The mayor sends a card to everyone.",
   "A card will go on her shelf.", "She voted for you, you know."],
  ["Claps once.", "Smile fades.", "Smiles.", "Raises an eyebrow."],
  ["Promise Hours 2 within 168", "", "", ""],
  ["You visit her mother on her hundredth birthday with a signed letter. She asks how old you are.", "", "", ""]),
 ("VQ406", "VI18", "The dog next door barks from dawn. Its owner works nights and sleeps through it.",
  ["I'll sit down with both of you and talk it through.", "Neighbors' quarrels aren't the Assembly's business.",
   "The ward has a noise desk; I'll pass it on.", "Earplugs are cheap, Granny."],
  ["BO06 +3; BO03 +1; BO27 -1", "BO27 +2; BO06 -2", "BO06 +1; BO27 -1", "BO06 -3; BO03 -1"],
  ["Sit with us? He listens to a legislator.", "Then whose business is my sleep?",
   "A desk. Well.", "Cheap? I am eighty-four."],
  ["Pours you tea.", "Sets down her cup.", "Nods.", "Glares."],
  ["Promise Hours 1 within 72", "", "", ""],
  ["You sit with Granny Chiyo and her neighbor. The dog gets a quieter corner of the yard.", "", "", ""]),
 ("VQ407", "VI21", "The dogs need somewhere to run. Can one corner of the park be fenced?",
  ["I'll back a fenced corner for dogs.", "The park is for children first.",
   "I'll ask the ward to survey park users.", "Dogs can run on a lead."],
  ["BO27 +3; BO06 +1; BO12 -1", "BO12 +2; BO27 -2", "BO27 +1; BO12 -1", "BO27 -3; BO06 -1"],
  ["My dog thanks you. So do I.", "Children like dogs.",
   "Survey the dogs too.", "A lead is not running."],
  ["Grins.", "Sighs.", "Shrugs.", "Whistles low."],
  ["Promise Hours 1 within 72", "", "", ""],
  ["You back the fenced dog corner at the ward meeting, and the park plan gets a new gate.", "", "", ""]),
 ("VQ408", "VI136", "Our station has stairs only. I have not taken a train in two years.",
  ["I'll press the rail company for an elevator.", "The elevator waiting list is long, and it is fair.",
   "I'll ask for station staff to help at set times.", "The bus can take you to the next station."],
  ["BO21 +3; BO14 +1; BO23 -1", "BO23 +2; BO21 -2", "BO21 +1; BO23 -1", "BO21 -3; BO14 -1"],
  ["Two years. I counted.", "I am on that list. So is my wheelchair.",
   "Set times are something.", "The next station has stairs too."],
  ["Grips the wheels.", "Looks out the window.", "Nods slowly.", "Laughs bitterly."],
  ["Promise Hours 1 within 72", "", "", ""],
  ["You press the rail company, and the station goes on next year's elevator list.", "", "", ""]),
 ("VQ409", "VI124", "Commuters chain their bicycles across my door. Customers climb over them.",
  ["I'll push for a proper bicycle lot by the station.", "Bicycles beat cars; live with it.",
   "I'll ask the ward to tow the worst ones.", "Put up a sign yourself."],
  ["BO25 +3; BO14 +1; BO23 -1", "BO14 +2; BO25 -2", "BO25 +1; BO14 -1", "BO25 -3; BO27 -1"],
  ["A lot would clear my door.", "Better for whom?",
   "Tow them, then.", "I have three signs."],
  ["Wipes the counter.", "Folds her arms.", "Nods.", "Points at the door."],
  ["Promise Hours 1 within 72", "", "", ""],
  ["You push for the station bicycle lot, and the ward marks out spaces by the end of the month.", "", "", ""]),
 ("VQ410", "VI84", "An empty house in the village is falling in. Animals live in it. Nobody knows the owner.",
  ["I'll get the town to trace the owner.", "It's private property; the town can't touch it.",
   "I'll ask about a demolition grant.", "There are a hundred like it. Leave it."],
  ["BO30 +3; BO06 +1; BO23 -1", "BO23 +2; BO30 -2", "BO30 +1; BO23 -1", "BO30 -3; BO06 -1"],
  ["The heir is in the city, somewhere.", "Private property, with a fox in the kitchen.",
   "A grant would bring it down.", "This one is next to the school."],
  ["Taps his walking stick.", "Grumbles.", "Nods.", "Stares."],
  ["Promise Hours 1 within 72; Followup EV79 after 168", "", "", ""],
  ["You get the town office to trace the owner of the empty house. A letter goes to a nephew in Sapporo.", "", "", ""]),
 ("VQ411", "VI121", "The bathhouse next to my shop may close. Half the street washes there.",
  ["I'll look for a community grant to keep it open.", "A business that can't pay its way closes.",
   "I'll ask the bath owners' union what would help.", "Most homes have baths now."],
  ["BO15 +3; BO06 +1; BO23 -1", "BO23 +2; BO15 -2", "BO15 +1; BO23 -1", "BO15 -3; BO06 -1"],
  ["My customers come in clean because of it.", "It pays. It just doesn't profit.",
   "They would like to be asked.", "Not the old flats on this street."],
  ["Snips the air.", "Puts down the scissors.", "Nods.", "Shakes his head."],
  ["Promise Hours 1 within 72", "", "", ""],
  ["You find a community grant for the bathhouse boiler, and the owner agrees to stay open another year.", "", "", ""]),
 ("VQ412", "VI111", "The ward says my sidewalk sign breaks the rules. Without it, nobody finds the bakery.",
  ["I'll ask for a small-sign exception for shops.", "Sidewalks are for walking; the rule stays.",
   "Try a sign in the window instead.", "Everyone knows where the bakery is."],
  ["BO25 +3; BO05 +1; BO06 -1", "BO06 +2; BO25 -2", "BO25 +1; BO06 -1", "BO25 -3; BO05 -1"],
  ["One small sign, that's all.", "People walk around it fine.",
   "The window is full of bread.", "The tourists do not."],
  ["Dusts flour off his apron.", "Frowns.", "Considers it.", "Laughs."],
  ["Promise Hours 1 within 48", "", "", ""],
  ["You get the ward to allow small sidewalk signs for shops, inside a marked line.", "", "", ""]),
 ("VQ413", "VI98", "The harbor ice machine broke in the middle of salmon season. Fish are spoiling.",
  ["I'll press for an emergency repair grant today.", "Upkeep is the co-op's job, not the town's.",
   "I'll see if a nearby harbor can share its ice.", "Sell the catch faster."],
  ["BO07 +3; BO25 +1; BO23 -1", "BO23 +2; BO07 -2", "BO07 +1; BO23 -1", "BO07 -3; BO25 -1"],
  ["Then the season is saved.", "The co-op is us. We are broke.",
   "Trucking ice is costly, but it works.", "Faster than the sun?"],
  ["Wipes salt from his face.", "Spits over the rail.", "Nods.", "Turns his back."],
  ["Hours 1", "", "", ""],
  ["", "", "", ""]),
 ("VQ414", "VI146", "Our old science teacher taught three generations here. Can the riverside park carry her name?",
  ["I'll back naming the park for her.", "Parks keep their place names; a plaque is enough.",
   "I'll ask the town to put up a plaque.", "Naming things after people starts fights."],
  ["BO15 +3; BO12 +1; BO04 -1", "BO04 +2; BO15 -2", "BO15 +1; BO04 -1", "BO15 -3; BO12 -1"],
  ["Her students will come back for it.", "A plaque gets lost in the grass.",
   "A plaque is a beginning.", "Not this person. Ask anyone."],
  ["Straightens his tie.", "Clears his throat.", "Nods.", "Frowns."],
  ["Promise Hours 1 within 72", "", "", ""],
  ["You back the park naming at the town council, and her former students fill the gallery.", "", "", ""]),
 ("VQ415", "VI79", "The museum's Ainu robes sit in a cracked case. Dust gets in every day.",
  ["I'll find money for a proper case.", "Museums must manage their own budgets.",
   "I'll ask a foundation to sponsor it.", "Store them away until there is money."],
  ["BO29 +3; BO28 +1; BO23 -1", "BO23 +2; BO29 -2", "BO29 +1; BO23 -1", "BO29 -3; BO28 -1"],
  ["Our grandmothers' work deserves glass.", "Our budget is a box of envelopes.",
   "A sponsor would be welcome.", "Stored away, nobody learns from them."],
  ["Touches the edge of a robe.", "Sighs.", "Nods.", "Shakes her head."],
  ["Promise Hours 1 within 72", "", "", ""],
  ["You find the money for a sealed case, and the robes go back on display.", "", "", ""]),
 ("VQ416", "VI81", "The warehouse that stored our festival float is coming down. Where does it go this winter?",
  ["I'll ask the town for space in a public garage.", "Storage is the committee's cost.",
   "I'll ask local businesses to lend a barn.", "Build a smaller float."],
  ["BO06 +3; BO15 +1; BO23 -1", "BO23 +2; BO06 -2", "BO06 +1; BO23 -1", "BO06 -3; BO15 -1"],
  ["Then we pull it again next summer.", "Our cost is our sweat.",
   "A barn would do.", "Smaller? It is ninety years old."],
  ["Bows.", "Scratches his head.", "Nods.", "Looks pained."],
  ["Promise Hours 1 within 48", "", "", ""],
  ["You find winter space for the float in the town's road-equipment garage.", "", "", ""]),
 ("VQ417", "VI64", "The path up to the temple graves is too steep for our elderly visitors. Can we get a handrail?",
  ["I'll find funding for a handrail and lights.", "Temple grounds are the temple's to fix.",
   "I'll ask for a shuttle on memorial days.", "Families can help their elders up."],
  ["BO19 +3; BO21 +1; BO23 -1", "BO23 +2; BO19 -2", "BO19 +1; BO23 -1", "BO19 -3; BO21 -1"],
  ["Then grandmothers can visit their husbands.", "The path below the gate is the town's.",
   "On memorial days it would help.", "Many of them come alone."],
  ["Bows deeply.", "Fingers prayer beads.", "Nods.", "Closes eyes."],
  ["Promise Hours 1 within 72", "", "", ""],
  ["You find funding for a handrail up the temple steps, and lights for winter evenings.", "", "", ""]),
 ("VQ418", "VI14", "My nephew is applying to the prefectural office. A letter from you would help.",
  ["I'll write him a letter.", "I don't write job letters; it isn't fair.",
   "I'll meet him first and see if he's suited.", "Let him stand on his own."],
  ["BO03 +3; BO01 +1; BO08 -1", "BO26 +2; BO03 -2", "BO03 +1; BO26 -1", "BO03 -3; BO01 -1"],
  ["He will not forget it. Nor will I.", "Fair? Everyone does it.",
   "He will put on a tie.", "He is standing. He wants a hand."],
  ["Grins.", "Stiffens.", "Nods.", "Frowns."],
  ["Hours 1", "", "Promise Hours 1 within 72", ""],
  ["", "", "You meet the nephew over coffee. He is better prepared than you expected.", ""]),
 ("VQ419", "VI113", "I keep getting tax letters for someone who moved out years ago. The ward won't listen.",
  ["I'll call the ward tax desk with you now.", "Fill in the correction form; that's the process.",
   "Bring the letters to my office; I'll forward them.", "Just throw them away."],
  ["BO18 +3; BO27 +1; BO23 -1", "BO23 +2; BO18 -2", "BO18 +1; BO23 -1", "BO18 -3; BO27 -1"],
  ["They pick up for a legislator.", "I filled it in twice.",
   "That box is getting full.", "And then they fine me."],
  ["Holds out a stack of envelopes.", "Groans.", "Nods.", "Stares."],
  ["Hours 1", "", "", ""],
  ["", "", "", ""]),
 ("VQ420", "VI131", "Three of my clients nearly sent their savings to phone scammers this month.",
  ["I'll hold a warning session at the community hall.", "Families should watch their parents' accounts.",
   "I'll ask the phone companies to flag scam numbers.", "People have to be careful themselves."],
  ["BO21 +3; BO26 +1; BO24 -1", "BO24 +2; BO21 -2", "BO21 +1; BO24 -1", "BO21 -3; BO26 -1"],
  ["They trust a legislator's voice.", "Many have no family nearby.",
   "Flagging would stop some of them.", "They were careful. The scammer was better."],
  ["Writes a date on her calendar.", "Shakes her head.", "Nods.", "Closes her folder."],
  ["Promise Hours 2 within 72; Followup EV81 after 168", "", "", ""],
  ["You hold a warning session at the community hall. The room fills with seniors and their notebooks.", "", "", ""]),
 ("VQ421", "VI145", "The fish plant beside the school smells all summer. The children eat lunch indoors.",
  ["I'll press for an inspection and better filters.", "The plant gives this town its jobs.",
   "I'll ask the plant to move its worst work to weekends.", "It's the smell of a fishing town."],
  ["BO12 +3; BO27 +1; BO07 -1", "BO07 +2; BO12 -2", "BO12 +1; BO07 -1", "BO12 -3; BO27 -1"],
  ["The children will eat outside again.", "Jobs, and headaches.",
   "Weekends would help the school.", "Not inside a classroom."],
  ["Fans herself with a newsletter.", "Frowns.", "Nods.", "Wrinkles her nose."],
  ["Promise Hours 1 within 72", "", "", ""],
  ["You press for the inspection, and the plant fits new filters before autumn.", "", "", ""]),
 ("VQ422", "VI161", "They want a wind turbine on the ridge above my pasture. Nobody asked the sheep, or me.",
  ["I'll call a public meeting before anything is signed.", "Clean power has to go somewhere.",
   "I'll ask the company about compensation for you.", "The ridge is not your land."],
  ["BO30 +3; BO10 +1; BO16 -1", "BO16 +2; BO30 -2", "BO30 +1; BO16 -1", "BO30 -3; BO10 -1"],
  ["A meeting, at least, with chairs.", "Somewhere is always here.",
   "Money does not quiet a blade.", "My grandfather grazed it."],
  ["Leans on his crook.", "Spits.", "Grunts.", "Walks off."],
  ["Promise Hours 2 within 96; Followup EV82 after 168", "", "", ""],
  ["You hold the meeting in the village hall, and the company answers questions for two hours.", "", "", ""]),
 ("VQ423", "VI132", "Half the valley road has no phone signal. Twice this year I couldn't call the hospital.",
  ["I'll press the carriers for a tower on the valley road.", "Carriers build where the customers are.",
   "I'll ask for radios in every ambulance.", "Drive to the pass and call from there."],
  ["BO21 +3; BO30 +1; BO23 -1", "BO23 +2; BO21 -2", "BO21 +1; BO23 -1", "BO21 -3; BO30 -1"],
  ["Then I can call ahead.", "Patients are customers too.",
   "Radios would cover us for now.", "Every minute counts on that road."],
  ["Taps a dead phone.", "Shakes his head.", "Nods.", "Stares."],
  ["Promise Hours 1 within 72; Followup EV80 after 168", "", "", ""],
  ["You press the carriers, and one agrees to survey the valley road.", "", "", ""]),
]

# Events: id, title, flavor, trigger, available, hours, image, seasons, choices.
# Each choice: (letter, text, result, cells) with cells in Event Choices columns:
# H Constituency, I Reputation, J Party, K District, L National, M Rewards,
# Q Commitment, R Kept, S Broken, T Kept text. "decline" makes a Decline row.
E = [
 ("EV66", "Honoring the Elders at the Hall",
  "The neighborhood association is honoring every resident over eighty and asks you to hand out the certificates.",
  "Random", "Both", 2, "OUT_FESTIVAL_2_REGULAR", "Autumn", [
  ("A", "Hand out every certificate yourself", "You kneel to hand each certificate over. One man reads his twice.", {"K": "1-2", "M": "BO06 +1; BO21 +1"}),
  ("B", "Send a staff member with a message from you", "Your staffer reads your message. It is warmly received, and quickly over.", {"K": "0-1", "M": "BO21 +1"}),
  ("C", "Give a short speech on care for the elderly", "You speak for five minutes about home care. The front row nods; the back row naps.", {"I": "0-1", "M": "BO21 +1; BO23 -1"}),
  "decline"]),
 ("EV67", "Litter After the Blossom Parties",
  "After a week of blossom-viewing parties, the riverside park is buried in cans and paper.",
  "Random", "Both", 1, "OUT_STREET_2", "Spring", [
  ("A", "Join the morning cleanup with residents", "You fill four bags before breakfast. The residents take a photograph.", {"K": "1-2", "M": "BO06 +1; BO27 +1"}),
  ("B", "Send a staff member to help with the cleanup", "Your staffer fills two bags and brings back a sunburn.", {"K": "0-1", "M": "BO06 +1"}),
  ("C", "Ask the ward for more bins next spring", "The ward promises to look at it before next spring.", {"M": "BO27 +1; BO23 -1"}),
  "decline"]),
 ("EV68", "A Car That Never Moves",
  "A rusted car has sat outside the apartment blocks for half a year. The residents want it gone.",
  "Random", "Weekday", 1, "OUT_STREET_1", None, [
  ("A", "Ask the police to tow it today", "The tow truck comes by evening. A child waves it goodbye.", {"H": "0-1", "M": "BO27 +1"}),
  ("B", "Have a staff member check on the owner first", "Your staffer finds the owner has been in hospital since spring. His family moves the car.", {"M": "BO21 +1"}),
  ("C", "Leave a note on the windshield", "The note is still there a week later, a little faded.", {"M": "BO06 +1; BO27 -1"}),
  "decline"]),
 ("EV69", "The Farm Road Washes Out",
  "Last night's storm took out the only road to six farms. The co-op asks whether you will come and see it.",
  "Random", "Both", 2, "OUT_FARM_1; OUT_FARM_2", "Summer; Autumn", [
  ("A", "Walk the washout with the farmers", "You stand in the mud where the road used to be. The farmers notice your shoes.", {"K": "1-2", "M": "BO10 +1; BO30 +1"}),
  ("B", "Send a staff member with a camera", "Your staffer's photographs reach the prefecture by evening.", {"K": "0-1", "M": "BO10 +1"}),
  ("C", "Press the prefecture for an emergency repair", "You promise the co-op you will press the prefecture this week.",
   {"M": "BO10 +1; BO23 -1", "Q": "Promise Hours 1 within 48 for BO10", "R": "BO10 +2; BO30 +1", "S": "BO10 -3; Reputation -1",
    "T": "You press the prefecture until a crew is sent, and a gravel road is open within the week."}),
  "decline"]),
 ("EV70", "Old Campaign Boards Still Standing",
  "The poster boards from the last campaign are still up on three corners, your own face among them, peeling.",
  "Random", "Weekday", 1, "OUT_STREET_3", None, [
  ("A", "Ask your supporters to take them down this weekend", "Your supporters clear all three corners and keep one poster as a souvenir.", {"M": "BO03 +1; BO06 +1"}),
  ("B", "Have a staff member call the ward to remove them", "The ward removes them, and sends your office a polite reminder.", {"M": "BO06 +1"}),
  ("C", "Leave them; the ward will get to it", "Someone draws a moustache on your face.", {"M": "BO06 -1; BO23 +1"}),
  ]),
 ("EV71", "A Supporter's Grandson Is Getting Married",
  "An elder of the Local Kōenkai invites you to her grandson's wedding reception this weekend.",
  "Random", "Weekend", 2, None, None, [
  ("A", "Attend and give a short toast", "You keep the toast to two minutes. The grandmother says it was three too short.", {"K": "0-1", "M": "BO03 +1; BO12 +1"}),
  ("B", "Send a telegram of congratulations", "The telegram is read out between the speeches.", {"M": "BO03 +1"}),
  ("C", "Send a staff member with a gift", "Your staffer brings a gift and leaves with cake.", {"M": "BO03 +1; BO12 +1", "Q": "Funds 10000"}),
  "decline"]),
 ("EV72", "The Ditch That Floods",
  "Every heavy rain, the drainage ditch behind the housing estate overflows into the gardens, and the mosquitoes follow.",
  "Random", "Both", 1, "OUT_STREET_2", "Summer", [
  ("A", "Organize a cleanup day with residents", "Twenty residents clear the ditch in an afternoon. The next rain stays in it.", {"K": "1-2", "M": "BO06 +1; BO27 +1"}),
  ("B", "Send a staff member to photograph it for the ward", "Your staffer's photographs reach the ward office the same day.", {"K": "0-1", "M": "BO06 +1"}),
  ("C", "Press the ward for a permanent drain", "You promise the residents you will press the ward for a real drain.",
   {"M": "BO27 +1; BO23 -1", "Q": "Promise Hours 1 within 72 for BO27", "R": "BO27 +2; BO06 +1", "S": "BO27 -3; Reputation -1",
    "T": "You press the ward, and a covered drain goes on next year's works list."}),
  "decline"]),
 ("EV73", "Will You Lend Your Name?",
  "The organizers of a charity fun run for the children's hospital ask whether they can list you as an honorary patron.",
  "Random", "Weekday", 1, None, None, [
  ("A", "Agree, and run the first lap", "You finish the first lap in last place, to loud applause.", {"L": "0-1", "M": "BO12 +1; BO21 +1"}),
  ("B", "Agree, and send a staff member to the start line", "Your staffer fires the starting horn.", {"M": "BO12 +1"}),
  ("C", "Ask to see their accounts first", "The accounts are in order. The organizers are a little hurt you asked.", {"M": "BO26 +1; BO12 -1"}),
  "decline"]),
 # Follow-ups, scheduled by a choice above (or VQ01 A).
 ("EV74", "The Streetlight Is Back On",
  "Hanako Okuda writes: the corner light came on last night. She asks whether the next corner could be next.",
  "Followup", "Both", 1, "OUT_STREET_1", None, [
  ("A", "Walk the corner with her this evening", "The light hums. She points out the next three dark corners.", {"K": "0-1", "M": "BO06 +1"}),
  ("B", "Write to thank the ward office", "The ward office is surprised to be thanked.", {"M": "BO04 +1"}),
  ("C", "Ask the ward about the next corner too", "You promise to raise the next corner with the ward.",
   {"M": "BO06 +1", "Q": "Promise Hours 1 within 72 for BO06", "R": "BO06 +2", "S": "BO06 -3; Reputation -1",
    "T": "You raise the next corner with the ward, and it goes on the same repair list."}),
  ]),
 ("EV75", "The Passport Arrives in Time",
  "Chihiro Endo's passport arrived two days before the flight. A reporter from the local paper has heard about it and wants the story.",
  "Followup", "Both", 1, None, None, [
  ("A", "Give the paper the story", "The story runs with your photograph. Some readers ask why their own forms are still waiting.", {"L": "1-2", "M": "BO08 +1; BO23 -1"}),
  ("B", "Keep it private, as the family asked", "The family sends a short card from abroad.", {"M": "BO12 +1"}),
  ("C", "Credit the ministry staff who rushed it", "The ministry clerks pin the article to their noticeboard.", {"I": "0-1", "M": "BO17 +1"}),
  ]),
 ("EV76", "The Crows Move One Street Over",
  "The nets work on Hanako Okuda's street. The crows have moved to the next one, and its association is at your door.",
  "Followup", "Both", 1, None, None, [
  ("A", "Get nets for the next street too", "You promise the next street its nets.",
   {"M": "BO06 +1", "Q": "Promise Hours 1 within 48 for BO06", "R": "BO06 +2", "S": "BO06 -3; Reputation -1",
    "T": "You get nets for the next street. The crows move on to the river."}),
  ("B", "Tell them to buy nets as a group", "They buy nets as a group, and grumble as a group.", {"M": "BO23 +1; BO06 -1"}),
  ("C", "Ask the ward to change pickup times citywide", "The ward agrees to study pickup times.", {"M": "BO27 +1"}),
  ]),
 ("EV77", "The Pothole Is Patched",
  "The market-road pothole is filled. The delivery drivers have left a thank-you note and a box of doughnuts at your office.",
  "Followup", "Both", 1, None, None, [
  ("A", "Share the doughnuts with your staff", "Your staff decide you should fix more potholes.", {"M": "BO14 +1"}),
  ("B", "Thank the road crew in person", "The road crew are not used to being thanked. They offer you a hard hat.", {"K": "0-1", "M": "BO09 +1"}),
  ]),
 ("EV78", "The Veteran's Claim Comes Back",
  "The ministry has approved the coast guard veteran's claim. The Veterans' Association invites you to a small celebration at its hall.",
  "Followup", "Both", 1, None, None, [
  ("A", "Attend and say a few words", "The old man shakes your hand for a long time.", {"K": "0-1", "M": "BO22 +1; BO15 +1"}),
  ("B", "Send a staff member with a letter", "Your letter is read out and pinned beside his old photograph.", {"M": "BO22 +1"}),
  ("C", "Ask the ministry how many claims are stuck like his", "You promise the association you will ask how many others are waiting.",
   {"M": "BO22 +1; BO23 -1", "Q": "Promise Hours 1 within 72 for BO22", "R": "BO22 +2; Reputation +1", "S": "BO22 -3; Reputation -1",
    "T": "You ask the ministry. Forty claims are stuck the same way, and a clerk is assigned to them."}),
  ]),
 ("EV79", "The Owner of the Empty House Is Found",
  "The town has traced the empty house's owner to Sapporo. He wants to sell, but not to pay for the demolition.",
  "Followup", "Both", 1, None, None, [
  ("A", "Help him apply for a demolition grant", "The grant covers most of it. The fox will need a new home.", {"M": "BO30 +1; BO23 -1"}),
  ("B", "Tell him the cost is his", "He says he will think about it, from Sapporo.", {"M": "BO23 +1; BO30 -1"}),
  ("C", "Ask the village whether it wants the land", "The village hall fills with ideas for the land, most of them for a park.", {"M": "BO06 +1; BO30 +1"}),
  ]),
 ("EV80", "The Phone Company Writes Back",
  "A carrier will survey the valley road for a tower, if the town provides the land at no charge.",
  "Followup", "Both", 1, None, None, [
  ("A", "Ask the town to offer the land", "The town agrees, after a long meeting.", {"M": "BO21 +1; BO30 +1; BO23 -1"}),
  ("B", "Ask the carrier to pay rent like anyone else", "The carrier says it will consider it, which means no.", {"M": "BO23 +1; BO21 -1"}),
  ("C", "Ask the other carriers to share the tower", "Two carriers agree to share, if the third goes first.", {"M": "BO16 +1"}),
  ]),
 ("EV81", "The Scam Calls Come Again",
  "Ayako Kudo calls: since your session, two of her clients hung up on scammers. A third was not there, and lost her savings.",
  "Followup", "Both", 1, None, None, [
  ("A", "Hold a second session in the next town", "You promise a second session for the next town.",
   {"M": "BO21 +1", "Q": "Promise Hours 2 within 96 for BO21", "R": "BO21 +2; BO26 +1", "S": "BO21 -3; Reputation -1",
    "T": "You hold the second session. A man stands up to say he hung up on one this morning."}),
  ("B", "Push the banks to hold large transfers by the elderly", "The banks agree to a call-back on large transfers, grudgingly.", {"M": "BO26 +1; BO24 -1"}),
  ("C", "Send a staff member door to door with leaflets", "Your staffer delivers two hundred leaflets and hears a hundred stories.", {"M": "BO21 +1"}),
  ]),
 ("EV82", "The Wind Turbine Meeting",
  "The village hall is full. The company has brought a model of the turbine, and the sheep farmers have brought their questions.",
  "Followup", "Both", 1, None, None, [
  ("A", "Ask the company to move it one ridge further", "The company agrees to study the far ridge. The farmers applaud.", {"M": "BO30 +1; BO16 -1"}),
  ("B", "Back the turbine as planned", "The company thanks you. The back row does not.", {"M": "BO16 +1; BO30 -1"}),
  ("C", "Ask for a share of the power income for the village", "The company offers a small share. The village asks for a bigger one.", {"M": "BO30 +1; BO10 +1; BO16 -1"}),
  ]),
]

DECLINE_RESULT = {
 "EV66": "You decline the invitation. The certificates are handed out by the association chair.",
 "EV67": "You decline. The residents clear the park without you.",
 "EV68": "You decline to get involved. The car stays where it is.",
 "EV69": "You decline the visit. The farmers walk the washout on their own.",
 "EV71": "You decline the invitation. Your seat at the reception is given to a cousin.",
 "EV72": "You decline. The ditch floods again with the next rain.",
 "EV73": "You decline. The run goes ahead with another patron's name.",
}
GAME_TERMS = re.compile(r"\b(levels?|stages?|energy)\b", re.I)


def parse_effects(text):
    out = {}
    for part in [p.strip() for p in (text or "").split(";") if p.strip()]:
        target, delta = part.rsplit(" ", 1)
        out[target] = int(delta)
    return out


def budget_ok(effects):
    big = 0
    strong = False
    for text in effects:
        d = parse_effects(text)
        total = sum(abs(v) for v in d.values())
        net = sum(d.values())
        has_cost = any(v < 0 for v in d.values())
        strong = strong or any(v >= 3 for v in d.values())
        assert 2 <= total <= 7, text
        assert net <= 1 or has_cost, text
        big += net >= 2
    assert strong and big <= 2, effects


def range_max(cell):
    if not cell:
        return 0
    return int(str(cell).split("-")[-1])


def decline_cells(choices):
    """1.5 x the shortfall of the staff choice against choice A, rounded half up, as a loss."""
    a = choices[0][3]
    staff = next((c[3] for c in choices if isinstance(c, tuple) and "staff member" in c[1]), {})
    cells = {}
    for col in "HIJKL":
        gap = range_max(a.get(col)) - range_max(staff.get(col))
        if gap > 0:
            cells[col] = str(-int(math.floor(gap * 1.5 + 0.5)))
    ra, rs = parse_effects(a.get("M")), parse_effects(staff.get("M"))
    losses = []
    for target, value in ra.items():
        gap = value - rs.get(target, 0)
        if gap > 0:
            losses.append(f"{target} -{int(math.floor(gap * 1.5 + 0.5))}")
    if losses:
        cells["M"] = "; ".join(losses)
    return cells


def check():
    texts = []
    for q in Q:
        assert len(q[3]) == 4 and len(q[4]) == 4
        budget_ok(q[4])
        assert any(not c for c in q[7]), q[0] + " needs a free choice"
        for c, k in zip(q[7], q[8]):
            assert bool(k) == ("Promise" in c), q[0]
        texts += [q[2]] + q[3] + q[5] + q[6] + [t for t in q[8] if t]
    for e in E:
        texts += [e[1], e[2]]
        for c in e[8]:
            if c == "decline":
                continue
            texts += [c[1], c[2]]
    for t in texts:
        assert not GAME_TERMS.search(t), t
    print(len(Q), "questions,", len(E), "events,", sum(1 for e in E for c in e[8] if c == "decline"), "declines; checks pass")


def write():
    from wbx import WB
    w = WB("design/Game_Workbook.xlsx")
    vq = "Visitor Questions"
    style = w.last_data_row(vq)
    for q in Q:
        cells = {"A": q[0], "B": q[1], "C": q[2], "H": "A"}
        for i, col in enumerate("DEFG"):
            cells[col] = q[3][i]
        for i, col in enumerate("MNOP"):
            cells[col] = q[4][i]
        for i, col in enumerate("QRST"):
            cells[col] = q[5][i]
        for i, col in enumerate("UVWX"):
            cells[col] = q[6][i]
        for i, col in enumerate(["Y", "Z", "AA", "AB"]):
            if q[7][i]:
                cells[col] = q[7][i]
        for i, col in enumerate(["AC", "AD", "AE", "AF"]):
            if q[8][i]:
                cells[col] = q[8][i]
        w.append_row(vq, cells, style_row=style)
    # VQ01 A now schedules the streetlight follow-up.
    row = w.find_row(vq, "VQ01")
    w.set_cell(vq, row, "Y", "Hours 1; Followup EV74 after 72")
    ev_style = w.last_data_row("Events")
    ch_style = w.last_data_row("Event Choices")
    for eid, title, flavor, trigger, available, hours, image, seasons, choices in E:
        cells = {"A": eid, "B": title, "C": flavor, "D": trigger, "E": available, "F": hours}
        if trigger == "Random":
            cells["I"] = 5
        if image:
            cells["M"] = image
        if seasons:
            cells["Q"] = seasons
        w.append_row("Events", cells, style_row=ev_style)
        letters = "ABCD"
        for i, c in enumerate(choices):
            if c == "decline":
                cells = {"A": eid, "B": letters[i], "C": "@event.decline", "D": "@event.decline." + eid}
                cells.update(decline_cells(choices))
            else:
                cells = {"A": eid, "B": c[0], "C": c[1], "D": c[2]}
                cells.update(c[3])
            w.append_row("Event Choices", cells, style_row=ch_style)
    for eid, text in DECLINE_RESULT.items():
        w.copy_row("Text", "event.decline.EV65", {"Key": "event.decline." + eid,
            "Where": "Event Choices: the result of declining " + eid, "English": text,
            "Notes": "2026-11-08 mundane casework batch. Claude's draft for Cameron to rewrite."})
    w.save()
    print("written")


if __name__ == "__main__":
    check()
    if "--write" in sys.argv:
        write()
