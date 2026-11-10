--!nocheck

-- ═══════════════════════════════════════════════════════════════════════════
--  Nitrous — Unified Script Hub
--  Built by Olivia — https://discord.gg/ojailbreaks
-- ═══════════════════════════════════════════════════════════════════════════

if not game:IsLoaded() then game.Loaded:Wait() end

local SCRIPT_NAME    = "Nitrous"
local SCRIPT_VERSION = "v1.0"

-- ── services ─────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ── library load ─────────────────────────────────────────────────────────
local Library, Window
do
    local ok, res = pcall(function()
        local url   = "https://raw.githubusercontent.com/sixfourshi/Games/refs/heads/main/fip?cb=" .. tostring(os.time())
        local chunk = loadstring(game:HttpGet(url))
        if type(chunk) ~= "function" then error("compile: " .. tostring(chunk), 0) end
        local lib = chunk()
        if type(lib) ~= "table" then error("not a table", 0) end
        return lib
    end)
    if not ok then error("UI library: " .. tostring(res), 0) end
    Library = res
end

Library:SetDefaultTheme("Rose")

Window = Library:CreateWindow({
    Name              = SCRIPT_NAME,
    LoadingSubtitle   = SCRIPT_VERSION,
    ToggleUIKeybind   = "RightControl",
    ConfigurationSaving = { Enabled = true, FolderName = "Nitrous", FileName = "default" },
    ToggleButton      = { Platform = "Mobile" },
    Home = {
        Title   = "Welcome to " .. SCRIPT_NAME .. "!",
        Tier    = SCRIPT_VERSION,
        Discord = "https://discord.gg/ojailbreaks",
        Website = "https://example.com",
        Stats   = { "Players", "Session", "FPS", "Ping" },
    },
})

local MainTab         = Window:CreateTab({ Name = "Main",         Icon = "house"             })
local ESPTab          = Window:CreateTab({ Name = "ESP",          Icon = "eye"               })
local RivalsTab       = Window:CreateTab({ Name = "Rivals",       Icon = "sword"             })
local EnhancementsTab = Window:CreateTab({ Name = "Enhancements", Icon = "zap"               })
local ExtraTab        = Window:CreateTab({ Name = "Extra",        Icon = "layers"            })
local SettingsTab     = Window:CreateTab({ Name = "Settings",     Icon = "settings"          })

-- ══════════════════════════════════════════════════════════════════════════
-- ESP STATE
-- ══════════════════════════════════════════════════════════════════════════
local S = {
    Enabled       = false,
    TeamCheck     = false,

    -- box
    Box           = false,
    BoxType       = "Corner",   -- Corner | Full | 3D
    BoxColor      = Color3.fromRGB(255,255,255),
    BoxColorMode  = "Custom",   -- Custom | Team | Health | Rainbow
    BoxThickness  = 1,
    BoxFilled     = false,
    BoxFillTrans  = 0.7,

    -- skeleton
    Skeleton          = false,
    SkeletonColor     = Color3.fromRGB(255,255,255),
    SkeletonColorMode = "Custom",
    SkeletonThickness = 1,

    -- health bar
    HealthBar       = false,
    HealthBarSide   = "Left",   -- Left | Right | Top | Bottom
    HealthBarWidth  = 2,
    HealthBarBG     = true,

    -- name
    Name          = false,
    NameColor     = Color3.fromRGB(255,255,255),
    NameColorMode = "Custom",
    NameSize      = 13,

    -- distance
    Distance      = false,
    DistColor     = Color3.fromRGB(200,200,200),
    DistSize      = 11,
    MaxDistance   = 500,

    -- head dot
    HeadDot        = false,
    HeadDotColor   = Color3.fromRGB(255,80,80),
    HeadDotRadius  = 4,
    HeadDotOutline = true,

    -- tracer
    Tracer          = false,
    TracerOrigin    = "Bottom", -- Bottom | Top | Middle | Mouse
    TracerColor     = Color3.fromRGB(255,255,255),
    TracerColorMode = "Custom",
    TracerThickness = 1,

    -- look vector
    LookVector          = false,
    LookVectorColor     = Color3.fromRGB(255,200,0),
    LookVectorLength    = 50,
    LookVectorThickness = 1,

    -- chams
    Chams             = false,
    ChamsStyle        = "Fill",  -- Fill | Outline | Both
    ChamsColor        = Color3.fromRGB(255,100,100),
    ChamsColorMode    = "Custom",
    ChamsFillTrans    = 0.5,
    ChamsOutlineColor = Color3.fromRGB(255,255,255),
    ChamsOutlineTrans = 0,
    ChamsDepthCheck   = true,

    -- weapon
    Weapon      = false,
    WeaponColor = Color3.fromRGB(255,255,255),
    WeaponSize  = 11,

    -- flags
    Flags      = false,
    FlagsColor = Color3.fromRGB(255,255,255),
    FlagsSize  = 11,

    -- off-screen arrow
    OffScreenArrow  = false,
    OffScreenColor  = Color3.fromRGB(255,255,255),
    OffScreenRadius = 150,
    OffScreenSize   = 20,

    -- visibility check
    VisCheck   = false,
    VisColor   = Color3.fromRGB(0,255,0),
    InvisColor = Color3.fromRGB(255,50,50),

    -- target highlight
    TargetHighlight = false,
    TargetColor     = Color3.fromRGB(255,215,0),
    TargetThickness = 3,
    TargetPlayer    = nil,

    -- misc
    RainbowMode  = false,
    RainbowSpeed = 1,
}

-- ══════════════════════════════════════════════════════════════════════════
-- DRAWING HELPERS
-- ══════════════════════════════════════════════════════════════════════════
local function D(kind, props)
    local d = Drawing.new(kind)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function Hide(d) if d then d.Visible = false end end

local function ResolveColor(custom, mode, hpRatio, player)
    if mode == "Team" then
        local t = player and player.Team
        if t then return t.TeamColor.Color end
    elseif mode == "Health" then
        return Color3.fromHSV((hpRatio or 1) / 3, 1, 1)
    elseif mode == "Rainbow" then
        return Color3.fromHSV((tick() * S.RainbowSpeed * 0.08) % 1, 1, 1)
    end
    return custom
end

local function W2S(pos)
    local sp, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), on, sp.Z
end

-- ══════════════════════════════════════════════════════════════════════════
-- SKELETON BONE MAP
-- ══════════════════════════════════════════════════════════════════════════
local BONES_R6 = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},{"HumanoidRootPart","Torso"},
}
local BONES_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"LowerTorso","HumanoidRootPart"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}

local function GetBones(char)
    if char:FindFirstChild("UpperTorso") then return BONES_R15 end
    return BONES_R6
end

-- ══════════════════════════════════════════════════════════════════════════
-- PER-PLAYER ESP POOL
-- ══════════════════════════════════════════════════════════════════════════
local ESPPool = {}

local MAX_SKELETON_BONES = 15

local function MakePool(player)
    if player == LocalPlayer then return end
    if ESPPool[player] then return end

    local t = {}

    t.FullBox = {}
    for i = 1,4 do
        t.FullBox[i] = D("Square",{Visible=false,Filled=false,Thickness=1,
                                    Color=Color3.new(1,1,1),ZIndex=5})
    end
    t.CornerLines = {}
    for i = 1,8 do
        t.CornerLines[i] = D("Line",{Visible=false,Thickness=1,
                                      Color=Color3.new(1,1,1),ZIndex=5})
    end
    t.DepthLines = {}
    for i = 1,4 do
        t.DepthLines[i] = D("Line",{Visible=false,Thickness=1,
                                     Color=Color3.new(1,1,1),ZIndex=4})
    end

    t.HealthBG   = D("Square",{Visible=false,Filled=true,Thickness=0,
                                Color=Color3.fromRGB(30,30,30),ZIndex=6})
    t.HealthFill = D("Square",{Visible=false,Filled=true,Thickness=0,
                                Color=Color3.fromRGB(80,220,80),ZIndex=7})

    t.SkeletonLines = {}
    for i = 1, MAX_SKELETON_BONES do
        t.SkeletonLines[i] = D("Line",{Visible=false,Thickness=1,
                                        Color=Color3.new(1,1,1),ZIndex=3})
    end

    t.NameText    = D("Text",{Visible=false,Center=true,Outline=true,
                               Size=13,Font=2,Color=Color3.new(1,1,1),ZIndex=8})
    t.DistText    = D("Text",{Visible=false,Center=true,Outline=true,
                               Size=11,Font=1,Color=Color3.new(.8,.8,.8),ZIndex=8})
    t.WeaponText  = D("Text",{Visible=false,Center=true,Outline=true,
                               Size=11,Font=1,Color=Color3.new(1,1,1),ZIndex=8})
    t.FlagsText   = D("Text",{Visible=false,Center=false,Outline=true,
                               Size=11,Font=1,Color=Color3.new(1,1,1),ZIndex=8})

    t.HeadDot = D("Circle",{Visible=false,Filled=true,Thickness=1,
                              NumSides=24,Color=Color3.fromRGB(255,80,80),ZIndex=9})

    t.Tracer = D("Line",{Visible=false,Thickness=1,Color=Color3.new(1,1,1),ZIndex=2})
    t.LookLine = D("Line",{Visible=false,Thickness=1,Color=Color3.fromRGB(255,200,0),ZIndex=6})
    t.OSArrow = D("Triangle",{Visible=false,Filled=true,Color=Color3.new(1,1,1),ZIndex=10})
    t.TargetBox = D("Square",{Visible=false,Filled=false,Thickness=3,
                               Color=Color3.fromRGB(255,215,0),ZIndex=4})

    t.Highlight = Instance.new("SelectionBox")
    t.Highlight.LineThickness       = 0
    t.Highlight.SurfaceTransparency = 1
    t.Highlight.Parent              = workspace

    ESPPool[player] = t

    local conn; conn = player.AncestryChanged:Connect(function()
        if player.Parent then return end
        conn:Disconnect()
        for _, v in pairs(ESPPool[player] or {}) do
            if typeof(v) == "Instance" then
                v:Destroy()
            elseif type(v) == "table" then
                for _, d in pairs(v) do
                    if type(d) == "userdata" then pcall(function() d:Remove() end) end
                end
            else
                pcall(function() v:Remove() end)
            end
        end
        ESPPool[player] = nil
    end)
