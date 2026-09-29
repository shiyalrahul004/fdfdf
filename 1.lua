-- ============================================================
-- 🔒 INJECTOR BIND (B) - sirf apne injector ke saath chalegi
-- match -> chalegi, mismatch -> silent return (load nahi hogi)
-- ============================================================
do
    local ctx = _G.__NIVO_CTX
    local function _bindFail(reason)
        pcall(function() print("[NIVO] bind reject: " .. tostring(reason)) end)
        _G.__NIVO_CTX = nil
        -- Chor ko sunao (session me ek baar), phir bhi return -> mods load nahi honge
        if not _G._THIEF_WARNED then
            _G._THIEF_WARNED = true
            pcall(function()
                local Msg = require("client.slua.logic.common.logic_common_msg_box")
                if Msg and Msg.Show then
                    Msg.Show(2, "⛔ PAKDE GAYE!",
                        "teri maa ki choot bhen ke lode lua file chalayga tera baap h dravix samjh gya bhadwe madarchod",
                        function() end, function()
                            pcall(function()
                                local WS = _G.WebviewSDK or WebviewSDK
                                if WS and WS.OpenURL then WS:OpenURL("https://t.me/trndravix") end
                            end)
                        end, "Nikkal", "Telegram")
                end
            end)
        end
    end
    if type(ctx) ~= "table" or ctx.key == nil or ctx.keyPath == nil then _bindFail("no-ctx") return end
    -- 1. HWID khud padhke match karo
    local okH, myHwid = pcall(function()
        local Kismet = import('/Script/Engine.KismetSystemLibrary')
        if Kismet and Kismet.GetDeviceId then return Kismet.GetDeviceId() end
        return nil
    end)
    if not okH or not myHwid or myHwid ~= ctx.hwid then _bindFail("hwid") return end
    -- 2. keys.txt fresh padhke match karo (injector wale path se)
    local okK, myKey = pcall(function()
        local f = io.open(ctx.keyPath, "r")
        if not f then return nil end
        local c = f:read("*all"):gsub("%s+", "")
        f:close()
        return c
    end)
    if not okK or not myKey or myKey ~= ctx.key then _bindFail("key") return end
    -- 3. server token match karo (dusri license ka token nahi chalega)
    local myTok = (_G.LicenseMeta and _G.LicenseMeta.token) or ""
    if (ctx.token or "") == "" or myTok ~= ctx.token then _bindFail("token") return end
end

-- ============================================================
-- MODED BY NivoCheats - OPTIMIZED + BYPASS INLINE
-- ============================================================

-- ============================================================
-- 1. PER-MATCH GUARD
-- ============================================================
do
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if _G._MOD_FULL_LOADED and _G._MOD_FULL_PC == pc then return end
    _G._MOD_FULL_LOADED = true
    _G._MOD_FULL_PC = pc
end

-- ============================================================
-- 2. GLOBALS / TOGGLES
-- ============================================================
if not _G.Mod_Aimbot_Enabled then _G.Mod_Aimbot_Enabled = false end
if _G.Mod_AimbotStrength == nil then _G.Mod_AimbotStrength = 80 end
if _G.Mod_ForceTPP_Enabled == nil then _G.Mod_ForceTPP_Enabled = false end
if not _G.Mod_Wallhack_Enabled then _G.Mod_Wallhack_Enabled = false end
if _G.Mod_ESP_Line_Enabled == nil then _G.Mod_ESP_Line_Enabled = true end
if _G.Mod_ESP_Text_Enabled == nil then _G.Mod_ESP_Text_Enabled = true end
if _G.Mod_ESP_Health_Enabled == nil then _G.Mod_ESP_Health_Enabled = true end
if _G.Mod_ESP_NameDist_Enabled == nil then _G.Mod_ESP_NameDist_Enabled = true end
if _G.Mod_EnemyCounter_Enabled == nil then _G.Mod_EnemyCounter_Enabled = true end
if _G.Mod_iPadView_Enabled == nil then _G.Mod_iPadView_Enabled = false end
if _G.Mod_iPadViewFOV == nil then _G.Mod_iPadViewFOV = 110 end

-- ✅ ESP DISTANCE: 500 METERS FIXED (PerfMode removed)
if _G.Mod_ESPDistance == nil then _G.Mod_ESPDistance = 500 end

-- ✅ BYPASS INTERNAL TOGGLES (no UI, always on)
if _G.Mod_NewBypass_Enabled == nil then _G.Mod_NewBypass_Enabled = true end
if _G.Mod_NB_Tss == nil then _G.Mod_NB_Tss = true end
if _G.Mod_NB_Gokuba == nil then _G.Mod_NB_Gokuba = true end
if _G.Mod_NB_Higgs == nil then _G.Mod_NB_Higgs = true end
if _G.Mod_NB_NetFilter == nil then _G.Mod_NB_NetFilter = true end
if _G.Mod_NB_Emu == nil then _G.Mod_NB_Emu = true end
if _G.Mod_NB_Report == nil then _G.Mod_NB_Report = true end

_G.CheatsEnabled = true

