-- ============================================================
-- ESP + MENU ONLY (Health Bar fix + Line stability)
-- Uses Main OB Widget for Name, Distance, and Health Bar
-- No extra horizontal bar, no forced colors
-- Line toggle is independent from OB card refresh.
-- Match cache is rebuilt on pawn/session transitions and live pawn snapshots.
-- ============================================================

-- No early-return per-match guard.
-- The ESP state is explicitly re-synchronized when the local pawn changes
-- or when the pawn list is unloaded between matches.
-- Global toggles (default: all on)
if _G.Mod_ESP_Line_Enabled == nil then _G.Mod_ESP_Line_Enabled = true end
if _G.Mod_ESP_Health_Enabled == nil then _G.Mod_ESP_Health_Enabled = true end
if _G.Mod_ESP_NameDist_Enabled == nil then _G.Mod_ESP_NameDist_Enabled = true end

_G.CheatsEnabled = true

-- ============================================================
-- REQUIRED IMPORTS
-- ============================================================
local require = require
local import  = import
local isValid = slua.isValid
local pcall = pcall
local type = type
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local math = math
local string = string

local function safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

local SecurityCommonUtils = safe_require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
local KismetMathLibrary = import("KismetMathLibrary")
local SlateBlueprintLibrary = import("SlateBlueprintLibrary")
local UIUtil = safe_require("client.common.ui_util")
local InGameUITools = safe_require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
local time_ticker = safe_require("common.time_ticker")

local OBUI_Library = nil
pcall(function() OBUI_Library = import("/Game/BluePrints/UI/OBUI/Lib/OBUI_Library.OBUI_Library_C") end)
local WidgetLayoutLibrary = nil
pcall(function() WidgetLayoutLibrary = import("WidgetLayoutLibrary") end)
local FVector2DClass = _G.FVector2D
local game_frontend_hud = nil
pcall(function() game_frontend_hud = require("game_frontend_hud") end)

-- ============================================================
-- ESP STATE
-- ============================================================
local OB_WIDGET_PATH = "/Game/BluePrints/UI/OBUI/Item/OB_PlayerHeadHPItem_UIBP.OB_PlayerHeadHPItem_UIBP"
local OB_WIDGET_ZORDER = 10700

-- Cleanup previous ESP state
local oldOBState = rawget(_G, "__OB_ESP_WIDGETS_V1")
if oldOBState and oldOBState.Widgets then
    for _,widget in pairs(oldOBState.Widgets) do
        pcall(function() if widget.SetWidgetVisibility then widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end end)
        pcall(function() if widget.RemoveFromParent then widget:RemoveFromParent() end end)
    end
end

local OBWidgetState = {Widgets={}, Data={}, CountBox=nil}
_G.__OB_ESP_WIDGETS_V1 = OBWidgetState

-- Stop previous timers
pcall(function()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if isValid(pc) then
        local oldTimers = {
            "_ESPTimerHandle",
            "_ESPLineTimerHandle",
            "_HeavyESPTimer",
        }
        for _, key in ipairs(oldTimers) do
            local handle = rawget(_G, key)
            if handle then
                if pc.RemoveGameTimer then
                    pcall(function() pc:RemoveGameTimer(handle) end)
                end
            end
            rawset(_G, key, nil)
        end
    end
end)

-- Global state for lines
local GLOBAL_LINE_STATE = "__ESP_LINE_STATE_V1"
local oldLineState = rawget(_G, GLOBAL_LINE_STATE)
if oldLineState then
    pcall(function()
        if oldLineState.LineTimer then
            time_ticker.RemoveTimer(oldLineState.LineTimer)
        end
    end)
    pcall(function()
        if oldLineState.Lines then
            for _, line in pairs(oldLineState.Lines) do
                if line then
                    if line.Close then
                        line:Close()
                    elseif line.UIRoot and line.UIRoot.SetWidgetVisibility then
                        line.UIRoot:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    end
                end
            end
        end
    end)
end

local LineState = {
    LineTimer = nil,
    Lines = {},
    Started = false,
    Generation = os.clock()
}
_G[GLOBAL_LINE_STATE] = LineState

local cachedPawns = {}
local lastPawnRefresh = 0
local enemyLineCache = LineState.Lines

-- ============================================================
-- MATCH / CACHE LIFECYCLE
-- Prevents second-match and mid-match stale UMG/line state.
-- ============================================================
local MatchState = {
    Controller = nil,
    Pawn = nil,
    EmptyFrames = 0,
    Generation = 0
}

local ESPDebug = {
    Controller = false, Pawn = false, HUD = false, Root = false,
    Project = false, Viewport = false, Config = false,
    LineCreate = false, LineUpdate = false,
    EnemyCount = 0, PlayerCount = 0, BotCount = 0, LineCount = 0,
    LastMethod = "NONE", LastError = "NONE",
    TargetState = "NONE",
    ActorX = 0, ActorY = 0, ActorZ = 0,
    ScreenX = 0, ScreenY = 0,
    LocalX = 0, LocalY = 0,
    RootW = 0, RootH = 0,
    StartX = 0, StartY = 0,
    EndX = 0, EndY = 0,
    LineLength = 0, LineAngle = 0,
    CreateAttempts = 0, FastTickCount = 0, LastFastTick = 0,
    TimerMode = "NONE",
    OBWidget = false, OBVisible = false, OBAdded = false,
    HPFound = false, OBUpdate = false,
    OBCardX = 0, OBCardY = 0, MatchGeneration = 0
}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
local function IsOBWidgetValid(w)
    if not w then return false end
    local ok=false
    pcall(function() if slua and slua.isValid then ok=slua.isValid(w) end end)
    if ok then return true end
    pcall(function() ok=isValid(w) end)
    return ok
end

local function RemoveOBWidget(key)
    local w=OBWidgetState.Widgets[key]
    if w then
        pcall(function() if w.SetWidgetVisibility then w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end end)
        pcall(function() if w.RemoveFromParent then w:RemoveFromParent() end end)
    end
    OBWidgetState.Widgets[key]=nil
    OBWidgetState.Data[key]=nil
end

local function IsBotOrAI(pawn)
    local result = false
    local function test(v)
        if v == true or v == 1 then result = true end
    end
    pcall(function() if Game and Game.IsAI then test(Game:IsAI(pawn)) end end)
    if result then return true end
    pcall(function() if Game and Game.IsBot then test(Game:IsBot(pawn)) end end)
    if result then return true end
    pcall(function() if pawn and pawn.IsAI then test(pawn:IsAI()) end end)
    if result then return true end
    pcall(function() if pawn and pawn.IsBot then test(pawn:IsBot()) end end)
    if result then return true end
    pcall(function() test(pawn and pawn.bIsAI) end)
    if result then return true end
    pcall(function() test(pawn and pawn.bIsBot) end)
    if result then return true end
    pcall(function()
        local ps = pawn and pawn.PlayerState
        if isValid(ps) then
            if ps.IsAI then test(ps:IsAI()) end
            if ps.IsBot then test(ps:IsBot()) end
            test(ps.bIsAI)
            test(ps.bIsBot)
        end
    end)
    return result
end

local function IsPawnAlive(pawn)
    if not isValid(pawn) then return false end
    if pawn.HealthStatus then
        return SecurityCommonUtils.IsHealthStatusAlive(pawn.HealthStatus)
    end
    if pawn.IsAlive then return pawn:IsAlive() end
    if pawn.GetHealth then return (pawn:GetHealth() or 0) > 0 end
    return false
