--[[
Upgrade data for Reforge.

Item names must match Windower/res/items.lua, either the short name (`en`) or the full name (`enl`).
Anything not marked "confirmed" comes from BG Wiki (Oct 2026) and hasn't been checked against a real trade.
Where the wiki gives no quantity for an ingredient, it is taken as 1.

Reforge covers the upgrades that wait for a game day. For Artifact and Relic armor:
  old level 75 set (or its +1/+2) -> iL109 -> +1 -> +2 -> +3
And for Empyrean armor:
  old level 99 set (+1 or +2 only) -> iL109 -> +1 -> +2 -> +3
The Limbus +4 furnaces are instant, so they're left out.
]]

local upgrades = {}

-- First word of each reforged set's full item name: {artifact, relic, empyrean}
upgrades.jobs = {
    WAR = {"pummeler's", 'agoge', 'boii'},
    MNK = {"anchorite's", "hesychast's", 'bhikku'},
    WHM = {'theophany', 'piety', 'ebers'},
    BLM = {"spaekona's", "archmage's", 'wicce'},
    RDM = {'atrophy', 'vitiation', 'lethargy'},
    THF = {"pillager's", "plunderer's", "skulker's"},
    PLD = {'reverence', 'caballarius', "chevalier's"},
    DRK = {'ignominy', "fallen's", "heathen's"},
    BST = {'totemic', 'ankusa', 'nukumi'},
    BRD = {'brioso', 'bihu', 'fili'},
    RNG = {'orion', 'arcadian', 'amini'},
    SAM = {'wakido', 'sakonji', 'kasuga'},
    NIN = {'hachiya', 'mochizuki', 'hattori'},
    DRG = {'vishap', 'pteroslaver', "peltast's"},
    SMN = {"convoker's", 'glyphic', "beckoner's"},
    BLU = {"assimilator's", 'luhlaza', 'hashishin'},
    COR = {"laksamana's", 'lanun', "chasseur's"},
    PUP = {'foire', 'pitre', 'karagoz'},
    DNC = {'maxixi', 'horos', 'maculele'},
    SCH = {"academic's", 'pedagogy', 'arbatel'},
    GEO = {'geomancy', 'bagua', 'azimuth'},
    RUN = {'runeist', 'futhark', 'erilaz'},
}

