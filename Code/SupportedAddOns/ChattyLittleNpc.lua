-- Change our TTS button to play CLN voiceover
-- https://github.com/mantaskazlauskas/ChattyLittleNpc


local _, addon = ...

do
    local ADDON_NAME = "ChattyLittleNpc";

    local requiredMethods = {
        "LibStub",
    };

    local function OnAddOnLoaded()
        local CLN = LibStub("AceAddon-3.0"):GetAddon("ChattyLittleNpc");
        if not (CLN and CLN.VoiceoverPlayer) then return end;

        local GetUnitTypeAndID = addon.API.GetUnitTypeAndID;
        local VoiceoverPlayer = CLN.VoiceoverPlayer;

        local function DoesQuestFileExist(questID, type)
            if CLN.VoiceoverPacks then
                local postfix;
                if type == "detail" then
                    postfix = "_Desc.ogg";
                elseif type == "progress" then
                    postfix = "_Prog.ogg";
                elseif type == "completion" then
                    postfix = "_Comp.ogg";
                end
                if postfix then
                    local questFileName = questID .. postfix;
                    for packName, packData in pairs(CLN.VoiceoverPacks) do
                        if CLN.Utils:ContainsString(packData.Voiceovers, questFileName) then
                            return true
                        end
                    end
                end
            end
            return false
        end

        local function StopPlaying()
            local clearQueue = true;
            VoiceoverPlayer:ForceStopCurrentSound(clearQueue);
        end

        local function IsPlaying()
            return VoiceoverPlayer.currentlyPlaying and VoiceoverPlayer.currentlyPlaying:isPlaying()
        end

        local function GetAutoPlayDelay()
            if CLN.db and CLN.db.profile then
                return CLN.db.profile.playVoiceoverAfterDelay
            end
        end

        local provider = {
            name = "ChattyLittleNpc",                                            --string: Your addon's name
            doesFileExist = function(interactionType, id, optionalArg1, optionalArg2)
                if interactionType == "quest" then
                    return DoesQuestFileExist(id, optionalArg1);
                elseif interactionType == "gossip" then
                    local unitID = id;
                    local unitType = optionalArg1;
                    local gossipText = optionalArg2;
                    local soundType;
                    if unitType == "GameObject" then
                        soundType = "GameObject";
                    else
                        soundType = "Gossip";
                    end
                    local sex = UnitSex("npc");
                    local gender = (sex == 1 and "Neutral") or (sex == 2 and "Male") or (sex == 3 and "Female") or "";
                    local hashes = CLN.Utils:GetHashes(unitID, gossipText);
                    local pathToFile = CLN.Utils:GetPathToNonQuestFile(unitID, soundType, hashes, gender);
                    return pathToFile and pathToFile ~= ""
                end

                return false
            end,

            playFile = function(interactionType, id, optionalArg1, optionalArg2)
                StopPlaying();

                if interactionType == "quest" then
                    local questId = id;
                    local phase;
                    local type = optionalArg1;
                    if type == "detail" then
                        phase = "Desc";
                    elseif type == "progress" then
                        phase = "Prog";
                    elseif type == "completion" then
                        phase = "Comp";
                    end
                    local unitType, unitID = GetUnitTypeAndID();
                    VoiceoverPlayer:PlayQuestSound(questId, phase, unitID or 0);
                elseif interactionType == "gossip" then
                    local unitID = id;
                    local unitType = optionalArg1;
                    local gossipText = optionalArg2;
                    local soundType;
                    if unitType == "GameObject" then
                        soundType = "GameObject";
                    else
                        soundType = "Gossip";
                    end
                    local sex = UnitSex("npc");
                    local gender = (sex == 1 and "Neutral") or (sex == 2 and "Male") or (sex == 3 and "Female") or "";
                    VoiceoverPlayer:PlayNonQuestSound(unitID, soundType, gossipText, gender);
                end
            end,

            stopPlaying = StopPlaying,
            isPlaying = IsPlaying,
            getAutoPlayDelay = GetAutoPlayDelay,
        };

        addon.SetVOProvider(provider)   --Global API
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded, requiredMethods);
end