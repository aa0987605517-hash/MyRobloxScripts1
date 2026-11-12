-- Studio preview of the custom 3D charm (chibi keychain style).
-- Roblox Studio: View > Command Bar, paste this, press Enter.
-- Builds "NMZL_Charm" in front of the camera: big black messy hair, small
-- black body with "你媽炸了" on the chest, stubby arms and legs, and a metal
-- ring + chain on top like the game's charms. Run again to rebuild.

local SCALE = 1.5

local old = workspace:FindFirstChild("NMZL_Charm")
if old then old:Destroy() end

local fig = Instance.new("Model")
fig.Name = "NMZL_Charm"

local cam = workspace.CurrentCamera
local base = cam and CFrame.new(cam.CFrame.Position + cam.CFrame.LookVector * 10)
    * CFrame.Angles(0, math.atan2(-cam.CFrame.LookVector.X, -cam.CFrame.LookVector.Z), 0)
    or CFrame.new(0, 5, 0)

local BODY = Color3.fromRGB(20, 20, 22)
local HAIR = Color3.fromRGB(14, 14, 16)
local METAL = Color3.fromRGB(205, 205, 210)

local function part(size, offset, color, mesh, material)
    local p = Instance.new("Part")
    p.Size = size * SCALE
    p.CFrame = base * CFrame.new(offset.Position * SCALE) * (offset - offset.Position)
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.Anchored = true
    p.CanCollide = false
    if mesh then
        local m = Instance.new("SpecialMesh")
        m.MeshType = mesh
        m.Parent = p
    end
    p.Parent = fig
    return p
end

-- ── body (chibi: small torso, stubby limbs) ──
local torso = part(Vector3.new(1.1, 1.0, 0.65), CFrame.new(0, 0, 0), BODY)
torso.Name = "Torso"
part(Vector3.new(0.42, 0.9, 0.5), CFrame.new(-0.78, 0.02, 0) * CFrame.Angles(0, 0, math.rad(-8)), BODY).Name = "LeftArm"
part(Vector3.new(0.42, 0.9, 0.5), CFrame.new(0.78, 0.02, 0) * CFrame.Angles(0, 0, math.rad(8)), BODY).Name = "RightArm"
part(Vector3.new(0.48, 0.6, 0.55), CFrame.new(-0.27, -0.8, 0), BODY).Name = "LeftLeg"
part(Vector3.new(0.48, 0.6, 0.55), CFrame.new(0.27, -0.8, 0), BODY).Name = "RightLeg"

-- chest text (front and back)
for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
    local sg = Instance.new("SurfaceGui")
    sg.Face = face
    sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
    sg.CanvasSize = Vector2.new(220, 200)
    sg.LightInfluence = 0
    local tl = Instance.new("TextLabel")
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.new(0.9, 0, 0.32, 0)
    tl.Position = UDim2.new(0.05, 0, 0.2, 0)
    tl.Text = "你媽炸了"
    tl.TextScaled = true
    tl.TextColor3 = Color3.fromRGB(180, 180, 180)
    tl.Parent = sg
    sg.Parent = torso
end

-- ── head = big messy black hair (headless look, no face) ──
local hc = Vector3.new(0, 1.25, 0)
part(Vector3.new(1.75, 1.45, 1.6), CFrame.new(hc), HAIR, Enum.MeshType.Sphere).Name = "HairMass"
part(Vector3.new(1.5, 0.9, 1.4), CFrame.new(hc + Vector3.new(0, 0.45, -0.05)), HAIR, Enum.MeshType.Sphere).Name = "HairTop"

-- flat locks: long side follows the hair direction, wide side lies flat
local function lock(pos, dir, len, width)
    local c = pos + dir.Unit * (len / 2)
    part(Vector3.new(width, 0.1, len), CFrame.lookAt(c, c + dir, Vector3.yAxis), HAIR).Name = "HairLock"
end

-- bangs over the front and sides, hanging down and out
local N = 16
for i = 1, N do
    local yaw = (i / N) * math.pi * 2 + math.sin(i * 4.7) * 0.2
    local out = Vector3.new(math.cos(yaw), 0, math.sin(yaw))
    local start = hc + Vector3.new(out.X * 0.7, 0.15, out.Z * 0.62)
    local droop = -1.4 - ((i * 7) % 5) * 0.25
    lock(start, out + Vector3.new(0, droop, 0) * 0.5, 0.55 + ((i * 3) % 4) * 0.08, 0.38)
end
-- messy locks flicking outward around the top
for i = 1, 10 do
    local yaw = (i / 10) * math.pi * 2 + 0.3
    local out = Vector3.new(math.cos(yaw), 0, math.sin(yaw))
    local start = hc + Vector3.new(out.X * 0.55, 0.55, out.Z * 0.5)
    lock(start, out + Vector3.new(0, 0.35 + (i % 3) * 0.2, 0), 0.5 + (i % 2) * 0.15, 0.3)
end
-- two thin strands sticking up on the left (like the picture)
part(Vector3.new(0.04, 0.9, 0.04), CFrame.new(-0.4, 2.35, 0) * CFrame.Angles(0, 0, math.rad(14)), HAIR).Name = "Strand"
part(Vector3.new(0.04, 0.8, 0.04), CFrame.new(-0.25, 2.3, 0.08) * CFrame.Angles(0, 0, math.rad(-5)), HAIR).Name = "Strand"

-- ── keychain: small loop on the head, chain links, big ring ──
local function ring(center, radius, thick, segs, axisAngles)
    for k = 1, segs do
        local a = (k / segs) * math.pi * 2
        local p = Vector3.new(math.cos(a) * radius, math.sin(a) * radius, 0)
        local seg = (2 * math.pi * radius) / segs * 1.15
        local cf = CFrame.new(center) * axisAngles * CFrame.new(p) * CFrame.Angles(0, 0, a)
        part(Vector3.new(thick, seg, thick), cf, METAL, nil, Enum.Material.Metal).Name = "Ring"
    end
end
ring(Vector3.new(0, 2.15, 0), 0.14, 0.05, 10, CFrame.Angles(0, math.rad(90), 0))   -- loop on head
ring(Vector3.new(0, 2.42, 0), 0.12, 0.045, 10, CFrame.new())                      -- chain link
ring(Vector3.new(0, 2.68, 0), 0.12, 0.045, 10, CFrame.Angles(0, math.rad(90), 0))  -- chain link
ring(Vector3.new(0, 3.2, 0), 0.42, 0.07, 20, CFrame.new())                         -- big ring

fig.PrimaryPart = torso
fig.Parent = workspace
print("NMZL_Charm built - look in front of the camera")
