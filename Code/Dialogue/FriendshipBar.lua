local _, addon = ...
local API = addon.API;
local TooltipFrame = addon.SharedTooltip;
local Clamp = API.Clamp;
local Lerp = API.ClampLerp;

local GetFriendshipReputation = C_GossipInfo.GetFriendshipReputation;
local GetFriendshipReputationRanks = C_GossipInfo.GetFriendshipReputationRanks;

local FRAME_SIZE = 52;
local FriendshipBar = CreateFrame("Frame");
addon.FriendshipBar = FriendshipBar;
FriendshipBar:SetSize(FRAME_SIZE, FRAME_SIZE);
FriendshipBar.textures = {};


--Positive: Counter-clockwise
local RAD_FILL1_BEGIN = math.pi *(5/4);
local RAD_FILL1_END = math.pi *(1/2);
local RAD_FILL2_BEGIN = RAD_FILL1_END;
local RAD_FILL2_END = 0;
local RAD_FILL3_BEGIN = RAD_FILL2_END;
local RAD_FILL3_END = math.pi * (-1/2);
local RAD_FILL4_BEGIN = RAD_FILL3_END;
local RAD_FILL4_END = math.pi * (-5/4);


local function CreateTextureMask(frame, maskedTexture, layer)
    local mask = frame:CreateMaskTexture(nil, layer);
    maskedTexture:AddMaskTexture(mask);
    mask:SetTexture("Interface/AddOns/DialogueUI/Art/BasicShapes/Mask-RightWhite", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
    mask:SetSize(26, 26);
    return mask
end

local function SetTextureNumber(texture, number)
    --Bake number into textures for visual consistency
    number = Clamp(number, 1, 9);
    texture:SetTexCoord((number - 1)*0.0625, number*0.0625, 0, 1);
end

function FriendshipBar:Init()
    local Container = CreateFrame("Frame", nil, self);
    Container:SetSize(FRAME_SIZE, FRAME_SIZE);
    Container:SetPoint("CENTER", self, "CENTER", 0, 0);
    self.Container = Container;

    local tinsert = table.insert;

    local FrontTexture = Container:CreateTexture(nil, "OVERLAY", nil, 3);
    FrontTexture:SetTexCoord(0.0625, 0.4375, 0.0625, 0.4375);
    FrontTexture:SetAllPoints(true);
    self.FrontTexture = FrontTexture;
    tinsert(self.textures, FrontTexture);

    local BackTexture = Container:CreateTexture(nil, "BACKGROUND");
    BackTexture:SetTexCoord(0.5625, 0.9375, 0.0625, 0.4375);
    BackTexture:SetAllPoints(true);
    self.BackTexture = BackTexture;
    tinsert(self.textures, BackTexture);


    local fillLayer = "ARTWORK";

    local FillFull = Container:CreateTexture(nil, fillLayer);
    FillFull:SetTexCoord(0.5625, 0.9375, 0.0625, 0.4375);
    FillFull:SetAllPoints(true);
    self.FillFull = FillFull;
    tinsert(self.textures, FillFull);

    --Top Right Piece
    local Fill1 = Container:CreateTexture(nil, fillLayer);
    Fill1:SetTexCoord(0.25, 0.4375, 0.5625, 0.703125);
    Fill1:SetSize(FRAME_SIZE*0.5, FRAME_SIZE*0.5*0.75);
    Fill1:SetPoint("BOTTOMLEFT", Container, "CENTER", 0, 6.4);
    self.Fill1 = Fill1;
    tinsert(self.textures, Fill1);

    self.Mask1 = CreateTextureMask(Container, Fill1, fillLayer);
    self.Mask1:SetSize(26, 26);
    self.Mask1:SetPoint("CENTER", Container, "CENTER", FRAME_SIZE/6, FRAME_SIZE/6*0.75)
    self.Mask1:SetRotation(RAD_FILL1_BEGIN);

    --Bottom Right Piece
    local Fill2 = Container:CreateTexture(nil, fillLayer);
    Fill2:SetTexCoord(0.25, 0.4375, 0.703125, 0.9375);
    Fill2:SetSize(FRAME_SIZE*0.5, FRAME_SIZE*0.5*1.25);
    Fill2:SetPoint("TOPLEFT", Container, "CENTER", 0, 6.4);
    self.Fill2 = Fill2;
    tinsert(self.textures, Fill2);

    self.Mask2 = CreateTextureMask(Container, Fill2, fillLayer);
    self.Mask2:SetSize(52, 52);
    self.Mask2:SetPoint("CENTER", Container, "CENTER", 0, 6.4);
    self.Mask2:SetRotation(RAD_FILL2_BEGIN);

    --Bottom Left Piece
    local Fill3 = Container:CreateTexture(nil, fillLayer);
    Fill3:SetTexCoord(0.0625, 0.25, 0.703125, 0.9375);
    Fill3:SetSize(FRAME_SIZE*0.5, FRAME_SIZE*0.5*1.25);
    Fill3:SetPoint("TOPRIGHT", Container, "CENTER", 0, 6.4);
    self.Fill3 = Fill3;
    tinsert(self.textures, Fill3);

    self.Mask3 = CreateTextureMask(Container, Fill3, fillLayer);
    self.Mask3:SetSize(52, 52);
    self.Mask3:SetPoint("CENTER", Container, "CENTER", 0, 6.4);
    self.Mask3:SetRotation(RAD_FILL3_BEGIN);

    --Top Left Piece
    local Fill4 = Container:CreateTexture(nil, fillLayer);
    Fill4:SetTexCoord(0.0625, 0.25, 0.5625, 0.703125);
    Fill4:SetSize(FRAME_SIZE*0.5, FRAME_SIZE*0.5*0.75);
    Fill4:SetPoint("BOTTOMRIGHT", Container, "CENTER", 0, 6.4);
    self.Fill4 = Fill4;
    tinsert(self.textures, Fill4);

    self.Mask4 = CreateTextureMask(Container, Fill4, fillLayer);
    self.Mask4:SetSize(26, 26);
    self.Mask4:SetPoint("CENTER", Container, "CENTER", -FRAME_SIZE/6, FRAME_SIZE/6*0.75)
    self.Mask4:SetRotation(RAD_FILL4_BEGIN);


    local Surface = Container:CreateTexture(nil, fillLayer, nil, 4);
    Surface:SetTexCoord(0.5625, 0.9375, 0.5625, 0.9375);
    Surface:SetSize(52, 52);
    Surface:SetPoint("CENTER", Container, "CENTER", 0, 0);
    Surface:Hide();
    self.Surface = Surface;
    tinsert(self.textures, Surface);

    local FillMask = Container:CreateMaskTexture(nil, fillLayer, nil, 4);
    Surface:AddMaskTexture(FillMask);
    FillMask:SetTexture("Interface/AddOns/DialogueUI/Art/Theme_Shared/Mask-HeartFill", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
    FillMask:SetSize(69, 69);
    FillMask:SetPoint("CENTER", Container, "CENTER", 0, 0);


    --[[
    local MaxLevelText = Container:CreateFontString(nil, "OVERLAY", "MirageFont_Serif_10_DarkBrown", 2);
    MaxLevelText:SetJustifyH("CENTER");
    MaxLevelText:SetJustifyV("MIDDLE");
    MaxLevelText:SetPoint("CENTER", Container, "CENTER", 8.5, 4.8);
    MaxLevelText:SetText(5);
    self.MaxLevelText = MaxLevelText;

    local CurrentLevelText = Container:CreateFontString(nil, "OVERLAY", "MirageFont_Serif_18_DarkBrown", 3);
    CurrentLevelText:SetJustifyH("CENTER");
    CurrentLevelText:SetJustifyV("MIDDLE");
    CurrentLevelText:SetPoint("CENTER", Container, "CENTER", -8.5, 3);
    CurrentLevelText:SetText(1);
    self.CurrentLevelText = CurrentLevelText;
    --]]

    local CurrentLevelText = Container:CreateTexture(nil, "OVERLAY", nil, 5);
    CurrentLevelText:SetPoint("CENTER", Container, "CENTER", -8, 3);
    CurrentLevelText:SetSize(20, 20);
    self.CurrentLevelText = CurrentLevelText;

    local MaxLevelText = Container:CreateTexture(nil, "OVERLAY", nil, 5);
    MaxLevelText:SetPoint("CENTER", Container, "CENTER", 8.5, 4.8);
    MaxLevelText:SetSize(13, 13);
    self.MaxLevelText = MaxLevelText;

    self:SetScript("OnEnter", self.OnEnter);
    self:SetScript("OnLeave", self.OnLeave);
    self:SetScript("OnEvent", self.OnEvent);
    self:SetScript("OnHide", self.OnHide);

    self:SetHitRectInsets(1, 1, 2, 2);

    self.Init = nil;
    self:LoadTheme();
end

function FriendshipBar:LoadTheme()
    if self.Init then return end;

    local barFile = addon.ThemeUtil:GetTextureFile("FriendshipBar.png");
    local numberFile = addon.ThemeUtil:GetTextureFile("FriendshipDigits.tga");

    for _, tex in ipairs(self.textures) do
        tex:SetTexture(barFile);
    end

    local filer = "TRILINEAR";
    self.CurrentLevelText:SetTexture(numberFile, nil, nil, filer);
    self.MaxLevelText:SetTexture(numberFile, nil, nil, filer);
end


local FILL1_RATIO;
local FILL2_RATIO;
local FILL3_RATIO;
local FILL4_RATIO;

do
    local ARC1 = 0.75;
    local ARC2 = 0.9;
    local FULL_ARC = 2*(ARC1 + ARC2);
    FILL1_RATIO = ARC1/FULL_ARC;
    FILL2_RATIO = ARC2/FULL_ARC;
    FILL3_RATIO = ARC2/FULL_ARC;
    FILL4_RATIO = ARC1/FULL_ARC;
end

function FriendshipBar:SetRatio(ratio)
    local ratio1 = ratio/FILL1_RATIO;
    local ratio2 = (ratio - FILL1_RATIO)/FILL2_RATIO;
    local ratio3 = (ratio - FILL1_RATIO - FILL2_RATIO)/FILL3_RATIO;
    local ratio4 = (ratio - FILL1_RATIO - FILL2_RATIO - FILL3_RATIO)/FILL4_RATIO;

    local rad1 = Lerp(RAD_FILL1_BEGIN, RAD_FILL1_END, ratio1);
    local rad2 = Lerp(RAD_FILL2_BEGIN, RAD_FILL2_END, ratio2);
    local rad3 = Lerp(RAD_FILL3_BEGIN, RAD_FILL3_END, ratio3);
    local rad4 = Lerp(RAD_FILL4_BEGIN, RAD_FILL4_END, ratio4);

    self.Mask1:SetRotation(rad1);
    self.Mask2:SetRotation(rad2);
    self.Mask3:SetRotation(rad3);
    self.Mask4:SetRotation(rad4);

    local surfRad, surfOffsetX, surfOffsetY;
    if ratio4 > 0 then
        surfRad = rad4;
        surfOffsetX = -FRAME_SIZE/6;
        surfOffsetY = FRAME_SIZE/6*0.75;
    elseif ratio3 > 0 then
        surfRad = rad3;
        surfOffsetX = 0;
        surfOffsetY = 6.4;
    elseif ratio2 > 0 then
        surfRad = rad2;
        surfOffsetX = 0;
        surfOffsetY = 6.4;
    else
        surfRad = rad1;
        surfOffsetX = FRAME_SIZE/6;
        surfOffsetY = FRAME_SIZE/6*0.75;
    end

    self.Surface:ClearAllPoints();
    self.Surface:SetPoint("CENTER", self, "CENTER", surfOffsetX, surfOffsetY);
    self.Surface:SetRotation(surfRad);
    self.Surface:SetShown(ratio > 0.01 and ratio < 0.995);
end

function FriendshipBar:Update(factionID)
    local repInfo = GetFriendshipReputation and GetFriendshipReputation(factionID or 0);
	if repInfo and repInfo.friendshipFactionID and  repInfo.friendshipFactionID > 0 then
        if self.Init then
            self:Init();
        end

		self.friendshipFactionID = repInfo.friendshipFactionID;
        local fillRatio;

        if repInfo.nextThreshold then
			local current = repInfo.standing - repInfo.reactionThreshold;
			local max = repInfo.nextThreshold - repInfo.reactionThreshold;
            if max == 0 then
                fillRatio = 1;
            else
                fillRatio = current / max;
            end
		else
			fillRatio = 1;
		end

        self:SetRatio(fillRatio);

        local rankInfo = GetFriendshipReputationRanks(repInfo.friendshipFactionID);

        --self.CurrentLevelText:SetText(rankInfo.currentLevel);
        --self.MaxLevelText:SetText(rankInfo.maxLevel);
        SetTextureNumber(self.CurrentLevelText, rankInfo.currentLevel);
        SetTextureNumber(self.MaxLevelText, rankInfo.maxLevel);

        self:RegisterEvent("UPDATE_FACTION");
		self.Container:Show();

	elseif self.Container then
        self.friendshipFactionID = nil;
        self:UnregisterEvent("UPDATE_FACTION");
		self.Container:Hide();
	end
end

function FriendshipBar:OnUpdate(elapsed)
    self:SetScript("OnUpdate", nil);
    self:Update();
end

function FriendshipBar:RequestUpdate()
    self:SetScript("OnUpdate", self.OnUpdate);
    self:Show();
end

function FriendshipBar:OnEnter()
    if not self.friendshipFactionID then return end;

	local repInfo = GetFriendshipReputation(self.friendshipFactionID);
	if repInfo and repInfo.friendshipFactionID and repInfo.friendshipFactionID > 0 then
        TooltipFrame:Hide();
		TooltipFrame:SetOwner(self, "ANCHOR_NONE");
        TooltipFrame:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", 0, 0);
		local rankInfo = GetFriendshipReputationRanks(repInfo.friendshipFactionID);
		if rankInfo.maxLevel > 0 then
			TooltipFrame:SetTitle(repInfo.name.." ("..rankInfo.currentLevel.." / "..rankInfo.maxLevel..")", 1, 1, 1);
		else
			TooltipFrame:SetTitle(repInfo.name, 1, 1, 1);
		end
		TooltipFrame:AddLeftLine(repInfo.text, 1, 0.82, 0, true);
		if repInfo.nextThreshold then
			local current = repInfo.standing - repInfo.reactionThreshold;
			local max = repInfo.nextThreshold - repInfo.reactionThreshold;
			TooltipFrame:AddLeftLine(repInfo.reaction.." ("..current.." / "..max..")" , 1, 1, 1, true);

            local diff = max - current;
            TooltipFrame:AddLeftLine(addon.L["To Next Level Label"]..": |cffffffff"..diff.."|r", 1, 0.82, 0);
		else
			TooltipFrame:AddLeftLine(repInfo.reaction, 1, 1, 1, true);
		end
		TooltipFrame:Show();
	end
end

function FriendshipBar:OnLeave()
    TooltipFrame:Hide();
end

function FriendshipBar:OnEvent(event, ...)
    if event == "UPDATE_FACTION" then
        self:RequestUpdate();
    end
end

function FriendshipBar:OnHide()
    self:UnregisterEvent("UPDATE_FACTION");
end