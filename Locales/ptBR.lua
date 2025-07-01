--Translator: Wefin
if not (GetLocale() == "ptBR") then return end;


local _, addon = ...
local L = addon.L;

L["Quest Frequency Daily"] = DAILY or "Diária";
L["Quest Frequency Weekly"] = WEEKLY or "Semanal";

L["Quest Type Repeatable"] = "Repetível";
L["Quest Type Trivial"] = "Trivial";    --Low-level quest
L["Quest Type Dungeon"] = LFG_TYPE_DUNGEON or "Masmorra";
L["Quest Type Raid"] = LFG_TYPE_RAID or "Raide";
L["Quest Type Covenant Calling"] = "Chamado da Congregação";

L["Accept"] = ACCEPT or "Aceitar";
L["Continue"] = CONTINUE or "Continuar";
L["Complete Quest"] = COMPLETE_QUEST or "Completar Missão";
L["Incomplete"] = INCOMPLETE or "Incompleta";
L["Cancel"] = CANCEL or "Cancelar";
L["Goodbye"] = GOODBYE or "Adeus";
L["Decline"] = DECLINE or "Recusar";
L["OK"] = "OK";
L["Quest Objectives"] = OBJECTIVES_LABEL or "Objetivos";   --We use the shorter one, not QUEST_OBJECTIVES
L["Reward"] = REWARD or "Recompensa";
L["Rewards"] = REWARDS or "Recompensas";
L["War Mode Bonus"] = WAR_MODE_BONUS or "Bônus do Modo Guerra";
L["Honor Points"] = HONOR_POINTS or "Honra";
L["Symbol Gold"] = GOLD_AMOUNT_SYMBOL or "o";
L["Symbol Silver"] = SILVER_AMOUNT_SYMBOL or "p";
L["Symbol Copper"] = COPPER_AMOUNT_SYMBOL or "c";
L["Requirements"] = REQUIREMENTS or "Requisitos";
L["Current Colon"] = ITEM_UPGRADE_CURRENT or "Atual:";
L["Renown Level Label"] = "Renome ";  --There is a space
L["Abilities"] = ABILITIES or "Habilidades";
L["Traits"] = GARRISON_RECRUIT_TRAITS or "Características";
L["Costs"] = "Custos";   --The costs to continue an action, usually gold
L["Ready To Enter"] = QUEUED_STATUS_PROPOSAL or "Pronto para Entrar";
L["Show Comparison"] = "Mostrar Comparação";   --Toggle item comparison on the tooltip
L["Hide Comparison"] = "Esconder Comparação";
L["Copy Text"] = "Copiar Texto";
L["To Next Level Label"] = COVENANT_MISSIONS_XP_TO_LEVEL or "Para o próximo nível";
L["Quest Accepted"] = "Missão Aceita";
L["Quest Log Full"] = "Registro de Missões Cheio";
L["Quest Auto Accepted Tooltip"] = "Esta missão é aceita automaticamente pelo jogo.";
L["Level Maxed"] = "(Máximo)";   --Reached max level
L["Paragon Reputation"] = "Paragão";
L["Different Item Types Alert"] = "Os tipos de itens são diferentes!";
L["Click To Read"] = "Clique com o Botão Esquerdo para Ler";
L["Item Level"] = STAT_AVERAGE_ITEM_LEVEL or "Nível de Item";
L["Gossip Quest Option Prepend"] = "(Missão)";   --Some gossip options start with blue (Quest), we prioritize them when sorting. See GOSSIP_QUEST_OPTION_PREPEND
L["TTS Button Tooltip"] = "Clique com o Botão Esquerdo: Reproduzir/Parar Leitura.\nClique com o Botão Direito: Alternar Reprodução Automática";
L["Item Is An Upgrade"] = "Este item é uma melhoria para você";
L["Identical Stats"] = "Os dois itens têm as mesmas estatísticas";   --Two items provide the same stats
L["Quest Completed On Account"] = (ACCOUNT_COMPLETED_QUEST_NOTICE or "Seu Grupo de Guerra já completou esta missão anteriormente.");