end

local function HidePool(t)
    for _, v in pairs(t.FullBox)       do Hide(v) end
    for _, v in pairs(t.CornerLines)   do Hide(v) end
    for _, v in pairs(t.DepthLines)    do Hide(v) end
    for _, v in pairs(t.SkeletonLines) do Hide(v) end
    Hide(t.HealthBG)   Hide(t.HealthFill)
    Hide(t.NameText)   Hide(t.DistText)
    Hide(t.WeaponText) Hide(t.FlagsText)
    Hide(t.HeadDot)    Hide(t.Tracer)
    Hide(t.LookLine)   Hide(t.OSArrow)
    Hide(t.TargetBox)
    t.Highlight.Adornee = nil
end

for _, p in ipairs(Players:GetPlayers()) do MakePool(p) end
Players.PlayerAdded:Connect(MakePool)
Players.PlayerRemoving:Connect(function(p)
    ESPPool[p] = nil
end)

-- ══════════════════════════════════════════════════════════════════════════
-- VISIBILITY RAYCAST
-- ══════════════════════════════════════════════════════════════════════════
local RAY_PARAMS = RaycastParams.new()
RAY_PARAMS.FilterType = Enum.RaycastFilterType.Exclude

local function IsVisible(char, origin)
    local head = char:FindFirstChild("Head")
    if not head then return false end
    RAY_PARAMS.FilterDescendantsInstances = { LocalPlayer.Character or workspace }
    local result = workspace:Raycast(origin, (head.Position - origin), RAY_PARAMS)
    if not result then return true end
    return result.Instance:IsDescendantOf(char)
end

-- ══════════════════════════════════════════════════════════════════════════
-- 3D BOX CORNERS
-- ══════════════════════════════════════════════════════════════════════════
local function Get3DCorners(root, head)
    local center = root.Position
    local hw, hh, hd = 1.5, 3.5, 1.0
    local top = head.Position.Y + 0.5
    local bot = top - hh * 2
    return {
        Vector3.new(center.X - hw, top, center.Z - hd),
        Vector3.new(center.X + hw, top, center.Z - hd),
        Vector3.new(center.X + hw, top, center.Z + hd),
        Vector3.new(center.X - hw, top, center.Z + hd),
        Vector3.new(center.X - hw, bot, center.Z - hd),
        Vector3.new(center.X + hw, bot, center.Z - hd),
        Vector3.new(center.X + hw, bot, center.Z + hd),
        Vector3.new(center.X - hw, bot, center.Z + hd),
    }
end

-- ══════════════════════════════════════════════════════════════════════════
-- MAIN RENDER LOOP
-- ══════════════════════════════════════════════════════════════════════════
local VP = Camera.ViewportSize

