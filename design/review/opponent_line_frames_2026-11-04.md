# Opponent line frames for review (2026-11-04)

Drafts for Cameron to rewrite. Each frame is filled with a bill's own phrases (`design/reference/bill_facets.json`) or, for bill parts, the part's phrase, and was added only to the pools `tools/cue_coverage.py` found short.

| Side | Who says it |
|---|---|
| Neutral | anyone |
| For | a supporter, to a player who opposes the bill |
| Against | a critic, to a player who supports it |
| Ally | someone on the player's own side (shared by every bill) |

## Totals

| Kind | Lines | Rows |
|---|---|---|
| Written bills and bill parts | 1082 | 698 |
| Shared Ally lines | 84 | 24 |

## Bill frames

Slots: {bill} the bill's name; {what} what it does; {gain} who gains; {hurt} who loses out; {local} what a town would see; {risk} the main risk. A capital {Gain} starts a sentence.

**Earnest · attack · Neutral**

- Tell this room plainly what the {bill} would change for {local}.
- I want a straight answer: what does the {bill} actually do?
- Before anyone votes, explain how you would prevent {risk}.
- Say plainly who you think gains from {what}, and who does not.

**Earnest · attack · For**

- Voting down the {bill} leaves {gain} where they started. Say that to them plainly.
- {Gain} have waited long enough for {what}. Why make them wait longer?
- If you oppose {what}, tell {gain} what you offer them in its place.
- I back the {bill} because {gain} asked for it. Who asked you to block it?
- Opposing the {bill} is easy. Facing {gain} afterward is not.
- Say no if you must. Then tell {gain} why.
- {Gain} need this. What do you offer them?
- Who speaks for {gain} if you block this?
- I will not let {gain} be an afterthought.

**Earnest · attack · Against**

- I cannot support {what} while {hurt} are left to pay the price.
- Before you pass this, look {hurt} in the eye and explain it.
- You owe {hurt} an honest answer before you ask for their trust.

**Earnest · gain · Neutral**

- I will judge the {bill} on what it does for {local}, nothing else.
- Let us hear from the people who live with {local} first.
- My vote goes to whoever answers the hard questions on {what}.
- I came here to listen on the {bill}, and so should we all.

**Earnest · gain · For**

- I stand with {gain}, and I stand with the {bill}.
- This is simple: the {bill} helps {gain}, and I will say so anywhere.
- I have met {gain}. The {bill} is what they asked for.

**Earnest · gain · Against**

- I stand with {hurt}. The {bill} asks too much of them.
- Ask {hurt} how they feel about {what}. I already have.
- I will speak for {hurt}, because the {bill} forgets them.

**Earnest · block · Neutral**

- That is not an answer about {local}. Try again.
- Fine words. Now show me how it touches {local}.
- I will not be rushed on {what}.
- That does not settle the {bill} for me. Not yet.

**Earnest · block · For**

- Delay does not protect anyone from {risk}. It only fails {gain}.
- {Gain} cannot live on objections. They need {what}.
- Your worries are noted. {Gain} still need the {bill}.
- That objection leaves {gain} with nothing at all.

**Earnest · block · Against**

- Promises will not shield {hurt} from {risk}.
- That reassurance means little to {hurt}.

**Emotional · attack · Neutral**

- Look at me and tell me what the {bill} would mean for real families!
- People who care about {local} are watching you right now!
- How can you speak about the {bill} without a word for anyone it touches?
- I am tired of speeches! What happens to {local}?
- Do you even feel the weight of this vote?
- Answer me! Who will you face at home after the {bill}?
- My heart sinks when I hear the {bill} treated like a slogan!
- Stop hiding behind procedure! People care about {local}!

**Emotional · attack · For**

- How can you turn your back on {gain}? They need this!
- I have seen what waiting does to {gain}. Do not make them wait!
- Every delay on {what} breaks another promise to {gain}!
- You would send {gain} home empty-handed? How could you?
- Do not abandon {gain}! Not now!

**Emotional · attack · Against**

- My heart breaks for {hurt}. Do you even think of them?
- You would trade away {hurt} for {what}? Shame!
- I have met {hurt}. They are frightened, and you are not listening!
- Who will comfort {hurt} when the {bill} lands on them?

**Emotional · gain · Neutral**

- Let us remember the people behind the {bill}, not the headlines!
- This room should feel what {local} means to people!
- Whatever we decide, decide it with a heart!
- I feel this vote in my bones, and so should you!
- Let this room hear real voices, not just ours!

**Emotional · gain · For**

- Think of {gain} tonight, finally hopeful! That is the {bill}!
- I want {gain} to hear that someone here fought for them!

**Emotional · gain · Against**

- Think of {hurt} tonight, worried sick! That is the {bill}!
- I want {hurt} to hear that someone here fought for them!

**Emotional · block · Neutral**

