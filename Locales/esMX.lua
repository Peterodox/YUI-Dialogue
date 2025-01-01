--Contributors: HectorZaGa
if not (GetLocale() == "esMX") then return end;

local _, addon = ...
local L = addon.L;


L["Quest Frequency Daily"] = DAILY or "Diaria";
L["Quest Frequency Weekly"] = WEEKLY or "Semanal";

L["Quest Type Repeatable"] = "Repetible";
L["Quest Type Trivial"] = "Nivel bajo";    --Misión de nivel bajo
L["Quest Type Dungeon"] = LFG_TYPE_DUNGEON or "Calabozo";
L["Quest Type Raid"] = LFG_TYPE_RAID or "Banda";
L["Quest Type Covenant Calling"] = "Misiones de Pacto";

L["Accept"] = ACCEPT or "Aceptar";
L["Continue"] = CONTINUE or "Continar";
L["Complete Quest"] = COMPLETE_QUEST or "Completar misión";
L["Incomplete"] = INCOMPLETE or "Incompleto";
L["Cancel"] = CANCEL or "Cancelar";
L["Goodbye"] = GOODBYE or "Adiós";
L["Decline"] = DECLINE or "Rechazar";
L["OK"] = "OK";
L["Quest Objectives"] = OBJECTIVES_LABEL or "Objetivos";   --Usamos la forma más corta, no QUEST_OBJECTIVES
L["Reward"] = REWARD or "Recompensa";
L["Rewards"] = REWARDS or "Recompensas";
L["War Mode Bonus"] = WAR_MODE_BONUS or "Bono del Modo de guerra";
L["Honor Points"] = HONOR_POINTS or "Honor";
L["Symbol Gold"] = GOLD_AMOUNT_SYMBOL or "g";
L["Symbol Silver"] = SILVER_AMOUNT_SYMBOL or "s";
L["Symbol Copper"] = COPPER_AMOUNT_SYMBOL or "c";
L["Requirements"] = REQUIREMENTS or "Requisitos";
L["Current Colon"] = ITEM_UPGRADE_CURRENT or "Actual:";
L["Renown Level Label"] = RENOWN_LEVEL_LABEL or "Renombre ";  --Hay un espacio
L["Abilities"] = ABILITIES or "Habilidades";
L["Traits"] = GARRISON_RECRUIT_TRAITS or "Rasgos";
L["Costs"] = "Costos";   --Los costos para continuar una acción, generalmente en oro
L["Ready To Enter"] = QUEUED_STATUS_PROPOSAL or "Listo para entrar";
L["Show Comparison"] = "Mostrar comparación";   --Alternar la comparación de objetos en la descripción emergente
L["Hide Comparison"] = "Ocultar comparación";
L["Copy Text"] = "Copiar texto";
L["To Next Level Label"] = COVENANT_MISSIONS_XP_TO_LEVEL or "Hasta el siguiente nivel";
L["Quest Accepted"] = "Misión aceptada";
L["Quest Log Full"] = "El registro de misiones está lleno";
L["Quest Auto Accepted Tooltip"] = "Esta misión se acepta automáticamente por el juego.";
L["Level Maxed"] = "(Max.)";   --Se alcanzó el nivel máximo
L["Paragon Reputation"] = "Paragón";
L["Different Item Types Alert"] = "¡Los tipos de objetos son diferentes!";
L["Click To Read"] = "Clic izquierdo para leer";
L["Item Level"] = STAT_AVERAGE_ITEM_LEVEL or "Nivel de objeto";
L["Gossip Quest Option Prepend"] = "(Misión)";   --Some gossip options start with blue (Quest), we prioritize them when sorting. See GOSSIP_QUEST_OPTION_PREPEND
L["TTS Button Tooltip"] = "Clic izquierdo: Reproducir/Detener lectura.\nClic Derecho: Alternar reproducción automática";
L["Item Is An Upgrade"] = "Este objeto es una mejora para ti";
L["Identical Stats"] = "Los dos objetos tienen las mismas estadísticas";   --Dos objetos proporcionan las mismas estadísticas
L["Quest Completed On Account"] = "- ".. (ACCOUNT_COMPLETED_QUEST_NOTICE or "Tu grupo de guerra ya completó esta misión.");

