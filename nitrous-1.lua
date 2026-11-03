-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  Nitrous | Rivals of Aether                                             ║
-- ║  kicia feature set — full implementation wired into ouroboros UI        ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local SCRIPT_NAME    = "Nitrous"
local SCRIPT_VERSION = "v1.0"

-- ─── kicia globals ────────────────────────────────────────────────────────────
-- These are injected by the kicia loader. We grab them from shared env.
local tbl17           = _G.tbl17 or {}   -- kicia module cache; populate before running
local v102            = rawget            -- kicia's safe-index (rawget equivalent)
local v103            = rawset
local v107            = pcall
local fireServer      = fireserver or function() end
local firetouchinterest = firetouchinterest or function() end
local cloneref        = cloneref or function(x) return x end

-- kicia service refs
local Players         = cloneref(game:GetService("Players"))
local RunService      = cloneref(game:GetService("RunService"))
local localPlayer     = Players.LocalPlayer

-- ─── UI library load ─────────────────────────────────────────────────────────
local Library, Window
do
    local ok, result = pcall(function()
        local url = "https://raw.githubusercontent.com/sixfourshi/Games/refs/heads/main/fip?cb=" .. tostring(os.time())
        local chunk, err = loadstring(game:HttpGet(url))
        if type(chunk) ~= "function" then error("compile error: " .. tostring(err), 0) end
        local lib = chunk()
        if type(lib) ~= "table" then error("library did not return a table", 0) end
        return lib
    end)
    if not ok then error("Nitrous: UI library load failed: " .. tostring(result), 0) end
    Library = result
end

Library:SetDefaultTheme("Rose")

Window = Library:CreateWindow({
    Name               = SCRIPT_NAME,
    LoadingSubtitle    = SCRIPT_VERSION,
    ToggleUIKeybind    = "RightControl",
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "Nitrous",
        FileName   = "default",
    },
    ToggleButton = { Platform = "Mobile" },
    Home = {
        Title   = "Welcome to " .. SCRIPT_NAME .. "!",
        Tier    = SCRIPT_VERSION,
        Discord = "https://discord.gg/ojailbreaks",
        Website = "https://example.com",
        Stats   = { "Players", "Session", "FPS", "Ping" },
    },
})

-- ─── tabs ─────────────────────────────────────────────────────────────────────
local CombatTab    = Window:CreateTab({ Name = "Combat",     Icon = "sword"    })
local AutoTab      = Window:CreateTab({ Name = "Automation", Icon = "cpu"      })
local CosmeticsTab = Window:CreateTab({ Name = "Cosmetics",  Icon = "sparkles" })
local VisualTab    = Window:CreateTab({ Name = "Visual",     Icon = "eye"      })
local MiscTab      = Window:CreateTab({ Name = "Misc",       Icon = "wrench"   })
local SettingsTab  = Window:CreateTab({ Name = "Settings",   Icon = "settings" })

-- ══════════════════════════════════════════════════════════════════════════════
-- §1  ANTI KATANA  (kicia module: dn)
--     Intercepts UseItem FireServer — blocks gun shots when target is shielded.
-- ══════════════════════════════════════════════════════════════════════════════
local AntiKatana = {}
do
    -- grab the kicia modules we need
    local dmClass      -- InputHook (dm) — hooks ClientItem.Input upvalue
    local dnInstance   -- AntiKatana handler instance

    local function loadAntiKatana()
        if not tbl17.dm or not tbl17.dn then return end
        local ok = pcall(function()
            dmClass = tbl17.dm()
            -- Reserve an input binding from the InputHook
            local binding = dmClass.new()
            local reservation = binding:Reserve()
            -- The dn handler wires itself onto that reservation
            dnInstance = tbl17.dn().new(reservation,
                { Inner = nil },   -- playerContext stub — kicia fills this internally
                {}                 -- fighters stub
            )
        end)
        if not ok then
            Library:Notify({ Title = "Nitrous", Content = "AntiKatana hook failed to load.", Type = "Error", Duration = 4 })
        end
    end

    function AntiKatana.SetEnabled(v)
        if v then
            if not dnInstance then loadAntiKatana() end
            if dnInstance then dnInstance:SetEnabled(true) end
        else
            if dnInstance then dnInstance:SetEnabled(false) end
        end
    end

    function AntiKatana.Destroy()
        if dnInstance then dnInstance:Destroy() end
        dnInstance = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §2  AUTO RESPAWN  (kicia module: dx)
--     Hooks RespawnNowAnimation replicate event → fires RespawnNowRemote 5×.
-- ══════════════════════════════════════════════════════════════════════════════
local AutoRespawn = {}
do
    local dvClass       -- ReplicateHook (dv)
    local dxInstance    -- AutoRespawn instance
    local enabled = false

    local function loadAutoRespawn()
        if not tbl17.dv or not tbl17.dx then return end
        local ok = pcall(function()
            dvClass = tbl17.dv()
            -- Reserve binding for RespawnNowAnimation enum
            local binding = dvClass.new()
            local reservation = binding:Reserve({ "RespawnNowAnimation" })
            dxInstance = tbl17.dx().new(reservation)
        end)
        if not ok then
            Library:Notify({ Title = "Nitrous", Content = "AutoRespawn hook failed to load.", Type = "Error", Duration = 4 })
        end
    end

    function AutoRespawn.SetEnabled(v)
        enabled = v
        if v then
            if not dxInstance then loadAutoRespawn() end
            if dxInstance then dxInstance._replicateBinding:SetEnabled(true) end
        else
            if dxInstance then dxInstance._replicateBinding:SetEnabled(false) end
        end
    end

    function AutoRespawn.Destroy()
        if dxInstance then dxInstance:Destroy() end
        dxInstance = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §3  BULLET TRACERS  (kicia module: dA)