- Do not lecture me while people who care about {local} wait for answers!
- That answer is cold, and people deserve warmth!
- No! You do not get to brush this aside!
- I will not let you make the {bill} sound simple!
- Do not wave this away! People are hurting!
- That is no answer! People deserve better!

**Emotional · block · For**

- Say no to the {bill} and you say no to {gain}!
- Spare me the doubts! {Gain} need help now!
- Your fears will not feed {gain}!

**Appeal · attack · Neutral**

- Friends, the {bill} deserves a real debate, not slogans.
- Friends, let us talk about {local}, which matters to us all.

**Appeal · attack · For**

- Friends, {gain} are our neighbors. Why stand in their way?
- Surely we can all agree that {gain} deserve a fair hearing on the {bill}.
- Friends, opposing the {bill} leaves {gain} out in the cold.
- Friends, the {bill} is a fair offer. Why refuse it?

**Appeal · attack · Against**

- Friends, {hurt} are our neighbors too. Why leave them behind?
- Friends, a fair bill would not ask so much of {hurt}.

**Appeal · gain · Neutral**

- Let us find the version of the {bill} this whole room can live with.
- We all want {local} to thrive. Start there, friends.
- Friends, whatever we decide on the {bill}, let us decide it together.

**Appeal · gain · For**

- A fair country stands by {gain}. The {bill} does exactly that.
- Friends, {gain} have been patient. The {bill} is our answer to them.

**Appeal · block · Neutral**

- Friends, let us not split hairs while people wait.
- We can disagree on the {bill} and still respect each other.
- That is unfair to everyone who cares about {local}.
- Friends, cooler heads, please. The {bill} deserves that.

**Appeal · block · For**

- Friends, {gain} should not lose their chance over fear of {risk}.
- We can guard against {risk} and still pass the {bill}.
- Friends, {gain} have been patient. Let us be fair to them.
- That objection is not fair to {gain}, friends.

**Data Driven · attack · Neutral**

- Show me the figures for {local}. Not estimates, figures.
- What is the cost estimate for {what}? I have not seen one.
- Where is your evidence on {risk}?
- Which study supports your view of the {bill}?
- Give me one number about {local} that backs your case.
- How many people would the {bill} reach? Give me a count.

**Data Driven · attack · For**

- The data on {gain} is clear. Where is your counter-evidence?
- Name one figure showing {what} would fail. I will wait.
- Your objection has no numbers. The case for {gain} does.
- Your doubts about {what} have no figures behind them.

**Data Driven · attack · Against**

- No one has priced {risk}. That alone should stop the {bill}.
- The figures for {hurt} do not add up under the {bill}.
- Show me the impact study on {hurt}. There is none.

**Data Driven · gain · Neutral**

- Let us settle the {bill} with evidence, not volume.
- The record on {local} should guide this vote.
- I will follow the evidence on {what}, wherever it goes.

**Data Driven · gain · Against**

- The numbers say {hurt} lose out. I go with the numbers.
- On the evidence, {hurt} pay more than the {bill} admits.

**Data Driven · block · Neutral**

- Anecdotes are not data. Bring figures on {local}.
- That claim about the {bill} is unsourced.
- One example is not a trend. Try again.

**Data Driven · block · For**

- Your worry about {risk} is speculation. The gains for {gain} are measured.
- That projection ignores how similar plans have worked elsewhere.
- Speculation is not evidence. The case for {gain} is.

**Divisive · attack · Neutral**

- Pick a side on the {bill}. This room is watching.
- Which camp are you in on the {bill}? Say it.

**Divisive · attack · For**

- The ones blocking the {bill} have never cared about {gain}.
- Their side always finds a reason to fail {gain}.

**Divisive · attack · Against**

- Your camp pushes {what} and leaves {hurt} to pay.
- Their side never asks {hurt} what they think.

**Divisive · block · Neutral**

- Their side always says that. It means nothing about {local}.
- That is a talking point from the other camp.

**Duplicitous · attack · Neutral**

- I have no view on the {bill}, of course. But you seem unsure.
- I only ask questions. Do you really know what the {bill} involves?
- Interesting position. I wonder how long you will hold it.
- People are saying things about {local}. I could not possibly repeat them.
- Who drafted your answer on the {bill}? It sounds borrowed.
- I am sure you have thought hard about {risk}. Haven't you?
- Nobody doubts you on the {bill}. Well, nobody I would name.

**Duplicitous · attack · For**

- I am sure you have reasons to oppose {what}. Let us hear them, slowly.
- Odd that anyone would stand against {gain}. Unless they owe someone.
- Of course you may oppose the {bill}. {Gain} will remember it.
- Opposing the {bill} is your right. Explaining it to {gain} is your problem.
- Oppose it, by all means. {Gain} are taking notes.

**Duplicitous · attack · Against**

- Of course we all love {gain}. But who answers to {hurt}?
- A lovely bill. Pity about {hurt}, but who counts them?

## Bill part frames (drafted and sponsored bills)

