
if not (GetLocale() == "esES") then return end;


local _, addon = ...
local L = addon.L;

L["Quest Frequency Daily"] = DAILY or "Diaria";
L["Quest Frequency Weekly"] = WEEKLY or "Semanal";

L["Quest Type Repeatable"] = "Repetible";
L["Quest Type Trivial"] = "Trivial";    --Low-level quest
L["Quest Type Dungeon"] = LFG_TYPE_DUNGEON or "Mazmorra";
L["Quest Type Raid"] = LFG_TYPE_RAID or "Banda";
L["Quest Type Covenant Calling"] = "Llamamiento de Pacto";

L["Accept"] = ACCEPT or "Aceptar";
L["Continue"] = CONTINUE or "Continuar";
L["Complete Quest"] = COMPLETE_QUEST or "Completar misión";
L["Incomplete"] = INCOMPLETE or "Incompleta";
L["Cancel"] = CANCEL or "Cancelar";
L["Goodbye"] = GOODBYE or "Adiós";
L["Decline"] = DECLINE or "Rechazar";
L["OK"] = "OK";
L["Quest Objectives"] = OBJECTIVES_LABEL or "Objetivos";   --We use the shorter one, not QUEST_OBJECTIVES
L["Reward"] = REWARD or "Recompensa";
L["Rewards"] = REWARDS or "Recompensas";
L["War Mode Bonus"] = WAR_MODE_BONUS or "Bonus Modo Guerra";
L["Honor Points"] = HONOR_POINTS or "Honor";
L["Symbol Gold"] = GOLD_AMOUNT_SYMBOL or "o";
L["Symbol Silver"] = SILVER_AMOUNT_SYMBOL or "p";
L["Symbol Copper"] = COPPER_AMOUNT_SYMBOL or "c";
L["Requirements"] = REQUIREMENTS or "Requisitos";
L["Current Colon"] = ITEM_UPGRADE_CURRENT or "Actual:";
L["Renown Level Label"] = RENOWN_LEVEL_LABEL or "Renombre ";  --There is a space
L["Abilities"] = ABILITIES or "Habilidades";
L["Traits"] = GARRISON_RECRUIT_TRAITS or "Rasgos";
L["Costs"] = "Costs";   --The costs to continue an action, usually gold
L["Ready To Enter"] = QUEUED_STATUS_PROPOSAL or "Listo para entrar";
L["Show Comparison"] = "Mostrar comparación";   --Toggle item comparison on the tooltip
L["Hide Comparison"] = "Ocultar comparación";
L["Copy Text"] = "Copiar texto";
L["To Next Level Label"] = COVENANT_MISSIONS_XP_TO_LEVEL or "Para siguiente nivel";
L["Quest Accepted"] = "Misión Aceptada";
L["Quest Log Full"] = "Registro de misiones lleno";
L["Quest Auto Accepted Tooltip"] = "Esta misión es aceptada automáticamente por el juego.";
L["Level Maxed"] = "(Máximo)";   --Reached max level
L["Paragon Reputation"] = "Dechado";
L["Different Item Types Alert"] = "¡El tipo de objeto es diferente!";
L["Click To Read"] = "Clic izquierdo para leer";
L["Item Level"] = STAT_AVERAGE_ITEM_LEVEL or "Nivel de objeto";
L["Gossip Quest Option Prepend"] = "(Misión)";   --Some gossip options start with blue (Quest), we prioritize them when sorting. See GOSSIP_QUEST_OPTION_PREPEND
L["TTS Button Tooltip"] = "Click izquierdo: Iniciar/Parar lectura.\nClick derecho: Activar inicio automático";
L["Item Is An Upgrade"] = "Este objeto es una mejora para ti";
L["Identical Stats"] = "Los dos objetos tienen las mismas estadísticas.";   --Two items provide the same stats
L["Quest Completed On Account"] = (ACCOUNT_COMPLETED_QUEST_NOTICE or "Tu Banda Guerrera ya ha completado esta misión.");