-- Old level 75 sets that Monisette reforges into the iL109 sets. Full item names, head to feet.
-- Old Artifact can start from the NQ or +1 piece, old Relic from NQ, +1 or +2. GEO and RUN have none.
upgrades.old_sets = {
    WAR = {
        artifact = {"Fighter's Mask", "Fighter's Lorica", "Fighter's Mufflers", "Fighter's Cuisses", "Fighter's Calligae"},
        relic = {"Warrior's Mask", "Warrior's Lorica", "Warrior's Mufflers", "Warrior's Cuisses", "Warrior's Calligae"},
    },
    MNK = {
        artifact = {'Temple Crown', 'Temple Cyclas', 'Temple Gloves', 'Temple Hose', 'Temple Gaiters'},
        relic = {'Melee Crown', 'Melee Cyclas', 'Melee Gloves', 'Melee Hose', 'Melee Gaiters'},
    },
    WHM = {
        artifact = {"Healer's Cap", "Healer's Bliaut", "Healer's Mitts", "Healer's Pantaloons", "Healer's Duckbills"},
        relic = {"Cleric's Cap", "Cleric's Bliaut", "Cleric's Mitts", "Cleric's Pantaloons", "Cleric's Duckbills"},
    },
    BLM = {
        artifact = {"Wizard's Petasos", "Wizard's Coat", "Wizard's Gloves", "Wizard's Tonban", "Wizard's Sabots"},
        relic = {"Sorcerer's Petasos", "Sorcerer's Coat", "Sorcerer's Gloves", "Sorcerer's Tonban", "Sorcerer's Sabots"},
    },
    RDM = {
        artifact = {"Warlock's Chapeau", "Warlock's Tabard", "Warlock's Gloves", "Warlock's Tights", "Warlock's Boots"},
        relic = {"Duelist's Chapeau", "Duelist's Tabard", "Duelist's Gloves", "Duelist's Tights", "Duelist's Boots"},
    },
    THF = {
        artifact = {"Rogue's Bonnet", "Rogue's Vest", "Rogue's Armlets", "Rogue's Culottes", "Rogue's Poulaines"},
        relic = {"Assassin's Bonnet", "Assassin's Vest", "Assassin's Armlets", "Assassin's Culottes", "Assassin's Poulaines"},
    },
    PLD = {
        artifact = {'Gallant Coronet', 'Gallant Surcoat', 'Gallant Gauntlets', 'Gallant Breeches', 'Gallant Leggings'},
        relic = {'Valor Coronet', 'Valor Surcoat', 'Valor Gauntlets', 'Valor Breeches', 'Valor Leggings'},
    },
    DRK = {
        artifact = {'Chaos Burgeonet', 'Chaos Cuirass', 'Chaos Gauntlets', 'Chaos Flanchard', 'Chaos Sollerets'},
        relic = {'Abyss Burgeonet', 'Abyss Cuirass', 'Abyss Gauntlets', 'Abyss Flanchard', 'Abyss Sollerets'},
    },
    BST = {
        artifact = {'Beast Helm', 'Beast Jackcoat', 'Beast Gloves', 'Beast Trousers', 'Beast Gaiters'},
        relic = {'Monster Helm', 'Monster Jackcoat', 'Monster Gloves', 'Monster Trousers', 'Monster Gaiters'},
    },
    BRD = {
        artifact = {'Choral Roundlet', 'Choral Justaucorps', 'Choral Cuffs', 'Choral Cannions', 'Choral Slippers'},
        relic = {"Bard's Roundlet", "Bard's Justaucorps", "Bard's Cuffs", "Bard's Cannions", "Bard's Slippers"},
    },
    RNG = {
        artifact = {"Hunter's Beret", "Hunter's Jerkin", "Hunter's Bracers", "Hunter's Braccae", "Hunter's Socks"},
        relic = {"Scout's Beret", "Scout's Jerkin", "Scout's Bracers", "Scout's Braccae", "Scout's Socks"},
    },
    SAM = {
        artifact = {'Myochin Kabuto', 'Myochin Domaru', 'Myochin Kote', 'Myochin Haidate', 'Myochin Sune-Ate'},
        relic = {'Saotome Kabuto', 'Saotome Domaru', 'Saotome Kote', 'Saotome Haidate', 'Saotome Sune-Ate'},
    },
    NIN = {
        artifact = {'Ninja Hatsuburi', 'Ninja Chainmail', 'Ninja Tekko', 'Ninja Hakama', 'Ninja Kyahan'},
        relic = {'Koga Hatsuburi', 'Koga Chainmail', 'Koga Tekko', 'Koga Hakama', 'Koga Kyahan'},
    },
    DRG = {
        artifact = {'Drachen Armet', 'Drachen Mail', 'Drachen Finger Gauntlets', 'Drachen Brais', 'Drachen Greaves'},
        relic = {'Wyrm Armet', 'Wyrm Mail', 'Wyrm Finger Gauntlets', 'Wyrm Brais', 'Wyrm Greaves'},
    },
    SMN = {
        artifact = {"Evoker's Horn", "Evoker's Doublet", "Evoker's Bracers", "Evoker's Spats", "Evoker's Pigaches"},
        relic = {"Summoner's Horn", "Summoner's Doublet", "Summoner's Bracers", "Summoner's Spats", "Summoner's Pigaches"},
    },
    BLU = {
        artifact = {'Magus Keffiyeh', 'Magus Jubbah', 'Magus Bazubands', 'Magus Shalwar', 'Magus Charuqs'},
        relic = {'Mirage Keffiyeh', 'Mirage Jubbah', 'Mirage Bazubands', 'Mirage Shalwar', 'Mirage Charuqs'},
    },
    COR = {
        artifact = {"Corsair's Tricorne", "Corsair's Frac", "Corsair's Gants", "Corsair's Culottes", "Corsair's Bottes"},
        relic = {'Commodore Tricorne', 'Commodore Frac', 'Commodore Gants', 'Commodore Trews', 'Commodore Bottes'},
    },
    PUP = {
        artifact = {'Puppetry Taj', 'Puppetry Tobe', 'Puppetry Dastanas', 'Puppetry Churidars', 'Puppetry Babouches'},
        relic = {'Pantin Taj', 'Pantin Tobe', 'Pantin Dastanas', 'Pantin Churidars', 'Pantin Babouches'},
    },
    DNC = {
        artifact = {"Dancer's Tiara", "Dancer's Casaque", "Dancer's Bangles", "Dancer's Tights", "Dancer's Toe Shoes"},
        relic = {'Etoile Tiara', 'Etoile Casaque', 'Etoile Bangles', 'Etoile Tights', 'Etoile Toe Shoes'},
    },
    SCH = {
        artifact = {"Scholar's Mortarboard", "Scholar's Gown", "Scholar's Bracers", "Scholar's Pants", "Scholar's Loafers"},
        relic = {'Argute Mortarboard', 'Argute Gown', 'Argute Bracers', 'Argute Pants', 'Argute Loafers'},
    },
}

