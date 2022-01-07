os.loadAPI("buttonAPI.lua")
local DEBUG = true;

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
            print(tostring(message), channel, distance)
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

local mon = peripheral.find("monitor")
buttonAPI.initMonitor(mon, determineTextScale(mon))
local buttonWidth = buttonAPI.getButtonWidth()
local buttonHeight = buttonAPI.getButtonHeight()
local rows, cols = buttonAPI.getGridCoords()
local sizeX, sizeY = buttonAPI.getSizeXY()

settings = loadSettings()

local buttonList = {["Mob Slaughter"] = {sendCommand, settings["Mob Slaughter"] or false},
                    ["Mob Masher"] = {sendCommand, settings["Mob Masher"] or false}}
                    -- ["Ghast Spawner"] = {sendCommand, settings["Ghast Spawner"] or false},
                    -- ["Blaze Spawner"] = {sendCommand, settings["Blaze Spawner"] or false},
                    -- ["Wither Spawner"] = {sendCommand, settings["Wither Spawner"] or false},
                    -- ["Mob Grinder"] = {sendCommand, settings["Mob Grinder"] or false}}

local indX, indY = 0, 0
for buttonText, values in pairs(buttonList) do
    buttonAPI.drawButton(mon, cols[indX], rows[indY], buttonWidth, buttonHeight, buttonText, values[2])
    sendCommand(wireless, sendChannel, recvReplyChannel, buttonText, values[2])
    if indX == 1 then
        indX = 0
        indY = indY + 1
    else
        indX = indX + 1
    end
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
            local result = buttonList[buttonText][1](wireless, sendChannel, recvReplyChannel, buttonText, not buttonState)
            if DEBUG then print(buttonText, buttonState) end
            if result then
                buttonAPI.toggleButton(mon, buttonText, not buttonState, true)
                -- button = buttonAPI.handleTouchEvent(mon, tonumber(x), tonumber(y))
                saveSettings()
            else
                if DEBUG then print("Function failed for ", buttonText) end
            end
        elseif event == "modem_message" then
            --event, side, channel, replyChannel, message, distance = eventData
            local channel, replyChannel, message, distance = eventData[3], eventData[4], tostring(eventData[5]), eventData[6]
            if channel == recvChannel then
                if DEBUG then print(message, channel, distance) end
                local splitMsg = {}
                for str in string.gmatch(message, "%S+") do
                    if (str ~= "on") and (str ~= "off") then
                        table.insert(splitMsg, str)
                    end
                end
                local buttonText = table.concat(splitMsg, " ")
                if string.find(message, "on") then
                    buttonAPI.toggleButton(mon, buttonText, true, true)
                elseif string.find(message, "off") then
                    buttonAPI.toggleButton(mon, buttonText, false, true)
                end
                saveSettings()
                wireless.closeAll()
            end
        end
    else
        local event, side, x, y = os.pullEvent()
        button = buttonAPI.handleTouchEvent(mon, tonumber(x), tonumber(y))
        saveSettings()
    end
end