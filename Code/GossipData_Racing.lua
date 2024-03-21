local _, addon = ...
if not addon.IsToCVersionEqualOrNewerThan(100000) then return end;

local DataSource = CreateFrame("Frame");

function DataSource:OnInteractWithNPC(npcName)
    if self:IsDragonRacingNPC(npcName) then
        self:SetScript("OnEvent", self.OnEvent);
        self:RegisterUnitEvent("UNIT_AURA", "player");
        self:ResetQueryCounter();
        self:UpdateRaceTimesFromAura();
        self.active = true;
    else
        self.active = false;
    end
end

function DataSource:OnInteractStopped()
    if self.active then
        self:PostDataFullyRetrieved();
    end
end

function DataSource:SetupTooltipByGossipOptionID(tooltip, gossipOptionID)
    return false
end

function DataSource:OnEvent(event)
    if event == "UNIT_AURA" then
        self:UpdateRaceTimesFromAura();
    end
end

addon.GossipDataProvider:AddDataSource(DataSource);


local match = string.match;
local RACE_TIMES = "^Race Times";
local NPC_NAME1 = "Bronze Timekeeper";
local NPC_NAME2 = " ";

local RankIcons = {
    [1] = "Interface/AddOns/DialogueUI/Art/Icons/Racing-Gold.png",
    [2] = "Interface/AddOns/DialogueUI/Art/Icons/Racing-Silver.png",
    [3] = "Interface/AddOns/DialogueUI/Art/Icons/Racing-Bronze.png",
    [4] = "Interface/AddOns/DialogueUI/Art/Icons/Racing-None.png",
};

function DataSource:IsDragonRacingNPC(npcName)
    return npcName == NPC_NAME1
end


function DataSource:IsDragonRacingNPC_Variants(npcName)
    return npcName == NPC_NAME1 or npcName == NPC_NAME2
end

do
    local locale = GetLocale();

    if locale == "enUS" then
        RACE_TIMES = "^Race Times";
        NPC_NAME1 = "Bronze Timekeeper";

    elseif locale == "esMX" then
        RACE_TIMES = "^Tiempos de la carrera";
        NPC_NAME1 = "Cronometradora bronce";

    elseif locale == "ptBR" then
        RACE_TIMES = "^Tempos da Corrida";
        NPC_NAME1 = "Guarda-tempo Bronze";

    elseif locale == "frFR" then
        RACE_TIMES = "^Temps des courses";
        NPC_NAME1 = "Chronométreuse de bronze";
        NPC_NAME2 = "Chronométreur de bronze";
        DataSource.IsDragonRacingNPC = DataSource.IsDragonRacingNPC_Variants;

    elseif locale == "deDE" then
        RACE_TIMES = "^Rennzeiten";
        NPC_NAME1 = "Bronzezeithüter";
        NPC_NAME2 = "Bronzezeithüterin";
        DataSource.IsDragonRacingNPC = DataSource.IsDragonRacingNPC_Variants;

    elseif locale == "esES" then
        RACE_TIMES = "^Tiempos de carrera";
        NPC_NAME1 = "Vigilante del tiempo bronce";

    elseif locale == "itIT" then
        RACE_TIMES = "^Tempi della Corsa";
        NPC_NAME1 = "Custode del Tempo Bronzea";

    elseif locale == "ruRU" then
        RACE_TIMES = "^Время гонки";
        NPC_NAME1 = "Бронзовая хранительница времени";

    elseif locale == "koKR" then
        RACE_TIMES = "^경주 시간";
        NPC_NAME1 = "청동 시간지기";

    elseif locale == "zhTW" then
        RACE_TIMES = "^競賽時間";
        NPC_NAME1 = "青銅時空守衛者";

    elseif locale == "zhCN" then
        RACE_TIMES = "^竞速时间";
        NPC_NAME1 = "青铜时光守护者";
    end
end


local function UpdateGossipIcons(ranks)
    local f = addon.DialogueUI;

    if not f:IsShown() then return end;

    local optionButtons = f.optionButtonPool:GetActiveObjects();
    for i = 1, #ranks do
        if optionButtons[i] then
            optionButtons[i].Icon:SetTexture(RankIcons[ranks[i]]);
        end
    end
end

local function ProcessLines(...)
    local n = select('#', ...);
    local i = 1;
    local line, medal;
    local ranks = {};
    local k = 1;
    local rankID;

    while i < n do
        line = select(i, ...);

        if match(line, "[Cc][Ff][Ff][Ff][Ff][Dd]100") then  --title: Normal, Advanced, Reverse, etc.
            i = i + 1;  --player record follows the title
            line = select(i, ...);
            medal = match(line, "medal%-small%-(%a+)");
            if medal then
                if medal == "gold" then
                    rankID = 1;
                elseif medal == "silver" then
                    rankID = 2;
                elseif medal == "bronze" then
                    rankID = 3;
                else
                    rankID = 4;
                end
            else
                --No Attempts
                rankID = 4;
                i = i + 1;  --Gold time follows player record (if not reached gold)
            end
            ranks[k] = rankID;
            k = k + 1;
        end
        i = i + 1;
    end

    if k == 1 then
        --print("No Data")
        DataSource:QueryAuraTooltipInto();
    else
        UpdateGossipIcons(ranks);
        DataSource:QueryAuraTooltipInto();    --Sometimes the tooltip data is partial so we keep querying x times
        --DataSource:PostDataFullyRetrieved();
    end
end

local function ProcessAuraByAuraInstanceID(auraInstanceID)
    local info = C_TooltipInfo.GetUnitBuffByAuraInstanceID("player", auraInstanceID);
    if info and info.lines and info.lines[2] then
        ProcessLines( string.split("\r", info.lines[2].leftText) );
    else
        --Tooltip data not ready
        DataSource:QueryAuraTooltipInto(auraInstanceID)
    end
end

local function EL_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.25 then
        self.t = 0;
        self.queryTimes = self.queryTimes + 1;
        self:SetScript("OnUpdate", nil);

        if self.auraInstanceID then
            ProcessAuraByAuraInstanceID(self.auraInstanceID);
        end
    end
end

function DataSource:ResetQueryCounter()
    self.queryTimes = 0;
end

function DataSource:QueryAuraTooltipInto(auraInstanceID)
    if self.queryTimes >= 6 then
        self:PostDataFullyRetrieved();
        return
    end

    self.t = 0;
    if auraInstanceID then
        self.auraInstanceID = auraInstanceID;
    end
    self:SetScript("OnUpdate", EL_OnUpdate);
end

function DataSource:PostDataFullyRetrieved()
    self.auraInstanceID = nil;
    self:UnregisterEvent("UNIT_AURA");
    self:SetScript("OnUpdate", nil);
    self:SetScript("OnEvent", nil);
end



local function ProcessFunc(auraInfo)
    if auraInfo.icon == 237538 then
        --API.SaveLocalizedText(auraInfo.name);
        if string.find(auraInfo.name, RACE_TIMES) then
            ProcessAuraByAuraInstanceID(auraInfo.auraInstanceID);
            return true
        end
    end
end


function DataSource:UpdateRaceTimesFromAura()
    local unit = "player";
    local filter = "HELPFUL";
    local usePackedAura = true;

    AuraUtil.ForEachAura(unit, filter, nil, ProcessFunc, usePackedAura);
end