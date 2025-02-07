local _, addon = ...
local API = addon.API;
local L = addon.L;
local CallbackRegistry = addon.CallbackRegistry;

local floor = math.floor;
local sqrt = math.sqrt;
local tostring = tostring;
local find = string.find;

local LOCALE = GetLocale and GetLocale() or "enUS";


local function AlwaysNil(arg)
end
API.Nop = AlwaysNil;

local function AlwaysFalse(arg)
    --used to replace non-existent API in Classic
    return false
end
API.AlwaysFalse = AlwaysFalse;

local function AlwaysTrue(arg)
    return true
end
API.AlwaysTrue = AlwaysTrue;

local function AlwaysZero(arg)
    return 0
end

local function CopyEnum(name)
    local tbl = {};
    if Enum and Enum[name] then
        for k, v in pairs(Enum[name]) do
            tbl[k] = v;
        end
    end
    return tbl
end

do  -- Math
    local function GetPointsDistance2D(x1, y1, x2, y2)
        return sqrt( (x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2))
    end
    API.GetPointsDistance2D = GetPointsDistance2D;

    local function Round(n)
        return floor(n + 0.5);
    end
    API.Round = Round;

    local function Clamp(value, min, max)
        if value > max then
            return max
        elseif value < min then
            return min
        end
        return value
    end
    API.Clamp = Clamp;

    local function Lerp(startValue, endValue, amount)
        return (1 - amount) * startValue + amount * endValue;
    end
    API.Lerp = Lerp;

    local function ClampLerp(startValue, endValue, amount)
        amount = Clamp(amount, 0, 1);
        return Lerp(startValue, endValue, amount);
    end
    API.ClampLerp = ClampLerp;

    local function Saturate(value)
        return Clamp(value, 0.0, 1.0);
    end

    local TARGET_FRAME_PER_SEC = 60.0;

    local function DeltaLerp(startValue, endValue, amount, timeSec)
        return Lerp(startValue, endValue, Saturate(amount * timeSec * TARGET_FRAME_PER_SEC));
    end
    API.DeltaLerp = DeltaLerp;


    do  --Used for currency amount. Simplified from Blizzard's "AbbreviateNumbers" in UIParent.lua
        local ABBREVIATION_K = L["Abbrev Breakpoint 1000"];    --Asian language cut off: 10,000

        if LOCALE == "zhCN" or LOCALE == "zhTW" or LOCALE == "koKR" then
            local ABBREVIATION_W = L["Abbrev Breakpoint 10000"];
            API.AbbreviateNumbers = function(value)
                if value > 100000 then
                    return floor(value / 10000) .. ABBREVIATION_W
                elseif value >= 10000 then
                    return floor(value / 1000)/10 .. ABBREVIATION_W
                --elseif value >= 1000 then
                --    return floor(value / 100)/10 .. ABBREVIATION_K
                else
                    return tostring(value)
                end
            end
        else
            API.AbbreviateNumbers = function(value)
                if value > 10000 then
                    return floor(value / 1000) .. ABBREVIATION_K
                elseif value > 1000 then
                    return floor(value / 100)/10 .. ABBREVIATION_K
                else
                    return tostring(value)
                end
            end
        end
    end
end

do  -- Table
    local function Mixin(object, ...)
        for i = 1, select("#", ...) do
            local mixin = select(i, ...)
            for k, v in pairs(mixin) do
                object[k] = v;
            end
        end
        return object
    end
    API.Mixin = Mixin;

    local function CreateFromMixins(...)
        return Mixin({}, ...)
    end
    API.CreateFromMixins = CreateFromMixins;
end

do  -- Pixel
    local GetPhysicalScreenSize = GetPhysicalScreenSize;
    local SCREEN_WIDTH, SCREEN_HEIGHT = GetPhysicalScreenSize();
    local UI_SCALE_RATIO = 1 / UIParent:GetEffectiveScale();

    local function GetPixelPertectScale()
        return (768/SCREEN_HEIGHT)
    end
    API.GetPixelPertectScale = GetPixelPertectScale;

    local function UpdateTextureSliceScale(textureSlice)
        --Temp Fix for 10.1.7 change
        textureSlice:SetScale(GetPixelPertectScale());
    end
    API.UpdateTextureSliceScale = UpdateTextureSliceScale;

    --if addon.IS_CATA then
        --Era 1.15.3 has this issue too
        --API.UpdateTextureSliceScale = AlwaysNil;  --4.4.1 has this issue too
    --end

    local function GetPixelForScale(scale, pixelSize)
        if pixelSize then
            return pixelSize * (768/SCREEN_HEIGHT)/scale
        else
            return (768/SCREEN_HEIGHT)/scale
        end
    end
    API.GetPixelForScale = GetPixelForScale;

    local function GetPixelForWidget(widget, pixelSize)
        local scale = widget:GetEffectiveScale();
        return GetPixelForScale(scale, pixelSize);
    end
    API.GetPixelForWidget = GetPixelForWidget;

    local function GetSizeInPixel(scale, size)
        return size * scale / (768/SCREEN_HEIGHT)
    end
    API.GetSizeInPixel = GetSizeInPixel;

    local function DisableSharpening(texture)
        texture:SetTexelSnappingBias(0);
        texture:SetSnapToPixelGrid(false);
    end
    API.DisableSharpening = DisableSharpening;

    local function GetBestViewportSize()
        --WorldFrame's size is unaffected by screen resolution
        --Issue caused by occasionally bugged resolution since 11.0? https://github.com/Peterodox/YUI-Dialogue/issues/104
        local viewportWidth, viewportHeight = WorldFrame:GetSize();
        viewportWidth = math.min(viewportWidth, viewportHeight * 16/9);
        return viewportWidth, viewportHeight
    end
    API.GetBestViewportSize = GetBestViewportSize;

    local PixelUtil = CreateFrame("Frame");
    addon.PixelUtil = PixelUtil;

    PixelUtil.objects = {};

    function PixelUtil:AddPixelPerfectObject(object)
        table.insert(self.objects, object);
    end

    function PixelUtil:MarkScaleDirty()
        self.scaleDirty = true;
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate);
    end
    PixelUtil:MarkScaleDirty();

    function PixelUtil:RequireUpdate()
        if self.scaleDirty then
            self.scaleDirty = nil;
            local scale;

            for _, object in ipairs(self.objects) do
                scale = object:GetEffectiveScale();
                object:UpdatePixel(scale);
            end
        end
    end

    function PixelUtil:OnUpdate(elpased)
        self.t = self.t + elpased;
        if self.t > 0.1 then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            self:RequireUpdate();
        end
    end

    PixelUtil:RegisterEvent("UI_SCALE_CHANGED");
    PixelUtil:RegisterEvent("DISPLAY_SIZE_CHANGED");

    PixelUtil:SetScript("OnEvent", function(self, event, ...)
        SCREEN_WIDTH, SCREEN_HEIGHT = GetPhysicalScreenSize();
        UI_SCALE_RATIO = 1 / UIParent:GetEffectiveScale();
        self:MarkScaleDirty();
    end);


    local GetCursorPosition = GetCursorPosition;

    local function GetScaledCursorPosition()
        local x, y = GetCursorPosition();
        return x*UI_SCALE_RATIO, y*UI_SCALE_RATIO
    end
    API.GetScaledCursorPosition = GetScaledCursorPosition;
end

do  -- Object Pool (Pool needs to Release all objects before reusing) / DynamicPoolMixin (can reuse any inactive object without Releasing All objects)
    local ObjectPoolMixin = {};
    local ipairs = ipairs;
    local tinsert = table.insert;
    local tremove = table.remove;

    function ObjectPoolMixin:Release()
        for i, object in ipairs(self.objects) do
            if i <= self.numActive then
                self.Remove(object);
            else
                break
            end
        end
        self.numActive = 0;
    end

    function ObjectPoolMixin:Acquire()
        local n = self.numActive + 1;
        self.numActive = n;

        if not self.objects[n] then
            self.objects[n] = self.Create();
        end

        if self.OnAcquired then
            self.OnAcquired(self.objects[n]);
        end

        self.objects[n]:Show();

        return self.objects[n]
    end

    function ObjectPoolMixin:OnLoad()
        self.numActive = 0;
        self.objects = {};
    end

    function ObjectPoolMixin:CallActive(method)
        for i = 1, self.numActive do
            self.objects[i][method](self.objects[i]);
        end
    end

    function ObjectPoolMixin:CallAllObjects(method, ...)
        for i, obj in ipairs(self.objects) do
            obj[method](obj, ...);
        end
    end

    function ObjectPoolMixin:ProcessActiveObjects(func)
        for i = 1, self.numActive do
            func(self.objects[i]);
        end
    end

    function ObjectPoolMixin:ProcessAllObjects(func)
        for i, obj in ipairs(self.objects) do
            func(obj);
        end
    end

    function ObjectPoolMixin:GetObjectsByPredicate(pred)
        local tbl = {};
        for i, obj in ipairs(self.objects) do
            if pred(obj) then
                tinsert(tbl, obj);
            end
        end
        return tbl
    end

    function ObjectPoolMixin:GetActiveObjects()
        local tbl = {};
        for i = 1, self.numActive do
            tinsert(tbl, self.objects[i]);
        end
        return tbl
    end

    function ObjectPoolMixin:EnumerateActive()
        local activeObjects = self:GetActiveObjects();
        return ipairs(activeObjects)
    end

    local function RemoveObject(object)
        object:Hide();
        object:ClearAllPoints();
    end

    local function CreateObjectPool(createFunc, removeFunc, onAcquiredFunc)
        local pool = API.CreateFromMixins(ObjectPoolMixin);
        pool:OnLoad();
        pool.Create = createFunc;
        pool.Remove = removeFunc or RemoveObject;
        pool.OnAcquired = onAcquiredFunc;
        return pool
    end
    API.CreateObjectPool = CreateObjectPool;




    local DynamicPoolMixin = {};

    function DynamicPoolMixin:ReleaseAll()
        local removeFunc = self.Remove or RemoveObject;
        for obj, active in pairs(self.activeObjects) do
            if active then
                removeFunc(obj);
            end
        end
        self.activeObjects = {};
        self.bins = {};
        for i, obj in ipairs(self.allObjects) do
            self.bins[i] = obj;
        end
    end

    function DynamicPoolMixin:RecycleObject(obj)
        if self.activeObjects[obj] then
            self.activeObjects[obj] = nil;
            if self.Remove then
                self.Remove(obj);
            else
                RemoveObject(obj);
            end
        end
        tinsert(self.bins, obj);
    end

    function DynamicPoolMixin:Acquire()
        local obj = tremove(self.bins);
        if not obj then
            obj = self.Create();
            obj.Release = self.ReleaseObject;
            tinsert(self.allObjects, obj);
        end
        if self.OnAcquired then
            self.OnAcquired(obj);
        end
        self.activeObjects[obj] = true;
        return obj
    end

    function DynamicPoolMixin:CallActive(method, arg1, arg2, arg3, arg4)
        for obj, active in pairs(self.activeObjects) do
            obj[method](obj, arg1, arg2, arg3, arg4);
        end
    end

    function DynamicPoolMixin:EnumerateActive()
        return pairs(self.activeObjects);
    end

    function DynamicPoolMixin:DebugGetCount()
        local numTotal = #self.allObjects;
        local numInactive = #self.bins;
        local numActive = 0;
        for obj, active in pairs(self.activeObjects) do
            numActive = numActive + 1;
        end
        print(numTotal, numActive, numInactive);
    end

    local function CreateDynamicObjectPool(createFunc, removeFunc, onAcquiredFunc)
        local pool = API.CreateFromMixins(DynamicPoolMixin);

        pool.allObjects = {};
        pool.bins = {};
        pool.activeObjects = {};

        pool.Create = createFunc;
        pool.Remove = removeFunc or RemoveObject;
        pool.OnAcquired = onAcquiredFunc;

        pool.ReleaseObject = function(obj)
            pool:RecycleObject(obj);
        end

        return pool
    end
    API.CreateDynamicObjectPool = CreateDynamicObjectPool;
end

do  -- String
    local match = string.match;
    local gmatch = string.gmatch;
    local gsub = string.gsub;
    local tinsert = table.insert;

    local function SplitParagraph(text)
        local tbl = {};

        if text then
            local n = 0;
            for v in gmatch(text, "[%C]+") do
                if v ~= " " then
                    n = n + 1;
                    tbl[n] = v;
                end
            end
        end

        return tbl
    end
    API.SplitParagraph = SplitParagraph;


    local READING_CPS = 15; --Vary depends on Language
    local strlenutf8 = strlenutf8;

    local function GetTextReadingTime(text)
        local numWords = strlenutf8(text);
        return API.Clamp(numWords / READING_CPS, 2.75, 8);
    end
    API.GetTextReadingTime = GetTextReadingTime;


    local function ReplaceRegularExpression(formatString)
        return gsub(formatString, "%%d", "%%s")
    end
    API.ReplaceRegularExpression = ReplaceRegularExpression;

    do
        local function UpdateFormat(k)
            if L[k] then
                L[k] = ReplaceRegularExpression(L[k]);
            else
                print("DialogueUI Missing String:", k);
            end
        end

        UpdateFormat("Format Player XP");
        UpdateFormat("Format Gold Amount")
        UpdateFormat("Format Silver Amount")
        UpdateFormat("Format Copper Amount")
    end

    local function GetItemIDFromHyperlink(link)
        local id = match(link, "[Ii]tem:(%d*)");
        if id then
            return tonumber(id)
        end
    end
    API.GetItemIDFromHyperlink = GetItemIDFromHyperlink;

    local function GetGlobalObject(objNameKey)
        --Get object via string "FrameName.Key1.Key2"
        local obj = _G;

        for k in string.gmatch(objNameKey, "%w+") do
            obj = obj[k];
            if not obj then
                return
            end
        end

        return obj
    end
    API.GetGlobalObject = GetGlobalObject;

    local function DoesGlobalObjectExist(objNameKey)
        return GetGlobalObject(objNameKey) ~= nil
    end
    API.GetGlobalObject = DoesGlobalObjectExist;
