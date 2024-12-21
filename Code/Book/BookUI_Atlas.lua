--Manually define WoW textures used in the book that doesn't have TexCoord (Artifact Book)

local _, addon = ...

local unpack = unpack;
local BookComponent = addon.BookComponent;
local Atlas = {};
local TextureSize = {};

local function CalculateCoord(file, ratio, width, height, left, right, top, bottom)
    --ratio: height / width
    Atlas[file] = {ratio, left/width, right/width, top/height, bottom/height};
end

function BookComponent:GetTextureCoordForFile(file)
    if Atlas[file] then
        return unpack(Atlas[file])
    end
end

function BookComponent:GetTextureSize(file)
    if TextureSize[file] then
        return TextureSize[file][1], TextureSize[file][2]
    end
end

do  --Artifact Book
    --interface/pictures/artifactbook
    local WIDTH, HEIGHT = 512, 256;
    local PREFIX = "interface\\pictures\\artifactbook-";
    local Info = {
        --Name = {top, bottom} (px)

        ["warrior-scaleoftheearthwarder"] = {0, 178},
        ["warrior-stromkar"] ={24, 104},
        ["warrior-warswordsofthevalarjar"] ={12, 140},

        ["paladin-ashbringer"] = {18, 112},
        ["paladin-silverhand"] = {0, 138},
        ["paladin-truthguard"] = {0, 174},

        ["hunter-talonclaw"] = {0, 118},
        ["hunter-thasdorah"] = {0, 118},
        ["hunter-titanstrike"] = {24, 104},

        ["rogue-dreadblades"] = {0, 134},
        ["rogue-fangsofthedevourer"] = {0, 106},
        ["rogue-kingslayers"] = {14, 128},

        ["priest-lightswrath"] = {24, 130},
        ["priest-tuure"] = {24, 130},
        ["priest-xalatath"] = {0, 140},

        ["deathknight-apocalypse"] = {0, 128},
        ["deathknight-bladesofthefallenprince"] = {36, 106},
        ["deathknight-mawofthedamned"] = {0, 148},

        ["shaman-doomhammer"] = {0, 120},
        ["shaman-fistofraden"] = {4, 138},
        ["shaman-sharasdal"] = {6, 112},

        ["mage-aluneth"] = {0, 126},
        ["mage-ebonchill"] = {12, 78},
        ["mage-felomelorn"] = {10, 78},

        ["warlock-scepterofsargeras"] = {0, 140},
        ["warlock-skullofthemanari"] = {0, 162},
        ["warlock-ulthalesh"] = {0, 132},

        ["monk-fists"] = {8, 134},
        ["monk-fuzan"] = {0, 150},
        ["monk-sheilun"] = {0, 114},

        ["druid-ghanirthemothertree"] = {0, 120},
        ["druid-scytheofelune"] = {0, 160},
        ["druid-theclawsofursoc"] = {8, 134},
        ["druid-thefangsofashamane"] = {8, 136},

        ["demonhunter-thealdrachiwarblades"] = {0, 140},
        ["demonhunter-twinbladesofthedeceiver"] = {0, 134},
    };

    for k, v in pairs(Info) do
        CalculateCoord(PREFIX..k, ((v[2] -v[1])/WIDTH), WIDTH, HEIGHT, 0, WIDTH, v[1], v[2]);
    end
end

do  --PvPRankBadges, A Treatise on Military Ranks, Stormwind City  75, 68
    local CustomSize = {40, 40};
    local name;
    for i = 1, 14 do
        if i < 10 then
            name = "0"..i;
        else
            name = i;
        end
        TextureSize["interface\\pvprankbadges\\pvprank"..name] = CustomSize;
    end

    TextureSize["interface\\pvprankbadges\\pvprankalliance"] = {86, 100};
    TextureSize["interface\\pvprankbadges\\pvprankhorde"] = {86, 100};
end