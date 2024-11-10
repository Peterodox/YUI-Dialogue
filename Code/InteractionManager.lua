--Unused

local _, addon = ...

local IsInteractingWithNpcOfType = C_PlayerInteractionManager.IsInteractingWithNpcOfType;

function DUI_GetInteractionType()
    for k, v in pairs(Enum.PlayerInteractionType) do
        if IsInteractingWithNpcOfType(v) then
            print(k, v);
        end
    end
end

local function SetStatusBarTextHeight(height)
    local font = SystemFont_Outline_Small:GetFont();
    height = height or 10;
    local style = "OUTLINE";
    TextStatusBarText:SetFont(font, height, style);
end

--/script local height = 14; local font = SystemFont_Outline_Small:GetFont(); TextStatusBarText:SetFont(font, height, "OUTLINE")