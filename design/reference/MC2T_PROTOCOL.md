# Mechanic Coherence & Clarity Test (MC²T): A Player-Centred Protocol and Scoring Rubric for Deckbuilder × Mobile × Political-Debate Games

The most defensible way to evaluate mechanic coherence and clarity is a mixed-method protocol that scores **what players can actually predict and explain**, using prediction tasks, freeze-probes and teach-back, rather than how they say they feel; questionnaires such as the GEQ should play only a minor role. Wrap that core in genre modules for deckbuilder, mobile and debate mechanics, and use hard gates so that one catastrophic confusion cannot be averaged away.

## TL;DR
- **Measure clarity as prediction accuracy and coherence as consistency of the player's mental model.** Clarity = can the player perceive, comprehend and *project* outcomes (SAGAT-style Level 1/2/3 freeze-probes + "predict-then-reveal" card tasks). Coherence = do the player's explanations stay consistent across cards, modes and fiction (keyword audit, cross-mode transfer probes, theme-mechanic card sorts, contradiction log).
- **Run it as 3 iterative RITE-style rounds of 5–6 players per key segment (~15–18 total), plus a 3-evaluator heuristic pass beforehand.** Use miniPXI/PXI clarity-related items as the validated self-report layer, and use the GEQ only with caution because its psychometrics are contested.
- **Score with a weighted 1–5 rubric:** Core Clarity 30%, Core Coherence 25%, and genre modules 45% (deckbuilder, mobile and debate at 15% each, re-weightable). Composite ≥4.0 = ship-ready. Any severity-4 issue, or any critical criterion ≤2, is an automatic fail whatever the composite.

---

## Executive Summary

