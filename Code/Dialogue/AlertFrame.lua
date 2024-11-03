local _, addon = ...
local L = addon.L;
local API = addon.API;

local GetTextReadingTime = API.GetTextReadingTime;
local SetTextColorByIndex = API.SetTextColorByIndex;
local GetTitleForQuestID = API.GetTitleForQuestID;

local GetLFGProposal = GetLFGProposal;

local UIErrorsFrame = UIErrorsFrame;

-- User Settings
local ALERT_FRAME_ENABLED = true;   --Disable when HideUI is disabled
------------------

local AlertFrame = CreateFrame("Frame");
addon.AlertFrame = AlertFrame;

AlertFrame:SetFrameStrata("DIALOG");
AlertFrame:SetFixedFrameStrata(true);
AlertFrame:SetSize(64, 12);

local FontString = AlertFrame:CreateFontString(nil, "OVERLAY", "DUIFont_AlertFont"); --Top right of the screen
FontString:SetPoint("TOPRIGHT", AlertFrame, "TOPRIGHT", 0, 0);
--FontString:SetText("1/1 Photo shared with Maurice") --Debug

local LFGAlert = CreateFrame("Frame", nil, AlertFrame);
LFGAlert.initialized = false;
LFGAlert:SetIgnoreParentAlpha(true);
LFGAlert:SetPoint("TOP", UIParent, "TOP", 0, -48);

local COLOR_YELLOW = 1;
local COLOR_GREEN = 3;
local COLOR_RED = 4;

local SUPPORTED_TYPES = {
    --https://warcraft.wiki.gg/wiki/API_GetGameMessageInfo
    --1: Ivory  3:Green  4:Red
    -- [LE_GAME_ or ] = 1,


    [LE_GAME_ERR_QUEST_ACCEPTED_S or 179] = COLOR_GREEN,
    [LE_GAME_ERR_QUEST_COMPLETE_S or 180] = COLOR_GREEN,
    [LE_GAME_ERR_QUEST_REWARD_EXP_I or 196] = COLOR_GREEN,
    [LE_GAME_ERR_QUEST_REWARD_MONEY_S or 197] = COLOR_GREEN;


    [LE_GAME_ERR_QUEST_OBJECTIVE_COMPLETE_S or 303] = COLOR_YELLOW,
    --[LE_GAME_ERR_QUEST_UNKNOWN_COMPLETE or 304] = COLOR_YELLOW,   --Objective Complete.
    [LE_GAME_ERR_QUEST_ADD_KILL_SII or 305] = COLOR_YELLOW,
    [LE_GAME_ERR_QUEST_ADD_FOUND_SII or 306] = COLOR_YELLOW,
    [LE_GAME_ERR_QUEST_ADD_ITEM_SII or 307] = COLOR_YELLOW,
    [LE_GAME_ERR_QUEST_ADD_PLAYER_KILL_SII or 308] = COLOR_YELLOW,
};

local QUEST_ERROR_TYPES = {
    [LE_GAME_ERR_QUEST_FAILED_S or 181] = true,
    [LE_GAME_ERR_QUEST_FAILED_BAG_FULL_S or 182] = true,
    [LE_GAME_ERR_QUEST_FAILED_MAX_COUNT_S or 183] = true,
    [LE_GAME_ERR_QUEST_FAILED_MISSING_ITEMS or 185] = true,
    [LE_GAME_ERR_QUEST_FAILED_NOT_ENOUGH_MONEY or 187] = true,
    [LE_GAME_ERR_QUEST_FAILED_EXPANSION or 188] = true,
    [LE_GAME_ERR_QUEST_ONLY_ONE_TIMED or 189] = true,
    [LE_GAME_ERR_QUEST_NEED_PREREQS or 190] = true,
    [LE_GAME_ERR_QUEST_NEED_PREREQS_CUSTOM or 191] = true,
    [LE_GAME_ERR_QUEST_ALREADY_ON or 192] = true,
    [LE_GAME_ERR_QUEST_ALREADY_DONE or 193] = true,
    [LE_GAME_ERR_QUEST_ALREADY_DONE_DAILY or 194] = true,
    [LE_GAME_ERR_QUEST_LOG_FULL or 199] = true,
    [LE_GAME_ERR_QUEST_FAILED_TOO_MANY_DAILY_QUESTS_I or 629] = true,
    [LE_GAME_ERR_QUEST_FORCE_REMOVED_S or 844] = true,
    [LE_GAME_ERR_QUEST_FAILED_SPELL or 858] = true,
    [LE_GAME_ERR_QUEST_TURN_IN_FAIL_REASON or 1040] = true,
};
addon.QUEST_ERROR_TYPES = QUEST_ERROR_TYPES;

for k in pairs(QUEST_ERROR_TYPES) do
    SUPPORTED_TYPES[k] = COLOR_RED;
end


