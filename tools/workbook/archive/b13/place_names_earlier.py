"""Real Aomori and Hokkaido places for the earlier Visitor Questions and
Events (Cameron, 2026-11-08). Each recurring visitor keeps one home town
across all their questions (Hanako Okuda in Kotoni, Gen Tsukamoto in Rausu,
and so on), and follow-ups share their source's place. Named places are never
described as the player's own district: questions about "the district" or the
player's own campaign stay unnamed. Only questions about a concrete local
situation are placed; policy questions are left general. Claude's draft.
Archived copy: not runnable as it stands once applied."""
import sys
sys.path.insert(0, "tools/workbook")

QUESTIONS = {
 # VI01 Hanako Okuda, Kotoni (Sapporo)
 "VQ01": "The streetlight on our corner in Kotoni has been out since spring. Can you help?",
 "VQ02": "Who is going to shovel the Kotoni sidewalks for the elderly this winter?",
 "VQ03": "Can we get a crosswalk and a crossing guard near the elementary school in Kotoni?",
 "VQ177": "The Kotoni community hall roof leaks. Will you help us repair it?",
 # VI02 Gen Tsukamoto, Rausu
 "VQ04": "Russian patrol boats keep shadowing our Rausu boats. Will you stand with the fleet?",
 "VQ06": "Rausu harbor is silting up. Will you carry the dredging request to the capital?",
 "VQ180": "Seals are eating the catch off Shiretoko. What can the fleet do?",
 # VI05 Fumiko Sugawara, Betsukai
 "VQ189": "The milk truck cannot reach us in Betsukai in winter. Can the road be cleared?",
 # VI04 Ryo Kawabata, Muroran
 "VQ186": "The Muroran steelworks is cutting night shifts. Will you speak up?",
 "VQ188": "A safety inspector was removed from our plant in Muroran. Will you ask why?",
 # VI07 Yuri Hasegawa, Ebetsu
 "VQ195": "The playground equipment in our Ebetsu park is broken. Who fixes it?",
 # VI08 Daigo Ishikari, Akan
 "VQ199": "The wood supply for the carvers at Lake Akan is shrinking. Can you help?",
 "VQ200": "Would you visit our workshop at Lake Akan and hear how we work?",
 # VI09 Emi Takasugi, Sapporo commuter
 "VQ25": "When do we get more train cars on the morning line into Sapporo?",
 "VQ26": "Will you push for a faster rail link to New Chitose Airport?",
 # VI10 Hiroshi Wada, Esashi
 "VQ29": "Will you join us for the next Esashi shrine festival?",
 "VQ204": "Our shrine roof in Esashi needs repair and the donations are thin. Can you help?",
 "VQ206": "The men who carry the Esashi festival shrine are growing old. Any ideas?",
 # VI11 Lele Aoyama, Sapporo
 "VQ209": "The cold around Ishikari cuts data center costs. Will you back that story?",
 # VI12 Kiyoshi Murata, Shimokawa
 "VQ210": "The Shimokawa town office roof is falling apart and we have no funds. Help?",
 # VI13 Tomoko Ide, Asahikawa
 "VQ34": "Our shopping arcade off Asahikawa's Heiwa-dori is half empty. What would you do?",
 "VQ213": "Rent on my Asahikawa shop doubled. What should I do?",
 # VI17 Haruto Ebina, Furano
 "VQ42": "Seasonal staff for the Furano slopes are hard to find. Any ideas?",
 # VI19 Sora Kudo, the Tsugaru Strait
 "VQ44": "Would you cross with me on the night ferry from Ōma to Hakodate to see the delays yourself?",
 # Bill-room and one-room visitors
 "VQ95": "A logging truck rolled through the nesting grounds below Daisetsuzan again. Who can stop it?",
 "VQ96": "We have four rangers for the whole Daisetsuzan range. Can protection really work?",
 "VQ97": "From Shakotan I drive ninety minutes to reach the nearest surgeon. Would a regional hospital network change that?",
 "VQ111": "The Hakodate dock has orders for two years. What happens after that?",
 "VQ115": "Our queue at Hakodate port runs three hours. Will joint checks help?",
 "VQ121": "I want to take over my father's farm in Tokachi, but the land costs too much. Help?",
 "VQ129": "We have had thefts on the platform at Aomori Station. Are cameras the answer?",
 "VQ131": "If Nishimeya merges, who answers the phone at the village office?",
 "VQ132": "Our festival in Nishimeya is run by the village office. Will it survive a merger?",
 "VQ158": "A dry summer is coming to the Tokachi plain. Will you help with irrigation?",
 "VQ159": "Rent near the Hirosaki campus is climbing. Will you act?",
 "VQ163": "Our youngest Tsugaru lacquer apprentice is leaving. Can you help us keep craft alive?",
 "VQ167": "The Sapporo Festival route is being rezoned. Will you protect it?",
 "VQ171": "Our Sapporo buses run half empty and then packed. Will you act?",
 "VQ173": "Only a few elders in Biratori speak our language fluently. Will you help record them?",
 "VQ174": "Children in Shiraoi want to learn our language at school. Will you fund teachers?",
 "VQ175": "The last bus out of Ashoro leaves at noon. How will people reach town?",
 "VQ176": "Young families could move to Ashoro with help. Will you back grants?",
 # VI81 Takashi Hamada, Hirosaki
 "VQ222": "Hirosaki's Neputa festival is ninety years old on our street and half the float pullers are over seventy. How do we keep it alive?",
 "VQ223": "Our Neputa float costs a hundred and twenty thousand yen in permits and insurance. The Hirosaki office wants proof it helps everyone.",
 # VI82 Michiko Sasaki, Takayama Inari Shrine
 "VQ224": "The roof of the hall at Takayama Inari Shrine leaks and the carpenters who know the old joints are dying out. Who pays?",
 "VQ225": "Thousands come to Takayama Inari for photos of the gates and leave no offering. Some climb the sacred stones.",
 # VI83 Daisuke Kondo, Yūbari
 "VQ226": "Nineteen houses on one road in Yūbari are empty. Nobody pays property tax on a house nobody owns.",
 "VQ227": "Yūbari's garbage truck now costs more than the festival budget. Should we cut collection days?",
 # VI84 Ichiro Watanabe, Imabetsu
 "VQ228": "Snow closes the only road into Imabetsu for days. The plow contract is up and nobody wants to bid for forty houses.",
 "VQ229": "The school in our Imabetsu valley has three pupils. The town talks of closing it.",
 # VI85 Yoshie Narita, Itayanagi
 "VQ230": "A black bear came through my orchard in Itayanagi twice this month and ate a week of harvest. What now?",
 "VQ231": "Everyone wants to visit Itayanagi in picking season but nobody wants to pick. The labor is gone.",
 # VI86 Kazuo Abe, Shari
 "VQ232": "Bears are coming along the school path in Shari in autumn. Our club has eleven members, nine over sixty.",
 # VI87 Akemi Fujiwara, Noboribetsu
 "VQ234": "Noboribetsu is empty on weekdays and jammed at New Year. How do we spread the visitors?",
 "VQ235": "The Noboribetsu hot spring water table drops each year. The larger inns want more wells.",
 # VI88 Hiroshi Kimura, Niseko
 "VQ236": "Overseas skiers are discovering the Niseko powder. How do we welcome more without wrecking the village?",
 "VQ237": "My own staff cannot afford to rent in Niseko anymore.",
 # VI89 Rina Kurosawa, Daisetsuzan
 "VQ238": "Hikers use the Daisetsuzan trails but rescue costs fall on the village. Only one hut remains open.",
 # VI90 Noboru Ishikawa, Lake Shikotsu
 "VQ240": "Litter and toilet waste pile up at Lake Shikotsu. Our budget is the same as twenty years ago.",
 "VQ241": "The drive around Lake Shikotsu is lovely in autumn and unknown the rest of the year.",
 # VI91 Fumiko Sato, Aomori fish market
 "VQ242": "Our Mutsu Bay scallop stall had a line of three hundred last year, then half the stalls were fined over a license mix-up.",
 # VI92 Tetsuya Ota, Aomori City
 "VQ244": "I run three plows in Aomori City. The city pays a flat rate and the snow does not follow the budget.",
 # VI93 Haruko Mori, Teshikaga
 "VQ246": "Last term a bear stood outside the school gate in Teshikaga. The children now walk in a group with a bell, which is not a plan.",
 "VQ247": "The old Teshikaga school building could be a community hall but the town wants to sell it.",
 # VI94 Yuto Matsuda, Kamishihoro
 "VQ248": "I came home to Kamishihoro from Sapporo to work remotely. My neighbors think I am on vacation. What can be done about this?",
 # VI95 Masato Takeda, Iwamizawa
 "VQ250": "The combine is ready in Iwamizawa and the hands are not. Half my neighbors are over seventy.",
 # VI96 Chiyo Hayashi, Memuro
 "VQ252": "Imported potatoes undercut my Memuro crop by a third. Supermarkets want a cheaper price every year.",
 # VI97 Genji Endo, Hachinohe
 "VQ254": "A small Hachinohe brewery pays the same excise paperwork as a large one. We are four people.",
 # VI98 Shinobu Kikuchi, Shari
 "VQ256": "The salmon run at Shari has halved in ten years. The hatchery says it needs a new tank.",
 # VI101 Sachiko Nomura, Furano market
 "VQ262": "The Furano market's stall fees went up and half the older vendors quit.",
 # VI102 Tomekichi Sakai, Goshogawara
 "VQ264": "I am eighty-four, farming in Goshogawara, and I have no one to take the farm. The family wants to sell.",
 # VI103 / VI104, Sapporo Snow Festival
 "VQ266": "The Sapporo Snow Festival's sculpture budget is half what it was. I have six blocks of ice and two assistants.",
 "VQ268": "Hauling snow for the Sapporo Snow Festival costs more than the sculptures. Who should pay?",
 # VI105 Noriko Taniguchi, Nishiokoppe
 "VQ270": "Three of my patients in Nishiokoppe were hurt shoveling this winter. All of them are over seventy-five.",
 # VI106 Satoru Imai, Lake Abashiri
 "VQ272": "The ice on Lake Abashiri is thinner each year. Tourists rent holes by the hour, and some walk out too far.",
 # VI107 Kunio Fukuda, Sōunkyō
 "VQ274": "The valley bus to Sōunkyō runs three times a day and ice delays all of them.",
 # VI108 Mai Nishimura, Niseko
 "VQ276": "Seasonal instructors cannot find rooms in Niseko. The resort wants a full season of work with no housing.",
 # VI109 Isamu Kato, Jōzankei
 "VQ278": "Fuel prices doubled and the old boiler is the largest cost in my Jōzankei hotel.",
 # VI110 Reiko Shimizu, Abashiri
 "VQ280": "The drift ice reaches Abashiri later and leaves earlier each year. My season has shrunk by a month.",
 "VQ281": "On the best days there are four hundred people on the Abashiri shore and no toilets.",
 # VI111 Haruo Kimura, Tanukikōji
 "VQ283": "My shop is the last on this block of Tanukikōji with a bell on the door. The landlord wants to sell. Will you speak up?",
 # VI112 Emi Sasaki, Kitami
 "VQ284": "The 7:40 bus in Kitami has been cut to every second day. I have a job on the other side of town. What do I do?",
 # VI113 Ryo Takeda, Susukino
 "VQ286": "I work nights alone near Susukino and the street gets rough after midnight. Who looks out for people like me?",
 # VI114 Sachiko Ono, Hirosaki
 "VQ288": "This Hirosaki ward used to hold a summer cleanup every year. Nobody organizes it now. Will you?",
 # VI115 Daichi Mori, Hakodate
 "VQ291": "The road outside the Hakodate depot is cracked and my van bounces over it all day. What can you do?",
 # VI116 Mayumi Hayashi, Kushiro
 "VQ292": "The Washō Market hall in Kushiro has an expensive new lease. We sell fish, not diamonds. Will you ask them to reconsider?",
 # VI118 Fumiko Inoue, Hachinohe
 "VQ297": "The Hachinohe shotengai lights are half dead and the street looks abandoned at dusk. Can it be fixed?",
 # VI119 Takuya Fujita, Shin-Aomori
 "VQ299": "The taxi rank at Shin-Aomori Station was moved to the far corner. Passengers do not find us. Can you ask for it back?",
 # VI120 Yoshie Nakajima, Otaru
 "VQ300": "The nearest supermarket in Otaru is a twenty-minute walk uphill and I have a bad knee. What are my options?",
 # VI124 Michiko Aoki, Hachinohe
 "VQ309": "Tourists come for the view of the Tanesashi coast and never buy a coffee. How do we turn visits into sales?",
 # VI130 Genji Okada, Toyotomi
 "VQ320": "The Toyotomi village clinic closes at noon on Fridays. Where do I go if my knee gives out?",
 # VI135 Satomi Morita
 "VQ330": "The maternity ward in Rumoi closes next spring. Where do I give birth?",
 # VI145 Hanae Hirata, Monbetsu
 "VQ351": "The road outside the Monbetsu school has no crossing guard. A child nearly got hit. Will you act?",
 # VI146 Kazuo Hayakawa, Takikawa
 "VQ353": "Takikawa's local history is almost gone from the curriculum. Is it important?",
 # VI148 Eiji Nakamura, Horonobe
 "VQ356": "Our Horonobe route was cut and children now walk through the dark. What happens in winter?",
 # VI153 Shigeru Ito, Kiyosato
 "VQ366": "Fertilizer prices doubled in Kiyosato and the potato price did not. What do I do?",
 # VI154 Kimiko Hasegawa, Nakashibetsu
 "VQ369": "Cows in Nakashibetsu need milking at five and I have not had a day off in a year. Is there relief?",
 # VI155 Tadashi Kato, Sarufutsu
 "VQ370": "The Sarufutsu scallop catch is down and fuel is up. What can the city do?",
 # VI156 Hiromi Sakurai, Kuroishi
 "VQ373": "My pickles win prizes but nobody outside Kuroishi knows them. How do I reach buyers?",
 # VI157 Mamoru Tsuchiya, Hirosaki
 "VQ374": "The frost came late in Hirosaki and half the apple blossom died. Is there insurance for that?",
 # VI159 Kenzo Ikeda, Pippu
 "VQ379": "Young people leave Pippu for the city. Is there any hope for the village?",
 # VI160 Yumiko Hoshino, Rishiri
 "VQ380": "My kombu drying racks are on the Rishiri beach and the storm took half. Can the city help?",
 # VI161 Goro Hamamoto, Cape Sōya
 "VQ382": "Wolves have not been seen in a century but bears come into my paddock near Cape Sōya. What do I do?",
 # VI162 Chieko Wakabayashi, Nanae
 "VQ384": "Our roadside stand in Nanae was moved off Route 5 and sales dropped by half. Why?",
 # VI163 Haruki Nagano, Shintoku
 "VQ386": "I moved to Shintoku to farm and nobody will lease me land. What am I missing?",
 # VI164 Setsuko Omura, Tokachi
 "VQ388": "Our Tokachi cheese wins medals and still loses to cheap imports on the shelf. Why?",
 # VI165 Toshio Kuroda, Sapporo
 "VQ390": "Cold storage at the Sapporo wholesale market is full and expensive. Fresh produce spoils before it sells. Is there a shared option?",
 # VI166 Yasuo Noda, Asahikawa
 "VQ392": "Young drinkers prefer beer and wine. Our Asahikawa brewery is a hundred and ten years old. Will it last?",
 # VI18 Granny Chiyo, Asahikawa
 "VQ396": "The temple in Asahikawa that keeps our family graves cannot afford a new roof. Should the town help?",
}

