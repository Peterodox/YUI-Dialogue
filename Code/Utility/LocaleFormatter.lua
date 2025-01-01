-- Implement our own escape sequance
---- Device Button:     [KEY:F1] [KEY:XBOX:PAD1]
---- Localized NPC Name:    [NPC:12345:Fallback Name] (Unused)

local _, addon = ...
local L = addon.L;

local match = string.match;
local gsub = string.gsub;

local HOTKEY_PATH = "Interface/AddOns/DialogueUI/Art/Keys/";
local BUTTON_FORMAT = {
    TAB = "|TInterface/AddOns/DialogueUI/Art/Keys/PC-TAB.png:16:29:0:-4:64:32:0:58:0:32:|t";
}

local ProcessedString = {

};

local ReplaceStringWithKey;
do
    local count = 0;    --Limit the number of loops in case of localization error
    
    local function ReplaceStringWithKey_Recursive(text, offsetY)
        count = count + 1;
        if count > 4 then
            return text
        end

        local type, arg1, arg2 = match(text, "%[(%w+):(%w+):(%w+)%]");

        if type and type == "KEY" and arg1 and arg2 then
            local iconSize = 16;
            local device, button;
            local texture;

            device = arg1;
            button = arg2;

            texture = BUTTON_FORMAT[button];
            if not texture then
                texture = ("|T%s%s-%s.png:%s:%s:0:%s|t"):format(HOTKEY_PATH, device, button, iconSize, iconSize, offsetY);
            end

            text = gsub(text, "%[[%w:]+%]", texture, 1);
            return ReplaceStringWithKey_Recursive(text, offsetY);
        else
            return text
        end
    end

    function ReplaceStringWithKey(text, offsetY)
        count = 0;
        offsetY = offsetY or 0;
        return ReplaceStringWithKey_Recursive(text, offsetY)
    end
end

local function GetFormattedLocale(lKey)
    if not ProcessedString[lKey] then
        ProcessedString[lKey] = ReplaceStringWithKey(L[lKey]);
    end
    return ProcessedString[lKey]
end
addon.GetFormattedLocale = GetFormattedLocale;


do
    local function FormatLocales(lKey, iconOffsetY)
        if L[lKey] then
            local text = ReplaceStringWithKey(L[lKey], iconOffsetY);
            if text then
                L[lKey] = text;
            end
        else
            addon.API.PrintMessage("Missing String:", lKey);
        end
    end

    local SETTINGS_DESC_SPACING = -4;
    local BANNER_TEXT_SPACING = -6;

    local LOCALE_KEYS = {
        --See enUS.lua
        --[key] = iconOffsetY (compensated for fontString Spacing)

        ["Input Device Xbox Tooltip"] = SETTINGS_DESC_SPACING,
        ["Input Device PlayStation Tooltip"] = SETTINGS_DESC_SPACING,
        ["Input Device Switch Tooltip"] = SETTINGS_DESC_SPACING,
        ["Interact Key Not Set"] = SETTINGS_DESC_SPACING,
        ["Use Default Control Key Alert"] = SETTINGS_DESC_SPACING,
        ["Press Key To Use Item Desc PC"] = SETTINGS_DESC_SPACING,
        ["Press Key To Use Item Desc Xbox"] = SETTINGS_DESC_SPACING,
        ["Press Key To Use Item Desc PlayStation"] = SETTINGS_DESC_SPACING,
        ["Press Key To Use Item Desc Switch"] = SETTINGS_DESC_SPACING,
        ["TTS Use Hotkey Tooltip PC"] = SETTINGS_DESC_SPACING,
        ["TTS Use Hotkey Tooltip Xbox"] = SETTINGS_DESC_SPACING,
        ["TTS Use Hotkey Tooltip PlayStation"] = SETTINGS_DESC_SPACING,
        ["TTS Use Hotkey Tooltip Switch"] = SETTINGS_DESC_SPACING,
        ["Press Tab To Select Reward Desc"] = SETTINGS_DESC_SPACING,

        ["Tutorial Settings Hotkey"] = BANNER_TEXT_SPACING,
        ["Tutorial Settings Hotkey Console"] = BANNER_TEXT_SPACING,

        ["Instruction Open Settings"] = SETTINGS_DESC_SPACING,
        ["Instruction Open Settings Console"] = SETTINGS_DESC_SPACING,
    };

    for lkey, iconOffsetY in pairs(LOCALE_KEYS) do
        FormatLocales(lkey, iconOffsetY);
    end
end