end

do  -- NPC Interaction
    local SetUnitCursorTexture = SetUnitCursorTexture;
    local UnitExists = UnitExists;
    local UnitName = UnitName;
    local UnitGUID = UnitGUID;

    local f = CreateFrame("Frame");
    f.texture = f:CreateTexture();
    f.texture:SetSize(1, 1);

    local CursorTextureTypes = {
        ["Cursor Talk"] = "gossip",     --Most interactable NPC that doesn't provide quests
        [4675624] = "direction",        --Guard, asking for direction
    };

    local TexturePrefix = "Interface/AddOns/DialogueUI/Art/Icons/NPCType-";

    local CustomTypeTexture = {
        direction = "Direction",
    };

    local function GetInteractType(unit)
        if UnitExists(unit) then
            --Returns cursor texture (RepairNPC, Transmog, Taxi...)
            --Quest NPC (with question mark) returns nil (there is no type icon on the nameplate)
            SetUnitCursorTexture(f.texture, unit);
            local file = f.texture:GetTexture();
            return file, file and CursorTextureTypes[file]
        end
    end
    API.GetInteractType = GetInteractType;

    local function GetInteractTexture(unit)
        local _, type = GetInteractType(unit);
        if type and CustomTypeTexture[type] then
            return TexturePrefix..CustomTypeTexture[type]
        end
    end
    API.GetInteractTexture = GetInteractTexture;


    local IsInteractingWithNpcOfType = C_PlayerInteractionManager.IsInteractingWithNpcOfType;
    local TYPE_GOSSIP = Enum.PlayerInteractionType and Enum.PlayerInteractionType.Gossip or 3;
    local TYPE_QUEST_GIVER = Enum.PlayerInteractionType and Enum.PlayerInteractionType.QuestGiver or 4;

    local function IsInteractingWithGossip()
        return IsInteractingWithNpcOfType(TYPE_GOSSIP)
    end
    API.IsInteractingWithGossip = IsInteractingWithGossip;

    local function IsInteractingWithQuestGiver()
        return IsInteractingWithNpcOfType(TYPE_QUEST_GIVER)
    end
    API.IsInteractingWithQuestGiver = IsInteractingWithQuestGiver;

    local function IsInteractingWithDialogNPC()
        return (IsInteractingWithNpcOfType(TYPE_GOSSIP) or IsInteractingWithNpcOfType(TYPE_QUEST_GIVER))
    end
    API.IsInteractingWithDialogNPC = IsInteractingWithDialogNPC;

    --A helper to close gossip interaction
    --CloseGossip twice in a row cause issue: UI like MerchantFrame won't close itself, no frame portrait

    local CloseGossip = C_GossipInfo.CloseGossip;

    local function ResetCloseStatus(self, elapsed)
        self.isClosing = false;
        self:SetScript("OnUpdate", nil);
        if f.closeInteraction then
            CloseGossip();
        end
    end

    local function CloseGossipInteraction()
        f.closeInteraction = true;
        if not f.isClosing then
            f.isClosing = true;
            f:SetScript("OnUpdate", ResetCloseStatus);
        end
    end
    API.CloseGossipInteraction = CloseGossipInteraction;

    local function CancelClosingGossipInteraction()
        if f.isClosing then
            f.closeInteraction = false;
        end
    end
    API.CancelClosingGossipInteraction = CancelClosingGossipInteraction;


    f:RegisterEvent("CINEMATIC_START");
    f:RegisterEvent("CINEMATIC_STOP");
    f:RegisterEvent("PLAY_MOVIE");
    f:RegisterEvent("STOP_MOVIE");
    f:RegisterEvent("LOADING_SCREEN_DISABLED");

    f:SetScript("OnEvent", function(self, event, ...)
        if event == "CINEMATIC_START" then
            self.isPlayingCinematic = true;
        elseif event == "CINEMATIC_STOP" then
            self.isPlayingCinematic = false;
        elseif event == "PLAY_MOVIE" then
            self.isPlayingMovie = true;
        elseif event == "STOP_MOVIE" then
            self.isPlayingMovie = false;
        elseif event == "LOADING_SCREEN_DISABLED" then
            --Cutscene events can be stuck?
            self.isPlayingCutscene = false;
            self.isPlayingCinematic = false;
            self.isPlayingMovie = false;
        end

        if self.isPlayingCinematic or self.isPlayingMovie then
            self.isPlayingCutscene = true;
            CallbackRegistry:Trigger("PlayCutscene");
        else
            self.isPlayingCutscene = false;
        end
    end);

    local function IsPlayingCutscene()
        return f.isPlayingCutscene
    end
    API.IsPlayingCutscene = IsPlayingCutscene;

    local function SetPlayCutsceneCallback(callback)
        CallbackRegistry:Register("PlayCutscene", callback);
    end
    API.SetPlayCutsceneCallback = SetPlayCutsceneCallback;


    --Model Size Evaluation
    local ModelScene, NPCActor, MountActor, CameraController;
    --local IsUnitModelReadyForUI = IsUnitModelReadyForUI;


    DUIUtilityActorMixin = {};

    function DUIUtilityActorMixin:EvaluateNPCHeight()
        local bottomX, bottomY, bottomZ, topX, topY, topZ = self:GetActiveBoundingBox(); -- Could be nil for invisible models
        if bottomX and bottomY and bottomZ and topX and topY and topZ then
            local width = topX - bottomX;
            local depth = topY - bottomY;
            local height = topZ - bottomZ;

            --local widthScale = width / MODEL_SCENE_ACTOR_DIMENSIONS_FOR_NORMALIZATION.width;
            --local depthScale = depth / MODEL_SCENE_ACTOR_DIMENSIONS_FOR_NORMALIZATION.depth;
            --local heightScale = height / MODEL_SCENE_ACTOR_DIMENSIONS_FOR_NORMALIZATION.height;
            --print(width, depth, height);

            if CameraController and height then
                CameraController:OnModelEvaluationComplete(height);
            end
        end
        self:ClearModel();
    end

    function DUIUtilityActorMixin:GetMountScale()
        --local calcMountScale = MountActor:CalculateMountScale(PlayerActor);
        --local inverseScale = 1 / calcMountScale;
        --the results are always 1.0 after certain patch
        --print(self.mountName, calcMountScale, inverseScale);
        local bottomX, bottomY, bottomZ, topX, topY, topZ = self:GetActiveBoundingBox(); -- Could be nil for invisible models
        if bottomX and bottomY and bottomZ and topX and topY and topZ then
            local width = topX - bottomX;
            local depth = topY - bottomY;
            local height = topZ - bottomZ;

            local widthScale = width / 2.1;
            local depthScale = depth / 1.1;
            local heightScale = height / 1;
            print(width, depth, height);

            local scale = widthScale * depthScale * heightScale;
            print(scale);

            local volumn = width * height * depth;
            print(volumn)
        end
        self:ClearModel();
    end

    function DUIUtilityActorMixin:OnModelLoaded()
        if self.onModelLoadedCallback then
            self.onModelLoadedCallback(self);
        end
    end

    --0.8, 1.0, 1.6: Goblin
    --0.9, 1.1, 2.1: Human
    --1.1, 1.3, 1.7: Dwarf
    --0.9, 1.2, 2.5: NElf M
    --0.8, 0.8, 2.1: VElf F
    --0.5, 0.8, 1.1: Gnome
    --3.2, 2.0, 2.9: Malicia
    --3.8, 3.5, 5.2: Draknoid
    --2.9, 5.1, 7.7: Watcher Koranos
    --30, 20, 14:    Dragon Aspect

    local function CreateModelScene()
        if not ModelScene then
            ModelScene = CreateFrame("ModelScene");
            ModelScene:SetSize(1, 1);
        end
    end

    local function EvaluateUnitSize(unit)
        CreateModelScene();

        if not NPCActor then
            NPCActor = ModelScene:CreateActor(nil, "DUIUtilityActorTemplate");
            NPCActor.onModelLoadedCallback = NPCActor.EvaluateNPCHeight;
        end

        local success = NPCActor:SetModelByUnit(unit);
        return success
    end

    local function EvaluateNPCSize()
        return EvaluateUnitSize("npc");
    end
    API.EvaluateNPCSize = EvaluateNPCSize;


    local function EvaluateMountScale(mountID)
        CreateModelScene();

        if not MountActor then
            MountActor = ModelScene:CreateActor(nil, "DUIUtilityActorTemplate");
            MountActor.onModelLoadedCallback = MountActor.GetMountScale;
        end

        if not PlayerActor then
            PlayerActor = ModelScene:CreateActor(nil, "DUIUtilityActorTemplate");
            PlayerActor.onModelLoadedCallback = function() print("LOADED") end;
        end

        local hasAlternateForm, inAlternateForm = C_PlayerInfo.GetAlternateFormInfo();
        local sheatheWeapon = true;
        local autodress = false;
		local hideWeapon = true;
        local useNativeForm = not inAlternateForm;
        PlayerActor:SetScale(1);
        
        local result = PlayerActor:SetModelByUnit("player", sheatheWeapon, autodress, hideWeapon, useNativeForm);
        if result then
            local creatureDisplayID, _, _, isSelfMount, _, modelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(mountID);
            MountActor.mountName = C_MountJournal.GetMountInfoByID(mountID);
            local showCustomization = true;
            MountActor:ClearModel();
            MountActor:SetModelByCreatureDisplayID(creatureDisplayID, showCustomization);
        end
    end
    API.EvaluateMountScale = EvaluateMountScale;

    local function SetCameraController(controller)
        CameraController = controller;
    end
    addon.SetCameraController = SetCameraController;


    local match = string.match;

    local function GetCreatureIDFromGUID(guid)
        --Including Creature, Vehicle, GameObject
        local id = guid and match(guid, "^%a+%-0%-%d*%-%d*%-%d*%-(%d*)");
        if id then
            return tonumber(id)
        end
    end
    API.GetCreatureIDFromGUID = GetCreatureIDFromGUID;

    local function GetCurrentNPCInfo()
        local name = UnitName("npc");
        local creatureID = GetCreatureIDFromGUID(UnitGUID("npc"));
        if creatureID then
            name = name or "";
            return name, creatureID
        end
    end
    API.GetCurrentNPCInfo = GetCurrentNPCInfo;

    local SkippedNPC = {
        [94398] = true,     --Fleet Command Table
        [94399] = true,     --Fleet Command Table
        [138704] = true,    --Mission Command Table
        [138706] = true,    --Mission Command Table
        [147244] = true,    --Mission Command Table
        [215758] = true,    --Mission Command Table
    };
    local function IsInteractingWithGameObject()
        local guid = UnitGUID("npc");
        if guid then
            local unitType, id = match(guid, "^(%a+)%-0%-%d*%-%d*%-%d*%-(%d*)");
            if unitType == "GameObject" or unitType == "Vehicle" then
                return true
            elseif unitType == "Creature" and id then
                id = tonumber(id) or 0;
                return SkippedNPC[id]
            end
        end
    end
    API.IsInteractingWithGameObject = IsInteractingWithGameObject;

    local SCOUTING_MAP = ADVENTURE_MAP_TITLE or "Scouting Map";
    local UnitClass = UnitClass;

    local function IsTargetAdventureMap()
        local className = UnitClass("npc");
        return className == SCOUTING_MAP
    end
    API.IsTargetAdventureMap = IsTargetAdventureMap;
end

do  -- Easing
    local EasingFunctions = {};
    addon.EasingFunctions = EasingFunctions;


    local sin = math.sin;
    local cos = math.cos;
    local pow = math.pow;
    local pi = math.pi;

    --t: total time elapsed
    --b: beginning position
    --e: ending position
    --d: animation duration

    function EasingFunctions.linear(t, b, e, d)
        return (e - b) * t / d + b
    end

    function EasingFunctions.outSine(t, b, e, d)
        return (e - b) * sin(t / d * (pi / 2)) + b
    end

    function EasingFunctions.inOutSine(t, b, e, d)
        return -(e - b) / 2 * (cos(pi * t / d) - 1) + b
    end

    function EasingFunctions.outQuart(t, b, e, d)
        t = t / d - 1;
        return (b - e) * (pow(t, 4) - 1) + b
    end

    function EasingFunctions.outQuint(t, b, e, d)
        t = t / d
        return (b - e)* (pow(1 - t, 5) - 1) + b
    end

    function EasingFunctions.inQuad(t, b, e, d)
        t = t / d
        return (e - b) * pow(t, 2) + b
    end

    function EasingFunctions.none(t, b, e, d)
        return e
    end

    function EasingFunctions.noChange(t, b, e, d)
        return b
    end
end

