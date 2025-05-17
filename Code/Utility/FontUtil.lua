-- Customize Font
---- 1. Support LibSharedMedia
---- 1. Font Select and Comparison UI (Accessed via Settings)
---  Color defined in ThemeUtil.lua

local _, addon = ...
local API = addon.API;
local L = addon.L;
local GetDBValue = addon.GetDBValue;
local FontUtil = {};
addon.FontUtil = FontUtil;

FontUtil.TestFont = UIParent:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
FontUtil.TestFont:SetPoint("TOP", UIParent, "BOTTOM", 0, -64);

local AUTO_SCALING_MIN_HEIGHT = 9;

local DEFAULT_FONT_FILE = {
    roman = "Interface/AddOns/DialogueUI/Fonts/frizqt__.ttf",       --Friz Quadrata
    korean = "Fonts/2002.TTF",
    simplifiedchinese = "Fonts/ARKai_T.ttf",
    traditionalchinese = "Fonts/blei00d.TTF",
    russian = "Interface/AddOns/DialogueUI/Fonts/frizqt___cyr.ttf",
};

local NUMBER_FONT_FILE = {
    roman = "Interface/AddOns/DialogueUI/Fonts/ARIALN.ttf",
    korean = "Fonts/2002.TTF",
    simplifiedchinese = "Fonts/ARHei.ttf",
    traditionalchinese = "Fonts/arheiuhk_bd.TTF",
    russian = "Interface/AddOns/DialogueUI/Fonts/ARIALN.ttf",
};

local DEFAULT_BOOK_TITLE_FONT_FILE = {
    roman = "Interface/AddOns/DialogueUI/Fonts/TrajanPro3SemiBold.ttf",
};

local OVERRIDE_FONT = {};   --[FontObjectName] = file, used as multilanguage support
local HEIGHT_1 = {10, 12, 14, 16, 24};
local HEIGHT_2 = {8, 10, 12, 14, 20};

local FONT_OBJECT_HEIGHT = {
    --Fifth value is currently used for MobileDeviceMode
    --FontObjectName = {10, 12, 14, 16}     --Paragraph Font Size as Base

    DUIFont_Quest_Title_18 = {14, 18, 18, 18, 24},
    DUIFont_Quest_Title_16 = {12, 16, 16, 16, 20},
    DUIFont_Quest_SubHeader = HEIGHT_1,
    DUIFont_Quest_Paragraph = HEIGHT_1,
    DUIFont_Quest_Gossip = HEIGHT_1,
    DUIFont_Quest_Quest = HEIGHT_1,
    DUIFont_Quest_Disabled = HEIGHT_1,
    DUIFont_Quest_MultiLanguage = HEIGHT_1,

    DUIFont_Settings_Disabled = HEIGHT_1,

    DUIFont_Item = HEIGHT_2,
    DUIFont_ItemSelect = HEIGHT_2,

    DUIFont_Hotkey = HEIGHT_2,

    DUIFont_QuestType_Left = HEIGHT_2,
    DUIFont_QuestType_Right = HEIGHT_2,

    DUIFont_Tooltip_Large = HEIGHT_1,
    DUIFont_Tooltip_Medium = HEIGHT_2,
    DUIFont_Tooltip_Small = HEIGHT_2,

    DUIFont_ItemCount = {8, 10, 10, 12, 12},

    DUIFont_MenuButton_Normal = HEIGHT_1,
    DUIFont_MenuButton_Highlight = HEIGHT_1,

    DUIFont_AlertHeader = {8, 9, 10, 12, 12},

    DUIFont_Book_10 = {10, 10, 10, 10, 12},
    DUIFont_ChatFont = {10, 10, 10, 10, 12},
};

FONT_OBJECT_HEIGHT.DUIFont_Book_H1 = FONT_OBJECT_HEIGHT.DUIFont_Quest_Title_18;
FONT_OBJECT_HEIGHT.DUIFont_Book_H2 = FONT_OBJECT_HEIGHT.DUIFont_Quest_Title_16;
FONT_OBJECT_HEIGHT.DUIFont_Book_H3 = FONT_OBJECT_HEIGHT.DUIFont_Quest_Title_16;
FONT_OBJECT_HEIGHT.DUIFont_Book_Paragraph = FONT_OBJECT_HEIGHT.DUIFont_Quest_Paragraph;