-- Old set pieces whose full name differs at some tier: full name without +N -> name used above
upgrades.old_aliases = {
    ["commodore's tricorne"] = 'Commodore Tricorne', -- the +2 is spelt differently
}

-- Old level 99 Empyrean sets that Monisette reforges into the iL109 Empyrean sets. Full item names, head to feet.
-- Only a +1 or +2 piece can be reforged, not the NQ. GEO and RUN have none.
upgrades.old_empyrean = {
    WAR = {"Ravager's Mask", "Ravager's Lorica", "Ravager's Mufflers", "Ravager's Cuisses", "Ravager's Calligae"},
    MNK = {"Tantra Crown", "Tantra Cyclas", "Tantra Gloves", "Tantra Hose", "Tantra Gaiters"},
    WHM = {"Orison Cap", "Orison Bliaut", "Orison Mitts", "Orison Pantaloons", "Orison Duckbills"},
    BLM = {"Goetia Petasos", "Goetia Coat", "Goetia Gloves", "Goetia Chausses", "Goetia Sabots"},
    RDM = {"Estoqueur's Chappel", "Estoqueur's Sayon", "Estoqueur's Gantherots", "Estoqueur's Fuseau", "Estoqueur's Houseaux"},
    THF = {"Raider's Bonnet", "Raider's Vest", "Raider's Armlets", "Raider's Culottes", "Raider's Poulaines"},
    PLD = {"Creed Armet", "Creed Cuirass", "Creed Gauntlets", "Creed Cuisses", "Creed Sabatons"},
    DRK = {"Bale Burgeonet", "Bale Cuirass", "Bale Gauntlets", "Bale Flanchard", "Bale Sollerets"},
    BST = {"Ferine Cabasset", "Ferine Gausape", "Ferine Manoplas", "Ferine Quijotes", "Ferine Ocreae"},
    BRD = {"Aoidos' Calot", "Aoidos' Hongreline", "Aoidos' Manchettes", "Aoidos' Rhingrave", "Aoidos' Cothurnes"},
    RNG = {"Sylvan Gapette", "Sylvan Caban", "Sylvan Glovelettes", "Sylvan Bragues", "Sylvan Bottillons"},
    SAM = {"Unkai Kabuto", "Unkai Domaru", "Unkai Kote", "Unkai Haidate", "Unkai Sune-ate"},
    NIN = {"Iga Zukin", "Iga Ningi", "Iga Tekko", "Iga Hakama", "Iga Kyahan"},
    DRG = {"Lancer's Mezail", "Lancer's Plackart", "Lancer's Vambraces", "Lancer's Cuissots", "Lancer's Schynbalds"},
    SMN = {"Caller's Horn", "Caller's Doublet", "Caller's Bracers", "Caller's Spats", "Caller's Pigaches"},
    BLU = {"Mavi Kavuk", "Mavi Mintan", "Mavi Bazubands", "Mavi Tayt", "Mavi Basmak"},
    COR = {"Navarch's Tricorne", "Navarch's Frac", "Navarch's Gants", "Navarch's Culottes", "Navarch's Bottes"},
    PUP = {"Cirque Cappello", "Cirque Farsetto", "Cirque Guanti", "Cirque Pantaloni", "Cirque Scarpe"},
    DNC = {"Charis Tiara", "Charis Casaque", "Charis Bangles", "Charis Tights", "Charis Toe Shoes"},
    SCH = {"Savant's Bonnet", "Savant's Gown", "Savant's Bracers", "Savant's Pants", "Savant's Loafers"},
}