-- ============================================================
-- 2.5 BYPASS (inline from bypass.lua v17) - ALWAYS ON
-- ============================================================
_G.ApplyNewBypass = function()
    local function nlog(m)
        if _G._NB_SILENT and not tostring(m):find("REAPPLY") then return end
        pcall(function()
            if _G.CounterLog then _G.CounterLog("NB " .. tostring(m))
            else print("[NB] " .. tostring(m)) end
        end)
        -- file routing: wahi mods_debug.log jo share hota hai (bind ctx path se)
        pcall(function()
            local c = _G.__NIVO_CTX
            if c and c.keyPath then
                local lp = tostring(c.keyPath):gsub("keys%.txt$", "mods_debug.log")
                local f = io.open(lp, "a")
                if f then f:write("[NB] " .. tostring(m) .. "\n"); f:flush(); f:close() end
            end
        end)
    end
    if _G.Mod_NewBypass_Enabled == false then
        nlog("bypass DISABLED by toggle")
        return
    end
    -- L1: TSS tag source clean
    if _G.Mod_NB_Tss ~= false then
        local okT, tss = pcall(function() return Tss end)
        if okT and tss and type(tss.GetUserTag4Lua) == "function" then
            pcall(function() tss.GetUserTag4Lua = function() return "" end end)
            nlog("hook Tss.GetUserTag4Lua=OK")
        else
            nlog("hook Tss.GetUserTag4Lua=SKIP")
        end
    end
    -- L2: Gokuba forward noop + timer kill
    if _G.Mod_NB_Gokuba ~= false then
        local okG, gk = pcall(require, "GameLua.Mod.BaseMod.Client.Security.Gokuba")
        if okG and type(gk) == "table" then
            if type(gk.ForwardFeature) == "function" then
                pcall(function() gk.ForwardFeature = function() end end)
                nlog("hook Gokuba.ForwardFeature=OK")
            else
                nlog("hook Gokuba.ForwardFeature=SKIP")
            end
            pcall(function()
                local tt = require("common.time_ticker")
                if tt and tt.RemoveTimer and gk.TimerHandle then
                    tt.RemoveTimer(gk.TimerHandle)
                    gk.TimerHandle = nil
                    nlog("hook Gokuba.TimerHandle=CANCELLED")
                end
            end)
        else
            nlog("hook Gokuba=SKIP (module not in VM)")
        end
    end
    -- L3: Higgs full-6 noop
    if _G.Mod_NB_Higgs ~= false then
        local okH, hg = pcall(require, "GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if okH and type(hg) == "table" then
            for _, fn in ipairs({ "SendHisarData", "SendAntiDataFlow", "SendHitFireBtnFlow", "SendFingerTouchFlow", "OnBattleResult", "RecordStrategyTimestampInReplay" }) do
                if type(hg[fn]) == "function" then
                    local fname = fn
                    pcall(function() hg[fname] = function(...) end end)
                    nlog("hook Higgs." .. fname .. "=OK")
                else
                    nlog("hook Higgs." .. fn .. "=SKIP")
                end
            end
        else
            nlog("hook Higgs=SKIP (module not in VM)")
        end
    end
    -- L4: NetUtil packet filter
    if _G.Mod_NB_NetFilter ~= false then
        local nu = _G.NetUtil
        if nu and type(nu.SendPkg) == "function" and not nu.__NBWrapped then
            local orig = nu.SendPkg
            local drop = {
                hisar = true,
                on_crow_update_ntf = true,
                on_crow_update_ntf2 = true,
                on_crow_update_ntf3 = true,
                on_crow_update_ntf4 = true,
                on_crow_update_ntf5 = true,
                battle_client_sync_allstar_auth_check_result_req = true,
                report_battle_ping = true,
                report_client_frame_details = true
            }
            local wok = false
            pcall(function()
                nu.SendPkg = function(pkg, ...)
                    if type(pkg) == "string" and drop[pkg] then return end
                    return orig(pkg, ...)
                end
                nu.__NBWrapped = true
                wok = true
            end)
            nlog("hook NetUtil.SendPkg filter=" .. tostring(wok))
        else
            nlog("hook NetUtil.SendPkg=SKIP")
        end
    end
    -- L5: Emulator spoof
    if _G.Mod_NB_Emu ~= false then
        local okE, es = pcall(require, "client.logic.login.logic_emulator")
        if okE and type(es) == "table" then
            if type(es.IsEmulator) == "function" then
                pcall(function() es.IsEmulator = function(...) return false end end)
                nlog("hook EmulatorSystem.IsEmulator=OK")
            else
                nlog("hook EmulatorSystem.IsEmulator=SKIP")
            end
        else
            nlog("hook EmulatorSystem=SKIP (module not in VM)")
        end
        local okS, sc = pcall(require, "client.logic.login.emulator_scanner")
        if okS and type(sc) == "table" and type(sc.find_emulator) == "function" then
            pcall(function() sc.find_emulator = function(...) return false, nil end end)
            nlog("hook emulator_scanner.find_emulator=OK")
        else
            nlog("hook emulator_scanner.find_emulator=SKIP")
        end
        local okH2, eh = pcall(require, "client.network.Protocol.EmulatorHandler")
        if okH2 and type(eh) == "table" and type(eh.send_report_simulator_check) == "function" then
            pcall(function() eh.send_report_simulator_check = function(...) end end)
            nlog("hook EmulatorHandler.send_report_simulator_check=OK")
        else
            nlog("hook EmulatorHandler.send_report_simulator_check=SKIP")
        end
    end
    -- L1b: TSS full clean (SKD blob, eigeninfo fake-success, device fingerprint, APK collect)
    if _G.Mod_NB_Tss ~= false then
        local function hookTssObj(tss)
            if type(tss) ~= "table" and type(tss) ~= "userdata" then return false end
            local n = 0
            pcall(function()
                if type(tss.SendSkdData) == "function" and not tss.__NBNoSkd then
                    tss.SendSkdData = function(...) end
                    tss.__NBNoSkd = true
                    n = n + 1
                end
            end)
            pcall(function()
                -- fake-success: normal GEM "6" event behta rahe, error event nahi
                if type(tss.SendEigeninfoData) == "function" and not tss.__NBNoEig then
                    tss.SendEigeninfoData = function(...) return 0 end
                    tss.__NBNoEig = true
                    n = n + 1
                end
            end)
            pcall(function()
                if type(tss.GetDeviceFeature) == "function" and not tss.__NBNoDvc then
                    tss.GetDeviceFeature = function(...) return "" end
                    tss.__NBNoDvc = true
                    n = n + 1
                end
            end)
            pcall(function()
                if type(tss.EigenArrayObfuscationVerify) == "function" and not tss.__NBNoEov then
                    tss.EigenArrayObfuscationVerify = function(...) return 0 end
                    tss.__NBNoEov = true
                    n = n + 1
                end
            end)
            pcall(function()
                -- sirf code 18 (AllowAPKCollect) roko, baaki passthrough
                if type(tss.InvokeSDKIoctl) == "function" and not tss.__NBIoctlWrapped then
                    local origIo = tss.InvokeSDKIoctl
                    tss.InvokeSDKIoctl = function(...)
                        local a1 = select(1, ...)
                        if a1 == 18 then return end
                        return origIo(...)
                    end
                    tss.__NBIoctlWrapped = true
                    n = n + 1
                end
            end)
            return n
        end
        pcall(function()
            local okT, tss = pcall(function() return Tss end)
            if okT and tss then
                nlog("hook Tss.ext=" .. tostring(hookTssObj(tss)) .. " fns")
            else
                nlog("hook Tss.ext=SKIP (nil)")
            end
        end)
        pcall(function()
            local okM, tm = pcall(function() return _G.TssManager end)
            if okM and tm then
                nlog("hook TssManager.ext=" .. tostring(hookTssObj(tm)) .. " fns")
            end
        end)
        pcall(function()
            local nu = _G.NetUtil
            if nu and type(nu.SendTss) == "function" and not nu.__NBNoSendTss then
                nu.SendTss = function() end
                nu.__NBNoSendTss = true
                nlog("hook NetUtil.SendTss=OK")
            else
                nlog("hook NetUtil.SendTss=SKIP")
            end
        end)
    end
    -- L6: REPORT LAYER (replay/rotation/FPP/battle/crash exfil) - naya bypass core
    if _G.Mod_NB_Report ~= false then
        -- L6a: central choke - GameReportUtils
        pcall(function()
            local okR, gru = pcall(require, "GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils")
            if okR and type(gru) == "table" then
                if type(gru.ReplayReportData) == "function" and not gru.__NBRRWrapped then
                    local origRR = gru.ReplayReportData
                    local drop = { [4] = true, [5] = true, [6] = true, [8] = true, [9] = true, [10] = true }
                    gru.ReplayReportData = function(rid, ...)
                        if type(rid) ~= "table" and drop[rid] then return end
                        return origRR(rid, ...)
                    end
                    gru.__NBRRWrapped = true
                    nlog("hook ReplayReportData ID-block=OK")
                else
                    nlog("hook ReplayReportData=SKIP")
                end
                if type(gru.BugglyPostExceptionFull) == "function" and not gru.__NBBugWrapped then
                    gru.BugglyPostExceptionFull = function(...) return false end
                    gru.__NBBugWrapped = true
                    nlog("hook BugglyPostExceptionFull=OK")
                end
                if type(gru.CheckCanBugglyPostException) == "function" and not gru.__NBChkWrapped then
                    gru.CheckCanBugglyPostException = function(...) return false end
                    gru.__NBChkWrapped = true
                    nlog("hook CheckCanBuggly=OK")
                end
                if type(gru.ReportException) == "function" and not gru.__NBExcWrapped then
                    gru.ReportException = function(...) end
                    gru.__NBExcWrapped = true
                    nlog("hook ReportException=OK")
                end
            else
                nlog("hook GameReportUtils=SKIP (module not in VM)")
            end
        end)
        -- L6b: rotation sudden-change reporter noop (aimbot ID5 backup)
        pcall(function()
            local okC, rk = pcall(require, "GameLua.Mod.BaseMod.GamePlay.Feature.Player.ReportCrashKitFeature")
            if okC and type(rk) == "table" and type(rk.OnControlRotationSuddenChangeToReplay) == "function" then
                rk.OnControlRotationSuddenChangeToReplay = function(...) end
                nlog("hook RotationSuddenChange=OK")
            else
                nlog("hook RotationSuddenChange=SKIP")
            end
        end)
        -- L6c: FPP mismatch reporter off (ForceTPP ID10 backup)
        pcall(function()
            local okF, fpp = pcall(require, "GameLua.Mod.BaseMod.GamePlay.Feature.Player.FPPAnimMonitorFeature")
            if okF and type(fpp) == "table" then
                pcall(function() if type(fpp.SetEnabled) == "function" then fpp.SetEnabled(false) end end)
                if type(fpp.ReportFPPAnimState) == "function" then
                    fpp.ReportFPPAnimState = function(...) end
                end
                nlog("hook FPPAnimReporter=OK")
            else
                nlog("hook FPPAnimReporter=SKIP")
            end
        end)
        -- L6d: shoot-verify alarm noop (avatar/scope inconsistency RPC)
        pcall(function()
            local okB, cb = pcall(require, "GameLua.GameCore.Framework.CharacterBase")
            if okB and type(cb) == "table" and type(cb.RPC_Server_ShootVertifyFailAlarm) == "function" then
                cb.RPC_Server_ShootVertifyFailAlarm = function(...) end
                nlog("hook ShootVertifyFailAlarm=OK")
            else
                nlog("hook ShootVertifyFailAlarm=SKIP")
            end
        end)
        -- L6e: Higgs extra (jump-abnormal, alert, chatrobot queue)
        pcall(function()
            local okH, hg = pcall(require, "GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
            if okH and type(hg) == "table" then
                for _, fn in ipairs({ "LuaNotifySecurityAbnormalJump", "C2SSendAlert", "_ReportChatRobot" }) do
                    if type(hg[fn]) == "function" then
                        local fname = fn
                        pcall(function() hg[fname] = function(...) end end)
                        nlog("hook Higgs." .. fname .. "=OK")
                    else
                        nlog("hook Higgs." .. fn .. "=SKIP")
                    end
                end
            else
                nlog("hook Higgs.ext=SKIP (module not in VM)")
            end
        end)
        -- L6f: crew test channel noop
        pcall(function()
            local okW, cw = pcall(require, "client.network.Protocol.CrewHandler")
            if okW and type(cw) == "table" and type(cw.send_test_client_umix) == "function" then
                cw.send_test_client_umix = function(...) end
                nlog("hook CrewTestUmix=OK")
            else
                nlog("hook CrewTestUmix=SKIP")
            end
        end)
        -- L6g: chat securityLog noop
        pcall(function()
            local okH2, ch = pcall(require, "client.network.Protocol.ChatHandler")
            if okH2 and type(ch) == "table" and type(ch.send_report_info) == "function" then
                ch.send_report_info = function(...) end
                nlog("hook ChatReportInfo=OK")
            else
                nlog("hook ChatReportInfo=SKIP")
            end
        end)
        -- L6h: lobby TLog noop
        pcall(function()
            local okT, tl = pcall(require, "client.network.Protocol.ClientTlogHandler")
            if okT and type(tl) == "table" and type(tl.send_report_lobby_common_tlog) == "function" then
                tl.send_report_lobby_common_tlog = function(...) end
                nlog("hook LobbyTlog=OK")
            else
                nlog("hook LobbyTlog=SKIP")
            end
        end)
        -- L6i: battle result exfil noop (video/score/feedback/evaluation)
        pcall(function()
            local okR2, br = pcall(require, "client.network.Protocol.BattleResultHandler")
            if okR2 and type(br) == "table" then
                for _, fn in ipairs({ "send_report_battle_feedback", "send_report_video", "send_report_player_battle_score", "send_report_battle_evaluation" }) do
                    if type(br[fn]) == "function" then
                        local fname = fn
                        pcall(function() br[fname] = function(...) end end)
                        nlog("hook Battle." .. fname .. "=OK")
                    else
                        nlog("hook Battle." .. fn .. "=SKIP")
                    end
                end
            else
                nlog("hook BattleResult=SKIP (module not in VM)")
            end
        end)
        -- L6j: tools crash report noop
        pcall(function()
            local okC2, ct = pcall(require, "client.slua.logic.report.ClientToolsReport")
            if okC2 and type(ct) == "table" and type(ct.SendReport) == "function" then
                ct.SendReport = function(...) end
                nlog("hook ToolsSendReport=OK")
            else
                nlog("hook ToolsSendReport=SKIP")
            end
        end)
    end
    nlog("bypass apply done")
end
pcall(function() _G.ApplyNewBypass() end)

-- L7: periodic re-apply (late-load modules + recreate proofing, idempotent via __NB* guards)
pcall(function()
    local function reapply()
        _G._NB_SILENT = true
        pcall(function() if _G.ApplyNewBypass then _G.ApplyNewBypass() end end)
        _G._NB_SILENT = nil
        pcall(function()
            local c = _G.__NIVO_CTX
            if c and c.keyPath then
                local lp = tostring(c.keyPath):gsub("keys%.txt$", "mods_debug.log")
                local f = io.open(lp, "a")
                if f then f:write("[NB] REAPPLY done\n"); f:flush(); f:close() end
            end
        end)
    end
    local started = false
    pcall(function()
        local tt = require("common.time_ticker")
        if tt and tt.AddTimerLoop then
            local ok, h = pcall(function() return tt.AddTimerLoop(60, reapply, tt.TIMER_INFINITE or -1, 0) end)
            if ok and h then started = true end
        end
    end)
    if not started then
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if pc and pc.AddGameTimer then pc:AddGameTimer(60, true, reapply) end
        end)
    end
end)

-- ============================================================
-- 3. SAFE IMPORTS
-- ============================================================
local require = require
local import = import
local isValid = slua.isValid
local pcall = pcall
local type = type
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local math = math
local string = string
local table = table
local os = os

local function safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

local InGameUITools = safe_require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
local SecurityCommonUtils = safe_require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
local UIUtil = safe_require("client.common.ui_util")
local time_ticker = safe_require("common.time_ticker")

local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
local SlateBlueprintLibrary = import("SlateBlueprintLibrary")
local FVector2DClass = _G.FVector2D
local FLinearColor = _G.FLinearColor
local FVector = _G.FVector

local FMarginClass = _G.FMargin
if not FMarginClass then pcall(function() FMarginClass = import("FMargin") end) end

-- ============================================================
-- WALLHACK
-- ============================================================
local function ApplyWallHack(localPlayer, enemy, pc)
    if not _G.CheatsEnabled then return end
    if _G.Mod_Wallhack_Enabled == false then return end
    if not slua.isValid(enemy) then return end
    local meshes = {}
    pcall(function()
        if slua.isValid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
        local SkelClass = import("SkeletalMeshComponent")
        if SkelClass then
            local childs = enemy:GetComponentsByClass(SkelClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for c = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(c-1) or childs[c]
                    if slua.isValid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
                end
            end
        end
    end)
    pcall(function()
        for _, comp in ipairs(meshes) do
            if slua.isValid(comp) then
                local ok, mat = pcall(function() return comp:GetMaterial(0) end)
                if ok and slua.isValid(mat) then
                    local ok2, base = pcall(function() return mat:GetBaseMaterial() end)
                    if ok2 and slua.isValid(base) then
                        base.bDisableDepthTest = true; base.BlendMode = 2
                    end
                end
                comp.UseScopeDistanceCulling = false
                comp.PrimitiveShadingStrategy = 1; comp.ShadingRate = 6
            end
        end
        local isVisible = false
        if slua.isValid(pc) and slua.isValid(enemy) and type(pc.LineOfSightTo) == "function" then
            pcall(function() isVisible = pc:LineOfSightTo(enemy) end)
        end
        local finalColor = isVisible and {R=0, G=255, B=0, A=255} or {R=255, G=0, B=0, A=255}
        local scale = {R=255, G=255, B=0, A=0}
        enemy._WH_MIDs = enemy._WH_MIDs or {}
        for _, comp in ipairs(meshes) do
            if slua.isValid(comp) then
                local ck = tostring(comp)
                enemy._WH_MIDs[ck] = enemy._WH_MIDs[ck] or {}
                for i = 0, 10 do
                    local ok3, mi = pcall(function() return comp:GetMaterial(i) end)
                    if not ok3 or not slua.isValid(mi) then break end
                    local mid = enemy._WH_MIDs[ck][i]
                    if not slua.isValid(mid) then
                        local ok4, nm = pcall(function() return comp:CreateAndSetMaterialInstanceDynamic(i) end)
                        if ok4 and slua.isValid(nm) then enemy._WH_MIDs[ck][i] = nm; mid = nm end
                    end
                    if slua.isValid(mid) then
                        pcall(function()
                            mid:SetVectorParameterValue("颜色", finalColor)
                            mid:SetVectorParameterValue("Color", finalColor)
                            mid:SetVectorParameterValue("BaseColor", finalColor)
                            mid:SetVectorParameterValue("BodyColor", finalColor)
                            mid:SetVectorParameterValue("DiffuseColor", finalColor)
                            mid:SetVectorParameterValue("ParaScaleOffset", scale)
                        end)
                    end
                end
            end
        end
    end)
end

-- ============================================================
-- COMMON HELPERS
-- ============================================================
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
    pcall(function() if pawn.TeamID ~= nil then teamID = pawn.TeamID end end)
    if teamID == 0 then
        pcall(function()
            local ps = pawn.PlayerState
            if isValid(ps) and ps.TeamID ~= nil then teamID = ps.TeamID end
        end)
    end
    return teamID
end

local function GetPawnHeadPos(pawn)
    local pos = nil
    pcall(function()
        if pawn.GetBonePos then
            pos = pawn:GetBonePos("head", { X = 0, Y = 0, Z = 0 })
        end
    end)
    if pos and not (pos.X == 0 and pos.Y == 0) then
        pos.Z = pos.Z + 18
        return pos
    end
    pcall(function() pos = pawn:K2_GetActorLocation() end)
    if pos then pos.Z = pos.Z + 108 end
    return pos
end

local function GetPlayerName(pawn)
    local name = nil
    pcall(function()
        if pawn.PlayerName ~= nil then
            local v = tostring(pawn.PlayerName)
            if v ~= " " and v ~= "Player Name" and v ~= "UNKNOWN" then name = v end
        end
    end)
    if not name then
        pcall(function()
            local ps = pawn.PlayerState
            if isValid(ps) then
                if ps.PlayerName ~= nil then
                    local v = tostring(ps.PlayerName)
                    if v ~= " " and v ~= "Player Name" and v ~= "UNKNOWN" then name = v end
                elseif ps.PlayerNameText ~= nil then
                    local v = tostring(ps.PlayerNameText)
                    if v ~= " " and v ~= "Player Name" and v ~= "UNKNOWN" then name = v end
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
                    if v ~= " " and v ~= "Player Name" and v ~= "UNKNOWN" then name = v end
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

local function IsTargetVisible(eyePos, targetPos, ignoredActors)
    local visible = false
    pcall(function()
        visible = Game:IsTargetPosVisible(eyePos, targetPos, ignoredActors or {})
    end)
    return visible
end

-- ============================================================
-- CANVAS HELPERS
-- ============================================================
local CanvasState = {
    Canvas = nil,
    CanvasScaleX = 1,
    CanvasScaleY = 1,
    CanvasOffsetX = 0,
    CanvasOffsetY = 0
}

local function GetESPCanvas()
    if CanvasState.Canvas and isValid(CanvasState.Canvas) then
        return CanvasState.Canvas
    end
    local MainControlBaseUI = nil
    pcall(function() MainControlBaseUI = InGameUITools.GetMainControlBaseUI() end)
    if not MainControlBaseUI or not isValid(MainControlBaseUI) then return nil end
    local ParentCanvas = nil
    pcall(function()
        if MainControlBaseUI.CanvasPanel_0 and isValid(MainControlBaseUI.CanvasPanel_0) then
            ParentCanvas = MainControlBaseUI.CanvasPanel_0
        elseif MainControlBaseUI.CanvasPanel_42 and isValid(MainControlBaseUI.CanvasPanel_42) then
            ParentCanvas = MainControlBaseUI.CanvasPanel_42
        end
    end)
    if ParentCanvas then
        CanvasState.Canvas = ParentCanvas
    end
    return ParentCanvas
end

local function UpdateCanvasTransform(PC)
    if not CanvasState.Canvas or not isValid(CanvasState.Canvas) then return end
    local success = false
    pcall(function()
        local SBL = SlateBlueprintLibrary
        if SBL and SBL.AbsoluteToLocal then
            local cg = CanvasState.Canvas:GetCachedGeometry()
            if cg then
                local pt0 = SBL.AbsoluteToLocal(cg, FVector2D(0,0))
                local pt1 = SBL.AbsoluteToLocal(cg, FVector2D(100,100))
                if pt0 and pt1 then
                    CanvasState.CanvasScaleX = (pt1.X - pt0.X) / 100
                    CanvasState.CanvasScaleY = (pt1.Y - pt0.Y) / 100
                    CanvasState.CanvasOffsetX = pt0.X
                    CanvasState.CanvasOffsetY = pt0.Y
                    success = true
                end
            end
        end
    end)
    if not success then
        local scale = 1.0
        local WLL = import("WidgetLayoutLibrary")
        if WLL and WLL.GetViewportScale then scale = WLL:GetViewportScale(PC) or 1.0 end
        CanvasState.CanvasScaleX = 1.0 / scale
        CanvasState.CanvasScaleY = 1.0 / scale
        CanvasState.CanvasOffsetX = 0
        CanvasState.CanvasOffsetY = 0
    end
end

local function ScreenPixelToCanvas(p)
    if not p then return FVector2D(0,0) end
    local sx = CanvasState.CanvasScaleX or 1.0
    local sy = CanvasState.CanvasScaleY or 1.0
    local ox = CanvasState.CanvasOffsetX or 0
    local oy = CanvasState.CanvasOffsetY or 0
    return FVector2D(p.X*sx+ox, p.Y*sy+oy)
end

local function ProjectToScreen(controller, worldPos)
    if not controller or not worldPos then return nil end
    local viewportSize = nil
    pcall(function() viewportSize = UIUtil.GetViewportSize() end)
    if not viewportSize or viewportSize.X <= 0 or viewportSize.Y <= 0 then return nil end

    local screenPos = FVector2D(0, 0)
    local ok = false
    pcall(function()
        ok = controller:ProjectWorldLocationToScreen(worldPos, screenPos, true)
    end)
    if not ok then
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
            local sx, sy = 0, 0
            if localZ > 0 then
                sx = (localX / localZ) / halfFOVTan
                sy = (localY / localZ) / (halfFOVTan / aspect)
                screenPos.X = (sx * 0.5 + 0.5) * viewportSize.X
                screenPos.Y = (sy * 0.5 + 0.5) * viewportSize.Y
                ok = true
            else
                local z = math.max(math.abs(localZ), 1.0)
                sx = (-localX / z) / halfFOVTan
                sy = (-localY / z) / (halfFOVTan / aspect)
                local mag = math.sqrt(sx * sx + sy * sy)
                if mag < 0.001 then
                    sx, sy = 0, -1
                else
                    sx, sy = sx / mag, sy / mag
                end
                local edgeX, edgeY = viewportSize.X * 0.5, viewportSize.Y * 0.5
                local dx, dy = sx * edgeX, sy * edgeY
                local tx = math.huge
                local ty = math.huge
                if math.abs(dx) > 0.001 then tx = edgeX / math.abs(dx) end
                if math.abs(dy) > 0.001 then ty = edgeY / math.abs(dy) end
                local t = math.min(tx, ty)
                screenPos.X = edgeX + dx * t
                screenPos.Y = edgeY + dy * t
                ok = true
            end
        end)
    end
    if not ok then return nil end
    screenPos.X = math.max(0, math.min(viewportSize.X, screenPos.X))
    screenPos.Y = math.max(0, math.min(viewportSize.Y, screenPos.Y))
    return screenPos
end

-- ============================================================
-- BORDER LINE HELPERS
-- ============================================================
local function CreateBorderLine(Canvas)
    if not Canvas or not isValid(Canvas) then return nil end
    local Border = nil
    pcall(function()
        Border = CGame:NewObjectFromPath("/Script/UMG.Border", Canvas)
    end)
    if not Border or not isValid(Border) then
        pcall(function()
            local BorderClass = import("/Script/UMG.Border")
            if not BorderClass then BorderClass = import("Border") end
            if BorderClass and BorderClass.NewObject then
                Border = BorderClass:NewObject(Canvas)
            end
        end)
    end
    if not Border or not isValid(Border) then return nil end

    pcall(function()
        Border:SetBrushColor(FLinearColor(0, 1, 0, 1))
        Border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        Border:SetRenderTransformPivot(FVector2D(0.0, 0.5))
    end)

    local Slot = nil
    pcall(function()
        Slot = Canvas:AddChildToCanvas(Border)
        if Slot then
            Slot:SetAutoSize(false)
            Slot:SetZOrder(9997)
        end
    end)
    if not Slot then return nil end
    return { Widget = Border, Slot = Slot }
end

local function UpdateBorderLine(lineData, canvasX1, canvasY1, canvasX2, canvasY2, thickness, color)
    if not lineData or not lineData.Widget or not lineData.Slot then return end
    local dx = canvasX2 - canvasX1
    local dy = canvasY2 - canvasY1
    local len = math.sqrt(dx*dx + dy*dy)
    if len < 0.5 then
        pcall(function() lineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
        return
    end
    local ang = (math.atan2 and math.atan2(dy,dx) or math.atan(dy,dx)) * (180.0/math.pi)
    pcall(function()
        lineData.Slot:SetPosition(FVector2D(canvasX1, canvasY1 - thickness/2))
        lineData.Slot:SetSize(FVector2D(len, thickness))
        lineData.Widget:SetRenderAngle(ang)
        if color then lineData.Widget:SetBrushColor(color) end
        lineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)
end

-- ============================================================
-- COLORS
-- ============================================================
local C_BG_GREEN  = FLinearColor(0.05, 0.80, 0.15, 0.92)
local C_BG_YELLOW = FLinearColor(0.95, 0.75, 0.05, 0.92)
local C_BG_RED    = FLinearColor(0.85, 0.05, 0.05, 0.92)
local C_BG_ORANGE = FLinearColor(0.00, 0.00, 0.00, 1.00)
local C_TX_WHITE  = FLinearColor(1.00, 1.00, 1.00, 1.00)

local HEAD_BOX_W        = 34
local HEAD_BOX_H        = 4
local HEAD_BOX_Y_OFFSET = -5

local BASE_FONT  = 10
local MIN_FONT   = 6
local NEAR_DIST  = 5
local FAR_DIST   = 50
local NEAR_SCALE = 1.00
local FAR_SCALE  = 0.35

local FOOT_TEXT_GAP = 4
local ACTOR_TO_FEET_M = 0.90

local KC_BOX_W = 76
local KC_BOX_H = 28
local KC_Y     = 30
local KC_GAP   = 4
local KC_FONT  = 13

-- ============================================================
-- UMG BUILDERS
-- ============================================================
local function NewUMG(path, outer)
    local obj = nil
    pcall(function()
        if CGame and CGame.NewObjectFromPath then
            obj = CGame:NewObjectFromPath(path, outer)
        end
    end)
    if not obj or not isValid(obj) then
        pcall(function()
            local cls = import(path)
            if cls and cls.NewObject then obj = cls:NewObject(outer) end
        end)
    end
    if not obj or not isValid(obj) then
        pcall(function()
            if slua and slua.NewObject then obj = slua.NewObject(path, outer) end
        end)
    end
    return obj
end

local function SetFontSize(txt, size)
    if not isValid(txt) then return end
    pcall(function() if txt.SetFontSize then txt:SetFontSize(size) end end)
    pcall(function()
        local f = txt.Font
        if f then
            f.Size = size
            if txt.SetFont then txt:SetFont(f) end
        end
    end)
    pcall(function()
        local SFC = import("SlateFontInfo")
        if SFC and txt.SetFont then
            local f = SFC()
            f.Size = size
            txt:SetFont(f)
        end
    end)
end

local function ClearOutlineAndShadow(txt)
    if not isValid(txt) then return end
    pcall(function()
        if txt.SetShadowColorAndOpacity then
            txt:SetShadowColorAndOpacity(FLinearColor(0, 0, 0, 0))
        end
    end)
    pcall(function()
        if txt.SetShadowOffset then
            txt:SetShadowOffset(FVector2D(0, 0))
        end
    end)
    pcall(function()
        local f = txt.Font
        if f and f.OutlineSettings then
            f.OutlineSettings.OutlineSize = 0
            f.OutlineSettings.OutlineColor = FLinearColor(0, 0, 0, 0)
            if txt.SetFont then txt:SetFont(f) end
        end
    end)
end

local function FontFromDistance(distM)
    if distM <= NEAR_DIST then return BASE_FONT end
    if distM >= FAR_DIST then return MIN_FONT end
    local t = (distM - NEAR_DIST) / (FAR_DIST - NEAR_DIST)
    local scale = NEAR_SCALE + (FAR_SCALE - NEAR_SCALE) * t
    local size = math.floor(BASE_FONT * scale + 0.5)
    if size < MIN_FONT then size = MIN_FONT end
    return size
end

-- ============================================================
-- HEAD BOX
-- ============================================================
local HeadBoxState = { Entries = {} }

local function CreateHeadBox(canvas)
    if not canvas or not isValid(canvas) then return nil end
    local border = NewUMG("/Script/UMG.Border", canvas)
    if not border or not isValid(border) then return nil end

    pcall(function() if border.SetBrushColor then border:SetBrushColor(C_BG_GREEN) end end)
    pcall(function() if border.SetVisibility then border:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end end)

    local slot = nil
    pcall(function() slot = canvas:AddChildToCanvas(border) end)
    if not slot then
        pcall(function() border:RemoveFromParent() end)
        return nil
    end

    pcall(function() if slot.SetAlignment then slot:SetAlignment(FVector2DClass(0.5, 0.5)) end end)
    pcall(function() if slot.SetAutoSize then slot:SetAutoSize(false) end end)
    pcall(function() if slot.SetSize then slot:SetSize(FVector2DClass(HEAD_BOX_W, HEAD_BOX_H)) end end)
    pcall(function() if slot.SetZOrder then slot:SetZOrder(9999) end end)

    return { border = border, slot = slot, last_color = nil, last_w = nil }
end

local function RemoveHeadBox(entry)
    if not entry then return end
    if isValid(entry.border) then
        pcall(function() entry.border:RemoveFromParent() end)
    end
end

local function UpdateHeadBox(entry, canvasX, canvasY, bgColor)
    if not entry then return end
    local border, slot = entry.border, entry.slot
    if not isValid(border) or not slot then return end

    if entry.last_color ~= bgColor then
        pcall(function() if border.SetBrushColor then border:SetBrushColor(bgColor) end end)
        entry.last_color = bgColor
    end

    if entry.last_w ~= HEAD_BOX_W then
        pcall(function()
            if slot.SetSize then
                slot:SetSize(FVector2DClass(HEAD_BOX_W, HEAD_BOX_H))
            end
        end)
        entry.last_w = HEAD_BOX_W
    end

    pcall(function()
        if slot.SetAlignment then
            slot:SetAlignment(FVector2DClass(0.5, 0.5))
        end
    end)
    pcall(function()
        if slot.SetPosition then
            slot:SetPosition(FVector2DClass(canvasX, canvasY + HEAD_BOX_Y_OFFSET))
        end
    end)
end

-- ============================================================
-- FOOT TEXT
-- ============================================================
local FootTextState = { Entries = {} }

local function CreateFootTextEntry(canvas)
    if not canvas or not isValid(canvas) then return nil end

    local text = NewUMG("/Script/UMG.TextBlock", canvas)
    if not text or not isValid(text) then return nil end

    pcall(function() if text.SetJustification then text:SetJustification(1) end end)
    pcall(function() if text.SetColorAndOpacity then text:SetColorAndOpacity(C_TX_WHITE) end end)
    pcall(function() if text.SetVisibility then text:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end end)

    ClearOutlineAndShadow(text)

    local slot = nil
    pcall(function() slot = canvas:AddChildToCanvas(text) end)
    if not slot then
        pcall(function() text:RemoveFromParent() end)
        return nil
    end

    pcall(function() if slot.SetAutoSize then slot:SetAutoSize(true) end end)
    pcall(function() if slot.SetZOrder then slot:SetZOrder(9998) end end)
    pcall(function()
        if slot.SetAlignment then
            slot:SetAlignment(FVector2DClass(0.5, 0.0))
        end
    end)

    return {
        text = text,
        slot = slot,
        last_text = nil,
        last_font = nil,
    }
end

local function RemoveFootTextEntry(entry)
    if not entry then return end
    if isValid(entry.text) then
        pcall(function() entry.text:RemoveFromParent() end)
    end
end

local function UpdateFootTextEntry(entry, canvasX, canvasY, label, fontSize)
    if not entry then return end
    local txt, slot = entry.text, entry.slot
    if not isValid(txt) or not slot then return end

    if entry.last_font ~= fontSize then
        SetFontSize(txt, fontSize)
        ClearOutlineAndShadow(txt)
        pcall(function() if txt.SetColorAndOpacity then txt:SetColorAndOpacity(C_TX_WHITE) end end)
        entry.last_font = fontSize
    end
    if entry.last_text ~= label then
        pcall(function() if txt.SetText then txt:SetText(label) end end)
        entry.last_text = label
    end

    pcall(function() if txt.SetColorAndOpacity then txt:SetColorAndOpacity(C_TX_WHITE) end end)

    pcall(function()
        if slot.SetAlignment then
            slot:SetAlignment(FVector2DClass(0.5, 0.0))
        end
    end)
    pcall(function()
        if slot.SetPosition then
            slot:SetPosition(FVector2DClass(canvasX, canvasY))
        end
    end)
end

-- ============================================================
-- LINE ESP
-- ============================================================
local LineState = { Lines = {} }

local function DrawLineESP(controller, pawn, visible, canvas)
    if not isValid(controller) or not isValid(pawn) then return nil, nil end
    if not canvas or not isValid(canvas) then return nil, nil end

    local pawnKey = pawn
    local headWorld = GetPawnHeadPos(pawn)
    if not headWorld then return nil, nil end

    local headScreen = ProjectToScreen(controller, headWorld)
    if not headScreen then return nil, nil end

    local headCanvas = ScreenPixelToCanvas(headScreen)

    local viewportSize = nil
    pcall(function() viewportSize = UIUtil.GetViewportSize() end)
    if not viewportSize then return nil, nil end

    local originScreen = FVector2D(viewportSize.X / 2, 70)
    local originCanvas = ScreenPixelToCanvas(originScreen)

    if not LineState.Lines[pawnKey] then
        local lineData = CreateBorderLine(canvas)
        if lineData then
            LineState.Lines[pawnKey] = lineData
        end
    end

    local lineData = LineState.Lines[pawnKey]
    if lineData then
        local lineColor
        if visible then
            lineColor = FLinearColor(0.0, 1.0, 0.0, 1.0)
        else
            lineColor = FLinearColor(1.0, 0.0, 0.0, 1.0)
        end
        local thickness = 1.5
        UpdateBorderLine(lineData, originCanvas.X, originCanvas.Y,
                         headCanvas.X, headCanvas.Y, thickness, lineColor)
    end

    return true, headCanvas
end

-- ============================================================
-- ENEMY COUNTER
-- ============================================================
local CounterState = {
    boxReal = nil, txtReal = nil,
    boxBot  = nil, txtBot  = nil,
    lastText = nil,
    ctl = nil, pawn = nil,
}

local function KC_IsBotOrAI(pawn)
    if not pawn then return false end
    local r = false
    local function T(v) if v == true or v == 1 then r = true end end
    pcall(function() if Game and Game.IsAI  then T(Game:IsAI(pawn))  end end); if r then return true end
    pcall(function() if Game and Game.IsBot then T(Game:IsBot(pawn)) end end); if r then return true end
    pcall(function() if pawn.IsAI  then T(pawn:IsAI())  end end);             if r then return true end
    pcall(function() if pawn.IsBot then T(pawn:IsBot()) end end);             if r then return true end
    pcall(function() T(pawn.bIsAI) end);                                      if r then return true end
    pcall(function() T(pawn.bIsBot) end);                                     if r then return true end
    pcall(function()
        local ps = pawn.PlayerState
        if slua.isValid(ps) then
            if ps.IsAI  then T(ps:IsAI())  end
            if ps.IsBot then T(ps:IsBot()) end
            T(ps.bIsAI); T(ps.bIsBot)
        end
    end)
    return r
end

local function KC_MakeBox(canvas, xPos, bgColor, label)
    if not canvas or not isValid(canvas) then return nil, nil end

    local border = NewUMG("/Script/UMG.Border", canvas)
    if not border or not isValid(border) then return nil, nil end
    local text = NewUMG("/Script/UMG.TextBlock", canvas)
    if not text or not isValid(text) then
        pcall(function() border:RemoveFromParent() end)
        return nil, nil
    end

    pcall(function() if border.SetContent then border:SetContent(text) end end)
    pcall(function()
        if border.SetPadding and FMarginClass then
            border:SetPadding(FMarginClass(4, 2, 4, 2))
        end
    end)
    pcall(function() if border.SetBrushColor then border:SetBrushColor(bgColor) end end)
    pcall(function() if border.SetVisibility then border:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end end)

    pcall(function() if text.SetJustification then text:SetJustification(1) end end)
    pcall(function() if text.SetColorAndOpacity then text:SetColorAndOpacity(C_TX_WHITE) end end)
    pcall(function() if text.SetVisibility then text:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end end)
    SetFontSize(text, KC_FONT)
    ClearOutlineAndShadow(text)
    pcall(function() if text.SetText then text:SetText(label or "") end end)

    local slot = nil
    pcall(function() slot = canvas:AddChildToCanvas(border) end)
    if not slot then
        pcall(function() border:RemoveFromParent() end)
        pcall(function() text:RemoveFromParent() end)
        return nil, nil
    end

    pcall(function() if slot.SetAlignment then slot:SetAlignment(FVector2DClass(0.5, 0.0)) end end)
    pcall(function() if slot.SetAutoSize then slot:SetAutoSize(false) end end)
    pcall(function() if slot.SetSize then slot:SetSize(FVector2DClass(KC_BOX_W, KC_BOX_H)) end end)
    pcall(function() if slot.SetZOrder then slot:SetZOrder(12000) end end)
    pcall(function() if slot.SetPosition then slot:SetPosition(FVector2DClass(xPos, KC_Y)) end end)

    return border, text, slot
end

local function KC_Drop()
    if isValid(CounterState.boxReal) then pcall(function() CounterState.boxReal:RemoveFromParent() end) end
    if isValid(CounterState.boxBot)  then pcall(function() CounterState.boxBot:RemoveFromParent()  end) end
    CounterState.boxReal, CounterState.txtReal = nil, nil
    CounterState.boxBot,  CounterState.txtBot  = nil, nil
    CounterState.lastText = nil
end

local function KC_EnsureBoxes(canvas)
    if isValid(CounterState.boxReal) and isValid(CounterState.boxBot) then return true end

    KC_Drop()

    local vpX = 1920
    pcall(function()
        local vp = nil
        if UIUtil and UIUtil.GetViewportSize then vp = UIUtil.GetViewportSize() end
        if vp and vp.X > 0 then vpX = vp.X end
    end)

    local centerX = vpX * 0
    local totalW = KC_BOX_W * 2 + KC_GAP
    local realX = centerX - totalW * -7.66 + KC_BOX_W * -7.66
    local botX  = realX + KC_BOX_W + KC_GAP

    local rBox, rTxt = KC_MakeBox(canvas, realX, C_BG_RED,   "REAL: 0")
    local bBox, bTxt = KC_MakeBox(canvas, botX,  C_BG_GREEN, "BOT: 0")

    if not (isValid(rBox) and isValid(bBox)) then
        if isValid(rBox) then pcall(function() rBox:RemoveFromParent() end) end
        if isValid(bBox) then pcall(function() bBox:RemoveFromParent() end) end
        return false
    end

    CounterState.boxReal, CounterState.txtReal = rBox, rTxt
    CounterState.boxBot,  CounterState.txtBot  = bBox, bTxt
    return true
end

local function KC_Tick(controller, currentPawn, canvas)
    if not _G.Mod_EnemyCounter_Enabled then
        if isValid(CounterState.boxReal) then pcall(function() CounterState.boxReal:SetVisibility(UEnums.ESlateVisibility.Collapsed) end) end
        if isValid(CounterState.boxBot)  then pcall(function() CounterState.boxBot:SetVisibility(UEnums.ESlateVisibility.Collapsed)  end) end
        return
    end

    if not isValid(controller) or not isValid(currentPawn) or not canvas or not isValid(canvas) then return end

    local myTeamID = GetTeamID(currentPawn)
    local playerCount, botCount = 0, 0
    local livePawns = Game:GetAllPlayerPawns() or {}
    for _, pawn in pairs(livePawns) do
        if isValid(pawn) and pawn ~= currentPawn then
            local sameTeam = false
            pcall(function()
                if pawn.TeamID ~= nil and pawn.TeamID == myTeamID then sameTeam = true end
            end)
            if not sameTeam and IsPawnAlive(pawn) then
                if KC_IsBotOrAI(pawn) then botCount = botCount + 1
                else playerCount = playerCount + 1 end
            end
        end
    end

    local key = playerCount .. "|" .. botCount
    if CounterState.lastText == key then
        if isValid(CounterState.boxReal) then pcall(function() CounterState.boxReal:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end) end
        if isValid(CounterState.boxBot)  then pcall(function() CounterState.boxBot:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)  end) end
        return
    end

    if not KC_EnsureBoxes(canvas) then return end

    if isValid(CounterState.txtReal) then
        pcall(function() CounterState.txtReal:SetText(string.format("REAL %d", playerCount)) end)
    end
    if isValid(CounterState.txtBot) then
        pcall(function() CounterState.txtBot:SetText(string.format("BOT %d", botCount)) end)
    end

    if isValid(CounterState.boxReal) then pcall(function() CounterState.boxReal:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end) end
    if isValid(CounterState.boxBot)  then pcall(function() CounterState.boxBot:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)  end) end

    CounterState.lastText = key
end

-- ============================================================
-- AIMBOT
-- ============================================================
_G._AimbotCurrentPC = nil

ApplyHardAimbot = function()
    if not _G.CheatsEnabled then return end
    if _G.Mod_Aimbot_Enabled == false then return end
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end

        local char = pc:GetPlayerCharacterSafety()
        if not isValid(char) then return end

        local wm = char.WeaponManagerComponent
        if not isValid(wm) then return end

        -- Weapon source: local authoritative pehle (first-equip race fix), replicated fallback
        local weapon = nil
        pcall(function()
            if char.GetCurrentWeapon then
                local w = char:GetCurrentWeapon()
                if isValid(w) then weapon = w end
            end
        end)
        if not isValid(weapon) then
            weapon = wm.CurrentWeaponReplicated
        end
        if not isValid(weapon) then return end

        -- Entity resolver: har gun par alag path ho sakta hai (AUG=direct, baaki=method/nested)
        local entity = nil
        pcall(function()
            if isValid(weapon.ShootWeaponEntityComp) then
                entity = weapon.ShootWeaponEntityComp
            end
        end)
        if not isValid(entity) then
            pcall(function()
                if weapon.GetShootWeaponEntityComponent then
                    local e = weapon:GetShootWeaponEntityComponent()
                    if isValid(e) then entity = e end
                end
            end)
        end
        if not isValid(entity) then
            pcall(function()
                local swc = weapon.ShootWeaponComponent
                if isValid(swc) and isValid(swc.ShootWeaponEntityComponent) then
                    entity = swc.ShootWeaponEntityComponent
                end
            end)
        end
        if not isValid(entity) then return end

        -- MODERATE MAGNET (ban-safe: recoil/shake untouched, stats human-like)
        -- Slider: Mod_AimbotStrength 0-100 -> magnet speed scale (default 80)
        local sm = 0.5 + ((_G.Mod_AimbotStrength or 80) / 100)
        if entity.AutoAimingConfig then
            for _, range in ipairs({"OuterRange", "InnerRange"}) do
                local cfg = entity.AutoAimingConfig[range]
                if cfg then
                    cfg.Speed = 3.5 * sm
                    cfg.RangeRate = 3.5 * sm
                    cfg.SpeedRate = 3.5 * sm
                    cfg.RangeRateSight = 3.5 * sm
                    cfg.SpeedRateSight = 3.5 * sm
                    cfg.CrouchRate = 4.0
                    cfg.ProneRate = 3.0
                    cfg.DyingRate = 0
                    cfg.adsorbMaxRange = 250
                    cfg.adsorbMinRange = 20
                    cfg.adsorbMinAttenuationDis = 100
                    cfg.adsorbMaxAttenuationDis = 8000
                    cfg.adsorbActiveMinRange = 20
                end
            end
            entity.AutoAimingConfig = entity.AutoAimingConfig
        end
    end)
