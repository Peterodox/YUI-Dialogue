local _, addon = ...
local L = addon.L;
local API = addon.API;
local Lerp = API.Lerp;
local Clamp = API.Clamp;
local GetPlayerLevelXP = API.GetPlayerLevelXP;
local TooltipFrame = addon.SharedTooltip;
local inOutSine = addon.EasingFunctions.inOutSine;

local BreakUpLargeNumbers = BreakUpLargeNumbers;


local FILL_DURATION = 2.0;

local function AnimFill_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    local ratio = inOutSine(self.t, self.fromRatio, self.toRatio, FILL_DURATION)

    if self.t >= FILL_DURATION then
        self.t = 0;
        self:SetScript("OnUpdate", nil);
        ratio = self.toRatio;
    end

    if ratio > 1 then
        ratio = ratio - 1;
        self:OnOverflow();
    end

    self:SetBarWidthByPercentage(ratio);
end

local function CrossFade_OnUpdate(self, elapsed)
    if self.t <= 1.0 then
        self.alpha = self.alpha + 10*elapsed;
        if self.alpha > 1 then
            self.alpha = 1;
            self.t = self.t + elapsed;
        end
    else
        self.alpha = self.alpha - 1*elapsed;
        if self.alpha <= 0 then
            self.alpha = 0;
            self:SetScript("OnUpdate", nil);
            self:Hide();
        end
    end

    self:SetAlpha(self.alpha);
end


local StatusBarMixin = {};

function StatusBarMixin:OnLoad()
    local FILE_PATH = "Interface/AddOns/DialogueUI/Art/Theme_Shared/";

    if not self.Border then
        self.Border = self:CreateTexture(nil, "OVERLAY", nil, 2);
        self.Border:SetTextureSliceMode(1);
        local margin = 6;
        self.Border:SetTextureSliceMargins(margin, margin, margin, margin);
        self.Border:SetAllPoints(true);
        self.Border:SetTexture(FILE_PATH.."StatusBar-Border.png");
        self:SetBorderColor(0.25, 0.25, 0.25);
    end

    if not self.Background then
        self.Background = self:CreateTexture(nil, "BACKGROUND");
        self.Background:SetTextureSliceMode(1);
        local margin = 6;
        self.Background:SetTextureSliceMargins(margin, margin, margin, margin);
        self.Background:SetAllPoints(true);
        self.Background:SetTexture(FILE_PATH.."StatusBar-Background.png");
        self.Background:SetAlpha(0.5);
    end

    if not self.Fill then
        self.Fill = self:CreateTexture(nil, "ARTWORK");
        self.Fill:SetTextureSliceMode(1);
        local margin = 6;
        self.Fill:SetTextureSliceMargins(margin, margin, margin, margin);
        self.Fill:SetWidth(0.1);
        self.Fill:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
        self.Fill:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0);
        self.Fill:SetTexture(FILE_PATH.."StatusBar-FillShort-Purple.png");
    end

    if not self.Surface then
        self.Surface = self:CreateTexture(nil, "ARTWORK", nil, 2);
        self.Surface:SetHeight(6);
        self.Surface:SetWidth(48);
        self.Surface:SetColorTexture(1, 1, 1);
        self.Surface:SetGradient("HORIZONTAL", CreateColor(1, 0.5, 1, 0), CreateColor(1, 0.5, 1, 0.5));
        self.Surface:SetBlendMode("ADD");
        self.Surface:SetPoint("RIGHT", self.Fill, "RIGHT", 0, 0);
    end

    if not self.ValueBlock then
        local f = CreateFrame("Frame", nil, self);
        self.ValueBlock = f;
        f:SetHeight(32);

        local bg = f:CreateTexture(nil, "OVERLAY", nil, 4);
        bg:SetTextureSliceMode(0);
        local margin = 8;
        bg:SetTextureSliceMargins(margin, margin, margin, margin);
        bg:SetAllPoints(true);
        bg:SetTexture(FILE_PATH.."StatusBar-ValueBlock-Purple.png");

        f.Text = f:CreateFontString(nil, "OVERLAY", "DUIFont_AlertFont", 7);
        f.Text:SetJustifyH("CENTER");
        f.Text:SetTextColor(0.8, 0.8, 0.8);
        f.Text:SetPoint("CENTER", f, "CENTER", 0, 2);
    end

    if not self.notchPool then
        local function CreateNotch()
            local texture = self:CreateTexture(nil, "OVERLAY");
            texture:SetTexture(FILE_PATH.."StatusBar-Notch.png");
            texture:SetVertexColor(0.25, 0.25, 0.25);
            return texture
        end

        self.notchPool = API.CreateObjectPool(CreateNotch);
    end

    self:SetMinMaxValue(0, 100);
    self:SetScript("OnShow", self.OnShow);
    self:SetScript("OnHide", self.OnHide);
    self:SetScript("OnEnter", self.OnEnter);
    self:SetScript("OnLeave", self.OnLeave);
