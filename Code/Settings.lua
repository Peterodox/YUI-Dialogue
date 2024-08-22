local _, addon = ...
local L = addon.L;
local API = addon.API;
local Clamp = API.Clamp;
local ThemeUtil = addon.ThemeUtil;
local TTSUtil = addon.TTSUtil;
local PlaySound = addon.PlaySound;
local InCombatLockdown = InCombatLockdown;
local CreateFrame = CreateFrame;
local type = type;

local GetDBValue = addon.GetDBValue;
local SetDBValue = addon.SetDBValue;

local INPUT_DEVICE_GAME_PAD = false;
local INPUT_DEVICE_ID = 1;
local GAME_PAD_ACTIVE = false;
local BUTTON_PADDING_LARGE = 12;
local FONT_HEIGHT_LARGE = 12;
local FONT_HEIGHT_NORMAL = 12;
local FRAME_PADDING = 14;

local OPTIONBUTTON_HEIGHT = 36;                         --Adaptive
local OPTIONBUTTON_WIDTH = OPTIONBUTTON_HEIGHT*12;      --Adaptive
local OPTIONBUTTON_FROM_Y = 4;
local OPTIONBUTTON_LABEL_OFFSET = 14;
local OPTION_WIDGET_SIZE = 24;
local NUM_VISIBLE_OPTIONS = 10.5;
local ARROWOPTION_VALUETEXT_OFFSET_Y = -2;
local ARROWOTPION_WIDTH_RATIO = 7;                      --Adaptive
local ARROWOTPION_BAR_HEIGHT = 5;                       --Adaptive
local ARROWOTPION_CYCLING = false;
local HOTKEYFRAME_VALUETEXT_GAP = 4;
local TAB_BUTTON_GAP = 4;

local DISABLED_TEXTURE_ALPHA = 0.2;

local PREVIEW_PATH = "Interface/AddOns/DialogueUI/Art/PreviewPicture/";

local MainFrame;


local function Reposition_OnDragStart(self)
    if self.OnMouseUp then
        self:OnMouseUp();
    end

    MainFrame:StartMoving();
end

local function Reposition_OnDragStop(self)
    MainFrame:StopMovingOrSizing();
    MainFrame:UpdateScrollFrameBound();
end

local function SetupRepositionObject(obj)
    obj:SetScript("OnDragStart", Reposition_OnDragStart);
    obj:SetScript("OnDragStop", Reposition_OnDragStop);
    obj:RegisterForDrag("LeftButton");
end

DUIDialogSettingsMixin = {};

function DUIDialogSettingsMixin:OnLoad()
    MainFrame = self;
    addon.SettingsUI = self;
    addon.PixelUtil:AddPixelPerfectObject(self);

    SetupRepositionObject(self.Header);
end

function DUIDialogSettingsMixin:OnShow_First()
    if self.Init then
        self:Init();
    end
    self:Layout();
    self:UpdatePixel();
    self:SetScript("OnShow", self.OnShow);
    self.tabID = 1;
    self:OnShow();
end

function DUIDialogSettingsMixin:OnShow()
    self:UpdateCurrentTab();
    self:EnableGamePadButton(true);
    self:RegisterEvent("GAME_PAD_ACTIVE_CHANGED");
    self:RegisterEvent("GAME_PAD_DISCONNECTED");
    self:MoveToBestPosition();
    addon.CallbackRegistry:Trigger("SettingsUI.Show");
end

function DUIDialogSettingsMixin:MoveToBestPosition()
    if addon.DialogueUI:IsShown() then
        local viewportWidth, viewportHeight = WorldFrame:GetSize(); --height unaffected by screen resolution
        viewportWidth = math.min(viewportWidth, viewportHeight * 16/9);
        local frameWidth = self:GetWidth();
        local offset = 0.5*frameWidth -0.5 * viewportWidth +16;
        if addon.IsDBValue("FrameOrientation", 1) then
            offset = -offset;
        end
        self:ClearAllPoints();
        self:SetPoint("CENTER", nil, "CENTER", offset, 0);
    else
        self:ClearAllPoints();
        self:SetPoint("CENTER", nil, "CENTER", 0, 0);
    end
    self:UpdateScrollFrameBound();
end

function DUIDialogSettingsMixin:UpdateScrollFrameBound()
    self.scrollFrameTop = self.ScrollFrame:GetTop();
    self.scrollFrameBottom = self.ScrollFrame:GetBottom();
end

function DUIDialogSettingsMixin:OnKeyDown(key)
    local valid = false;

    if key == "ESCAPE" or key == "F1" then
        self:Hide();
        valid = true;
    end

    if not InCombatLockdown() then
        self:SetPropagateKeyboardInput(not valid);
    end
end

function DUIDialogSettingsMixin:OnGamePadButtonDown(button)
    --print(button)

    GAME_PAD_ACTIVE = true;

    local valid = false;

    if button == "PADFORWARD" or button == "PADBACK" or button == "PAD2" then
        self:Hide();
        valid = true;
    elseif button == "PADLSHOULDER" then
        self:SelectTabByDelta(-1);
        valid = true;
    elseif button == "PADRSHOULDER" then
        self:SelectTabByDelta(1);
        valid = true;
    elseif button == "PADDUP" then
        self:FocusObjectByDelta(1);
        valid = true;
    elseif button == "PADDDOWN" then
        self:FocusObjectByDelta(-1);
        valid = true;
    elseif button == "PADDLEFT" or button == "PADDRIGHT" or button == "PAD1" then
        self:ClickFocusedObject(button);
        valid = true;
    end

    if not InCombatLockdown() then
        self:SetPropagateKeyboardInput(not valid);
    end
end

function DUIDialogSettingsMixin:OnMouseWheel(delta)

end

function DUIDialogSettingsMixin:LoadTheme()
    if self.Init then return end;

    local filePath = ThemeUtil:GetTexturePath();

    self.Background:SetTexture(filePath.."Settings-Background.png");
    self.BackgroundShadow:SetTexture(filePath.."Settings-BackgroundShadow.png");
    self.HeaderDivider:SetTexture(filePath.."Settings-Divider-H.png");
    self.VerticalDivider:SetTexture(filePath.."Settings-Divider-V.png");
    self.PreviewBorder:SetTexture(filePath.."Settings-PreviewBorder.png");
    self.Header.Selection:SetTexture(filePath.."Settings-TabButton-Selection.png");
    self.ButtonHighlight.BackTexture:SetTexture(filePath.."Settings-ButtonHighlight.png");

    local file1 = filePath.."Settings-CloseButton.png";
    self.Header.CloseButton.Background:SetTexture(file1);
    self.Header.CloseButton.Highlight:SetTexture(file1);
    self.Header.CloseButton.Icon:SetTexture(file1);

    local file2 = filePath.."Settings-Checkbox.png";
    self.checkboxPool:ProcessAllObjects(function(widget)
        widget:SetTexture(file2);
    end);

    local file3 = filePath.."Settings-ArrowOption.png";
    local file4 = filePath.."Settings-ArrowOption.png";

    self.arrowOptionPool:ProcessAllObjects(function(widget)
        widget:SetTexture(file3);
        widget.barPool:ProcessAllObjects(function(bar)
            bar:SetTexture(file4);
        end);
    end);

    if self.hotkeyFramePool then
        self.hotkeyFramePool:CallAllObjects("LoadTheme");
    end

    self.BackgroundDecor:SetTexture(filePath.."Settings-BackgroundDecor.png");

    local themeID;

    if ThemeUtil:IsDarkMode() then
        themeID = 2;
        self.BackgroundDecor:SetBlendMode("ADD");
    else
        themeID = 1;
        self.BackgroundDecor:SetBlendMode("BLEND");
    end

    self.ScrollBar:SetTheme(themeID);

    for i, button in ipairs(self.tabButtons) do
        local isSelected = button.isSelected;
        button.isSelected = true;
        button:SetSelected(isSelected);
    end
end

function DUIDialogSettingsMixin:UpdatePixel(scale)
    if not scale then
        scale = self:GetEffectiveScale();
    end

    local pixelOffset = 10.0;
    local offset = API.GetPixelForScale(scale, pixelOffset);
    self.BackgroundShadow:ClearAllPoints();
    self.BackgroundShadow:SetPoint("TOPLEFT", self, "TOPLEFT", -offset, offset);
    self.BackgroundShadow:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", offset, -offset);


    API.UpdateTextureSliceScale(self.Background);
    API.UpdateTextureSliceScale(self.BackgroundShadow);
    API.UpdateTextureSliceScale(self.PreviewBorder);
    API.UpdateTextureSliceScale(self.Header.Selection);
end

function DUIDialogSettingsMixin:HighlightButton(button)
    self.ButtonHighlight:Hide();
    self.ButtonHighlight:ClearAllPoints();

    if button and button:IsEnabled() then
        self.ButtonHighlight:SetParent(button);
        self.ButtonHighlight:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0);
        self.ButtonHighlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0);
        self.ButtonHighlight:Show();
    end
end

function DUIDialogSettingsMixin:OnHide()
    self.focusedObject = nil;
    self.focusedObjectOffsetY = nil;
    self.scrollFrameTop = nil;
    self.scrollFrameBottom = nil;
    self:EnableGamePadButton(false);
    self:UnregisterEvent("GAME_PAD_ACTIVE_CHANGED");
    self:UnregisterEvent("GAME_PAD_DISCONNECTED");
    addon.CallbackRegistry:Trigger("SettingsUI.Hide");
end

function DUIDialogSettingsMixin:OnEvent(event, ...)
    if event == "GAME_PAD_ACTIVE_CHANGED" then
        local isActive = ...
        GAME_PAD_ACTIVE = isActive;
    elseif event == "GAME_PAD_DISCONNECTED" then
        GAME_PAD_ACTIVE = false;
    end
end