end

local function GetTeamID(pawn)
    local teamID = 0
    pcall(function()
        if pawn.TeamID ~= nil then teamID = pawn.TeamID end
    end)
    if teamID == 0 then
        pcall(function()
            local ps = pawn.PlayerState
            if isValid(ps) and ps.TeamID ~= nil then teamID = ps.TeamID end
        end)
    end
    return teamID
end

local function GetPlayerName(pawn)
    local name = nil
    pcall(function()
        if pawn.PlayerName ~= nil then
            local v = tostring(pawn.PlayerName)
            if v ~= "" and v ~= "Player Name" and v ~= "UNKNOWN" then name = v end
        end
    end)
    if not name then
        pcall(function()
            local ps = pawn.PlayerState
            if isValid(ps) then
                if ps.PlayerName ~= nil then
                    local v = tostring(ps.PlayerName)
                    if v ~= "" and v ~= "Player Name" and v ~= "UNKNOWN" then name = v end
                elseif ps.PlayerNameText ~= nil then
                    local v = tostring(ps.PlayerNameText)
                    if v ~= "" and v ~= "Player Name" and v ~= "UNKNOWN" then name = v end
                end
            end
        end)
    end
    if not name then
        pcall(function()
            if pawn.GetPlayerNameSafety then
                local v = pawn:GetPlayerNameSafety()
                if v ~= nil then
                    v = tostring(v)
                    if v ~= "" and v ~= "Player Name" and v ~= "UNKNOWN" then name = v end
                end
            end
        end)
    end
    return name or "UNKNOWN"
end

local function GetHealthInfo(pawn)
    local hpPercent = 0
    local isKnock = false
    pcall(function()
        local hp = pawn.Health
        local maxHp = pawn.HealthMax
        if hp and maxHp and maxHp > 0 and hp > 0 then
            hpPercent = hp / maxHp
        else
            isKnock = true
        end
    end)
    if hpPercent <= 0 then
        pcall(function()
            local ps = pawn.PlayerState
            if isValid(ps) then
                if ps.GetPlayerHealthPercent then
                    local value = ps:GetPlayerHealthPercent() or 0
                    if value > 0 then
                        hpPercent = value
                        isKnock = false
                    elseif ps.GetBreathPercentage then
                        hpPercent = ps:GetBreathPercentage() or 0
                        isKnock = true
                    end
                end
            end
        end)
    end
    hpPercent = math.max(0, math.min(1, hpPercent))
    return hpPercent, isKnock
end

local function GetOBCardWorldPos(enemy)
    local pos=nil
    pcall(function()
        if enemy.GetBonePos then
            pos=enemy:GetBonePos("head",{X=0,Y=0,Z=0})
        end
    end)
    if pos and not(pos.X==0 and pos.Y==0) then
        -- Keep the card directly above the enemy head.
        pos.Z = pos.Z + 18
        return pos
    end
    pcall(function() pos=enemy:K2_GetActorLocation() end)
    if pos then pos.Z=pos.Z+108 end
    return pos
end

-- Keep the OB card clean: hide only marker/dot images inside the card widget.
local function HideOBCardMarkers(w)
    if not w then return end

    -- Hide marker/dot elements from the supplied OB widget.
    local markerNames={
        "Image_Dot","Image_Point","Image_Marker","Image_Head",
        "Image_HeadPoint","Image_HeadMarker","Image_TargetPoint",
        "Image_Target","Image_PointMarker",
        "CanvasPanel_Dot","CanvasPanel_Point","CanvasPanel_Marker",
        "CanvasPanel_TargetPoint","CanvasPanel_Target"
    }
    for _,name in ipairs(markerNames) do
        pcall(function()
            local obj=w[name]
            if obj and obj.SetWidgetVisibility then
                obj:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
        end)
    end

    -- Remove decorative card/box backgrounds while keeping text + HP bar.
    local bgNames={
        "Image_Name_BG","Image_BG","Image_Background",
        "Image_NameBG","Image_PlayerBG","Image_CardBG",
        "Image_Box","Image_Border","Image_Frame",
        "Border_Name","Border_BG","Border_Background",
        "Border_Box","Border_Frame",
        "CanvasPanel_NameBG","CanvasPanel_Background",
        "CanvasPanel_Box","CanvasPanel_Frame",
        "SizeBox_Background","Overlay_Background"
    }
    for _,name in ipairs(bgNames) do
        pcall(function()
            local obj=w[name]
            if obj and obj.SetWidgetVisibility then
                obj:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
        end)
    end
end

local function GetMainControlUI()
    local rootUI = nil
    pcall(function() rootUI = InGameUITools.GetMainControlBaseUI() end)
    return rootUI
end

-- ============================================================
-- FEATURE: COUNT BOX (Player/Bot count)
-- ============================================================
local function GetCountBox(rootUI)
    local box = OBWidgetState.CountBox
    if IsOBWidgetValid(box) then return box end
    box = nil
    pcall(function() if slua and slua.loadUI then box=slua.loadUI(OB_WIDGET_PATH) end end)
    if not IsOBWidgetValid(box) then return nil end
    local added=false
    pcall(function()
        if game_frontend_hud and game_frontend_hud.AddToContainer and UIContainers and UIContainers.Top then
            game_frontend_hud.AddToContainer(UIContainers.Top,box,OB_WIDGET_ZORDER+20)
            added=true
        end
    end)
    if not added then
        pcall(function()
            local fh=require('game_frontend_hud')
            if fh and fh.AddToContainer and UIContainers and UIContainers.Top then
                fh.AddToContainer(UIContainers.Top,box,OB_WIDGET_ZORDER+20)
                added=true
            end
        end)
    end
    if not added then
        pcall(function() if box.RemoveFromParent then box:RemoveFromParent() end end)
        return nil
    end
    local function vis(w,v)
        pcall(function()
            if w and w.SetWidgetVisibility then
                w:SetWidgetVisibility(v and UEnums.ESlateVisibility.SelfHitTestInvisible or UEnums.ESlateVisibility.Collapsed)
            end
        end)
    end
    for _,w in ipairs({
        box.TextBlock_Teammate_Name,box.TextBlock_TeamName,box.TextBlock_TeamID,
        box.TextBlock_PlayerTeamID,box.TextBlock_TeamIndex,box.TextBlock_Distance,
        box.Text_Distance,box.TextBlock_Dist,box.Text_Dist,box.TextBlock_PlayerDistance,
        box.Text_PlayerDistance,box.TextBlock_HP,box.Text_HP,box.TextBlock_Health,
        box.Text_Health,box.TextBlock_PlayerHP,box.Text_PlayerTeam,box.Image_TeamLogoBegin,
        box.Image_TeamLogoBG2,box.Image_TeamBG_2,box.Image_TeamBG,box.Image_WeaponIcon,box.Image_Weapon
    }) do
        vis(w,false)
    end
    local bg=box.Image_Name_BG or box.Image_BG or box.Image_Background
    local txt=box.TextBlock_PlayerName or box.Text_PlayerName
    if bg then
        vis(bg,true)
        pcall(function() if bg.SetColorAndOpacity then bg:SetColorAndOpacity(FLinearColor(1,1,1,1)) end end)
    end
    if txt then
        vis(txt,true)
        pcall(function() if txt.SetColorAndOpacity then txt:SetColorAndOpacity(FLinearColor(0.05,0.05,0.05,1)) end end)
    end
    local slot=nil
    pcall(function() if WidgetLayoutLibrary and WidgetLayoutLibrary.SlotAsCanvasSlot then slot=WidgetLayoutLibrary.SlotAsCanvasSlot(box) end end)
    if slot then
        pcall(function() slot:SetAlignment(FVector2DClass(0.5,0)); slot:SetPosition(FVector2DClass(0,4)); slot:SetSize(FVector2DClass(190,26)) end)
    end
    OBWidgetState.CountBox=box
    return box
