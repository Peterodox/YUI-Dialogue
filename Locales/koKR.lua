
if not (GetLocale() == "koKR") then return end;


local _, addon = ...
local L = addon.L;


--DO NOT TRANSLATE
L["Match Stat Armor"] = "방어도 ([,%d%.]+)";
L["Match Stat Stamina"] = " 체력 %+([,%d%.]+)";
L["Match Stat Strengh"] = "힘 %+([,%d%.]+)";
L["Match Stat Agility"] = "민첩성 %+([,%d%.]+)";
L["Match Stat Intellect"] = "지능 %+([,%d%.]+)";
L["Match Stat Spirit"] = "정신력 %+([,%d%.]+)";
L["Match Stat DPS"] = "초당 공격력 ([,%d%.]+)";