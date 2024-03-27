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