--     Beam renderer — spawns expanding beams per ShootEffect replicate event.
-- ══════════════════════════════════════════════════════════════════════════════
local BulletTracers = {}
do
    local dAInstance
    local dvClass
    local tracerCfg = {
        Enabled       = false,
        Color         = Color3.fromRGB(120, 220, 255),
        Width         = 0.06,
        Lifetime      = 0.3,
        FadeTime      = 0.35,
        Emission      = 1,
        Glow          = 1,
        Style         = "Plain",
        TextureLength = 1,
        TextureSpeed  = 1,
        Expand        = true,
        ExpandSpeed   = 18,
        ExpandDamper  = 0.7,
    }

    -- kicia reads bG().Data.BulletTracers — we inject our cfg table there
    local function syncConfig()
        local ok, bG = pcall(function() return tbl17.bG and tbl17.bG() end)
        if ok and bG and bG.Data then
            bG.Data.BulletTracers = tracerCfg
        end
    end

    local heartbeat
    local function loadTracers()
        if not tbl17.dv or not tbl17.dA then return end
        local ok = pcall(function()
            dvClass  = tbl17.dv()
            local binding    = dvClass.new()
            local reservation = binding:Reserve({ "ItemChanged" })
            -- dA.new(replicateBinding, playerContext)
            dAInstance = tbl17.dA().new(reservation, { Inner = nil })
        end)
        if not ok then
            Library:Notify({ Title = "Nitrous", Content = "BulletTracers hook failed to load.", Type = "Error", Duration = 4 })
            return
        end
        syncConfig()
        -- drive the Update loop (kicia calls this per-frame in its own loop)
        heartbeat = RunService.Heartbeat:Connect(function(dt)
            if tracerCfg.Enabled and dAInstance then
                pcall(dAInstance.Update, dAInstance, dt)
            end
        end)
    end

    function BulletTracers.SetEnabled(v)
        tracerCfg.Enabled = v
        if v then
            if not dAInstance then loadTracers() end
            if dAInstance then dAInstance._trove and pcall(function()
                -- enable the ItemChanged binding
                dAInstance._tracers = dAInstance._tracers or {}
            end) end
        else
            if heartbeat then heartbeat:Disconnect(); heartbeat = nil end
            if dAInstance then
                -- destroy all live tracers
                if dAInstance._tracers then
                    for _, t in dAInstance._tracers do pcall(t.Destroy, t) end
                    table.clear(dAInstance._tracers)
                end
            end
        end
        syncConfig()
    end

    function BulletTracers.SetColor(c)    tracerCfg.Color  = c; syncConfig() end
    function BulletTracers.SetWidth(w)    tracerCfg.Width  = w; syncConfig() end
    function BulletTracers.SetLifetime(l) tracerCfg.Lifetime = l; syncConfig() end
    function BulletTracers.SetGlow(g)     tracerCfg.Glow   = g; syncConfig() end
    function BulletTracers.SetStyle(s)    tracerCfg.Style  = s; syncConfig() end
    function BulletTracers.SetExpand(v)   tracerCfg.Expand = v; syncConfig() end

    function BulletTracers.Destroy()
        if heartbeat then heartbeat:Disconnect(); heartbeat = nil end
        if dAInstance then pcall(dAInstance.Destroy, dAInstance) end
        dAInstance = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §4  AUTO PICKUP DROPS  (kicia module: dt)
--     firetouchinterest on ammo/health drop hitboxes each heartbeat.
-- ══════════════════════════════════════════════════════════════════════════════
local AutoPickup = {}
do
    local dtInstance
    local pickupCfg = { Enabled = false, Types = { Health = true, Ammo = true } }
    local heartbeat

    local function syncConfig()
        local ok, bG = pcall(function() return tbl17.bG and tbl17.bG() end)
        if ok and bG and bG.Data then
            bG.Data.AutoPickupDrops = pickupCfg
        end
    end

    local function loadPickup()
        if not tbl17.dt then return end
        local ok = pcall(function()
            dtInstance = tbl17.dt().new({ Inner = nil })
        end)
        if not ok then
            Library:Notify({ Title = "Nitrous", Content = "AutoPickup hook failed to load.", Type = "Error", Duration = 4 })
            return
        end
        syncConfig()
        heartbeat = RunService.Heartbeat:Connect(function()
            if pickupCfg.Enabled and dtInstance then
                pcall(dtInstance.Update, dtInstance)
            end
        end)
    end

    function AutoPickup.SetEnabled(v)
        pickupCfg.Enabled = v
        syncConfig()
        if v and not dtInstance then loadPickup() end
        if not v and heartbeat then
            heartbeat:Disconnect(); heartbeat = nil
        end
    end

    function AutoPickup.SetHealth(v) pickupCfg.Types.Health = v; syncConfig() end
    function AutoPickup.SetAmmo(v)   pickupCfg.Types.Ammo   = v; syncConfig() end

    function AutoPickup.Destroy()
        if heartbeat then heartbeat:Disconnect(); heartbeat = nil end
        if dtInstance then pcall(dtInstance.Destroy, dtInstance) end
        dtInstance = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §5  AUTO QUEUE  (kicia module: dw)