--String Format
L["Format Reputation Reward Tooltip"] = QUEST_REPUTATION_REWARD_TOOLTIP or "Concede %d de reputação com %s";
L["Format You Have X"] = "- Você tem |cffffffff%s|r";
L["Format You Have X And Y In Bank"] = "- Você tem |cffffffff%s|r (|cffffffff%s|r no banco)";
L["Format Suggested Players"] = QUEST_SUGGESTED_GROUP_NUM or "Jogadores Sugeridos [%d]";
L["Format Current Skill Level"] = "Nível Atual: |cffffffff%d/%d|r";
L["Format Reward Title"] = HONOR_REWARD_TITLE or "Título: %s";
L["Format Follower Level Class"] = FRIENDS_LEVEL_TEMPLATE or "Nível %d %s";
L["Format Monster Say"] = CHAT_MONSTER_SAY_GET or "%s diz: ";
L["Format Quest Accepted"] = ERR_QUEST_ACCEPTED_S or "Missão aceita: %s";
L["Format Quest Completed"] = ERR_QUEST_COMPLETE_S or "%s concluída.";
L["Format Player XP"] = PET_BATTLE_CURRENT_XP_FORMAT_BOTH or  "XP: %d/%d (%d%%)";
L["Format Gold Amount"] = GOLD_AMOUNT or "%d Ouro";
L["Format Silver Amount"] = SILVER_AMOUNT or "%d Prata";
L["Format Copper Amount"] = COPPER_AMOUNT or "%d Cobre";
L["Format Unit Level"] = UNIT_LEVEL_TEMPLATE or "Nível %d";
L["Format Replace Item"] = "Substituir %s";
L["Format Item Level"] = "Nível de Item %d";   --_G.ITEM_LEVEL in Classic is different
L["Format Breadcrumb Quests Available"] = "Missões de Trilhas Disponíveis: %s";    --This type of quest guide the player to a new quest zone. See "Breadcrumb" on https://warcraft.wiki.gg/wiki/Quest#Quest_variations
L["Format Functionality Handled By"] = "Esta funcionalidade é gerenciada por %s";      --A functionality is provided by [another addon name] (Used in Settings.lua)

--Settings
L["UI"] = "Interface";
L["Camera"] = "Câmera";
L["Control"] = "Controle";
L["Gameplay"] = SETTING_GROUP_GAMEPLAY or "Jogabilidade";
L["Accessibility"] = SETTING_GROUP_ACCESSIBILITY or "Acessibilidade";

L["Option Enabled"] = VIDEO_OPTIONS_ENABLED or "Habilitado";
L["Option Disabled"] = VIDEO_OPTIONS_DISABLED or "Desabilitado";
L["Move Position"] = "Mover";
L["Reset Position"] = RESET_POSITION or "Redefinir Posição";
L["Drag To Move"] = "Clique com o botão esquerdo e arraste para mover a janela.";

