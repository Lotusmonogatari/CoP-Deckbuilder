"""Style voice banks for opponent cues (2026-10-18). Each entry:
STYLE[style][verb] = (generic, topic_templates, party_templates)
Lines: nine words or fewer, no time words, no invented history, not a reply.
{topic} = a noun phrase for the speaker's business; {care} = their party's concern."""
STYLE = {
"Earnest": {
 "attack": (
  ["I mean this plainly: your case falls short.","I will say it straight. This does not work.","I came to be honest with you.","Judge this by the facts, not the speech.","I say this with respect. You are mistaken.","Plain words: that answer is not enough.","I believe you can do better.","I have no trick. I just disagree.","My view is simple. This is wrong.","Say what you mean, and mean it.","I owe you a straight answer. Here it is.","Respect works both ways. Show some."],
  ["{topic} deserves an honest answer.","I speak plainly about {topic}.","Tell the truth about {topic}.","{topic} is no place for spin."],
  ["I stand for {care}. That is all.","{care} is why I am here.","Honest politics starts with {care}."]),
 "gain": (
  ["I mean it. That is the whole point.","Plain truth wins me over.","I will keep my word on this.","That is an honest case. Thank you.","I say yes, and I say it openly.","Simple and fair. I can stand behind it.","I believe that. It sounds true.","No tricks here. Just my honest view.","You can count on what I say.","I back it, and I will say why.","That earns my respect.","I will stand by that in public."],
  ["{topic} needs people who mean it.","I back honest work on {topic}.","Good. {topic} gets a fair hearing.","That is the right way to treat {topic}."],
  ["{care} is served by a straight answer.","I speak for {care}. I mean it.","Honest dealing helps {care}."]),
 "block": (
  ["I will not move on this. I am sorry.","My answer is no, and I mean it.","I hold this line in good faith.","I cannot agree. I will not pretend to.","Here I stand. I will not hide it.","I owe my honest no to this.","I would rather be plain than popular.","That is a line I will not cross.","I will keep faith with my own word.","Please do not ask me to bend.","My conscience says no.","I cannot sign my name to that."],
  ["I will not trade away {topic}.","{topic} is not something I will bend on.","I protect {topic} in good faith.","My word on {topic} is not for sale."],
  ["I owe {care} a firm no.","{care} will not be bargained away.","I stay true to {care}."]),
},
"Emotional": {
 "attack": (
  ["Look at the faces you are failing!","People are hurting, and you talk numbers!","How can you say that to them?","My heart breaks at that answer!","Think of the families listening!","This is about real lives, not papers!","I cannot stay calm about this!","Have you no feeling for them?","Shame on a plan like that!","I will not be shouted down!","Tears are not a weakness!","Say it to their faces!"],
  ["{topic} is about people, not paper!","My heart is with {topic}!","How can you treat {topic} so coldly?","{topic} means real lives to me!"],
  ["{care} is in my heart!","I weep for {care}!","I fight for {care} with everything!"]),
 "gain": (
  ["Yes! That warms my heart!","Thank you! People will feel that!","I could cry. That is kind!","That brings hope to so many!","Someone who truly cares, at last!","I feel it too. Thank you!","Bless that answer!","That lifts a heavy weight!","Smiles will follow from this!","My heart is full!","That gives people courage!","That is human, and I thank you!"],
  ["{topic} will feel the difference!","Thank you for caring about {topic}!","That brings hope to {topic}!","{topic} deserves this kindness!"],
  ["{care} will be glad of this!","My heart is with {care}. Thank you!","That honors {care}!"]),
 "block": (
  ["I cannot do it. It hurts too much!","Not with those faces in front of me!","My heart will not allow it!","Do not ask me to turn away!","I would sooner weep than agree!","No! People would be hurt!","I cannot look them in the eye!","That is more than I can bear!","Please, understand why I refuse!","Whatever the cost, I say no!","I will stand here, trembling or not!","I will not abandon them!"],
  ["I cannot abandon {topic}!","{topic} would be hurt by that!","Not with {topic} on the line!","I will shield {topic} with my heart!"],
  ["{care} would not forgive me!","I stand between {care} and harm!","For {care}, my answer is no!"]),
},
"Appeal": {
 "attack": (
  ["We can do better together than that.","Friends, this is not how we do things.","Let us find a fairer path, all of us.","We are on the same side. Act like it.","A good turn deserves another. Where is yours?","We owe each other more than this.","Come, let us be neighbors about this.","I ask you as a friend: reconsider.","We share this house. Treat it so.","Together we can fix this. Not that way.","One hand helps the other. Offer yours.","We all want better. This is not it."],
  ["Let us look after {topic} together.","{topic} belongs to all of us.","We owe {topic} a fair deal.","Friends of {topic} expect more."],
  ["We who care for {care} ask better.","{care} is our shared cause.","Let us honor {care} together."]),
 "gain": (
  ["That is the spirit. We are with you.","Together, we can make that real.","Good. That brings us closer.","We will remember that kindness.","A fine turn. We return the favor.","That is what friends do for each other.","We stand together on that.","We are getting somewhere, all of us.","Count us in on that.","That builds trust between us.","Let us shake on it.","Many hands make that work."],
  ["{topic} thrives when we work together.","Friends of {topic} will back that.","That is a favor {topic} will repay.","We all gain when {topic} gains."],
  ["{care} grows when we pull together.","Friends of {care} will cheer this.","Together, we serve {care}."]),
 "block": (
  ["We would rather not go that way, friend.","Let us not close this door on each other.","We hold back for all of our sakes.","Friends do not push friends like that.","Give us room, and we give you room.","We stand together on this one.","Please, let us find a middle way.","Not without everyone at the table.","We can wait for a fairer offer.","Let us keep this civil and shared.","We guard what we share.","Do not ask us to go alone."],
  ["We protect {topic} together.","{topic} stays safe with all of us.","Friends of {topic} hold the line.","Not without {topic} at the table."],
  ["{care} is ours to guard together.","We keep faith with {care}.","Friends of {care} stand firm."]),
},
"Data Driven": {
 "attack": (
  ["Those figures do not support your claim.","Two numbers disagree. Pick one.","Yes or no: can you fund that?","The data point the other way.","Cite the source. Then we talk.","That claim fails a simple check.","Ninety seconds of math undoes it.","Show the cost. Show the benefit.","The sample is too small to matter.","Your estimate is off by a wide margin.","Correlation is not your argument.","Provide the number, not the adjective."],
  ["The numbers on {topic} do not add up.","What does {topic} cost? State it.","Yes or no: does {topic} improve?","The data on {topic} contradict you."],
  ["Does the evidence favor {care}? Show it.","The record on {care} says otherwise.","Quantify the effect on {care}."]),
 "gain": (
  ["That figure checks out. Accepted.","The evidence supports that. Agreed.","Yes. The numbers hold.","Three of three checks pass.","That is measurable, and I accept it.","The method is sound. I agree.","The result is within range. Good.","A clear source. Good enough.","That claim survives scrutiny.","The trend supports it. Yes.","I verified it. It stands.","Correct on the numbers."],
  ["The data on {topic} favor that.","{topic} metrics support the case.","The figures for {topic} agree. Yes.","Yes: the numbers on {topic} improve."],
  ["The evidence for {care} is solid.","The record on {care} backs it.","Measured against {care}, it passes."]),
 "block": (
  ["Not without the numbers published.","The data do not justify a yes.","No. The error bars are too wide.","I need the audit first.","The model fails a stress test.","Insufficient evidence. My answer is no.","The baseline is missing. No.","Show a control group, then ask.","The risk is too high to approve.","The threshold is not met.","The figures are incomplete.","Request denied pending verification."],
  ["No change to {topic} without data.","The record on {topic} must be audited.","Show the figures for {topic} first.","{topic} requires evidence, not hope."],
  ["No cost estimate for {care}. No deal.","Evidence for {care} comes first.","Prove the effect on {care}."]),
},
"Divisive": {
 "attack": (
  ["Pick a side. The voters are watching.","You are with us or against us.","People like you are the problem.","There are two camps. You chose wrong.","Spare us the neutral act.","Whose side are you really on?","We know who you answer to.","Their side is losing, and so are you.","Stop pretending you stand in the middle.","Draw the line and own it.","You belong to the other camp.","Real people are on our side."],
  ["Whose side is {topic} on? Ours.","{topic} has friends and enemies. Pick.","Enemies of {topic} sit across the aisle.","Defend {topic} or stand aside."],
  ["{care} against the establishment!","Our {care} against theirs.","Stand with {care} or stand against it."]),
 "gain": (
  ["Our side is gaining. Join it.","That is the right side to be on.","Another one comes over to us.","The other camp is shrinking.","Good. Stand with us, not them.","That proves who is right.","We are the majority that counts.","You know where the line is.","The opposition looks smaller to me.","Welcome to the winning side.","They lose. We gain.","Our people are growing in number."],
  ["{topic} belongs to our side.","Friends of {topic} versus the rest.","{topic} is ours to defend against them.","We take {topic} from the other camp."],
  ["Friends of {care} versus the rest.","{care} is on our side.","Our {care} wins over theirs."]),
 "block": (
  ["We do not give ground to them.","No deal with the other camp.","That is their idea. We refuse it.","Hold the line against those people.","Whatever they offer, we say no.","Not one step toward their side.","We stay where we are, and so do they.","There is no middle for you here.","We do not shake that hand.","Their terms are not our terms.","I will not stand with them.","The line stays where it is."],
  ["We do not hand {topic} to them.","{topic} stays on our side of the line.","Hands off {topic}, outsiders.","No surrender of {topic} to them."],
  ["{care} stays with our side.","We guard {care} from them.","No middle ground on {care}."]),
},
"Duplicitous": {
 "attack": (
  ["Some might say that was unwise...","It has been suggested you erred...","Mistakes may have been made here...","One hears troubling things, of course...","It would be a shame if this spread...","Concerns have been raised, quietly...","I am only asking, you understand...","Perhaps this was overlooked by you...","A pity if this were misunderstood...","Not that I would say it myself...","Things are said in the corridors...","I merely wonder about your motives..."],
  ["It is said that {topic} is neglected...","Some wonder what became of {topic}...","One hears worrying things about {topic}...","Perhaps {topic} deserves a closer look..."],
  ["{care} may feel overlooked, I hear...","Concerned parties for {care} are talking...","Friends of {care} have doubts, quietly..."]),
 "gain": (
  ["We will consider that positively...","That may be seen in a good light...","It has been well received, I understand...","Perhaps we can work something out...","That could be helpful to many...","I am open to it, in principle...","It might be arranged, quietly...","That is very much appreciated...","Progress seems to have been made...","Words have been exchanged to good effect...","I could be persuaded, perhaps...","It would be welcomed, I think..."],
  ["{topic} may benefit, one hopes...","It could be good for {topic}, perhaps...","{topic} will be considered favorably...","Something may be done for {topic}..."],
  ["{care} could well be advanced...","I am sympathetic to {care}, in a sense...","Arrangements for {care} are possible..."]),
 "block": (
  ["No decision has been made, of course...","It is being looked into, I believe...","That was not what was intended...","I could not possibly comment...","Matters are under review, naturally...","It is a complex question, you see...","The details are being clarified...","I was not consulted, as it happens...","There may be a misunderstanding...","I will have to take that away...","Nothing has been agreed...","One would need to see the paperwork..."],
  ["Nothing is decided on {topic}, naturally...","{topic} is under review, I am told...","I could not comment on {topic}...","On {topic}, no commitments were made..."],
  ["{care} is a delicate matter...","Nothing is settled on {care}...","I cannot speak for {care}, you see..."]),
},
}
TOPIC = {
 "Committee on Government Administration":"the civil service",
 "Committee on Ethics and Prosecution":"clean government",
 "Committee on the Environment":"the land",
 "Committee on Foreign Affairs":"our standing abroad",
 "Committee on the National Assembly":"the chamber",
 "Committee on Agriculture":"the farms",
 "Committee on Finance":"the budget",
 "Committee on War":"our defenses",
 "Committee on Construction and Development":"our roads and towns",
 "Journalist":"the public record",
 "Student":"our future",
 "Constituent":"this district",
 "Neighborhood Association Member":"our block",
 "Family Network Member":"our households",
 "Kōenkai Member":"our supporters",
 "Committee of the Cabinet":"the government",
 "Chamber of Commerce Lobbyist":"local business",
 "Labor Federation Member":"working people",
 "Agricultural Cooperative Member":"the harvest",
 "Fisheries Cooperative Member":"the harbor",
 "Mayors' Network Representative":"our towns",
 "Our Traditional Society Member":"our customs",
}
CARE = {
 "Butsutou":"the vulnerable","Yezo Heritage Party":"heritage and the land",
 "Frontier Party":"the regions","Five Point Independents":"the citizen",
 "Keizaijiyuutou":"a growing economy","Country Initiative":"order and custom",
}