--String Format
L["Format Reputation Reward Tooltip"] = QUEST_REPUTATION_REWARD_TOOLTIP or "Otorga %d de reputación con %s";
L["Format You Have X"] = "- Tienes |cffffffff%d|r";
L["Format You Have X And Y In Bank"] = "- Tienes |cffffffff%d|r (|cffffffff%d|r en tu banco)";
L["Format Suggested Players"] = QUEST_SUGGESTED_GROUP_NUM or "Jugadores sugeridos: [%d]";
L["Format Current Skill Level"] = "Current Level: |cffffffff%d/%d|r";
L["Format Reward Title"] = HONOR_REWARD_TITLE or "Título: %s";
L["Format Follower Level Class"] = FRIENDS_LEVEL_TEMPLATE or "Nivel %d %s";
L["Format Monster Say"] = CHAT_MONSTER_SAY_GET or "%s dice: ";
L["Format Quest Accepted"] = ERR_QUEST_ACCEPTED_S or "Misión aceptada: %s";
L["Format Quest Completed"] = ERR_QUEST_COMPLETE_S or "%s completado.";
L["Format Player XP"] = PET_BATTLE_CURRENT_XP_FORMAT_BOTH or  "XP: %d/%d (%d%%)";
L["Format Gold Amount"] = GOLD_AMOUNT or "%d Oro";
L["Format Silver Amount"] = SILVER_AMOUNT or "%d Plata";
L["Format Copper Amount"] = COPPER_AMOUNT or "%d Cobre";
L["Format Unit Level"] = UNIT_LEVEL_TEMPLATE or "Nivel %d";
L["Format Replace Item"] = "Reemplazar %s";
L["Format Item Level"] = "Nivel de objeto %d";   --_G.ITEM_LEVEL en Classic es diferente
L["Format Breadcrumb Quests Available"] = "Misiones de ruta disponibles: %s";    --Este tipo de misión guía al jugador a una nueva zona de misión. Ver "Breadcrumb" en https://warcraft.wiki.gg/wiki/Quest#Quest_variations
L["Format Functionality Handled By"] = "Esta funcionalidad es manejada por %s";      --Una funcionalidad es proporcionada por [nombre de otro complemento] (Usado en Settings.lua)

--Settings
L["UI"] = "UI";
L["Camera"] = "Cámara";
L["Control"] = "Control";
L["Gameplay"] = SETTING_GROUP_GAMEPLAY or "Juego";
L["Accessibility"] = SETTING_GROUP_ACCESSIBILITY or "Accesibilidad";

L["Option Enabled"] = VIDEO_OPTIONS_ENABLED or "Activado";
L["Option Disabled"] = VIDEO_OPTIONS_DISABLED or "Desactivado";
L["Move Position"] = "Mover";
L["Reset Position"] = RESET_POSITION or "Restablecer posición";
L["Drag To Move"] = "Haz clic izquierdo y arrastra para mover la ventana.";

L["Quest"] = "Misión";
L["Gossip"] = "Chisme";
L["Theme"] = "Tema";
L["Theme Desc"] = "Selecciona un tema de color para la UI.";
L["Theme Brown"] = "Marrón";
L["Theme Dark"] = "Oscuro";
L["Frame Size"] = "Tamaño del marco";
L["Frame Size Desc"] = "Establece el tamaño de la UI de diálogo.\n\nPredeterminado: Mediano";
L["Size Extra Small"] = "Extra pequeño";
L["Size Small"] = "Pequeño";
L["Size Medium"] = "Mediano";
L["Size Large"] = "Grande";
L["Font Size"] = "Tamaño de fuente";
L["Font Size Desc"] = "Establece el tamaño de la fuente para la UI.\n\nPredeterminado: 12";
L["Frame Orientation"] = "Orientación";
L["Frame Orientation Desc"] = "Coloca la interfaz a la izquierda o derecha de la pantalla";
L["Orientation Left"] = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_LEFT or "Izquierda";
L["Orientation Right"] = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_RIGHT or "Derecha";
L["Hide UI"] = "Ocultar UI";
L["Hide UI Desc"] = "Desvanece la UI del juego cuando interactúas con un NPC.";
L["Hide Unit Names"] = "Ocultar nombres de unidades";
L["Hide Unit Names Desc"] = "Oculta los nombres de jugadores y otros NPC cuando interactúas con un NPC.";
L["Show Copy Text Button"] = "Mostrar botón de Copiar texto";
L["Show Copy Text Button Desc"] = "Muestra el botón de Copiar Texto en la parte superior derecha de la UI de diálogo.";
L["Show Quest Type Text"] = "Mostrar tipo de misión";
L["Show Quest Type Text Desc"] = "Muestra el tipo de misión a la derecha de la opción si es especial.\n\nLas misiones de bajo nivel siempre están etiquetadas.";
L["Show NPC Name On Page"] = "Mostrar nombre del NPC";
L["Show NPC Name On Page Desc"] = "Muestra el nombre del NPC en la página.";
L["Show Warband Completed Quest"] = MINIMAP_TRACKING_ACCOUNT_COMPLETED_QUESTS or "Misiones completadas por la banda de guerra";
L["Show Warband Completed Quest Desc"] = "Muestra una nota en la parte inferior del detalle de la misión si ya has completado la misión actual con otro personaje.";
L["Simplify Currency Rewards"] = "Simplificar recompensas de moneda";
L["Simplify Currency Rewards Desc"] = "Usa iconos más pequeños para las recompensas de moneda y omite sus nombres.";
L["Mark Highest Sell Price"] = "Marcar precio de venta más alto";
L["Mark Highest Sell Price Desc"] = "Muestra cuál es el objeto con el precio de venta más alto cuando estás eligiendo una recompensa.";
L["Use Blizzard Tooltip"] = "Usar Tooltip de Blizzard";
L["Use Blizzard Tooltip Desc"] = "Usa el tooltip de Blizzard para el botón de recompensa de la misión en lugar de nuestro tooltip especial.";
L["Roleplaying"] = GDAPI_REALMTYPE_RP or "Juego de Rol";
L["Use RP Name In Dialogues"] = "Usar nombre de Rol en diálogos";
L["Use RP Name In Dialogues Desc"] = "Reemplaza el nombre de tu personaje en los textos de diálogo con tu nombre de rol.";