L["Quest"] = "Missão";
L["Gossip"] = "Gossip";
L["Theme"] = "Tema";
L["Theme Desc"] = "Selecione um tema de cor para a interface.";
L["Theme Brown"] = "Marrom";
L["Theme Dark"] = "Escuro";
L["Frame Size"] = "Tamanho da Janela";
L["Frame Size Desc"] = "Defina o tamanho da interface de diálogo.\n\nPadrão: Médio";
L["Size Extra Small"] = "Extra Pequeno";
L["Size Small"] = "Pequeno";
L["Size Medium"] = "Médio";
L["Size Large"] = "Grande";
L["Font Size"] = "Tamanho da Fonte";
L["Font Size Desc"] = "Defina o tamanho da fonte para a interface.\n\nPadrão: 12";
L["Frame Orientation"] = "Orientação";
L["Frame Orientation Desc"] = "Coloque a interface no lado esquerdo ou direito da tela";
L["Orientation Left"] = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_LEFT or "Esquerda";
L["Orientation Right"] = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_RIGHT or "Direita";
L["Hide UI"] = "Esconder Interface";
L["Hide UI Desc"] = "Esmaecer a interface do jogo quando você interagir com um NPC.";
L["Hide Unit Names"] = "Esconder Nomes das Unidades";
L["Hide Unit Names Desc"] = "Esconder os nomes dos jogadores e outros NPCs quando você interagir com um NPC.";
L["Show Copy Text Button"] = "Mostrar Botão de Copiar Texto";
L["Show Copy Text Button Desc"] = "Mostrar o botão Copiar Texto no canto superior direito da interface de diálogo.\n\nIsso também inclui dados do jogo como IDs de missões, NPCs, itens.";
L["Show Quest Type Text"] = "Mostrar Texto do Tipo de Missão";
L["Show Quest Type Text Desc"] = "Mostrar o tipo de missão à direita da opção se for especial.\n\nMissões de baixo nível sempre são rotuladas.";
L["Show NPC Name On Page"] = "Mostrar Nome do NPC";
L["Show NPC Name On Page Desc"] = "Mostrar o nome do NPC na página.";
L["Show Warband Completed Quest"] = MINIMAP_TRACKING_ACCOUNT_COMPLETED_QUESTS or "Missões Completas pelo Grupo de Guerra";
L["Show Warband Completed Quest Desc"] = "Mostrar uma nota no final do detalhe da missão se você já completou a missão atual em outro personagem.";
L["Simplify Currency Rewards"] = "Simplificar Recompensas em Moeda";
L["Simplify Currency Rewards Desc"] = "Use ícones menores para recompensas em moeda e omita seus nomes.";
L["Mark Highest Sell Price"] = "Marcar Maior Preço de Venda";
L["Mark Highest Sell Price Desc"] = "Mostra qual item tem o maior preço de venda ao escolher uma recompensa.";
L["Use Blizzard Tooltip"] = "Usar Dica de Ferramenta da Blizzard";
L["Use Blizzard Tooltip Desc"] = "Usa a dica de ferramenta da Blizzard para o botão de recompensa de missão em vez da nossa dica de ferramenta especial.";
L["Roleplaying"] = GDAPI_REALMTYPE_RP or "Interpretação";
L["Use RP Name In Dialogues"] = "Usar Nome RP em Diálogos";
L["Use RP Name In Dialogues Desc"] = "Substitui o nome do seu personagem nos textos de diálogo pelo seu nome RP.";

L["Camera Movement"] = "Movimento da Câmera";
L["Camera Movement Off"] = "DESLIGADO";
L["Camera Movement Zoom In"] = "Aproximar";
L["Camera Movement Horizontal"] = "Horizontal";
L["Maintain Camera Position"] = "Manter Posição da Câmera";
L["Maintain Camera Position Desc"] = "Mantém a posição da câmera brevemente após o término da interação com o NPC.\n\nHabilitar esta opção reduzirá o movimento brusco da câmera causado pela latência entre diálogos.";
L["Change FOV"] = "Alterar FOV";
L["Change FOV Desc"] = "Reduz o campo de visão da câmera para aproximar-se mais do NPC.";
L["Disable Camera Movement Instance"] = "Desativar em Instância";
L["Disable Camera Movement Instance Desc"] = "Desativa o movimento da câmera enquanto estiver em masmorra ou raide.";
L["Maintain Offset While Mounted"] = "Manter Offset Montado";
L["Maintain Offset While Mounted Desc"] = "Tenta manter a posição do seu personagem na tela enquanto montado.\n\nHabilitar esta opção pode supercompensar o offset horizontal para montarias de grande porte.";

