--To all contributors: Thank you for providing a localization!
--Reserved space below so all localization files line up

local _, addon = ...
local L = addon.L;


L["Quest Frequency Daily"] = DAILY or "Daily";
L["Quest Frequency Weekly"] = WEEKLY or "Weekly";

L["Quest Type Repeatable"] = "Repeatable";
L["Quest Type Trivial"] = "Trivial";    --Low-level quest
L["Quest Type Dungeon"] = LFG_TYPE_DUNGEON or "Dungeon";
L["Quest Type Raid"] = LFG_TYPE_RAID or "Raid";
L["Quest Type Covenant Calling"] = "Covenant Calling";

L["Accept"] = ACCEPT or "Accpet";
L["Continue"] = CONTINUE or "Continue";
L["Complete Quest"] = COMPLETE_QUEST or "Complete Quest";
L["Incomplete"] = INCOMPLETE or "Incomplete";
L["Cancel"] = CANCEL or "Cancel";
L["Goodbye"] = GOODBYE or "Goodbye";
L["Decline"] = DECLINE or "Decline";
L["OK"] = "OK";
L["Quest Objectives"] = OBJECTIVES_LABEL or "Objectives";   --We use the shorter one, not QUEST_OBJECTIVES
L["Reward"] = REWARD or "Reward";
L["Rewards"] = REWARDS or "Rewards";
L["War Mode Bonus"] = WAR_MODE_BONUS or "War Mode Bonus";
L["Honor Points"] = HONOR_POINTS or "Honor";
L["Symbol Gold"] = GOLD_AMOUNT_SYMBOL or "g";
L["Symbol Silver"] = SILVER_AMOUNT_SYMBOL or "s";
L["Symbol Copper"] = COPPER_AMOUNT_SYMBOL or "c";
L["Requirements"] = REQUIREMENTS or "Requirements";
L["Current Colon"] = ITEM_UPGRADE_CURRENT or "Current:";
L["Renown Level Label"] = RENOWN_LEVEL_LABEL or "Renown ";  --There is a space
L["Abilities"] = ABILITIES or "Abilities";
L["Traits"] = GARRISON_RECRUIT_TRAITS or "Traits";
L["Costs"] = "Costs";   --The costs to continue an action, usually gold
L["Ready To Enter"] = QUEUED_STATUS_PROPOSAL or "Ready To Enter";
L["Show Comparison"] = "Show Comparison";   --Toggle item comparison on the tooltip
L["Hide Comparison"] = "Hide Comparison";
L["Copy Text"] = "Copy Text";
L["To Next Level Label"] = COVENANT_MISSIONS_XP_TO_LEVEL or "To next level";
L["Quest Accepted"] = "Quest Accepted";
L["Quest Log Full"] = "Quest Log Is Full";
L["Quest Auto Accepted Tooltip"] = "This quest is accepted automatically by the game.";
L["Level Maxed"] = "(Maxed)";   --Reached max level
L["Paragon Reputation"] = "Paragon";
L["Different Item Types Alert"] = "The item types are different!";
L["Click To Read"] = "Left Click to Read";
L["Item Level"] = STAT_AVERAGE_ITEM_LEVEL or "Item Level";
L["Gossip Quest Option Prepend"] = "(Quest)";   --Some gossip options start with blue (Quest), we prioritize them when sorting. See GOSSIP_QUEST_OPTION_PREPEND
L["TTS Button Tooltip"] = "Left Click: Play/Stop Reading.\nRight Click: Toggle Auto Play";
L["Item Is An Upgrade"] = "This item is an upgrade for you";
L["Identical Stats"] = "The two items have the same stats";   --Two items provide the same stats
L["Quest Completed On Account"] = (ACCOUNT_COMPLETED_QUEST_NOTICE or "Your Warband previously completed this quest.");

