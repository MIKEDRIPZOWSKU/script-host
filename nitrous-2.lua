--[[
    Nitrous
    Rebuilt from Kicia using the Ouroboros UI library.
    All game logic, configs, and callbacks are stubs — wire them to your
    live implementations the same way the original Kicia hooks do.
--]]

if getgenv().NitrousScript and getgenv().NitrousScript.Unload then
    pcall(getgenv().NitrousScript.Unload)
end
if not game:IsLoaded() then game.Loaded:Wait() end

local SCRIPT_NAME    = "Nitrous"
local SCRIPT_VERSION = "v1.0"

local Library
local Window

-- Load the Ouroboros UI library -------------------------------------------
local ok, result = pcall(function()
    local url = "https://raw.githubusercontent.com/sixfourshi/Games/refs/heads/main/fip?cb=" .. tostring(os.time())
    local chunk, compileErr = loadstring(game:HttpGet(url))
    if type(chunk) ~= "function" then
        error("library failed to compile: " .. tostring(compileErr), 0)
    end
    local lib = chunk()
    if type(lib) ~= "table" then
        error("library file did not return a table", 0)
    end
    return lib
end)
if not ok then
    error("failed to load UI library: " .. tostring(result), 0)
end
Library = result

getgenv().NitrousScript = { Unload = function() Window:Destroy() end }

Library:SetDefaultTheme("Rose")

Window = Library:CreateWindow({
    Name              = SCRIPT_NAME,
    LoadingSubtitle   = SCRIPT_VERSION,
    ToggleUIKeybind   = "RightShift",
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "Nitrous",
        FileName   = "default",
    },
    ToggleButton = { Platform = "Mobile" },
    Home = {
        Title   = "Welcome to " .. SCRIPT_NAME .. "!",
        Tier    = SCRIPT_VERSION,
        Discord = "https://discord.gg/example",
        Website = "https://example.com",
        Stats   = { "Players", "Session", "FPS", "Ping" },
    },
})

-- ═══════════════════════════════════════════════════════════════════════════
--  TAB STRUCTURE (mirrors Kicia exactly)
--   Combat  /  Visuals  /  Player  /  World  /  Settings
-- ═══════════════════════════════════════════════════════════════════════════

local CombatTab   = Window:CreateTab({ Name = "Combat",   Icon = "crosshair" })
local VisualsTab  = Window:CreateTab({ Name = "Visuals",  Icon = "eye" })
local PlayerTab   = Window:CreateTab({ Name = "Player",   Icon = "user" })
local WorldTab    = Window:CreateTab({ Name = "World",    Icon = "globe" })
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "settings" })


-- ═══════════════════════════════════════════════════════════════════════════
--  COMBAT TAB
--   Sub-tabs: Aimbot · Silent Aim · Ragebot · Fire Assist
--             Weapon Handling · Hit Feedback
-- ═══════════════════════════════════════════════════════════════════════════

---- Aimbot ------------------------------------------------------------------
local AimbotTab     = CombatTab:CreateTab({ Name = "Aimbot",          Icon = "camera" })
local AimbotGeneral = AimbotTab:AddLeftGroupbox({ Name = "Activation", Icon = "power" })
AimbotGeneral:CreateToggle({
    Name = "Enable Aimbot", CurrentValue = false, Flag = "AimbotEnabled",
    Callback = function(v) end,
})
AimbotGeneral:CreateDropdown({
    Name = "Mode", Options = { "Always", "Toggle", "Hold" },
    CurrentOption = "Hold", Flag = "AimbotMode",
    Callback = function(v) end,
})
AimbotGeneral:CreateDropdown({
    Name = "Target Priority",
    Options = { "Closest to Crosshair", "Lowest HP", "Closest Distance" },
    CurrentOption = "Closest to Crosshair", Flag = "AimbotTargetPriority",
    Callback = function(v) end,
})

local AimbotConditions = AimbotTab:AddRightGroupbox({ Name = "Activation Conditions", Icon = "check-circle" })
AimbotConditions:CreateToggle({
    Name = "Not Reloading", CurrentValue = true, Flag = "AimbotNotReloading",
    Callback = function(v) end,
})
AimbotConditions:CreateToggle({
    Name = "Scoped In", CurrentValue = false, Flag = "AimbotScopedIn",
    Callback = function(v) end,
})
AimbotConditions:CreateToggle({
    Name = "Visible Only", CurrentValue = true, Flag = "AimbotVisibleOnly",
    Callback = function(v) end,
})
AimbotConditions:CreateToggle({
    Name = "Not Deflecting", CurrentValue = true, Flag = "AimbotNotDeflecting",
    Callback = function(v) end,
})
AimbotConditions:CreateToggle({
    Name = "Not Shielded", CurrentValue = true, Flag = "AimbotNotShielded",
    Callback = function(v) end,
})
AimbotConditions:CreateToggle({
    Name = "Within FOV", CurrentValue = true, Flag = "AimbotWithinFov",
    Callback = function(v) end,
})

local AimbotFov = AimbotTab:AddLeftGroupbox({ Name = "FOV & Smoothness", Icon = "sliders-horizontal" })
AimbotFov:CreateSlider({
    Name = "FOV Radius", Range = { 1, 360 }, Increment = 1,
    CurrentValue = 90, Flag = "AimbotFovRadius",
    Callback = function(v) end,
})
AimbotFov:CreateSlider({
    Name = "Smoothness", Range = { 1, 100 }, Increment = 1,
    CurrentValue = 10, Flag = "AimbotSmoothness",
    Callback = function(v) end,
})
AimbotFov:CreateSlider({
    Name = "Activation Chance (%)", Range = { 1, 100 }, Increment = 1,
    CurrentValue = 100, Flag = "AimbotActivationChance",
    Callback = function(v) end,
})

local AimbotHitbox = AimbotTab:AddRightGroupbox({ Name = "Hitbox Selection", Icon = "target" })
AimbotHitbox:CreateDropdown({
    Name = "Hitbox Type",
    Options = { "Head", "Neck", "Torso", "Closest to Crosshair" },
    CurrentOption = "Head", Flag = "AimbotHitboxType",
    Callback = function(v) end,
})
AimbotHitbox:CreateSlider({
    Name = "Head %", Range = { 0, 100 }, Increment = 1,
    CurrentValue = 50, Flag = "AimbotHeadPercent",
    Callback = function(v) end,
})

---- Silent Aim --------------------------------------------------------------
local SilentTab    = CombatTab:CreateTab({ Name = "Silent Aim", Icon = "zap" })
local SilentMain   = SilentTab:AddLeftGroupbox({ Name = "Activation", Icon = "power" })
SilentMain:CreateToggle({
    Name = "Enable Silent Aim", CurrentValue = false, Flag = "SilentAimEnabled",
    Callback = function(v) end,
})
SilentMain:CreateDropdown({
    Name = "Mode", Options = { "Always", "Toggle", "Hold" },
    CurrentOption = "Hold", Flag = "SilentAimMode",
    Callback = function(v) end,
})
SilentMain:CreateToggle({
    Name = "Manipulate", CurrentValue = false, Flag = "SilentAimManipulate",
    Callback = function(v) end,
})
SilentMain:CreateDropdown({
    Name = "Manipulation Check",
    Options = { "On Best Target", "On All Targets" },
    CurrentOption = "On Best Target", Flag = "SilentAimManipulateMode",
    Callback = function(v) end,
})
SilentMain:CreateToggle({
    Name = "Show Indicator", CurrentValue = true, Flag = "SilentAimShowIndicator",
    Callback = function(v) end,
})

