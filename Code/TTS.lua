local _, addon = ...

local TTSUtil = CreateFrame("Frame");
addon.TTSUtil = TTSUtil;

local C_VoiceChat = C_VoiceChat;
local C_TTSSettings = C_TTSSettings;
local StopSpeakingText = C_VoiceChat.StopSpeakingText;

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

    if not self.voiceID then
        self:UpdateTTSSettings();
    end

    C_VoiceChat.SpeakText(self.voiceID, text, self.destination, self.rate, self.volume);
end

function TTSUtil:SpeakCurrentContent()
    StopSpeakingText();
    local gossipText = C_GossipInfo.GetText();
    self:QueueText(gossipText);
end

function TTSUtil:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...)
    end

    print(...)
end

function TTSUtil:VOICE_CHAT_TTS_PLAYBACK_STARTED(numConsumers, utteranceID, durationMS, destination)
    --durationMS is zero?
end

function TTSUtil:VOICE_CHAT_TTS_PLAYBACK_FINISHED(numConsumers, utteranceID, destination)

end


function TTSUtil:EnableModule(state)
    if state then
        self.isEnabled = true;
        self:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_STARTED");
        self:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_FINISHED");
        self:SetScript("OnEvent", self.OnEvent);
    elseif self.isEnabled then
        self.isEnabled = false;
        self:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_STARTED");
        self:UnregisterEvent("VOICE_CHAT_TTS_PLAYBACK_FINISHED");
        self:SetScript("OnEvent", nil);
    end
end

--TTSUtil:EnableModule(true);    --debug


do
    local function OnHandleEvent(event)
        print(event);
        TTSUtil:SpeakCurrentContent()
    end

    --addon.CallbackRegistry:Register("DialogueUI.HandleEvent", OnHandleEvent);
end