--String Format
L["Format Reputation Reward Tooltip"] = QUEST_REPUTATION_REWARD_TOOLTIP or "Awards %d reputation with the %s";
L["Format You Have X"] = "- You have |cffffffff%d|r";
L["Format You Have X And Y In Bank"] = "- You have |cffffffff%d|r (|cffffffff%d|r in your bank)";
L["Format Suggested Players"] = QUEST_SUGGESTED_GROUP_NUM or "Suggested Players [%d]";
L["Format Current Skill Level"] = "Current Level: |cffffffff%d/%d|r";
L["Format Reward Title"] = HONOR_REWARD_TITLE or "Title: %s";
L["Format Follower Level Class"] = FRIENDS_LEVEL_TEMPLATE or "Level %d %s";
L["Format Monster Say"] = CHAT_MONSTER_SAY_GET or "%s says: ";
L["Format Quest Accepted"] = ERR_QUEST_ACCEPTED_S or "Quest accepted: %s";
L["Format Quest Completed"] = ERR_QUEST_COMPLETE_S or "%s completed.";
L["Format Player XP"] = PET_BATTLE_CURRENT_XP_FORMAT_BOTH or  "XP: %d/%d (%d%%)";
L["Format Gold Amount"] = GOLD_AMOUNT or "%d Gold";
L["Format Silver Amount"] = SILVER_AMOUNT or "%d Silver";
L["Format Copper Amount"] = COPPER_AMOUNT or "%d Copper";
L["Format Unit Level"] = UNIT_LEVEL_TEMPLATE or "Level %d";
L["Format Replace Item"] = "Replace %s";
L["Format Item Level"] = "Item Level %d";   --_G.ITEM_LEVEL in Classic is different
L["Format Breadcrumb Quests Available"] = "Available Breadcrumb Quests: %s";    --This type of quest guide the player to a new quest zone. See "Breadcrumb" on https://warcraft.wiki.gg/wiki/Quest#Quest_variations
L["Format Functionality Handled By"] = "This functionality is handled by %s";      --A functionality is provided by [another addon name] (Used in Settings.lua)

--Settings
L["UI"] = "UI";
L["Camera"] = "Camera";
L["Control"] = "Control";
L["Gameplay"] = SETTING_GROUP_GAMEPLAY or "Gameplay";
L["Accessibility"] = SETTING_GROUP_ACCESSIBILITY or "Accessibility";

L["Option Enabled"] = VIDEO_OPTIONS_ENABLED or "Enabled";
L["Option Disabled"] = VIDEO_OPTIONS_DISABLED or "Disabled";
L["Move Position"] = "Move";
L["Reset Position"] = RESET_POSITION or "Reset Position";
L["Drag To Move"] = "Left-click and drag to move the window.";

L["Quest"] = "Quest";
L["Gossip"] = "Gossip";
L["Theme"] = "Theme";
L["Theme Desc"] = "Select a color theme for the UI.";
L["Theme Brown"] = "Brown";
L["Theme Dark"] = "Dark";
L["Frame Size"] = "Frame Size";
L["Frame Size Desc"] = "Set the size of the dialogue UI.\n\nDefault: Medium";
L["Size Extra Small"] = "Extra Small";
L["Size Small"] = "Small";
L["Size Medium"] = "Medium";
L["Size Large"] = "Large";
L["Font Size"] = "Font Size";
L["Font Size Desc"] = "Set the font size for the UI.\n\nDefault: 12";
L["Frame Orientation"] = "Orientation";
L["Frame Orientation Desc"] = "Place the UI on the left or right side of the screen";
L["Orientation Left"] = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_LEFT or "Left";
L["Orientation Right"] = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_RIGHT or "Right";
L["Hide UI"] = "Hide UI";
L["Hide UI Desc"] = "Fade out the game UI when you interact with an NPC.";
L["Hide Unit Names"] = "Hide Unit Names";
L["Hide Unit Names Desc"] = "Hide players and other NPC names when you interact with an NPC.";
L["Show Copy Text Button"] = "Show Copy Text Button";
L["Show Copy Text Button Desc"] = "Show Copy Text button on the top right of the dialogue UI.\n\nIt also includes game data like quest, npc, item IDs.";
L["Show Quest Type Text"] = "Show Quest Type Text";
L["Show Quest Type Text Desc"] = "Show quest type on the right of the option if it's special.\n\nLow level quests are always labeled.";
L["Show NPC Name On Page"] = "Show NPC Name";
L["Show NPC Name On Page Desc"] = "Show the NPC name on the page.";
L["Show Warband Completed Quest"] = MINIMAP_TRACKING_ACCOUNT_COMPLETED_QUESTS or "Warband Completed Quests";
L["Show Warband Completed Quest Desc"] = "Show a note on the bottom of quest detail if you have previously completed the current quest on another character.";
L["Simplify Currency Rewards"] = "Simplify Currency Rewards";
L["Simplify Currency Rewards Desc"] = "Use smaller icons for currency rewards and omit their names.";
L["Mark Highest Sell Price"] = "Mark Highest Sell Price";
L["Mark Highest Sell Price Desc"] = "Show you which item has the highest sell price when you are choosing a reward.";
L["Use Blizzard Tooltip"] = "Use Blizzard Tooltip";
L["Use Blizzard Tooltip Desc"] = "Use Blizzard tooltip for the quest reward button instead of our special tooltip.";
L["Roleplaying"] = GDAPI_REALMTYPE_RP or "Roleplaying";
L["Use RP Name In Dialogues"] = "Use RP Name In Dialogues";
L["Use RP Name In Dialogues Desc"] = "Replace your character's name in dialogue texts with your RP name.";

