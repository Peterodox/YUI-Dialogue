--Contributors: Brainc3ll, Zazou89
if not (GetLocale() == "frFR") then return end;

local _, addon = ...
local L = addon.L;


L["Quest Frequency Daily"] = DAILY or "Journalière";
L["Quest Frequency Weekly"] = WEEKLY or "Hebdomadaire";

L["Quest Type Repeatable"] = "Répétable";
L["Quest Type Trivial"] = "Bas niveau";    --Low-level quest
L["Quest Type Dungeon"] = LFG_TYPE_DUNGEON or "Donjon";
L["Quest Type Raid"] = LFG_TYPE_RAID or "Raid";
L["Quest Type Covenant Calling"] = "Appel de Congrégation";

L["Accept"] = ACCEPT or "Accepter";
L["Continue"] = CONTINUE or "Continuer";
L["Complete Quest"] = COMPLETE_QUEST or "Terminer la quête";
L["Incomplete"] = INCOMPLETE or "Incomplète";
L["Cancel"] = CANCEL or "Annuler";
L["Goodbye"] = GOODBYE or "Au revoir";
L["Decline"] = DECLINE or "Decliner";
L["OK"] = "OK";
L["Quest Objectives"] = OBJECTIVES_LABEL or "Objectifs";   --We use the shorter one, not QUEST_OBJECTIVES
L["Reward"] = REWARD or "Récompense";
L["Rewards"] = REWARDS or "Récompenses";
L["War Mode Bonus"] = WAR_MODE_BONUS or "Bonus de mode Guerre";
L["Honor Points"] = HONOR_POINTS or "Honneur";
L["Symbol Gold"] = GOLD_AMOUNT_SYMBOL or "o";
L["Symbol Silver"] = Silver_AMOUNT_SYMBOL or "a";
L["Symbol Copper"] = COPPER_AMOUNT_SYMBOL or "c";
L["Requirements"] = REQUIREMENTS or "Requis";
L["Current Colon"] = ITEM_UPGRADE_CURRENT or "Actuel :";
L["Renown Level Label"] = RENOWN_LEVEL_LABEL or "Renom ";  --There is a space
L["Abilities"] = ABILITIES or "Capacités";
L["Traits"] = GARRISON_RECRUIT_TRAITS or "Traits";
L["Costs"] = "Coûts";   --The costs to continue an action, usually gold
L["Ready To Enter"] = QUEUED_STATUS_PROPOSAL or "Prêt à entrer";
L["Show Comparison"] = "Afficher la comparaison";   --Toggle item comparison on the tooltip
L["Hide Comparison"] = "Cacher la comparaison";
L["Copy Text"] = "Copier le texte";
L["To Next Level Label"] = COVENANT_MISSIONS_XP_TO_LEVEL or "Jusqu'au prochain niveau";
L["Quest Accepted"] = "Quête acceptée";
L["Quest Log Full"] = "Journal de quêtes complet";
L["Quest Auto Accepted Tooltip"] = "Cette quête est automatiquement acceptée par le jeu.";
L["Level Maxed"] = "(Max)";   --Reached max level
L["Paragon Reputation"] = "Parangon";
L["Different Item Types Alert"] = "Le type d'objet est different !";
L["Click To Read"] = "Clic gauche pour lire";
L["Item Level"] = STAT_AVERAGE_ITEM_LEVEL or "Niveau d'objet";														  
L["Gossip Quest Option Prepend"] = "(Quête)";   --Some gossip options start with blue (Quest), we prioritize them when sorting. See GOSSIP_QUEST_OPTION_PREPEND
L["TTS Button Tooltip"] = "Clic gauche : Démarrer/Arrêter la lecture.\nClic droit : Activer/désactiver la lecture automatique";

