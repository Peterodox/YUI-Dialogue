--Contributors: Luckyone961
if not (GetLocale() == "deDE") then return end;

local _, addon = ...
local L = addon.L;


L["Quest Frequency Daily"] = DAILY or "Täglich";
L["Quest Frequency Weekly"] = WEEKLY or "Wöchentlich";

L["Quest Type Repeatable"] = "Wiederholbar";
L["Quest Type Trivial"] = "Trivial";    --Low-level quest
L["Quest Type Dungeon"] = LFG_TYPE_DUNGEON or "Dungeon";
L["Quest Type Raid"] = LFG_TYPE_RAID or "Raid";
L["Quest Type Covenant Calling"] = "Pakt";

L["Accept"] = ACCEPT or "Akzeptieren";
L["Continue"] = CONTINUE or "Weiter";
L["Complete Quest"] = COMPLETE_QUEST or "Quest abschließen";
L["Incomplete"] = INCOMPLETE or "Unvollständig";
L["Cancel"] = CANCEL or "Abbrechen";
L["Goodbye"] = GOODBYE or "Auf Wiedersehen";
L["Decline"] = DECLINE or "Ablehnen";
L["OK"] = "OK";
L["Quest Objectives"] = OBJECTIVES_LABEL or "Ziele";   --We use the shorter one, not QUEST_OBJECTIVES
L["Reward"] = REWARD or "Belohnung";
L["Rewards"] = REWARDS or "Belohnungen";
L["War Mode Bonus"] = WAR_MODE_BONUS or "Kriegsmodus-Bonus";
L["Honor Points"] = HONOR_POINTS or "Ehrenpunkte";
L["Symbol Gold"] = GOLD_AMOUNT_SYMBOL or "g";
L["Symbol Silver"] = Silver_AMOUNT_SYMBOL or "s";
L["Symbol Copper"] = COPPER_AMOUNT_SYMBOL or "k";
L["Requirements"] = REQUIREMENTS or "Anforderungen";
L["Current Colon"] = ITEM_UPGRADE_CURRENT or "Aktuell:";
L["Renown Level Label"] = RENOWN_LEVEL_LABEL or "Ruf ";  --There is a space
L["Abilities"] = ABILITIES or "Fähigkeiten";
L["Traits"] = GARRISON_RECRUIT_TRAITS or "Eigenschaften";
L["Costs"] = "Kosten";   --The costs to continue an action, usually gold
L["Ready To Enter"] = QUEUED_STATUS_PROPOSAL or "Bereit zum Betreten";
L["Show Comparison"] = "Vergleich anzeigen";   --Toggle item comparison on the tooltip
L["Hide Comparison"] = "Vergleich ausblenden";
L["Copy Text"] = "Text kopieren";
L["To Next Level Label"] = COVENANT_MISSIONS_XP_TO_LEVEL or "Zum nächsten Level";
L["Quest Accepted"] = "Quest angenommen";
L["Quest Log Full"] = "Questlog voll";
L["Quest Auto Accepted Tooltip"] = "Quest automatisch angenommen.";
L["Level Maxed"] = "(Maximum)";   --Reached max level
L["Paragon Reputation"] = "Paragon";
L["Different Item Types Alert"] = "Verschiedene Gegenstandstypen!";