L["Camera Movement"] = "Camera Movement";
L["Camera Movement Off"] = "OFF";
L["Camera Movement Zoom In"] = "Zoom In";
L["Camera Movement Horizontal"] = "Horizontal";
L["Maintain Camera Position"] = "Maintain Camera Position";
L["Maintain Camera Position Desc"] = "Maintain camera position briefly after NPC interaction ends.\n\nEnabling this option will reduce the camera's sudden movement caused by the latency between dialogs.";
L["Change FOV"] = "Change FOV";
L["Change FOV Desc"] = "Reduce the camera\'s field of view to zoom in closer to the NPC.";
L["Disable Camera Movement Instance"] = "Disable In Instance";
L["Disable Camera Movement Instance Desc"] = "Disable camera movement while in dungeon or raid.";
L["Maintain Offset While Mounted"] = "Maintain Offset While Mounted";
L["Maintain Offset While Mounted Desc"] = "Attempt to maintain your character's position on the screen while mounted.\n\nEnabling this option may overcompensate the horizontal offset for large-sized mounts.";

L["Input Device"] = "Input Device";
L["Input Device Desc"] = "Affects hotkey icons and UI layout.";
L["Input Device KBM"] = "KB&M";
L["Input Device Xbox"] = "Xbox";
L["Input Device Xbox Tooltip"] = "Confirm Button: [KEY:XBOX:PAD1]\nCancel Button: [KEY:XBOX:PAD2]";
L["Input Device PlayStation"] = "PlayStation";
L["Input Device PlayStation Tooltip"] = "Confirm Button: [KEY:PS:PAD1]\nCancel Button: [KEY:PS:PAD2]";
L["Input Device Switch"] = "Switch";
L["Input Device Switch Tooltip"] = "Confirm Button: [KEY:SWITCH:PAD1]\nCancel Button: [KEY:SWITCH:PAD2]";
L["Primary Control Key"] = "Confirm Button";
L["Primary Control Key Desc"] = "Press this key to select the first available option like Accept Quest."
L["Press Button To Scroll Down"] = "Press Button To Scroll Down";
L["Press Button To Scroll Down Desc"] = "If the content is taller than the viewport, pressing the Confirm Button will scroll the page down instead of accepting quest.";
L["Right Click To Close UI"] = "Right Click To Close UI";
L["Right Click To Close UI Desc"] = "Right click on the dialogue UI to close it.";

L["Key Space"] = "Space";
L["Key Interact"] = "Interact";
L["Cannot Use Key Combination"] = "Key combination is not supported.";
L["Interact Key Not Set"] = "[KEY:PC:INVALID] You haven't set an Interact Key."
L["Use Default Control Key Alert"] = "We will still use [KEY:PC:SPACE] as the Confirm Button.";
L["Key Disabled"] = "Disabled";
L["Key Disabled Tooltip"] = "Confirm Button has been disabled.\n\nYou will not be able to accept quest by pressing keys.";

