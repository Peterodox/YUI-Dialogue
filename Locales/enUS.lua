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
L["Complete Quest"] = COMPLETE or "Complete";   --Complete (Verb)  We no longer use COMPLETE_QUEST because the it's too long in some languages
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
L["Renown Level Label"] = "Renown ";  --There is a space    --RENOWN_LEVEL_LABEL
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
L["TTS Button Tooltip"] = "Left Click: Play/Stop Reading.\nRight Click: Toggle Auto Play.";
L["Item Is An Upgrade"] = "This item is an upgrade for you";
L["Identical Stats"] = "The two items have the same stats";   --Two items provide the same stats
L["Quest Completed On Account"] = (ACCOUNT_COMPLETED_QUEST_NOTICE or "Your Warband previously completed this quest.");
L["New Quest Available"] = "New Quest Available";
L["Campaign Quest"] = TRACKER_HEADER_CAMPAIGN_QUESTS or "Campaign";
L["Click To Open BtWQuests"] = "Click to view this quest in BtWQuests window.";
L["Story Progress"] = STORY_PROGRESS or "Story Progress";
L["Quest Complete Alert"] = QUEST_WATCH_POPUP_QUEST_COMPLETE or "Quest Complete!";
L["Item Equipped"] = "Equipped";
L["Collection Collected"] = COLLECTED or "Collected";

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
L["Format Time Left"] = BONUS_OBJECTIVE_TIME_LEFT or "Time Left: %s";
L["Format Your Progress"] = "Your progress: |cffffffff%d/%d|r";
L["Format And More"] = LFG_LIST_AND_MORE or "and %d more...";
L["Format Chapter Progress"] = STORY_CHAPTERS or "%d/%d Chapters";
L["Format Quest Progress"] = "%d/%d Quests";

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
L["Middle Click To Reset Position"] = "Middle-click to reset position.";

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
L["Font"] = "Font";
L["Font Desc"] = "Set the font for the UI.";
L["Font Tooltip Normal"] = "Current font: ";
L["Font Tooltip Missing"] = "The font you chose is missing. We are now using the default font.";
L["Default"] = "Default";
L["Default Font"] = "Default Font";
L["System Font"] = "System Font";
L["Frame Orientation"] = "Orientation";
L["Frame Orientation Desc"] = "Place the UI on the left or right side of the screen";
L["Orientation Left"] = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_LEFT or "Left";
L["Orientation Right"] = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_RIGHT or "Right";
L["Hide UI"] = "Hide UI";
L["Hide UI Desc"] = "Fade out the game UI when you interact with an NPC.";
L["Show Chat Window"] = "NPC Chat Window";
L["Show Chat Window Left Desc"] = "Show an NPC chat window on the bottom left of your screen.";
L["Show Chat Window Right Desc"] = "Show an NPC chat window on the bottom right of your screen.";
L["Hide Unit Names"] = "Hide Unit Names";
L["Hide Unit Names Desc"] = "Hide players and other NPC names when you interact with an NPC.";
L["Hide Sparkles"] = "Hide Outline Sparkles";
L["Hide Sparkles Desc"] = "Disable the outline and sparkle effect on quest NPCs.\n\nWoW automatically adds sparkles to the quest NPC's model when the UI becomes hidden.";
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
L["Camera Zoom Multiplier"] = "Zoom Multiplier";
L["Camera Zoom Multiplier Desc"] = "The smaller the value, the closer the camera moves to the target.\n\nThe distance is also affected by the target's size.";

