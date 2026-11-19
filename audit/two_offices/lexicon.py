"""Word lists for the two-offices audit: place types, real place names, real brands, and office cues.

Everything here is a DRAFT for Cameron: a proposal about where text points, never a decision about canon.
The 24 archetypes are the spec's (design/proposals/two_offices_2026-11-19/place_catalog_by_pc.csv).
"""
import re

ARCHETYPES = ["district_office", "station", "travel_route", "town_hall", "harbor", "onsen_town", "mountain", "farmland",
              "fishing_grounds", "school", "university", "hospital", "shrine_temple", "market", "festival", "factory",
              "energy_site", "island", "landmark", "ainu_site", "beach", "ski_area", "park", "community_hall"]

# Generic words that imply a place of an archetype (lower-case patterns, word-bounded).
GENERIC = {
    "district_office": [r"constituency office", r"district office", r"\byour office\b", r"front desk", r"waiting room", r"open house"],
    "station": [r"\bstations?\b", r"\bplatform\b", r"\bterminal\b"],
    "travel_route": [r"\btrains?\b", r"\brail(way|road)?\b", r"\bshinkansen\b", r"\bexpress\b", r"\bsubway\b", r"\bferry\b", r"\bferries\b", r"\bbus(es)?\b", r"timetable", r"commuter"],
    "town_hall": [r"\bcity hall\b", r"\btown hall\b", r"\bward office\b", r"\bvillage office\b", r"\bmunicipal\b", r"\bcouncil chamber\b", r"\bmayor"],
    "harbor": [r"\bharbors?\b", r"\bports?\b", r"\bpier\b", r"\bdock", r"\bwharf\b", r"\bcannery\b", r"\bseawall\b", r"\bbreakwater\b"],
    "onsen_town": [r"\bonsen\b", r"\bhot springs?\b", r"\bbathhouse\b", r"\bryokan\b", r"\binns?\b"],
    "mountain": [r"\bmountains?\b", r"\bhills?\b", r"\bhillside\b", r"\bpeaks?\b", r"\bvolcano"],
    "farmland": [r"\bfarms?\b", r"\bfarmland\b", r"\bfields?\b", r"\bdairy\b", r"\borchards?\b", r"\bpastures?\b", r"\bbarns?\b", r"\bcattle\b", r"\bharvest\b", r"\bgreenhouses?\b", r"\bpotato", r"\bfarmers?\b"],
    "fishing_grounds": [r"\bfishing\b", r"\bfishermen\b", r"\bfishers?\b", r"\bkelp\b", r"\bscallops?\b", r"\bsalmon\b", r"\bcatch\b", r"\bnets?\b", r"\bfishery\b", r"\bfisheries\b", r"\bseaweed\b", r"\btuna\b", r"\bsquid\b", r"\bcrab\b"],
    "school": [r"\bschools?\b", r"\bclassroom", r"\bhigh school\b", r"\bkindergarten\b", r"\bpta\b", r"\bgraduation\b", r"\bplayground\b", r"\bstudents?\b", r"\bteachers?\b"],
    "university": [r"\buniversit(y|ies)\b", r"\bcampus\b", r"\bcollege\b", r"\blaborator(y|ies)\b"],
    "hospital": [r"\bhospitals?\b", r"\bclinics?\b", r"\bnurses?\b", r"\bdoctors?\b", r"\bambulance\b", r"\bmedical\b"],
    "shrine_temple": [r"\bshrines?\b", r"\btemples?\b", r"\bbell tower\b", r"\bpriest\b", r"\babbot\b", r"\bmonk"],
    "market": [r"\bmarkets?\b", r"\bshopping street\b", r"\barcade\b", r"\bshopkeepers?\b", r"\bshops?\b", r"\bstalls?\b", r"\bbazaar\b", r"\bstore\b", r"\bstores\b", r"\bmain street\b", r"\bsupermarket\b"],
    "festival": [r"\bfestivals?\b", r"\bmatsuri\b", r"\bfloat\b", r"\bparade\b", r"\bfireworks\b", r"\bcarnival\b"],
    "factory": [r"\bfactory\b", r"\bfactories\b", r"\bplant\b", r"\bmill\b", r"\bwarehouse\b", r"\bworkshop\b", r"\bshipyard\b", r"\bcreamery\b", r"\bindustrial\b", r"\bassembly line\b"],
    "energy_site": [r"\bwind (farm|turbine|park)", r"\bturbines?\b", r"\bpower (plant|station|line)", r"\bnuclear\b", r"\bsolar\b", r"\bpipeline\b", r"\bterminal\b(?=.*gas)", r"\blng\b", r"\bsubstation\b", r"\bgrid\b"],
    "island": [r"\bislands?\b", r"\bislet\b", r"\boffshore\b"],
    "landmark": [r"\blake\b", r"\bcape\b", r"\bcoast\b", r"\blighthouse\b", r"\bwaterfall\b", r"\bgorge\b", r"\briver\b", r"\bbridge\b", r"\bmonument\b", r"\bwetlands?\b", r"\bsquare\b"],
    "ainu_site": [r"\bainu\b", r"\bkotan\b", r"\bcise\b", r"\bcultural (center|centre)\b"],
    "beach": [r"\bbeach(es)?\b", r"\bshore\b", r"\bseashore\b", r"\bsand\b", r"\bdrying racks?\b"],
    "ski_area": [r"\bski\b", r"\bskiing\b", r"\bslopes?\b", r"\bresort\b", r"\bsnow festival\b"],
    "park": [r"\bparks?\b", r"\bgarden\b", r"\bplayground\b", r"\bpicnic\b", r"\bbench\b"],
    "community_hall": [r"\bcommunity (hall|center|centre)\b", r"\bpublic hall\b", r"\bgymnasium\b", r"\bassembly hall\b", r"\bsocial hall\b", r"\bmeeting hall\b", r"\bthe hall\b", r"\bneighborhood association\b", r"\bresidents' association\b"],
}