--String Format
L["Format Reputation Reward Tooltip"] = QUEST_REPUTATION_REWARD_TOOLTIP or "Récompense %d de réputation avec les %s";
L["Format You Have X"] = "- Vous avez |cffffffff%d|r";
L["Format You Have X And Y In Bank"] = "- Vous avez |cffffffff%d|r (|cffffffff%d|r dans votre banque)";
L["Format Suggested Players"] = QUEST_SUGGESTED_GROUP_NUM or "Joueurs suggérés [%d]";
L["Format Current Skill Level"] = "Niveau Actuel : |cffffffff%d/%d|r";
L["Format Reward Title"] = HONOR_REWARD_TITLE or "Titre: %s";
L["Format Follower Level Class"] = FRIENDS_LEVEL_TEMPLATE or "Niveau %d %s";
L["Format Monster Say"] = CHAT_MONSTER_SAY_GET or "%s dit: ";
L["Format Quest Accepted"] = ERR_QUEST_ACCEPTED_S or "Quête acceptée: %s";
L["Format Quest Completed"] = ERR_QUEST_COMPLETE_S or "%s complétée.";
L["Format Player XP"] = PET_BATTLE_CURRENT_XP_FORMAT_BOTH or  "XP : %d/%d (%d%%)";
L["Format Gold Amount"] = GOLD_AMOUNT or "%d Or";
L["Format Silver Amount"] = SILVER_AMOUNT or "%d Argent";
L["Format Copper Amount"] = COPPER_AMOUNT or "%d Cuivre";
L["Format Unit Level"] = UNIT_LEVEL_TEMPLATE or "Niveau %d";
L["Format Replace Item"] = "Remplace %s";
L["Format Item Level"] = "Niveau d'objet %d";   --_G.ITEM_LEVEL in Classic is different																				   
L["Format Breadcrumb Quests Available"] = "Quêtes de changement de zone disponibles: %s"; --This type of quest guide the player to a new quest zone. See "Breadcrumb" on https://warcraft.wiki.gg/wiki/Quest#Quest_variations
L["Format Functionality Handled By"] = "Cette fonctionnalité est prise en charge par %s";      --A functionality is provided by [another addon name] (Used in Settings.lua)

--Settings
L["UI"] = "UI";
L["Camera"] = "Camera";
L["Control"] = "Contrôle";
L["Gameplay"] = SETTING_GROUP_GAMEPLAY or "Jeu";
L["Accessibility"] = SETTING_GROUP_ACCESSIBILITY or "Accessibilité";

L["Option Enabled"] = VIDEO_OPTIONS_ENABLED or "Activé";
L["Option Disabled"] = VIDEO_OPTIONS_DISABLED or "Désactivé";
L["Move Position"] = "Déplacer";
L["Reset Position"] = RESET_POSITION or "Réinitialise la position";
L["Drag To Move"] = "Cliquez avec le bouton gauche de la souris et faites glisser pour déplacer la fenêtre.";

