local _, addon = ...
local GetDBValue = addon.GetDBValue;

local DeviceUtil = {};
addon.DeviceUtil = DeviceUtil;

local Mapping = {
    --1:Bottom   2:Right   3:Left                 4:Top
    --1:Confirm  2:Cancel  3:Mod(Alternate Info)  4:Action(Use/Cast)

    KBM = {
        [1] = "SPACE",
        [2] = "ESCAPE",
        [3] = "SPACE",
        [4] = "LSHIFT",
    },

    XBOX = {
        [1] = "PAD1",
        [2] = "PAD2",
        [3] = "PAD3",
        [4] = "PAD4",
    },

    PS = {
        [1] = "PAD1",
        [2] = "PAD2",
        [3] = "PAD3",
        [4] = "PAD4",
    },

    SWITCH = {
        [1] = "PAD2",
        [2] = "PAD1",
        [3] = "PAD4",
        [4] = "PAD3",
    },
};


function DeviceUtil:IsUsingController()
    local deviceID = GetDBValue("InputDevice");
    return (deviceID == 2 or deviceID == 3 or deviceID == 4)
end

function DeviceUtil:GetDeviceMapping()
    local deviceID = GetDBValue("InputDevice");
    if deviceID == 2 then
        return Mapping.XBOX
    elseif deviceID == 3 then
        return Mapping.KBM
    elseif deviceID == 4 then
        return Mapping.PS
    else
        return Mapping.KBM
    end
end

function DeviceUtil:GetConfirmKey()
    return self:GetDeviceMapping()[1]
end

function DeviceUtil:GetCancelKey()
    return self:GetDeviceMapping()[2]
end

function DeviceUtil:GetActionKey()
    if self:IsUsingController() then
        return self:GetDeviceMapping()[3]
    else
        return addon.BindingUtil:GetActiveActionKey("Confirm");
    end
end

function DeviceUtil:GetModKey()
    return self:GetDeviceMapping()[4]
end