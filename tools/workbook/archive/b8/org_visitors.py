"""Content 5, second half (2026-10-18): one visitor per organization that never
reached 60 standing, each with two dilemma questions. Run from the repo root."""
import sys, json
sys.path.insert(0, "tools/workbook")
from wbx import WB
# visitor -> (org, rival, friend, [(question, [(choice, role, response, reaction)] x4)] x2)
V = {
"VI71": ("BO10", "BO26", "BO30", [
 ("Rice prices fell and the co-op is worried. Where do you stand?", [
  ("Farmers need a price floor. I will back one.", 'F', "That is what our members hoped to hear.", "Sits up straighter."),
  ("Shoppers deserve cheaper rice. Let prices fall.", 'R', "Then you have chosen the shop over the field.", "Shakes head slowly."),
  ("Let me study a smaller support fund first.", 'M', "A fund is something. Do not take long.", "Nods once."),
  ("Farming is a private business.", 'X', "Tell that to the empty barns.", "Turns toward the door.")]),
 ("A dry summer is coming. Will you help with irrigation?", [
  ("Yes, I will find money for shared irrigation.", 'F', "Water is life here. Thank you.", "Smiles with relief."),
  ("Farmers should insure themselves.", 'R', "Insurance does not make rain.", "Folds arms."),
  ("I will ask the ministry for a report.", 'M', "A report is a start.", "Shrugs."),
  ("Dry summers are nature's business.", 'X', "Nature does not pay our bills.", "Looks away.")]),
]),
"VI72": ("BO11", "BO15", "BO27", [
 ("Rent near campus is climbing. Will you act?", [
  ("Yes. I will push for student housing.", 'F', "That would change lives on campus.", "Brightens."),
  ("Landlords have rights too.", 'R', "Landlords have rights. Students have rent.", "Sighs."),
  ("I will look at what other cities do.", 'M', "Look quickly. Leases are due.", "Taps a notebook."),
  ("That is not a matter for government.", 'X', "Then who is it for?", "Stares.")]),
 ("We want a student seat on the university board. Yes or no?", [
  ("Yes. Students belong in that room.", 'F', "Finally, someone who sees us.", "Raises a fist, grinning."),
  ("Boards should stay with the experts.", 'R', "Experts forget who pays tuition.", "Rolls eyes."),
  ("I will raise it with the rectors.", 'M', "Raise it loudly, then.", "Smiles thinly."),
  ("You are too young to judge.", 'X', "We are old enough to pay.", "Stiffens.")]),
]),
"VI73": ("BO12", "BO05", "BO21", [
 ("Both parents work and daycare is full. What will you do?", [
  ("I will fight for more daycare places.", 'F', "Families will feel that.", "Exhales, relieved."),
  ("Businesses cannot fund more childcare.", 'R', "Then who will? Families cannot.", "Frowns."),
  ("I will ask the ministry how many are waiting.", 'M', "Please do. The list is long.", "Nods."),
  ("Parents made their choices.", 'X', "That is a cruel thing to say.", "Goes pale.")]),
 ("Schools want to cut after-school programs. Where are you?", [
  ("Protect them. Children need a safe place.", 'F', "Children will sleep easier for that.", "Smiles warmly."),
  ("Cut them. The budget is tight.", 'R', "Tight for whom? Not for our kids.", "Shakes head."),
  ("Let us keep half and review the rest.", 'M', "Half is better than none.", "Sighs."),
  ("Families should handle it at home.", 'X', "And when both parents work?", "Looks hurt.")]),
]),
"VI74": ("BO13", "BO16", "BO15", [
 ("Our youngest apprentice is leaving. Can you help us keep craft alive?", [
  ("Yes. I will back apprenticeship stipends.", 'F', "A stipend keeps hands at the bench.", "Bows slightly."),
  ("Crafts should compete like any business.", 'R', "A craft is not a gadget.", "Frowns."),
  ("I will ask the arts office what exists.", 'M', "Ask them. They know us.", "Nods."),
  ("Not every old craft survives.", 'X', "Not without help, no.", "Turns away.")]),
 ("Cheap copies are flooding the market. What will you do?", [
  ("I will push for a quality mark.", 'F', "A mark tells buyers the truth.", "Smiles."),
  ("Customers choose what they like.", 'R', "They choose what they can see.", "Sighs."),
  ("I will talk to the tourist board.", 'M', "That helps a little.", "Nods once."),
  ("Imitation is flattery.", 'X', "Flattery does not pay rent.", "Looks hurt.")]),
]),
"VI75": ("BO17", "BO08", "BO18", [
 ("Members are tired of being attacked in the press. Will you defend us?", [
  ("Yes. The Assembly deserves respect.", 'F', "We need colleagues who say so aloud.", "Straightens a lapel."),
  ("The press is doing its job.", 'R', "The press is hardly short of volunteers.", "Rolls eyes."),
  ("I will say what I can, fairly.", 'M', "Fairness is a fine start.", "Nods."),
  ("Maybe members earn the attacks.", 'X', "Spoken like an outsider.", "Goes cold.")]),
 ("We need more staff to read bills carefully. Will you support it?", [
  ("Yes. A better-staffed member serves the public.", 'F', "Good. Better reading makes better law.", "Smiles."),
  ("Taxpayers will not like it.", 'R', "Taxpayers like good law.", "Sighs."),
  ("I will ask for a costed plan.", 'M', "A plan is fair.", "Nods slowly."),
  ("Members have enough help.", 'X', "You have not seen our desks.", "Shakes head.")]),
]),
"VI76": ("BO20", "BO11", "BO06", [
 ("The festival route is being rezoned. Will you protect it?", [
  ("Yes. The route is part of the town.", 'F', "Neighbors and shrine will thank you.", "Smiles, relieved."),
  ("Development should come first.", 'R', "Development passes. The route stays.", "Frowns."),
  ("I will ask the city to consult everyone.", 'M', "Consult widely, please.", "Nods."),
  ("Festivals are not public business.", 'X', "They are the town's heartbeat.", "Looks away.")]),
 ("Volunteers keep the grove clean. Will you recognize them?", [
  ("Yes. They deserve public thanks.", 'F', "They will be glad to hear it.", "Beams."),
  ("Volunteering is its own reward.", 'R', "Thanks cost little.", "Sighs."),
  ("I will mention them in my speech.", 'M', "A mention is kind.", "Smiles."),
  ("Groves are not my concern.", 'X', "Then whose concern are they?", "Frowns.")]),
]),
"VI77": ("BO21", "BO23", "BO12", [
 ("Care workers are leaving for better pay. Will you raise it?", [
  ("Yes. Care work deserves a living wage.", 'F', "Our residents will notice the difference.", "Eyes glisten."),
  ("The budget cannot stretch further.", 'R', "Then the care will stretch thinner.", "Shakes head."),
  ("I will ask for a pay review.", 'M', "A review is something.", "Nods."),
  ("Care is a family matter.", 'X', "Families are already exhausted.", "Turns away.")]),
 ("Elders are lonely. Will you fund home visits?", [
  ("Yes. A visit can change a week.", 'F', "Thank you. Many wait by the door.", "Smiles softly."),
  ("Neighbors should visit voluntarily.", 'R', "Some have no neighbors left.", "Frowns."),
  ("I will pilot it in one district.", 'M', "A pilot is a start.", "Nods."),
  ("That is not government's job.", 'X', "Then whose is it?", "Stares.")]),
]),
"VI78": ("BO27", "BO30", "BO14", [
 ("Our buses run half empty and then packed. Will you act?", [
  ("Yes. Let the data decide the routes.", 'F', "Data is what we asked for.", "Opens a folder."),
  ("Rural roads need the money more.", 'R', "Both matter. The numbers favor the city.", "Frowns."),
  ("I will ask for a service review.", 'M', "A review is fair.", "Nods."),
  ("People should drive.", 'X', "Not everyone can.", "Sighs.")]),
 ("We want mixed-use zoning near stations. Will you back it?", [
  ("Yes. Homes near stations make sense.", 'F', "It cuts commutes and costs.", "Smiles."),
  ("Keep neighborhoods as they are.", 'R', "They are changing anyway.", "Shrugs."),
  ("I will ask for pilot areas.", 'M', "Pilots are sensible.", "Nods."),
  ("Zoning is too complicated.", 'X', "That is why we need leaders.", "Rolls eyes.")]),
]),
"VI79": ("BO29", "BO15", "BO28", [
 ("Only a few elders speak our language fluently. Will you help record them?", [
  ("Yes. Their voices must be kept.", 'F', "Thank you. That work cannot wait.", "Hand to chest."),
  ("Languages fade as societies change.", 'R', "Some fade. Some are pushed.", "Frowns."),
  ("I will ask what recording costs.", 'M', "A cost is a start.", "Nods."),
  ("That is not a government matter.", 'X', "It was once the government's doing.", "Turns away.")]),
 ("Children want to learn our language at school. Will you fund teachers?", [
  ("Yes. Children should hear it in class.", 'F', "They will learn proudly.", "Smiles."),
  ("Schools have enough subjects.", 'R', "Not this one, apparently.", "Sighs."),
  ("I will ask the ministry about training.", 'M', "Training is the root.", "Nods."),
  ("It is a private matter for families.", 'X', "Families alone cannot do it.", "Shakes head.")]),
]),
"VI80": ("BO30", "BO27", "BO10", [
 ("The last bus leaves at noon. How will people reach town?", [
  ("I will fight for a regular rural service.", 'F', "People here will remember that.", "Exhales."),
  ("Cities need transit more.", 'R', "Cities have plenty already.", "Folds arms."),
  ("I will ask for a service count.", 'M', "Count carefully. We are few.", "Nods."),
  ("Move closer to town.", 'X', "That is how villages die.", "Looks away.")]),
 ("Young families could move here with help. Will you back grants?", [
  ("Yes. Grants can fill empty houses.", 'F', "Empty houses wait for them.", "Smiles."),
  ("Grants are a waste.", 'R', "Empty villages cost more.", "Frowns."),
  ("I will look at a small pilot.", 'M', "A pilot is a good start.", "Nods."),
  ("Let the market decide.", 'X', "The market left already.", "Stares.")]),
]),
}
EFF = {'F': "{W} +3; {F} +1; {R} -1", 'R': "{R} +3; {W} -2", 'M': "{W} +1; {R} -1", 'X': "{W} -3; {F} -1"}
boosters = {b['booster_id']: b for b in json.load(open('data/boosters.json'))}
w = WB('design/CoP_Starter_Card_Stage_Data.xlsx')
vrows = w.rows('Visitors')
stage_cell = vrows[w.find_row('Visitors', 'VI01')]['F']
vtop = max(int(v['A'][2:]) for v in vrows.values() if (v.get('A') or '').startswith('VI') and v['A'][2:].isdigit())
qrows = w.rows('Visitor Questions')
qtop = max(int(v['A'][2:]) for v in qrows.values() if (v.get('A') or '').startswith('VQ') and v['A'][2:].isdigit())
for vid, (org, rival, friend, qs) in V.items():
    assert int(vid[2:]) == vtop + 1, (vid, vtop)
    vtop += 1
    b = boosters[org]
    name = b['name_en']
    w.append_row('Visitors', {'A': vid, 'B': f'{name} Representative', 'C': f"{b['name_jp']}の代表",
        'D': f"{b['romaji']} no Daihyō", 'E': f'{name} Representative', 'F': stage_cell,
        'G': f'{org} +1-3; {friend} +1', 'H': f'{org} -3; {rival} -2'})
    for text, choices in qs:
        qtop += 1
        d = {'A': f'VQ{qtop}', 'B': vid, 'C': text, 'H': 'A'}
        fmt = dict(W=org, R=rival, F=friend)
        order = ['A', 'B', 'C', 'D']
        for letter, (ch, role, resp, react), col_c, col_e, col_r, col_x in zip(
                'ABCD', choices, 'DEFG', 'MNOP', 'QRST', 'UVWX'):
            d[col_c] = ch
            d[col_e] = EFF[role].format(**fmt)
            d[col_r] = resp
            d[col_x] = react
        d['I'] = choices[0][2]; d['J'] = choices[1][2]; d['K'] = choices[0][3]; d['L'] = choices[1][3]
        w.append_row('Visitor Questions', d)
w.save()
print('visitors', len(V), 'questions to', qtop)
