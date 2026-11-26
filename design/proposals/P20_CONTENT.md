# P20 content: rows to add

Draft content by Claude, 2026-11-25, for Cameron to edit. Written to the Decision! scene rules in `design/CONTENT_GUIDE.md`: short, dry, no exclamation marks except in system names. `{colleague}` and `{campaign_staffer}` are filled by the code. Every sentence below becomes a Text row (events and choices keep their text in their own tabs, as today).

## 1. Decision Scenes rows

| Scene ID | Event ID | Kind | Card | Opens | Follows | Delay | Follow If | Office | Speaker | Activates | Weight | Weight Late | Repeat | Cooldown Weeks | Phase | Needs |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| DS11 | EV120 | Mandatory | Campaign | 18.11.01 | | | | District | | `venue:VN10` | | | | | | |
| DS12 | EV121 | Random | Campaign | | | | | District | CS02 | | 3 | | | | building | office_open |
| DS13 | EV122 | Mandatory | Campaign | | DS12 | 7 | A,B | District | CS02 | | | | | | | |
| DS14 | EV123 | Mandatory | Campaign | | DS13 | 14 | A,B | District | CS02 | `campaign_staff:CS02@A` | | | | | | |
| DS15 | EV124 | Random | Campaign | | | | | Capitol | CS04 | | 3 | 3 | | | building;mustering | office_open |
| DS16 | EV125 | Mandatory | Campaign | | DS15 | 7 | A,B | District | CS04 | `challenge:CA01x3in14@A` | | | | | | |
| DS17 | EV126 | Mandatory | Campaign | | DS16 | 14 | challenge_met | District | CS04 | `campaign_staff:CS04@A` | | | | | | |
| DS18 | EV127 | Mandatory | Campaign | | DS16 | 14 | challenge_failed | District | | | | | | | | |
| DS19 | EV128 | Random | Campaign | | | | | District | CS06 | | 3 | 3 | | | any | van_speech_done |
| DS20 | EV129 | Mandatory | Campaign | | DS19 | 7 | A,B | District | CS06 | | | | | | | |
| DS21 | EV130 | Mandatory | Campaign | | DS20 | 14 | A,B | District | CS06 | `campaign_staff:CS06@A` | | | | | | |
| DS22 | EV131 | Random | Campaign | | | | | Capitol | colleague | | 4 | 4 | Y | 4 | any | office_open |
| DS23 | EV132 | Random | Campaign | | | | | District | colleague | | 2 | 5 | Y | 3 | any | office_open |
| DS24 | EV133 | Random | Campaign | | | | | District | colleague | | 3 | 3 | Y | 4 | any | campaign_staff_free |
| DS25 | EV134 | Mandatory | Campaign | 27.10.11 | | | | Capitol | | | | | | | | |

DS11's Activates applies to both choices. DS25 is added in phase D.

## 2. Events rows