RunService.RenderStepped:Connect(function()
    VP = Camera.ViewportSize

    if not S.Enabled then
        for _, t in pairs(ESPPool) do HidePool(t) end
        return
    end

    local localChar = LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
    local localPos  = localRoot and localRoot.Position or Vector3.new()
    local mousePos  = UserInputService:GetMouseLocation()

    for player, t in pairs(ESPPool) do
        if not player or not player.Parent then HidePool(t); continue end

        if S.TeamCheck and player.Team == LocalPlayer.Team then
            HidePool(t); continue
        end

        local char = player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if not (char and hum and root and head and hum.Health > 0) then
            HidePool(t); continue
        end

        local dist = (root.Position - localPos).Magnitude
        if dist > S.MaxDistance then HidePool(t); continue end

        local hp      = hum.Health
        local maxHp   = math.max(hum.MaxHealth, 1)
        local hpRatio = hp / maxHp

        local rootS, rootOn  = W2S(root.Position)
        local headS, headOn  = W2S(head.Position + Vector3.new(0, 0.6, 0))
        local footS          = W2S(root.Position - Vector3.new(0, 3.1, 0))

        local charH = math.abs(headS.Y - footS.Y)
        local charW = charH * 0.55
        local bL = rootS.X - charW / 2
        local bT = headS.Y
        local bR = bL + charW
        local bB = bT + charH

        local visible = not S.VisCheck
        if S.VisCheck and localRoot then
            visible = IsVisible(char, localRoot.Position)
        end

        local function BC()  return ResolveColor(S.BoxColor,      S.BoxColorMode,      hpRatio, player) end
        local function SC()  return ResolveColor(S.SkeletonColor, S.SkeletonColorMode, hpRatio, player) end
        local function NC()  return ResolveColor(S.NameColor,     S.NameColorMode,     hpRatio, player) end
        local function TC()  return ResolveColor(S.TracerColor,   S.TracerColorMode,   hpRatio, player) end
        local function CC()  return ResolveColor(S.ChamsColor,    S.ChamsColorMode,    hpRatio, player) end
        local function VC()  return visible and S.VisColor or S.InvisColor end

        local finalBoxColor = S.VisCheck and VC() or BC()

        -- ── BOX ──────────────────────────────────────────────────────────
        if S.Box and rootOn then
            local thick = S.BoxThickness
            local col   = finalBoxColor

            if S.BoxType == "Full" then
                for _, l in ipairs(t.CornerLines) do l.Visible = false end
                for _, l in ipairs(t.DepthLines)  do l.Visible = false end
                local sq = t.FullBox[1]
                sq.Visible     = true
                sq.Color       = col
                sq.Thickness   = thick
                sq.Filled      = S.BoxFilled
                sq.Transparency= S.BoxFilled and (1 - S.BoxFillTrans) or 0
                sq.Position    = Vector2.new(bL, bT)
                sq.Size        = Vector2.new(charW, charH)
                for i = 2,4 do t.FullBox[i].Visible = false end

            elseif S.BoxType == "Corner" then
                for _, sq in ipairs(t.FullBox)    do sq.Visible = false end
                for _, l  in ipairs(t.DepthLines) do l.Visible  = false end
                local cLen = math.clamp(charW * 0.25, 4, 18)
                local function SetLine(ln, x1,y1,x2,y2)
                    ln.Visible = true; ln.Color = col; ln.Thickness = thick
                    ln.From = Vector2.new(x1,y1); ln.To = Vector2.new(x2,y2)
                end
                SetLine(t.CornerLines[1], bL,       bT,        bL+cLen,  bT)
                SetLine(t.CornerLines[2], bL,       bT,        bL,       bT+cLen)
                SetLine(t.CornerLines[3], bR-cLen,  bT,        bR,       bT)
                SetLine(t.CornerLines[4], bR,       bT,        bR,       bT+cLen)
                SetLine(t.CornerLines[5], bL,       bB-cLen,   bL,       bB)
                SetLine(t.CornerLines[6], bL,       bB,        bL+cLen,  bB)
                SetLine(t.CornerLines[7], bR,       bB-cLen,   bR,       bB)
                SetLine(t.CornerLines[8], bR-cLen,  bB,        bR,       bB)

            elseif S.BoxType == "3D" then
                local corners3D = Get3DCorners(root, head)
                local sc = {}
                local allOn = true
                for i, c in ipairs(corners3D) do
                    local s, on = W2S(c)
                    sc[i] = s
                    if not on then allOn = false end
                end
                if allOn then
                    for _, l in ipairs(t.CornerLines) do l.Visible = false end
                    for i = 1,4 do t.FullBox[i].Visible = false end
                    local function SetL3(arr, idx, a, b)
                        arr[idx].Visible   = true
                        arr[idx].Color     = col
                        arr[idx].Thickness = thick
                        arr[idx].From      = sc[a]
                        arr[idx].To        = sc[b]
                    end
                    SetL3(t.CornerLines,1,1,2) SetL3(t.CornerLines,2,2,3)
                    SetL3(t.CornerLines,3,3,4) SetL3(t.CornerLines,4,4,1)
                    SetL3(t.CornerLines,5,5,6) SetL3(t.CornerLines,6,6,7)
                    SetL3(t.CornerLines,7,7,8) SetL3(t.CornerLines,8,8,5)
                    SetL3(t.DepthLines, 1,1,5) SetL3(t.DepthLines, 2,2,6)
                    SetL3(t.DepthLines, 3,3,7) SetL3(t.DepthLines, 4,4,8)
                else
                    for _, l in ipairs(t.FullBox)      do l.Visible = false end
                    for _, l in ipairs(t.CornerLines)  do l.Visible = false end
                    for _, l in ipairs(t.DepthLines)   do l.Visible = false end
                end
            end
        else
            for _, v in ipairs(t.FullBox)     do v.Visible = false end
            for _, v in ipairs(t.CornerLines) do v.Visible = false end
            for _, v in ipairs(t.DepthLines)  do v.Visible = false end
        end

        -- ── HEALTH BAR ───────────────────────────────────────────────────
        if S.HealthBar and rootOn then
            local w     = S.HealthBarWidth
            local side  = S.HealthBarSide
            local hCol  = Color3.fromHSV(hpRatio / 3, 1, 1)
            local bgX,bgY,bgW,bgH, fX,fY,fW,fH

            if side == "Left" then
                bgX,bgY,bgW,bgH = bL-w-2, bT, w, charH
                fX,fY,fW,fH     = bgX, bB - charH*hpRatio, w, charH*hpRatio
            elseif side == "Right" then
                bgX,bgY,bgW,bgH = bR+2, bT, w, charH
                fX,fY,fW,fH     = bgX, bB - charH*hpRatio, w, charH*hpRatio
            elseif side == "Top" then
                bgX,bgY,bgW,bgH = bL, bT-w-2, charW, w
                fX,fY,fW,fH     = bgX, bgY, charW*hpRatio, w
            elseif side == "Bottom" then
                bgX,bgY,bgW,bgH = bL, bB+2, charW, w
                fX,fY,fW,fH     = bgX, bgY, charW*hpRatio, w
            end

            if S.HealthBarBG then
                t.HealthBG.Visible  = true
                t.HealthBG.Position = Vector2.new(bgX, bgY)
                t.HealthBG.Size     = Vector2.new(bgW, bgH)
            else
                t.HealthBG.Visible = false
            end
            t.HealthFill.Visible   = true
            t.HealthFill.Color     = hCol
            t.HealthFill.Position  = Vector2.new(fX, fY)
            t.HealthFill.Size      = Vector2.new(fW, fH)
        else
            Hide(t.HealthBG); Hide(t.HealthFill)
        end

        -- ── SKELETON ─────────────────────────────────────────────────────
        if S.Skeleton then
            local sCol   = SC()
            local sThick = S.SkeletonThickness
            local bones  = GetBones(char)
            local idx    = 0
            for _, pair in ipairs(bones) do
                local pA = char:FindFirstChild(pair[1])
                local pB = char:FindFirstChild(pair[2])
                if pA and pB then
                    local sA, onA = W2S(pA.Position)
                    local sB, onB = W2S(pB.Position)
                    if onA or onB then
                        idx = idx + 1
                        if idx <= MAX_SKELETON_BONES then
                            local ln = t.SkeletonLines[idx]
                            ln.Visible   = true
                            ln.From      = sA
                            ln.To        = sB
                            ln.Color     = sCol
                            ln.Thickness = sThick
                        end
                    end
                end
            end
            for i = idx+1, MAX_SKELETON_BONES do
                t.SkeletonLines[i].Visible = false
            end
        else
            for _, ln in ipairs(t.SkeletonLines) do ln.Visible = false end
        end

        -- ── NAME ─────────────────────────────────────────────────────────
        if S.Name and headOn then
            t.NameText.Visible  = true
            t.NameText.Text     = player.Name
            t.NameText.Color    = NC()
            t.NameText.Size     = S.NameSize
            t.NameText.Position = Vector2.new(rootS.X, bT - S.NameSize - 2)
        else
            Hide(t.NameText)
        end

        -- ── DISTANCE ─────────────────────────────────────────────────────
        local distOffsetY = bB + 3
        if S.Distance and rootOn then
            t.DistText.Visible  = true
            t.DistText.Text     = string.format("[%dm]", math.round(dist))
            t.DistText.Color    = S.DistColor
            t.DistText.Size     = S.DistSize
            t.DistText.Position = Vector2.new(rootS.X, distOffsetY)
            distOffsetY = distOffsetY + S.DistSize + 1
        else
            Hide(t.DistText)
        end

        -- ── WEAPON ───────────────────────────────────────────────────────
        if S.Weapon and rootOn then
            local tool
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Tool") then tool = v.Name; break end
            end
            t.WeaponText.Visible  = true
            t.WeaponText.Text     = "[" .. (tool or "Fists") .. "]"
            t.WeaponText.Color    = S.WeaponColor
            t.WeaponText.Size     = S.WeaponSize
            t.WeaponText.Position = Vector2.new(rootS.X, distOffsetY)
            distOffsetY = distOffsetY + S.WeaponSize + 1
        else
            Hide(t.WeaponText)
        end

        -- ── FLAGS ────────────────────────────────────────────────────────
        if S.Flags and rootOn then
            local flags = {}
            if hum.FloorMaterial == Enum.Material.Air then
                table.insert(flags, "AIR")
            end
            if hum.WalkSpeed > 20 then
                table.insert(flags, "SPRINT")
            end
            if hum.SeatPart then
                table.insert(flags, "SEATED")
            end
            local tool
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Tool") then tool = v; break end
            end
            if tool and tool:FindFirstChildOfClass("Script") then
                table.insert(flags, "ARMED")
            end
            if #flags > 0 then
                t.FlagsText.Visible  = true
                t.FlagsText.Text     = table.concat(flags, " | ")
                t.FlagsText.Color    = S.FlagsColor
                t.FlagsText.Size     = S.FlagsSize
                t.FlagsText.Position = Vector2.new(bL, distOffsetY)
            else
                Hide(t.FlagsText)
            end
        else
            Hide(t.FlagsText)
        end

        -- ── HEAD DOT ─────────────────────────────────────────────────────
        if S.HeadDot and headOn then
            t.HeadDot.Visible   = true
            t.HeadDot.Position  = Vector2.new(headS.X, headS.Y)
            t.HeadDot.Radius    = S.HeadDotRadius
            t.HeadDot.Color     = S.HeadDotColor
            t.HeadDot.Filled    = true
            t.HeadDot.Thickness = S.HeadDotOutline and 1 or 0
        else
            Hide(t.HeadDot)
        end

        -- ── TRACER ───────────────────────────────────────────────────────
        if S.Tracer and rootOn then
            local origin
            if S.TracerOrigin == "Top" then
                origin = Vector2.new(VP.X/2, 0)
            elseif S.TracerOrigin == "Middle" then
                origin = Vector2.new(VP.X/2, VP.Y/2)
            elseif S.TracerOrigin == "Mouse" then
                origin = mousePos
            else
                origin = Vector2.new(VP.X/2, VP.Y)
            end
            t.Tracer.Visible   = true
            t.Tracer.From      = origin
            t.Tracer.To        = Vector2.new(rootS.X, rootS.Y)
            t.Tracer.Color     = TC()
            t.Tracer.Thickness = S.TracerThickness
        else
            Hide(t.Tracer)
        end

        -- ── LOOK VECTOR ──────────────────────────────────────────────────
        if S.LookVector and headOn then
            local lookEnd    = head.Position + head.CFrame.LookVector * S.LookVectorLength
            local lookS, lOn = W2S(lookEnd)
            if lOn then
                t.LookLine.Visible   = true
                t.LookLine.From      = headS
                t.LookLine.To        = lookS
                t.LookLine.Color     = S.LookVectorColor
                t.LookLine.Thickness = S.LookVectorThickness
            else
                Hide(t.LookLine)
            end
        else
            Hide(t.LookLine)
        end

        -- ── OFF-SCREEN ARROW ─────────────────────────────────────────────
        if S.OffScreenArrow and not rootOn then
            local dir     = (root.Position - Camera.CFrame.Position)
            local camDir  = Camera.CFrame:VectorToObjectSpace(dir)
            local angle   = math.atan2(camDir.X, -camDir.Y)
            local cx, cy  = VP.X/2, VP.Y/2
            local r       = S.OffScreenRadius
            local px      = cx + math.sin(angle) * r
            local py      = cy - math.cos(angle) * r
            local sz      = S.OffScreenSize
            local cos_a   = math.cos(angle)
            local sin_a   = math.sin(angle)
            t.OSArrow.Visible = true
            t.OSArrow.Color   = S.OffScreenColor
            t.OSArrow.Filled  = true
            t.OSArrow.PointA  = Vector2.new(px + sin_a*sz,            py - cos_a*sz)
            t.OSArrow.PointB  = Vector2.new(px - cos_a*sz/2 - sin_a*sz/2,
                                             py - sin_a*sz/2 + cos_a*sz/2)
            t.OSArrow.PointC  = Vector2.new(px + cos_a*sz/2 - sin_a*sz/2,
                                             py + sin_a*sz/2 + cos_a*sz/2)
        else
            Hide(t.OSArrow)
        end

        -- ── TARGET HIGHLIGHT ─────────────────────────────────────────────
        if S.TargetHighlight and rootOn and S.TargetPlayer == player then
            t.TargetBox.Visible   = true
            t.TargetBox.Color     = S.TargetColor
            t.TargetBox.Thickness = S.TargetThickness
            t.TargetBox.Position  = Vector2.new(bL - 2, bT - 2)
            t.TargetBox.Size      = Vector2.new(charW + 4, charH + 4)
            t.TargetBox.Filled    = false
        else
            Hide(t.TargetBox)
        end

        -- ── CHAMS ────────────────────────────────────────────────────────
        if S.Chams then
            local cCol = CC()
            t.Highlight.Adornee = char

            if S.ChamsStyle == "Fill" or S.ChamsStyle == "Both" then
                t.Highlight.SurfaceColor3       = cCol
                t.Highlight.SurfaceTransparency = S.ChamsFillTrans
            else
                t.Highlight.SurfaceTransparency = 1
            end

            if S.ChamsStyle == "Outline" or S.ChamsStyle == "Both" then
                t.Highlight.Color3        = S.ChamsOutlineColor
                t.Highlight.LineThickness = S.BoxThickness
            else
                t.Highlight.LineThickness = 0
            end

            if not S.ChamsDepthCheck then
                t.Highlight.LineThickness = math.max(S.BoxThickness, 1)
            end
        else
            t.Highlight.Adornee = nil
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════════
-- ESP PREVIEW
-- ══════════════════════════════════════════════════════════════════════════
local PreviewGui = nil

local function BuildPreview()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("NitrousESPPreview")
    if gui then gui:Destroy() end

    local SG = Instance.new("ScreenGui")
    SG.Name           = "NitrousESPPreview"
    SG.ResetOnSpawn   = false
    SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    SG.DisplayOrder   = 999
    SG.Parent         = LocalPlayer.PlayerGui

    local Frame = Instance.new("Frame")
    Frame.Name              = "PF"
    Frame.Size              = UDim2.new(0, 220, 0, 325)
    Frame.Position          = UDim2.new(0.5,-110,0.5,-162)
    Frame.BackgroundColor3  = Color3.fromRGB(14,14,20)
    Frame.BorderSizePixel   = 0
    Frame.ClipsDescendants  = true
    Frame.Parent            = SG
    local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(0,8); c1.Parent = Frame
    local sk = Instance.new("UIStroke"); sk.Color = Color3.fromRGB(70,70,100); sk.Thickness = 1; sk.Parent = Frame

    local TB = Instance.new("Frame")
    TB.Size = UDim2.new(1,0,0,24); TB.BackgroundColor3 = Color3.fromRGB(22,22,32)
    TB.BorderSizePixel = 0; TB.Parent = Frame
    local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0,8); c2.Parent = TB

    local TL = Instance.new("TextLabel")
    TL.Size = UDim2.new(1,-30,1,0); TL.Position = UDim2.new(0,8,0,0)
    TL.BackgroundTransparency = 1; TL.Text = "Nitrous ESP Preview"
    TL.TextColor3 = Color3.fromRGB(190,190,210); TL.TextSize = 11
    TL.Font = Enum.Font.GothamBold; TL.TextXAlignment = Enum.TextXAlignment.Left
    TL.Parent = TB

    local CB = Instance.new("TextButton")
    CB.Size = UDim2.new(0,20,0,20); CB.Position = UDim2.new(1,-22,0,2)
    CB.BackgroundColor3 = Color3.fromRGB(170,50,50); CB.Text = "×"
    CB.TextColor3 = Color3.fromRGB(255,255,255); CB.TextSize = 14
    CB.Font = Enum.Font.GothamBold; CB.BorderSizePixel = 0; CB.Parent = TB
    local c3 = Instance.new("UICorner"); c3.CornerRadius = UDim.new(0,4); c3.Parent = CB

    local VF = Instance.new("ViewportFrame")
    VF.Name = "VP"; VF.Size = UDim2.new(1,-16,0,205)
    VF.Position = UDim2.new(0,8,0,30)
    VF.BackgroundColor3 = Color3.fromRGB(8,8,13)
    VF.BorderSizePixel  = 0
    VF.LightDirection   = Vector3.new(-1,-1,-1)
    VF.LightColor       = Color3.fromRGB(220,220,255)
    VF.Ambient          = Color3.fromRGB(80,80,110)
    VF.Parent           = Frame
    local c4 = Instance.new("UICorner"); c4.CornerRadius = UDim.new(0,6); c4.Parent = VF

    local AvatarClone
    local lChar = LocalPlayer.Character
    if lChar then
        AvatarClone = lChar:Clone()
        for _, v in ipairs(AvatarClone:GetDescendants()) do
            if v:IsA("Script") or v:IsA("LocalScript")
            or v:IsA("ParticleEmitter") or v:IsA("Trail")
            or v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
                v:Destroy()
            end
        end
        local pr = AvatarClone.PrimaryPart or AvatarClone:FindFirstChild("HumanoidRootPart")
        if pr then AvatarClone:SetPrimaryPartCFrame(CFrame.new(0,0,0)) end
        AvatarClone.Parent = VF
    end

    local VC = Instance.new("Camera")
    VC.FieldOfView   = 48
    VF.CurrentCamera = VC
    VC.Parent        = VF

    local ChamsOL = Instance.new("Frame")
    ChamsOL.Size = UDim2.new(1,0,1,0); ChamsOL.BackgroundTransparency = 1
    ChamsOL.BorderSizePixel = 0; ChamsOL.ZIndex = 3
    local c5 = Instance.new("UICorner"); c5.CornerRadius = UDim.new(0,6); c5.Parent = ChamsOL
    ChamsOL.Parent = VF

    local Canvas = Instance.new("Frame")
    Canvas.Name = "Canvas"; Canvas.Size = UDim2.new(1,-16,0,205)
    Canvas.Position = UDim2.new(0,8,0,30)
    Canvas.BackgroundTransparency = 1; Canvas.BorderSizePixel = 0
    Canvas.ZIndex = 5; Canvas.ClipsDescendants = false; Canvas.Parent = Frame

    local function FR(parent, bgc, zi)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = bgc or Color3.new(1,1,1)
        f.BorderSizePixel  = 0
        f.ZIndex           = zi or 6
        f.Parent           = parent
        return f
    end
    local function TXT(parent, zi)
        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1; t.TextStrokeTransparency = 0.5
        t.ZIndex = zi or 7; t.Parent = parent; return t
    end
    local function SetF(f, x, y, w, h)
        f.Position = UDim2.new(0,x,0,y); f.Size = UDim2.new(0,w,0,h)
    end

    local PCorners = {}
    for i = 1,8 do PCorners[i] = FR(Canvas, Color3.new(1,1,1), 6) end
    local PDepth = {}
    for i = 1,4 do PDepth[i] = FR(Canvas, Color3.new(1,1,1), 5) end
    local PFullBox = FR(Canvas, Color3.new(1,1,1), 6)

    local PHbg  = FR(Canvas, Color3.fromRGB(30,30,30), 6)
    local PHfil = FR(Canvas, Color3.fromRGB(80,220,80), 7)
    local PHdot = FR(Canvas, Color3.fromRGB(255,80,80), 8)
    local c6 = Instance.new("UICorner"); c6.CornerRadius = UDim.new(1,0); c6.Parent = PHdot

    local PTracer = FR(Canvas, Color3.new(1,1,1), 4)
    PTracer.AnchorPoint = Vector2.new(0.5,0)
    local PLook   = FR(Canvas, Color3.fromRGB(255,200,0), 6)
    local PName   = TXT(Canvas, 8)
    local PDist   = TXT(Canvas, 8)
    local PWeapon = TXT(Canvas, 8)
    local PFlags  = TXT(Canvas, 8)

    local InfoF = Instance.new("Frame")
    InfoF.Size = UDim2.new(1,-16,0,72); InfoF.Position = UDim2.new(0,8,0,242)
    InfoF.BackgroundColor3 = Color3.fromRGB(18,18,26); InfoF.BorderSizePixel = 0
    InfoF.ZIndex = 3; InfoF.Parent = Frame
    local c7 = Instance.new("UICorner"); c7.CornerRadius = UDim.new(0,6); c7.Parent = InfoF

    local InfoL = Instance.new("TextLabel")
    InfoL.Size = UDim2.new(1,-10,1,0); InfoL.Position = UDim2.new(0,6,0,0)
    InfoL.BackgroundTransparency = 1; InfoL.TextColor3 = Color3.fromRGB(150,150,180)
    InfoL.TextSize = 10; InfoL.Font = Enum.Font.Gotham
    InfoL.TextXAlignment = Enum.TextXAlignment.Left
    InfoL.TextYAlignment = Enum.TextYAlignment.Center
    InfoL.TextWrapped = true; InfoL.ZIndex = 4; InfoL.Parent = InfoF

    local dragging, dStart, dPos0
    TB.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dStart = inp.Position; dPos0 = Frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
                      or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dStart
            Frame.Position = UDim2.new(dPos0.X.Scale, dPos0.X.Offset+d.X,
                                        dPos0.Y.Scale, dPos0.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    CB.MouseButton1Click:Connect(function() SG:Destroy(); PreviewGui = nil end)

    local rotAngle   = 0
    local renderConn = RunService.Heartbeat:Connect(function(dt)
        if not SG.Parent then return end
        rotAngle = rotAngle + dt * 38
        if AvatarClone and AvatarClone.Parent then
            local pr = AvatarClone:FindFirstChild("HumanoidRootPart")
            if pr then
                local r   = math.rad(rotAngle)
                local cam = pr.Position + Vector3.new(math.sin(r)*7, 1.8, math.cos(r)*7)
                VC.CFrame = CFrame.lookAt(cam, pr.Position + Vector3.new(0,1,0))
            end
        end

        local cW = Canvas.AbsoluteSize.X
        local cH = Canvas.AbsoluteSize.Y
        local padX, padY = 28, 8
        local bL = padX;      local bT = padY + 12
        local bR = cW-padX;   local bB = cH-padY
        local bW = bR-bL;     local bH = bB-bT
        local thick = S.BoxThickness
        local cLen  = math.clamp(bW*0.25, 5, 16)
        local bCol  = S.VisCheck and (S.VisColor) or S.BoxColor
        if S.RainbowMode then bCol = Color3.fromHSV((tick()*S.RainbowSpeed*0.08)%1,1,1) end

        local function HF(f) f.Visible = false end
        for _, f in ipairs(PCorners) do HF(f) end
        for _, f in ipairs(PDepth)   do HF(f) end
        HF(PFullBox); HF(PHbg); HF(PHfil); HF(PHdot); HF(PTracer); HF(PLook)
        HF(PName); HF(PDist); HF(PWeapon); HF(PFlags)

        local esp = S.Enabled

        if esp and S.Box then
            local function LC(f, x1,y1,x2,y2)
                f.Visible = true; f.BackgroundColor3 = bCol
                local dx,dy = x2-x1, y2-y1
                local len = math.sqrt(dx*dx+dy*dy)
                if len < 0.5 then len = 0.5 end
                f.Position = UDim2.new(0,x1,0,y1)
                f.Size = UDim2.new(0,math.abs(dx) > math.abs(dy) and len or thick,
                                    0,math.abs(dy) >= math.abs(dx) and len or thick)
            end
            if S.BoxType == "Corner" then
                LC(PCorners[1],bL,bT,       bL+cLen,bT)
                LC(PCorners[2],bL,bT,       bL,     bT+cLen)
                LC(PCorners[3],bR-cLen,bT,  bR,     bT)
                LC(PCorners[4],bR,bT,       bR,     bT+cLen)
                LC(PCorners[5],bL,bB-cLen,  bL,     bB)
                LC(PCorners[6],bL,bB,       bL+cLen,bB)
                LC(PCorners[7],bR,bB-cLen,  bR,     bB)
                LC(PCorners[8],bR-cLen,bB,  bR,     bB)
            else
                PFullBox.Visible = true; PFullBox.BackgroundColor3 = bCol
                PFullBox.BackgroundTransparency = S.BoxFilled and (1-S.BoxFillTrans) or 1
                SetF(PFullBox, bL, bT, bW, thick)
                LC(PCorners[1],bL,bT,bR,bT)
                LC(PCorners[2],bL,bB,bR,bB)
                LC(PCorners[3],bL,bT,bL,bB)
                LC(PCorners[4],bR,bT,bR,bB)
                for i=5,8 do PCorners[i].Visible=false end
            end
        end

        if esp and S.HealthBar then
            local w = S.HealthBarWidth
            local hp = 1
            local hCol = Color3.fromHSV(hp/3, 1, 1)
            if S.HealthBarSide == "Left" then
                if S.HealthBarBG then SetF(PHbg,bL-w-2,bT,w,bH); PHbg.Visible=true end
                SetF(PHfil, bL-w-2, bB-bH*hp, w, bH*hp); PHfil.Visible=true
            elseif S.HealthBarSide == "Right" then
                if S.HealthBarBG then SetF(PHbg,bR+2,bT,w,bH); PHbg.Visible=true end
                SetF(PHfil, bR+2, bB-bH*hp, w, bH*hp); PHfil.Visible=true
            elseif S.HealthBarSide == "Top" then
                if S.HealthBarBG then SetF(PHbg,bL,bT-w-2,bW,w); PHbg.Visible=true end
                SetF(PHfil, bL, bT-w-2, bW*hp, w); PHfil.Visible=true
            elseif S.HealthBarSide == "Bottom" then
                if S.HealthBarBG then SetF(PHbg,bL,bB+2,bW,w); PHbg.Visible=true end
                SetF(PHfil, bL, bB+2, bW*hp, w); PHfil.Visible=true
            end
            PHfil.BackgroundColor3 = hCol
        end

        if esp and S.HeadDot then
            local r  = S.HeadDotRadius
            local cx = bL+bW/2
            local cy = bT + bH*0.08
            SetF(PHdot, cx-r, cy-r, r*2, r*2)
            PHdot.BackgroundColor3 = S.HeadDotColor
            PHdot.Visible = true
        end

        if esp and S.Tracer then
            local tx, ty = bL+bW/2, bB
            local ox     = cW/2
            local oy     = S.TracerOrigin == "Top" and 0
                        or S.TracerOrigin == "Middle" and cH/2
                        or cH
            local dx, dy = tx-ox, ty-oy
            local len    = math.sqrt(dx*dx+dy*dy)
            if len > 1 then
                PTracer.Visible          = true
                PTracer.BackgroundColor3 = S.TracerColor
                PTracer.Size             = UDim2.new(0,S.TracerThickness,0,len)
                PTracer.Position         = UDim2.new(0,ox,0,oy)
                PTracer.Rotation         = math.deg(math.atan2(dx,dy))
            end
        end

        if esp and S.LookVector then
            local cx = bL+bW/2
            PLook.Visible = true; PLook.BackgroundColor3 = S.LookVectorColor
            SetF(PLook, cx - S.LookVectorThickness/2, bT+bH*0.1, S.LookVectorThickness, 20)
        end

        local textY = bT - 15
        if esp and S.Name then
            PName.Visible = true; PName.Text = LocalPlayer.Name
            PName.TextColor3 = S.NameColor; PName.TextSize = S.NameSize
            SetF(PName, bL, textY, bW, 16)
        end

        local belowY = bB+2
        if esp and S.Distance then
            PDist.Visible = true; PDist.Text = "[42m]"
            PDist.TextColor3 = S.DistColor; PDist.TextSize = S.DistSize
            SetF(PDist, bL, belowY, bW, 14); belowY = belowY + 14
        end

        if esp and S.Weapon then
            PWeapon.Visible = true; PWeapon.Text = "[Tool]"
            PWeapon.TextColor3 = S.WeaponColor; PWeapon.TextSize = S.WeaponSize
            SetF(PWeapon, bL, belowY, bW, 14); belowY = belowY + 14
        end

        if esp and S.Flags then
            PFlags.Visible = true; PFlags.Text = "AIR | SPRINT"
            PFlags.TextColor3 = S.FlagsColor; PFlags.TextSize = S.FlagsSize
            SetF(PFlags, bL, belowY, bW, 14)
        end

        if esp and S.Chams then
            local cCol = S.ChamsColor
            if S.RainbowMode then cCol = Color3.fromHSV((tick()*S.RainbowSpeed*0.08)%1,1,1) end
            if S.ChamsStyle == "Fill" or S.ChamsStyle == "Both" then
                ChamsOL.BackgroundTransparency = S.ChamsFillTrans
                ChamsOL.BackgroundColor3       = cCol
            else
                ChamsOL.BackgroundTransparency = 1
            end
        else
            ChamsOL.BackgroundTransparency = 1
        end

        local active = {}
        if esp              then table.insert(active,"✓ ESP") end
        if esp and S.Box    then table.insert(active,"Box:"..S.BoxType) end
        if esp and S.Skeleton then table.insert(active,"Skel") end
        if esp and S.HealthBar then table.insert(active,"HP:"..S.HealthBarSide) end
        if esp and S.Name   then table.insert(active,"Name") end
        if esp and S.Tracer then table.insert(active,"Tracer") end
        if esp and S.Chams  then table.insert(active,"Chams:"..S.ChamsStyle) end
        if S.RainbowMode    then table.insert(active,"🌈") end

        InfoL.Text = #active > 0 and table.concat(active,"  •  ") or "All ESP off"
    end)

    SG.AncestryChanged:Connect(function()
        if not SG.Parent then renderConn:Disconnect() end
    end)

    return SG
end

-- ══════════════════════════════════════════════════════════════════════════
-- ESP TAB UI
-- ══════════════════════════════════════════════════════════════════════════
local GenGrp    = ESPTab:AddLeftGroupbox({  Name = "General",         Icon = "eye"              })
local BoxGrp    = ESPTab:AddLeftGroupbox({  Name = "Box",             Icon = "box"              })
local NameGrp   = ESPTab:AddLeftGroupbox({  Name = "Name & Distance", Icon = "tag"              })
local HBGrp     = ESPTab:AddLeftGroupbox({  Name = "Health Bar",      Icon = "heart"            })
local SkelGrp   = ESPTab:AddLeftGroupbox({  Name = "Skeleton",        Icon = "git-branch"       })

local HdGrp     = ESPTab:AddRightGroupbox({ Name = "Head Dot",        Icon = "circle"           })
local TrcGrp    = ESPTab:AddRightGroupbox({ Name = "Tracer & Look",   Icon = "arrow-up-right"   })
local ChGrp     = ESPTab:AddRightGroupbox({ Name = "Chams",           Icon = "layers"           })
local MiscGrp   = ESPTab:AddRightGroupbox({ Name = "Misc",            Icon = "settings-2"       })
local PrevGrp   = ESPTab:AddRightGroupbox({ Name = "Preview",         Icon = "monitor"          })

-- General
GenGrp:CreateToggle({ Name="Enable ESP",    CurrentValue=false, Flag="ESPEnabled",
    Callback=function(v) S.Enabled=v end })
GenGrp:CreateToggle({ Name="Team Check",    CurrentValue=false, Flag="ESPTeam",
    Callback=function(v) S.TeamCheck=v end })
GenGrp:CreateToggle({ Name="Rainbow Mode",  CurrentValue=false, Flag="ESPRainbow",
    Callback=function(v) S.RainbowMode=v end })
GenGrp:CreateSlider({ Name="Rainbow Speed", Range={0.1,5}, Increment=0.1, CurrentValue=1,
    Flag="ESPRainbowSpd", Callback=function(v) S.RainbowSpeed=v end })
GenGrp:CreateSlider({ Name="Max Distance",  Range={50,2000}, Increment=50, CurrentValue=500,
    Flag="ESPMaxDist", Callback=function(v) S.MaxDistance=v end })
GenGrp:CreateToggle({ Name="Visibility Check", CurrentValue=false, Flag="ESPVisChk",
    Callback=function(v) S.VisCheck=v end })
GenGrp:CreateColorPicker({ Name="Visible Color",   Default=Color3.fromRGB(0,255,0),   Flag="ESPVisCol",
    Callback=function(v) S.VisColor=v end })
GenGrp:CreateColorPicker({ Name="Invisible Color", Default=Color3.fromRGB(255,50,50), Flag="ESPInvisCol",
    Callback=function(v) S.InvisColor=v end })

-- Box
BoxGrp:CreateToggle({ Name="Show Box", CurrentValue=false, Flag="ESPBox",
    Callback=function(v) S.Box=v end })
BoxGrp:CreateDropdown({ Name="Box Type", Options={"Corner","Full","3D"},
    CurrentOption="Corner", AllowNone=false, Flag="ESPBoxType",
    Callback=function(v) S.BoxType=type(v)=="table" and v[1] or v end })
BoxGrp:CreateDropdown({ Name="Color Mode", Options={"Custom","Team","Health","Rainbow"},
    CurrentOption="Custom", AllowNone=false, Flag="ESPBoxCMode",
    Callback=function(v) S.BoxColorMode=type(v)=="table" and v[1] or v end })
BoxGrp:CreateColorPicker({ Name="Box Color", Default=Color3.fromRGB(255,255,255), Flag="ESPBoxCol",
    Callback=function(v) S.BoxColor=v end })
BoxGrp:CreateSlider({ Name="Thickness", Range={1,5}, Increment=1, CurrentValue=1,
    Flag="ESPBoxThick", Callback=function(v) S.BoxThickness=v end })
BoxGrp:CreateToggle({ Name="Filled", CurrentValue=false, Flag="ESPBoxFilled",
    Callback=function(v) S.BoxFilled=v end })
BoxGrp:CreateSlider({ Name="Fill Transparency", Range={0,1}, Increment=0.05, CurrentValue=0.7,
    Flag="ESPBoxFillTr", Callback=function(v) S.BoxFillTrans=v end })

-- Name & Distance
NameGrp:CreateToggle({ Name="Show Name", CurrentValue=false, Flag="ESPName",
    Callback=function(v) S.Name=v end })
NameGrp:CreateDropdown({ Name="Name Color Mode", Options={"Custom","Team","Health","Rainbow"},
    CurrentOption="Custom", AllowNone=false, Flag="ESPNameCMode",
    Callback=function(v) S.NameColorMode=type(v)=="table" and v[1] or v end })
NameGrp:CreateColorPicker({ Name="Name Color", Default=Color3.fromRGB(255,255,255), Flag="ESPNameCol",
    Callback=function(v) S.NameColor=v end })
NameGrp:CreateSlider({ Name="Name Size", Range={8,24}, Increment=1, CurrentValue=13,
    Flag="ESPNameSz", Callback=function(v) S.NameSize=v end })
NameGrp:CreateToggle({ Name="Show Distance", CurrentValue=false, Flag="ESPDist",
    Callback=function(v) S.Distance=v end })
NameGrp:CreateColorPicker({ Name="Distance Color", Default=Color3.fromRGB(200,200,200), Flag="ESPDistCol",
    Callback=function(v) S.DistColor=v end })
NameGrp:CreateSlider({ Name="Distance Size", Range={8,20}, Increment=1, CurrentValue=11,
    Flag="ESPDistSz", Callback=function(v) S.DistSize=v end })
NameGrp:CreateToggle({ Name="Show Weapon", CurrentValue=false, Flag="ESPWeapon",
    Callback=function(v) S.Weapon=v end })
NameGrp:CreateColorPicker({ Name="Weapon Color", Default=Color3.fromRGB(255,255,255), Flag="ESPWeapCol",
    Callback=function(v) S.WeaponColor=v end })
NameGrp:CreateToggle({ Name="Show Flags", CurrentValue=false, Flag="ESPFlags",
    Callback=function(v) S.Flags=v end })
NameGrp:CreateColorPicker({ Name="Flags Color", Default=Color3.fromRGB(255,255,255), Flag="ESPFlagsCol",
    Callback=function(v) S.FlagsColor=v end })

-- Health Bar
HBGrp:CreateToggle({ Name="Show Health Bar", CurrentValue=false, Flag="ESPHBar",
    Callback=function(v) S.HealthBar=v end })
HBGrp:CreateDropdown({ Name="Bar Side", Options={"Left","Right","Top","Bottom"},
    CurrentOption="Left", AllowNone=false, Flag="ESPHBarSide",
    Callback=function(v) S.HealthBarSide=type(v)=="table" and v[1] or v end })
HBGrp:CreateSlider({ Name="Bar Width", Range={1,6}, Increment=1, CurrentValue=2,
    Flag="ESPHBarW", Callback=function(v) S.HealthBarWidth=v end })
HBGrp:CreateToggle({ Name="Bar Background", CurrentValue=true, Flag="ESPHBarBG",
    Callback=function(v) S.HealthBarBG=v end })

-- Skeleton
SkelGrp:CreateToggle({ Name="Show Skeleton", CurrentValue=false, Flag="ESPSkel",
    Callback=function(v) S.Skeleton=v end })
SkelGrp:CreateDropdown({ Name="Color Mode", Options={"Custom","Team","Health","Rainbow"},
    CurrentOption="Custom", AllowNone=false, Flag="ESPSkelCMode",
    Callback=function(v) S.SkeletonColorMode=type(v)=="table" and v[1] or v end })
SkelGrp:CreateColorPicker({ Name="Skeleton Color", Default=Color3.fromRGB(255,255,255), Flag="ESPSkelCol",
    Callback=function(v) S.SkeletonColor=v end })
SkelGrp:CreateSlider({ Name="Thickness", Range={1,4}, Increment=1, CurrentValue=1,
    Flag="ESPSkelThick", Callback=function(v) S.SkeletonThickness=v end })

-- Head Dot
HdGrp:CreateToggle({ Name="Show Head Dot", CurrentValue=false, Flag="ESPHDot",
    Callback=function(v) S.HeadDot=v end })
HdGrp:CreateColorPicker({ Name="Dot Color", Default=Color3.fromRGB(255,80,80), Flag="ESPHDotCol",
    Callback=function(v) S.HeadDotColor=v end })
HdGrp:CreateSlider({ Name="Dot Radius", Range={2,10}, Increment=1, CurrentValue=4,
    Flag="ESPHDotR", Callback=function(v) S.HeadDotRadius=v end })
HdGrp:CreateToggle({ Name="Dot Outline", CurrentValue=true, Flag="ESPHDotOL",
    Callback=function(v) S.HeadDotOutline=v end })

-- Tracer & Look
TrcGrp:CreateToggle({ Name="Show Tracer", CurrentValue=false, Flag="ESPTracer",
    Callback=function(v) S.Tracer=v end })
TrcGrp:CreateDropdown({ Name="Tracer Origin", Options={"Bottom","Top","Middle","Mouse"},
    CurrentOption="Bottom", AllowNone=false, Flag="ESPTrcOrig",
    Callback=function(v) S.TracerOrigin=type(v)=="table" and v[1] or v end })
TrcGrp:CreateDropdown({ Name="Color Mode", Options={"Custom","Team","Health","Rainbow"},
    CurrentOption="Custom", AllowNone=false, Flag="ESPTrcCMode",
    Callback=function(v) S.TracerColorMode=type(v)=="table" and v[1] or v end })
TrcGrp:CreateColorPicker({ Name="Tracer Color", Default=Color3.fromRGB(255,255,255), Flag="ESPTrcCol",
    Callback=function(v) S.TracerColor=v end })
TrcGrp:CreateSlider({ Name="Tracer Thickness", Range={1,5}, Increment=1, CurrentValue=1,
    Flag="ESPTrcThick", Callback=function(v) S.TracerThickness=v end })
TrcGrp:CreateToggle({ Name="Look Vector", CurrentValue=false, Flag="ESPLook",
    Callback=function(v) S.LookVector=v end })
TrcGrp:CreateColorPicker({ Name="Look Color", Default=Color3.fromRGB(255,200,0), Flag="ESPLookCol",
    Callback=function(v) S.LookVectorColor=v end })
TrcGrp:CreateSlider({ Name="Look Length", Range={10,200}, Increment=5, CurrentValue=50,
    Flag="ESPLookLen", Callback=function(v) S.LookVectorLength=v end })
TrcGrp:CreateSlider({ Name="Look Thickness", Range={1,4}, Increment=1, CurrentValue=1,
    Flag="ESPLookThick", Callback=function(v) S.LookVectorThickness=v end })

-- Chams
ChGrp:CreateToggle({ Name="Enable Chams", CurrentValue=false, Flag="ESPChams",
    Callback=function(v) S.Chams=v end })
ChGrp:CreateDropdown({ Name="Chams Style", Options={"Fill","Outline","Both"},
    CurrentOption="Fill", AllowNone=false, Flag="ESPChamsStyle",
    Callback=function(v) S.ChamsStyle=type(v)=="table" and v[1] or v end })
ChGrp:CreateDropdown({ Name="Color Mode", Options={"Custom","Team","Health","Rainbow"},
    CurrentOption="Custom", AllowNone=false, Flag="ESPChamsCMode",
    Callback=function(v) S.ChamsColorMode=type(v)=="table" and v[1] or v end })
ChGrp:CreateColorPicker({ Name="Fill Color", Default=Color3.fromRGB(255,100,100), Flag="ESPChamsCol",
    Callback=function(v) S.ChamsColor=v end })
ChGrp:CreateSlider({ Name="Fill Transparency", Range={0,1}, Increment=0.05, CurrentValue=0.5,
    Flag="ESPChamsFTr", Callback=function(v) S.ChamsFillTrans=v end })
ChGrp:CreateColorPicker({ Name="Outline Color", Default=Color3.fromRGB(255,255,255), Flag="ESPChamsOCol",
    Callback=function(v) S.ChamsOutlineColor=v end })
ChGrp:CreateToggle({ Name="Depth Check", CurrentValue=true, Flag="ESPChamsDepth",
    Callback=function(v) S.ChamsDepthCheck=v end })

-- Misc
MiscGrp:CreateToggle({ Name="Off-Screen Arrow", CurrentValue=false, Flag="ESPOSArrow",
    Callback=function(v) S.OffScreenArrow=v end })
MiscGrp:CreateColorPicker({ Name="Arrow Color", Default=Color3.fromRGB(255,255,255), Flag="ESPOSACol",
    Callback=function(v) S.OffScreenColor=v end })
MiscGrp:CreateSlider({ Name="Arrow Radius", Range={80,300}, Increment=10, CurrentValue=150,
    Flag="ESPOSARadius", Callback=function(v) S.OffScreenRadius=v end })
MiscGrp:CreateSlider({ Name="Arrow Size", Range={10,40}, Increment=2, CurrentValue=20,
    Flag="ESPOSASize", Callback=function(v) S.OffScreenSize=v end })
MiscGrp:CreateToggle({ Name="Target Highlight", CurrentValue=false, Flag="ESPTgtHL",
    Callback=function(v) S.TargetHighlight=v end })
MiscGrp:CreateColorPicker({ Name="Target Color", Default=Color3.fromRGB(255,215,0), Flag="ESPTgtCol",
    Callback=function(v) S.TargetColor=v end })
MiscGrp:CreateSlider({ Name="Target Thickness", Range={1,6}, Increment=1, CurrentValue=3,
    Flag="ESPTgtThick", Callback=function(v) S.TargetThickness=v end })

-- Preview
PrevGrp:CreateButton({ Name="Toggle Preview", Icon="eye",
    Callback=function()
        if PreviewGui and PreviewGui.Parent then
            PreviewGui:Destroy(); PreviewGui = nil
        else
            PreviewGui = BuildPreview()
        end
    end,
})

-- ══════════════════════════════════════════════════════════════════════════
-- RIVALS TAB (Nitrous-patched Kicia loader)
-- ══════════════════════════════════════════════════════════════════════════
local RivalsGrp = RivalsTab:AddLeftGroupbox({ Name = "Rivals Module", Icon = "sword" })

local rivalsLoaded = false

local function patchAndLoadKicia()
    if rivalsLoaded then
        Library:Notify({ Title=SCRIPT_NAME, Content="Rivals already loaded.", Type="Info", Duration=3 })
        return
    end

    Library:Notify({ Title=SCRIPT_NAME, Content="Loading Rivals module...", Type="Info", Duration=3 })

    local ok, src = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/pafapafa/GameScripts/main/Kicia")
    end)

    if not ok then
        Library:Notify({ Title=SCRIPT_NAME, Content="Network error: " .. tostring(src), Type="Error", Duration=6 })
        return
    end

    -- ── Name patches: Kicia → Nitrous ────────────────────────────────────
    -- Global env key
    src = src:gsub("getgenv%(%)%.KiciaCracked", "getgenv().Nitrous")
    src = src:gsub("env%.KiciaCracked",          "env.Nitrous")
    src = src:gsub("sharedEnv%['KiciaCracked'%]","sharedEnv['Nitrous']")
    -- Storage / filesystem paths
    src = src:gsub("'KiciaCracked/",             "'Nitrous/")
    src = src:gsub('"KiciaCracked/',             '"Nitrous/')
    src = src:gsub("KiciaCracked/",              "Nitrous/")
    -- Log/error strings
    src = src:gsub("%[Kicia Cracked%]",           "[Nitrous]")
    src = src:gsub("Kicia Cracked",               "Nitrous")
    src = src:gsub("Kicia was not started",        "Nitrous was not started")
    src = src:gsub("Kicia initialization",         "Nitrous initialization")
    src = src:gsub("Kicia did not finish startup", "Nitrous did not finish startup")
    -- Window title
    src = src:gsub("Kicia Cracked | Rivals",       "Nitrous | Rivals")
    -- Unload label
    src = src:gsub("Unload Kicia Cracked",         "Unload Nitrous")
    -- Function names (safe — these only affect local calls)
    src = src:gsub("waitForKiciaClient",           "waitForNitrousRivalsClient")
    src = src:gsub("runKicia",                     "runNitrousRivals")
    -- Teleport resume env key
    src = src:gsub("__PA_KiciaTeleportResume",     "__PA_NitrousTeleportResume")
    src = src:gsub("__PA_KiciaTeleportBoot",       "__PA_NitrousTeleportBoot")
    src = src:gsub("__KiciaStartupState",          "__NitrousStartupState")
    -- HTTP re-fetch URL inside the script (teleport resume auto-reload)
    src = src:gsub(
        "https://raw%.githubusercontent%.com/pafapapa/GameScripts/main/Kicia",
        "https://raw.githubusercontent.com/pafapafa/GameScripts/main/Kicia" -- keep same URL; names patched at load
    )
    -- ── Compile & run ────────────────────────────────────────────────────
    local chunk, compileErr = loadstring(src, "=NitrousRivals")
    if not chunk then
        Library:Notify({ Title=SCRIPT_NAME, Content="Compile error — " .. tostring(compileErr), Type="Error", Duration=8 })
        return
    end

    local ok2, runErr = pcall(chunk)
    if not ok2 then
        Library:Notify({ Title=SCRIPT_NAME, Content="Runtime error — " .. tostring(runErr), Type="Error", Duration=8 })
        return
    end

    rivalsLoaded = true
    Library:Notify({ Title=SCRIPT_NAME, Content="Rivals module loaded.", Type="Success", Duration=3 })