end

local function UpdateCountBox(rootUI,playerCount,botCount)
    local box=GetCountBox(rootUI)
    if not box then return nil end
    local txt=box.TextBlock_PlayerName or box.Text_PlayerName
    if txt then
        pcall(function()
            txt:SetText(string.format('PLAYER: %d    BOT: %d',playerCount or 0,botCount or 0))
        end)
    end
    pcall(function() if box.SetWidgetVisibility then box:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end end)
    return box
end

-- ============================================================
-- FEATURE: MAIN OB WIDGET (Core enemy card)
-- ============================================================
local function GetOBWidget(key)
    local w=OBWidgetState.Widgets[key]
    if IsOBWidgetValid(w) then return w end
    w=nil
    pcall(function() if slua and slua.loadUI then w=slua.loadUI(OB_WIDGET_PATH) end end)
    if not IsOBWidgetValid(w) then
        ESPDebug.LastError="OB_WIDGET_LOAD_FAILED"
        return nil
    end
    local added=false
    pcall(function()
        if game_frontend_hud and game_frontend_hud.AddToContainer and UIContainers and UIContainers.Top then
            game_frontend_hud.AddToContainer(UIContainers.Top,w,OB_WIDGET_ZORDER)
            added=true
        end
    end)
    if not added then
        pcall(function()
            local fh=require("game_frontend_hud")
            if fh and fh.AddToContainer and UIContainers and UIContainers.Top then
                fh.AddToContainer(UIContainers.Top,w,OB_WIDGET_ZORDER)
                added=true
            end
        end)
    end
    if not added then
        ESPDebug.LastError="OB_ADD_TO_CONTAINER_FAILED"
        return nil
    end
    OBWidgetState.Widgets[key]=w
    ESPDebug.OBWidget=true
    ESPDebug.OBAdded=true
    return w
end

local function ProjectOBCard(pc,rootUI,enemy)
    local world=GetOBCardWorldPos(enemy)
    if not world then return nil end
    local viewport=nil
    pcall(function() viewport=UIUtil.GetViewportSize() end)
    if not viewport or viewport.X<=0 or viewport.Y<=0 then return nil end
    local screen=FVector2DClass(0,0)
    local ok=false
    pcall(function() ok=pc:ProjectWorldLocationToScreen(world,screen,false) end)
    if not ok then return nil end
    if screen.X < -100 or screen.X > viewport.X+100 or screen.Y < -100 or screen.Y > viewport.Y+100 then return nil end
    local geom=nil
    pcall(function() geom=rootUI:GetCachedGeometry() end)
    if not geom then return nil end
    local size=nil
    pcall(function() size=SlateBlueprintLibrary.GetLocalSize(geom) end)
    if not size or size.X<=0 or size.Y<=0 then return nil end
    local localPos=FVector2DClass(screen.X/viewport.X*size.X,screen.Y/viewport.Y*size.Y)
    ESPDebug.OBCardX=localPos.X
    ESPDebug.OBCardY=localPos.Y
    return localPos
end

local function ApplyOBTeamColor(w,teamID)
    local root=w and (w.UIRoot or w)
    if not root then return end
    local teamColor=nil
    local nameColor=nil
    pcall(function() if OBUI_Library and OBUI_Library.GetPlayerLinearColorByTeamID then teamColor=OBUI_Library.GetPlayerLinearColorByTeamID(teamID,root) end end)
    pcall(function() if OBUI_Library and OBUI_Library.GetPlayerNameLinearColorByTeamID then nameColor=OBUI_Library.GetPlayerNameLinearColorByTeamID(teamID,root) end end)
    if teamColor then
        for _,bg in ipairs({w.Image_TeamLogoBegin,w.Image_TeamLogoBG2,w.Image_TeamBG_2,w.Image_TeamBG}) do
            pcall(function() if bg and bg.SetColorAndOpacity then bg:SetColorAndOpacity(teamColor) end end)
        end
    end
    if nameColor then
        for _,txt in ipairs({w.TextBlock_PlayerName,w.Text_PlayerName,w.TextBlock_Teammate_Name,w.TextBlock_TeamName}) do
            pcall(function() if txt and txt.SetColorAndOpacity then txt:SetColorAndOpacity(nameColor) end end)
        end
    end
    -- Remove background images (no white background)
    for _,bg in ipairs({
        w.Image_Name_BG,w.Image_BG,w.Image_Background,
        w.Image_NameBG,w.Image_PlayerBG,w.Image_CardBG,
        w.Image_Box,w.Image_Border,w.Image_Frame
    }) do
        pcall(function()
            if bg and bg.SetWidgetVisibility then
                bg:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
        end)
    end
end

-- Set name and distance on main widget (uses native OB widget colors - NO FORCE)
local function ApplyOBNameDist(w, name, dist)
    if not w then return end
    -- Find the name text widget
    local nameText = w.TextBlock_PlayerName or w.Text_PlayerName or w.TextBlock_Teammate_Name
    if nameText then
        pcall(function()
            if nameText.SetWidgetVisibility then
                nameText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end
        end)
        pcall(function()
            if nameText.SetText then
                local distStr = string.format("%dm", math.floor(dist + 0.5))
                nameText:SetText(string.format("%s   %s", tostring(name or "Enemy"), distStr))
            end
        end)
        -- NO FORCE COLOR HERE - Uses widget's default/native color
    end
    -- Also set distance text (some widgets have separate distance text)
    local distText = w.TextBlock_Distance or w.Text_Distance or w.TextBlock_Dist or w.Text_Dist or w.TextBlock_PlayerDistance
    if distText then
        pcall(function()
            if distText.SetWidgetVisibility then
                distText:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
        end)
    end
    -- Hide other text elements, but KEEP TEAM ID visible.
    for _,txt in ipairs({
        w.TextBlock_TeamName,
        w.TextBlock_TeamIndex, w.TextBlock_PlayerName, w.Text_PlayerName,
        w.TextBlock_Teammate_Name, w.Text_PlayerTeam,
        w.TextBlock_HP, w.Text_HP, w.TextBlock_Health, w.Text_Health,
        w.TextBlock_PlayerHP, w.Text_PlayerHP
    }) do
        if txt and txt ~= nameText then
            pcall(function()
                if txt.SetWidgetVisibility then
                    txt:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                end
            end)
        end
    end
end

