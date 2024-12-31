local _, addon = ...
local API = addon.API;
local TemplateAPI = addon.TemplateAPI;


do  --DUIGenericTitledFrameMixin
    DUIGenericTitledFrameMixin = {};

    function DUIGenericTitledFrameMixin:UpdatePixel()
        API.UpdateTextureSliceScale(self.Background);

        local pixelOffset = self.pixelOffset;   --Drop Shadow
        local scale = self.Background:GetEffectiveScale()
        local offset = API.GetPixelForScale(scale, pixelOffset);
        self.Background:ClearAllPoints();
        self.Background:SetPoint("TOPLEFT", self, "TOPLEFT", -offset, offset);
        self.Background:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", offset, -offset);
    end

    local TEXTURE_LOOKUP = {
        [1] = { --Settings Background: Brown    (Minimal Size: 480*480 px)
            file = "Interface/AddOns/DialogueUI/Art/Theme_Brown/GenericFrame-Tiled-Large.png",
            offset = 16,
            margins = {80, 80, 80, 80},
        },

        [2] = { --Settings Background: Dark     (Minimal Size: 480*480 px)
            file = "Interface/AddOns/DialogueUI/Art/Theme_Dark/GenericFrame-Tiled-Large.png",
            offset = 16,
            margins = {80, 80, 80, 80},
        },

        HelpTip1 = { --Help Tip
            file = "Interface/AddOns/DialogueUI/Art/Theme_Shared/HelpTip.png",
            offset = 8,
            margins = {40, 24, 40, 24},
            texCoords = {0, 256/512, 0, 104/512},
        },

        HelpTip2 = { --Help Tip
            file = "Interface/AddOns/DialogueUI/Art/Theme_Shared/HelpTip.png",
            offset = 8,
            margins = {40, 24, 40, 24},
            texCoords = {0, 256/512, 104/512, 208/512},
        },
    };

    function DUIGenericTitledFrameMixin:SetTheme(themeID)
        if not (themeID and TEXTURE_LOOKUP[themeID]) then
            themeID = 1;
        end
        if themeID ~= self.themeID then
            self.themeID = themeID;
            local info = TEXTURE_LOOKUP[themeID];
            self.Background:SetTexture(info.file);
            if info.texCoords then
                self.Background:SetTexCoord(info.texCoords[1], info.texCoords[2], info.texCoords[3], info.texCoords[4]);
            else
                self.Background:SetTexCoord(0, 1, 0, 1);
            end
            self.Background:SetTextureSliceMargins(info.margins[1], info.margins[2], info.margins[3], info.margins[4]);
            self.pixelOffset = info.offset;
            self:UpdatePixel();
        end
    end

    function DUIGenericTitledFrameMixin:OnLoad()
        --For frame anchor
        self.RealArea = self.Background;
        self.EffectiveArea = self;

        self:SetTheme(1);
    end
end