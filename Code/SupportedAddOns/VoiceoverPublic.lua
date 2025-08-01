---- Implementation Guide ----

--[[
    local provider = {
        name = "AddOn Name",                                            --string: Your addon's name
        doesFileExist = function(interactionType, id, optionalArg1, optionalArg2)
            --interactionType: "quest", "gossip"
            --id (quest): questID, id (gossip): npcID
            --optionalArg1 (quest): "detail", "progress", "completion",
            --optionalArg1 (gossip): unitType, optionalArg2 (gossip): GossipText

            if interactionType == "quest" then
                if optionalArg1 == "detail" then
                    
                elseif optionalArg1 == "progress" then

                elseif optionalArg1 == "completion" then

                end
            elseif interactionType == "gossip" then
                
            end

            return false
        end,

        playFile = function(interactionType, id, optionalArg1)
            if interactionType == "quest" then
                if optionalArg1 == "detail" then
                    
                elseif optionalArg1 == "progress" then

                elseif optionalArg1 == "completion" then

                end
            elseif interactionType == "gossip" then
                
            end
        end,

        stopPlaying = function()

        end,

        getAutoPlayDelay = function()
            return 1.0  --number
        end,
    };

    DialogueUIAPI.SetVOProvider(provider)   --Global API
--]]




local temp, addon = ...
temp = false;
local API = addon.API;
local GetUnitTypeAndID = API.GetUnitTypeAndID;


local VOAddOnName;
local VOProvider;
local OnAddOnLoaded;


local function SetVOProvider(provider)
    if provider and type(provider == "table") then
        if not provider.name then
            API.PrintMessage("Missing Voiceover AddOn Name");
            return
        end

        if type(provider.doesFileExist) == "function" and type(provider.playFile) == "function" then
            VOAddOnName = provider.name;
            VOProvider = provider;
        else
            API.PrintMessage("Missing Voiceover Data Provider");
            return
        end

        if not temp then
            temp = true;
            C_Timer.After(0.1, function()
                OnAddOnLoaded();
            end);
        elseif provider.name ~= VOAddOnName then
            API.PrintMessage(string.format("You already had a Voiceover AddOn: %s, but %s is trying to add another one.", VOAddOnName, provider.name));
        end
    end
end
DialogueUIAPI.SetVOProvider = SetVOProvider;
addon.SetVOProvider = SetVOProvider;


local function AlwaysTrue()
    return true
end

local function AlwaysFalse()
    return false
end

function OnAddOnLoaded()
    if not (VOAddOnName and VOProvider) then return end;

    local TTSUtil = addon.TTSUtil;

    function TTSUtil:GetExternalVoiceoverName()
        return VOAddOnName
    end

    TTSUtil.DoesExternalVoiceoverExist = AlwaysTrue;


    if VOProvider.stopPlaying and type(VOProvider.stopPlaying) == "function"then
        function TTSUtil:StopVoiceoverExternal()
            VOProvider.stopPlaying();
        end
    end

    if VOProvider.getAutoPlayDelay and type(VOProvider.getAutoPlayDelay) == "function" then
        function TTSUtil:GetAutoPlayDelayExternal()
            return VOProvider.getAutoPlayDelay();
        end
    end

    if VOProvider.isPlaying and type(VOProvider.isPlaying == "function") then
        function TTSUtil:IsPlayingVoiceoverExternal()
            return VOProvider.isPlaying();
        end
    end


    local function DialogueUI_OnHandleEvent(event, _id)
        local interactionType, id, arg1, arg2;
        local unitType, unitID = GetUnitTypeAndID();

        if event == "GOSSIP_SHOW" then
            interactionType = "gossip";
            id = unitID;
            arg1 = unitType;
            arg2 = C_GossipInfo.GetText();
        elseif event == "QUEST_GREETING" then

        elseif event == "QUEST_DETAIL" then
            interactionType = "quest";
            id = _id;
            arg1 = "detail";
        elseif event == "QUEST_COMPLETE" then
            interactionType = "quest";
            id = _id;
            arg1 = "completion";
        elseif event == "QUEST_PROGRESS" then
            interactionType = "quest";
            id = _id;
            arg1 = "progress";
        end

        local found = false;
        if interactionType and id then
            if VOProvider.doesFileExist(interactionType, id, arg1, arg2) then
                TTSUtil.DoesExternalVoiceoverExist = AlwaysTrue;
                found = true;
            end
        end

        if found then
            TTSUtil.DoesExternalVoiceoverExist = AlwaysTrue;
            TTSUtil.PlayVoiceoverExternal = function()
                VOProvider.playFile(interactionType, id, arg1, arg2);
                return true
            end;
        else
            TTSUtil.DoesExternalVoiceoverExist = AlwaysFalse;
            TTSUtil.PlayVoiceoverExternal = AlwaysFalse;
        end
    end

    local prioritized = true;
    addon.CallbackRegistry:Register("DialogueUI.HandleEvent", DialogueUI_OnHandleEvent, nil, prioritized);


    local function OnBookCached()
        --TEMP
        TTSUtil:StopVoiceoverExternal();
        TTSUtil.DoesExternalVoiceoverExist = AlwaysFalse;
    end

    addon.CallbackRegistry:Register("BookUI.BookCached", OnBookCached, prioritized);
end