--String Format
L["Format Reputation Reward Tooltip"] = QUEST_REPUTATION_REWARD_TOOLTIP or "Ihr erhaltet %d Ruf bei %s"; --Awards %d reputation with the %s
L["Format You Have X"] = "- Du hast |cffffffff%d|r";
L["Format You Have X And Y In Bank"] = "- Du hast |cffffffff%d|r (|cffffffff%d|r in deiner Bank)";
L["Format Suggested Players"] = QUEST_SUGGESTED_GROUP_NUM or "Empfohlene Spieler [%d]";
L["Format Current Skill Level"] = "Aktuelles Level: |cffffffff%d/%d|r";
L["Format Reward Title"] = HONOR_REWARD_TITLE or "Titel: %s";
L["Format Follower Level Class"] = FRIENDS_LEVEL_TEMPLATE or "Level %d %s";
L["Format Monster Say"] = CHAT_MONSTER_SAY_GET or "%s sagt: ";
L["Format Quest Accepted"] = ERR_QUEST_ACCEPTED_S or "Quest angenommen: %s";
L["Format Quest Completed"] = ERR_QUEST_COMPLETE_S or "%s abgeschlossen.";
L["Format Player XP"] = PET_BATTLE_CURRENT_XP_FORMAT_BOTH or  "XP: %d/%d (%d%%)";
L["Format Gold Amount"] = GOLD_AMOUNT or "%d Gold";
L["Format Silver Amount"] = SILVER_AMOUNT or "%d Silber";
L["Format Copper Amount"] = COPPER_AMOUNT or "%d Kupfer";
L["Format Unit Level"] = UNIT_LEVEL_TEMPLATE or "Level %d";
L["Format Replace Item"] = "Ersetzt %s";


--Settings
L["UI"] = "UI";
L["Camera"] = "Kamera";
L["Control"] = "Steuerung";
L["Gameplay"] = SETTING_GROUP_GAMEPLAY or "Gameplay";

L["Quest"] = "Quest";
L["Gossip"] = "Begrüßungsfenster";
L["Theme"] = "Thema";
L["Theme Desc"] = "Wähle ein Farbthema für die Benutzeroberfläche.";
L["Frame Size"] = "Fenstergröße";
L["Frame Size Desc"] = "Wähle die Größe für das Dialogfenster.";
L["Font Size"] = "Schriftgröße";
L["Font Size Desc"] = "Wähle die Schriftgröße für die Benutzeroberfläche.";
L["Hide UI"] = "Benutzeroberfläche ausblenden";
L["Hide UI Desc"] = "Lässt die Benutzeroberfläche verblassen, wenn du mit einem NPC interagierst.";
L["Hide Unit Names"] = "Namen ausblenden";
L["Hide Unit Names Desc"] = "Blende die Namen anderer Spieler und NPCs aus, wenn du mit einem NPC interagierst.";
L["Show Copy Text Button"] = "Text kopieren Taste anzeigen";
L["Show Copy Text Button Desc"] = "Zeigt die Text kopieren Taste oben rechts im Dialogfenster.";
L["Show Quest Type Text"] = "Questtyp anzeigen";
L["Show Quest Type Text Desc"] = "Den Questtyp rechts neben der Option anzeigen, wenn sie besonders ist.\n\nNiedrigstufige Quests sind immer gekennzeichnet.";
L["Show NPC Name On Page"] = "NPC Namen anzeigen";
L["Show NPC Name On Page Desc"] = "Zeigt den NPC Namen in der Beschreibung an.";
L["Simplify Currency Rewards"] = "Vereinfachte Währungsbelohnungen";
L["Simplify Currency Rewards Desc"] = "Kleinere Icons ohne Text für Währungsbelohnungen.";

L["Camera Movement"] = "Kamera Bewegung";
L["Camera Movement Off"] = "AUS";
L["Camera Movement Zoom In"] = "Reinzoomen";
L["Camera Movement Horizontal"] = "Horizontal";
L["Maintain Camera Position"] = "Kameraposition beibehalten";
L["Maintain Camera Position Desc"] = "Behalte die Kameraposition kurzfristig bei, wenn du mit einem NPC interagiert hast.\n\nDiese Option reduziert die plötzliche Bewegung der Kamera, die durch die Latenz zwischen den Dialogen verursacht wird.";
L["Change FOV"] = "Change FOV";
L["Change FOV Desc"] = "Reduce the camera\'s field of view to zoom in closer to the NPC.";