end

RivalsGrp:CreateLabel({ Text = "Loads the Rivals (Nitrous) module." })
RivalsGrp:CreateLabel({ Text = "Game: Rivals (ID 6035872082)" })
RivalsGrp:CreateButton({ Name = "Load Rivals Module", Icon = "play",
    Callback = patchAndLoadKicia })

-- ══════════════════════════════════════════════════════════════════════════
-- ENHANCEMENTS TAB (Nitrous-patched UE loader)
-- ══════════════════════════════════════════════════════════════════════════
local UEGrp = EnhancementsTab:AddLeftGroupbox({ Name = "Enhancements Module", Icon = "zap" })

local ueLoaded = false

local function patchAndLoadEnhancements()
    if ueLoaded then
        Library:Notify({ Title=SCRIPT_NAME, Content="Enhancements already loaded.", Type="Info", Duration=3 })
        return
    end

    Library:Notify({ Title=SCRIPT_NAME, Content="Loading Enhancements module...", Type="Info", Duration=3 })

    local ok, src = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/pafapafa/GameScripts/main/Unnamed%20Enhancements")
    end)

    if not ok then
        Library:Notify({ Title=SCRIPT_NAME, Content="Network error: " .. tostring(src), Type="Error", Duration=6 })
        return
    end

    -- ── Name patches: Unnamed Enhancements → Nitrous Enhancements ────────
    -- Global env key (string literal, safe on obfuscated output)
    src = src:gsub(
        "'Unnamed Enhancements %- Cracked'",
        "'Nitrous Enhancements'"
    )
    src = src:gsub(
        '"Unnamed Enhancements %- Cracked"',
        '"Nitrous Enhancements"'
    )
    -- Loaded flag
    src = src:gsub("'UE_LOADED'",  "'NITROUS_UE_LOADED'")
    src = src:gsub('"UE_LOADED"',  '"NITROUS_UE_LOADED"')
    -- Discord banner in ascii art header
    src = src:gsub("discord%.gg/vKXWdGT8pc", "discord.gg/ojailbreaks")
    -- ── Compile & run ────────────────────────────────────────────────────
    local chunk, compileErr = loadstring(src, "=NitrousEnhancements")
    if not chunk then
        Library:Notify({ Title=SCRIPT_NAME, Content="Compile error — " .. tostring(compileErr), Type="Error", Duration=8 })
        return
    end

    local ok2, runErr = pcall(chunk)
    if not ok2 then
        Library:Notify({ Title=SCRIPT_NAME, Content="Runtime error — " .. tostring(runErr), Type="Error", Duration=8 })
        return
    end

    ueLoaded = true
    Library:Notify({ Title=SCRIPT_NAME, Content="Enhancements module loaded.", Type="Success", Duration=3 })