function DUIDialogSettingsMixin:SetPreviewTexture(optionData)
    if optionData.preview and (type(optionData.preview) == "string") then
        self.Preview:SetTexture(PREVIEW_PATH..optionData.preview);
    end

    if optionData.ratio == 1 then
        self.Preview:SetWidth(self.previewHeight);
    elseif optionData.ratio == 2 then
        self.Preview:SetWidth(2 * self.previewHeight);
    else

    end
end


function DUIDialogSettingsMixin:DisplayOptionInfo(optionData, choiceTooltip)
    local hasPreview;

    if optionData.preview then
        hasPreview = true;
        self:SetPreviewTexture(optionData);
    else
        hasPreview = false;
    end

    self.Preview:SetShown(hasPreview);
    self.PreviewBorder:SetShown(hasPreview);

    if hasPreview then
        if not self.hasPreview then
            self.hasPreview = true;
            self.Description:ClearAllPoints();
            self.Description:SetPoint("TOP", self.Preview, "BOTTOM", 0, -FRAME_PADDING);
        end
    else
        if self.hasPreview then
            self.hasPreview = nil;
            self.Description:ClearAllPoints();
            self.Description:SetPoint("TOP", self.Preview, "TOP", 0, -8);
        end
    end

    if choiceTooltip and optionData.description then
        self.Description:SetText(optionData.description.."\n\n"..choiceTooltip);
    else
        self.Description:SetText(optionData.description);
    end
end


local function ValueTextFormatter_PrimaryControlKey(arrowOptionButton, dbValue)
    local f = arrowOptionButton.HotkeyFrame;

    if not f then
        f = MainFrame.hotkeyFramePool:Acquire();
        arrowOptionButton.HotkeyFrame = f;
    end

    f:SetBaseHeight(20);

    local key, keyDesc, errorText;

    if dbValue == 1 then
        key = "SPACE";
        keyDesc = L["Key Space"];
    elseif dbValue == 2 then
        key, errorText = API.GetBestInteractKey();
        keyDesc = L["Key Interact"];
    elseif dbValue == 0 then
        key = "DISABLED";
        keyDesc = L["Key Disabled"];
    end

    local fontString = arrowOptionButton.ValueText;
    f:SetKey(key or "ERROR");
    fontString:SetText(keyDesc);

    local widgetWidth = f:GetWidth() + HOTKEYFRAME_VALUETEXT_GAP;
    fontString:ClearAllPoints();
    fontString:SetPoint("TOP", arrowOptionButton, "TOP", widgetWidth*0.5, ARROWOPTION_VALUETEXT_OFFSET_Y);
    f:ClearAllPoints();
    f:SetPoint("RIGHT", fontString, "LEFT", -HOTKEYFRAME_VALUETEXT_GAP, 0);
end

local function PrimaryControlKey_Interact_Tooltip()
    local key, errorText = API.GetBestInteractKey();
    if errorText then
        local additionalTooltip = errorText.."\n\n"..L["Use Default Control Key Alert"];
        return additionalTooltip
    end
end

local function TTSHotkey_TooltipFunc()
    local device;

    if INPUT_DEVICE_ID == 1 then
        device = "PC";
    elseif INPUT_DEVICE_ID == 2 then
        device = "Xbox";
    elseif INPUT_DEVICE_ID == 3 then
        device = "PlayStation";
    elseif INPUT_DEVICE_ID == 4 then
        device = "Switch";
    else
        device = "PC";
    end

    return L["TTS Use Hotkey Tooltip "..device]
end

local function TTSVoice_TooltipFunc(self)
    local dbValue = GetDBValue(self.dbKey);
    return TTSUtil:GetVoiceName(dbValue)
end

local function TTSVoice_MenuButton_OnClick(menuButton)
    local dbKey = menuButton.data.dbKey;
    local voiceID = menuButton.id;
    SetDBValue(dbKey, voiceID, true);
    MainFrame:UpdateOptionButtonByDBKey(dbKey);
end

local function TTSVoice_AbbreviateName(text)
    text = string.gsub(text, "^Microsoft", "");
    return strtrim(text);
end

local function TTSVoice_GetChoices()
    local voices = TTSUtil:GetAvailableVoices();
    local choices = {};

    for index, data in ipairs(voices) do
        choices[index] = {
            dbValue = data.voiceID,
            tooltip = data.name,
        }
    end

    return choices
end

local function ValueTextFormatter_TTSVoiceName(dropdownButton, dbValue)
    --dbValue: voiceID
    if INPUT_DEVICE_GAME_PAD then
        dropdownButton.ValueText:SetText(dbValue);
    else
        local voiceName = TTSVoice_AbbreviateName(TTSUtil:GetVoiceName(dbValue));
        addon.FontUtil:SetAutoScalingText(dropdownButton.ValueText, voiceName);
    end
end

local function TTSVoice_BuildMenuData(dropdownButton, dbKey)
    local voices = TTSUtil:GetAvailableVoices();
    local total = voices and #voices or 0;

    if total > 0 then
        local menuData = {};
        menuData.buttons = {};
        menuData.buttonHeight = OPTION_WIDGET_SIZE;
        menuData.buttonWidth = OPTION_WIDGET_SIZE * 8;
        menuData.selectedID = GetDBValue(dbKey);
        menuData.fitWidth = true;
        menuData.autoScaling = true;

        for i, data in ipairs(voices) do
            menuData.buttons[i] = {
                name = TTSVoice_AbbreviateName(data.name),
                id = data.voiceID,
                onClickFunc = TTSVoice_MenuButton_OnClick,
                keptOpen = true,
                dbKey = dbKey,
            };
        end

        return menuData
    end
end

local function QuestItemDisplay_Move_OnClick()
    addon.QuestItemDisplay:EnterEditMode();
end

local function QuestItemDisplay_Reset_OnClick()
    addon.QuestItemDisplay:ResetPosition();
end

local function QuestItemDisplayPosition_Validation()
    local f = addon.QuestItemDisplay;
    return f and f:IsUsingCustomPosition()
end

local function RPAddOn_Validation()
    return addon.GetInstalledRPAddOnName() ~= nil
end

local function RPAddOn_ReplaceName_Tooltip()
    local addOnName = addon.GetInstalledRPAddOnName();
    if addOnName then
        return L["Format Functionality Handled By"]:format(addOnName);
    end
end

