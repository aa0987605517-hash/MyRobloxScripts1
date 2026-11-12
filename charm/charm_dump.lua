-- Charm dump: run once in the executor while holding a gun that has a charm.
-- Writes workspace/unnamed/charm_dump.txt with everything named "charm" in
-- ReplicatedStorage and the full ViewModels tree, so the custom charm can be
-- added to the cosmetics changer the same way Rivals stores its own charms.
-- Read-only: changes nothing in the game.

local lines = {}
local function add(s) lines[#lines + 1] = s end

local function tree(root, depth, maxDepth)
    if depth > maxDepth or #lines > 4000 then return end
    for _, c in ipairs(root:GetChildren()) do
        local extra = ""
        if c:IsA("BasePart") then
            extra = (" size=%.2f,%.2f,%.2f"):format(c.Size.X, c.Size.Y, c.Size.Z)
            if c:IsA("MeshPart") then extra = extra .. " mesh=" .. tostring(c.MeshId) .. " tex=" .. tostring(c.TextureID) end
        elseif c:IsA("Attachment") then
            extra = " pos=" .. tostring(c.Position)
        elseif c:IsA("Constraint") or c:IsA("JointInstance") or c:IsA("WeldConstraint") then
            local a0 = c:IsA("Constraint") and c.Attachment0 or c.Part0
            local a1 = c:IsA("Constraint") and c.Attachment1 or c.Part1
            extra = " 0=" .. (a0 and a0:GetFullName() or "nil") .. " 1=" .. (a1 and a1:GetFullName() or "nil")
        elseif c:IsA("ValueBase") then
            extra = " value=" .. tostring(c.Value)
        end
        add(string.rep("  ", depth) .. c.Name .. " [" .. c.ClassName .. "]" .. extra)
        tree(c, depth + 1, maxDepth)
    end
end

add("== ViewModels ==")
local vm = workspace:FindFirstChild("ViewModels")
if vm then tree(vm, 1, 8) else add("  (no ViewModels folder)") end

add("")
add("== Camera ==")
if workspace.CurrentCamera then tree(workspace.CurrentCamera, 1, 6) end

add("")
add("== ReplicatedStorage: anything named charm ==")
local RS = game:GetService("ReplicatedStorage")
for _, d in ipairs(RS:GetDescendants()) do
    if d.Name:lower():find("charm", 1, true) then
        add("  " .. d:GetFullName() .. " [" .. d.ClassName .. "]")
        if (d:IsA("Folder") or d:IsA("Model")) and #lines < 3500 then
            tree(d, 2, 3)
        end
    end
    if #lines > 4000 then break end
end

local text = table.concat(lines, "\n")
pcall(function() if not isfolder("unnamed") then makefolder("unnamed") end end)
local ok = pcall(writefile, "unnamed/charm_dump.txt", text)
print(("[CharmDump] %d lines -> %s"):format(#lines, ok and "workspace/unnamed/charm_dump.txt" or "WRITE FAILED"))
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Charm Dump", Text = ok and "saved unnamed/charm_dump.txt" or "write failed", Duration = 6,
    })
end)
