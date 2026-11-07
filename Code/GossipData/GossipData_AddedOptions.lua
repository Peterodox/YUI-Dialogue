local _, addon = ...
local DataProvider = addon.GossipDataProvider;
local CallbackRegistry = addon.CallbackRegistry;
local canaccessvalue = addon.API.canaccessvalue;
local LayoutEvent = ScrollBoxListMixin and ScrollBoxListMixin.Event and ScrollBoxListMixin.Event.OnLayout;
local EmptyOptions = {};
local HiddenParent;
local Session;

function DataProvider:EndAddedGossip()
    local session = Session;
    if not session then return end;
    Session = nil;

    session.box:UnregisterCallback(LayoutEvent, session);
    session.view:SetVirtualized(session.virtualized);
    local frame = session.frame;
    frame:Hide();
    if session.addedAnchor then
        frame:ClearAllPoints();
    end
    frame:SetParent(session.parent);
    frame.gossipOptions = session.originalOptions;
    if session.dialogStrata then
        session.dialog:SetFrameStrata(session.dialogStrata);
    end
end

local function IsCurrentOption(session, option)
    local button = option.button;
    return Session == session and button.GetElementData and button:GetElementData() == option.element
end

local function SelectOption(session, option)
    if not IsCurrentOption(session, option) then return end;
    CallbackRegistry:Trigger("PlayerInteraction.ShowUI", true);
    if not IsCurrentOption(session, option) then return end;

    -- Give windows opened by an addon priority over the dialogue.
    if not session.dialogStrata then
        session.dialogStrata = session.dialog:GetFrameStrata();
        session.dialog:SetFrameStrata("MEDIUM");
    end
    -- Restoring UIParent can hide the source panel before the addon refreshes it.
    if not session.frame:IsShown() then
        session.frame:Show();
    end
    option.button:Click("LeftButton");
end

local function ReadOptions(session, rebuild)
    if rebuild then
        session.frame:Update();
    end
    if Session ~= session then return end;
    local provider = session.box:GetDataProvider();
    if not (provider and provider.Enumerate) then return end;

    local options, greeting, changed = {}, nil, false;
    for _, element in provider:Enumerate() do
        if element.buttonType == GOSSIP_BUTTON_TYPE_OPTION then
            local info = element.info;
            if type(info) == "table" and not session.native[info] and not session.native[info.gossipOptionID] then
                local button = session.box:FindFrame(element);
                if not (button and button.Click and button.GetElementData) then return end;
                local name = button:GetText() or info.name;
                local icon = (button.Icon and button.Icon:GetTexture()) or info.overrideIconID or info.icon;
                local enabled = button:IsEnabled();
                local index = #options + 1;
                local option = session.options[index];
                if not option or option.name ~= name or option.overrideIconID ~= icon or option.enabled ~= enabled then
                    option = {name = name, overrideIconID = icon, enabled = enabled};
                    option.onClick = function()
                        SelectOption(session, option);
                    end;
                    changed = true;
                end
                -- The ScrollBox can recycle a button without changing what the player sees.
                option.button, option.element = button, element;
                options[index] = option;
            end
        elseif element.buttonType == GOSSIP_BUTTON_TYPE_TITLE then
            local text = element.text;
            if canaccessvalue(text) and canaccessvalue(session.nativeGreeting) and text ~= session.nativeGreeting then
                greeting = text;
            end
        end
    end

    changed = changed or #options ~= #session.options or greeting ~= session.greeting;
    session.options, session.greeting = options, greeting;
    CallbackRegistry:Trigger("DialogueUI.AddedGossipOptions", options);
    return changed
end

local function UpdateOptions(session, rebuild)
    session.updating = true;
    local ok, changed = pcall(ReadOptions, session, rebuild);
    session.updating = nil;
    if ok and changed ~= nil then return changed end;
    if Session ~= session then return false end;

    DataProvider:EndAddedGossip();
    if not ok then geterrorhandler()(changed) end;
    return true
end

local function QueueRefresh(session)
    if session.updating or session.pending then return end;
    session.pending = true;
    C_Timer.After(0, function()
        if Session ~= session then return end;
        session.pending = nil;
        local dialog = session.dialog;
        if dialog:IsShown() and dialog.handler == "HandleGossip" and not dialog.requireGossipConfirm then
            if UpdateOptions(session) then
                dialog:HandleGossip(nil, true);
            end
        end
    end);
end

function DataProvider:BeginAddedGossip(dialog, nativeOptions)
    self:EndAddedGossip();

    local frame = GossipFrame;
    local box = frame and frame.GreetingPanel and frame.GreetingPanel.ScrollBox;
    local view = box and box.GetView and box:GetView();
    if not (LayoutEvent and frame and frame.Update and not frame:IsShown() and GOSSIP_BUTTON_TYPE_OPTION
        and box and box.GetDataProvider and box.FindFrame and box.RegisterCallback and box.UnregisterCallback
        and view and view.SetVirtualized and view.IsVirtualized) then
        return
    end

    local native, options = {}, {};
    for i, option in ipairs(nativeOptions) do
        options[i] = option;
        native[option] = true;
        if option.gossipOptionID then native[option.gossipOptionID] = true end;
    end

    if not HiddenParent then
        HiddenParent = CreateFrame("Frame");
        HiddenParent:Hide();
    end
    local session = {
        frame = frame, box = box, view = view, dialog = dialog,
        parent = frame:GetParent(), virtualized = view:IsVirtualized(),
        originalOptions = frame.gossipOptions, nativeGreeting = C_GossipInfo.GetText() or "",
        native = native, options = EmptyOptions,
    };
    Session = session;
    frame.gossipOptions = options;
    frame:SetParent(HiddenParent);
    if frame:GetNumPoints() == 0 then
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT");
        session.addedAnchor = true;
    end
    -- Addons initialize their actions on the actual buttons, including off-screen rows.
    view:SetVirtualized(false);
    box:RegisterCallback(LayoutEvent, QueueRefresh, session);
    -- The window stays invisible while addons can still update its list.
    frame:Show();
    UpdateOptions(session, true);
end

function DataProvider:GetAddedGossip()
    if Session then return Session.options, Session.greeting end;
    return EmptyOptions
end
