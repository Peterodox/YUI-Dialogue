local _, addon = ...

local API = addon.API;
local GetPixelForScale = API.GetPixelForScale;
local ThemeUtil = addon.ThemeUtil;


local TEXTURE_INFO = {
    --Width, height, 4 margins
    ["HotkeyBackground.png"] = {32, 32, 8, 8, 8, 8},
};


local PseudoSliceTextureMixin = {};
do  -- Texture Slicing (Temp Fix for https://github.com/Stanzilla/WoWUIBugs/issues/547)
    local InheritedMethods = {
        "SetDrawLayer", "SetVertexColor", "SetBlendMode", "SetDesaturation", "SetDesaturated",
        "SetSnapToPixelGrid", "SetTexelSnappingBias",
    };

    for _, method in ipairs(InheritedMethods) do
        PseudoSliceTextureMixin[method] = function(self, ...)
            for _, slice in ipairs(self.Slices) do
                slice[method](slice, ...);
            end
        end
    end

    function PseudoSliceTextureMixin:SetBoundaryOffset(a)
        --a < 0 shrink, a > 0 expand
        a = a or 0;
        self.Slice1:SetPoint("TOPLEFT", self, "TOPLEFT", -a, a);
        self.Slice3:SetPoint("TOPRIGHT", self, "TOPRIGHT", a, a);
        self.Slice7:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", -a, -a);
        self.Slice9:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", a, -a);
    end

    function PseudoSliceTextureMixin:OnLoad()
        for _, slice in ipairs(self.Slices) do
            slice:ClearAllPoints();
            slice:SetDrawLayer(self.drawLayer, self.textureSubLevel);
        end

        self.Slice2:SetPoint("TOPLEFT", self.Slice1, "TOPRIGHT", 0, 0);
        self.Slice2:SetPoint("BOTTOMRIGHT", self.Slice3, "BOTTOMLEFT", 0, 0);
        self.Slice4:SetPoint("TOPLEFT", self.Slice1, "BOTTOMLEFT", 0, 0);
        self.Slice4:SetPoint("BOTTOMRIGHT", self.Slice7, "TOPRIGHT", 0, 0);
        self.Slice6:SetPoint("TOPLEFT", self.Slice3, "BOTTOMLEFT", 0, 0);
        self.Slice6:SetPoint("BOTTOMRIGHT", self.Slice9, "TOPRIGHT", 0, 0);
        self.Slice8:SetPoint("TOPLEFT", self.Slice7, "TOPRIGHT", 0, 0);
        self.Slice8:SetPoint("BOTTOMRIGHT", self.Slice9, "BOTTOMLEFT", 0, 0);
        self.Slice5:SetPoint("TOPLEFT", self.Slice1, "BOTTOMRIGHT", 0, 0);
        self.Slice5:SetPoint("BOTTOMRIGHT", self.Slice9, "TOPLEFT", 0, 0);

        self:SetBoundaryOffset(0);
    end

    function PseudoSliceTextureMixin:SetTexture()

    end

    function PseudoSliceTextureMixin:SetAtlas(fileName)
        local file = ThemeUtil:GetTextureFile(fileName);

        for _, slice in ipairs(self.Slices) do
            slice:SetTexture(file);
        end

        local p = TEXTURE_INFO[fileName];
        self.textureInfo = p;

        if p then
            local x1 = p[3]/p[1];
            local y1 = p[4]/p[2];
            local x2 = 1 - p[5]/p[1];
            local y2 = 1 - p[6]/p[2];

            self.Slice1:SetTexCoord(0, x1, 0, y1);
            self.Slice2:SetTexCoord(x1, x2, 0, y1);
            self.Slice3:SetTexCoord(x2, 1, 0, y1);
            self.Slice4:SetTexCoord(0, x1, y1, y2);
            self.Slice5:SetTexCoord(x1, x2, y1, y2);
            self.Slice6:SetTexCoord(x2, 1, y1, y2);
            self.Slice7:SetTexCoord(0, x1, y2, 1);
            self.Slice8:SetTexCoord(x1, x2, y2, 1);
            self.Slice9:SetTexCoord(x2, 1, y2, 1);

            self:UpdateSliceSize();
        end
    end

    function PseudoSliceTextureMixin:UpdateSliceSize()
        if not self.textureInfo then return end;

        local scale = self:GetEffectiveScale();
        local px = GetPixelForScale(scale, 1);
        local p = self.textureInfo;

        self.Slice1:SetSize(p[3] * px, p[4] * px);
        self.Slice3:SetSize(p[5] * px, p[4] * px);
        self.Slice7:SetSize(p[3] * px, p[6] * px);
        self.Slice9:SetSize(p[5] * px, p[6] * px);
    end

    function PseudoSliceTextureMixin:SetTextureSliceMode(sliceMode)

    end

    function PseudoSliceTextureMixin:SetTextureSliceMargins(left, top, right, bottom)

    end
end

do
    local USE_PSEUDO_TEXTURE = true;

    local CreateSliceTexture;

    if USE_PSEUDO_TEXTURE then
        function CreateSliceTexture(parent)
            local f = CreateFrame("Frame", nil, parent, "DUIPseudoSliceTextureTemplate");
            API.Mixin(f, PseudoSliceTextureMixin);

            f:OnLoad();

            return f
        end
    else
        function CreateSliceTexture(parent, drawLayer, templateName, subLevel)
            local texture = parent:CreateTexture(nil, drawLayer, templateName, subLevel);
            return texture
        end
    end
    addon.CreateSliceTexture = CreateSliceTexture;
end
