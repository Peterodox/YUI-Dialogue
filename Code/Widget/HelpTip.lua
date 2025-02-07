local _, addon = ...
local L = addon.L;
local API = addon.API;
local CallbackRegistry = addon.CallbackRegistry;

local FONTSTRING_MAX_WIDTH = 256;

local HelpTip = {};
addon.HelpTip = HelpTip;

local TipPresets = {};


do  --Help UI
    local HelpFrameMixin = {};

    function HelpFrameMixin:Init()
        self.Init = nil;

        self:SetFrameStrata("FULLSCREEN_DIALOG");
        self:SetFixedFrameStrata(true);
        self:SetFrameLevel(100);
        self:SetClampedToScreen(true);

        self.Text:SetSpacing(4);
        self.Text:SetWidth(FONTSTRING_MAX_WIDTH);
        self.Text:SetHeight(0);

        self:SetScript("OnHide", self.OnHide);
        self:SetScript("OnMouseUp", self.OnMouseUp);

        local file = "Interface/AddOns/DialogueUI/Art/Theme_Shared/HelpTip.png";
        for i, arrow in ipairs(self.ArrowFrame.Arrows) do
            arrow:SetTexture(file);
        end
        self:SetArrowPointingDirection("RIGHT");

        self.CloseButton.NormalTexture:SetTexture(file);
        self.CloseButton.HighlightTexture:SetTexture(file);
        self.CloseButton:SetScript("OnClick", function()
            self:Close();
        end);

        self.HotkeyFrame =  CreateFrame("Frame", nil, self.OkayButton, "DUIDialogHotkeyTemplate");
        self.OkayButton.ButtonText:SetText(L["Got It"]);

        self:SetTheme(addon.ThemeUtil:GetThemeID());
        CallbackRegistry:Register("ThemeChanged", "SetTheme", self);
    end

    function HelpFrameMixin:SetArrowPointingDirection(direction)
        self.ArrowFrame:ClearAllPoints();
        local l, r, t, b;

        if direction == "RIGHT" then
            l, r, t, b = 256/512, 304/512, 0, 48/512;
            self.ArrowFrame:SetPoint("CENTER", self, "RIGHT", 0, 0);
            self.ArrowAnimation = self.ArrowFrame.AnimPointRight;
        end

        for i, arrow in ipairs(self.ArrowFrame.Arrows) do
            arrow:SetTexCoord(l, r, t, b);
        end

        self.ArrowFrame:StopAnimating();
    end

    function HelpFrameMixin:SetTheme(id)
        if id == 1 then
            addon.ThemeUtil:SetFontColor(self.Text, "Ivory");
            addon.ThemeUtil:SetFontColor(self.OkayButton.ButtonText, "Ivory");
            self.CloseButton.NormalTexture:SetTexCoord(256/512, 304/512, 48/512, 96/512);
            self.CloseButton.HighlightTexture:SetTexCoord(304/512, 352/512, 48/512, 96/512);
        else
            id = 2;
            addon.ThemeUtil:SetFontColor(self.Text, "DarkModeGold");
            addon.ThemeUtil:SetFontColor(self.OkayButton.ButtonText, "DarkModeGold");
            self.CloseButton.NormalTexture:SetTexCoord(256/512, 304/512, 48/512, 96/512);
            self.CloseButton.HighlightTexture:SetTexCoord(304/512, 352/512, 48/512, 96/512);
        end
        self.BackgroundFrame:SetTheme("HelpTip"..id);
    end

    function HelpFrameMixin:SetText(helpText)
        self.Text:SetWidth(FONTSTRING_MAX_WIDTH);
        self.Text:SetText(helpText);
        self:Layout();
    end

    function HelpFrameMixin:Layout()
        local padding = 16;
        local textWidth = self.Text:GetWrappedWidth();
        local textHeight = self.Text:GetHeight();
        self.Text:ClearAllPoints();
        self.Text:SetPoint("TOPLEFT", self, "TOPLEFT", padding, -padding);

        if not addon.DeviceUtil:IsUsingController() then
            self.OkayButton:Hide();
        else
            self.OkayButton:Show();
            --local key = addon.DeviceUtil:GetConfirmKey("Confirm");
            self.HotkeyFrame:SetKey("PRIMARY");
            self.OkayButton:ClearAllPoints();
            self.OkayButton:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -padding, padding);
            local h = self.OkayButton.ButtonText:GetHeight();
            self.OkayButton:SetHeight(h);
            local w = self.OkayButton.ButtonText:GetWrappedWidth();
            local gap = API.Round(0.5*h);
            self.HotkeyFrame:ClearAllPoints();
            self.HotkeyFrame:SetPoint("RIGHT", self.OkayButton.ButtonText, "LEFT", -gap, 0);
            local objectWidth = self.HotkeyFrame:GetWidth() + gap + w;
            if objectWidth > textWidth then
                textWidth = objectWidth;
            end
            textHeight = textHeight + 4 + self.HotkeyFrame:GetHeight();
        end

        local width = API.Round(textWidth + 2 * padding);
        local height = API.Round(textHeight + 2 * padding);

        if width < self.minWidth or height < self.minHeight then
            width = math.max(width, self.minWidth);
            height = math.max(height, self.minHeight);
            self.Text:ClearAllPoints();
            self.Text:SetPoint("TOPLEFT", self, "TOPLEFT", 0.5*(width - textWidth), -0.5*(height - textHeight));
        end
        self:SetSize(width, height);
    end

    function HelpFrameMixin:UpdatePixel()
        self.BackgroundFrame:UpdatePixel();

        local scale = 0.6;
        for i, arrow in ipairs(self.ArrowFrame.Arrows) do
            arrow:SetSize(48 * scale, 48 * scale)
        end

        local a = API.GetPixelForWidget(self, 48);
        self.CloseButton:SetSize(a, a);
        self.CloseButton:ClearAllPoints();
        self.CloseButton:SetPoint("TOPRIGHT", self.BackgroundFrame.RealArea, "TOPRIGHT", 0, 0);

        local closeButtonMinSize = 34;
        local inset = 0;
        if a < closeButtonMinSize then
            inset = -math.floor(0.5*(closeButtonMinSize - a));
        end
        self.CloseButton:SetHitRectInsets(inset, inset, inset, inset);

        self.minWidth = API.GetPixelForWidget(self, 256);
        self.minHeight = API.GetPixelForWidget(self, 104);
    end

    function HelpFrameMixin:OnHide()
        if self.Release then
            self:Release();
        end
        self:SetScript("OnUpdate", nil);
        self.t = nil;
        self.alpha = 0;
    end

    local function FadeIn_OnUpdate(self, elapsed)
        self.t = self.t + elapsed;
        if self.t > 0 then
            self.t = 0;
            self.alpha = self.alpha + 5 * elapsed;
            if self.alpha >= 1 then
                self.alpha = 1;
                self:SetScript("OnUpdate", nil);
                self:OnFadeInComplete();
            end
            self:SetAlpha(self.alpha);
        end
    end

    function HelpFrameMixin:FadeIn(delay)
        self.t = (delay and -delay) or 0;
        self:SetAlpha(0);
        self.alpha = 0;
        self.ArrowFrame:StopAnimating();
        self:SetScript("OnUpdate", FadeIn_OnUpdate);
        self:Show();
    end

    function HelpFrameMixin:PlayArrowAnimation()
        if self.ArrowAnimation then
            if addon.GetDBBool("DisableUIMotion") then
                self.ArrowFrame.Arrow1:SetAlpha(1);
            else
                self.ArrowFrame.Arrow1:SetAlpha(0);
                self.ArrowAnimation:Play();
            end
        end
    end

    function HelpFrameMixin:OnFadeInComplete()
        HelpTip.anyShown = true;
        self:PlayArrowAnimation();
    end

    function HelpFrameMixin:Close()
        self:Hide();
        if self.helpFlag then
            addon.SetTutorialRead(self.helpFlag);
            TipPresets[self.helpFlag].unread = false;
        end
    end

    function HelpFrameMixin:OnMouseUp(button)
        if self:IsMouseMotionFocus() then
            if button == "LeftButton" then
                self:ShowNextStep();
            else
                self:Close();
            end
        end
    end

    function HelpFrameMixin:ShowNextStep()
        if self.helpFlag then
            self:Close();
        else
            self:Close();
        end
    end

    function HelpFrameMixin:SetOwner(owner)
        self:SetParent(owner);
        self.owner = owner;
    end

    function HelpFrameMixin:Refresh()
        self:UpdatePixel();
        self.Text:SetWidth(FONTSTRING_MAX_WIDTH);
        self:Layout();
    end

    local function CreateUI()
        local f = CreateFrame("Frame", nil, nil, "DUIHelpTipFrameTemplate");
        f:Hide();
        API.Mixin(f, HelpFrameMixin);
        f:Init();
        return f
    end

    local function RemoveUI(f)
        f:Hide();
        f:ClearAllPoints();
        f:SetParent(nil);
        f.owner = nil;
    end

    local function OnAcquireUI(f)
        f:UpdatePixel();
    end

    HelpTip.framePool = API.CreateDynamicObjectPool(CreateUI, RemoveUI, OnAcquireUI);


    local function TooltipTextMaxWidthChanged(width)
        FONTSTRING_MAX_WIDTH = width;
        HelpTip.framePool:CallActive("Refresh");
    end
    CallbackRegistry:Register("TooltipTextMaxWidthChanged", TooltipTextMaxWidthChanged);