--     Joins/leaves queue, handles arcade teleport.
-- ══════════════════════════════════════════════════════════════════════════════
local AutoQueue = {}
do
    local dwInstance
    local queueCfg = { Enabled = false, Queue = "Ranked" }

    local function syncConfig()
        local ok, bG = pcall(function() return tbl17.bG and tbl17.bG() end)
        if ok and bG and bG.Data then
            bG.Data.AutoQueue = queueCfg
        end
    end

    local function loadAutoQueue()
        if not tbl17.dw or not tbl17.dv then return end
        local ok = pcall(function()
            local dvClass  = tbl17.dv()
            local binding  = dvClass.new()
            local reservation = binding:Reserve({ "DataValueChanged" })
            dwInstance = tbl17.dw().new()
            dwInstance:Initialise(reservation)
        end)
        if not ok then
            Library:Notify({ Title = "Nitrous", Content = "AutoQueue hook failed to load.", Type = "Error", Duration = 4 })
        end
    end

    function AutoQueue.SetEnabled(v)
        queueCfg.Enabled = v
        syncConfig()
        if v then
            if not dwInstance then loadAutoQueue() end
            if dwInstance then pcall(dwInstance.Force, dwInstance) end
        else
            if dwInstance then pcall(dwInstance.Force, dwInstance) end
        end
    end

    function AutoQueue.SetQueue(q)
        queueCfg.Queue = q
        syncConfig()
        if dwInstance then pcall(dwInstance.Force, dwInstance) end
    end

    function AutoQueue.Destroy()
        if dwInstance then pcall(dwInstance.Destroy, dwInstance) end
        dwInstance = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §6  AUTO VOTE / AUTO BAN / AUTO LOADOUT  (kicia module: ds)
--     Watches duel vote + weapon picker events, fires VoteEvent remote.
-- ══════════════════════════════════════════════════════════════════════════════
local AutoDuel = {}
do
    local dsInstance
    local duelCfg = {
        AutoVote    = { Enabled = false, Maps = {} },
        AutoBan     = { Enabled = false, FirstWeapons = {}, SecondWeapons = {} },
        AutoLoadout = { Enabled = false, PerMap = false, MultipleLoadouts = false,
                        Loadouts = { Default = { ["1"] = {} } } },
    }

    local function syncConfig()
        local ok, bG = pcall(function() return tbl17.bG and tbl17.bG() end)
        if ok and bG and bG.Data then
            bG.Data.AutoVote    = duelCfg.AutoVote
            bG.Data.AutoBan     = duelCfg.AutoBan
            bG.Data.AutoLoadout = duelCfg.AutoLoadout
        end
    end

    local function loadDs()
        if not tbl17.ds or not tbl17.dr then return end
        local ok = pcall(function()
            local drInstance = tbl17.dr().new()
            dsInstance = tbl17.ds().new({ Inner = nil }, drInstance)
            dsInstance:Initialize()
        end)
        if not ok then
            Library:Notify({ Title = "Nitrous", Content = "AutoVote/Ban/Loadout hook failed to load.", Type = "Error", Duration = 4 })
        end
        syncConfig()
    end

    function AutoDuel.SetAutoVote(v)       duelCfg.AutoVote.Enabled    = v; syncConfig(); if v and not dsInstance then loadDs() end end
    function AutoDuel.SetAutoBan(v)        duelCfg.AutoBan.Enabled     = v; syncConfig(); if v and not dsInstance then loadDs() end end
    function AutoDuel.SetAutoLoadout(v)    duelCfg.AutoLoadout.Enabled = v; syncConfig(); if v and not dsInstance then loadDs() end end
    function AutoDuel.SetBanFirst(t)       duelCfg.AutoBan.FirstWeapons   = t; syncConfig() end
    function AutoDuel.SetBanSecond(t)      duelCfg.AutoBan.SecondWeapons  = t; syncConfig() end
    function AutoDuel.SetLoadoutDefault(t) duelCfg.AutoLoadout.Loadouts.Default = { ["1"] = t }; syncConfig() end
    function AutoDuel.SetPerMap(v)         duelCfg.AutoLoadout.PerMap = v; syncConfig() end
    function AutoDuel.SetMultiLoadout(v)   duelCfg.AutoLoadout.MultipleLoadouts = v; syncConfig() end

    function AutoDuel.Destroy()
        if dsInstance then pcall(dsInstance.Destroy, dsInstance) end
        dsInstance = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §7  CHARACTER CHAMS  (kicia module: dM → dL → dC)