-- Equipment slot index (as in res.items[id].slots) -> name
upgrades.slots = {[4] = 'head', [5] = 'body', [6] = 'hands', [7] = 'legs', [8] = 'feet'}
upgrades.slot_order = {'head', 'body', 'hands', 'legs', 'feet'}

-- Old set -> iL109 at Monisette. One game day. Rem's Tale Ch.1-5 by slot.
local monisette = {npc = 'Monisette', zone = 'Port Jeuno (I-8)'}
local il109_slot_item = {head = 'Phoenix Feather', body = 'Malboro Fiber', hands = 'Beetle Blood', legs = 'Damascene Cloth', feet = 'Oxblood'}

upgrades.artifact109 = {
    npc = monisette.npc, zone = monisette.zone,
    tales = {[0] = 10, [1] = 5}, -- Rem's Tales for an NQ or +1 piece
    chapter = {head = 1, body = 2, hands = 3, legs = 4, feet = 5},
    slot_item = il109_slot_item,
    job_item = {
        WAR = 'Tiger Leather', BST = 'Tiger Leather',
        MNK = 'Gold Thread', THF = 'Gold Thread', DNC = 'Gold Thread',
        WHM = 'Imp. Silk Cloth', BRD = 'Imp. Silk Cloth', BLU = 'Imp. Silk Cloth',
        BLM = 'Karakul Cloth', RNG = 'Karakul Cloth', COR = 'Karakul Cloth', PUP = 'Karakul Cloth',
        RDM = 'Scarlet Linen', SMN = 'Scarlet Linen', SCH = 'Scarlet Linen',
        PLD = 'Gold Sheet', DRG = 'Gold Sheet',
        DRK = 'Darksteel Sheet',
        SAM = 'Tama-Hagane', NIN = 'Tama-Hagane',
    },
    note = 'Needs Promathia Mission 7-5, then a chat with Sagheera ("Just wanted to chat").',
}