--String Format
L["Format Reputation Reward Tooltip"] = QUEST_REPUTATION_REWARD_TOOLTIP or "Otorga %d de reputación con %s";
L["Format You Have X"] = "- Tienes |cffffffff%d|r";
L["Format You Have X And Y In Bank"] = "- Tienes |cffffffff%d|r (|cffffffff%d|r en tu banco)";
L["Format Suggested Players"] = QUEST_SUGGESTED_GROUP_NUM or "Jugadores sugeridos [%d]";
L["Format Current Skill Level"] = "Nivel actual: |cffffffff%d/%d|r";
L["Format Reward Title"] = HONOR_REWARD_TITLE or "Título: %s";
L["Format Follower Level Class"] = FRIENDS_LEVEL_TEMPLATE or "Nivel %d %s";
L["Format Monster Say"] = CHAT_MONSTER_SAY_GET or "%s dice: ";
L["Format Quest Accepted"] = ERR_QUEST_ACCEPTED_S or "Misión aceptada: %s";
L["Format Quest Completed"] = ERR_QUEST_COMPLETE_S or "%s completada.";
L["Format Player XP"] = PET_BATTLE_CURRENT_XP_FORMAT_BOTH or  "EXP: %d/%d (%d%%)";
L["Format Gold Amount"] = GOLD_AMOUNT or "%d Oro";
L["Format Silver Amount"] = SILVER_AMOUNT or "%d Plata";
L["Format Copper Amount"] = COPPER_AMOUNT or "%d Cobre";
L["Format Unit Level"] = UNIT_LEVEL_TEMPLATE or "Nivel %d";
L["Format Replace Item"] = "Reemplaza %s";
L["Format Item Level"] = "Nivel de objeto %d";   --_G.ITEM_LEVEL in Classic is different
L["Format Breadcrumb Quests Available"] = "Misiones de camino de migas disponibles: %s";    --This type of quest guide the player to a new quest zone. See "Breadcrumb" on https://warcraft.wiki.gg/wiki/Quest#Quest_variations
L["Format Functionality Handled By"] = "Esta funcionalidad la gestiona %s";      --A functionality is provided by [another addon name] (Used in Settings.lua)

--Settings
L["UI"] = "Interfaz";
L["Camera"] = "Cámara";
L["Control"] = "Controles";
L["Gameplay"] = SETTING_GROUP_GAMEPLAY or "Jugabilidad";
L["Accessibility"] = SETTING_GROUP_ACCESSIBILITY or "Accesibilidad";

L["Option Enabled"] = VIDEO_OPTIONS_ENABLED or "Activado";
L["Option Disabled"] = VIDEO_OPTIONS_DISABLED or "Desactivado";
L["Move Position"] = "Mover";
L["Reset Position"] = RESET_POSITION or "Reiniciar posición";
L["Drag To Move"] = "Click izquierdo y arrastrar para mover la ventana.";

L["Quest"] = "Misión";
L["Gossip"] = "Charla";
L["Theme"] = "Tema";
L["Theme Desc"] = "Selecciona un tema de color para la interfaz.";
L["Theme Brown"] = "Marrón";
L["Theme Dark"] = "Oscuro";
L["Frame Size"] = "Tamaño de la ventana";
L["Frame Size Desc"] = "Establece el tamaño de la ventana.\n\nPor defecto: Mediano";
L["Size Extra Small"] = "Muy pequeña";
L["Size Small"] = "Pequeña";
L["Size Medium"] = "Mediana";
L["Size Large"] = "Grande";
L["Font Size"] = "Tamaño de Fuente";
L["Font Size Desc"] = "Establece el tamaño de la fuente de la interfaz.\n\nPor defecto: 12";
L["Frame Orientation"] = "Posición";
L["Frame Orientation Desc"] = "Posiciona la ventana a la izquierda o derecha de la pantalla";
L["Orientation Left"] = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_LEFT or "Izquierda";
L["Orientation Right"] = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_RIGHT or "Derecha";
L["Hide UI"] = "Ocultar IU";
L["Hide UI Desc"] = "Oculta la interfaz del juego cuado interactúas con un PNJ.";
L["Hide Unit Names"] = "Ocultar marco de unidades";
L["Hide Unit Names Desc"] = "Oculta los nombres de jugadores y otros PNJ cuando interactúas con un PNJ.";
L["Show Copy Text Button"] = "Mostrar Botón Copiar Texto";
L["Show Copy Text Button Desc"] = "Muestra el botón para copiar el texto en la parte superior derecha de dialogue UI.";
L["Show Quest Type Text"] = "Mostrar texto de tipo de misión";
L["Show Quest Type Text Desc"] = "Muestra el tipo de misión a la derecha de la opción si es especial.\n\nLas misiones de bajo nivel siempre se etiquetan.";
L["Show NPC Name On Page"] = "Mostrar nombre del PNJ";
L["Show NPC Name On Page Desc"] = "Mostrar el nombre del PNJ en la página.";
L["Show Warband Completed Quest"] = MINIMAP_TRACKING_ACCOUNT_COMPLETED_QUESTS or "Misiones completadas por tu Banda Guerrera";
L["Show Warband Completed Quest Desc"] = "Mostrar una nota al final del detalle de misión si ya has completado la misión con otro personaje.";
L["Simplify Currency Rewards"] = "Simplificar recompensas de Monedas";
L["Simplify Currency Rewards Desc"] = "Utilizar iconos más pequeños para las recompensas de Monedas y ocultar sus nombres.";
L["Mark Highest Sell Price"] = "Marcar precio de venta más alto";
L["Mark Highest Sell Price Desc"] = "Muestra qué objeto tiene el mayor precio de venta al elegir una recompensa.";
L["Use Blizzard Tooltip"] = "Utilizar tooltip de Blizzard";
L["Use Blizzard Tooltip Desc"] = "Utiliza el tooltip de Blizzard para las recompensas de misión en vez de nuestro tooltip especial.";
L["Roleplaying"] = GDAPI_REALMTYPE_RP or "Juego de Rol";
L["Use RP Name In Dialogues"] = "Utilizar nombre de JdR en Diálogos";
L["Use RP Name In Dialogues Desc"] = "Reemplaza el nombre de tu personaje con tu nombre de JdR.";

