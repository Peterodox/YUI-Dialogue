local _, addon = ...
local GossipDataProvider = addon.GossipDataProvider;

local GossipData = {
    --[gossipOptionID] = true

    --A Time to Reflect, Historian Llore, Hint
    [46026] = true,    --Nefarion
    [46185] = true,    --Cro Threadstrong threats fruit vendor
    [41523] = true,    --Draconic Thank you, Belan shi
    [46069] = true,    --Tanaris
    [46080] = true,    --Not an orc clan
    [45687] = true,    --Jiang
    [45705] = true,    --Aliden, Syndicate
    [41706] = true,    --Mag'har
    [42162] = true,    --Titan lore-keeper, Norgannon
    [46134] = true,    --Bolvar Fordragon
    [42176] = true,    --May the bloodied crown stay lost and forgotten
    [46085] = true,    --Maiev
    [46194] = true,    --Broxigar
    [46202] = true,    --Taretha Foxton
    [46130] = true,    --Hillsbrad Foothills, Dalaran
    [41686] = true,    --Mur'ghoul
    [46010] = true,    --Vashj
    [46017] = true,    --Sha
    [41676] = true,    --Gelbin Mekkatorque
    [46225] = true,    --Dioniss aca
    [46175] = true,    --War of the Shifting Sands
    [46094] = true,    --Devilsaur
    [42086] = true,    --Mia Greymane
    [46106] = true,    --The Barrens
    [46004] = true,    --Quillboar
    [42166] = true,    --Veranus, Razorscale
    [46212] = true,    --You breathe fire
    [46001] = true,    --Warden
    [46139] = true,    --Alexandros
    [46219] = true,    --Right eye; left arm
    [41536] = true,    --Tatai
    [42179] = true,    --Xavius
    [46229] = true,    --Loque'nahak
    [41660] = true,    --Frostwolf clan
    [42220] = true,    --Mord'rethar
    [46019] = true,    --Blood Elves
    [46031] = true,    --the righteous one
    [46237] = true,    --Tyranastrasz
    [42032] = true,    --Sky'ree
    [46192] = true,    --Liu Lang
    [46155] = true,    --Copeland
    [46101] = true,    --Thandol Span
    [41711] = true,    --Blue dragonflight
    [46214] = true,    --Piccolo of the Flaming Fire
    [41683] = true,    --Cenarion Circle
    [46073] = true,    --Azshara, goblins
    [42026] = true,    --Acherus
    [46108] = true,    --Archmage Antonidas
    [42185] = true,    --K'aresh
    [46146] = true,    --Magtheridon
    [42156] = true,    --Mirador
    [46088] = true,    --Benedictus
    [45695] = true,    --Devoted Ones
    [46159] = true,    --Venture Company
    [42192] = true,    --Red Pox
    [41544] = true,    --Mueh'zala
    [46148] = true,    --Majordomo Staghelm
    [41674] = true,    --Archdruid
    [45699] = true,    --Argus Wake
    [42098] = true,    --Nobundo
    [46166] = true,    --Aedelas Blackmoore
    [46168] = true,    --Ner'zhul
    [46206] = true,    --Auberdine
    [46036] = true,    --A Luckydo

    [111323] = true,   --The Fourth War
    [111300] = true,   --Silithus, Sargeras
    [111295] = true,   --Draenei homeworld Argus
    [111346] = true,   --Vulpera visage, Majordomo Selistra
    [111340] = true,   --Rogue, Draka afterlife
    [111320] = true,   --Fuzzy, alpaca-driving nomads
    [111284] = true,   --Blackrock Clan
    [111290] = true,   --Prophet Velen
    [111308] = true,   --Fruit of the Arcan'dor, Nightfallen cure
    [111342] = true,   --Merithra
    [111302] = true,   --Lion's Rest
    [111330] = true,   --Ritual of absolution
    [111336] = true,   --Pelagos
    [111351] = true,   --Malygos
    [111327] = true,   --The Helm of Domination
    [111314] = true,   --Xal'atath
    [111278] = true,   --The blood of Mannoroth
    [111355] = true,   --Khan
    [111287] = true,   --Kairozdormu
    [111311] = true,    --Magni Bronzebeard
};

function GossipDataProvider:DoesOptionHaveHint(gossipOptionID)
    return GossipData[gossipOptionID]
end