-- Studio preview of the custom 3D charm figure.
-- Roblox Studio: open any place, View > Command Bar, paste this, press Enter.
-- It builds a model "NMZL_Charm" in Workspace (about 6 studs tall, in front
-- of the camera) so you can look at it from every side before it goes into
-- the cheat. Run it again to rebuild (the old one is replaced).

local SCALE = 1  -- 1 = ~6 studs tall

local old = workspace:FindFirstChild("NMZL_Charm")
if old then old:Destroy() end

local fig = Instance.new("Model")
fig.Name = "NMZL_Charm"

local cam = workspace.CurrentCamera
local base = cam and CFrame.new(cam.CFrame.Position + cam.CFrame.LookVector * 14)
    * CFrame.Angles(0, math.atan2(-cam.CFrame.LookVector.X, -cam.CFrame.LookVector.Z), 0)
    or CFrame.new(0, 5, 0)

local BODY = Color3.fromRGB(18, 18, 18)
local HAIR = Color3.fromRGB(12, 12, 12)
local root

local function part(size, offset, color, shape)
    local p = Instance.new("Part")
    p.Size = size * SCALE
    p.CFrame = base * CFrame.new(offset.Position * SCALE) * (offset - offset.Position)
    p.Color = color
    p.Material = Enum.Material.SmoothPlastic
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.Anchored = true
    p.CanCollide = false
    if shape then p.Shape = shape end
    p.Parent = fig
    return p
end

-- body: torso, two arms, one leg (headless, like the picture)
local torso = part(Vector3.new(2, 2, 1), CFrame.new(0, 0, 0), BODY)
torso.Name = "Torso"
-- small gaps so the arms/leg read as separate blocks, like the picture
part(Vector3.new(1, 2, 1), CFrame.new(-1.54, 0, 0), BODY).Name = "LeftArm"
part(Vector3.new(1, 2, 1), CFrame.new(1.54, 0, 0), BODY).Name = "RightArm"
part(Vector3.new(1, 2, 1), CFrame.new(0, -2.04, 0), BODY).Name = "Leg"

-- chest text
for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
    local sg = Instance.new("SurfaceGui")
    sg.Face = face
    sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
    sg.CanvasSize = Vector2.new(200, 200)
    sg.LightInfluence = 0
    local tl = Instance.new("TextLabel")
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.new(0.84, 0, 0.26, 0)
    tl.Position = UDim2.new(0.08, 0, 0.18, 0)
    tl.Text = "你媽炸了"
    tl.TextScaled = true
    tl.TextColor3 = Color3.fromRGB(175, 175, 175)
    tl.Parent = sg
    sg.Parent = torso
end

-- hair: fluffy cap + flat drooping locks (messy anime-style hair)
local hc = Vector3.new(0, 2.05, 0)
local dome = part(Vector3.new(2.0, 1.3, 1.8), CFrame.new(hc), HAIR)
dome.Name = "HairDome"
local m = Instance.new("SpecialMesh") -- Ball parts can't be stretched, a sphere mesh can
m.MeshType = Enum.MeshType.Sphere
m.Parent = dome

local function lock(yaw, pitch, len, width)
    local d = Vector3.new(math.cos(pitch) * math.cos(yaw), math.sin(pitch), math.cos(pitch) * math.sin(yaw))
    local start = hc + Vector3.new(d.X * 0.8, d.Y * 0.5 + 0.15, d.Z * 0.7)
    local pos = start + d * (len / 2)
    -- long axis along d, wide side horizontal, thin side facing outward
    part(Vector3.new(width, 0.12, len), CFrame.lookAt(pos, pos + d, Vector3.yAxis), HAIR).Name = "HairLock"
end

-- drooping locks all around (front fringe included)
local N = 18
for i = 1, N do
    local yaw = (i / N) * math.pi * 2 + math.sin(i * 5.1) * 0.2
    local pitch = math.rad(-25 - ((i * 23) % 40))     -- -25 .. -65 degrees
    lock(yaw, pitch, 0.9 + ((i * 7) % 4) * 0.15, 0.5)
end
-- a few messy locks sticking up / back on top
for i = 1, 7 do
    local yaw = math.pi * 0.5 + (i - 4) * 0.45        -- mostly toward the back
    local pitch = math.rad(15 + ((i * 17) % 35))
    lock(yaw, pitch, 0.7 + (i % 3) * 0.2, 0.4)
end
-- two thin strands sticking up on the left
part(Vector3.new(0.05, 1.4, 0.05), CFrame.new(-0.55, 3.2, 0) * CFrame.Angles(0, 0, math.rad(12)), HAIR).Name = "Strand"
part(Vector3.new(0.05, 1.2, 0.05), CFrame.new(-0.35, 3.15, 0.1) * CFrame.Angles(0, 0, math.rad(-6)), HAIR).Name = "Strand"

fig.PrimaryPart = torso
fig.Parent = workspace
print("NMZL_Charm built - look in front of the camera")