do  -- Quest
    local ICON_PATH = "Interface/AddOns/DialogueUI/Art/Icons/";
    local Enum_QuestClassification = CopyEnum("QuestClassification");

    local QuestGetAutoAccept = QuestGetAutoAccept or AlwaysFalse;
    local C_QuestLog = C_QuestLog;
    local IsOnQuest = C_QuestLog.IsOnQuest;
    local GetQuestReward = GetQuestReward;
    local ReadyForTurnIn = C_QuestLog.ReadyForTurnIn or IsQuestComplete or AlwaysFalse;
    local QuestIsFromAreaTrigger = QuestIsFromAreaTrigger or AlwaysFalse;
    local GetSuggestedGroupSize = GetSuggestedGroupSize or AlwaysZero;
    local IsQuestTrivial = C_QuestLog.IsQuestTrivial or AlwaysFalse;
    local IsCampaignQuest = (C_CampaignInfo and C_CampaignInfo.IsCampaignQuest) or AlwaysFalse;
    local IsQuestTask = C_QuestLog.IsQuestTask or AlwaysFalse;
    local IsWorldQuest = C_QuestLog.IsWorldQuest or AlwaysFalse;
    local GetRewardSkillPoints = GetRewardSkillPoints or AlwaysFalse;
    local GetRewardArtifactXP = GetRewardArtifactXP or AlwaysZero;
    local QuestCanHaveWarModeBonus = C_QuestLog.QuestCanHaveWarModeBonus or AlwaysFalse;
    local QuestHasQuestSessionBonus = C_QuestLog.QuestHasQuestSessionBonus or AlwaysFalse;
    local GetQuestItemInfoLootType = GetQuestItemInfoLootType or AlwaysZero;
    local GetTitleForQuestID = C_QuestLog.GetTitleForQuestID or C_QuestLog.GetQuestInfo or AlwaysFalse;
    local GetQuestObjectives = C_QuestLog.GetQuestObjectives;
    local GetQuestTimeLeftSeconds = C_TaskQuest and C_TaskQuest.GetQuestTimeLeftSeconds or AlwaysNil;
    local IsQuestFlaggedCompletedOnAccount = C_QuestLog.IsQuestFlaggedCompletedOnAccount or AlwaysFalse;
    local GetLogIndexForQuestID = C_QuestLog.GetLogIndexForQuestID or GetQuestLogIndexByID or AlwaysNil;
    local GetNumQuestLeaderBoards = GetNumQuestLeaderBoards;
    local GetQuestLogLeaderBoard = GetQuestLogLeaderBoard;
    local GetQuestClassification = C_QuestInfoSystem.GetQuestClassification or AlwaysNil;
    local IsAccountQuest = C_QuestLog.IsAccountQuest or AlwaysFalse;

    API.IsQuestFlaggedCompletedOnAccount = IsQuestFlaggedCompletedOnAccount;

    local function IsPlayerOnQuest(questID)
        if questID then
            return IsOnQuest(questID)
        end
    end
    API.IsPlayerOnQuest = IsPlayerOnQuest;

    if AcknowledgeAutoAcceptQuest then
        API.AcknowledgeAutoAcceptQuest = AcknowledgeAutoAcceptQuest;
    else    --Classic
        API.AcknowledgeAutoAcceptQuest = AcceptQuest;
    end

    --TWW
    local GetQuestCurrency;

    if C_QuestOffer and C_QuestOffer.GetQuestRewardCurrencyInfo then
        local GetQuestRequiredCurrencyInfo = C_QuestOffer.GetQuestRequiredCurrencyInfo;
        local GetQuestRewardCurrencyInfo = C_QuestOffer.GetQuestRewardCurrencyInfo;

        function GetQuestCurrency(questInfoType, index)
            --Unifiy two APIs and their payload structures:
            --"duiDisplayedAmount" for displaying the ItemCount

            local tbl;

            if questInfoType == "reward" or questInfoType == "choice" then
                tbl = GetQuestRewardCurrencyInfo(questInfoType, index);
                tbl.duiDisplayedAmount = tbl.totalRewardAmount;
            elseif questInfoType == "required" then
                tbl = GetQuestRequiredCurrencyInfo(index);
                tbl.duiDisplayedAmount = tbl.requiredAmount;
            end

            return tbl
        end
    else
        local GetQuestCurrencyInfo = GetQuestCurrencyInfo;
        local GetQuestCurrencyID = GetQuestCurrencyID;

        function GetQuestCurrency(questInfoType, index)
            local name, texture, amount, quality = GetQuestCurrencyInfo(questInfoType, index)
            local currencyID = GetQuestCurrencyID(questInfoType, index);

            local tbl = {
                texture = texture,
                name = name,
                currencyID = currencyID,
                quality = quality or 0,
                baseRewardAmount = amount,
                bonusRewardAmount = 0,
                totalRewardAmount = amount,
                questRewardContextFlags = nil,
                requiredAmount = 0,
                duiDisplayedAmount = amount;
            };

            return tbl
        end
    end
    API.GetQuestCurrency = GetQuestCurrency;

    local function GetQuestLogProgress(questID)
        local questLogIndex = GetLogIndexForQuestID(questID);
        if questLogIndex then
            local numObjectives = GetNumQuestLeaderBoards(questLogIndex);
            if numObjectives > 0 then
                local str;
                local text, objectiveType, finished;
                local n = 0;
                for i = 1, numObjectives do
                    text, objectiveType, finished = GetQuestLogLeaderBoard(i, questLogIndex);
                    if text then
                        if str then
                            str = str.."\n".."- "..text;
                        else
                            str = "- "..text;
                        end
                    end
                end
                return str
            end
        end
    end
    API.GetQuestLogProgress = GetQuestLogProgress;

    --Classic
    API.QuestGetAutoAccept = QuestGetAutoAccept;
    API.QuestIsFromAreaTrigger = QuestIsFromAreaTrigger;
    API.GetSuggestedGroupSize = GetSuggestedGroupSize;
    API.GetRewardSkillPoints = GetRewardSkillPoints;
    API.GetRewardArtifactXP = GetRewardArtifactXP;
    API.QuestCanHaveWarModeBonus = QuestCanHaveWarModeBonus;
    API.QuestHasQuestSessionBonus = QuestHasQuestSessionBonus;
    API.GetQuestItemInfoLootType = GetQuestItemInfoLootType;
    API.GetTitleForQuestID = GetTitleForQuestID;
    API.IsAccountQuest = IsAccountQuest;

    if GetAvailableQuestInfo then
        API.GetAvailableQuestInfo = GetAvailableQuestInfo;
    else
        API.GetAvailableQuestInfo = function()
            return false, 0, false, false, 0
        end
    end

    if GetActiveQuestID then
        API.GetActiveQuestID = GetActiveQuestID;
    else
        API.GetActiveQuestID = function()
            return 0
        end
    end

    local function CompleteCurrentQuest(rewardChoiceID, isAutoComplete)
        rewardChoiceID = rewardChoiceID or 0;
        GetQuestReward(rewardChoiceID);
        CallbackRegistry:Trigger("TriggerQuestFinished", isAutoComplete);   --In some cases game doesn't fire QUEST_FINISHED after completing a quest?
    end
    API.CompleteCurrentQuest = CompleteCurrentQuest;

    local QuestMixin = {};
    do
        function QuestMixin:Refresh()
            self.classification = GetQuestClassification(self.questID) or -1;
            self.isTrivial = IsQuestTrivial(self.questID);
        end
    end

    local function BuildQuestInfo(questInfo)
        questInfo.Refresh = QuestMixin.Refresh;

        local class = GetQuestClassification(questInfo.questID) or -1;
        questInfo.classification = class;

        if questInfo.isOnQuest == nil then
            questInfo.isOnQuest = IsOnQuest(questInfo.questID);
        end

        if not questInfo.isComplete then     --Classic Shenanigans
            questInfo.isComplete = ReadyForTurnIn(questInfo.questID);
        end

        if questInfo.isCampaign == nil then
            questInfo.isCampaign = IsCampaignQuest(questInfo.questID);  --QuestMixin uses C_CampaignInfo.GetCampaignID() ~= 0. Wonder what's the difference here;
        end

        if questInfo.isLegendary == nil then
            questInfo.isLegendary = class == Enum_QuestClassification.Legendary;
        end

        if questInfo.isImportant == nil then
            questInfo.isImportant = class == Enum_QuestClassification.Important;
        end

        if questInfo.isTrivial == nil then
            questInfo.isTrivial  = IsQuestTrivial(questInfo.questID);   --May not get the correct value during the first call
        end

        if questInfo.frequency == nil then
            --frequency may be inaccurate?
            questInfo.frequency = 0;
        end

        if not questInfo.isMeta then
            questInfo.isMeta = class == Enum_QuestClassification.Meta;
        end

        if questInfo.frequency == 2 then
            questInfo.isWeekly = true;
        end

        if questInfo.frequency == 1 then
            questInfo.isDaily = true;
        end

        if questInfo.isAccountQuest == nil then
            questInfo.isAccountQuest = IsAccountQuest(questInfo.questID);
        end

        return questInfo
    end
    API.BuildQuestInfo = BuildQuestInfo;

    local function GetQuestIcon(questInfo)
        --QuestMapLogTitleButton_OnEnter

        if not questInfo then
            return ICON_PATH.."IncompleteQuest.png";
        end

        local file;

        if questInfo.isOnQuest then
            if questInfo.isComplete then
                if questInfo.isCampaign then
                    file = "CompleteCampaignQuest.png";
                elseif questInfo.isLegendary then
                    file = "CompleteLegendaryQuest.png";
                elseif questInfo.isImportant then
                    file = "CompleteImportantQuest.png";
                else
                    file = "CompleteQuest.png";
                end
            else
                if questInfo.isCampaign then
                    file = "IncompleteCampaignQuest.png";
                elseif questInfo.isLegendary then
                    file = "IncompleteLegendaryQuest.png";
                elseif questInfo.isImportant then
                    file = "IncompleteImportantQuest.png";
                elseif questInfo.isMeta then
                    file = "IncompleteMetaQuest.png";
                else
                    file = "IncompleteQuest.png";
                end
            end

        else
            if questInfo.frequency == 1 then    --Enum.QuestFrequency.Daily
                file = "DailyQuest.png";
            elseif questInfo.frequency == 2 then    --Enum.QuestFrequency.Weekly
                file = "WeeklyQuest.png";
            elseif questInfo.frequency == 3 and not questInfo.isMeta then   ----Enum.QuestFrequency.ResetByScheduler
                file = "RepeatableScheduler.png";    --TWW
            elseif  questInfo.repeatable then
                file = "RepeatableQuest.png";
            else
                if questInfo.isCampaign then
                    file = "AvailableCampaignQuest.png";
                elseif questInfo.isLegendary then
                    file = "AvailableLegendaryQuest.png";
                elseif questInfo.isImportant then
                    file = "AvailableImportantQuest.png";
                elseif questInfo.isMeta then
                    file = "AvailableMetaQuest.png";
                else
                    file = "AvailableQuest.png";
                end
            end
        end

        return ICON_PATH..file
    end
    API.GetQuestIcon = GetQuestIcon;

    local function IsQuestAutoAccepted()
        return QuestGetAutoAccept()
    end
    API.IsQuestAutoAccepted = IsQuestAutoAccepted;

    local function ShouldShowQuestAcceptedAlert(questID)
        return not (IsWorldQuest(questID) and IsQuestTask(questID));
    end
    API.ShouldShowQuestAcceptedAlert = ShouldShowQuestAcceptedAlert;

    local GetDetailText = GetQuestText;
    local GetProgressText = GetProgressText;
    local GetRewardText = GetRewardText;
    local GetGreetingText = GetGreetingText;
    local GetGossipText = C_GossipInfo.GetText;

    local QuestTextMethod = {
        Detail = GetDetailText,
        Progress = GetProgressText,
        Complete = GetRewardText,
        Greeting = GetGreetingText,
    };

    API.GetGossipText = GetGossipText;

    local function GetQuestText(method)
        local text = QuestTextMethod[method]();
        if text and text ~= "" then
            return text
        end
    end
    API.GetQuestText = GetQuestText;

    if C_QuestInfoSystem.GetQuestRewardCurrencies then
        local GetQuestRewardCurrencies = C_QuestInfoSystem.GetQuestRewardCurrencies;

        local function GetNumRewardCurrencies_TWW(questID)
            local currencyRewards = GetQuestRewardCurrencies(questID) or {};
            return #currencyRewards
        end
        API.GetNumRewardCurrencies = GetNumRewardCurrencies_TWW;
    else
        local GetNumRewardCurrencies_Deprecated = GetNumRewardCurrencies;
        API.GetNumRewardCurrencies = GetNumRewardCurrencies_Deprecated;
    end


    --QuestTheme
    local GetQuestDetailsTheme = C_QuestLog.GetQuestDetailsTheme or AlwaysFalse;
    local DECOR_PATH = "Interface/AddOns/DialogueUI/Art/ParchmentDecor/";
    local BackgroundDecors = {
        ["QuestBG-Dragonflight"] = "Dragonflight.png",
        ["QuestBG-Azurespan"] = "Dragonflight.png",
        ["QuestBG-EmeraldDream"] = "Dragonflight-Green.png",
        ["QuestBG-Ohnplains"] = "Dragonflight-Green.png",
        ["QuestBG-Thaldraszus"] = "Dragonflight-Bronze.png",
        ["QuestBG-Walkingshore"] = "Dragonflight-Red.png",
        ["QuestBG-ZaralekCavern"] = "Dragonflight.png",
        ["QuestBG-ExilesReach"] = "Dragonflight.png",

        ["QuestBG-Alliance"] = "Alliance.png",
        ["QuestBG-Horde"] = "Horde.png",

        ["QuestBG-Flame"] = "TWW-Flame.png",
        ["QuestBG-Candle"] = "TWW-Candle.png",
        ["QuestBG-Storm"] = "TWW-Storm.png",
        ["QuestBG-Web"] = "TWW-Web.png",
        ["QuestBG-1027"] = "TWW-Azeroth.png",
        ["QuestBG-Rocket"] = "TWW-Rocket.png",
    };

    local function GetQuestBackgroundDecor(questID)
        local theme = GetQuestDetailsTheme(questID);
        --print(theme.background)
        --theme = {background = "QuestBG-Web"};    --debug
        if theme and theme.background and BackgroundDecors[theme.background] then
            return DECOR_PATH..BackgroundDecors[theme.background]
        end
    end
    API.GetQuestBackgroundDecor = GetQuestBackgroundDecor;


    local MAX_QUESTS;
    local GetNumQuestLogEntries = C_QuestLog.GetNumQuestLogEntries;
    local GetQuestIDForLogIndex = C_QuestLog.GetQuestIDForLogIndex;
    local GetQuestInfo = C_QuestLog.GetInfo;

    local function GetNumQuestCanAccept()
        --*Unreliable
        --numQuests include all types of quests.
        --(Account/Daily) quests don't count towards MaxQuest(35)
        if not MAX_QUESTS then
            MAX_QUESTS = C_QuestLog.GetMaxNumQuestsCanAccept();
        end

        local numShownEntries, numAllQuests = GetNumQuestLogEntries();
        local numQuests = 0;
        local questID;
        local n = 0;
        print("numShownEntries", numShownEntries);

        for i = 1, numShownEntries do
            questID = GetQuestIDForLogIndex(i);
            if questID ~= 0 then
                local info = GetQuestInfo(i);

                if info and not (info.isHidden or info.isHeader) then
                    if not (IsAccountQuest(questID)) then
                        numQuests = numQuests + 1;

                        print(numQuests, questID, info.title)
                    end
                end
            end
        end

        print("Num Quests:", numQuests);
        return MAX_QUESTS - numQuests, MAX_QUESTS
    end

    local GetItemInfoInstant = C_Item.GetItemInfoInstant;
    local select = select;

    local function IsQuestLoreItem(item)
        --Display lore text (QuestItemDisplay)
        if not item then return end;
        local classID, subclassID = select(6, GetItemInfoInstant(item));
        --print(item, classID, subclassID)
        return (classID == 12) or (classID == 0 and subclassID == 8) or (classID == 15 and (subclassID == 0 or subclassID == 4))
    end
    API.IsQuestLoreItem = IsQuestLoreItem;

    local function IsQuestRequiredItem(item)
        --Don't show item count in bag if ItemType == 12
        if not item then return end;
        local classID, subclassID = select(6, GetItemInfoInstant(item));
        return classID == 12
    end
    API.IsQuestRequiredItem = IsQuestRequiredItem;

    local function GetQuestName(questID)
        local questName = C_TaskQuest.GetQuestInfoByQuestID(questID);
        if not questName then
            --Retail
            if C_QuestLog.GetTitleForQuestID then
                questName = C_QuestLog.GetTitleForQuestID(questID);
                if questName and questName ~= "" then
                    return questName
                else
                    C_QuestLog.RequestLoadQuestByID(questID);
                end
            end

            --Classic
            if GetQuestLogIndexByID then
                local questIndex = GetQuestLogIndexByID(questID);
                if questIndex and questIndex > 0 then
                    questName = GetQuestLogTitle(questIndex);
                else
                    questName = C_QuestLog.GetQuestInfo(questID);
                end
            end
        end
        return questName
    end
    API.GetQuestName = GetQuestName;

    local HoldableItems = {
        INVTYPE_WEAPON = true,
        INVTYPE_2HWEAPON = true,
        INVTYPE_SHIELD = true,
        INVTYPE_HOLDABLE = true,
        INVTYPE_RANGED = true,
        INVTYPE_RANGEDRIGHT = true,
        INVTYPE_WEAPONMAINHAND = true,
        INVTYPE_WEAPONOFFHAND = true,
    };

    local NoUseTransmogSkin = {
        INVTYPE_HEAD = true,
        INVTYPE_HAND = true,
        --INVTYPE_FEET = true,
    };

    local TransmogSetupGear = {
        INVTYPE_HEAD = {78420},
        INVTYPE_HAND = {78420, 78425},
    };

    local function IsHoldableItem(item)
        if item then
            local _, _, _, itemEquipLoc = GetItemInfoInstant(item);
            return HoldableItems[itemEquipLoc];
        end
    end
    API.IsHoldableItem = IsHoldableItem;

    local function GetTransmogSetup(item)
        local _, _, _, itemEquipLoc = GetItemInfoInstant(item);
        local useTransmogSkin = not (NoUseTransmogSkin[itemEquipLoc] or false);
        local setupGear = TransmogSetupGear[itemEquipLoc];
        return useTransmogSkin, setupGear
    end
    API.GetTransmogSetup = GetTransmogSetup;


    --QuestTag
    local GetQuestTagInfo = C_QuestLog.GetQuestTagInfo or AlwaysFalse;
    local QUEST_TAG_NAME = {
        --Also: Enum.QuestTagType
        [Enum.QuestTag.Dungeon] = {L["Quest Type Dungeon"], "QuestTag-Dungeon.png"},
        [Enum.QuestTag.Raid] = {L["Quest Type Raid"], "QuestTag-Raid.png"},
        [Enum.QuestTag.Raid10] = {L["Quest Type Raid"], "QuestTag-Raid.png"},
        [Enum.QuestTag.Raid25] = {L["Quest Type Raid"], "QuestTag-Raid.png"},

        [271] = {L["Quest Type Covenant Calling"]},
    };

    local function GetQuestTag(questID)
        local info = GetQuestTagInfo(questID);
        if info and info.tagID then
            return info.tagID
        end
    end
    API.GetQuestTag = GetQuestTag;

    local function GetQuestTagNameIcon(tagID)
        if QUEST_TAG_NAME[tagID] then
            local icon = QUEST_TAG_NAME[tagID][2];
            if icon then
                icon = ICON_PATH..icon;
            end
            return QUEST_TAG_NAME[tagID][1], icon
        end
    end
    API.GetQuestTagNameIcon = GetQuestTagNameIcon;


    local PLAYER_HONOR_ICON;

    local function GetHonorIcon()
        if PLAYER_HONOR_ICON == nil then
            if UnitFactionGroup and UnitFactionGroup("player") == "Horde" then
                PLAYER_HONOR_ICON = "Interface/Icons/PVPCurrency-Honor-Horde";
            else
                PLAYER_HONOR_ICON = "Interface/Icons/PVPCurrency-Honor-Alliance";
            end
        end

        return PLAYER_HONOR_ICON
    end
    API.GetHonorIcon = GetHonorIcon;

    local function GetQuestTimeLeft(questID, formatedToText)
        local seconds = GetQuestTimeLeftSeconds(questID);
        if seconds then
            if formatedToText then
                return API.SecondsToTime(seconds, true, true)
            else
                return seconds
            end
        end
    end
    API.GetQuestTimeLeft = GetQuestTimeLeft;


    local function GetRecurringQuestTimeLeft(questID, formatedToText)
        if GetQuestClassification(questID) then
            local seconds = GetQuestTimeLeft(questID, formatedToText);
            return true, seconds
        else
            return false
        end
    end
    API.GetRecurringQuestTimeLeft = GetRecurringQuestTimeLeft;

    local function ShouldMuteQuestDetail(questID)
        --Temp Blizzard bug fix for weekly quest appearing repeatedly issue
        local class = GetQuestClassification(questID);
        if (class == 4 or class == 5) and IsOnQuest(questID) then
            return true
        else
            return false
        end
    end
    API.ShouldMuteQuestDetail = ShouldMuteQuestDetail;

    do
        --Replace player name with RP name:
        --Handled by addon when installed: Total RP 3: RP Name in Quest Text
        --Otherwise use our own modifier
        --See Code\SupportedAddOns\Roleplay
        local function TextModifier_None(text)
            return text
        end

        local TextModifier = TextModifier_None;

        local function GetModifiedQuestText(method)
            return TextModifier(GetQuestText(method))
        end
        API.GetModifiedQuestText = GetModifiedQuestText;

        local function GetModifiedGossipText()
            return TextModifier(GetGossipText());
        end
        API.GetModifiedGossipText = GetModifiedGossipText;

        local function SetDialogueTextModifier(modifierFunc)
            TextModifier = modifierFunc or TextModifier_None;
        end
        addon.SetDialogueTextModifier = SetDialogueTextModifier;
    end


    --QuestLine
    if C_QuestLog.GetZoneStoryInfo and C_QuestLine and C_QuestLine.GetQuestLineInfo then
        local GetBestMapForUnit = C_Map.GetBestMapForUnit;
        function API.GetQuestLineInfo(questID)
            local uiMapID = GetBestMapForUnit("player");
            local hasQuestLineOnMap, questLineName, questLineID, achievementID;
            if uiMapID then
                achievementID = C_QuestLog.GetZoneStoryInfo(uiMapID);
                if achievementID then
                    hasQuestLineOnMap = true;
                    local questLineInfo = C_QuestLine.GetQuestLineInfo(questID, uiMapID);
                    if questLineInfo then
                        questLineName = questLineInfo.questLineName;
                        questLineID = questLineInfo.questLineID;
                    end
                end
            end
            return hasQuestLineOnMap, questLineName, questLineID, uiMapID, achievementID
        end
    else
        function API.GetQuestLineInfo(questID)

        end
    end