-- Each old Relic piece goes straight to iL109; lower starting pieces cost more Dynamis currency.
-- An augmented +2 costs the same as a plain one.
upgrades.relic109 = {
    npc = monisette.npc, zone = monisette.zone,
    tales = 10,
    chapter = {head = 1, body = 2, hands = 3, legs = 4, feet = 5},
    slot_item = il109_slot_item,
    currency_count = {[0] = 2, [1] = 1, [2] = 0}, -- for an NQ, +1 or +2 piece
    currency = {
        WAR = '100 Byne Bill', MNK = '100 Byne Bill', DRK = '100 Byne Bill', BRD = '100 Byne Bill',
        SAM = '100 Byne Bill', NIN = '100 Byne Bill', COR = '100 Byne Bill', SCH = '100 Byne Bill',
        WHM = 'M. Silverpiece', RDM = 'M. Silverpiece', PLD = 'M. Silverpiece', DRG = 'M. Silverpiece',
        BLU = 'M. Silverpiece', DNC = 'M. Silverpiece',
        BLM = 'L. Jadeshell', THF = 'L. Jadeshell', BST = 'L. Jadeshell', RNG = 'L. Jadeshell',
        SMN = 'L. Jadeshell', PUP = 'L. Jadeshell',
    },
    job_item = {
        WAR = 'Wootz Ore', PLD = 'Wootz Ore', DRK = 'Wootz Ore',
        MNK = 'Griffon Hide', RDM = 'Griffon Hide', THF = 'Griffon Hide', BRD = 'Griffon Hide',
        RNG = 'Griffon Hide', DRG = 'Griffon Hide', BLU = 'Griffon Hide',
        WHM = 'Sparkling Stone', BLM = 'Sparkling Stone', COR = 'Sparkling Stone',
        BST = 'Mammoth Tusk', DNC = 'Mammoth Tusk',
        SAM = 'Relic Iron', NIN = 'Relic Iron',
        SMN = 'Lancewood Log', PUP = 'Lancewood Log', SCH = 'Lancewood Log',
    },
}

-- Old Empyrean +1/+2 -> iL109 at Monisette. One game day. Rem's Tale Ch.1-5 by slot.
upgrades.empyrean109 = {
    npc = monisette.npc, zone = monisette.zone,
    tales = {[1] = 10, [2] = 5}, -- Rem's Tales for a +1 or +2 piece
    chapter = {head = 1, body = 2, hands = 3, legs = 4, feet = 5},
    slot_item = il109_slot_item,
    job_item = {
        WAR = 'Helm of Briareus', DRK = 'Helm of Briareus',
        MNK = 'Itzpapa. Scale',
        WHM = "Orthrus's Claw",
        BLM = 'Glavoid Shell',
        RDM = 'Cirein. Lantern',
        THF = "Alfard's Fang",
        PLD = "Kukulkan's Fang",
        BST = "Carabosse's Gem", SMN = "Carabosse's Gem", PUP = "Carabosse's Gem",
        BRD = "Dragua's Scale",
        RNG = "Ulhuadshi's Fang",
        SAM = 'Apademak Horn',
        NIN = "Bukhis's Wing",
        DRG = "Azdaja's Horn",
        BLU = "Isgebind's Heart",
        COR = "Sobek's Skin",
        DNC = 'Two-Leaf Chloris Bud',
        SCH = "Sedna's Tusk",
    },
}

-- iL109 -> +1 at Monisette. One game day. Rem's Tale Ch.6-10 by slot.
upgrades.artifact1 = {
    npc = monisette.npc, zone = monisette.zone,
    tales = 8,
    chapter = {head = 6, body = 7, hands = 8, legs = 9, feet = 10},
    slot_item = {head = 'Maliyakaleya Orb', body = 'Hepatizon Ingot', hands = 'Beryllium Ingot', legs = 'Exalted Lumber', feet = "Sif's Macrame"},
    job_item = {
        WAR = 'Behem. Leather', BST = 'Behem. Leather',
        MNK = 'Platinum Silk', THF = 'Platinum Silk', DNC = 'Platinum Silk',
        WHM = 'Raxa', BRD = 'Raxa', BLU = 'Raxa', GEO = 'Raxa',
        BLM = 'Twill Damask', RNG = 'Twill Damask', COR = 'Twill Damask', PUP = 'Twill Damask',
        RDM = "Siren's Hair", SMN = "Siren's Hair", SCH = "Siren's Hair",
        PLD = 'Orichalcum Sheet', DRG = 'Orichalcum Sheet',
        DRK = 'Durium Sheet',
        SAM = 'Damascus Ingot', NIN = 'Damascus Ingot', RUN = 'Damascus Ingot',
    },
}

