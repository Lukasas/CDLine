---------------- Globals  ----------------

BACKDROP_DIALOG_0_0 = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	tile = true,
	tileEdge = true,
	tileSize = 32,
	edgeSize = 0,
    insets = {left=-4, right=-4, top=4, bottom=4}
};
SLASH_REC1 = "/cdline"
local movable = true
local spellsOnCooldown = {}
local cdline_icon_frames = {}
local iconDim = 20
local addonLoaded = false
local cdline_stage = {
    start = 1,
    ending = 2,
    ended = 3
}
local cdl_idx = 0

local function getLen(input)
    if input == nil then
        return 0
    end

    local counter = 0
    for k, v in pairs(input) do
        counter = counter + 1
    end
    return counter
end

local timingIdxMap = {
    m20 = 0,
    m10 = 1,
    m5 = 2,
    m1 = 3,
    s30 = 4,
    s10 = 5,
    s2 = 6,
    s0 = 7
}

local ori = {
    hori = {
        swxy = false,
        rev = false,
        anchor = "LEFT"
    },
    horir = {
        swxy = false,
        rev = true,
        anchor = "RIGHT"
    },
    vert = {
        swxy = true,
        rev = false,
        anchor = "BOTTOM"
    },
    vertr = {
        swxy = true,
        rev = true,
        anchor = "TOP"
    }
}

local timings = {{
    text = "20",
    offset = 5,
    time = 20 * 60
}, {
    text = "10",
    offset = 20,
    time = 10 * 60
}, {
    text = "5",
    offset = 35,
    time = 5 * 60
}, {
    text = "1",
    offset = 60,
    time = 1 * 60
}, {
    text = "30",
    offset = 95,
    time = 30
}, {
    text = "10",
    offset = 135,
    time = 10
}, {
    text = "2",
    offset = 180,
    time = 2
}, {
    text = "",
    offset = 200,
    time = 0
}}

local fontSize = 8
local currentOri = ori.hori

local dropDown = CreateFrame("Frame", "WPDemoContextMenu", UIParent, "UIDropDownMenuTemplate")

local iconsBuffer = {}
---------------- Timers ----------------

---------------- Addon Functions ----------------

local function ShowMinimapTooltip()
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(ListOfItemsRecordedFrame, "ANCHOR_CURSOR")
    GameTooltip:SetText('Hello World')
    GameTooltip:Show()
end

function setupTimes()

end

local totalFramesCount = 50
local function prepareIcons()
    for idx = 1, totalFramesCount do
        local frame = CreateFrame('BUTTON', "spell" .. tostring(idx), CDLine_Frame, 'CooldownIconTemplate');
        iconsBuffer[idx] = {
            inUse = false,
            frame = frame,
            texture = frame:CreateTexture()
        }
    end
end

function InitializeCDLine()
    prepareIcons()
    addonLoaded = true
end

local function getAvailableIconFrame()
    for idx = 1, totalFramesCount do
        if iconsBuffer[idx].inUse == false then
            iconsBuffer[idx].frame:Show()
            iconsBuffer[idx].frame:SetSize(iconDim, iconDim);
            iconsBuffer[idx].frame:SetAlpha(1);
            return iconsBuffer[idx]
        end
    end
    totalFramesCount = totalFramesCount + 1
    local frame = CreateFrame('BUTTON', "spell" .. tostring(totalFramesCount), CDLine_Frame, 'CooldownIconTemplate');
    iconsBuffer[totalFramesCount] = {
        inUse = false,
        frame = frame,
        texture = frame:CreateTexture()
    }
    return iconsBuffer[totalFramesCount]
end

local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local function ShowTooltip(text)
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(CDLine_Frame, "ANCHOR_CURSOR")
    GameTooltip:SetText(text)
    GameTooltip:Show()
end

local function HideTooltip()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
end

---------------- Buttons Click ----------------