local SilentCond = SilentTab:AddRightGroupbox({ Name = "Target Conditions", Icon = "check-circle" })
SilentCond:CreateToggle({
    Name = "Visible Only", CurrentValue = true, Flag = "SilentVisibleOnly",
    Callback = function(v) end,
})
SilentCond:CreateToggle({
    Name = "Not Deflecting", CurrentValue = true, Flag = "SilentNotDeflecting",
    Callback = function(v) end,
})
SilentCond:CreateToggle({
    Name = "Not Shielded", CurrentValue = true, Flag = "SilentNotShielded",
    Callback = function(v) end,
})
SilentCond:CreateToggle({
    Name = "Not Reloading", CurrentValue = true, Flag = "SilentNotReloading",
    Callback = function(v) end,
})

---- Ragebot -----------------------------------------------------------------
local RagebotTab  = CombatTab:CreateTab({ Name = "Ragebot", Icon = "skull" })
local RagebotMain = RagebotTab:AddLeftGroupbox({ Name = "Activation", Icon = "power" })
RagebotMain:CreateToggle({
    Name = "Enable Ragebot", CurrentValue = false, Flag = "RagebotEnabled",
    Callback = function(v) end,
})
RagebotMain:CreateDropdown({
    Name = "Mode", Options = { "Always", "Toggle", "Hold" },
    CurrentOption = "Hold", Flag = "RagebotMode",
    Callback = function(v) end,
})
RagebotMain:CreateToggle({
    Name = "Prioritize Hackers", CurrentValue = false, Flag = "RagebotPrioritizeHackers",
    Callback = function(v) end,
})
RagebotMain:CreateSlider({
    Name = "Stability", Range = { 0, 1.5 }, Increment = 0.001,
    CurrentValue = 0.5, Flag = "RagebotStability",
    Callback = function(v) end,
})
RagebotMain:CreateSlider({
    Name = "Shoot Frames", Range = { 1, 5 }, Increment = 1,
    CurrentValue = 1, Flag = "RagebotShootFrames",
    Callback = function(v) end,
})

local RagebotWeapons = RagebotTab:AddRightGroupbox({ Name = "Weapon Strategy", Icon = "gun" })
RagebotWeapons:CreateToggle({
    Name = "Primary Enabled", CurrentValue = true, Flag = "RagebotPrimaryEnabled",
    Callback = function(v) end,
})
RagebotWeapons:CreateToggle({
    Name = "Secondary Enabled", CurrentValue = true, Flag = "RagebotSecondaryEnabled",
    Callback = function(v) end,
})
RagebotWeapons:CreateToggle({
    Name = "Melee Enabled", CurrentValue = false, Flag = "RagebotMeleeEnabled",
    Callback = function(v) end,
})
RagebotWeapons:CreateDropdown({
    Name = "On Empty",
    Options = { "Reload", "Swap", "Swap or Reload" },
    CurrentOption = "Reload", Flag = "RagebotOnEmpty",
    Callback = function(v) end,
})

local RagebotEvasion = RagebotTab:AddLeftGroupbox({ Name = "Evasion", Icon = "shuffle" })
RagebotEvasion:CreateDropdown({
    Name = "Evasion Mode",
    Options = { "Off", "Random", "Translocate", "Projectile Breaker" },
    CurrentOption = "Off", Flag = "RagebotEvasionMode",
    Callback = function(v) end,
})
RagebotEvasion:CreateSlider({
    Name = "Base Radius", Range = { 5, 100 }, Increment = 1,
    CurrentValue = 20, Flag = "RagebotEvasionBaseRadius",
    Callback = function(v) end,
})
RagebotEvasion:CreateSlider({
    Name = "Random Factor", Range = { 0, 1 }, Increment = 0.1,
    CurrentValue = 0.5, Flag = "RagebotEvasionRandomFactor",
    Callback = function(v) end,
})

---- Fire Assist -------------------------------------------------------------
local FireAssistTab = CombatTab:CreateTab({ Name = "Fire Assist", Icon = "flame" })
local TriggerBox    = FireAssistTab:AddLeftGroupbox({ Name = "Triggerbot", Icon = "mouse-pointer-click" })
TriggerBox:CreateToggle({
    Name = "Enable Triggerbot", CurrentValue = false, Flag = "TriggerbotEnabled",
    Callback = function(v) end,
})
TriggerBox:CreateDropdown({
    Name = "Mode", Options = { "Always", "Toggle", "Hold" },
    CurrentOption = "Hold", Flag = "TriggerbotMode",
    Callback = function(v) end,
})
TriggerBox:CreateToggle({
    Name = "Not Reloading", CurrentValue = true, Flag = "TriggerbotNotReloading",
    Callback = function(v) end,
})
TriggerBox:CreateToggle({
    Name = "Not Deflecting", CurrentValue = true, Flag = "TriggerbotNotDeflecting",
    Callback = function(v) end,
})

local FlickBox = FireAssistTab:AddRightGroupbox({ Name = "Flickbot", Icon = "zap" })
FlickBox:CreateToggle({
    Name = "Enable Flickbot", CurrentValue = false, Flag = "FlickbotEnabled",
    Callback = function(v) end,
})
FlickBox:CreateDropdown({
    Name = "Mode", Options = { "Hold", "Toggle" },
    CurrentOption = "Hold", Flag = "FlickbotMode",
    Callback = function(v) end,
})
FlickBox:CreateToggle({
    Name = "Auto Shoot", CurrentValue = true, Flag = "FlickbotShoot",
    Callback = function(v) end,
})
FlickBox:CreateSlider({
    Name = "Shot Delay (ms)", Range = { 0, 250 }, Increment = 1,
    CurrentValue = 50, Flag = "FlickbotShotDelay",
    Callback = function(v) end,
})
FlickBox:CreateSlider({
    Name = "Cooldown (ms)", Range = { 0, 2000 }, Increment = 1,
    CurrentValue = 500, Flag = "FlickbotCooldown",
    Callback = function(v) end,
})
FlickBox:CreateSlider({
    Name = "Flick Duration (ms)", Range = { 30, 400 }, Increment = 1,
    CurrentValue = 120, Flag = "FlickbotFlickDuration",
    Callback = function(v) end,
})
FlickBox:CreateSlider({
    Name = "Curvature", Range = { 0, 50 }, Increment = 1,
    CurrentValue = 10, Flag = "FlickbotCurvature",
    Callback = function(v) end,
})
FlickBox:CreateSlider({
    Name = "Humanness", Range = { 0, 100 }, Increment = 1,
    CurrentValue = 50, Flag = "FlickbotHumanness",
    Callback = function(v) end,
})