L["Quest"] = "Quête";
L["Gossip"] = "Discussion";
L["Theme"] = "Thème";
L["Theme Desc"] = "Sélectionnez un thème pour l'UI.";
L["Theme Brown"] = "Clair";
L["Theme Dark"] = "Sombre";
L["Frame Size"] = "Taille de la fenêtre";
L["Frame Size Desc"] = "Ajuste la taille de l'UI de dialogue.\n\nDéfaut : Moyenne";
L["Size Extra Small"] = "Très petite";
L["Size Small"] = "Petite";
L["Size Medium"] = "Moyenne";
L["Size Large"] = "Large";
L["Font Size"] = "Taille de la police";
L["Font Size Desc"] = "Ajuste la taille de la police.\n\nDéfaut : 12";
L["Hide UI"] = "Cacher l'UI";
L["Hide UI Desc"] = "Cacher l’interface du jeu lorsque vous interagissez avec un PNJ.";
L["Hide Unit Names"] = "Cacher le nom des unités";
L["Hide Unit Names Desc"] = "Cache les noms des joueurs.euses et des autres PNJ lorsque vous interagissez avec un PNJ.";
L["Show Copy Text Button"] = "Afficher le bouton de copie de texte";
L["Show Copy Text Button Desc"] = "Affiche le bouton de copie de texte en haut à droite de l'UI de dialogue.";
L["Show Quest Type Text"] = "Afficher le texte du type de quête";
L["Show Quest Type Text Desc"] = "Affiche le type de quête à droite de l’option si elle est spéciale.\n\nLes quêtes de bas niveau sont toujours indiquées.";
L["Show NPC Name On Page"] = "Afficher le nom du PNJ";
L["Show NPC Name On Page Desc"] = "Affiche le nom de PNJ sur la page.";
L["Simplify Currency Rewards"] = "Simplifier les récompenses en monnaie";
L["Simplify Currency Rewards Desc"] = "Utilise des icônes plus petites pour les récompenses en monnaie et cache leurs noms.";
L["Mark Highest Sell Price"] = "Marquer l'objet le plus rentable";
L["Mark Highest Sell Price Desc"] = "Marque l'objet en récompense ayant la plus grande valeur de revente.";
L["Roleplaying"] = GDAPI_REALMTYPE_RP or "JDR";
L["Use RP Name In Dialogues"] = "Utiliser votre nom JDR dans les dialogues";
L["Use RP Name In Dialogues Desc"] = "Remplace le nom de votre personnage dans les dialogues par votre nom JDR.";

L["Camera Movement"] = "Mouvement de la caméra";
L["Camera Movement Off"] = "DÉSACTIVÉ";
L["Camera Movement Zoom In"] = "Zoomer";
L["Camera Movement Horizontal"] = "Horizontale";
L["Maintain Camera Position"] = "Maintenir la position de la caméra";
L["Maintain Camera Position Desc"] = "Maintien brièvement la position de la caméra après la fin de l’interaction avec les PNJ.\n\nL'activation de cette option réduira les mouvements brusques de la caméra causés par la latence entre les dialogues.";
L["Change FOV"] = "Changer le FOV";
L["Change FOV Desc"] = "Réduit le champ de vision de la caméra pour zoomer plus près du PNJ.";
L["Disable Camera Movement Instance"] = "Désactiver lors d'une instance";
L["Disable Camera Movement Instance Desc"] = "Désactive les mouvements de la caméra en donjon ou en raid.";
L["Maintain Offset While Mounted"] = "Maintenir le décalage sur une monture";
L["Maintain Offset While Mounted Desc"] = "Tente de maintenir la position de votre personnage à l’écran lorsqu’il est sur une monture.\n\nL’activation de cette option peut surcompenser le décalage horizontal pour les montures de grande taille.";

L["Input Device"] = "Périphérique d'entrée";
L["Input Device Desc"] = "Affecte les icônes de raccourci clavier et la disposition de l'UI.";
L["Input Device KBM"] = "Clavier";
L["Input Device Xbox"] = "Xbox";
L["Input Device Xbox Tooltip"] = "Bouton de confirmation: [KEY:XBOX:PAD1]\nBouton d'annulation: [KEY:XBOX:PAD2]";
L["Input Device PlayStation"] = "PlayStation";
L["Input Device PlayStation Tooltip"] = "Bouton de confirmation: [KEY:PS:PAD1]\nBouton d'annulation: [KEY:PS:PAD2]";
L["Primary Control Key"] = "Bouton de confirmation";
L["Primary Control Key Desc"] = "Appuyez sur cette touche pour sélectionner la première option disponible comme Accepter."
L["Press Button To Scroll Down"] = "Appuyer sur le bouton fait défiler vers le bas";
L["Press Button To Scroll Down Desc"] = "Si le contenu est plus grand que la fenêtre d'affichage, appuyer sur le bouton Confirmer fera défiler la page vers le bas au lieu d'accepter la quête.";