end

do  -- Color
    -- Make Rare and Epic brighter (use the color in Narcissus)
    local CreateColor = CreateColor;
    local ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS;
    local QualityColors = {};

    QualityColors[0] = CreateColor(0.9, 0.9, 0.9, 1);
    QualityColors[1] = QualityColors[0];
    QualityColors[3] = CreateColor(105/255, 158/255, 255/255, 1);
    QualityColors[4] = CreateColor(185/255, 83/255, 255/255, 1);

    local function GetItemQualityColor(quality)
        if QualityColors[quality] then
            return QualityColors[quality]
        else
            return ITEM_QUALITY_COLORS[quality].color
        end
    end
    API.GetItemQualityColor = GetItemQualityColor;


    local TextPalette = {
        [0] = CreateColor(1, 1, 1, 1),              --Fallback
        [1] = CreateColor(0.87, 0.86, 0.75, 1),     --Ivory: Used by big buttons and low-priority alerts like criteria complete
        [2] = CreateColor(0.19, 0.17, 0.13, 1),     --Dark Brown: Used as paragraph text color
        [3] = CreateColor(0.42, 0.75, 0.48, 1),     --Green: Quest Complete
        [4] = CreateColor(1.000, 0.125, 0.125, 1),  --ERROR_COLOR
    };

    local function GetTextColorByIndex(colorIndex)
        if not (colorIndex and TextPalette[colorIndex]) then
            colorIndex = 0;
        end
        return TextPalette[colorIndex]
    end
    API.GetTextColorByIndex = GetTextColorByIndex;

    local function SetTextColorByIndex(fontString, colorIndex)
        local color = GetTextColorByIndex(colorIndex);
        if color then
            local r, g, b = color:GetRGB();
            fontString:SetTextColor(r, g, b);
        end
    end
    API.SetTextColorByIndex = SetTextColorByIndex;

    local function SetTextColorByGlobal(fontString, colorMixin)
        local r, g, b;
        if colorMixin then
            r, g, b = colorMixin:GetRGB();
        else
            r, g, b = 1, 1, 1;
        end
        fontString:SetTextColor(r, g, b);
    end
    API.SetTextColorByGlobal = SetTextColorByGlobal;
end