Slot: {phrase}, the part's own wording ("raise the minimum wage").

**Appeal · attack · For**

- Friends, to {phrase} is a fair step. Why stand against it?
- Surely we can all agree it is time to {phrase}.

**Divisive · attack · For**

- Only the other camp would refuse to {phrase}.
- Their side will never {phrase}. Ours will.

**Emotional · attack · For**

- People have begged us to {phrase}! How can you say no?
- Do not tell me we cannot {phrase}! Families are waiting!
- It breaks my heart that anyone would refuse to {phrase}!

## Shared Ally lines

No bill named, so each fits any bill and either side.

**Earnest · attack**

- We are on the same side, so I will be blunt: that case was weak.
- I agree with where you stand. I do not agree with how you argue it.
- If you are with us, make the case properly. People are listening.
- Allies tell each other the truth: you are losing this room.
- Standing with us means doing the work. Where is it?
- I share your view, and I expect better from you.

**Earnest · gain**

- Our side wins this on the merits. Let me show you how.
- I will make the case plainly, since someone has to.
- Watch closely. This is how our side should sound.
- We agree on the goal. Let me carry this part.
- I will speak for our side, and I will keep it honest.
- Let our side earn this, one honest point at a time.

**Earnest · block**

- I am with you, but I will not defend that last answer.
- Agreeing with you does not mean I take every claim on trust.
- Not so fast. Our side needs a better answer than that.
- I will stand beside you, not behind a weak argument.
- Same side or not, that answer does not hold.
- We agree. That still does not make your point stronger.

**Emotional · attack**

- We want the same thing! So why are you making it so hard?
- You are on our side, and that answer breaks my heart!
- Fight for this like you mean it!
- I believed you would carry us! Do not let us down now!
- Where is your fire? Our side deserves passion!
- We stand together, so stand up straight!
- People trusted us both! Show them why!

**Emotional · gain**

- Let me say what our side feels, since you will not!
- This matters to me, and I will make the room feel it!
- Our side has heart! Let me show it!
- Listen, all of you! This is why we stand where we stand!

**Emotional · block**

- Do not drag our side into that! It hurts us!
- I cannot cheer for that answer, friend or not!
- Stop! You are giving our opponents easy ammunition!
- I love this cause too much to accept that!
- Not like that! Our people deserve better!

**Appeal · attack**

- Friend, we agree. Now bring the rest of the room with us.
- We share a view. Please argue it in a way others can share.
- Friends do not let friends make a weak case.
- You are on the right side. Be fair to the other one too.
- Win them over, friend. Do not just win the point.

**Appeal · gain**

- We can bring more people to our side than this. Let me try.
- There is room on our side for everyone here. Come and see.
- Let me put our case in a way the whole room can accept.
- Friends, our view is fair, and fairness persuades.
- Join us. Our case is better than that last answer made it sound.

**Appeal · block**

- Friend, that answer pushes people away from our side.
- Let us keep our case fair. That claim was not.
- We agree, but that remark was unkind to the other side.
- Easy now. Our side should be the reasonable one.
- Friend, that will not win anyone over.

**Data Driven · attack**

- We agree on the conclusion. Your numbers do not support it.
- Our side has the evidence. Why are you not using it?
- Cite a source, please. Our side cannot afford sloppy claims.
- I share your position. I do not share your arithmetic.
- That figure is wrong, and it weakens our case.
- Same side, different standard: I check my figures.
- If our case is right, the data will show it. Show it.
- You are arguing from feeling. Our side has numbers.

**Data Driven · gain**

- Let me give our side the figures it needs.
- Here is the evidence for our position, properly sourced.
- The record supports us. I will read it into the debate.

**Data Driven · block**

- I agree with you, but that statistic is misleading.
- Our side does not need inflated numbers. Withdraw that one.
- A correction, from a friend: that is not what the data says.
- That estimate will not survive scrutiny. Drop it.

**Divisive · attack**

- You are supposed to be one of us. Act like it.
- Our side does not go soft. Why are you?
- If you are with us, stop apologizing to them.

**Divisive · gain**

- Our side holds the line. Theirs never has.
- We are right, and they know it. Say so!

**Divisive · block**

- Do not hand the other camp that line. They will use it.
- One of us does not concede that point.
- Careful. You sound like them.

**Duplicitous · attack**

- We agree, naturally. Though I wonder how long you will.
- On our side, are you? How reassuring.
- I support you completely. In public, at least.
- A fine position. Shame about the delivery.
- We are allies, of course. Allies keep notes.
- I would never question your loyalty. Others might.
- Same side, yes. Different reasons, I suspect.
- Of course I back you. For now.

**Duplicitous · gain**

- Let me help our side. I am always happy to help.
- I will speak for us both. You may thank me later.

**Duplicitous · block**

- Let us not say that out loud, friend. Not yet.
- I agree, in principle. In practice, not that answer.
