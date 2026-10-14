# Draft 2026-10-13 topic cue templates. {t} = topic phrase, {T} = same with a capital first letter.
BANK={
('Earnest','attack'):["{T} deserves honesty, not slogans.","Say plainly what you mean about {t}.","Be sincere with people about {t}.","{T} is no place for games.","People deserve a straight answer on {t}."],
('Earnest','gain'):["I mean every word about {t}.","People can trust me on {t}.","{T} matters to me personally.","I will be honest about {t}.","Here is my honest view on {t}."],
('Earnest','block'):["I will not dodge {t}.","You can ask me about {t}.","I stand by what I said.","Ask plainly. I will answer plainly.","My view on {t} is sincere."],
('Emotional','attack'):["Think of the families behind {t}.","Look at the faces affected by {t}.","{T} is about real people.","Do you feel nothing about {t}?","Tell that to those hurt by {t}."],
('Emotional','gain'):["I have met people touched by {t}.","{T} weighs on me.","Their stories made me care about {t}.","I carry those families with me.","Every family I met raised {t}."],
('Emotional','block'):["You cannot dismiss people over {t}.","Do not turn {t} into a game.","I will not shrink their stories.","These are people, not statistics.","Speak gently about {t}."],
('Appeal','attack'):["People want answers on {t}.","Ask anyone in the street about {t}.","The public wants less spin on {t}.","Most people disagree with you on {t}.","Voters have spoken on {t}."],
('Appeal','gain'):["Most people I meet back {t}.","Ordinary people want action on {t}.","Voters keep raising {t}.","Ask around. People care about {t}.","The public mood favours {t}."],
('Appeal','block'):["Do not speak for everyone on {t}.","People are divided on {t}.","Do not claim the crowd on {t}.","Let the public decide {t}.","I hear all sides on {t}."],
('Data Driven','attack'):["Where are the figures on {t}?","Your numbers on {t} do not hold.","Show the evidence for {t}.","What is the real cost of {t}?","Those {t} statistics are selective."],
('Data Driven','gain'):["The evidence on {t} is clear.","Here are the figures on {t}.","Studies on {t} support this.","The cost of {t} adds up.","The numbers on {t} hold."],
('Data Driven','block'):["Check the source on {t}.","Those figures on {t} are misread.","The data does not say that.","Read the full report on {t}.","That is not what the data shows."],
('Divisive','attack'):["{T} serves insiders, not you.","Whose side are you on over {t}?","You work against the public on {t}.","This is a fight over {t}.","Wrong side of {t}. Own it."],
('Divisive','gain'):["We must choose a side on {t}.","Some lose over {t}. So be it.","{T} needs hard choices.","There is no middle ground on {t}.","I will not please everyone on {t}."],
('Divisive','block'):["Your side caused this over {t}.","Spare me the sermon on {t}.","Do not hide behind {t}.","That jab on {t} fails.","Pick a side on {t} yourself."],
('Duplicitous','attack'):["Funny how {t} suits you so well.","Who benefits from {t}, really?","Your story on {t} has gaps.","Convenient wording on {t}.","What are you leaving out on {t}?"],
('Duplicitous','gain'):["Let me reframe {t} slightly.","Everyone agrees on {t}, broadly.","{T} is simpler than you think.","I said what I said on {t}.","Trust me on {t}."],
('Duplicitous','block'):["That is not my line on {t}.","You misheard me on {t}.","I take that as praise on {t}.","A fair question on {t}. Next.","Let us move past {t}."],
}
# transition templates by family: (character, line, reply). {t} = topic phrase.
TRANS={
'TH':[('SF15','The hall is full of people worried about {t}.','Then I will listen first.'),('SF16','Keep it human when they ask about {t}.','Human first.'),('SF01','I marked the questions to expect on {t}.','Thank you.')],
'PS':[('SF01','The briefing on {t} is in your folder.','I will read it.'),('SF02','Every figure on {t} is checked and sourced.','Good. I will lean on them.'),('SF16','Take your time with {t}. Nobody is rushing you.','Patience helps.')],
'PR':[('SF08','Reporters will ask about {t} straight away.','I am ready.'),('SF09','Say plainly where you stand on {t}.','Plainly. Understood.'),('SF02','Keep one clear number on {t} in mind.','One number. Got it.')],
'HR':[('SF01','Members will quote the record on {t}.','Then I will quote back.'),('SF02','Be exact about {t}. They will check.','Exact. Noted.'),('SF15','People back home follow this hearing on {t}.','Then I will be careful.')],
'LB':[('SF15','The lobbyist cares about {t}. Hear them out.','I will listen.'),('SF09','Anything you promise on {t} may be repeated.','Then I promise little.'),('SF01','I listed what each side wants on {t}.','Useful. Thank you.')],
'MA':[('SF08','Cameras are waiting outside to ask about {t}.','Calm and brief.'),('SF09','Keep your answer on {t} short and calm.','Short and calm.'),('SF16','Breathe first. Then speak about {t}.','Breathe. Then speak.')],
'TV':[('SF08','The studio lights are hot. Keep calm on {t}.','Calm it is.'),('SF09','The viewers care about {t}. Speak to them.','Directly to them.'),('SF02','Keep your facts on {t} short and sharp.','Short and sharp.')],
'CA':[('SF15','Your own party is watching you on {t}.','Then I will choose well.'),('SF16','Caucus members will test you on {t}.','I am ready.'),('SF01','Know where your party stands on {t}.','I will check.')],
}
BADWORDS=set('always again already still before after last now soon later never ever once yet today tomorrow yesterday earlier until since then when while'.split())
def lint(line,limit=9):
    import re
    words=re.findall(r"[A-Za-z']+",line)
    bad=[w for w in words if w.lower() in BADWORDS]
    return (len(words)<=limit) and not bad and not re.search(r'\d',line)