function AlertFrame:OnShow()
    self:RegisterEvent("UI_ERROR_MESSAGE");
    self:RegisterEvent("UI_INFO_MESSAGE");
    self:RegisterEvent("QUEST_ACCEPTED");
    self:RegisterEvent("QUEST_TURNED_IN");
    self:RegisterEvent("LFG_PROPOSAL_SHOW");
    self:RegisterEvent("LFG_PROPOSAL_DONE");
    self:RegisterEvent("LFG_PROPOSAL_FAILED");
end

function AlertFrame:OnHide()
    self:Clear();
    self:UnregisterEvent("UI_ERROR_MESSAGE");
    self:UnregisterEvent("UI_INFO_MESSAGE");
    self:UnregisterEvent("QUEST_ACCEPTED");
    self:UnregisterEvent("QUEST_TURNED_IN");
    self:UnregisterEvent("LFG_PROPOSAL_SHOW");
    self:UnregisterEvent("LFG_PROPOSAL_DONE");
    self:UnregisterEvent("LFG_PROPOSAL_FAILED");
end

function AlertFrame:OnEvent(event, ...)
    if not ALERT_FRAME_ENABLED then return end;

    if event == "UI_INFO_MESSAGE" then
        self:TryDisplayMessage(...);
    elseif event == "UI_ERROR_MESSAGE" then
        self:TryDisplayMessage(...);
    elseif event == "QUEST_ACCEPTED" then
        local questID, classicQuestID = ...
        if classicQuestID and classicQuestID ~= 0 then
            questID = classicQuestID;
        end
        if API.ShouldShowQuestAcceptedAlert(questID) then   --Emissary Quests (LEG, BFA) are auto accepted upon login
            self:DisplayQuestMessage(questID, L["Format Quest Accepted"], COLOR_YELLOW);
        end
    elseif event == "QUEST_TURNED_IN" then
        local questID, xpReward, moneyReward = ...
        self:DisplayQuestMessage(questID, L["Format Quest Completed"], COLOR_GREEN);
    elseif event == "LFG_PROPOSAL_SHOW" then
        self:OnLFGProposal();
    elseif event == "LFG_PROPOSAL_DONE" or event == "LFG_PROPOSAL_FAILED" then
        self:HideLFGDialog();
    end
end

AlertFrame:SetScript("OnShow", AlertFrame.OnShow);
AlertFrame:SetScript("OnHide", AlertFrame.OnHide);
AlertFrame:SetScript("OnEvent", AlertFrame.OnEvent);

function AlertFrame:TryDisplayMessage(messageType, message, r, g, b)
    local colorIndex = messageType and SUPPORTED_TYPES[messageType];
    if colorIndex then
        self:QueueMessage(message, colorIndex);
    end
end

function AlertFrame:Clear(alsoClearDefaultUI)
    if self.queue then
        self.queue = nil;
        self.t = nil;
        self.current = nil;
        self.total = nil;
        self:SetScript("OnUpdate", nil);
        FontString:SetText(nil);
        self:SetAlpha(0);

        if alsoClearDefaultUI and UIErrorsFrame then
            UIErrorsFrame:Clear();
        end
    end
end

function AlertFrame:OnUpdate_OnHold(elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0 then
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate_FadeOut);
    end
end

function AlertFrame:OnUpdate_FadeIn(elapsed)
    self.t = self.t + elapsed;
    local alpha = self.t * 4;

    if alpha < 0 then
        alpha = 0;
    elseif alpha >= 1 then
        alpha = 1;
        self.t = -self.onHoldDuration;
        self:SetScript("OnUpdate", self.OnUpdate_OnHold);
    end

    self:SetAlpha(alpha);
end

function AlertFrame:OnUpdate_FadeOut(elapsed)
    self.t = self.t + elapsed;
    local alpha = 1 - self.t * 4;

    if alpha < 0 then
        alpha = 0;
        self.t = 0;
        self:SetScript("OnUpdate", nil);
        self:DisplayNextMessage();
    elseif alpha >= 1 then
        alpha = 1;
    end

    self:SetAlpha(alpha);
end

function AlertFrame:DisplayMessage(message, colorIndex)
    FontString:SetText(message);
    SetTextColorByIndex(FontString, colorIndex);
    return (message and GetTextReadingTime(message)) or 0
end

function AlertFrame:DisplayNextMessage()
    self.current = self.current + 1;
    local index = self.current;

    if self.queue[index] then
        self.onHoldDuration = self:DisplayMessage(self.queue[index][1], self.queue[index][2])
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate_FadeIn);
    else
        self:Clear(true);
    end
end

function AlertFrame:QueueMessage(message, colorIndex)
    if not self:IsShown() then return end;

    if not self.queue then
        self.queue = {};
    end

    if not self.total then
        self.total = 0;
    end

    self.total = self.total + 1;
    self.queue[self.total] = {message, colorIndex};

    if not self.current then
        self.current = 0;
        self:DisplayNextMessage();
    end
end

