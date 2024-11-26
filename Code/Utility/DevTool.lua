local _, addon = ...
local API = addon.API;
local DevTool = {};
addon.DevTool = DevTool;


do  --Print something on the screen (Gamepad Button Down)
    local Container, FontString;

    function DevTool:PrintText(text)
        if not FontString then
            local f = CreateFrame("Frame");
            Container = f;

            FontString = f:CreateFontString(nil, "OVERLAY", "DUIFont_Quest_Title_18");
            FontString:SetJustifyH("CENTER");
            FontString:SetJustifyV("BOTTOM");
            FontString:SetPoint("BOTTOM", nil, "BOTTOM", 0, 32);
            FontString:SetTextColor(0.9, 0.9, 0.9);
            FontString:SetShadowOffset(2, -2);
            FontString:SetShadowColor(0, 0, 0);

            local function FadeOut_OnUpdate(_, elapsed)
                f.t = f.t + elapsed;
                if f.t >= 0 then
                    f.alpha = 1 - 2*f.t;
                    if f.alpha <= 0 then
                        f.alpha = 0;
                        f:Hide();
                    end
                else
                    f.alpha = 1;
                end
                f:SetAlpha(f.alpha);
            end
            Container.FadeOut = FadeOut_OnUpdate;

            local function FadeIn_OnUpdate(_, elapsed)
                f.t = f.t + elapsed;
                f.alpha = 10 * f.t;
                if f.alpha >= 1 then
                    f.alpha = 1;
                    f.t = -1;
                    f:SetScript("OnUpdate", FadeOut_OnUpdate);
                end
                f:SetAlpha(f.alpha);
            end
            Container.FadeIn = FadeIn_OnUpdate;

            f.t = 0;
            f:Hide();
            f:SetScript("OnUpdate", FadeOut_OnUpdate);
        end

        FontString:SetText(text);
        Container.t = 0;
        Container:SetAlpha(0);
        Container:SetScript("OnUpdate", Container.FadeIn);
        Container:Show();
    end
end