local function buildDropDown()
    UIDropDownMenu_Initialize(dropDown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        if (level or 1) == 1 then
            info.text = "Font Scale"
            info.checked = false
            info.menuList, info.hasArrow = "fSize", true
            UIDropDownMenu_AddButton(info)

            info.text = "Orientation"
            info.checked = false
            info.menuList, info.hasArrow = "lineOri", true
            UIDropDownMenu_AddButton(info)

        else
            if menuList == "fSize" then
                info.func = self.setFontSize
                for i = 1, 3, 0.25 do
                    info.text = i
                    info.arg1 = i
                    info.checked = i == fontSize
                    UIDropDownMenu_AddButton(info, level)
                end
            elseif menuList == "lineOri" then
                info.func = self.setOrientation
                info.text = "Horizontal"
                info.arg1 = ori.hori
                info.checked = currentOri == info.arg1
                UIDropDownMenu_AddButton(info, level)
                info.text = "Horizontal (Reversed)"
                info.arg1 = ori.horir
                info.checked = currentOri == info.arg1
                UIDropDownMenu_AddButton(info, level)
                info.text = "Vertical"
                info.arg1 = ori.vert
                info.checked = currentOri == info.arg1
                UIDropDownMenu_AddButton(info, level)
                info.text = "Vertical (Reversed)"
                info.arg1 = ori.vertr
                info.checked = currentOri == info.arg1
                UIDropDownMenu_AddButton(info, level)
            end
            -- Display a nested group of 10 favorite number options
        end
    end)
end

local function applyFontSize()
    local val = fontSize
    m20:SetTextScale(val)
    m10:SetTextScale(val)
    m5:SetTextScale(val)
    m1:SetTextScale(val)
    s30:SetTextScale(val)
    s10:SetTextScale(val)
    s2:SetTextScale(val)
end

local function positionTexts()

end

function dropDown:setFontSize(value)
    fontSize = value
    applyFontSize()
end

local function clearIconsPoints()
    for i = 1, totalFramesCount do
        iconsBuffer[i].frame:ClearAllPoints()
    end
end

local function flipXY(frm, rev, anchor, flip)
    local point, relTo, relPoint, offX, offY = frm:GetPoint()
    if rev == true then
        offX, offY = -offX, -offY
    end
    if flip == true then
        offX, offY = offY, offX
    end
    frm:ClearAllPoints()
    frm:SetPoint(point, relTo, anchor, offX, offY)
end

function dropDown:setOrientation(orie)
    local flip = false;
    if ((currentOri == ori.hori or currentOri == ori.horir) and (orie == ori.vert or orie == ori.vertr)) or
        ((currentOri == ori.vert or currentOri == ori.vertr) and (orie == ori.hori or orie == ori.horir)) then
        local sx, sy = CDLine_Frame:GetSize()
        CDLine_Frame:SetSize(sy, sx)
        BACKDROP_DIALOG_0_0.insets = {left=BACKDROP_DIALOG_0_0.insets.top, right=BACKDROP_DIALOG_0_0.insets.bottom,
        top=BACKDROP_DIALOG_0_0.insets.left, bottom=BACKDROP_DIALOG_0_0.insets.right}
        CDLine_Frame.backdropInfo = BACKDROP_DIALOG_0_0
        CDLine_Frame:ApplyBackdrop()
        flip = true
    end

    flipXY(m20, not (orie.rev == currentOri.rev), orie.anchor, flip)
    flipXY(m10, not (orie.rev == currentOri.rev), orie.anchor, flip)
    flipXY(m5, not (orie.rev == currentOri.rev), orie.anchor, flip)
    flipXY(m1, not (orie.rev == currentOri.rev), orie.anchor, flip)
    flipXY(s30, not (orie.rev == currentOri.rev), orie.anchor, flip)
    flipXY(s10, not (orie.rev == currentOri.rev), orie.anchor, flip)
    flipXY(s2, not (orie.rev == currentOri.rev), orie.anchor, flip)
    currentOri = orie
end

function applyLayout()
    applyFontSize()

end
---------------- Events functions ----------------
local events = {}

function events:PLAYER_LOGIN()
end

function events:UNIT_SPELLCAST_SUCCEEDED(who, cast, spellid)
    if addonLoaded == false then
        return
    end

    if who == "player" then
        local curIdx = cdl_idx
        cdl_idx = cdl_idx + 1
        spellsOnCooldown[curIdx] = {
            stage = cdline_stage.start,
            spellID = spellid,
            iconFrame = getAvailableIconFrame()
        }
        -- spellsOnCooldown[curIdx]['frame']:SetPoint('CENTER', CDLine_Frame, 'LEFT', 0, 0)
        spellsOnCooldown[curIdx].iconFrame.inUse = true
        spellsOnCooldown[curIdx].iconFrame.texture:SetTexture(GetSpellTexture(spellid))
        spellsOnCooldown[curIdx].iconFrame.texture:SetAllPoints()
    end
