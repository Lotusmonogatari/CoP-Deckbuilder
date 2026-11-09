"""Writing review group 2, item F (2026-11-09, Cameron decisions #55, #57).
The eight journalists (OP110-OP117) only attack since 2026-11-04, so their 48 gain
and block rows (240 lines) were never spoken. Each row's move becomes attack; lines
that already read as a reporter's challenge keep their words, the rest are reworded
as a challenge in the reporter's voice and the row's style. No line repeats one of
the same journalist's attack lines. Drafts for Cameron. Run from the repo root."""
import sys, json; sys.path.insert(0, "tools/workbook")
from wbx import WB

KEEP = object()
MAP = {
 # already a challenge: wording kept, move changed to attack
 "No comment is also a comment.": KEEP,
 "I will follow up on that.": KEEP,
 "Off the record, you hedged.": KEEP,
 "Save the speech for your own side.": KEEP,
 "That trick will not work on me.": KEEP,
 "We will see what the facts say.": KEEP,
 "Source, please.": KEEP,
 "Your sample is far too small.": KEEP,
 "That is not what the data shows.": KEEP,
 "Do not turn this into a numbers game.": KEEP,
 # reworded as challenges
 "That is a headline.": "That is tomorrow's headline. Happy?",
 "Clear and quotable. Thank you.": "Quotable, sure. Is it true?",
 "The public will like that answer.": "The public may like that. Can you deliver it?",
 "This is us against them.": "So it is us against them now?",
 "Some will hate this. Good.": "Half the country will hate this. Do you care?",
 "That reads well in print.": "It reads well in print. It proves nothing.",
 "The evidence is on my side.": "Our evidence says otherwise. Answer it.",
 "Here are the figures behind it.": "Here are the figures. Explain them.",
 "Everyone wins if you read it my way.": "Read it my way and nobody wins. Do you see?",
 "There is more to this than meets the eye.": "There is more to this. What are you hiding?",
 "I have no idea what you mean.": "What do you actually mean by that?",
 "That was taken out of context.": "Will you claim we took that out of context?",
 "I came here with a heavy heart.": "Families wrote to us in tears. Answer them.",
 "Listen to the room, not the rules.": "Listen to the room, not your briefing notes.",
 "I will not apologize for caring.": "Do you even care how this lands at home?",
 "Let us call it a misunderstanding.": "Shall we call it a misunderstanding? I won't.",
 "You must be mistaken.": "Are you sure you are not mistaken?",
 "Every claim here is documented.": "Every claim we print is documented. Is yours?",
 "I could be persuaded, perhaps...": "Some say you could be persuaded, for a price...",
 "Something may be done for the public record...": "Something is missing from the public record...",
 "It has been well received, I understand...": "Well received by whom, I wonder...",
 "Arrangements for ordinary people are possible...": "Were arrangements made, away from ordinary people...?",
 "It might be arranged, quietly...": "Was something arranged, quietly...?",
 "It is being looked into, I believe...": "We are looking into it, you should know...",
 "On the public record, no commitments were made...": "No commitments on the public record. And off it...?",
 "It is a complex question, you see...": "Complex, you say. Or convenient...?",
 "I cannot speak for ordinary people, you see...": "Who exactly do you speak for, then...?",
 "I will have to take that away...": "Our editors will want to take that apart...",
 "That brings hope to so many!": "So many hoped for more than that!",
 "The public record will feel the difference!": "Look at the public record and tell me you are proud!",
 "That lifts a heavy weight!": "Who lifts the weight you leave behind?",
 "That honors ordinary people!": "Is that how you honor ordinary people?",
 "That is human, and I thank you!": "Where is the human being behind that answer?",
 "I cannot look them in the eye!": "Could you look them in the eye and say that?",
 "I cannot abandon the public record!": "Why abandon the public record now?",
 "I will stand here, whatever it costs me!": "I will stand here until you answer!",
 "For ordinary people, my answer is no!": "Ordinary people deserve a real answer!",
 "My heart will not allow it!": "Does your heart allow you to say that?",
 "That proves who is right.": "Prove you are right. Our readers are waiting.",
 "The public record belongs to the public.": "The public record belongs to the public. Open it.",
 "That will make the front page.": "Do you want that on the front page?",
 "Friends of ordinary people versus the rest.": "Are you with ordinary people or the rest?",
 "That is a position readers will notice.": "Readers will notice which side you took.",
 "We do not shake that hand.": "Whose hand did you shake to get here?",
 "We do not hand the public record to them.": "Who did you hand the public record to?",
 "We do not give ground to them.": "Why give ground to them at all?",
 "Ordinary people stays with our side.": "Ordinary people are not on your side today.",
 "Whatever they offer, we say no.": "What did they offer you to say yes?",
 "It could be good for the public record, perhaps...": "Good for the public record, perhaps. Good for you...?",
 "Ordinary people could well be advanced...": "Ordinary people may be left behind, I hear...",
 "The public record is under review, I am told...": "The public record is under review, I am told. Yours...",
 "Ordinary people are a delicate matter...": "Ordinary people are a delicate subject for you, then...",
 "That is the spirit. Our readers will notice.": "Our readers will notice the spirit is missing.",
 "Friends of the public record will welcome that.": "Friends of the public record will not welcome that.",
 "A fine turn. We return the favor.": "A favor for a favor? Is that how it works?",
 "Friends of ordinary people will cheer this.": "Friends of ordinary people will not cheer this.",
 "Our readers will want to hear that.": "Our readers want to hear the rest of it.",
 "Friends do not push friends like that.": "Friends would tell you the truth. So will we.",
 "The public record stays safe with all of us.": "Is the public record safe with you?",
 "Not without everyone at the table.": "Who was left off the table this time?",
 "We keep faith with ordinary people.": "Have you kept faith with ordinary people?",
 "Do not ask us to go alone.": "You cannot do this alone. Who is with you?",
 "I feel it too. Thank you!": "Do you feel it too, or is it a script?",
 "That brings hope to the public record!": "Where is the hope in the public record?",
 "My heart is full!": "My inbox is full of angry readers!",
 "My heart is with ordinary people. Thank you!": "Is your heart really with ordinary people?",
 "Thank you! People will feel that!": "People will feel that, and not kindly!",
 "Please, understand why I refuse!": "Please, help us understand your refusal!",
 "Not with the public record on the line!": "The public record is on the line, and you joke?",
 "I cannot do it. It hurts too much!": "Can you not see how much this hurts?",
 "I stand between ordinary people and harm!": "Who stands between ordinary people and harm?",
 "I would sooner stay silent than agree!": "Why stay silent when we ask you straight?",
 "You know where the line is.": "Do you even know where the line is?",
 "The public record is ours to defend against them.": "Who defends the public record against you?",
 "Our people are growing in number.": "Your critics are growing in number.",
 "Our ordinary people win over theirs.": "Whose ordinary people win under your plan?",
 "The other camp is shrinking.": "Your own camp is shrinking. Why?",
 "I will not stand with them.": "Will you stand with them or not?",
 "Hands off the public record.": "Keep your hands off the public record.",
 "That is their idea. We refuse it.": "That is their idea. Why are you selling it?",
 "No middle ground on ordinary people.": "Is there no middle ground for ordinary people?",
 "We stay where we are, and so do they.": "You stay where you are while they suffer?",
 "We all gain when the public record gains.": "Who gains when the public record is hidden?",
 "Together, we serve ordinary people.": "Do you serve ordinary people, together or not?",
 "Not without the public record at the table.": "Where was the public record at that table?",
 "Friends of ordinary people stand firm.": "Friends of ordinary people expect you to stand firm.",
 "Yes. The numbers hold.": "Do your numbers hold? Show me.",
 "Yes: the numbers on the public record improve.": "Did the public record improve? The figures say no.",
 "The result is within range. Good.": "Your result is out of range. Explain.",
 "The evidence for ordinary people is solid.": "Where is the evidence for ordinary people?",
 "I verified it. It stands.": "We verified it. Your claim does not stand.",
 "Insufficient evidence. My answer is no.": "Insufficient evidence. Why should anyone agree?",
 "The public record requires evidence, not hope.": "The public record needs evidence, not hope.",
 "That falls short of what I need.": "That falls short of a real answer.",
 "No cost estimate for ordinary people. No deal.": "No cost estimate for ordinary people? Why not?",
 "The data do not justify a yes.": "Do the data justify any of this?",
 "That is very much appreciated...": "Someone must have appreciated that very much...",
 "The public record may benefit, one hopes...": "One hopes the public record benefits, not you...",
 "It would be welcomed, I think...": "Welcomed by your donors, I think...",
 "Perhaps we can work something out...": "Did you work something out, in private...?",
 "Nothing has been agreed...": "Nothing agreed, you say. Then why the dinner...?",
 "Nothing is decided on the public record, naturally...": "Nothing decided on the record, naturally. Off it...?",
 "That was not what was intended...": "Was that really what you intended...?",
 "The details are being clarified...": "The details keep changing, I notice...",
 "Another one comes over to us.": "Another one of yours crossed over. Why?",
 "Friends of the public record versus the rest.": "Friends of the public record want answers from you.",
 "We are the majority that counts.": "Do you think you are the majority that counts?",
 "Ordinary people are on our side.": "Ordinary people are not buying this.",
 "They lose. We gain.": "Who loses so you can gain?",
 "Not one step toward their side.": "Not one step toward the voters. Why?",
 "Their terms are not our terms.": "Whose terms are you working on?",
 "We guard ordinary people from them.": "Who guards ordinary people from you?",
 "No deal with the other camp.": "Did you cut a deal with the other camp?",
 "The public record will be considered favorably...": "The public record says otherwise, I hear...",
 "I could not comment on the public record...": "You will not comment on the public record...?",
 "Ordinary people grow when we pull together.": "Ordinary people pulled together. Where were you?",
 "Ordinary people are ours to guard together.": "Who guards ordinary people when you will not?",
}

