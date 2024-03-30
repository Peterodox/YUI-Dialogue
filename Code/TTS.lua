local _, addon = ...

local TTSUtil = CreateFrame("Frame");
addon.TTSUtil = TTSUtil;


local TTS_AUTO_PLAY = false;
local TTS_STOP_WHEN_LEAVING = true;


local C_VoiceChat = C_VoiceChat;
local C_TTSSettings = C_TTSSettings;
local StopSpeakingText = C_VoiceChat.StopSpeakingText;

local TTSButton;

function TTSUtil:UpdateTTSSettings()
    self.voiceID = C_TTSSettings.GetVoiceOptionID(0);
    self.volume = C_TTSSettings.GetSpeechVolume();     --0 ~ 100 (Default: 100)
    self.rate = C_TTSSettings.GetSpeechRate();         -- -10 ~ +10 (Default: 0)
    self.destination = Enum.VoiceTtsDestination and Enum.VoiceTtsDestination.LocalPlayback or 1;

    if self.volume == 0 then
        
    end
end

function TTSUtil:OnUpdate_InitialDelay(elapsed)
    self.t = self.t + elapsed;
    if self.t > 0 then
        self.t = nil;
        self:SetScript("OnUpdate", nil);
        self:ProcessQueue();
    end
end

function TTSUtil:Clear()
    self.t = nil;
    self.queue = nil;
    self.nextText = nil;
    self:SetScript("OnUpdate", nil);
    StopSpeakingText();
end

function TTSUtil:ProcessQueue()
    if self.queue and #self.queue > 0 then
        local text = table.remove(self.queue, 1);
        self:StopThenPlay(text);
    else
        self:Clear();
    end
end

function TTSUtil:QueueText(text)
    if not self.queue then
        self.queue = {};
    end

    table.insert(self.queue, text);

    self.t = -0.75;
    self:SetScript("OnUpdate", self.OnUpdate_InitialDelay);
end

function TTSUtil:OnUpdate_StopThenPlay(elapsed)
    self.t = self.t + elapsed;
    if self.t > 0 then
        self.t = nil;
        self:SetScript("OnUpdate", nil);
        self:SpeakText(self.nextText);
    end
end

function TTSUtil:StopThenPlay(text)
    StopSpeakingText();
    self.t = -0.1;
    self.nextText = text;
    self:SetScript("OnUpdate", self.OnUpdate_StopThenPlay);
end

function TTSUtil:SpeakText(text)
    if not text then return end;

    self:UpdateTTSSettings();

    self:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_STARTED");
    C_VoiceChat.SpeakText(self.voiceID, text, self.destination, self.rate, self.volume);
end

function TTSUtil:SpeakCurrentContent()
    StopSpeakingText();
    local texts = addon.DialogueUI:GetContent();
    self:QueueText(texts);
end

function TTSUtil:IsSpeaking()
    return self.utteranceID ~= nil;
end

function TTSUtil:ToggleSpeaking()
    if self:IsSpeaking() then
        self:StopLastTTS();
    else
        self:SpeakCurrentContent();
    end
end

function TTSUtil:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...)
    end
end

function TTSUtil:VOICE_CHAT_TTS_PLAYBACK_STARTED(numConsumers, utteranceID, durationMS, destination)
    --durationMS is zero?
    self.utteranceID = utteranceID;
    self:UnregisterEvent("VOICE_CHAT_TTS_PLAYBACK_STARTED");
    self:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_FINISHED");
    if TTSButton then
        TTSButton.AnimWave:Play();
    end
end

function TTSUtil:VOICE_CHAT_TTS_PLAYBACK_FINISHED(numConsumers, utteranceID, destination)
    self.utteranceID = nil;
    self:UnregisterEvent("VOICE_CHAT_TTS_PLAYBACK_FINISHED");
    if TTSButton then
        TTSButton.AnimWave:Stop();
    end
end

function TTSUtil:StopLastTTS()
    if self.utteranceID then
        StopSpeakingText();
    end
end

function TTSUtil:EnableModule(state)
    if state then
        self.isEnabled = true;
        self:SetScript("OnEvent", self.OnEvent);
    elseif self.isEnabled then
        self.isEnabled = false;
        self:UnregisterEvent("VOICE_CHAT_TTS_PLAYBACK_STARTED");
        self:UnregisterEvent("VOICE_CHAT_TTS_PLAYBACK_FINISHED");
        self:SetScript("OnEvent", nil);
    end
end


do
    local function OnHandleEvent(event)
        if TTSUtil.isEnabled then
            TTSUtil:StopLastTTS();
            if TTS_AUTO_PLAY then
                TTSUtil:SpeakCurrentContent();
            end
        end
    end
    addon.CallbackRegistry:Register("DialogueUI.HandleEvent", OnHandleEvent);

    local function InteractionClosed()
        if TTSUtil.isEnabled and TTS_STOP_WHEN_LEAVING then
            TTSUtil:StopLastTTS();
        end
    end
    addon.CallbackRegistry:Register("DialogueUI.Hide", InteractionClosed);


    local function Settings_TTSEnabled(dbValue)
        TTSUtil:EnableModule(dbValue == true);
    end
    addon.CallbackRegistry:Register("SettingChanged.TTSEnabled", Settings_TTSEnabled);

    local function Settings_TTSAutoPlay(dbValue)
        TTS_AUTO_PLAY = dbValue == true;
    end
    addon.CallbackRegistry:Register("SettingChanged.TTSAutoPlay", Settings_TTSAutoPlay);

    local function Settings_TTSAutoStop(dbValue)
        TTS_STOP_WHEN_LEAVING = dbValue == true;
    end
    addon.CallbackRegistry:Register("SettingChanged.TTSAutoStop", Settings_TTSAutoStop);