L["Camera Movement"] = "Movimiento de Cámara";
L["Camera Movement Off"] = "Sin movimiento";
L["Camera Movement Zoom In"] = "Acercar";
L["Camera Movement Horizontal"] = "Horizontal";
L["Maintain Camera Position"] = "Mantener posición de cámara";
L["Maintain Camera Position Desc"] = "Mantiene la posición de cámara brevemente tras finalizar la interacción con el PNJ.\n\nActivar esta opción reducirá el movimiento brusco de cámara causado por la latencia entre diálogos.";
L["Change FOV"] = "Cambiar Campo de Visión";
L["Change FOV Desc"] = "Reduce el campo de visión al acercar la cámara al PNJ.";
L["Disable Camera Movement Instance"] = "Desactivar en estancias";
L["Disable Camera Movement Instance Desc"] = "Desactiva el movimiento de cámara en una mazmorra o banda.";
L["Maintain Offset While Mounted"] = "Mantener offset en montura";
L["Maintain Offset While Mounted Desc"] = "Intenta mantener la posición de tu personaje en la pantalla mientras estás en una montura.\n\nAxctivar esta opción puede sobrecompensar el offset horizontal para monturas grandes.";

L["Input Device"] = "Dispositivo de entrada";
L["Input Device Desc"] = "Afecta a los iconos de teclas y organización de la interfaz.";
L["Input Device KBM"] = "Teclado y ratón";
L["Input Device Xbox"] = "Xbox";
L["Input Device Xbox Tooltip"] = "Confirmar: [KEY:XBOX:PAD1]\nCancelar: [KEY:XBOX:PAD2]";
L["Input Device PlayStation"] = "PlayStation";
L["Input Device PlayStation Tooltip"] = "Confirmar: [KEY:PS:PAD1]\nCancelar: [KEY:PS:PAD2]";
L["Input Device Switch"] = "Intercambiar";
L["Input Device Switch Tooltip"] = "Confirmar: [KEY:SWITCH:PAD1]\nCancelar: [KEY:SWITCH:PAD2]";
L["Primary Control Key"] = "Confirmar";
L["Primary Control Key Desc"] = "Presiona esta tecla para seleccionar la primera opción disponible, como Aceptar Misión."
L["Press Button To Scroll Down"] = "Presionar Botón para deslizar verticalmente";
L["Press Button To Scroll Down Desc"] = "Si el contenido es más alto que la ventana, presionar el botón de confirmación deslizará verticalmente la página hacia abajo en vez de aceptar la misión.";
L["Right Click To Close UI"] = "Click derecho para cerrar la interfaz";
L["Right Click To Close UI Desc"] = "Click derecho en dialogue UI para cerrarlo.";