-- Health bar on main widget (improved to find any progress bar)
local function ApplyOBHP(w, hp, knock)
    if not w then return end
    hp = math.max(0, math.min(1, hp or 0))
    local fill = knock and FLinearColor(1,0,0,1)
        or (hp < 0.30 and FLinearColor(1,0,0,1)
        or (hp < 0.70 and FLinearColor(1,1,0,1)
        or FLinearColor(0,1,0,1)))
    local found = false
    -- List of possible progress bar names
    local barNames = {
        "ProgressBar_HP", "ProgressBar_0", "ProgressBar_PlayerHP",
        "ProgressBar_Health", "ProgressBar_PlayerHealth",
        "ProgressBar_HPBar", "ProgressBar_HealthBar",
        "ProgressBar_Health1", "ProgressBar_Health2"
    }
    for _, name in ipairs(barNames) do
        local bar = w[name]
        if bar then
            found = true
            ESPDebug.HPFound = true
            pcall(function() if bar.SetWidgetVisibility then bar:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end end)
            pcall(function() if bar.SetPercent then bar:SetPercent(hp) end end)
            pcall(function() if bar.SetFillColorAndOpacity then bar:SetFillColorAndOpacity(fill) end end)
            pcall(function() if bar.SetRenderOpacity then bar:SetRenderOpacity(1.0) end end)
        end
    end
    if not found then
        pcall(function()
            local ProgressBarClass = import("ProgressBar")
            if ProgressBarClass and w.GetComponentsByClass then
                local comps = w:GetComponentsByClass(ProgressBarClass)
                if comps and comps.Num then
                    for i = 0, comps:Num() - 1 do
                        local bar = comps:Get(i)
                        if bar then
                            found = true
                            ESPDebug.HPFound = true
                            pcall(function() if bar.SetWidgetVisibility then bar:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end end)
                            pcall(function() if bar.SetPercent then bar:SetPercent(hp) end end)
                            pcall(function() if bar.SetFillColorAndOpacity then bar:SetFillColorAndOpacity(fill) end end)
                            pcall(function() if bar.SetRenderOpacity then bar:SetRenderOpacity(1.0) end end)
                        end
                    end
                end
            end
        end)
    end
    if not found then
        ESPDebug.LastError = "OB_HP_WIDGET_NOT_FOUND"
    end
end

local function ApplyOBTeamID(w, teamID)
    if not w then return end
    local teamTextList = {
        w.TextBlock_TeamID,
        w.TextBlock_PlayerTeamID
    }
    local text = tostring(teamID or 0)
    for _,txt in ipairs(teamTextList) do
        pcall(function()
            if txt and txt.SetText then
                txt:SetText(text)
            end
            if txt and txt.SetWidgetVisibility then
                txt:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end
        end)
    end
end

local function HideOBNameDist(w)
    if not w then return end
    local names = {
        w.TextBlock_PlayerName, w.Text_PlayerName, w.TextBlock_Teammate_Name,
        w.TextBlock_TeamName, w.TextBlock_Distance, w.Text_Distance,
        w.TextBlock_Dist, w.Text_Dist, w.TextBlock_PlayerDistance,
        w.Text_PlayerDistance
    }
    for _,txt in ipairs(names) do
        pcall(function()
            if txt and txt.SetWidgetVisibility then
                txt:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
        end)
    end
    -- Hide only the NAME/DISTANCE background/container. Keep Team ID and HP independent.
    local bg = {
        w.Image_Name_BG, w.Image_NameBG, w.Image_PlayerBG,
        w.Image_CardBG, w.Image_Box, w.Image_Border, w.Image_Frame
    }
    for _,v in ipairs(bg) do
        pcall(function()
            if v and v.SetWidgetVisibility then
                v:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
        end)
    end
end

local function HideOBCardContainer(w)
    if not w then return end
    local parts = {
        w.Image_Name_BG, w.Image_NameBG, w.Image_PlayerBG,
        w.Image_CardBG, w.Image_Box, w.Image_Border, w.Image_Frame,
        w.Image_Background
    }
    for _,v in ipairs(parts) do
        pcall(function()
            if v and v.SetWidgetVisibility then
                v:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
        end)
    end
end

local function ShowOBNameDistArea(w)
    if not w then return end
    -- Keep the card container/background permanently hidden.
    -- Only the actual name/distance text is shown.
    local bg = {
        w.Image_Name_BG, w.Image_NameBG, w.Image_PlayerBG,
        w.Image_CardBG, w.Image_Box, w.Image_Border, w.Image_Frame,
        w.Image_Background
    }
    for _,v in ipairs(bg) do
        pcall(function()
            if v and v.SetWidgetVisibility then
                v:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
        end)
    end
    local nameText = w.TextBlock_PlayerName or w.Text_PlayerName or w.TextBlock_Teammate_Name
    pcall(function()
        if nameText and nameText.SetWidgetVisibility then
            nameText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end
    end)
end

local function UpdateOBCard(enemy,pc,rootUI,name,teamID,dist,hp,knock,forceData)
    local key=enemy
    local w=GetOBWidget(key)
    if not w then return end

    -- Rebind the native OB widget to the current pawn every refresh so the
    -- card cannot retain a previous player's text/target after respawn/round reset.
    pcall(function() if w.InitData then w:InitData(enemy) end end)
    pcall(function()
        if w.SetSavedPlayerCharacter then
            w:SetSavedPlayerCharacter(enemy)
        elseif w.UIRoot and w.UIRoot.SetSavedPlayerCharacter then
            w.UIRoot:SetSavedPlayerCharacter(enemy)
        end
    end)

    local pos=ProjectOBCard(pc,rootUI,enemy)
    if not pos then
        pcall(function() if w.SetWidgetVisibility then w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end end)
        ESPDebug.OBVisible=false
        ESPDebug.OBUpdate=false
        return false
    end
    local slot=nil
    pcall(function()
        if WidgetLayoutLibrary and WidgetLayoutLibrary.SlotAsCanvasSlot then
            slot=WidgetLayoutLibrary.SlotAsCanvasSlot(w)
        end
    end)
    if not slot then
        ESPDebug.LastError="OB_CANVAS_SLOT_FAIL"
        ESPDebug.OBVisible=false
        return
    end
    pcall(function()
        -- Bottom-center of the card sits on the projected head point,
        -- keeping the entire name/HP card centered horizontally above the head.
        slot:SetAlignment(FVector2DClass(0.5,0.5))
        slot:SetPosition(pos)
    end)

    -- Do not show a default point/dot from the OB card itself.
    HideOBCardMarkers(w)
    pcall(function()
        if w.GetOpacityByDistance then
            w:SetRenderOpacity(w:GetOpacityByDistance(dist * 100.0))
        else
            w:SetRenderOpacity(1.0)
        end
    end)
    ApplyOBTeamColor(w, teamID)
    -- Re-apply marker/background cleanup after native team-color updates.
    HideOBCardMarkers(w)
    -- TEAM ID is always shown, independent of Name/Distance toggle.
    ApplyOBTeamID(w, teamID)

    -- Health bar (if toggle on)
    if _G.Mod_ESP_Health_Enabled then
        ApplyOBHP(w, hp, knock)
    else
        local barNames = {
            "ProgressBar_HP", "ProgressBar_0", "ProgressBar_PlayerHP",
            "ProgressBar_Health", "ProgressBar_PlayerHealth",
            "ProgressBar_HPBar", "ProgressBar_HealthBar"
        }
        for _, name in ipairs(barNames) do
            local bar = w[name]
            if bar then
                pcall(function() if bar.SetWidgetVisibility then bar:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end end)
            end
        end
        pcall(function()
            local ProgressBarClass = import("ProgressBar")
            if ProgressBarClass and w.GetComponentsByClass then
                local comps = w:GetComponentsByClass(ProgressBarClass)
                if comps and comps.Num then
                    for i = 0, comps:Num() - 1 do
                        local bar = comps:Get(i)
                        if bar then
                            pcall(function() if bar.SetWidgetVisibility then bar:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end end)
                        end
                    end
                end
            end
        end)
    end

    pcall(function()
        if w.OnDistanceModeChanged then
            w:OnDistanceModeChanged(dist >= 100 and 1 or 0, teamID)
        end
    end)

    -- Re-apply TEAM ID after widget callbacks so it cannot be hidden/reset.
    ApplyOBTeamID(w, teamID)

    -- Apply Name/Distance visibility LAST. The widget may rebuild its text during
    -- InitData/SetSavedPlayerCharacter/OnDistanceModeChanged, so doing it here
    -- prevents the name from reappearing when the toggle is OFF.
    if _G.Mod_ESP_NameDist_Enabled then
        ShowOBNameDistArea(w)
        ApplyOBNameDist(w, name, dist)
    else
        HideOBNameDist(w)
    end

    -- Always remove the native gray card/container layer.
    -- Name/Distance text, Team ID and HP remain independent.
    HideOBCardContainer(w)
    -- Final Team ID pass: keep Team ID visible even after container cleanup.
    ApplyOBTeamID(w, teamID)

    pcall(function()
        if w.SetWidgetVisibility then
            w:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end
    end)
    ESPDebug.OBWidget=true
    ESPDebug.OBVisible=true
    ESPDebug.OBUpdate=true
    return true