L["Input Device"] = "Input Device";
L["Input Device Desc"] = "Affects hotkey icons and UI layout.";
L["Input Device KBM"] = "KB&M";
L["Input Device Xbox"] = "Xbox";
L["Input Device Xbox Tooltip"] = "Confirm Button: [KEY:XBOX:PAD1]\nCancel Button: [KEY:XBOX:PAD2]";
L["Input Device PlayStation"] = "PlayStation";
L["Input Device PlayStation Tooltip"] = "Confirm Button: [KEY:PS:PAD1]\nCancel Button: [KEY:PS:PAD2]";
L["Input Device Switch"] = "Switch";
L["Input Device Switch Tooltip"] = "Confirm Button: [KEY:SWITCH:PAD1]\nCancel Button: [KEY:SWITCH:PAD2]";
L["Use Custom Bindings"] = "Use Custom Bindings";
L["Use Custom Bindings Desc"] = "Enable this option to use your own bindings.";
L["Primary Control Key"] = "Confirm Button";
L["Primary Control Key Desc"] = "Press this key to select the first available option like Accept Quest."
L["Press Button To Scroll Down"] = "Press Button To Scroll Down";
L["Press Button To Scroll Down Desc"] = "If the content is taller than the viewport, pressing the Confirm Button will scroll the page down instead of accepting quest.";
L["Right Click To Close UI"] = "Right Click To Close UI";
L["Right Click To Close UI Desc"] = "Right click on the dialogue UI to close it.";
L["Press Tab To Select Reward"] = "Press Tab To Select Reward";
L["Press Tab To Select Reward Desc"] = "Press [KEY:PC:TAB] to cycle through choosable rewards when you turn in the quest.";
L["Disable Hokey For Teleport"] = "Disable Hokey For Teleport";
L["Disable Hokey For Teleport Desc"] = "Disable the hotkeys when you are choosing a teleport destination.";
L["Experimental Features"] = "Experimental";
L["Emulate Swipe"] = "Emulate Swipe Gesture";
L["Emulate Swipe Desc"] = "Scroll the dialogue UI up/down by clicking and dragging on the window.";
L["Mobile Device Mode"] = "Mobile Device Mode";
L["Mobile Device Mode Desc"] = "Experimental Feature:\n\nIncreases UI and font size to make texts readable on small-screen devices.";
L["Mobile Device Mode Override Option"] = "This option currently has no effect because you have enabled \"Mobile Device Mode\" in Control.";
L["GamePad Click First Object"] = "Click First Option";
L["GamePad Click First Object Desc"] = "When starting a new interaction with an NPC, press the Confirm Button to click the first dialogue option.";

L["Key Space"] = "Space";
L["Key Interact"] = "Interact";
L["Cannot Use Key Combination"] = "Key combination is not supported.";
L["Interact Key Not Set"] = "[KEY:PC:INVALID] You haven't set an Interact Key."
L["Use Default Control Key Alert"] = "We will still use [KEY:PC:SPACE] as the Confirm Button.";
L["Key Disabled"] = "Disabled";
L["Key Disabled Tooltip"] = "Confirm Button has been disabled.\n\nYou will not be able to accept quest by pressing keys.";

L["Auto Quest Popup"] = "Auto Quest Popup";
L["Auto Quest Popup Desc"] = "If a new quest is automatically triggered by picking up an item or entering an area, the quest will be displayed on a pop-up first instead of showing quest details.\n\nQuests triggered upon login may not meet our criteria.";
L["Popup Position"] = "Pop-up Position";    --Pop-up window position
L["Widget Is Docked Generic"] = "This widget is docked with other pop-ups.";   --Indicate a window is docked with other pop-up windows
L["Widget Is Docked Named"] = "%s is docked with other pop-ups.";
L["Quest Item Display"] = "Quest Item Display";
L["Quest Item Display Desc"] = "Auto display the quest item's description and allow you to use it without opening bags.";
L["Quest Item Display Hide Seen"] = "Ignore Seen Items";
L["Quest Item Display Hide Seen Desc"] = "Ignore items that have been discovered by any of your characters.";
L["Quest Item Display Await World Map"] = " Await World Map";
L["Quest Item Display Await World Map Desc"] = "When you open the World Map, temporarily hide the Quest Item Display and pause the auto close timer.";
L["Quest Item Display Reset Position Desc"] = "Reset the window's position.";
L["Valuable Reward Popup"] = "Valuable Reward Popup";
L["Valuable Reward Popup Desc"] = "When you receive a valuable item like an upgrade, a chest, or an uncollected cosmetic item, show a button that allows you to use it directly.";
L["Auto Complete Quest"] = "Auto Complete Quest";
L["Auto Complete Quest Desc"] = "Auto complete the following quest then display the dialogue and rewards in a separate window. If the rewards contain a chest, you can click to open it.\n\n- Candy Bucket (Hallow's End)\n- Khaz Algar Weekly";
L["Press Key To Use Item"] = "Press Button To Use";
L["Press Key To Use Item Desc PC"] = "Press [KEY:PC:SPACE] to use the item when you are out of combat.";
L["Press Key To Use Item Desc Xbox"] = "Press [KEY:XBOX:PAD3] to use the item when you are out of combat.";
L["Press Key To Use Item Desc PlayStation"] = "Press [KEY:PS:PAD3] to use the item when you are out of combat.";
L["Press Key To Use Item Desc Switch"] = "Press [KEY:SWITCH:PAD3] to use the item when you are out of combat.";
L["Auto Select"] = "Auto Select";
L["Auto Select Gossip"] = "Auto Select Option";
L["Auto Select Gossip Desc"] = "Automatically select the best dialogue option when interacting with certain NPC.";
L["Force Gossip"] = "Force Gossip";
L["Force Gossip Desc"] = "By default, the game sometimes automatically selects the first option without showing the dialog. By enabling Force Gossip, the dialogue will become visible.";
L["Skip GameObject"] = "Skip GameObject";   --Sub-option of Force Gossip
L["Skip GameObject Desc"] = "Dot not reveal the hidden dialogue of GameObject like Crafting Tables.";
L["Show Hint"] = "Show Hint";
L["Show Hint Desc"] = "Add a button that selects the correct answer if possible.\n\nCurrently only supports the quiz during Timewalking.";
L["Nameplate Dialog"] = "Display Dialogue On Nameplate";
L["Nameplate Dialog Desc"] = "Display the dialogue on the NPC nameplate if they offer no choice.\n\nThis option modifies CVar \"SoftTarget Nameplate Interact\".";
L["Compatibility"] = "Compatibility";
L["Disable DUI In Instance"] = "Use WoW's Default UI In Instance";
L["Disable DUI In Instance Desc"] = "Disable Dialogue UI and use WoW's default one when you are in dungeon or raid.";

