-- Nitrous | Rivals of Aether cheat
-- kicia feature set ported into ouroboros UI library
-- branding: Nitrous

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local SCRIPT_NAME    = "Nitrous"
local SCRIPT_VERSION = "v1.0"

-- ─── library load ────────────────────────────────────────────────────────────
local Library, Window
do
    local ok, result = pcall(function()
        local url = "https://raw.githubusercontent.com/sixfourshi/Games/refs/heads/main/fip?cb=" .. tostring(os.time())
        local chunk, err = loadstring(game:HttpGet(url))
        if type(chunk) ~= "function" then
            error("library failed to compile: " .. tostring(err), 0)
        end
        local lib = chunk()
        if type(lib) ~= "table" then
            error("library did not return a table", 0)
        end
        return lib
    end)
    if not ok then
        error("Nitrous: failed to load UI library: " .. tostring(result), 0)
    end
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
local CombatTab    = Window:CreateTab({ Name = "Combat",     Icon = "sword"        })
local AutoTab      = Window:CreateTab({ Name = "Automation", Icon = "cpu"          })
local CosmeticsTab = Window:CreateTab({ Name = "Cosmetics",  Icon = "sparkles"     })
local VisualTab    = Window:CreateTab({ Name = "Visual",     Icon = "eye"          })
local MiscTab      = Window:CreateTab({ Name = "Misc",       Icon = "wrench"       })
local SettingsTab  = Window:CreateTab({ Name = "Settings",   Icon = "settings"     })

