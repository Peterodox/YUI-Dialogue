# Enhanced QuickSlot Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Extend QuickSlot to listen for loot from all sources, queue multiple popup candidates with priority, and handle deferred item evaluation.

**Architecture:** Four logical units in Widget_QuickSlot.lua -- loot listener (always-on mode via CHAT_MSG_LOOT), candidate filter (dedup + deferred resolution), queue manager (two FIFO buckets: high/low priority), and the existing popup renderer. New settings registered in Initialization.lua and Settings.lua; locale strings in enUS.lua.

**Tech Stack:** WoW Lua API, DialogueUI addon framework (CallbackRegistry, WidgetManager, settings system)

---

### Task 1: Register new settings and locale strings

**Files:**
- Modify: `Initialization.lua:59-61`
- Modify: `Code/Settings/Settings.lua:699-701`
- Modify: `Locales/enUS.lua:224-232`

**Step 1: Add setting defaults in Initialization.lua**

After line 59 (`QuickSlotQuestReward = false,`), add the new settings. The indentation pattern here uses 4 spaces and sub-options are indented further.

```lua
    QuickSlotQuestReward = false,
    QuickSlotAlwaysOn = false,
    QuickSlotPriorityOnly = false,
    AutoCompleteQuest = false,
        QuickSlotUseHotkey = true,
```

**Step 2: Add locale strings in Locales/enUS.lua**

After line 225 (`L["Valuable Reward Popup Desc"] = ...`), add:

```lua
L["Always-On Loot Popup"] = "Always-On Loot Popup";
L["Always-On Loot Popup Desc"] = "Show the valuable reward popup for items received from any source, not just quest completion. Covers boss drops, world drops, treasure chests, and more.";
L["Upgrades And Containers Only"] = "Upgrades and Containers Only";
L["Upgrades And Containers Only Desc"] = "Only show popups for equipment upgrades and openable containers. Suppress cosmetics, mounts, pets, toys, and decor.";
```

**Step 3: Add settings UI entries in Code/Settings/Settings.lua**

After line 699 (the `QuickSlotQuestReward` checkbox), add two new checkboxes. They are children of `QuickSlotQuestReward` -- they require it to be enabled:

```lua
            {type = "Checkbox", name = L["Valuable Reward Popup"], description = L["Valuable Reward Popup Desc"], dbKey = "QuickSlotQuestReward", preview = "QuickSlotQuestReward", ratio = 2},
            {type = "Checkbox", name = L["Always-On Loot Popup"], description = L["Always-On Loot Popup Desc"], dbKey = "QuickSlotAlwaysOn", requiredParentValueAnd = {QuickSlotQuestReward = true}},
            {type = "Checkbox", name = L["Upgrades And Containers Only"], description = L["Upgrades And Containers Only Desc"], dbKey = "QuickSlotPriorityOnly", requiredParentValueAnd = {QuickSlotQuestReward = true, QuickSlotAlwaysOn = true}},
```

**Step 4: Commit**

```bash
git add Initialization.lua Code/Settings/Settings.lua Locales/enUS.lua
git commit -m "feat(quickslot): add settings for always-on loot popup and priority filtering"
```

---

### Task 2: Add candidate filter with suppression caches and deferred resolution

**Files:**
- Modify: `Code/Widget/Widget_QuickSlot.lua:1-35` (add new locals and filter module at top of file)

**Step 1: Add constants and suppression caches**

After the existing constants block (lines 11-13: `COUNTDOWN_IDLE`, `COUNTDOWN_COMPLETE_AUTO`, `COUNTDOWN_COMPLETE_MANUAL`), add:

```lua
local DUPLICATE_SUPPRESS_SECONDS = 5;
local DISMISSED_COOLDOWN_SECONDS = 30;
local DEFERRED_RETRY_INTERVAL = 0.5;
local DEFERRED_MAX_RETRIES = 3;

local DEBUG_QUICKSLOT = false;

local function DebugLog(...)
    if DEBUG_QUICKSLOT then
        print("|cfffe6100[QuickSlot]|r", ...);
    end
end
```

