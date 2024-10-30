local _, addon = ...
local L = addon.L;
local API = addon.API;
local FontUtil = addon.FontUtil;
local GetDBValue = addon.GetDBValue;

local FontOptionData = {};
addon.SettingsDefinitions.FontOptionData = FontOptionData;
FontOptionData.type = "DropdownButton";
FontOptionData.name = L["Font"];
FontOptionData.description = L["Font Desc"];
FontOptionData.dbKey = "FontText";

FontOptionData.tooltip = function()
    local fontFile, fontName, customFontExist = FontUtil:GetFontFromDB();

    if customFontExist then
        return L["Font Tooltip Normal"]..fontName
    else
        return L["Font Tooltip Missing"]
    end
end

FontOptionData.valueTextFormatter = function(dropdownButton, fontFile, isGamepad)
    --dbValue: voiceID
    local fontName = FontUtil:GetFontNameByFile(fontFile);
    if isGamepad then
        dropdownButton.ValueText:SetText(fontName);
    else
        FontUtil:SetAutoScalingText(dropdownButton.ValueText, fontName);
    end
end

FontOptionData.choices = function()
    local choices = {
        {
            name = FontUtil:GetFontNameByFile("default"),
            dbValue = "default",
        },
        {
            name = FontUtil:GetFontNameByFile("system"),
            dbValue = "system",
        },
    };

    local fontList = FontUtil:GetInstalledFont();
    if fontList then
        local n = #choices;
        for index, data in ipairs(fontList) do
            n = n + 1;
            choices[n] = {
                name = data[1],
                dbValue = data[2]
            };
        end
    end

    return choices
end

local function MenuButton_OnClick(self)
    addon.SetDBValue("FontText", self.id, true);
    addon.SettingsUI:UpdateOptionButtonByDBKey("FontText");
end

FontOptionData.menuDataBuilder = function(dropdownButton, dbKey)
    local choices = {
        {FontUtil:GetFontNameByFile("default"), "default"},
        {FontUtil:GetFontNameByFile("system"), "system"},
    };

    local fontList = FontUtil:GetInstalledFont();
    if fontList then
        local n = #choices;
        for index, data in ipairs(fontList) do
            n = n + 1;
            choices[n] = {data[1], data[2]};
        end
    end

    local menuData = {};
    menuData.buttons = {};
    menuData.selectedID = GetDBValue(dbKey);
    menuData.fitWidth = true;
    menuData.autoScaling = false;
    menuData.reloadPage = true;

    local function selectedIDGetter()
        return GetDBValue(dbKey)
    end
    menuData.selectedIDGetter = selectedIDGetter;

    local fontSize = FontUtil:GetDefaultFontSize();
    local r, g, b = addon.ThemeUtil:GetMenuButtonColor();

    local function MenuButton_Setup(self, name)
        local font = FontUtil:GetFontFromDB(self.id);
        self.ButtonText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "");
        self.ButtonText:SetFont(font, fontSize, "");
        self.ButtonText:SetTextColor(r, g, b);
        self.ButtonText:SetText(name);
        self.ButtonText:SetTextScale(1);
        return self.ButtonText:GetUnboundedStringWidth()
    end

    for i, data in ipairs(choices) do
        menuData.buttons[i] = {
            name = data[1],
            id = data[2],
            onClickFunc = MenuButton_OnClick,
            setupFunc = MenuButton_Setup,
            keptOpen = true,
            dbKey = dbKey,
        };
    end

    return menuData
end