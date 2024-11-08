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
