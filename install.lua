-- One-shot installer: writes the loader into the executor's autoexec folder.
-- Paste this into your executor's console ONCE and press execute.
-- After this, every time you launch the executor the script will auto-run.
--
-- To update what the loader fetches, edit loader.lua in the repo - you don't
-- need to re-run this installer.

local LOADER_URL =
    "https://raw.githubusercontent.com/aa0987605517-hash/MyRobloxScripts1/claude/loving-edison-7k2co2/loader.lua"

local AUTOEXEC_FOLDERS = { "autoexec", "auto_execute", "autoexecute", "workspace/autoexec" }
local FILENAME = "nebula_loader.lua"

local function notify(msg, sec)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Installer",
            Text  = tostring(msg),
            Duration = sec or 6,
        })
    end)
    warn("[Installer] " .. tostring(msg))
end

if type(writefile) ~= "function" then
    notify("your executor has no writefile - cannot install automatically", 8)
    return
end

-- Pick the first folder that already exists; otherwise fall back to the first entry.
local target
for _, dir in ipairs(AUTOEXEC_FOLDERS) do
    local ok = pcall(function()
        if isfolder and isfolder(dir) then target = dir end
    end)
    if target then break end
end
if not target then
    target = AUTOEXEC_FOLDERS[1]
    pcall(function() if makefolder then makefolder(target) end end)
end

-- Loader content: fetches the real main script every launch (so updates are
-- picked up without reinstalling). If you prefer to pin the loader itself,
-- change `LOADER_URL` below to a tag or commit SHA.
local body = string.format(
    'loadstring(game:HttpGet(%q))()',
    LOADER_URL
)

local path = target .. "/" .. FILENAME
local ok, err = pcall(writefile, path, body)
if not ok then
    notify("write failed to " .. path .. ": " .. tostring(err), 8)
    return
end

notify("installed to " .. path .. " - relaunch executor to auto-load", 8)