**Step 2: Add the CandidateFilter module**

After the `SupportedItemTypes` table (line 34), add the filter module. This sits between loot detection and the queue:

```lua
local CandidateFilter = {};
do
    local recent_loot = {};     -- [itemLink] = lastSeenTime
    local recently_handled = {}; -- [itemLink] = lastDismissedOrEquippedTime

    function CandidateFilter:IsRecentLoot(itemLink)
        local lastSeen = recent_loot[itemLink];
        if lastSeen and (GetTime() - lastSeen < DUPLICATE_SUPPRESS_SECONDS) then
            DebugLog("Rejected duplicate:", itemLink);
            return true
        end
        return false
    end

    function CandidateFilter:IsRecentlyHandled(itemLink)
        local lastHandled = recently_handled[itemLink];
        if lastHandled and (GetTime() - lastHandled < DISMISSED_COOLDOWN_SECONDS) then
            DebugLog("Rejected recently handled:", itemLink);
            return true
        end
        return false
    end

    function CandidateFilter:RecordLoot(itemLink)
        recent_loot[itemLink] = GetTime();
    end

    function CandidateFilter:RecordHandled(itemLink)
        recently_handled[itemLink] = GetTime();
    end

    -- Prune stale entries periodically to avoid unbounded growth.
    function CandidateFilter:Prune()
        local now = GetTime();
        for link, t in pairs(recent_loot) do
            if now - t > DUPLICATE_SUPPRESS_SECONDS then
                recent_loot[link] = nil;
            end
        end
        for link, t in pairs(recently_handled) do
            if now - t > DISMISSED_COOLDOWN_SECONDS then
                recently_handled[link] = nil;
            end
        end
    end
end
```

**Step 3: Commit**

```bash
git add Code/Widget/Widget_QuickSlot.lua
git commit -m "feat(quickslot): add candidate filter with suppression caches and debug logging"
```

---

### Task 3: Add queue manager with two FIFO buckets

**Files:**
- Modify: `Code/Widget/Widget_QuickSlot.lua` (add QueueManager module after CandidateFilter)

**Step 1: Add the QueueManager module**

Insert after the CandidateFilter block:

```lua
local QueueManager = {};
do
    local highQueue = {};   -- equipment upgrades, containers
    local lowQueue = {};    -- cosmetics, mounts, pets, toys, decor
    local isProcessing = false;

    local HIGH_PRIORITY_TYPES = {
        equipment = true,
        container = true,
    };

    function QueueManager:Enqueue(itemLink, classification)
        local entry = {
            itemLink = itemLink,
            classification = classification,
            enqueueTime = GetTime(),
        };

        if HIGH_PRIORITY_TYPES[classification] then
            table.insert(highQueue, entry);
            DebugLog("Enqueued HIGH:", classification, itemLink);
        else
            table.insert(lowQueue, entry);
            DebugLog("Enqueued LOW:", classification, itemLink);
        end

        if not isProcessing then
            self:ProcessNext();
        end
    end

    function QueueManager:Peek()
        return highQueue[1] or lowQueue[1]
    end

    function QueueManager:Dequeue()
        if #highQueue > 0 then
            return table.remove(highQueue, 1)
        elseif #lowQueue > 0 then
            return table.remove(lowQueue, 1)
        end
    end

    function QueueManager:IsEmpty()
        return #highQueue == 0 and #lowQueue == 0
    end

    function QueueManager:Clear()
        wipe(highQueue);
        wipe(lowQueue);
        isProcessing = false;
    end

    -- Revalidate: item still in bags, still an upgrade (for equipment), still usable.
    function QueueManager:IsStillEligible(entry)
        if not HasItem(entry.itemLink) then
            DebugLog("Revalidation failed (not in bags):", entry.itemLink);
            return false
        end
        if entry.classification == "equipment" then
            local isUpgrade = API.IsItemAnUpgrade_External(entry.itemLink);
            if not isUpgrade then
                DebugLog("Revalidation failed (no longer upgrade):", entry.itemLink);
                return false
            end
        end
        return true
    end

    function QueueManager:ProcessNext()
        while not self:IsEmpty() do
            local entry = self:Dequeue();
            if entry and self:IsStillEligible(entry) then
                isProcessing = true;
                DebugLog("Showing popup:", entry.classification, entry.itemLink);
                QuickSlotManager:AddItemButtonByType(entry.classification, entry.itemLink);
                return
            else
                DebugLog("Skipped on revalidation:", entry and entry.itemLink or "nil");
            end
        end
        isProcessing = false;
        DebugLog("Queue drained");
    end

    function QueueManager:OnPopupDismissed(itemLink)
        isProcessing = false;
        if itemLink then
            CandidateFilter:RecordHandled(itemLink);
        end
        self:ProcessNext();
    end

    function QueueManager:SetProcessing(state)
        isProcessing = state;
    end
end
```