end


do  --APIs
    function HelpTip:CloseAll()
        --For Controller
        if self.anyShown then
            self.anyShown = nil;
            for obj in self.framePool:EnumerateActive() do
                obj:Close();
            end
            return true
        end
        return false
    end

    function HelpTip:GetWidgetOwnedHelpFrame(owner, helpFlag)
        for obj in self.framePool:EnumerateActive() do
            if obj.owner == owner then
                return obj
            elseif obj.helpFlag and helpFlag and obj.helpFlag == helpFlag then
                return obj
            end
        end
        return nil
    end

    function HelpTip:ShowHelpOnObject(owner, anchorTo, helpText, helpFlag)
        --object may be <Texture> that cannot be set as parent

        local f = self:GetWidgetOwnedHelpFrame(owner);
        if not f then
            f = self.framePool:Acquire();
        end

        f:ClearAllPoints();
        f:SetOwner(owner);
        f:SetPoint("RIGHT", anchorTo, "LEFT", 0, 0);
        f:SetText(helpText);
        f.helpFlag = helpFlag;
        f:FadeIn(0.5);
        --self.framePool:DebugGetCount();
    end

    local function SortFunc_Order(a, b)
        if a.order ~= b.order then
            return a.order < b.order
        end
        return a.helpText < b.helpText
    end

    function HelpTip:SetObjectHelpTip(helpFlag, order, helpText, object, orientation)
        local p = TipPresets[helpFlag];

        if not p then
            p = {};
            TipPresets[helpFlag] = p;
        end

        table.insert(p, {
            object = object,
            helpText = helpText,
            order = order,
            orientation = orientation,
        });

        table.sort(p, SortFunc_Order);

        return true
    end

    function HelpTip:ShowPreset(helpFlag, owner, anchorTo)
        local info = TipPresets[helpFlag];
        if info and info.unread then
            self:ShowHelpOnObject(owner, anchorTo, info.helpText, info.helpFlag);
        end
    end
end


do  --Load Tips (TipPresets);
    TipPresets.WarbandCompletedQuest = {
        helpText = L["HelpTip Warband Completed Quest"],
        event = "WarbandCompleteAlert.Show",
        helpFlag = "WarbandCompletedQuest",
    };

    for helpFlag, info in pairs(TipPresets) do
        CallbackRegistry:RegisterTutorial(helpFlag, function()
            TipPresets[helpFlag].unread = true;
            if info.event and info.helpText then
                local function callback(arg1, arg2, arg3)
                    HelpTip:ShowPreset(helpFlag, arg1, arg2, arg3);
                    CallbackRegistry:UnregisterCallback(info.event, callback);
                end
                CallbackRegistry:Register(info.event, callback);
            end
        end);
    end

    --[[    --debug
    C_Timer.After(1, function()
        addon.ResetTutorials();
    end)
    --]]
end