local IS_NUMBER_FONT = {
    DUIFont_ItemCount = true,
};


do
    local CLIENT_ALPHABET;

    local AlphabetLocales = {
        roman = {"enUS", "frFR", "deDE", "esES", "esMX", "ptBR", "itIT"},
        korean = {"koKR"},
        simplifiedchinese = {"zhCN"},
        traditionalchinese = {"zhTW"},
        russian = {"ruRU"},
    };

    function FontUtil:GetAlphabetForCurrentClient()
        if not CLIENT_ALPHABET then
            local clientLocale = GetLocale() or "enUS";

            for alphabet, locales in pairs(AlphabetLocales) do
                for _, locale in ipairs(locales) do
                    if clientLocale == locale then
                        CLIENT_ALPHABET = alphabet;
                        break
                    end
                end
            end

            if not CLIENT_ALPHABET then
                CLIENT_ALPHABET = "roman";
            end

            AlphabetLocales = nil;
        end

        return CLIENT_ALPHABET
    end
end

function FontUtil:GetDefaultFont()
    local alphabet = self:GetAlphabetForCurrentClient();
    return DEFAULT_FONT_FILE[alphabet];
end

function FontUtil:GetDefaultTitleFont()
    local alphabet = self:GetAlphabetForCurrentClient();
    return DEFAULT_BOOK_TITLE_FONT_FILE[alphabet] or DEFAULT_FONT_FILE[alphabet]
end

function FontUtil:GetUserFont()
    if GetDBValue("FontText") == "default" then
        return self:GetDefaultFont();
    else
        return self:GetFontFromDB();
    end
end

function FontUtil:GetUserNumberFont()
    local alphabet = self:GetAlphabetForCurrentClient();
    return NUMBER_FONT_FILE[alphabet];
end

function FontUtil:GetInstalledFont()
    if self.installedFontGetter then
        local fontData = self.installedFontGetter();
        return fontData
    end
end

function FontUtil:GetFontFromDB(dbValue)
    local font = dbValue or GetDBValue("FontText") or "default";
    local fontFile, fontName;
    local exist = false;

    if font == "default" then
        fontFile = self:GetDefaultFont();
        fontName = L["Default Font"];
        exist = true;
    elseif font == "system" then
        fontFile = GameFontNormal:GetFont();
        fontName = L["System Font"];
        exist = true;
    else
        local fontList = self:GetInstalledFont();
        if fontList then
            for _, data in ipairs(fontList) do
                if data[2] == font then
                    fontFile = font;
                    fontName = data[1];
                    exist = true;
                    break
                end
            end
        end
        fontFile = fontFile or self:GetDefaultFont();
        fontName = fontName or L["Default Font"];
    end

    return fontFile, fontName, exist
end

function FontUtil:SetCustomFont(dbValue)
    --font = DBValue "FontText"
    local fontFile, fontName, exist = self:GetFontFromDB(dbValue);
    if exist then
        self:SetFontByFile(fontFile);
    end
end

function FontUtil:UpdateFont()
    self:SetCustomFont();
end

function FontUtil:GetFontNameByFile(fontFile)
    fontFile = fontFile or "default";
    local fontName;

    if fontFile == "default" then
        fontName = L["Default Font"];
    elseif fontFile == "system" then
        fontName = L["System Font"];
    else
        local fontList = FontUtil:GetInstalledFont();
        fontName = (self.fontToName and self.fontToName[fontFile]) or L["Default Font"];
    end

    return fontName
end

