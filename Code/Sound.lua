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

local SOUND_KIT = {
    ["SOUNDKIT.IG_QUEST_LIST_OPEN"] = SOUNDKIT.IG_QUEST_LIST_OPEN,
};

local function PlaySound(name)
    if SOUNDS[name] then
        PlaySoundFile(PATH..SOUNDS[name]);
    elseif SOUND_KIT[name] then
        PlaySoundKit(SOUND_KIT[name])
    end
end

addon.PlaySound = PlaySound;