---- Weapon Handling ---------------------------------------------------------
local WeaponTab   = CombatTab:CreateTab({ Name = "Weapon Handling", Icon = "tool" })
local AimFireBox  = WeaponTab:AddLeftGroupbox({ Name = "Aim & Fire", Icon = "crosshair" })
AimFireBox:CreateToggle({
    Name = "Reduce Recoil", CurrentValue = false, Flag = "WeaponReduceRecoil",
    Callback = function(v) end,
})
AimFireBox:CreateSlider({
    Name = "Recoil Reduction (%)", Range = { 0, 100 }, Increment = 1,
    CurrentValue = 50, Flag = "WeaponRecoilReductionPct",
    Callback = function(v) end,
})
AimFireBox:CreateToggle({
    Name = "Remove Spread", CurrentValue = false, Flag = "WeaponNoSpread",
    Callback = function(v) end,
})
AimFireBox:CreateToggle({
    Name = "Fast Shoot", CurrentValue = false, Flag = "WeaponFastShoot",
    Callback = function(v) end,
})
AimFireBox:CreateToggle({
    Name = "Fast Projectile", CurrentValue = false, Flag = "WeaponFastProjectile",
    Callback = function(v) end,
})
AimFireBox:CreateToggle({
    Name = "Full Auto", CurrentValue = false, Flag = "WeaponFullAuto",
    Callback = function(v) end,
})
AimFireBox:CreateToggle({
    Name = "Fire Rate Override", CurrentValue = false, Flag = "WeaponFireRateEnabled",
    Callback = function(v) end,
})
AimFireBox:CreateSlider({
    Name = "Fire Rate (%)", Range = { 1, 100 }, Increment = 1,
    CurrentValue = 50, Flag = "WeaponFireRatePct",
    Callback = function(v) end,
})

local CooldownBox = WeaponTab:AddRightGroupbox({ Name = "Cooldowns", Icon = "timer" })
CooldownBox:CreateToggle({
    Name = "Fire Cooldown Override", CurrentValue = false, Flag = "WeaponFireCooldownEnabled",
    Callback = function(v) end,
})
CooldownBox:CreateSlider({
    Name = "Fire Cooldown (%)", Range = { 0, 100 }, Increment = 1,
    CurrentValue = 50, Flag = "WeaponFireCooldownPct",
    Callback = function(v) end,
})
CooldownBox:CreateToggle({
    Name = "Aim Cooldown Override", CurrentValue = false, Flag = "WeaponAimCooldownEnabled",
    Callback = function(v) end,
})
CooldownBox:CreateSlider({
    Name = "Aim Cooldown (%)", Range = { 1, 100 }, Increment = 1,
    CurrentValue = 50, Flag = "WeaponAimCooldownPct",
    Callback = function(v) end,
})
CooldownBox:CreateToggle({
    Name = "Melee Cooldown Override", CurrentValue = false, Flag = "WeaponMeleeCooldownEnabled",
    Callback = function(v) end,
})
CooldownBox:CreateSlider({
    Name = "Melee Cooldown (%)", Range = { 0, 100 }, Increment = 1,
    CurrentValue = 50, Flag = "WeaponMeleeCooldownPct",
    Callback = function(v) end,
})
CooldownBox:CreateToggle({
    Name = "Dash Cooldown Override", CurrentValue = false, Flag = "WeaponDashCooldownEnabled",
    Callback = function(v) end,
})
CooldownBox:CreateSlider({
    Name = "Dash Cooldown (%)", Range = { 0, 100 }, Increment = 1,
    CurrentValue = 50, Flag = "WeaponDashCooldownPct",
    Callback = function(v) end,
})

local MeleeBox = WeaponTab:AddLeftGroupbox({ Name = "Melee", Icon = "sword" })
MeleeBox:CreateToggle({
    Name = "Always Backstab", CurrentValue = false, Flag = "WeaponAlwaysBackstab",
    Callback = function(v) end,
})
MeleeBox:CreateToggle({
    Name = "Extend Melee Range", CurrentValue = false, Flag = "WeaponExtendMeleeRangeEnabled",
    Callback = function(v) end,
})
MeleeBox:CreateSlider({
    Name = "Melee Range", Range = { 5, 20 }, Increment = 0.1,
    CurrentValue = 8, Flag = "WeaponMeleeRange",
    Callback = function(v) end,
})

local GrenadeBox = WeaponTab:AddRightGroupbox({ Name = "Grenades", Icon = "alert-triangle" })
GrenadeBox:CreateToggle({
    Name = "Fuse Override", CurrentValue = false, Flag = "WeaponFuseOverrideEnabled",
    Callback = function(v) end,
})
GrenadeBox:CreateDropdown({
    Name = "Explode On", Options = { "Impact", "Throw" },
    CurrentOption = "Impact", Flag = "WeaponFuseExplodeOn",
    Callback = function(v) end,
})
GrenadeBox:CreateToggle({
    Name = "Remove Fuse", CurrentValue = false, Flag = "WeaponRemoveFuse",
    Callback = function(v) end,
})

---- Hit Feedback ------------------------------------------------------------
local HitFeedbackTab  = CombatTab:CreateTab({ Name = "Hit Feedback", Icon = "activity" })
local HitSoundBox     = HitFeedbackTab:AddLeftGroupbox({ Name = "Sound", Icon = "volume-2" })
HitSoundBox:CreateToggle({
    Name = "Enable Hit Sound", CurrentValue = false, Flag = "HitSoundEnabled",
    Callback = function(v) end,
})
HitSoundBox:CreateSlider({
    Name = "Volume", Range = { 0, 10 }, Increment = 0.1,
    CurrentValue = 1, Flag = "HitSoundVolume",
    Callback = function(v) end,
})
HitSoundBox:CreateToggle({
    Name = "Kill Sound", CurrentValue = false, Flag = "KillSoundEnabled",
    Callback = function(v) end,
})

local HitVisualBox = HitFeedbackTab:AddRightGroupbox({ Name = "Visual & Flash", Icon = "eye" })
HitVisualBox:CreateToggle({
    Name = "Enable Hitmarker", CurrentValue = false, Flag = "HitmarkerEnabled",
    Callback = function(v) end,
})
HitVisualBox:CreateToggle({
    Name = "Hit Flash", CurrentValue = false, Flag = "HitFlashEnabled",
    Callback = function(v) end,
})
HitVisualBox:CreateToggle({
    Name = "Enable Notifications", CurrentValue = false, Flag = "HitNotifEnabled",
    Callback = function(v) end,
})


-- ═══════════════════════════════════════════════════════════════════════════
--  VISUALS TAB
--   Sub-tabs: Player ESP · Crosshair · Weapon Visuals
--             Camera & Screen · Sound ESP
-- ═══════════════════════════════════════════════════════════════════════════

---- Player ESP --------------------------------------------------------------
local EspTab   = VisualsTab:CreateTab({ Name = "Player ESP", Icon = "users" })

-- Main section
local EspMainBox = EspTab:AddLeftGroupbox({ Name = "Player ESP", Icon = "eye" })
EspMainBox:CreateToggle({
    Name = "Enable ESP", CurrentValue = false, Flag = "EspEnabled",
    Callback = function(v) end,
})
EspMainBox:CreateDropdown({
    Name = "Mode", Options = { "Always", "Toggle", "Hold" },
    CurrentOption = "Always", Flag = "EspMode",
    Callback = function(v) end,
})
EspMainBox:CreateDropdown({
    Name = "Box Fit", Options = { "Static", "Dynamic" },
    CurrentOption = "Dynamic", Flag = "EspBoxFit",
    Callback = function(v) end,
})

-- Text section
local EspTextBox = EspTab:AddRightGroupbox({ Name = "Text", Icon = "type" })
EspTextBox:CreateToggle({
    Name = "Use Display Names", CurrentValue = false, Flag = "EspUseDisplayName",
    Callback = function(v) end,
})
EspTextBox:CreateDropdown({
    Name = "Text Case", Options = { "Standard", "UPPERCASE", "lowercase" },
    CurrentOption = "Standard", Flag = "EspTextCase",
    Callback = function(v) end,
})
EspTextBox:CreateDropdown({
    Name = "Text Surround", Options = { "None", "[]", "()", "<>", "{}" },
    CurrentOption = "None", Flag = "EspTextSurround",
    Callback = function(v) end,
})
EspTextBox:CreateToggle({
    Name = "Scale With Distance", CurrentValue = false, Flag = "EspDistanceScaling",
    Callback = function(v) end,
})
EspTextBox:CreateSlider({
    Name = "Reference Distance", Range = { 10, 300 }, Increment = 1,
    CurrentValue = 60, Flag = "EspDistanceScalingRef",
    Callback = function(v) end,
})