**Step 2: Commit**

```bash
git add Code/Widget/Widget_QuickSlot.lua
git commit -m "feat(quickslot): add queue manager with two FIFO priority buckets and revalidation"
```

---

### Task 4: Add deferred resolution for uncached items

**Files:**
- Modify: `Code/Widget/Widget_QuickSlot.lua` (add DeferredResolver after QueueManager)

**Step 1: Add the DeferredResolver module**

```lua
local DeferredResolver = {};
do
    local pending = {}; -- { itemLink, retryCount, classification }

    function DeferredResolver:Add(itemLink)
        table.insert(pending, {
            itemLink = itemLink,
            retryCount = 0,
            classification = nil,
        });
        DebugLog("Deferred:", itemLink);
        self:EnsureTimer();
    end

    function DeferredResolver:EnsureTimer()
        if not self.timer then
            self.timer = C_Timer.NewTicker(DEFERRED_RETRY_INTERVAL, function()
                self:Resolve();
            end);
        end
    end

    function DeferredResolver:StopTimer()
        if self.timer then
            self.timer:Cancel();
            self.timer = nil;
        end
    end

    function DeferredResolver:Resolve()
        local stillPending = {};

        for _, entry in ipairs(pending) do
            entry.retryCount = entry.retryCount + 1;
            local itemClassification = GetItemClassification(entry.itemLink);
            local shouldAdd = itemClassification and SupportedItemTypes[itemClassification];

            if itemClassification == "equipment" then
                local isUpgrade, isReady = API.IsItemAnUpgrade_External(entry.itemLink);
                if not isReady then
                    shouldAdd = nil; -- still not ready
                else
                    shouldAdd = isUpgrade;
                end
            end

            if shouldAdd then
                local priorityOnly = addon.GetDBBool("QuickSlotPriorityOnly");
                local isHighPriority = (itemClassification == "equipment" or itemClassification == "container");
                if (not priorityOnly) or isHighPriority then
                    DebugLog("Deferred resolved:", itemClassification, entry.itemLink);
                    QueueManager:Enqueue(entry.itemLink, itemClassification);
                end
            elseif entry.retryCount < DEFERRED_MAX_RETRIES and not itemClassification then
                -- Still no classification data; keep retrying
                table.insert(stillPending, entry);
            else
                DebugLog("Deferred dropped after", entry.retryCount, "retries:", entry.itemLink);
            end
        end

        pending = stillPending;
        if #pending == 0 then
            self:StopTimer();
        end
    end

    function DeferredResolver:Clear()
        wipe(pending);
        self:StopTimer();
    end
end
```

**Step 2: Commit**

```bash
git add Code/Widget/Widget_QuickSlot.lua
git commit -m "feat(quickslot): add deferred resolution for uncached item data"
```

---

