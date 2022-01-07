os.loadAPI("buttonAPI.lua")
local DEBUG = false

if DEBUG then print("<Program> Start") end

local wireless = peripheral.find("modem") or print("Wireless modem not found, running in local mode")
local sendChannel = 1
local recvChannel = 1
local recvReplyChannel = 2
local textScale = 0.5
local settings = {}


function loadSettings()
    local tempSettings = nil
    f = io.open("settings.json", "r")
    if f ~= nil then
        fContent = f:read()
        tempSettings = textutils.unserialiseJSON(fContent)
    else
        f:close()
        f = io.open("settings.json", "w")
        f:write("{}")
        f:flush()
        tempSettings = textutils.unserialiseJSON("{}")
    end
    f:close()
    return tempSettings
end

function saveSettings()
    f = io.open("settings.json", "w")
    if f ~= nil then
        local buttonDict = buttonAPI.getButtonDict()
        local tempDict = {}
        for k,v in pairs(buttonDict) do
            tempDict[k] = v[#v]
        end
        local jsonString = textutils.serialiseJSON(tempDict)
        f:write(jsonString)
    end
    f:flush()
    f:close()
end

function sendCommand(modem, sChannel, rReplyChannel, button, state)
    if wireless ~= nil then
        if state then
            command = string.format("%s on", button)
        else
            command = string.format("%s off", button)
        end
        if DEBUG then print("Sending command:", command) end
        wireless.open(rReplyChannel)
        wireless.transmit(sChannel, rReplyChannel, command)
        local timeout = os.startTimer(0.2)
        local event, side, channel, replyChannel, message, distance
        repeat
            event, side, channel, replyChannel, message, distance = os.pullEvent()
            if event == "timer" then
                channel = rReplyChannel
                message = nil
                print("Modem timed out!")
            end
        until channel == rReplyChannel
        wireless.closeAll()
        if message then
            if DEBUG then print("Received a reply: " .. tostring(message)) end
            return true
        else
            return false
        end
    end
end

function determineTextScale(mon)
    local ts = nil
    local currentTS = mon.getTextScale()
    mon.setTextScale(1)
    local w, h = mon.getSize()
    if w > 20 then
        ts = 1
    else
        ts = 0.5
    end
    mon.setTextScale(currentTS)
    return ts
end

function getCurrentActions()
    local tempSettings
    if wireless then
        wireless.open(recvReplyChannel)
        wireless.transmit(sendChannel, recvReplyChannel, "getCurrentActions")
        local timeout = os.startTimer(0.2)
        local event, side, channel, replyChannel, message, distance
        repeat
            event, side, channel, replyChannel, message, distance = os.pullEvent()
            if event == "timer" then
                wireless.closeAll()
                return nil
            end
        until channel == recvReplyChannel
        wireless.closeAll()
        if message then
            tempSettings = textutils.unserialiseJSON(message)
            if DEBUG then
                for k,v in pairs(tempSettings) do
                    print(k, v)
                end
            end
        end
    end
    return tempSettings
end


local mon = peripheral.find("monitor")
buttonAPI.initMonitor(mon, determineTextScale(mon))
local buttonWidth = buttonAPI.getButtonWidth()
local buttonHeight = buttonAPI.getButtonHeight()
local rows, cols = buttonAPI.getGridCoords()
local sizeX, sizeY = buttonAPI.getSizeXY()

settings = getCurrentActions()

if settings == nil then
    settings = loadSettings()
end

local buttonList = {["Mob Slaughter"] = {sendCommand, settings["Mob Slaughter"] or false, indX = 1, indY = 0},
                    ["Mob Masher"] = {sendCommand, settings["Mob Masher"] or false, indX = 0, indY = 0},
                    ["Wither Skeleton"] = {sendCommand, settings["Wither Skeleton"] or false, indX = 0, indY = 1},
                    ["Nether Star"] = {sendCommand, settings["Nether Star"] or false, indX = 0, indY = 3},
                    ["Ether Gas"] = {sendCommand, settings["Ether Gas"] or false, indX = 1, indY = 3}}

                    -- ["Wither Spawner"] = {sendCommand, settings["Wither Spawner"] or false, indX = 0, indY = 3},

for buttonText, values in pairs(buttonList) do
    buttonAPI.drawButton(mon, cols[values.indX], rows[values.indY], buttonWidth, buttonHeight, buttonText, values[2])
    sendCommand(wireless, sendChannel, recvReplyChannel, buttonText, values[2])
end

saveSettings()

while true do
    if wireless then
        wireless.open(recvChannel)
        local eventData = {os.pullEvent()}
        local event = eventData[1]
        local buttonDict = buttonAPI.getButtonDict()
        if event == "monitor_touch" then
            local x, y = eventData[3], eventData[4]
            local buttonText, buttonState = buttonAPI.getButtonAtPos(x, y)
            if buttonText ~= nil then
                if (buttonText == "Nether Star") or (buttonText == "Ether Gas")  then
                    local netherOrEtherState
                    if buttonText == "Nether Star" then
                        netherOrEtherState = not buttonState
                    else
                        netherOrEtherState = buttonState
                    end
                    local result1 = buttonList["Nether Star"][1](wireless, sendChannel, recvReplyChannel, "Nether Star", netherOrEtherState)
                    local result2 = buttonList["Ether Gas"][1](wireless, sendChannel, recvReplyChannel, "Ether Gas", not netherOrEtherState)
                    buttonAPI.toggleButton(mon, "Nether Star", netherOrEtherState, true)
                    buttonAPI.toggleButton(mon, "Ether Gas", not netherOrEtherState, true)
                else
                    local result = buttonList[buttonText][1](wireless, sendChannel, recvReplyChannel, buttonText, not buttonState)
                    if result then
                        buttonAPI.toggleButton(mon, buttonText, not buttonState, true)
                    else
                        if DEBUG then print("Function failed for ", buttonText) end
                    end
                end
                saveSettings()
            end
        elseif event == "modem_message" then
            --event, side, channel, replyChannel, message, distance = eventData
            local channel, replyChannel, message, distance = eventData[3], eventData[4], tostring(eventData[5]), eventData[6]
            if channel == recvChannel then
                if (not string.find("{", message) and not string.find("getCurrentActions", message)) then
                    if DEBUG then print("Received message: " .. message .." channel: " .. channel) end -- .. " distance: " .. distance) end
                    local splitMsg = {}
                    for str in string.gmatch(message, "%S+") do
                        table.insert(splitMsg, str)
                    end
                    local buttonText = splitMsg[1].." "..splitMsg[2]
                    if splitMsg[#splitMsg] == "on" then
                        buttonAPI.toggleButton(mon, buttonText, true, true)
                    elseif splitMsg[#splitMsg] == "off" then
                        buttonAPI.toggleButton(mon, buttonText, false, true)
                    end
                    saveSettings()
                end
                wireless.closeAll()
            end
        end
    else
        local event, side, x, y = os.pullEvent()
        button = buttonAPI.handleTouchEvent(mon, tonumber(x), tonumber(y))
        saveSettings()
    end
end