L["Camera Movement"] = "Movimiento de cámara";
L["Camera Movement Off"] = "APAGADO";
L["Camera Movement Zoom In"] = "Acercar";
L["Camera Movement Horizontal"] = "Horizontal";
L["Maintain Camera Position"] = "Mantener posición de cámara";
L["Maintain Camera Position Desc"] = "Mantiene la posición de la cámara brevemente después de que termine la interacción con un NPC.\n\nHabilitar esta opción reducirá el movimiento repentino de la cámara causado por la latencia entre los diálogos.";
L["Change FOV"] = "Cambiar FOV";
L["Change FOV Desc"] = "Reduce el campo de visión de la cámara para acercarte más al NPC.";
L["Disable Camera Movement Instance"] = "Desactivar en instancia";
L["Disable Camera Movement Instance Desc"] = "Desactiva el movimiento de la cámara mientras estás en calabozos o bandas.";
L["Maintain Offset While Mounted"] = "Mantener desplazamiento en montura";
L["Maintain Offset While Mounted Desc"] = "Intenta mantener la posición de tu personaje en la pantalla mientras estás montado.\n\nHabilitar esta opción puede compensar demasiado el desplazamiento horizontal para monturas de gran tamaño.";

L["Input Device"] = "Dispositivo de entrada";
L["Input Device Desc"] = "Afecta a los iconos de teclas de acceso rápido y el diseño de la UI.";
L["Input Device KBM"] = "Ratón y Teclado";
L["Input Device Xbox"] = "Xbox";
L["Input Device Xbox Tooltip"] = "Botón de confirmar: [KEY:XBOX:PAD1]\nBotón de cancelar: [KEY:XBOX:PAD2]";
L["Input Device PlayStation"] = "PlayStation";
L["Input Device PlayStation Tooltip"] = "Botón de confirmar: [KEY:PS:PAD1]\nBotón de cancelar: [KEY:PS:PAD2]";
L["Input Device Switch"] = "Cambiar";
L["Input Device Switch Tooltip"] = "Botón de confirmar: [KEY:SWITCH:PAD1]\nBotón de cancelar: [KEY:SWITCH:PAD2]";
L["Primary Control Key"] = "Botón de confirmar";
L["Primary Control Key Desc"] = "Presiona esta tecla para seleccionar la primera opción disponible, como Aceptar misión."
L["Press Button To Scroll Down"] = "Desplazar hacia abajo";
L["Press Button To Scroll Down Desc"] = "Si el contenido es más alto que la ventana, presionar el Botón de confirmar desplazará la página hacia abajo en lugar de aceptar la misión.";
L["Right Click To Close UI"] = "Clic Derecho para Cerrar la Interfaz";
L["Right Click To Close UI Desc"] = "Haz clic derecho en la interfaz de diálogo para cerrarla.";

L["Key Space"] = "Espacio";
L["Key Interact"] = "Interactuar";
L["Cannot Use Key Combination"] = "No se puede usar la combinación de teclas.";
L["Interact Key Not Set"] = "[KEY:PC:INVALID] No has configurado una tecla para Interactuar."
L["Use Default Control Key Alert"] = "Seguiremos usando [KEY:PC:SPACE] como el Botón de confirmar.";
L["Key Disabled"] = "Desactivado";
L["Key Disabled Tooltip"] = "El Botón de confirmar ha sido desactivado.\n\nNo podrás aceptar misiones presionando teclas.";

