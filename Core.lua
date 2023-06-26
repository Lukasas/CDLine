---------------- Globals  ----------------

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

local timings = {
    {text="20", offset=5, time=20*60},
    {text="10", offset=20, time=10*60},
    {text="5", offset=35, time=5*60},
    {text="1", offset=60, time=1*60},
    {text="30", offset=95, time=30},
    {text="10", offset=135, time=10},
    {text="2", offset=180, time=2},
    {text="", offset=200, time=0}
}

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
        iconsBuffer[idx] = {inUse = false, frame = frame, texture = frame:CreateTexture()}
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
    iconsBuffer[totalFramesCount] = {inUse = false, frame = frame, texture = frame:CreateTexture()}
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
        spellsOnCooldown[curIdx] = {stage = cdline_stage.start, spellID = spellid, iconFrame = getAvailableIconFrame()}
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

                percentage, stage, w = calcTimingAndOffset(left, duration)
                percentage = 1 - percentage
                spellsOnCooldown[k].iconFrame.frame:SetPoint('CENTER', CDLine_Frame, 'LEFT', stage + (w) * percentage, 0)
                spellsOnCooldown[k].endpoint = (cdLw) * percentage
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
            spellsOnCooldown[k].iconFrame.frame:SetPoint('CENTER', CDLine_Frame, 'LEFT', v.endpoint + (iconDim * percentage), 0)
            local newSize = iconDim + (50*percentage)
            spellsOnCooldown[k].iconFrame.frame:SetSize(newSize, newSize);
            if percentage >= 1 then
                spellsOnCooldown[k].stage = cdline_stage.ended
            else
                spellsOnCooldown[k].iconFrame.frame:SetAlpha(1 - percentage);
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

---------------- Slash Commands ----------------


function showFrame(msg, editBox)
    CDLine_Frame:Show()
end
SlashCmdList["CDLSHOW"] = showFrame