-- Rank Spoof
local RankSpoofBox = EspTab:AddLeftGroupbox({ Name = "Rank Spoof", Icon = "award" })
RankSpoofBox:CreateToggle({
    Name = "Spoof Rank", CurrentValue = false, Flag = "EspSpoofRankEnabled",
    Callback = function(v) end,
})

-- Enemy ESP
local EspEnemyBox = EspTab:AddLeftGroupbox({ Name = "Enemy ESP", Icon = "user-x" })
EspEnemyBox:CreateToggle({
    Name = "Enable Enemy ESP", CurrentValue = false, Flag = "EspEnemyEnabled",
    Callback = function(v) end,
})
EspEnemyBox:CreateToggle({
    Name = "Name", CurrentValue = true, Flag = "EspEnemyName",
    Callback = function(v) end,
})
EspEnemyBox:CreateToggle({
    Name = "Box", CurrentValue = true, Flag = "EspEnemyBox",
    Callback = function(v) end,
})
EspEnemyBox:CreateDropdown({
    Name = "Box Style", Options = { "Full", "Corner" },
    CurrentOption = "Full", Flag = "EspEnemyBoxStyle",
    Callback = function(v) end,
})
EspEnemyBox:CreateToggle({
    Name = "Health Bar", CurrentValue = true, Flag = "EspEnemyHealthBar",
    Callback = function(v) end,
})
EspEnemyBox:CreateDropdown({
    Name = "Health Bar Color Mode", Options = { "Solid", "Gradient", "Reactive" },
    CurrentOption = "Reactive", Flag = "EspEnemyHealthBarMode",
    Callback = function(v) end,
})
EspEnemyBox:CreateToggle({
    Name = "Health Number", CurrentValue = false, Flag = "EspEnemyHealthNumber",
    Callback = function(v) end,
})
EspEnemyBox:CreateToggle({
    Name = "Held Weapon", CurrentValue = false, Flag = "EspEnemyHeldWeapon",
    Callback = function(v) end,
})
EspEnemyBox:CreateToggle({
    Name = "Distance", CurrentValue = false, Flag = "EspEnemyDistance",
    Callback = function(v) end,
})
EspEnemyBox:CreateToggle({
    Name = "Win Streak", CurrentValue = false, Flag = "EspEnemyWinstreak",
    Callback = function(v) end,
})
EspEnemyBox:CreateToggle({
    Name = "Chams", CurrentValue = false, Flag = "EspEnemyChamsEnabled",
    Callback = function(v) end,
})
EspEnemyBox:CreateDropdown({
    Name = "Chams Kind", Options = { "Legacy", "Highlight" },
    CurrentOption = "Legacy", Flag = "EspEnemyChamsKind",
    Callback = function(v) end,
})
EspEnemyBox:CreateToggle({
    Name = "Skeleton", CurrentValue = false, Flag = "EspEnemySkeletonEnabled",
    Callback = function(v) end,
})
EspEnemyBox:CreateSlider({
    Name = "Skeleton Thickness", Range = { 1, 6 }, Increment = 1,
    CurrentValue = 1, Flag = "EspEnemySkeletonThickness",
    Callback = function(v) end,
})
EspEnemyBox:CreateToggle({
    Name = "Tracer", CurrentValue = false, Flag = "EspEnemyTracerEnabled",
    Callback = function(v) end,
})
EspEnemyBox:CreateDropdown({
    Name = "Tracer Origin", Options = { "Bottom", "Center", "Top", "Mouse" },
    CurrentOption = "Bottom", Flag = "EspEnemyTracerOrigin",
    Callback = function(v) end,
})
EspEnemyBox:CreateSlider({
    Name = "Tracer Thickness", Range = { 1, 6 }, Increment = 1,
    CurrentValue = 1, Flag = "EspEnemyTracerThickness",
    Callback = function(v) end,
})

-- Team ESP
local EspTeamBox = EspTab:AddRightGroupbox({ Name = "Team ESP", Icon = "user-check" })
EspTeamBox:CreateToggle({
    Name = "Enable Team ESP", CurrentValue = false, Flag = "EspTeamEnabled",
    Callback = function(v) end,
})
EspTeamBox:CreateToggle({
    Name = "Name", CurrentValue = true, Flag = "EspTeamName",
    Callback = function(v) end,
})
EspTeamBox:CreateToggle({
    Name = "Box", CurrentValue = false, Flag = "EspTeamBox",
    Callback = function(v) end,
})
EspTeamBox:CreateToggle({
    Name = "Health Bar", CurrentValue = true, Flag = "EspTeamHealthBar",
    Callback = function(v) end,
})
EspTeamBox:CreateToggle({
    Name = "Tracer", CurrentValue = false, Flag = "EspTeamTracerEnabled",
    Callback = function(v) end,
})
EspTeamBox:CreateToggle({
    Name = "Chams", CurrentValue = false, Flag = "EspTeamChamsEnabled",
    Callback = function(v) end,
})

---- Crosshair ---------------------------------------------------------------
local CrosshairTab = VisualsTab:CreateTab({ Name = "Crosshair", Icon = "plus-circle" })
local CrosshairMain = CrosshairTab:AddLeftGroupbox({ Name = "Crosshair", Icon = "plus-circle" })
CrosshairMain:CreateToggle({
    Name = "Enable Custom Crosshair", CurrentValue = false, Flag = "CrosshairEnabled",
    Callback = function(v) end,
})
CrosshairMain:CreateDropdown({
    Name = "Style", Options = { "Lines", "Image" },
    CurrentOption = "Lines", Flag = "CrosshairStyle",
    Callback = function(v) end,
})

local CrosshairLines = CrosshairTab:AddRightGroupbox({ Name = "Lines", Icon = "grid" })
CrosshairLines:CreateSlider({
    Name = "Line Length", Range = { 1, 100 }, Increment = 1,
    CurrentValue = 10, Flag = "CrosshairLength",
    Callback = function(v) end,
})
CrosshairLines:CreateSlider({
    Name = "Line Thickness", Range = { 1, 20 }, Increment = 1,
    CurrentValue = 2, Flag = "CrosshairThickness",
    Callback = function(v) end,
})
CrosshairLines:CreateSlider({
    Name = "Line Gap", Range = { 0, 100 }, Increment = 1,
    CurrentValue = 4, Flag = "CrosshairGap",
    Callback = function(v) end,
})
CrosshairLines:CreateToggle({
    Name = "Crosshair Outline", CurrentValue = false, Flag = "CrosshairOutlineEnabled",
    Callback = function(v) end,
})
CrosshairLines:CreateSlider({
    Name = "Outline Thickness", Range = { 0, 10 }, Increment = 1,
    CurrentValue = 1, Flag = "CrosshairOutlineThickness",
    Callback = function(v) end,
})
CrosshairLines:CreateToggle({
    Name = "Top Line",    CurrentValue = true, Flag = "CrosshairTopEnabled",    Callback = function(v) end,
})
CrosshairLines:CreateToggle({
    Name = "Bottom Line", CurrentValue = true, Flag = "CrosshairBottomEnabled", Callback = function(v) end,
})
CrosshairLines:CreateToggle({
    Name = "Left Line",   CurrentValue = true, Flag = "CrosshairLeftEnabled",   Callback = function(v) end,
})
CrosshairLines:CreateToggle({
    Name = "Right Line",  CurrentValue = true, Flag = "CrosshairRightEnabled",  Callback = function(v) end,
})