### Task 5: Wire up the loot listener with always-on mode

**Files:**
- Modify: `Code/Widget/Widget_QuickSlot.lua` -- modify `OnItemLooted`, `ListenLootEvent`, and the settings callback block

**Step 1: Modify `OnItemLooted` to use the filter and queue**

Replace the existing `OnItemLooted` function (lines 118-140) with one that pipes through the candidate filter:

```lua
function QuickSlotManager:OnItemLooted(itemLink)
    if IsPlayingCutscene() then return end;

    -- Duplicate/cooldown suppression
    if CandidateFilter:IsRecentLoot(itemLink) then return end;
    if CandidateFilter:IsRecentlyHandled(itemLink) then return end;
    CandidateFilter:RecordLoot(itemLink);

    local itemClassification = GetItemClassification(itemLink);
    local shouldAdd = itemClassification and SupportedItemTypes[itemClassification];

    if itemClassification == "equipment" then
        local isUpgrade, isReady = API.IsItemAnUpgrade_External(itemLink);
        if not isReady then
            -- Item data not cached yet; defer evaluation
            if HasItem(itemLink) then
                DeferredResolver:Add(itemLink);
            else
                self:WatchBagItem(itemLink, nil); -- watch for bag arrival, then defer
            end
            return
        end
        shouldAdd = isUpgrade;
    end

    if not shouldAdd then
        DebugLog("Rejected (not eligible):", itemClassification, itemLink);
        return
    end

    -- Priority filtering
    local priorityOnly = addon.GetDBBool("QuickSlotPriorityOnly");
    local isHighPriority = (itemClassification == "equipment" or itemClassification == "container");
    if priorityOnly and (not isHighPriority) then
        DebugLog("Rejected (low priority suppressed):", itemClassification, itemLink);
        return
    end

    if HasItem(itemLink) then
        QueueManager:Enqueue(itemLink, itemClassification);
    else
        self:WatchBagItem(itemLink, itemClassification);
    end
end
```

**Step 2: Update `WatchBagItem` and `BAG_UPDATE_DELAYED` handler to use queue**

Replace the `BAG_UPDATE_DELAYED` handler in `OnEvent` (lines 54-67) to enqueue instead of directly showing:

```lua
    elseif event == "BAG_UPDATE_DELAYED" then
        if self.pendingItemLink then
            if HasItem(self.pendingItemLink) then
                self:UnregisterEvent(event);

                if self.pendingClassification then
                    QueueManager:Enqueue(self.pendingItemLink, self.pendingClassification);
                else
                    -- Classification was unknown at loot time; try deferred resolution
                    DeferredResolver:Add(self.pendingItemLink);
                end

                self.pendingItemLink = nil;
                self.pendingClassification = nil;
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
```

Update `WatchBagItem` to use `pendingClassification` instead of `itemClassification`:

```lua
function QuickSlotManager:WatchBagItem(itemLink, itemClassification)
    self:RegisterEvent("BAG_UPDATE_DELAYED");
    self.pendingItemLink = itemLink;
    self.pendingClassification = itemClassification;
    if self.t then
        self.t = self.t - 1;
    end
end
```

**Step 3: Add the always-on settings callback**

Modify the settings callback block (lines 233-263). Add a new callback for `QuickSlotAlwaysOn` that registers/unregisters the permanent loot listener:

