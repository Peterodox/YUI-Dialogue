# Draggable QuickSlot Popup

## Problem

The QuickSlot popup position is hardcoded at bottom-center, 196px up. There is no way to reposition it.

## Solution

Make the popup draggable via Shift+drag, with position persistence and settings UI controls.

### Key Invariant

All popup placement flows through `LoadPosition()`. The hardcoded `SetPoint` is only the default fallback when no saved position exists.

### Architecture

- **RewardItemButton** is the correct root frame. Created once, reused across popups. The secure action button is a child frame — parent-level drag does not conflict with the secure click path.
- **WidgetBaseMixin** methods are mixed onto RewardItemButton, giving it `SavePosition`/`LoadPosition`/`ResetPosition`/`IsUsingCustomPosition` for free.
- **`OnButtonMouseDown`** (currently empty) hooks Shift+LeftButton to start `DragFrame`.

### Position Persistence

- DB key: `QuickSlotPosition` (nil by default = use hardcoded position)
- Saved format: `{left, centerY}` matching existing `WidgetBaseMixin` convention
- Restore: `SetPoint("LEFT", UIParent, "BOTTOMLEFT", x, y)`
- Default: `SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 196)`

### Edit Mode

`ToggleEditMode()` shows the popup with placeholder content:
- Title: "Loot Popup"
- Subtitle: "Shift+Drag to Move"
- Icon: question mark (134400)
- Countdown stopped, interactable for drag only

Exiting edit mode clears the placeholder. Showing a real item fully replaces placeholder state.

### Files Changed

- `Initialization.lua` — add `QuickSlotPosition` to `DefaultValues` (nil)
- `Widget_QuickSlot.lua` — mix in WidgetBaseMixin, override LoadPosition default, hook Shift+drag in OnButtonMouseDown, add ToggleEditMode, replace hardcoded SetPoint with LoadPosition call
- `Settings.lua` — add "Move Position" / "Reset Position" buttons under QuickSlot group

### What Doesn't Change

- Popup behavior, countdown, queue, combat pause
- WidgetBaseMixin implementation in WidgetManager.lua
- Other widget positions