end

AttachAimbotTimer = function()
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        if pc == _G._AimbotCurrentPC then return end
        _G._AimbotCurrentPC = pc
        if pc.AddGameTimer then
            pc:AddGameTimer(0.1, true, function()
                if not isValid(_G._AimbotCurrentPC) then
                    _G._AimbotCurrentPC = nil
                    return
                end
                ApplyHardAimbot()
            end)
        end
    end)
end

AttachAimbotTimer()

pcall(function()
    local pc = slua_GameFrontendHUD:GetPlayerController()
    if isValid(pc) and pc.AddGameTimer then
        pc:AddGameTimer(2.0, true, function()
            if not isValid(_G._AimbotCurrentPC) then
                _G._AimbotCurrentPC = nil
                AttachAimbotTimer()
                pcall(function() if _G.ApplyNewBypass then _G.ApplyNewBypass() end end)
            end
        end)
    end
end)

-- ============================================================
-- FORCE TPP IN FPP MATCH (ported, stacking-timer leak fixed)
-- ============================================================
local FORCE_TPP_TIMER = nil
local FORCE_TPP_SCOPE_TIMER = nil
local _TPP_HOOKED = false
local _IsScopeOpen = false

local function CheckScopeState()
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not pc then return end
        local uPawn = pc:GetPlayerCharacterSafety()
        if not slua.isValid(uPawn) then return end
        if uPawn.bIsWeaponAiming or uPawn.bIsGunADS then _IsScopeOpen = true else _IsScopeOpen = false end
    end)
end

local function ForceTPPView()
    if not _G.CheatsEnabled then return end
    if not _G.Mod_ForceTPP_Enabled then return end
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not pc then return end
        local uPawn = pc:GetPlayerCharacterSafety()
        if not slua.isValid(uPawn) then return end
        if uPawn.bIsWeaponAiming or uPawn.bIsGunADS then return end
        if uPawn.SetCurrentPersonPerspective then uPawn:SetCurrentPersonPerspective(false, false) end
        if uPawn.LocalSwitchPersonPerspective then uPawn:LocalSwitchPersonPerspective(false, true, true) end
        if pc.SwitchFpp then pc:SwitchFpp(false) end
        if SI_BattleInterface and SI_BattleInterface.ClientSetFpp then SI_BattleInterface.ClientSetFpp(uPawn, false) end
        if slua.isValid(pc.PlayerCameraManager) then pc.PlayerCameraManager:SetCameraMode(0) end
        if CGameState and CGameState.IsFPPGameMode then CGameState.IsFPPGameMode = false end
        if uPawn.GetIsFPP and not _TPP_HOOKED then
            local oldFPP = uPawn.GetIsFPP
            uPawn.GetIsFPP = function()
                if _G.Mod_ForceTPP_Enabled then
                    if _IsScopeOpen then return true end
                    return false
                end
                return oldFPP()
            end
            _TPP_HOOKED = true
        end
    end)
end

local function StartForceTPP()
    if FORCE_TPP_TIMER then
        pcall(function()
            if _G.Game then _G.Game:RemoveGameTimer(FORCE_TPP_TIMER) end
        end)
        FORCE_TPP_TIMER = nil
    end
    if FORCE_TPP_SCOPE_TIMER then
        pcall(function()
            local pc0 = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc0) and pc0.RemoveGameTimer then pc0:RemoveGameTimer(FORCE_TPP_SCOPE_TIMER) end
        end)
        FORCE_TPP_SCOPE_TIMER = nil
    end
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        FORCE_TPP_SCOPE_TIMER = pc:AddGameTimer(0.05, true, CheckScopeState)
        FORCE_TPP_TIMER = pc:AddGameTimer(0.2, true, ForceTPPView)
        print("[FORCE TPP] Started! Scope will work normally!")
        return true
    end
    return false
end

local function StopForceTPP()
    if FORCE_TPP_SCOPE_TIMER then
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) and pc.RemoveGameTimer then pc:RemoveGameTimer(FORCE_TPP_SCOPE_TIMER) end
        end)
        FORCE_TPP_SCOPE_TIMER = nil
    end
    if FORCE_TPP_TIMER then
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) and pc.RemoveGameTimer then pc:RemoveGameTimer(FORCE_TPP_TIMER) end
        end)
        FORCE_TPP_TIMER = nil
    end
    _TPP_HOOKED = false
    _IsScopeOpen = false
    print("[FORCE TPP] Stopped")
end

_G.StartForceTPP = StartForceTPP
_G.StopForceTPP = StopForceTPP

local _iPadViewLastPawn = nil
local _iPadViewDefaultFOV = nil
local function ApplyIPadView(currentPawn)
    if not _G.CheatsEnabled then return end
    if not slua.isValid(currentPawn) then return end
    local cam = currentPawn.ThirdPersonCameraComponent
    if not slua.isValid(cam) then return end

    if _iPadViewLastPawn ~= currentPawn then
        _iPadViewLastPawn = currentPawn
        _iPadViewDefaultFOV = cam.FieldOfView
    elseif _iPadViewDefaultFOV == nil then
        _iPadViewDefaultFOV = cam.FieldOfView
    end

    local isAiming = (currentPawn.bIsWeaponAiming == true) or (currentPawn.bIsGunADS == true)
    if _G.Mod_iPadView_Enabled == true and not isAiming then
        local targetFOV = tonumber(_G.Mod_iPadViewFOV) or 110
        if targetFOV < 90 then targetFOV = 90 end
        if targetFOV > 130 then targetFOV = 130 end
        cam.FieldOfView = targetFOV
    elseif _iPadViewDefaultFOV ~= nil then
        cam.FieldOfView = _iPadViewDefaultFOV
    end
end

-- ============================================================
-- CLEANUP
-- ============================================================
local function ResetCaches()
    for pawnKey, lineData in pairs(LineState.Lines) do
        pcall(function() if lineData and lineData.Widget then lineData.Widget:RemoveFromParent() end end)
    end
    LineState.Lines = {}

    for pawnKey, entry in pairs(HeadBoxState.Entries) do
        RemoveHeadBox(entry)
    end
    HeadBoxState.Entries = {}

    for pawnKey, entry in pairs(FootTextState.Entries) do
        RemoveFootTextEntry(entry)
    end
    FootTextState.Entries = {}

    KC_Drop()

    CanvasState.Canvas = nil
end

-- ============================================================
-- PERFORMANCE CACHES
-- ============================================================
local tickCounter = 0
local VisibilityCache = {}
local HeadPosCache = {}
local ActorPosCache = {}
-- Aimbot fns neeche define (forward decl taaki MainTick re-attach kar sake)
local ApplyHardAimbot = nil
local AttachAimbotTimer = nil

local CACHE_TTL_VIS   = 1.0
local CACHE_TTL_HEAD  = 0.10
local CACHE_TTL_ACTOR = 0.10

-- ============================================================
-- MAIN TICK (OPTIMIZED FOR FPS) — ESP DISTANCE 500m FIXED
-- ============================================================
local function MainTick()
    pcall(function()
        if not _G.CheatsEnabled then return end

        tickCounter = tickCounter + 1
        if tickCounter > 1000000 then tickCounter = 0 end

        local controller = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not (isValid(controller) and Game:IsClassOf(controller, ASTExtraPlayerController)) then
            return
        end

        -- Aimbot re-attach (respawn/pc-change: pc-bound timers purane pc ke saath marte hain)
        if tickCounter % 30 == 1 and _G.Mod_Aimbot_Enabled ~= false then
            pcall(function()
                if not isValid(_G._AimbotCurrentPC) then
                    _G._AimbotCurrentPC = nil
                end
                if controller ~= _G._AimbotCurrentPC and AttachAimbotTimer then
                    AttachAimbotTimer()
                    if ApplyHardAimbot then ApplyHardAimbot() end
                end
            end)
        end

        -- Weapon-switch instant apply (first-equip race fix: object badla to turant magnet)
        if _G.Mod_Aimbot_Enabled ~= false then
            pcall(function()
                local w = nil
                if currentPawn and currentPawn.GetCurrentWeapon then
                    local cw = currentPawn:GetCurrentWeapon()
                    if isValid(cw) then w = cw end
                end
                if w ~= _G._AimbotLastWeapon then
                    _G._AimbotLastWeapon = w
                    if w ~= nil and ApplyHardAimbot then ApplyHardAimbot() end
                end
            end)
        end

        local currentPawn = controller:GetCurPawn()
        if not isValid(currentPawn) then return end
        ApplyIPadView(currentPawn)

        local canvas = GetESPCanvas()
        if canvas then UpdateCanvasTransform(controller) end

        -- Slider drag poll (fixx2 menu, timer-free, touch reliable)
        if _G._SliderDrag then pcall(function()
            local sd = _G._SliderDrag
            if not sd then return end
            sd.n = (sd.n or 0) + 1
            local mx, my = 0, 0
            local gmp = _G.GetMousePos
            if gmp then mx, my = gmp() end
            if mx == 0 and my == 0 then
                pcall(function()
                    local pcx = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                    if slua.isValid(pcx) and pcx.GetInputMousePosition then
                        local ok, ax, ay = pcall(pcx.GetInputMousePosition, pcx)
                        if ok and type(ax) == "number" and type(ay) == "number" and (ax ~= 0 or ay ~= 0) then mx, my = ax, ay end
                    end
                end)
            end
            if mx == 0 and my == 0 then return end
            -- viewport->canvas: ESP wala proven transform (menuScaleX galat scale deta tha = minus-jump bug)
            local sc = CanvasState.CanvasScaleX or CanvasState.CanvasScaleY or 1
            local ox = CanvasState.CanvasOffsetX or 0
            if type(sc) ~= "number" or sc <= 0 then sc = sd.sc or 1 ox = 0 end
            local mxl = mx * sc + ox
            local t = (mxl - (sd.tx0 or 0)) / math.max(1, ((sd.tx1 or 0) - (sd.tx0 or 0)))
            if t < 0 then t = 0 end
            if t > 1 then t = 1 end
            local mn, mxv, st = (sd.min or 0), (sd.max or 100), (sd.step or 1)
            local nv = mn + math.floor(t * (mxv - mn) / st + 0.5) * st
            if nv < mn then nv = mn end
            if nv > mxv then nv = mxv end
            if sd.feat and sd.feat.get and nv ~= sd.feat.get() then
                sd.feat.set(nv)
                if sd.valLabel and slua.isValid(sd.valLabel) and sd.valLabel.SetText then
                    sd.valLabel:SetText(tostring(nv))
                end
                if sd.paint then sd.paint(nv) end
            end
        end) end

        -- ENEMY COUNTER (har 10th frame)
        if canvas and (tickCounter % 10 == 0) then
            KC_Tick(controller, currentPawn, canvas)
        end

        -- EARLY EXIT
        if _G.Mod_ESP_Line_Enabled ~= true 
           and _G.Mod_ESP_Text_Enabled ~= true 
           and _G.Mod_Wallhack_Enabled ~= true then 
            return 
        end

        local myTeamID = GetTeamID(currentPawn)
        local myPos = currentPawn:K2_GetActorLocation()
        if not myPos then return end

        local myEyePos = myPos
        pcall(function()
            if currentPawn.GetHeadLocation then 
                myEyePos = currentPawn:GetHeadLocation(false) or myPos 
            end
        end)

        local viewportSize = nil
        pcall(function() viewportSize = UIUtil.GetViewportSize() end)
        local vpY = viewportSize and viewportSize.Y or 1080
        local vpX = viewportSize and viewportSize.X or 1920
        local canvasScaleY = CanvasState.CanvasScaleY or 1.0

        -- ✅ ESP DISTANCE: 500 METERS FIXED
        local maxDistCm = 500 * 100  -- 50000 cm = 500m

        local wallhackOn = _G.Mod_Wallhack_Enabled
        local wallhackFrame = (tickCounter % 6 == 0)
        local now = os.clock()

        local livePawns = Game:GetAllPlayerPawns() or {}
        local usedLines = {}
        local usedHeadBox = {}
        local usedFootText = {}

        for _, pawn in pairs(livePawns) do
            if isValid(pawn) and pawn ~= currentPawn and pawn.TeamID ~= myTeamID and IsPawnAlive(pawn) then

                -- CACHED ACTOR POSITION
                local cachedActor = ActorPosCache[pawn]
                local enemyPos
                if cachedActor and (now - cachedActor.t) < CACHE_TTL_ACTOR then
                    enemyPos = cachedActor.pos
                else
                    enemyPos = pawn:K2_GetActorLocation()
                    ActorPosCache[pawn] = { pos = enemyPos, t = now }
                end

                if enemyPos then
                    local dx = enemyPos.X - myPos.X
                    local dy = enemyPos.Y - myPos.Y
                    local dz = enemyPos.Z - myPos.Z
                    local distCm = math.sqrt(dx*dx + dy*dy + dz*dz)

                    -- ✅ DISTANCE CULLING: 500m
                    if distCm < maxDistCm then
                        local distM = distCm / 100.0

                        -- WALLHACK (throttled — har 6th frame)
                        if wallhackOn and wallhackFrame then
                            pcall(ApplyWallHack, currentPawn, pawn, controller)
                        end

                        -- CACHED HEAD POSITION
                        local cachedHead = HeadPosCache[pawn]
                        local headPos
                        if cachedHead and (now - cachedHead.t) < CACHE_TTL_HEAD then
                            headPos = cachedHead.pos
                        else
                            pcall(function()
                                if pawn.GetBonePos then 
                                    headPos = pawn:GetBonePos("head", {X=0,Y=0,Z=0}) 
                                end
                            end)
                            if not headPos then
                                headPos = {X=enemyPos.X, Y=enemyPos.Y, Z=enemyPos.Z + 70}
                            end
                            HeadPosCache[pawn] = { pos = headPos, t = now }
                        end

                        -- CACHED VISIBILITY
                        local visible
                        if distM > 500 then
                            visible = true
                        else
                            local cacheKey = tostring(pawn)
                            local cachedVis = VisibilityCache[cacheKey]
                            if cachedVis and (now - cachedVis.t) < CACHE_TTL_VIS then
                                visible = cachedVis.v
                            else
                                visible = IsTargetVisible(myEyePos, headPos, {currentPawn})
                                VisibilityCache[cacheKey] = { v = visible, t = now }
                            end
                        end

                        local hp, knock = GetHealthInfo(pawn)

                        local bgColor
                        if knock then
                            bgColor = C_BG_ORANGE
                        elseif hp >= 0.70 then
                            bgColor = C_BG_GREEN
                        elseif hp >= 0.30 then
                            bgColor = C_BG_YELLOW
                        else
                            bgColor = C_BG_RED
                        end

                        -- LINE ESP
                        local headCanvas = nil
                        if canvas and _G.Mod_ESP_Line_Enabled then
                            local ok, hc = DrawLineESP(controller, pawn, visible, canvas)
                            if ok then
                                usedLines[pawn] = true
                                headCanvas = hc
                            end
                        end

                        -- HP BAR + FOOT TEXT
                        if canvas and _G.Mod_ESP_Text_Enabled then
                            local headWorldT = headPos
                            if headWorldT then
                                headWorldT = {X=headWorldT.X, Y=headWorldT.Y, Z=headWorldT.Z + 18}
                            end
                            local headScreenT = headWorldT and ProjectToScreen(controller, headWorldT) or nil
                            
                            -- FOV CULLING
                            if headScreenT and headScreenT.X >= 0 and headScreenT.X <= vpX 
                               and headScreenT.Y >= 0 and headScreenT.Y <= vpY then
                                
                                local hc = headCanvas or ScreenPixelToCanvas(headScreenT)

                                -- HP BAR
                                local hbox = HeadBoxState.Entries[pawn]
                                if not hbox then
                                    hbox = CreateHeadBox(canvas)
                                    if hbox then HeadBoxState.Entries[pawn] = hbox end
                                end
                                if hbox then
                                    UpdateHeadBox(hbox, hc.X, hc.Y, bgColor)
                                    usedHeadBox[pawn] = true
                                end

                                -- FOOT TEXT
                                local actorScreen = ProjectToScreen(controller, enemyPos)
                                if actorScreen then
                                    local ac = ScreenPixelToCanvas(actorScreen)

                                    local feetOffsetPx = (ACTOR_TO_FEET_M / (2.0 * math.max(distM, 0.5))) * vpY * canvasScaleY
                                    if feetOffsetPx > 200 then feetOffsetPx = 200 end
                                    if feetOffsetPx < 3 then feetOffsetPx = 3 end

                                    local textY = ac.Y + feetOffsetPx + FOOT_TEXT_GAP
                                    local textX = ac.X

                                    local fontSize = FontFromDistance(distM)

                                    local name = GetPlayerName(pawn)
                                    local maxChars = math.max(4, math.floor(14 * (fontSize / BASE_FONT)))
                                    if #name > maxChars then name = string.sub(name, 1, maxChars) .. ".." end

                                    local label = string.format("%s\n%dm", name, math.floor(distM))

                                    local entry = FootTextState.Entries[pawn]
                                    if not entry then
                                        entry = CreateFootTextEntry(canvas)
                                        if entry then FootTextState.Entries[pawn] = entry end
                                    end
                                    if entry then
                                        UpdateFootTextEntry(entry, textX, textY, label, fontSize)
                                        usedFootText[pawn] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- CLEANUP
        for pawnKey, lineData in pairs(LineState.Lines) do
            if not usedLines[pawnKey] or not isValid(pawnKey) then
                pcall(function() 
                    if lineData and lineData.Widget then 
                        lineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) 
                    end 
                end)
            end
            if not isValid(pawnKey) then
                pcall(function() 
                    if lineData and lineData.Widget then 
                        lineData.Widget:RemoveFromParent() 
                    end 
                end)
                LineState.Lines[pawnKey] = nil
                VisibilityCache[pawnKey] = nil
                HeadPosCache[pawnKey] = nil
                ActorPosCache[pawnKey] = nil
            end
        end

        for pawnKey, entry in pairs(HeadBoxState.Entries) do
            if not usedHeadBox[pawnKey] or not isValid(pawnKey) then
                RemoveHeadBox(entry)
                HeadBoxState.Entries[pawnKey] = nil
            end
        end

        for pawnKey, entry in pairs(FootTextState.Entries) do
            if not usedFootText[pawnKey] or not isValid(pawnKey) then
                RemoveFootTextEntry(entry)
                FootTextState.Entries[pawnKey] = nil
            end
        end

        -- Cache cleanup (har 10 sec)
        if tickCounter % 600 == 0 then
            for k in pairs(VisibilityCache) do
                if not isValid(k) then VisibilityCache[k] = nil end
            end
            for k in pairs(HeadPosCache) do
                if not isValid(k) then HeadPosCache[k] = nil end
            end
            for k in pairs(ActorPosCache) do
                if not isValid(k) then ActorPosCache[k] = nil end
            end
        end
    end)