L["Input Device"] = "Dispositivo de Entrada";
L["Input Device Desc"] = "Afeta ícones de teclas de atalho e layout da interface.";
L["Input Device KBM"] = "Teclado e Mouse";
L["Input Device Xbox"] = "Xbox";
L["Input Device Xbox Tooltip"] = "Botão de Confirmar: [KEY:XBOX:PAD1]\nBotão de Cancelar: [KEY:XBOX:PAD2]";
L["Input Device PlayStation"] = "PlayStation";
L["Input Device PlayStation Tooltip"] = "Botão de Confirmar: [KEY:PS:PAD1]\nBotão de Cancelar: [KEY:PS:PAD2]";
L["Input Device Switch"] = "Switch";
L["Input Device Switch Tooltip"] = "Botão de Confirmar: [KEY:SWITCH:PAD1]\nBotão de Cancelar: [KEY:SWITCH:PAD2]";
L["Primary Control Key"] = "Botão de Confirmar";
L["Primary Control Key Desc"] = "Pressione esta tecla para selecionar a primeira opção disponível, como Aceitar Missão.";
L["Press Button To Scroll Down"] = "Pressionar Botão para Rolar para Baixo";
L["Press Button To Scroll Down Desc"] = "Se o conteúdo for maior que a área de visualização, pressionar o Botão de Confirmar fará a página rolar para baixo em vez de aceitar a missão.";
L["Right Click To Close UI"] = "Clique com o Direito para Fechar UI";
L["Right Click To Close UI Desc"] = "Clique com o botão direito na interface de diálogo para fechá-la.";

L["Key Space"] = "Espaço";
L["Key Interact"] = "Interagir";
L["Cannot Use Key Combination"] = "Combinação de teclas não suportada.";
L["Interact Key Not Set"] = "[KEY:PC:INVALID] Você não configurou uma tecla de Interagir.";
L["Use Default Control Key Alert"] = "Ainda usaremos [KEY:PC:SPACE] como o Botão de Confirmar.";
L["Key Disabled"] = "Desativado";
L["Key Disabled Tooltip"] = "Botão de Confirmar foi desativado.\n\nVocê não poderá aceitar missões pressionando teclas.";

L["Quest Item Display"] = "Exibição de Itens de Missão";
L["Quest Item Display Desc"] = "Exibe automaticamente a descrição do item de missão e permite que você o use sem abrir as bolsas.";
L["Quest Item Display Hide Seen"] = "Ignorar Itens Vistos";
L["Quest Item Display Hide Seen Desc"] = "Ignora itens que já foram descobertos por qualquer um de seus personagens.";
L["Quest Item Display Await World Map"] = "Aguardar Mapa-múndi";
L["Quest Item Display Await World Map Desc"] = "Quando você abrir o Mapa-múndi, ocultar temporariamente a Exibição de Itens de Missão e pausar o temporizador de fechamento automático.";
L["Quest Item Display Reset Position Desc"] = "Redefinir a posição da janela.";
L["Auto Select"] = "Selecionar Automaticamente";
L["Auto Select Gossip"] = "Selecionar Opção Automaticamente";
L["Auto Select Gossip Desc"] = "Seleciona automaticamente a melhor opção de diálogo ao interagir com certos NPCs.";
L["Force Gossip"] = "Forçar Diálogo";
L["Force Gossip Desc"] = "Por padrão, o jogo às vezes seleciona automaticamente a primeira opção sem mostrar o diálogo. Habilitar Forçar Diálogo fará o diálogo se tornar visível.";
L["Nameplate Dialog"] = "Exibir Diálogo na Placa de Nome";
L["Nameplate Dialog Desc"] = "Exibe o diálogo na placa de nome do NPC se ele não oferecer escolha.\n\nEsta opção modifica o CVar \"SoftTarget Nameplate Interact\".";

