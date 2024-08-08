
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