# Patterns above that name a PERSON or an ACTIVITY (a weaker sign of a place than a place noun). place_references.csv
# lists only the strong ones; place_types.md counts both.
WEAK = {r"\bstudents?\b", r"\bteachers?\b", r"\bpta\b", r"\bgraduation\b", r"\bnurses?\b", r"\bdoctors?\b", r"\bmedical\b", r"\bfarmers?\b", r"\bharvest\b",
        r"\bcattle\b", r"\bpotato", r"\bfishing\b", r"\bfishermen\b", r"\bfishers?\b", r"\bcatch\b", r"\bnets?\b", r"\bshopkeepers?\b", r"\bshops?\b", r"\bstalls?\b",
        r"\bstore\b", r"\bstores\b", r"\bmayor", r"\binns?\b", r"\bcommuter", r"timetable", r"\bsand\b", r"\bshore\b", r"\bpicnic\b", r"\bbench\b", r"\bparade\b",
        r"\bfireworks\b", r"\bfloat\b", r"\bneighborhood association\b", r"\bresidents' association\b", r"\bthe hall\b", r"\bgrid\b", r"\bnuclear\b", r"\bsolar\b",
        r"\bpriest\b", r"\babbot\b", r"\bmonk", r"\bplayground\b", r"\bcampus\b", r"\blaborator(y|ies)\b", r"\bfishery\b", r"\bfisheries\b", r"\bseaweed\b", r"\bsalmon\b",
        r"\btuna\b", r"\bsquid\b", r"\bcrab\b", r"\bdairy\b", r"\bfield?s\b", r"\bfields?\b", r"\bexpress\b", r"\bhills?\b", r"\bpeaks?\b", r"\bcoast\b", r"\bsquare\b", r"\bgymnasium\b",
        r"\bresort\b", r"\bslopes?\b"}

