# Draft 2026-10-13 content for batch 1. Grades order: Earnest, Emotional, Appeal, Data Driven, Divisive, Duplicitous
Q=[ # id, stage, question, theme, grades
('S34','ST24','My monthly pass costs more every year. What am I paying for?','Commuter fares','SSMSWW'),
('S35','ST24','The last train leaves too early for shift workers. Will you change that?','Rail timetables','MSSMMW'),
('S36','ST24','My mother cannot climb the station stairs. Who fixes this?','Station access','SSMWWM'),
('S37','ST24','Why do commuters pay for trains while highways are free?','Transit','WMWSSM'),
('S38','ST24','Will you promise no fare increases in your term?','Commuter fares','WMSWMS'),
('S39','ST25','Which lines carry the most riders, and which run mostly empty?','Rail timetables','MWMSSS'),
('S40','ST25','How long should a connection between two lines take?','Transit','SWMSWM'),
('S41','ST25','Should timetables follow demand or serve every town equally?','Rural rail service','SMSWSM'),
('S42','ST26','Will you support raising train fares, yes or no?','Commuter fares','SWMSSW'),
('S43','ST26','The operator says fares must rise to cover costs. Do you accept that?','Rail operator costs','MWMSWS'),
('S44','ST26','Who should pay for station upgrades: riders or taxpayers?','Rail funding','MMWSSM'),
('S45','ST26','Commuters call a fare rise a betrayal. How do you answer them?','Commuter fares','SSSWWM'),
('S46','ST26','Would you cap fares for students and seniors?','Fare relief','MSSWWS'),
('S47','ST26','If fares rise, will service improve? Can you guarantee it?','Transit','MWMSMS'),
('S48','ST27','How many safety inspections does each line receive each year?','Rail safety','SWMSMW'),
('S49','ST27','Platform doors cost money. How many lives justify the cost?','Rail safety','WSMSWM'),
('S50','ST27','Who is accountable when an operator ignores a safety warning?','Rail safety','SMWMSW'),
('S51','ST27','Ageing track on rural lines worries residents. What is the plan?','Rural rail service','SSMMWS'),
('S52','ST27','Are staff cuts at stations putting passengers at risk?','Station staffing','MSMSSW'),
('S53','ST27','Should the state take over lines the operator cannot keep safe?','Rail funding','WMMMSS'),
('S54','ST28','Our fleet needs bigger quotas. What can you deliver?','Fishing quotas','MMSWWS'),
('S55','ST28','Imported fish undercuts our catch. Will you act on labelling?','Seafood labelling','SSMMMW'),
('S56','ST29','The harbour wall is cracked. Who will pay to fix it?','Harbour upkeep','SMSMWW'),
('S57','ST29','Young people leave because fishing no longer pays. How do you keep them?','Fishing livelihoods','SSMWWM'),
('S58','ST29','Quotas are set far away by people who never fish. Why?','Fishing quotas','MMWMSS'),
('S59','ST29','What is your plan for warming seas and shrinking catches?','Ocean changes','MWMSMS'),
('S60','ST29','Fuel costs eat our margins. Will you help?','Fishing livelihoods','WSSMWM'),
('S61','ST30','Is the seafood on the shelf really caught in Yezo?','Seafood labelling','SWMSMW'),
('S62','ST30','Shoppers say labels mislead them. Whose fault is that?','Label accuracy','MMWSSS'),
('S63','ST30','Would you ban the word local on unverified packaging?','Label accuracy','SMWMSW'),
('S64','ST31','On what evidence are the annual catch limits set?','Fishing quotas','SWMSWM'),
('S65','ST31','Small boats say big fleets take the best quota. Is that fair?','Fishing quotas','MSMMSW'),
('S66','ST31','How will you check that catch reports are honest?','Catch reporting','SWMMMS'),
('S67','ST31','Should unused quota be returned to the pool?','Fishing quotas','MMWSMS'),
('S68','ST31','Who pays for patrol boats against illegal fishing?','Illegal fishing','SMMMSM'),
('S69','ST31','Will quota reform protect the family boats?','Fishing livelihoods','WSSMWS'),
]
# new themes: theme, organisations, why, annoys
THEMES=[
('Rail safety','BO14; BO26','Commuter Committee and Consumer Advocacy Network follow whether trains and stations are safe.',''),
('Rural rail service','BO30; BO04; BO14','Rural Revitalization Council and Mayors\' Network want branch lines kept; Commuter Committee follows service.',''),
('Rail funding','BO23; BO14','Taxpayers\' Alliance asks who pays; Commuter Committee asks what riders get.',''),
('Fare relief','BO14; BO11; BO21','Commuter Committee, Students United and Care and Welfare Council follow fare caps for students and seniors.',''),
('Rail operator costs','BO05; BO23','Chamber of Commerce and Taxpayers\' Alliance weigh operator costs against fares.',''),
('Station staffing','BO09; BO14','Labor Federation follows station jobs; Commuter Committee follows service at stations.',''),
('Fishing livelihoods','BO07; BO30; BO12','Fisheries Cooperative, Rural Revitalization Council and Family Network follow whether fishing families can stay.',''),
('Ocean changes','BO07; BO16','Fisheries Cooperative and Innovation Society follow warming seas and shrinking catches.',''),
('Label accuracy','BO26; BO07','Consumer Advocacy Network wants honest labels; Fisheries Cooperative wants domestic catch told apart.',''),
('Catch reporting','BO07; BO26','Fisheries Cooperative and Consumer Advocacy Network follow whether catch reports can be trusted.',''),
('Illegal fishing','BO07; BO22','Fisheries Cooperative and Veterans\' Association (coastal security) follow patrols against illegal fishing.',''),
]
# cues: (level, suit, verb) -> two lists of 5
PC={ # player
('A','Data Driven','attack'):[
 ["Which fares rise, and by how much?","Show me the ridership figures.","Name the line that earns its subsidy.","Cost per passenger. Give me the number.","Your timetable data does not add up."],
 ["Is the operator in profit or loss?","Where is the safety audit?","The delay statistics tell a different story.","Fares or service. You cannot cut both.","Publish the numbers or withdraw the claim."]],
('A','Data Driven','gain'):[
 ["The figures support a fare freeze.","Ridership data points one way.","Run the numbers. They hold up.","Every line on this chart is sourced.","The audit confirms the safety case."],
 ["Compare cost per rider across all lines.","Delays fall when timetables follow demand.","The evidence is in the appendix.","A fare cap costs less than empty trains.","Check the figures. I will wait."]],
('A','Data Driven','block'):[
 ["Those figures are audited and public.","The data does not support that claim.","Read the source before you object.","Cite the table. I will answer.","Averages hide the variation by line."],
 ["The methodology is on the record.","Correlation is not cause on this chart.","Ask the operator for the raw data.","Your sample is too small to matter.","Check the denominator first."]],
('A','Emotional','attack'):[
 ["Think of the night-shift nurse waiting!","Families are counting every yen!","Seniors cannot climb those stairs!","Students skip meals to afford fares!","Tell the commuters to their faces!"],
 ["Real people ride these trains!","A ticket is a week of groceries!","Who speaks for the people on the platform?","Explain this to a tired parent!","Remember who pays at the turnstile!"]],
('A','Emotional','gain'):[
 ["I ride these lines with you!","Every commuter deserves a safe platform!","Together we keep the trains running!","This fight is for every rider!","I will not let fares crush families!"],
 ["Our towns need their trains!","No one should dread the ticket machine!","This is about dignity on the commute!","Hear the riders. They are right!","Let us fix this together!"]],
('A','Emotional','block'):[
 ["Do not use their struggle as a weapon!","I care about riders more than you know!","Leave families out of your argument!","My heart is with the commuters!","Do not twist their stories!"],
 ["Compassion is not weakness!","Riders deserve respect, not slogans!","Their fears are real. Mine too!","Do not wave their pain around!","I stand with them, whatever you say!"]],
('B','Earnest','attack'):[
 ["Name the boat that fishes illegally.","I have read the quota report.","The catch figures do not support you.","Plainly, the quota system is failing.","Stand behind your label or remove it."],
 ["I want honest catch reports.","Small boats deserve a fair share.","I will not accept hidden quotas.","Own the problem. Then fix it.","Your plan leaves the harbours behind."]],
('B','Earnest','gain'):[
 ["I will fix the harbour wall.","Here is my plan for the quotas.","Judge me by the catch limits.","I will check every label myself.","Plainly: family boats come first."],
 ["I will protect honest fishers.","My position on quotas is simple.","I will answer to the harbour.","No label should mislead a shopper.","I will keep this fair."]],
('B','Earnest','block'):[
 ["My answer on quotas is plain.","I have nothing to hide on catch limits.","The record on catch limits is public.","I take responsibility for this plan.","Check the quota rules yourself."],
 ["I own what the plan costs.","Fair quotas are the whole point.","I will not dodge on labelling.","The report says otherwise.","Honest labels protect honest fishers."]],
('B','Appeal','attack'):[
 ["Harbour towns stand together. Whose side are you on?","We all eat the catch. Be fair.","Friends of the harbour know better.","Surely we want fair labels together.","Good neighbours do not hide quotas."],
 ["We share these waters. Share the quota.","Our fishing towns deserve better from you.","Be a friend to the harbour.","Together we can do better than this.","A good turn deserves a fair quota."]],
('B','Appeal','gain'):[
 ["We will keep our harbours alive.","Together we protect the family boats.","Our fishing towns are one family.","We all gain from honest labels.","Let us steady the harbour together."],
 ["Friends, the sea feeds us all.","We are stronger fishing as one.","Stand with the harbour and with me.","Our shared catch deserves our shared care.","I know we agree on the sea."]],
('B','Appeal','block'):[
 ["We can settle this like neighbours.","Let us not divide the harbour.","We are all on the same boat.","Our towns need calm, not quarrels.","We agree on more than we say."],
 ["Good neighbours find the middle ground.","Do not turn friends against friends.","Let us keep the harbour united.","We share the same tide.","There is room for everyone's boat."]],
}
OC={ # opponent (general, stage-scoped)
('A','Data Driven','attack'):[
 ["Your fare projection ignores operating costs.","Where is the source for that figure?","Ridership says otherwise.","Show the audit or drop the claim.","The timetable numbers do not reconcile."],
 ["Cost per passenger. Answer or admit it.","What is the on-time rate, exactly?","Which lines would you close?","Your safety figures are incomplete.","Yes or no: will fares rise?"]],
('A','Data Driven','gain'):[
 ["The evidence favours my reading.","Check the ridership table. I am right.","These figures support the fare review.","The audit is on my side.","Delay rates prove the point."],
 ["Compare the numbers. They agree with me.","Operating costs are in the appendix.","The data is clear on this.","Every table I cite is public.","The safety record backs my plan."]],
('A','Data Driven','block'):[
 ["The sample size is adequate.","Those averages are misleading.","My figures were verified.","The operator's data is audited.","Cite your source first."],
 ["Context matters for these numbers.","That chart omits the costs.","Correct the baseline, then ask.","My methodology is sound.","The ratio is more complicated."]],
('A','Emotional','attack'):[
 ["Ordinary riders pay for your policy!","Look the commuters in the eye!","Seniors are stranded on those platforms!","Do you feel nothing for riders?","Families are the ones who suffer!"],
 ["Your fares hurt the people I serve!","Tell the night shift it is fine!","This is a heartless proposal!","Think of the children on those platforms!","People deserve better than this!"]],
('A','Emotional','gain'):[
 ["Finally, someone fights for riders!","That is what commuters need!","My heart is with the riders!","Yes! This is worth fighting for!","Safe platforms for every family!"],
 ["You understand what riders face!","That gives commuters hope!","Thank you for hearing them!","That is a decent thing to say!","Finally we speak about people!"]],
('A','Emotional','block'):[
 ["Do not dismiss their fear!","My concern for riders is genuine!","Do not belittle ordinary commuters!","I speak for people who cannot!","Their struggle is not a talking point!"],
 ["Spare us the cold arithmetic!","Riders are not statistics!","I will not be lectured about feelings!","Compassion has a place here!","My conscience is clear!"]],
('B','Earnest','attack'):[
 ["I need to see honest quotas.","Show me the catch records.","Own up to the harbour's problems.","Where is the plain answer?","I want accountability, not excuses."],
 ["Your label policy does not hold.","Say plainly what you will fix.","The small boats deserve a straight answer.","Quota rules must mean something.","Stand behind your plan or withdraw it."]],
('B','Earnest','gain'):[
 ["That is a straight answer. Thank you.","I respect plain speaking about quotas.","That is honest. I can work with it.","You own the problem. Good.","That plan has my attention."],
 ["A clear commitment is what I wanted.","I believe you mean it.","That is how a fair quota sounds.","Honest labels, honest fishers. Agreed.","Fine. You have my ear."]],
('B','Earnest','block'):[
 ["My catch records are open.","I report every landing honestly.","The rules are public and I follow them.","I hide nothing about my fleet.","Judge the harbour by its work."],
 ["Our books are in order.","Inspect the boats yourself.","I answer for my own fleet.","Fair quotas protect us both.","Let the records speak."]],
('B','Appeal','attack'):[
 ["Friends of the harbour would not do this.","We are neighbours. Act like it.","Surely you can see our side.","Our towns deserve better from you.","A fair quota is a favour to all."],
 ["Do not turn your back on us.","We hope you will stand with us.","Fisher families stand together here.","Be one of us in this.","Help us as good neighbours do."]],
('B','Appeal','gain'):[
 ["Thank you, friend. The harbour agrees.","That is the spirit we need.","We stand together on this.","Our towns will welcome that.","We share the same boat."],
 ["We all benefit from that.","Together we can make this work.","That is generous, and we welcome it.","You speak for the whole harbour.","I knew we shared common ground."]],
('B','Appeal','block'):[
 ["Let us not fall out over fish.","We are better as friends.","There is no need for sharp words.","Our differences are small.","Let us all keep the peace."],
 ["I count you as a friend.","Fisher families need us united.","Keep it friendly, and I will too.","Calm talk serves the harbour best.","No one gains from a quarrel."]],
}
TD=[ # (character, stage or '', line, reply)
('SF01','','I have the briefing notes ready. Read the first page on your way in.','I will read it on the way.'),
('SF01','','The research folder is thin on this one. Trust your instincts in there.','I usually do.'),
('SF02','','I double-checked the facts. They should hold up under pressure.','Good. That is all I need.'),
('SF02','','Whatever happens next, the numbers are on your side.','Let us hope they listen.'),
('SF08','','Reporters are gathering outside. Keep your answers short and clear.','Short and clear. Understood.'),
('SF08','','I have cleared your schedule. Focus on the room ahead.','Thank you. I will.'),
('SF09','','Every word may be quoted. Choose them with care.','I will.'),
('SF09','','The cameras are ready, but you do not need them.','Then I will ignore them.'),
('SF15','','Folks back home are watching how this goes. No pressure.','None at all, then.'),
('SF15','','I brought word from the district. People are counting on you.','I will not let them down.'),
('SF16','','The district office sent tea. It is a long session ahead.','Tea first. Then the fight.'),
('SF16','','People in the district asked me to wish you luck.','Please thank them for me.'),
('SF15','ST03','This is your own party\'s room. They will notice every word.','Then I will choose well.'),
('SF16','ST03','Caucus members like a firm hand and a friendly tone.','Firm and friendly. Got it.'),
('SF08','ST04','Pick three simple points. Say them and do not wander.','Three points. Then stop.'),
('SF09','ST04','Journalists smell hesitation. Answer plainly and keep your composure.','Plain and calm. Ready.'),
('SF01','ST02','Count the seats as you rise. Every one matters.','I know the numbers.'),
('SF02','ST02','The chamber is full. Make the first minute count.','The first minute counts most.'),
('SF15','ST24','Commuters have filled the hall. Fares are on everyone\'s mind.','Then fares are what we discuss.'),
('SF16','ST24','They want to hear about their own fares. Keep it human.','Human first, numbers second.'),
('SF01','ST25','The timetable data is in your folder. Every line is marked.','Good. Marked lines help.'),
('SF02','ST25','This room rewards patience and precise answers.','Precise it is.'),
('SF08','ST26','The fare rise is the only question they care about.','Then I will answer it.'),
('SF09','ST26','Say what you will protect, not just what you oppose.','Protect first. Oppose second.'),
('SF01','ST27','Safety records are public. Expect the members to quote them.','Then I will quote back.'),
('SF02','ST27','Be exact about inspections and costs. They will check.','Exact. Noted.'),
('SF15','ST28','The fisheries representative is blunt but fair. Meet that with plain talk.','Plain talk, then.'),
('SF16','ST28','Quotas decide whether boats stay in business. Listen first.','Listening is my strength.'),
('SF15','ST29','The harbour crowd is proud and tired. Show them respect.','Respect comes first.'),
('SF16','ST29','It smells of salt and diesel in there. Do not mind it.','I like the harbour.'),
('SF08','ST30','Cameras are waiting at the dock. Stay calm and brief.','Calm and brief.'),
('SF09','ST30','They will ask about labels. Know where the catch comes from.','I will say what I know.'),
('SF01','ST31','The catch limits are in tab three. Read them first.','Tab three. Got it.'),
('SF02','ST31','Small boats against big fleets. Expect that fight in there.','I expect it.'),
]