end

-- ============================================================
-- FEATURE: ESP LINE (Mortar Line) - Stability Fixes
-- ============================================================
local function IsMortarLineValid(line)
    if not line then return false end
    local root = nil
    pcall(function() root = line.UIRoot end)
    if not root then return false end
    local ok = false
    pcall(function() ok = isValid(root) end)
    return ok
end

local function SetMortarLineVisible(line, visible)
    if not line then return end
    pcall(function()
        if line.UIRoot and line.UIRoot.SetWidgetVisibility then
            line.UIRoot:SetWidgetVisibility(visible and UEnums.ESlateVisibility.SelfHitTestInvisible or UEnums.ESlateVisibility.Collapsed)
        end
    end)
    pcall(function()
        local airline = line.UIRoot and line.UIRoot.CanvasPanel_Airline
        if airline then
            airline:SetWidgetVisibility(visible and UEnums.ESlateVisibility.SelfHitTestInvisible or UEnums.ESlateVisibility.Collapsed)
        end
    end)
end

local function ResetMatchCaches(reason)
    -- Hide and destroy all cached enemy lines.
    for pawn, line in pairs(enemyLineCache) do
        pcall(function() SetMortarLineVisible(line, false) end)
        pcall(function() if line and line.Close then line:Close() end end)
        enemyLineCache[pawn] = nil
        LineState.Lines[pawn] = nil
    end

    -- Destroy every cached enemy OB widget so no old match card survives.
    local keys = {}
    for key, _ in pairs(OBWidgetState.Widgets) do
        keys[#keys + 1] = key
    end
    for _, key in ipairs(keys) do
        RemoveOBWidget(key)
    end

    if OBWidgetState.CountBox then
        pcall(function()
            if OBWidgetState.CountBox.SetWidgetVisibility then
                OBWidgetState.CountBox:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
            if OBWidgetState.CountBox.RemoveFromParent then
                OBWidgetState.CountBox:RemoveFromParent()
            end
        end)
    end

    OBWidgetState.Widgets = {}
    OBWidgetState.Data = {}
    OBWidgetState.CountBox = nil
    cachedPawns = {}
    lastPawnRefresh = 0
    MatchState.Generation = (MatchState.Generation or 0) + 1
    ESPDebug.LastError = reason or "MATCH_CACHE_RESET"
end

local function SyncMatchLifecycle(controller, currentPawn, pawnList)
    local pawnCount = 0
    for _ in pairs(pawnList or {}) do pawnCount = pawnCount + 1 end

    -- Pawn/controller replacement is the strongest match/session boundary.
    if MatchState.Controller ~= controller or MatchState.Pawn ~= currentPawn then
        ResetMatchCaches("MATCH_CONTEXT_RESET")
        MatchState.Controller = controller
        MatchState.Pawn = currentPawn
        MatchState.EmptyFrames = 0
        return
    end

    -- During loading/transition the pawn list can disappear.
    -- Treat a short empty window as an unload boundary, then fully rebuild.
    if pawnCount == 0 then
        MatchState.EmptyFrames = (MatchState.EmptyFrames or 0) + 1
        if MatchState.EmptyFrames >= 2 then
            ResetMatchCaches("PAWN_CACHE_UNLOADED")
        end
    else
        if (MatchState.EmptyFrames or 0) >= 2 then
            ResetMatchCaches("PAWN_CACHE_RELOADED")
            MatchState.Controller = controller
            MatchState.Pawn = currentPawn
        end
        MatchState.EmptyFrames = 0
    end
end

local function CreateMortarLine(rootUI)
    if not rootUI then return nil end
    local config = nil
    pcall(function() config = UIManager.UI_Config.MortarLineUI end)
    if not config then
        ESPDebug.Config = false
        ESPDebug.LastError = "MORTAR_CONFIG_NULL"
        return nil
    end
    ESPDebug.Config = true
    ESPDebug.CreateAttempts = ESPDebug.CreateAttempts + 1
    local line = nil
    pcall(function()
        line = rootUI:CreateChildWindow("CanvasPanel_0", config, FVector2D(0, 0), FVector2D(0, 0))
    end)
    if not line then
        ESPDebug.LineCreate = false
        ESPDebug.LastError = "CREATE_CHILDWINDOW_FAIL"
        return nil
    end
    ESPDebug.LineCreate = true
    SetMortarLineVisible(line, false)
    return line
end

-- Manual projection using FOV when standard projection fails
local function ProjectPawnExact(controller, rootUI, pawn)
    if not controller or not rootUI or not isValid(pawn) then return nil end
    local worldPos = GetOBCardWorldPos(pawn)
    if not worldPos then return nil end
    local viewportSize = nil
    pcall(function() viewportSize = UIUtil.GetViewportSize() end)
    if not viewportSize or viewportSize.X <= 0 or viewportSize.Y <= 0 then return nil end
    local screenPos = FVector2D(0, 0)
    local projected = false
    -- Try standard projection first
    pcall(function()
        projected = controller:ProjectWorldLocationToScreen(worldPos, screenPos, true)
    end)

    -- When normal projection fails or the target is behind the camera,
    -- deliberately generate a stable screen-edge direction instead of
    -- dropping the line. This keeps the line alive while the target is
    -- behind the current view.
    if not projected then
        pcall(function()
            local camManager = controller.PlayerCameraManager
            if not camManager and controller.GetPlayerCameraManager then
                camManager = controller:GetPlayerCameraManager()
            end

            local camLoc = nil
            local camRot = nil
            if controller.GetCameraLocation then
                camLoc = controller:GetCameraLocation()
            elseif camManager and camManager.GetCameraLocation then
                camLoc = camManager:GetCameraLocation()
            end
            if controller.GetCameraRotation then
                camRot = controller:GetCameraRotation()
            elseif camManager and camManager.GetCameraRotation then
                camRot = camManager:GetCameraRotation()
            end

            if not camLoc or not camRot then return end

            local forward = camRot:Vector()
            local right = camRot:RightVector()
            local up = camRot:UpVector()
            if not forward or not right or not up then return end

            local rel = worldPos - camLoc
            local localX = rel:Dot(right)
            local localY = rel:Dot(up)
            local localZ = rel:Dot(forward)

            local fov = 90
            if camManager then
                fov = camManager.FOV or fov
                pcall(function()
                    if camManager.GetFOVAngle then
                        fov = camManager:GetFOVAngle() or fov
                    end
                end)
            end

            local aspect = viewportSize.X / viewportSize.Y
            local halfFOVTan = math.tan(math.rad(fov * 0.5))
            if halfFOVTan <= 0 then halfFOVTan = 1 end

            local sx, sy
            if localZ > 0 then
                sx = (localX / localZ) / halfFOVTan
                sy = (localY / localZ) / (halfFOVTan / aspect)
            else
                -- Behind camera: use the reverse-facing screen direction.
                -- This intentionally produces an edge anchor, not a fake
                -- in-screen target point.
                local z = math.max(math.abs(localZ), 1.0)
                sx = (-localX / z) / halfFOVTan
                sy = (-localY / z) / (halfFOVTan / aspect)

                local mag = math.sqrt(sx * sx + sy * sy)
                if mag < 0.001 then
                    sx, sy = 0, -1
                else
                    sx, sy = sx / mag, sy / mag
                end

                local edgeX = viewportSize.X * 0.5
                local edgeY = viewportSize.Y * 0.5
                local dx = sx * edgeX
                local dy = sy * edgeY
                local tx = math.abs(dx) > 0.001 and edgeX / math.abs(dx) or math.huge
                local ty = math.abs(dy) > 0.001 and edgeY / math.abs(dy) or math.huge
                local t = math.min(tx, ty)

                screenPos.X = edgeX + dx * t
                screenPos.Y = edgeY + dy * t
                projected = true
            end

            if localZ > 0 then
                screenPos.X = (sx * 0.5 + 0.5) * viewportSize.X
                screenPos.Y = (sy * 0.5 + 0.5) * viewportSize.Y
                projected = true
            end
        end)
    end

    if not projected then
        ESPDebug.Project = false
        ESPDebug.TargetState = "PROJECT_FAIL"
        ESPDebug.LastError = "PROJECT_FAILED"
        return nil
    end

    -- Clamp to viewport edges (so line never disappears completely)
    screenPos.X = math.max(0, math.min(viewportSize.X, screenPos.X))
    screenPos.Y = math.max(0, math.min(viewportSize.Y, screenPos.Y))
    local geometry = nil
    pcall(function() geometry = rootUI:GetCachedGeometry() end)
    if not geometry then return nil end
    local rootSize = nil
    pcall(function() rootSize = SlateBlueprintLibrary.GetLocalSize(geometry) end)
    if not rootSize or rootSize.X <= 0 or rootSize.Y <= 0 then return nil end
    local localPos = FVector2D(screenPos.X / viewportSize.X * rootSize.X, screenPos.Y / viewportSize.Y * rootSize.Y)
    localPos.X = math.max(0, math.min(rootSize.X, localPos.X))
    localPos.Y = math.max(0, math.min(rootSize.Y, localPos.Y))
    ESPDebug.Project = true
    ESPDebug.TargetState = "PLAYER"
    ESPDebug.ScreenX = screenPos.X
    ESPDebug.ScreenY = screenPos.Y
    ESPDebug.LocalX = localPos.X
    ESPDebug.LocalY = localPos.Y
    ESPDebug.LastError = "NONE"
    return localPos
end

local function GetLineColor(pawn)
    local isAI=false
    pcall(function() if Game and Game.IsAI then isAI=Game:IsAI(pawn) end end)
    if isAI then
        return FLinearColor(1.0,1.0,0.0,1.0),true
    end
    return FLinearColor(1.0,0.0,0.0,1.0),false
end

local function ApplyLineColor(line,color)
    if not line or not color then return end
    local root=line.UIRoot
    if not root then return end
    local candidates={
        root.Image_Airline,
        root.Image_Line,
        root.Image_0,
        root.Image,
        root.BG,
        root.CanvasPanel_Airline
    }
    for _,w in ipairs(candidates) do
        pcall(function()
            if w and w.SetColorAndOpacity then
                w:SetColorAndOpacity(color)
            end
        end)
    end
    pcall(function()
        if root.SetColorAndOpacity then root:SetColorAndOpacity(color) end
    end)
    pcall(function()
        if root.GetAllChildren then
            local children=root:GetAllChildren()
            if children then
                for _,w in pairs(children) do
                    pcall(function()
                        if w and w.SetColorAndOpacity then w:SetColorAndOpacity(color) end
                    end)
                end
            end
        end
    end)
end

local function UpdateMortarLine(line, rootSize, endPosition, lineColor)
    if not IsMortarLineValid(line) then
        return false
    end
    if not endPosition then
        SetMortarLineVisible(line, false)
        return false
    end
    local centerX = rootSize.X * 0.5
    local centerY = rootSize.Y * 0.5
    local COUNT_BOX_HEIGHT = 26
    local COUNT_BOX_GAP = 2
    local startPosition = FVector2D(0, -centerY + COUNT_BOX_HEIGHT + COUNT_BOX_GAP)
    local localEnd = FVector2D(endPosition.X - centerX, endPosition.Y - centerY)
    line.StartPosition = startPosition
    line.EndPosition = localEnd
    local ok = false
    pcall(function()
        line:OnInitialize()
        ok = true
    end)
    if not ok then
        ESPDebug.LastError = "MORTAR_ONINITIALIZE_FAIL"
        return false
    end
    ApplyLineColor(line,lineColor)
    local diff = FVector2D(localEnd.X - startPosition.X, localEnd.Y - startPosition.Y)
    local length = math.sqrt(diff.X * diff.X + diff.Y * diff.Y)
    local normalized = nil
    pcall(function() normalized = KismetMathLibrary.Normal2D(diff) end)
    local angle = 0
    if normalized then
        local dot = KismetMathLibrary.DotProduct2D(normalized, FVector2D(-1, 0))
        angle = KismetMathLibrary.DegAcos(dot)
        if normalized.Y > 0 then angle = angle * -1 end
        angle = angle + 180
    end
    ESPDebug.StartX = startPosition.X
    ESPDebug.StartY = startPosition.Y
    ESPDebug.EndX = localEnd.X
    ESPDebug.EndY = localEnd.Y
    ESPDebug.LineLength = length
    ESPDebug.LineAngle = angle
    ESPDebug.LineUpdate = true
    ESPDebug.LastMethod = "MortarLineUI"
    ESPDebug.LastError = "NONE"
    SetMortarLineVisible(line, true)
    return true
end

-- ============================================================
-- FAST LINE TICK (Main loop) - Now fully protected
-- ============================================================
local function FastLineTick()
    -- Wrap everything in pcall to prevent timer death
    local success, err = pcall(function()
        ESPDebug.FastTickCount = (ESPDebug.FastTickCount or 0) + 1
        ESPDebug.LastFastTick = os.clock()
        ESPDebug.LastMethod = "FAST_TICK_ENTER"
        ESPDebug.LastError = "NONE"
        if not _G.CheatsEnabled then return end

        local controller = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not (isValid(controller) and Game:IsClassOf(controller, ASTExtraPlayerController)) then
            ESPDebug.Controller = false
            ESPDebug.LastError = "CONTROLLER_FAIL"
            return
        end
        ESPDebug.Controller = true
        local currentPawn = controller:GetCurPawn()
        if not isValid(currentPawn) then
            ESPDebug.Pawn = false
            ESPDebug.LastError = "PAWN_FAIL"
            return
        end
        ESPDebug.Pawn = true
        local rootUI = GetMainControlUI()
        if not rootUI then
            ESPDebug.Root = false
            ESPDebug.LastError = "ROOT_FAIL"
            return
        end
        ESPDebug.Root = true
        local geometry = nil
        pcall(function() geometry = rootUI:GetCachedGeometry() end)
        if not geometry then
            ESPDebug.LastError = "GEOMETRY_FAIL"
            return
        end
        local rootSize = nil
        pcall(function() rootSize = SlateBlueprintLibrary.GetLocalSize(geometry) end)
        if not rootSize then
            ESPDebug.LastError = "ROOTSIZE_FAIL"
            return
        end
        ESPDebug.RootW = rootSize.X
        ESPDebug.RootH = rootSize.Y
        local myTeamID = GetTeamID(currentPawn)
        local now = os.clock()

        -- LIVE pawn snapshot every frame. This removes cross-match and mid-match
        -- stale-pawn cache problems while keeping the per-pawn UI/line cache only
        -- for rendered objects.
        local livePawns = Game:GetAllPlayerPawns() or {}
        cachedPawns = livePawns
        lastPawnRefresh = now
        SyncMatchLifecycle(controller, currentPawn, livePawns)
        ESPDebug.MatchGeneration = MatchState.Generation

        local used = {}
        local activeOB = {}
        local lineCount = 0
        local playerCount = 0
        local botCount = 0

        for _, pawn in pairs(cachedPawns) do
            if isValid(pawn) and pawn ~= currentPawn and pawn.TeamID ~= myTeamID and IsPawnAlive(pawn) then
                local myPos = nil
                local enemyPos = nil
                pcall(function()
                    myPos = currentPawn:K2_GetActorLocation()
                    enemyPos = pawn:K2_GetActorLocation()
                end)
                if myPos and enemyPos then
                    local dx = enemyPos.X - myPos.X
                    local dy = enemyPos.Y - myPos.Y
                    local dz = enemyPos.Z - myPos.Z
                    local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
                    if distance < 600000 then
                        local isAI = IsBotOrAI(pawn)
                        if isAI then botCount=botCount+1 else playerCount=playerCount+1 end
                        local lineColor = isAI and FLinearColor(1.0,1.0,0.0,1.0) or FLinearColor(1.0,0.0,0.0,1.0)
                        local target2D = ProjectPawnExact(controller, rootUI, pawn)
                        local cardDist = distance/100.0
                        local cardName = GetPlayerName(pawn)
                        local cardTeam = GetTeamID(pawn)
                        local cardHP, cardKnock = GetHealthInfo(pawn)
                        local cardKey = pawn
                        activeOB[cardKey] = true
                        OBWidgetState.Data = OBWidgetState.Data or {}
                        local old = OBWidgetState.Data[cardKey] or {}
                        local changed = old.name~=cardName or old.team~=cardTeam or old.hp~=cardHP or old.knock~=cardKnock or math.abs((old.distance or -999999)-cardDist)>=1.0
                        UpdateOBCard(pawn, controller, rootUI, cardName, cardTeam, cardDist, cardHP, cardKnock, changed)
                        OBWidgetState.Data[cardKey] = {name=cardName, team=cardTeam, hp=cardHP, knock=cardKnock, distance=cardDist}

                        -- ESP Line feature
                        if _G.Mod_ESP_Line_Enabled then
                            local line = enemyLineCache[pawn]
                            if not IsMortarLineValid(line) then
                                line = CreateMortarLine(rootUI)
                                if line then
                                    enemyLineCache[pawn] = line
                                    LineState.Lines[pawn] = line
                                end
                            end
                            if not IsMortarLineValid(line) then
                                ESPDebug.LastError = "LINE_UIROOT_INVALID"
                            elseif target2D then
                                local ok = UpdateMortarLine(line, rootSize, target2D, lineColor)
                                if ok then
                                    used[pawn] = true
                                    lineCount = lineCount + 1
                                else
                                    SetMortarLineVisible(line, false)
                                end
                            elseif line then
                                SetMortarLineVisible(line, false)
                            end
                        else
                            local line = enemyLineCache[pawn]
                            if line then SetMortarLineVisible(line, false) end
                        end
                    end
                end
            end
        end
        -- Remove OB cards for enemies that are no longer active/alive.
        -- This prevents the main name/distance widget from freezing at its
        -- last projected screen position after a kill/despawn.
        for key, widget in pairs(OBWidgetState.Widgets) do
            if key ~= OBWidgetState.CountBox and not activeOB[key] then
                RemoveOBWidget(key)
            end
        end

        ESPDebug.PlayerCount = playerCount
        ESPDebug.BotCount = botCount
        UpdateCountBox(rootUI, playerCount, botCount)
        for pawn, line in pairs(enemyLineCache) do
            if not used[pawn] then
                SetMortarLineVisible(line, false)
            end
            if not isValid(pawn) then
                pcall(function()
                    if line and line.Close then line:Close() end
                end)
                enemyLineCache[pawn] = nil
                LineState.Lines[pawn] = nil
            end
        end
        ESPDebug.LineCount = lineCount
        ESPDebug.PlayerCount = playerCount
        ESPDebug.BotCount = botCount
    end)
    if not success then
        ESPDebug.LastError = "FAST_TICK_ERROR: " .. tostring(err)
    end
end

-- ============================================================
-- TIMER MANAGEMENT
-- ============================================================
local function StartLineTimer()
    if LineState.Started and LineState.LineTimer then
        -- Verify timer is still valid (optional)
        return true
    end
    LineState.Started = false
    LineState.LineTimer = nil
    LineState.LineTimerOwner = nil
    ESPDebug.TimerMode = "NONE"
    local ok1, handle1 = pcall(function()
        return time_ticker.AddTimerLoop(0, function() pcall(FastLineTick) end, TIMER_INFINITE, time_ticker.NEXT_FRAME)
    end)
    if ok1 and handle1 then
        LineState.LineTimer = handle1
        LineState.Started = true
        ESPDebug.TimerMode = "time_ticker.NEXT_FRAME"
        pcall(FastLineTick)
        return true
    end
    local controller = nil
    pcall(function() controller = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController() end)
    if isValid(controller) and controller.AddTimerLoop then
        local ok2, handle2 = pcall(function()
            return controller:AddTimerLoop(0, function() pcall(FastLineTick) end, TIMER_INFINITE, 0.5)
        end)
        if ok2 and handle2 then
            LineState.LineTimer = handle2
            LineState.LineTimerOwner = controller
            LineState.Started = true
            ESPDebug.TimerMode = "Controller.AddTimerLoop"
            pcall(FastLineTick)
            return true
        end
    end
    if isValid(controller) and controller.AddGameTimer then
        local ok3, handle3 = pcall(function()
            return controller:AddGameTimer(0.016, true, function() pcall(FastLineTick) end)
        end)
        if ok3 and handle3 then
            LineState.LineTimer = handle3
            LineState.LineTimerOwner = controller
            LineState.Started = true
            ESPDebug.TimerMode = "Controller.AddGameTimer(0.016)"
            pcall(FastLineTick)
            return true
        end
    end
    pcall(FastLineTick)
    ESPDebug.TimerMode = "FAILED"
    ESPDebug.LastError = "NO_LINE_TIMER"
    return false
end

local function StopLineTimer()
    if LineState.LineTimer then
        pcall(function()
            if ESPDebug.TimerMode == "time_ticker.NEXT_FRAME" then
                time_ticker.RemoveTimer(LineState.LineTimer)
            elseif LineState.LineTimerOwner then
                if LineState.LineTimerOwner.RemoveTimer then
                    LineState.LineTimerOwner:RemoveTimer(LineState.LineTimer)
                elseif LineState.LineTimerOwner.RemoveGameTimer then
                    LineState.LineTimerOwner:RemoveGameTimer(LineState.LineTimer)
                end
            end
        end)
    end
    LineState.LineTimer = nil
    LineState.LineTimerOwner = nil
    LineState.Started = false
    ESPDebug.TimerMode = "NONE"
end

local function HeavyTick()
    -- Lightweight maintenance only; the actual ESP/Card refresh is NEXT_FRAME.
    if not _G.CheatsEnabled then return end
    if not LineState.Started or not LineState.LineTimer then
        StartLineTimer()
    end
end

local function StartESP()
    StartLineTimer()
end

local function StopESP()
    StopLineTimer()
    ResetMatchCaches("ESP_STOP")
    MatchState.Controller = nil
    MatchState.Pawn = nil
    MatchState.EmptyFrames = 0
end

_G.ESPTick = HeavyTick
_G.ESPStart = StartESP
_G.ESPStop = StopESP
_G.ESPFastLineTick = FastLineTick
_G.ESPStartLineTimer = StartLineTimer
_G.ESPStopLineTimer = StopLineTimer

pcall(function() StartESP() end)

-- ============================================================
-- MENU SYSTEM (Three toggles)
-- ============================================================

local FakeTextMap = {
    [999000] = "ESPMENU MENU",
    [999101] = "ESP Line",
    [999102] = "Health Bar",
    [999103] = "Name & Distance",
}

local function HookLocUtil()
    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then
        LocUtil = require("client.common.LocUtil")
    end
    if LocUtil and not LocUtil._IsModMenuHooked_Fix then
        local hookFuncs = {"GetLocalizeResStr", "GetText", "GetTextByID", "GetLocalText", "GetLocalizeStr"}
        for _, funcName in ipairs(hookFuncs) do
            if LocUtil[funcName] then
                local old_func = LocUtil[funcName]
                LocUtil[funcName] = function(id)
                    if FakeTextMap[id] then return FakeTextMap[id] end
                    if type(id) == "string" and not tonumber(id) then return id end
                    if old_func then return old_func(id) end
                    return ""
                end
            end
        end
        LocUtil._IsModMenuHooked_Fix = true
    end
end

_G.InitModMenuTab = function()
    if _G.ModMenuInitialized then return end
    _G.ModMenuInitialized = true
    HookLocUtil()

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")

    local function getFeatureVal(id)
        if id == "Line" then return _G.Mod_ESP_Line_Enabled or false end
        if id == "Health" then return _G.Mod_ESP_Health_Enabled or false end
        if id == "NameDist" then return _G.Mod_ESP_NameDist_Enabled or false end
        return false
    end

    local function setFeatureVal(id, v)
        if id == "Line" then
            _G.Mod_ESP_Line_Enabled = v
            -- Line toggle must not stop the main ESP/card refresh loop.
            -- Keep OB Name/Distance, HP, and Team ID independent.
            if v then
                StartLineTimer()
            else
                for _, line in pairs(enemyLineCache) do
                    pcall(function() SetMortarLineVisible(line, false) end)
                end
            end
            return true
        end
        if id == "Health" then
            _G.Mod_ESP_Health_Enabled = v
            for key,w in pairs(OBWidgetState.Widgets) do
                pcall(function()
                    local d = OBWidgetState.Data[key]
                    if v and d then
                        ApplyOBHP(w, d.hp or 0, d.knock or false)
                    else
                        if not v then
                            local bars = {
                                "ProgressBar_HP","ProgressBar_0","ProgressBar_PlayerHP",
                                "ProgressBar_Health","ProgressBar_PlayerHealth",
                                "ProgressBar_HPBar","ProgressBar_HealthBar",
                                "ProgressBar_Health1","ProgressBar_Health2"
                            }
                            for _,n in ipairs(bars) do
                                local bar=w[n]
                                if bar and bar.SetWidgetVisibility then
                                    bar:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                                end
                            end
                        end
                    end
                end)
            end
            return true
        end
        if id == "NameDist" then
            _G.Mod_ESP_NameDist_Enabled = v
            for key,w in pairs(OBWidgetState.Widgets) do
                pcall(function()
                    if v then
                        local d = OBWidgetState.Data[key]
                        if d then
                            ShowOBNameDistArea(w)
                            ApplyOBNameDist(w, d.name or "Enemy", d.distance or 0)
                        end
                    else
                        HideOBNameDist(w)
                    end
                    HideOBCardContainer(w)
                end)
            end
            return true
        end
        return false
    end

    local StackFeatures = {
        { UI = AliasMap.Title, Text = 999000 },
        { Key = "ModMenu_Line", UI = AliasMap.Switcher, Text = 999101, GetFunc = function() return getFeatureVal("Line") end, SetFunc = function(c,v) return setFeatureVal("Line", v) end },
        { Key = "ModMenu_Health", UI = AliasMap.Switcher, Text = 999102, GetFunc = function() return getFeatureVal("Health") end, SetFunc = function(c,v) return setFeatureVal("Health", v) end },
        { Key = "ModMenu_NameDist", UI = AliasMap.Switcher, Text = 999103, GetFunc = function() return getFeatureVal("NameDist") end, SetFunc = function(c,v) return setFeatureVal("NameDist", v) end },
    }

    if not SettingPageDefine.ESPMENUMenu then
        SettingPageDefine.ESPMENUMenu = {
            Key = "ESPMENU MENU",
            Text = 999000,
            UIKey = "Setting_Page_Privacy",
            Category = {
                { Key = "Cat_Features", Text = 999000, Stack = StackFeatures },
            }
        }
        table.insert(SettingCatalog, 1, SettingPageDefine.ESPMENUMenu)
    end

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked_Fix then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            local n = select('#', ...)
            if config and config.keyName then
                local lowerKeyName = string.lower(config.keyName)
                if string.find(lowerKeyName, "setting_main") and not string.find(lowerKeyName, "custom") then
                    local catalog = args[1]
                    if type(catalog) == "table" and catalog[1] and type(catalog[1]) == "table" and catalog[1].Key then
                        local hasModMenu = false
                        for _, page in ipairs(catalog) do
                            if type(page) == "table" and page.Key == "ESPMENU MENU" then
                                hasModMenu = true
                                break
                            end
                        end
                        if not hasModMenu and SettingPageDefine.ESPMENUMenu then
                            table.insert(catalog, 1, SettingPageDefine.ESPMENUMenu)
                        end
                    end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args, 1, n))
        end
        UIManager._IsModMenuHooked_Fix = true
    end
end

_G.InitModMenuTab()