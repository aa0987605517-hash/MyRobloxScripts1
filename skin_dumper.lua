-- Rivals Skin Dumper
-- 在遊戲裡 (大廳或對局都可以) 執行這個腳本
-- 完成後會把皮膚資料寫到 workspace 資料夾裡的 rivals_skins_dump.txt

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local output = {
    timestamp = os.date("%Y-%m-%d %H:%M:%S"),
    gameId = game.PlaceId,
    sections = {}
}

local function safeName(inst)
    local ok, n = pcall(function() return inst.Name end)
    return ok and n or "?"
end

local function safeClass(inst)
    local ok, c = pcall(function() return inst.ClassName end)
    return ok and c or "?"
end

local function scanFolder(folder, label)
    if not folder then return end
    local section = {label = label, path = folder:GetFullName(), items = {}}
    local ok, children = pcall(function() return folder:GetChildren() end)
    if not ok or not children then return end

    for _, child in ipairs(children) do
        pcall(function()
            local entry = {
                name = safeName(child),
                class = safeClass(child),
                children = {}
            }
            local ok2, grand = pcall(function() return child:GetChildren() end)
            if ok2 and grand then
                for _, g in ipairs(grand) do
                    pcall(function()
                        table.insert(entry.children, {
                            name = safeName(g),
                            class = safeClass(g),
                        })
                    end)
                end
            end
            local ok3, attrs = pcall(function() return child:GetAttributes() end)
            if ok3 and attrs and next(attrs) then
                entry.attributes = attrs
            end
            table.insert(section.items, entry)
        end)
    end
    table.insert(output.sections, section)
end

-- Known Rivals cosmetic paths (adjust as needed)
local candidates = {
    {ReplicatedStorage:FindFirstChild("Cosmetics"), "Cosmetics"},
    {ReplicatedStorage:FindFirstChild("Skins"), "Skins"},
    {ReplicatedStorage:FindFirstChild("Weapons"), "Weapons"},
    {ReplicatedStorage:FindFirstChild("Items"), "Items"},
    {ReplicatedStorage:FindFirstChild("Assets"), "Assets"},
    {ReplicatedStorage:FindFirstChild("Modules"), "Modules"},
    {ReplicatedStorage:FindFirstChild("Shared"), "Shared"},
}
for _, pair in ipairs(candidates) do
    scanFolder(pair[1], pair[2])
end

-- Deep scan: look for anything with "skin" or "camo" in the name under ReplicatedStorage
local matches = {label = "KeywordMatches (skin/camo/wrap)", path = "ReplicatedStorage", items = {}}
local function deepScan(parent, depth)
    if depth > 6 then return end
    local ok, children = pcall(function() return parent:GetChildren() end)
    if not ok or not children then return end
    for _, child in ipairs(children) do
        pcall(function()
            local n = safeName(child):lower()
            if n:find("skin") or n:find("camo") or n:find("wrap") or n:find("cosmetic") then
                table.insert(matches.items, {
                    name = safeName(child),
                    class = safeClass(child),
                    path = child:GetFullName(),
                })
            end
            deepScan(child, depth + 1)
        end)
    end
end
deepScan(ReplicatedStorage, 0)
table.insert(output.sections, matches)

-- Try loading ModuleScripts named like skin lists
local moduleResults = {label = "RequiredModules", path = "various", items = {}}
local function tryRequireNamed(parent, depth)
    if depth > 5 then return end
    local ok, children = pcall(function() return parent:GetChildren() end)
    if not ok then return end
    for _, child in ipairs(children) do
        pcall(function()
            if child:IsA("ModuleScript") then
                local n = safeName(child):lower()
                if n:find("skin") or n:find("cosmetic") or n:find("camo") or n:find("wrap") or n:find("item") then
                    local ok2, data = pcall(require, child)
                    if ok2 then
                        local okEnc, enc = pcall(function()
                            return HttpService:JSONEncode(data)
                        end)
                        table.insert(moduleResults.items, {
                            name = safeName(child),
                            path = child:GetFullName(),
                            data = okEnc and enc or ("ERR: " .. tostring(enc)),
                        })
                    end
                end
            end
            tryRequireNamed(child, depth + 1)
        end)
    end
end
tryRequireNamed(ReplicatedStorage, 0)
table.insert(output.sections, moduleResults)

-- Serialize and write
local okEnc, encoded = pcall(function()
    return HttpService:JSONEncode(output)
end)

if not okEnc then
    warn("[SkinDumper] Encode failed:", encoded)
    return
end

if writefile then
    writefile("rivals_skins_dump.txt", encoded)
    print("[SkinDumper] Done! File saved to workspace/rivals_skins_dump.txt")
    print("[SkinDumper] Size:", #encoded, "bytes")
    if setclipboard then
        setclipboard(encoded)
        print("[SkinDumper] Also copied to clipboard")
    end
else
    warn("[SkinDumper] writefile not available, printing to console...")
    print(encoded)
end
