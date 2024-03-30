-- Notify player when there is an available breadcomb quest for the current quest.
-- It's, in fact, the Grail addon that we need. But the notification is created by Wholly
local _, addon = ...


do
    local ADDON_NAME = "Wholly";

    --https://github.com/smaitch/Wholly/blob/master/Wholly.lua#L4398    --Wholly:_GetBreadcrumbMessage()
    --https://github.com/smaitch/Grail/blob/master/Grail/Grail.lua#4401

    local function OnAddOnLoaded()
        if not (Wholly and Grail) then return end;

        local requiredMethods = {
            "AvailableBreadcrumbs",
        };

        for _, method in ipairs(requiredMethods) do
            if not Grail[method] then
                return
            end
        end

        --Success

        local GetQuestName = addon.API.GetQuestName;

        local function HandleEvent(event)
            if event == "QUEST_DETAIL" then
                local questID = GetQuestID();
                if questID and questID ~= 0 then
                    local quests = Grail:AvailableBreadcrumbs();

                    if quests then
                        local questText;
                        for _, id in ipairs(quests)do
                            local text;
                            local name = GetQuestName(id);
                            if name and name ~= "" then
                                text = name;
                            else
                                text = string.format("[Quest:%s]", id);
                            end

                            if text then
                                if not questText then
                                    questText = text;
                                else
                                    questText = questText .. ", "..text;
                                end
                            end
                        end

                        if questText then
                            questText = addon.L["Format Breadcrumb Quests Available"]:format(questText);
                            addon.Banner:DisplayAutoFadeMessage(questText, 0.5);
                        end
                    end
                end
            end
        end

        addon.CallbackRegistry:Register("DialogueUI.HandleEvent", HandleEvent);
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded);
end