local Schematic = { --Scheme
    {
        tabName = L["UI"],  --Cate1
        options = {
            {type = "ArrowOption", name = L["Theme"], description = L["Theme Desc"], dbKey = "Theme", preview = "Theme", ratio = 2,
                choices = {
                    {dbValue = 1, valueText = L["Theme Brown"]},
                    {dbValue = 2, valueText = L["Theme Dark"]},
                },
            },
            {type = "ArrowOption", name = L["Frame Size"], description = L["Frame Size Desc"], dbKey = "FrameSize",
                choices = {
                    {dbValue = 0, valueText = L["Size Extra Small"]},
                    {dbValue = 1, valueText = L["Size Small"]},
                    {dbValue = 2, valueText = L["Size Medium"]},
                    {dbValue = 3, valueText = L["Size Large"]},
                },
            },
            {type = "ArrowOption", name = L["Font Size"], description = L["Font Size Desc"], dbKey = "FontSizeBase", realignAfterClicks = true,
                choices = {
                    {dbValue = 0, valueText = "10"},
                    {dbValue = 1, valueText = "12"},
                    {dbValue = 2, valueText = "14"},
                    {dbValue = 3, valueText = "16"},
                },
            },
            {type = "ArrowOption", name = L["Frame Orientation"], description = L["Frame Orientation Desc"], dbKey = "FrameOrientation",
                choices = {
                    {dbValue = 1, valueText = L["Orientation Left"]},
                    {dbValue = 2, valueText = L["Orientation Right"]},
                },
            },
            {type = "Checkbox", name = L["Hide UI"], description = L["Hide UI Desc"], dbKey = "HideUI"},
            {type = "Checkbox", name = L["Hide Unit Names"], description = L["Hide Unit Names Desc"], dbKey = "HideUnitNames", parentKey = "HideUI", requiredParentValue = true},
            {type = "Checkbox", name = L["Show Copy Text Button"], description = L["Show Copy Text Button Desc"], preview = "CopyTextButton", ratio = 1, dbKey = "ShowCopyTextButton"},
            {type = "Checkbox", name = L["Show NPC Name On Page"], description = L["Show NPC Name On Page Desc"], dbKey = "ShowNPCNameOnPage"},

            {type = "Subheader", name = L["Quest"]},    --Quest
            {type = "Checkbox", name = L["Mark Highest Sell Price"], description = L["Mark Highest Sell Price Desc"], dbKey = "MarkHighestSellPrice", preview = "MarkHighestSellPrice", ratio = 1},
            {type = "Checkbox", name = L["Show Quest Type Text"], description = L["Show Quest Type Text Desc"], dbKey = "QuestTypeText", preview = "QuestTypeText", ratio = 1},
            {type = "Checkbox", name = L["Simplify Currency Rewards"], description = L["Simplify Currency Rewards Desc"], dbKey = "SimplifyCurrencyReward", preview = "SimplifyCurrencyReward", ratio = 2},
            {type = "Checkbox", name = L["Use Blizzard Tooltip"], description = L["Use Blizzard Tooltip Desc"], dbKey = "UseBlizzardTooltip"},
            {type = "Subheader", name = L["Roleplaying"], validationFunc = RPAddOn_Validation},
            {type = "Checkbox", name = L["Use RP Name In Dialogues"], description = L["Use RP Name In Dialogues Desc"], tooltip = RPAddOn_ReplaceName_Tooltip, dbKey = "UseRoleplayName", validationFunc = RPAddOn_Validation},
        },
    },

    {
        tabName = L["Camera"],  --Cate2
        options = {
            {type = "ArrowOption", name = L["Camera Movement"], dbKey="CameraMovement",
                choices = {
                    {dbValue = 0, valueText = L["Camera Movement Off"]},
                    {dbValue = 1, valueText = L["Camera Movement Zoom In"]},
                    {dbValue = 2, valueText = L["Camera Movement Horizontal"]},
                },
            },
            {type = "Checkbox", name = L["Change FOV"], description = L["Change FOV Desc"], dbKey = "CameraChangeFov", parentKey = "CameraMovement", requiredParentValue = 1, preview = "CameraChangeFov", ratio = 2},
            {type = "Checkbox", name = L["Maintain Camera Position"], description = L["Maintain Camera Position Desc"], dbKey = "CameraMovement1MaintainPosition", parentKey = "CameraMovement", requiredParentValue = 1},
            --{type = "Checkbox", name = L["Maintain Camera Position"], description = L["Maintain Camera Position Desc"], dbKey = "CameraMovement2MaintainPosition", parentKey = "CameraMovement", requiredParentValue = 2, },
            {type = "Checkbox", name = L["Maintain Offset While Mounted"], description = L["Maintain Offset While Mounted Desc"], dbKey = "CameraMovementMountedCamera", parentKey = "CameraMovement", requiredParentValue = {1, 2}},
            {type = "Checkbox", name = L["Disable Camera Movement Instance"], description = L["Disable Camera Movement Instance Desc"], dbKey = "CameraMovementDisableInstance", parentKey = "CameraMovement", requiredParentValue = {1, 2}},
        },
    },

    {
        tabName = L["Control"],  --Cate3
        options = {
            {type = "ArrowOption", name = L["Input Device"], dbKey = "InputDevice", description = L["Input Device Desc"],
                choices = {
                    {dbValue = 1, valueText = L["Input Device KBM"]},
                    {dbValue = 2, valueText = L["Input Device Xbox"], tooltip = L["Input Device Xbox Tooltip"]},
                    {dbValue = 3, valueText = L["Input Device PlayStation"], tooltip = L["Input Device PlayStation Tooltip"]},
                    {dbValue = 4, valueText = L["Input Device Switch"], tooltip = L["Input Device Switch Tooltip"]},
                },
            },
            {type = "ArrowOption", name = L["Primary Control Key"], description = L["Primary Control Key Desc"], dbKey = "PrimaryControlKey", valueTextFormatter = ValueTextFormatter_PrimaryControlKey, hasHotkey = true, parentKey = "InputDevice", requiredParentValue = 1,
                choices = {
                    {dbValue = 1, valueText = L["Key Space"]},
                    {dbValue = 2, valueText = L["Key Interact"], tooltip = PrimaryControlKey_Interact_Tooltip},
                    {dbValue = 0, valueText = L["Key Disabled"], tooltip = L["Key Disabled Tooltip"]},
                },
            },
            {type = "Checkbox", name = L["Right Click To Close UI"], description = L["Right Click To Close UI Desc"], dbKey = "RightClickToCloseUI", parentKey = "InputDevice", requiredParentValue = 1},

            {type = "Subheader", name = L["Quest"]},
            {type = "Checkbox", name = L["Press Button To Scroll Down"], description = L["Press Button To Scroll Down Desc"], dbKey = "ScrollDownThenAcceptQuest"},
        },
    },

    {
        tabName = L["Gameplay"],  --Cate4
        options = {
            {type = "Checkbox", name = L["Quest Item Display"], description = L["Quest Item Display Desc"], dbKey = "QuestItemDisplay", preview = "QuestItemDisplay", ratio = 2},
            {type = "Checkbox", name = L["Quest Item Display Hide Seen"], description = L["Quest Item Display Hide Seen Desc"], dbKey = "QuestItemDisplayHideSeen", parentKey = "QuestItemDisplay", requiredParentValue = true},
            {type = "Checkbox", name = L["Quest Item Display Await World Map"], description = L["Quest Item Display Await World Map Desc"], dbKey = "QuestItemDisplayDynamicFrameStrata", parentKey = "QuestItemDisplay", requiredParentValue = true},
            {type = "Custom", name = L["Move Position"], icon = "Settings-Move.png", parentKey = "QuestItemDisplay", requiredParentValue = true, onClickFunc = QuestItemDisplay_Move_OnClick},
            {type = "Custom", name = L["Reset Position"], icon = "Settings-Reset.png", description = L["Quest Item Display Reset Position Desc"], parentKey = "QuestItemDisplay", requiredParentValue = true, validationFunc = QuestItemDisplayPosition_Validation, onClickFunc = QuestItemDisplay_Reset_OnClick},

            {type = "Subheader", name = L["Gossip"]},
            {type = "Checkbox", name = L["Auto Select Gossip"], description = L["Auto Select Gossip Desc"], dbKey = "AutoSelectGossip"},
            {type = "Checkbox", name = L["Force Gossip"], description = L["Force Gossip Desc"], dbKey = "ForceGossip"},
            --{type = "Checkbox", name = L["Nameplate Dialog"], description = L["Nameplate Dialog Desc"], dbKey = "NameplateDialogEnabled", preview = "NameplateDialogEnabled", ratio = 1},
        },
    },

    {
        tabName = L["Accessibility"],  --Cate5
        options = {
            {type = "Checkbox", name = L["TTS"], description = L["TTS Desc"], dbKey = "TTSEnabled", preview = "TTSButton", ratio = 1},
            {type = "Checkbox", name = L["TTS Use Hotkey"], description = L["TTS Use Hotkey Desc"], tooltip = TTSHotkey_TooltipFunc, dbKey = "TTSUseHotkey", parentKey = "TTSEnabled", requiredParentValue = true},
            {type = "Checkbox", name = L["TTS Auto Play"], description = L["TTS Auto Play Desc"], dbKey = "TTSAutoPlay", parentKey = "TTSEnabled", requiredParentValue = true},
            {type = "Checkbox", name = L["TTS Auto Stop"], description = L["TTS Auto Stop Desc"], dbKey = "TTSAutoStop", parentKey = "TTSEnabled", requiredParentValue = true},
            {type = "DropdownButton", name = L["TTS Voice Male"], description = L["TTS Voice Male Desc"], tooltip = TTSVoice_TooltipFunc, dbKey="TTSVoiceMale", valueTextFormatter = ValueTextFormatter_TTSVoiceName, parentKey="TTSEnabled", requiredParentValue = true, choices = TTSVoice_GetChoices},
            {type = "DropdownButton", name = L["TTS Voice Female"], description = L["TTS Voice Female Desc"],  tooltip = TTSVoice_TooltipFunc, dbKey="TTSVoiceFemale", valueTextFormatter = ValueTextFormatter_TTSVoiceName, parentKey="TTSEnabled", requiredParentValue = true, choices = TTSVoice_GetChoices},
            {type = "ArrowOption", name = L["TTS Rate"], dbKey = "TTSRate", description = L["TTS Rate Desc"], parentKey="TTSEnabled", requiredParentValue = true,
                choices = {
                    {dbValue = 1, valueText = "1"},
                    {dbValue = 2, valueText = "2"},
                    {dbValue = 3, valueText = "3"},
                    {dbValue = 4, valueText = "4"},
                    {dbValue = 5, valueText = "5"},
                    {dbValue = 6, valueText = "6"},
                },
            },
            {type = "ArrowOption", name = L["TTS Volume"], dbKey = "TTSVolume", description = L["TTS Volume Desc"], parentKey="TTSEnabled", requiredParentValue = true,
                choices = {
                    {dbValue = 5, valueText = "50%"},
                    {dbValue = 6, valueText = "60%"},
                    {dbValue = 7, valueText = "70%"},
                    {dbValue = 8, valueText = "80%"},
                    {dbValue = 9, valueText = "90%"},
                    {dbValue = 10, valueText = "100%"},
                },
            },
            {type = "Subheader", name = L["TTS Include Content"], parentKey = "TTSEnabled", requiredParentValue = true},
            {type = "Checkbox", name = L["TTS Content NPC Name"], dbKey = "TTSContentSpeaker", parentKey = "TTSEnabled", requiredParentValue = true},
            {type = "Checkbox", name = L["TTS Content Quest Name"], dbKey = "TTSContentQuestTitle", parentKey = "TTSEnabled", requiredParentValue = true},
        },
    },
};


local CloseButtonScripts = {};

function CloseButtonScripts:OnClick()
    MainFrame:Hide();
    PlaySound("CHECKBOX_ON");
end

function CloseButtonScripts:OnEnter()
    self.Highlight:Show();
end

function CloseButtonScripts:OnLeave()
    self.Highlight:Hide();
end

function CloseButtonScripts:OnMouseDown()
    self.Icon:SetPoint("CENTER", 0, -1);
end

function CloseButtonScripts:OnMouseUp()
    self.Icon:SetPoint("CENTER", 0, 0);
end

function CloseButtonScripts:OnHide()
    self.Highlight:Hide();
    self.Icon:SetPoint("CENTER", 0, 0);
end


local function RemoveWidget(widget)
    widget:Hide();
    widget:ClearAllPoints();
    widget:SetParent(MainFrame);
    widget.HotkeyFrame = nil;
    widget.valueTextFormatter = nil;
end

local function CreateOptionButton()
    local optionButton = CreateFrame("Button", nil, MainFrame, "DUIDialogSettingsOptionTemplate");
    return optionButton
end

local function CreateCheckbox()
    local checkbox = CreateFrame("Button", nil, MainFrame, "DUIDialogSettingsCheckboxTemplate");
    return checkbox
end

local function OnAcquireCheckbox(checkbox)
    checkbox:SetTexture(ThemeUtil:GetTextureFile("Settings-Checkbox.png"));
end

local function CreateArrowOption()
    local widget = CreateFrame("Frame", nil, MainFrame, "DUIDialogSettingsArrowOptionTemplate");
    return widget
end

local function OnAcquireArrowOption(widget)
    widget:SetTexture(ThemeUtil:GetTextureFile("Settings-ArrowOption.png"));