end

-- ============================================================
-- TIMER MANAGEMENT (FIXED 30 FPS TICK RATE)
-- ============================================================
local TimerState = { Timer = nil, Started = false, TimerOwner = nil }

local function StartTimer()
    -- _G singleton: purana loop pehle maaro (reload stacking khatam, hamesha exactly 1 loop)
    pcall(function()
        local old = _G._NIVO_ESPTIMER
        if old ~= nil then
            if type(old) == "table" and old.owner and old.owner.RemoveGameTimer and slua.isValid(old.owner) then
                old.owner:RemoveGameTimer(old.handle)
            elseif time_ticker and time_ticker.RemoveTimer then
                pcall(function() time_ticker.RemoveTimer(old.handle or old) end)
            end
        end
        _G._NIVO_ESPTIMER = nil
    end)
    if TimerState.Started and TimerState.Timer then return true end
    TimerState.Started = false
    TimerState.Timer = nil
    TimerState.TimerOwner = nil

    -- ✅ FIXED 30 FPS tick rate (PerfMode removed)
    local tickRate = 0.033

    local ok1, handle1 = pcall(function()
        return time_ticker.AddTimerLoop(tickRate, function() MainTick() end,
            time_ticker.TIMER_INFINITE or -1, tickRate)
    end)
    if ok1 and handle1 then
        TimerState.Timer = handle1
        TimerState.Started = true
        _G._NIVO_ESPTIMER = { handle = handle1 }
        pcall(MainTick)
        return true
    end

    local controller = nil
    pcall(function()
        controller = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    end)
    if isValid(controller) and controller.AddGameTimer then
        local ok3, handle3 = pcall(function()
            return controller:AddGameTimer(tickRate, true, function() MainTick() end)
        end)
        if ok3 and handle3 then
            TimerState.Timer = handle3
            TimerState.TimerOwner = controller
            TimerState.Started = true
            _G._NIVO_ESPTIMER = { handle = handle3, owner = controller }
            pcall(MainTick)
            return true
        end
    end

    pcall(MainTick)
    return false
end

local function StopTimer()
    if TimerState.Timer then
        pcall(function()
            if TimerState.TimerOwner then
                if TimerState.TimerOwner.RemoveGameTimer then
                    TimerState.TimerOwner:RemoveGameTimer(TimerState.Timer)
                end
            else
                if time_ticker and time_ticker.RemoveTimer then
                    time_ticker.RemoveTimer(TimerState.Timer)
                end
            end
        end)
    end
    TimerState.Timer = nil
    TimerState.TimerOwner = nil
    TimerState.Started = false
    _G._NIVO_ESPTIMER = nil

    VisibilityCache = {}
    HeadPosCache = {}
    ActorPosCache = {}

    ResetCaches()
end

-- ============================================================
-- DRAVIX MENU (extended features)
-- ============================================================
if not _G.CounterLog then
    _G.CounterLog = function(m) pcall(function() print("[MENU] " .. tostring(m)) end) end
end

-- ============================================================
-- MENU SETTERS (1.lua features only)
-- ============================================================
local function setESPVal(id, v)
    if id == "Aimbot" then _G.Mod_Aimbot_Enabled = v; return true end
    if id == "AimbotStrength" then _G.Mod_AimbotStrength = v; return true end
    if id == "Wallhack" then _G.Mod_Wallhack_Enabled = v; return true end
    if id == "LineESP" then
        _G.Mod_ESP_Line_Enabled = v
        if not v then
            for _, lineData in pairs(LineState.Lines) do
                pcall(function() if lineData and lineData.Widget then lineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end end)
            end
        end
        return true
    end
    if id == "TextESP" then
        _G.Mod_ESP_Text_Enabled = v
        if not v then
            for _, entry in pairs(HeadBoxState.Entries) do RemoveHeadBox(entry) end
            HeadBoxState.Entries = {}
            for _, entry in pairs(FootTextState.Entries) do RemoveFootTextEntry(entry) end
            FootTextState.Entries = {}
        end
        return true
    end
    if id == "OBHealthESP" then _G.Mod_ESP_Health_Enabled = v; return true end
    if id == "OBNameDistESP" then _G.Mod_ESP_NameDist_Enabled = v; return true end
    if id == "CounterTop" then
        _G.Mod_EnemyCounter_Enabled = v
        if not v then KC_Drop() else CounterState.lastText = nil end
        return true
    end
    if id == "iPadView" then _G.Mod_iPadView_Enabled = v; return true end
    if id == "iPadFOV" then _G.Mod_iPadViewFOV = v; return true end
    if id == "ForceTPP" then _G.Mod_ForceTPP_Enabled = v; if v then StartForceTPP() else StopForceTPP() end; return true end
    return false
end

-- ============================================================
-- ============================================================
-- DRAVIX MENU v1.0 (RED/BLACK, CLEAN) - transplanted UI layer
-- Features wired to setESPVal. Sliders write numeric globals live.
-- NOTE: wrapped in BuildDravixMenu() to stay under Lua's 200-locals limit.
-- ============================================================
local function BuildDravixMenu()
local J = {}
local Pal = J

local THEMES = {
    { name = "Sky", roles = {
        PANEL={ R=0.82,G=0.85,B=0.89,A=0.72 }, CYAN={ R=0.10,G=0.50,B=0.95,A=1.00 },
        CYAN_HI={ R=0.04,G=0.38,B=0.88,A=1.00 }, CYAN_DIM={ R=0.40,G=0.62,B=0.85,A=0.80 },
        TEXT_HI={ R=0.06,G=0.09,B=0.15,A=1.00 }, TEXT_MAIN={ R=0.16,G=0.22,B=0.32,A=1.00 },
        TEXT_DIM={ R=0.48,G=0.53,B=0.60,A=0.95 }, SUCCESS={ R=0.05,G=0.65,B=0.25,A=1.00 },
        WARN={ R=0.85,G=0.55,B=0.05,A=1.00 }, DANGER={ R=0.90,G=0.15,B=0.15,A=1.00 },
        ON_BG={ R=0.10,G=0.50,B=0.95,A=0.95 }, OFF_BG={ R=0.70,G=0.73,B=0.78,A=0.70 },
        TOGGLE_ON={ R=0.10,G=0.50,B=0.95,A=1.00 }, TOGGLE_OFF={ R=0.62,G=0.66,B=0.70,A=1.00 },
        TOGTXT_ON={ R=1.00,G=1.00,B=1.00,A=1.00 }, TOGTXT_OFF={ R=0.25,G=0.30,B=0.38,A=1.00 },
        ROW_ON={ R=0.72,G=0.82,B=0.95,A=0.55 }, ROW_OFF={ R=0.87,G=0.89,B=0.92,A=0.40 },
        TOAST_BG={ R=0.86,G=0.88,B=0.91,A=0.80 }, BAR_BG={ R=0.76,G=0.80,B=0.85,A=0.75 },
        BTN_BG={ R=0.84,G=0.86,B=0.89,A=0.75 } } },
    { name = "Red", roles = {
        PANEL={ R=0.03,G=0.03,B=0.045,A=0.96 }, CYAN={ R=0.95,G=0.08,B=0.10,A=1.00 },
        CYAN_HI={ R=1.00,G=0.45,B=0.45,A=1.00 }, CYAN_DIM={ R=0.55,G=0.12,B=0.14,A=0.75 },
        TEXT_HI={ R=1.00,G=1.00,B=1.00,A=1.00 }, TEXT_MAIN={ R=0.78,G=0.78,B=0.82,A=1.00 },
        TEXT_DIM={ R=0.45,G=0.45,B=0.50,A=0.90 }, SUCCESS={ R=0.20,G=1.00,B=0.55,A=1.00 },
        WARN={ R=1.00,G=0.75,B=0.10,A=1.00 }, DANGER={ R=1.00,G=0.30,B=0.20,A=1.00 },
        ON_BG={ R=0.45,G=0.05,B=0.07,A=0.95 }, OFF_BG={ R=0.08,G=0.08,B=0.10,A=0.90 },
        TOGGLE_ON={ R=0.85,G=0.08,B=0.10,A=1.00 }, TOGGLE_OFF={ R=0.25,G=0.25,B=0.28,A=1.00 },
        TOGTXT_ON={ R=1.00,G=1.00,B=1.00,A=1.00 }, TOGTXT_OFF={ R=1.00,G=1.00,B=1.00,A=1.00 },
        ROW_ON={ R=0.10,G=0.02,B=0.03,A=0.65 }, ROW_OFF={ R=0.03,G=0.03,B=0.04,A=0.65 },
        TOAST_BG={ R=0.05,G=0.03,B=0.03,A=0.96 }, BAR_BG={ R=0.08,G=0.03,B=0.03,A=0.95 },
        BTN_BG={ R=0.03,G=0.03,B=0.04,A=0.95 } } },
    { name = "Dark", roles = {
        PANEL={ R=0.012,G=0.012,B=0.016,A=0.97 }, CYAN={ R=0.80,G=0.80,B=0.85,A=1.00 },
        CYAN_HI={ R=1.00,G=1.00,B=1.00,A=1.00 }, CYAN_DIM={ R=0.40,G=0.40,B=0.45,A=0.80 },
        TEXT_HI={ R=1.00,G=1.00,B=1.00,A=1.00 }, TEXT_MAIN={ R=0.75,G=0.75,B=0.78,A=1.00 },
        TEXT_DIM={ R=0.42,G=0.42,B=0.46,A=0.90 }, SUCCESS={ R=0.30,G=0.90,B=0.50,A=1.00 },
        WARN={ R=0.90,G=0.70,B=0.20,A=1.00 }, DANGER={ R=0.90,G=0.30,B=0.30,A=1.00 },
        ON_BG={ R=0.25,G=0.25,B=0.28,A=0.95 }, OFF_BG={ R=0.06,G=0.06,B=0.08,A=0.90 },
        TOGGLE_ON={ R=0.85,G=0.85,B=0.88,A=1.00 }, TOGGLE_OFF={ R=0.22,G=0.22,B=0.25,A=1.00 },
        TOGTXT_ON={ R=0.05,G=0.05,B=0.06,A=1.00 }, TOGTXT_OFF={ R=1.00,G=1.00,B=1.00,A=1.00 },
        ROW_ON={ R=0.10,G=0.10,B=0.12,A=0.65 }, ROW_OFF={ R=0.02,G=0.02,B=0.03,A=0.65 },
        TOAST_BG={ R=0.02,G=0.02,B=0.03,A=0.97 }, BAR_BG={ R=0.02,G=0.02,B=0.03,A=0.96 },
        BTN_BG={ R=0.015,G=0.015,B=0.02,A=0.96 } } },
    { name = "Gold", roles = {
        PANEL={ R=0.05,G=0.04,B=0.02,A=0.96 }, CYAN={ R=0.95,G=0.72,B=0.15,A=1.00 },
        CYAN_HI={ R=1.00,G=0.85,B=0.35,A=1.00 }, CYAN_DIM={ R=0.55,G=0.42,B=0.12,A=0.80 },
        TEXT_HI={ R=1.00,G=1.00,B=1.00,A=1.00 }, TEXT_MAIN={ R=0.82,G=0.78,B=0.68,A=1.00 },
        TEXT_DIM={ R=0.50,G=0.46,B=0.36,A=0.90 }, SUCCESS={ R=0.20,G=1.00,B=0.55,A=1.00 },
        WARN={ R=1.00,G=0.75,B=0.10,A=1.00 }, DANGER={ R=1.00,G=0.30,B=0.20,A=1.00 },
        ON_BG={ R=0.45,G=0.32,B=0.06,A=0.95 }, OFF_BG={ R=0.10,G=0.08,B=0.05,A=0.90 },
        TOGGLE_ON={ R=0.85,G=0.62,B=0.12,A=1.00 }, TOGGLE_OFF={ R=0.28,G=0.25,B=0.20,A=1.00 },
        TOGTXT_ON={ R=0.08,G=0.06,B=0.02,A=1.00 }, TOGTXT_OFF={ R=1.00,G=1.00,B=1.00,A=1.00 },
        ROW_ON={ R=0.14,G=0.10,B=0.04,A=0.65 }, ROW_OFF={ R=0.04,G=0.03,B=0.02,A=0.65 },
        TOAST_BG={ R=0.06,G=0.05,B=0.03,A=0.97 }, BAR_BG={ R=0.07,G=0.05,B=0.02,A=0.96 },
        BTN_BG={ R=0.04,G=0.035,B=0.02,A=0.96 } } },
}

_G.DravixThemeIdx = _G.DravixThemeIdx or 1

local TOTAL_W = 660
local TOTAL_H = 440
local TOP_H   = 40
local BOT_H   = 28
local SIDE_W  = 145
local ROW_H   = 32
local ITEMS_PER_PAGE = 16
local MENU_VER = "v1.0"

local FloatingMenu = {
    Initialized = false, IsOpen = false,
    ActiveTab = "All",
    RootCanvas = nil, RootContainer = nil,
    ToggleContainer = nil, ToastContainer = nil,
    CurrentPage = 1,
    _activeCount = 0, _totalCount = 0,
    Favorites = {},
    _ClockRef = nil, _OnlineRef = nil, _BadgeRef = nil, _TitleRef = nil,
    _WrappedFeatures = nil,
    _Anim = { Angle = 0, WavePhase = 0, Blink = 0, ReactorSegs = {}, WaveBars = {} },
    _AnimTimer = nil,
}

local ApplyTheme = nil

local ACCENTS = {
    { name = "Red",    c = {0.95, 0.08, 0.10}, hi = {1.00, 0.45, 0.45}, dim = {0.55, 0.12, 0.14} },
    { name = "Sky",    c = {0.10, 0.50, 0.95}, hi = {0.30, 0.65, 1.00}, dim = {0.25, 0.45, 0.70} },
    { name = "Green",  c = {0.05, 0.75, 0.30}, hi = {0.35, 1.00, 0.55}, dim = {0.10, 0.45, 0.20} },
    { name = "Gold",   c = {0.95, 0.72, 0.15}, hi = {1.00, 0.85, 0.35}, dim = {0.55, 0.42, 0.12} },
    { name = "Purple", c = {0.65, 0.25, 0.95}, hi = {0.80, 0.50, 1.00}, dim = {0.40, 0.18, 0.55} },
}

local function ApplyAccent(idx)
    _G.DravixAccentIdx = idx
    if not idx or idx <= 1 then
        ApplyTheme(_G.DravixThemeIdx or 1, true)
        return true
    end
    local a = ACCENTS[idx - 1]
    if not a then return false end
    J.CYAN = { R = a.c[1], G = a.c[2], B = a.c[3], A = 1.00 }
    J.CYAN_HI = { R = a.hi[1], G = a.hi[2], B = a.hi[3], A = 1.00 }
    J.CYAN_DIM = { R = a.dim[1], G = a.dim[2], B = a.dim[3], A = 0.80 }
    J.TOGGLE_ON = { R = a.c[1], G = a.c[2], B = a.c[3], A = 1.00 }
    J.ON_BG = { R = a.c[1] * 0.5, G = a.c[2] * 0.5, B = a.c[3] * 0.5, A = 0.95 }
    return true
end

local OUTLINES = {
    { name = "Off" },
    { name = "Black", c = {0, 0, 0} },
    { name = "White", c = {1, 1, 1} },
    { name = "Red",   c = {0.95, 0.08, 0.10} },
    { name = "Sky",   c = {0.10, 0.50, 0.95} },
}
_G.DravixOutlineIdx = _G.DravixOutlineIdx or 2

local function ApplyOutline(idx)
    _G.DravixOutlineIdx = idx
    return true
end

local function OutlineRGB(alpha)
    local o = OUTLINES[_G.DravixOutlineIdx or 2]
    if not o or not o.c then return nil end
    return o.c[1], o.c[2], o.c[3], alpha or 1
end

ApplyTheme = function(idx, silent)
    local t = THEMES[idx]
    if not t then return false end
    for k, v in pairs(t.roles) do J[k] = v end
    FloatingMenu.ThemeName = t.name
    FloatingMenu.ThemeIdx = idx
    _G.DravixThemeIdx = idx
    local ai = _G.DravixAccentIdx
    if ai and ai > 1 then ApplyAccent(ai) end
    return true
end

ApplyTheme(_G.DravixThemeIdx or 1)

local DragState = { Active=false, DragTimer=nil, BtnX=20, BtnY=100, Slot=nil, StartMouseX=0, StartMouseY=0, HasMoved=false }

local function MakeColor(r, g, b, a)
    local LC = _FAST_LC or import("LinearColor")
    if not LC then return nil end
    return LC(r, g, b, a)
end

local function GetMousePos()
    local x, y = 0, 0
    local src = "none"
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        local V2 = _FAST_V2 or import("Vector2D")
        if pc.GetInputTouchState and V2 then
            for f = 0, 4 do
                local loc = V2(0, 0)
                local ok, rx, ry = pcall(function() return pc:GetInputTouchState(f, loc, false) end)
                if ok then
                    if loc.X and loc.Y and (loc.X ~= 0 or loc.Y ~= 0) then x, y = loc.X, loc.Y src = "touch" .. f break end
                    if type(rx) == "number" and type(ry) == "number" and (rx ~= 0 or ry ~= 0) then x, y = rx, ry src = "touchret" .. f break end
                end
            end
            if x ~= 0 or y ~= 0 then return end
        end
        if UIUtil and UIUtil.GetMousePositionOnViewport then
            local ok, mx, my = pcall(UIUtil.GetMousePositionOnViewport)
            if ok and type(mx) == "number" and type(my) == "number" and (mx ~= 0 or my ~= 0) then
                x, y = mx, my src = "uiutil"
                return
            end
        end
        if pc.GetMousePosition and V2 then
            local pos = V2(0, 0)
            local ok = pcall(function() pc:GetMousePosition(pos) end)
            if ok and pos.X and pos.Y and (pos.X ~= 0 or pos.Y ~= 0) then x, y = pos.X, pos.Y src = "mouse" return end
        end
    end)
    if (x ~= 0 or y ~= 0) and not _G._MouseSrcLogged then
        _G._MouseSrcLogged = true
        pcall(function() CounterLog("MOUSE src=" .. tostring(src)) end)
    end
    return x, y
end
_G.GetMousePos = GetMousePos

local MenuTimer = nil
local function StartDragTimer()
    if DragState.DragTimer then return end
    DragState.DragTimer = MenuTimer(0.016, true, function()
        if not DragState.Active then return end
        local mx, my = GetMousePos()
        if mx == 0 and my == 0 then return end
        if math.abs(mx - DragState.StartMouseX) > 5 or math.abs(my - DragState.StartMouseY) > 5 then DragState.HasMoved = true end
        if DragState.HasMoved then
            DragState.BtnX = mx - 30
            DragState.BtnY = my - 20
            if DragState.Slot and slua.isValid(DragState.Slot) then
                local V2 = _FAST_V2 or import("Vector2D")
                if V2 then DragState.Slot:SetPosition(V2(DragState.BtnX, DragState.BtnY)) end
            end
        end
    end)
