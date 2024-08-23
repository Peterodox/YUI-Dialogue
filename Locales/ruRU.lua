--Contributors: Voopie
if not (GetLocale() == "ruRU") then return end;

local _, addon = ...
local L = addon.L;


L["Quest Frequency Daily"] = "Ежедневное";
L["Quest Frequency Weekly"] = "Еженедельное";

L["Quest Type Repeatable"] = "Повторяемое";
L["Quest Type Trivial"] = "Простое";    --Low-level quest
L["Quest Type Dungeon"] = "Подземелье";
L["Quest Type Raid"] = "Рейд";
L["Quest Type Covenant Calling"] = "Призыв ковенанта";

L["Accept"] = "Принять";
L["Continue"] = "Продолжить";
L["Complete Quest"] = "Завершить";
L["Incomplete"] = "Не завершено";
L["Cancel"] = "Отмена";
L["Goodbye"] = "До встречи";
L["Decline"] = "Отказаться";
L["OK"] = "OK";
L["Quest Objectives"] = "Задачи";   --We use the shorter one, not QUEST_OBJECTIVES
L["Reward"] = "Награда";
L["Rewards"] = "Награды";
L["War Mode Bonus"] = "Бонус режима войны";
L["Honor Points"] = "Честь";
L["Symbol Gold"] = "з";
L["Symbol Silver"] = "с";
L["Symbol Copper"] = "м";
L["Requirements"] = "Требования";
L["Current Colon"] = "Текущий уровень:";
L["Renown Level Label"] = "Известность ";  --There is a space
L["Abilities"] = "Способности";
L["Traits"] = "Особенности";
L["Costs"] = "Стоимость";   --The costs to continue an action, usually gold
L["Ready To Enter"] = "Можно войти";
L["Show Comparison"] = "Показать сравнение";   --Toggle item comparison on the tooltip
L["Hide Comparison"] = "Скрыть сравнение";
L["Copy Text"] = "Скопировать текст";
L["To Next Level Label"] = "Следующий уровень";
L["Quest Accepted"] = "Задание принято";
L["Quest Log Full"] = "Журнал заданий заполнен";
L["Quest Auto Accepted Tooltip"] = "Это задание автоматически принимается игрой.";
L["Level Maxed"] = "(Макс.)";   --Reached max level
L["Paragon Reputation"] = "Совершенствование";
L["Different Item Types Alert"] = "Типы предметов отличаются!";
L["Click To Read"] = "Щелкните левой кнопкой мыши, чтобы прочитать";
L["Item Level"] = "Уровень предмета";
L["Gossip Quest Option Prepend"] = "(Задание)";   --Some gossip options start with blue (Quest), we prioritize them when sorting. See GOSSIP_QUEST_OPTION_PREPEND
L["TTS Button Tooltip"] = "Левый клик: Начать или прекратить озвучивание.\nПравый клик: Переключение автоматического озвучивания";
L["Item Is An Upgrade"] = "Этот предмет является улучшением для вас";
L["Identical Stats"] = "Эти два предмета имеют одинаковые характеристики";
L["Quest Completed On Account"] = "Ваш отряд уже выполнял это задание.";

--String Format
L["Format Reputation Reward Tooltip"] = "Улучшает отношение фракции %2$s на %1$d";
L["Format You Have X"] = "- Имеется |cffffffff%d|r";
L["Format You Have X And Y In Bank"] = "- Имеется |cffffffff%d|r (|cffffffff%d|r в банке)";
L["Format Suggested Players"] = "Рекомендуется %d |4игрок:игрока:игроков;.";
L["Format Current Skill Level"] = "Текущий уровень: |cffffffff%d/%d|r";
L["Format Reward Title"] = "Звание: %s";
L["Format Follower Level Class"] = "Уровень %d %s";
L["Format Monster Say"] = "%s говорит: ";
L["Format Quest Accepted"] = "Вы получили задание \"%s\".";
L["Format Quest Completed"] = "Задание \"%s\" выполнено.";
L["Format Player XP"] = "Опыт: %d/%d (%d%%)";
L["Format Gold Amount"] = "%d |4золотая:золотые:золотых;";
L["Format Silver Amount"] = "%d |4серебряная:серебряные:серебряных;";
L["Format Copper Amount"] = "%d |4медная монета:медные монеты:медных монет;";
L["Format Unit Level"] = "%d-й уровень";
L["Format Replace Item"] = "Заменить %s";
L["Format Item Level"] = "Уровень предмета %d"; --_G.ITEM_LEVEL in Classic is different
L["Format Breadcrumb Quests Available"] = "Доступные направляющие задания: %s"; --This type of quest guide the player to a new quest zone. See "Breadcrumb" on https://warcraft.wiki.gg/wiki/Quest#Quest_variations
L["Format Functionality Handled By"] = "За эту функциональность отвечает %s"; --A functionality is provided by [another addon name] (Used in Settings.lua)