end

UEGrp:CreateLabel({ Text = "Loads the Enhancements (Nitrous) module." })
UEGrp:CreateButton({ Name = "Load Enhancements Module", Icon = "play",
    Callback = patchAndLoadEnhancements })

-- ══════════════════════════════════════════════════════════════════════════
-- MAIN TAB
-- ══════════════════════════════════════════════════════════════════════════
local Toggles = MainTab:AddLeftGroupbox({ Name = "Toggles", Icon = "toggle-left" })
Toggles:CreateToggle({ Name="Example Toggle",                 CurrentValue=false, Flag="ExampleToggle",  Callback=function(v) end })
Toggles:CreateToggle({ Name="Another Toggle (on by default)", CurrentValue=true,  Flag="ExampleToggle2", Callback=function(v) end })

local Sliders = MainTab:AddLeftGroupbox({ Name = "Sliders", Icon = "sliders-horizontal" })
Sliders:CreateSlider({ Name="Example Slider", Range={0,100}, Increment=1,   CurrentValue=50, Flag="ExampleSlider",  Callback=function(v) end })
Sliders:CreateSlider({ Name="Decimal Slider", Range={0,2},   Increment=0.1, CurrentValue=1,  Flag="ExampleSlider2", Callback=function(v) end })

local Buttons = MainTab:AddRightGroupbox({ Name = "Buttons", Icon = "mouse-pointer-click" })
Buttons:CreateButton({ Name="Example Button",
    Callback=function()
        Library:Notify({ Title=SCRIPT_NAME, Content="Button clicked!", Type="Info", Duration=3 })
    end })
