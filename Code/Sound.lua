local _, addon = ...

local PlaySoundFile = PlaySoundFile;
local PlaySoundKit = PlaySound;

--[[
local SoundPanel = CreateFrame("Frame");

function SoundPanel:OnUpdate(elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.1 then
        self.t = 0;
        self:Unlock();
    end
end

function SoundPanel:Start()
    if not self.isPlaying then
        self.isPlaying = true;
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate);
    end
end

function SoundPanel:Unlock()
    self.isPlaying = nil;
    self:SetScript("OnUpdate", nil);
end

--]]

local PATH = "Interface/AddOns/DialogueUI/Sound/";
local SOUNDS = {
    DIALOG_OPTION_CLICK = "paper-collect-1.mp3",
    DIALOG_OPTION_ENTER = "paper-collect-2.mp3",
    QUEST_TEXT_SHOW = "page-turn-1.mp3",
};

local SOUNDKIT = SOUNDKIT or {};
local SOUND_KIT = {
    ["SOUNDKIT.IG_QUEST_LIST_OPEN"] = SOUNDKIT.IG_QUEST_LIST_OPEN,
    ["CHECKBOX_ON"] = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON,
    ["CHECKBOX_OFF"] = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF,
};

local function PlaySound(name)
    if SOUNDS[name] then
        PlaySoundFile(PATH..SOUNDS[name]);
    elseif SOUND_KIT[name] then
        PlaySoundKit(SOUND_KIT[name])
    end
end
addon.PlaySound = PlaySound;


do  --Mute Target Lost Sound while interacting with NPC
    --https://wago.tools/db2/SoundKitEntry?filter[SoundKitID]=684&page=1&sort[SoundKitID]=asc
    --local soundKitID = (SOUNDKIT and SOUNDKIT.INTERFACE_SOUND_LOST_TARGET_UNIT) or 684;

    local SOUND_FILE_ID = 567520;
    local MuteSoundFile = MuteSoundFile;
    local UnmuteSoundFile = UnmuteSoundFile;

    local function MuteTargetLostSound()
        MuteSoundFile(SOUND_FILE_ID);
    end

    local function UnmuteTargetLostSound()
        UnmuteSoundFile(SOUND_FILE_ID);
    end

    addon.CallbackRegistry:Register("DialogueUI.Show", MuteTargetLostSound);
    addon.CallbackRegistry:Register("DialogueUI.Hide", UnmuteTargetLostSound);
end