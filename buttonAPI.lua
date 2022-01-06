local buttonWidth = 0
local buttonHeight = 3
local buttonDict = {}
local sizeX, sizeY = 0, 0
local rows, cols = {}, {}

function initMonitor(mon, textScale)
    local xOffset = 1
    if mon == nil then
        print("Monitor not found :(")
        shell.exit()
    else
        mon.setBackgroundColor(colors.black)
        mon.setTextScale(textScale)
        mon.clear()
        sizeX, sizeY = mon.getSize() -- 4x3 = 39w 19h || 2x2 = 18w 12h @textScale=1
        if sizeX > 30 then
            xOffset = 3
        end
        if sizeX % 2 == 0 then
            print("even")
            buttonWidth = (sizeX - 2) / 2 - xOffset-- 36 - 4 = 32. 32 / 2 = 16
        else
            print("odd")
            buttonWidth = (sizeX - 1) / 2 - xOffset-- 39 - 3 = 36, 36 / 2 = 18
        end
        for i=0,10 do
            rows[i] = 2 + (buttonHeight * i) + i -- 2+buttonHeight+1 -- 2+buttonHeight*2+2
        end
        if sizeX % 2 == 0 then
            for i=0,10 do
                cols[i] = 1 + xOffset + (buttonWidth * i) + (2 * i)
            end
        else
            for i=0,10 do
                cols[i] = 1 + xOffset + (buttonWidth * i) + (1 * i)
            end
        end
    end
end

function drawButton(mon, x, y, width, height, text, active)
    local spaces = 0
    local newText = text
    local textLength = string.len(text)
    local currentBackgroundColor = mon.getBackgroundColor()
    if width % 2 == 0 then
        if (textLength % 2 ~= 0) then
            newText = string.format("%s ", text)
        end
    else
        if (textLength % 2 == 0) then
            newText = string.format("%s ", text)
        end
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
    buttonDict[text] = {x, x+width, y, y+height, width, height, active}
end

function toggleButton(mon, button, state)
    local tempDict = buttonDict
    for text, values in pairs(tempDict) do
        local xStart, xEnd, yStart, yEnd, width, height, active = values[1], values[2], values[3], values[4], values[5], values[6], values[7]
        if text == button then
            drawButton(mon, xStart, yStart, width, height, text, state)
        end
    end
end

function handleTouchEvent(mon, x, y)
    local tempDict = buttonDict
    for text, values in pairs(tempDict) do
        local xStart, xEnd, yStart, yEnd, width, height, active = values[1], values[2], values[3], values[4], values[5], values[6], values[7]
        if (x >= xStart) and (x <= xEnd) and (y >= yStart) and (y <= yEnd) then
            drawButton(mon, xStart, yStart, width, height, text, not active)
        end
    end
end

function getButtonAtPos(x, y)
    local tempDict = buttonDict
    for text, values in pairs(tempDict) do
        local xStart, xEnd, yStart, yEnd, width, height, state = values[1], values[2], values[3], values[4], values[5], values[6], values[7]
        if (x >= xStart) and (x <= xEnd) and (y >= yStart) and (y <= yEnd) then
            return text, state
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