end
local function StopDragTimer()
    MenuTimerStop(DragState.DragTimer)
    DragState.DragTimer = nil
end

-- MenuTimer: time_ticker first (proven), pc:AddGameTimer fallback. Loop timers
-- repeat until MenuTimerStop(st). One-shot (loop=false) fires once.
local _MenuTimerBackendLogged = false
local MenuTimerStop = nil
MenuTimer = function(interval, loop, fn)
    local st = { active = true, handle = nil, ticker = false, pc = nil }
    local function cb()
        if not st.active then return end
        pcall(fn)
        if not loop then MenuTimerStop(st) end
    end
    if time_ticker and time_ticker.AddTimerLoop then
        local ok, h = pcall(function()
            return time_ticker.AddTimerLoop(interval, cb, (time_ticker.TIMER_INFINITE or -1), 0)
        end)
        if ok and h then
            st.handle = h
            st.ticker = true
            if not _MenuTimerBackendLogged then
                _MenuTimerBackendLogged = true
                CounterLog("MENU timer backend: ticker")
            end
            return st
        end
    end
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        local ok, h = pcall(function() return pc:AddGameTimer(interval, loop and true or false, cb) end)
        if ok and h then
            st.handle = h
            st.pc = pc
            if not _MenuTimerBackendLogged then
                _MenuTimerBackendLogged = true
                CounterLog("MENU timer backend: pc")
            end
            return st
        end
    end
    if not _MenuTimerBackendLogged then
        _MenuTimerBackendLogged = true
        CounterLog("MENU timer backend: NONE")
    end
    return nil
end
MenuTimerStop = function(st)
    if not st then return end
    st.active = false
    if st.handle then
        if st.ticker then
            if time_ticker and time_ticker.RemoveTimer then pcall(time_ticker.RemoveTimer, st.handle) end
        elseif st.pc then
            pcall(function() st.pc:RemoveGameTimer(st.handle) end)
        end
        st.handle = nil
    end
end

function FloatingMenu.TryGetCanvas()
    local canvas = nil
    pcall(function()
        local M = nil
        if InGameUITools and InGameUITools.GetMainControlBaseUI then M = InGameUITools.GetMainControlBaseUI() end
        if M and slua.isValid(M) then
            local c = M.CanvasPanel_0 or M.CanvasPanel_42
            if c and slua.isValid(c) then canvas = c end
        end
    end)
    return canvas
end

-- feature table
_G.AK_Features = {
    { id="Aimbot", name="Aimbot (Hard)", category="Combat", type="toggle", critical=true,
        get=function() return _G.Mod_Aimbot_Enabled == true end, apply=function(v) setESPVal("Aimbot", v) end },
    { id="AimbotStrength", name="Aim Strength", category="Combat", type="slider", min=0, max=100, step=5,
        get=function() return _G.Mod_AimbotStrength or 80 end, apply=function(v) setESPVal("AimbotStrength", v) end },
    { id="iPadView", name="iPad View", category="Combat", type="toggle",
        get=function() return _G.Mod_iPadView_Enabled == true end, apply=function(v) setESPVal("iPadView", v) end },
    { id="iPadFOV", name="iPad FOV", category="Combat", type="slider", min=90, max=130, step=1,
        get=function() return tonumber(_G.Mod_iPadViewFOV) or 110 end, apply=function(v) setESPVal("iPadFOV", v) end },
    { id="Wallhack", name="Wallhack", category="ESP", type="toggle", critical=true,
        get=function() return _G.Mod_Wallhack_Enabled == true end, apply=function(v) setESPVal("Wallhack", v) end },
    { id="LineESP", name="Line ESP", category="ESP", type="toggle",
        get=function() return _G.Mod_ESP_Line_Enabled == true end, apply=function(v) setESPVal("LineESP", v) end },
    { id="TextESP", name="Text ESP", category="ESP", type="toggle",
        get=function() return _G.Mod_ESP_Text_Enabled == true end, apply=function(v) setESPVal("TextESP", v) end },
    { id="OBHealthESP", name="OB Health", category="ESP", type="toggle",
        get=function() return _G.Mod_ESP_Health_Enabled == true end, apply=function(v) setESPVal("OBHealthESP", v) end },
    { id="OBNameDistESP", name="OB Name/Distance", category="ESP", type="toggle",
        get=function() return _G.Mod_ESP_NameDist_Enabled == true end, apply=function(v) setESPVal("OBNameDistESP", v) end },
    { id="CounterTop", name="Enemy Counter", category="ESP", type="toggle",
        get=function() return _G.Mod_EnemyCounter_Enabled == true end, apply=function(v) setESPVal("CounterTop", v) end },
    { id="ForceTPP", name="Force TPP", category="Misc", type="toggle",
        get=function() return _G.Mod_ForceTPP_Enabled == true end, apply=function(v) setESPVal("ForceTPP", v) end },
}

local function ApplyFeatureSideEffect(featureId, isOn)
    -- wiring goes through entry apply() -> setESPVal; kept for compat
end

function FloatingMenu.RebuildWrappedFeatures()
    local list = {}
    for _,f in ipairs(_G.AK_Features) do
        local wrapper = {
            id = f.id, name = f.name, category = f.category or "Misc",
            type = f.type, critical = f.critical, min = f.min, max = f.max, step = f.step,
        }
        wrapper.get = function()
            local ok, r = pcall(f.get)
            if f.type == "slider" or f.type == "cycle" then
                if not ok then return (f.min or 1) end
                return tonumber(r) or (f.min or 1)
            end
            if not ok then return 0 end
            return (r == true) and 1 or 0
        end
        wrapper.set = function(v)
            pcall(f.apply, v)
            if wrapper.type == "toggle" then pcall(ApplyFeatureSideEffect, wrapper.id, v) end
        end
        table.insert(list, wrapper)
    end
    FloatingMenu._WrappedFeatures = list
end

function FloatingMenu.GetAllFeatures()
    if not FloatingMenu._WrappedFeatures then FloatingMenu.RebuildWrappedFeatures() end
    return FloatingMenu._WrappedFeatures
end

function FloatingMenu.GetFilteredFeatures()
    local all = FloatingMenu.GetAllFeatures()
    local out = {}
    for _,f in ipairs(all) do
        local ok = true
        if FloatingMenu.ActiveTab == "All" then ok = true
        elseif FloatingMenu.ActiveTab == "Favorites" then
            if not FloatingMenu.Favorites or not FloatingMenu.Favorites[f.id] then ok = false end
        elseif FloatingMenu.ActiveTab == "Critical" then
            if not f.critical then ok = false end
        else
            if f.category ~= FloatingMenu.ActiveTab then ok = false end
        end
        if ok then table.insert(out, f) end
    end
    return out
end

function FloatingMenu.DestroyRoot()
    if FloatingMenu.RootContainer and slua.isValid(FloatingMenu.RootContainer) then
        pcall(function() FloatingMenu.RootContainer:RemoveFromParent() FloatingMenu.RootContainer:ConditionalBeginDestroy() end)
    end
    FloatingMenu.RootContainer = nil
    FloatingMenu._RootSlot = nil
    FloatingMenu._BgFx = nil
    MenuTimerStop(FloatingMenu._BgFxTimer)
    FloatingMenu._BgFxTimer = nil
    MenuTimerStop(FloatingMenu._ClockTimer)
    FloatingMenu._ClockTimer = nil
    FloatingMenu._ClockRef = nil
    FloatingMenu._OnlineRef = nil
    FloatingMenu._BadgeRef = nil
    FloatingMenu._TitleRef = nil
    FloatingMenu.DrawerOpen = false
    FloatingMenu.DrawerRef = nil
    if FloatingMenu._DrawerTimer then
        MenuTimerStop(FloatingMenu._DrawerTimer)
        FloatingMenu._DrawerTimer = nil
    end
    if FloatingMenu._AnimTimer then
        MenuTimerStop(FloatingMenu._AnimTimer)
        FloatingMenu._AnimTimer = nil
    end
    FloatingMenu._Anim.ReactorSegs = {}
    FloatingMenu._Anim.WaveBars = {}
end
function FloatingMenu.DestroyToggle()
    if FloatingMenu.ToggleContainer and slua.isValid(FloatingMenu.ToggleContainer) then
        pcall(function() FloatingMenu.ToggleContainer:RemoveFromParent() FloatingMenu.ToggleContainer:ConditionalBeginDestroy() end)
    end
    FloatingMenu.ToggleContainer = nil
    DragState.Slot = nil
end
function FloatingMenu.DestroyToast()
    if FloatingMenu.ToastContainer and slua.isValid(FloatingMenu.ToastContainer) then
        pcall(function() FloatingMenu.ToastContainer:RemoveFromParent() FloatingMenu.ToastContainer:ConditionalBeginDestroy() end)
    end
    FloatingMenu.ToastContainer = nil
end