function FontUtil:SetupFontStringByFontObjectName(fontString, fontObjectName)
    --Temp fix for the following issue:
    --SetFont may break the link between fontString and its fontObject (see https://github.com/Stanzilla/WoWUIBugs/issues/581)
    local font, height, style = _G[fontObjectName]:GetFont();
    local r, g, b = _G[fontObjectName]:GetTextColor();
    fontString:SetFont(font, height, style);
    fontString:SetTextColor(r, g, b);
end

do  --Auto Downsize Font To Fit Into Region (Derivative of AutoScalingFontStringMixin, Blizzard_SharedXML/SecureUtil)
    local Round = API.Round;
    local AutoScalingFontStringMixin =  {};

    function AutoScalingFontStringMixin:SetText(fontString, text, minLineHeight)
        fontString:SetText(text);
        self:ScaleTextToFit(fontString, minLineHeight);
    end

    function AutoScalingFontStringMixin:GetFontHeight(fontString)
        local _, height = fontString:GetFont();
        return Round(height);
    end

    function AutoScalingFontStringMixin:ScaleTextToFit(fontString, minLineHeight)
        local baseLineHeight = self:GetFontHeight(fontString);
        local tryHeight = baseLineHeight;
        minLineHeight = minLineHeight or AUTO_SCALING_MIN_HEIGHT;
        local stringWidth = fontString:GetUnboundedStringWidth() / fontString:GetTextScale();

        if stringWidth > 0 then
            local maxLines = fontString:GetMaxLines();
            if maxLines == 0 then
                maxLines = Round(fontString:GetHeight() / (baseLineHeight + fontString:GetSpacing()));
            end
            local targetScale = fontString:GetWidth() * maxLines / stringWidth;
            if targetScale >= 1 then
                tryHeight = baseLineHeight;
            else
                tryHeight = Round(targetScale * baseLineHeight);
                if tryHeight < minLineHeight then
                    tryHeight = minLineHeight;
                end
            end
        end

        while tryHeight >= minLineHeight do
            local scale = tryHeight / baseLineHeight;
            fontString:SetTextScale(scale);
            if fontString:IsTruncated() then
                tryHeight = tryHeight - 1;
            else
                break
            end
        end
    end

    function FontUtil:SetAutoScalingText(fontString, text, minLineHeight)
        AutoScalingFontStringMixin:SetText(fontString, text, minLineHeight)
    end
end

do
    local DEFAULT_FONT_SIZE = 0;
    local FONT_SIZE_ID = 1;
    local FONT_DATA_ID = FONT_SIZE_ID + 1;

    local FONT_SIZE_INDEX = {
        [0] = 10,
        [1] = 12,
        [2] = 14,
        [3] = 16,
    };

    local MOBILE_DEVICE_FONT_SIZE_ID = 4;

    for index, size in ipairs(HEIGHT_1) do
        FONT_SIZE_INDEX[index - 1] = size;
    end

    function FontUtil:SetFontSizeByID(id)
        if (GetDBValue("MobileDeviceMode") == true) and FONT_SIZE_INDEX[MOBILE_DEVICE_FONT_SIZE_ID] then
            id = MOBILE_DEVICE_FONT_SIZE_ID;
        end

        if not (id and FONT_SIZE_INDEX[id]) then return end;

        FONT_SIZE_ID = id;
        FONT_DATA_ID = FONT_SIZE_ID + 1;

        if FONT_SIZE_INDEX[id] == DEFAULT_FONT_SIZE then return end;

        local fontSize = FONT_SIZE_INDEX[id];
        DEFAULT_FONT_SIZE = fontSize;

        local k = FONT_DATA_ID;
        local _G = _G;

        local textFontFile = self:GetUserFont();

        for fontName, v in pairs(FONT_OBJECT_HEIGHT) do
            local _, _, flags = _G[fontName]:GetFont();
            local fontFile;

            if IS_NUMBER_FONT[fontName] then
                fontFile = FontUtil:GetUserNumberFont();
            elseif OVERRIDE_FONT[fontName] then
                fontFile = OVERRIDE_FONT[fontName];
            else
                fontFile = textFontFile;
            end

            _G[fontName]:SetFont(fontFile, v[k], flags);
        end

        if fontSize >= 16 then
            AUTO_SCALING_MIN_HEIGHT = 10;
        else
            AUTO_SCALING_MIN_HEIGHT = 9;
        end

        addon.CallbackRegistry:Trigger("FontSizeChanged", fontSize, id);
    end

    function FontUtil:SetFontByFile(textFontFile, isRequery)
        self.TestFont:SetFont("Fonts\\FRIZQT__.TTF", 10, "");
        local success = self.TestFont:SetFont(textFontFile, 12, "");
        if not success then
            if not isRequery then
                C_Timer.After(0.2, function()  --Wait until "PostFontSizeChanged" tiggered in SharedUITemplate.lua
                    self:SetFontByFile(textFontFile, true);
                end);
            end
            return
        end

        local k = FONT_DATA_ID;
        local _G = _G;

        for fontName, v in pairs(FONT_OBJECT_HEIGHT) do
            local _, _, flags = _G[fontName]:GetFont();
            local fontFile;

            if IS_NUMBER_FONT[fontName] then
                fontFile = FontUtil:GetUserNumberFont();
            elseif OVERRIDE_FONT[fontName] then
                fontFile = OVERRIDE_FONT[fontName];
            else
                fontFile = textFontFile;
            end

            _G[fontName]:SetFont(fontFile, v[k], flags);
        end

        if GetDBValue("FontText") == "default" then
            textFontFile = self:GetDefaultTitleFont();
        end
        _G.DUIFont_Book_Title:SetFont(textFontFile, 18, "");

        addon.CallbackRegistry:Trigger("FontSizeChanged", DEFAULT_FONT_SIZE, FONT_SIZE_ID);
    end

    function FontUtil:GetDefaultFontSize()
        return DEFAULT_FONT_SIZE
    end

    function FontUtil:SetOverrideFont(fontObjectName, file, isRequery)
        if FONT_OBJECT_HEIGHT[fontObjectName] then
            if file then
                self.TestFont:SetFont("Fonts/frizqt__.ttf", 10, "");
                local success = self.TestFont:SetFont(file, 10, "");
                if success then
                    OVERRIDE_FONT[fontObjectName] = file;
                else
                    if not isRequery then
                        C_Timer.After(0.2, function()
                            self:SetOverrideFont(fontObjectName, file, true);
                        end);
                    end
                    return
                end
            else
                OVERRIDE_FONT[fontObjectName] = nil;
            end
            self:UpdateFont();
        end
        return false
    end

    function FontUtil:SetMultiLanguageQuestFont(file)
        return self:SetOverrideFont("DUIFont_Quest_MultiLanguage", file);
    end


    function FontUtil:GetFontByAlphabet(alphabet)
        return DEFAULT_FONT_FILE[alphabet]
    end

    function FontUtil:SetMultiLanguageQuestFontByAlphabet(alphabet)
        return self:SetOverrideFont("DUIFont_Quest_MultiLanguage", self:GetFontByAlphabet(alphabet));
    end
end


do  --Settings Callbacks
    local function Settings_FontSizeBase(dbValue)
        FontUtil:SetFontSizeByID(dbValue);
    end
    addon.CallbackRegistry:Register("SettingChanged.FontSizeBase", Settings_FontSizeBase);

    local function Settings_MobileDeviceMode(dbValue, userInput)
        if userInput then
            FontUtil:SetFontSizeByID(GetDBValue("FontSizeBase"));
            C_Timer.After(0.05, function()  --Wait until "PostFontSizeChanged" tiggered in SharedUITemplate.lua
                addon.SetDBValue("FrameSize", GetDBValue("FrameSize"));
            end);
        end
    end
    addon.CallbackRegistry:Register("SettingChanged.MobileDeviceMode", Settings_MobileDeviceMode);


    local function Settings_FontText(dbValue, userInput)
        if userInput then
            FontUtil:SetCustomFont(dbValue);
        end
    end
    addon.CallbackRegistry:Register("SettingChanged.FontText", Settings_FontText);
end


do  --Check LibSharedMedia

    local function CheckLib()
        local libName = "LibSharedMedia-3.0";
        C_AddOns.LoadAddOn(libName);

        local silent = true;
        local lib = LibStub and LibStub.GetLibrary and LibStub:GetLibrary(libName, silent);

        if lib then
            FontUtil.installedFontGetter = function()
                local data = lib:HashTable("font");
                local list = lib:List("font");

                local fontList = {};
                local n = 0;
                local file;

                FontUtil.fontToName = {};

                for _, fontName in ipairs(list) do
                    if data[fontName] then
                        n = n + 1;
                        file = data[fontName];
                        fontList[n] = {fontName, file};
                        FontUtil.fontToName[file] = fontName;
                    end
                end

                return fontList
            end
        else

        end

        FontUtil:SetCustomFont();
    end
    addon.CallbackRegistry:Register("PLAYER_ENTERING_WORLD", CheckLib);
end