end


do  --TTS Play Button
    local BUTTON_SIZE = 24;
    local ICON_SIZE = 16;
    local ALPHA_UNFOCUSED = 0.6;

    local TTSButtonMixin = {};
    
    local L = addon.L;

    function TTSButtonMixin:OnEnter()
        self:SetAlpha(1);
        local TooltipFrame = addon.SharedTooltip;
        TooltipFrame:Hide();
        TooltipFrame:SetOwner(self, "TOPRIGHT");
        TooltipFrame:SetTitle(L["TTS"], 1, 1, 1);

        if TTS_AUTO_PLAY then
            TooltipFrame:AddDoubleLine(L["TTS Auto Play"], L["Option Enabled"], 1, 1, 1, 0.098, 1.000, 0.098);
        else
            TooltipFrame:AddDoubleLine(L["TTS Auto Play"], L["Option Disabled"], 1, 1, 1, 1.000, 0.125, 0.125);
        end

        TooltipFrame:AddLeftLine(L["TTS Button Tooltip"], 1, 0.82, 0);
        TooltipFrame:Show();
    end

    function TTSButtonMixin:OnLeave()
        self:SetAlpha(ALPHA_UNFOCUSED);
        addon.SharedTooltip:Hide();
    end

    function TTSButtonMixin:SetTheme(themeID)
        local x;
        if themeID == 1 then
            x = 0;
        else
            x = 0.5;
        end
        self.Icon:SetTexCoord(0 + x, 0.5 + x, 0, 0.5);
        self.Wave1:SetTexCoord(0 + x, 0.125 + x, 0.5, 1);
        self.Wave2:SetTexCoord(0.125 + x, 0.3125 + x, 0.5, 1);
        self.Wave3:SetTexCoord(0.3125 + x, 0.5 + x, 0.5, 1);
    end

    function TTSButtonMixin:OnClick(button)
        if button == "LeftButton" then
            TTSUtil:ToggleSpeaking();
        elseif button == "RightButton" then
            addon.SetDBValue("TTSAutoPlay", not TTS_AUTO_PLAY);
            if self:IsMouseOver() then
                self:OnEnter();
            end

            addon.SettingsUI:RequestUpdate();
        end
    end

    local function CreateTTSButton(parent, themeID)
        if TTSButton then return TTSButton end;

        local b = CreateFrame("Button", nil, parent);
        b:SetSize(BUTTON_SIZE, BUTTON_SIZE);
        b:SetAlpha(ALPHA_UNFOCUSED);
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp");

        local file = "Interface/AddOns/DialogueUI/Art/Theme_Shared/TTSButton.png";

        b.Icon = b:CreateTexture(nil, "OVERLAY");
        b.Icon:SetSize(ICON_SIZE, ICON_SIZE);
        b.Icon:SetPoint("CENTER", b, "CENTER", 0, 0);
        b.Icon:SetTexture(file);
        b.Icon:SetSize(ICON_SIZE, ICON_SIZE);


        b.Wave1 = b:CreateTexture(nil, "OVERLAY");
        b.Wave1:SetSize(0.25*ICON_SIZE, ICON_SIZE);
        b.Wave1:SetPoint("LEFT", b, "RIGHT", -8, 0);
        b.Wave1:SetTexture(file);

        b.Wave2 = b:CreateTexture(nil, "OVERLAY");
        b.Wave2:SetSize(0.375*ICON_SIZE, ICON_SIZE);
        b.Wave2:SetPoint("LEFT", b.Wave1, "RIGHT", -3, 0);
        b.Wave2:SetTexture(file);

        b.Wave3 = b:CreateTexture(nil, "OVERLAY");
        b.Wave3:SetSize(0.375*ICON_SIZE, ICON_SIZE);
        b.Wave3:SetPoint("LEFT", b.Wave2, "RIGHT", -4, 0);
        b.Wave3:SetTexture(file);

        b.Wave1:Hide();
        b.Wave2:Hide();
        b.Wave3:Hide();

        b.AnimWave = b:CreateAnimationGroup(nil, "DUISpeakerAnimationTemplate");

        b.AnimWave:SetScript("OnPlay", function()
            b.Wave1:Show();
            b.Wave2:Show();
            b.Wave3:Show();
        end);
    
        b.AnimWave:SetScript("OnStop", function()
            b.Wave1:Hide();
            b.Wave2:Hide();
            b.Wave3:Hide();
        end);

        addon.API.Mixin(b, TTSButtonMixin);

        b:SetScript("OnClick", b.OnClick);
        b:SetScript("OnEnter", b.OnEnter);
        b:SetScript("OnLeave", b.OnLeave);

        b:SetTheme(themeID);

        TTSButton = b;

        return b
    end
    addon.CreateTTSButton = CreateTTSButton;
end