L["Key Space"] = "Espacio";
L["Key Interact"] = "Interactuar";
L["Cannot Use Key Combination"] = "No se permite la combinación de teclas.";
L["Interact Key Not Set"] = "[KEY:PC:INVALID] No has establecido una tecla de interacción."
L["Use Default Control Key Alert"] = "Utilizaremos [KEY:PC:SPACE] como Botón de Confirmación.";
L["Key Disabled"] = "Deshabilitado";
L["Key Disabled Tooltip"] = "Botón de Confirmación deshabilitado.\n\nNo podrás aceptar misiones presionando teclas.";

L["Quest Item Display"] = "Mostrar Objeto de Misión";
L["Quest Item Display Desc"] = "Muestra la descripción del Objeto de Misión aiutomáticamente y te permite utilizarlo sin abrir la bolsa.";
L["Quest Item Display Hide Seen"] = "Ignorar Objetos ya vistos";
L["Quest Item Display Hide Seen Desc"] = "Ignorar objetos que ya han sido descubiertos por tus otros personajes.";
L["Quest Item Display Reset Position Desc"] = "Reiniciar la posición de la ventana.";
L["Auto Select"] = "Auto Selecccionar";
L["Auto Select Gossip"] = "Auto Seleccionar Opción";
L["Auto Select Gossip Desc"] = "Selecciona automáticamente la mejor opción de diálogo al interactuar con ciertos PNJ.";
L["Force Gossip"] = "Forzar Charla";
L["Force Gossip Desc"] = "Por defecto, el juego a veces selecciona automáticamente la primera opción sin mostrar el diálogo. Activando Forzar Charla, el diálogo será visible.";
L["Nameplate Dialog"] = "Mostrar Diálogo en Placa de Unidades";
L["Nameplate Dialog Desc"] = "Muestra el diálogo en la Placa de Unidades del PNJ si no hay otra opción.\n\nEsta opción modifica CVar \"SoftTarget Nameplate Interact\".";

L["TTS"] = TEXT_TO_SPEECH or "Texto a voz";
L["TTS Desc"] = "Lee el diálogo en voz alta al hacer clic en el botón en la parte superior izquierda de la interfaz.\n\nVoz, volumen y velocidad utilizan la configuración de Texto a voz del juego.";
L["TTS Use Hotkey"] = "Utilizar Atajo de teclado";
L["TTS Use Hotkey Desc"] = "Inicia o para la lectura presionando:";
L["TTS Use Hotkey Tooltip PC"] = "[KEY:PC:R]";
L["TTS Use Hotkey Tooltip Xbox"] = "[KEY:XBOX:LT]";
L["TTS Use Hotkey Tooltip PlayStation"] = "[KEY:PS:LT]";
L["TTS Use Hotkey Tooltip Switch"] = "[KEY:SWITCH:LT]";
L["TTS Auto Play"] = "Inciar automáticamente";
L["TTS Auto Play Desc"] = "Iniciar automáticamente la lectura de textos de diálogo.";
L["TTS Auto Stop"] = "Parar al abandonar";
L["TTS Auto Stop Desc"] = "Para la lectura de Texto a voz cuando abandonas al PNJ.";

--Tutorial
L["Tutorial Settings Hotkey"] = "Presiona [KEY:PC:F1] para abrir la Configuración";     --Shown when interacting with an NPC with this addon for the first time
L["Tutorial Settings Hotkey Console"] = "Presiona [KEY:PC:F1] o [KEY:CONSOLE:MENU] para abrir la Configuración";   --Use this if gamepad enabled
L["Instuction Open Settings"] = "Para abrir la Configuración, presiona [KEY:PC:F1] mientras interactúas con un PNJ.";    --Used in Game Menu - AddOns
L["Instuction Open Settings Console"] = "Para abrir la Configuración, presiona [KEY:PC:F1] o [KEY:CONSOLE:MENU] mientras interactúas con un PNJ.";

--DO NOT TRANSLATE
L["Match Stat Armor"] = "([,%d%.]+) armadura";
L["Match Stat Stamina"] = "([,%d%.]+) aguante";
L["Match Stat Strengh"] = "([,%d%.]+) fuerza";
L["Match Stat Agility"] = "([,%d%.]+) agilidad";
L["Match Stat Intellect"] = "([,%d%.]+) intelecto";
L["Match Stat Spirit"] = "([,%d%.]+) espíritu";
L["Match Stat DPS"] = "([,%d%.]+) daño por segundo";