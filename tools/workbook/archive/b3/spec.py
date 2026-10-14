# Batch 3 spec (Draft 2026-10-13): topic rooms and levels for BI31-BI50.
# rooms: family codes; 'HR:STxx' = a hearing built from that committee. A caucus ('CA') is always added last.
# R = suits ranked by topic fit, best first. Q = six questions: two on the benefit (theme 1), two on cost/risk (theme 2), two on fairness/rights (theme 3).
SU=['Earnest','Emotional','Appeal','Data Driven','Divisive','Duplicitous']
B={}
def add(bid,T,jp,ro,t,rooms,R,themes,Q,thought):
    B[bid]=dict(id=bid,T=T,jp=jp,ro=ro,t=t,rooms=rooms,R=R,themes=themes,Q=Q,thought=thought)
add('BI31','Wilderness Protection','原生自然の保護','Gensei Shizen no Hogo','the wilderness',['PR','HR:ST10','TH'],
 ['Earnest','Emotional','Data Driven','Appeal','Divisive','Duplicitous'],('Wilderness protection','Logging jobs','Public access to nature'),
 ["What will protecting the wilderness save for our children?","Which animals are in danger if this bill fails?",
  "Loggers will lose work. What do you say to them?","Who pays for the new ranger stations?",
  "Who decides where the protected boundaries are drawn?","Will hikers and local guides keep their access?"],
 "Some land is worth more standing than cut.")
add('BI32','Rural Hospitals','地方病院網','Chihō Byōin-mō','rural hospitals',['TH','HR:ST17','PS'],
 ['Emotional','Earnest','Appeal','Data Driven','Duplicitous','Divisive'],('Rural health care','Hospital funding','City and country fairness'),
 ["My village is ninety minutes from an emergency room. Will this change that?","Will doctors really move to the countryside?",
  "How much will the hospital network cost each year?","Could small clinics close after the first few years?",
  "Why should cities pay for hospitals they will never use?","Who staffs a clinic in a town of two hundred?"],
 "A town without a hospital slowly stops being a town.")
add('BI33','Digital Identity Cards','デジタル身分証','Dejitaru Mibun-shō','the identity card',['PS','TV'],
 ['Data Driven','Earnest','Duplicitous','Appeal','Emotional','Divisive'],('Digital convenience','Data security','Personal privacy'),
 ["Can one card really replace my tax, health and benefit papers?","How much time will the card save an ordinary family?",
  "What happens to my records if the system is hacked?","Who will see my data, and who can sell it?",
  "Is the card compulsory for the elderly?","Why should I trust the state with everything in one place?"],
 "Convenience is never free. Someone always holds the keys.")
add('BI34','Broadcaster Independence','公共放送の独立','Kōkyō Hōsō no Dokuritsu','the broadcaster',['PR','TV'],
 ['Earnest','Data Driven','Appeal','Emotional','Duplicitous','Divisive'],('Press independence','Broadcaster funding','Regional coverage'),
 ["Should ministers be able to dictate what the public broadcaster airs?","What does an independent board change in daily news?",
  "Why should taxpayers fund a broadcaster at all?","How is independence not just a blank cheque?",
  "Who watches the watchers on the new board?","Will rural viewers see more of their own region?"],
 "A free voice is only as strong as the hand that funds it.")
add('BI35','Donation Transparency','政治献金の透明化','Seiji Kenkin no Tōmeika','political donations',['PR','HR:ST17','LB'],
 ['Data Driven','Earnest','Divisive','Appeal','Emotional','Duplicitous'],('Campaign finance','Donor privacy','Member fundraising'),
 ["Why should anyone hide who pays for a campaign?","Will published donor lists end back-room deals?",
  "Small donors fear harassment if named. Will you protect them?","Does a donation cap silence honest supporters?",
  "Who audits the new reports, and who audits the auditor?","Why punish members for money their voters give freely?"],
 "Sunlight is a fine disinfectant, but it burns too.")
add('BI36','Corporate Tax Cuts','法人税の引き下げ','Hōjinzei no Hikisage','the tax cut',['PS','HR:ST16'],
 ['Data Driven','Appeal','Duplicitous','Divisive','Earnest','Emotional'],('Business investment','Public revenue','Small shop fairness'),
 ["Will lower taxes really bring factories to Yezo?","How many jobs does each yen of tax relief buy?",
  "Who makes up the lost revenue when taxes fall?","Do big firms get a gift while small shops wait?",
  "Why cut taxes when schools are short of money?","What stops firms from pocketing the cut and leaving anyway?"],
 "Every tax cut is a promise someone else pays for.")