end

local function CreateDropdownButton()
    local widget = CreateFrame("Button", nil, MainFrame, "DUIDialogSettingsDropdownButtonTemplate");
    return widget
end

local function OnAcquireDropdownButton(widget)
    widget:SetTexture(ThemeUtil:GetTextureFile("Settings-DropdownButton.png"));
end


local TextureFrameMixin = {};

function TextureFrameMixin:SetTexture(file)
    self.Texture:SetTexture(file);
end

function TextureFrameMixin:SetVertexColor(r, g, b, a)
    self.Texture:SetVertexColor(r, g, b, a)
end

local function CreateTexture()
    local f = CreateFrame("Frame", nil, MainFrame, "DUIDialogSettingsTextureFrameTemplate");
    API.Mixin(f, TextureFrameMixin);
    return f
end


local ScrollFrameMixin = {};

function ScrollFrameMixin:SetViewSize(height)
    self.viewSize = height;
    self:SetHeight(height);
end

function ScrollFrameMixin:GetViewSize()
    return self.viewSize or 0
end

function ScrollFrameMixin:SetScrollRange(range)
    if range < 0 then
        range = 0;
        self.scrollBar:Hide();
        MainFrame.VerticalDivider:Show();
    else
        self.scrollBar:Show();
        MainFrame.VerticalDivider:Hide();
    end

    self.maxScrollOffset = range;
    self.scrollBar:UpdateThumbSize();
end

function ScrollFrameMixin:GetScrollRange()
    return self.maxScrollOffset or 0
end

function ScrollFrameMixin:SetContentHeight(contentHeight)
    self:SetScrollRange(contentHeight - self:GetViewSize());
end

function ScrollFrameMixin:GetScrollOffset()
    return self.scrollOffset or 0
end

function ScrollFrameMixin:SetScrollOffset(scrollOffset)
    scrollOffset = Clamp(scrollOffset, 0, self.maxScrollOffset);
    if scrollOffset ~= self.scrollOffset then
        self.scrollOffset = scrollOffset;
        self.Reference:SetPoint("TOPLEFT", 0, scrollOffset);
        self.scrollBar:UpdateThumbPosition();
    end
end

function ScrollFrameMixin:IsAtBottom()
    return self:GetScrollOffset() + 0.1 >= self:GetScrollRange();
end

function ScrollFrameMixin:ScrollBy(offset)
    self:SetScrollOffset( self:GetScrollOffset() + offset);
end

function ScrollFrameMixin:ScrollToBottom()
    self:SetScrollOffset(self:GetScrollRange());
end

function ScrollFrameMixin:OnMouseWheel(delta)
    if delta > 0 then
        self:ScrollBy(-OPTIONBUTTON_HEIGHT);
    else
        self:ScrollBy(OPTIONBUTTON_HEIGHT);
    end
end


function DUIDialogSettingsMixin:Init()
    --Tab Buttons
    if not self.tabButtons then
        self.tabButtons = {};
    end

    self.optionButtonPool = API.CreateObjectPool(CreateOptionButton, RemoveWidget);
    self.checkboxPool = API.CreateObjectPool(CreateCheckbox, RemoveWidget, OnAcquireCheckbox);
    self.arrowOptionPool = API.CreateObjectPool(CreateArrowOption, RemoveWidget, OnAcquireArrowOption);
    self.dropdownButtonPool = API.CreateObjectPool(CreateDropdownButton, RemoveWidget, OnAcquireDropdownButton);
    self.texturePool = API.CreateObjectPool(CreateTexture);

    local function CreateHotkeyFrame()
        local f = CreateFrame("Frame", nil, self, "DUIDialogHotkeyTemplate");
        f:SetShowDisabledKey(true);
        return f
    end

    local function RemoveHotkeyFrame(f)
        f:ClearKey();
        f:ClearAllPoints();
        f:SetParent(self);
    end

    self.hotkeyFramePool = API.CreateObjectPool(CreateHotkeyFrame, RemoveHotkeyFrame);
    
    self.numTabs = #Schematic;

    for i, tabData in ipairs(Schematic) do
        if not self.tabButtons[i] then
            self.tabButtons[i] = CreateFrame("Button", nil, self.Header.Container, "DUIDialogSettingsTabButtonTemplate");
            SetupRepositionObject(self.tabButtons[i]);
        end
        self.tabButtons[i].tabID = i;
        self.tabButtons[i]:SetName(tabData.tabName);
    end

    --Close Button
    local CloseButton = self.Header.CloseButton;
    for method, func in pairs(CloseButtonScripts) do
        CloseButton:SetScript(method, func);
    end
    CloseButton.Background:SetTexCoord(0, 0.5, 0, 0.5);
    CloseButton.Highlight:SetTexCoord(0.5, 1, 0, 0.5);
    CloseButton.Icon:SetTexCoord(0.0625, 0.1875, 0.625, 0.875);

    API.Mixin(self.ScrollFrame, ScrollFrameMixin);
    self.ScrollFrame:SetScript("OnMouseWheel", ScrollFrameMixin.OnMouseWheel);

    --ScrollBar
    local ScrollBar = addon.CreateScrollBar(self);
    self.ScrollBar = ScrollBar;
    self.ScrollFrame.scrollBar = ScrollBar;
    ScrollBar:SetOwner(self.ScrollFrame);
    ScrollBar:SetAlwaysVisible(false);
    ScrollBar:ShowScrollToBottomButton(false);
    ScrollBar:Show();

    self.Init = nil;

    self:LoadTheme();
end

function DUIDialogSettingsMixin:Layout()
    OPTIONBUTTON_HEIGHT = FONT_HEIGHT_NORMAL + 2*BUTTON_PADDING_LARGE;

    --Header
    local tabButtonHeight = FONT_HEIGHT_LARGE + 2*BUTTON_PADDING_LARGE;
    local minTabButtonWidth = 2 * tabButtonHeight;
    local headerHeight = tabButtonHeight;

    self.Header:ClearAllPoints();
    self.Header:SetPoint("TOPLEFT", self, "TOPLEFT", FRAME_PADDING, -FRAME_PADDING);
    self.Header:SetPoint("TOPRIGHT", self, "TOPRIGHT", -FRAME_PADDING, -FRAME_PADDING);
    self.Header:SetHeight(headerHeight);

    local tabButtonContainer = self.Header.Container;

    self.Header.CloseButton:ClearAllPoints();
    self.Header.CloseButton:SetParent(tabButtonContainer);
    self.Header.CloseButton:SetPoint("RIGHT", tabButtonContainer, "RIGHT", 0, 0);
    self.Header.CloseButton:SetSize(minTabButtonWidth, tabButtonHeight);
    self.Header.CloseButton.Icon:SetSize(FONT_HEIGHT_LARGE, FONT_HEIGHT_LARGE);

    self.HeaderDivider:ClearAllPoints();
    self.HeaderDivider:SetPoint("TOPLEFT", self.Header, "BOTTOMLEFT", 0, -TAB_BUTTON_GAP);
    self.HeaderDivider:SetPoint("TOPRIGHT", self.Header, "BOTTOMRIGHT", 0, -TAB_BUTTON_GAP);
    self.HeaderDivider:SetHeight(9);

    --Tab Buttons
    local buttonWidth;
    local tabButtonsSpan = 0;

    for i, button in ipairs(self.tabButtons) do
        buttonWidth = API.Round(button.Name:GetWrappedWidth() + 2*FONT_HEIGHT_LARGE);
        if buttonWidth < minTabButtonWidth then
            buttonWidth = minTabButtonWidth;
        end
        button:SetSize(buttonWidth, tabButtonHeight);
        tabButtonsSpan = tabButtonsSpan + buttonWidth;
        button:ClearAllPoints();
        if i > 1 then
            button:SetPoint("LEFT", self.tabButtons[i - 1], "RIGHT", TAB_BUTTON_GAP, 0);
            tabButtonsSpan = tabButtonsSpan + TAB_BUTTON_GAP;
        end
    end

    local tabFromOffsetX = (INPUT_DEVICE_GAME_PAD and 60) or 0;
    local firstTabButton = self.tabButtons[1];
    firstTabButton:ClearAllPoints();
    firstTabButton:SetPoint("LEFT", tabButtonContainer, "LEFT", tabFromOffsetX, 0);

    --ScrollFrame
    local scrollFrameWidth = OPTIONBUTTON_WIDTH;
    local scrollFrameHeight = NUM_VISIBLE_OPTIONS * OPTIONBUTTON_HEIGHT;
    local ScrollFrame = self.ScrollFrame;
    local gapToHeader = 12;
    ScrollFrame:ClearAllPoints();
    ScrollFrame:SetPoint("TOPLEFT", self.Header, "BOTTOMLEFT", 0, -gapToHeader);
    ScrollFrame:SetWidth(scrollFrameWidth);
    ScrollFrame:SetViewSize(scrollFrameHeight);

    --ScrollBar
    local ScrollBar = self.ScrollBar;
    local scrollBarOffsetX = OPTIONBUTTON_FROM_Y;
    ScrollBar:SetPoint("TOPLEFT", ScrollFrame, "TOPRIGHT", scrollBarOffsetX, 0);
    ScrollBar:SetPoint("BOTTOMLEFT", ScrollFrame, "BOTTOMRIGHT", scrollBarOffsetX, 0);
    ScrollBar:OnSizeChanged();

    self.VerticalDivider:ClearAllPoints();
    self.VerticalDivider:SetPoint("TOPLEFT", ScrollBar, "TOP", -2, 0);
    self.VerticalDivider:SetPoint("BOTTOMLEFT", ScrollBar, "BOTTOM", -2, 0);

    local frameWidth = API.Round((scrollFrameWidth + 1.5*FRAME_PADDING) / 0.618);
    local frameHeight = FRAME_PADDING + headerHeight + gapToHeader + scrollFrameHeight + FRAME_PADDING;

    local rightAreaWidth = API.Round(frameWidth - scrollFrameWidth - 2*FRAME_PADDING);
    local descriptionWidth = API.Round(frameWidth - scrollFrameWidth - 3*FRAME_PADDING -BUTTON_PADDING_LARGE);
    local previewShrink = 1;
    self.Preview:ClearAllPoints();
    self.Preview:SetPoint("TOP", self, "TOPRIGHT", -rightAreaWidth*0.5 -previewShrink, -(headerHeight + 2.5*FRAME_PADDING));

    local previewWidth = descriptionWidth - 2*previewShrink;
    local previewHeight = 0.5*previewWidth;
    self.Preview:SetSize(previewWidth, 0.5*previewWidth);
    self.previewHeight = previewHeight;

    self.Description:SetWidth(descriptionWidth);

    self.Description:ClearAllPoints();
    self.Description:SetPoint("TOP", self.Preview, "TOP", 0, -8);

    self:SetSize(frameWidth, frameHeight);
    --self.BackgroundGradient:SetWidth(frameHeight);
    self.BackgroundDecor:SetSize(rightAreaWidth, rightAreaWidth);

    self.DecorMask:SetSize(rightAreaWidth, rightAreaWidth);
    self.DecorMask:ClearAllPoints();
    self.DecorMask:SetPoint("BOTTOM", self.Description, "BOTTOM", 0, -16);

    --Reduce tab button size if necessary
    local headerObjectWidth = tabButtonsSpan + minTabButtonWidth + TAB_BUTTON_GAP;
    if INPUT_DEVICE_GAME_PAD then
        headerObjectWidth = headerObjectWidth + tabFromOffsetX + 4 * TAB_BUTTON_GAP + minTabButtonWidth;
    end

    local headerWidth = frameWidth - 2*FRAME_PADDING;

    if headerObjectWidth > headerWidth then
        if headerObjectWidth * 0.8 < headerWidth then
            tabButtonContainer:SetScale(0.8);
        else
            tabButtonContainer:SetScale(0.6);
        end
    else
        tabButtonContainer:SetScale(1);
    end
