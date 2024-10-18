-- Customize Font
---- 1. Support LibSharedMedia
---- 1. Font Select and Comparison UI (Accessed via Settings)
---  Color defined in ThemeUtil.lua

local _, addon = ...
local API = addon.API;
local GetDBValue = addon.GetDBValue;
local FontUtil = {};
addon.FontUtil = FontUtil;


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

function FontUtil:GetUserFont()
    if true then
        return self:GetDefaultFont();
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

    function FontUtil:SetFontByFile(textFontFile)
        local k = FONT_DATA_ID;
        local _G = _G;

        for fontName, v in pairs(FONT_OBJECT_HEIGHT) do
            local _, _, flags = _G[fontName]:GetFont();
            local fontFile;

            if IS_NUMBER_FONT[fontName] then
                fontFile = FontUtil:GetUserNumberFont();
            else
                fontFile = textFontFile;
            end

            _G[fontName]:SetFont(fontFile, v[k], flags);
        end

        addon.CallbackRegistry:Trigger("FontSizeChanged", DEFAULT_FONT_SIZE, FONT_SIZE_ID);
    end
end


do
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
end


do  --Check LibSharedMedia

    local DropDownMenu;

    local function CheckLib()
        local libName = "LibSharedMedia-3.0";
        local silent = true;
        local lib = LibStub and LibStub.GetLibrary and LibStub:GetLibrary(libName, silent);

        if lib then
            FontUtil.installedFontGetter = function()
                local data = lib:HashTable("font");
                local list = lib:List("font");

                local fontData = {};
                local n = 0;

                for _, fontName in ipairs(list) do
                    if data[fontName] then
                        n = n + 1;
                        fontData[n] = {fontName, data[fontName]};
                    end
                end

                return fontData
            end

            local fontList = FontUtil:GetInstalledFont();
            if fontList and #fontList > 1 then
                DropDownMenu = addon.GetDropDownMenu();
                DropDownMenu:SetContent(fontList)
            end
        else

        end
    end
    --addon.CallbackRegistry:Register("PLAYER_ENTERING_WORLD", CheckLib);
end