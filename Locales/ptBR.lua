
if not (GetLocale() == "ptBR") then return end;


local _, addon = ...
local L = addon.L;


--DO NOT TRANSLATE
L["Match Stat Armor"] = "([,%d%.]+) de Armadura";
L["Match Stat Stamina"] = "([,%d%.]+) Vigor";
L["Match Stat Strengh"] = "([,%d%.]+) Força";
L["Match Stat Agility"] = "([,%d%.]+) Agilidade";
L["Match Stat Intellect"] = "([,%d%.]+) Intelecto";
L["Match Stat Spirit"] = "([,%d%.]+) Espírito";
L["Match Stat DPS"] = "([,%d%.]+) de dano por segundo";