| Event ID | Title | Flavor | Trigger | Hours | Location |
| --- | --- | --- | --- | --- | --- |
| EV120 | A Storefront With Your Name on It | The party has leased an empty storefront two doors down from your District office. Inside are a folding table, a telephone and a box of blank banners. The next election is three years away, the party liaison says, and that is about how long a campaign takes to build. | Dated (18.11.01) | 2 | District |
| EV121 | Boxes in the Doorway | A man in a rain jacket is carrying boxes out of the storefront next door. His candidate has quit the race, he says, and he has a van full of posters and nowhere to take them. | Campaign | 1 | District |
| EV122 | The Farewell Party | Dan is throwing a farewell party for the volunteers of his old campaign. Nobody from their party is coming, he says, and someone should say a few words. | Followup | 2 | District |
| EV123 | An Organizer Without a Candidate | Dan sits across your desk with a notebook full of phone numbers. He has run four campaigns and lost one, and he would like a fifth. | Followup | 1 | District |
| EV124 | A Small-Donor Dinner | A woman with a leather folio stops you on the Capitol steps. Umina Kota raises money for candidates who are bad at asking for it, she says, and she is hosting a dinner in Susukino on Friday. | Campaign | 1 | Capitol |
| EV125 | Her Test | Umina telephones with an offer. Make three fundraising calls in the next two weeks, she says, and she will decide whether you are worth her time. | Followup | 1 | District |
| EV126 | Worth Her Time | Umina reads your call sheet line by line. She circles two names and says you should call them again. | Followup | 1 | District |
| EV127 | A Short Note | A note arrives from Umina in neat handwriting. Three calls was not much to ask, it says. | Followup | 0 | District |
| EV128 | Heard on Otaru Radio 今日 | A host on Otaru Radio 今日 spends five minutes on your van speech. The words were fine, she tells her listeners, and the delivery was a parking ticket. | Campaign | 1 | District |
| EV129 | On the Air | Yuina Chanami invites you on her program for half an hour. The phone lines will be open, she warns. | Followup | 4 | District |
| EV130 | Ride Along | Yuina turns up at the Campaign Office with a thermos and her own microphone. She has heard the van, she says, and she can fix it. | Followup | 1 | District |
| EV131 | A Colleague Comes Asking | {colleague} catches you in a Capitol corridor. Their district is close this cycle, and their campaign fund is closer to empty. | Campaign | 1 | Capitol |
| EV132 | Stand Beside Me | {colleague} asks you to stand beside them at a station rally in their district this weekend. A familiar face, they say, draws a bigger crowd. | Campaign | 4 | District |
| EV133 | Short-Handed | {colleague}'s campaign is short-handed, and they ask to borrow {campaign_staffer} for a while. | Campaign | 1 | District |
| EV134 | Stepping Aside | The party's notice of candidates goes up on the board outside the Capitol, and your name is not on it. You chose that some time ago. There is still a campaign to run; it just isn't yours. | Dated (27.10.11) | 1 | Capitol |

Trigger `Campaign` marks an event that only a Random Campaign Moment! scene can open (never the ordinary random event draw). If the exporter's Trigger list has no room for it, ask.

## 3. Event Choices rows

