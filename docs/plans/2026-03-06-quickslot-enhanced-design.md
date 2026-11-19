# Enhanced QuickSlot: Always-On Upgrade Popup with Queue

## Summary

Extend DialogueUI's QuickSlot system to listen for loot from all sources (not
just quest completion), queue multiple popup candidates, and handle deferred
item evaluation gracefully.

## Architecture

Four logical units, all in `Widget_QuickSlot.lua`:

1. **Loot Listener / Source Ingestion** -- captures loot events, extracts item links
2. **Candidate Filter + Normalization** -- dedup, eligibility, deferred resolution
3. **Queue Manager** -- two FIFO buckets with priority drain, identity rules
4. **Popup Renderer / Action Handler** -- existing button UI (unchanged)

## 1. Loot Listener

- `CHAT_MSG_LOOT` is the primary event. It covers most earned loot sources:
  boss drops, quest rewards, world drops, treasure chests, bonus rolls.
- Vault coverage is unverified and should be treated as best-effort.
- New setting `QuickSlotAlwaysOn` (default `false`): when enabled, register
  `CHAT_MSG_LOOT` permanently on `PLAYER_ENTERING_WORLD`.
- The existing quest-completion listener remains independent and unchanged.

## 2. Candidate Filter

Pipeline between loot detection and queue:

```
loot event received
  -> normalize: extract item link, resolve classification
  -> reject: no valid item link or classification resolved -> drop
  -> reject: not in SupportedItemTypes -> drop
  -> reject: equipment but not an upgrade -> drop
  -> reject: duplicate (same item_link seen in recent_loot within DUPLICATE_SUPPRESS_SECONDS) -> drop
  -> reject: recently handled (same item_link in recently_handled within DISMISSED_COOLDOWN_SECONDS) -> drop
  -> if item info incomplete: enqueue as pending-resolution
  -> else: enqueue as resolved candidate
```

### Deferred Item Resolution

- If `GetItemClassification` or `IsItemAnUpgrade_External` returns nil/not-ready,
  mark the candidate as pending.
- Retry at `DEFERRED_RETRY_INTERVAL` (0.5s), up to `DEFERRED_MAX_RETRIES` (3).
- On success: promote to resolved, enqueue normally.
- On failure after max retries: drop silently (debug log if enabled).

### Suppression Caches

Two separate caches:

- `recent_loot[item_link] = last_seen_time` -- dedup key is `item_link` only;
  suppress if same link seen within `DUPLICATE_SUPPRESS_SECONDS` (5s).
- `recently_handled[item_link] = last_dismissed_or_equipped_time` -- suppress if
  same link dismissed/equipped within `DISMISSED_COOLDOWN_SECONDS` (30s).

## 3. Queue Manager

Two FIFO buckets, high drained before low:

- **High priority**: equipment upgrades, containers (usable items)
- **Low priority**: cosmetics, mounts, pets, toys, decor

### Display-Time Revalidation

Before showing the next queued item:

- Re-check eligibility (still in bags, still an upgrade, still usable).
- Skip if already equipped, no longer an upgrade, or item no longer exists.

### Container Chain

When opening a container produces loot, the always-on listener catches the
contents. Any resulting upgrades wait in queue -- no preemption of the current
popup.

## 4. Popup Renderer

No changes to the existing `QuestRewardItemButtonMixin` or button creation.
The queue manager calls `GetItemButton()` and the appropriate setup method
when it is time to show the next candidate.

On dismiss/equip/use, the queue manager advances to the next item.

## Settings

| Setting               | Type | Default | Description                                      |
|-----------------------|------|---------|--------------------------------------------------|
| QuickSlotAlwaysOn     | bool | false   | Listen for loot from all sources                 |
| QuickSlotPriorityOnly | bool | false   | Only show equipment upgrades and containers       |

### Internal Constants

```lua
DUPLICATE_SUPPRESS_SECONDS  = 5
DISMISSED_COOLDOWN_SECONDS  = 30
DEFERRED_RETRY_INTERVAL     = 0.5
DEFERRED_MAX_RETRIES        = 3
```

## Debug Logging

Gated behind a local `DEBUG` flag (not user-facing):

- Loot event received
- Candidate rejected (with reason)
- Deferred retry count
- Enqueue / dequeue
- Skipped on revalidation

## Non-Goals

- No detection of AH, vendor, mail, trade, or manual bag moves.
- No retroactive scan of existing bags when always-on mode is enabled.
- No automatic equip without user action.
- No guarantee for uncached items until item data resolves.
- No modification to existing quest-completion QuickSlot behavior when
  always-on is disabled.

## Files to Modify

- `Code/Widget/Widget_QuickSlot.lua` -- all four units
- `Code/Settings/Settings.lua` -- register new settings
- `Locales/enUS.lua` -- setting labels and descriptions