upgrades.relic1 = {
    npc = monisette.npc, zone = monisette.zone,
    tales = 8,
    chapter = {head = 6, body = 7, hands = 8, legs = 9, feet = 10},
    slot_item = {head = 'Gabbrath Horn', body = 'Yggdreant Bole', hands = 'Bztavian Stinger', legs = 'Waktza Rostrum', feet = 'Rockfin Tooth'},
    job_item = {
        WAR = 'Voidwrought Plate', NIN = 'Voidwrought Plate', DRG = 'Voidwrought Plate',
        MNK = "Kaggen's Cuticle", THF = "Kaggen's Cuticle", BRD = "Kaggen's Cuticle", COR = "Kaggen's Cuticle",
        WHM = "Akvan's Pennon", BLM = "Akvan's Pennon", SCH = "Akvan's Pennon", GEO = "Akvan's Pennon",
        RDM = "Pil's Tuille", PLD = "Pil's Tuille", DRK = "Pil's Tuille", SAM = "Pil's Tuille", BLU = "Pil's Tuille",
        BST = "Hahava's Mail", SMN = "Hahava's Mail", PUP = "Hahava's Mail",
        RNG = "Celaeno's Cloth", DNC = "Celaeno's Cloth", RUN = "Celaeno's Cloth",
    },
}

-- Empyrean iL109 -> +1 at Monisette. One game day. The same for every job.
upgrades.empyrean1 = {
    npc = monisette.npc, zone = monisette.zone,
    tales = 8,
    chapter = {head = 6, body = 7, hands = 8, legs = 9, feet = 10},
    memories = {head = 15, body = 25, hands = 15, legs = 20, feet = 15}, -- Etched Memory
    slot_item = {head = 'Defiant Sweat', body = 'Dark Matter', hands = 'Macuil Horn', legs = 'Tartarian Chain', feet = 'Plovid Effluvium'},
    note = "Needs The Truth Beckons, and the slot's Vagary boss beaten "
        .. '(head Palloritus, body Plouton, hands Putraxia, legs Perfidien, feet Rancibus).',
}

-- +1 -> +2: the job ingredient is the same for Artifact and Relic.
upgrades.plus2_job_item = {
    WAR = 'S. Faulpie Leather', BST = 'S. Faulpie Leather', RNG = 'S. Faulpie Leather',
    MNK = 'Cypress Log', THF = 'Cypress Log', DNC = 'Cypress Log',
    WHM = 'Khoma Thread', BRD = 'Khoma Thread', BLU = 'Khoma Thread', GEO = 'Khoma Thread',
    BLM = 'Azure Leaf', COR = 'Azure Leaf', PUP = 'Azure Leaf',
    RDM = 'Cyan Coral', SMN = 'Cyan Coral', SCH = 'Cyan Coral',
    PLD = 'Ruthenium Ore', DRG = 'Ruthenium Ore',
    DRK = 'Niobium Ore', SAM = 'Niobium Ore', NIN = 'Niobium Ore', RUN = 'Niobium Ore',
}

-- Artifact +1 -> +2 at Coelestrox. One game day.
upgrades.artifact2 = {
    npc = 'Coelestrox', zone = 'Reisenjima',
    beads = 10,
    instant = 500, -- what the instant option costs; Reforge never picks it, it checks the menu shows this
    cards = {head = 4, body = 5, hands = 3, legs = 4, feet = 3},
    slot_item = {
        head = "Emperor Arthro's Shell", body = "Joyous's Moss", hands = "Imperator's Wing",
        legs = "Warblade Beak's Hide", feet = "Abyssdiver's Feather",
    },
}

-- Relic +1 -> +2 in Ru'Lude Gardens. One game day.
upgrades.relic2 = {
    npc = '??? (Aurix)', zone = "Ru'Lude Gardens (G-8)",
    shards = 2,
    slot_item = upgrades.relic1.slot_item,
}

