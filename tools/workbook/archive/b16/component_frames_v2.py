"""Component (bill-part) line frames, brought up to date 2026-11-09 (writing review
group 2, item G; Cameron decision #56). Supersedes archive/b11/component_frames.py.

SET A is the wording that is in the data today: the 2026-10-25 hand rewrite (commit
104d9ed) plus the 2026-11-09 writing-review fixes (organization articles, "Members
of ... want us to", stance-free Appeal and Data Driven lines, varied critic clauses).
Set A rows are NOT regenerated: their text, including per-row hand variants of the
critic clause, stays exactly as it is in the workbook. The A lists below record the
frames for reference only.

SETS B and C are new. A part's set follows its slot, so the two or three parts of a
sponsored bill (slots X+Y, or Z+W+A/B/C) never share a set:
    X, Z -> A    Y, W -> B    A, B, C, D, V -> C
Slots: {p} the part's phrase (a bare verb phrase), {who} / {Who} the people the part
serves, as the data already names them ("the members of the Chamber of Commerce",
"constituents"). Opponent frames carry the side they argue (None = neutral question,
"Against" = an attack on the part), as the Opponent Cues Side columns do.
All drafts for Cameron."""
SUITS = ['Earnest', 'Emotional', 'Appeal', 'Data Driven', 'Divisive', 'Duplicitous']
SLOT_SET = {'X': 'A', 'Z': 'A', 'Y': 'B', 'W': 'B', 'A': 'C', 'B': 'C', 'C': 'C', 'D': 'C', 'V': 'C'}

PLAYER_A = {  # reference: the data's current frames ({the_owner}, {The_rival} hand-varied per row)
'Earnest': ["I will say plainly why we should {p}.", "Members of {the_owner} want us to {p}, and I think they are right.",
            "If we {p}, I will answer for every part of it.", "To {p} is to keep faith with the members of {the_owner}.",
            "{The_rival} may disagree, but I believe we should {p}.", "Judge me on whether we {p} honestly."],
'Emotional': ["Think of the people who need us to {p}!", "Members of {the_owner} want us to {p}, and their voices matter!",
              "Do not turn away from those who need us to {p}!", "I have seen what it means to families. We must {p}!",
              "This is about real families, and we should {p}!", "Hear the people it helps, then help us {p}!"],
'Appeal': ["Friends, let us hear everyone on whether to {p}.", "Let us work together to decide whether to {p}.",
           "Everyone affected by a plan to {p} deserves a hearing.", "A plan to {p} is stronger if we all shape it.",
           "We can shape a plan to {p} that works for all of us.", "Whatever we decide about whether to {p}, let us decide together.",
           "Let us work together on whether to {p}.", "Most of us would agree: hear everyone on whether to {p}.",
           "The members of {the_owner} are our neighbors. Ask them: should we {p}?", "I hope {the_rival} will join us: should we {p}?"],
'Data Driven': ["The risks of a plan to {p} are measurable, and I have measured them.", "Compare the options: weigh the plan to {p} fairly.",
                "Here is what it takes to {p}, line by line.", "Examine the figures on a plan to {p}.", "Weigh the evidence on whether to {p}.",
                "Run the numbers on a plan to {p}. They deserve scrutiny.", "The figures on a plan to {p} deserve a look.",
                "Let us see the evidence on whether to {p}.", "Run the numbers on a plan to {p}. Read them first."],
'Divisive': ["The other side fears change. We should {p}.", "Whoever stands against a plan to {p} owes the members of {the_owner} an answer.",
             "Delay is a decision against the members of {the_owner}. We should {p}.", "Those who block a plan to {p} are blocking the members of {the_owner}.",
             "Choose a side: we {p}, or we leave the members of {the_owner} behind.", "{The_rival} will fight us on this. We should {p} anyway."],
'Duplicitous': ["Of course we should {p}. Who would say otherwise?", "It may be that a plan to {p} deserves a quiet hearing.",
                "Some say we should not {p}. I would not like to comment.", "I could imagine a plan to {p} in a more modest form.",
                "I would not want a plan to {p} misunderstood.", "Perhaps {the_rival} will not mind a plan to {p} as much as feared."],
}