L["Key Space"] = "Espace";
L["Key Interact"] = "Interagir";
L["Cannot Use Key Combination"] = "La combinaison de touches n'est pas prise en charge.";
L["Interact Key Not Set"] = "Vous n'avez pas défini de raccourci pour Interagir."
L["Use Default Control Key Alert"] = "[KEY:PC:SPACE] sera toujours utilisé comme bouton de confirmation.";
L["Key Disabled"] = "Désactivé";
L["Key Disabled Tooltip"] = "le bouton de confirmation est désactivé.\n\nVous ne pourrez pas accepter de quêtes avec une touche.";

L["Quest Item Display"] = "Afficher l'objet de quête"
L["Quest Item Display Desc"] = "Affiche automatiquement la description de l'objet de quête et vous permet de l'utiliser sans ouvrir les sacs.";
L["Quest Item Display Hide Seen"] = "Ignorer les objets déjà vus";
L["Quest Item Display Hide Seen Desc"] = "Ignore les objets qui ont déjà été découverts par l'un de vos personnages.";
L["Quest Item Display Reset Position Desc"] = "Réinitialise la position de la fenêtre.";
L["Auto Select"] = "Selection Auto";
L["Auto Select Gossip"] = "Sélection automatique";
L["Auto Select Gossip Desc"] = "Sélectionne automatiquement la meilleure option de dialogue lors de l’interaction avec certains PNJ.";
L["Force Gossip"] = "Forcer la discussion";
L["Force Gossip Desc"] = "Par défaut, le jeu sélectionne parfois automatiquement la première option sans afficher la boîte de dialogue. En activant Forcer la discussion, la boîte de dialogue deviendra visible.";
L["Nameplate Dialog"] = "Afficher le dialogue sur la barre d'info";
L["Nameplate Dialog Desc"] = "Affiche le dialogue sur la barre d'info du PNJ s'il ne propose pas de choix.\n\nCette option modifie la CVar \"SoftTarget Nameplate Interact\".";

L["TTS"] = TEXT_TO_SPEECH or "Synthèse vocale (TTS)";
L["TTS Desc"] = "Lis le texte du dialogue à haute voix.";
L["TTS Use Hotkey"] = "Utiliser un raccourci";
L["TTS Use Hotkey Desc"] = "Démarrez ou arrêtez la lecture avec:";
L["TTS Use Hotkey Tooltip PC"] = "[KEY:PC:R]";
L["TTS Use Hotkey Tooltip Xbox"] = "[KEY:XBOX:LT]";
L["TTS Use Hotkey Tooltip PlayStation"] = "[KEY:PS:LT]";
L["TTS Auto Play"] = "Lecture automatique";
L["TTS Auto Play Desc"] = "Lis automatiquement les textes de dialogue.";
L["TTS Auto Stop"] = "Arrêter en quittant";
L["TTS Auto Stop Desc"] = "Arrête la lecture quand on quitte le PNJ.";

--Tutorial
L["Tutorial Settings Hotkey"] = "Utilisez [KEY:PC:F1] pour afficher les options";
L["Tutorial Settings Hotkey Console"] = "utilisez [KEY:PC:F1] ou [KEY:CONSOLE:MENU] pour afficher les options";   --Use this if gamepad enabled


--DO NOT TRANSLATE
L["Match Stat Armor"] = "Armure : ([,%d%.%-]+)";
L["Match Stat Stamina"] = "([,%d%.%-]+) Endurance";
L["Match Stat Strengh"] = "([,%d%.%-]+) Force";
L["Match Stat Agility"] = "([,%d%.%-]+) Agilité";
L["Match Stat Intellect"] = "([,%d%.%-]+) Intelligence";
L["Match Stat Spirit"] = "([,%d%.%-]+) Esprit";
L["Match Stat DPS"] = "([,%d%.%-]+) dégâts par seconde";