-- Artifact +2 -> +3 at Coelestrox. Two trades, a game day apart.
-- Stopping partway loses everything already traded.
upgrades.artifact3 = {
    npc = 'Coelestrox',
    zone = 'Reisenjima',
    zone_id = 291,
    -- Escha Beads for the normal (wait a day) option, confirmed from the NPC's menu for both days (GEO, 2026-10-27).
    beads = {day1 = 200, day2 = 300},
    -- What the instant option would cost. Reforge never picks it; it checks the menu shows these numbers.
    instant = {day1 = 10000, day2 = 15000},
    -- Day 1: the +2 piece, P. cards for its job and the job's scale.
    -- Card counts are the same for every job since the May 2025 reduction.
    cards = {head = 12, body = 15, hands = 9, legs = 12, feet = 9},
    scale = {
        WAR = "Kin's Scale", MNK = "Kin's Scale", PLD = "Kin's Scale", DRK = "Kin's Scale", SAM = "Kin's Scale",
        THF = "Gin's Scale", NIN = "Gin's Scale", DNC = "Gin's Scale", RUN = "Gin's Scale",
        WHM = "Kei's Scale", BLM = "Kei's Scale", RDM = "Kei's Scale", BLU = "Kei's Scale", SCH = "Kei's Scale",
        BRD = "Kyou's Scale", RNG = "Kyou's Scale", COR = "Kyou's Scale", GEO = "Kyou's Scale",
        BST = "Fu's Scale", DRG = "Fu's Scale", SMN = "Fu's Scale", PUP = "Fu's Scale",
    },
    -- Day 2: crafted materials and Cyan Orbs, the same for every job. Feet confirmed for GEO on 2026-10-27.
    day2 = {
        head = {{'Khoma Cloth', 1}, {'S. Faulpie Leather', 1}, {'Cyan Orb', 2}},
        body = {{'Niobium Ingot', 1}, {'Cypress Lumber', 1}, {'Cyan Orb', 3}},
        hands = {{'Faulpie Leather', 3}, {'Cypress Log', 1}, {'Cyan Orb', 1}},
        legs = {{'Ruthenium Ingot', 1}, {'Cypress Lumber', 1}, {'Cyan Orb', 2}},
        feet = {{'Azure Cermet', 3}, {'Khoma Thread', 1}, {'Cyan Orb', 1}},
    },
}

-- Relic +2 -> +3 in Ru'Lude Gardens. Takes one game day.
-- Shards and voids are named per slot and job, e.g. "Footshard: GEO" and "Voidfoot: GEO".
-- The wiki says these counts were reduced in May 2025 but doesn't give the new ones.
upgrades.relic3 = {
    npc = '??? (Aurix)',
    zone = "Ru'Lude Gardens (G-8)",
    count = 2,
    shard = {head = 'Headshard', body = 'Torsoshard', hands = 'Handshard', legs = 'Legshard', feet = 'Footshard'},
    void = {head = 'Voidhead', body = 'Voidtorso', hands = 'Voidhand', legs = 'Voidleg', feet = 'Voidfoot'},
    material = {head = 'Defiant Scarf', body = "Hades' Claw", hands = 'Macuil Plating', legs = 'Tartarian Soul', feet = 'Plovid Flesh'},
}

-- Empyrean +1 -> +2 at Ruspix. One game day.
upgrades.empyrean2 = {
    npc = 'Ruspix',
    zone = 'Leafallia (H-8)',
    items = {{"Ra'Kaz. Sapphire", 1}},
    currency = {'Gallimaufry', 10000},
    note = 'Needs The Light Within, and a Sortie visit on that job.',
}

-- Empyrean +2 -> +3 at Ruspix. Unknown whether there is a day wait.
upgrades.empyrean3 = {
    npc = 'Ruspix',
    zone = 'Leafallia (H-8)',
    items = {{"Ra'Kaz. Starstone", 1}},
    currency = {'Gallimaufry', 70000},
}

return upgrades