PLAYER = {
'B': {
 'Earnest': ["Here is my honest case for why we should {p}.", "I would not ask you to {p} if I did not believe in it.",
             "{Who} deserve a straight answer, and mine is to {p}.", "I have read every detail. We should {p}.",
             "I am asking you plainly to help us {p}.", "My name goes on this. We should {p}."],
 'Emotional': ["I have sat with the people who need us to {p}!", "Somebody's daughter, somebody's father: they need us to {p}!",
               "How long must {who} wait for us to {p}?", "Every week we wait, someone pays. Let us {p}!",
               "I will not look away. We must {p}!", "This is personal for people back home. Help us {p}!"],
 'Appeal': ["We all share an interest in a plan to {p}.", "Let us find the common ground and {p}.",
            "Any of us could back a fair plan to {p}.", "Join me, and together we can {p}.",
            "A sensible plan to {p} serves every district.", "Let us listen to {who} and shape a plan to {p}."],
 'Data Driven': ["The case to {p} rests on evidence, not hope.", "Look at the costs and the benefits: we should {p}.",
                 "The studies I have read favor a plan to {p}.", "A careful plan to {p} pays its way.",
                 "The record elsewhere supports a plan to {p}.", "Measured against the alternatives, it is wise to {p}."],
 'Divisive': ["Some would rather stall than {p}. I will not.", "You are either helping us {p} or standing in the way.",
              "Those who stall a plan to {p} will answer to {who}.", "The usual voices will object. We should {p} regardless.",
              "I know who benefits from doing nothing. We should {p}.", "Pick your side. Mine is to {p}."],
 'Duplicitous': ["I am sure nobody here truly objects to a plan to {p}.", "A plan to {p} could be arranged with very little fuss.",
                 "Let us simply say a plan to {p} has friends in many places.", "I would hate for anyone to be seen blocking a plan to {p}.",
                 "Between us, a plan to {p} is already half agreed.", "Who could be against a modest plan to {p}?"],
},
'C': {
 'Earnest': ["Let me be direct: it is right to {p}.", "I owe {who} the truth, and the truth is we should {p}.",
             "No tricks here. I want us to {p}.", "If I am wrong to {p}, show me where.",
             "I stand behind the plan to {p}, every word of it.", "It is simple. We should {p}, and I will say so anywhere."],
 'Emotional': ["I heard the stories myself. We have to {p}!", "Families are counting on us to {p}!",
               "It breaks my heart to wait. Let us {p}!", "{Who} are hurting. We can {p} and help!",
               "There are real lives behind this. Let us {p}!", "Please, for the sake of those who wait, let us {p}!"],
 'Appeal': ["We do better when we {p} together.", "Neighbors help neighbors. Let us {p}.",
            "I invite everyone here to help us {p}.", "Nobody loses when we {p} with care.",
            "There is room for all of us in a plan to {p}.", "Let us stand with {who} and {p}."],
 'Data Driven': ["Every estimate I trust points to a plan to {p}.", "Here are the facts behind a plan to {p}.",
                 "Doing nothing costs more than a plan to {p}.", "Check my sources. They support a plan to {p}.",
                 "The data are clear enough: we should {p}.", "Count what we gain if we {p}. It adds up."],
 'Divisive': ["There is no comfortable middle here. We should {p}.", "Those who sneer at a plan to {p} have never needed it.",
              "Stand with {who} or stand aside. We should {p}.", "Opposing a plan to {p} protects the few.",
              "Let the doubters object. We should {p}.", "Doing nothing is a choice too. I choose to {p}."],
 'Duplicitous': ["I hear quiet support for a plan to {p} in surprising places.", "Naturally, a plan to {p} would be handled with discretion.",
                 "It would be a pity if a plan to {p} were misread.", "One need not announce a plan to {p} too loudly.",
                 "I suspect a plan to {p} has more friends than it seems.", "Let us not make a plan to {p} sound bigger than it is."],
},
}

