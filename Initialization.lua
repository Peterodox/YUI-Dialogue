local VERSION_TEXT = "v0.2.7";
local VERSION_DATE = 1712505000;


local addonName, addon = ...

local L = {};       --Locale
local API = {};     --Custom APIs used by this addon
local DB;

addon.L = L;
addon.API = API;
addon.VERSION_TEXT = VERSION_TEXT;

local DefaultValues = {
    Theme = 1,
    FrameSize = 2,
    FontSizeBase = 1,
    HideUI = true,
    HideUnitNames = false,
    ShowCopyTextButton = false,
    ShowNPCNameOnPage = false,
    QuestTypeText = false,
    SimplifyCurrencyReward = false,
    MarkHighestSellPrice = false,
    UseRoleplayName = false,

    CameraMovement = 1,                         --0:OFF  1:Zoom-In  2:Horizontal
    CameraChangeFov = true,
    CameraMovement1MaintainPosition = false,
    CameraMovement2MaintainPosition = true,
    CameraMovementDisableInstance = false,

    InputDevice = 1,                            --1:K&M  2:XBOX  3.PS  4.Mobile
    PrimaryControlKey = 1,                      --1: Space  2:Interact Key
    ScrollDownThenAcceptQuest = false,

    QuestItemDisplay = false,
    QuestItemDisplayHideSeen = false,
    AutoSelectGossip = false,
    ForceGossip = false,
    NameplateDialogEnabled = false,

    TTSEnabled = false,
    TTSUseHotkey = true,    --Default key R
    TTSAutoPlay = false,
    TTSAutoStop = true,     --Stop when leaving

    --Not shown in the Settings. Accessible by other means
    TooltipShowItemComparison = false,          --Tooltip
    
    --QuestItemDisplayPosition = {x, y};
};

local TutorialFlags = {
    --Saved in the DB, prefix: Tutorial_
    --e.g. Tutorial_OpenSettings = true
    "OpenSettings",
};

local function GetDBValue(dbKey)
    return DB[dbKey]
end
addon.GetDBValue = GetDBValue;

local function SetDBValue(dbKey, value)
    DB[dbKey] = value;
    addon.CallbackRegistry:Trigger("SettingChanged."..dbKey, value);
end
addon.SetDBValue = SetDBValue;

local function LoadTutorials()
    --Tutorial Flags (false means haven't shown)

    for _, flag in pairs(TutorialFlags) do
        local dbKey = "Tutorial_"..flag;

        if DB[dbKey] == nil then
            addon.CallbackRegistry:Trigger("Tutorial."..flag);
        end
    end
end

local function LoadDatabase()
    DialogueUI_DB = DialogueUI_DB or {};
    DB = DialogueUI_DB;

    DialogueUI_Saves = DialogueUI_Saves or {};

    local type = type;

    for dbKey, defaultValue in pairs(DefaultValues) do
        if DB[dbKey] == nil or type(DB[dbKey]) ~= type(defaultValue) then
            SetDBValue(dbKey, defaultValue);
        else
            SetDBValue(dbKey, DB[dbKey]);
        end
    end

    if not DB.installTime or type(DB.installTime) ~= "number" then
        DB.installTime = VERSION_DATE;
    end

    DefaultValues = nil;

    LoadTutorials();
end

local function SetTutorialRead(tutorialFlag)
    local dbKey = "Tutorial_"..tutorialFlag;
    DB[dbKey] = true;
end
addon.SetTutorialRead = SetTutorialRead;


local EL = CreateFrame("Frame");
EL:RegisterEvent("ADDON_LOADED");
EL:RegisterEvent("PLAYER_ENTERING_WORLD");

EL:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            self:UnregisterEvent(event);
            LoadDatabase();
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        --Keybindings are loaded after this
        self:UnregisterEvent(event);

        local dbKey = "PrimaryControlKey";
        SetDBValue(dbKey, DB[dbKey]);

        addon.CallbackRegistry:Trigger("PLAYER_ENTERING_WORLD");
    end
end);


do
    local currentToCVersion = select(4, GetBuildInfo());
    if not currentToCVersion then
        print("API Changed: GetBuildInfo()")
        currentToCVersion = 999999;
    end
    currentToCVersion = tonumber(currentToCVersion);

    local function IsToCVersionEqualOrNewerThan(targetVersion)
        return currentToCVersion >= targetVersion
    end
    addon.IsToCVersionEqualOrNewerThan = IsToCVersionEqualOrNewerThan;
end