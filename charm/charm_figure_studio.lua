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
part(Vector3.new(1, 2, 1), CFrame.new(-1.5, 0, 0), BODY).Name = "LeftArm"
part(Vector3.new(1, 2, 1), CFrame.new(1.5, 0, 0), BODY).Name = "RightArm"
part(Vector3.new(1, 2, 1), CFrame.new(0, -2, 0), BODY).Name = "Leg"

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

-- hair: dome + messy spikes, floating above the torso
local hc = Vector3.new(0, 1.95, 0)
part(Vector3.new(1.9, 1.2, 1.7), CFrame.new(hc), HAIR, Enum.PartType.Ball).Name = "HairDome"
local N = 26
for i = 1, N do
    local yaw = (i / N) * math.pi * 2 + math.sin(i * 7.3) * 0.3
    local pitch = math.rad(-40 + ((i * 37) % 80))
    local d = Vector3.new(math.cos(pitch) * math.cos(yaw), math.sin(pitch), math.cos(pitch) * math.sin(yaw))
    local len = 0.55 + ((i * 13) % 5) * 0.11
    local pos = hc + Vector3.new(d.X * 0.75, d.Y * 0.45, d.Z * 0.65) + d * (len / 2)
    part(Vector3.new(0.22, 0.22, len), CFrame.lookAt(pos, pos + d), HAIR).Name = "HairSpike"
end
part(Vector3.new(0.05, 1.4, 0.05), CFrame.new(-0.55, 3.0, 0) * CFrame.Angles(0, 0, math.rad(12)), HAIR).Name = "Strand"
part(Vector3.new(0.05, 1.2, 0.05), CFrame.new(-0.35, 2.95, 0.1) * CFrame.Angles(0, 0, math.rad(-6)), HAIR).Name = "Strand"

fig.PrimaryPart = torso
fig.Parent = workspace
print("NMZL_Charm built - look in front of the camera")
