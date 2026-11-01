local _, addon = ...
local GetDBValue = addon.GetDBValue;
local CallbackRegistry = addon.CallbackRegistry;

local DeviceUtil = CreateFrame("Frame");
addon.DeviceUtil = DeviceUtil;

local Mapping = {
    --1:Bottom   2:Right   3:Left              4:Top
    --1:Confirm  2:Cancel  3:Action(Use/Cast)  4:Mod(Alternate Info)

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

local DeviceIndex = {
    KBM = 1,
    XBOX = 2,
    PS = 3,
    SWITCH = 4,
};


function DeviceUtil:IsUsingControllerLayout()
    local deviceIndex = GetDBValue("InputDevice");
    for _productKey, index in pairs(DeviceIndex) do
        if deviceIndex == index and deviceIndex ~= DeviceIndex.KBM then
            return true;
        end
    end
    return false;
end

---@param productKey "KBM"|"XBOX"|"PS"|"SWITCH"
function DeviceUtil:SetLayoutByProduct(productKey)
    local deviceIndex;
    for key, index in pairs(DeviceIndex) do
        if key == productKey then
            deviceIndex = index;
        end
    end
    if deviceIndex then
        addon.SetDBValue("InputDevice", deviceIndex, true);
        return true;
    end
    return false;
end

function DeviceUtil:GetDeviceMapping()
    local deviceIndex = GetDBValue("InputDevice");
    for productKey, index in pairs(DeviceIndex) do
        if deviceIndex == index then
            return Mapping[productKey];
        end
    end
    return Mapping.KBM;
end

function DeviceUtil:GetConfirmKey()
    return self:GetDeviceMapping()[1]
end

function DeviceUtil:GetCancelKey()
    return self:GetDeviceMapping()[2]
end

function DeviceUtil:GetActionKey()
    if self:IsUsingControllerLayout() then
        return self:GetDeviceMapping()[3]
    else
        return addon.BindingUtil:GetActiveActionKey("Confirm");
    end
end

function DeviceUtil:GetModKey()
    return self:GetDeviceMapping()[4]
end

function DeviceUtil:GetKeyByFunction(keyFunction)
    if keyFunction == "Confirm" then
        return self:GetConfirmKey();
    elseif keyFunction == "Cancel" then
        return self:GetCancelKey();
    elseif keyFunction == "Action" then
        return self:GetActionKey();
    elseif keyFunction == "Mod" then
        return self:GetModKey();
    end
end


--- Process "MODIFIER_STATE_CHANGED" event
function DeviceUtil.IsShiftDown(key, down)
    return down == 1 and (key == "LSHIFT" or key == "RSHIFT")
end

function DeviceUtil.IsCtrlDown(key, down)
    return down == 1 and (key == "LCTRL" or key == "RCTRL")
end

function DeviceUtil.IsAltDown(key, down)
    return down == 1 and (key == "LALT" or key == "RALT")
end


--- Game pad detection
DeviceUtil:RegisterEvent("GAME_PAD_CONNECTED");
DeviceUtil:RegisterEvent("GAME_PAD_DISCONNECTED");
DeviceUtil:RegisterEvent("GAME_PAD_ACTIVE_CHANGED");
DeviceUtil.isGamePadActive = false;

function DeviceUtil:OnEvent(event, ...)
    if event == "GAME_PAD_ACTIVE_CHANGED" then
        ---triggers when pressing any controller button
        self.isGamePadActive = ...
    elseif event == "GAME_PAD_CONNECTED" then
        self.isGamePadActive = true;
        DeviceUtil:RegisterDeviceChangedCallback();
        if not self.gamePadConnected then
            self.gamePadConnected = true;
            self:QuestOrBookUIOnShow();
        end
    end
end
DeviceUtil:SetScript("OnEvent", DeviceUtil.OnEvent);

local ProductNameXProductKey = {
    XBOX = "XBOX",
    PLAYSTATION = "PS",
    DUALSENSE = "PS",
};

function DeviceUtil:GetActiveProduct()
    local productKey;

    if self.isGamePadActive then
        productKey = "XBOX";
        for _, deviceID in pairs(C_GamePad.GetAllDeviceIDs()) do
            local rawState = C_GamePad.GetDeviceRawState(deviceID);
            if rawState and rawState.name then
                local name = string.upper(rawState.name);
                for productName, key in pairs(ProductNameXProductKey) do
                    if string.find(name, productName) then
                        productKey = key;
                        break;
                    end
                end
            end
        end
    else
        productKey = "KBM";
    end

    return productKey;
end