---- Weapon Visuals ----------------------------------------------------------
local WeaponVisTab  = VisualsTab:CreateTab({ Name = "Weapon Visuals", Icon = "layers" })
local ViewmodelBox  = WeaponVisTab:AddLeftGroupbox({ Name = "Viewmodel Position", Icon = "move" })
ViewmodelBox:CreateToggle({
    Name = "Enable Viewmodel Position", CurrentValue = false, Flag = "ViewmodelPosEnabled",
    Callback = function(v) end,
})
ViewmodelBox:CreateSlider({
    Name = "X", Range = { -7.5, 7.5 }, Increment = 0.01,
    CurrentValue = 0, Flag = "ViewmodelPosX", Callback = function(v) end,
})
ViewmodelBox:CreateSlider({
    Name = "Y", Range = { -7.5, 7.5 }, Increment = 0.01,
    CurrentValue = 0, Flag = "ViewmodelPosY", Callback = function(v) end,
})
ViewmodelBox:CreateSlider({
    Name = "Z", Range = { -7.5, 7.5 }, Increment = 0.01,
    CurrentValue = 0, Flag = "ViewmodelPosZ", Callback = function(v) end,
})
ViewmodelBox:CreateSlider({
    Name = "Pitch", Range = { -180, 180 }, Increment = 1,
    CurrentValue = 0, Flag = "ViewmodelPitch", Callback = function(v) end,
})
ViewmodelBox:CreateSlider({
    Name = "Yaw", Range = { -180, 180 }, Increment = 1,
    CurrentValue = 0, Flag = "ViewmodelYaw", Callback = function(v) end,
})
ViewmodelBox:CreateSlider({
    Name = "Roll", Range = { -180, 180 }, Increment = 1,
    CurrentValue = 0, Flag = "ViewmodelRoll", Callback = function(v) end,
})

local MotionBox = WeaponVisTab:AddRightGroupbox({ Name = "Motion & Animation", Icon = "activity" })
MotionBox:CreateToggle({
    Name = "Hide Shoot Animation",  CurrentValue = false, Flag = "NoShootAnim",  Callback = function(v) end,
})
MotionBox:CreateToggle({
    Name = "Hide Sprint Animation", CurrentValue = false, Flag = "NoSprintAnim", Callback = function(v) end,
})
MotionBox:CreateToggle({
    Name = "Hide Equip Animation",  CurrentValue = false, Flag = "NoEquipAnim",  Callback = function(v) end,
})
MotionBox:CreateToggle({
    Name = "Hide Reload Animation", CurrentValue = false, Flag = "NoReloadAnim", Callback = function(v) end,
})
MotionBox:CreateToggle({
    Name = "Remove Weapon Motion",   CurrentValue = false, Flag = "NoWeaponMotion",  Callback = function(v) end,
})
MotionBox:CreateToggle({
    Name = "Remove Camera Shake",    CurrentValue = false, Flag = "NoCameraShake",   Callback = function(v) end,
})
MotionBox:CreateToggle({
    Name = "Remove Camera Sway",     CurrentValue = false, Flag = "NoCameraSway",    Callback = function(v) end,
})

local SuppressBox = WeaponVisTab:AddLeftGroupbox({ Name = "Suppressions", Icon = "eye-off" })
SuppressBox:CreateToggle({
    Name = "Hide Muzzle Flash",   CurrentValue = false, Flag = "NoMuzzleFlash",  Callback = function(v) end,
})
SuppressBox:CreateToggle({
    Name = "Hide Game Tracers",   CurrentValue = false, Flag = "NoGunTracers",   Callback = function(v) end,
})

---- Camera & Screen ---------------------------------------------------------
local CameraTab  = VisualsTab:CreateTab({ Name = "Camera & Screen", Icon = "monitor" })
local ThirdPBox  = CameraTab:AddLeftGroupbox({ Name = "Third Person", Icon = "camera" })
ThirdPBox:CreateToggle({
    Name = "Enable Third Person", CurrentValue = false, Flag = "ThirdPersonEnabled",
    Callback = function(v) end,
})
ThirdPBox:CreateDropdown({
    Name = "Mode", Options = { "Toggle" },
    CurrentOption = "Toggle", Flag = "ThirdPersonMode", Callback = function(v) end,
})
ThirdPBox:CreateToggle({
    Name = "Ray Check",    CurrentValue = true,  Flag = "ThirdPersonRayCheck",    Callback = function(v) end,
})
ThirdPBox:CreateToggle({
    Name = "Show Replica", CurrentValue = false, Flag = "ThirdPersonShowReplica", Callback = function(v) end,
})
ThirdPBox:CreateSlider({ Name = "X Offset", Range = { -15, 15 }, Increment = 0.1, CurrentValue = 2,  Flag = "ThirdPersonX", Callback = function(v) end })
ThirdPBox:CreateSlider({ Name = "Y Offset", Range = {  -5, 10 }, Increment = 0.1, CurrentValue = 1,  Flag = "ThirdPersonY", Callback = function(v) end })
ThirdPBox:CreateSlider({ Name = "Z Offset", Range = {   0, 15 }, Increment = 0.1, CurrentValue = 5,  Flag = "ThirdPersonZ", Callback = function(v) end })

local CameraFovBox = CameraTab:AddRightGroupbox({ Name = "Camera FOV", Icon = "maximize-2" })
CameraFovBox:CreateToggle({
    Name = "Enable Camera FOV", CurrentValue = false, Flag = "CameraFovEnabled",
    Callback = function(v) end,
})
CameraFovBox:CreateSlider({
    Name = "Field of View", Range = { 30, 120 }, Increment = 1,
    CurrentValue = 70, Flag = "CameraFovValue", Callback = function(v) end,
})

local OverlaysBox = CameraTab:AddLeftGroupbox({ Name = "Gameplay Overlays", Icon = "layers" })
OverlaysBox:CreateToggle({ Name = "Hide Flashbang Effect",  CurrentValue = false, Flag = "NoFlashbang",      Callback = function(v) end })
OverlaysBox:CreateToggle({ Name = "Hide Burn Effect",       CurrentValue = false, Flag = "NoBurnEffect",     Callback = function(v) end })
OverlaysBox:CreateToggle({ Name = "Hide ADS Vignette",      CurrentValue = false, Flag = "NoAdsVignette",    Callback = function(v) end })
OverlaysBox:CreateToggle({ Name = "Hide Scope Overlay",     CurrentValue = false, Flag = "NoScopeOverlay",   Callback = function(v) end })
OverlaysBox:CreateToggle({ Name = "Hide Scope Reticle",     CurrentValue = false, Flag = "NoScopeReticle",   Callback = function(v) end })
OverlaysBox:CreateToggle({ Name = "Hide Hitmarker",         CurrentValue = false, Flag = "NoHitmarker",      Callback = function(v) end })

local StretchBox = CameraTab:AddRightGroupbox({ Name = "Stretched Resolution", Icon = "maximize" })
StretchBox:CreateToggle({
    Name = "Enable Stretched Resolution", CurrentValue = false, Flag = "StretchEnabled",
    Callback = function(v) end,
})
StretchBox:CreateSlider({ Name = "X Scale", Range = { 0.01, 1 }, Increment = 0.01, CurrentValue = 1, Flag = "StretchX", Callback = function(v) end })
StretchBox:CreateSlider({ Name = "Y Scale", Range = { 0.01, 1 }, Increment = 0.01, CurrentValue = 1, Flag = "StretchY", Callback = function(v) end })