L["Quest Item Display"] = "Quest Item Display";
L["Quest Item Display Desc"] = "Auto display the quest item's description and allow you to use it without opening bags.";
L["Quest Item Display Hide Seen"] = "Ignore Seen Items";
L["Quest Item Display Hide Seen Desc"] = "Ignore items that have been discovered by any of your characters.";
L["Quest Item Display Await World Map"] = " Await World Map";
L["Quest Item Display Await World Map Desc"] = "When you open the World Map, temporarily hide the Quest Item Display and pause the auto close timer.";
L["Quest Item Display Reset Position Desc"] = "Reset the window's position.";
L["Auto Select"] = "Auto Select";
L["Auto Select Gossip"] = "Auto Select Option";
L["Auto Select Gossip Desc"] = "Automatically select the best dialogue option when interacting with certain NPC.";
L["Force Gossip"] = "Force Gossip";
L["Force Gossip Desc"] = "By default, the game sometimes automatically selects the first option without showing the dialog. By enabling Force Gossip, the dialogue will become visible.";
L["Nameplate Dialog"] = "Display Dialogue On Nameplate";
L["Nameplate Dialog Desc"] = "Display the dialogue on the NPC nameplate if they offer no choice.\n\nThis option modifies CVar \"SoftTarget Nameplate Interact\".";

L["TTS"] = TEXT_TO_SPEECH or "Text To Speech";
L["TTS Desc"] = "Read dialogue text out loud by clicking the button on the top left of the UI.";
L["TTS Use Hotkey"] = "Use Hotkey";
L["TTS Use Hotkey Desc"] = "Start or stop reading by pressing:";
L["TTS Use Hotkey Tooltip PC"] = "[KEY:PC:R]";
L["TTS Use Hotkey Tooltip Xbox"] = "[KEY:XBOX:LT]";
L["TTS Use Hotkey Tooltip PlayStation"] = "[KEY:PS:LT]";
L["TTS Use Hotkey Tooltip Switch"] = "[KEY:SWITCH:LT]";
L["TTS Auto Play"] = "Auto Play";
L["TTS Auto Play Desc"] = "Auto play dialogue texts.";
L["TTS Auto Stop"] = "Stop When Leaving";
L["TTS Auto Stop Desc"] = "Stop reading when you leave the NPC.";
L["TTS Voice Male"] = "Male Voice";
L["TTS Voice Male Desc"] = "Use this voice when you interact with a male character:";
L["TTS Voice Female"] = "Female Voice";
L["TTS Voice Female Desc"] = "Use this voice when you interact with a female character:";
L["TTS Volume"] = VOLUME or "Volume";
L["TTS Volume Desc"] = "Adjust the speech volume.";
L["TTS Rate"] = "Rate of Speech";
L["TTS Rate Desc"] = "Adjust the rate of speech.";
L["TTS Include Content"] = "Include Content";
L["TTS Content NPC Name"] = "NPC Name";
L["TTS Content Quest Name"] = "Quest Title";

--Tutorial
L["Tutorial Settings Hotkey"] = "Press [KEY:PC:F1] to toggle Settings";     --Shown when interacting with an NPC with this addon for the first time
L["Tutorial Settings Hotkey Console"] = "Press [KEY:PC:F1] or [KEY:CONSOLE:MENU] to toggle Settings";   --Use this if gamepad enabled
L["Instuction Open Settings"] = "To open Settings, press [KEY:PC:F1] while you are interacting with an NPC.";    --Used in Game Menu - AddOns
L["Instuction Open Settings Console"] = "To open Settings, press [KEY:PC:F1] or [KEY:CONSOLE:MENU] while you are interacting with an NPC.";

--DO NOT TRANSLATE
L["Abbrev Breakpoint 1000"] = FIRST_NUMBER_CAP_NO_SPACE or "K";     --1,000 = 1K
L["Abbrev Breakpoint 10000"] = FIRST_NUMBER_CAP_NO_SPACE or "K";    --Reserved for Asian languages that have words for 10,000
L["Match Stat Armor"] = "([,%d%.]+) Armor";
L["Match Stat Stamina"] = "([,%d%.]+) Stamina";
L["Match Stat Strengh"] = "([,%d%.]+) Strengh";
L["Match Stat Agility"] = "([,%d%.]+) Agility";
L["Match Stat Intellect"] = "([,%d%.]+) Intellect";
L["Match Stat Spirit"] = "([,%d%.]+) Spirit";
L["Match Stat DPS"] = "([,%d%.]+) damage per second";