L["Disable UI Motions"] = "Reduce UI Movements";
L["Disable UI Motions Desc"] = "Reduce UI movements such as Unfolding UI or Nudging Button Text.";

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
L["TTS Skip Recent"] = "Skip Recently Read Texts";
L["TTS Skip Recent Desc"] = "Skip recently read texts.";
L["TTS Auto Play Delay"] = "Delay Reading";
L["TTS Auto Play Delay Desc"] = "Add a brief delay before auto reading so it does not overlap with the NPC's own voiceover.";
L["TTS Auto Stop"] = "Stop On Leaving";
L["TTS Auto Stop Desc"] = "Stop reading when you leave the NPC.";
L["TTS Stop On New"] = "Stop On New Dialogue";
L["TTS Stop On New Desc"] = "Stop previous reading when you start viewing a different dialogue.";
L["TTS Voice Male"] = "Male Voice";
L["TTS Voice Male Desc"] = "Use this voice when you interact with a male character:";
L["TTS Voice Female"] = "Female Voice";
L["TTS Voice Female Desc"] = "Use this voice when you interact with a female character:";
L["TTS Use Narrator"] = "Narrator";
L["TTS Use Narrator Desc"] = "Use a different voice to read the NPC name, quest title, objectives, and any text in <> braces.";
L["TTS Voice Narrator"] = "Voice";
L["TTS Voice Narrator Desc"] = "Use this voice for narrating:";
L["TTS Volume"] = VOLUME or "Volume";
L["TTS Volume Desc"] = "Adjust the speech volume.";
L["TTS Rate"] = "Rate of Speech";
L["TTS Rate Desc"] = "Adjust the rate of speech.";
L["TTS Include Content"] = "Include Content";
L["TTS Content NPC Name"] = "NPC Name";
L["TTS Content Quest Name"] = "Quest Title";
L["TTS Content Objective"] = "Quest Objectives";

--Book UI and Settings
L["Readables"] = "Readables";   --Readable Objects
L["Readable Objects"] = "Readable Objects";     --Used as a label for a setting in Accessibility-TTS
L["BookUI Enable"] = "Use New UI For Readable Objects";
L["BookUI Enable Desc"] = "Use new UI for readable objects such as books, letters and notes.";
L["BookUI Frame Size Desc"] = "Set the size of the Book UI.";
L["BookUI Keep UI Open"] = "Keep Window Open";
L["BookUI Keep UI Open Desc"] = "Keep the window open when you move away from the object.\n\nPress Escape or right-click on the UI to close it.";
L["BookUI Show Location"] = "Show Location";
L["BookUI Show Location Desc"] = "Show the object's location in the header.\n\nOnly works for game objects, not items in your bags.";
L["BookUI Show Item Description"] = "Show Item Description";
L["BookUI Show Item Description Desc"] = "If the item has any description on its tooltip, display it on the top of the UI.";
L["BookUI Darken Screen"] = "Darken Screen";
L["BookUI Darken Screen Desc"] = "Darken the area below the UI to help you concentrate on the content.";
L["BookUI TTS Voice"] = "Voice";
L["BookUI TTS Voice Desc"] = "Use this voice for readable objects:";
L["BookUI TTS Click To Read"] = "Click Paragraph To Read";
L["BookUI TTS Click To Read Desc"] = "Click on a paragraph to read it.\n\nClick on a paragraph currently being read to stop reading.";