L["TTS"] = TEXT_TO_SPEECH or "Texto para Fala";
L["TTS Desc"] = "Leia o texto do diálogo em voz alta clicando no botão no canto superior esquerdo da interface.";
L["TTS Use Hotkey"] = "Usar Tecla de Atalho";
L["TTS Use Hotkey Desc"] = "Inicie ou pare a leitura pressionando:";
L["TTS Use Hotkey Tooltip PC"] = "[KEY:PC:R]";
L["TTS Use Hotkey Tooltip Xbox"] = "[KEY:XBOX:LT]";
L["TTS Use Hotkey Tooltip PlayStation"] = "[KEY:PS:LT]";
L["TTS Use Hotkey Tooltip Switch"] = "[KEY:SWITCH:LT]";
L["TTS Auto Play"] = "Reprodução Automática";
L["TTS Auto Play Desc"] = "Reproduz automaticamente os textos do diálogo.";
L["TTS Auto Stop"] = "Parar ao Sair";
L["TTS Auto Stop Desc"] = "Para de ler quando você sai do NPC.";
L["TTS Voice Male"] = "Voz Masculina";
L["TTS Voice Male Desc"] = "Usa esta voz ao interagir com um personagem masculino:";
L["TTS Voice Female"] = "Voz Feminina";
L["TTS Voice Female Desc"] = "Usa esta voz ao interagir com um personagem feminino:";
L["TTS Volume"] = VOLUME or "Volume";
L["TTS Volume Desc"] = "Ajusta o volume da fala.";
L["TTS Rate"] = "Velocidade da Fala";
L["TTS Rate Desc"] = "Ajusta a velocidade da fala.";
L["TTS Include Content"] = "Incluir Conteúdo";
L["TTS Content NPC Name"] = "Nome do NPC";
L["TTS Content Quest Name"] = "Título da Missão";

--Tutorial
L["Tutorial Settings Hotkey"] = "Pressione [KEY:PC:F1] para alternar Configurações";     --Shown when interacting with an NPC with this addon for the first time
L["Tutorial Settings Hotkey Console"] = "Pressione [KEY:PC:F1] ou [KEY:CONSOLE:MENU] para alternar Configurações";   --Use this if gamepad enabled
L["Instruction Open Settings"] = "Para abrir Configurações, pressione [KEY:PC:F1] enquanto estiver interagindo com um NPC.";    --Used in Game Menu - AddOns
L["Instruction Open Settings Console"] = "Para abrir Configurações, pressione [KEY:PC:F1] ou [KEY:CONSOLE:MENU] enquanto estiver interagindo com um NPC.";

--DO NOT TRANSLATE
L["Abbrev Breakpoint 1000"] = FIRST_NUMBER_CAP_NO_SPACE or "K";     --1,000 = 1K
L["Abbrev Breakpoint 10000"] = FIRST_NUMBER_CAP_NO_SPACE or "K";    --Reserved for Asian languages that have words for 10,000
L["Match Stat Armor"] = "([,%d%.]+) de Armadura";
L["Match Stat Stamina"] = "([,%d%.]+) Vigor";
L["Match Stat Strengh"] = "([,%d%.]+) Força";
L["Match Stat Agility"] = "([,%d%.]+) Agilidade";
L["Match Stat Intellect"] = "([,%d%.]+) Intelecto";
L["Match Stat Spirit"] = "([,%d%.]+) Espírito";
L["Match Stat DPS"] = "([,%d%.]+) de dano por segundo";

L["Show Answer"] = "Mostrar solução.";
L["Quest Failed Pattern"] = "^A entrega de";
L["AutoCompleteQuest HallowsEnd"] = "Balde de Doces";     --Quest:28981
L["AutoCompleteQuest Midsummer"] = "Reverencie a chama";   --Quest:29031
L["AutoCompleteQuest Midsummer2"] = "Profane o fogo!";     --Quest:11580

--Asking for Directions-- (match the name to replace gossip icon)
L["Pin Auction House"] = "Casa de Leilões";
L["Pin Bank"] = "Banco";
L["Pin Barber"] = "Barbeiro";
L["Pin Battle Pet Trainer"] = "Adestramento de Batalha";
L["Pin Crafting Orders"] = "Pedidos de criação";
L["Pin Flight Master"] = "Mestre de Voo";
L["Pin Great Vault"] = "Grande Cofre";
L["Pin Inn"] = "Estalagem";
L["Pin Item Upgrades"] = "Aprimoramento de Itens";
L["Pin Mailbox"] = "Caixa de Correio";
L["Pin Other Continents"] = "Outros continentes";
L["Pin POI"] = "Pontos de Interesse";
L["Pin Profession Trainer"] = "Instrutores de Profissão";
L["Pin Rostrum"] = "Tribuna de Transformação";
L["Pin Stable Master"] = "Mestre de Estábulo";
L["Pin Trading Post"] = "Posto Comercial";
L["Pin Transmogrifier"] = "Transmogrificador";