add('BI37','the Carbon Levy','炭素課徴金','Tanso Kachōkin','the carbon levy',['TH','HR:ST10','PR'],
 ['Data Driven','Earnest','Emotional','Appeal','Divisive','Duplicitous'],('Clean air','Household energy costs','Fuel for farms and boats'),
 ["Will cleaner air be worth a higher heating bill this winter?","How much of the levy comes back to households?",
  "Farmers and fishers burn fuel for a living. Who protects them?","Why tax a family before the factories change?",
  "Is this a climate measure or a tax grab?","Will other countries do the same, or are we alone?"],
 "People will pay for a clean sky if they trust where the money goes.")
add('BI38','Fishing Quota Reform','漁獲枠改革','Gyokaku-waku Kaikaku','tradeable quotas',['HR:ST13','TH'],
 ['Data Driven','Earnest','Appeal','Emotional','Duplicitous','Divisive'],('Quota trading','Catch monitoring','Family boats'),
 ["Will tradeable quotas let big fleets buy out family boats?","How will onboard reporting catch cheats at sea?",
  "Who owns a quota if my father's boat is sold?","Do the new limits follow science or politics?",
  "Why must small harbours pay for monitoring equipment?","What happens to quota when a fisher retires?"],
 "The sea keeps a ledger, and it is running short.")
add('BI39','Shipbuilding Support','造船・防衛産業支援','Zōsen Bōei Sangyō Shien','the shipyards',['HR:ST11','TH'],
 ['Appeal','Earnest','Data Driven','Divisive','Emotional','Duplicitous'],('Shipyard jobs','Shipbuilding subsidies','Contract oversight'),
 ["How many yard jobs does a guaranteed order really protect?","Will our own ships keep the coast safe?",
  "Why guarantee profits to defense firms with public money?","Could the same money build clinics instead?",
  "Will the yards depend on exports to stay busy?","Who inspects the contracts for waste?"],
 "A fleet is a promise. Someone must keep the yards alive to keep it.")
add('BI40','the Constitutional Review','憲法見直し委員会','Kenpō Minaoshi Iinkai','the review',['HR:ST12','PR'],
 ['Earnest','Data Driven','Appeal','Duplicitous','Emotional','Divisive'],('Constitutional reform','Commission membership','Citizen rights'),
 ["Why reopen the constitution when it has served us well?","Who will sit on the commission, and who picks them?",
  "Could the review be used to weaken my rights?","How long will the commission study before it reports?",
  "Will ordinary citizens have any say in the findings?","What would you refuse to change, whatever the commission says?"],
 "A constitution that never changes dies. One that changes carelessly dies faster.")
add('BI41','Border Cooperation','税関・国境協力','Zeikan Kokkyō Kyōryoku','border sharing',['HR:ST14','LB'],
 ['Data Driven','Appeal','Earnest','Duplicitous','Divisive','Emotional'],('Customs efficiency','Data sharing','National sovereignty'),
 ["Will merged customs checks really shorten the queue at the port?","How much trade do we lose to delays every year?",
  "What data would Japan receive about our citizens?","Who answers if the data is misused abroad?",
  "Does sharing a border mean sharing our sovereignty?","Why trust a neighbour's officers at our docks?"],
 "Open doors speed trade, but someone must still watch the door.")
add('BI42','Chishima Development','千島資源開発','Chishima Shigen Kaihatsu','the islands',['HR:ST14','PR','LB'],
 ['Appeal','Data Driven','Duplicitous','Earnest','Emotional','Divisive'],('Island resources','Fishing waters','Island security'),
 ["What will the Chishima venture bring home to Yezo?","Who is our partner, and what do they get?",
  "Fishers say the islands are their waters. What about them?","Will island residents share the profits?",
  "Who guards the islands if tensions rise?","Could this deal anger a bigger neighbour?"],
 "Wealth on a contested shore comes with a bill nobody prints.")
add('BI43','China Trade','対中貿易正常化','Taichū Bōeki Seijōka','open trade',['TV','HR:ST14'],
 ['Data Driven','Appeal','Duplicitous','Divisive','Earnest','Emotional'],('Export gains','Local makers','Trade dependence'),
 ["Will cheaper goods help ordinary families or hurt local makers?","How many exporters gain when the tariffs fall?",
  "Can a farm compete with imports at half the price?","What stops us depending on one trading partner?",
  "Do we ignore human rights for cheaper goods?","Who protects workers if a factory closes?"],
 "Trade is friendship with a price tag. Read it carefully.")