do  -- Currency
    local GetCurrencyContainerInfoDefault = C_CurrencyInfo.GetCurrencyContainerInfo;
    local GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo;
    local format = string.format;
    local FormatLargeNumber = FormatLargeNumber;

    local function GetCurrencyContainerInfo(currencyID, numItems, name, texture, quality)
        local entry = GetCurrencyContainerInfoDefault(currencyID, numItems);
        if entry then
            return entry.name, entry.icon, entry.displayAmount, entry.quality
        end
        return name, texture, numItems, quality
    end
    API.GetCurrencyContainerInfo = GetCurrencyContainerInfo;


    local function GenerateMoneyText(rawCopper, colorized, noAbbreviation) --coins
        local text;
        local gold = floor(rawCopper / 10000);
        local silver = floor((rawCopper - gold * 10000) / 100);
        local copper = floor(rawCopper - gold * 10000 - silver * 100);

        local goldText, silverText, copperText;

        if copper > 0 then
            if noAbbreviation then
                copperText = format(L["Format Copper Amount"], copper);
            else
                copperText = copper..L["Symbol Copper"];
            end

            if colorized then
                copperText = "|cffe3b277"..copperText.."|r";
            end
        end

        if gold ~= 0 or silver ~= 0 then
            if noAbbreviation then
                silverText = format(L["Format Silver Amount"], silver);
            else
                silverText = silver..L["Symbol Silver"];
            end

            if colorized then
                silverText = "|cffc5d2e8"..silverText.."|r";
            end

            if gold > 0 then
                if noAbbreviation then
                    goldText = format(L["Format Gold Amount"], FormatLargeNumber(gold));
                else
                    goldText = gold..L["Symbol Gold"];
                end

                if colorized then
                    goldText = "|cffffbb18"..goldText.."|r";
                end

                if copperText then
                    text = goldText.." "..silverText.." "..copperText;
                elseif silver == 0 then
                    text = goldText;
                else
                    text = goldText.." "..silverText;
                end
            else
                if copperText then
                    text = silverText.." "..copperText;
                else
                    text = silverText;
                end
            end
        else
            text = copperText;
        end

        return text
    end
    API.GenerateMoneyText = GenerateMoneyText;


    local IGNORED_OVERFLOW_ID = {
        [3068] = true,      --Delver's Journey
        [3143] = true,      --Delver's Journey
    };

    local function WillCurrencyRewardOverflow(currencyID, rewardQuantity)
        if IGNORED_OVERFLOW_ID[currencyID] then return false end;

        local currencyInfo = GetCurrencyInfo(currencyID);
        local quantity = currencyInfo and (currencyInfo.useTotalEarnedForMaxQty and currencyInfo.totalEarned or currencyInfo.quantity);
        return quantity and currencyInfo.maxQuantity > 0 and rewardQuantity + quantity > currencyInfo.maxQuantity;
    end
    API.WillCurrencyRewardOverflow = WillCurrencyRewardOverflow;

    local function GetColorizedAmountForCurrency(currencyID, rewardQuantity, useIcon)
        if WillCurrencyRewardOverflow(currencyID, rewardQuantity) then
            if useIcon then --For Small Button
                return "|TInterface/AddOns/DialogueUI/Art/Icons/CurrencyOverflow.png:0:0|t"..rewardQuantity.."|r"
            else
                return "|cffff2020"..rewardQuantity.."|r"
            end
        else
            return rewardQuantity
        end
    end
    API.GetColorizedAmountForCurrency = GetColorizedAmountForCurrency;

    local function GetOwnedCurrencyQuantity(currencyID)
        local currencyInfo = GetCurrencyInfo(currencyID);
        return currencyInfo and currencyInfo.quantity or 0
    end
    API.GetOwnedCurrencyQuantity = GetOwnedCurrencyQuantity;

    local UnitXP = UnitXP;
    local UnitXPMax = UnitXPMax;
    local UnitLevel = UnitLevel;

    local function GetXPPercentage(xp)
        local current = UnitXP("player");
        local max = UnitXPMax("player");
        if current and max and max ~= 0 and xp > 0 then
            local ratio = xp/max;
            if ratio > 1 then
                
            end
            return API.Round(ratio*100);
        else
            return 0
        end
    end
    API.GetXPPercentage = GetXPPercentage;

    local function GetPlayerLevelXP()
        local level = UnitLevel("player");
        local currentXP = UnitXP("player");
        local maxXP = UnitXPMax("player");
        return level, currentXP, maxXP
    end
    API.GetPlayerLevelXP = GetPlayerLevelXP;

    local function IsPlayerAtMaxLevel()
        local maxLevel;

        if GetMaxLevelForPlayerExpansion then
            maxLevel = GetMaxLevelForPlayerExpansion();
        elseif GetMaxPlayerLevel then
            maxLevel = GetMaxPlayerLevel();
        else
            maxLevel = 999
        end

        return UnitLevel("player") >= maxLevel
    end
    API.IsPlayerAtMaxLevel = IsPlayerAtMaxLevel;
end

do  -- Grid Layout
    local ipairs = ipairs;
    local tinsert = table.insert;

    local GridMixin = {};

    function GridMixin:OnLoad()
        self:SetGrid(1, 1);
        self:SetSpacing(0);
    end

    function GridMixin:SetGrid(x, y)
        self.x = x;
        self.y = y;
        self:ResetGrid();
    end

    function GridMixin:SetSpacing(spacing)
        self.spacing = spacing;
    end

    function GridMixin:ResetGrid()
        self.grid = {};
        self.fromRow = 1;
        self.maxOccupiedX = 0;
        self.maxOccupiedY = 0;
    end

    function GridMixin:SetGridSize(gridWidth, gridHeight)
        self.gridWidth = gridWidth;
        self.gridHeight = gridHeight;
    end

    function GridMixin:CreateNewRows(n)
        n = n or 1;

        for i = 1, n do
            local tbl = {};
            for col = 1, self.x do
                tinsert(tbl, false);
            end
            tinsert(self.grid, tbl);
        end
    end

    function GridMixin:FindGridForSize(objectSizeX, objectSizeY)
        local found = false;
        local maxRow = #self.grid;
        local topleftGridX, topleftGridY;

        for row = self.fromRow, maxRow do
            local rowStatus = self.grid[row];
            local maxCol = #rowStatus;
            local rowFull = true;

            for col, occupied in ipairs(rowStatus) do
                if not occupied then
                    rowFull = false;
                    if (col + objectSizeX - 1 <= maxCol) and (row + objectSizeY - 1 <= maxRow) then
                        found = true;
                        topleftGridX = col;
                        topleftGridY = row;

                        for _row = row, row + objectSizeY - 1 do
                            for _col = col, col + objectSizeX - 1 do
                                self.grid[_row][_col] = true;
                            end
                        end

                        if topleftGridX > self.maxOccupiedX then
                            self.maxOccupiedX = topleftGridX;
                        end

                        if topleftGridY > self.maxOccupiedY then
                            self.maxOccupiedY = topleftGridY;
                            if objectSizeY > 1 then
                                self.maxOccupiedY = self.maxOccupiedY + objectSizeY - 1;
                            end
                        end

                        break
                    end
                end
            end

            if found then
                break
            end

            if rowFull then
                self.fromRow = self.fromRow + 1;
            end
        end

        if found then
            return topleftGridX, topleftGridY
        else
            self:CreateNewRows(self.y);
            return self:FindGridForSize(objectSizeX, objectSizeY)
        end
    end

    function GridMixin:FlagPreviousRowFull()
        local maxRow = #self.grid;

        for row = self.fromRow, maxRow do
            local rowStatus = self.grid[row];
            local anyContentThisRow;
            for col, occupied in ipairs(rowStatus) do
                if col == 1 then
                    if occupied then
                        anyContentThisRow = true;
                    end
                else
                    if anyContentThisRow then
                        self.grid[row][col] = true;
                    end
                end
            end
        end
    end

    function GridMixin:GetOffsetForGridPosition(topleftGridX, topleftGridY)
        local offsetX = (topleftGridX - 1) * (self.gridWidth + self.spacing);
        local offsetY = (topleftGridY - 1) * (self.gridHeight + self.spacing);
        return offsetX, -offsetY
    end

    function GridMixin:PlaceObject(object, objectSizeX, objectSizeY, anchorTo, fromOffsetX, fromOffsetY)
        local topleftGridX, topleftGridY = self:FindGridForSize(objectSizeX, objectSizeY);
        local offsetX, offsetY = self:GetOffsetForGridPosition(topleftGridX, topleftGridY);
        object:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", fromOffsetX + offsetX, fromOffsetY + offsetY);
    end

    function GridMixin:GetWrappedSize()
        local width = (self.maxOccupiedX > 0 and self.maxOccupiedX * (self.gridWidth + self.spacing) - self.spacing) or 0;
        local height = (self.maxOccupiedY > 0 and self.maxOccupiedY * (self.gridHeight + self.spacing) - self.spacing) or 0;

        return width, height
    end

    local function CreateGridLayout()
        local grid = API.CreateFromMixins(GridMixin);
        grid:OnLoad();
        return grid
    end
    API.CreateGridLayout = CreateGridLayout;
end

do  -- Fade Frame
    local abs = math.abs;
    local tinsert = table.insert;
    local wipe = wipe;

    local fadeInfo = {};
    local fadingFrames = {};

    local f = CreateFrame("Frame");

    local function OnUpdate(self, elpased)
        local i = 1;
        local frame, info, timer, alpha;
        local isComplete = true;
        while fadingFrames[i] do
            frame = fadingFrames[i];
            info = fadeInfo[frame];
            if info then
                timer = info.timer + elpased;
                if timer >= info.duration then
                    alpha = info.toAlpha;
                    fadeInfo[frame] = nil;
                    if info.alterShownState and alpha <= 0 then
                        frame:Hide();
                    end
                else
                    alpha = info.fromAlpha + (info.toAlpha - info.fromAlpha) * timer/info.duration;
                    info.timer = timer;
                end
                frame:SetAlpha(alpha);
                isComplete = false;
            end
            i = i + 1;
        end

        if isComplete then
            f:Clear();
        end
    end

    function f:Clear()
        self:SetScript("OnUpdate", nil);
        wipe(fadingFrames);
        wipe(fadeInfo);
    end

    function f:Add(frame, fullDuration, fromAlpha, toAlpha, alterShownState, useConstantDuration)
        local alpha = frame:GetAlpha();
        if alterShownState then
            if toAlpha > 0 then
                frame:Show();
            end
            if toAlpha == 0 then
                if not frame:IsShown() then
                    frame:SetAlpha(0);
                    alpha = 0;
                end
                if alpha == 0 then
                    frame:Hide();
                end
            end
        end
        if fromAlpha == toAlpha or alpha == toAlpha then
            if fadeInfo[frame] then
                fadeInfo[frame] = nil;
            end
            return;
        end
        local duration;
        if useConstantDuration then
            duration = fullDuration;
        else
            if fromAlpha then
                duration = fullDuration * (alpha - toAlpha)/(fromAlpha - toAlpha);
            else
                duration = fullDuration * abs(alpha - toAlpha);
            end
        end
        if duration <= 0 then
            frame:SetAlpha(toAlpha);
            if toAlpha == 0 then
                frame:Hide();
            end
            return;
        end
        fadeInfo[frame] = {
            fromAlpha = alpha,
            toAlpha = toAlpha,
            duration = duration,
            timer = 0,
            alterShownState = alterShownState,
        };
        for i = 1, #fadingFrames do
            if fadingFrames[i] == frame then
                return;
            end
        end
        tinsert(fadingFrames, frame);
        self:SetScript("OnUpdate", OnUpdate);
    end

    function f:SimpleFade(frame, toAlpha, alterShownState, speedMultiplier)
        --Use a constant fading speed: 1.0 in 0.25s
        --alterShownState: if true, run Frame:Hide() when alpha reaches zero / run Frame:Show() at the beginning
        speedMultiplier = speedMultiplier or 1;
        local alpha = frame:GetAlpha();
        local duration = abs(alpha - toAlpha) * 0.25 * speedMultiplier;
        if duration <= 0 then
            return;
        end

        self:Add(frame, duration, alpha, toAlpha, alterShownState, true);
    end

    function f:Snap()
        local i = 1;
        local frame, info;
        while fadingFrames[i] do
            frame = fadingFrames[i];
            info = fadeInfo[frame];
            if info then
                frame:SetAlpha(info.toAlpha);
            end
            i = i + 1;
        end
        self:Clear();
    end

    local function UIFrameFade(frame, duration, toAlpha, initialAlpha)
        if initialAlpha then
            frame:SetAlpha(initialAlpha);
            f:Add(frame, duration, initialAlpha, toAlpha, true, false);
        else
            f:Add(frame, duration, nil, toAlpha, true, false);
        end
    end

    local function UIFrameFadeIn(frame, duration)
        frame:SetAlpha(0);
        f:Add(frame, duration, 0, 1, true, false);
    end


    API.UIFrameFade = UIFrameFade;       --from current alpha
    API.UIFrameFadeIn = UIFrameFadeIn;   --from 0 to 1
end

do  -- Model
    local UnitRace = UnitRace;
    local WantsAlteredForm = C_UnitAuras and C_UnitAuras.WantsAlteredForm or AlwaysFalse;

    local function SetModelByUnit(model, unit)
        local _, raceFileName = UnitRace(unit);
        if raceFileName == "Dracthyr" or raceFileName == "Worgen" then
            local arg = WantsAlteredForm(unit);
            model:SetUnit(unit, false, arg);    --blend = false
        else
            model:SetUnit(unit, false);
        end
        model.unit = unit;
    end
    API.SetModelByUnit = SetModelByUnit;


    local function SetModelLight(model, enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB)
        local lightValues = {
            omnidirectional = omni or false;
            point = CreateVector3D(dirX or 0, dirY or 0, dirZ or 0),
            ambientIntensity = ambIntensity or 1,
            ambientColor = CreateColor(ambR or 1, ambG or 1, ambB or 1),
            diffuseIntensity = dirIntensity or 1,
            diffuseColor = CreateColor(dirR or 1, dirG or 1, dirB or 1),
        };

        model:SetLight(enabled, lightValues);
    end
    API.SetModelLight = SetModelLight;
end

