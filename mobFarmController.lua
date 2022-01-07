local DEBUG = false
local wireless = peripheral.find("modem")
local redstoneSide = "right"
local mobFarmState = false
local mobSlaughterState = {value = false}
local mobMasherState = {value = false}
local witherSkeletonState = {value = false}
local netherStarState = {value = false}
local etherGasState = {value = false}
local recvChannel = 1

local mobFarmExceptions = {["Ether Gas"] = true,
                           ["Nether Star"] = true}

cmdList = {["Mob Slaughter"] = {colors.white, mobSlaughterState},
           ["Mob Masher"] = {colors.red, mobMasherState},
           ["Wither Skeleton"] = {colors.blue, witherSkeletonState},
           ["Nether Star"] = {colors.black + colors.gray, netherStarState},
           ["Ether Gas"] = {0, etherGasState}}

        --    ["Mob Grinder"] = {colors.black, mobGrinderState},
        --    ["Wither Spawner"] = {colors.gray, witherSpawnerState},
        --    ["Stasis Chamber"] = {colors.lime, stasisChamberState}}


function loadSettings()
    local tempSettings = nil
    local f = io.open("settings.json", "r")
    if f ~= nil then
        fContent = f:read()
        tempSettings = textutils.unserialiseJSON(fContent)
        for name, state in pairs(tempSettings) do
            cmdList[name][2].value = tempSettings[name]
        end
    else
        f = io.open("settings.json", "w")
        local tempDict = {}
        for name, values in pairs(cmdList) do
            tempDict[name] = values[2].value
        end
        local jsonString = textutils.serialiseJSON(tempDict)
        f:write(jsonString)
        f:flush()
        tempSettings = textutils.unserialiseJSON(jsonString)
    end
    f:close()
    return tempSettings
end

function saveSettings()
    f = io.open("settings.json", "w")
    if f ~= nil then
        local tempDict = {}
        for name, values in pairs(cmdList) do
            tempDict[name] = values[2].value
        end
        local jsonString = textutils.serialiseJSON(tempDict)
        f:write(jsonString)
        f:flush()
    end
    f:close()
end

function mobFarmControl()
    local combinedState = false
    for name, values in pairs(cmdList) do
        if mobFarmExceptions[name] == nil then
            combinedState = combinedState or values[2].value
        end
    end
    if combinedState then
        toggleRedstoneColor(colors.green, true)
        if DEBUG then print("Mobfarm turned on") end
        if not mobFarmState then
            mobFarmState = true
        end
    else
        toggleRedstoneColor(colors.green, false)
        if DEBUG then print("Mobfarm turned off") end
        if mobFarmState then
            mobFarmState = false
        end
    end
end

function toggleRedstoneColor(color, action)
    local currentBundle = redstone.getBundledOutput(redstoneSide)
    local newBundle = nil
    if action then
        newBundle = colors.combine(currentBundle, color)
    else
        newBundle = colors.subtract(currentBundle, color)
    end
    redstone.setBundledOutput(redstoneSide, newBundle)
end

settings = loadSettings()
redstone.setBundledOutput(redstoneSide, 0)

for name, values in pairs(cmdList) do
    toggleRedstoneColor(values[1], settings[name] or values[2].value)
end

mobFarmControl()

if wireless ~= nil then
    while true do
        wireless.open(recvChannel)
        local event, side, channel, replyChannel, message, distance
        repeat
            event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
            if DEBUG then
                if message ~= nil then
                    print("\nCommand: '" .. tostring(message) .. "'")
                    print("Channel: '" .. channel .. "'")
                    print("Reply channel: '" .. replyChannel .. "'")
                end
            end
        until channel == recvChannel
        command = tostring(message)
        if string.find(command, "getCurrentActions") then
            local tempJSON = textutils.serialiseJSON(loadSettings())
            wireless.transmit(replyChannel, channel, tempJSON)
        else
            wireless.transmit(replyChannel, channel, command)
        end
        wireless.closeAll()


        for name, values in pairs(cmdList) do
            if string.find(command, name) then
                local splitMsg = {}
                for str in string.gmatch(message, "%S+") do
                    table.insert(splitMsg, str)
                end
                if splitMsg[#splitMsg] == "on" then
                    if DEBUG then print("Turning on the '"..name.."'") end
                    print("Turning on the '"..name.."'")
                    toggleRedstoneColor(values[1], true)
                    values[2].value = true
                elseif splitMsg[#splitMsg] == "off" then
                    if DEBUG then print("Turning off the '"..name.."'") end
                    print("Turning off the '"..name.."'")
                    toggleRedstoneColor(values[1], false)
                    values[2].value = false
                end
            end
        end
        saveSettings()
        mobFarmControl()
    end
end