--Settings
L["UI"] = "Интерфейс";
L["Camera"] = "Камера";
L["Control"] = "Управление";
L["Gameplay"] = "Игровой процесс";
L["Accessibility"] = "Спец. возможности";

L["Option Enabled"] = "Включено";
L["Option Disabled"] = "Отключено";
L["Move Position"] = "Перетащить";
L["Reset Position"] = "Вернуть позицию по умолчанию";
L["Drag To Move"] = "Зажмите ЛКМ и тащите курсор, чтобы переместить окно.";

L["Quest"] = "Задание";
L["Gossip"] = "Разговор";
L["Theme"] = "Тема";
L["Theme Desc"] = "Выберите цветовую тему интерфейса.";
L["Theme Brown"] = "Коричневая";
L["Theme Dark"] = "Тёмная";
L["Frame Size"] = "Размер окна";
L["Frame Size Desc"] = "Выберите размер диалогового окна.\n\nПо умолчанию: Средний";
L["Size Extra Small"] = "Очень малый";
L["Size Small"] = "Малый";
L["Size Medium"] = "Средний";
L["Size Large"] = "Большой";
L["Font Size"] = "Размер шрифта";
L["Font Size Desc"] = "Выберите размер шрифта.\n\nПо умолчанию: 12";
L["Frame Orientation"] = "Расположение";
L["Frame Orientation Desc"] = "Расположение интерфейса в левой или правой части экрана";
L["Orientation Left"] = "Влево";
L["Orientation Right"] = "Вправо";
L["Hide UI"] = "Скрыть интерфейс";
L["Hide UI Desc"] = "Скрыть интерфейс игры, когда вы взаимодействуете с NPC.";
L["Hide Unit Names"] = "Скрыть имена";
L["Hide Unit Names Desc"] = "Скрывать имена игроков и других NPC, когда вы взаимодействуете с NPC.";
L["Show Copy Text Button"] = "Показать кнопку копирования текста";
L["Show Copy Text Button Desc"] = "Показывать кнопку копирования текста в правом верхнем углу диалогового окна.\n\nТакже включает в себя игровые данные, такие как идентификаторы квеста, NPC, предмета.";
L["Show Quest Type Text"] = "Показать тип задания";
L["Show Quest Type Text Desc"] = "Показывать тип задания справа от него.\n\nПростые задания всегда помечены.";
L["Show NPC Name On Page"] = "Показать имя NPC";
L["Show NPC Name On Page Desc"] = "Показывать имя NPC в диалоговом окне.";
L["Show Warband Completed Quest"] = "Задания, выполненные отрядом";
L["Show Warband Completed Quest Desc"] = "Показывать примечание внизу описания задания, если вы ранее выполняли текущее задание на другом персонаже.";
L["Simplify Currency Rewards"] = "Упрощение наград в виде валют";
L["Simplify Currency Rewards Desc"] = "Использовать значки меньшего размера для обозначения наград в виде валют и убрать их названия.";
L["Mark Highest Sell Price"] = "Метка самой высокой цены продажи";
L["Mark Highest Sell Price Desc"] = "Покажет вам, какой товар имеет самую высокую цену продажи, когда вы выбираете награду.";
L["Use Blizzard Tooltip"] = "Подсказка Blizzard";
L["Use Blizzard Tooltip Desc"] = "Использовать подсказку Blizzard для награды за выполнение задания вместо нашей специальной подсказки.";
L["Roleplaying"] = "Ролевая игра";
L["Use RP Name In Dialogues"] = "Использовать ролевое имя в диалогах";
L["Use RP Name In Dialogues Desc"] = "Заменить имя персонажа в диалогах на свое ролевое имя.";

