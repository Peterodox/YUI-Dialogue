local _, addon = ...
local Banner = addon.Banner;


do  --Teach players how to open Settings
    local TUTORIAL_FLAG = "OpenSettings";
    local TUTORIAL_SHOWN = false;

    local function SetupTutorial_OpenSettings()
        local function onShowFunc()
            TUTORIAL_SHOWN = true;
            addon.SetTutorialRead(TUTORIAL_FLAG);
        end
        Banner.onShowFunc = onShowFunc;

        local function DisplayTutorial()
            if not TUTORIAL_SHOWN then
                local delay = 1;
                if C_CVar.GetCVarBool("GamePadEnable") then
                    Banner:DisplayMessage(addon.L["Tutorial Settings Hotkey Console"], delay);
                else
                    Banner:DisplayMessage(addon.L["Tutorial Settings Hotkey"], delay);
                end
            end
        end

        addon.DialogueUI:HookScript("OnShow", DisplayTutorial);


        local function SettingsUI_OnShow()
            Banner:Hide();
        end

        addon.CallbackRegistry:Register("SettingsUI.Show", SettingsUI_OnShow);
    end

    addon.CallbackRegistry:RegisterTutorial(TUTORIAL_FLAG, SetupTutorial_OpenSettings);
end