do  -- Faction -- Reputation
    local C_GossipInfo = C_GossipInfo;
    local C_MajorFactions = C_MajorFactions;
    local C_Reputation = C_Reputation;
    local GetFactionInfoByID = GetFactionInfoByID or C_Reputation.GetFactionDataByID;   --TWW
    local GetFactionGrantedByCurrency = C_CurrencyInfo.GetFactionGrantedByCurrency or AlwaysFalse;
    local IsAccountWideReputation = C_Reputation and C_Reputation.IsAccountWideReputation or AlwaysFalse;

    local function GetFactionStatusText(factionID)
        --Derived from Blizzard ReputationFrame_InitReputationRow in ReputationFrame.lua
        if not factionID then return end;
        local p1, description, standingID, barMin, barMax, barValue = GetFactionInfoByID(factionID);

        if type(p1) == "table" then     --Return table after TWW
            standingID = p1.reaction;
            barMin = p1.currentReactionThreshold;
            barMax = p1.nextReactionThreshold;
            barValue = p1.currentStanding;
        end

        local isParagon = C_Reputation.IsFactionParagon(factionID);
        local isMajorFaction = C_Reputation.IsMajorFaction(factionID);
        local repInfo = C_GossipInfo.GetFriendshipReputation(factionID);

        local isCapped;
        local factionStandingtext;  --Revered/Junior/Renown 1

        if repInfo and repInfo.friendshipFactionID > 0 then --Friendship
            factionStandingtext = repInfo.reaction;

            if repInfo.nextThreshold then
                barMin, barMax, barValue = repInfo.reactionThreshold, repInfo.nextThreshold, repInfo.standing;
            else
                barMin, barMax, barValue = 0, 1, 1;
                isCapped = true;
            end

            local rankInfo = C_GossipInfo.GetFriendshipReputationRanks(repInfo.friendshipFactionID);
            if rankInfo then
                factionStandingtext = factionStandingtext .. string.format(" (Lv. %s/%s)", rankInfo.currentLevel, rankInfo.maxLevel);
            end

        elseif isMajorFaction then
            local majorFactionData = C_MajorFactions.GetMajorFactionData(factionID);
            if majorFactionData then
                barMin, barMax = 0, majorFactionData.renownLevelThreshold;
                isCapped = C_MajorFactions.HasMaximumRenown(factionID);
                barValue = isCapped and majorFactionData.renownLevelThreshold or majorFactionData.renownReputationEarned or 0;
                factionStandingtext = L["Renown Level Label"] .. majorFactionData.renownLevel;

                if isParagon then
                    local totalEarned, threshold = C_Reputation.GetFactionParagonInfo(factionID);
                    if totalEarned and threshold and threshold ~= 0 then
                        local paragonLevel = floor(totalEarned / threshold);
                        local currentValue = totalEarned - paragonLevel * threshold;
                        factionStandingtext = ("|cff00ccff"..L["Paragon Reputation"].."|r %d/%d"):format(currentValue, threshold);
                    end
                else
                    if isCapped then
                        factionStandingtext = factionStandingtext.." "..L["Level Maxed"];
                    end
                end
            end
        elseif (standingID and standingID > 0) then
            isCapped = standingID == 8;  --MAX_REPUTATION_REACTION
            local gender = UnitSex("player");
		    factionStandingtext = GetText("FACTION_STANDING_LABEL"..standingID, gender);    --GetText: Game API that returns localized texts
        end

        local rolloverText; --(0/24000)
        if barValue and barMax and (not isCapped) then
            rolloverText = string.format("(%s/%s)", barValue, barMax);
        end

        local text;

        if factionStandingtext then
            if not text then text = L["Current Colon"] end;
            factionStandingtext = " |cffffffff"..factionStandingtext.."|r";
            text = text .. factionStandingtext;
        end

        if rolloverText then
            if not text then text = L["Current Colon"] end;
            rolloverText = "  |cffffffff"..rolloverText.."|r";
            text = text .. rolloverText;
        end

        if text then
            text = " \n"..text;
        end

        return text
    end
    API.GetFactionStatusText = GetFactionStatusText;

    local function GetFactionStatusTextByCurrencyID(currencyID)
        local factionID =  GetFactionGrantedByCurrency(currencyID);
        if factionID then
            return GetFactionStatusText(factionID);
        end
    end
    API.GetFactionStatusTextByCurrencyID = GetFactionStatusTextByCurrencyID;

    local function IsReputationAccountWide(factionID)
        return factionID and IsAccountWideReputation(factionID);
    end
    API.IsAccountWideReputation = IsAccountWideReputation;
end

do  -- Chat Message
    local ADDON_ICON = "|TInterface\\AddOns\\DialogueUI\\Art\\Icons\\Logo:0:0|t";
    local function PrintMessage(header, msg)
        if not msg then
            msg = "";
        end
        if StripHyperlinks then
            msg = StripHyperlinks(msg);
        end
        print(ADDON_ICON.."|cffffd100"..header.."  |cffffffff"..msg.."|r");
    end
    API.PrintMessage = PrintMessage;

    function API.PrintQuestCompletionText(msg)
        if msg == "" then return end;
        if StripHyperlinks then
            msg = StripHyperlinks(msg);
        end
        print(ADDON_ICON.." |cffffd100"..msg.."|r");
    end
end