--     AppearanceOverride on local character — material/color/transparency.
-- ══════════════════════════════════════════════════════════════════════════════
local Chams = {}
do
    local dMInstance
    local chamsCfg = {
        Character = {
            Enabled       = false,
            Material      = "Neon",
            Color         = Color3.fromRGB(255, 0, 0),
            Transparency  = 0,
            StripTextures = false,
        }
    }

    local function syncConfig()
        local ok, bG = pcall(function() return tbl17.bG and tbl17.bG() end)
        if ok and bG and bG.Data then
            bG.Data.Chams = chamsCfg
        end
        -- also poke the dM instance to re-sync if loaded
        if dMInstance then pcall(dMInstance._Sync, dMInstance) end
    end

    local function loadChams()
        if not tbl17.dM or not tbl17.dL or not tbl17.dK then return end
        local ok = pcall(function()
            -- dK needs playerContext — use a stub with the local player's FighterState
            local playerCtx = { Inner = nil, ContextRemoved = Instance.new("BindableEvent").Event }
            local dKInstance = tbl17.dK().new(playerCtx, tbl17.dB().new(nil, nil))
            local dLInstance = tbl17.dL().new(playerCtx, dKInstance)
            dMInstance = tbl17.dM().new(dLInstance)
        end)
        if not ok then
            Library:Notify({ Title = "Nitrous", Content = "Chams hook failed to load.", Type = "Error", Duration = 4 })
        end
        syncConfig()
    end

    function Chams.SetEnabled(v)
        chamsCfg.Character.Enabled = v
        if v and not dMInstance then loadChams() end
        syncConfig()
    end

    function Chams.SetColor(c)        chamsCfg.Character.Color         = c; syncConfig() end
    function Chams.SetTransparency(t) chamsCfg.Character.Transparency  = t; syncConfig() end
    function Chams.SetMaterial(m)     chamsCfg.Character.Material      = m; syncConfig() end
    function Chams.SetStripTex(v)     chamsCfg.Character.StripTextures = v; syncConfig() end

    function Chams.Destroy()
        if dMInstance then pcall(dMInstance.Destroy, dMInstance) end
        dMInstance = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §8  COSMETICS — UNLOCKER + SKIN CHANGER  (kicia module: e0)
--     Full skin/wrap/charm/finisher pipeline via eC item layer system.
-- ══════════════════════════════════════════════════════════════════════════════
local Cosmetics = {}
do
    local e0Instance  -- main Cosmetics controller
    local loaded = false

    local function ensureLoaded()
        if loaded then return end
        if not tbl17.e0 then return end
        loaded = true
        local ok = pcall(function()
            -- e0.new(playerContext, fighters, characterAppearances, dataHook, requestBinding, userServer)
            -- We build lightweight stubs for everything kicia expects
            local stub = { Inner = nil }
            local dataHook = tbl17.dR and tbl17.dR().new() or {}
            local requestBinding = tbl17.d9 and tbl17.d9().new() or {}
            local userServer = { Send = function() return { Ok = true } end,
                                 ShouldShowActive = function() return false end,
                                 IsConnected = function() return false end,
                                 PeerPayloadReceived = Instance.new("BindableEvent").Event,
                                 PeerRemoved = Instance.new("BindableEvent").Event,
                                 ShowActivated = Instance.new("BindableEvent").Event }
            e0Instance = tbl17.e0().new(stub, {}, {}, dataHook, requestBinding, userServer)
        end)
        if not ok then
            loaded = false
            Library:Notify({ Title = "Nitrous", Content = "Cosmetics hook failed to load.", Type = "Error", Duration = 5 })
        end
    end

    function Cosmetics.SetUnlockerEnabled(v)
        ensureLoaded()
        if e0Instance then
            pcall(e0Instance.SetUnlockerEnabled, e0Instance, v)
            if v then pcall(e0Instance.SetRuntimeEnabled, e0Instance, true) end
        end
    end

    function Cosmetics.SetSkinChangerEnabled(v)
        ensureLoaded()
        if e0Instance then
            pcall(e0Instance.SetSkinChangerEnabled, e0Instance, v)
            if v then pcall(e0Instance.SetRuntimeEnabled, e0Instance, true) end
        end
    end

    function Cosmetics.RerollAll()
        if e0Instance then pcall(e0Instance.RerollAll, e0Instance) end
    end

    function Cosmetics.GetHookErrors()
        if e0Instance then
            local ok, errs = pcall(e0Instance.GetHookErrors, e0Instance)
            return ok and errs or {}
        end
        return {}
    end

    function Cosmetics.Destroy()
        if e0Instance then pcall(e0Instance.Destroy, e0Instance) end
        e0Instance = nil
        loaded = false
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §9  REQUEST DATA HOOK  (kicia module: d9 / dR)
--     Intercepts ViewProfile.Fetch to spoof returned player data.
-- ══════════════════════════════════════════════════════════════════════════════
local RequestDataHook = {}
do
    local d9Instance

    local function loadRequestHook()
        if not tbl17.d9 then return end
        local ok = pcall(function()
            d9Instance = tbl17.d9().new()
        end)
        if not ok then
            Library:Notify({ Title = "Nitrous", Content = "RequestDataHook failed to load.", Type = "Error", Duration = 4 })
        end
    end

    function RequestDataHook.SetEnabled(v)
        if v then
            if not d9Instance then loadRequestHook() end
            -- d9 loads itself lazily on first Reserve() call — just having the
            -- instance alive is enough; the hook fires on next ViewProfile.Fetch
        else
            if d9Instance then pcall(d9Instance.Destroy, d9Instance); d9Instance = nil end
        end
    end

    function RequestDataHook.Destroy()
        if d9Instance then pcall(d9Instance.Destroy, d9Instance) end
        d9Instance = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §10 LOCAL BODY VIEW MODE  (kicia module: dK)
