# Combat Pause for QuickSlot Popup Countdown

## Problem

When a player enters combat while a quickslot popup is showing, the equip/use button correctly disables and shows a "usable after combat" notice. However, the auto-fade countdown timer continues running. The popup can fade away during combat before the player ever gets a chance to interact with it.

## Solution

Pause the auto-fade countdown timer during combat. Resume only when both combat and hover are inactive.

### Key Invariant

The auto-fade timer is paused whenever **either** combat lockdown **or** hover is active, and only resumes when **neither** condition applies.

### Design

**Add `UpdatePauseState()` to `QuestRewardItemButtonMixin`** that derives the pause state from current conditions:

```lua
function QuestRewardItemButtonMixin:UpdatePauseState()
    self.CloseButton:PauseAutoCloseTimer(self:IsFocused() or InCombatLockdown());
end
```

**Callers:**

| Event | Action |
|---|---|
| `OnButtonEnter` | Call `UpdatePauseState()` (replaces direct `PauseAutoCloseTimer(true)`) |
| `OnButtonLeave` | Call `UpdatePauseState()` (replaces direct `PauseAutoCloseTimer(false)`) |
| `onEnterCombatCallback` | Call `UpdatePauseState()` (new) |
| `PLAYER_REGEN_ENABLED` | Call `UpdatePauseState()` after re-enabling button (new) |

**Edge case: popup created during combat.** After `SetCountdown()` is called in `AddAutoCloseItemButton`, if `InCombatLockdown()` is true, immediately pause the timer. The button will already show the combat notice via `GetActionButton()` (line 249). Timer resumes on `PLAYER_REGEN_ENABLED`.

**Edge case: timer nearly expired when combat starts.** Remaining time is frozen exactly where it is. It resumes from that point after combat ends. No restart.

**Guard on `PLAYER_REGEN_ENABLED`.** Before resuming, verify the popup still exists and hasn't been dismissed by another path (close button, queue invalidation, etc.).

### Files Changed

- `Widget_QuickSlot.lua` — add `UpdatePauseState()`, modify `OnButtonEnter`/`OnButtonLeave`, modify `AddAutoCloseItemButton` for combat-created popups
- `Widget_ItemButton.lua` — call `UpdatePauseState()` from `onEnterCombatCallback` and `PLAYER_REGEN_ENABLED` handler

### What Doesn't Change

- Countdown durations (4s idle, 2s auto-complete, 1s manual)
- Combat notice text and disabled button appearance
- Queue system behavior
- `PauseAutoCloseTimer` implementation in `WidgetManager.lua`
- `StopCountdown` behavior