```lua
do
    local ALWAYS_ON_ENABLED = false;

    local function Settings_QuickSlotAlwaysOn(state)
        if state and addon.GetDBBool("QuickSlotQuestReward") then
            if not ALWAYS_ON_ENABLED then
                ALWAYS_ON_ENABLED = true;
                QuickSlotManager:RegisterEvent("CHAT_MSG_LOOT");
                DebugLog("Always-on loot listener enabled");
            end
        else
            if ALWAYS_ON_ENABLED then
                ALWAYS_ON_ENABLED = false;
                -- Only unregister if the quest-completion listener isn't active
                if not QuickSlotManager.t then
                    QuickSlotManager:UnregisterEvent("CHAT_MSG_LOOT");
                end
                QueueManager:Clear();
                DeferredResolver:Clear();
                DebugLog("Always-on loot listener disabled");
            end
        end
    end
    CallbackRegistry:Register("SettingChanged.QuickSlotAlwaysOn", Settings_QuickSlotAlwaysOn);

    -- Also re-evaluate when the parent setting changes
    CallbackRegistry:Register("SettingChanged.QuickSlotQuestReward", function(state)
        Settings_QuickSlotAlwaysOn(addon.GetDBBool("QuickSlotAlwaysOn"));
    end);

    -- Initialize on login
    QuickSlotManager:RegisterEvent("PLAYER_ENTERING_WORLD");
end
```

Add the `PLAYER_ENTERING_WORLD` handler to the `OnEvent` function to initialize always-on mode:

```lua
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        if addon.GetDBBool("QuickSlotQuestReward") and addon.GetDBBool("QuickSlotAlwaysOn") then
            self:RegisterEvent("CHAT_MSG_LOOT");
            DebugLog("Always-on loot listener initialized");
        end
    end
```

**Step 4: Modify `ListenLootEvent` to not stomp always-on mode**

The existing `ListenLootEvent` registers/unregisters `CHAT_MSG_LOOT` for the quest-completion window. When always-on is active, the unregister should be skipped:

```lua
function QuickSlotManager:ListenLootEvent(state)
    if state then
        self:RegisterEvent("CHAT_MSG_LOOT");
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate_UnregisterEvents);
    else
        self.t = nil;
        self.pendingItemLink = nil;
        self.pendingClassification = nil;
        self:SetScript("OnUpdate", nil);
        -- Don't unregister CHAT_MSG_LOOT if always-on mode is active
        if not addon.GetDBBool("QuickSlotAlwaysOn") then
            self:UnregisterEvent("CHAT_MSG_LOOT");
        end
        self:UnregisterEvent("BAG_UPDATE_DELAYED");
    end
end
```

**Step 5: Commit**

```bash
git add Code/Widget/Widget_QuickSlot.lua
git commit -m "feat(quickslot): wire loot listener with always-on mode, filter pipeline, and queue"
```

---

### Task 6: Wire popup dismiss/equip/use callbacks to advance the queue

**Files:**
- Modify: `Code/Widget/Widget_QuickSlot.lua` -- modify `QuestRewardItemButtonMixin` callbacks and `GetItemButton`/`HideItemButton`

**Step 1: Track current item link on the button**

In `AddAutoCloseItemButton` (lines 142-164), store the item link on the button:

```lua
function QuickSlotManager:AddAutoCloseItemButton(itemLink, setupMethod, isActionCompleteMethod)
    local countDownDuration = COUNTDOWN_IDLE;
    local disableButton;
    local allowPressKeyToUse = addon.GetDBBool("QuickSlotUseHotkey");

    local button = self:GetItemButton();
    button.currentItemLink = itemLink;
    button[setupMethod](button, itemLink, allowPressKeyToUse);
    -- ... rest unchanged
```

**Step 2: Advance queue on dismiss/equip**

Modify `OnCountdownFinished` to advance the queue:

```lua
    function QuestRewardItemButtonMixin:OnCountdownFinished()
        local itemLink = self.currentItemLink;
        self.currentItemLink = nil;
        self:FadeOut(0);
        self:UnregisterAllEvents();
        QueueManager:OnPopupDismissed(itemLink);
    end
```

Modify `OnItemEquipped` to advance the queue:

```lua
    function QuestRewardItemButtonMixin:OnItemEquipped()
        local itemLink = self.currentItemLink;
        self.currentItemLink = nil;
        self:ShowUpgradeIcon(false);
        self:SetCountdown(COUNTDOWN_COMPLETE_MANUAL, true);
        -- Queue advances when countdown finishes
    end
```