L["Camera Movement"] = "Движение камеры";
L["Camera Movement Off"] = "ВЫКЛ";
L["Camera Movement Zoom In"] = "Приближение";
L["Camera Movement Horizontal"] = "Горизонтальное";
L["Maintain Camera Position"] = "Сохранять положение камеры";
L["Maintain Camera Position Desc"] = "Сохранять положение камеры на короткое время после окончания взаимодействия с NPC.\n\nВключение этой опции уменьшит резкое движение камеры, вызванное задержкой между диалогами.";
L["Change FOV"] = "Изменить поле зрения";
L["Change FOV Desc"] = "Уменьшить поле зрения камеры, чтобы приблизить изображение к NPC.";
L["Disable Camera Movement Instance"] = "Отключить в подземельях";
L["Disable Camera Movement Instance Desc"] = "Отключить движение камеры во время нахождения в подземелье или рейде.";
L["Maintain Offset While Mounted"] = "Сохранять смещение на средстве передвижения";
L["Maintain Offset While Mounted Desc"] = "Стараться сохранять положение персонажа, когда вы находитесь на средстве передвижения.\n\nВключение этой опции может привести к чрезмерной компенсации горизонтального смещения для больших средств передвижения.";

L["Input Device"] = "Устройство ввода";
L["Input Device Desc"] = "Влияет на значки горячих клавиш и макет интерфейса.";
L["Input Device KBM"] = "Клавиатура и мышь";
L["Input Device Xbox"] = "Xbox";
L["Input Device Xbox Tooltip"] = "Клавиша подтверждения: [KEY:XBOX:PAD1]\nКлавиша отмены: [KEY:XBOX:PAD2]";
L["Input Device PlayStation"] = "PlayStation";
L["Input Device PlayStation Tooltip"] = "Клавиша подтверждения: [KEY:PS:PAD1]\nКлавиша отмены: [KEY:PS:PAD2]";
L["Input Device Switch"] = "Switch";
L["Input Device Switch Tooltip"] = "Клавиша подтверждения: [KEY:SWITCH:PAD1]\nКлавиша отмены: [KEY:SWITCH:PAD2]";
L["Primary Control Key"] = "Клавиша подтверждения";
L["Primary Control Key Desc"] = "Нажмите эту клавишу, чтобы выбрать первый доступный вариант, например, принять задание."
L["Press Button To Scroll Down"] = "Нажатие клавиши для прокрутки вниз";
L["Press Button To Scroll Down Desc"] = "Если содержимое превышает высоту окна, нажатие клавиши подтверждения приведет к прокрутке страницы вниз вместо принятия задания.";
L["Right Click To Close UI"] = "ПКМ для закрытия";
L["Right Click To Close UI Desc"] = "Щелкните правой кнопкой мыши по диалоговому окну, чтобы закрыть его.";

L["Key Space"] = "Пробел";
L["Key Interact"] = "Взаимодействие";
L["Cannot Use Key Combination"] = "Комбинация клавиш не поддерживается.";
L["Interact Key Not Set"] = "[KEY:PC:INVALID] Вы не установили клавишу взаимодействия.";
L["Use Default Control Key Alert"] = "По-прежнему будет использоваться [KEY:PC:SPACE] в качестве клавиши подтверждения.";
L["Key Disabled"] = "Отключено";
L["Key Disabled Tooltip"] = "Клавиша подтверждения была отключена.\n\nВы не сможете принять задание нажатием клавиш.";

