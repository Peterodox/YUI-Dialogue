local _, addon = ...
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
            FontString:SetJustifyH("BOTTOM");
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


--[[
do  --Debug TextureSlice 10.2.7
    local container;
    container = CreateFrame("Frame");
    container:SetAllPoints(true);
    
    local bg = container:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints(true);
    bg:SetColorTexture(0, 0, 0);

    local scale = addon.API.GetPixelPertectScale();

    local function CreateTextureSlice()
        local t = container:CreateTexture(nil, "OVERLAY");
        t:SetTextureSliceMargins(8, 8, 8, 8);
        t:SetTextureSliceMode(1);
        t:SetTexture("Interface/AddOns/DialogueUI/Art/BasicShapes/DebugStroke.png");
        t:SetScale(scale);
        return t
    end

    local sizes = {
        128,
        64,
        32,
        16,
        8,
    };

    local lastObject;

    for i = 1, #sizes do
        local t = CreateTextureSlice();
        local size = sizes[i]/scale
        t:SetSize(size, size);
        if i == 1 then
            t:SetPoint("CENTER", nil, "CENTER", 0, 0);
        else
            t:SetPoint("LEFT", lastObject, "RIGHT", 32, 0);
        end
        lastObject = t;
    end
end
--]]