# Place nouns that appear in the text but have NO archetype in the spec's catalog (candidates for new types).
UNCATALOGED = {
    "airport": [r"\bairports?\b", r"\bairline\b", r"\bflight\b", r"\bairstrip\b", r"\brunway\b", r"\bpassport\b"],
    "post_office": [r"\bpost office\b", r"\bmail carrier\b", r"\bparcel\b"],
    "police_or_fire": [r"\bpolice\b", r"\bkoban\b", r"\bfire (station|department|brigade)\b", r"\bfirefighters?\b"],
    "bank_or_credit_union": [r"\bbank\b", r"\bcredit union\b", r"\bloan\b", r"\bsavings\b"],
    "library": [r"\blibrar(y|ies)\b"],
    "road_or_bridge": [r"\broads?\b", r"\bhighway\b", r"\btunnel\b", r"\bintersection\b", r"\bcrosswalk\b", r"\bpothole\b", r"\bstreetlight\b", r"\bsidewalk\b", r"\bdetour\b"],
    "street_or_neighborhood": [r"\bstreet\b", r"\bneighborhood\b", r"\bneighbors?\b", r"\balley\b", r"\bdowntown\b", r"\bblock\b", r"\bcorner\b"],
    "housing": [r"\bapartments?\b", r"\bhousing\b", r"\bempty house\b", r"\bhouse\b", r"\bhome\b", r"\bresidence\b", r"\bvillage\b", r"\bdormitory\b"],
    "care_facility": [r"\bnursing home\b", r"\bcare home\b", r"\belderly\b", r"\bday ?care\b", r"\bnursery\b", r"\bchildcare\b"],
    "sports_venue": [r"\bstadium\b", r"\barena\b", r"\bsports team\b", r"\bgym\b", r"\bsumo\b", r"\bsports field\b"],
    "restaurant_or_inn": [r"\brestaurants?\b", r"\bizakaya\b", r"\bcaf[eé]\b", r"\bdinner\b", r"\bbreakfast\b", r"\bdining\b", r"\bhotel\b", r"\bdiner\b", r"\bpub\b"],
    "newsroom_or_studio": [r"\bradio\b", r"\bnewspaper\b", r"\btelevision\b", r"\bnewsroom\b", r"\bstudio\b", r"\bbroadcast\b", r"\bpodcast\b"],
    "river_or_flood_works": [r"\bflood\b", r"\bdike\b", r"\bditch\b", r"\briverbank\b", r"\bdam\b", r"\bculvert\b"],
    "forest_or_wildlife": [r"\bforest\b", r"\bwoods?\b", r"\bbears?\b", r"\bcrows?\b", r"\bdeer\b", r"\bwetland\b", r"\bwilderness\b"],
}