function AlertFrame:DisplayQuestMessage(questID, stringFormat, colorIndex)
    local title = questID and GetTitleForQuestID(questID);
    if title and title ~= "" then
        self:QueueMessage(stringFormat:format(title), colorIndex);
    end
end

local LFGALERT_ALPHA_HIGH = 0.8;
local LFGALERT_ALPHA_LOW = 0.3;

local function LFGAlert_OnUpdate(self, elapsed)
    self.alpha = self.alpha + self.delta*elapsed;
    if self.alpha > LFGALERT_ALPHA_HIGH then
        self.alpha = LFGALERT_ALPHA_HIGH;
        self.delta = -self.delta;
    elseif self.alpha < LFGALERT_ALPHA_LOW then
        self.alpha = LFGALERT_ALPHA_LOW;
        self.delta = -self.delta
    end
    self.Background:SetAlpha(self.alpha);
end

local function LFGAlert_OnMouseDown(self)
    if not InCombatLockdown() then
        UIParent:Show();
        SetUIVisibility(true);
        self:Hide();
    end
end

local function CreateBounceAnimation(texture)
    local ag = texture:CreateAnimationGroup();
    ag:SetLooping("REPEAT");

    local a1 = ag:CreateAnimation("Translation");
    a1:SetOrder(1);
    a1:SetOffset(0, -8);
    a1:SetDuration(0.6);
    a1:SetSmoothing("IN");

    local a2 = ag:CreateAnimation("Translation");
    a2:SetOrder(2);
    a2:SetOffset(0, 8);
    a2:SetDuration(0.6);
    a2:SetSmoothing("OUT");

    return ag
end

function AlertFrame:ShowLFGDialog()
    if not LFGAlert.initialized then
        LFGAlert.initialized = true;

        local iconSize = 32;
        local gap = 4;

        LFGAlert.Icon = LFGAlert:CreateTexture(nil, "OVERLAY");
        LFGAlert.Icon:SetSize(iconSize, iconSize);
        LFGAlert.Icon:SetPoint("LEFT", LFGAlert, "LEFT", 0, 0);
        LFGAlert.Icon:SetTexture("Interface/AddOns/DialogueUI/Art/Theme_Shared/LFGEye.png");

        LFGAlert.Text = LFGAlert:CreateFontString(nil, "OVERLAY", "DUIFont_AlertFont"); --Top right of the screen
        LFGAlert.Text:SetPoint("LEFT", LFGAlert, "LEFT", iconSize + gap, 0);
        LFGAlert.Text:SetText(L["Ready To Enter"]);
        LFGAlert.Text:SetTextColor(1, 1, 1);

        local width = LFGAlert.Text:GetWrappedWidth() + iconSize + gap;
        LFGAlert:SetSize(width, iconSize);

        LFGAlert.Background = LFGAlert:CreateTexture(nil, "BACKGROUND");
        LFGAlert.Background:SetSize(256, 256);
        LFGAlert.Background:SetPoint("CENTER", LFGAlert, "CENTER", -8, -4);
        LFGAlert.Background:SetTexture("Interface/AddOns/DialogueUI/Art/Theme_Shared/TopAlertBackground.png");
        --LFGAlert.Background:SetVertexColor(66/255, 183/255, 97/255);
        LFGAlert.Background:SetAlpha(0.67);

        LFGAlert:SetScript("OnHide", function()
            LFGAlert:Hide();
            LFGAlert:SetScript("OnUpdate", nil);
            LFGAlert.alpha = 0;
        end);

        LFGAlert:SetScript("OnMouseDown", LFGAlert_OnMouseDown);

        LFGAlert.Anim1 = CreateBounceAnimation(LFGAlert.Icon);
        LFGAlert.Anim2 = CreateBounceAnimation(LFGAlert.Text);
    end

    LFGAlert:SetFrameStrata("LOW");
    LFGAlert.alpha = LFGALERT_ALPHA_LOW;
    LFGAlert.delta = 0.833;
    --LFGAlert:SetScript("OnUpdate", LFGAlert_OnUpdate);
    LFGAlert:Show();
    LFGAlert:StopAnimating();
    LFGAlert.Anim1:Play();
    LFGAlert.Anim2:Play();

    API.UIFrameFade(LFGAlert, 0.25, 1, 0);
end

function AlertFrame:HideLFGDialog()
    LFGAlert:Hide();
end

function AlertFrame:OnLFGProposal()
    local proposalExists, id, typeID, subtypeID, name, backgroundTexture, role, hasResponded, totalEncounters, completedEncounters, numMembers, isLeader, isHoliday, proposalCategory, isSilent = GetLFGProposal();
    if (not proposalExists) or isSilent then
        return
    end

    if UIParent:IsVisible() then
        return
    end

    self:ShowLFGDialog();
end


do
    local function Settings_HideUI(dbValue)
        ALERT_FRAME_ENABLED = (dbValue == true);
    end
    addon.CallbackRegistry:Register("SettingChanged.HideUI", Settings_HideUI);
end