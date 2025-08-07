local VERSION_TEXT = "v0.6.7";
local VERSION_DATE = 1754000000;


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
    FontText = "default",
    FontNumber = "default",
    FrameOrientation = 2,                       --1:Left  2:Right(Default)
    HideUI = true,
        ShowChatWindow = true,
        HideOutlineSparkles = true,
        HideUnitNames = false,
    ShowCopyTextButton = false,
    ShowNPCNameOnPage = false,
    MarkHighestSellPrice = false,
    QuestTypeText = false,
    SimplifyCurrencyReward = false,
    UseRoleplayName = false,
    UseBlizzardTooltip = false,

    CameraMovement = 1,                         --0:OFF  1:Zoom-In  2:Horizontal
    CameraChangeFov = true,
    CameraMovement1MaintainPosition = false,
    CameraMovement2MaintainPosition = true,
    CameraMovementMountedCamera = true,
    CameraMovementDisableInstance = false,
    CameraZoomMultiplier = 1,                   --The smaller the further

    InputDevice = 1,                            --1:K&M  2:XBOX  3.PS  4.Mobile
    UseCustomBindings = false,
    PrimaryControlKey = 1,                      --1: Space  2:Interact Key
    ScrollDownThenAcceptQuest = false,
    EscapeToDeclineQuest = false,
    RightClickToCloseUI = true,
    CycleRewardHotkeyEnabled = false,           --Press Tab to cycle through choosable rewards
    DisableHotkeyForTeleport = false,           --Disable gossip hotkey when select teleportation
    GamePadClickFirstObject = false,            --If true, when starting a new interaction, pressing PAD1 will click the first object
    EmulateSwipe = true,
    MobileDeviceMode = false,

    WidgetManagerDummy = true,                  --Doesn't control anything, used as a trigger
    AutoQuestPopup = true,
    QuestItemDisplay = false,
        QuestItemDisplayHideSeen = false,
        QuestItemDisplayDynamicFrameStrata = false,
    QuickSlotQuestReward = false,
    AutoCompleteQuest = false,
        QuickSlotUseHotkey = true,
    AutoSelectGossip = false,
    ForceGossip = false,
        ForceGossipSkipGameObject = false,
    ShowDialogHint = true,
    DisableDUIInInstance = false,

    NameplateDialogEnabled = false,             --Experimental. Not in the settings

    DisableUIMotion = false,

    TTSEnabled = false,
        TTSUseHotkey = true,    --Default key R
        TTSAutoPlay = false,
            TTSSkipRecent = false,              --Skip recently read texts
            TTSAutoPlayDelay = false,           --Add a delay before starting auto play in case the NPC is speaking
        TTSAutoStop = true,     --Stop when leaving
        TTSStopOnNew = true,    --Stop when reading new quest
        TTSVoiceMale = 0,       --0: System default
        TTSVoiceFemale = 0,
        TTSUseNarrator = false,
            TTSVoiceNarrator = 0,
        TTSVolume = 10,
        TTSRate = 0,
            TTSContentSpeaker = false,
            TTSContentQuestTitle = true,
            TTSContentObjective = false,

    --Book Settings
    BookUIEnabled = true,
        BookUISize = 1,
        BookKeepUIOpen = false,
        BookShowLocation = false,
        BookUIItemDescription = false,      --Show source item's description on top of the UI
        BookDarkenScreen = true,
        BookTTSVoice = 0,
        BookTTSClickToRead = true,

    --Not shown in the Settings. Accessible by other means
    TooltipShowItemComparison = false,          --Tooltip
    TTSReadTranslation = false,                 --Read original text or translation. Controlled by TTSButton modifier key

    --WidgetManagerPosition = {x, y};
    --QuestItemDisplayPosition = {x, y};


    --Deprecated:
    --WarbandCompletedQuest = true,         --Always ON
};

local InheritExistingValues = {
    --Newly added systems may copy the the dbValue of similar system: BookUI/DialogueUI frame size, Book/Dialogue voice
    --If the new dbValue doesn't exisit and the existing dbValue isn't the default value, use the new default value
    {"BookUISize", "FrameSize"},
    {"BookTTSVoice", "TTSVoiceNarrator"},
    {"BookTTSVoice", "TTSVoiceMale"},
    {"BookTTSVoice", "TTSVoiceFemale"},
};

local TutorialFlags = {
    --Saved in the DB, prefix: Tutorial_
    --e.g. Tutorial_OpenSettings = true
    "OpenSettings",
    "WarbandCompletedQuest",
};

local function GetDBValue(dbKey)
    return DB[dbKey]
end
addon.GetDBValue = GetDBValue;

local function SetDBValue(dbKey, value, userInput)
    DB[dbKey] = value;
    addon.CallbackRegistry:Trigger("SettingChanged."..dbKey, value, userInput);
end
addon.SetDBValue = SetDBValue;

local function LoadTutorials()
    --Tutorial Flags (nil means haven't shown)

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

    for _, v in ipairs(InheritExistingValues) do
        if DB[v[1]] == nil then
            if DB[v[2]] ~= nil and DB[v[2]] ~= DefaultValues[v[2]] then
                DB[v[1]] = DB[v[2]];
            end
        end
    end

    for dbKey, defaultValue in pairs(DefaultValues) do
        --Some settings are inter-connected so we load all values first
        if DB[dbKey] == nil or type(DB[dbKey]) ~= type(defaultValue) then
            DB[dbKey] = defaultValue;
        end
    end

    for dbKey, defaultValue in pairs(DefaultValues) do
        SetDBValue(dbKey, DB[dbKey]);
    end

    if not DB.installTime or type(DB.installTime) ~= "number" then
        DB.installTime = VERSION_DATE;
    end

    DefaultValues = nil;
    InheritExistingValues = nil;

    LoadTutorials();

    addon.CallbackRegistry:Trigger("ADDON_LOADED", DB);
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

    addon.IS_CLASSIC = not IsToCVersionEqualOrNewerThan(100000);
    addon.IS_CATA = currentToCVersion >= 40400 and currentToCVersion < 50000;
end


local function GetDBBool(dbKey)
    if DB then
        return DB[dbKey] == true
    end
end
addon.GetDBBool = GetDBBool;


local function FlipDBBool(dbKey, userInput)
    if DB then
        SetDBValue(dbKey, not GetDBBool(dbKey), userInput)
    end
end
addon.FlipDBBool = FlipDBBool;


local function IsDBValue(dbKey, value)
    if DB then
        return DB[dbKey] == value
    end
end
addon.IsDBValue = IsDBValue;


local function ResetTutorials()
    for _, flag in pairs(TutorialFlags) do
        local dbKey = "Tutorial_"..flag;
        DB[dbKey] = nil;
    end
end
addon.ResetTutorials = ResetTutorials;




do
    DialogueUIAPI = {};
end