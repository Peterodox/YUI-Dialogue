# Pet Quality Pips & Combat Lockdown Notice

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Show empty slot indicators for pet collection pips, and display a visible combat notice when the QuickSlot popup can't be used in combat.

**Architecture:** Two independent enhancements to `Widget_ItemButton.lua` with a supporting locale string in `enUS.lua`. Pet pips change is purely text formatting. Combat notice adds a FontString overlay to the item button and integrates with the existing `GetActionButton`/`onEnterCombatCallback` flow.

**Tech Stack:** WoW Lua API, DialogueUI addon framework

---

### Task 1: Add locale string for combat notice

**Files:**
- Modify: `Locales/enUS.lua:63` (after "Collection Collected" line)

**Step 1: Add the locale string**

After line 63 (`L["Collection Collected"]`), add:

```lua
L["Popup Usable After Combat"] = "Usable after combat";
```

**Step 2: Commit**

```
feat(locale): add combat notice string
```

---

### Task 2: Add empty pip indicators for pet collection slots

**Files:**
- Modify: `Code/Widget/Widget_ItemButton.lua:612-622` (`BuildPetCollectionText` function)

**Step 1: Modify `BuildPetCollectionText` to show empty pips**

Replace the current function (lines 612-622):

```lua
local function BuildPetCollectionText(name, owned, maxOwned, qualities)
    local pips = "";
    for _, rarity in ipairs(qualities) do
        local color = PET_RARITY_COLORS[rarity] or "ffffffff";
        pips = pips .. "|c" .. color .. "\226\151\143|r";  --● (U+25CF)
    end
    if pips ~= "" then
        pips = pips .. " ";
    end
    return string.format("%s  %s%d/%d", name or "", pips, owned, maxOwned);
end
```

With:

```lua
local function BuildPetCollectionText(name, owned, maxOwned, qualities)
    local pips = "";
    -- Filled pips for owned qualities
    for _, rarity in ipairs(qualities) do
        local color = PET_RARITY_COLORS[rarity] or "ffffffff";
        pips = pips .. "|c" .. color .. "\226\151\143|r";  --● filled (U+25CF)
    end
    -- Empty pips for remaining capacity
    for i = 1, maxOwned - owned do
        pips = pips .. "|cff666666\226\151\139|r";  --○ empty (U+25CB)
    end
    if pips ~= "" then
        pips = pips .. " ";
    end
    return string.format("%s  %s%d/%d", name or "", pips, owned, maxOwned);
end
```

Key changes:
- After the owned-quality filled pips loop, add a second loop for `maxOwned - owned` empty pips
- Empty pips use `\226\151\139` (U+25CB, WHITE CIRCLE ○) in grey (`ff666666`)
- Example result: `Pet Cage  ●○○ 1/3` (● in blue, ○○ in grey)

**Step 2: Commit**

```
feat(quickslot): show empty pip indicators for pet collection slots
```

---

### Task 3: Add combat lockdown notice to item button

**Files:**
- Modify: `Code/Widget/Widget_ItemButton.lua:221-248` (`GetActionButton` method)
- Modify: `Code/Widget/Widget_ItemButton.lua:311-325` (`ClearButton` method)

**Step 1: Add `SetCombatNotice` method to ItemButtonMixin**

Add this method in the `ItemButtonMixin` block (after `SetFailedText` at line 356, before the `end` closing the block at line 357):

```lua
    function ItemButtonMixin:SetCombatNotice(show)
        if show then
            if not self.CombatNoticeText then
                local f = self:CreateFontString(nil, "OVERLAY");
                f:SetFontObject("DUIFont_Tooltip_Small");
                f:SetPoint("TOP", self, "BOTTOM", 0, -4);
                self.CombatNoticeText = f;
            end
            ThemeUtil:SetFontColor(self.CombatNoticeText, "WarningRed");
            self.CombatNoticeText:SetText(L["Popup Usable After Combat"]);
            self.CombatNoticeText:Show();
        elseif self.CombatNoticeText then
            self.CombatNoticeText:Hide();
        end
    end
```

**Step 2: Modify `GetActionButton` to show/clear combat notice**

Replace the current `GetActionButton` method (lines 221-248):

```lua
    function ItemButtonMixin:GetActionButton()
        local ActionButton = addon.AcquireSecureActionButton("QuestRewardItem");
        if ActionButton then
            self.ActionButton = ActionButton;
            ActionButton:SetScript("OnEnter", function()
                self:OnEnter();
            end);
            ActionButton:SetScript("OnLeave", function()
                self:OnLeave();
            end);
            ActionButton:SetPostClickCallback(function(f, button)
                self:OnMouseUp(button);
                if self.PostClick then
                    self:PostClick(button);
                end
            end);
            ActionButton:SetParent(self);
            ActionButton:SetFrameStrata(self:GetFrameStrata());
            ActionButton:SetFrameLevel(self:GetFrameLevel() + 5);
            ActionButton.onEnterCombatCallback = function()
                self:SetButtonEnabled(false);
                self:SetCombatNotice(true);
            end;
            self:SetButtonEnabled(true);
            self:SetCombatNotice(false);
            return ActionButton
        else
            self:SetButtonEnabled(false);
            if InCombatLockdown() then
                self:SetCombatNotice(true);
            end
        end
    end
```

Changes from original:
- `onEnterCombatCallback`: added `self:SetCombatNotice(true)` after disabling button
- Success path: added `self:SetCombatNotice(false)` to clear notice when button re-enables after combat
- Failure path during combat: added `self:SetCombatNotice(true)` when `InCombatLockdown()` is true

**Step 3: Clean up combat notice in `ClearButton`**

Add `self:SetCombatNotice(false);` to `ClearButton`, after `self:ReleaseActionButton();` (line 322):

```lua
    function ItemButtonMixin:ClearButton()
        self:Hide();
        self:StopAnimating();
        if self.hasData then
            self.hasData = nil;
            self.t = 0;
            self.isFadingOut = nil;
            self.itemID = nil;
            self.hyperlink = nil;
            self:SetScript("OnUpdate", nil);
            self:UnregisterAllEvents();
            self:ReleaseActionButton();
            self:SetCombatNotice(false);
            self:OnButtonHide();
        end
    end
```

**Step 4: Commit**

```
feat(quickslot): show combat lockdown notice on popup button
```

---

### Task 4: In-game verification

**Test pet pips:**
1. Find or cage a companion pet you already own (e.g., own 1/3 of a species)
2. Loot another cage of the same species from a quest or purchase
3. Verify the QuickSlot popup shows filled pip(s) in quality color + grey empty pips for remaining slots
4. Verify the `owned/max` count is correct

**Test combat notice:**
1. Enter combat (attack a mob)
2. While in combat, trigger a QuickSlot popup (loot a container, pet cage, etc.)
3. Verify the popup appears greyed out with "Usable after combat" text below it
4. Leave combat and verify the button becomes active and the notice disappears

**Test combat-starts-while-showing:**
1. Trigger a QuickSlot popup outside of combat
2. Enter combat while the popup is still visible
3. Verify the button greys out and the "Usable after combat" notice appears
4. Leave combat and verify it re-enables
