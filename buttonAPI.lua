local buttonWidth = 0
local buttonHeight = 3
local buttonDict = {}
local sizeX, sizeY = 0, 0
local rows, cols = {}, {}

function initMonitor(textScale)
    local mon = peripheral.find("monitor")
    if mon == nil then
        print("Monitor not found :(")
        shell.exit()
    else
        mon.setBackgroundColor(colors.black)
        mon.setTextScale(textScale)
        mon.clear()
        sizeX, sizeY = mon.getSize() -- 4x3 = 39w 19h || 2x2 = 18w 12h
        buttonWidth = (sizeX - 5) / 2
        
        for i=0,10 do
            rows[i] = 2 + (buttonHeight * i) + i -- 2+buttonHeight+1 -- 2+buttonHeight*2+2
        end
        for i=0,10 do
            cols[i] = 2 + (buttonWidth * i) + (3 * i)
        end
    end
    return mon
end

function drawButton(mon, x, y, width, height, text, func, active, guiOnly)
    local spaces = 0
    local newText = text
    local textLength = string.len(text)
    local currentBackgroundColor = mon.getBackgroundColor()
    if (textLength % 2 == 0) then
        newText = string.format("%s ", text)
    end
    textLength = string.len(newText)
    spaces = (width - textLength) / 2
    newText = string.format("%s%s%s",string.rep(" ", spaces), newText, string.rep(" ", spaces))
    if active then
        mon.setBackgroundColor(colors.green)
    else
        mon.setBackgroundColor(colors.red)
    end
    mon.setTextColor(colors.white)
    if (height > 1) then
        mon.setCursorPos(x, y)
        mon.write(string.rep(" ", width))
        mon.setCursorPos(x, y+1)
        mon.write(newText)
        mon.setCursorPos(x, y+2)
        mon.write(string.rep(" ", width))
    else
        mon.setCursorPos(x, y)
        mon.write(newText)
    end
    mon.setBackgroundColor(currentBackgroundColor)
    buttonDict[text] = {x, x+width, y, y+height, width, height, func, active}
    if not guiOnly then
        func(active)
    end
end

function toggleButton(mon, button, state, guiOnly)
    local tempDict = buttonDict
    for name, values in pairs(tempDict) do
        local xStart, xEnd, yStart, yEnd, width, height, func, active = values[1], values[2], values[3], values[4], values[5], values[6], values[7], values[8]
        if name == button then
            drawButton(mon, xStart, yStart, width, height, name, func, state, guiOnly)
        end
    end
end

function handleTouchEvent(mon, x, y)
    local tempDict = buttonDict
    for name, values in pairs(tempDict) do
        local xStart, xEnd, yStart, yEnd, width, height, func, active = values[1], values[2], values[3], values[4], values[5], values[6], values[7], values[8]
        if (x >= xStart) and (x <= xEnd) and (y >= yStart) and (y <= yEnd) then
            drawButton(mon, xStart, yStart, width, height, name, func, not active)
        end
    end
end

function getButtonAtPos(x, y)
    local tempDict = buttonDict
    for name, values in pairs(tempDict) do
        local xStart, xEnd, yStart, yEnd, width, height, func, state = values[1], values[2], values[3], values[4], values[5], values[6], values[7], values[8]
        if (x >= xStart) and (x <= xEnd) and (y >= yStart) and (y <= yEnd) then
            return name, func, state
        end
    end
end

function getButtonWidth()
    return buttonWidth
end

function getButtonHeight()
    return buttonHeight
end

function getGridCoords()
    return rows, cols
end

function getButtonDict()
    return buttonDict
end

function getSizeXY()
    return sizeX, sizeY
end