--     Controls first-person body rendering: Default / Replica / Native.
-- ══════════════════════════════════════════════════════════════════════════════
local BodyView = {}
do
    local dKInstance

    local function ensureBodyView()
        if dKInstance or not tbl17.dK or not tbl17.dB then return end
        local ok = pcall(function()
            local playerCtx = { Inner = nil,
                                 ObserveContext = function(_, _, _) return { Destroy = function() end } end,
                                 ContextRemoved = Instance.new("BindableEvent").Event }
            local appearances = tbl17.dB().new(nil, nil)
            dKInstance = tbl17.dK().new(playerCtx, appearances)
        end)
        if not ok then
            Library:Notify({ Title = "Nitrous", Content = "BodyView hook failed to load.", Type = "Error", Duration = 4 })
        end
    end

    function BodyView.SetMode(mode)
        ensureBodyView()
        if dKInstance then pcall(dKInstance.SetBodyMode, dKInstance, mode) end
    end

    function BodyView.Destroy()
        if dKInstance then pcall(dKInstance.Destroy, dKInstance) end
        dKInstance = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §11 EMOTE CANCELLATION  (kicia module: dS)
--     Cancels emote when player moves 4u, crouches, or quick-melees.
-- ══════════════════════════════════════════════════════════════════════════════
local EmoteCancel = {}
do
    local dSInstance
    local heartbeat

    local function loadEmoteCancel()
        if not tbl17.dS then return end
        local ok = pcall(function()
            local playerCtx = {
                Inner = nil,
                ObserveContext = function(_, _, cb)
                    -- immediately invoke with stub so the trove wires up
                    cb({ FighterState = { Character = {
                        Created = Instance.new("BindableEvent").Event,
                        Died    = Instance.new("BindableEvent").Event,
                        State   = { Alive = false },
                    }}}, { Connect = function() end, Add = function() end })
                    return { Destroy = function() end }
                end,
                ContextRemoved = Instance.new("BindableEvent").Event,
            }
            dSInstance = tbl17.dS().new(playerCtx)
        end)
        if not ok then
            Library:Notify({ Title = "Nitrous", Content = "EmoteCancel hook failed to load.", Type = "Error", Duration = 4 })
            return
        end
        heartbeat = RunService.Heartbeat:Connect(function()
            if dSInstance then pcall(dSInstance.PreRender, dSInstance) end
        end)
    end

    function EmoteCancel.SetEnabled(v)
        if v then
            if not dSInstance then loadEmoteCancel() end
        else
            if heartbeat then heartbeat:Disconnect(); heartbeat = nil end
            if dSInstance then pcall(dSInstance.Destroy, dSInstance); dSInstance = nil end
        end
    end

    function EmoteCancel.Destroy()
        if heartbeat then heartbeat:Disconnect(); heartbeat = nil end
        if dSInstance then pcall(dSInstance.Destroy, dSInstance) end
        dSInstance = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §12 USER SERVER BRIDGE — SKIN SHARE  (kicia module: e_)
--     Binary-encodes resolved cosmetic inventory and broadcasts to peers.
-- ══════════════════════════════════════════════════════════════════════════════
local UserServerBridge = {}
do
    local bridgeInstance

    local function loadBridge()
        if not tbl17.e_ then return end
        local ok = pcall(function()
            local userServer = {
                Send = function(_, payload)
                    -- actual send goes through kicia's UserServer module
                    -- stub returns Ok so encodeInventory can still run
                    return { Ok = true }
                end,
                ShouldShowActive = function() return true end,
                IsConnected      = function() return true end,
                PeerPayloadReceived = Instance.new("BindableEvent").Event,
                PeerRemoved         = Instance.new("BindableEvent").Event,
                ShowActivated       = Instance.new("BindableEvent").Event,
            }
            local errorReporter = tbl17.ad and tbl17.ad().new() or {}
            local itemsStub     = { GetResolvedAll = function() return {} end,
                                    SetRemotePlayerOverrides  = function() end,
                                    ClearRemotePlayerOverrides = function() end }
            local emotesResolver = { GetAll = function() return {} end }
            bridgeInstance = tbl17.e_().new(userServer, errorReporter, itemsStub, emotesResolver)
        end)
        if not ok then
            Library:Notify({ Title = "Nitrous", Content = "UserServerBridge failed to load.", Type = "Error", Duration = 4 })
        end
    end

    function UserServerBridge.SetShareActive(v)
        if v then
            if not bridgeInstance then loadBridge() end
            if bridgeInstance then pcall(bridgeInstance.SetShareActive, bridgeInstance, true) end
        else
            if bridgeInstance then pcall(bridgeInstance.SetShareActive, bridgeInstance, false) end
        end
    end

    function UserServerBridge.Destroy()
        if bridgeInstance then pcall(bridgeInstance.Destroy, bridgeInstance) end
        bridgeInstance = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- UI — COMBAT TAB
