-- Nebula / Kicia enhanced loader
-- Put this (or install.lua) in your executor's autoexec folder to run on launch.
-- Retries HttpGet on failure and reports errors through the notification API.

local URL = "https://raw.githubusercontent.com/aa0987605517-hash/MyRobloxScripts1/claude/loving-edison-7k2co2/unnamed_main.lua"
local MAX_TRIES = 4
local RETRY_DELAY = 2  -- seconds, doubles each retry

local function notify(msg, sec)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Loader",
            Text  = tostring(msg),
            Duration = sec or 5,
        })
    end)
    warn("[Loader] " .. tostring(msg))
end

task.spawn(function()
    local src, delay = nil, RETRY_DELAY
    for attempt = 1, MAX_TRIES do
        local ok, result = pcall(game.HttpGet, game, URL)
        if ok and type(result) == "string" and #result > 1000 then
            src = result
            break
        end
        notify(("fetch failed (attempt %d/%d): %s"):format(attempt, MAX_TRIES, tostring(result)), 3)
        if attempt < MAX_TRIES then task.wait(delay); delay = delay * 2 end
    end

    if not src then
        notify("could not fetch main script after " .. MAX_TRIES .. " tries", 8)
        return
    end

    local chunk, compileErr = loadstring(src, "=unnamed_main.lua")
    if not chunk then
        notify("compile error: " .. tostring(compileErr), 8)
        return
    end

    local okRun, runErr = pcall(chunk)
    if not okRun then
        notify("runtime error: " .. tostring(runErr), 8)
        return
    end

    notify("loaded", 3)
end)