Buttons:CreateButton({ Name="Confirm Dialog",
    Callback=function()
        Library:Confirm({ Title="Are you sure?", ConfirmText="Yes", Callback=function() end })
    end })

local Dropdowns = MainTab:AddRightGroupbox({ Name = "Dropdowns", Icon = "list" })
Dropdowns:CreateDropdown({ Name="Single Select", Options={"Option 1","Option 2","Option 3"},
    CurrentOption="Option 1", AllowNone=false, Flag="ExampleDropdown", Callback=function(o) end })
Dropdowns:CreateDropdown({ Name="Multi Select", Options={"Red","Green","Blue","Yellow"},
    MultipleOptions=true, CurrentOption={}, Flag="ExampleMultiDropdown", Callback=function(o) end })

-- ══════════════════════════════════════════════════════════════════════════
-- EXTRA TAB
-- ══════════════════════════════════════════════════════════════════════════
local Keys = ExtraTab:AddLeftGroupbox({ Name = "Keybinds", Icon = "keyboard" })
Keys:CreateKeybind({ Name="Example Keybind", CurrentKeybind="E", Flag="ExampleKeybind",
    Callback=function() end, OnChanged=function(k) end })

local StatusGrp = ExtraTab:AddRightGroupbox({ Name = "Status", Icon = "activity" })
StatusGrp:CreateStatusList({ Name="Nitrous Status", MaxRows=3, UpdateRate=1,
    Update=function()
        return {
            { Text="ESP",          Value = S.Enabled and "ON" or "OFF"   },
            { Text="Rivals",       Value = rivalsLoaded and "Loaded" or "Idle" },
            { Text="Enhancements", Value = ueLoaded    and "Loaded" or "Idle" },
        }
    end })