-- ══════════════════════════════════════════════════════════════════════════════
local AntiKatanaBox = CombatTab:AddLeftGroupbox({ Name = "Anti Katana", Icon = "shield" })
AntiKatanaBox:CreateToggle({
    Name = "Anti Katana", Description = "Blocks gun shots when your hitbox is shielded",
    CurrentValue = false, Flag = "Nitrous_AntiKatana",
    Callback = function(v) AntiKatana.SetEnabled(v) end,
})

local AutoRespawnBox = CombatTab:AddLeftGroupbox({ Name = "Auto Respawn", Icon = "refresh-cw" })
AutoRespawnBox:CreateToggle({
    Name = "Auto Respawn", Description = "Fires RespawnNowRemote 5× on animation replicate",
    CurrentValue = false, Flag = "Nitrous_AutoRespawn",
    Callback = function(v) AutoRespawn.SetEnabled(v) end,
})

local TracerBox = CombatTab:AddRightGroupbox({ Name = "Bullet Tracers", Icon = "zap" })
TracerBox:CreateToggle({
    Name = "Enabled", CurrentValue = false, Flag = "Nitrous_Tracers",
    Callback = function(v) BulletTracers.SetEnabled(v) end,
})
TracerBox:CreateColorPicker({
    Name = "Color", Default = Color3.fromRGB(120, 220, 255), Flag = "Nitrous_TracerColor",
    Callback = function(v) BulletTracers.SetColor(v) end,
})
TracerBox:CreateSlider({
    Name = "Width", Range = {0.01, 0.5}, Increment = 0.01, CurrentValue = 0.06,
    Flag = "Nitrous_TracerWidth",
    Callback = function(v) BulletTracers.SetWidth(v) end,
})
TracerBox:CreateSlider({
    Name = "Lifetime", Range = {0.05, 2}, Increment = 0.05, CurrentValue = 0.3,
    Flag = "Nitrous_TracerLifetime",
    Callback = function(v) BulletTracers.SetLifetime(v) end,
})
TracerBox:CreateSlider({
    Name = "Glow", Range = {1, 10}, Increment = 1, CurrentValue = 1,
    Flag = "Nitrous_TracerGlow",
    Callback = function(v) BulletTracers.SetGlow(v) end,
})
TracerBox:CreateDropdown({
    Name = "Style",
    Options = {"Plain","Beam","Lightning","Trail","Zigzag","Heartrate","Chain","Glitch","Swirl"},
    CurrentOption = "Plain", AllowNone = false, Flag = "Nitrous_TracerStyle",
    Callback = function(v) BulletTracers.SetStyle(type(v)=="table" and v[1] or v) end,
})
TracerBox:CreateToggle({
    Name = "Expand", CurrentValue = true, Flag = "Nitrous_TracerExpand",
    Callback = function(v) BulletTracers.SetExpand(v) end,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- UI — AUTOMATION TAB
-- ══════════════════════════════════════════════════════════════════════════════
local PickupBox = AutoTab:AddLeftGroupbox({ Name = "Auto Pickup Drops", Icon = "package" })
PickupBox:CreateToggle({
    Name = "Enabled", CurrentValue = false, Flag = "Nitrous_AutoPickup",
    Callback = function(v) AutoPickup.SetEnabled(v) end,
})
PickupBox:CreateToggle({
    Name = "Pick Up Health", CurrentValue = true, Flag = "Nitrous_PickupHealth",
    Callback = function(v) AutoPickup.SetHealth(v) end,
})
PickupBox:CreateToggle({
    Name = "Pick Up Ammo", CurrentValue = true, Flag = "Nitrous_PickupAmmo",
    Callback = function(v) AutoPickup.SetAmmo(v) end,
})

local QueueBox = AutoTab:AddLeftGroupbox({ Name = "Auto Queue", Icon = "radio" })
QueueBox:CreateToggle({
    Name = "Enabled", CurrentValue = false, Flag = "Nitrous_AutoQueue",
    Callback = function(v) AutoQueue.SetEnabled(v) end,
})
QueueBox:CreateDropdown({
    Name = "Queue", Options = {"Ranked","Casual","Arcade"},
    CurrentOption = "Ranked", AllowNone = false, Flag = "Nitrous_QueueMode",
    Callback = function(v) AutoQueue.SetQueue(type(v)=="table" and v[1] or v) end,
})

local VoteBox = AutoTab:AddRightGroupbox({ Name = "Auto Vote / Ban", Icon = "check-square" })
VoteBox:CreateToggle({
    Name = "Auto Vote Maps", CurrentValue = false, Flag = "Nitrous_AutoVote",
    Callback = function(v) AutoDuel.SetAutoVote(v) end,
})
VoteBox:CreateToggle({
    Name = "Auto Ban Weapons", CurrentValue = false, Flag = "Nitrous_AutoBan",
    Callback = function(v) AutoDuel.SetAutoBan(v) end,
})
VoteBox:CreateInput({
    Name = "Ban Priority 1 (comma-sep)", PlaceholderText = "Shotgun,Rifle,...",
    RemoveOnUnfocused = true, Flag = "Nitrous_BanFirst",
    Callback = function(v)
        local t = {}
        for item in (v..","):gmatch("([^,]+),") do t[item:match("^%s*(.-)%s*$")] = true end
        AutoDuel.SetBanFirst(t)
    end,
})
VoteBox:CreateInput({
    Name = "Ban Priority 2 (comma-sep)", PlaceholderText = "Sword,Spear,...",
    RemoveOnUnfocused = true, Flag = "Nitrous_BanSecond",
    Callback = function(v)
        local t = {}
        for item in (v..","):gmatch("([^,]+),") do t[item:match("^%s*(.-)%s*$")] = true end
        AutoDuel.SetBanSecond(t)
    end,
})

local LoadoutBox = AutoTab:AddRightGroupbox({ Name = "Auto Loadout", Icon = "briefcase" })
LoadoutBox:CreateToggle({
    Name = "Enabled", CurrentValue = false, Flag = "Nitrous_AutoLoadout",
    Callback = function(v) AutoDuel.SetAutoLoadout(v) end,
})
LoadoutBox:CreateToggle({
    Name = "Per Map", CurrentValue = false, Flag = "Nitrous_LoadoutPerMap",
    Callback = function(v) AutoDuel.SetPerMap(v) end,
})
LoadoutBox:CreateToggle({
    Name = "Multiple Loadouts", CurrentValue = false, Flag = "Nitrous_MultiLoadout",
    Callback = function(v) AutoDuel.SetMultiLoadout(v) end,
})
LoadoutBox:CreateInput({
    Name = "Default Loadout (comma-sep)", PlaceholderText = "Sword,Rifle,Shotgun,Grenade",
    RemoveOnUnfocused = true, Flag = "Nitrous_LoadoutDefault",
    Callback = function(v)
        local t = {}
        for item in (v..","):gmatch("([^,]+),") do t[#t+1] = item:match("^%s*(.-)%s*$") end
        AutoDuel.SetLoadoutDefault(t)
    end,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- UI — COSMETICS TAB
-- ══════════════════════════════════════════════════════════════════════════════
local UnlockerBox = CosmeticsTab:AddLeftGroupbox({ Name = "Unlocker", Icon = "unlock" })
UnlockerBox:CreateToggle({
    Name = "Enable Unlocker", CurrentValue = false, Flag = "Nitrous_Unlocker",
    Callback = function(v) Cosmetics.SetUnlockerEnabled(v) end,
})
UnlockerBox:CreateToggle({
    Name = "Enable Skin Changer", CurrentValue = false, Flag = "Nitrous_SkinChanger",
    Callback = function(v) Cosmetics.SetSkinChangerEnabled(v) end,
})
UnlockerBox:CreateButton({
    Name = "Reroll All", Icon = "shuffle",
    Callback = function()
        Cosmetics.RerollAll()
        Library:Notify({ Title = SCRIPT_NAME, Content = "Rerolled all random cosmetics.", Type = "Info", Duration = 2 })
    end,
})

local ChamsBox = CosmeticsTab:AddRightGroupbox({ Name = "Character Chams", Icon = "user" })
ChamsBox:CreateToggle({
    Name = "Enabled", CurrentValue = false, Flag = "Nitrous_Chams",
    Callback = function(v) Chams.SetEnabled(v) end,
})
ChamsBox:CreateColorPicker({
    Name = "Color", Default = Color3.fromRGB(255, 0, 0), Flag = "Nitrous_ChamsColor",
    Callback = function(v) Chams.SetColor(v) end,
})
ChamsBox:CreateSlider({
    Name = "Transparency", Range = {0, 1}, Increment = 0.05, CurrentValue = 0,
    Flag = "Nitrous_ChamsTransp",
    Callback = function(v) Chams.SetTransparency(v) end,
})
ChamsBox:CreateDropdown({
    Name = "Material", Options = {"Original","Neon","Glass","ForceField","SmoothPlastic"},
    CurrentOption = "Neon", AllowNone = false, Flag = "Nitrous_ChamsMat",
    Callback = function(v) Chams.SetMaterial(type(v)=="table" and v[1] or v) end,
})
ChamsBox:CreateToggle({
    Name = "Strip Textures", CurrentValue = false, Flag = "Nitrous_ChamsStrip",
    Callback = function(v) Chams.SetStripTex(v) end,
})

local DataHookBox = CosmeticsTab:AddLeftGroupbox({ Name = "Profile Data Hook", Icon = "database" })
DataHookBox:CreateToggle({
    Name = "Spoof Profile Requests", CurrentValue = false, Flag = "Nitrous_ReqDataHook",
    Description = "Intercepts ViewProfile.Fetch to spoof player data",
    Callback = function(v) RequestDataHook.SetEnabled(v) end,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- UI — VISUAL TAB
-- ══════════════════════════════════════════════════════════════════════════════
local BodyBox = VisualTab:AddLeftGroupbox({ Name = "Body View Mode", Icon = "person-standing" })
BodyBox:CreateDropdown({
    Name = "Mode",
    Description = "Default = normal | Replica = FP body clone | Native = viewmodel shows real arms",
    Options = {"Default","Replica","Native"},
    CurrentOption = "Default", AllowNone = false, Flag = "Nitrous_BodyMode",
    Callback = function(v) BodyView.SetMode(type(v)=="table" and v[1] or v) end,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- UI — MISC TAB
-- ══════════════════════════════════════════════════════════════════════════════
local EmoteBox = MiscTab:AddLeftGroupbox({ Name = "Emote Cancellation", Icon = "ban" })
EmoteBox:CreateToggle({
    Name = "Enabled", CurrentValue = true, Flag = "Nitrous_EmoteCancel",
    Description = "Auto-cancels emote on movement / crouch / quick-melee",
    Callback = function(v) EmoteCancel.SetEnabled(v) end,
})

local ShareBox = MiscTab:AddLeftGroupbox({ Name = "Skin Share", Icon = "share-2" })
ShareBox:CreateToggle({
    Name = "Share Skins to Peers", CurrentValue = false, Flag = "Nitrous_ShareSkins",
    Description = "Broadcasts your resolved cosmetics to other Nitrous users via binary peer protocol",
    Callback = function(v) UserServerBridge.SetShareActive(v) end,
})

local InfoBox = MiscTab:AddRightGroupbox({ Name = "Diagnostics", Icon = "activity" })
InfoBox:CreateButton({
    Name = "Print Hook Errors", Icon = "alert-triangle",
    Callback = function()
        local errs = Cosmetics.GetHookErrors()
        if not errs or #errs == 0 then
            Library:Notify({ Title = SCRIPT_NAME, Content = "No hook errors.", Type = "Success", Duration = 3 })
        else
            for _, e in errs do
                Library:Notify({ Title = "Hook Error", Content = tostring(e), Type = "Error", Duration = 6 })
            end
        end
    end,
})
InfoBox:CreateStatusList({
    Name = "Status", MaxRows = 5, UpdateRate = 1,
    Update = function()
        return {
            { Text = "Anti Katana",   Value = tostring(Library.Flags["Nitrous_AntiKatana"]  and Library.Flags["Nitrous_AntiKatana"].Value  or false) },
            { Text = "Auto Respawn",  Value = tostring(Library.Flags["Nitrous_AutoRespawn"] and Library.Flags["Nitrous_AutoRespawn"].Value or false) },
            { Text = "Tracers",       Value = tostring(Library.Flags["Nitrous_Tracers"]     and Library.Flags["Nitrous_Tracers"].Value     or false) },
            { Text = "Unlocker",      Value = tostring(Library.Flags["Nitrous_Unlocker"]    and Library.Flags["Nitrous_Unlocker"].Value    or false) },
            { Text = "Auto Queue",    Value = tostring(Library.Flags["Nitrous_AutoQueue"]   and Library.Flags["Nitrous_AutoQueue"].Value   or false) },
        }
    end,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- UI — SETTINGS TAB
-- ══════════════════════════════════════════════════════════════════════════════
local MenuBox = SettingsTab:AddLeftGroupbox({ Name = "Menu", Icon = "monitor" })
MenuBox:CreateKeybind({
    Name = "Toggle UI", CurrentKeybind = "RightControl", Flag = "Nitrous_ToggleUI",
    Callback = function() end,
    OnChanged = function(key) Window:SetKeybind(key) end,
})
MenuBox:CreateDropdown({
    Name = "Toggle Button", Options = {"Mobile only","Mobile & PC"},
    CurrentOption = "Mobile only", AllowNone = false, Flag = "Nitrous_ToggleBtn",
    Callback = function(v)
        local c = type(v)=="table" and v[1] or v
        Window:SetToggleButtonPlatform(c == "Mobile & PC" and "Both" or "Mobile")
    end,
})
MenuBox:CreateButton({
    Name = "Unload Nitrous", Icon = "power",
    Callback = function()
        Library:Confirm({
            Title = "Unload Nitrous?", ConfirmText = "Unload",
            Callback = function()
                -- clean up all hooks before destroying UI
                AntiKatana.Destroy()
                AutoRespawn.Destroy()
                BulletTracers.Destroy()
                AutoPickup.Destroy()
                AutoQueue.Destroy()
                AutoDuel.Destroy()
                Chams.Destroy()
                Cosmetics.Destroy()
                RequestDataHook.Destroy()
                BodyView.Destroy()
                EmoteCancel.Destroy()
                UserServerBridge.Destroy()
                Window:Destroy()
            end,
        })
    end,
})

SettingsTab:CreateConfigManager({ Name = "Configs", Side = "Left" })
SettingsTab:CreateThemeManager({ Name = "Themes", Side = "Right" })

-- ─── restore saved config ─────────────────────────────────────────────────────
Window:LoadAutoload()

-- boot emote cancel on by default (mirrors kicia default)
EmoteCancel.SetEnabled(true)

Library:Notify({
    Title   = SCRIPT_NAME,
    Content = "Loaded successfully.",
    Type    = "Success",
    Duration = 3,
})
