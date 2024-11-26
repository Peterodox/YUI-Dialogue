local _, addon = ...
local API = addon.API;
local TemplateAPI = addon.TemplateAPI;


do  --DUIGenericTitledFrameMixin (Minimal Size: 480*480 px)
    DUIGenericTitledFrameMixin = {};

    function DUIGenericTitledFrameMixin:UpdatePixel()
        API.UpdateTextureSliceScale(self.Background);

        local pixelOffset = 16.0;   --Drop Shadow
        local scale = self.Background:GetEffectiveScale()
        local offset = API.GetPixelForScale(scale, pixelOffset);
        self.Background:ClearAllPoints();
        self.Background:SetPoint("TOPLEFT", self, "TOPLEFT", -offset, offset);
        self.Background:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", offset, -offset);
    end

    local TEXTURE_LOOKUP = {
        [1] = "Interface/AddOns/DialogueUI/Art/Theme_Brown/GenericFrame-Tiled-Large.png",
        [2] = "Interface/AddOns/DialogueUI/Art/Theme_Dark/GenericFrame-Tiled-Large.png",
    };

    function DUIGenericTitledFrameMixin:SetTheme(themeID)
        self.Background:SetTexture(themeID and TEXTURE_LOOKUP[themeID] or TEXTURE_LOOKUP[1]);
    end
end