end

function DUIDialogSettingsMixin:SelectTabByID(tabID, forceUpdate)
    if tabID == self.tabID and not forceUpdate then return false end;

    if self.tabID then  --Save Scroll Position
        self["tabOffset"..self.tabID] = self.ScrollFrame:GetScrollOffset();
        self["tab"..self.tabID.."gamepadFocusIndex"] = self.gamepadFocusIndex;
    end

    self.tabID = tabID;

    --Update Options
    self.optionButtonPool:Release();
    self.checkboxPool:Release();
    self.arrowOptionPool:Release();
    self.dropdownButtonPool:Release();
    self.texturePool:Release();
    self.hotkeyFramePool:Release();

    self:ResetGamePadObjects();

    --Highlight Button
    self.Header.Selection:ClearAllPoints();
    self.Header.Selection:Hide();

    for i, button in ipairs(self.tabButtons) do
        if button.tabID == tabID then
            button:SetSelected(true);
            self.Header.Selection:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0);
            self.Header.Selection:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0);
            self.Header.Selection:Show();
        else
            button:SetSelected(false);
        end
    end

    if INPUT_DEVICE_GAME_PAD then
        local gap = 4 * TAB_BUTTON_GAP;
        local lb = self.hotkeyFramePool:Acquire();
        lb:SetKey("PADLSHOULDER");
        lb:SetPoint("LEFT", self.Header.Container, "LEFT", 0, 0);

        local firstTabButton = self.tabButtons[1];
        firstTabButton:ClearAllPoints();
        firstTabButton:SetPoint("LEFT", lb, "RIGHT", gap, 0);

        local rb = self.hotkeyFramePool:Acquire();
        rb:SetKey("PADRSHOULDER");
        rb:SetPoint("LEFT", self.tabButtons[ #self.tabButtons ], "RIGHT", gap, 0);
    end

    local tabData = Schematic[tabID];
    local optionButton;
    local numShownOptions = 0;
    local isOptionValid;

    local dbKeyToWidget = {};

    for i, optionData in ipairs(tabData.options) do
        if optionData.parentKey then
            isOptionValid = false;
            local requirement = optionData.requiredParentValue;
            local dbValue = GetDBValue(optionData.parentKey);

            if type(requirement) == "table" then
                for _, requiredParentValue in ipairs(requirement) do
                    if dbValue == requiredParentValue then
                        isOptionValid = true;
                        break
                    end
                end
            else
                if dbValue == optionData.requiredParentValue then
                    isOptionValid = true;
                end
            end


            if dbKeyToWidget[optionData.parentKey] then
                dbKeyToWidget[optionData.parentKey].isParentOption = true;
            end
        else
            isOptionValid = true;
        end

        if isOptionValid and optionData.validationFunc then
            isOptionValid = optionData.validationFunc();
        end

        if isOptionValid then
            numShownOptions = numShownOptions + 1;
            optionButton = self.optionButtonPool:Acquire();
            optionButton.isParentOption = nil;
            optionButton:SetParent(self.ScrollFrame);
            optionButton:SetData(optionData);
            optionButton:SetSize(OPTIONBUTTON_WIDTH, OPTIONBUTTON_HEIGHT);
            optionButton:SetPoint("TOPLEFT", self.ScrollFrame.Reference, "TOPLEFT", 0, (1 - numShownOptions)*OPTIONBUTTON_HEIGHT);
            if optionData.dbKey then
                dbKeyToWidget[optionData.dbKey] = optionButton;
            end
        end
    end

    self.ScrollFrame:SetContentHeight(numShownOptions * OPTIONBUTTON_HEIGHT);
    self.ScrollFrame:SetScrollOffset(self["tabOffset"..self.tabID] or 0);
    self.dbKeyToWidget = dbKeyToWidget;

    if GAME_PAD_ACTIVE then
        self:FocusObjectByIndex(self["tab"..self.tabID.."gamepadFocusIndex"] or 1);
    end
end

function DUIDialogSettingsMixin:SelectTabByDelta(delta)
    local tabID = self.tabID or 0;
    if delta > 0 and tabID < self.numTabs then
        self:SelectTabByID(tabID + 1);
    elseif delta < 0 and tabID > 1 then
        self:SelectTabByID(tabID - 1);
    end
end

function DUIDialogSettingsMixin:UpdateCurrentTab()
    self:SelectTabByID(self.tabID, true)
end

function DUIDialogSettingsMixin:RequestUpdate()
    if self:IsVisible() then
        self:UpdateCurrentTab();
    end
end

function DUIDialogSettingsMixin:SetFocusedObject(object)
    self.focusedObject = object;
    if object then
        local _;
        _, self.focusedObjectOffsetY = object:GetCenter();
    else
        self.focusedObjectOffsetY = nil;
    end
end

function DUIDialogSettingsMixin:ReAlignToFocusedObject()
    --The UI's dimension change with Font Size, so we need maintain the option's offsetY so players don't click another option by accident
    if self.focusedObject and self.focusedObject:IsShown() and self.focusedObjectOffsetY then
        local _, newOffsetY = self.focusedObject:GetCenter();
        local point, relativeTo, relativePoint, offsetX, offsetY = self:GetPoint(1);
        self:ClearAllPoints();
        self:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY + self.focusedObjectOffsetY - newOffsetY);
        self:UpdateScrollFrameBound();
    end
end

function DUIDialogSettingsMixin:ToggleUI()
    self:SetShown(not self:IsShown());
end

function DUIDialogSettingsMixin:GetOptionButtonByDBKey(dbKey)
    if dbKey and self.dbKeyToWidget then
        return self.dbKeyToWidget[dbKey]
    end
end

function DUIDialogSettingsMixin:UpdateOptionButtonByDBKey(dbKey)
    local optionButton = self:GetOptionButtonByDBKey(dbKey);
    if optionButton and optionButton:IsVisible() and optionButton.optionData and optionButton.widget then
        optionButton.widget:SetData(optionButton.optionData);
    end
end


DUIDialogSettingsTabButtonMixin = {};

function DUIDialogSettingsTabButtonMixin:OnEnter()
    MainFrame:HighlightButton(self);
end

function DUIDialogSettingsTabButtonMixin:OnLeave()
    MainFrame:HighlightButton(nil);
end

function DUIDialogSettingsTabButtonMixin:OnMouseDown(button)
    if button ~= "LeftButton" or self.isSelected then return end;
    self.Name:SetPoint("CENTER", 0, -1);
end

function DUIDialogSettingsTabButtonMixin:OnMouseUp()
    self.Name:SetPoint("CENTER", 0, 0);
end

function DUIDialogSettingsTabButtonMixin:OnClick()
    MainFrame:SelectTabByID(self.tabID);
    PlaySound("CHECKBOX_ON");
end

function DUIDialogSettingsTabButtonMixin:SetName(name)
    self.Name:SetText(string.upper(name));
end

function DUIDialogSettingsTabButtonMixin:SetSelected(state)
    if state then
        self.isSelected = true;
        self.Name:SetFontObject("DUIFont_Quest_Quest");
    else
        if self.isSelected then
            self.isSelected = nil;
            self.Name:SetFontObject("DUIFont_Quest_Gossip");
        end
    end
end


DUIDialogSettingsOptionMixin = {};

function DUIDialogSettingsOptionMixin:OnEnter()
    local choiceTooltip;

    if not self.isSubheader then
        MainFrame:HighlightButton(self);
        MainFrame:SetGamePadFocus(self);
        if self.widget then
            choiceTooltip = self.widget:GetSelectedChoiceTooltip();
        end
    end

    MainFrame:DisplayOptionInfo(self.optionData, choiceTooltip);
end

function DUIDialogSettingsOptionMixin:OnLeave()
    if not self:IsMouseOver() then
        MainFrame:HighlightButton(nil);
    end
end

function DUIDialogSettingsOptionMixin:OnClick(button)
    MainFrame:SetFocusedObject(self);

    if self.widgetType == "Checkbox" and self.widget and self.widget.OnClick and self.widget:IsEnabled() then
        self.widget:OnClick(button);
    elseif self.optionData.onClickFunc then
        self.optionData.onClickFunc(self);
    end

    MainFrame:HighlightButton(nil);
    self:OnEnter();
end

function DUIDialogSettingsOptionMixin:AttachWidget(widgetPool, rightOffsetRatio)
    local right = (rightOffsetRatio and rightOffsetRatio * OPTION_WIDGET_SIZE) or 0;
    self.widget = widgetPool:Acquire();
    self.widget:SetParent(self);
    self.widget:SetPoint("RIGHT", self, "RIGHT", -BUTTON_PADDING_LARGE -right, 0);
    self.widget:SetWidgetHeight(OPTION_WIDGET_SIZE);
end

function DUIDialogSettingsOptionMixin:SetCheckbox(optionData)
    self:AttachWidget(MainFrame.checkboxPool);
    self.widget:SetData(optionData);
end

function DUIDialogSettingsOptionMixin:SetArrowOption(optionData)
    self:AttachWidget(MainFrame.arrowOptionPool);
    self.widget:SetData(optionData);
end

function DUIDialogSettingsOptionMixin:SetDropdownButton(optionData)
    self:AttachWidget(MainFrame.dropdownButtonPool, 0.125);
    self.widget:SetData(optionData);
end

function DUIDialogSettingsOptionMixin:SetCustomButton(optionData)
    self.widget = nil;
end


function DUIDialogSettingsOptionMixin:SetSubheader()
    --[[
    local icon = MainFrame.texturePool:Acquire();
    icon:SetSize(FONT_HEIGHT_NORMAL, FONT_HEIGHT_NORMAL);
    icon:SetTexture(FILE_PATH.."Settings-SubheaderIcon.png");
    icon:SetVertexColor(0.50, 0.36, 0.24);
    icon:SetPoint("LEFT", self, "LEFT", 4, 0);
    icon:SetParent(self);
    --]]
end

function DUIDialogSettingsOptionMixin:SetData(optionData)
    self.optionData = optionData;
    self.dbKey = optionData.dbKey;
    self.updateTabAfterClicks = optionData.updateTabAfterClicks;

    local isSubheader;

    if optionData.type == "Subheader" then
        isSubheader = true;
        self:SetSubheader();
    elseif optionData.type == "Checkbox" then
        self:SetCheckbox(optionData);
    elseif optionData.type == "ArrowOption" then
        self:SetArrowOption(optionData);
    elseif optionData.type == "DropdownButton" then
        if INPUT_DEVICE_GAME_PAD then   --We convert Dropdown to ArrowOption because of UX
            self:SetArrowOption(optionData);
        else
            self:SetDropdownButton(optionData);
        end
    elseif optionData.type == "Custom" then
        self:SetCustomButton(optionData);
    end
    self.widgetType = optionData.type;

    if isSubheader then
        self.Label:SetText(string.upper(optionData.name));
        if not self.isSubheader then
            self.Label:SetFontObject("DUIFont_Settings_Disabled");
        end
    else
        self.Label:SetText(optionData.name);
        if self.isSubheader then
            self.Label:SetFontObject("DUIFont_Quest_Paragraph");
        end
        MainFrame:IndexGamePadObject(self);
    end
    self.isSubheader = isSubheader;

    local nameOffset;

    if optionData.parentKey then
        nameOffset = OPTIONBUTTON_LABEL_OFFSET + 24;
        local branch = MainFrame.texturePool:Acquire();
        branch:SetSize(OPTIONBUTTON_HEIGHT*0.5, OPTIONBUTTON_HEIGHT*0.5);
        branch:SetTexture(ThemeUtil:GetTextureFile("Settings-SubOptionIcon.png"));
        branch:SetVertexColor(1, 1, 1, 0.5);
        branch:SetPoint("BOTTOM", self, "LEFT", OPTIONBUTTON_LABEL_OFFSET + 2, 0);
        branch:SetParent(self);
    else
        nameOffset = OPTIONBUTTON_LABEL_OFFSET;
    end

    if optionData.icon then
        local icon = MainFrame.texturePool:Acquire();
        local iconSize = OPTION_WIDGET_SIZE;
        local iconOffset = -0.125*iconSize;
        icon:SetSize(iconSize, iconSize);
        icon:SetTexture(ThemeUtil:GetTextureFile(optionData.icon));
        icon:SetVertexColor(1, 1, 1, 1);
        icon:SetPoint("LEFT", self, "LEFT", nameOffset + iconOffset, 0);
        icon:SetParent(self);
        nameOffset = nameOffset + iconSize;
    end

    self.Label:ClearAllPoints();
    self.Label:SetPoint("LEFT", self, "LEFT", nameOffset, 0);
end


do  --ArrowOption
    DUIDialogSettingsArrowOptionMixin = {};

    local function ArrowButton_OnClick(self)
        self:GetParent():SelectChoiceByDelta(self.delta);
        PlaySound("CHECKBOX_ON");
    end

    local function ArrowButton_OnEnter(self)
        self:GetParent():GetParent():OnEnter();
    end

    local function ArrowButton_OnLeave(self)
        self:GetParent():GetParent():OnLeave();
    end

    local function ArrowButton_OnMouseDown(self)
        if not self:IsEnabled() then return end;

        if self.delta < 0 then
            self.Texture:SetPoint("CENTER", -1, 0);
        else
            self.Texture:SetPoint("CENTER", 1, 0);
        end
    end

    local function ArrowButton_OnMouseUp(self)
        self.Texture:SetPoint("CENTER", 0, 0);
    end

    local function ArrowButton_OnEnable(self)
        self:SetAlpha(1);
    end

    local function ArrowButton_OnDisable(self)
        self:SetAlpha(DISABLED_TEXTURE_ALPHA);
    end

    local function RemoveBar(bar)
        bar:Hide();
        bar:ClearAllPoints();
    end

    local function OnAcquireBar(bar)
        bar:SetTexture(ThemeUtil:GetTextureFile("Settings-ArrowOption.png"));
    end

    function DUIDialogSettingsArrowOptionMixin:OnLoad()
        self.ValueText:SetPoint("TOP", self, "TOP", 0, ARROWOPTION_VALUETEXT_OFFSET_Y);

        self.LeftArrow.delta = -1;
        self.LeftArrow:SetScript("OnEnter", ArrowButton_OnEnter);
        self.LeftArrow:SetScript("OnLeave", ArrowButton_OnLeave);
        self.LeftArrow:SetScript("OnClick", ArrowButton_OnClick);
        self.LeftArrow:SetScript("OnMouseDown", ArrowButton_OnMouseDown);
        self.LeftArrow:SetScript("OnMouseUp", ArrowButton_OnMouseUp);
        self.LeftArrow:SetScript("OnEnable", ArrowButton_OnEnable);
        self.LeftArrow:SetScript("OnDisable", ArrowButton_OnDisable);

        self.RightArrow.delta = 1;
        self.RightArrow:SetScript("OnEnter", ArrowButton_OnEnter);
        self.RightArrow:SetScript("OnLeave", ArrowButton_OnLeave);
        self.RightArrow:SetScript("OnClick", ArrowButton_OnClick);
        self.RightArrow:SetScript("OnMouseDown", ArrowButton_OnMouseDown);
        self.RightArrow:SetScript("OnMouseUp", ArrowButton_OnMouseUp);
        self.RightArrow:SetScript("OnEnable", ArrowButton_OnEnable);
        self.RightArrow:SetScript("OnDisable", ArrowButton_OnDisable);

        local function CreateBar()
            local bar = self:CreateTexture(nil, "OVERLAY");
            bar:SetTextureSliceMargins(1, 1, 1, 1);
            bar:SetTextureSliceMode(1);
            bar:SetTexCoord(0, 16/128, 124/128, 1);
            return bar
        end

        self.barPool = API.CreateObjectPool(CreateBar, RemoveBar, OnAcquireBar);
    end

    function DUIDialogSettingsArrowOptionMixin:SetNumChoices(numChoices, forceUpdate)
        if numChoices ~= self.numChoices or forceUpdate then
            self.barPool:Release();
            self.numChoices = numChoices;
            self.bars = {};
            local barHeight = API.GetPixelForWidget(self, ARROWOTPION_BAR_HEIGHT);
            local gap = API.GetPixelForWidget(self, 4);
            local buttonWidth = self.LeftArrow:GetWidth();
            local barShrink = 4;
            local fromOffsetX = buttonWidth + barShrink;
            local barWidth = (self:GetWidth() -2*barShrink - 2*buttonWidth - (numChoices - 1)*gap) / numChoices;
            local bar;
            for i = 1, numChoices do
                bar = self.barPool:Acquire();
                bar:SetSize(barWidth, barHeight);
                bar:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", fromOffsetX + (gap + barWidth) * (i - 1), 2);
                self.bars[i] = bar;
            end
        end
    end

    function DUIDialogSettingsArrowOptionMixin:GetCentralWidth()
        return self:GetWidth() - 2*self.LeftArrow:GetWidth();
    end

    function DUIDialogSettingsArrowOptionMixin:SetWidgetWidth(width)
        local centralWidth = self:GetCentralWidth();
    end

    function DUIDialogSettingsArrowOptionMixin:SetWidgetHeight(height)
        self.LeftArrow.Texture:SetSize(height, height);
        self.RightArrow.Texture:SetSize(height, height);
        self:SetHeight(height);
        self:SetWidth(height * ARROWOTPION_WIDTH_RATIO);
    end

    function DUIDialogSettingsArrowOptionMixin:SetValueTextByID(id)
        if self.valueTextFormatter then
            self.valueTextFormatter(self, self.choices[id].dbValue);
        else
            local valueText = self.choices[id].valueText;
            self.ValueText:SetText(valueText);
        end
    end

    function DUIDialogSettingsArrowOptionMixin:SelectChoiceByIndex(id)
        if not self.choices[id] then
            id = 1;
        end

        local choiceData = self.choices[id];
        if choiceData then
            self:SetValueTextByID(id);
        end

        self.selectedID = id;

        for i, bar in ipairs(self.bars) do
            if i == id then
                bar:SetAlpha(1);
            else
                bar:SetAlpha(DISABLED_TEXTURE_ALPHA);
            end
        end

        self.LeftArrow:SetEnabled(id ~= 1);
        self.RightArrow:SetEnabled(id ~= self.numChoices);
    end

    function DUIDialogSettingsArrowOptionMixin:SelectNextChoice()
        if ARROWOTPION_CYCLING then
            self.selectedID = self.selectedID + 1;
            if self.selectedID > self.numChoices then
                self.selectedID = 1;
            end
        else
            if self.selectedID < self.numChoices then
                self.selectedID = self.selectedID + 1;
            else
                return false
            end
        end

        self:SelectChoiceByIndex(self.selectedID);
        return true
    end

    function DUIDialogSettingsArrowOptionMixin:SelectPreviousChoice()
        if ARROWOTPION_CYCLING then
            self.selectedID = self.selectedID - 1;
            if self.selectedID < 1 then
                self.selectedID = self.numChoices;
            end
        else
            if self.selectedID > 1 then
                self.selectedID = self.selectedID - 1;
            else
                return false
            end
        end

        self:SelectChoiceByIndex(self.selectedID);
        return true
    end

    function DUIDialogSettingsArrowOptionMixin:SelectChoiceByDelta(delta)
        --right = 1, left = -1
        local anyChange;

        if delta > 0 then
            anyChange = self:SelectNextChoice();
        else
            anyChange = self:SelectPreviousChoice();
        end

        if anyChange then
            self:PostClick();
        end
    end

    function DUIDialogSettingsArrowOptionMixin:PostClick()
        local optionButton = self:GetParent();
        MainFrame:SetFocusedObject(optionButton);

        local value = self.choices[self.selectedID].dbValue;
        SetDBValue(optionButton.dbKey, value, true);

        if optionButton.isParentOption or optionButton.updateTabAfterClicks then
            MainFrame:UpdateCurrentTab();
        end

        if self.realignAfterClicks then
            MainFrame:ReAlignToFocusedObject();
        end

        self:GetParent():OnEnter();
    end

    function DUIDialogSettingsArrowOptionMixin:SetData(optionData)
        local choices = optionData.choices;

        if type(choices) == "function" then
            self.choices = choices(optionData.dbKey);
        else
            self.choices = choices;
        end

        self.dbKey = optionData.dbKey;
        self.valueTextFormatter = optionData.valueTextFormatter;
        self.realignAfterClicks = optionData.realignAfterClicks;

        self:SetNumChoices(#self.choices);

        if not optionData.hasHotkey then
            self.ValueText:ClearAllPoints();
            self.ValueText:SetPoint("TOP", self, "TOP", 0, ARROWOPTION_VALUETEXT_OFFSET_Y);
        end

        local selectedID = 1;
        local dbValue = GetDBValue(self.dbKey);

        for id, choiceData in ipairs(self.choices) do
            if dbValue == choiceData.dbValue then
                selectedID = id;
                break
            end
        end

        self:SelectChoiceByIndex(selectedID);
    end

    function DUIDialogSettingsArrowOptionMixin:SetTexture(file)
        self.LeftArrow.Texture:SetTexture(file);
        self.LeftArrow.Highlight:SetTexture(file);
        self.RightArrow.Texture:SetTexture(file);
        self.RightArrow.Highlight:SetTexture(file);
    end

    function DUIDialogSettingsArrowOptionMixin:GetSelectedChoiceTooltip()
        if self.selectedID and self.choices and self.choices[self.selectedID] then
            local tooltip = self.choices[self.selectedID].tooltip;
            if type(tooltip) == "function" then
                return tooltip()
            else
                return tooltip
            end
        end
    end
end


do  --Checkbox
    DUIDialogSettingsCheckboxMixin = {};

    function DUIDialogSettingsCheckboxMixin:OnEnter()
        self:GetParent():OnEnter();
    end

    function DUIDialogSettingsCheckboxMixin:OnLeave()
        self:GetParent():OnLeave();
    end

    function DUIDialogSettingsCheckboxMixin:SetTexture(file)
        self.Background:SetTexture(file);
        self.Check:SetTexture(file);
    end

    function DUIDialogSettingsCheckboxMixin:OnClick()
        self:Toggle();

        local optionButton = self:GetParent();
        SetDBValue(optionButton.dbKey, self.checked, true);

        if optionButton.isParentOption or optionButton.updateTabAfterClicks then
            MainFrame:UpdateCurrentTab();
        end

        self:OnEnter();

        if self.checked then
            PlaySound("CHECKBOX_ON");
        else
            PlaySound("CHECKBOX_OFF");
        end
    end

    function DUIDialogSettingsCheckboxMixin:SetData(optionData)
        self.dbKey = optionData.dbKey;
        self:SetChecked(GetDBValue(optionData.dbKey) == true);
    end

    function DUIDialogSettingsCheckboxMixin:SetChecked(state)
        self.checked = state;
        self.Check:SetShown(state);
        if state then
            self.Background:SetTexCoord(0.5, 1, 0, 0.5);
        else
            self.Background:SetTexCoord(0, 0.5, 0, 0.5);
        end
    end

    function DUIDialogSettingsCheckboxMixin:GetChecked()
        return self.checked == true
    end

    function DUIDialogSettingsCheckboxMixin:Toggle()
        self.checked = not self.checked;
        self:SetChecked(self.checked);
    end

    function DUIDialogSettingsCheckboxMixin:SetWidgetHeight(height)
        self:SetSize(height, height);
        self.Check:SetSize(height*0.5, height*0.5);
    end

    function DUIDialogSettingsCheckboxMixin:GetSelectedChoiceTooltip()
        local optionButton = self:GetParent();
        local tooltip = optionButton.optionData and optionButton.optionData.tooltip;
        if tooltip then
            if type(tooltip) == "function" then
                return tooltip(self.checked)
            else
                return tooltip
            end
        end
    end
end


do  --DropdownButton
    DUIDialogSettingsDropdownButtonMixin = {};

    function DUIDialogSettingsDropdownButtonMixin:OnEnter()
        self.Background:SetTexCoord(0, 1, 68/256, 132/256);
        self:GetParent():OnEnter();
    end

    function DUIDialogSettingsDropdownButtonMixin:OnLeave()
        self.Background:SetTexCoord(0, 1, 0, 64/256);
        self:GetParent():OnLeave();
    end

    function DUIDialogSettingsDropdownButtonMixin:OnClick()
        self:ToggleMenu();
        PlaySound("CHECKBOX_ON");
    end

    function DUIDialogSettingsDropdownButtonMixin:SetTexture(file)
        self.Background:SetTexture(file);
        self.Arrow:SetTexture(file);
    end

    function DUIDialogSettingsDropdownButtonMixin:SetWidgetHeight(height)
        local width = 8*height; --ratio
        self:SetSize(width, height);
        local arrowSize = 0.5*height;
        self.Arrow:SetSize(arrowSize, arrowSize);
    end

    function DUIDialogSettingsDropdownButtonMixin:ToggleMenu()
        self.menuShown = not self.menuShown;
        if self.menuShown then
            self:ShowMenu();
        else
            self:HideMenu();
        end
    end

    function DUIDialogSettingsDropdownButtonMixin:ShowMenu()
        self.menuShown = true;
        self.Arrow:SetTexCoord(36/512, 68/512, 224/256, 1);
        if true then
            local menu = addon.GetDropdownMenu(self);
            menu:SetOwner(self, MainFrame);
            menu:Show();
            menu:SetMenuData(TTSVoice_BuildMenuData(self, self.dbKey));
        end
    end

    function DUIDialogSettingsDropdownButtonMixin:OnMenuClosed()
        self.menuShown = nil;
        self.Arrow:SetTexCoord(0/512, 32/512, 224/256, 1);
    end

    function DUIDialogSettingsDropdownButtonMixin:HideMenu()
        self.menuShown = nil;
        self:OnMenuClosed();
        if true then
            addon.CloseDropdownMenu();
        end
    end

    function DUIDialogSettingsDropdownButtonMixin:SetText(text)
        self.ValueText:SetText(text);
    end

    function DUIDialogSettingsDropdownButtonMixin:SetPadding(left)
        self.ValueText:SetPoint("LEFT", self, "LEFT", left, 0);
        self.Arrow:SetPoint("RIGHT", self, "RIGHT", -left, 0);
    end

    function DUIDialogSettingsDropdownButtonMixin:SetValueTextByID(id)
        if self.valueTextFormatter then
            self.valueTextFormatter(self, self.choices[id].dbValue);
        else
            self.ValueText:SetText(id);
        end
    end

    function DUIDialogSettingsDropdownButtonMixin:SelectChoiceByIndex(id)
        if not self.choices[id] then
            id = 1;
        end

        local choiceData = self.choices[id];
        if choiceData then
            self.selectedID = id;
            self:SetValueTextByID(id);
            local dbKey = self.dbKey;
            SetDBValue(dbKey, choiceData.dbValue, true);
            MainFrame:UpdateOptionButtonByDBKey(dbKey);
            self:GetParent():OnEnter();
        end
    end

    function DUIDialogSettingsDropdownButtonMixin:SelectChoiceByDelta(delta)
        local id;

        if not self.choices[id] then
            id = 1;
        end

        if delta < 0 then
            id = self.selectedID - 1;
        else
            id = self.selectedID + 1;
        end

        id = Clamp(id, 1, #self.choices);
        self:SelectChoiceByIndex(id);
    end

    function DUIDialogSettingsDropdownButtonMixin:SetData(optionData)
        self.dbKey = optionData.dbKey;
        self.valueTextFormatter = optionData.valueTextFormatter;

        local choices = optionData.choices;

        if type(choices) == "function" then
            self.choices = choices(optionData.dbKey);
        else
            self.choices = choices;
        end

        local selectedID = 1;
        local dbValue = GetDBValue(self.dbKey);

        for id, data in ipairs(self.choices) do
            if data.dbValue == dbValue then
                selectedID = id;
            end
        end
        self.selectedID = selectedID;

        self:SetValueTextByID(selectedID);
    end

    function DUIDialogSettingsDropdownButtonMixin:GetSelectedChoiceTooltip()
        local optionButton = self:GetParent();
        local tooltip = optionButton.optionData and optionButton.optionData.tooltip;
        if tooltip then
            if type(tooltip) == "function" then
                return tooltip(self)
            else
                return tooltip
            end
        end
    end
end


do  --GamePad/Controller
    function DUIDialogSettingsMixin:ResetGamePadObjects()
        self.gamepadMaxIndex = 0;
        self.gamepadFocusIndex = nil;
        self.gamepadFocus = nil;
        self.gamepadObjects = {};
    end

    function DUIDialogSettingsMixin:IndexGamePadObject(object)
        self.gamepadMaxIndex = self.gamepadMaxIndex + 1;
        self.gamepadObjects[self.gamepadMaxIndex] = object;
        object.gamepadIndex = self.gamepadMaxIndex;
    end

    function DUIDialogSettingsMixin:ClearGamePadFocus()
        if self.gamepadFocus then
            --self.gamepadFocus:OnLeave();
            self.gamepadFocus = nil;
        end
    end

    function DUIDialogSettingsMixin:SetGamePadFocus(optionButton)
        self.gamepadFocusIndex = optionButton.gamepadIndex;
        self.gamepadFocus = optionButton;
    end

    function DUIDialogSettingsMixin:FocusObjectByIndex(index)
        local object = self.gamepadObjects[index];
        if object then
            self.gamepadFocusIndex = index;
            self.gamepadFocus = object;
            self.gamepadFocus:OnEnter();
            return true
        end
    end

    function DUIDialogSettingsMixin:FocusObjectByDelta(delta)
        local maxIndex = self.gamepadMaxIndex or 0;
        local index = self.gamepadFocusIndex;

        if not index then
            index = 0;
        end

        if delta < 0 and index < maxIndex then
            index = index + 1;
        elseif delta > 0 and index > 1 then
            index = index - 1;
        elseif index == 0 then
            index = 1;
        else
            return
        end

        self:ClearGamePadFocus();

        if self:FocusObjectByIndex(index) then
            local threshold = 2 * OPTIONBUTTON_HEIGHT;
            if delta > 0 then
                local top = self.gamepadFocus:GetTop();
                if top + threshold >= self.scrollFrameTop then
                    self.ScrollFrame:ScrollBy(-OPTIONBUTTON_HEIGHT);
                end
            else
                local bottom = self.gamepadFocus:GetBottom();
                if bottom - threshold <= self.scrollFrameBottom then
                    self.ScrollFrame:ScrollBy(OPTIONBUTTON_HEIGHT);
                end
            end
            return true
        end
    end

    function DUIDialogSettingsMixin:FocusNextObject()
        if self:FocusObjectByDelta(1) then
            return
        end
    end

    function DUIDialogSettingsMixin:FocusPreviousObject()
        if self:FocusObjectByDelta(-1) then
            return
        end
    end

    function DUIDialogSettingsMixin:ClickFocusedObject(gamepadButton)
        if self.gamepadFocus then
            local optionButton = self.gamepadFocus;
            if gamepadButton == "PAD1" then
                optionButton:OnClick();
            elseif gamepadButton == "PADDLEFT" then
                if optionButton.widgetType == "ArrowOption" or optionButton.widgetType == "DropdownButton" then
                    optionButton.widget:SelectChoiceByDelta(-1);
                end
            elseif gamepadButton == "PADDRIGHT" then
                if optionButton.widgetType == "ArrowOption" or optionButton.widgetType == "DropdownButton" then
                    optionButton.widget:SelectChoiceByDelta(1);
                end
            end
            return true
        end
        return false
    end
end


function DialogueUI_ShowSettingsFrame()
    MainFrame:ToggleUI();
end


do
    local function OnFontSizeChanged(baseFontSize, fontSizeID)
        FONT_HEIGHT_LARGE = baseFontSize;
        FONT_HEIGHT_NORMAL = baseFontSize;

        BUTTON_PADDING_LARGE = FONT_HEIGHT_NORMAL;
        OPTIONBUTTON_HEIGHT = 3*FONT_HEIGHT_NORMAL;
        OPTION_WIDGET_SIZE = 2 * FONT_HEIGHT_NORMAL;

        local widthMultiplier;

        if fontSizeID <= 1 then
            NUM_VISIBLE_OPTIONS = 10.5;
            widthMultiplier = 12;
            ARROWOTPION_WIDTH_RATIO = 7;
            ARROWOTPION_BAR_HEIGHT = 5;
        elseif fontSizeID == 2 then
            NUM_VISIBLE_OPTIONS = 9.5;
            widthMultiplier = 11;
            ARROWOTPION_WIDTH_RATIO = 7;
            ARROWOTPION_BAR_HEIGHT = 6;
        elseif fontSizeID == 3 then
            NUM_VISIBLE_OPTIONS = 8.5;
            widthMultiplier = 10;
            ARROWOTPION_WIDTH_RATIO = 6;
            ARROWOTPION_BAR_HEIGHT = 6;
        else
            NUM_VISIBLE_OPTIONS = 8.5;
            widthMultiplier = 10;
            ARROWOTPION_WIDTH_RATIO = 6;
            ARROWOTPION_BAR_HEIGHT = 6;
        end

        OPTIONBUTTON_WIDTH = widthMultiplier * OPTIONBUTTON_HEIGHT;
    end
    addon.CallbackRegistry:Register("FontSizeChanged", OnFontSizeChanged);

    local function PostFontSizeChanged()
        --We wait after hotkey frame size update
        local f = MainFrame;

        if f.Init then return end;

        if f.arrowOptionPool then
            local function ModifyArrowOption(widget)
                widget:SetWidgetHeight(OPTION_WIDGET_SIZE);
                widget.numChoices = 0;
            end
            f.arrowOptionPool:ProcessAllObjects(ModifyArrowOption);
        end

        if f.dropdownButtonPoolPool then
            local function ModifyDropdownButton(widget)
                widget:SetWidgetHeight(OPTION_WIDGET_SIZE);
            end
            f.dropdownButtonPoolPool:ProcessAllObjects(ModifyDropdownButton);
        end

        if f.hotkeyFramePool then
            local method = "UpdateBaseHeight";
            f.hotkeyFramePool:CallAllObjects(method);
        end

        f:Layout();
        f:UpdateCurrentTab();
    end
    addon.CallbackRegistry:Register("PostFontSizeChanged", PostFontSizeChanged);

    local function PostInputDeviceChanged(dbValue)
        INPUT_DEVICE_GAME_PAD = dbValue ~= 1;
        INPUT_DEVICE_ID = dbValue;

        local f = MainFrame;
        if f.Init then return end;

        f:Layout();
        f:UpdateCurrentTab();
    end
    addon.CallbackRegistry:Register("PostInputDeviceChanged", PostInputDeviceChanged);
end

do  --Create an entrance to settings in Blizzard addon settings window
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local f = CreateFrame("Frame");
        f:SetSize(8, 8);    --will be changed by API

        local paddingV = 96;

        local bg = f:CreateTexture(nil, "BACKGROUND");
        bg:SetPoint("BOTTOM", f, "BOTTOM", 0, paddingV);
        bg:SetTexture(PREVIEW_PATH.."GameMenuImage.jpg");
        local mask = f:CreateMaskTexture(nil, "BACKGROUND");
        mask:SetPoint("TOPLEFT", bg, "TOPLEFT", 0, 0);
        mask:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", 0, 0);
        mask:SetTexture(PREVIEW_PATH.."GameMenuImage-Mask.tga");
        bg:AddMaskTexture(mask);

        local Text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
        Text:SetJustifyH("CENTER");
        Text:SetJustifyV("MIDDLE");
        Text:SetSpacing(4);
        Text:SetPoint("CENTER", f, "TOP", 0, 0);

        local function SetupInstruction()
            if C_CVar.GetCVarBool("GamePadEnable") then
                Text:SetText(L["Instuction Open Settings Console"]);
            else
                Text:SetText(L["Instuction Open Settings"]);
            end
        end

        local function OnFrameSizeChanged()
            local width = f:GetWidth();
            local height = f:GetHeight();
            local imageHeight = width * 0.5;
            local imageVisualHeight = imageHeight * 0.9;

            paddingV = (height - imageVisualHeight) / 3;

            Text:SetWidth(width - 64);
            Text:ClearAllPoints();
            Text:SetPoint("CENTER", f, "TOP", 0, -paddingV);

            bg:SetSize(width, imageHeight);
            bg:ClearAllPoints();
            bg:SetPoint("CENTER", f, "BOTTOM", 0, paddingV + imageHeight * 0.5);

            ThemeUtil:SetFontColor(Text, "DarkModeGoldDim");

            SetupInstruction();
        end

        f:SetScript("OnShow", function()
            OnFrameSizeChanged();
            f:SetScript("OnShow", SetupInstruction);
        end);

        f:SetScript("OnSizeChanged", OnFrameSizeChanged);


        local category = Settings.RegisterCanvasLayoutCategory(f, "Dialogue UI");
        Settings.RegisterAddOnCategory(category);
    end
end