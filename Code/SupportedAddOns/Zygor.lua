-- Zygor Guides Item Score Integration
local _, addon = ...
local API = addon.API;


do
    local ADDON_NAME = "ZygorGuidesViewer";

    local requiredMethods = {
        "ZGV";
    };

    local function OnAddOnLoaded()
        local ZGV = _G.ZGV;
        if not (ZGV and ZGV.ItemScore and ZGV.ItemScore.Upgrades) then return end;

        local ItemScore = ZGV.ItemScore;
        local Upgrades = ItemScore.Upgrades;
        local tooltip = addon.SharedTooltip;
        local floor = math.floor;

        local function get_change(old, new)
            if old and old > 0 then
                return floor(((new * 100 / old) - 100) * 100) / 100
            else
                return 100
            end
        end

        -- Override upgrade detection for reward item arrows
        API.IsItemAnUpgrade_External = function(itemLink)
            if not ItemScore.ActiveRuleSet then
                return API.IsItemAnUpgrade(itemLink)
            end
            local isUpgrade, slot, change, score, comment = Upgrades:IsUpgrade(itemLink);
            if comment == "not scored" or comment == "no link" then
                return nil, false
            end
            return isUpgrade, true
        end

        -- Append a single slot's upgrade/downgrade line to the tooltip.
        local function addSlotLine(self, slotLabel, futurePrefix, stripped, equipped, score)
            if equipped and (equipped.score or score) then
                if stripped ~= equipped.itemlink then
                    local change;
                    if equipped.score and ItemScore:IsValidItem(equipped.itemlink) then
                        change = get_change(equipped.artifactscore or equipped.score, score);
                    else
                        change = 100;
                    end
                    local pct = (change > 999) and "999+" or tostring(change);
                    if change > 0 then
                        self:AddLeftLine("  " .. slotLabel .. futurePrefix .. "Upgrade: +" .. pct .. "%", 0, 1, 0, false, nil, 2);
                    elseif change < 0 then
                        self:AddLeftLine("  " .. slotLabel .. futurePrefix .. "Downgrade: " .. pct .. "%", 1, 0, 0, false, nil, 2);
                    else
                        self:AddLeftLine("  " .. slotLabel .. "No change", 0.6, 0.6, 0.6, false, nil, 2);
                    end
                else
                    self:AddLeftLine("  " .. slotLabel .. "Equipped", 0.6, 0.6, 0.6, false, nil, 2);
                end
            elseif (score or 0) > 0 then
                self:AddLeftLine("  " .. slotLabel .. futurePrefix .. "Upgrade: +100%", 0, 1, 0, false, nil, 2);
            end
        end

        -- Add Zygor score info to reward item tooltip
        function tooltip:ProcessItemExternal(itemLink)
            if not ItemScore.ActiveRuleSet then return end;

            local item = ItemScore:GetItemDetails(itemLink, "temporary");
            if not item then return end;
            if item.type == "INVTYPE_NON_EQUIP_IGNORE" then return end;

            local score, success = ItemScore:GetItemScore(item.itemlink);
            if not success then return end;

            local valid, validfuture, final = ItemScore:IsValidItem(item.itemlink, "future");
            if not final then return end;

            local spec = ItemScore.ActiveRuleSet.specname;
            local specText = spec and (" (" .. spec .. ")") or "";

            self:AddBlankLine();
            self:AddLeftLine("Zygor ItemScore" .. specText .. ":", 254/255, 97/255, 0, true);

            if valid or validfuture then
                local futurePrefix = (not valid and validfuture) and "Future " or "";
                local slot_1, slot_2 = item.slot, item.slot_2;
                local hasTwoSlots = slot_2 ~= nil;
                local stripped = item.itemlink;

                addSlotLine(self,
                    hasTwoSlots and "Slot 1: " or "",
                    futurePrefix, stripped,
                    slot_1 and Upgrades.EquippedItems[slot_1],
                    score);

                if hasTwoSlots then
                    addSlotLine(self,
                        "Slot 2: ",
                        futurePrefix, stripped,
                        Upgrades.EquippedItems[slot_2],
                        score);
                end
            else
                if item.type == "INVTYPE_TRINKET" then
                    self:AddLeftLine("  Trinkets are not part of the scoring system.", 0.6, 0.6, 0.6, true, nil, 2);
                else
                    local specName = ItemScore.playerspecName or (ItemScore.ActiveRuleSet and ItemScore.ActiveRuleSet.specname) or "current spec";
                    self:AddLeftLine("  Not valid for " .. specName, 1, 0, 0, false, nil, 2);
                end
            end

            self:Show();
        end
    end

    addon.AddSupportedAddOn(ADDON_NAME, OnAddOnLoaded, requiredMethods);
end