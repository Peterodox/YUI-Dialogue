
if not (GetLocale() == "koKR") then return end;


local _, addon = ...
local L = addon.L;


--DO NOT TRANSLATE
L["Abbrev Breakpoint 1000"] = "천";     --1,000 = 1K
L["Abbrev Breakpoint 10000"] = "만";    --Reserved for Asian languages that have words for 10,000
L["Match Stat Armor"] = "방어도 ([,%d%.]+)";
L["Match Stat Stamina"] = " 체력 %+([,%d%.]+)";
L["Match Stat Strengh"] = "힘 %+([,%d%.]+)";
L["Match Stat Agility"] = "민첩성 %+([,%d%.]+)";
L["Match Stat Intellect"] = "지능 %+([,%d%.]+)";
L["Match Stat Spirit"] = "정신력 %+([,%d%.]+)";
L["Match Stat DPS"] = "초당 공격력 ([,%d%.]+)";