end

function StatusBarMixin:SetBarWidth(width)
    if width == self.width then return end;

    self.width = width;
    self:SetWidth(width);
    self:UpdatePixel();
end


function StatusBarMixin:SetNumCompartment(numCompartment, forceUpdate)
    local numNotches = numCompartment - 1;

    if (numNotches ~= self.numNotches) or forceUpdate then
        self.numNotches = numNotches;
    else
        return
    end

    self.notchPool:Release();

    if numNotches <= 0 then return end;

    local fullWidth = self:GetWidth();
    local offset = fullWidth / numCompartment;
    local lineWidth = self:GetNotchWidth();
    local height = self:GetHeight() - 2;

    local texture;

    for i = 1, numNotches do
        texture = self.notchPool:Acquire();
        texture:SetSize(lineWidth, height);
        texture:SetPoint("CENTER", self, "LEFT", i * offset, 0);
    end
end

function StatusBarMixin:UpdateNotches()
    if self.numNotches then
        self:SetNumCompartment(self.numNotches + 1, true);
    end
end

function StatusBarMixin:GetNotchWidth(scale)
    if not scale then
        scale = self:GetEffectiveScale();
    end

    local lineWeight = 4.0;
    local width = API.GetPixelForScale(scale, lineWeight);

    return width
end

function StatusBarMixin:UpdatePixel(scale)
    self:UpdateNotches();
end

function StatusBarMixin:SetBorderColor(r, g, b)
    self.Border:SetVertexColor(r, g, b);
end

function StatusBarMixin:SetMinMaxValue(minVal, maxVal)
    self.minVal = minVal;
    self.maxVal = maxVal;
    self.range = maxVal - minVal;

    if self.value then
        local value = Clamp(self.value, self.minVal, self.maxVal);
        self:SetValue(value);
    end
end

function StatusBarMixin:OnOverflow()
    if self.getRangeFunc then
        local newValue = self.value - self.maxVal;
        local minVal, maxVal = self:getRangeFunc();
        self:SetMinMaxValue(minVal, maxVal);
        self:SetValue(newValue);
        self:AnimateBetweenValues(0, newValue);
    end

    if self.dataProvider then
        self:Update(true);
    end
end

function StatusBarMixin:SetBarWidthByPercentage(a)
    if a <= 0 then
        a = 0;
        self.Fill:Hide();
    else
        if a > 1 then
            a = 1
        end
        self.Fill:Show();
        self.Fill:SetWidth(self.width * a);
    end

    self.barProgress = a;
end

function StatusBarMixin:GetProgressEquivalentValue()
    if self.barProgress then
        return (1 - self.barProgress) * self.minVal + self.barProgress * self.maxVal
    end
    return self.value
end

function StatusBarMixin:CalculateValueRatio(value)
    return (value - self.minVal) / self.range
end

function StatusBarMixin:AnimateBetweenValues(fromValue, toValue)
    if toValue < fromValue then
        toValue = self.maxVal;
    end
    self.fromRatio = self:CalculateValueRatio(fromValue);
    self.toRatio = self:CalculateValueRatio(toValue);
    self.t = 0;
    self:SetScript("OnUpdate", AnimFill_OnUpdate);
end

function StatusBarMixin:SetValue(value)
    value = Clamp(value, self.minVal, self.maxVal);
    self.value = value;
    local a = (value - self.minVal)/self.range;
    self:SetBarWidthByPercentage(a);
end

function StatusBarMixin:AddValue(deltaValue)
    --Show visual indicator
    local deltaPercentage = deltaValue / self.range;
    local blockWidth = self.width * deltaPercentage;

    if blockWidth > 24 then
        self.ValueBlock:SetWidth(self.width * deltaPercentage);
        self.ValueBlock:ClearAllPoints();
        self.ValueBlock:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", self:CalculateValueRatio(self.value) * self.width, 0);
        self.ValueBlock.Text:SetText(deltaValue.." XP");
        self.ValueBlock.t = 0;
        self.ValueBlock.alpha = 0;
        self.ValueBlock:SetScript("OnUpdate", CrossFade_OnUpdate);
        self.ValueBlock:Show();
    else
        self.ValueBlock:Hide();
        self.ValueBlock:SetScript("OnUpdate", nil);
    end

    local currentValue = self.value;    --self:GetProgressEquivalentValue();
    local newValue = currentValue + deltaValue;
    self.value = newValue;
    self:AnimateBetweenValues(currentValue, newValue);
end

function StatusBarMixin:SetValueByPercentage(a)
    local value = Lerp(self.minVal, self.maxVal, a);
    self:SetValue(value);
