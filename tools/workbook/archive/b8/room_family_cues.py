"""Content 10 (2026-10-18): style cues for the room families that had none of their
own (Floor Debate, Press Conference, Steering Committee, Media Ambush, Lobbyist
Meeting, Policy Study). One row per style and verb, five lines each, shared
with each room's bill-specific and topic copies. Run from the repo root."""
import sys, json
sys.path.insert(0, "tools/workbook")
from wbx import WB
VERBS = ['attack', 'gain', 'block']
F = {
"ST02": {  # Floor Debate: the chamber, colleagues, seats, the vote
 'Earnest': [
  ["Colleagues, the record is not on your side.", "I ask this chamber for an honest vote.", "Say plainly why you oppose this.", "The floor deserves a straight answer.", "I will not dress this up for you."],
  ["I say it plainly: this deserves your vote.", "Members, I ask you to judge it fairly.", "My word on this chamber floor is good.", "Read the bill and you will agree.", "I speak for those who sent me."],
  ["I hold my seat and my position.", "I will not give ground on the floor.", "My vote answers to my conscience.", "I stand where I said I would.", "That is not a reason to change my mind."]],
 'Emotional': [
  ["Look at the public gallery and say that!", "Members, think of who you are failing!", "This chamber should be ashamed!", "Real people sit behind this vote!", "How can any member look away?"],
  ["Hear the voices behind this bill!", "Members, feel what this means to them!", "My heart is in this chamber!", "This is for every family waiting!", "Vote with your conscience, not your party!"],
  ["I cannot let this pass in silence!", "I will not be shouted down on this floor!", "My heart will not allow it!", "I stand between them and this vote!", "Not while families are listening!"]],
 'Appeal': [
  ["Colleagues, we can do better than this.", "Members of every bench want a fairer way.", "We share this chamber. Let us act like it.", "A good turn deserves a good vote.", "Surely we can find common ground."],
  ["Together, this chamber can get it done.", "Members from every bench can agree here.", "Let us pass this one together.", "We are stronger when we cross the aisle.", "A shared vote is a shared win."],
  ["We keep faith with those who elected us.", "Let us not close this door on each other.", "Colleagues, hear our concern as friends.", "We hold together on this one.", "A fair amendment keeps us all at the table."]],
 'Data Driven': [
  ["The tally does not support that claim.", "Members, check the committee figures.", "Yes or no: does the bill pay for itself?", "The cost estimate is off by a wide margin.", "Cite the clause. I will check it."],
  ["The evidence on the floor favors this bill.", "Count the seats. The numbers hold.", "The committee report supports this.", "Three studies agree. I accept that.", "The result is within the budget."],
  ["No. The figures do not justify a yes.", "I need the audited numbers first.", "The clause fails its own test.", "The sample behind that claim is too small.", "Insufficient evidence. My vote stands."]],
 'Divisive': [
  ["Members, pick a side on this floor.", "Those benches voted against the people.", "You are with us or against us.", "Name the members who block this bill.", "Spare the chamber your neutral act."],
  ["Our side of the floor carries this bill.", "Join the members who stand for the people.", "The other benches are losing this vote.", "This chamber knows who is who.", "We are the majority that counts."],
  ["We do not give the other benches that win.", "No deal with the side that opposes us.", "Hold the line on the floor.", "Not one vote toward their bench.", "This chamber will see who blinks."]],
 'Duplicitous': [
  ["It has been suggested members were misled...", "One hears concerns about this bill, quietly...", "Perhaps the clause was misread, deliberately...", "I merely wonder who drafted this...", "Questions are being asked in the corridors..."],
  ["I could be persuaded, on the right terms...", "The bill may have friends in unexpected places...", "A way forward may be found...", "Arrangements are possible, one hears...", "We will consider it favorably, in principle..."],
  ["No decision has been made on the floor...", "The amendment is under review, of course...", "I would need to see the final text...", "It was not my understanding that...", "Matters are being clarified in committee..."]],
},
"ST04": {  # Press Conference: reporters, questions, headlines, the record
 'Earnest': [
  ["Quote the whole answer, not a fragment.", "That question deserves a straight reply. Here it is.", "I answer for my record, not the rumor.", "Print what I actually said.", "I will say it plainly for the cameras."],
  ["Here is exactly where I stand.", "Write this down: I mean every word.", "That is a fair question and an honest answer.", "I stand behind that statement.", "Let the record show I said it openly."],
  ["I decline to speculate on that.", "My answer has not changed and will not.", "I will not be baited into a headline.", "No, I do not accept that framing.", "Ask me something I can answer honestly."]],
 'Emotional': [
  ["Behind every headline there is a family!", "Reporters, ask them how it feels!", "Do not turn real lives into a story!", "How can the press look away?", "Put the people on the front page!"],
  ["I came here to speak for those who cannot!", "Please tell their story fairly!", "This is not politics. It is people!", "Say that every parent has a stake!", "I am grateful for the question!"],
  ["I will not answer a cruel question!", "That framing hurts people!", "I cannot let that go unanswered!", "Do not twist their pain into a headline!", "I will protect them from that story!"]],
 'Appeal': [
  ["Friends of the press, be fair to us all.", "Readers deserve better than that framing.", "We all want an honest story here.", "A fair question gets a fair answer.", "Let us not turn this into a show."],
  ["The public wants to know. Let us tell them.", "Together we can get the facts out.", "Readers will thank us for a clear answer.", "Here is the answer, for everyone watching.", "We want the same thing: the truth."],
  ["Let us stay on what matters to readers.", "Friends, that is not a fair question.", "We will not be pulled off topic.", "Readers deserve the full story, not a clip.", "Let us keep this civil and clear."]],
 'Data Driven': [
  ["What is your source for that figure?", "That statistic is out of context.", "Yes or no: can you verify that number?", "The data say otherwise, reporters.", "Print the percentage, not the adjective."],
  ["The numbers support my answer.", "Here is the figure, with its source.", "Check the report. It confirms this.", "Two independent studies agree.", "The data are public. Read them."],
  ["That number is selectively quoted.", "The headline overstates the finding.", "No. The data do not say that.", "I need the full table, not a snippet.", "Correct the figure if you print it."]],
 'Divisive': [
  ["Whose side is your paper on?", "Reporters, you picked a narrative.", "Some outlets would like this to fail.", "Print who benefits. You know the answer.", "The other camp paid for that question."],
  ["Our side has the facts. Print them.", "The public is with us, reporters.", "Let the other camp explain themselves.", "This is a story of two sides. Ours wins.", "Write that the opposition has no answer."],
  ["I will not play into their story.", "That is the other camp's question.", "Not that frame. Not their frame.", "I do not take orders from your editors.", "Ask the other side that question."]],
 'Duplicitous': [
  ["One might wonder why that question was chosen...", "It has been suggested your sources are thin...", "Perhaps the editor knows more than you do...", "Is that what is being said, quietly?", "I merely ask who gave you that question..."],
  ["I may have something for the right outlet...", "The story could be a good one, for friends...", "Let us say the answer is encouraging...", "Details to follow, perhaps...", "I am happy to be quoted, on background..."],
  ["I could not possibly comment...", "No decision has been announced, of course...", "That is a matter for others, I believe...", "I will take that away, naturally...", "One would need to see the paperwork..."]],
},
"ST08": {  # Party Steering Committee: platform, discipline, candidates, party leaders
 'Earnest': [
  ["Committee, the party platform says otherwise.", "I ask you to be honest about the trade-offs.", "Say what you want from me, plainly.", "I owe this party a straight word.", "The rank and file expect better."],
  ["I serve this party and I mean it.", "My record in the party speaks plainly.", "I will keep faith with our platform.", "I am here to help, not to posture.", "Let me earn the committee's trust."],
  ["I will not sign what I cannot support.", "Party loyalty is not blind obedience.", "I hold to the platform as written.", "My conscience stays my own.", "I respect the committee, and I disagree."]],
 'Emotional': [
  ["Think of the members who built this party!", "Our volunteers deserve more than this!", "The committee is breaking hearts!", "Do you not feel what this does to us?", "Our people are watching this decision!"],
  ["I love this party and everyone in it!", "My heart is with the members!", "I came up from the bottom, and I remember!", "This party is my family!", "Let us do right by our people!"],
  ["I cannot betray those who trust me!", "Please do not make me choose against them!", "My heart will not let me sign!", "I stand with the members, whatever it costs!", "I cannot abandon our base!"]],
 'Appeal': [
  ["Friends of the party, let us be fair.", "We built this party together, committee.", "Surely we can find a way for all.", "A good turn deserves another, committee.", "We are all on the same side here."],
  ["Together we can strengthen this party.", "The committee and I want the same thing.", "Let us shake hands on a plan.", "We are stronger when the party speaks as one.", "I am glad to work with all of you."],
  ["Let us not break the party over this.", "We hold together, committee.", "Give us a fair compromise, friends.", "The party is bigger than one decision.", "We can find a middle way, together."]],
 'Data Driven': [
  ["The poll numbers do not support this.", "Show the committee's own turnout figures.", "Yes or no: does this win seats?", "The cost to the party is not accounted for.", "What is the evidence for that strategy?"],
  ["The district numbers back my plan.", "Turnout figures support this approach.", "The data show a path to a majority.", "Two surveys agree with me.", "The party's own research supports this."],
  ["No. The numbers do not justify the change.", "I need the district breakdown first.", "The projection fails on its own assumptions.", "Insufficient evidence. I decline.", "The sample behind that poll is small."]],
 'Divisive': [
  ["Committee, whose side are you really on?", "The party has factions, and you chose one.", "Name who benefits from this decision.", "Some in this room work against the party.", "Choose: the members or the machine."],
  ["The members are with us. The machine is not.", "Our faction carries the party forward.", "Stand with the base or stand aside.", "We know where the loyalty lies.", "The party is ours to lead."],
  ["I will not hand the other faction a win.", "No deal with those who undermine us.", "Hold the line, committee.", "Not one concession to the other camp.", "The party will see who stands firm."]],
 'Duplicitous': [
  ["One hears the committee has decided...", "It has been suggested someone is being favored...", "Perhaps the minutes tell a different story...", "I merely ask who benefits from this...", "Things are said in the corridors, committee..."],
  ["I may be of use to the committee, quietly...", "Arrangements are possible, one hears...", "Let us say I am open to guidance...", "The committee can count on discretion...", "I could be persuaded, on the right terms..."],
  ["No decision has been made, of course...", "I would need to see the minutes first...", "It was not my understanding that...", "I cannot possibly commit at this stage...", "Matters are under review, I believe..."]],
},
"ST19": {  # Media Ambush: cameras, microphones, hallway
 'Earnest': [
  ["You ambush me, but I will answer plainly.", "Ask your question properly, then.", "Cameras do not change my answer.", "I will tell you the truth in the hallway.", "Put the microphone down and listen."],
  ["Here is the truth, on camera.", "I have nothing to hide. Ask away.", "I will answer every question you have.", "A straight answer, as promised.", "I stand by it in front of any lens."],
  ["I decline to answer in a hallway.", "Not this question, not this way.", "I will answer when the questions are fair.", "I do not answer to a shouted question.", "No. I have said what I will say."]],
 'Emotional': [
  ["Is this how you treat people, with cameras?", "You corner me, but think of the families!", "Do you feel nothing behind those lenses?", "Put the cameras down and see them!", "Real people are hurt by this ambush!"],
  ["Let the cameras see how much I care!", "I will speak from the heart, right here!", "This matters to families watching at home!", "I am not afraid of the lens!", "Let everyone hear it from me!"],
  ["I cannot answer that in front of children!", "Please, step back from the people!", "That question hurts, and I will not answer!", "I will not be a headline at their expense!", "Leave them out of this!"]],
 'Appeal': [
  ["Friends, an ambush helps nobody.", "Reporters, we can do better than this.", "A fair question beats a loud one.", "Readers want facts, not a scrum.", "Let us be civil about this."],
  ["Together we can get the story right.", "I will give you a real answer, friends.", "Let me tell it for everyone watching.", "We want the same thing: the truth.", "Ask, and I will answer for all."],
  ["Let us step aside and talk properly.", "Friends, this is not the place.", "We will take questions in order.", "Please, take the questions in order.", "I will give a statement later, for everyone."]],
 'Data Driven': [
  ["What is your source for that claim?", "That figure is out of context.", "Yes or no: can you verify it?", "The data contradict your question.", "Cite the number, then ask."],
  ["The numbers are public. Check them.", "Here is the figure and its source.", "The report confirms it.", "Two studies agree with me.", "Read the data, then print."],
  ["That statistic is misleading.", "The headline overstates the finding.", "No. The data do not say that.", "I need the full table, not a clip.", "Correct the number if you print."]],
 'Divisive': [
  ["Whose side is your network on?", "You were sent here by the other camp.", "Some outlets want a story, not the truth.", "Say who paid for this ambush.", "Print who benefits from this stunt."],
  ["The public is with us. The cameras will see.", "Our side has the facts.", "Let the other camp explain themselves.", "This is a story of two sides.", "Write that the opposition has nothing."],
  ["I will not play into their trap.", "That is the other camp's question.", "Not that frame. Not their frame.", "I do not answer for your editor.", "Ask the other side."]],
 'Duplicitous': [
  ["How interesting that you happened to be here...", "One wonders who tipped you off...", "Perhaps the cameras were told in advance...", "I merely ask who arranged this...", "Quite a coincidence, reporters..."],
  ["I may have something for the right camera...", "Let us say the answer is encouraging...", "Details to follow, for friends...", "I could offer an exclusive, perhaps...", "I am happy to speak, off the record..."],
  ["I could not possibly comment in a hallway...", "No statement has been prepared...", "That is a matter for others, I believe...", "I will take that away, naturally...", "One would need to see the paperwork..."]],
},
"ST20": {  # Lobbyist Meeting: access, interests, donors
 'Earnest': [
  ["Say plainly what you want from me.", "I do not trade favors for access.", "Whose interest are you really here for?", "State your case. I will weigh it fairly.", "I answer to voters, not to lobbyists."],
  ["I listen to every group in good faith.", "Tell me what your members need.", "I will be honest about what I can do.", "My door is open to everyone.", "Here is where I stand, plainly."],
  ["I do not make promises I cannot keep.", "My vote is not for sale.", "I hold my position, whoever asks.", "No. I will not commit to that.", "Access does not buy my answer."]],
 'Emotional': [
  ["Think of the families who have no lobbyist!", "Do you feel nothing for those you shut out?", "Money talks, but people suffer!", "Who speaks for the ones without a voice?", "How can you ask this of me?"],
  ["I hear your members, and I care about them!", "Let me tell you who else is affected!", "Everyone deserves a fair hearing!", "I want to help, from the heart!", "Your story moves me!"],
  ["I cannot do that to people who trust me!", "Please do not ask me to betray them!", "My heart says no!", "I will not trade their futures!", "Not at the cost of families!"]],
 'Appeal': [
  ["Friends, interests are not the public interest.", "We all want a fair process, lobbyist.", "A good turn should not cost the many.", "Let us find a way that works for all.", "Surely your members want fairness too."],
  ["Together we can find common ground.", "Your members and mine want the same thing.", "Let us work out a plan for all sides.", "A shared solution is the best one.", "I am glad to meet you halfway."],
  ["Let us keep this fair for everyone.", "Friends, I cannot favor one group.", "We can find a middle way.", "I owe everyone a fair hearing.", "Give me something that works for all."]],
 'Data Driven': [
  ["What does the evidence say about your claim?", "Show me the cost-benefit figures.", "Yes or no: who pays for this?", "Your members' numbers do not add up.", "Cite the study behind that request."],
  ["The data support part of your case.", "Here are the figures that matter.", "The report backs a limited version.", "Two analyses agree on one point.", "I can accept what the numbers show."],
  ["No. The evidence does not support that.", "I need the full cost first.", "The request fails its own test.", "Insufficient evidence for a commitment.", "The sample behind that claim is small."]],
 'Divisive': [
  ["Whose side are you on, lobbyist?", "Some interests take from the public.", "Name who profits from this request.", "You are with us or against the people.", "Spare me the neutral pitch."],
  ["My side is the public. Join us.", "Stand with the people, not the privileged.", "The other interests are losing this.", "We know who stands where.", "I will not shy from taking a side."],
  ["I will not hand your side that win.", "No deal with interests that harm the public.", "Hold the line against special pleading.", "Not one concession to the privileged.", "Everyone will see who I stand with."]],
 'Duplicitous': [
  ["How very generous of your members...", "One hears there may be conditions attached...", "Perhaps there is more to this offer...", "I merely wonder who else was approached...", "Quite a coincidence, the timing..."],
  ["I could be persuaded, on the right terms...", "Arrangements are possible, one hears...", "Let us say I am open to guidance...", "Discretion is of course assured...", "We may find a mutually useful path..."],
  ["No commitment has been made, of course...", "I would need to consult others first...", "It was not my understanding that...", "Matters are under review, I believe...", "I could not possibly say at this stage..."]],
},
"ST21": {  # Policy Study Session: experts, evidence, report
 'Earnest': [
  ["The study does not say what you claim.", "Experts, tell me what the evidence shows.", "I ask for honest findings, not comfort.", "State the limits of your study plainly.", "Show me the data behind that conclusion."],
  ["The evidence supports this, plainly.", "I read the report and I agree.", "This is what the findings actually say.", "I trust the work of these experts.", "Here is the honest summary."],
  ["I will not accept a conclusion unsupported.", "The report does not justify that.", "My position follows the evidence.", "I cannot endorse what I have not read.", "Show me more if you want a yes."]],
 'Emotional': [
  ["Behind every table in this study is a person!", "Do the experts feel what the numbers hide?", "People live with these findings!", "Studies must not forget the human cost!", "I cannot look past the people in this report!"],
  ["This study gives hope to so many!", "I am moved by what the researchers found!", "Their work could change lives!", "Let us honor the families this helps!", "I am grateful to these experts!"],
  ["I cannot accept a report that ignores them!", "Please do not reduce them to a footnote!", "My heart says the study falls short!", "I stand with those left out of the sample!", "Not without their voices included!"]],
 'Appeal': [
  ["Friends, let us read this study together.", "Experts, help the public understand it.", "We all deserve to see the full findings.", "Surely the report can be made fair to all.", "A study should serve everyone."],
  ["Together we can build on this finding.", "The study belongs to all of us.", "Let us share these results widely.", "We are stronger when we use the evidence together.", "Friends, this is common ground."],
  ["Let us not rush to conclusions, friends.", "We can wait for the full report together.", "A fair study is worth a fair hearing.", "Please, let us hear all the experts.", "We hold together while the evidence is weighed."]],
 'Data Driven': [
  ["What is the sample size behind that finding?", "The confidence interval is too wide.", "Yes or no: is the effect statistically significant?", "Show the methodology, expert.", "The correlation does not prove the cause."],
  ["The data support this at the stated level.", "The method is sound and the result holds.", "Two independent studies agree.", "The effect size is meaningful.", "I accept the finding as presented."],
  ["No. The evidence does not support that.", "The method fails a basic check.", "I need the raw figures first.", "Insufficient data for a conclusion.", "The result does not replicate."]],
 'Divisive': [
  ["Some experts serve one side. Name them.", "Whose study is this, really?", "The other camp's research is selective.", "Pick: honest data or comfortable data.", "Experts have sides. Say whose."],
  ["The strongest evidence is on our side.", "Let the other camp rebut these findings.", "We are the ones following the data.", "The study proves who is right.", "Their experts have nothing to match this."],
  ["I will not accept their framing of the data.", "No deal on the other camp's study.", "Hold the line on the findings.", "Not one concession to selective evidence.", "The report must not favor one side."]],
 'Duplicitous': [
  ["One wonders who funded this study...", "It has been suggested the sample was chosen...", "Perhaps the conclusion came first...", "I merely ask who reviewed the findings...", "Quite a convenient result, experts..."],
  ["The findings may be encouraging...", "Let us say the study points somewhere helpful...", "I could be persuaded by the full report...", "Arrangements for follow-up are possible...", "We may find the evidence agrees..."],
  ["No conclusion has been reached, of course...", "I would need to see the full report...", "The study is under review, I believe...", "It was not my understanding that...", "I could not possibly endorse it..."]],
},
}
stages = json.load(open('data/stages.json'))
fam = {}
for s in stages:
    b = s.get('background_id') or s['stage_id']
    fam.setdefault(b, []).append(s['stage_id'])
w = WB('design/CoP_Starter_Card_Stage_Data.xlsx')
rows = w.rows('Player Cues')
nid = max(int(v['A'][2:]) for v in rows.values() if (v.get('A') or '').startswith('PL') and v['A'][2:].isdigit()) + 1
last = max(rows)
cols = {r: c for c, r in rows[1].items()}
added = 0
for base, styles in F.items():
    # only stages without a topic-specific Player Cue set of their own: all stages with this background
    ids = sorted(set([base] + fam.get(base, [])), key=lambda x: int(x[2:]))
    for suit, verbs in styles.items():
        for verb, lines in zip(VERBS, verbs):
            assert len(lines) == 5
            row = {'A': f'PL{nid}', cols.get('Suit', 'B'): suit, cols.get('Verb', 'C'): verb,
                   cols.get('Stage ID', 'D'): '; '.join(ids)}
            for i, col in enumerate('EFGHI'):
                row[col] = lines[i]
            w.append_row('Player Cues', row, style_row=last)
            nid += 1; added += 1
w.save()
print('added', added, 'cols', cols)