| Event | Choice | Choice text | Result text | Effects (columns) |
| --- | --- | --- | --- | --- |
| EV120 | A | Open the doors and get to work | You tape your name to the window and sit at the folding table. By evening the telephone has rung twice. | — |
| EV120 | B | Open it, and put in 50,000円 of your own | You make the first donation to your own campaign yourself. The liaison says that is a good sign, and a rare one. | Donate Funds 50000 |
| EV121 | A | Help him carry the boxes | You carry boxes until dark. He writes his number on the back of a poster and hands it to you. | — |
| EV121 | B | Offer him a corner of your office | You clear a corner of the Campaign Office. He stacks the boxes neatly and labels every one. | — |
| EV121 | C | Wish him luck | He nods and keeps carrying. The van pulls away an hour later. | — |
| EV122 | A | Give the toast (50,000円) | You thank people you have never met for work you never saw. They cheer anyway. | Campaign Fund Delta −50000; Rewards BO31 +2 |
| EV122 | B | Send a card and a gift (20,000円) | The card goes round the room. Dan tells you later that it was read out twice. | Campaign Fund Delta −20000 |
| EV122 | C | Stay away | Dan does not call again. | — |
| EV123 | A | Offer him a place on your campaign | He shakes your hand and asks where the good pens are kept. | (Activates on the scene) |
| EV123 | B | Tell him you can't take him on | He tears the first page from the notebook, leaves it on your desk and takes the rest with him. | — |
| EV124 | A | Buy a seat at the table (30,000円) | Twelve people sit at one long table. Umina knows every name and every amount. | Campaign Fund Delta −30000 |
| EV124 | B | Send a donation instead (10,000円) | She sends a thank-you note with your name spelled right, which she says is the first rule. | Campaign Fund Delta −10000 |
| EV124 | C | Decline | She closes the folio and wishes you a good evening. | — |
| EV125 | A | Accept | She hangs up before you can ask what happens if you don't. | (Activates on the scene) |
| EV125 | B | Tell her you don't take tests | She laughs, once, and says that is also an answer. | — |
| EV126 | A | Ask her to join the campaign | She says yes, and that she will need her own telephone. | (Activates on the scene) |
| EV126 | B | Thank her for the advice | She tucks the call sheet into her folio and is gone by morning. | — |
| EV127 | A | Put the note away | You put the note in a drawer you don't open often. | — |
| EV128 | A | Call in to the program | She lets you talk for a full minute, then tells you to breathe. | — |
| EV128 | B | Write her a polite letter | She reads the letter on air, kindly, and keeps the envelope. | — |
| EV128 | C | Let it go | The program moves on to the weather. | — |
| EV129 | A | Go on the program | The callers are rough and fair. Yuina laughs at one of your answers, which she says counts. | District Delta +2 |
| EV129 | B | Send a recorded message | She plays it twice and says the second time was better. | District Delta +1 |
| EV129 | C | Decline | She fills the half hour with listener mail. | — |
| EV130 | A | Hand her the microphone | She tests it, frowns, and adjusts something you didn't know could be adjusted. | (Activates on the scene) |
| EV130 | B | Thank her and say no | She finishes the thermos and leaves a spare battery behind. | — |
| EV131 | A | Give 100,000円 | {colleague} thanks you twice and says they won't forget it. | Campaign Fund Delta −100000; Party Support Delta +2; Rewards BO17 +3; Favor Owed Y |
| EV131 | B | Give 300,000円 | {colleague} goes quiet, then shakes your hand for a long time. | Campaign Fund Delta −300000; Party Support Delta +5; Rewards BO17 +3; Favor Owed Y |
| EV131 | C | Wish them well | {colleague} says they understand, in the voice people use when they don't. | Party Support Delta −1 |
| EV132 | A | Go (30,000円 for travel) | You stand on a crate beside {colleague} and wave at commuters. A few wave back. | Campaign Fund Delta −30000; Party Support Delta +3; National Delta +2; Rewards BO31 +2; Favor Owed Y |
| EV132 | B | Send a campaign staffer | Your staffer goes in your place and comes back hoarse. | Needs campaign_staff_free; Party Support Delta +2; National Delta +1; Rewards BO31 +1; Lend Campaign Staff Weeks 1; Favor Owed Y |
| EV132 | C | Decline | {colleague} finds someone else. You hear the crowd was small. | — |
| EV133 | A | Lend them for a week | {campaign_staffer} packs a bag and promises to call. | Lend Campaign Staff Weeks 1; Party Support Delta +2; Favor Owed Y |
| EV133 | B | Lend them for two weeks | {campaign_staffer} is gone two weeks and comes back with stories. | Lend Campaign Staff Weeks 2; Party Support Delta +4; Rewards BO32 +3; Favor Owed Y |
| EV133 | C | Say you need everyone | {colleague} nods and says they would do the same. | — |
| EV134 | A | Go to work | You go back to your desk. The telephone is already ringing. | — |

Mandatory follow-ups never lapse, so no `L` rows are needed.

## 4. Text rows

