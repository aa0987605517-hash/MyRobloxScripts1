-- Studio preview of the custom 3D charm (chibi keychain style).
-- Roblox Studio: View > Command Bar, paste this, press Enter.
-- Builds "NMZL_Charm" in front of the camera: big black messy hair, small
-- black body with "你媽炸了" on the chest, stubby arms and legs, and a metal
-- ring + chain on top like the game's charms. Run again to rebuild.

local SCALE = 1

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

-- body: proportions of the picture (wide torso, full-height arms,
-- one centred leg, headless)
local torso = part(Vector3.new(2, 2, 1), CFrame.new(0, 0, 0), BODY)
part(Vector3.new(1, 2, 1), CFrame.new(-1.53, 0, 0), BODY)
part(Vector3.new(1, 2, 1), CFrame.new(1.53, 0, 0), BODY)
part(Vector3.new(1, 2, 1), CFrame.new(0, -2.03, 0), BODY)
for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
    local sg = Instance.new("SurfaceGui")
    sg.Face = face
    sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
    sg.CanvasSize = Vector2.new(200, 200)
    sg.LightInfluence = 0
    local tl = Instance.new("TextLabel")
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.new(0.8, 0, 0.22, 0)
    tl.Position = UDim2.new(0.1, 0, 0.18, 0)
    tl.Text = "你媽炸了"
    tl.TextScaled = true
    tl.TextColor3 = Color3.fromRGB(175, 175, 175)
    tl.Parent = sg
    sg.Parent = torso
end
-- hair floating above the torso (no head), messy black locks
local hc = Vector3.new(0, 2.35, 0)
part(Vector3.new(1.95, 1.3, 1.6), CFrame.new(hc), HAIR, Enum.MeshType.Sphere)
local function lock(pos, dir, len, width)
    local c = pos + dir.Unit * (len / 2)
    part(Vector3.new(width, 0.08, len), CFrame.lookAt(c, c + dir, Vector3.yAxis), HAIR)
end
-- bangs hanging down over the front and sides
for i = 1, 18 do
    local yaw = (i / 18) * math.pi * 2 + math.sin(i * 4.7) * 0.2
    local out = Vector3.new(math.cos(yaw), 0, math.sin(yaw))
    local start = hc + Vector3.new(out.X * 0.6, 0.1, out.Z * 0.55)
    lock(start, out * 0.45 + Vector3.new(0, -1, 0), 0.6 + ((i * 3) % 4) * 0.1, 0.3)
end
-- spiky locks sticking out sideways / up (right side flicks)
for i = 1, 12 do
    local yaw = (i / 12) * math.pi * 2 + 0.25
    local out = Vector3.new(math.cos(yaw), 0, math.sin(yaw))
    local up = 0.15 + (i % 4) * 0.18
    local start = hc + Vector3.new(out.X * 0.55, 0.3, out.Z * 0.5)
    lock(start, out + Vector3.new(0, up, 0), 0.55 + (i % 3) * 0.15, 0.22)
end
-- long thin strands sticking up on the left
part(Vector3.new(0.04, 1.3, 0.04), CFrame.new(-0.5, 3.35, 0) * CFrame.Angles(0, 0, math.rad(12)), HAIR)
part(Vector3.new(0.04, 1.1, 0.04), CFrame.new(-0.35, 3.25, 0.08) * CFrame.Angles(0, 0, math.rad(-4)), HAIR)
part(Vector3.new(0.03, 0.9, 0.03), CFrame.new(-0.62, 3.1, -0.05) * CFrame.Angles(0, 0, math.rad(25)), HAIR)

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
ring(Vector3.new(0, 3.05, 0), 0.18, 0.06, 10, CFrame.Angles(0, math.rad(90), 0))  -- loop on hair
ring(Vector3.new(0, 3.4, 0), 0.16, 0.055, 10, CFrame.new())                       -- chain link
ring(Vector3.new(0, 3.72, 0), 0.16, 0.055, 10, CFrame.Angles(0, math.rad(90), 0)) -- chain link
ring(Vector3.new(0, 4.35, 0), 0.5, 0.08, 20, CFrame.new())                        -- big ring

fig.PrimaryPart = torso
fig.Parent = workspace
print("NMZL_Charm built - look in front of the camera")
