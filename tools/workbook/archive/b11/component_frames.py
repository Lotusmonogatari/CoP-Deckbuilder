"""Frames for component-scoped lines (Patron Bills steps 5 and 6, 2026-10-19).
Every line is about ONE component and nothing else, so any mix of components
reads naturally. Slots: {p} the component's phrase (a bare verb phrase such as
"fund rural school buses"; always after "to" or "we"), {owner} the organization
that wants it, {rival} the organization it costs. All drafts."""
SUITS = ['Earnest', 'Emotional', 'Appeal', 'Data Driven', 'Divisive', 'Duplicitous']

PLAYER = {
'Earnest': [
 "I will say plainly why we should {p}.",
 "{owner} wants us to {p}, and it is right.",
 "If we {p}, I will answer for every part of it.",
 "To {p} is to keep faith with {owner_s} members.",
 "{rival} may disagree, but I believe we should {p}.",
 "Judge me on whether we {p} honestly.",
],
'Emotional': [
 "Think of the people who need us to {p}!",
 "People depend on us to {p}, and their voices matter!",
 "Do not turn away from those who need us to {p}!",
 "I have seen what it means to them. We must {p}!",
 "This is about real families, and we should {p}!",
 "Hear them out and help us {p}!",
],
'Appeal': [
 "Most of us would agree we should {p}.",
 "Let us work together to {p}.",
 "Let us {p} for {owner_s} members.",
 "A fair plan to {p} is good for everyone.",
 "I hope {rival} will join us as we {p}.",
 "Friends, it is sensible to {p}.",
],
'Data Driven': [
 "The figures support a plan to {p}.",
 "Run the numbers on a plan to {p}. They are sound.",
 "The evidence shows why we should {p}.",
 "Here is what it takes to {p}, line by line.",
 "The risks of a plan to {p} are measurable.",
 "Compare the options: to {p} comes out ahead.",
],
'Divisive': [
 "Those who block a plan to {p} block {owner}.",
 "Choose a side: we {p}, or we leave them behind.",
 "{rival} will fight us on this. We should {p} anyway.",
 "Whoever blocks a plan to {p} answers to {owner}.",
 "Delay is a decision against {owner}. We should {p}.",
 "The other side fears change. We should {p}.",
],
'Duplicitous': [
 "Of course we should {p}. Who would say otherwise?",
 "I could imagine a plan to {p} in a more modest form.",
 "Perhaps {rival} will not mind a plan to {p}.",
 "Some say we should not {p}. I would not like to comment.",
 "It may be that a plan to {p} deserves a quiet hearing.",
 "I would not want a plan to {p} misunderstood.",
],
}

OPPONENT = {
'Earnest': [
 "Why should we {p}? Tell me honestly.",
 "Who pays if we {p}? Say it plainly.",
 "I want an honest answer: what goes wrong if we {p}?",
 "Why should we {p} just because {owner} asks?",
 "{rival} may worry about a plan to {p}. Answer them.",
 "Be straight with us: is it fair to {p}?",
],
'Emotional': [
 "You would ask us to {p}? Think of who it would hurt!",
 "{rival} may fear what happens if we {p}!",
 "Do not ask families to carry the cost if we {p}!",
 "The worry about a plan to {p} is real!",
 "This is not paperwork. It is people, and you want to {p}!",
 "Hear {rival} out on a plan to {p}!",
],
'Appeal': [
 "Most people I meet doubt that we should {p}.",
 "Let us not ignore {rival} if we {p}.",
 "A fairer plan would not {p} like this.",
 "Friends, let us look for a better way than to {p}.",
 "Surely there is a middle path short of a plan to {p}.",
 "Not everyone agrees we should {p}.",
],
'Data Driven': [
 "Show me the figures on a plan to {p}.",
 "What does it cost to {p}? Give me the number.",
 "The evidence for a plan to {p} is thin.",
 "Where is the study that says we should {p}?",
 "The risks of a plan to {p} are not accounted for.",
 "Compare the alternatives to a plan to {p}.",
],
'Divisive': [
 "Those who push us to {p} serve one group only.",
 "Choose a side: {rival}, or a plan to {p}.",
 "{owner} wants us to {p}. Who speaks for everyone else?",
 "A plan to {p} is a gift to a few.",
 "Backers of a plan to {p} owe us an answer.",
 "The other side wants us to {p}. We should say no.",
],
'Duplicitous': [
 "Of course we may {p}. Just not like this.",
 "I could imagine a plan to {p}, quietly, in another form.",
 "Some say we should {p}. I would not like to comment.",
 "Perhaps {rival} will have more to say if we {p}.",
 "It may be that a plan to {p} needs another look.",
 "Nothing is settled on a plan to {p}, naturally.",
],
}

# Question stems (about the component alone) with grade profiles by suit
# (Earnest, Emotional, Appeal, Data Driven, Divisive, Duplicitous): at least two
# Strong, at most two Weak.
QUESTIONS = [
 ("Who pays if we {p}?", "S M M S W M"),
 ("Why should Yezo {p}?", "S S M M M W"),
 ("Critics say we should not {p}. What do you tell them?", "M M S M S W"),
 ("{Owner} wants us to {p}. Why should everyone else care?", "M S M W M S"),
 ("What would it mean for my town if we {p}?", "M S S M M W"),
 ("How would you make sure we {p} fairly and on schedule?", "M W M S W S"),
 ("What goes wrong if we {p} badly?", "S M M S M W"),
 ("Is there a smaller way than to {p}?", "M M S M W S"),
]

STAFF_LINES = [
 ("SF01", "The research on a plan to {p} is thin in places. Start with the numbers.", "Numbers first."),
 ("SF08", "Someone will ask why we should {p}. Have a short answer ready.", "I will keep it short."),
 ("SF15", "People at home are asking whether we will {p}.", "Then I owe them a plain answer."),
]
THOUGHTS = [
 "If we {p}, I should be ready to answer for every part of it.",
 "Someone has to speak for {owner_s} members. It may as well be me.",
 "To {p} will make friends and enemies. I should count both.",
 "I wonder what {rival} will say if we {p}.",
]
