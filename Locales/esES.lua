
if not (GetLocale() == "esES") then return end;


local _, addon = ...
local L = addon.L;


--DO NOT TRANSLATE
L["Match Stat Armor"] = "([,%d%.]+) armadura";
L["Match Stat Stamina"] = "([,%d%.]+) aguante";
L["Match Stat Strengh"] = "([,%d%.]+) fuerza";
L["Match Stat Agility"] = "([,%d%.]+) agilidad";
L["Match Stat Intellect"] = "([,%d%.]+) intelecto";
L["Match Stat Spirit"] = "([,%d%.]+) espíritu";
L["Match Stat DPS"] = "([,%d%.]+) daño por segundo";