| Question | Answer | Confidence |
|---|---|---|
| What is being measured? | **Clarity**: players perceive the signs, understand the rules and can predict outcomes and read the game state. **Coherence**: the mechanics are internally consistent, use keywords consistently, don't contradict each other, and fit the fiction. | High (definitions built on Hodent's usability pillars and the MDA framework) |
| Core method | Moderated think-aloud playtest with embedded prediction tasks, freeze-probes, teach-back and card sorts, preceded by an expert heuristic evaluation (PLAY/HEP + Pinelle + Korhonen mobile heuristics) | High that these methods are established; Medium for this specific combination (it is a synthesis) |
| Why not just a questionnaire? | Self-report measures feelings, not understanding. The GEQ lacks a formal peer-reviewed validation. [sciencedirect](https://www.sciencedirect.com/science/article/abs/pii/S1071581918302337) [researchgate](https://www.researchgate.net/publication/327098420_Systematic_Review_and_Validation_of_the_Game_Experience_Questionnaire_GEQ_-_Implications_for_Citation_and_Reporting_Practice) PXI/miniPXI are better validated but can't tell you *which* mechanic is misunderstood. | High |
| Sample | Expert pass: 3–5 evaluators. Player test: 3 iterative rounds × 5–6 per primary segment. Add more players when you need comprehension percentages with tight confidence intervals. | High (Faulkner, Nielsen, RITE) |
| Output | Weighted rubric score per dimension, severity-rated issue log (Nielsen 0–4), a "mechanic clarity matrix" (each mechanic × each metric), and go/no-go gates | Medium (the rubric thresholds are proposed practitioner benchmarks, not literature-validated cut-offs) |
| Biggest genre risks | Deckbuilder: keyword drift, invisible pile state, unreadable combo chains. Mobile: tap targets, hidden information behind long-press, interruption loss. Debate: opaque cause→effect, delayed consequences with no attribution, "designer-logic" rejection of valid arguments. | Medium–High (from designer statements, reviews and heuristic literature) |

**Confidence notation used throughout:** **H** = peer-reviewed or primary source, consistent across sources; **M** = credible secondary or developer statement, or a reasonable synthesis; **L** = practitioner convention, single anecdotal source, or my proposed benchmark.

---

## 1. Operational Definitions: Coherence vs. Clarity

The framing comes from MDA: designers build Mechanics → Dynamics → Aesthetics, while players experience Aesthetics → Dynamics → Mechanics (Hunicke, LeBlanc & Zubek, 2004) **[H]**. [yukaichou](https://yukaichou.com/gamification-analysis/mda-framework-hunicke-leblanc-zubek-mechanics-dynamics-aesthetics/) Clarity is therefore the player's ability to recover the *mechanics* from the *aesthetics and dynamics* they observe. Coherence is whether that recovered model is consistent and fits the fiction.

| Construct | Sub-dimension | Operational definition (what we observe) | Primary measures | Grounding |
|---|---|---|---|---|
| **Clarity** | C1 Perceptibility | Player notices and can read the relevant signs (numbers, icons, meters, intents) | Freeze-probe Level 1 accuracy; missed-sign count; eye/attention notes | Hodent "Clarity" = signs and feedback perceived as intended **[H]**; [celiahodent](https://celiahodent.com/understanding-the-success-of-fortnite-ux/) SAGAT Level 1 **[H]** |
| | C2 Comprehension | Player can correctly state what a mechanic/keyword does | Card read-and-explain accuracy; keyword definition recall; teach-back completeness | Hodent "Signs & feedback", "Form follows function" **[H]** |
| | C3 Predictability | Player can forecast the outcome of an action before taking it | Predict-then-reveal accuracy (exact / directional / wrong); calibration (confidence vs. correctness) | SAGAT Level 3 projection **[H]**; prediction tasks (GUR practice) **[M]** |
| | C4 Feedback legibility | After acting, player can explain *what changed and why* | Post-action attribution accuracy; "surprise" codes in think-aloud | PXI "Progress Feedback"/"Clarity of Goals" constructs **[H]**; PENS: clear, consistent feedback supports competence **[H]** [selfdeterminationtheory](https://selfdeterminationtheory.org/player-experience-of-needs-satisfaction-pens/) |
| | C5 State readability | Player can reconstruct full game state (hand/draw/discard/exhaust, meters, factions) on demand | State-reconstruction probe accuracy; time to answer | SAGAT Level 1–2 **[H]** |
| **Coherence** | K1 Internal consistency | Same keyword/icon/color always means the same thing; no synonyms for one effect | Expert keyword audit (synonym/overload count); player inconsistency reports | Hodent "Consistency" **[H]**; PLAY "Consistency in game world" **[H]** |
| | K2 Rule non-contradiction | No two rules produce conflicting or undefined outcomes | Contradiction/edge-case log (expert + player); "rules dispute" events in session | Heuristic eval (Federoff, Desurvire) **[H]** |
| | K3 Systemic fit | Mechanics reinforce rather than undermine each other (e.g., thinning, resource and draw systems interact sensibly) | Cross-mechanic prediction tasks; dominant-strategy reports; designer intent vs. observed dynamics | MDA dynamics lens **[H]** |
| | K4 Theme–mechanic alignment | Fiction implies the right function (a "Rebuttal" card counters; a "Scandal" hurts approval) | Name+art-only function guessing; card-sort into fictional categories; dissonance codes | Hodent "Form follows function" (cognitive affordance) **[H]** [kupdf](https://kupdf.net/download/the-gamers-brain-how-neuroscience-and-ux-can-impact-video-game-design_5b699f01e2b6f50b3e1085b9_pdf) |
| | K5 Cross-mode transfer | Concepts learned in one mode map predictably onto another (combat ↔ negotiation ↔ meta-map) | Transfer prediction accuracy; mode-confusion errors | Griftlands' shared battle/negotiation structure (reviews) **[M]** [pcgamer](https://www.pcgamer.com/griftlands-complex-double-deck-building-shows-promise-in-early-access/) |

**Key rule:** distinguish *intended* difficulty from *accidental* confusion. Hodent frames UX work as anticipating the "frustrations that players can have with the game that aren't by design" **[H]**. [celiahodent](https://celiahodent.com/understanding-the-success-of-fortnite-ux/) Cliff Harris states that "Overcomplexity is a feature, not a bug in Democracy 4" **[H, primary blog]**. [positech](https://www.positech.co.uk/cliffsblog/2023/02/19/democracy-4s-overcomplexity-is-by-design/) So before testing, the design team files an **Intended Opacity Declaration** listing what is *meant* to be hidden or uncertain. Confusion inside that declaration is scored against intended experience, not as a clarity defect.

---

## 2. Evidence Base: Methods and Instruments

| Method / instrument | What it is | Use in MC²T | Strengths | Limitations | Confidence |
|---|---|---|---|---|---|
| **HEP** (Desurvire, Caplan & Toth, CHI 2004) | 43 heuristics across game play, game story, mechanics, usability [researchgate](https://www.researchgate.net/publication/200553251_Using_heuristics_to_evaluate_the_playability_of_games) | Pre-test expert pass | Earliest empirically tested game heuristic set; recommended for early development [ed](https://files.eric.ed.gov/fulltext/ED621970.pdf) | Not genre-specific | H |
| **PLAY** (Desurvire & Wiberg, 2009) | Refined playability principles; 54 gamers rated high- and low-ranked games on 116 candidate heuristics [squarespace](https://userbehavioristics.squarespace.com/s/DesigningBetterGames-09HCI-Desurvire.pdf) | Pre-test expert pass; heuristics like "Game provides feedback", "Consistency in game world", "Player does not need to access the tutorial in order to play" [squarespace](https://userbehavioristics.squarespace.com/s/DesigningBetterGames-09HCI-Desurvire.pdf) | Broader genre generalization | Heuristics remain high-level | H |
| **Federoff (2002)** | 40 heuristics spanning interface, mechanics, gameplay [ceur-ws](https://ceur-ws.org/Vol-2186/paper19.pdf) | Cross-check for mechanics heuristics | Includes gameplay, not just UI | Older, PC/console-centric | H |
| **Pinelle, Wong & Stach (CHI 2008)** | 10 usability heuristics from 12 problem classes found in reviews of 108 PC games; follow-up showed problem frequency depends on genre [researchgate](https://www.researchgate.net/publication/200553264_Heuristic_evaluation_for_games_Usability_principles_for_video_game_design) [researchgate](https://www.researchgate.net/publication/279751807_A_Heuristic_Framework_for_Evaluating_User_Experience_in_Games) | UI/usability layer of expert pass | Evidence-derived from real problems; genre-sensitive | Interface-focused, less on mechanics [oulu](http://cc.oulu.fi/~mrajanen/paper19.pdf) | H |
| **Korhonen & Koivisto (MobileHCI 2006/2007)** | Mobile playability heuristics: Game Usability, Mobility, Gameplay modules; validation found 235 playability problems in 5 mobile games [academia](https://www.academia.edu/14601934/Playability_heuristics_for_mobile_games) | Mobile module | Mobility heuristics: sessions start quickly, game accommodates surroundings, interruptions handled reasonably [springer](https://link.springer.com/chapter/10.1007/978-3-319-40355-7_22) | Pre-modern-smartphone origin | H |
| **Hodent, *The Gamer's Brain*** | Usability pillars (signs & feedback, clarity, form follows function, consistency, minimum workload, error prevention/recovery, flexibility) + engage-ability (motivation, emotion, game flow); onboarding via "context and meaning", learning by doing [gdcvault](https://media.gdcvault.com/gdc2016/Presentations/Hodent_Celia_TheGamersBrain.pdf) [sobrief](https://sobrief.com/books/the-gamers-brain) | Rubric dimension structure; FTUE tasks | Industry-proven (Ubisoft, LucasArts, Epic/Fortnite) [celiahodent](https://celiahodent.com/understanding-the-success-of-fortnite-ux/) | Framework, not a scored instrument | H |
| **MDA** (Hunicke, LeBlanc & Zubek, 2004) | Mechanics → Dynamics → Aesthetics lens [futurelearn](https://www.futurelearn.com/info/courses/introduction-to-games-from-design-art-technology-to-esports/0/steps/453684) | Coherence framing; intent-vs-observed dynamics | Shared vocabulary | Not a measurement tool | H |
| **Think-aloud (concurrent + cued retrospective)** | Verbalized cognition during or after play [casrai](https://casrai.org/guides/think-aloud-protocols-concurrent-vs-retrospective) [arxiv](https://arxiv.org/pdf/2402.15452) | Core qualitative data | Concurrent captures confusion in the moment; cued retrospective (watching a replay) captures the "why" [casrai](https://casrai.org/guides/think-aloud-protocols-concurrent-vs-retrospective) [arxiv](https://arxiv.org/pdf/2402.15452) | Concurrent think-aloud can alter behavior and slow tasks; retrospective risks reconstruction [casrai](https://casrai.org/guides/think-aloud-protocols-concurrent-vs-retrospective) [koji](https://www.koji.so/docs/think-aloud-protocol) | H |
| **SAGAT-style freeze probes** (Endsley) | Pause, blank display, query perception, comprehension and projection, score vs. ground truth [medium](https://medium.com/prompt-engineering/a-comprehensive-review-of-situational-awareness-theory-application-measurement-and-future-6c6980f6da94) [arxiv](https://arxiv.org/pdf/1803.08067) | State readability + prediction | Objective, scored against ground truth; sensitive [medium](https://medium.com/prompt-engineering/a-comprehensive-review-of-situational-awareness-theory-application-measurement-and-future-6c6980f6da94) [researchgate](https://www.researchgate.net/publication/244953719_Comparative_analysis_of_SAGAT_and_SART_for_evaluations_of_situation_awareness) | Intrusive; partly a working-memory measure [arxiv](https://arxiv.org/pdf/1803.08067) [sciencedirect](https://www.sciencedirect.com/science/article/abs/pii/S0925753512001762) | H (in aviation/HF); M (adaptation to games) |
| **RITE** (Medlock et al., Microsoft, 2002) | Fix issues between participants; verify fixes [linkedin](https://www.linkedin.com/learning/ux-insights-weekly/what-is-rite-testing?trk=lynda_redirect_learning) | Iteration structure | Age of Empires II tutorial: after rapid iteration with 10 participants, the next 6 needed no changes [measuringu](https://measuringu.com/rite-method/) | Needs a team that can patch fast; not for summative stats | H |
| **PXI / miniPXI** (Vanden Abeele et al., 2020; Haider et al., 2022) | Functional constructs (incl. Ease of Control, Clarity of Goals, Progress Feedback) + psychosocial (e.g., Mastery, Autonomy) [qut](https://eprints.qut.edu.au/133989/) | Validated self-report layer | Full PXI showed good model fit with 529 participants; miniPXI = 11 single items [acm](https://dl.acm.org/doi/pdf/10.1145/3549507) [qut](https://eprints.qut.edu.au/241448/) | miniPXI single-item reliability .51–.83 (avg .68); validity confirmed for 9 of 11 constructs [qut](https://eprints.qut.edu.au/241448/) | H |
| **PENS** (Ryan, Rigby & Przybylski, 2006) | 21 items, 7-point; autonomy, competence, relatedness, intuitive controls, presence [qut](https://eprints.qut.edu.au/59977/5/59977.pdf) [psytests](https://psytests.org/cyber/pensen.html) | Optional "Intuitive Controls" subscale | Theory-grounded (SDT) [researchgate](https://www.researchgate.net/publication/225998888_The_Motivational_Pull_of_Video_Games_A_Self-Determination_Theory_Approach) | Independent validation found competence and intuitive controls loaded on one factor; 3 items removed [sciencedirect](https://www.sciencedirect.com/science/article/abs/pii/S1071581918302337) | H |
| **GEQ** (IJsselsteijn et al.) | 33-item core experience questionnaire [acm](https://dl.acm.org/doi/pdf/10.1145/3242671.3242683) | **Not recommended as primary** | Widely used [sciencedirect](https://www.sciencedirect.com/science/article/abs/pii/S1071581918302337) | Law, Brühlmann & Mekler (CHI PLAY 2018): lacks formal peer-reviewed publication; inconsistent psychometrics and citation practices [sciencedirect](https://www.sciencedirect.com/science/article/abs/pii/S1071581918302337) [semanticscholar](https://www.semanticscholar.org/paper/Systematic-Review-and-Validation-of-the-Game-%28GEQ%29-Law-Br%C3%BChlmann/bc86ee3f2c8b05c1940bd7ec0d6b4d2a1e6c090f/figure/2) | H |
| **Nielsen severity scale** | 0 = not a problem … 4 = usability catastrophe [koji](https://www.koji.so/docs/usability-issue-severity-ratings) | Issue severity | Industry standard | Single-evaluator ratings unreliable; average ≥3 raters [koji](https://www.koji.so/docs/usability-issue-severity-ratings) | H |

---

## 3. Test Protocol

### 3.1 Objectives

| # | Objective | Success evidence |
|---|---|---|
| O1 | Determine whether first-time players can learn core mechanics without external help | FTUE completion, teach-back score, prediction accuracy after tutorial |
| O2 | Identify which specific mechanics/keywords are misunderstood, and why | Mechanic clarity matrix + coded think-aloud |
| O3 | Assess whether mechanics form a consistent, contradiction-free, theme-aligned system | Keyword audit, contradiction log, transfer and card-sort probes |
| O4 | Assess mobile ergonomics' effect on comprehension (mis-taps, hidden info, interruptions) | Mis-tap rate, long-press discovery, resume accuracy |
| O5 | Assess legibility of persuasion/opinion/faction cause→effect | Attribution accuracy for immediate and delayed consequences |
| O6 | Produce prioritized, severity-rated fixes and a go/no-go decision | Rubric composite + gates |

### 3.2 Participant Profiles and Sample Size

| Segment | Profile | Why | Per round | Total (3 rounds) |
|---|---|---|---|---|
| **S1 Genre-naive mobile players** (primary for FTUE) | Play mobile games ≥3×/week; have *not* played a roguelike deckbuilder or political sim in the past year | Exposes onboarding and jargon gaps; experts "auto-fill" missing explanations | 5–6 | 15–18 |
| **S2 Deckbuilder veterans** | ≥20 h in ≥2 of Slay the Spire, Balatro, Marvel Snap, Hearthstone, Inscryption, Dominion | Detects keyword drift vs. genre conventions (Hodent: consistency "across the game and the genre"); [ixdf](https://ixdf.org/literature/article/the-game-ux-twist-usability-principles-for-games) transfer and negative-transfer errors | 4–5 | 12–15 |
| **S3 Narrative/political strategy players** | Played ≥1 of Suzerain, Democracy, Twilight Struggle, Ace Attorney, Griftlands | Tests debate/consequence legibility against genre expectations | 4–5 | 12–15 |
| **S4 Accessibility subset** (can be embedded in S1–S3) | Low vision/large text settings, motor limitations, non-native readers of the game's language | Text density and target size stress-test | 2–3 | 6–9 |
| **Expert evaluators** | 3–5 UX/GUR or design reviewers not on the team | Heuristic pass; severity rating (≥3 raters) | — | 3–5 |

**Sample-size rationale [H]:** Faulkner (2003) tested 60 users. Random 5-user sets found on average 85% of problems but as few as 55%; 10-user sets averaged 95% with a minimum of 82%. [humanfactors +2](https://www.humanfactors.com/newsletters/how_many_test_participants.asp) RITE-style iteration (5–6 per round, fixing between rounds) is therefore preferred to a single 5-person test. [davidleeking](https://davidleeking.com/usability-testing-with-5-users-challenged/) [articos](https://www.articos.com/blog/how-many-test-users-in-usability-study) **For summative comprehension percentages** (e.g., "80% predict correctly"), n≈5 gives very wide confidence intervals. Run a final unmoderated or remote validation with a larger sample (≥20 per primary segment is a practical floor) **[L — practitioner benchmark]**.

**Device matrix:** at least one small phone (~5.4–6.1"), one large phone (≥6.7"), and one tablet if supported. Include iOS and Android when both ship. Participants use their own device for the diary component.

### 3.3 Session Structure (moderated, ~100 min + optional 3–5-day diary)

| Phase | Time | Activity | Data captured |
|---|---|---|---|
| **Pre-test** | 0–10 min | Consent; screener confirmation; genre-familiarity questionnaire; baseline "What do you expect a card game about politics to have you do?" (mental-model baseline); practice think-aloud on a neutral app | Prior-knowledge covariates; expectations to compare against later |
| **Block A: Cold FTUE** | 10–30 min | Install/launch → play the tutorial and first encounter **unassisted**, concurrent think-aloud. Moderator intervenes only after 60 s of being stuck ("What are you trying to do?") | Time-to-first-meaningful-action; help requests; stuck events; FTUE completion; mis-taps |
| **Block B: Deckbuilder probes** | 30–50 min | Tasks T-D1…T-D6 (below) inside real encounters; freeze-probes at scripted turns | Prediction accuracy; keyword recall; state reconstruction |
| **Block C: Debate/persuasion probes** | 50–70 min | Tasks T-P1…T-P6 in a debate or negotiation encounter and its consequence screen | Argument-type ID; counter selection rationale; attribution accuracy |
| **Block D: Mobile ergonomics** | 70–82 min | Tasks T-M1…T-M6: one-handed play, interruption, long-press info, store transparency | Mis-tap rate; resume accuracy; info-discovery |
| **Block E: Coherence probes** | 82–92 min | Card sort (fiction categories); name+art-only function guessing; cross-mode transfer predictions; "teach a friend" teach-back | Card-sort agreement; transfer accuracy; teach-back rubric |
| **Post-test** | 92–100 min | miniPXI (or PXI functional subscales); custom clarity/coherence items; cued retrospective on 3 flagged replay moments; debrief | Validated self-report; explanation of confusions |
| **Diary (optional)** | Days 1–5 | Natural play on own device; daily 3-question log; return probe on day 5 (delayed recall of keywords and of a consequence chain) | Session length; interruptibility; retention of rules; delayed-consequence attribution |

**Think-aloud mode [H]:** use **concurrent** think-aloud during Blocks A–D and **cued retrospective** (replay of flagged clips) in post-test. This compromise captures confusion as it happens and still gets the explanation without heavy interference. [casrai](https://casrai.org/guides/think-aloud-protocols-concurrent-vs-retrospective) **Do not** require concurrent think-aloud during timed freeze-probes.

### 3.4 Task Scripts and Comprehension Probes

**Probe answer scoring (all prediction tasks):** 2 = exact (correct outcome and magnitude); 1 = directional (right effect, wrong magnitude or target); 0 = wrong / "don't know". Also record confidence (1–5) to compute **calibration**. Confident-and-wrong answers flag *false mental models* and are the most dangerous category.

#### Block A: FTUE (all segments)

| ID | Script (moderator says) | What to observe | Metric |
|---|---|---|---|
| T-A1 | "Please start the game and play as you normally would. Keep talking about what you see and think." | Hesitations; skipped tutorial text; first wrong action | Time-to-first-meaningful-action (TTFMA); # stuck events (>60 s no progress) |
| T-A2 | (after tutorial) "In one or two sentences, what is the goal of this game?" | Goal clarity | Goal statement correct (0/1/2) |
| T-A3 | "What are the three most important numbers or bars on this screen, and what do they do?" | Hierarchy of info | # correctly identified and explained (of designer-defined key 3) |

#### Block B: Deckbuilder

| ID | Script | Target mechanic | Metric |
|---|---|---|---|
| T-D1 Read-and-predict | Show 5 cards (designer-selected: 1 simple, 2 keyword, 1 conditional, 1 combo enabler). "Without playing it, what will happen if you play this card right now?" | Card text/keyword clarity | Prediction score (0–2) per card; time-to-answer |
| T-D2 Combo forecast | "If you play these two cards in this order, what happens? What if you reverse the order?" | Combo readability; order dependence; trigger timing | Prediction score; ordering-error rate |
| T-D3 Pile tracking (freeze) | Freeze mid-turn, hide UI: "Roughly how many cards are in your draw pile? Where will the card you just played go? Is any card gone for the rest of this fight?" | Draw/discard/exhaust state | State reconstruction accuracy (L1/L2) |
| T-D4 Resource forecast | "How much energy/mana will you have next turn? Why?" | Energy/resource system | Prediction score |
| T-D5 Enemy/opponent intent | "What is the enemy going to do next turn, and how sure are you?" | Intent telegraphing (cf. Slay the Spire intent icons) [rpgmakerweb](https://forums.rpgmakerweb.com/threads/forecasting-enemy-intent-slay-the-spire-like-battle-flow.113080/) | Projection accuracy + calibration |
| T-D6 Draft/thin decision | At reward or shop: "Which would you take or remove, and why? How will your deck play differently?" | Deck thinning, synergy, run progression | Rationale codes: synergy-aware / generic-power / random; agency perception |
| T-D7 Randomness attribution | After a loss/bad draw: "Why did that happen? Could you have done anything differently?" | Randomness vs. agency | Attribution code: skill / luck / unclear-system |

#### Block C: Political debate / persuasion

| ID | Script | Target mechanic | Metric |
|---|---|---|---|
| T-P1 Argument typing | "What kind of argument is your opponent making? What would counter it?" | Argument types and counters (e.g., diplomacy/manipulation/intimidation style categories) [turnbasedlovers](https://turnbasedlovers.com/review/griftlands-tbl/) | Type ID accuracy; counter-selection accuracy |
| T-P2 Meter prediction | "If you play this, how will the audience/public opinion change? Which group?" | Audience/opinion meters | Direction + magnitude + target-group accuracy |
| T-P3 Contradiction task (Ace-Attorney-style) | "Which statement is weakest, and what would you use against it?" Record *all* logically valid answers the participant proposes, then compare to what the game accepts | Contradiction/evidence logic | **Valid-alternative rejection rate** (logically valid player answers the game rejects); hint use; penalties |
| T-P4 Faction/coalition | "Which factions currently support you? What would make group X leave your coalition?" | Faction legibility | State accuracy; projection accuracy |
| T-P5 Immediate consequence trace | After a choice: "What changed because of that choice? How do you know?" | Cause→effect legibility | Attribution accuracy; source of knowledge (UI / text / guess) |
| T-P6 Delayed consequence trace | When a delayed effect fires (scripted to occur ≥1 encounter later): "Why did this happen?" | Delayed-consequence attribution | Correct attribution to originating choice (0/1/2) |
| T-P7 Dual-use decision (Twilight-Struggle-style) | "If you use this card for its points instead of its event, what else happens?" | Ops/event duality, opponent-event triggering [Wikipedia](https://en.wikipedia.org/wiki/Twilight_Struggle) | Prediction score |

#### Block D: Mobile

| ID | Script | Target | Metric |
|---|---|---|---|
| T-M1 One-handed play | "Play the next encounter holding the phone in one hand only." | Thumb reach; one-handed play | Mis-tap rate; reach-related grip changes; completion |
| T-M2 Hidden info discovery | "Find the full description of [keyword/status effect] on this enemy." | Long-press/tooltips on touch (no hover) | Discovery success; time; # wrong gestures |
| T-M3 Drag vs. tap | "Play this card on that target." | Targeting gestures, cancel/undo | Targeting errors; accidental plays; undo use |
| T-M4 Interruption | Moderator triggers a call/notification or asks the participant to background the app mid-turn for 2 min, then resume | Interruptibility; state persistence | Resume success; state-recall accuracy after resume; lost progress |
| T-M5 Session fit | "You have 5 minutes before your bus. Start and finish something meaningful." | Session length; quick start | Time-to-play; natural stopping point found (Y/N) |
| T-M6 Monetization transparency | "What can you buy here? What exactly does it give you? How much real money? Does it affect winning?" | Monetization transparency | Accuracy of item, effect and real-currency price; pay-to-win perception |

#### Block E: Coherence

| ID | Script | Target | Metric |
|---|---|---|---|
| T-K1 Name+art guess | Show 8 cards with rules text hidden: "What do you think this card does?" | Theme–mechanic alignment (form follows function) | % function-category correct |
| T-K2 Card sort | Sort 20 cards into piles by "what they do"; then name each pile | Mental-model structure vs. designer taxonomy | Agreement with designer categories (e.g., adjusted Rand index); pile names vs. keywords |
| T-K3 Keyword consistency challenge | Present 2 cards using the same keyword in different contexts: "Does [keyword] mean the same thing on both?" | Keyword consistency | Correct + consistent explanation |
| T-K4 Cross-mode transfer | "In combat, Block absorbs damage. What do you expect [negotiation equivalent] does?" | Cross-mode mapping | Transfer prediction accuracy; negative transfer errors |
| T-K5 Teach-back | "Explain how to play this to a friend who's never seen it, in under 2 minutes." | Overall mental model | Teach-back rubric: goal, turn loop, resource, deck piles, persuasion loop, win/lose (6 points) |
| T-K6 Contradiction hunt | "Has anything in the game seemed to break its own rules or surprised you in a way that felt unfair?" | Rule non-contradiction | Count + severity of reported contradictions (verified against rules) |

### 3.5 Observation Metrics

| Metric | Definition | Collection | Proposed target (green) | Red flag | Confidence in threshold |
|---|---|---|---|---|---|
| Prediction accuracy (PA) | Mean probe score ÷ 2, per mechanic | T-D1–D5, T-P2, T-P7 | ≥80% after FTUE for core mechanics | <60% | L (proposed) |
| False-confidence rate | % of wrong answers given with confidence ≥4/5 | All probes | ≤10% | >20% | L |
| Keyword recall | Correct definition of designer's top-N keywords | T-D1, T-K3, diary day 5 | ≥75% session; ≥60% delayed | <50% | L |
| State reconstruction | Freeze-probe accuracy (L1 perception, L2 comprehension) | T-D3, T-P4 | ≥85% L1; ≥75% L2 | <60% | L |
| TTFMA | Seconds from launch to first deliberate, goal-directed game action | T-A1 | Team-defined (mobile convention: within first minute) | — | L |
| Stuck events | No progress >60 s | All blocks | ≤1 per participant in FTUE | ≥3 | L |
| Help/hint requests | Moderator or in-game help | All | Decreasing across RITE rounds | Increasing | M |
| Mis-tap rate | Unintended taps ÷ total taps | T-M1, T-M3 (video coding/telemetry) | <3% | >8% | L |
| Valid-alternative rejection rate | Logically valid answers rejected ÷ valid answers offered | T-P3 | ≤10% | >25% | L |
| Attribution accuracy | Correct link of outcome → cause (immediate / delayed) | T-P5, T-P6, T-D7 | ≥80% immediate; ≥60% delayed | <50% delayed | L |
| Resume accuracy | Correct state recall + continuation after interruption | T-M4 | 100% no lost state; ≥80% recall | Any lost progress | M (Korhonen heuristic) / L (number) |
| Monetization accuracy | Correct item, effect and real price | T-M6 | 100% price; ≥90% effect | Any price misunderstanding | M |
| Teach-back score | 0–6 rubric | T-K5 | ≥5/6 | ≤3/6 | L |
| miniPXI clarity/control items | 7-point items (e.g., Clarity of Goals, Ease of Control, Progress Feedback) | Post-test | ≥5.5/7 | ≤4/7 | M (instrument validated; cut-off proposed) |

**Qualitative codes for think-aloud (apply to transcripts and video):**

| Code | Meaning | Maps to |
|---|---|---|
| PER | Didn't notice / misread a sign | C1 |
| COM | Noticed but misunderstood the rule | C2 |
| PRD | Understood rule but mispredicted interaction or outcome | C3 |
| FBK | Couldn't tell what just happened or why | C4 |
| STA | Lost track of state (piles, meters, factions) | C5 |
| INC | Same term or icon behaved differently | K1 |
| CTR | Experienced a rule contradiction or undefined case | K2 |
| SYS | Mechanics working against each other / degenerate strategy | K3 |
| DIS | Fiction implied a different function (ludonarrative dissonance) | K4 |
| TRN | Wrong transfer between modes or from genre conventions | K5 |
| ERG | Physical/touch problem caused the error | Mobile |
| OPQ | Opacity inside the Intended Opacity Declaration (not penalized; track for tuning) | — |

### 3.6 Data Analysis Approach

| Step | Procedure | Output |
|---|---|---|
| 1. Expert heuristic pass (pre-test) | 3–5 evaluators independently apply PLAY/HEP + Pinelle + Korhonen mobile + the genre checklists in §5. Each issue tagged with a heuristic and a Nielsen 0–4 severity. Ratings averaged. | Hypothesis list; probe selection; early fixes |
| 2. Keyword & rules audit | Build a lexicon of every keyword, icon, color and status; flag synonyms (two words, one effect), overloads (one word, two effects), and undefined interactions | K1/K2 audit score (pre-registered) |
| 3. Transcribe & code | Two coders code ≥20% of sessions jointly; report Cohen's kappa (aim ≥0.6 **[L]**) before single-coding the rest | Coded think-aloud dataset |
| 4. Mechanic clarity matrix | Rows = each mechanic/keyword/meter; columns = PA, false confidence, recall, code frequency, worst severity | Heat map of where understanding breaks |
| 5. Triangulate | An issue is "confirmed" when ≥2 sources agree (e.g., probe failure + think-aloud code, or expert flag + player failure). Self-report alone never confirms or clears an issue. | Confirmed issue list |
| 6. Severity rating | Nielsen 0–4 by ≥3 raters, combining frequency (% participants), impact (blocks progress / causes false model / cosmetic), and persistence (does it recur after first exposure). Report rater agreement. [measuringu](https://measuringu.com/rating-severity/) [fleck](https://fleck.ai/ux-frameworks/nielsen-heuristics) | Prioritized backlog |
| 7. RITE iteration | Fix severity 3–4 issues between rounds where feasible. Track whether the metric recovers in the next round (verification). | Fix-efficacy evidence |
| 8. Rubric scoring | Score each criterion 1–5 using anchors (§4) **from the evidence**, not impression. Two raters score independently, then reconcile. | Dimension and composite scores; gate check |
| 9. Segment comparison | Report S1 vs. S2 vs. S3 separately. Veteran success must not mask novice failure. | Segment-specific findings |

---

## 4. Scoring Rubric

### 4.1 How scoring works

| Element | Rule |
|---|---|
| Scale | Each criterion 1–5 with behavioral anchors. Anchor 5 = exemplary; 3 = acceptable with notable friction; 1 = broken. |
| Evidence basis | Each score must cite the metric(s) and code frequencies behind it (see "Evidence" column). |
| Dimension score | Weighted mean of its criteria (criterion weights listed). |
| Composite | Σ (dimension score × dimension weight). Default weights: **Core Clarity 30%, Core Coherence 25%, Deckbuilder 15%, Mobile 15%, Debate 15%**. If a genre doesn't apply, redistribute its weight pro rata. For a hybrid where debate *is* the deck system, consider Deckbuilder 12 / Debate 18. |
| Critical criteria (★) | Any ★ criterion scoring ≤2 = **automatic FAIL** of the build for that segment, regardless of composite. |
| Severity gate | Any confirmed Nielsen severity-4 issue = **FAIL**. ≥3 confirmed severity-3 issues in one dimension caps that dimension at 3.0. |

### 4.2 Core Clarity (30%)

| Criterion | Wt | 5 (Exemplary) | 4 | 3 (Acceptable) | 2 | 1 (Broken) | Evidence |
|---|---|---|---|---|---|---|---|
| **CL1 Perceptibility of signs** | 20% | All key signs noticed unprompted; L1 freeze accuracy ≥90%; legible at target text size | Minor misses on secondary info only | Occasional miss of a key sign (≤1 per participant); recovered quickly | Key signs regularly missed by ≥30% of players | Players act without seeing critical info; L1 <60% | T-A3, T-D3, PER codes |
| **CL2 Rule comprehension ★** | 25% | Core rules explained correctly by ≥90% after FTUE; no tutorial re-reading needed | ≥80%; isolated confusion on advanced rules | 65–79%; needed help once | 50–64%; repeated help requests | <50%; cannot state core loop | T-A2, T-D1, T-K5, COM codes |
| **CL3 Outcome predictability ★** | 25% | PA ≥85%; false-confidence ≤5% | PA 80–84% | PA 65–79%; false-confidence ≤15% | PA 50–64% or false-confidence 15–25% | PA <50% or false-confidence >25% | T-D1–D5, T-P2, T-P7 |
| **CL4 Feedback legibility** | 15% | Players explain every outcome's cause immediately; no "what just happened?" | Rare surprises on complex chains only | Some surprises; resolved by inspecting log/UI | Frequent unexplained outcomes; log insufficient | Outcomes appear arbitrary | T-P5, T-D7, FBK codes |
| **CL5 State readability** | 15% | L2 freeze accuracy ≥85%; all state inspectable within 1 interaction | ≥75% | 65–74%; some state requires digging | 50–64%; key state hidden | <50% | T-D3, T-P4, STA codes |

### 4.3 Core Coherence (25%)

| Criterion | Wt | 5 | 4 | 3 | 2 | 1 | Evidence |
|---|---|---|---|---|---|---|---|
| **CO1 Keyword/icon consistency ★** | 25% | Audit: 0 synonyms/overloads; players' definitions stable across cards (T-K3 ≥90%) | 1–2 minor inconsistencies, no player errors | Inconsistencies caused errors in <20% of players | Caused errors in 20–40% | Same term means different things; >40% error | Audit, T-K3, INC codes |
| **CO2 Rule non-contradiction ★** | 20% | No contradictions or undefined interactions found by experts or players | Edge cases only, documented in-game | 1 contradiction noticed by players; low impact | Multiple contradictions; players dispute rules | Core rules conflict; outcomes inconsistent across identical states | Audit, T-K6, CTR codes |
| **CO3 Systemic fit** | 20% | Mechanics reinforce each other; multiple viable strategies; designer-intended dynamics observed | Minor degenerate line, rarely found | One dominant strategy found by veterans | Mechanics undermine each other (e.g., resource system makes card types moot) | System collapses into one action / random outcome | T-D6, SYS codes, telemetry |
| **CO4 Theme–mechanic alignment** | 20% | Name+art predicts function ≥80% (T-K1); card sort mirrors taxonomy | 70–79% | 55–69%; some dissonance codes | 40–54%; fiction regularly misleads | <40%; fiction contradicts function | T-K1, T-K2, DIS codes |
| **CO5 Cross-mode/genre transfer** | 15% | Concepts transfer between modes with ≥85% accuracy; deviations from genre conventions are signposted | ≥75% | 60–74%; occasional negative transfer from genre | Frequent negative transfer; mode confusion | Modes feel like unrelated games, or are so similar that the theme is lost | T-K4, TRN codes |

### 4.4 Module D: Deckbuilder (15%)

| Criterion | Wt | 5 | 3 | 1 | Evidence |
|---|---|---|---|---|---|
| **DB1 Card text & keyword clarity ★** | 25% | First read → correct prediction ≥85%; keywords have tap-to-define; text ≤ designer's line budget | 65–84%; some cards need re-reading | <50%; text ambiguous, templating inconsistent | T-D1, CO1 audit |
| **DB2 Pile & deck-state visibility** | 15% | Draw/discard/exhaust counts and contents inspectable in 1 tap; players track "gone for this fight" correctly | Counts visible, contents buried; occasional errors | Players can't tell where cards go | T-D3 |
| **DB3 Resource/energy legibility** | 15% | Next-turn resource predicted ≥90%; carry-over rules obvious | 70–89% | <50% | T-D4 |
| **DB4 Combo & trigger readability** | 20% | Order-dependent outcomes predicted; trigger timing shown (preview/damage forecast) | Simple combos read; complex chains surprise | Outcomes of 2-card combos unpredictable | T-D2 |
| **DB5 Opponent/enemy intent** | 10% | Intent telegraphed (cf. Slay the Spire intent icons); [rpgmakerweb](https://forums.rpgmakerweb.com/threads/forecasting-enemy-intent-slay-the-spire-like-battle-flow.113080/) projection accuracy ≥85% | Partial telegraphing; 60–84% | No forecast; players blindsided | T-D5 |
| **DB6 Randomness vs. agency** | 10% | Losses attributed to own decisions or understood odds; players identify mitigation (thinning, scry, reroll) | Mixed attribution | Losses attributed to "the game" / RNG with no recourse | T-D7, T-D6 |
| **DB7 Run progression & build-around clarity** | 5% | Players articulate a deck plan and why rewards fit it | Generic "take strongest card" | No sense of build direction | T-D6 |

(Scores 4 and 2 are interpolated between the 5/3/1 anchors for module criteria.)

### 4.5 Module M: Mobile (15%)

| Criterion | Wt | 5 | 3 | 1 | Evidence |
|---|---|---|---|---|---|
| **MO1 Touch targets & gesture reliability ★** | 25% | All interactive targets ≥44×44 pt (iOS) / ≥48×48 dp (Android) with ≥8 dp spacing; [naviplus](https://naviplus.io/blogs/sell-online/topic/icon-sizing-tap-targets-mobile/) mis-tap <3%; drag-to-play has cancel | Most targets compliant; mis-tap 3–8% | Sub-minimum targets on core actions; mis-tap >8% or accidental card plays | Spec audit, T-M1, T-M3, ERG codes |
| **MO2 Small-screen readability & info density** | 20% | Card text legible at default size on smallest supported phone; zoom/inspect available; key info not occluded by thumb | Readable with zoom; some occlusion | Text unreadable without external magnification; critical info under thumb | T-A3, S4 subset |
| **MO3 Touch-native information access** | 15% | All hover-equivalent info (keywords, statuses, intents) discoverable via consistent long-press/tap; discovered unprompted | Discoverable after hint | Info hidden behind undiscoverable gesture | T-M2 |
| **MO4 One-handed play** | 10% | Core loop fully playable one-handed; primary actions in lower screen zone | Playable with occasional grip change | Requires two hands for core actions | T-M1 |
| **MO5 Interruptibility & session fit ★** | 15% | State saved at every action; resume restores full context (incl. reminder of pending choice); meaningful unit fits ≤5 min | Saves per turn; small context loss | Progress lost on background/call | T-M4, T-M5, diary |
| **MO6 FTUE/onboarding** | 10% | Learning by doing in context; no front-loaded text walls; TTFMA within first minute | Some front-loaded text; minor stuck events | Long unskippable text or stuck before first meaningful play | Block A |
| **MO7 Monetization transparency ★** | 5% | Real-currency price, contents and gameplay effect correctly stated by ≥90%; odds disclosed for randomized items | Effect clear, price conversions confusing | Players misunderstand what they're paying for or whether it affects power | T-M6 |

### 4.6 Module P: Political Debate / Persuasion (15%)

| Criterion | Wt | 5 | 3 | 1 | Evidence |
|---|---|---|---|---|---|
| **PD1 Argument types & counters** | 20% | Players identify argument type and a valid counter ≥85%; counter relationships consistent | 60–84%; counters feel partly arbitrary | Counter system unreadable | T-P1 |
| **PD2 Meter/opinion legibility** | 20% | Direction, magnitude and affected group predicted ≥80%; preview before commit | Direction right, magnitude/group unclear | Meter changes appear random | T-P2 |
| **PD3 Immediate cause→effect ★** | 20% | Attribution ≥85%; UI shows which choice moved which value | 60–84%; requires digging through reports | <50%; players can't link choices to outcomes | T-P5 |
| **PD4 Delayed consequence attribution** | 15% | ≥70% attribute delayed effect to source; game reminds of originating choice | 40–69% | <25%; delayed effects feel unjustified | T-P6, diary day-5 |
| **PD5 Faction/coalition state** | 10% | Support levels and their drivers inspectable; projection accurate ≥80% | Visible but drivers unclear | Hidden or contradictory | T-P4 |
| **PD6 Logic fairness (no "designer-logic")** | 10% | Valid-alternative rejection ≤10%, or alternatives accepted with partial credit; hints available | 10–25%; hint system mitigates | >25%; players must guess the writer's single answer | T-P3 |
| **PD7 Dual-use/trade-off legibility** | 5% | Side effects of choices (e.g., triggering opponent's event) predicted ≥85% | Learned after one painful surprise | Repeatedly surprised | T-P7 |

### 4.7 Hybrid Coherence Add-on (scored inside CO5 / PD and DB criteria when the game is a mobile deckbuilder with persuasion themes)

| Check | Pass condition | Failure pattern to watch |
|---|---|---|
| Debate verbs map to card verbs | "Rebut/Concede/Appeal" cards behave the way their rhetoric implies (T-K1 ≥80%) | Rhetorical names on generic damage/block cards, i.e., re-skinned combat (a criticism bit-tech's review levelled at Griftlands' negotiation) |
| Opinion meter ≠ HP in disguise | Players describe the meter in political terms and understand multi-group effects | Players call it "health" and ignore group composition |
| Small-screen debate state | Opponent arguments, audience meters and hand all readable without modal stacking | Players must flip between 3+ panels to decide one play |
| Delayed consequences survive interruptions | After backgrounding, the game reminds players of pending consequences | Consequence fires after a break and players attribute it to RNG |

### 4.8 Composite Thresholds and Decision Rules

| Composite | Rating | Decision |
|---|---|---|
| ≥ 4.0 and no gates triggered | **Ship-ready (Green)** | Proceed; monitor via telemetry |
| 3.3 – 3.9, no gates | **Conditional (Amber)** | Fix severity-3 items; re-test affected modules with 5 players |
| 2.5 – 3.2, or any dimension < 2.5 | **Major revision (Red)** | Redesign flagged mechanics; full re-test |
| < 2.5, OR any ★ criterion ≤ 2, OR any severity-4 issue | **Fail (Black)** | Block milestone; RITE cycle on the failing mechanics |

### 4.9 Severity Scale (issue log)

| Sev. | Label (Nielsen 0–4) | Mechanic-clarity interpretation | Example | Action |
|---|---|---|---|---|
| 0 | Not a problem | Disagreement or preference only; or inside Intended Opacity Declaration | Player wishes meters were hidden | Log only |
| 1 | Cosmetic | Momentary hesitation, self-corrected | Icon briefly misread, corrected | Fix if time |
| 2 | Minor | Wrong prediction on non-core mechanic; recovers within the encounter | Misjudges a rare keyword once | Backlog |
| 3 | Major | False mental model of a core mechanic, or repeated wrong predictions; affects ≥20% of a segment | Players think exhausted cards return next turn | Fix before next milestone |
| 4 | Catastrophe | Blocks progress, causes quitting, loses progress, or misleads spending | Interruption wipes run; price misunderstood | Fix before any release |

### 4.10 Quick-Reference Summary Card

| Dimension | Weight | ★ Critical criteria | Headline metric | Green | Red |
|---|---|---|---|---|---|
| Core Clarity | 30% | CL2 Comprehension, CL3 Predictability | Prediction accuracy | ≥80% | <60% |
| Core Coherence | 25% | CO1 Keyword consistency, CO2 Non-contradiction | Keyword audit + T-K3 | 0 overloads; ≥90% | >40% term errors |
| Deckbuilder | 15% | DB1 Card text clarity | First-read prediction | ≥85% | <50% |
| Mobile | 15% | MO1 Targets, MO5 Interruptibility, MO7 Monetization | Mis-tap rate; resume | <3%; no loss | >8%; any loss |
| Political Debate | 15% | PD3 Immediate cause→effect | Attribution accuracy | ≥85% | <50% |
| **Gates** | — | Any ★ ≤2 → FAIL | Any Sev-4 → FAIL | — | — |

---

## 5. Genre-Specific Failure Points (Checklist for Expert Pass and Probe Design)

### 5.1 Deckbuilders

| Failure point | Why it hurts clarity/coherence | Reference pattern | Probe |
|---|---|---|---|
| Keyword drift / inconsistent templating | Same effect worded differently, so players assume different mechanics. Long-running digital card games accumulate wording inconsistencies across expansions (community-documented in Hearthstone forums) **[M]** [hearthpwn](https://www.hearthpwn.com/forums/hearthstone-general/card-discussion/183941-card-text-consistency) [hearthpwn](https://www.hearthpwn.com/forums/hearthstone-general/general-discussion/233196-card-text-inconsistencies-and-how-theyd-look) | Hearthstone's stated rule (via Eric Dodds): if a first-time reader doesn't "immediately understand what the card does, we need to change that power or re-word it" **[M, wiki-reported]** [fandom](https://hearthstone.fandom.com/wiki/Design_and_development_of_Hearthstone) | T-D1, T-K3 |
| Invisible pile state | Exhaust vs. discard confusion corrupts deck-thinning logic | Inspectable piles with counts | T-D3 |
| Unforecast opponent turns | Without intent, decisions feel reactive and losses feel random | Slay the Spire shows each enemy's intent (attack with damage tier, buff, debuff, defend, unknown) above its head **[H — game behavior]** [rpgmakerweb](https://forums.rpgmakerweb.com/threads/forecasting-enemy-intent-slay-the-spire-like-battle-flow.113080/) | T-D5 |
| Combo/trigger opacity | Order-dependent, multi-trigger chains (Balatro-style scoring) unreadable without step-through | Step-by-step resolution animation; damage/score preview | T-D2 |
| Randomness without recourse | Players attribute losses to RNG rather than to understood odds | Mitigation tools surfaced (thinning, scry, reroll) | T-D7 |
| Theme-mechanic dissonance | Card names imply wrong function | Name+art predicts function | T-K1 |

### 5.2 Mobile

| Failure point | Evidence / standard | Probe |
|---|---|---|
| Sub-minimum touch targets | Apple HIG: ≥44×44 pt; Material: ≥48×48 dp with ≥8 dp spacing; WCAG 2.2 SC 2.5.8 (AA) floor 24×24 CSS px; SC 2.5.5 (AAA) 44×44 **[H]** [naviplus](https://naviplus.io/blogs/sell-online/topic/icon-sizing-tap-targets-mobile/) | Spec audit; T-M1/M3 |
| Two-handed-only layouts | Steven Hoober, "How Do Users Really Hold Mobile Devices?" (UXmatters, Feb 2013): 1,333 observations over two months ending Jan 8, 2013, of which 780 people were touching the screen; among those 780, 49% one-handed, 36% cradled, 15% two-handed; 67% of one-handed use was right thumb **[H — primary source]** | T-M1 |
| Hover-dependent info | No hover on touch; tooltips must move to long-press or tap. Discoverability failures are common | T-M2 |
| Interruption loss | Korhonen & Koivisto mobility heuristics: quick start, accommodate surroundings, handle interruptions reasonably **[H]** [springer](https://link.springer.com/chapter/10.1007/978-3-319-40355-7_22) | T-M4 |
| Front-loaded tutorials | Hodent: "learning by doing" in context and with meaning beats "learn then do" **[H]**; [gdcvault](https://media.gdcvault.com/gdc2016/Presentations/Hodent_Celia_TheGamersBrain.pdf) PLAY: player shouldn't need the tutorial to play **[H]** [squarespace](https://userbehavioristics.squarespace.com/s/DesigningBetterGames-09HCI-Desurvire.pdf) | Block A |
| Monetization opacity | Players misjudge price, contents or power effects | T-M6 |

### 5.3 Political Debate / Persuasion

| Failure point | Evidence from the genre | Probe | Confidence |
|---|---|---|---|
| Opaque causal network | Democracy is "a custom-build neural network with a cunning GUI on top of it" (Harris). [positech](https://www.positech.co.uk/cliffsblog/2013/01/) Hover arrows show positive/negative inputs, yet Class and Games' "Managing Class in 'Democracy 4'" reported: "I spent quite a long time following arrows across the network… In the end I felt that I had more of a headache than a clear indication of how an act would impact another policy area." Harris states the overcomplexity is deliberate ("If your game is representing something incredibly difficult, it needs to BE difficult") [positech](https://www.positech.co.uk/cliffsblog/category/democracy-4/) | T-P2, T-P5 + Intended Opacity Declaration | H (primary blog) / M (critique) |
| Making hidden models visible exposes incoherence | Harris built a per-voter income visualization for Democracy 4, and it "showed me what an absolute mess the simulation was", prompting a rewrite. [positech](https://www.positech.co.uk/cliffsblog/2020/06/23/democracy-4-the-fixed-income-rewrite/) **Implication: visualizing cause→effect is a coherence test, not just a clarity aid.** | Expert pass: request debug visualization of the effect graph | H |
| Narrative-first systems with weak feedback | Suzerain's lead: the team "initially built the narrative and added numbers after… How do you quantify ideology?" [avclub](https://www.avclub.com/suzerain-interview) Torpor's 2.0 "Amendment" update (July 31, 2023) focused on "refining the in-game feedback, ensuring that each action you take has clearer results and consequences". [torporgames](https://www.torporgames.com/press-releases) [torporgames](https://www.torporgames.com/2023-broadcasts) A top Steam review called consequences "random and unjustified" (low-quality source) [steamcommunity](https://steamcommunity.com/app/1207650/reviews/?browsefilter=toprated&snr=1_5_100010_) | T-P5, T-P6 | H (dev) / L (user review) |
| Single-answer contradiction logic | Ace Attorney's core is "presenting evidence to the contradictions" (Takumi). He counted ~5 statements × 5 evidence = 25 options, [blogspot](https://gyakutensaibanlibrary.blogspot.com/2017/08/game-designer-dreams-vol-3-dai-gyakuten.html) and acknowledged experienced players complain "I presented this there, but it said I was wrong." [blogspot](https://gyakutensaibanlibrary.blogspot.com/2016/08/capcoms-takumi-shu-x-storytelling-ishii.html) RPGFan's Ace Attorney Investigations Collection review lists "rigid 'moon' logic" among its cons and calls this "a central weakness of all Ace Attorney titles. There is a single line of logic/evidence you must follow", with valid evidence rejected "because I needed to use it on the fourth statement, not the third." | T-P3 (valid-alternative rejection rate) | M (translated interviews; reputable review) |
| Dual-use cards with hidden side effects | In Twilight Struggle, playing an opponent's card for Operations still triggers their event. Co-designer Ananda Gupta: "Beginners often feel overwhelmed by the problem they have to solve" [defence](https://theforge.defence.gov.au/wargaming/wargame-design-decisions-twilight-struggle-and-elsewhere) | T-P7 | H (designer essay) |
| Persuasion that's re-skinned combat | Griftlands negotiation uses core argument, "resolve" (HP), "composure" (block) and side arguments. [pcgamer](https://www.pcgamer.com/griftlands-complex-double-deck-building-shows-promise-in-early-access/) Game Informer's reviewer found it "a little overwhelming at first to learn a second set of card mechanics" (while ultimately rating the negotiation system "excellent"), and bit-tech's review said "there's little mechanical difference between the physical battles and the verbal ones. Griftlands essentially uses the exact same battle system with cards that do roughly the same things." | T-K4, hybrid add-on | M (reviews) |

---

## 6. Recommendations

| Priority | Recommendation | Rationale |
|---|---|---|
| 1 | **Pre-register an Intended Opacity Declaration and a keyword lexicon before testing.** | Separates designed difficulty (Democracy-style overwhelm, Suzerain-style bias) from accidental confusion; makes CO1/CO2 auditable. |
| 2 | **Make prediction tasks the backbone; treat questionnaires as secondary.** Use miniPXI (or full PXI functional subscales) rather than the GEQ. | Prediction scored against ground truth is objective. GEQ psychometrics are contested; miniPXI is short, but single-item reliability is moderate. [qut](https://eprints.qut.edu.au/241448/) [semanticscholar](https://www.semanticscholar.org/paper/Systematic-Review-and-Validation-of-the-Game-%28GEQ%29-Law-Br%C3%BChlmann/bc86ee3f2c8b05c1940bd7ec0d6b4d2a1e6c090f/figure/2) |
| 3 | **Run 3 RITE rounds (5–6 per primary segment), then a larger remote validation for percentages.** | Faulkner shows 5-user variance (55%–~99% of problems found); [netguru](https://www.netguru.com/blog/usability-testing-guide) [springer](https://link.springer.com/content/pdf/10.3758/BF03195514.pdf) RITE verifies fixes. [linkedin](https://www.linkedin.com/learning/ux-insights-weekly/what-is-rite-testing?trk=lynda_redirect_learning) |
| 4 | **Always report segments separately.** Veterans hide novice failure; genre conventions cause negative transfer for veterans. | Hodent's consistency principle covers both within-game and genre-level consistency. [ixdf](https://ixdf.org/literature/article/the-game-ux-twist-usability-principles-for-games) |
| 5 | **Ask engineering for a debug visualization of every cause→effect system** (persuasion, opinion, faction) for the expert pass. | Harris's experience shows that visualizing the model surfaces incoherence the designers didn't know about. [positech](https://www.positech.co.uk/cliffsblog/2020/06/23/democracy-4-the-fixed-income-rewrite/) |
| 6 | **Use the gates.** Don't let a high composite average away a severity-4 interruption bug or a misleading price. | Catastrophic issues have non-linear impact on retention and trust. |

---

## 7. Caveats

| Caveat | Implication |
|---|---|
| **Numeric thresholds are proposed, not validated.** Target percentages (e.g., PA ≥80%, mis-tap <3%) are practitioner benchmarks I've set for decision-making. No published study establishes them for these genres. **[L]** | Calibrate on your first round. Consider anchoring thresholds to a benchmark title (e.g., test Slay the Spire or Marvel Snap with the same probes to get a "good" baseline). |
| **SAGAT is validated in aviation/human factors, not games.** **[M for adaptation]** | Freeze-probes are intrusive and partly measure working memory. [arxiv](https://arxiv.org/pdf/1803.08067) [sciencedirect](https://www.sciencedirect.com/science/article/abs/pii/S0925753512001762) Keep them short (≤3 queries) and don't run them during think-aloud. |
| **Political/debate evidence is mostly developer statements and reviews**, not peer-reviewed GUR studies. Some Ace Attorney details come from fan translations or unverified secondary sources. | Treat genre failure patterns as hypotheses to test, not established facts. |
| **The rubric is a synthesis.** It combines validated components (heuristic sets, PXI, SAGAT logic, Nielsen severity) into a new structure that hasn't been psychometrically validated as a whole. | Track inter-rater agreement on rubric scores; revise anchors where raters diverge. |