---- Sound ESP ---------------------------------------------------------------
local SoundEspTab  = VisualsTab:CreateTab({ Name = "Sound ESP", Icon = "volume-2" })
local SoundEspBox  = SoundEspTab:AddLeftGroupbox({ Name = "Sound ESP", Icon = "radio" })
SoundEspBox:CreateToggle({
    Name = "Enable Sound ESP", CurrentValue = false, Flag = "SoundEspEnabled",
    Callback = function(v) end,
})
SoundEspBox:CreateSlider({
    Name = "Max Distance", Range = { 10, 500 }, Increment = 10,
    CurrentValue = 100, Flag = "SoundEspMaxDistance", Callback = function(v) end,
})


-- ═══════════════════════════════════════════════════════════════════════════
--  PLAYER TAB
--   Sub-tabs: Movement · Character · Identity Spoofing
-- ═══════════════════════════════════════════════════════════════════════════

---- Movement ----------------------------------------------------------------
local MovementTab   = PlayerTab:CreateTab({ Name = "Movement", Icon = "navigation" })
local GroundBox     = MovementTab:AddLeftGroupbox({ Name = "Ground", Icon = "grid" })
GroundBox:CreateToggle({
    Name = "Walk Speed", CurrentValue = false, Flag = "MoveWalkSpeedEnabled",
    Callback = function(v) end,
})
GroundBox:CreateDropdown({
    Name = "Walk Speed Mode", Options = { "Always", "Toggle", "Hold" },
    CurrentOption = "Always", Flag = "MoveWalkSpeedMode", Callback = function(v) end,
})
GroundBox:CreateSlider({
    Name = "Walk Speed Multiplier", Range = { 1, 10 }, Increment = 0.01,
    CurrentValue = 1.5, Flag = "MoveWalkSpeedMultiplier", Callback = function(v) end,
})
GroundBox:CreateToggle({
    Name = "Sliding", CurrentValue = false, Flag = "MoveSlidingEnabled",
    Callback = function(v) end,
})
GroundBox:CreateSlider({
    Name = "Slide Multiplier", Range = { 1, 10 }, Increment = 0.01,
    CurrentValue = 1.5, Flag = "MoveSlidingMultiplier", Callback = function(v) end,
})
GroundBox:CreateToggle({
    Name = "Noclip", CurrentValue = false, Flag = "MoveNoclipEnabled",
    Callback = function(v) end,
})
GroundBox:CreateDropdown({
    Name = "Noclip Mode", Options = { "Always", "Toggle", "Hold" },
    CurrentOption = "Toggle", Flag = "MoveNoclipMode", Callback = function(v) end,
})
GroundBox:CreateToggle({
    Name = "Auto Strafe", CurrentValue = false, Flag = "MoveAutoStrafeEnabled",
    Callback = function(v) end,
})
GroundBox:CreateSlider({
    Name = "Auto Strafe Speed", Range = { 1, 200 }, Increment = 1,
    CurrentValue = 50, Flag = "MoveAutoStrafeSpeed", Callback = function(v) end,
})

local AirBox = MovementTab:AddRightGroupbox({ Name = "Air", Icon = "wind" })
AirBox:CreateToggle({
    Name = "Jump Power", CurrentValue = false, Flag = "MoveJumpPowerEnabled",
    Callback = function(v) end,
})
AirBox:CreateSlider({
    Name = "Jump Power Multiplier", Range = { 0.1, 10 }, Increment = 0.01,
    CurrentValue = 1.5, Flag = "MoveJumpPowerMultiplier", Callback = function(v) end,
})
AirBox:CreateToggle({
    Name = "Flight", CurrentValue = false, Flag = "MoveFlightEnabled",
    Callback = function(v) end,
})
AirBox:CreateDropdown({
    Name = "Flight Mode", Options = { "Always", "Toggle", "Hold" },
    CurrentOption = "Toggle", Flag = "MoveFlightMode", Callback = function(v) end,
})
AirBox:CreateSlider({
    Name = "Flight Speed", Range = { 25, 500 }, Increment = 1,
    CurrentValue = 80, Flag = "MoveFlightSpeed", Callback = function(v) end,
})
AirBox:CreateToggle({
    Name = "Infinite Double Jumps", CurrentValue = false, Flag = "MoveInfiniteDoubleJumps",
    Callback = function(v) end,
})
AirBox:CreateToggle({
    Name = "Long Jump", CurrentValue = false, Flag = "MoveLongJumpEnabled",
    Callback = function(v) end,
})
AirBox:CreateDropdown({
    Name = "Long Jump Mode", Options = { "Under Feet", "Camera Look" },
    CurrentOption = "Under Feet", Flag = "MoveLongJumpMode", Callback = function(v) end,
})
AirBox:CreateSlider({
    Name = "Long Jump Force", Range = { 0, 300 }, Increment = 1,
    CurrentValue = 100, Flag = "MoveLongJumpForce", Callback = function(v) end,
})
AirBox:CreateSlider({
    Name = "Upward Velocity", Range = { 0, 200 }, Increment = 1,
    CurrentValue = 50, Flag = "MoveLongJumpUpward", Callback = function(v) end,
})

---- Character ---------------------------------------------------------------
local CharacterTab   = PlayerTab:CreateTab({ Name = "Character", Icon = "user" })
local CharAnimBox    = CharacterTab:AddLeftGroupbox({ Name = "Animations", Icon = "activity" })
CharAnimBox:CreateToggle({
    Name = "Animation Spoof", CurrentValue = false, Flag = "AnimSpoof",
    Callback = function(v) end,
})

---- Identity Spoofing -------------------------------------------------------
local IdentityTab    = PlayerTab:CreateTab({ Name = "Identity Spoofing", Icon = "user-check" })
local DeviceSpoofBox = IdentityTab:AddLeftGroupbox({ Name = "Device Spoof", Icon = "smartphone" })
DeviceSpoofBox:CreateToggle({
    Name = "Enable Device Spoof", CurrentValue = false, Flag = "DeviceSpoofEnabled",
    Callback = function(v) end,
})
DeviceSpoofBox:CreateDropdown({
    Name = "Presented Platform", Options = { "MouseKeyboard", "Touch", "Gamepad", "VR" },
    CurrentOption = "MouseKeyboard", Flag = "DeviceSpoofType", Callback = function(v) end,
})

local PlayerSpoofBox = IdentityTab:AddRightGroupbox({ Name = "Player Spoof", Icon = "user-x" })
PlayerSpoofBox:CreateToggle({
    Name = "Spoof Name",         CurrentValue = false, Flag = "PSpoofName",        Callback = function(v) end,
})
PlayerSpoofBox:CreateToggle({
    Name = "Spoof Display Name", CurrentValue = false, Flag = "PSpoofDisplayName", Callback = function(v) end,
})
PlayerSpoofBox:CreateToggle({
    Name = "Spoof Level",        CurrentValue = false, Flag = "PSpoofLevel",       Callback = function(v) end,
})
PlayerSpoofBox:CreateToggle({
    Name = "Spoof Winstreak",    CurrentValue = false, Flag = "PSpoofWinstreak",   Callback = function(v) end,
})
PlayerSpoofBox:CreateToggle({
    Name = "Spoof Ranked ELO",   CurrentValue = false, Flag = "PSpoofRankedElo",   Callback = function(v) end,
})
PlayerSpoofBox:CreateToggle({
    Name = "Influencer",         CurrentValue = false, Flag = "PSpoofInfluencer",  Callback = function(v) end,
})
PlayerSpoofBox:CreateToggle({
    Name = "Roblox Employee",    CurrentValue = false, Flag = "PSpoofRblxEmployee",Callback = function(v) end,
})