L["Input Device"] = "Eingabegerät";
L["Input Device Desc"] = "Dies beeinflusst die Tastenkombinationen und die Benutzeroberfläche.";
L["Input Device KBM"] = "KB&M";
L["Input Device Xbox"] = "Xbox";
L["Input Device Xbox Tooltip"] = "Bestätigungstaste: [KEY:XBOX:PAD1]\nAbbruchtaste: [KEY:XBOX:PAD2]";
L["Input Device PlayStation"] = "PlayStation";
L["Input Device PlayStation Tooltip"] = "Bestätigungstaste: [KEY:PS:PAD1]\nAbbruchtaste: [KEY:PS:PAD2]";
L["Primary Control Key"] = "Bestätigungstaste";
L["Primary Control Key Desc"] = "Diese Taste verwenden, um die erste Option wie zum Beispiel Quest akzeptieren, auszuwählen.";
L["Press Button To Scroll Down"] = "Drücke die Taste, um nach unten zu scrollen";
L["Press Button To Scroll Down Desc"] = "Wenn der Inhalt höher als der Bildschirm ist, wird durch Drücken der Bestätigungstaste die Seite nach unten gescrollt, anstatt die Quest zu akzeptieren.";

L["Key Space"] = "Leertaste";
L["Key Interact"] = "Interagieren";
L["Cannot Use Key Combination"] = "Tastenkombination wird nicht unterstützt.";
L["Interact Key Not Set"] = "Du hast keine Interaktionstaste festgelegt."

L["Auto Select"] = "Automatische Auswahl";
L["Auto Select Gossip"] = "Automatische Optionen Auswahl";
L["Auto Select Gossip Desc"] = "Wählt automatisch die beste Option, wenn du mit einem NPC interagierst.";
L["Force Gossip"] = "Dialogfenster erzwingen";
L["Force Gossip Desc"] = "Manchmal wählt das Spiel automatisch die erste Option des Dialogs aus. Wenn du Dialogfenster erzwingen anschaltest, umgehst du dies.";
L["Nameplate Dialog"] = "Dialog auf Namensplaketten anzeigen";
L["Nameplate Dialog Desc"] = "Den Dialog auf der Namensplakette des NPCs anzeigen, wenn sie keine Wahl anbieten.\n\nDiese Option ändert die CVar \"SoftTarget Nameplate Interact\".";


--Tutorial
L["Tutorial Settings Hotkey"] = "Benutze [KEY:PC:F1] um die Einstellungen zu öffnen/schließen";
L["Tutorial Settings Hotkey Console"] = "Benutze [KEY:PC:F1] oder [KEY:CONSOLE:MENU] um die Einstellungen zu öffnen/schließen";   --Use this if gamepad enabled


--DO NOT TRANSLATE
L["Match Stat Armor"] = "([,%d%.]+) Rüstung";
L["Match Stat Stamina"] = "([,%d%.]+) Ausdauer";
L["Match Stat Strengh"] = "([,%d%.]+) Stärke";
L["Match Stat Agility"] = "([,%d%.]+) Beweglichkeit";
L["Match Stat Intellect"] = "([,%d%.]+) Intelligenz";
L["Match Stat Spirit"] = "([,%d%.]+) Willenskraft";
L["Match Stat DPS"] = "([,%d%.]+) Schaden pro Sekunde";

L["Show Answer"] = "Lösung anzeigen.";
L["Quest Failed Pattern"] = "^Abgabe von";
L["AutoCompleteQuest HallowsEnd"] = "Eimer mit Süßigkeiten";     --Quest:28981

--Asking for Directions-- (match the name to replace gossip icon)
L["Pin Auction House"] = "Auktionshaus";
L["Pin Bank"] = "Bank";
L["Pin Barber"] = "Barbier";
L["Pin Battle Pet Trainer"] = "Kampfhaustiertrainer";
L["Pin Crafting Orders"] = "Handwerksaufträge";
L["Pin Flight Master"] = "Flugmeister";
L["Pin Great Vault"] = "Große Schatzkammer";
L["Pin Inn"] = "Gasthaus";
L["Pin Item Upgrades"] = "Gegenstandsaufwertungen";
L["Pin Mailbox"] = "Briefkasten";
L["Pin Other Continents"] = "Andere Kontinente";
L["Pin POI"] = "Bedeutende Orte";
L["Pin Profession Trainer"] = "Berufsausbilder";
L["Pin Rostrum"] = "Podium der Transformation";
L["Pin Stable Master"] = "Stallmeister";
L["Pin Trading Post"] = "Handelsposten";