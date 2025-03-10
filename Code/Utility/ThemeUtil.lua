local _, addon = ...
local GetItemQualityColor = addon.API.GetItemQualityColor;

local ThemeUtil = {};
addon.ThemeUtil = ThemeUtil;

local gsub = string.gsub;
local unpack = unpack;

local TEXTURE_PATH;
local THEME_ID;


local function AdjustRedText(text)
    local count;
    text, count = gsub(text, "|[cC][fF][fF][fF][fF]0000", "|cff9B2020");

    if count == 0 then
        text, count = gsub(text, "|cnRED_FONT_COLOR:", "|cff9B2020");
    end

    if count == 0 then
        text, count = gsub(text, "|[cC][fF][fF][fF][fF]4040", "|cff9B2020");
    end

    return text, (count and count > 0)  --2nd payload used for replacing the gossip icon
end

local function AdjustBlueText(text)
    local count;
    text, count = gsub(text, "|[cC][fF][fF]0000[fF][fF]", "|cff0078FF");
    return text, false
end

local AdjustTextColor = AdjustRedText;

local COLORS = {
    --ColorKey = {r, g, b}

    DarkBrown = {0.19, 0.17, 0.13},
    LightBrown = {0.50, 0.36, 0.24},
    Ivory = {0.87, 0.86, 0.75},
    Brick = {0.416, 0.18, 0.165},

    DarkModeGrey90 = {0.9, 0.9, 0.9},
    DarkModeGrey70 = {0.7, 0.7, 0.7},
    DarkModeGrey50 = {0.5, 0.5, 0.5},
    DarkModeGold = {1, 0.98, 0.8},
    DarkModeGoldDim = {0.796, 0.784, 0.584},

    WarningRed = {1.000, 0.125, 0.125},
    BrightGreen = {0.5, 0.86, 0.5};
};

local FONT_OBJECT_COLOR = {
    --FontObjectName = {Theme Brown, Dark}

    DUIFont_Quest_Title_18 = {"DarkBrown", "DarkModeGrey90"},
    DUIFont_Quest_Title_16 = {"DarkBrown", "DarkModeGrey90"},
    DUIFont_Quest_SubHeader = {"DarkBrown", "DarkModeGrey90"},
    DUIFont_Quest_Paragraph = {"DarkBrown", "DarkModeGrey70"},
    DUIFont_Quest_Gossip = {"DarkBrown", "DarkModeGoldDim"},
    DUIFont_Quest_Quest = {"Ivory", "DarkModeGold"},
    DUIFont_Quest_Disabled = {"LightBrown", "DarkModeGrey50"},
    DUIFont_Quest_MultiLanguage = {"Brick", "DarkModeGrey50"},

    DUIFont_Settings_Disabled = {"LightBrown", "DarkModeGrey50"},

    DUIFont_Item = {"DarkBrown", "DarkModeGrey90"},
    DUIFont_ItemSelect = {"Ivory", "DarkModeGold"},

    DUIFont_QuestType_Left = {"DarkBrown", "DarkModeGrey90"},
    DUIFont_QuestType_Right = {"DarkModeGrey70", "DarkModeGrey70"},

    DUIFont_Constant_10 = {"DarkBrown", "DarkModeGrey70"},
    DUIFont_Constant_8 = {"DarkBrown", "DarkModeGrey70"},

    DUIFont_MenuButton_Normal = {"DarkBrown", "DarkModeGrey90"},
    DUIFont_MenuButton_Highlight = {"DarkBrown", "DarkModeGrey90"},
};


local function SetFontColor(fontObject, key)
    local color = COLORS[key];
    fontObject:SetTextColor(color[1], color[2], color[3]);
end

function ThemeUtil:SetFontColor(fontObject, key)
    SetFontColor(fontObject, key);
end

function ThemeUtil:SetThemeByID(themeID)
    local colorIndex;

    if themeID == 2 then    --Dark
        colorIndex = 2;
        TEXTURE_PATH = "Interface/AddOns/DialogueUI/Art/Theme_Dark/";
        AdjustTextColor = AdjustBlueText;
    else
        themeID = 1;
        colorIndex = 1;
        TEXTURE_PATH = "Interface/AddOns/DialogueUI/Art/Theme_Brown/";
        AdjustTextColor = AdjustRedText;
    end

    THEME_ID = themeID;

    local _G = _G;

    for fontName, colorKey in pairs(FONT_OBJECT_COLOR) do
        SetFontColor(_G[fontName], colorKey[colorIndex]);
    end

    if addon.DialogueUI then
        addon.DialogueUI:LoadTheme();
    end

    if addon.SettingsUI then
        addon.SettingsUI:LoadTheme();
    end

    if addon.QuestItemDisplay then
        addon.QuestItemDisplay:LoadTheme();
    end

    if addon.DropdownMenu then
        addon.DropdownMenu:LoadTheme();
    end

    addon.CallbackRegistry:Trigger("ThemeChanged", themeID);
end

function ThemeUtil:GetTexturePath()
    return TEXTURE_PATH
end

function ThemeUtil:GetTextureFile(fileName)
    if fileName then
        return TEXTURE_PATH..fileName;
    end
end

function ThemeUtil:GetThemeID()
    return THEME_ID
end

function ThemeUtil:IsDarkMode()
    return THEME_ID == 2
end

function ThemeUtil:GetQualityColor(quality)
    if self:IsDarkMode() then
        return GetItemQualityColor(quality):GetRGB()
    else
        return 0.19, 0.17, 0.13, 1
    end
end

function ThemeUtil:GetItemSelectColor()
    if self:IsDarkMode() then
        return unpack(COLORS.DarkModeGold)
    else
        return unpack(COLORS.Ivory)
    end
end

function ThemeUtil:GetMenuButtonColor()
    if self:IsDarkMode() then
        return unpack(COLORS.DarkModeGrey90)
    else
        return unpack(COLORS.DarkBrown)
    end
end

function ThemeUtil:AdjustTextColor(text)
    return AdjustTextColor(text);
end


do
    ThemeUtil:SetThemeByID(1);

    local function Settings_Theme(dbValue)
        local themeID;
        if dbValue == 2 then
            themeID = 2;
        else
            themeID = 1;
        end
        ThemeUtil:SetThemeByID(themeID);
    end
    addon.CallbackRegistry:Register("SettingChanged.Theme", Settings_Theme);
end