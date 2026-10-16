local _, addon = ...
local GetItemQualityColor = addon.API.GetItemQualityColor;

local ThemeUtil = {};
addon.ThemeUtil = ThemeUtil;

local gsub = string.gsub;
local unpack = unpack;

local TEXTURE_PATH;
local THEME_ID;


local ColorAdjustment = {
    ---Used to replace Red for Brown theme
    Red = {
        pattern = {
            "|cnRED_FONT_COLOR:",
            "|cnWARNING_FONT_COLOR:",
            "|[cC][fF][fF][fF][fF]0000",
            "|[cC][fF][fF][fF][fF]4040",
        },
        replaceBy = "|cff9B2020",
    },

    ---Used to replace Blue for Dark theme
    Blue = {
        pattern = {
            "|cnPURE_BLUE_COLOR:",
            "|[cC][fF][fF]0000[fF][fF]",
        },
        replaceBy = "|cff0078FF",
    }
};


local ActiveColorLookup = ColorAdjustment.Red;

---Used in Brown theme. Adjust red text color to increase legibility.
---@return string adjustedText
---@return boolean redColorFound
local function AdjustTextColor(text)
    local count = 0;

    for _, pattern in ipairs(ActiveColorLookup.pattern) do
        text, count = gsub(text, pattern, ActiveColorLookup.replaceBy);
        if count > 0 then
            break;
        end
    end

    return text, count > 0;
end


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
        ActiveColorLookup = ColorAdjustment.Blue;
    else
        themeID = 1;
        colorIndex = 1;
        TEXTURE_PATH = "Interface/AddOns/DialogueUI/Art/Theme_Brown/";
        ActiveColorLookup = ColorAdjustment.Red;
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

    ThemeUtil:UpdateMultiLanguageFontColor();
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

function ThemeUtil:UpdateMultiLanguageFontColor(showOriginal)
    local colorIndex = THEME_ID == 2 and 2 or 1;
    local colors;

    if showOriginal == nil then
        showOriginal = true;
    end

    if showOriginal then
        colors = FONT_OBJECT_COLOR.DUIFont_Quest_MultiLanguage;
    else
        colors = FONT_OBJECT_COLOR.DUIFont_Quest_Paragraph;
    end

    local fontName = "DUIFont_Quest_MultiLanguage";
    SetFontColor(_G[fontName], colors[colorIndex]);
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

    addon.CallbackRegistry:Register("SettingChanged.TranslatorShowOriginalText", ThemeUtil.UpdateMultiLanguageFontColor, ThemeUtil);
end