# Real place names found in the text (from a scan of every capitalised word on 2026-11-19), with a proposed
# archetype and a note. Names are the spec's "real places"; Yezo may rename them (canon, for Cameron).
REAL_PLACES = {
    # The Capitol side: kept (canon: Sapporo is the capital).
    "Sapporo": ("capital", "Yezo's capital (CONTENT_GUIDE, Nov 9): the Capitol office's city; keep"),
    "Susukino": ("landmark", "Sapporo's entertainment district: Capitol-side, keep"),
    "Tokyo": ("capital", "a national or foreign capital: national, not a district place"),
    "Hokkaido": ("region", "the real region name (Yezo is the nation): bills and the ticker use it; canon decision"),
    "Honshu": ("region", "the real main island: canon decision"),
    "Tohoku": ("region", "the real region: canon decision"),
    # Hokkaido towns and cities.
    "Tomakomai": ("town_hall", "PC02's district town (the spec)"),
    "Wakkanai": ("town_hall", "PC01's district town (the spec)"),
    "Sōya": ("landmark", "Cape Sōya / the Sōya region (PC01)"),
    "Rishiri": ("island", "an island off Wakkanai (PC01); the spec made VQ380 generic for it"),
    "Rebun": ("island", "an island off Wakkanai (PC01)"),
    "Teine": ("mountain", "Mount Teine / Teine ward (PC03)"),
    "Ishikari": ("town_hall", "Ishikari city (PC03)"),
    "Kotoni": ("town_hall", "a Sapporo ward area named in VQ01 and an event"),
    "Asahikawa": ("town_hall", "a Hokkaido city"),
    "Hakodate": ("town_hall", "a Hokkaido city"),
    "Otaru": ("town_hall", "a Hokkaido city"),
    "Kitami": ("town_hall", "a Hokkaido city"),
    "Kushiro": ("town_hall", "a Hokkaido city"),
    "Abashiri": ("town_hall", "a Hokkaido city"),
    "Furano": ("farmland", "a Hokkaido farm and lavender town"),
    "Biei": ("farmland", "a Hokkaido farm town"),
    "Imabetsu": ("town_hall", "an Aomori town"),
    "Shari": ("town_hall", "a Hokkaido town"),
    "Esashi": ("harbor", "a Hokkaido fishing town"),
    "Matsumae": ("shrine_temple", "a Hokkaido castle town (the temple-bell event)"),
    "Niseko": ("ski_area", "a Hokkaido ski town"),
    "Akan": ("landmark", "Lake Akan, a Hokkaido landmark"),
    "Yūbari": ("town_hall", "a Hokkaido town"),
    "Daisetsuzan": ("mountain", "a Hokkaido mountain range"),
    "Noboribetsu": ("onsen_town", "a Hokkaido onsen town"),
    "Toyotomi": ("onsen_town", "Toyotomi Onsen (PC01, the spec)"),
    "Rausu": ("fishing_grounds", "a Hokkaido fishing town"),
    "Memuro": ("farmland", "a Hokkaido farm town"),
    "Heiwa-dori": ("market", "a shopping street"),
    "Ebetsu": ("town_hall", "a Hokkaido city"),
    "Iwamizawa": ("town_hall", "a Hokkaido city"),
    "Nishimeya": ("town_hall", "an Aomori village"),
    "Ashoro": ("town_hall", "a Hokkaido town"),
    "Takayama": ("town_hall", "a town"),
    "Itayanagi": ("town_hall", "an Aomori town"),
    "Shikotsu": ("landmark", "Lake Shikotsu, a Hokkaido landmark"),
    "Teshikaga": ("landmark", "a Hokkaido town on Lake Kussharo and Mashu"),
    "Tanukikōji": ("market", "a Sapporo shopping arcade"),
    "Monbetsu": ("harbor", "a Hokkaido port town"),
    "Chitose": ("station", "Chitose, the Sapporo-area airport town (airport: not in the catalog)"),
    "Shakotan": ("beach", "a Hokkaido coast peninsula"),
    "Biratori": ("ainu_site", "a Hokkaido town known for Ainu culture"),
    "Shiretoko": ("landmark", "a Hokkaido peninsula"),
    "Betsukai": ("farmland", "a Hokkaido dairy town"),
    "Shimokawa": ("town_hall", "a Hokkaido town"),
    "Kamishihoro": ("town_hall", "a Hokkaido town"),
    "Nishiokoppe": ("town_hall", "a Hokkaido village"),
    "Sōunkyō": ("onsen_town", "a Hokkaido onsen gorge"),
    "Jōzankei": ("onsen_town", "a Sapporo onsen district"),
    "Washō": ("landmark", "a place name (Washō)"),
    "Tanesashi": ("landmark", "an Aomori coast landmark"),
    "Rumoi": ("harbor", "a Hokkaido port"),
    "Horonobe": ("energy_site", "a Hokkaido town"),
    "Kiyosato": ("town_hall", "a town"),
    "Nakashibetsu": ("town_hall", "a Hokkaido town"),
    "Sarufutsu": ("fishing_grounds", "a Hokkaido fishing village"),
    "Pippu": ("town_hall", "a Hokkaido town"),
    "Nanae": ("town_hall", "a Hokkaido town"),
    "Shintoku": ("town_hall", "a Hokkaido town"),
    "Takikawa": ("town_hall", "a Hokkaido city"),
    "Usu": ("mountain", "Mount Usu, a volcano"),
    "Tarumae": ("mountain", "Mount Tarumae (PC02, the spec)"),
    "Sukayu": ("onsen_town", "Sukayu Onsen (Aomori)"),
    "Hakkōda": ("mountain", "the Hakkōda Mountains (Aomori)"),
    "Tōya": ("landmark", "Lake Tōya"),
    "Ōnuma": ("landmark", "Ōnuma quasi-national park"),
    "Utonai": ("landmark", "Lake Utonai (PC02)"),
    "Muroran": ("harbor", "a Hokkaido port city"),
    # Aomori and Tohoku.
    "Aomori": ("town_hall", "PC04's prefecture (the spec)"),
    "Hirosaki": ("town_hall", "an Aomori city"),
    "Hachinohe": ("harbor", "an Aomori port city"),
    "Mutsu": ("town_hall", "Mutsu (PC04, the spec)"),
    "Towada": ("town_hall", "Towada (PC04, the spec)"),
    "Noheji": ("station", "Noheji (PC04, the spec)"),
    "Rokkasho": ("energy_site", "Rokkasho (PC04, the spec)"),
    "Ōma": ("fishing_grounds", "Cape Ōma, the tuna town (PC04, the spec)"),
    "Goshogawara": ("town_hall", "an Aomori city"),
    "Kuroishi": ("town_hall", "an Aomori city"),
    "Gonō": ("station", "a Gonō rail line stop (Aomori)"),
    "Shin-Aomori": ("station", "Shin-Aomori Station"),
    "Shin-Hakodate-Hokuto": ("station", "Shin-Hakodate-Hokuto Station (the Shinkansen terminus)"),
    "Tsugaru": ("landmark", "the Tsugaru region and strait (Aomori)"),
    "Neputa": ("festival", "an Aomori festival (Neputa/Nebuta)"),
    "Nebuta": ("festival", "an Aomori festival"),
    "Hokkaido Shinkansen": ("travel_route", "the real Shinkansen line (bill name)"),
    "Mongolia": ("foreign", "a foreign country"),
    "Russia": ("foreign", "a foreign country (a standing rival in the cues)"),
    "Korea": ("foreign", "a foreign country"),
    "Taiwan": ("foreign", "a foreign territory"),
    "China": ("foreign", "a foreign country"),
    "Sakhalin": ("foreign", "foreign territory; the PC01 Capitol level in the spec"),
    "Europe": ("foreign", "a continent"),
    "Asia": ("foreign", "a continent"),
    "Japan": ("foreign", "the real nation (Yezo is the game's nation); canon decision"),
}