L["Quest Item Display"] = "Mostrar objeto de misión";
L["Quest Item Display Desc"] = "Muestra automáticamente la descripción del objeto de misión y te permite usarlo sin abrir las bolsas.";
L["Quest Item Display Hide Seen"] = "Ignorar objetos vistos";
L["Quest Item Display Hide Seen Desc"] = "Ignora los objetos que han sido descubiertos por alguno de tus personajes.";
L["Quest Item Display Reset Position Desc"] = "Restablece la posición de la ventana.";
L["Auto Select"] = "Selección automática";
L["Auto Select Gossip"] = "Opción de selección automática";
L["Auto Select Gossip Desc"] = "Selecciona automáticamente la mejor opción de diálogo al interactuar con ciertos NPC.";
L["Force Gossip"] = "Forzar chismes";
L["Force Gossip Desc"] = "Por defecto, el juego a veces selecciona automáticamente la primera opción sin mostrar el diálogo. Al habilitar Forzar chismes, el diálogo será visible.";
L["Nameplate Dialog"] = "Mostrar diálogo en Placas de nombre";
L["Nameplate Dialog Desc"] = "Muestra el diálogo en las Placas de nombre de los NPCs si no ofrecen opciones.\n\nEsta opción modifica la CVar \"SoftTarget Nameplate Interact\".";

L["TTS"] = TEXT_TO_SPEECH or "Texto a voz";
L["TTS Desc"] = "Lee en voz alta el texto de diálogo haciendo clic en el botón en la parte superior izquierda de la UI.\n\nLa voz, el volumen y la velocidad siguen la configuración de texto a voz de tu juego.";
L["TTS Use Hotkey"] = "Usar tecla de acceso rápido";
L["TTS Use Hotkey Desc"] = "Inicia o detiene la lectura al presionar:";
L["TTS Use Hotkey Tooltip PC"] = "[KEY:PC:R]";
L["TTS Use Hotkey Tooltip Xbox"] = "[KEY:XBOX:LT]";
L["TTS Use Hotkey Tooltip PlayStation"] = "[KEY:PS:LT]";
L["TTS Use Hotkey Tooltip Switch"] = "[KEY:SWITCH:LT]";
L["TTS Auto Play"] = "Reproducción automática";
L["TTS Auto Play Desc"] = "Reproduce automáticamente los textos de diálogo.";
L["TTS Auto Stop"] = "Detener al salir";
L["TTS Auto Stop Desc"] = "Detiene la lectura cuando te alejas del NPC.";

--Tutorial
L["Tutorial Settings Hotkey"] = "Presiona [KEY:PC:F1] para alternar al menú de Ajustes";
L["Tutorial Settings Hotkey Console"] = "Presiona [KEY:PC:F1] o [KEY:CONSOLE:MENU] para alternar al menú de Ajustes";   --Usa esto si el gamepad está habilitado
L["Instruction Open Settings"] = "Para abrir Ajustes, presiona [KEY:PC:F1] mientras interactúas con un NPC.";
L["Instruction Open Settings Console"] = "Para abrir Ajustes, presiona [KEY:PC:F1] o [KEY:CONSOLE:MENU] mientras interactúas con un NPC.";

--DO NOT TRANSLATE
L["Match Stat Armor"] = "([,%d%.]+) p. de armadura";
L["Match Stat Stamina"] = "([,%d%.]+) Aguante";
L["Match Stat Strengh"] = "([,%d%.]+) Fuerza";
L["Match Stat Agility"] = "([,%d%.]+) Agilidad";
L["Match Stat Intellect"] = "([,%d%.]+) Intelecto";
L["Match Stat Spirit"] = "([,%d%.]+) Espíritu";
L["Match Stat DPS"] = "([,%d%.]+) p. de daño por segundo";

L["Show Answer"] = "Mostrar solución.";
L["Quest Failed Pattern"] = "^No se pudo completar";
L["AutoCompleteQuest HallowsEnd"] = "Cubo de caramelos";     --Quest:28981

--Asking for Directions-- (match the name to replace gossip icon)
L["Pin Auction House"] = "Casa de Subastas";
L["Pin Bank"] = "Banco";
L["Pin Barber"] = "Peluquero";
L["Pin Battle Pet Trainer"] = "Instructor de mascotas de duelo";
L["Pin Crafting Orders"] = "Pedidos de fabricación";
L["Pin Flight Master"] = "Maestro de vuelo";
L["Pin Great Vault"] = "Gran bóveda";
L["Pin Inn"] = "Posada";
L["Pin Item Upgrades"] = "Mejoras de objetos";
L["Pin Mailbox"] = "Buzón";
L["Pin Other Continents"] = "Otros continentes";
L["Pin POI"] = "Puntos de interés";
L["Pin Profession Trainer"] = "Instructor de profesión";
L["Pin Rostrum"] = "Estrado de transformación";
L["Pin Stable Master"] = "Maestro de establos";
L["Pin Trading Post"] = "Puesto de venta";