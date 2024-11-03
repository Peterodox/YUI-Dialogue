
if not (GetLocale() == "zhTW") then return end;


local _, addon = ...
local L = addon.L;


--DO NOT TRANSLATE
L["Abbrev Breakpoint 1000"] = "千";     --1,000 = 1K
L["Abbrev Breakpoint 10000"] = "萬";    --Reserved for Asian languages that have words for 10,000
L["Match Stat Armor"] = "([,%d%.]+)點護甲";
L["Match Stat Stamina"] = "([,%d%.]+)耐力";     --No Space!
L["Match Stat Strengh"] = "([,%d%.]+)力量";
L["Match Stat Agility"] = "([,%d%.]+)敏捷";
L["Match Stat Intellect"] = "([,%d%.]+)智力";
L["Match Stat Spirit"] = "([,%d%.]+)精神";
L["Match Stat DPS"] = "每秒傷害([,%d%.]+)";

L["Show Answer"] = "顯示正確答案。";
L["Quest Failed Pattern"] = "才能完成此任務。$";
L["AutoCompleteQuest HallowsEnd"] = "糖果桶";     --Quest:28981

--Asking for Directions-- (match the name to replace gossip icon)
L["Pin Auction House"] = "拍賣場";
L["Pin Bank"] = "銀行";
L["Pin Barber"] = "美容師";
L["Pin Battle Pet Trainer"] = "戰寵訓練師";
L["Pin Crafting Orders"] = "製作訂單";
L["Pin Flight Master"] = "飛行管理員";
L["Pin Great Vault"] = "寶庫";
L["Pin Inn"] = "旅店";
L["Pin Item Upgrades"] = "物品升級";
L["Pin Mailbox"] = "郵箱";
L["Pin Other Continents"] = "其他大陸";
L["Pin POI"] = "地標";
L["Pin Profession Trainer"] = "專業技能訓練師";
L["Pin Rostrum"] = "外形調整台";
L["Pin Stable Master"] = "獸欄管理員";
L["Pin Trading Post"] = "貿易站";