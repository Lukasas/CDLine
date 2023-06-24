---------------- Globals  ----------------

SLASH_REC1 = "/cdline"
movable = true
spellsOnCooldown = {}
cdline_icon_frames = {}
cdline_stage = {
    start = 1,
    ending = 2,
    ended = 3
}
cdl_idx = 0

function getLen(input)
    if input == nil then
        return 0
    end

    local counter = 0
    for k, v in pairs(input) do
        counter = counter + 1
    end
    return counter
end
---------------- Timers ----------------

---------------- Addon Functions ----------------

function ShowMinimapTooltip()
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(ListOfItemsRecordedFrame, "ANCHOR_CURSOR")
    GameTooltip:SetText('Hello World')
    GameTooltip:Show()
end

function dump(o)
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

function ShowTooltip(text)
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(CDLine_Frame, "ANCHOR_CURSOR")
    GameTooltip:SetText(text)
    GameTooltip:Show()
end

function HideTooltip()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
end

---------------- Buttons Click ----------------

---------------- Events functions ----------------
local events = {}

function events:PLAYER_LOGIN()
end

function events:UNIT_SPELLCAST_SUCCEEDED(who, cast, spellid)
    if who == "player" then
        local curIdx = cdl_idx
        cdl_idx = cdl_idx + 1
        spellsOnCooldown[curIdx] = {stage = cdline_stage.start, spellID = spellid, frame = CreateFrame('BUTTON', "spell" .. tostring(spellid), CDLine_Frame, 'CooldownIcon') }
        -- spellsOnCooldown[curIdx]['frame']:SetPoint('CENTER', CDLine_Frame, 'LEFT', 0, 0)
        local texture = spellsOnCooldown[curIdx]['frame']:CreateTexture(nil, "BACKGROUND")
        texture:SetTexture(GetSpellTexture(spellid))
        texture:SetAllPoints()
    end
end

function events:SPELL_UPDATE_COOLDOWN()

end

local iconDim = 10;

local pos = {
    m20 = 5,
    m10 = 20,
    m5 = 35,
    m1 = 60,
    s30 = 95,
    s10 = 135,
    s2 = 180
};

local times = {
    m20 = 20*60,
    m10 = 10*60,
    m5 = 5*60,
    m1 = 1*60,
    s30 = 30,
    s10 = 10,
    s2 = 2
}

function OnUpdate(self, elapsed)
    local idx = 0;
    local start, duration, enabled, mod
    local cdLw, cdLh = CDLine_Frame:GetSize();
    local w;
    for k, v in pairs(spellsOnCooldown) do
        idx = idx + 1
        start, duration, enabled, mod = GetSpellCooldown(v.spellID)
        if v.stage == cdline_stage.start then
            if start > 0 and duration > 0 then
                local counting = GetTime() - start
                local left = duration - counting
                local percentage = counting / duration
                local stage = 0;

                -- refactor - tables and cycles
                if left > times.m20 then
                    percentage = (left - times.m20) / (duration - times.m20)
                    stage = 0
                    w = pos.m20
                elseif left > times.m10 then
                    percentage = (left - times.m10) / (times.m20 - times.m10)
                    stage = pos.m20
                    w = pos.m10 - stage
                elseif left > times.m5 then
                    percentage = (left - times.m5) / (times.m10 - times.m5)
                    stage = pos.m10
                    w = pos.m5 - stage
                elseif left > times.m1 then
                    percentage = (left - times.m1) / (times.m5 - times.m1)
                    stage = pos.m5
                    w = pos.m1 - stage
                elseif left > times.s30 then
                    percentage = (left - times.s30) / (times.m1 - times.s30)
                    stage = pos.m1
                    w = pos.s30 - stage
                elseif left > times.s10 then
                    percentage = (left - times.s10) / (times.s30 - times.s10)
                    stage = pos.s30
                    w = pos.s10 - stage
                elseif left > times.s2 then
                    percentage = (left - times.s2) / (times.s10 - times.s2)
                    stage = pos.s10
                    w = pos.s2 - stage
                else
                    percentage = left / times.s2
                    stage = pos.s2
                    w = cdLw - stage
                end
                percentage = 1 - percentage

                spellsOnCooldown[k]['frame']:SetPoint('CENTER', CDLine_Frame, 'LEFT', stage + (w) * percentage, 0)
                spellsOnCooldown[k].endpoint = (cdLw) * percentage
                -- print("Spell" , tostring(k) , " is on cooldown for " , tostring(takes) , " more seconds.")
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
            spellsOnCooldown[k].frame:SetPoint('CENTER', CDLine_Frame, 'LEFT', v.endpoint + (iconDim * percentage), 0)
            local newSize = iconDim + (50*percentage)
            spellsOnCooldown[k].frame:SetSize(newSize, newSize);
            if percentage >= 1 then
                spellsOnCooldown[k].stage = cdline_stage.ended
            else
                spellsOnCooldown[k].frame:SetAlpha(1 - percentage);
            end
        elseif v.stage == cdline_stage.ended then
            spellsOnCooldown[k]['frame']:Hide()
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