FLAVOR = {
 "EV12": "A shopkeeper stops you outside Shin-Hakodate-Hokuto Station. The road surface has been broken for years, and everyone keeps talking about a faster train but nobody says who pays.",
 "EV17": "A veterans' hall secretary writes that the old coastal batteries on Mount Hakodate are being discussed again, and nobody has asked the people who served there.",
 "EV19": "A temple priest and a shrine caretaker from Hirosaki have come together, which almost never happens, to ask about the gate that both their congregations use.",
 "EV22": "The owner of a small hotel in Noboribetsu waits at the end of your surgery. Two floors are shut because she cannot hire anyone, and the visitors keep coming.",
 "EV26": "A nurse from the Toyotomi village clinic says the doctor now comes only four days a week, and the next clinic is ninety minutes away.",
 "EV27": "A letter in careful handwriting from Hakodate port: the harbor is short of staff, the paperwork has doubled, and no one in the capital seems to know.",
 "EV38": "Two neighborhoods in Kitami both refuse the new transfer station. Each wants you to say it should go to the other.",
 "EV41": "Overnight snow has shut the road up to Sukayu in the Hakkōda Mountains. The village office rings to ask whether anyone in the capital is listening.",
 "EV42": "The principal of a school in Shari calls at seven in the morning. A bear has been seen at the edge of the school grounds.",
 "EV48": "A group of elders has done the same radio exercises on the Lake Tōya path every morning for decades. The organizer asks whether you would join them for the first set.",
 "EV49": "The Ainu Kotan at Lake Akan is holding its cultural showcase day: songs, dance, embroidery and food. The elders have asked whether you will come.",
 "EV50": "A university student society has invited you to join its field visit to the Ainu cultural center at Shiraoi. The students will tour the exhibits and meet the staff, and they would like a legislator to come along.",
 "EV53": "The Fisheries Cooperative has called its members to the Rausu harbor hall about quotas, prices and the cracked breakwater, and asked you to stand in front of them.",
 "EV56": "The agricultural cooperative in Memuro is bringing in the autumn harvest and invites you to spend a few hours in the fields with its members.",
 "EV57": "A woodcarver and two potters have opened a shared workshop in an empty shop on Asahikawa's Heiwa-dori. The Artisans Guild asks you to cut the ribbon.",
 "EV58": "The Commuter Committee dares you to ride the packed rush-hour train from Otaru into Sapporo with them, standing, before you vote on fares.",
 "EV62": "You convened both Kitami neighborhood associations in one room, as you said you would. Nobody wants the transfer station, and everyone has come.",
 "EV63": "The ministry has answered the letter you forwarded from Hakodate port: the harbor office will be reviewed, at some point, by someone.",
 # Disconnected from the player's own district (2026-11-08).
 "EV70": "The poster boards from your last campaign are still up on three corners, your own face among them, peeling.",
 "EV71": "An elder of the Local Kōenkai invites you to her grandson's wedding reception in Hachinohe, where the bride's family lives.",
}


def main():
    from wbx import WB
    w = WB("design/Game_Workbook.xlsx")
    for qid, text in QUESTIONS.items():
        w.set_cell("Visitor Questions", w.find_row("Visitor Questions", qid), "C", text)
    for eid, text in FLAVOR.items():
        w.set_cell("Events", w.find_row("Events", eid), "C", text)
    w.save()
    print("placed", len(QUESTIONS), "questions and", len(FLAVOR), "events")


if __name__ == "__main__":
    main()

# Applied with it (2026-11-08): VQ234 choice A and its replies, and VQ235's
# reply D, said "onsen district", which reads as the player's own district once
# the town is named; they now say "onsen town" / "the whole town".