local function HoloPanel(parent, x, y, w, h, zBase, edge)
    local V2 = _FAST_V2 or import("Vector2D")
    local z = zBase or 10
    local bg = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
    if bg then
        pcall(function()
            bg:SetBrushColor(MakeColor(J.PANEL.R, J.PANEL.G, J.PANEL.B, J.PANEL.A))
            bg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local bs = parent:AddChildToCanvas(bg)
        if bs then bs:SetAutoSize(false) bs:SetPosition(V2(x, y)) bs:SetSize(V2(w, h)) bs:SetZOrder(z) end
    end
    if not edge then return end
    local te = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
    if te then
        pcall(function()
            te:SetBrushColor(MakeColor(J.CYAN.R, J.CYAN.G, J.CYAN.B, 0.85))
            te:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local ts = parent:AddChildToCanvas(te)
        if ts then ts:SetAutoSize(false) ts:SetPosition(V2(x, y)) ts:SetSize(V2(w, 2)) ts:SetZOrder(z+2) end
    end
end

local function Label(parent, x, y, text, size, color, zOrder, align)
    local V2 = _FAST_V2 or import("Vector2D")
    local txt = CGame:NewObjectFromPath("/Script/UMG.TextBlock", parent)
    if txt and slua.isValid(txt) then
        pcall(function()
            txt:SetText(text)
            local FSC = import("SlateColor") or import("/Script/SlateCore/SlateColor")
            local cc = MakeColor(color.R, color.G, color.B, color.A or 1)
            if FSC then txt:SetColorAndOpacity(FSC(cc)) else txt:SetColorAndOpacity(cc) end
            if txt.Font then local f = txt.Font f.Size = size or 9 txt.Font = f end
            txt:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local ls = parent:AddChildToCanvas(txt)
        if ls then
            ls:SetAutoSize(true)
            ls:SetAlignment(align or V2(0, 0.5))
            ls:SetPosition(V2(x, y))
            ls:SetZOrder(zOrder or 10)
        end
        return txt
    end
    return nil
end

local function JarvisBtn(parent, x, y, w, h, label, onClick, zOrder, isActive, isDanger)
    local V2 = _FAST_V2 or import("Vector2D")
    local baseCol = isActive and J.ON_BG or J.OFF_BG
    local edgeCol = isActive and J.CYAN or (isDanger and J.DANGER or J.CYAN_DIM)
    local btn = CGame:NewObjectFromPath("/Script/UMG.Button", parent)
    if not btn then return nil end
    pcall(function()
        btn:SetBackgroundColor(MakeColor(baseCol.R, baseCol.G, baseCol.B, baseCol.A))
        btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
    end)
    local slot = parent:AddChildToCanvas(btn)
    if slot then slot:SetAutoSize(false) slot:SetPosition(V2(x, y)) slot:SetSize(V2(w, h)) slot:SetZOrder(zOrder or 30) end
    pcall(function()
        local or1, og1, ob1, oa1 = OutlineRGB(1)
        if or1 then
            local ol = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
            if ol then
                ol:SetBrushColor(MakeColor(or1, og1, ob1, oa1))
                ol:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                local ols = parent:AddChildToCanvas(ol)
                if ols then ols:SetAutoSize(false) ols:SetPosition(V2(x - 1, y - 1)) ols:SetSize(V2(w + 2, h + 2)) ols:SetZOrder((zOrder or 30) - 1) end
            end
        end
    end)
    local te = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
    if te then
        pcall(function()
            te:SetBrushColor(MakeColor(edgeCol.R, edgeCol.G, edgeCol.B, isActive and 1.0 or 0.55))
            te:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local ts = parent:AddChildToCanvas(te)
        if ts then ts:SetAutoSize(false) ts:SetPosition(V2(x+1, y)) ts:SetSize(V2(w-2, 2)) ts:SetZOrder((zOrder or 30)+1) end
    end
    if label and label ~= "" then
        local txt = CGame:NewObjectFromPath("/Script/UMG.TextBlock", parent)
        if txt then
            pcall(function()
                txt:SetText(label)
                local FSC = import("SlateColor") or import("/Script/SlateCore/SlateColor")
                local cc = isActive and MakeColor(1,1,1,1) or MakeColor(J.TEXT_MAIN.R, J.TEXT_MAIN.G, J.TEXT_MAIN.B, 1)
                if FSC then txt:SetColorAndOpacity(FSC(cc)) else txt:SetColorAndOpacity(cc) end
                if txt.Font then local f = txt.Font f.Size = 10 txt.Font = f end
                txt:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local ts = parent:AddChildToCanvas(txt)
            if ts then
                ts:SetAutoSize(true)
                ts:SetAlignment(V2(0.5, 0.5))
                ts:SetPosition(V2(x + w/2, y + h/2))
                ts:SetZOrder((zOrder or 30) + 5)
            end
        end
    end
    if onClick then pcall(function() btn.OnClicked:Add(onClick) end) end
    return btn
end

local function JarvisToggle(parent, x, y, isOn, onToggle, zOrder)
    local V2 = _FAST_V2 or import("Vector2D")
    local W, H = 62, 26
    local bgCol = isOn and J.TOGGLE_ON or J.TOGGLE_OFF
    local btn = CGame:NewObjectFromPath("/Script/UMG.Button", parent)
    if not btn then return end
    pcall(function()
        btn:SetBackgroundColor(MakeColor(bgCol.R, bgCol.G, bgCol.B, bgCol.A))
        btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
    end)
    local slot = parent:AddChildToCanvas(btn)
    if slot then slot:SetAutoSize(false) slot:SetPosition(V2(x, y)) slot:SetSize(V2(W, H)) slot:SetZOrder(zOrder or 30) end
    local knob = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
    local knobSlot = nil
    if knob then
        local tc = (isOn and J.TOGTXT_ON) or J.TOGTXT_OFF
        pcall(function()
            knob:SetBrushColor(MakeColor(tc.R, tc.G, tc.B, 1))
            knob:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local ks = parent:AddChildToCanvas(knob)
        if ks then
            ks:SetAutoSize(false)
            if isOn then ks:SetPosition(V2(x + W - 25, y + 3)) else ks:SetPosition(V2(x + 3, y + 3)) end
            ks:SetSize(V2(22, H - 6))
            ks:SetZOrder((zOrder or 30) + 1)
            knobSlot = ks
        end
    end
    if onToggle then pcall(function() btn.OnClicked:Add(onToggle) end) end
    local te = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
    if te then
        pcall(function()
            te:SetBrushColor(MakeColor(J.CYAN_HI.R, J.CYAN_HI.G, J.CYAN_HI.B, isOn and 1.0 or 0.35))
            te:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local ts = parent:AddChildToCanvas(te)
        if ts then ts:SetAutoSize(false) ts:SetPosition(V2(x+1, y)) ts:SetSize(V2(W-2, 2)) ts:SetZOrder((zOrder or 30)+1) end
    end
    local stateTxt = CGame:NewObjectFromPath("/Script/UMG.TextBlock", parent)
    if stateTxt then
        pcall(function()
            stateTxt:SetText(isOn and "ON" or "OFF")
            local FSC = import("SlateColor") or import("/Script/SlateCore/SlateColor")
            local tc = (isOn and J.TOGTXT_ON) or J.TOGTXT_OFF
            local cc = MakeColor(tc.R, tc.G, tc.B, tc.A or 1)
            if FSC then stateTxt:SetColorAndOpacity(FSC(cc)) else stateTxt:SetColorAndOpacity(cc) end
            if stateTxt.Font then local f = stateTxt.Font f.Size = 12 f.TypefaceFontName = "Bold" stateTxt.Font = f end
            stateTxt:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local sts = parent:AddChildToCanvas(stateTxt)
        if sts then
            sts:SetAutoSize(true)
            sts:SetAlignment(V2(0.5, 0.5))
            sts:SetPosition(V2(x + W/2, y + H/2))
            sts:SetZOrder((zOrder or 30) + 3)
        end
    end
end

-- ============================================================
-- ============================================================
-- DRAVIX MENU PART B - render layer (red/black, clean, no decor anims)
-- ============================================================
function FloatingMenu.StartBgFx()
    if FloatingMenu._BgFxTimer then return end
    FloatingMenu._BgFxTimer = MenuTimer(0.07, true, function()
        if not FloatingMenu.IsOpen then return end
        pcall(function()
            local fx = FloatingMenu._BgFx
            if not fx then return end
            local V2 = _FAST_V2 or import("Vector2D")
            local px0 = FloatingMenu._PanelX or 0
            local py0 = FloatingMenu._PanelY or 0
            if fx.shine and slua.isValid(fx.shine) and fx.shineSlot then
                fx.shineX = (fx.shineX or px0) + 14
                if fx.shineX > px0 + TOTAL_W + 40 then fx.shineX = px0 - 130 end
                fx.shineSlot:SetPosition(V2(fx.shineX, py0))
            end
            if fx.parts then
                for _, pt in ipairs(fx.parts) do
                    pt.y = (pt.y or py0) - (pt.sp or 3)
                    if pt.y < py0 + 30 then pt.y = py0 + TOTAL_H - 30 end
                    local pyv, pxv = pt.y, pt.x
                    pcall(function() if pt.s then pt.s:SetPosition(V2(pxv, pyv)) end end)
                end
            end
        end)
    end)
end

function FloatingMenu.StartAnimations()
    if FloatingMenu._AnimTimer then return end
    FloatingMenu._AnimTimer = MenuTimer(0.5, true, function()
        if not FloatingMenu.IsOpen then return end
        pcall(function()
            FloatingMenu._Anim.Blink = (FloatingMenu._Anim.Blink + 1) % 20
            if FloatingMenu._OnlineRef and slua.isValid(FloatingMenu._OnlineRef) then
                if FloatingMenu._Anim.Blink < 10 then FloatingMenu._OnlineRef:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                else FloatingMenu._OnlineRef:SetWidgetVisibility(UEnums.ESlateVisibility.Hidden) end
            end
            if FloatingMenu._BadgeRef and slua.isValid(FloatingMenu._BadgeRef) then
                local op = 0.70 + 0.30 * (FloatingMenu._Anim.Blink / 20)
                pcall(function() FloatingMenu._BadgeRef:SetRenderOpacity(op) end)
            end
            if FloatingMenu._TitleRef and slua.isValid(FloatingMenu._TitleRef) then
                local tc2 = (FloatingMenu._Anim.Blink < 10) and J.CYAN_HI or J.TEXT_HI
                pcall(function()
                    local FSC2 = import("SlateColor") or import("/Script/SlateCore/SlateColor")
                    local cc2 = MakeColor(tc2.R, tc2.G, tc2.B, tc2.A or 1)
                    if FSC2 then FloatingMenu._TitleRef:SetColorAndOpacity(FSC2(cc2)) else FloatingMenu._TitleRef:SetColorAndOpacity(cc2) end
                end)
            end
        end)
    end)
end

local function MenuCanvasSize(canvas)
    local cw, ch = 1920, 1080
    pcall(function()
        if canvas and slua.isValid(canvas) and canvas.GetCachedGeometry then
            local g = canvas:GetCachedGeometry()
            if g and SlateBlueprintLibrary and SlateBlueprintLibrary.GetLocalSize then
                local s = SlateBlueprintLibrary.GetLocalSize(g)
                if s and s.X > 200 and s.Y > 200 then cw, ch = s.X, s.Y end
            end
        end
    end)
    if cw == 1920 then
        pcall(function()
            if UIUtil and UIUtil.GetViewportSize then
                local vs = UIUtil.GetViewportSize()
                if vs and vs.X > 200 then cw, ch = vs.X, vs.Y end
            end
        end)
    end
    return cw, ch
end

function FloatingMenu.ShowToast(msg)
    pcall(function()
        FloatingMenu.DestroyToast()
        local canvas = FloatingMenu.RootCanvas
        if not canvas then return end
        local V2 = _FAST_V2 or import("Vector2D")
        local cw, ch = MenuCanvasSize(canvas)
        local container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas)
        if not container then return end
        local cs = canvas:AddChildToCanvas(container)
        if not cs then return end
        cs:SetPosition(V2(0,0)) cs:SetSize(V2(cw,ch)) cs:SetAutoSize(false) cs:SetZOrder(5500)
        FloatingMenu.ToastContainer = container
        pcall(function()
            if container.SetRenderOpacity then container:SetRenderOpacity(0.15) end
            local pc0 = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc0) and pc0.AddGameTimer then
            local fs = 0
            local st = nil
            st = MenuTimer(0.04, true, function()
                fs = fs + 1
                local t = math.min(1, fs / 5)
                pcall(function() if slua.isValid(container) then container:SetRenderOpacity(0.15 + 0.85 * t) end end)
                if t >= 1 then MenuTimerStop(st) end
            end)
            if not st then
                if container.SetRenderOpacity then container:SetRenderOpacity(1.0) end
            end
            else
                if container.SetRenderOpacity then container:SetRenderOpacity(1.0) end
            end
        end)
        local tw, th = 340, 40
        local tx = (cw - tw)/2
        local ty = ch - th - 100
        local bg = CGame:NewObjectFromPath("/Script/UMG.Border", container)
        if bg then
            pcall(function()
                bg:SetBrushColor(MakeColor(J.TOAST_BG.R, J.TOAST_BG.G, J.TOAST_BG.B, J.TOAST_BG.A or 0.96))
                bg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local bs = container:AddChildToCanvas(bg)
            if bs then bs:SetAutoSize(false) bs:SetPosition(V2(tx, ty)) bs:SetSize(V2(tw, th)) bs:SetZOrder(1) end
        end
        local te = CGame:NewObjectFromPath("/Script/UMG.Border", container)
        if te then
            pcall(function()
                te:SetBrushColor(MakeColor(J.CYAN_HI.R, J.CYAN_HI.G, J.CYAN_HI.B, 1))
                te:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local ts = container:AddChildToCanvas(te)
            if ts then ts:SetAutoSize(false) ts:SetPosition(V2(tx, ty)) ts:SetSize(V2(tw, 2)) ts:SetZOrder(2) end
        end
        Label(container, tx+tw/2, ty+th/2, msg or "Done", 11, J.TEXT_HI, 3, V2(0.5, 0.5))
        MenuTimer(2.0, false, function() FloatingMenu.DestroyToast() end)
    end)
end

local function RenderCategoryTabs(parent, x, y, w, zBase)
    local tabs = { {"All","ALL"}, {"ESP","ESP"}, {"Combat","CMB"}, {"Misc","MSC"}, {"Favorites","FAV"} }
    local gap = 5
    local tw = (w - gap * (#tabs - 1)) / #tabs
    for i, tabEntry in ipairs(tabs) do
        local realTab = tabEntry[1]
        local shortLabel = tabEntry[2]
        local tx = x + (i - 1) * (tw + gap)
        local isActive = (FloatingMenu.ActiveTab == realTab)
        Label(parent, tx + tw/2, y + 10, shortLabel, 10, isActive and J.CYAN_HI or J.TEXT_DIM, zBase + 1, import("Vector2D")(0.5, 0.5))
        if isActive then
            local un = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
            if un then
                pcall(function()
                    un:SetBrushColor(MakeColor(J.CYAN.R, J.CYAN.G, J.CYAN.B, 1))
                    un:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                end)
                local us = parent:AddChildToCanvas(un)
                if us then us:SetAutoSize(false) us:SetPosition(import("Vector2D")(tx + 6, y + 20)) us:SetSize(import("Vector2D")(tw - 12, 2)) us:SetZOrder(zBase + 1) end
            end
        end
        local hit = CGame:NewObjectFromPath("/Script/UMG.Button", parent)
        if hit then
            pcall(function()
                hit:SetBackgroundColor(MakeColor(0,0,0,0.001))
                hit:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
            end)
            local hs = parent:AddChildToCanvas(hit)
            if hs then hs:SetAutoSize(false) hs:SetPosition(import("Vector2D")(tx, y)) hs:SetSize(import("Vector2D")(tw, 24)) hs:SetZOrder(zBase + 2) end
            pcall(function() hit.OnClicked:Add(function()
                FloatingMenu.ActiveTab = realTab
                FloatingMenu.CurrentPage = 1
                FloatingMenu._FreshOpen = true
                FloatingMenu.CreateMainPanel()
            end) end)
        end
    end
end

local function RenderCategoryTabsV(parent, x, y, w, h, zBase)
    local tabs = { {"All","ALL"}, {"ESP","ESP"}, {"Combat","CMB"}, {"Misc","MSC"}, {"Favorites","FAV"} }
    local gap = 6
    local th = math.min(44, (h - gap * (#tabs - 1)) / #tabs)
    for i, tabEntry in ipairs(tabs) do
        local realTab = tabEntry[1]
        local ty = y + (i - 1) * (th + gap)
        local isActive = (FloatingMenu.ActiveTab == realTab)
        local fr = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
        if fr then
            pcall(function()
                if isActive then fr:SetBrushColor(MakeColor(J.CYAN.R, J.CYAN.G, J.CYAN.B, 1))
                else fr:SetBrushColor(MakeColor(J.CYAN_DIM.R, J.CYAN_DIM.G, J.CYAN_DIM.B, 0.5)) end
                fr:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local frs = parent:AddChildToCanvas(fr)
            if frs then frs:SetAutoSize(false) frs:SetPosition(import("Vector2D")(x, ty)) frs:SetSize(import("Vector2D")(w, th)) frs:SetZOrder(zBase) end
        end
        local fi = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
        if fi then
            pcall(function()
                if isActive then fi:SetBrushColor(MakeColor(J.ON_BG.R, J.ON_BG.G, J.ON_BG.B, J.ON_BG.A))
                else fi:SetBrushColor(MakeColor(J.OFF_BG.R, J.OFF_BG.G, J.OFF_BG.B, J.OFF_BG.A)) end
                fi:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local fis = parent:AddChildToCanvas(fi)
            if fis then fis:SetAutoSize(false) fis:SetPosition(import("Vector2D")(x + 1, ty + 1)) fis:SetSize(import("Vector2D")(w - 2, th - 2)) fis:SetZOrder(zBase) end
        end
        if isActive then
            local acc = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
            if acc then
                pcall(function()
                    acc:SetBrushColor(MakeColor(J.CYAN.R, J.CYAN.G, J.CYAN.B, 1))
                    acc:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                end)
                local as = parent:AddChildToCanvas(acc)
                if as then as:SetAutoSize(false) as:SetPosition(import("Vector2D")(x, ty)) as:SetSize(import("Vector2D")(3, th)) as:SetZOrder(zBase + 1) end
            end
        end
        Label(parent, x + w/2, ty + th/2, tabEntry[2], 10, isActive and J.CYAN_HI or J.TEXT_DIM, zBase + 1, import("Vector2D")(0.5, 0.5))
        local hit = CGame:NewObjectFromPath("/Script/UMG.Button", parent)
        if hit then
            pcall(function()
                hit:SetBackgroundColor(MakeColor(0,0,0,0.001))
                hit:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
            end)
            local hs = parent:AddChildToCanvas(hit)
            if hs then hs:SetAutoSize(false) hs:SetPosition(import("Vector2D")(x, ty)) hs:SetSize(import("Vector2D")(w, th)) hs:SetZOrder(zBase + 2) end
            pcall(function() hit.OnClicked:Add(function()
                FloatingMenu.ActiveTab = realTab
                FloatingMenu.CurrentPage = 1
                FloatingMenu._FreshOpen = true
                FloatingMenu.CreateMainPanel()
            end) end)
        end
    end
end

local function MenuCountOn()
    local n, total = 0, 0
    for _,f in ipairs(FloatingMenu.GetAllFeatures()) do
        total = total + 1
        if f.type == "toggle" and f.get() == 1 then n = n + 1 end
    end
    return n, total
end

local function MenuSym(cat)
    if cat == "Combat" then return "✚" end
    if cat == "ESP" then return "◉" end
    if cat == "Vehicle" then return "▣" end
    if cat == "Items" then return "◆" end
    if cat == "Loot" then return "◈" end
    if cat == "Misc" then return "⚙" end
    return "◇"
end

function FloatingMenu.RenderFeatureList(parent, x, y, w, h, zBase)
    local V2 = _FAST_V2 or import("Vector2D")
    local z = zBase or 100
    local mode = 0
    local lx, ly, lw, lh = x, y, w, h
    if mode == 0 then
        -- drawer nav owns categories; full list, no tab bar
    elseif mode == 2 then
        local railW = 70
        RenderCategoryTabsV(parent, x, y + 28, railW, h - 28, z + 2)
        lx = x + railW + 8
        lw = w - railW - 8
    elseif mode == 3 then
        RenderCategoryTabs(parent, x, y + h - 24, w, z + 2)
        lh = h - 30
    else
        RenderCategoryTabs(parent, x, y, w, z + 2)
    end

    local listTop = ly + 28
    local listH = lh - 28
    local twoCol = not FloatingMenu.DrawerInline
    local pw = twoCol and ((lw - 8) / 2) or lw
    HoloPanel(parent, lx, listTop, pw, listH, z)
    if twoCol then
        HoloPanel(parent, lx + pw + 8, listTop, pw, listH, z)
    end

    local nOn, nTotal = MenuCountOn()
    FloatingMenu._activeCount = nOn
    FloatingMenu._totalCount = nTotal
    Label(parent, lx+8, listTop+12, twoCol and ("◈ " .. tostring(FloatingMenu.ActiveTab) .. " · A") or ("◈ " .. tostring(FloatingMenu.ActiveTab)), 9, J.CYAN_HI, z+4)
    if twoCol then
        Label(parent, lx+pw+16, listTop+12, "◈ " .. tostring(FloatingMenu.ActiveTab) .. " · B", 9, J.CYAN_HI, z+4)
    end
    Label(parent, lx+lw-8, listTop+12, "ACT:" .. tostring(nOn) .. "/" .. tostring(nTotal), 8, J.SUCCESS, z+4, V2(1, 0.5))

    local features = FloatingMenu.GetFilteredFeatures()
    local totalPages = math.max(1, math.ceil(#features / ITEMS_PER_PAGE))
    if FloatingMenu.CurrentPage > totalPages then FloatingMenu.CurrentPage = totalPages end
    if FloatingMenu.CurrentPage < 1 then FloatingMenu.CurrentPage = 1 end
    local perPage = FloatingMenu.DrawerInline and 8 or ITEMS_PER_PAGE
    local sIdx = (FloatingMenu.CurrentPage - 1) * perPage + 1
    local eIdx = math.min(sIdx + perPage - 1, #features)

    local doStagger = FloatingMenu._FreshOpen == true
    FloatingMenu._FreshOpen = false
    local staggerList = {}

    local lx0, lw0 = lx, lw
    for i = sIdx, eIdx do
        local li = i - sIdx
        if twoCol and li >= 8 then lx = lx0 + pw + 8 else lx = lx0 end
        lw = pw
        local rowY = listTop + 26 + (li % 8) * ROW_H
        local feat = features[i]
        local isOn = feat.get() == 1
        if feat.type == "slider" then isOn = feat.get() > 0 end

        local rowBg = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
        if rowBg then
            pcall(function()
                local rc = (isOn and J.ROW_ON) or J.ROW_OFF
                rowBg:SetBrushColor(MakeColor(rc.R, rc.G, rc.B, rc.A or 0.65))
                rowBg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                if doStagger and rowBg.SetRenderOpacity then rowBg:SetRenderOpacity(0) end
            end)
            local rs = parent:AddChildToCanvas(rowBg)
            if rs then
                rs:SetAutoSize(false) rs:SetPosition(V2(lx+4, rowY)) rs:SetSize(V2(lw-8, ROW_H-2)) rs:SetZOrder(z+3)
                if doStagger then table.insert(staggerList, rowBg) end
            end
        end
        if isOn then
            local acc = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
            if acc then
                pcall(function()
                    acc:SetBrushColor(MakeColor(J.CYAN_HI.R, J.CYAN_HI.G, J.CYAN_HI.B, 1))
                    acc:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                end)
                local a = parent:AddChildToCanvas(acc)
                if a then a:SetAutoSize(false) a:SetPosition(V2(lx+4, rowY)) a:SetSize(V2(3, ROW_H-2)) a:SetZOrder(z+4) end
            end
        end

        Label(parent, lx+12, rowY+ROW_H/2, MenuSym(feat.category), 10, isOn and J.CYAN_HI or J.TEXT_DIM, z+5)

        local nameTxt = feat.name
        if #nameTxt > 20 then nameTxt = nameTxt:sub(1, 20) .. "…" end
        Label(parent, lx+28, rowY+ROW_H/2, nameTxt, 10, isOn and J.TEXT_HI or J.TEXT_MAIN, z+5)

        if feat.type == "radio" then
            local sel = feat.get() == 1
            local rp = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
            if rp then
                pcall(function()
                    if sel then rp:SetBrushColor(MakeColor(J.CYAN.R, J.CYAN.G, J.CYAN.B, 0.85))
                    else rp:SetBrushColor(MakeColor(J.OFF_BG.R, J.OFF_BG.G, J.OFF_BG.B, J.OFF_BG.A)) end
                    rp:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                end)
                local rps = parent:AddChildToCanvas(rp)
                if rps then rps:SetAutoSize(false) rps:SetPosition(V2(lx+4, rowY)) rps:SetSize(V2(lw-8, ROW_H-2)) rps:SetZOrder(z+4) end
            end
            Label(parent, lx+lw-44, rowY+ROW_H/2, sel and "◉" or "○", 16, sel and J.TOGTXT_ON or J.TEXT_DIM, z+5, V2(0.5, 0.5))
            local rb2 = CGame:NewObjectFromPath("/Script/UMG.Button", parent)
            if rb2 then
                pcall(function()
                    rb2:SetBackgroundColor(MakeColor(0,0,0,0.001))
                    rb2:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
                end)
                local rbs2 = parent:AddChildToCanvas(rb2)
                if rbs2 then rbs2:SetAutoSize(false) rbs2:SetPosition(V2(lx+4, rowY)) rbs2:SetSize(V2(lw-8, ROW_H-2)) rbs2:SetZOrder(z+8) end
                pcall(function() rb2.OnClicked:Add(function()
                    if feat.get() ~= 1 then
                        feat.set(true)
                        FloatingMenu.ShowToast(feat.name .. "  ●")
                        FloatingMenu.CreateMainPanel()
                    end
                end) end)
            end
        elseif feat.type == "cycle" then
            local opts = feat.options or {}
            local idx = feat.get()
            if type(idx) ~= "number" then idx = 1 end
            if idx < 1 then idx = 1 end
            if #opts > 0 and idx > #opts then idx = #opts end
            local cur = opts[idx] or ""
            Label(parent, lx+lw-100, rowY+ROW_H/2, cur, 10, J.CYAN_HI, z+5, V2(0.5, 0.5))
            local cb = CGame:NewObjectFromPath("/Script/UMG.Button", parent)
            if cb then
                pcall(function()
                    cb:SetBackgroundColor(MakeColor(0,0,0,0.001))
                    cb:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
                end)
                local cbs = parent:AddChildToCanvas(cb)
                if cbs then cbs:SetAutoSize(false) cbs:SetPosition(V2(lx+lw-70, rowY + (ROW_H-26)/2)) cbs:SetSize(V2(62, 26)) cbs:SetZOrder(z+6) end
                pcall(function() cb.OnClicked:Add(function()
                    local nidx = idx + 1
                    if #opts > 0 and nidx > #opts then nidx = 1 end
                    feat.set(nidx)
                    FloatingMenu.ShowToast(feat.name .. " · " .. tostring((feat.options or {})[feat.get()] or ""))
                    FloatingMenu.CreateMainPanel()
                end) end)
            end
            local cpill = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
            if cpill then
                pcall(function()
                    cpill:SetBrushColor(MakeColor(J.ON_BG.R, J.ON_BG.G, J.ON_BG.B, J.ON_BG.A))
                    cpill:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                end)
                local cps = parent:AddChildToCanvas(cpill)
                if cps then cps:SetAutoSize(false) cps:SetPosition(V2(lx+lw-70, rowY+(ROW_H-26)/2)) cps:SetSize(V2(62, 26)) cps:SetZOrder(z+4) end
            end
        elseif feat.type == "toggle" then
            JarvisToggle(parent, lx+lw-70, rowY + (ROW_H-26)/2, isOn, function()
                local curOn = feat.get() == 1
                feat.set(not curOn)
                local nowOn = feat.get() == 1
                FloatingMenu.ShowToast(feat.name .. (nowOn and "  ● ON" or "  ○ OFF"))
                FloatingMenu.CreateMainPanel()
            end, z+6)
        elseif feat.type == "slider" then
            local valLabel = Label(parent, lx+lw-25, rowY+ROW_H/2, tostring(feat.get()), 9, J.CYAN_HI, z+5, V2(0.5, 0.5))
            local tx0 = lx + 172
            local tx1 = lx + lw - 84
            if tx1 < tx0 + 40 then tx1 = tx0 + 40 end
            local knobSlot = nil
            local fillSlot = nil
            do
                local tr = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
                if tr then
                    pcall(function()
                        tr:SetBrushColor(MakeColor(J.OFF_BG.R, J.OFF_BG.G, J.OFF_BG.B, 0.9))
                        tr:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    end)
                    local trs = parent:AddChildToCanvas(tr)
                    if trs then trs:SetAutoSize(false) trs:SetPosition(V2(tx0, rowY + ROW_H/2 - 3)) trs:SetSize(V2(tx1 - tx0, 6)) trs:SetZOrder(z+2) end
                end
                local fl = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
                if fl then
                    pcall(function()
                        fl:SetBrushColor(MakeColor(J.CYAN.R, J.CYAN.G, J.CYAN.B, 1))
                        fl:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    end)
                    local fls = parent:AddChildToCanvas(fl)
                    if fls then
                        fls:SetAutoSize(false) fls:SetPosition(V2(tx0, rowY + ROW_H/2 - 3))
                        fls:SetZOrder(z+3)
                        fillSlot = fls
                    end
                end
                local kb = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
                if kb then
                    pcall(function()
                        kb:SetBrushColor(MakeColor(1, 1, 1, 1))
                        kb:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    end)
                    local kbs = parent:AddChildToCanvas(kb)
                    if kbs then
                        kbs:SetAutoSize(false) kbs:SetSize(V2(16, 20))
                        kbs:SetZOrder(z+4)
                        knobSlot = kbs
                    end
                end
            end
            local function paintSlider(nv)
                local mn, mx = (feat.min or 0), (feat.max or 100)
                local t = 0
                if mx > mn then t = math.max(0, math.min(1, (nv - mn) / (mx - mn))) end
                pcall(function()
                    if fillSlot and slua.isValid(fillSlot) then fillSlot:SetSize(V2(math.max(2, (tx1 - tx0) * t), 6)) end
                    if knobSlot then knobSlot:SetPosition(V2(tx0 + (tx1 - tx0 - 16) * t, rowY + ROW_H/2 - 10)) end
                end)
            end
            paintSlider(feat.get())
            local function menuScaleX()
                local cw = 0
                pcall(function()
                    local c = FloatingMenu.RootCanvas
                    if c and slua.isValid(c) and c.GetCachedGeometry and SlateBlueprintLibrary and SlateBlueprintLibrary.GetLocalSize then
                        local g = c:GetCachedGeometry()
                        if g then local s = SlateBlueprintLibrary.GetLocalSize(g) if s and s.X > 0 then cw = s.X end end
                    end
                end)
                local vw = 0
                pcall(function()
                    if UIUtil and UIUtil.GetViewportSize then local v = UIUtil.GetViewportSize() if v and v.X > 0 then vw = v.X end end
                end)
                if cw > 0 and vw > 0 then return cw / vw end
                return 1
            end
            local dz = CGame:NewObjectFromPath("/Script/UMG.Button", parent)
            if dz then
                pcall(function()
                    dz:SetBackgroundColor(MakeColor(0,0,0,0.001))
                    dz:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
                end)
                local dzs = parent:AddChildToCanvas(dz)
                if dzs then dzs:SetAutoSize(false) dzs:SetPosition(V2(tx0 - 6, rowY)) dzs:SetSize(V2((tx1 - tx0) + 12, ROW_H - 2)) dzs:SetZOrder(z+6) end
                local dtok = { active = false, sx = 0, sv = 0 }
                local function setFromLocal(mxl)
                    local t = (mxl - tx0) / math.max(1, (tx1 - tx0))
                    if t < 0 then t = 0 end
                    if t > 1 then t = 1 end
                    local mn, mxv, st = (feat.min or 0), (feat.max or 100), (feat.step or 1)
                    local nv = mn + math.floor(t * (mxv - mn) / st + 0.5) * st
                    if nv < mn then nv = mn end
                    if nv > mxv then nv = mxv end
                    return nv
                end
                pcall(function() dz.OnPressed:Add(function()
                    dtok.active = true
                    dtok.sx = GetMousePos()
                    dtok.sv = feat.get()
                    _G._SliderDrag = { feat = feat, tx0 = tx0, tx1 = tx1,
                        min = feat.min, max = feat.max, step = feat.step,
                        valLabel = valLabel, paint = paintSlider, sc = menuScaleX() }
                    CounterLog("SLD press " .. tostring(feat.id) .. " sv=" .. tostring(dtok.sv) .. " tx=" .. tostring(tx0) .. "-" .. tostring(tx1))
                end) end)
                pcall(function() dz.OnReleased:Add(function()
                    dtok.active = false
                    _G._SliderDrag = nil
                    CounterLog("SLD " .. tostring(feat.id) .. "=" .. tostring(feat.get()))
                    FloatingMenu.CreateMainPanel()
                end) end)
            end
            -- +/- stepper buttons flanking the track
            do
                local mn2, mx2, st2 = (feat.min or 0), (feat.max or 100), (feat.step or 5)
                JarvisBtn(parent, tx0 - 36, rowY + ROW_H/2 - 13, 30, 26, "-", function()
                    local cv = tonumber(feat.get()) or mn2
                    local nv = math.max(mn2, math.min(mx2, cv - st2))
                    feat.set(nv)
                    FloatingMenu.ShowToast(feat.name .. " · " .. tostring(nv))
                    FloatingMenu.CreateMainPanel()
                end, z+6, false, false)
                JarvisBtn(parent, tx1 + 4, rowY + ROW_H/2 - 13, 30, 26, "+", function()
                    local cv = tonumber(feat.get()) or mn2
                    local nv = math.max(mn2, math.min(mx2, cv + st2))
                    feat.set(nv)
                    FloatingMenu.ShowToast(feat.name .. " · " .. tostring(nv))
                    FloatingMenu.CreateMainPanel()
                end, z+6, false, false)
            end
        end
        rowY = rowY + ROW_H
    end

    if doStagger and #staggerList > 0 then
        local n = 0
        local st = nil
        st = MenuTimer(0.03, true, function()
            n = n + 1
            local e = staggerList[n]
            if e and slua.isValid(e) then pcall(function() e:SetRenderOpacity(1.0) end) end
            if n >= #staggerList then MenuTimerStop(st) end
        end)
        if not st then
            for _, e in ipairs(staggerList) do
                pcall(function() if e and slua.isValid(e) then e:SetRenderOpacity(1.0) end end)
            end
        end
    end

    lx, lw = lx0, lw0
    local pagY = listTop + listH - 28
    JarvisBtn(parent, lx+6, pagY, 60, 24, "◄ PREV", function()
        if FloatingMenu.CurrentPage > 1 then
            FloatingMenu.CurrentPage = FloatingMenu.CurrentPage - 1
            FloatingMenu.CreateMainPanel()
        else
            FloatingMenu.ShowToast("FIRST PAGE")
        end
    end, z+8)
    JarvisBtn(parent, lx+lw-66, pagY, 60, 24, "NEXT ►", function()
        if FloatingMenu.CurrentPage < totalPages then
            FloatingMenu.CurrentPage = FloatingMenu.CurrentPage + 1
            FloatingMenu.CreateMainPanel()
        else
            FloatingMenu.ShowToast("LAST PAGE")
        end
    end, z+8)
    Label(parent, lx+lw/2, pagY+12, string.format("PAGE %d/%d · %d ITEMS", FloatingMenu.CurrentPage, totalPages, #features), 9, J.CYAN_HI, z+9, V2(0.5, 0.5))
end

-- NIVO robot badge: theme-primary head + white face + dark eyes. Returns head widget.
local function RobotBadge(parent, x, y, s, zBase)
    local V2 = _FAST_V2 or import("Vector2D")
    local z = zBase or 100
    local head = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
    if head then
        pcall(function()
            head:SetBrushColor(MakeColor(J.CYAN.R, J.CYAN.G, J.CYAN.B, 1))
            head:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local hs = parent:AddChildToCanvas(head)
        if hs then hs:SetAutoSize(false) hs:SetPosition(V2(x, y)) hs:SetSize(V2(s, s * 0.86)) hs:SetZOrder(z) end
    end
    local fw, fh = s * 0.62, s * 0.44
    local face = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
    if face then
        pcall(function()
            face:SetBrushColor(MakeColor(1, 1, 1, 1))
            face:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local fs = parent:AddChildToCanvas(face)
        if fs then fs:SetAutoSize(false) fs:SetPosition(V2(x + (s - fw) / 2, y + s * 0.16)) fs:SetSize(V2(fw, fh)) fs:SetZOrder(z + 1) end
    end
    local ew = math.max(2, s * 0.09)
    local eh = math.max(3, s * 0.13)
    for i = 0, 1 do
        local eye = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
        if eye then
            pcall(function()
                eye:SetBrushColor(MakeColor(0.05, 0.08, 0.15, 1))
                eye:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local es = parent:AddChildToCanvas(eye)
            if es then
                es:SetAutoSize(false)
                es:SetPosition(V2(x + s * 0.30 + i * s * 0.30 - ew / 2, y + s * 0.30))
                es:SetSize(V2(ew, eh))
                es:SetZOrder(z + 2)
            end
        end
    end
    return head
end

function FloatingMenu.RenderLeftColumn(parent, x, y, w, h, zBase)
    local V2 = _FAST_V2 or import("Vector2D")
    local z = zBase or 100
    HoloPanel(parent, x, y, w, 64, z)
    RobotBadge(parent, x + 8, y + 12, 34, z+6)
    Label(parent, x + 50, y + 28, "NIVO", 13, J.CYAN_HI, z+6)
    Label(parent, x + 50, y + 46, "CHEATS", 9, J.TEXT_DIM, z+6)

    local midY = y + 68
    local midH = 118
    HoloPanel(parent, x, midY, w, midH, z)
    Label(parent, x+6, midY+12, "QUICK", 8, J.CYAN_HI, z+4)
    local btnW = (w - 16) / 2
    local quick = { { id = "Aimbot", label = "AIM" }, { id = "Wallhack", label = "WALL" }, { id = "LineESP", label = "LINE" }, { id = "CounterTop", label = "COUNT" } }
    local allFeats = FloatingMenu.GetAllFeatures()
    for i, q in ipairs(quick) do
        local col = (i-1) % 2
        local row = math.floor((i-1)/2)
        local bx = x + 6 + col * (btnW + 4)
        local by = midY + 26 + row * 28
        local feat = nil
        for _,f in ipairs(allFeats) do if f.id == q.id then feat = f break end end
        local isOn = feat and (feat.get() == 1) or false
        JarvisBtn(parent, bx, by, btnW, 24, q.label .. (isOn and " ●" or " ○"), function()
            if feat then
                local curOn = feat.get() == 1
                feat.set(not curOn)
                local nowOn = feat.get() == 1
                FloatingMenu.ShowToast(q.label .. (nowOn and " ON" or " OFF"))
                FloatingMenu.CreateMainPanel()
            end
        end, z+5, isOn)
    end

    local stY = midY + midH + 4
    local stH = h - 68 - midH - 4
    HoloPanel(parent, x, stY, w, stH, z)
    Label(parent, x+6, stY+12, "STATUS", 8, J.CYAN_HI, z+4)
    local nOn, nTotal = MenuCountOn()
    Label(parent, x+6, stY+30, "ACTIVE", 8, J.TEXT_DIM, z+4)
    Label(parent, x+w-6, stY+30, tostring(nOn) .. "/" .. tostring(nTotal), 8, J.SUCCESS, z+4, V2(1, 0.5))
    Label(parent, x+6, stY+48, "MENU", 8, J.TEXT_DIM, z+4)
    Label(parent, x+w-6, stY+48, MENU_VER, 8, J.CYAN_HI, z+4, V2(1, 0.5))
end

local function MenuUptime()
    local s = 0
    pcall(function()
        if _G._MenuBootClock then s = math.floor(os.clock() - _G._MenuBootClock) end
    end)
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    s = s % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

function FloatingMenu.RenderRightColumn(parent, x, y, w, h, zBase)
    local V2 = _FAST_V2 or import("Vector2D")
    local z = zBase or 100
    HoloPanel(parent, x, y, w, 64, z)
    Label(parent, x + w/2, y + 22, "●", 16, J.SUCCESS, z+6, V2(0.5, 0.5))
    Label(parent, x + w/2, y + 46, "ONLINE", 9, J.TEXT_MAIN, z+6, V2(0.5, 0.5))

    local midY = y + 68
    local midH = 118
    HoloPanel(parent, x, midY, w, midH, z)
    Label(parent, x+6, midY+12, "SESSION", 8, J.CYAN_HI, z+4)
    local nOn, nTotal = MenuCountOn()
    local rows = { {"ACTIVE", tostring(nOn) .. "/" .. tostring(nTotal)}, {"UPTIME", MenuUptime()}, {"VERSION", MENU_VER} }
    for i, r in ipairs(rows) do
        local ry = midY + 30 + (i-1) * 26
        Label(parent, x+6, ry, r[1], 8, J.TEXT_DIM, z+4)
        Label(parent, x+w-6, ry, r[2], 8, J.CYAN_HI, z+4, V2(1, 0.5))
    end

    local envY = midY + midH + 4
    local envH = h - 68 - midH - 4
    HoloPanel(parent, x, envY, w, envH, z)
    Label(parent, x+6, envY+12, "STATE", 8, J.CYAN_HI, z+4)
    Label(parent, x+6, envY+30, "CORE", 8, J.TEXT_DIM, z+4)
    Label(parent, x+w-6, envY+30, "ACTIVE", 8, J.SUCCESS, z+4, V2(1, 0.5))
end

local function OpenLink(url)
    local done = false
    pcall(function()
        local WS = _G.WebviewSDK or WebviewSDK
        if WS and WS.OpenURL then WS:OpenURL(url) done = true end
    end)
    if not done then
        pcall(function()
            local Cl = _G.Client or Client
            if Cl and Cl.OpenURLInSDK then Cl.OpenURLInSDK(url, false, true, false, "{}") done = true end
        end)
    end
    return done
end

function FloatingMenu.RenderNavView(parent, x, y, w, h, zBase)
    local V2 = _FAST_V2 or import("Vector2D")
    local z = zBase or 100
    HoloPanel(parent, x, y, w, h, z)
    Label(parent, x+12, y+16, "NAVIGATE", 10, J.CYAN_HI, z+4)
    local catIcons = {
        Combat = "/Game/UMG/Texture/Atlas/Lobby_JBK/Frames/JBK_icon_miaoju_png.JBK_icon_miaoju_png",
    }
    local cats = { {"All","ALL"}, {"ESP","ESP"}, {"Combat","CMB"}, {"Misc","MSC"}, {"Favorites","FAV"} }
    local gap = 8
    local cw = (w - 16 - gap * 2) / 3
    local chh = 62
    for i, c in ipairs(cats) do
        local col = (i - 1) % 3
        local row = math.floor((i - 1) / 3)
        local cx = x + 8 + col * (cw + gap)
        local cy = y + 32 + row * (chh + gap)
        local isActive = (FloatingMenu.ActiveTab == c[1])
        local fr = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
        if fr then
            pcall(function()
                if isActive then fr:SetBrushColor(MakeColor(J.CYAN.R, J.CYAN.G, J.CYAN.B, 1))
                else fr:SetBrushColor(MakeColor(J.CYAN_DIM.R, J.CYAN_DIM.G, J.CYAN_DIM.B, 0.55)) end
                fr:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local frs = parent:AddChildToCanvas(fr)
            if frs then frs:SetAutoSize(false) frs:SetPosition(V2(cx, cy)) frs:SetSize(V2(cw, chh)) frs:SetZOrder(z+1) end
        end
        local fi = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
        if fi then
            pcall(function()
                if isActive then fi:SetBrushColor(MakeColor(J.ON_BG.R, J.ON_BG.G, J.ON_BG.B, J.ON_BG.A))
                else fi:SetBrushColor(MakeColor(J.OFF_BG.R, J.OFF_BG.G, J.OFF_BG.B, J.OFF_BG.A)) end
                fi:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local fis = parent:AddChildToCanvas(fi)
            if fis then fis:SetAutoSize(false) fis:SetPosition(V2(cx + 1, cy + 1)) fis:SetSize(V2(cw - 2, chh - 2)) fis:SetZOrder(z+1) end
        end
        Label(parent, cx + 12, cy + chh/2, MenuSym(c[1]), 15, isActive and J.CYAN_HI or J.TEXT_DIM, z+2, V2(0, 0.5))
        do
            local ipath = catIcons[c[1]]
            if ipath then
                local im = CGame:NewObjectFromPath("/Script/UMG.Image", parent)
                if im then
                    pcall(function()
                        if im.SetWidgetVisibility then im:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
                        if im.SetBrushFromPathAsync then im:SetBrushFromPathAsync(ipath, false) end
                    end)
                    local ims = parent:AddChildToCanvas(im)
                    if ims then ims:SetAutoSize(false) ims:SetPosition(V2(cx + 8, cy + chh/2 - 12)) ims:SetSize(V2(24, 24)) ims:SetZOrder(z+3) end
                end
            end
        end
        Label(parent, cx + 40, cy + chh/2, c[1], 11, isActive and J.TEXT_HI or J.TEXT_MAIN, z+2, V2(0, 0.5))
        local cat = c[1]
        local hit = CGame:NewObjectFromPath("/Script/UMG.Button", parent)
        if hit then
            pcall(function()
                hit:SetBackgroundColor(MakeColor(0,0,0,0.001))
                hit:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
            end)
            local hs2 = parent:AddChildToCanvas(hit)
            if hs2 then hs2:SetAutoSize(false) hs2:SetPosition(V2(cx, cy)) hs2:SetSize(V2(cw, chh)) hs2:SetZOrder(z+4) end
            pcall(function() hit.OnClicked:Add(function()
                FloatingMenu.ActiveTab = cat
                FloatingMenu.CurrentPage = 1
                FloatingMenu.NavOpen = false
                FloatingMenu._FreshOpen = true
                FloatingMenu.CreateMainPanel()
            end) end)
        end
    end
    local ay = y + 32 + 3 * (chh + gap) + 6
    JarvisBtn(parent, x + 8, ay, (w - 24) / 2, 28, "CONTACT US", function()
        if not OpenLink("https://t.me/trndravix") then
            FloatingMenu.ShowToast("CONTACT · @trndravix")
        end
    end, z+5, false)
    JarvisBtn(parent, x + 16 + (w - 24) / 2, ay, (w - 24) / 2, 28, "JOIN CHANNEL", function()
        if not OpenLink("https://t.me/nivocheats") then
            FloatingMenu.ShowToast("JOIN · @nivocheats")
        end
    end, z+5, false)
end

function FloatingMenu.CreateMainPanel()
    FloatingMenu.DestroyRoot()
    local canvas = FloatingMenu.RootCanvas
    if not canvas or not slua.isValid(canvas) then return false end
    local V2 = _FAST_V2 or import("Vector2D")
    local screenW, screenH = MenuCanvasSize(canvas)

    FloatingMenu.RebuildWrappedFeatures()

    local doEntryAnim = FloatingMenu._FreshOpen == true

    local ac = 0
    for _,f in ipairs(_G.AK_Features) do if f.type == "toggle" and f.val == 1 then ac = ac + 1 end end
    FloatingMenu._activeCount = ac

    local container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas)
    if not container or not slua.isValid(container) then return false end
    local cslot = canvas:AddChildToCanvas(container)
    if not cslot then return false end
    cslot:SetPosition(V2(0, 0)) cslot:SetSize(V2(screenW, screenH)) cslot:SetAutoSize(false) cslot:SetZOrder(2800)
    FloatingMenu.RootContainer = container
    FloatingMenu._RootSlot = cslot

    local px = (screenW - TOTAL_W) / 2
    local py = (screenH - TOTAL_H) / 2
    FloatingMenu._PanelX = px
    FloatingMenu._PanelY = py

    HoloPanel(container, px, py, TOTAL_W, TOTAL_H, 10, true)

    local topBar = CGame:NewObjectFromPath("/Script/UMG.Border", container)
    if topBar then
        pcall(function()
            topBar:SetBrushColor(MakeColor(J.BAR_BG.R, J.BAR_BG.G, J.BAR_BG.B, J.BAR_BG.A or 0.95))
            topBar:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local ts = container:AddChildToCanvas(topBar)
        if ts then ts:SetAutoSize(false) ts:SetPosition(V2(px, py)) ts:SetSize(V2(TOTAL_W, TOP_H)) ts:SetZOrder(15) end
    end

    FloatingMenu.DrawerInline = FloatingMenu.DrawerInline == true
    do
        local ham = CGame:NewObjectFromPath("/Script/UMG.Button", container)
        if ham then
            pcall(function()
                ham:SetBackgroundColor(MakeColor(0,0,0,0.001))
                ham:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
            end)
            local hs = container:AddChildToCanvas(ham)
            if hs then hs:SetAutoSize(false) hs:SetPosition(V2(px + 8, py + 5)) hs:SetSize(V2(30, TOP_H - 10)) hs:SetZOrder(21) end
            pcall(function() ham.OnClicked:Add(function()
                FloatingMenu.DrawerInline = not FloatingMenu.DrawerInline
                FloatingMenu._FreshOpen = true
                FloatingMenu.CreateMainPanel()
            end) end)
        end
        if FloatingMenu.DrawerInline then
            for i = 1, 2 do
                local bar = CGame:NewObjectFromPath("/Script/UMG.Border", container)
                if bar then
                    pcall(function()
                        bar:SetBrushColor(MakeColor(J.TEXT_HI.R, J.TEXT_HI.G, J.TEXT_HI.B, 1))
                        bar:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    end)
                    local bs2 = container:AddChildToCanvas(bar)
                    if bs2 then
                        bs2:SetAutoSize(false) bs2:SetPosition(V2(px + 11, py + 18)) bs2:SetSize(V2(24, 2)) bs2:SetZOrder(20)
                        if bar.SetRenderAngle then bar:SetRenderAngle(i == 1 and 45 or -45) end
                    end
                end
            end
        else
            for i = 0, 2 do
                local bar = CGame:NewObjectFromPath("/Script/UMG.Border", container)
                if bar then
                    pcall(function()
                        bar:SetBrushColor(MakeColor(J.TEXT_HI.R, J.TEXT_HI.G, J.TEXT_HI.B, 1))
                        bar:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    end)
                    local bs2 = container:AddChildToCanvas(bar)
                    if bs2 then bs2:SetAutoSize(false) bs2:SetPosition(V2(px + 13, py + 13 + i * 7)) bs2:SetSize(V2(20, 2)) bs2:SetZOrder(20) end
                end
            end
        end
    end
    local badgeHead = RobotBadge(container, px + 44, py + (TOP_H - 30) / 2, 30, 16)
    FloatingMenu._BadgeRef = badgeHead
    FloatingMenu._TitleRef = Label(container, px + TOTAL_W/2, py + TOP_H/2, "◆ NIVO CHEATS", 13, J.CYAN_HI, 16, V2(0.5, 0.5))

    local onlineDot = CGame:NewObjectFromPath("/Script/UMG.Border", container)
    if onlineDot then
        pcall(function()
            onlineDot:SetBrushColor(MakeColor(0.20, 1.00, 0.55, 1))
            onlineDot:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local ods = container:AddChildToCanvas(onlineDot)
        if ods then ods:SetAutoSize(false) ods:SetPosition(V2(px + TOTAL_W - 206, py + TOP_H/2 - 3)) ods:SetSize(V2(6, 6)) ods:SetZOrder(16) end
    end
    Label(container, px + TOTAL_W - 196, py + TOP_H/2, "ONLINE", 9, J.SUCCESS, 16, V2(0, 0.5))
    JarvisBtn(container, px + TOTAL_W - 30, py + 6, 26, 22, "×", function() FloatingMenu.Minimize() end, 17, false, true)

    local bodyY = py + TOP_H + 4
    local bodyH = TOTAL_H - TOP_H - BOT_H - 8

    local centerX = px + 8
    local centerW = TOTAL_W - 16
    if FloatingMenu.DrawerInline then
        local dwI = 190
        pcall(function() FloatingMenu.RenderDrawerInline(container, centerX, bodyY, dwI, bodyH, 100) end)
        centerX = centerX + dwI + 8
        centerW = centerW - dwI - 8
    end
    if FloatingMenu.NavOpen then
        pcall(function() FloatingMenu.RenderNavView(container, centerX, bodyY, centerW, bodyH, 100) end)
    else
        pcall(function() FloatingMenu.RenderFeatureList(container, centerX, bodyY, centerW, bodyH, 100) end)
    end

    local botY = py + TOTAL_H - BOT_H
    local botBar = CGame:NewObjectFromPath("/Script/UMG.Border", container)
    if botBar then
        pcall(function()
            botBar:SetBrushColor(MakeColor(J.BAR_BG.R, J.BAR_BG.G, J.BAR_BG.B, J.BAR_BG.A or 0.95))
            botBar:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local bs = container:AddChildToCanvas(botBar)
        if bs then bs:SetAutoSize(false) bs:SetPosition(V2(px, botY)) bs:SetSize(V2(TOTAL_W, BOT_H)) bs:SetZOrder(15) end
    end
    Label(container, px + 10, botY + BOT_H/2, "◈ NIVO CHEATS · " .. MENU_VER, 8, J.CYAN_HI, 16)
    do
        local dx = px + TOTAL_W - 52
        for i = #THEMES, 1, -1 do
            local t = THEMES[i]
            if t and t.roles and t.roles.CYAN then
                if FloatingMenu.ThemeIdx == i then
                    local halo = CGame:NewObjectFromPath("/Script/UMG.Border", container)
                    if halo then
                        pcall(function()
                            halo:SetBrushColor(MakeColor(1, 1, 1, 0.85))
                            halo:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        end)
                        local hs3 = container:AddChildToCanvas(halo)
                        if hs3 then hs3:SetAutoSize(false) hs3:SetPosition(V2(dx - 2, botY + 4)) hs3:SetSize(V2(20, 20)) hs3:SetZOrder(18) end
                    end
                end
                local dot = CGame:NewObjectFromPath("/Script/UMG.Border", container)
                if dot then
                    pcall(function()
                        dot:SetBrushColor(MakeColor(t.roles.CYAN.R, t.roles.CYAN.G, t.roles.CYAN.B, 1))
                        dot:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    end)
                    local ds = container:AddChildToCanvas(dot)
                    if ds then ds:SetAutoSize(false) ds:SetPosition(V2(dx, botY + 6)) ds:SetSize(V2(16, 16)) ds:SetZOrder(19) end
                    local idx = i
                    local hit = CGame:NewObjectFromPath("/Script/UMG.Button", container)
                    if hit then
                        pcall(function()
                            hit:SetBackgroundColor(MakeColor(0,0,0,0.001))
                            hit:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
                        end)
                        local hs2 = container:AddChildToCanvas(hit)
                        if hs2 then hs2:SetAutoSize(false) hs2:SetPosition(V2(dx - 3, botY + 3)) hs2:SetSize(V2(22, 22)) hs2:SetZOrder(20) end
                        pcall(function() hit.OnClicked:Add(function()
                            if ApplyTheme(idx) then
                                FloatingMenu.ShowToast("THEME · " .. THEMES[idx].name)
                                FloatingMenu.CreateMainPanel()
                            end
                        end) end)
                    end
                end
            end
            dx = dx - 28
        end
    end
    -- (drawer nav owns categories; layout switch retired)

    -- (CONTACT/JOIN live in NAV view now; footer stays slim)

    -- (clock removed v17)

    if doEntryAnim then
    pcall(function()
        if slua.isValid(container) then
            if cslot and cslot.SetPosition then cslot:SetPosition(V2(-40, 0)) end
            if container.SetRenderOpacity then container:SetRenderOpacity(0.15) end
            local as = 0
            local st = nil
            st = MenuTimer(0.03, true, function()
                as = as + 1
                local t = math.min(1, as / 8)
                pcall(function()
                    if slua.isValid(container) then
                        if cslot and cslot.SetPosition then cslot:SetPosition(V2(-40 * (1 - t), 0)) end
                        container:SetRenderOpacity(0.15 + 0.85 * t)
                    end
                end)
                if t >= 1 or not FloatingMenu.IsOpen then MenuTimerStop(st) end
            end)
            if not st then
                if cslot and cslot.SetPosition then cslot:SetPosition(V2(0, 0)) end
                if container.SetRenderOpacity then container:SetRenderOpacity(1.0) end
            end
        end
    end)
    end
    FloatingMenu.StartAnimations()
    return true
end

-- ============================================================
-- ============================================================
-- DRAVIX MENU PART C - open/minimize/toggle-button/init/boot
-- ============================================================
FloatingMenu.DrawerOpen = false
FloatingMenu.DrawerRef = nil
FloatingMenu._DrawerTimer = nil
FloatingMenu._Minimizing = false

local function DrawerStopTimer()
    MenuTimerStop(FloatingMenu._DrawerTimer)
    FloatingMenu._DrawerTimer = nil
end

local function DrawerCatCount(cat)
    local n = 0
    for _,f in ipairs(FloatingMenu.GetAllFeatures()) do
        if cat == "All" or f.category == cat then n = n + 1 end
    end
    return n
end

local DR_CAT_ICONS = {
    Combat = "/Game/UMG/Texture/Atlas/Lobby_JBK/Frames/JBK_icon_miaoju_png.JBK_icon_miaoju_png",
}

function FloatingMenu.CloseDrawer(instant, after)
    if not FloatingMenu.DrawerOpen and not FloatingMenu.DrawerRef then
        if after then pcall(after) end
        return
    end
    FloatingMenu.DrawerOpen = false
    DrawerStopTimer()
    local ref = FloatingMenu.DrawerRef
    FloatingMenu.DrawerRef = nil
    local function kill()
        pcall(function()
            if ref then
                if ref.box and slua.isValid(ref.box) then ref.box:RemoveFromParent() end
                if ref.dim and slua.isValid(ref.dim) then ref.dim:RemoveFromParent() end
                if ref.dimHit and slua.isValid(ref.dimHit) then ref.dimHit:RemoveFromParent() end
            end
        end)
        if after then pcall(after) end
    end
    if instant then kill() return end
    local moved = false
    pcall(function()
        local x0 = FloatingMenu._PanelX or 0
        if ref and ref.box and slua.isValid(ref.box) and ref.slot then
            moved = true
            local n = 0
            local V2 = _FAST_V2 or import("Vector2D")
            local st = nil
            st = MenuTimer(0.02, true, function()
                n = n + 1
                local tl = math.min(1, n / 6)
                local t = 1 - (1 - tl) * (1 - tl)
                pcall(function()
                    if ref.slot then ref.slot:SetPosition(V2(x0 + 40 * t, FloatingMenu._PanelY or 0)) end
                    if ref.box and slua.isValid(ref.box) and ref.box.SetRenderOpacity then
                        ref.box:SetRenderOpacity(1 - 0.85 * t)
                    end
                end)
                if t >= 1 then
                    MenuTimerStop(st)
                    FloatingMenu._DrawerTimer = nil
                    kill()
                end
            end)
            FloatingMenu._DrawerTimer = st
            if not st then moved = false end
        end
    end)
    if not moved then kill() end
end

function FloatingMenu.OpenDrawer()
    if FloatingMenu.DrawerOpen then return end
    local rc = FloatingMenu.RootContainer
    if not rc or not slua.isValid(rc) then return end
    local V2 = _FAST_V2 or import("Vector2D")
    local px = FloatingMenu._PanelX or 0
    local py = FloatingMenu._PanelY or 0
    local dw = 230
    FloatingMenu.CloseDrawer(true)
    FloatingMenu.DrawerOpen = true
    local box = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", rc)
    if not box then FloatingMenu.DrawerOpen = false return end
    local slot = rc:AddChildToCanvas(box)
    if not slot then FloatingMenu.DrawerOpen = false return end
    slot:SetAutoSize(false) slot:SetPosition(V2(px - dw, py)) slot:SetSize(V2(dw, TOTAL_H)) slot:SetZOrder(2005)
    FloatingMenu.DrawerRef = { box = box, slot = slot }
    HoloPanel(box, 0, 0, dw, TOTAL_H, 2006)
    local edge = CGame:NewObjectFromPath("/Script/UMG.Border", box)
    if edge then
        pcall(function()
            edge:SetBrushColor(MakeColor(J.CYAN.R, J.CYAN.G, J.CYAN.B, 1))
            edge:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local es = box:AddChildToCanvas(edge)
        if es then es:SetAutoSize(false) es:SetPosition(V2(dw - 3, 0)) es:SetSize(V2(3, TOTAL_H)) es:SetZOrder(2007) end
    end
    Label(box, 12, 20, "NAVIGATE", 10, J.CYAN_HI, 2008)
    local cats = { {"All","ALL"}, {"ESP","ESP"}, {"Combat","CMB"}, {"Misc","MSC"}, {"Favorites","FAV"} }
    local ry = 44
    for _, c in ipairs(cats) do
        local isActive = (FloatingMenu.ActiveTab == c[1])
        local fr = CGame:NewObjectFromPath("/Script/UMG.Border", box)
        if fr then
            pcall(function()
                if isActive then fr:SetBrushColor(MakeColor(J.CYAN.R, J.CYAN.G, J.CYAN.B, 1))
                else fr:SetBrushColor(MakeColor(J.CYAN_DIM.R, J.CYAN_DIM.G, J.CYAN_DIM.B, 0.5)) end
                fr:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local frs = box:AddChildToCanvas(fr)
            if frs then frs:SetAutoSize(false) frs:SetPosition(V2(8, ry)) frs:SetSize(V2(dw - 16, 32)) frs:SetZOrder(2008) end
        end
        local fi = CGame:NewObjectFromPath("/Script/UMG.Border", box)
        if fi then
            pcall(function()
                if isActive then fi:SetBrushColor(MakeColor(J.ON_BG.R, J.ON_BG.G, J.ON_BG.B, J.ON_BG.A))
                else fi:SetBrushColor(MakeColor(J.OFF_BG.R, J.OFF_BG.G, J.OFF_BG.B, J.OFF_BG.A)) end
                fi:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local fis = box:AddChildToCanvas(fi)
            if fis then fis:SetAutoSize(false) fis:SetPosition(V2(9, ry + 1)) fis:SetSize(V2(dw - 18, 30)) fis:SetZOrder(2008) end
        end
        Label(box, 14, ry + 16, MenuSym(c[1]), 11, isActive and J.CYAN_HI or J.TEXT_DIM, 2008, V2(0, 0.5))
        do
            local ipath = DR_CAT_ICONS and DR_CAT_ICONS[c[1]] or nil
            if ipath then
                local im = CGame:NewObjectFromPath("/Script/UMG.Image", box)
                if im then
                    pcall(function()
                        if im.SetWidgetVisibility then im:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
                        if im.SetBrushFromPathAsync then im:SetBrushFromPathAsync(ipath, false) end
                    end)
                    local ims = box:AddChildToCanvas(im)
                    if ims then ims:SetAutoSize(false) ims:SetPosition(V2(11, ry + 5)) ims:SetSize(V2(22, 22)) ims:SetZOrder(2009) end
                end
            end
        end
        Label(box, 42, ry + 16, c[2], 11, isActive and J.TEXT_HI or J.TEXT_MAIN, 2009, V2(0, 0.5))
        if isActive then
            local abar = CGame:NewObjectFromPath("/Script/UMG.Border", box)
            if abar then
                pcall(function()
                    abar:SetBrushColor(MakeColor(J.CYAN_HI.R, J.CYAN_HI.G, J.CYAN_HI.B, 1))
                    abar:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                end)
                local abs = box:AddChildToCanvas(abar)
                if abs then abs:SetAutoSize(false) abs:SetPosition(V2(8, ry)) abs:SetSize(V2(3, 32)) abs:SetZOrder(2010) end
            end
        end
        local cat = c[1]
        local hit = CGame:NewObjectFromPath("/Script/UMG.Button", box)
        if hit then
            pcall(function()
                hit:SetBackgroundColor(MakeColor(0,0,0,0.001))
                hit:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
            end)
            local hs2 = box:AddChildToCanvas(hit)
            if hs2 then hs2:SetAutoSize(false) hs2:SetPosition(V2(8, ry)) hs2:SetSize(V2(dw - 16, 32)) hs2:SetZOrder(2010) end
            pcall(function() hit.OnClicked:Add(function()
                FloatingMenu.ActiveTab = cat
                FloatingMenu.CurrentPage = 1
                FloatingMenu.CloseDrawer(false, function()
                    FloatingMenu._FreshOpen = true
                    FloatingMenu.CreateMainPanel()
                end)
            end) end)
        end
        ry = ry + 38
    end
    Label(box, dw/2, ry + 24, "NIVO CHEATS · " .. MENU_VER, 9, J.TEXT_DIM, 2008, V2(0.5, 0.5))
    pcall(function()
        if slua.isValid(box) then
            if slot then slot:SetPosition(V2(px + 40, py)) end
            if box.SetRenderOpacity then box:SetRenderOpacity(0.15) end
            local n = 0
            local st = nil
            st = MenuTimer(0.02, true, function()
                n = n + 1
                local tl = math.min(1, n / 6)
                local t = 1 - (1 - tl) * (1 - tl)
                pcall(function()
                    if slua.isValid(box) then
                        if slot then slot:SetPosition(V2(px + 40 * (1 - t), py)) end
                        if box.SetRenderOpacity then box:SetRenderOpacity(0.15 + 0.85 * t) end
                    end
                end)
                if t >= 1 then
                    MenuTimerStop(st)
                    FloatingMenu._DrawerTimer = nil
                    kill()
                end
            end)
            FloatingMenu._DrawerTimer = st
        else
            if slot then slot:SetPosition(V2(px, py)) end
        end
    end)
end

function FloatingMenu.ToggleDrawer()
    if FloatingMenu.DrawerOpen then FloatingMenu.CloseDrawer()
    else FloatingMenu.OpenDrawer() end
end

function FloatingMenu.RenderDrawerInline(parent, x, y, w, h, zBase)
    local V2 = _FAST_V2 or import("Vector2D")
    local z = zBase or 100
    local catIcons = {
        Combat = "/Game/UMG/Texture/Atlas/Lobby_JBK/Frames/JBK_icon_miaoju_png.JBK_icon_miaoju_png",
    }
    HoloPanel(parent, x, y, w, h, z)
    local cats = { {"All","ALL"}, {"ESP","ESP"}, {"Combat","CMB"}, {"Misc","MSC"}, {"Favorites","FAV"} }
    local ry = y + 4
    for _, c in ipairs(cats) do
        local isActive = (FloatingMenu.ActiveTab == c[1])
        local fr = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
        if fr then
            pcall(function()
                if isActive then fr:SetBrushColor(MakeColor(J.CYAN.R, J.CYAN.G, J.CYAN.B, 1))
                else fr:SetBrushColor(MakeColor(J.CYAN_DIM.R, J.CYAN_DIM.G, J.CYAN_DIM.B, 0.5)) end
                fr:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local frs = parent:AddChildToCanvas(fr)
            if frs then frs:SetAutoSize(false) frs:SetPosition(V2(x + 6, ry)) frs:SetSize(V2(w - 12, 28)) frs:SetZOrder(z + 1) end
        end
        local fi = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
        if fi then
            pcall(function()
                if isActive then fi:SetBrushColor(MakeColor(J.ON_BG.R, J.ON_BG.G, J.ON_BG.B, J.ON_BG.A))
                else fi:SetBrushColor(MakeColor(J.OFF_BG.R, J.OFF_BG.G, J.OFF_BG.B, J.OFF_BG.A)) end
                fi:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local fis = parent:AddChildToCanvas(fi)
            if fis then fis:SetAutoSize(false) fis:SetPosition(V2(x + 7, ry + 1)) fis:SetSize(V2(w - 14, 26)) fis:SetZOrder(z + 1) end
        end
        Label(parent, x + 12, ry + 14, MenuSym(c[1]), 11, isActive and J.CYAN_HI or J.TEXT_DIM, z + 2, V2(0, 0.5))
        do
            local ipath = catIcons[c[1]]
            if ipath then
                local im = CGame:NewObjectFromPath("/Script/UMG.Image", parent)
                if im then
                    pcall(function()
                        if im.SetWidgetVisibility then im:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
                        if im.SetBrushFromPathAsync then im:SetBrushFromPathAsync(ipath, false) end
                    end)
                    local ims = parent:AddChildToCanvas(im)
                    if ims then ims:SetAutoSize(false) ims:SetPosition(V2(x + 30, ry + 4)) ims:SetSize(V2(20, 20)) ims:SetZOrder(z + 3) end
                end
            end
        end
        Label(parent, x + 56, ry + 14, c[1], 10, isActive and J.TEXT_HI or J.TEXT_MAIN, z + 2, V2(0, 0.5))
        local cat = c[1]
        local hit = CGame:NewObjectFromPath("/Script/UMG.Button", parent)
        if hit then
            pcall(function()
                hit:SetBackgroundColor(MakeColor(0,0,0,0.001))
                hit:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
            end)
            local hs2 = parent:AddChildToCanvas(hit)
            if hs2 then hs2:SetAutoSize(false) hs2:SetPosition(V2(x + 6, ry)) hs2:SetSize(V2(w - 12, 28)) hs2:SetZOrder(z + 4) end
            pcall(function() hit.OnClicked:Add(function()
                FloatingMenu.ActiveTab = cat
                FloatingMenu.CurrentPage = 1
                FloatingMenu.DrawerInline = false
                FloatingMenu._FreshOpen = true
                FloatingMenu.CreateMainPanel()
            end) end)
        end
        ry = ry + 30
    end
    JarvisBtn(parent, x + 6, ry + 4, w - 12, 24, "CONTACT US", function()
        if not OpenLink("https://t.me/trndravix") then
            FloatingMenu.ShowToast("CONTACT · @trndravix")
        end
    end, z + 5, false)
    JarvisBtn(parent, x + 6, ry + 32, w - 12, 24, "JOIN CHANNEL", function()
        if not OpenLink("https://t.me/nivocheats") then
            FloatingMenu.ShowToast("JOIN · @nivocheats")
        end
    end, z + 5, false)
end

function FloatingMenu.OpenPanel()
    CounterLog("PANEL open tap")
    FloatingMenu.IsOpen = true
    FloatingMenu.NavOpen = false
    FloatingMenu._Minimizing = false
    FloatingMenu._FreshOpen = true
    FloatingMenu.DestroyToggle()
    FloatingMenu.CurrentPage = 1
    if not FloatingMenu.RootCanvas or not slua.isValid(FloatingMenu.RootCanvas) then
        CounterLog("PANEL recanvas")
        FloatingMenu.Initialized = false
        FloatingMenu.RootCanvas = nil
        pcall(function() FloatingMenu.Init() end)
    end
    local ok, err = pcall(FloatingMenu.CreateMainPanel)
    if ok then
        CounterLog("PANEL build " .. tostring(ok))
    else
        CounterLog("PANEL build false ERR " .. tostring(err):sub(1, 300))
    end
end
function FloatingMenu.Minimize()
    if FloatingMenu._Minimizing then return end
    FloatingMenu.IsOpen = false
    FloatingMenu.DrawerOpen = false
    local rc = FloatingMenu.RootContainer
    local done = false
    CounterLog("MIN tap")
    pcall(function()
        if rc and slua.isValid(rc) then
            FloatingMenu._Minimizing = true
            done = true
            local n = 0
            local V2 = _FAST_V2 or import("Vector2D")
            local st = nil
            st = MenuTimer(0.03, true, function()
                n = n + 1
                local t = math.min(1, n / 5)
                if n == 1 then CounterLog("MIN tick start") end
                pcall(function()
                    if slua.isValid(rc) and rc.SetRenderOpacity then
                        rc:SetRenderOpacity(1 - 0.85 * t)
                    end
                    local rs0 = FloatingMenu._RootSlot
                    if rs0 and V2 then rs0:SetPosition(V2(0, -30 * t)) end
                end)
                if t >= 1 then
                    MenuTimerStop(st)
                    CounterLog("MIN done")
                    FloatingMenu._Minimizing = false
                    FloatingMenu.DestroyRoot()
                    FloatingMenu.CreateToggleButton()
                end
            end)
            if not st then
                CounterLog("MIN no-timer fallback")
                FloatingMenu._Minimizing = false
                done = false
            end
        else
            CounterLog("MIN no-container fallback")
        end
    end)
    if not done then
        FloatingMenu.DestroyRoot()
        FloatingMenu.CreateToggleButton()
    end
end
function FloatingMenu.Close() FloatingMenu.Minimize() end

function FloatingMenu.CreateToggleButton()
    FloatingMenu.DestroyToggle()
    local canvas = FloatingMenu.RootCanvas
    if not canvas then return false end
    local V2 = _FAST_V2 or import("Vector2D")
    local pw, ph = 142, 40
    local container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas)
    if not container then CounterLog("MENU btn-nocontainer") return false end
    local cslot = canvas:AddChildToCanvas(container)
    if not cslot then
        CounterLog("MENU btn-noslot")
        pcall(function() container:RemoveFromParent() end)
        return false
    end
    cslot:SetPosition(V2(DragState.BtnX, DragState.BtnY))
    cslot:SetSize(V2(pw + 12, ph + 12))
    cslot:SetAutoSize(false)
    cslot:SetZOrder(5100)
    FloatingMenu.ToggleContainer = container
    DragState.Slot = cslot

    local base = CGame:NewObjectFromPath("/Script/UMG.Border", container)
    if base then
        pcall(function()
            base:SetBrushColor(MakeColor(J.BTN_BG.R, J.BTN_BG.G, J.BTN_BG.B, J.BTN_BG.A or 0.95))
            base:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local bs = container:AddChildToCanvas(base)
        if bs then bs:SetAutoSize(false) bs:SetPosition(V2(6, 6)) bs:SetSize(V2(pw, ph)) bs:SetZOrder(1) end
    end
    local te = CGame:NewObjectFromPath("/Script/UMG.Border", container)
    if te then
        pcall(function()
            te:SetBrushColor(MakeColor(J.CYAN.R, J.CYAN.G, J.CYAN.B, 0.95))
            te:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
        end)
        local ts = container:AddChildToCanvas(te)
        if ts then ts:SetAutoSize(false) ts:SetPosition(V2(8, 6)) ts:SetSize(V2(pw - 4, 2)) ts:SetZOrder(2) end
    end
    RobotBadge(container, 10, 11, 24, 100)
    Label(container, 42, 6 + ph/2, "NIVO CHEATS", 11, J.CYAN_HI, 110)

    local btn = CGame:NewObjectFromPath("/Script/UMG.Button", container)
    local btnOk = false
    if btn then
        pcall(function()
            btn:SetBackgroundColor(MakeColor(0,0,0,0.001))
            btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
        end)
        local bs = container:AddChildToCanvas(btn)
        if bs then bs:SetAutoSize(false) bs:SetPosition(V2(6, 6)) bs:SetSize(V2(pw, ph)) bs:SetZOrder(115) btnOk = true end
        pcall(function() btn.OnPressed:Add(function()
            CounterLog("BTN down")
            local mx, my = GetMousePos()
            if mx ~= 0 or my ~= 0 then
                DragState.StartMouseX = mx
                DragState.StartMouseY = my
            end
            DragState.HasMoved = false
            DragState.Active = true
            StartDragTimer()
        end) end)
        pcall(function() btn.OnReleased:Add(function()
            CounterLog("BTN up moved=" .. tostring(DragState.HasMoved) .. " boot=" .. tostring(_G.FIXX2_BOOTN))
            local wasMoved = DragState.HasMoved
            DragState.Active = false
            CounterLog("BTN up step1")
            pcall(StopDragTimer)
            CounterLog("BTN up step2 wasMoved=" .. tostring(wasMoved))
            if not wasMoved then
                CounterLog("BTN up calling-open")
                local f = FloatingMenu and FloatingMenu.OpenPanel or nil
                CounterLog("BTN up fn=" .. tostring(f))
                if f then
                    local ok2, err2 = pcall(function() return FloatingMenu.OpenPanel() end)
                    CounterLog("BTN up open-ret ok=" .. tostring(ok2) .. (ok2 and "" or (" err=" .. tostring(err2):sub(1, 200))))
                else
                    CounterLog("BTN up NO-OPEN-FN")
                end
            end
        end) end)
    end
    if not btnOk then
        CounterLog("MENU btn-nobtn")
        pcall(function() container:RemoveFromParent() end)
        FloatingMenu.ToggleContainer = nil
        DragState.Slot = nil
        return false
    end
    CounterLog("MENU btn ok")
    return true
end

function FloatingMenu.Init()
    if FloatingMenu.Initialized then return true end
    local canvas = FloatingMenu.TryGetCanvas()
    if not canvas then return false end
    FloatingMenu.RootCanvas = canvas
    pcall(function()
        CounterLog("MENU init ok")
    end)
    if FloatingMenu.CreateToggleButton() then
        FloatingMenu.Initialized = true
        return true
    end
    return false
end

_G._MenuBootClock = os.clock()
pcall(function() math.randomseed(os.time()) end)
_G.FloatingMenu = FloatingMenu
_G.OpenModMenu = function() FloatingMenu.OpenPanel() end

local DravixBoot = { tries = 0, handle = nil, owner = nil }
local function DravixBootStop()
    if DravixBoot.handle then
        if DravixBoot.owner and DravixBoot.owner ~= "ticker" then
            pcall(function() DravixBoot.owner:RemoveGameTimer(DravixBoot.handle) end)
        elseif time_ticker and time_ticker.RemoveTimer then
            pcall(time_ticker.RemoveTimer, DravixBoot.handle)
        end
        DravixBoot.handle = nil
    end
    _G._DRAVIX_BOOT_ON = nil
end
local function DravixBootTick()
    DravixBoot.tries = DravixBoot.tries + 1
    pcall(function()
        local FM = _G.FloatingMenu
        if FM and not FM.Initialized and FM.Init() then
            CounterLog("MENU dravix ready")
        end
    end)
    local done = false
    pcall(function()
        local FM = _G.FloatingMenu
        if FM and FM.Initialized then done = true end
    end)
    if done or DravixBoot.tries >= 30 then DravixBootStop() end
end
local function StartDravixBoot()
    if _G._DRAVIX_BOOT_ON then return true end
    local ok, h = pcall(function() return time_ticker.AddTimerLoop(2, DravixBootTick, (time_ticker.TIMER_INFINITE or -1), 0) end)
    if ok and h then DravixBoot.handle = h; DravixBoot.owner = "ticker"; _G._DRAVIX_BOOT_ON = true; return true end
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        local ok2, h2 = pcall(function() return pc:AddGameTimer(2, true, DravixBootTick) end)
        if ok2 and h2 then DravixBoot.handle = h2; DravixBoot.owner = pc; _G._DRAVIX_BOOT_ON = true; return true end
    end
    pcall(DravixBootTick)
    return false
end
_G.StartDravixBoot = StartDravixBoot

-- (menu boots below)
end

-- Reload guard: purana menu destroy karke rebuild (duplicate button/panel nahi)
pcall(function()
    if _G._DRAVIX_PORT_BUILT and _G.FloatingMenu then
        pcall(function() _G.FloatingMenu.DestroyRoot() end)
        pcall(function() _G.FloatingMenu.DestroyToggle() end)
        pcall(function() _G.FloatingMenu.DestroyToast() end)
    end
end)
BuildDravixMenu()
_G._DRAVIX_PORT_BUILT = true
StartDravixBoot()

-- ============================================================
-- AUTO-START
-- ============================================================
pcall(function()
    StartTimer()
end)

-- ForceTPP resume (pichhle match me ON tha to)
pcall(function()
    if _G.Mod_ForceTPP_Enabled then StartForceTPP() end
end)

-- (DRAVIX menu self-boots via StartDravixBoot inside ported block)

_G.ESPStart = StartTimer
_G.ESPStop = StopTimer
_G.ESPTick = MainTick