-- ─── shared state (mirrors kicia Data table structure) ────────────────────────
-- Each toggle/slider callback writes into this table.
-- The actual hook implementations read from here at runtime — wire your
-- kicia module's .Data equivalent to point at NitrousData.
local NitrousData = {
    AntiKatana       = { Enabled = false },
    AutoRespawn      = { Enabled = false },
    AutoPickupDrops  = { Enabled = false, Types = { Health = true, Ammo = true } },
    BulletTracers    = {
        Enabled      = false,
        Color        = Color3.fromRGB(120, 220, 255),
        Width        = 0.06,
        Lifetime     = 0.3,
        FadeTime     = 0.35,
        Emission     = 1,
        Glow         = 1,
        Style        = "Plain",
        TextureLength= 1,
        TextureSpeed = 1,
        Expand       = true,
        ExpandSpeed  = 18,
        ExpandDamper = 0.7,
    },
    AutoQueue        = { Enabled = false, Queue = "Ranked" },
    AutoVote         = { Enabled = false, Maps = {} },
    AutoBan          = { Enabled = false, FirstWeapons = {}, SecondWeapons = {} },
    AutoLoadout      = { Enabled = false, PerMap = false, MultipleLoadouts = false, Loadouts = { Default = {} } },
    Chams            = { Character = { Enabled = false, Material = "Neon", Color = Color3.fromRGB(255, 0, 0), Transparency = 0, StripTextures = false } },
    SkinChanger      = { Enabled = false },
    Unlocker         = { Enabled = false },
    RequestDataHook  = { Enabled = false },
    BodyMode         = "Default",   -- "Default" | "Replica" | "Native"
    EmoteCancellation= { Enabled = true },
    UserServer       = { ShareSkins = false },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- COMBAT TAB
-- ─────────────────────────────────────────────────────────────────────────────
local AntiKatanaBox = CombatTab:AddLeftGroupbox({ Name = "Anti Katana", Icon = "shield" })
AntiKatanaBox:CreateToggle({
    Name         = "Anti Katana",
    Description  = "Blocks gun shots when your hitbox is shielded (kicia dn module)",
    CurrentValue = false,
    Flag         = "Nitrous_AntiKatana",
    Callback     = function(v)
        NitrousData.AntiKatana.Enabled = v
        -- kicia hook: tbl17.dn() reads bG().Data.AntiKatana.Enabled
        -- point bG().Data at NitrousData or call arg:SetEnabled(v) on the
        -- reserved InputHook binding
    end,
})

local AutoRespawnBox = CombatTab:AddLeftGroupbox({ Name = "Auto Respawn", Icon = "refresh-cw" })
AutoRespawnBox:CreateToggle({
    Name         = "Auto Respawn",
    Description  = "Fires RespawnNowRemote 5x when RespawnNowAnimation replicates (kicia dx)",
    CurrentValue = false,
    Flag         = "Nitrous_AutoRespawn",
    Callback     = function(v)
        NitrousData.AutoRespawn.Enabled = v
    end,
})

local TracerBox = CombatTab:AddRightGroupbox({ Name = "Bullet Tracers", Icon = "zap" })
TracerBox:CreateToggle({
    Name         = "Enabled",
    CurrentValue = false,
    Flag         = "Nitrous_BulletTracers",
    Callback     = function(v)
        NitrousData.BulletTracers.Enabled = v
    end,
})
TracerBox:CreateColorPicker({
    Name         = "Color",
    Default      = Color3.fromRGB(120, 220, 255),
    Flag         = "Nitrous_TracerColor",
    Callback     = function(v)
        NitrousData.BulletTracers.Color = v
    end,
})
TracerBox:CreateSlider({
    Name         = "Width",
    Range        = { 0.01, 0.5 },
    Increment    = 0.01,
    CurrentValue = 0.06,
    Flag         = "Nitrous_TracerWidth",
    Callback     = function(v)
        NitrousData.BulletTracers.Width = v
    end,
})
TracerBox:CreateSlider({
    Name         = "Lifetime",
    Range        = { 0.05, 2 },
    Increment    = 0.05,
    CurrentValue = 0.3,
    Flag         = "Nitrous_TracerLifetime",
    Callback     = function(v)
        NitrousData.BulletTracers.Lifetime = v
    end,
})
TracerBox:CreateSlider({
    Name         = "Glow",
    Range        = { 1, 10 },
    Increment    = 1,
    CurrentValue = 1,
    Flag         = "Nitrous_TracerGlow",
    Callback     = function(v)
        NitrousData.BulletTracers.Glow = v
    end,
})
TracerBox:CreateDropdown({
    Name          = "Style",
    Options       = { "Plain", "Beam", "Lightning", "Trail", "Zigzag", "Heartrate", "Chain", "Glitch", "Swirl" },
    CurrentOption = "Plain",
    AllowNone     = false,
    Flag          = "Nitrous_TracerStyle",
    Callback      = function(v)
        NitrousData.BulletTracers.Style = type(v) == "table" and v[1] or v
    end,
})
TracerBox:CreateToggle({
    Name         = "Expand",
    CurrentValue = true,
    Flag         = "Nitrous_TracerExpand",
    Callback     = function(v)
        NitrousData.BulletTracers.Expand = v
    end,
})

-- ─────────────────────────────────────────────────────────────────────────────
-- AUTOMATION TAB
-- ─────────────────────────────────────────────────────────────────────────────
local PickupBox = AutoTab:AddLeftGroupbox({ Name = "Auto Pickup Drops", Icon = "package" })
PickupBox:CreateToggle({
    Name         = "Enabled",
    Description  = "firetouchinterest on ammo/health drop hitboxes (kicia dt)",
    CurrentValue = false,
    Flag         = "Nitrous_AutoPickup",
    Callback     = function(v)
        NitrousData.AutoPickupDrops.Enabled = v
    end,
})
PickupBox:CreateToggle({
    Name         = "Pick Up Health",
    CurrentValue = true,
    Flag         = "Nitrous_PickupHealth",
    Callback     = function(v)
        NitrousData.AutoPickupDrops.Types.Health = v
    end,
})
PickupBox:CreateToggle({
    Name         = "Pick Up Ammo",
    CurrentValue = true,
    Flag         = "Nitrous_PickupAmmo",
    Callback     = function(v)
        NitrousData.AutoPickupDrops.Types.Ammo = v
    end,
})

local QueueBox = AutoTab:AddLeftGroupbox({ Name = "Auto Queue", Icon = "radio" })
QueueBox:CreateToggle({
    Name         = "Enabled",
    Description  = "Auto joins queue / handles arcade teleport (kicia dw)",
    CurrentValue = false,
    Flag         = "Nitrous_AutoQueue",
    Callback     = function(v)
        NitrousData.AutoQueue.Enabled = v
    end,
})
QueueBox:CreateDropdown({
    Name          = "Queue",
    Options       = { "Ranked", "Casual", "Arcade" },
    CurrentOption = "Ranked",
    AllowNone     = false,
    Flag          = "Nitrous_QueueMode",
    Callback      = function(v)
        NitrousData.AutoQueue.Queue = type(v) == "table" and v[1] or v
    end,
})

local VoteBox = AutoTab:AddRightGroupbox({ Name = "Auto Vote / Ban", Icon = "check-square" })
VoteBox:CreateToggle({
    Name         = "Auto Vote Maps",
    Description  = "Votes for preferred maps when vote opens (kicia ds AutoVote)",
    CurrentValue = false,
    Flag         = "Nitrous_AutoVote",
    Callback     = function(v)
        NitrousData.AutoVote.Enabled = v
    end,
})
VoteBox:CreateToggle({
    Name         = "Auto Ban Weapons",
    Description  = "Bans weapons by priority list (kicia ds AutoBan)",
    CurrentValue = false,
    Flag         = "Nitrous_AutoBan",
    Callback     = function(v)
        NitrousData.AutoBan.Enabled = v
    end,
})
VoteBox:CreateInput({
    Name         = "Ban Priority 1 (comma-sep)",
    PlaceholderText = "Shotgun,Rifle,...",
    RemoveOnUnfocused = true,
    Flag         = "Nitrous_BanFirst",
    Callback     = function(v)
        local t = {}
        for item in (v .. ","):gmatch("([^,]+),") do
            t[item:match("^%s*(.-)%s*$")] = true
        end
        NitrousData.AutoBan.FirstWeapons = t
    end,
})
VoteBox:CreateInput({
    Name         = "Ban Priority 2 (comma-sep)",
    PlaceholderText = "Sword,Spear,...",
    RemoveOnUnfocused = true,
    Flag         = "Nitrous_BanSecond",
    Callback     = function(v)
        local t = {}
        for item in (v .. ","):gmatch("([^,]+),") do
            t[item:match("^%s*(.-)%s*$")] = true
        end
        NitrousData.AutoBan.SecondWeapons = t
    end,
})

local LoadoutBox = AutoTab:AddRightGroupbox({ Name = "Auto Loadout", Icon = "briefcase" })
LoadoutBox:CreateToggle({
    Name         = "Enabled",
    Description  = "Auto-picks loadout when weapon picker opens (kicia ds AutoLoadout)",
    CurrentValue = false,
    Flag         = "Nitrous_AutoLoadout",
    Callback     = function(v)
        NitrousData.AutoLoadout.Enabled = v
    end,
})
LoadoutBox:CreateToggle({
    Name         = "Per Map",
    CurrentValue = false,
    Flag         = "Nitrous_LoadoutPerMap",
    Callback     = function(v)
        NitrousData.AutoLoadout.PerMap = v
    end,
})
LoadoutBox:CreateToggle({
    Name         = "Multiple Loadouts",
    CurrentValue = false,
    Flag         = "Nitrous_MultiLoadout",
    Callback     = function(v)
        NitrousData.AutoLoadout.MultipleLoadouts = v
    end,
})
LoadoutBox:CreateInput({
    Name              = "Default Loadout (comma-sep weapon names)",
    PlaceholderText   = "Sword,Rifle,Shotgun,Grenade",
    RemoveOnUnfocused = true,
    Flag              = "Nitrous_LoadoutDefault",
    Callback          = function(v)
        local t = {}
        for item in (v .. ","):gmatch("([^,]+),") do
            t[#t + 1] = item:match("^%s*(.-)%s*$")
        end
        NitrousData.AutoLoadout.Loadouts.Default = { ["1"] = t }
    end,
})

-- ─────────────────────────────────────────────────────────────────────────────
-- COSMETICS TAB
-- ─────────────────────────────────────────────────────────────────────────────
local UnlockerBox = CosmeticsTab:AddLeftGroupbox({ Name = "Unlocker", Icon = "unlock" })
UnlockerBox:CreateToggle({
    Name         = "Enable Unlocker",
    Description  = "Unlocks all cosmetics in the catalog (kicia e0 unlocker layer)",
    CurrentValue = false,
    Flag         = "Nitrous_Unlocker",
    Callback     = function(v)
        NitrousData.Unlocker.Enabled = v
        -- wire: Cosmetics:SetUnlockerEnabled(v)
    end,
})
UnlockerBox:CreateToggle({
    Name         = "Enable Skin Changer",
    Description  = "Override skins per weapon (kicia e0 skinChanger layer)",
    CurrentValue = false,
    Flag         = "Nitrous_SkinChanger",
    Callback     = function(v)
        NitrousData.SkinChanger.Enabled = v
        -- wire: Cosmetics:SetSkinChangerEnabled(v)
    end,
})
UnlockerBox:CreateButton({
    Name     = "Reroll All (randomize)",
    Icon     = "shuffle",
    Callback = function()
        -- wire: Cosmetics:RerollAll()
        Library:Notify({ Title = SCRIPT_NAME, Content = "Rerolled all random cosmetics.", Type = "Info", Duration = 2 })
    end,
})

local ChamsBox = CosmeticsTab:AddRightGroupbox({ Name = "Character Chams", Icon = "user" })
ChamsBox:CreateToggle({
    Name         = "Enabled",
    Description  = "Applies material override to your character (kicia dM)",
    CurrentValue = false,
    Flag         = "Nitrous_Chams",
    Callback     = function(v)
        NitrousData.Chams.Character.Enabled = v
    end,
})
ChamsBox:CreateColorPicker({
    Name         = "Color",
    Default      = Color3.fromRGB(255, 0, 0),
    Flag         = "Nitrous_ChamsColor",
    Callback     = function(v)
        NitrousData.Chams.Character.Color = v
    end,
})
ChamsBox:CreateSlider({
    Name         = "Transparency",
    Range        = { 0, 1 },
    Increment    = 0.05,
    CurrentValue = 0,
    Flag         = "Nitrous_ChamsTransparency",
    Callback     = function(v)
        NitrousData.Chams.Character.Transparency = v
    end,
})
ChamsBox:CreateDropdown({
    Name          = "Material",
    Options       = { "Original", "Neon", "Glass", "ForceField", "SmoothPlastic" },
    CurrentOption = "Neon",
    AllowNone     = false,
    Flag          = "Nitrous_ChamsMaterial",
    Callback      = function(v)
        NitrousData.Chams.Character.Material = type(v) == "table" and v[1] or v
    end,
})
ChamsBox:CreateToggle({
    Name         = "Strip Textures",
    CurrentValue = false,
    Flag         = "Nitrous_ChamsStripTex",
    Callback     = function(v)
        NitrousData.Chams.Character.StripTextures = v
    end,
})

local DataHookBox = CosmeticsTab:AddLeftGroupbox({ Name = "Request Data Hook", Icon = "database" })
DataHookBox:CreateToggle({
    Name         = "Spoof Profile Requests",
    Description  = "Intercepts ViewProfile.Fetch to spoof player data (kicia d9 / dR)",
    CurrentValue = false,
    Flag         = "Nitrous_RequestDataHook",
    Callback     = function(v)
        NitrousData.RequestDataHook.Enabled = v
        -- wire: RequestDataHook:Load() / :_Revert()
    end,
})

-- ─────────────────────────────────────────────────────────────────────────────
-- VISUAL TAB
-- ─────────────────────────────────────────────────────────────────────────────
local BodyBox = VisualTab:AddLeftGroupbox({ Name = "Body View Mode", Icon = "person-standing" })
BodyBox:CreateDropdown({
    Name          = "Mode",
    Description   = "Default = normal. Replica = cloned body visible in FP. Native = viewmodel shows real body (kicia dK).",
    Options       = { "Default", "Replica", "Native" },
    CurrentOption = "Default",
    AllowNone     = false,
    Flag          = "Nitrous_BodyMode",
    Callback      = function(v)
        NitrousData.BodyMode = type(v) == "table" and v[1] or v
        -- wire: LocalBodyView:SetBodyMode(NitrousData.BodyMode)
    end,
})

-- ─────────────────────────────────────────────────────────────────────────────
-- MISC TAB
-- ─────────────────────────────────────────────────────────────────────────────
local EmoteBox = MiscTab:AddLeftGroupbox({ Name = "Emote Cancellation", Icon = "ban" })
EmoteBox:CreateToggle({
    Name         = "Enabled",
    Description  = "Auto-cancels emote if you move 4u, crouch, or quick-melee (kicia dS)",
    CurrentValue = true,
    Flag         = "Nitrous_EmoteCancel",
    Callback     = function(v)
        NitrousData.EmoteCancellation.Enabled = v
    end,
})

local ShareBox = MiscTab:AddLeftGroupbox({ Name = "User Server Bridge", Icon = "share-2" })
ShareBox:CreateToggle({
    Name         = "Share Skins to Peers",
    Description  = "Sends your resolved cosmetic inventory to other Nitrous users via binary peer protocol (kicia e_)",
    CurrentValue = false,
    Flag         = "Nitrous_ShareSkins",
    Callback     = function(v)
        NitrousData.UserServer.ShareSkins = v
        -- wire: UserServerBridge:SetShareActive(v)
    end,
})

local NotifBox = MiscTab:AddRightGroupbox({ Name = "Info", Icon = "info" })
NotifBox:CreateButton({
    Name     = "Check Hook Errors",
    Icon     = "alert-triangle",
    Callback = function()
        -- wire: local errs = Cosmetics:GetHookErrors()
        -- display each error as a notify
        Library:Notify({ Title = "Nitrous", Content = "Wire Cosmetics:GetHookErrors() here.", Type = "Warning", Duration = 4 })
    end,
})
NotifBox:CreateButton({
    Name     = "Reroll Cosmetics",
    Icon     = "shuffle",
    Callback = function()
        -- wire: Cosmetics:RerollAll()
        Library:Notify({ Title = "Nitrous", Content = "Rerolled all random selections.", Type = "Info", Duration = 2 })
    end,
})

-- ─────────────────────────────────────────────────────────────────────────────
-- SETTINGS TAB
-- ─────────────────────────────────────────────────────────────────────────────
local MenuBox = SettingsTab:AddLeftGroupbox({ Name = "Menu", Icon = "monitor" })
MenuBox:CreateKeybind({
    Name           = "Toggle UI",
    CurrentKeybind = "RightControl",
    Flag           = "Nitrous_ToggleUI",
    Callback       = function() end,
    OnChanged      = function(key)
        Window:SetKeybind(key)
    end,
})
MenuBox:CreateDropdown({
    Name          = "Toggle Button",
    Options       = { "Mobile only", "Mobile & PC" },
    CurrentOption = "Mobile only",
    AllowNone     = false,
    Flag          = "Nitrous_ToggleButtonPlatform",
    Callback      = function(v)
        local choice = type(v) == "table" and v[1] or v
        Window:SetToggleButtonPlatform(choice == "Mobile & PC" and "Both" or "Mobile")
    end,
})
MenuBox:CreateButton({
    Name     = "Unload Nitrous",
    Icon     = "power",
    Callback = function()
        Library:Confirm({
            Title       = "Unload Nitrous?",
            ConfirmText = "Unload",
            Callback    = function()
                Window:Destroy()
            end,
        })
    end,
})

SettingsTab:CreateConfigManager({ Name = "Configs", Side = "Left" })
SettingsTab:CreateThemeManager({ Name = "Themes", Side = "Right" })

-- ─── restore saved config ─────────────────────────────────────────────────────
Window:LoadAutoload()

Library:Notify({
    Title   = SCRIPT_NAME,
    Content = "Loaded successfully.",
    Type    = "Success",
    Duration = 3,
})

-- ─── expose data table for your hook modules ─────────────────────────────────
-- After this file, point your kicia module's bG().Data at NitrousData
-- e.g.:  local bG = tbl17.bG(); bG._data = NitrousData
return NitrousData