-- ══════════════════════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ══════════════════════════════════════════════════════════════════════════
local Menu = SettingsTab:AddLeftGroupbox({ Name = "Menu", Icon = "monitor" })
Menu:CreateKeybind({ Name="Toggle UI", CurrentKeybind="RightControl", Flag="ToggleUIKey",
    Callback=function() end, OnChanged=function(k) Window:SetKeybind(k) end })
Menu:CreateDropdown({ Name="Toggle button", Options={"Mobile only","Mobile & PC"},
    CurrentOption="Mobile only", AllowNone=false, Flag="ToggleButtonPlatform",
    Callback=function(o)
        local c = type(o)=="table" and o[1] or o
        Window:SetToggleButtonPlatform(c=="Mobile & PC" and "Both" or "Mobile")
    end })
Menu:CreateButton({ Name="Unload Nitrous", Icon="power",
    Callback=function()
        Library:Confirm({ Title="Unload Nitrous?", ConfirmText="Unload",
            Callback=function() Window:Destroy() end })
    end })

SettingsTab:CreateConfigManager({ Name="Configs", Side="Left"  })
SettingsTab:CreateThemeManager({ Name="Themes",  Side="Right" })

-- ══════════════════════════════════════════════════════════════════════════
-- BOOT
-- ══════════════════════════════════════════════════════════════════════════
Window:LoadAutoload()

Library:Notify({
    Title   = SCRIPT_NAME,
    Content = "Loaded — ESP ready. Built by Olivia.",
    Type    = "Success",
    Duration = 4,
})