def main():
    w = WB("design/Game_Workbook.xlsx")
    T = "Opponent Cues"
    head = w.rows(T)[1]
    col = {v: k for k, v in head.items()}
    verb_col = col["Verb"]
    cue_cols = [col[f"Cue {i}"] for i in range(1, 6)]
    J = {f"OP{n}" for n in range(110, 118)}
    rows = w.rows(T)
    opp_col = col["Opponent IDs"] if "Opponent IDs" in col else col["Opponent ID"]
    attack = {}
    for r, v in rows.items():
        o = v.get(opp_col, "")
        if o in J and v.get(verb_col) == "attack":
            attack.setdefault(o, set()).update(v.get(c) for c in cue_cols)
    outs = [m for m in MAP.values() if m is not KEEP]
    assert len(outs) == len(set(outs)), "two new lines are the same"
    changed = kept = 0
    for r, v in rows.items():
        o = v.get(opp_col, "")
        if o not in J or v.get(verb_col) not in ("gain", "block"):
            continue
        w.set_cell(T, r, verb_col, "attack")
        for c in cue_cols:
            new = MAP[v[c]]
            if new is KEEP:
                kept += 1
                assert v[c] not in attack[o], (o, v[c])
                continue
            assert new not in attack[o], (o, new)
            w.set_cell(T, r, c, new)
            changed += 1
    w.save()
    print("reworded", changed, "kept", kept)

if __name__ == "__main__":
    main()