L["Quest Item Display"] = "Отображение предмета для задания";
L["Quest Item Display Desc"] = "Автоматическое отображение описания предмета для задания и возможность использовать его, не открывая сумки.";
L["Quest Item Display Hide Seen"] = "Игнорировать просмотренные предметы";
L["Quest Item Display Hide Seen Desc"] = "Игнорировать предметы, которые были обнаружены кем-либо из ваших персонажей.";
L["Quest Item Display Await World Map"] = " Ожидание Карты мира";
L["Quest Item Display Await World Map Desc"] = "При открытии Карты мира временно скрывать \"Описания предмета для задания\" и ставить на паузу таймер его авто-скрытия.";
L["Quest Item Display Reset Position Desc"] = "Сбросить положение окна.";
L["Auto Select"] = "Автовыбор";
L["Auto Select Gossip"] = "Автовыбор варианта";
L["Auto Select Gossip Desc"] = "Автоматически выбирать наилучший вариант диалога при взаимодействии с определенным NPC.";
L["Force Gossip"] = "Принудительный разговор";
L["Force Gossip Desc"] = "По умолчанию игра иногда автоматически выбирает первый вариант, не показывая диалоговое окно. Если включить принудительный просмотр разговора, диалоговое окно станет видимым.";
L["Nameplate Dialog"] = "Отображать диалог на неймплейте";
L["Nameplate Dialog Desc"] = "Отображать диалог на неймплейте NPC, если они не предлагают выбора.\n\nЭтот параметр изменяет CVar \"SoftTarget Nameplate Interact\".";

L["TTS"] = "Текст в речь";
L["TTS Desc"] = "Озвучивать текст диалога, нажав на кнопку в левом верхнем углу.";
L["TTS Use Hotkey"] = "Использовать горячую клавишу";
L["TTS Use Hotkey Desc"] = "Начать или прекратить озвучивание текста, нажав эту клавишу:";
L["TTS Use Hotkey Tooltip PC"] = "[KEY:PC:R]";
L["TTS Use Hotkey Tooltip Xbox"] = "[KEY:XBOX:LT]";
L["TTS Use Hotkey Tooltip PlayStation"] = "[KEY:PS:LT]";
L["TTS Use Hotkey Tooltip Switch"] = "[KEY:SWITCH:LT]";
L["TTS Auto Play"] = "Автоозвучивание";
L["TTS Auto Play Desc"] = "Автоматическое озвучивание текстов диалогов.";
L["TTS Auto Stop"] = "Прекращение при отдалении";
L["TTS Auto Stop Desc"] = "Прекратить озвучивание, когда отходите от NPC.";
L["TTS Voice Male"] = "Мужской голос";
L["TTS Voice Male Desc"] = "Использовать этот голос, когда общаетесь с персонажем мужского пола:";
L["TTS Voice Female"] = "Женский голос";
L["TTS Voice Female Desc"] = "Использовать этот голос, когда общаетесь с персонажем женского пола:";
L["TTS Volume"] = "Громкость";
L["TTS Volume Desc"] = "Регулировка громкости речи.";
L["TTS Rate"] = "Темп речи";
L["TTS Rate Desc"] = "Регулировка темпа речи";
L["TTS Include Content"] = "Включать содержимое";
L["TTS Content NPC Name"] = "Имя NPC";
L["TTS Content Quest Name"] = "Название задания";

--Tutorial
L["Tutorial Settings Hotkey"] = "Нажмите [KEY:PC:F1] для открытия настроек";   --Shown when interacting with an NPC with this addon for the first time
L["Tutorial Settings Hotkey Console"] = "Нажмите [KEY:PC:F1] или [KEY:CONSOLE:MENU] для открытия настроек";   --Use this if gamepad enabled
L["Instuction Open Settings"] = "Чтобы открыть настройки, нажмите [KEY:PC:F1] во время взаимодействия с NPC.";    --Used in Game Menu - AddOns
L["Instuction Open Settings Console"] = "Чтобы открыть настройки, нажмите [KEY:PC:F1] или [KEY:CONSOLE:MENU] во время взаимодействия с NPC.";

--DO NOT TRANSLATE
L["Abbrev Breakpoint 1000"] = "Т";     --1,000 = 1K
L["Abbrev Breakpoint 10000"] = "Т";    --Reserved for Asian languages that have words for 10,000
L["Match Stat Armor"] = "Броня: ([,%d%.]+)";
L["Match Stat Stamina"] = "([,%d%.]+) к выносливости";
L["Match Stat Strengh"] = "([,%d%.]+) к силе";
L["Match Stat Agility"] = "([,%d%.]+) к ловкости";
L["Match Stat Intellect"] = "([,%d%.]+) к интеллекту";
L["Match Stat Spirit"] = "([,%d%.]+) к духу";
L["Match Stat DPS"] = "([,%d%.]+) ед. урона в секунду";
