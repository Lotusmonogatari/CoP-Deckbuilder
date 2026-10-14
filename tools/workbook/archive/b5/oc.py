import json,sys,re
# role -> {verb: [lines]}  (<=9 words each, no time words)
def B(a,g,b): return {'attack':a,'gain':g,'block':b}
D={
'Committee on Government Administration':B(
 ["Your plan adds paperwork, not service.","Which office will run this? Name it.","Efficiency is the test. You fail it.","Show me the staffing plan first."],
 ["Clear rules help everyone here.","Good. Orderly offices serve the public.","That is administration done properly.","Fair process earns my respect."],
 ["Procedure protects us both. Keep to it.","I will wait for the full report.","Proper channels exist for a reason.","Not without a written standard."]),
'Committee on Ethics and Prosecution':B(
 ["Who benefits? Say it plainly.","Rules apply to you as well.","That sounds like a favour, not policy.","Clean hands, or no vote from me."],
 ["Honest answers matter to this committee.","That is the standard I expect.","Integrity makes a case stronger.","Straight talk. I can work with it."],
 ["I need the record on that point.","Careful. Every word is noted.","Evidence first, opinions second.","Prove it, and I will listen."]),
'Committee on the Environment':B(
 ["The land cannot wait for your compromise.","Where is the impact study?","Nature does not negotiate. You do.","Cheap here means costly downstream."],
 ["The watershed thanks you for that.","Good. Our forests need allies.","Sound ground for a lasting policy.","That protects more than a single season."],
 ["I will not trade away clean water.","Show me the monitoring plan.","Protection comes first. Talk second.","Not at the expense of the coast."]),
'Committee on Foreign Affairs':B(
 ["Our neighbours are reading every word.","This weakens us abroad. Explain.","Diplomacy is not a slogan.","Allies expect more than speeches."],
 ["Steady words build trust abroad.","That is how partners are kept.","A calm line serves Yezo well.","Good. Our standing needs this."],
 ["I will not hand rivals an opening.","Let the envoys weigh in first.","Careful. The wrong phrase echoes abroad.","No commitments without allied consent."]),
'Committee on the National Assembly':B(
 ["The chamber deserves better than this.","That breaks with how we legislate.","Floor rules exist for a reason.","Count the seats, not the applause."],
 ["Respect for the chamber. Welcome.","That is how a bill earns votes.","Order and fairness together. Good.","Members will remember that courtesy."],
 ["The floor schedule will not bend.","Amend it properly and we vote.","I hold the line on procedure.","Not by a shortcut through the chamber."]),
'Committee on Agriculture':B(
 ["Farmers cannot eat your promises.","Rice prices are no joke.","Visit a farm and decide fairly.","The fields feel every cut you make."],
 ["Honest work deserves honest support.","The countryside hears that and nods.","Good. Our growers need it.","That helps the next harvest."],
 ["Not while the co-ops are left out.","Show the numbers to the farmers.","I have watched this plan fail elsewhere.","The land will not forgive carelessness."]),
'Committee on Finance':B(
 ["The ledger does not add up.","Who pays? Give me a number.","Spending without sources is fantasy.","Your cost estimate is a guess."],
 ["Sound figures. That I respect.","The books agree with you there.","A balanced case. Well done.","That is fiscal sense."],
 ["Hold the spending; cost it properly.","I want the audit first.","Show me the revenue line.","No blank cheques from this seat."]),
'Committee on War':B(
 ["Readiness is not a talking point.","Our defences are not a debate prize.","Strategy needs more than slogans.","Name the threat you are answering."],
 ["Steady resolve. That reassures me.","Duty well stated. Noted.","That serves those in uniform.","A firm line, fairly drawn."],
 ["I will not weaken the guard.","Hold position and finish the briefing.","No cuts to readiness. None.","Security is not up for trade."]),
'Committee on Construction and Development':B(
 ["Roads do not build themselves.","Where is the budget for the work?","Delays cost towns their future.","Your plan has no foundation."],
 ["Good. Projects that last.","That builds something real.","Towns will see the difference.","Solid planning. I approve."],
 ["Not without a complete survey.","I need the contractor figures.","Safety codes are not optional.","Show me the schedule first."]),
'Journalist':B(
 ["That answer dodges the question.","Our readers expect a straight reply.","Care to explain that to the public?","I will quote you on that."],
 ["That is a headline.","Clear and quotable. Thank you.","The public will like that answer.","That reads well in print."],
 ["No comment is also a comment.","I will follow up on that.","Off the record, you hedged.","We will see what the facts say."]),
'Student':B(
 ["My generation is paying for this.","Who asked us? Nobody.","Words are cheap. Tuition is not.","We will remember how you vote."],
 ["Someone who listens. Good.","That gives us something to build on.","Maybe the future has a seat after all.","I can believe in that."],
 ["Show us the plan, not a poster.","We are watching closely.","Not without student voices at the table.","I need more than promises."]),
'Constituent':B(
 ["I have heard this line.","What have you done for my street?","Speeches do not fix potholes.","Come see how we live."],
 ["That sounds like someone who listens.","My neighbours will like that.","Good. Plain talk helps.","That is useful to us."],
 ["I will wait and see.","Tell me what changes at home.","Prove it where we live.","Talk is easy. Results are not."]),
'Neighborhood Association Member':B(
 ["Our block is not your test case.","Ask the neighbours and plan together.","Local people were left out.","Meetings count. You skipped ours."],
 ["Good for the block. Good for all.","That respects how we get along.","Neighbours will thank you for that.","Community first. Well said."],
 ["Not without the association's vote.","We guard our street's character.","Bring it to our meeting.","Slow down and consult us."]),
'Family Network Member':B(
 ["Families are not a talking point.","Who looks after the children?","Our kitchen tables disagree with you.","Easy to promise. Hard to live."],
 ["That helps families breathe easier.","Yes. Households need exactly that.","A kinder answer than most.","Parents will welcome this."],
 ["I will not risk my family on that.","Show me the support for parents.","Not without childcare in the plan.","I need to hear the details."]),
'Kōenkai Member':B(
 ["We stood by you. Remember that.","Loyalty is earned, not assumed.","Supporters deserve a real reply.","Do not take our backing lightly."],
 ["That is why we back you.","The support group is pleased.","Good. We will say so.","You honour the people behind you."],
 ["Hold your ground. We are here.","Do not give in so easily.","We will not shift without cause.","Stand firm, or we reconsider."]),
'Committee of the Cabinet':B(
 ["The government will not be pressured.","Cabinet speaks with one voice here.","Mind the limits of your office.","This is above a backbencher's concern."],
 ["A responsible view. Noted.","The cabinet can work with that.","Measured and fair. Good.","Government values that approach."],
 ["That decision is not yours.","Cabinet will answer in due course.","No commitments from this room.","Bring it through the proper ministry."]),
'Chamber of Commerce Lobbyist':B(
 ["Business bears this cost, not you.","Jobs depend on getting this right.","Red tape strangles small firms.","Markets punish bad policy fast."],
 ["Commerce can plan ahead on that.","Predictable rules help every firm.","That invites investment.","Good for trade. Good for towns."],
 ["We cannot absorb another burden.","Hold the tax; consult us.","Show the impact on employers.","Not without business at the table."]),
'Labor Federation Member':B(
 ["Workers are not a line in your budget.","Fair pay is not negotiable.","Ask the shop floor, not the boardroom.","Our members carry the weight."],
 ["Workers will stand behind that.","A fair deal. We can say yes.","Good for those who do the work.","That respects the union hall."],
 ["No deal without proper wages.","We hold the line for our members.","Put safety in writing first.","Bargaining is not finished."]),
'Agricultural Cooperative Member':B(
 ["The co-op has carried this district.","Weather and prices come first.","Fields need help, not lectures.","Our harvests deserve a fair price."],
 ["Good for the co-op. Good for all.","Growers will drink to that.","A fair price makes good neighbours.","That keeps the farms going."],
 ["The co-op will not accept that.","We need a price guarantee.","Not without the growers heard.","Come walk the rows first."]),
'Fisheries Cooperative Member':B(
 ["The sea has no patience for delay.","Quotas hit our boats first.","Harbour families bear this cost.","Come out on the water and talk."],
 ["The harbour welcomes that.","Fair catch, fair price. Good.","Boats will sail easier on that.","Fishers will remember this."],
 ["Not without the catch figures.","We need honest quotas first.","Keep the harbour working.","The nets stay where they are."]),
"Mayors' Network Representative":B(
 ["Towns get the bill, not the credit.","Local budgets cannot stretch further.","Mayors were not asked.","The centre forgets the regions."],
 ["Towns need partners like this.","That helps real municipal budgets.","Good. Local leaders will cooperate.","A fair split. Welcome."],
 ["Transfer the funds with the duties.","Towns hold firm on this.","We want it in writing.","Not without a local say."]),
'Our Traditional Society Member':B(
 ["Customs are not obstacles.","Our ways stand beyond this debate.","Respect what the community keeps.","Change for its own sake helps no one."],
 ["Tradition honoured. Well done.","That respects the old ways.","Good. Heritage deserves care.","The society will approve."],
 ["We keep our customs. Full stop.","Not at the cost of heritage.","Elders must be consulted first.","Tradition is not up for trade."]),
}
# party flavour closers for attack lines (rotation)
def make(opp):
    r=opp['role']; bank=D.get(r)
    if not bank: bank=D['Constituent']
    return bank