-- ═══════════════════════════════════════════════════════════════════════════
--  WORLD TAB
--   Sub-tabs: Lighting · Post Processing · Sky & Weather
-- ═══════════════════════════════════════════════════════════════════════════

---- Lighting ----------------------------------------------------------------
local LightingTab    = WorldTab:CreateTab({ Name = "Lighting", Icon = "sun" })
local LightMasterBox = LightingTab:AddLeftGroupbox({ Name = "Lighting Override", Icon = "toggle-left" })
LightMasterBox:CreateToggle({
    Name = "Enable Lighting Override", CurrentValue = false, Flag = "LightingEnabled",
    Callback = function(v) end,
})

local TimeExpBox = LightingTab:AddLeftGroupbox({ Name = "Time & Exposure", Icon = "clock" })
TimeExpBox:CreateToggle({ Name = "Clock Time",              CurrentValue = false, Flag = "LightClockEnabled",    Callback = function(v) end })
TimeExpBox:CreateSlider({ Name = "Time",                    Range = {0,24},       Increment = 0.01, CurrentValue = 12,  Flag = "LightClockValue",       Callback = function(v) end })
TimeExpBox:CreateToggle({ Name = "Geographic Latitude",     CurrentValue = false, Flag = "LightLatEnabled",      Callback = function(v) end })
TimeExpBox:CreateSlider({ Name = "Latitude",                Range = {-90,90},     Increment = 0.001,CurrentValue = 0,   Flag = "LightLatValue",         Callback = function(v) end })
TimeExpBox:CreateToggle({ Name = "Brightness",              CurrentValue = false, Flag = "LightBrightnessEnabled",Callback = function(v) end })
TimeExpBox:CreateSlider({ Name = "Brightness",              Range = {0,10},       Increment = 0.01, CurrentValue = 2,  Flag = "LightBrightnessValue",  Callback = function(v) end })
TimeExpBox:CreateToggle({ Name = "Exposure Compensation",   CurrentValue = false, Flag = "LightExposureEnabled", Callback = function(v) end })
TimeExpBox:CreateSlider({ Name = "Exposure",                Range = {-5,5},       Increment = 0.01, CurrentValue = 0,  Flag = "LightExposureValue",    Callback = function(v) end })

local ShadowsBox = LightingTab:AddRightGroupbox({ Name = "Shadows & Quality", Icon = "layers" })
ShadowsBox:CreateToggle({ Name = "Disable Global Shadows",      CurrentValue = false, Flag = "LightNoGlobalShadows",   Callback = function(v) end })
ShadowsBox:CreateToggle({ Name = "Shadow Softness",             CurrentValue = false, Flag = "LightShadowSoftEnabled", Callback = function(v) end })
ShadowsBox:CreateSlider({ Name = "Softness", Range = {0,1},     Increment = 0.01, CurrentValue = 0.5, Flag = "LightShadowSoftValue", Callback = function(v) end })
ShadowsBox:CreateToggle({ Name = "Lighting Style",              CurrentValue = false, Flag = "LightStyleEnabled",      Callback = function(v) end })
ShadowsBox:CreateDropdown({ Name = "Style", Options = { "Realistic", "Soft" }, CurrentOption = "Soft", Flag = "LightStyleValue", Callback = function(v) end })
ShadowsBox:CreateToggle({ Name = "Prioritize Lighting Quality", CurrentValue = false, Flag = "LightPrioritizeQuality", Callback = function(v) end })

---- Post Processing ---------------------------------------------------------
local PostTab    = WorldTab:CreateTab({ Name = "Post Processing", Icon = "sliders-horizontal" })
local ToneBox    = PostTab:AddLeftGroupbox({ Name = "Tone & Color", Icon = "palette" })

ToneBox:CreateToggle({ Name = "Color Correction",   CurrentValue = false, Flag = "ColorCorrEnabled",   Callback = function(v) end })
ToneBox:CreateSlider({ Name = "Saturation",  Range = {-1,1},   Increment = 0.01, CurrentValue = 0, Flag = "ColorCorrSat",   Callback = function(v) end })
ToneBox:CreateSlider({ Name = "Brightness",  Range = {-1,1},   Increment = 0.01, CurrentValue = 0, Flag = "ColorCorrBri",   Callback = function(v) end })
ToneBox:CreateSlider({ Name = "Contrast",    Range = {-1,1},   Increment = 0.01, CurrentValue = 0, Flag = "ColorCorrCon",   Callback = function(v) end })
ToneBox:CreateToggle({ Name = "Color Grading",      CurrentValue = false, Flag = "ColorGradEnabled",   Callback = function(v) end })
ToneBox:CreateDropdown({ Name = "Preset", Options = { "Default", "Retro" }, CurrentOption = "Default", Flag = "ColorGradPreset", Callback = function(v) end })

local FocusBox = PostTab:AddRightGroupbox({ Name = "Focus & Motion", Icon = "camera" })
FocusBox:CreateToggle({ Name = "Depth of Field",    CurrentValue = false, Flag = "DofEnabled",         Callback = function(v) end })
FocusBox:CreateSlider({ Name = "Far Intensity",   Range = {0,1},   Increment = 0.01, CurrentValue = 0.5,  Flag = "DofFarIntensity",  Callback = function(v) end })
FocusBox:CreateSlider({ Name = "Focus Distance",  Range = {0,1000},Increment = 1,    CurrentValue = 50,   Flag = "DofFocusDist",     Callback = function(v) end })
FocusBox:CreateSlider({ Name = "In Focus Radius", Range = {0,500}, Increment = 1,    CurrentValue = 30,   Flag = "DofInFocusRadius", Callback = function(v) end })
FocusBox:CreateSlider({ Name = "Near Intensity",  Range = {0,1},   Increment = 0.01, CurrentValue = 0,    Flag = "DofNearIntensity", Callback = function(v) end })
FocusBox:CreateToggle({ Name = "Motion Blur",       CurrentValue = false, Flag = "MotionBlurEnabled",   Callback = function(v) end })
FocusBox:CreateSlider({ Name = "Blur Intensity",  Range = {0,56},  Increment = 0.01, CurrentValue = 0.3,  Flag = "MotionBlurIntens",   Callback = function(v) end })
FocusBox:CreateSlider({ Name = "Blur Sensitivity",Range = {0,5},   Increment = 0.01, CurrentValue = 0.5,  Flag = "MotionBlurSens",     Callback = function(v) end })

local LightFxBox = PostTab:AddLeftGroupbox({ Name = "Light Effects", Icon = "sparkles" })
LightFxBox:CreateToggle({ Name = "Bloom",     CurrentValue = false, Flag = "BloomEnabled",    Callback = function(v) end })
LightFxBox:CreateSlider({ Name = "Intensity",  Range = {0,1},  Increment = 0.01, CurrentValue = 0.5,  Flag = "BloomIntensity",  Callback = function(v) end })
LightFxBox:CreateSlider({ Name = "Size",       Range = {0,56}, Increment = 1,    CurrentValue = 24,   Flag = "BloomSize",       Callback = function(v) end })
LightFxBox:CreateSlider({ Name = "Threshold",  Range = {0,5},  Increment = 0.01, CurrentValue = 1,    Flag = "BloomThreshold",  Callback = function(v) end })
LightFxBox:CreateToggle({ Name = "Sun Rays",  CurrentValue = false, Flag = "SunRaysEnabled",  Callback = function(v) end })
LightFxBox:CreateSlider({ Name = "Rays Intensity", Range = {0,1}, Increment = 0.01, CurrentValue = 0.5, Flag = "SunRaysIntens",  Callback = function(v) end })
LightFxBox:CreateSlider({ Name = "Rays Spread",    Range = {0,1}, Increment = 0.01, CurrentValue = 0.5, Flag = "SunRaysSpread",  Callback = function(v) end })