do  -- Tooltip
    local GetInventoryItemLink = GetInventoryItemLink;
    local GetInventoryItemID = GetInventoryItemID;
    local GetItemInfoInstant = C_Item.GetItemInfoInstant;
    local GetQuestItemLink = GetQuestItemLink;

    local EQUIPLOC_SLOTID = {
        INVTYPE_HEAD = 1,
        INVTYPE_NECK = 2,
        INVTYPE_SHOULDER = 3,
        INVTYPE_BODY = 4,
        INVTYPE_CHEST = 5,
        INVTYPE_ROBE = 5,
        INVTYPE_WAIST = 6,
        INVTYPE_LEGS = 7,
        INVTYPE_FEET = 8,
        INVTYPE_WRIST = 9,
        INVTYPE_HAND = 10,
        INVTYPE_FINGER = 11,    --12
        INVTYPE_TRINKET = 13,
        INVTYPE_WEAPON = 16,
        INVTYPE_SHIELD = 17,
        INVTYPE_CLOAK = 15,
        INVTYPE_2HWEAPON = 16,
        INVTYPE_WEAPONMAINHAND = 16,
        INVTYPE_WEAPONOFFHAND = 17,
        INVTYPE_HOLDABLE = 17,
        INVTYPE_RANGED = 18,    --Classic
        INVTYPE_RANGEDRIGHT = 18,
    };

    local FORMAT_POSITIVE_VALUE = "|cff19ff19+%s|r %s"; --Green
    local FORMAT_NEGATIVE_VALUE = "|cffff2020%s|r %s";  --Red

    local function FormatValueDiff(value, name)
        if value > 0 then
            return FORMAT_POSITIVE_VALUE:format(value, name);
        else
            return FORMAT_NEGATIVE_VALUE:format(value, name);
        end
    end

    local function GetEquippedSlotID(item)
        local _, _, _, itemEquipLoc = GetItemInfoInstant(item);
        local slotID = itemEquipLoc and EQUIPLOC_SLOTID[itemEquipLoc];
        return slotID
    end

    local function GetEquippedItemLink(comparisonItem)
        local slotID = GetEquippedSlotID(comparisonItem);

        if slotID then
            local link1 = GetInventoryItemLink("player", slotID);
            local link2;
            if slotID == 11 then
                link2 = GetInventoryItemLink("player", 12);
            elseif slotID == 13 then
                link2 = GetInventoryItemLink("player", 14);
            elseif slotID == 16 then
                link2 = GetInventoryItemLink("player", 17);
                if link2 then
                    local slotID2 = GetEquippedSlotID(link2);
                    if not (slotID2 and slotID2 == slotID) then
                        link2 = nil;
                    end
                end
            end

            if link2 and not link1 then
                link1 = link2;
                link2 = nil;
            end

            return link1, link2
        end
    end
    API.GetEquippedItemLink = GetEquippedItemLink;


    local function GetItemLevelDelta(newItem, oldItem, formatedToText)
        local newItemLevel = API.GetItemLevel(newItem) or 0;
        local oldItemLevel = API.GetItemLevel(oldItem) or 0;
        local diff = newItemLevel - oldItemLevel;

        if formatedToText then
            if diff ~= 0 then
                return FormatValueDiff(diff, L["Item Level"]);
            end
            return
        end

        return diff
    end
    API.GetItemLevelDelta = GetItemLevelDelta;


    local function GetEquippedItemLevelDelta(newLink)
        --Compare a reward item to the equipped one (check 2 slots for ring, trinket, weapon)
        --Return the maximum delta

        if not (newLink and API.IsEquippableItem(newLink)) then return end;

        local newItemLevel = API.GetItemLevel(newLink) or 0;
        local slotID = GetEquippedSlotID(newLink);
        local unit = "player";

        if slotID then
            local link1, link2, secondarySlotID;
            local itemID1 = GetInventoryItemID(unit, slotID);
            local itemID2;

            if itemID1 then
                link1 = GetInventoryItemLink(unit, slotID);
            end
            if slotID == 11 then
                secondarySlotID = 12;
            elseif slotID == 13 then
                secondarySlotID = 14;
            elseif slotID == 16 then
                --Case: Two-hand vs One-hand, Offhand vs Shield
                secondarySlotID = 17;
                itemID2 = GetInventoryItemID(unit, secondarySlotID);
                if itemID2 then
                    local equippedSlotID = GetEquippedSlotID(itemID2);
                    if not (equippedSlotID and equippedSlotID == slotID) then
                        itemID2 = nil;
                        secondarySlotID = nil;
                    end
                else
                    secondarySlotID = nil;
                end
            end

            local n = 0;
            local tbl = {};
            local itemLevel;

            if itemID1 then
                n = n + 1;
                itemLevel = link1 and API.GetItemLevel(link1) or 0;
                tbl[n] = {
                    isReady = itemLevel > 0 and newItemLevel > 0,
                    delta = newItemLevel - itemLevel,
                };
            else
                n = n + 1;
                tbl[n] = {
                    isReady = newItemLevel > 0,
                    delta = newItemLevel,
                };
            end

            if secondarySlotID then
                itemID2 = GetInventoryItemID(unit, secondarySlotID);
                link2 = GetInventoryItemLink(unit, secondarySlotID);
                n = n + 1;
                if itemID2 then
                    itemLevel = link1 and API.GetItemLevel(link2) or 0;
                    tbl[n] = {
                        isReady = itemLevel > 0 and newItemLevel > 0,
                        delta = newItemLevel - itemLevel,
                    };
                else
                    tbl[n] = {
                        isReady = newItemLevel > 0,
                        delta = newItemLevel,
                    };
                end
            end

            return tbl
        end
    end

    local function GetMaxEquippedItemLevelDelta(newLink)
        local itemLevelDeltaInfo = GetEquippedItemLevelDelta(newLink);
        if itemLevelDeltaInfo then
            local isReady = true;
            local maxDelta;
            for _, info in ipairs(itemLevelDeltaInfo) do
                if info.isReady then
                    if not maxDelta then
                        maxDelta = info.delta;
                    elseif info.delta > maxDelta then
                        maxDelta = info.delta;
                    end
                else
                    isReady = false;
                end
            end
            return maxDelta, isReady
        else
            return nil, true
        end
    end
    API.GetMaxEquippedItemLevelDelta = GetMaxEquippedItemLevelDelta;


    local function GetRewardItemLevelDelta(questInfoType, index)
        local newLink = GetQuestItemLink(questInfoType, index);
        return GetMaxEquippedItemLevelDelta(newLink);
    end
    API.GetRewardItemLevelDelta = GetRewardItemLevelDelta;

    local function IsItemAnUpgrade(newLink)
        local delta, isReady = GetMaxEquippedItemLevelDelta(newLink)
        return (delta and delta > 0), isReady
    end
    API.IsItemAnUpgrade = IsItemAnUpgrade;
    API.IsItemAnUpgrade_External = IsItemAnUpgrade;     --Override our API if Pawn is installed (see SupportedAddOns/Pawn.lua)

    local function IsRewardItemUpgrade(questInfoType, index)
        local newLink = GetQuestItemLink(questInfoType, index);
        return API.IsItemAnUpgrade_External(newLink)
    end
    API.IsRewardItemUpgrade = IsRewardItemUpgrade;


    if C_TooltipInfo then
        addon.TooltipAPI = C_TooltipInfo;

    else
        --For Classic where C_TooltipInfo doesn't exist:

        local TooltipAPI = {};
        local CreateColor = CreateColor;
        local TOOLTIP_NAME = "DialogueUIVirtualTooltip";
        local TP = CreateFrame("GameTooltip", TOOLTIP_NAME, nil, "GameTooltipTemplate");
        local UIParent = UIParent;

        TP:SetOwner(UIParent, 'ANCHOR_NONE');
        TP:SetClampedToScreen(false);
        TP:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, -128);
        TP:Show();
        TP:SetScript("OnUpdate", nil);


        local UpdateFrame = CreateFrame("Frame");

        local function UpdateTooltipInfo_OnUpdate(self, elapsed)
            self.t = self.t + elapsed;
            if self.t > 0.2 then
                self.t = 0;
                self:SetScript("OnUpdate", nil);
                CallbackRegistry:Trigger("SharedTooltip.TOOLTIP_DATA_UPDATE", 0);
            end
        end

        function UpdateFrame:OnItemChanged(numLines)
            self.t = 0;
            self.numLines = numLines;
            self:SetScript("OnUpdate", UpdateTooltipInfo_OnUpdate);
        end

        local function GetTooltipHyperlink()
            local name, link = TP:GetItem();
            if link then
                return link
            end

            name, link = TP:GetSpell();
            if link then
                return "spell:"..link
            end
        end

        local function GetTooltipTexts()
            local numLines = TP:NumLines();
            if numLines == 0 then return end;

            local tooltipData = {};
            tooltipData.dataInstanceID = 0;

            local addItemLevel;
            local itemLink = GetTooltipHyperlink();

            if itemLink then
                if itemLink ~= TP.hyperlink then
                    UpdateFrame:OnItemChanged(numLines);
                end

                if API.IsEquippableItem(itemLink) then
                    addItemLevel = API.GetItemLevel(itemLink);
                end
            end

            TP.hyperlink = itemLink;
            tooltipData.hyperlink = itemLink;

            local lines = {};
            local n = 0;

            local fs, text;
            for i = 1, numLines do
                if i == 2 and addItemLevel then
                    n = n + 1;
                    lines[n] = {
                        leftText = L["Format Item Level"]:format(addItemLevel);
                        leftColor = CreateColor(1, 0.82, 0),
                    };
                end

                fs = _G[TOOLTIP_NAME.."TextLeft"..i];
                if fs then
                    n = n + 1;

                    local r, g, b = fs:GetTextColor();
                    text = fs:GetText();
                    local lineData = {
                        leftText = text,
                        leftColor = CreateColor(r, g, b),
                        rightText = nil,
                        wrapText = true,
                        leftOffset = 0,
                    };

                    fs = _G[TOOLTIP_NAME.."TextRight"..i];
                    if fs then
                        text = fs:GetText();
                        if text and text ~= "" then
                            r, g, b = fs:GetTextColor();
                            lineData.rightText = text;
                            lineData.rightColor = CreateColor(r, g, b);
                        end
                    end

                    lines[n] = lineData;
                end
            end

            local sellPrice = API.GetItemSellPrice(itemLink);
            if sellPrice then
                n = n + 1;
                lines[n] = {
                    leftText = "",  --this will be ignored by our tooltip
                    price = sellPrice,
                };
            end

            tooltipData.lines = lines;
            return tooltipData
        end

        do
            local accessors = {
                SetItemByID = "GetItemByID",
                SetCurrencyByID = "GetCurrencyByID",
                SetQuestItem = "GetQuestItem",
                SetQuestCurrency = "GetQuestCurrency",
                SetSpellByID = "GetSpellByID",
                SetItemByGUID = "GetItemByGUID",
                SetHyperlink = "GetHyperlink",
            };

            for accessor, getterName in pairs(accessors) do
                if TP[accessor] then
                    local function GetterFunc(...)
                        TP:ClearLines();
                        TP:SetOwner(UIParent, "ANCHOR_PRESERVE");
                        TP[accessor](TP, ...);
                        return GetTooltipTexts();
                    end

                    TooltipAPI[getterName] = GetterFunc;
                end
            end
        end

        addon.TooltipAPI = TooltipAPI;


        local tinsert = table.insert;
        local match = string.match;
        local gsub = string.gsub;

        local function RemoveBrackets(text)
            return gsub(text, "[()（）]", "")
        end

        local function Pattern_RemoveControl(text)
            return gsub(text, "%%c", "");
        end

        local function Pattern_WrapSpace(text)
            return gsub(Pattern_RemoveControl(text), "%%s", "%(%.%+%)");
        end

        local function RemoveThousandSeparator(numberText)
            if numberText then
                numberText = gsub(numberText, "[,%.%-]", "");   --Include %- as a temp fix for French locale bug
                return numberText
            end
        end

        local STATS_PATTERN;
        local STATS_ORDER = {
            "dps", "armor", "stamina", "strength", "agility", "intellect", "spirit",
        };

        local STATS_NAME = {
            dps = STAT_DPS_SHORT or "DPS",      --ITEM_MOD_DAMAGE_PER_SECOND_SHORT
            armor = RESISTANCE0_NAME or "Armor",
            stamina = SPELL_STAT3_NAME or "Stamina",
            strength = SPELL_STAT1_NAME or "Strengh",
            agility = SPELL_STAT2_NAME or "Agility",
            intellect = SPELL_STAT4_NAME or "Intellect",
            spirit = SPELL_STAT5_NAME or "Spirit",
        };

        local function BuildStatsPattern()
            local PATTERN_DPS = L["Match Stat DPS"]             --Pattern_WrapSpace(RemoveBrackets(DPS_TEMPLATE or "(%s damage per second)"));
            local PATTERN_ARMOR = L["Match Stat Armor"]         --Pattern_WrapSpace(ARMOR_TEMPLATE or "%s Armor");
            local PATTERN_STAMINA = L["Match Stat Stamina"]     --Pattern_WrapSpace(ITEM_MOD_STAMINA or "%c%s Stamina");
            local PATTERN_STRENGTH = L["Match Stat Strength"]   --Pattern_WrapSpace(ITEM_MOD_STRENGTH or "%c%s Strength");
            local PATTERN_AGILITY = L["Match Stat Agility"]     --Pattern_WrapSpace(ITEM_MOD_AGILITY or "%c%s Agility");
            local PATTERN_INTELLECT = L["Match Stat Intellect"] --Pattern_WrapSpace(ITEM_MOD_INTELLECT or "%c%s Intellect");
            local PATTERN_SPIRIT = L["Match Stat Spirit"]       --Pattern_WrapSpace(ITEM_MOD_SPIRIT or "%c%s Spirit");

            STATS_PATTERN = {
                dps = PATTERN_DPS,
                armor = PATTERN_ARMOR,
                stamina = PATTERN_STAMINA,
                strength = PATTERN_STRENGTH,
                agility = PATTERN_AGILITY,
                intellect = PATTERN_INTELLECT,
                spirit = PATTERN_SPIRIT,
            };
        end

        local function GetItemStatsFromTooltip()
            if not STATS_PATTERN then
                BuildStatsPattern();
            end

            local numLines = TP:NumLines();
            if numLines == 0 then return end;

            local stats = {};
            local n = 0;

            local fs, text, value;
            for i = 3, numLines do
                fs = _G[TOOLTIP_NAME.."TextLeft"..i];
                if fs then
                    n = n + 1;
                    text = fs:GetText();
                    if text and text ~= " " then
                        for key, pattern in pairs(STATS_PATTERN) do
                            if not stats[key] then
                                value = match(text, pattern);
                                if value then
                                    value = RemoveThousandSeparator(value);
                                    value = tonumber(value) or 0;
                                    if key == "dps" then
                                        value = value * 0.1;
                                    end
                                    stats[key] = value;
                                end
                            end
                        end
                    end
                end
            end

            return stats
        end

        local function AreItemsSameType(item1, item2)
            local classID1, subclassID1 = select(6, GetItemInfoInstant(item1));
            local classID2, subclassID2 = select(6, GetItemInfoInstant(item2));
            return classID1 == classID2 and subclassID1 == subclassID2;
        end

        local function BuildItemComparison(newItemStats, newItem, slotID)
            local equippedItemLink = GetInventoryItemLink("player", slotID);
            if equippedItemLink then
                TP:ClearLines();
                TP:SetOwner(UIParent, "ANCHOR_PRESERVE");
                TP:SetHyperlink(equippedItemLink);
                local equippedItemStats = GetItemStatsFromTooltip();

                if newItemStats and equippedItemStats then
                    local v1;   --new item
                    local v2;   --equipped item
                    local deltaStats;

                    --Show item level diffs
                    v1 = API.GetItemLevel(newItem);
                    v2 = API.GetItemLevel(equippedItemLink);

                    if v1 and v2 and v1 ~= v2 then
                        if not deltaStats then
                            deltaStats = {};
                        end
                        tinsert(deltaStats, FormatValueDiff(v1 - v2, L["Item Level"]));
                    end

                    for _, k in ipairs(STATS_ORDER) do
                        v1 = newItemStats[k] or 0;
                        v2 = equippedItemStats[k] or 0;
                        if v1 ~= v2 then
                            if not deltaStats then
                                deltaStats = {};
                            end
                            tinsert(deltaStats, FormatValueDiff(v1 - v2, STATS_NAME[k]));
                        end
                    end

                    local info = {
                        deltaStats = deltaStats or {},
                        equippedItemLink = equippedItemLink,
                    };

                    return info, AreItemsSameType(newItem, equippedItemLink)
                end
            end
        end

        local function GetItemComparisonInfo(item)
            --Classic
            local _, _, _, itemEquipLoc = GetItemInfoInstant(item);
            local slotID = itemEquipLoc and EQUIPLOC_SLOTID[itemEquipLoc];

            if slotID then
                TP:ClearLines();
                TP:SetOwner(UIParent, "ANCHOR_PRESERVE");
                if type(item) == "number" then
                    TP:SetItemByID(item);
                else
                    TP:SetHyperlink(item);
                end
                local newItemStats = GetItemStatsFromTooltip();
                local item1Info, areItemsSameType = BuildItemComparison(newItemStats, item, slotID);

                local compairsonInfo;
                if item1Info then
                    if not compairsonInfo then
                        compairsonInfo = {};
                    end
                    tinsert(compairsonInfo, item1Info);
                end

                local item2Info;
                if slotID == 11 then
                    item2Info = BuildItemComparison(newItemStats, item, 12);
                elseif slotID == 13 then
                    item2Info = BuildItemComparison(newItemStats, item, 14);
                end

                if item2Info then
                    if not compairsonInfo then
                        compairsonInfo = {};
                    end
                    tinsert(compairsonInfo, item2Info);
                end

                return compairsonInfo, areItemsSameType
            end
        end
        API.GetItemComparisonInfo = GetItemComparisonInfo;
    end


    local ON_USE = ITEM_SPELL_TRIGGER_ONUSE or"Use:";
    local ON_EQUIP = ITEM_SPELL_TRIGGER_ONEQUIP or"Equip:";
    --local ON_PROC = ITEM_SPELL_TRIGGER_ONPROC or"Chance on hit:";

    local ITEMLINK_CACHED = {};

    local function GetItemEffect(itemLink)
        local cached = true;
        local classID, subClassID = select(6, GetItemInfoInstant(itemLink));
        if classID == 4 and subClassID == 0 then
            local tooltipData = addon.TooltipAPI.GetHyperlink(itemLink);
            if tooltipData and tooltipData.lines then
                if not ITEMLINK_CACHED[itemLink] then
                    ITEMLINK_CACHED[itemLink] = true;
                    cached = false;
                end
                local effectText, processed;
                for _, lineData in ipairs(tooltipData.lines) do
                    processed = false;
                    if lineData.leftText then
                        if find(lineData.leftText, ON_USE) then
                            processed = true;
                            if effectText then
                                effectText = effectText.."\n"..lineData.leftText;
                            else
                                effectText = lineData.leftText;
                            end
                        end

                        if (not processed) and find(lineData.leftText, ON_EQUIP) then
                            processed = true;
                            if effectText then
                                effectText = effectText.."\n"..lineData.leftText;
                            else
                                effectText = lineData.leftText;
                            end
                        end
                    end
                end
                return effectText, cached
            end
        end
        return nil, true
    end
    API.GetItemEffect = GetItemEffect;
end

do  -- Items
    local IsEquippableItem = C_Item.IsEquippableItem or IsEquippableItem or AlwaysFalse;
    local IsCosmeticItem = C_Item.IsCosmeticItem or IsCosmeticItem or AlwaysFalse;
    local GetTransmogItemInfo = (C_TransmogCollection and C_TransmogCollection.GetItemInfo) or AlwaysFalse;
    local GetItemLevel = C_Item.GetDetailedItemLevelInfo or GetDetailedItemLevelInfo or AlwaysZero;
    local GetItemInfoInstant = C_Item.GetItemInfoInstant;
    local GetItemInfo = C_Item.GetItemInfo;
    local IsDressableItem = C_Item.IsDressableItemByID or IsDressableItem or AlwaysFalse;
    local GetQuestItemLink = GetQuestItemLink;
    local GetToyInfo = C_ToyBox and C_ToyBox.GetToyInfo or AlwaysNil;

    API.IsEquippableItem = IsEquippableItem;
    API.IsCosmeticItem = IsCosmeticItem;
    API.GetTransmogItemInfo = GetTransmogItemInfo;
    API.GetItemInfo = GetItemInfo;
    API.IsDressableItem = IsDressableItem;

    local function _GetItemLevel(item)
        if item then
            return GetItemLevel(item) or 0
        end
    end
    API.GetItemLevel = _GetItemLevel;

    local function IsItemValidForComparison(itemID)
        return itemID and (not IsCosmeticItem(itemID)) and IsEquippableItem(itemID)
    end
    API.IsItemValidForComparison = IsItemValidForComparison;

    local function GetItemSellPrice(item)
        if item then
            local sellPrice = select(11, GetItemInfo(item));
            if sellPrice and sellPrice > 0 then
                return sellPrice
            end
        end
    end
    API.GetItemSellPrice = GetItemSellPrice;

    local function GetQuestChoiceSellPrice(index)
        local hyperlink = GetQuestItemLink("choice", index);
        if hyperlink and find(hyperlink, "[Ii]tem:") then
            return GetItemSellPrice(hyperlink) or 0
        else
            return 0
        end
    end
    API.GetQuestChoiceSellPrice = GetQuestChoiceSellPrice;

    local function GetItemClassification(item)
        if IsCosmeticItem(item) then
            return "cosmetic"
        end

        local itemID, _, _, _, _, classID, subClassID = GetItemInfoInstant(item);

        if API.IsContainerItem(itemID) then
            return "container"
        end

        if classID == 2 or classID == 4 then
            return "equipment"
        elseif classID == 17 then
            return "pet"
        elseif classID == 15 then
            if subClassID == 2 then
                return "pet"
            elseif subClassID == 5 then
                return "mount"
            end
        end

        local toyItemID = GetToyInfo(itemID);
        if toyItemID then
            return "toy"
        end
    end
    API.GetItemClassification = GetItemClassification;