N, X = None, 'Against'
OPPONENT = {
'B': {
 'Earnest': [("Explain to me why we should {p}.", N), ("What happens to the people who pay if we {p}?", N),
             ("Be honest: who loses if we {p}?", N), ("I am not convinced we should {p}. Convince me.", X),
             ("Is it right to {p} when so many have doubts?", X), ("Who asked for this, and why should we {p}?", N)],
 'Emotional': [("Think of the families who pay if we {p}!", X), ("Who comforts the people hurt if we {p}?", X),
               ("My office is full of letters against a plan to {p}!", X), ("People are frightened by a plan to {p}!", X),
               ("You cannot ask the struggling to pay so we can {p}!", X), ("Have a heart. Do not rush to {p}!", X)],
 'Appeal': [("Many of us have doubts about a plan to {p}.", X), ("Let us all slow down before we {p}.", X),
            ("There must be a gentler way than to {p}.", X), ("Friends, a plan to {p} needs more of us behind it.", X),
            ("We could find common ground short of a plan to {p}.", X), ("I ask everyone to think twice before we {p}.", X)],
 'Data Driven': [("What evidence says we should {p}?", N), ("The costs of a plan to {p} are understated.", X),
                 ("Has anyone checked the figures on a plan to {p}?", N), ("Others tried to {p}. The results were mixed.", X),
                 ("Give me the estimate before we {p}.", N), ("The projections behind a plan to {p} look optimistic.", X)],
 'Divisive': [("A plan to {p} serves insiders, not the public.", X), ("Whose side are you on if you want to {p}?", N),
              ("Only a narrow few want us to {p}.", X), ("Those pushing to {p} do not speak for my voters.", X),
              ("You cannot sit on the fence: do we {p} or not?", N), ("We should refuse to {p}, and say so loudly.", X)],
 'Duplicitous': [("A plan to {p} may have friends. Not many, I hear.", N), ("I would never oppose a plan to {p}. Openly.", X),
                 ("Perhaps a plan to {p} could wait a little.", N), ("One wonders who really wants us to {p}.", N),
                 ("A plan to {p} might be quietly reconsidered.", X), ("I hear a plan to {p} has some awkward details.", N)],
},
'C': {
 'Earnest': [("Tell me plainly what it costs to {p}.", N), ("Can you promise a plan to {p} will work?", N),
             ("What would you say to someone hurt if we {p}?", X), ("I need a straight reason to {p}. I have not heard one.", X),
             ("Is a plan to {p} fair to everyone?", N), ("Honestly, I doubt we should {p}.", X)],
 'Emotional': [("Real lives would be upended if we {p}!", X), ("I have seen the fear a plan to {p} brings!", X),
               ("Please, think again before we {p}!", X), ("Who stands up for those a plan to {p} leaves out?", X),
               ("It hurts to hear you want to {p}!", X), ("Families deserve better than a rushed plan to {p}!", X)],
 'Appeal': [("Few people back home are asking us to {p}.", X), ("Let us keep everyone together and not {p} this way.", X),
            ("Friends, let us talk more before we {p}.", X), ("A plan to {p} would split us. Let us find another way.", X),
            ("Surely we can agree on something better than to {p}.", X), ("Let us not leave anyone behind if we {p}.", X)],
 'Data Driven': [("Where does the money come from if we {p}?", N), ("The data on a plan to {p} are incomplete.", X),
                 ("Show me who benefits, in figures, if we {p}.", N), ("A plan to {p} has not been tested.", X),
                 ("What are the long-run costs if we {p}?", N), ("The sums for a plan to {p} do not add up.", X)],
 'Divisive': [("A plan to {p} picks winners and losers.", X), ("Who exactly gains if we {p}? Not my people.", X),
              ("Decide: are you for a plan to {p}, or not?", N), ("Backers of a plan to {p} ignore everyone else.", X),
              ("Pushing to {p} divides this country.", X), ("We will not be bullied into a plan to {p}.", X)],
 'Duplicitous': [("Certainly we could {p}. Eventually.", N), ("I am sure a plan to {p} means well.", N),
                 ("A plan to {p}? Interesting. Let us see.", N), ("Some details of a plan to {p} might be best kept quiet.", X),
                 ("I would hate to see a plan to {p} go wrong.", N), ("It might be wiser not to {p} just yet.", X)],
},
}