end

function events:SPELL_UPDATE_COOLDOWN()

end

local function calcTimingAndOffset(left, duration)
    local prevTime = duration
    local stage = 0
    local percentage = 0
    local offset = 0
    for timeKey, timeVal in pairs(timings) do
        if left > timeVal.time then
            percentage = (left - timeVal.time) / (prevTime - timeVal.time)
            offset = timeVal.offset - stage
            return percentage, stage, offset
        else
            stage = timeVal.offset
            prevTime = timeVal.time
        end
    end
    return percentage, stage, offset
end

function OnUpdate(self, elapsed)
    local idx = 0;
    local start, duration, enabled, mod
    local cdLw, cdLh = CDLine_Frame:GetSize();
    local w;
    for k, v in pairs(spellsOnCooldown) do
        idx = idx + 1
        start, duration, enabled, mod = GetSpellCooldown(v.spellID)
        if spellsOnCooldown[k].iconFrame == nil then
            spellsOnCooldown[k] = nil
        elseif v.stage == cdline_stage.start then
            if start > 0 and duration > 0 then
                local counting = GetTime() - start
                local left = duration - counting
                local percentage = 0
                local stage = 0;
                local prevTime = duration
                local set = false
                local posBaseX, posBaseY = 0, 0

                percentage, stage, w = calcTimingAndOffset(left, duration)
                percentage = 1 - percentage
                local advancing = w * percentage
                advancing = stage + advancing
                local x, y = advancing, 0;
                if currentOri.swxy == true then
                    x, y = y, x
                end
                if currentOri.rev == true then
                    x, y = -x, -y
                end

                -- spellsOnCooldown[k].iconFrame.frame:SetPoint('CENTER', CDLine_Frame, 'LEFT', x, y)
                spellsOnCooldown[k].iconFrame.frame:SetPoint('CENTER', CDLine_Frame, currentOri.anchor, x, y)
                spellsOnCooldown[k].endpoint = {x=x, y=y}
            else
                if v.endpoint == nil then
                    spellsOnCooldown[k].stage = cdline_stage.ended
                else
                    spellsOnCooldown[k].stage = cdline_stage.ending
                    spellsOnCooldown[k].timeEnding = GetTime()
                end
            end
        elseif v.stage == cdline_stage.ending then
            local percentage = (GetTime() - v.timeEnding) / 0.1
            local alphaSize = percentage
            -- spellsOnCooldown[k].iconFrame.frame:SetPoint('CENTER', CDLine_Frame, 'LEFT',
            local runX, runY = 0, 0
            if currentOri.rev == true then
                percentage = -percentage
            end

            if v.endpoint.x == 0 then
                runY = v.endpoint.y + (iconDim * percentage)
            end

            if v.endpoint.y == 0 then
                runX = v.endpoint.x + (iconDim * percentage)
            end

            spellsOnCooldown[k].iconFrame.frame:SetPoint('CENTER', CDLine_Frame, currentOri.anchor, runX, runY)
            local newSize = iconDim + (50 * alphaSize)
            spellsOnCooldown[k].iconFrame.frame:SetSize(newSize, newSize);
            if alphaSize >= 1 then
                spellsOnCooldown[k].stage = cdline_stage.ended
            else
                spellsOnCooldown[k].iconFrame.frame:SetAlpha(1 - alphaSize);
            end
        elseif v.stage == cdline_stage.ended then
            spellsOnCooldown[k].iconFrame.frame:Hide()
            spellsOnCooldown[k].iconFrame.inUse = false
            spellsOnCooldown[k] = nil
        end
    end
end

---------------- Events handler ----------------

function OnEventFunction(self, event, ...)
    events[event](self, ...)
end

function OnMouseUp(self, button)
    if button == "RightButton" then
        buildDropDown()
        ToggleDropDownMenu(1, nil, dropDown, "cursor", 3, -3)
    end
end

---------------- Slash Commands ----------------

function showFrame(msg, editBox)
    CDLine_Frame:Show()
end
SlashCmdList["CDLSHOW"] = showFrame
