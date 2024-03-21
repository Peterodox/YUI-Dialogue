local _, addon = ...

--Required CVar: SoftTargetNameplateInteract = 1

--User Settings
local USE_NAMPLATE_GOSSIP = false;
local ANCHOR_OFFSET_Y = 24;
------------------

local FadeFrame = addon.API.UIFrameFade;
local SplitParagraph = addon.API.SplitParagraph;
local CloseGossipInteraction = addon.API.CloseGossipInteraction;
local GetTextReadingTime = addon.API.GetTextReadingTime;

local UnitExists = UnitExists;
local UnitIsUnit = UnitIsUnit;
local UnitGUID = UnitGUID;
local UnitName = UnitName;
local GetGossipText = C_GossipInfo.GetText;
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit;


local Controller = CreateFrame("Frame");

local NameplateGossip = CreateFrame("Frame", nil, UIParent);
addon.NameplateGossip = NameplateGossip;
NameplateGossip:SetSize(4, 4);
NameplateGossip:Hide();
NameplateGossip:SetScript("OnHide", function(self)
    self:Hide();
end);

local FORMAT_SAY = addon.L["Format Monster Say"];

local function AddMessageAsChat(name, msg)
    msg = string.gsub(msg, "[%c]+", "\n");
    ChatFrame1:AddMessage(FORMAT_SAY:format(name)..msg, 1, 1, 0.62);
end

local function OnUpdate_ShowText(self, elapsed)
    self.t = self.t + elapsed;

    if self.t >= 0 then
        self:SetScript("OnUpdate", nil);
        if Controller:AnchorToNameplate() then
            NameplateGossip:DisplayNextParagraph();
        end
    end
end

local function OnUpdate_CloseGossip(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0 then
        CloseGossipInteraction();
        self.t = -0.25;
        self:SetScript("OnUpdate", OnUpdate_ShowText);
    end
end

local function GetNPCNampelate()
    --nameplate may not be ready immediately

    return GetNamePlateForUnit("softinteract");

    --[[
    if UnitExists("npc") then
        for _, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
            if UnitIsUnit("npc", nameplate.namePlateUnitToken) then
                return nameplate
            end
        end
    end
    --]]
end


function Controller:OnEvent(event, ...)
    if event == "PLAYER_SOFT_INTERACT_CHANGED" then
        local oldTarget, newTarget = ...;   --GUID
        self.interactGUID = newTarget;
    end
end

function Controller:EnableModule(state)
    USE_NAMPLATE_GOSSIP = state;

    if state then
        self:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED");
        self:SetScript("OnEvent", self.OnEvent);
    else
        self:UnregisterEvent("PLAYER_SOFT_INTERACT_CHANGED");
        self:SetScript("OnEvent", nil);
        self:Cancel();
        NameplateGossip:Clear();
    end
end
--Controller:EnableModule(true);  --debug


function Controller:Cancel()
    self:SetScript("OnUpdate", nil);
end

function Controller:StartShowTextCountdown()
    self.t = -0.1;
    self:SetScript("OnUpdate", OnUpdate_CloseGossip);
end

function Controller:IsUnitSameNPC()
    if UnitExists("softinteract") then
        local guid = UnitGUID("softinteract");
        return guid == self.lastNPCGUID
    end
end

function Controller:IsLastInteractNPC()
    if self.interactGUID then
        --print(self.interactGUID, UnitGUID("npc"))
        return self.interactGUID == UnitGUID("npc")
    end

    return false
end

function Controller:InitiateInteraction()
    self:Cancel();
    self.lastNPCGUID = UnitGUID("npc") or "none";
    self:StartShowTextCountdown();
end

function Controller:AnchorToNameplate()
    local success = false;

    if self:IsUnitSameNPC() then
        local nameplate = GetNPCNampelate();
        if nameplate then
            NameplateGossip:SetParent(nameplate);
            NameplateGossip:SetPoint("CENTER", nameplate, "CENTER", 0, ANCHOR_OFFSET_Y);
            success = true;
        end
    end

    return success
end


function NameplateGossip:Init()
    self:SetFrameStrata("HIGH");
    self:SetIgnoreParentScale(true);
    self:SetIgnoreParentAlpha(false);

    self.Text = self:CreateFontString(nil, "OVERLAY", "DUIFont_NameplateGossip");
    self.Text:SetJustifyV("BOTTOM");
    self.Text:SetJustifyH("CENTER");
    self.Text:SetPoint("BOTTOM", self, "BOTTOM", 0, 0);
    self.Text:SetWidth(272);
    self.Text:SetSpacing(2);
    self.Text:SetTextColor(1, 1, 0.62);

    local corner = 16;
    self.Background = self:CreateTexture(nil, "BACKGROUND");
    self.Background:SetTextureSliceMargins(corner, corner, corner, corner);
    self.Background:SetTextureSliceMode(1);
    self.Background:SetTexture("Interface/AddOns/DialogueUI/Art/Theme_Shared/NameplateDialogShadow.png");
    self.Background:SetPoint("CENTER", self.Text, "CENTER", 0, 0);

    self.Init = nil;
end


function NameplateGossip:RequestDisplayGossip()
    if self.Init then
        self:Init();
    end

    self:Clear();

    Controller:InitiateInteraction();

    local gossipText = GetGossipText();
    local name = UnitName("npc");
    AddMessageAsChat(name, gossipText);

    self.paragraphs = SplitParagraph(gossipText);
    self.numPages = #self.paragraphs;
    self.showPageNumber = self.numPages > 1;
    self.page = 0;

    return true
end

function NameplateGossip:SetText(text)
    self.Text:SetText(text);
    local width = self.Text:GetWrappedWidth();
    local height = self.Text:GetHeight();
    self.Background:SetSize(width + 24, height + 24);
end

function NameplateGossip:Clear()
    self:ClearAllPoints();
    self:Hide();
    self:SetScript("OnUpdate", nil);

    if self.Text then
        self.Text:SetText(nil);
    end
end

function NameplateGossip:ShowPageNumber(state)
    if state then
        
    else
    
    end
end

local function OnUpdate_ShowNextParagraph(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0 then
        self:DisplayNextParagraph();
    end
end

function NameplateGossip:DisplayNextParagraph()
    self.page = self.page + 1;

    if self.page > self.numPages then
        self:SetScript("OnUpdate", nil);
        self.paragraphs = nil;
        FadeFrame(self, 0.5, 0);
    else
        local paragraph = self.paragraphs[self.page];
        self:SetText(paragraph);
        local delay = GetTextReadingTime(paragraph);
        self.t = -delay;
        self:SetScript("OnUpdate", OnUpdate_ShowNextParagraph);
        FadeFrame(self, 0.25, 1, 0);
        self:ShowPageNumber(self.showPageNumber);
    end
end

function NameplateGossip:ShouldUseNameplate()
    if USE_NAMPLATE_GOSSIP then
        if Controller:IsLastInteractNPC() then
            --print("YES UNIT")
            return true
        else
            --print("NOT LAST UNIT")
        end
    end

    return false
end


do
    local function Settings_NameplateDialogEnabled(dbValue)
        Controller:EnableModule(dbValue == true);
    end
    addon.CallbackRegistry:Register("SettingChanged.NameplateDialogEnabled", Settings_NameplateDialogEnabled);
end