| Key | Text |
| --- | --- |
| `campaign.card_label` | CAMPAIGN MOMENT! |
| `campaign.phase.announcement` | Banners of War Rising |
| `campaign.phase.mustering` | Mustering the War Campaign |
| `campaign.phase.campaign` | Gladiators of War Unleashed |
| `campaign.phase.election_day` | Sengoku no Hi |
| `campaign.phase.election_day_jp` | 戦国の日 |
| `campaign.office.name` | Campaign Office |
| `campaign.office.fund` | Campaign fund |
| `campaign.office.capital` | Campaign capital |
| `campaign.office.actions_left` | {used} of {limit} campaign actions this week |
| `campaign.office.actions_unlimited` | No limit on campaign actions during the campaign. Only your hours. |
| `campaign.office.fund_full` | The campaign fund is full. Anything more raised is lost. |
| `campaign.office.locked_not_selected` | The party did not select you. The campaign office is quiet. |
| `campaign.office.locked_stepped_aside` | You are not standing this time. Your own campaign is closed. |
| `campaign.action.fundraise` | Fundraising calls |
| `campaign.action.letters` | Outreach letters |
| `campaign.action.mailings` | Mailings to local organizations |
| `campaign.action.van` | Campaign van speech |
| `campaign.action.donate` | Donate to your campaign |
| `campaign.staff.title` | Campaign staff |
| `campaign.staff.role_organizer` | Campaign Organizer |
| `campaign.staff.role_fundraiser` | Campaign Fundraiser |
| `campaign.staff.role_announcer` | Campaign Van Announcer |
| `campaign.staff.lent` | Lent until {date} |
| `campaign.staff.left` | Your campaign staff have gone home until the next cycle. |
| `campaign.van.title` | Campaign Van |
| `campaign.van.tier_0` | The van, and the Campaign van speech |
| `campaign.van.tier_1` | Van speech penalties halved |
| `campaign.van.tier_2` | Van speech rewards doubled |
| `campaign.alignment` | Party alignment |
| `how_to_play.campaign_1` | The Campaign Office runs on its own money: the campaign fund. Fundraising fills it, and you can donate your own Funds at the district office. Every campaign cost comes out of it. |
| `how_to_play.campaign_2` | Political Capital spent here becomes campaign capital, which counts toward your campaign strength. It fades a little each week, so keep the office busy. |
| `how_to_play.campaign_3` | Until the campaign opens you can take two campaign actions a week. Once Gladiators of War Unleashed begins, only your hours limit you. |
| `how_to_play.campaign_4` | Campaign staff work only on the campaign. They leave after Sengoku no Hi, and you can hire them again from January. |
| `how_to_play.campaign_5` | On the morning the campaign opens, the Candidate Selection Committee reads your campaign strength, how closely you have voted with the party, and your standing with the party. If it does not select you, your career ends on Sengoku no Hi. |
| `selection.title` | The Candidate Selection Committee |
| `selection.outcome.not_selected` | Not Selected |
| `selection.outcome.list` | Selected for the Proportional List |
| `selection.outcome.smd` | Selected for your Single-Member District |
| `selection.outcome.smd_safety_net` | Selected for your Single-Member District, with a place on the Proportional List |
| `selection.part.strength` | Campaign strength |
| `selection.part.alignment` | Party alignment |
| `selection.part.influence` | Standing with the party |
| `game_over.not_selected.title` | Sengoku no Hi |
| `game_over.not_selected.body` | The polls close without your name on the ballot. The party chose someone else, and the district will learn the new name by morning. |
| `run_end.stepped_aside.title` | Sengoku no Hi |
| `run_end.stepped_aside.body` | The results come in without you on them. Your office will belong to someone else by the new year. You leave the lights on for them. |
| `poll.title` | Campaign poll |
| `poll.source.internal` | Campaign Office internal poll |
| `poll.source.pr01` | Yezo Political Insider |
| `poll.source.pr02` | Yezo News Nightly |
| `poll.source.pr03` | Sapporo Broadcasting Center |
| `poll.range` | Campaign strength between {low} and {high} |
| `poll.outlook_likely` | Likely: {outcome} |
| `poll.outlook_could` | Could be: {outcome} |
| `poll.selected_as` | Selected: {outcome} |
| `poll.up.district` | More people in the district say they know your name. |
| `poll.down.district` | Fewer people in the district can place your name. |
| `poll.up.national` | Your name comes up more often outside the district. |
| `poll.down.national` | Outside the district, your name has gone quiet. |
| `poll.up.constituency` | Your own voters sound more sure of you. |
| `poll.down.constituency` | Your own voters sound less sure of you. |
| `poll.up.organizations` | More of the district's groups are on your side. |
| `poll.down.organizations` | Some of the district's groups have cooled. |
| `poll.up.war_chest` | The campaign fund has grown. |
| `poll.down.war_chest` | The campaign fund has shrunk. |
| `poll.up.capital` | The campaign office has been busy. |
| `poll.down.capital` | The campaign office has been quiet. |
| `poll.up.record` | Voters mention the laws you've passed. |
| `poll.down.record` | Voters ask what you've passed lately. |
| `poll.up.party` | The party is speaking well of you. |
| `poll.down.party` | The party has gone cool on you. |

Any other text the screens need (buttons, reasons a button is disabled) is added as Text rows in the same style; list them in the phase report.