add('BI44','Farm Succession','農地継承支援','Nōchi Keishō Shien','family farms',['TH','HR:ST13'],
 ['Emotional','Earnest','Appeal','Data Driven','Duplicitous','Divisive'],('Young farmers','Farm subsidies','Small farm fairness'),
 ["Will a grant keep my son on the family farm?","How many young people want to farm if the money is there?",
  "Why subsidize farms that cannot pay for themselves?","Does an inheritance tax cut only help the wealthy landowner?",
  "What happens to farms with no heir?","Will the grant favour big farms over small ones?"],
 "A field without a farmer is only land.")
add('BI45','University Research Funding','大学の自治と研究費','Daigaku no Jichi to Kenkyūhi','research funding',['PS','HR:ST17'],
 ['Data Driven','Earnest','Appeal','Emotional','Duplicitous','Divisive'],('Research and innovation','University spending','Rural students'),
 ["What will doubling research grants discover that we need?","Will graduates stay in Yezo if the labs are here?",
  "Who audits a university that controls its own budget?","Why spend on laboratories while schools lack teachers?",
  "Will rural students ever benefit from this?","Could autonomy let universities ignore national needs?"],
 "Knowledge is the only crop that grows in every season.")
add('BI46','Workplace Equality','職場の平等','Shokuba no Byōdō','equal treatment',['TH','PR','TV'],
 ['Earnest','Emotional','Data Driven','Appeal','Divisive','Duplicitous'],('Fair treatment at work','Small employer burden','Defining discrimination'),
 ["Will the penalties really stop a manager who discriminates?","How many workers face unequal pay today?",
  "Small shops fear lawsuits. Who protects them?","Will the rules make bosses hire fewer people?",
  "Who decides what counts as discrimination?","Why legislate what a good boss would do anyway?"],
 "Fairness at work is not a favour. It is a floor.")
add('BI47','Parental Leave','育児休業と保育','Ikuji Kyūgyō to Hoiku','parental leave',['TH','PS','LB'],
 ['Emotional','Earnest','Data Driven','Appeal','Duplicitous','Divisive'],('Parent and child care','Employer costs','Childcare fairness'),
 ["Will both parents really take leave without losing their jobs?","Where will the new childcare places be built?",
  "Who pays for the leave: employers or taxpayers?","Will small firms survive having two staff away?",
  "Does the state raise children now?","Why should people without children pay for this?"],
 "A country that cannot raise its children cannot expect a future.")
add('BI48','Surveillance Cameras','監視カメラ','Kanshi Kamera','the cameras',['HR:ST17','TV','PR'],
 ['Data Driven','Earnest','Divisive','Duplicitous','Appeal','Emotional'],('Public safety','Surveillance limits','Protest and privacy'),
 ["Will cameras at the station actually stop crime?","How long is my face stored by the police?",
  "Who watches the people who watch the cameras?","Does everyday safety justify tracking everyone?",
  "Could the footage be used against protesters?","Why should innocent people be tracked for the sake of suspects?"],
 "Safety and freedom both die in the same dark corner.")
add('BI49','Town Mergers','自治体合併','Jichitai Gappei','town mergers',['TH','HR:ST17','PS'],
 ['Appeal','Data Driven','Emotional','Earnest','Duplicitous','Divisive'],('Merger savings','Local identity','Village representation'),
 ["How much does merging two villages really save?","Will a merged town office still answer my phone call?",
  "Will my village's name and festival disappear?","What happens to the town hall staff?",
  "Who speaks for a small village inside a big town?","Why force towns to merge when they can share services?"],
 "A village is more than its budget line.")
add('BI50','Party Leadership Ballots','党首選出方法','Tōshu Senshutsu Hōhō','open ballots',['TV','PR'],
 ['Earnest','Appeal','Data Driven','Divisive','Duplicitous','Emotional'],('Internal democracy','Party stability','Ballot integrity'),
 ["Why should party members, not the caucus, choose the leader?","Would open ballots end back-room deals?",
  "Will a membership vote reward popularity over ability?","Do small parties even have enough members to vote?",
  "Who prevents a rival party from flooding the ballot?","Should a leader answer to members or to voters?"],
 "A leader chosen in the dark answers to the dark.")
assert sum(len(b['rooms']) for b in B.values())==49