---- Sky & Weather -----------------------------------------------------------
local SkyTab     = WorldTab:CreateTab({ Name = "Sky & Weather", Icon = "cloud" })
local SkyboxBox  = SkyTab:AddLeftGroupbox({ Name = "Skybox", Icon = "image" })
SkyboxBox:CreateToggle({
    Name = "Enable Skybox", CurrentValue = false, Flag = "SkyboxEnabled",
    Callback = function(v) end,
})
SkyboxBox:CreateDropdown({
    Name = "Preset", Options = { "Default" },
    CurrentOption = "Default", Flag = "SkyboxPreset", Callback = function(v) end,
})

local AmbSoundBox = SkyTab:AddRightGroupbox({ Name = "Ambient Sound", Icon = "volume-1" })
AmbSoundBox:CreateToggle({
    Name = "Enable Ambient Sound", CurrentValue = false, Flag = "AmbienceEnabled",
    Callback = function(v) end,
})
AmbSoundBox:CreateDropdown({
    Name = "Preset", Options = { "Rain", "Forest", "Wind", "Ocean" },
    CurrentOption = "Rain", Flag = "AmbienceSound", Callback = function(v) end,
})
AmbSoundBox:CreateSlider({
    Name = "Volume", Range = { 0, 10 }, Increment = 0.01,
    CurrentValue = 1, Flag = "AmbienceVolume", Callback = function(v) end,
})

local WeatherBox = SkyTab:AddLeftGroupbox({ Name = "Weather", Icon = "cloud-rain" })
WeatherBox:CreateToggle({
    Name = "Enable Weather", CurrentValue = false, Flag = "WeatherEnabled",
    Callback = function(v) end,
})
WeatherBox:CreateDropdown({
    Name = "Preset", Options = { "Snow", "Rain", "Blizzard" },
    CurrentOption = "Rain", Flag = "WeatherPreset", Callback = function(v) end,
})
WeatherBox:CreateSlider({ Name = "Intensity", Range = {0,2},   Increment = 0.01, CurrentValue = 1,   Flag = "WeatherIntensity", Callback = function(v) end })
WeatherBox:CreateSlider({ Name = "Height",    Range = {10,100},Increment = 1,    CurrentValue = 60,  Flag = "WeatherHeight",    Callback = function(v) end })
WeatherBox:CreateSlider({ Name = "Speed",     Range = {0.5,3}, Increment = 0.01, CurrentValue = 1,   Flag = "WeatherSpeed",     Callback = function(v) end })
WeatherBox:CreateSlider({ Name = "Wind Strength", Range = {0,20}, Increment = 0.1, CurrentValue = 5, Flag = "WeatherWindStr",   Callback = function(v) end })
WeatherBox:CreateSlider({ Name = "Wind Angle",    Range = {0,360},Increment = 1,   CurrentValue = 0, Flag = "WeatherWindAngle", Callback = function(v) end })

local LightningBox = SkyTab:AddRightGroupbox({ Name = "Lightning", Icon = "zap" })
LightningBox:CreateToggle({
    Name = "Enable Lightning", CurrentValue = false, Flag = "LightningEnabled",
    Callback = function(v) end,
})
LightningBox:CreateSlider({ Name = "Interval (s)",   Range = {0.2,10}, Increment = 0.1, CurrentValue = 3,   Flag = "LightningInterval",  Callback = function(v) end })
LightningBox:CreateSlider({ Name = "Distance",       Range = {10,200}, Increment = 1,   CurrentValue = 80,  Flag = "LightningDistance",  Callback = function(v) end })
LightningBox:CreateSlider({ Name = "Height",         Range = {50,400}, Increment = 1,   CurrentValue = 200, Flag = "LightningHeight",    Callback = function(v) end })
LightningBox:CreateSlider({ Name = "Thickness",      Range = {0.5,12}, Increment = 0.1, CurrentValue = 2,   Flag = "LightningThickness", Callback = function(v) end })
LightningBox:CreateSlider({ Name = "Jaggedness",     Range = {0,20},   Increment = 0.1, CurrentValue = 8,   Flag = "LightningJagged",    Callback = function(v) end })
LightningBox:CreateSlider({ Name = "Branches",       Range = {0,24},   Increment = 1,   CurrentValue = 4,   Flag = "LightningBranches",  Callback = function(v) end })
LightningBox:CreateSlider({ Name = "Flash",          Range = {0,20},   Increment = 0.1, CurrentValue = 5,   Flag = "LightningFlash",     Callback = function(v) end })
LightningBox:CreateToggle({ Name = "Thunder Sound",  CurrentValue = false, Flag = "LightningThunderEnabled", Callback = function(v) end })
LightningBox:CreateSlider({ Name = "Thunder Volume", Range = {0,3},   Increment = 0.05, CurrentValue = 1,   Flag = "LightningThunderVol",Callback = function(v) end })
LightningBox:CreateToggle({ Name = "Thunder Delay",  CurrentValue = true,  Flag = "LightningThunderDelay",   Callback = function(v) end })


-- ═══════════════════════════════════════════════════════════════════════════
--  SETTINGS TAB
-- ═══════════════════════════════════════════════════════════════════════════

local MenuBox = SettingsTab:AddLeftGroupbox({ Name = "Menu", Icon = "monitor" })
MenuBox:CreateKeybind({
    Name = "Toggle UI",
    CurrentKeybind = "RightShift",
    Flag = "ToggleUIKey",
    Callback = function() end,
    OnChanged = function(key)
        Window:SetKeybind(key)
    end,
})
MenuBox:CreateDropdown({
    Name = "Toggle Button",
    Options = { "Mobile only", "Mobile & PC" },
    CurrentOption = "Mobile only",
    AllowNone = false,
    Flag = "ToggleButtonPlatform",
    Callback = function(option)
        local choice = type(option) == "table" and option[1] or option
        Window:SetToggleButtonPlatform(choice == "Mobile & PC" and "Both" or "Mobile")
    end,
})
MenuBox:CreateToggle({
    Name = "Show Watermark", CurrentValue = true, Flag = "ShowWatermark",
    Callback = function(v) end,
})
MenuBox:CreateButton({
    Name = "Unload Nitrous",
    Icon = "power",
    Callback = function()
        Library:Confirm({
            Title = "Unload?",
            ConfirmText = "Unload",
            Callback = function()
                Window:Destroy()
            end,
        })
    end,
})

SettingsTab:CreateConfigManager({ Name = "Configs", Side = "Left" })
SettingsTab:CreateThemeManager({ Name = "Themes", Side = "Right" })

-- ═══════════════════════════════════════════════════════════════════════════
--  LOAD & NOTIFY
-- ═══════════════════════════════════════════════════════════════════════════

Window:LoadAutoload()

Library:Notify({
    Title   = SCRIPT_NAME,
    Content = "Loaded successfully.",
    Type    = "Success",
    Duration = 3,
})