# Real companies, products and brands (anything that names a real thing rather than a Yezo invention).
REAL_BRANDS = {
    r"\bTsugaru-nuri\b": ("Tsugaru-nuri (a real Aomori lacquerware craft)", "a craft, not a company: Yezo craft name or keep"),
    r"\bYoitomake\b": ("Yoitomake (a real Aomori folk tune and festival call)", "a cultural reference: keep or rename with the festival"),
    r"\bHaskap\b": ("Haskap (a real Hokkaido berry)", "a product, not a company: keep"),
    r"\bNebuta\b|\bNeputa\b": ("Nebuta / Neputa (real Aomori festivals)", "a place-named festival: keep until the place-canon decision"),
    r"\bChitose Airport\b|\bNew Chitose\b": ("New Chitose Airport", "a real airport: Yezo name"),
    r"\bSapporo Beer\b|\bKirin\b|\bAsahi\b": ("a real brewer", "a real company: Yezo brand"),
    r"\bNHK\b": ("NHK", "a real broadcaster: Yezo brand"),
    r"\bToyota\b|\bNissan\b|\bHonda\b": ("a real carmaker", "a real company: Yezo brand"),
    r"\bSeicomart\b|\bLawson\b|\b7-Eleven\b|\bFamilyMart\b": ("a real convenience store chain", "a real company: Yezo brand"),
    r"\bJR\b|\bJapan Rail\b": ("JR", "a real railway: Yezo Rail"),
    r"\bAmazon\b|\bGoogle\b|\bTwitter\b|\bFacebook\b|\bInstagram\b|\bYouTube\b|\bNetflix\b|\bLINE\b": ("a real internet company", "a real company: Yezo brand"),
}

# Words that point at an office (for the events audit).
CAPITOL_CUES = [r"\bassembly\b", r"\bcommittee\b", r"\bcorridors?\b", r"\bcaucus\b", r"\bprime minister\b", r"\bminister", r"\bministry\b", r"\bcabinet\b",
                r"\blobbyist\b", r"\btreasurer\b", r"\bparty\b", r"\bdues\b", r"\bcolleagues?\b", r"\bfloor\b", r"\bvote\b", r"\bbill\b",
                r"\bjournalist\b", r"\breporter\b", r"\bpress\b", r"\bbriefing\b", r"\bwhip\b", r"\bleadership\b", r"\bnational\b", r"\bsapporo\b", r"\bairline\b", r"\bsupreme court\b", r"\bspeaker\b"]
DISTRICT_CUES = [r"\bconstituents?\b", r"\bneighbou?rs?\b", r"\bneighbou?rhood\b", r"\bfestival\b", r"\bharbou?r\b", r"\bport\b", r"\bfisher", r"\bfarm", r"\bschool\b", r"\bshrine\b", r"\btemple\b",
                 r"\bstreet\b", r"\bshopkeeper\b", r"\bresidents?\b", r"\blocal\b", r"\bvillage\b", r"\btown\b", r"\bward\b", r"\bstreetlight\b", r"\bpothole\b", r"\bcrows?\b",
                 r"\bdistrict\b", r"\bassociation\b", r"\bkōenkai\b", r"\bkoenkai\b", r"\bhall\b", r"\bstation\b", r"\bbear\b", r"\bflood", r"\bditch\b", r"\bwind turbine\b", r"\bmayor\b", r"\bgrandson\b", r"\bhospital\b", r"\bclinic\b"]


def compile_all(table):
    return {k: [re.compile(p, re.I) for p in v] for k, v in table.items()}