Modify `OnItemKnown` similarly:

```lua
    function QuestRewardItemButtonMixin:OnItemKnown()
        local itemLink = self.currentItemLink;
        self.currentItemLink = nil;
        self:SetCountdown(COUNTDOWN_COMPLETE_MANUAL, true);
    end
```

**Step 3: Prune caches periodically**

Add a periodic prune call in `OnUpdate_UnregisterEvents` or use a separate timer. Simplest approach -- prune when the queue drains:

In `QueueManager:OnPopupDismissed`, after processing:

```lua
    function QueueManager:OnPopupDismissed(itemLink)
        isProcessing = false;
        if itemLink then
            CandidateFilter:RecordHandled(itemLink);
        end
        CandidateFilter:Prune();
        self:ProcessNext();
    end
```

**Step 4: Handle HideItemButton to also advance queue**

Modify `HideItemButton`:

```lua
    function QuickSlotManager:HideItemButton(fadeOut)
        if RewardItemButton then
            local itemLink = RewardItemButton.currentItemLink;
            RewardItemButton.currentItemLink = nil;
            if fadeOut then
                RewardItemButton:OnCountdownFinished();
                RewardItemButton:SetInteractable(false);
            else
                RewardItemButton:ClearButton();
                QueueManager:OnPopupDismissed(itemLink);
            end
        end
    end
```

**Step 5: Commit**

```bash
git add Code/Widget/Widget_QuickSlot.lua
git commit -m "feat(quickslot): wire popup dismiss/equip/use to advance queue"
```

---

### Task 7: Final cleanup and integration test

**Files:**
- Modify: `Code/Widget/Widget_QuickSlot.lua` -- update debug test block
- Modify: `docs/plans/2026-03-06-quickslot-enhanced-design.md` if needed

**Step 1: Update the debug test block**

Replace the commented-out debug block at the bottom of Widget_QuickSlot.lua (lines 425-473) with a more useful test that exercises the queue:

```lua
do  --debug
    --[[
    QuickSlotManager:RegisterEvent("PLAYER_ENTERING_WORLD");

    function QuickSlotManager:PLAYER_ENTERING_WORLD()
        C_Timer.After(3, function()
            -- Test: simulate two upgrade items arriving in rapid succession
            DEBUG_QUICKSLOT = true;
            local item1 = "|Hitem:6070|h";
            local item2 = "|Hitem:25473|h";
            QuickSlotManager:OnItemLooted(item1);
            QuickSlotManager:OnItemLooted(item2);
        end)
    end
    --]]
end
```

**Step 2: Review all changes for consistency**

- Verify no orphaned references to `self.itemClassification` (renamed to `self.pendingClassification`)
- Verify `wipe` is in the local upvalues at the top of the file (line 10 area)
- Verify `GetTime` and `C_Timer` are accessible (both are global WoW APIs)
- Verify `API.IsItemAnUpgrade_External` reference works (imported via `local API = addon.API` at top)

**Step 3: Commit**

```bash
git add Code/Widget/Widget_QuickSlot.lua
git commit -m "feat(quickslot): update debug test block for queue testing"
```

**Step 4: Final commit with design doc**

```bash
git add docs/
git commit -m "docs: add enhanced quickslot design document"
```

---

### Post-Implementation: WAU Tracking and PR Preparation

After all tasks are complete:

1. **Add DialogueUI to WAU tracking:**
   ```bash
   python3 /mnt/c/Users/phuze/Dropbox/WoWAddons/wau.py add DialogueUI https://github.com/Peterodox/YUI-Dialogue
   ```

2. **Switch back to the working branch for the user's local install.** The user's local copy needs both features active. Either merge both feature branches into a local `dev` branch, or cherry-pick onto main.

3. **PR preparation:** Each feature branch gets its own PR to the upstream repo. Install `gh` CLI or push branches and create PRs via GitHub web UI.
