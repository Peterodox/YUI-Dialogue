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


--Settings
L["UI"] = "UI";
L["Camera"] = "Camera";
L["Control"] = "Contrôle";
L["Gameplay"] = SETTING_GROUP_GAMEPLAY or "Jeu";

L["Quest"] = "Quête";
L["Gossip"] = "Discussion";
L["Theme"] = "Thème";
L["Theme Desc"] = "Sélectionnez un thème pour l'UI.";
L["Theme Brown"] = "Clair";
L["Theme Dark"] = "Sombre";
L["Frame Size"] = "Taille de la fenêtre";
L["Frame Size Desc"] = "Ajuste la taille de l'UI de dialogue.\n\nDéfaut : Moyenne";
L["Font Size"] = "Taille de la police";
L["Font Size Desc"] = "Ajuste la taille de la police.\n\nDéfaut : 12";
L["Size Extra Small"] = "Très petite";
L["Size Small"] = "Petite";
L["Size Medium"] = "Moyenne";
L["Size Large"] = "Large";
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

L["Camera Movement"] = "Mouvement de la caméra";
L["Camera Movement Off"] = "DÉSACTIVÉ";
L["Camera Movement Zoom In"] = "Zoomer";
L["Camera Movement Horizontal"] = "Horizontale";
L["Maintain Camera Position"] = "Maintenir la position de la caméra";
L["Maintain Camera Position Desc"] = "Maintien brièvement la position de la caméra après la fin de l’interaction avec les PNJ. L'activation de cette option réduira les mouvements brusques de la caméra causés par la latence entre les dialogues.";
L["Change FOV"] = "Changer le FOV";
L["Change FOV Desc"] = "Réduit le champ de vision de la caméra pour zoomer plus près du PNJ.";

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

L["Quest Item Display"] = "Afficher l'objet de quête"
L["Quest Item Display Desc"] = "Affiche automatiquement la description de l'objet de quête et vous permet de l'utiliser sans ouvrir les sacs.";
L["Quest Item Display Hide Seen"] = "Ignorer les objets déjà vus";
L["Quest Item Display Hide Seen Desc"] = "Ignore les objets qui ont déjà été découverts par l'un de vos personnages.";
L["Auto Select"] = "Selection Auto";
L["Auto Select Gossip"] = "Sélection automatique";
L["Auto Select Gossip Desc"] = "Sélectionne automatiquement la meilleure option de dialogue lors de l’interaction avec certains PNJ.";
L["Force Gossip"] = "Forcer la discussion";
L["Force Gossip Desc"] = "Par défaut, le jeu sélectionne parfois automatiquement la première option sans afficher la boîte de dialogue. En activant Forcer la discussion, la boîte de dialogue deviendra visible.";
L["Nameplate Dialog"] = "Afficher le dialogue sur la barre d'info";
L["Nameplate Dialog Desc"] = "Affiche le dialogue sur la barre d'info du PNJ s'il ne propose pas de choix.\n\nCette option modifie la CVar \"SoftTarget Nameplate Interact\".";


--Tutorial
L["Tutorial Settings Hotkey"] = "Utilisez [KEY:PC:F1] pour afficher les options";
L["Tutorial Settings Hotkey Console"] = "utilisez [KEY:PC:F1] ou [KEY:CONSOLE:MENU] pour afficher les options";   --Use this if gamepad enabled