end

do  -- Keybindings
    local GetBindingKey = GetBindingKey;

    local function GetBestInteractKey()
        local key1, key2 = GetBindingKey("INTERACTTARGET");
        local key, errorText;

        if key1 == "" then key1 = nil; end;
        if key2 == "" then key2 = nil; end;

        if key1 or key2 then
            if key1 then
                if not find(key1, "-") then
                    key = key1;
                end
            end

            if (not key) and key2 then
                if not find(key2, "-") then
                    key = key2;
                end
            end

            if not key then
                errorText = L["Cannot Use Key Combination"];
            end
        else
            errorText = L["Interact Key Not Set"];
        end

        return key, errorText
    end
    API.GetBestInteractKey = GetBestInteractKey;

    API.IsControllerMode = function()
        return addon.GetDBValue("InputDevice") ~= 1
    end
end

do  -- TextureUtil
    local function RemoveIconBorder(texture)
        texture:SetTexCoord(0.0625, 0.9375, 0.0625, 0.9375);
    end
    API.RemoveIconBorder = RemoveIconBorder;
end

do  -- Inventory Bags Container
    local NUM_BAG_SLOTS = 4;
    local GetItemCount = C_Item.GetItemCount or GetItemCount;
    local GetContainerNumSlots = C_Container.GetContainerNumSlots;
    local GetContainerItemID = C_Container.GetContainerItemID;
    local GetContainerItemQuestInfo = C_Container.GetContainerItemQuestInfo;
    local GetContainerItemInfo = C_Container.GetContainerItemInfo;

    local function GetItemBagPosition(itemID)
        local count = GetItemCount(itemID); --unused arg2: Include banks
        if count and count > 0 then 
            for bagID = 0, NUM_BAG_SLOTS do
                for slotID = 1, GetContainerNumSlots(bagID) do
                    if (GetContainerItemID(bagID, slotID) == itemID) then
                        return bagID, slotID
                    end
                end
            end
        end
    end
    API.GetItemBagPosition = GetItemBagPosition;

    local function GetBagQuestItemInfo(itemID)
        --used in Widget_QuestItemDisplay
        local bagID, slotID = GetItemBagPosition(itemID);
        if bagID and slotID then
            local containerInfo = GetContainerItemInfo(bagID, slotID);
            if containerInfo then
                local itemInfo = {};
                itemInfo.isReadable = containerInfo.isReadable;
                itemInfo.hasLoot = containerInfo.hasLoot;
                local questInfo = GetContainerItemQuestInfo(bagID, slotID);
                if questInfo then
                    itemInfo.questID = questInfo.questID;
                    itemInfo.isOnQuest = questInfo.isActive;
                end
                return itemInfo
            end
        end
    end
    API.GetBagQuestItemInfo = GetBagQuestItemInfo;

    local function GetItemLinkInBag(itemID)
        if not itemID then return end;

        local count = GetItemCount(itemID);
        if count and count > 0 then
            for bagID = 0, NUM_BAG_SLOTS do
                for slotID = 1, GetContainerNumSlots(bagID) do
                    if (GetContainerItemID(bagID, slotID) == itemID) then
                        local containerInfo = GetContainerItemInfo(bagID, slotID);
                        if containerInfo then
                            return containerInfo.hyperlink
                        end
                    end
                end
            end

            local GetInventoryItemID = GetInventoryItemID;
            for slotID = 1, 19 do
                if GetInventoryItemID("player", slotID) == itemID then
                    return GetInventoryItemLink("player", slotID)
                end
            end

            return string.format("|Hitem:%d|h", itemID)
        end
    end
    API.GetItemLinkInBag = GetItemLinkInBag;
end

do  -- Spell
    local DoesSpellExist = C_Spell.DoesSpellExist;
    local GetShapeshiftFormID = GetShapeshiftFormID or AlwaysZero;
    local GetCurrentGlyphNameForSpell = GetCurrentGlyphNameForSpell or AlwaysNil;

    API.GetShapeshiftFormID = GetShapeshiftFormID;

    local function GetGlyphIDForSpell(spellID)
        local _, glyphID = GetCurrentGlyphNameForSpell(spellID);
        return glyphID
    end
    API.GetGlyphIDForSpell = GetGlyphIDForSpell;

    if addon.IsToCVersionEqualOrNewerThan(110000) then
        local GetSpellInfo_Table = C_Spell.GetSpellInfo;    --{"name", "rank", "iconID", "castTime", "minRange", "maxRange", "spellID", "originalIconID"}

        local function GetSpellName(spellID)
            local info = spellID and DoesSpellExist(spellID) and GetSpellInfo_Table(spellID);
            if info then
                return info.name
            end

            if spellID then
                return "Unknown Spell: "..spellID
            else
                return "Unknown Spell"
            end
        end
        API.GetSpellName = GetSpellName;
    else
        local GetSpellInfo = GetSpellInfo;

        local function GetSpellName(spellID)
            if spellID and DoesSpellExist(spellID) then
                local name = GetSpellInfo(spellID);
                return name
            else
                if spellID then
                    return "Unknown Spell: "..spellID
                else
                    return "Unknown Spell"
                end
            end
        end
        API.GetSpellName = GetSpellName;
    end
end

do  -- Time -- Date
    local time = time;

    local D_DAYS = D_DAYS or "%d |4Day:Days;";
    local D_HOURS = D_HOURS or "%d |4Hour:Hours;";
    local D_MINUTES = D_MINUTES or "%d |4Minute:Minutes;";
    local D_SECONDS = D_SECONDS or "%d |4Second:Seconds;";

    local DAYS_ABBR = DAYS_ABBR or "%d |4Day:Days;"
    local HOURS_ABBR = HOURS_ABBR or "%d |4Hr:Hr;";
    local MINUTES_ABBR = MINUTES_ABBR or "%d |4Min:Min;";
    local SECONDS_ABBR = SECONDS_ABBR or "%d |4Sec:Sec;";

    local format = string.format;

    local function FormatTime(t, pattern)
        return format(pattern, t)
    end

    local function SecondsToTime(seconds, abbreviated, oneUnit)
        local intialSeconds = seconds;
        local timeString = "";
        local isComplete = false;
        local days = 0;
        local hours = 0;
        local minutes = 0;

        if seconds >= 86400 then
            days = floor(seconds / 86400);
            seconds = seconds - days * 86400;

            local dayText = FormatTime(days, (abbreviated and DAYS_ABBR) or D_DAYS);
            timeString = dayText;

            if oneUnit then
                isComplete = true;
            end
        end

        if not isComplete then
            hours = floor(seconds / 3600);
            seconds = seconds - hours * 3600;

            if hours > 0 then
                local hourText = FormatTime(hours, (abbreviated and HOURS_ABBR) or D_HOURS);
                if timeString == "" then
                    timeString = hourText;
                else
                    timeString = timeString.." "..hourText;
                end

                if oneUnit then
                    isComplete = true;
                end
            else
                if timeString ~= "" and oneUnit then
                    isComplete = true;
                end
            end
        end

        if oneUnit and days > 0 then
            isComplete = true;
        end

        if not isComplete then
            minutes = floor(seconds / 60);
            seconds = seconds - minutes * 60;

            if minutes > 0 then
                local minuteText = FormatTime(minutes, (abbreviated and MINUTES_ABBR) or D_MINUTES);
                if timeString == "" then
                    timeString = minuteText;
                else
                    timeString = timeString.." "..minuteText;
                end
                if oneUnit then
                    isComplete = true;
                end
            else
                if timeString ~= "" and oneUnit then
                    isComplete = true;
                end
            end
        end

        if (not isComplete) and seconds > 0 then
            seconds = floor(seconds);
            local secondText = FormatTime(seconds, (abbreviated and SECONDS_ABBR) or D_SECONDS);
            if timeString == "" then
                timeString = secondText;
            else
                timeString = timeString.." "..secondText;
            end
        end

        if intialSeconds < 0 then
            --WARNING_FONT_COLOR
            timeString = "|cffff4800"..timeString.."|r";
        end

        return timeString
    end
    API.SecondsToTime = SecondsToTime;

    local function SecondsToClock(seconds)
        --Clock: 00:00
        return format("%s:%02d", floor(seconds / 60), floor(seconds % 60))
    end
    API.SecondsToClock = SecondsToClock;


    local REF_TIME;
    local function GetRelativeTime()
        if not REF_TIME then
            REF_TIME = time();
            return 0
        end

        return time() - REF_TIME
    end
    API.GetRelativeTime = GetRelativeTime;
end

do  -- System
    if GetMouseFoci then
        local GetMouseFoci = GetMouseFoci;
        local function GetMouseFocus()
            local objects = GetMouseFoci();
            return objects and objects[1]
        end
        API.GetMouseFocus = GetMouseFocus;
    elseif GetMouseFocus then
        API.GetMouseFocus = GetMouseFocus;
    else
        API.GetMouseFocus = AlwaysNil;
    end

    local function TriggerQuestObjectiveTrackerDirty()
        --(Retail Only) Trigger a "SUPER_TRACKING_CHANGED" so QuestObjectiveTracker removes its popups after QuestObjectiveTrackerMixin:OnEvent
        if not C_SuperTrack then return end;

        local oldWaypoint C_Map.GetUserWaypoint();
        local hasWaypoints = oldWaypoint ~= nil;
        local isTracking = hasWaypoints and C_SuperTrack.IsSuperTrackingUserWaypoint();

        C_QuestLog.AddQuestWatch(0);
        if not hasWaypoints then
            oldWaypoint = {
                uiMapID = 84,
                position = {
                    x = 0.5,
                    y = 0.5,
                },
            };

            C_Map.SetUserWaypoint(oldWaypoint);
        end

        C_SuperTrack.SetSuperTrackedUserWaypoint(not isTracking);

        if hasWaypoints then
            C_SuperTrack.SetSuperTrackedUserWaypoint(isTracking);
        else
            C_Map.ClearUserWaypoint();
        end
    end
    API.TriggerQuestObjectiveTrackerDirty = TriggerQuestObjectiveTrackerDirty;

    local function RemoveQuestObjectiveTrackerQuestPopUp(questID)
        --QuestObjectiveTracker:RemoveAutoQuestPopUp() isn't safe
        --AutoQuest is usually auto-tracked, we change the tracking status to trigger "QUEST_WATCH_LIST_CHANGED";
        if not C_QuestLog.GetQuestWatchType then return end;

        local watchType = C_QuestLog.GetQuestWatchType(questID);
        local isWatched = watchType ~= nil;
        if isWatched then
            C_QuestLog.RemoveQuestWatch(questID);
            C_QuestLog.AddQuestWatch(questID);
        else
            C_QuestLog.AddQuestWatch(questID);
            C_QuestLog.RemoveQuestWatch(questID);
        end
    end
    API.RemoveQuestObjectiveTrackerQuestPopUp = RemoveQuestObjectiveTrackerQuestPopUp;
end

do  -- Zone -- Location -- Area
    local function GetZoneName(areaID)
        return C_Map.GetAreaInfo(areaID)
    end
    API.GetZoneName = GetZoneName;
end

do  -- Dev Tool
    local DEV_MODE = false;

    if not DEV_MODE then return end;

    local GetQuestIDForLogIndex = C_QuestLog.GetQuestIDForLogIndex;
    local GetQuestInfo = C_QuestLog.GetInfo;

    local function GetNumQuestCanAccept()
        --numQuests include all types of quests.
        --(Account/Daily) quests don't count towards MaxQuest(35)
        if not MAX_QUESTS then
            MAX_QUESTS = C_QuestLog.GetMaxNumQuestsCanAccept();
        end

        local numShownEntries, numAllQuests = GetNumQuestLogEntries();
        local numQuests = 0;
        local questID;

        for i = 1, numShownEntries do
            questID = GetQuestIDForLogIndex(i);
            if questID ~= 0 then
                print(i, questID)
            end
            if questID ~= 0 and not API.IsAccountQuest(questID) then
                local info = GetQuestInfo(i);
                if info and (not (info.isHidden or info.isHeader)) and info.frequency == 1 then
                    numAllQuests = numAllQuests - 1;
                end
            end
        end

        return MAX_QUESTS - numAllQuests, MAX_QUESTS
    end

    local function TooltipAddInfo(tooltip, info, key)
        tooltip:AddDoubleLine(key, tostring(info[key]));
    end

    local QuestInfoFields = {
        "questID", "campaignID", "frequency", "isHeader", "isTask", "isBounty", "isStory", "isAutoComplete",
    };

    local function QuestMapLogTitleButton_OnEnter_Callback(_, button, questID)
        local tooltip = GameTooltip;
        if not tooltip:IsShown() then return end;

        local info = C_QuestLog.GetInfo(button.questLogIndex);

        for _, key in ipairs(QuestInfoFields) do
            TooltipAddInfo(tooltip, info, key)
        end
        tooltip:AddDoubleLine("Account", tostring(API.IsAccountQuest(questID)));
        tooltip:AddDoubleLine("isCalling", tostring(C_QuestLog.IsQuestCalling(questID)));
        tooltip:AddDoubleLine("QuestType", C_QuestLog.GetQuestType(questID));
        tooltip:AddDoubleLine("isRepeatable", tostring(C_QuestLog.IsRepeatableQuest(questID)));

        tooltip:Show();
    end

    EventRegistry:RegisterCallback("QuestMapLogTitleButton.OnEnter", QuestMapLogTitleButton_OnEnter_Callback, nil);
end