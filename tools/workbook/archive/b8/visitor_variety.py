"""Content 6 (2026-10-18): three more dilemma questions for each of VI01-VI15.
Roles: F friend-pleaser, R rival-pleaser, M middle path, X refusal.
Run from the repo root."""
import sys, json
sys.path.insert(0, "tools/workbook")
from wbx import WB
ORGS = {  # visitor: (W, F, R)
 "VI01": ("BO06", "BO03", "BO05"), "VI02": ("BO07", "BO04", "BO05"),
 "VI03": ("BO08", "BO18", "BO01"), "VI04": ("BO09", "BO12", "BO05"),
 "VI05": ("BO10", "BO04", "BO27"), "VI06": ("BO11", "BO08", "BO15"),
 "VI07": ("BO12", "BO06", "BO05"), "VI08": ("BO13", "BO15", "BO16"),
 "VI09": ("BO14", "BO05", "BO30"), "VI10": ("BO15", "BO06", "BO11"),
 "VI11": ("BO16", "BO05", "BO13"), "VI12": ("BO04", "BO10", "BO27"),
 "VI13": ("BO05", "BO06", "BO09"), "VI14": ("BO01", "BO03", "BO02"),
 "VI15": ("BO02", "BO01", "BO08"),
}
Q = {
"VI01": [
 ("The community hall roof leaks. Will you help us repair it?", [
  ("Yes. I will find a repair grant.", 'F', "The whole street will be grateful.", "Claps once."),
  ("Charge the hall's users for repairs.", 'R', "Our users are mostly pensioners.", "Frowns."),
  ("I will ask what grants exist.", 'M', "Ask soon, please. It rains.", "Nods."),
  ("Halls are not government business.", 'X', "They are the glue of the block.", "Shakes head.")]),
 ("Newcomers do not join our association. How do we reach them?", [
  ("Let me help you host a welcome evening.", 'F', "A warm welcome works wonders.", "Beams."),
  ("Newcomers should come to you.", 'R', "Some do not know where to look.", "Sighs."),
  ("I will pass out your flyer.", 'M', "A flyer is a start.", "Takes the flyer."),
  ("Nobody wants meetings.", 'X', "We do, if someone invites us.", "Looks hurt.")]),
 ("A developer wants our vacant lot. Which side are you on?", [
  ("I will make sure the neighbors are heard first.", 'F', "That is all we ask.", "Relaxes."),
  ("Development brings jobs. Let it proceed.", 'R', "Jobs, perhaps. Our lane, no.", "Folds arms."),
  ("I will ask for a public hearing.", 'M', "A hearing is fair.", "Nods."),
  ("It is private land.", 'X', "Private land, public street.", "Turns away.")]),
],
"VI02": [
 ("Seals are eating the catch. What can the fleet do?", [
  ("I will back a study and fair compensation.", 'F', "Compensation would keep boats afloat.", "Nods hard."),
  ("Let the market sort it out.", 'R', "The market is not out on the water.", "Scoffs."),
  ("I will ask the ministry for data.", 'M', "Data helps. So does money.", "Shrugs."),
  ("Seals were here first.", 'X', "So were we.", "Walks to the door.")]),
 ("The boat I work is older than I am. Can there be help for new engines?", [
  ("Yes. I will press for a vessel renewal fund.", 'F', "A fund would save many boats.", "Smiles."),
  ("Fishers should save for their own boats.", 'R', "Our margins have no room to save.", "Sighs."),
  ("I will look at loan guarantees.", 'M', "Guarantees would help.", "Nods."),
  ("Old boats are old news.", 'X', "They are our livelihood.", "Stiffens.")]),
 ("Young people do not want to go to sea. What do we do?", [
  ("I will back training and housing for new crews.", 'F', "That could bring them home.", "Grins."),
  ("Let the industry shrink.", 'R', "A harbor without boats is a ghost.", "Stares."),
  ("I will visit the fishing school.", 'M', "The students would like that.", "Nods."),
  ("The sea is a hard life.", 'X', "It is a good one, too.", "Looks away.")]),
],
"VI03": [
 ("Can I see the budget for your office?", [
  ("Yes. Everything is public.", 'F', "I will print the line items.", "Writes quickly."),
  ("It is not your business.", 'R', "Our readers say otherwise.", "Narrows eyes."),
  ("Send a written request.", 'M', "I will, and I will wait.", "Notes it down."),
  ("Ask my staff.", 'X', "I did. They sent me to you.", "Puts away the pen.")]),
 ("A rival says you flip-flop. Care to respond?", [
  ("I changed my mind when the facts changed.", 'F', "That is a quotable answer.", "Smiles."),
  ("My rival lies.", 'R', "Strong words. Do you have evidence?", "Raises an eyebrow."),
  ("I would have to see what they said.", 'M', "I will send you the clip.", "Nods."),
  ("I will not respond to gossip.", 'X', "Then I will quote the gossip.", "Shrugs.")]),
 ("Would you appear on the evening news tonight?", [
  ("Gladly. I will answer anything.", 'F', "I will hold you to that.", "Beams."),
  ("Only if I see the questions.", 'R', "That is not how interviews work.", "Sighs."),
  ("I can do five minutes.", 'M', "Five is enough.", "Nods."),
  ("I do not do television.", 'X', "Your voters do.", "Closes notebook.")]),
],
"VI04": [
 ("The factory is cutting night shifts. Will you speak up?", [
  ("Yes. Workers deserve fair notice.", 'F', "Our members will hear that.", "Straightens up."),
  ("Companies must manage costs.", 'R', "So must families.", "Frowns."),
  ("I will ask the owners to meet us.", 'M', "A meeting is something.", "Nods."),
  ("That is a private matter.", 'X', "It is hundreds of livelihoods.", "Turns away.")]),
 ("Temp workers get no benefits. Will you support reform?", [
  ("Yes. Equal work deserves equal protection.", 'F', "That is the principle we want.", "Smiles."),
  ("Temp work keeps firms flexible.", 'R', "Flexibility for them, risk for us.", "Shakes head."),
  ("I will study how other places handle it.", 'M', "Study quickly, please.", "Nods."),
  ("Temps chose temp jobs.", 'X', "Few of them chose it.", "Looks angry.")]),
 ("A safety inspector was removed from our plant. Will you ask why?", [
  ("Yes. Safety cannot be a budget line.", 'F', "Thank you. People could get hurt.", "Exhales."),
  ("Inspectors cost money.", 'R', "Accidents cost more.", "Glares."),
  ("I will write a letter to the ministry.", 'M', "A letter is a start.", "Nods."),
  ("It is the company's decision.", 'X', "The company does not carry the injured.", "Stands.")]),
],
"VI05": [
 ("The milk truck cannot reach us in winter. Can the road be cleared?", [
  ("Yes. I will push for winter road priority.", 'F', "Our milk and our kids need that road.", "Smiles."),
  ("Farmers must plan for winter.", 'R', "We do. Snow has its own plans.", "Frowns."),
  ("I will ask the prefecture.", 'M', "Ask loudly.", "Nods."),
  ("Maybe move the farm.", 'X', "To where? The cows are here.", "Looks away.")]),
 ("Feed prices doubled. Will anyone help dairy farms?", [
  ("I will fight for feed support.", 'F', "Help like that keeps barns open.", "Relaxes."),
  ("Farms must become efficient.", 'R', "We have trimmed everything.", "Folds arms."),
  ("I will bring it to the committee.", 'M', "Please do.", "Nods."),
  ("Feed is a market matter.", 'X', "So is our collapse.", "Shakes head.")]),
 ("My son wants to take over the farm. Is there help for him?", [
  ("Yes. I will back successor grants.", 'F', "He will be grateful. So will I.", "Smiles with pride."),
  ("Young farmers should find loans.", 'R', "Loans for a farm are a mountain.", "Sighs."),
  ("I will find out what programs exist.", 'M', "Good. Tell us what you learn.", "Nods."),
  ("Farming is dying anyway.", 'X', "Not if we fight for it.", "Eyes flash.")]),
],
"VI06": [
 ("Textbooks cost a fortune. Will you help?", [
  ("Yes. I will back open textbook funding.", 'F', "That would save us a lot.", "Cheers quietly."),
  ("Publishers deserve their prices.", 'R', "We deserve to afford class.", "Frowns."),
  ("I will ask the university what it can do.", 'M', "That is a start.", "Nods."),
  ("Buy used.", 'X', "We already do.", "Rolls eyes.")]),
 ("The campus library closes early. Can you push for longer hours?", [
  ("Yes. Study space matters.", 'F', "You just earned fans.", "Grins."),
  ("The budget is what it is.", 'R', "It always seems to be.", "Sighs."),
  ("I will raise it with the rector.", 'M', "Please do.", "Nods."),
  ("Study at home.", 'X', "Not everyone has a quiet home.", "Stiffens.")]),
 ("Many of us cannot afford to live near campus. What will you do?", [
  ("I will back student housing support.", 'F', "That would change lives.", "Brightens."),
  ("Commute like everyone else.", 'R', "Our commute is two hours.", "Looks tired."),
  ("I will look at what other cities do.", 'M', "Good. Bring the details.", "Nods."),
  ("Students should work more.", 'X', "We do. It is not enough.", "Turns away.")]),
],
"VI07": [
 ("The playground equipment is broken. Who fixes it?", [
  ("I will get the ward to fix it.", 'F', "Children will thank you.", "Smiles."),
  ("Parents can fundraise.", 'R', "We do. We cannot afford it all.", "Frowns."),
  ("I will report it to the city.", 'M', "Please follow up.", "Nods."),
  ("Playgrounds are not a priority.", 'X', "They are to our children.", "Looks hurt.")]),
 ("School lunch is poor quality. Will you look into it?", [
  ("Yes. I will ask for an audit.", 'F', "Children need real food.", "Beams."),
  ("Lunch is the school's matter.", 'R', "Then ask the school to listen.", "Sighs."),
  ("I will check the budget.", 'M', "Thank you.", "Nods."),
  ("Kids are picky.", 'X', "These are not picky complaints.", "Stiffens.")]),
 ("I cannot attend school meetings; I work evenings. What can be done?", [
  ("I will push for online options.", 'F', "That would let all of us join.", "Relaxes."),
  ("Parents should make time.", 'R', "Time is what we lack.", "Sighs."),
  ("I will pass it to the school board.", 'M', "Please do.", "Nods."),
  ("Meetings are not your concern.", 'X', "Our children are.", "Turns away.")]),
],
"VI08": [
 ("A tourist wanted a cheaper version of my carving. Should I give in?", [
  ("Never lower the craft. I will back a mark of quality.", 'F', "That is encouragement I needed.", "Smiles."),
  ("Customers choose price.", 'R', "Quality is the whole point.", "Frowns."),
  ("Offer a small version at a fair price.", 'M', "A small piece, perhaps.", "Nods."),
  ("Craft is a hobby.", 'X', "It is my life.", "Looks wounded.")]),
 ("The wood supply for carvers is shrinking. Can you help?", [
  ("Yes. I will ask for a managed supply.", 'F', "A supply keeps the trade alive.", "Sighs, relieved."),
  ("Buy wood from abroad.", 'R', "Our wood is the heart of it.", "Shakes head."),
  ("I will ask the forest office.", 'M', "They know the forest.", "Nods."),
  ("Trees are for timber.", 'X', "Not for craft?", "Frowns.")]),
 ("Would you visit the workshop and hear how we work?", [
  ("Gladly. Name a day.", 'F', "Bring good shoes. It is dusty.", "Chuckles."),
  ("Send a staff member.", 'R', "Staff do not vote.", "Dry smile."),
  ("I will try to make time.", 'M', "Try soon, please.", "Nods."),
  ("I have no time for hobbies.", 'X', "It is no hobby.", "Turns away.")]),
],
"VI09": [
 ("Platform doors would keep us safe. Will you press for them?", [
  ("Yes. Safety should come first.", 'F', "We would sleep easier.", "Nods."),
  ("They cost too much.", 'R', "A life costs more.", "Frowns."),
  ("I will ask the railway for a plan.", 'M', "Please do.", "Nods."),
  ("Commuters should be careful.", 'X', "We are careful. Crowds are not.", "Stiffens.")]),
 ("The ticket machines never accept my card. Can that be fixed?", [
  ("I will ask the railway to modernize them.", 'F', "A small fix that matters.", "Smiles."),
  ("Carry cash.", 'R', "In this decade?", "Sighs."),
  ("I will report it.", 'M', "Thank you.", "Nods."),
  ("Not my department.", 'X', "Whose is it?", "Shrugs.")]),
 ("Late trains cost me wages. Will you push for compensation?", [
  ("Yes. Delays should cost the railway, not you.", 'F', "That would be fair.", "Perks up."),
  ("Delays are rare.", 'R', "Not on my line.", "Frowns."),
  ("I will ask for delay figures.", 'M', "Please publish them.", "Nods."),
  ("Leave earlier.", 'X', "I leave at five.", "Sighs.")]),
],
"VI10": [
 ("The shrine roof needs repair and the donations are thin. Can you help?", [
  ("I will look for a heritage restoration grant.", 'F', "Thank you. The roof is old and dear.", "Bows."),
  ("It should rely on its own funds.", 'R', "Our funds are our community.", "Sighs."),
  ("I will ask the culture office.", 'M', "They know the grants.", "Nods."),
  ("Religion is separate from the state.", 'X', "Heritage is not only religion.", "Frowns.")]),
 ("Visitors leave litter at the shrine grounds. What can be done?", [
  ("I will help get cleanup support and signs.", 'F', "A little help goes far.", "Smiles."),
  ("Charge entry fees.", 'R', "A shrine is not a ticket booth.", "Frowns."),
  ("I will talk to the tourist board.", 'M', "Please do.", "Nods."),
  ("Visitors will be visitors.", 'X', "We still clean up after them.", "Sighs.")]),
 ("Volunteers to carry the festival shrine are growing old. Any ideas?", [
  ("Let me help recruit young volunteers.", 'F', "That could keep the festival alive.", "Brightens."),
  ("Hire a professional crew.", 'R', "Then it is not the town's festival.", "Shakes head."),
  ("I will mention it to local schools.", 'M', "A fine start.", "Nods."),
  ("Festivals fade.", 'X', "Not if we carry them.", "Looks pained.")]),
],
"VI11": [
 ("Investors ask about our tax rules. What do I tell them?", [
  ("Tell them Yezo is open for business.", 'F', "I will quote that.", "Grins."),
  ("Tell them to follow the rules.", 'R', "Rules that keep changing are hard to follow.", "Frowns."),
  ("I will ask for a clear explainer.", 'M', "An explainer would help.", "Nods."),
  ("Investors can look it up.", 'X', "They look elsewhere.", "Shrugs.")]),
 ("Engineers leave for Tokyo. How do we keep talent?", [
  ("I will back housing and lab support.", 'F', "Support like that keeps us here.", "Nods hard."),
  ("People go where the money is.", 'R', "Then Yezo needs money in the lab.", "Sighs."),
  ("I will ask the university about ties.", 'M', "Ties would help.", "Nods."),
  ("Talent is not government's job.", 'X', "Then who builds it?", "Folds arms.")]),
 ("Our cold climate cuts data center costs. Will you back that story?", [
  ("Yes. I will tell it everywhere.", 'F', "A good story brings investment.", "Smiles."),
  ("Data centers use too much power.", 'R', "Power is local. So is the work.", "Frowns."),
  ("I will ask for a study.", 'M', "A study can help.", "Nods."),
  ("Nobody cares about cold.", 'X', "Servers do.", "Shakes head.")]),
],
"VI12": [
 ("The town office roof is falling apart and we have no funds. Help?", [
  ("I will fight for a small-town building fund.", 'F', "Mayors across the region will thank you.", "Nods."),
  ("Towns should merge.", 'R', "Merging is not a roof.", "Frowns."),
  ("I will ask what grants exist.", 'M', "Please do.", "Nods."),
  ("Not a national matter.", 'X', "It becomes one when the roof falls.", "Stands.")]),
 ("We are losing our young staff to cities. What can we do?", [
  ("I will back rural placement bonuses.", 'F', "A bonus could turn the tide.", "Smiles."),
  ("Pay them more yourself.", 'R', "With what money?", "Sighs."),
  ("I will raise it with the ministry.", 'M', "Please do.", "Nods."),
  ("People go where they want.", 'X', "And leave us empty.", "Looks away.")]),
 ("The prefecture dictates our budget priorities. Can that change?", [
  ("Yes. Towns should have more say.", 'F', "That would be a real change.", "Perks up."),
  ("The prefecture knows best.", 'R', "The prefecture is far away.", "Frowns."),
  ("I will study how other prefectures do it.", 'M', "A fair step.", "Nods."),
  ("It is fine as it is.", 'X', "It is not.", "Shakes head.")]),
],
"VI13": [
 ("Rent on my shop doubled. What should I do?", [
  ("I will back rent support for small shops.", 'F', "That could save many of us.", "Relieved."),
  ("Landlords set the price.", 'R', "Landlords are not hungry.", "Sighs."),
  ("I will talk to the landlord association.", 'M', "Please try.", "Nods."),
  ("Shops come and go.", 'X', "Not without a fight.", "Stiffens.")]),
 ("Online shops are killing my sales. Can anything level the field?", [
  ("Yes. I will back local-shop programs.", 'F', "That would be a lifeline.", "Smiles."),
  ("Adapt or close.", 'R', "We try. It is not easy.", "Frowns."),
  ("I will join your next shop-local day.", 'M', "A visit helps.", "Nods."),
  ("It is the market.", 'X', "The market is not neutral.", "Sighs.")]),
 ("Customers love the shop but parking is scarce. Ideas?", [
  ("I will ask the city for short-term parking.", 'F', "That would be a quiet miracle.", "Laughs."),
  ("Customers can walk.", 'R', "Not with heavy bags.", "Sighs."),
  ("I will raise it at the next council meeting.", 'M', "Please do.", "Nods."),
  ("Parking is not important.", 'X', "To us, it is.", "Frowns.")]),
],
"VI14": [
 ("Our poster volunteers are tired. Can you walk with them?", [
  ("Yes. I will walk the route.", 'F', "They will love that.", "Beams."),
  ("Hire professionals.", 'R', "Volunteers are the party.", "Frowns."),
  ("I will send a thank-you note.", 'M', "A note is nice.", "Nods."),
  ("I have no time for posters.", 'X', "Our members notice.", "Looks away.")]),
 ("New members want a voice in party platform choices. Will you back them?", [
  ("Yes. Members should shape the platform.", 'F', "That would energize the base.", "Grins."),
  ("The leadership decides.", 'R', "Leaders should listen.", "Frowns."),
  ("I will pass the request on.", 'M', "Please do.", "Nods."),
  ("Members should stay out of it.", 'X', "Without us there is no party.", "Stiffens.")]),
 ("The local office needs a new copier. Any funds?", [
  ("I will find a donor.", 'F', "Then my volunteers will survive.", "Smiles."),
  ("Fundraise yourselves.", 'R', "We are tired of fundraising.", "Sighs."),
  ("I will ask headquarters.", 'M', "Please do.", "Nods."),
  ("Copiers are trivial.", 'X', "They run our office.", "Shrugs.")]),
],
"VI15": [
 ("A younger member is rising fast. Should we worry?", [
  ("Welcome them, and keep them close.", 'F', "A wise approach. Loyalty grows from respect.", "Nods."),
  ("Ignore them.", 'R', "Ignoring talent is a mistake.", "Smirks."),
  ("Watch and see.", 'M', "Watching costs nothing.", "Chuckles."),
  ("Let them fail.", 'X', "That is not how we build a faction.", "Frowns.")]),
 ("The faction needs a new office. Will you pay a share?", [
  ("Yes. I will contribute.", 'F', "Generosity is remembered.", "Smiles."),
  ("Let the party pay.", 'R', "The party has other ideas.", "Raises eyebrow."),
  ("I will look at my budget.", 'M', "Do not take too long.", "Nods."),
  ("Not my problem.", 'X', "Then it is not your faction.", "Stands.")]),
 ("A scandal brews for one of ours. What do you advise?", [
  ("Stand by them until facts are known.", 'F', "That is how we keep trust.", "Nods."),
  ("Drop them quickly.", 'R', "Quick cuts leave scars.", "Winces."),
  ("Wait for the report.", 'M', "Patience, then.", "Nods."),
  ("Tell the press everything.", 'X', "That is no way to run a faction.", "Stares.")]),
],
}
EFF = {'F': "{W} +3; {F} +1; {R} -1", 'R': "{R} +3; {W} -2", 'M': "{W} +1; {R} -1", 'X': "{W} -3; {F} -1"}
w = WB('design/Game_Workbook.xlsx')
qrows = w.rows('Visitor Questions')
qtop = max(int(v['A'][2:]) for v in qrows.values() if (v.get('A') or '').startswith('VQ') and v['A'][2:].isdigit())
for vid, qs in Q.items():
    W, F, R = ORGS[vid]
    for text, choices in qs:
        assert len(choices) == 4
        qtop += 1
        d = {'A': f'VQ{qtop}', 'B': vid, 'C': text, 'H': 'A'}
        fmt = dict(W=W, F=F, R=R)
        for (ch, role, resp, react), cc, ce, cr, cx in zip(choices, 'DEFG', 'MNOP', 'QRST', 'UVWX'):
            d[cc] = ch; d[ce] = EFF[role].format(**fmt); d[cr] = resp; d[cx] = react
        d['I'] = choices[0][2]; d['J'] = choices[1][2]; d['K'] = choices[0][3]; d['L'] = choices[1][3]
        w.append_row('Visitor Questions', d)
w.save()
print('questions to', qtop)