do  --Camera Calibrator
    local Calibrator;
    local GetCursorPosition = GetCursorPosition;

    local function CreateLabelFrame(parent, asButton)
        local type = asButton and "Button" or "Frame";
        local f = CreateFrame(type, nil, parent);
        f:SetSize(4, 18);
        local label = f:CreateFontString(nil, "OVERLAY", "DUIFontFamily_Serif_10", 4);
        f.Label = label;
        label:SetJustifyH("CENTER");
        label:SetPoint("CENTER", f, "CENTER", 0, 0);
        local bg = f:CreateTexture(nil, "OVERLAY", nil, -1);
        bg:SetPoint("TOPLEFT", label, "TOPLEFT", -4, 4);
        bg:SetPoint("BOTTOMRIGHT", label, "BOTTOMRIGHT", 4, -4);
        bg:SetColorTexture(0, 0, 0, 0.8);
        f.Background = bg;
        return f
    end

    local LineMixin = {};
    do
        function LineMixin:SetColorTexture(r, g, b, a)
            self.Line:SetColorTexture(r, g, b, a);
        end

        function LineMixin:SetLabel(text)
            if text then
                if not self.LabelFrame then
                    self.LabelFrame = CreateLabelFrame(self);
                    self.LabelFrame:SetPoint("TOP", self, "TOP", 0, 0);
                end
                self.LabelFrame.Label:SetText(text);
                self.LabelFrame:Show();
            else
                if self.LabelFrame then
                    self.LabelFrame:Hide();
                end
            end
        end

        function LineMixin:OnEnter()
            if self.isDragging then
                self.Line:SetColorTexture(1, 1, 1);
            else
                self.Line:SetColorTexture(0.6, 0.6, 1);
            end
        end

        function LineMixin:OnLeave()
            if self.isDragging then
                self.Line:SetColorTexture(1, 1, 1);
            else
                self.Line:SetColorTexture(0.25, 0.25, 1);
            end
        end

        local function Dragging_OnUpdate(self, elapsed)
            self.t = self.t + elapsed;
            if self.t > 0.016 then
                self.t = 0;
                local x, y = GetCursorPosition();
                x = x + self.dx;
                if x < self.minX then
                    x = self.minX;
                elseif x > self.maxX then
                    x = self.maxX;
                end
                self:SetPoint("BOTTOM", nil, "BOTTOMLEFT", x, 0);
            end
        end

        local function WatchDrag_OnUpdate(self, elapsed)
            self.t = self.t + elapsed;
            if self.t > 0.016 then
                local x, y = GetCursorPosition();
                if (x > self.x0 + 2) or (x < self.x0 - 2) then
                    self:OnDragStart();
                end
            end
        end

        function LineMixin:OnMouseDown()
            self.isMouseDown = true;
            local x0 = self:GetCenter();
            self.x0 = x0;
            self.t = 0;
            self.Line:SetColorTexture(1, 1, 1);
            self:SetScript("OnUpdate", WatchDrag_OnUpdate);
        end

        function LineMixin:UpdateFocus()
            if self:IsVisible() and self:IsMouseOver() then
                self:OnEnter();
            else
                self:OnLeave();
            end
        end
    
        function LineMixin:OnMouseUp()
            self.isMouseDown = nil;
            self:OnDragStop();
        end

        function LineMixin:OnDragStart()
            --Emulate dragging
            self.isDragging = true;
            local x, y = GetCursorPosition();
            local x0 = self:GetCenter();
            self.x0 = x0;
            self.dx = x0 - x;
            self.t = 0;
            self.minX = 4;
            self.maxX = WorldFrame:GetRight() - 4;
            self.Line:SetColorTexture(1, 1, 1);
            self:ClearAllPoints();
            self:SetPoint("BOTTOM", nil, "BOTTOMLEFT", x0, 0);
            self:SetScript("OnUpdate", Dragging_OnUpdate);
        end

        function LineMixin:OnDragStop()
            self.isDragging = nil;
            self:SetScript("OnUpdate", nil);
            self:UpdateFocus();
        end

        function LineMixin:OnHide()
            if self.movable then
                self.isMouseDown = nil;
                self:OnDragStop();
                self:OnLeave();
            end
        end

        function LineMixin:SetMovable(state)
            self.movable = state;
            if state then
                self:SetScript("OnEnter", self.OnEnter);
                self:SetScript("OnLeave", self.OnLeave);
                self:SetScript("OnMouseDown", self.OnMouseDown);
                self:SetScript("OnMouseUp", self.OnMouseUp);
                self:SetScript("OnHide", self.OnHide);
            end
            self:EnableMouse(state);
            self:EnableMouseMotion(state);
        end
    end

    local function Calibrator_Init()
        if Calibrator then return end;

        local parent = addon.DialogueUI;
        Calibrator = CreateFrame("Frame", nil, parent);
        local baseFrameLevel = Calibrator:GetFrameLevel();

        local viewportWidth, viewportHeight = API.GetBestViewportSize();

        Calibrator:ClearAllPoints();
        Calibrator:SetPoint("LEFT", nil, "CENTER", -0.5*viewportWidth, 0);
        Calibrator:SetPoint("RIGHT", parent, "LEFT", 0, 0);
        Calibrator:SetHeight(viewportHeight);
        Calibrator:SetFrameStrata("FULLSCREEN_DIALOG");
        Calibrator:SetFixedFrameStrata(true);

        local lineWeight = API.GetPixelForWidget(Calibrator, 2);

        local function CreateLineV()
            local f = CreateFrame("Frame", nil, Calibrator);
            API.Mixin(f, LineMixin);
            f:SetSize(24, viewportHeight);

            local line = f:CreateTexture(nil, "BACKGROUND");
            line:SetHeight(viewportHeight);
            line:SetWidth(lineWeight);
            line:SetColorTexture(1, 0.2, 0.2, 0.5);
            line:SetPoint("CENTER", f, "CENTER", 0, 0);
            f.Line = line;

            return f
        end

        local Line1 = CreateLineV();
        Calibrator.CentralLine = Line1;
        Line1:SetColorTexture(1, 0.2, 0.2, 0.5);
        Line1:SetPoint("CENTER", Calibrator, "CENTER", 0, 0);
        Line1:SetLabel("Central");

        local Line2 = CreateLineV();
        Calibrator.RightLine = Line2;
        Line2:SetColorTexture(0.5, 0.5, 0.5, 0.5);
        Line2:SetPoint("CENTER", Calibrator, "RIGHT", 0, 0);

        local PlayerLine = CreateLineV();
        Calibrator.PlayerLine = PlayerLine;
        PlayerLine:OnLeave();
        PlayerLine:SetPoint("CENTER", Calibrator, "LEFT", 32, 0);
        PlayerLine:SetLabel("Player");
        PlayerLine:SetMovable(true);
        PlayerLine:SetFrameLevel(baseFrameLevel + 10);


        local ZoomReading = CreateLabelFrame(Calibrator);
        ZoomReading:SetFrameLevel(baseFrameLevel + 20);
        ZoomReading.Label:SetText("0.00");
        ZoomReading:SetPoint("BOTTOM", nil, "BOTTOM", 0, 48);

        local CvarReading = CreateLabelFrame(Calibrator);
        CvarReading:SetFrameLevel(baseFrameLevel + 20);
        CvarReading.Label:SetText("0.00");
        CvarReading:SetPoint("TOP", ZoomReading, "BOTTOM", 0, -4);

        local GetCameraZoom = GetCameraZoom;
        local GetCVar = C_CVar.GetCVar;

        local function FormatReading(label, value)
            return "|cffffd100"..label..":|r "..string.format("%.2f", value)
        end
    
        local function Readings_OnUpdate(f, elapsed)
            f.t = f.t + elapsed;
            if f.t > 0.2 then
                f.t = 0;
                ZoomReading.Label:SetText(FormatReading("Zoom", GetCameraZoom()))
                CvarReading.Label:SetText(FormatReading("Shoulder", GetCVar("test_cameraOverShoulder")));
            end
        end
        ZoomReading.t = 0;
        ZoomReading:SetScript("OnUpdate", Readings_OnUpdate);


        local Switch = CreateLabelFrame(Calibrator, true);
        Switch.Label:SetText("|cffffd100Calibrate:|r |cff808080OFF|r");
        Switch:SetWidth(Switch.Background:GetWidth());
        Switch:SetSize(100, 18);
        Switch:SetPoint("TOP", CvarReading, "BOTTOM", 0, -4);

        local function EnterCalibartorMode()
            addon.CameraUtil:EnterCalibartorMode();
            Switch.Label:SetText("|cffffd100Calibrate:|r |cff19ff19ON|r");
        end

        Switch:SetScript("OnClick", function(f)
            f.isOn = not f.isOn;
            if f.isOn then
                EnterCalibartorMode();
            else
                addon.CameraUtil:ExitCalibartorMode();
                f.Label:SetText("|cffffd100Calibrate:|r |cff808080OFF|r");
            end
        end);

        Switch:SetScript("OnHide", function()
            Switch.isOn = false;
            Switch.Label:SetText("|cffffd100Calibrate:|r |cff808080OFF|r");
        end);
        Switch:SetFrameLevel(baseFrameLevel + 20);


        local function CreateArrowButton(f, isLeft)
            local b = CreateFrame("Button", nil, f);
            b:SetSize(18, 18);

            local bg = f:CreateTexture(nil, "OVERLAY", nil, -1);
            bg:SetAllPoints(true);
            bg:SetColorTexture(0, 0, 0, 0.8);

            local Arrow = b:CreateTexture(nil, "OVERLAY");
            Arrow:SetPoint("CENTER", b, "CENTER", 0, 0);
            Arrow:SetSize(18, 18);
            Arrow:SetTexture("Interface/AddOns/DialogueUI/Art/Theme_Dark/Settings-ArrowOption.png");
            if isLeft then
                Arrow:SetTexCoord(1, 0.5, 0, 0.5);
                b.delta = -1;
            else
                Arrow:SetTexCoord(0.5, 1, 0, 0.5);
                b.delta = 1;
            end

            b:SetScript("OnEnter", function()
                Arrow:SetVertexColor(1, 1, 1);
            end);

            b:SetScript("OnLeave", function()
                Arrow:SetVertexColor(0.67, 0.67, 0.67);
            end);
            Arrow:SetVertexColor(0.67, 0.67, 0.67);

            b:SetScript("OnClick", function()
                if not Switch.isOn then
                    Switch.isOn = true;
                    EnterCalibartorMode();
                end
                local value = GetCVar("test_cameraOverShoulder");
                value = value + b.delta * 0.1;
                C_CVar.SetCVar("test_cameraOverShoulder", value);
            end);

            return b
        end

        local LeftArrow = CreateArrowButton(CvarReading, true);
        LeftArrow:SetPoint("RIGHT", CvarReading, "CENTER", -48, 0);
        local RightArrow = CreateArrowButton(CvarReading, false);
        RightArrow:SetPoint("LEFT", CvarReading, "CENTER", 48, 0);
    end

    local function DialogueUI_ShowCameraCalibrator(show)
        show = show ~= false;
        if show then
            Calibrator_Init();
            Calibrator:Show();
        elseif Calibrator then
            Calibrator:Hide();
        end
    end

    --C_Timer.After(4, DialogueUI_ShowCameraCalibrator);
end