end

function StatusBarMixin:Update(animating)
    --Overridden by DataProvider
end

function StatusBarMixin:SetDataProvider(dataProvider)
    self:SetScript("OnEvent", nil);
    self.dataProvider = dataProvider;
    self.Update = StatusBarMixin.Update;

    if dataProvider then
        dataProvider:OnLoad(self);
    end
end

function StatusBarMixin:StopAnimation()
    self:SetScript("OnUpdate", nil);
    self.ValueBlock:Hide();
    self.ValueBlock:SetScript("OnUpdate", nil);
end

function StatusBarMixin:OnShow()
    if self.dataProvider then
        self.dataProvider:OnShow(self);
    end
end

function StatusBarMixin:OnHide()
    self:SetScript("OnEvent", nil);
    self:StopAnimation();
end

function StatusBarMixin:OnMouseEnter()

end

function StatusBarMixin:OnEnter()
    self:OnMouseEnter();
end

function StatusBarMixin:OnLeave()
    TooltipFrame:Hide();
end


--[[
local StatusBarDataProvider = {};

function StatusBarDataProvider:OnLoad(bar)

end

function StatusBarDataProvider:OnShow(bar)

end

--]]

local PlayerXPDataProvider = {};    --EXP

function PlayerXPDataProvider:OnLoad(bar)
    self.owner = bar;
    bar.Update = self.Update;
    bar.OnMouseEnter = self.OnEnter;
    bar.getRangeFunc = self.getRangeFunc;
end

function PlayerXPDataProvider:OnShow(bar)
    if self.isCapped then
        bar:Hide();
        return
    end

    self.isCapped = API.IsPlayerAtMaxLevel();

    if self.isCapped then
        bar:Hide();
        --ChatFrame is anchored to this frame so we move it down
        bar:ClearAllPoints();
        bar:SetPoint("TOP", nil, "BOTTOM", 0, 0);
        return
    end

    bar:RegisterUnitEvent("PLAYER_XP_UPDATE", "player");
    bar:RegisterEvent("PLAYER_LEVEL_UP");
    bar:SetScript("OnEvent", self.OnEvent);
    bar:Update();
end

function PlayerXPDataProvider:OnEvent(event, ...)
    if event == "PLAYER_XP_UPDATE" then
        self:Update(true);
    elseif event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        self:Update(true, newLevel);
    end
end

function PlayerXPDataProvider:Update(animating, newLevel)
    local level, currentXP, maxXP = GetPlayerLevelXP();

    if newLevel and type(newLevel) == "number" then
        level = newLevel;
    end

    if animating then
        local deltaValue;

        if self.level and level > self.level then
            deltaValue = currentXP + self.maxVal - self.value;
        else
            deltaValue = currentXP - self.value;
        end

        self:AddValue(deltaValue);
    else
        self.level = level;
        self:StopAnimation();
        self:SetMinMaxValue(0, maxXP);
        self:SetValue(currentXP);
    end
end

function PlayerXPDataProvider:OnEnter()
    TooltipFrame:Hide();

    local level, currentXP, maxXP = GetPlayerLevelXP();
    local percentage = API.GetXPPercentage(currentXP);
    local diff = maxXP - currentXP;
    local xpText = L["Format Player XP"]:format(BreakUpLargeNumbers(currentXP), BreakUpLargeNumbers(maxXP), percentage);
    TooltipFrame:SetOwner(self, "ANCHOR_RIGHT");
    TooltipFrame:AddLeftLine(L["Format Unit Level"]:format(level), 1, 1, 1);
    TooltipFrame:AddLeftLine(xpText, 1, 1, 1);
    if diff > 0 then
        TooltipFrame:AddLeftLine(L["To Next Level Label"]..": |cffffffff"..BreakUpLargeNumbers(diff).."|r", 1, 0.82, 0);
    end
    TooltipFrame:Show();

    TooltipFrame:SetOwner(self, "ANCHOR_CURSOR");
end

function PlayerXPDataProvider:getRangeFunc()
    local level, currentXP, maxXP = GetPlayerLevelXP();
    self.level = level;

    if API.IsPlayerAtMaxLevel() then
        self:Hide();
        return 0, 100
    end

    return 0, maxXP
end



local DataProviderPresets = {
    xp = PlayerXPDataProvider,
};


local function CreateStatusBar(parent, dataProviderName)
    local frame = CreateFrame("Frame", nil, parent);
    frame:Hide();
    frame:SetFlattensRenderLayers(true);

    API.Mixin(frame, StatusBarMixin);

    if dataProviderName and DataProviderPresets[dataProviderName] then
        frame:SetDataProvider(DataProviderPresets[dataProviderName]);
    end

    return frame
end
addon.CreateStatusBar = CreateStatusBar;