--Keybinding Action
L["Bound To"] = "Bound to: ";
L["Hotkey Colon"] = "Hotkey: ";
L["Not Bound"] = NOT_BOUND or "Not Bound";
L["Action Confirm"] = "Confirm";
L["Action Settings"] = "Toggle Settings";
L["Action Option1"] = "Option 1";
L["Action Option2"] = "Option 2";
L["Action Option3"] = "Option 3";
L["Action Option4"] = "Option 4";
L["Action Option5"] = "Option 5";
L["Action Option6"] = "Option 6";
L["Action Option7"] = "Option 7";
L["Action Option8"] = "Option 8";
L["Action Option9"] = "Option 9";

--Tutorial
L["Tutorial Settings Hotkey"] = "Press [KEY:PC:F1] to toggle Settings";     --Shown when interacting with an NPC with this addon for the first time
L["Tutorial Settings Hotkey Console"] = "Press [KEY:PC:F1] or [KEY:CONSOLE:MENU] to toggle Settings";   --Use this if gamepad enabled
L["Instruction Open Settings"] = "You can open settings by pressing [KEY:PC:F1] when the dialogue window is active.";    --Used in Game Menu - AddOns
L["Instruction Open Settings Console"] = "You can open settings by pressing [KEY:PC:F1] or [KEY:CONSOLE:MENU] when the dialogue window is active.";
L["Instruction Open Settings Keybind Format"] = "You can open settings by pressing [%s] when the dialogue window is active.";
L["Instruction Open Settings No Keybind"] = "You did not set a keybind to open settings.";
L["HelpTip Warband Completed Quest"] = "This icon indicates the quest has been completed by your Warband.";
L["Got It"] = HELP_TIP_BUTTON_GOT_IT or "Got It";
L["Open Settings"] = "Open Settings";

--AddOn Compatibility for Language Translator
L["Translator"] = "Translator";
L["Translator Source"] = "Source: ";
L["Translator No Quest Data Format"] = "No entry found for [Quest: %s]";
L["Translator Click To Hide Translation"] = "Click to hide the translation";
L["Translator Click To Show Translation"] = "Click to show the translation";

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

L["Show Answer"] = "Show answer.";
L["Quest Failed Pattern"] = "^Turn in for";     --First few words of ERR_QUEST_FAILED_MAX_COUNT_S
L["AutoCompleteQuest HallowsEnd"] = "Candy Bucket";     --Quest:28981

--Asking for Directions-- (match the name to replace gossip icon)
L["Pin Auction House"] = BUTTON_LAG_AUCTIONHOUSE or "Auction House";
L["Pin Bank"] = BANK or "Bank";
L["Pin Barber"] = MINIMAP_TRACKING_BARBER or "Barber";
L["Pin Battle Pet Trainer"] = "Battle Pet Trainer";
L["Pin Crafting Orders"] = PROFESSIONS_CRAFTING_ORDERS_TAB_NAME or "Crafting Orders";
L["Pin Flight Master"] = MINIMAP_TRACKING_FLIGHTMASTER or "Flight Master";
L["Pin Great Vault"] = DELVES_GREAT_VAULT_LABEL or "Great Vault";
L["Pin Inn"] = "Inn";
L["Pin Item Upgrades"] = "Item Upgrades";
L["Pin Mailbox"] = MINIMAP_TRACKING_MAILBOX or "Mailbox";
L["Pin Other Continents"] = "Other Continents";
L["Pin POI"] = MINIMAP_TRACKING_POI or "Points of Interest";
L["Pin Profession Trainer"] = "Profession Trainer";
L["Pin Rostrum"] = "Rostrum of Transformation";
L["Pin Stable Master"] = MINIMAP_TRACKING_STABLEMASTER or "Stable Master";
L["Pin Trading Post"] = BATTLE_PET_SOURCE_12 or "Trading Post";
L["Pin Transmogrifier"] = MINIMAP_TRACKING_TRANSMOGRIFIER or "Transmogrifier";
L["Pin Class Trainer"] = MINIMAP_TRACKING_TRAINER_CLASS or "Class Trainer";
L["Pin Transmogrification"] = TRANSMOGRIFICATION or "Transmogrification";
L["Pin Void Storage"] = VOID_STORAGE or "Void Storage";
L["Pin Vendor"] = BATTLE_PET_SOURCE_3 or "Vendor";