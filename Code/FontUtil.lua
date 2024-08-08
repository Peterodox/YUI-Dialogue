-- Customize Font
---- 1. Support LibSharedMedia
---- 1. Font Select and Comparison UI (Accessed via Settings)

local _, addon = ...
local FontUtil = {};
addon.FontUtil = FontUtil;


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

local FONT_OBJECT_HEIGHT = {
    --FontObjectName = {10, 12, 14, 16}     --Paragraph Font Size as Base

    DUIFont_Quest_Title_18 = {14, 18, 18, 18},
    DUIFont_Quest_Title_16 = {12, 16, 16, 16},
    DUIFont_Quest_SubHeader = {10, 12, 14, 16},
    DUIFont_Quest_Paragraph = {10, 12, 14, 16},
    DUIFont_Quest_Gossip = {10, 12, 14, 16},
    DUIFont_Quest_Quest = {10, 12, 14, 16},
    DUIFont_Quest_Disabled = {10, 12, 14, 16},

    DUIFont_Settings_Disabled = {10, 12, 14, 16},

    DUIFont_Item = {8, 10, 12, 12},
    DUIFont_ItemSelect = {8, 10, 12, 12},

    DUIFont_Hotkey = {8, 10, 12, 12},

    DUIFont_QuestType_Left = {8, 10, 12, 12},
    DUIFont_QuestType_Right = {8, 10, 12, 12},

    DUIFont_Tooltip_Large = {10, 12, 14, 16},
    DUIFont_Tooltip_Medium = {8, 10, 12, 12},
    DUIFont_Tooltip_Small = {8, 10, 12, 12},

    DUIFont_ItemCount = {8, 10, 10, 12},
};

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

    function FontUtil:SetFontSizeByID(id)
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