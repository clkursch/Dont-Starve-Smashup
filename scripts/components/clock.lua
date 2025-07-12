--------------------------------------------------------------------------
--[[ Clock ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local NUM_SEGS = 16

local PHASE_NAMES = --keep in sync with shard_clock.lua NUM_PHASES
{
    "day",
    "dusk",
    "night",
}
local PHASES = table.invert(PHASE_NAMES)

local MOON_PHASE_NAMES =
{
    "new",
    "quarter",
    "half",
    "threequarter",
    "full",
}
local MOON_PHASES = table.invert(MOON_PHASE_NAMES)
local MOON_PHASE_LENGTHS =
{
    [MOON_PHASES.new] =             1,
    [MOON_PHASES.quarter] =         3,
    [MOON_PHASES.half] =            3,
    [MOON_PHASES.threequarter] =    3,
    [MOON_PHASES.full] =            1,
}
local MOON_PHASE_CYCLE = {}
for i = 1, #MOON_PHASE_NAMES do
    for x = 1, MOON_PHASE_LENGTHS[i] do
        table.insert(MOON_PHASE_CYCLE, i)
    end
end
for i = #MOON_PHASE_NAMES - 1, 2, -1 do
    for x = 1, MOON_PHASE_LENGTHS[i] do
        table.insert(MOON_PHASE_CYCLE, i)
    end
end
MOON_PHASE_LENGTHS = nil

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst
--12-17-17 LETS TRY TO MAKE SOME PUBLIC VARS --NO THESE DONT WORK CLIENTSIDE
self.MATCH_SEGS = 16
self.TOTAL_MATCH_LENGTH = 0

--Private
local _world = TheWorld
local _ismastersim = _world.ismastersim
local _ismastershard = _world.ismastershard
local _segsdirty = true
local _cyclesdirty = true
local _phasedirty = true
local _moonphasedirty = true
-- DST CHANGE 12-23-17
local _totalmatchlengthdirty = true
local _numbermatchsegsdirty = true

--Network
local _segs = {}
for i, v in ipairs(PHASE_NAMES) do
    _segs[i] = net_smallbyte(inst.GUID, "clock._segs."..v, "segsdirty")
end
local _cycles = net_ushortint(inst.GUID, "clock._cycles", "cyclesdirty")
local _phase = net_tinybyte(inst.GUID, "clock._phase", "phasedirty")
local _moonphase = net_tinybyte(inst.GUID, "clock._moonphase", "moonphasedirty")
local _mooniswaxing = net_bool(inst.GUID, "clock._mooniswaxing", "moonphasedirty")
local _totaltimeinphase = net_float(inst.GUID, "clock._totaltimeinphase")
local _remainingtimeinphase = net_float(inst.GUID, "clock._remainingtimeinphase")

--ALRIGHT ALRIGHT, ILL MAKE MY OWN - DST CHANGE 12-23-17
local _totalmatchlength = net_byte(inst.GUID, "clock._totalmatchlength", "totalmatchlengthdirty")
local _numbermatchsegs = net_byte(inst.GUID, "clock._numbermatchsegs", "numbermatchsegsdirty")

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function SetDefaultSegs()
    local totalsegs = 0
    for i, v in ipairs(_segs) do
        v:set(TUNING[string.upper(PHASE_NAMES[i]).."_SEGS_DEFAULT"] or 0)
        totalsegs = totalsegs + v:value()
    end

    if totalsegs ~= NUM_SEGS then
        for i, v in ipairs(_segs) do
            v:set(0)
        end
        _segs[PHASES.day]:set(NUM_SEGS)
    end
end

local function CalculateMoonPhase(cycles)
    --V2C: After waxing/waning changes, moon phase is
    --     now advanced at the beginning of each day.
    --[[
    -- don't advance the moon until nighttime
    if _phase:value() ~= PHASES.night and cycles > 0 then
        cycles = cycles - 1
    end]]

    local m = cycles % #MOON_PHASE_CYCLE
    local waxing = 2 * m < #MOON_PHASE_CYCLE
    return MOON_PHASE_CYCLE[m + 1], waxing
end

local ForceResync = _ismastersim and function(netvar)
    netvar:set_local(netvar:value())
    netvar:set(netvar:value())
end or nil

--------------------------------------------------------------------------
--[[ Private event listeners ]]
--------------------------------------------------------------------------

local function OnPlayerActivated()
    _segsdirty = true
    _cyclesdirty = true
    _phasedirty = true
    _moonphasedirty = true
end

local OnSetClockSegs = _ismastersim and function(src, segs, minutes)
    local normremaining = _totaltimeinphase:value() > 0 and (_remainingtimeinphase:value() / _totaltimeinphase:value()) or 1

    if segs then
        local totalsegs = 0
        -- for i, v in ipairs(_segs) do
            -- v:set(segs[PHASE_NAMES[i]] or 0)
            -- totalsegs = totalsegs + v:value()
        -- end
		
		
		
		--12-17-17 FIRST LETS JUST COUNT THE NUMBER OF SEGS
		-- for i, v in ipairs(segs) do
		-- for k, v in pairs(segs) do --MAYBE ITS JUST THAT WEIRD DIFFERENT SYNTAX
            -- totalsegs = totalsegs + segs[k]
			-- print("extention number", segs.day, segs.night)
        -- end
		
		--OH... ITS LIKE ONE OF THOSE DOUBLE TABLES.
		totalsegs = totalsegs + segs.day + segs.dusk + segs.night
		
		--LETS GET A ROUGH ESTIMATE ON HOW BIG EACH SEGMENT SHOULD BE TO ADD THEM ALL UP TO 16
		-- local seg_extender = 16 / totalsegs
		local seg_extender = 1 --NEVERMIND, SCRAP THE EXTENDER. THE TIMER WILL SHOW A FAKE DISPLAY THAT IS THE SAME EVERY TIME 12-20-17
		-- print("extention TOTAL", seg_extender)
		
		--12-22-17 OKAY, NOW WE SHOULD SET OUR TIME UP TO AUTOMATICALLY CHOOSE NUMBER OF DAY SEGS BASED ON TIME
		if segs.time then
			if segs.time > 30 then
				segs.time = 30
			end
			
			-- *2 SINCE THERE ARE 2 SEGS PER MINUTE. AND -1 BECAUSE THE LAST SEGMENT IS ALWAYS DUSK
			seg_extender = (segs.time * 2) - 1
			-- seg_extender = (segs.time * 1) - 0.5
			-- print("TIME SEGMENTS ", segs.time, seg_extender)
		end
		
		--6-16-20 MAN IDK WHATS UP WITH THIS MATH BUT ANY NON-WHOLE NUMBER TIMERS FREAK THE FLIP OUT AND OVERSHOOT BY A LOT. 
		--BUT IM TIRED AND I DONT WANT TO DEAL WITH THIS SO IM OUT. 
		--MAYBE I'LL JUST. MAKE THE HAND INVISIBLE OR SOMETHING STUPID
		
		
		--12-29-17 MAYBE SETTING THEM ALL TO 0 FIRST WILL HELP CLIENTS NOTICE THE CHANGE
		-- for i, v in ipairs(_segs) do
            -- v:set(0)
        -- end
		
		--OKAY, NOW WE CAN DO THIS PART
		for i, v in ipairs(_segs) do
            v:set((segs[PHASE_NAMES[i]] or 0) * seg_extender)
			-- v:set((segs[PHASE_NAMES[i]] or 0) + seg_extender) --JUST CURIOUS...
			-- print("SETTING PHASE LENGTHS", (segs[PHASE_NAMES[i]] or 0), seg_extender, ((segs[PHASE_NAMES[i]] or 0) * seg_extender))
            -- totalsegs = totalsegs + v:value()
			seg_extender = 1 --SINCE WE DONT WANT TO EXTEND NIGHT OR DUSK. I THINK
        end
		
		
		--12-26-17 MAYBE THIS WILL HELP THE HOST FIND ITS PLACE
		-- _remainingtimeinphase:set(0)
		_phase:set(2)
		_phase:set(1) --AH HA!!! SETTING IT TO A DIFFERENT PHASE FIRST FORCES IT TO REGISTER IT AS "CHANGED" FOR CLIENT
		-- self:LongUpdate(0) --WHAT DOES THIS EVEN DO??
		
        -- assert(totalsegs == NUM_SEGS, "Invalid number of time segs")
		--self.MATCH_SEGS = totalsegs --DST CHANGE
		--OH YEA, I FORGOT I CAN USE TUNING VALUES ANYWHERE I WANT. THATS HANDY
		-- if minutes then	--YOU CANT TAKE IN A THIRD VARIABLE HERE DUMMY
			-- TUNING.SEG_TIME = (minutes * 60) /16
		-- else
			-- TUNING.SEG_TIME = 30 --THE DEFAULT
		-- end
		
		-- TUNING.SEG_TIME = ((segs[0] or 5)* 60) /16
		-- TUNING.SEG_TIME = (totalsegs* 60) /16
		-- TUNING.NUM_SEGS_SMASH = totalsegs
		-- _moonphase:set(totalsegs) --THIS MAKES THE GAME VERY GRUMPY DO NOT DO THIS
		_numbermatchsegs:set(totalsegs) --USE THIS ONE INSTEAD
		
		
		if segs.time then
			-- TUNING.SEG_TIME = (segs.time* 60) /totalsegs --WHERE I LEFT OFF - THIS MADE THE CLOCK SHOW CORRECTLY, BUT THE TIME OF DAY DIDNT CHANGE
			-- TUNING.SEG_TIME = (segs.time* 30) /totalsegs --EH, LETS TRY 30. THAT GIVES US MORE CONTROL OVER MATCH LENGTH
			-- TUNING.SEG_TIME = totalsegs / 
			-- print("WHATS THE TIMe??", (segs.time* 30), totalsegs)
			
			-- TUNING.SEG_TIME = ((segs.time* 60) /totalsegs) * 1
			-- TUNING.SEG_TIME = 30 --ITS ALREADY 30 YA DINGUS
			
			--6-16-20 MAYBE ITS THIS??? WHO KNOWS
			local segstime = segs.time
			self.TOTAL_MATCH_LENGTH = segstime
			_totalmatchlength:set(segstime)
			
		else
			_totalmatchlength:set(30) 	--8 THE TIME OF A USUAL DAY
		end
		
		
    else
        SetDefaultSegs()
    end

    _totaltimeinphase:set(_segs[_phase:value()]:value() * TUNING.SEG_TIME)
    -- _remainingtimeinphase:set(normremaining * _totaltimeinphase:value())
	_remainingtimeinphase:set(_totaltimeinphase:value()) --12-26-17 SINCE WE NEVER CHANGE IT MID-MATCH
end or nil

local OnSetPhase = _ismastersim and function(src, phase)
    phase = PHASES[phase]
    if phase then
        _phase:set(phase)
        _totaltimeinphase:set(_segs[phase]:value() * TUNING.SEG_TIME)
        _remainingtimeinphase:set(_totaltimeinphase:value())
    end
    self:LongUpdate(0)
end or nil

local OnNextPhase = _ismastersim and function()
    _remainingtimeinphase:set(0)
    self:LongUpdate(0)
end or nil

local OnNextCycle = _ismastersim and function()
    _phase:set(#PHASE_NAMES)
    _remainingtimeinphase:set(0)
    self:LongUpdate(0)
end or nil

local OnSimUnpaused = _ismastersim and function()
    --Force resync values that client may have simulated locally
    ForceResync(_remainingtimeinphase)
end or nil

local OnClockUpdate = _ismastersim and not _ismastershard and function(src, data)
    for i, v in ipairs(_segs) do
        v:set(data.segs[i])
    end
    _cycles:set(data.cycles)
    _phase:set(data.phase)
    _moonphase:set(data.moonphase)	--YOINK -DST CHANGE
    _mooniswaxing:set(data.mooniswaxing)
    _totaltimeinphase:set(data.totaltimeinphase)
    _remainingtimeinphase:set(data.remainingtimeinphase)
    self:LongUpdate(0)
end or nil

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Initialize network variables
SetDefaultSegs()
_cycles:set(0)
_phase:set(PHASES.day)
local moonphase, waxing = CalculateMoonPhase(_cycles:value())
_moonphase:set(moonphase)
_mooniswaxing:set(waxing)
_totaltimeinphase:set(_segs[_phase:value()]:value() * TUNING.SEG_TIME)
_remainingtimeinphase:set(_totaltimeinphase:value())

--DST CHANGE 12-23-17
_totalmatchlength:set(5) 
_numbermatchsegs:set(16)

--Register network variable sync events
inst:ListenForEvent("segsdirty", function() _segsdirty = true end)
inst:ListenForEvent("cyclesdirty", function() _cyclesdirty = true end)
inst:ListenForEvent("phasedirty", function() _phasedirty = true end)
inst:ListenForEvent("moonphasedirty", function() _moonphasedirty = true end)
inst:ListenForEvent("playeractivated", OnPlayerActivated, _world)

--DST CHANGE 12-23-17
inst:ListenForEvent("totalmatchlengthdirty", function() _totalmatchlengthdirty = true end)
inst:ListenForEvent("numbermatchsegsdirty", function() _numbermatchsegsdirty = true end)


if _ismastersim then
    --Register master simulation events
    inst:ListenForEvent("ms_setclocksegs", OnSetClockSegs, _world)
    inst:ListenForEvent("ms_setphase", OnSetPhase, _world)
    inst:ListenForEvent("ms_nextphase", OnNextPhase, _world)
    inst:ListenForEvent("ms_nextcycle", OnNextCycle, _world)
    inst:ListenForEvent("ms_simunpaused", OnSimUnpaused, _world)

    if not _ismastershard then
        --Register slave shard events
        inst:ListenForEvent("slave_clockupdate", OnClockUpdate, _world)
    end
end

inst:StartUpdatingComponent(self)

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

--[[
    Client updates time on its own, while server force syncs to correct it
    at the end of each segment.  Client cannot change segments on its own,
    and must wait for a server sync to change segments.
--]]
function self:OnUpdate(dt)
    local remainingtimeinphase = _remainingtimeinphase:value() - dt

    if remainingtimeinphase > 0 then
        --Advance time in current phase
        local numsegsinphase = _segs[_phase:value()]:value()
        local prevseg = numsegsinphase > 0 and math.ceil(_remainingtimeinphase:value() / _totaltimeinphase:value() * numsegsinphase) or 0
        local nextseg = numsegsinphase > 0 and math.ceil(remainingtimeinphase / _totaltimeinphase:value() * numsegsinphase) or 0

        if prevseg == nextseg then
            --Client and server tick independently within current segment
            _remainingtimeinphase:set_local(remainingtimeinphase)
        elseif _ismastersim then
            --Server sync to client when segment changes
            _remainingtimeinphase:set(remainingtimeinphase)
        else
            --Client must wait at end of segment for a server sync
            remainingtimeinphase = numsegsinphase > 0 and nextseg / numsegsinphase * _totaltimeinphase:value() or 0
            _remainingtimeinphase:set_local(math.min(remainingtimeinphase + .001, _remainingtimeinphase:value()))
        end
    elseif _ismastershard then
        --Advance to next phase
        _remainingtimeinphase:set_local(0)

        while _remainingtimeinphase:value() <= 0 do
            _phase:set((_phase:value() % #PHASE_NAMES) + 1)
            _totaltimeinphase:set(_segs[_phase:value()]:value() * TUNING.SEG_TIME)
            _remainingtimeinphase:set(_totaltimeinphase:value())

            if _phase:value() == 1 then
                --Advance to next cycle
                _cycles:set(_cycles:value() + 1)
                _world:PushEvent("ms_cyclecomplete", _cycles:value())
            --V2C: After waxing/waning changes, moon phase is
            --     now advanced at the beginning of each day.
            --[[
            end

            if _phase:value() == PHASES.night then
            ]]
                --Advance to next moon phase
				
				
				--12-23-17 I DONT FEEL LIKE MAKING A WHOLE NEW NETVAR SO... LETS JUST HIJACK MOONPHASE~ DST CHANGE
				
                local moonphase, waxing = CalculateMoonPhase(_cycles:value())
                if moonphase ~= _moonphase:value() then
                    _moonphase:set(moonphase)
                end
                if waxing ~= _mooniswaxing:value() then
                    _mooniswaxing:set(waxing)
                end
				
				
				
				
            end
        end

        if remainingtimeinphase < 0 then
            self:OnUpdate(-remainingtimeinphase)
            return
        end
    else
        --Clients and slaves must wait at end of phase for a server sync
        _remainingtimeinphase:set_local(math.min(.001, _remainingtimeinphase:value()))
    end

    if _segsdirty then
        local data = {}
        for i, v in ipairs(_segs) do
            data[PHASE_NAMES[i]] = v:value()
        end
        _world:PushEvent("clocksegschanged", data)
        _segsdirty = false
    end

    if _cyclesdirty then
        _world:PushEvent("cycleschanged", _cycles:value())
        _cyclesdirty = false
    end

    if _phasedirty then
        _world:PushEvent("phasechanged", PHASE_NAMES[_phase:value()])
        _phasedirty = false
    end

	--12-23-17 DST CHANGE - WHO NEEDS THIS ANYWAYS
    -- if _moonphasedirty then
        -- --"moonphasechanged" deprecated, still pushing for old mods
        -- _world:PushEvent("moonphasechanged", MOON_PHASE_NAMES[_moonphase:value()])
        -- _world:PushEvent("moonphasechanged2", { moonphase = MOON_PHASE_NAMES[_moonphase:value()], waxing = _mooniswaxing:value() })
        -- _moonphasedirty = false
    -- end
	
	--DST CHANGE 12-23-17
	if _totalmatchlengthdirty then
        _world:PushEvent("totalmatchlengthchanged", _totalmatchlength:value())
        _totalmatchlengthdirty = false
    end
	
	if _numbermatchsegsdirty then
        _world:PushEvent("numbermatchsegschanged", _numbermatchsegs:value())
        _numbermatchsegsdirty = false
    end
	
	

    local elapsedsegs = 0
    local normtimeinphase = 0
    for i, v in ipairs(_segs) do
        if _phase:value() == i then
            normtimeinphase = 1 - (_totaltimeinphase:value() > 0 and _remainingtimeinphase:value() / _totaltimeinphase:value() or 0)
            elapsedsegs = elapsedsegs + v:value() * normtimeinphase
            break
        end
        elapsedsegs = elapsedsegs + v:value()
    end
    -- _world:PushEvent("clocktick", { phase = PHASE_NAMES[_phase:value()], timeinphase = normtimeinphase, time = elapsedsegs / TUNING.NUM_SEGS_SMASH })
	
	
	--12-22-17 MORE MATH. GET THE TOTAL COUNTDOWN TIMER FOR ALL SEGMENTS OF DAY AND DUSK
	local match_countdown = 0
	if _phase:value() == 1 then
		--REMAINING TIME IN CURRENT PHASE + ALL TIME IN DUSK PHASE
		match_countdown = _remainingtimeinphase:value() + (_segs[2]:value() * 30) --* TUNING.SEG_TIME
		-- print("---- SUNDOWN COUNTDOWN ", _remainingtimeinphase:value() , _segs[2]:value() * 30)
	elseif _phase:value() == 2 then
		match_countdown = _remainingtimeinphase:value() --NOW DUSK IS THE ONLY THING LEFT
	end
	
	
	--12-20-17 TIME TO MAKE MY OWN VERSION OF THIS.
	_world:PushEvent("clocktick", { 
			phase = PHASE_NAMES[_phase:value()], 
			timeinphase = normtimeinphase, 
			-- time = elapsedsegs / TUNING.NUM_SEGS_SMASH,	--ACTUALLY... LETS LEAVE THIS THE SAME. SINCE THE REST OF THE GAME ALSO USES THIS.
			-- time = elapsedsegs / _moonphase:value(),	--NO!! MESSING WITH MOONPHASES MAKES BAD THINGS HAPPEN
			time = elapsedsegs / _numbermatchsegs:value(),
			matchtime_current = elapsedsegs * TUNING.SEG_TIME,
			-- matchtime_remaining = _remainingtimeinphase:value(), --THIS IS BASICALLY "HOW MANY SECONDS UNTIL THE NEXT TIME OF DAY HITS"
			matchtime_remaining = match_countdown,
			-- matchtimelimit = self.TOTAL_MATCH_LENGTH * 60	---12-22-17 AND... LETS ADD SOMETHING OF OUR OWN.
			matchtimelimit = _totalmatchlength:value() * 60
			
			--OKAY, GIMME A WORK SPACE
				-- _totaltimeinphase:set(_segs[_phase:value()]:value() * TUNING.SEG_TIME)
				-- _remainingtimeinphase:set(_totaltimeinphase:value())
		
		
		
		
		}
	)
	-- print("ELAPSED TIMe??", elapsedsegs, _moonphase:value(), _totalmatchlength:value() ) 
	-- print("PHASE DATA", _totaltimeinphase:value() ,_remainingtimeinphase:value(), _phase:value() )
		-- _totaltimeinphase:set(_segs[_phase:value()]:value() * TUNING.SEG_TIME)
		-- _remainingtimeinphase:set(_totaltimeinphase:value())
	
    if _ismastershard then
        local data =
        {
            segs = {},
            cycles = _cycles:value(),
            moonphase = _moonphase:value(),
            mooniswaxing = _mooniswaxing:value(),
            phase = _phase:value(),
            totaltimeinphase = _totaltimeinphase:value(),
            remainingtimeinphase = _remainingtimeinphase:value(),
        }
        for i, v in ipairs(_segs) do
            table.insert(data.segs, v:value())
        end
        _world:PushEvent("master_clockupdate", data)
    end
end

self.LongUpdate = self.OnUpdate

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

if _ismastersim then function self:OnSave()
    local data =
    {
        segs = {},
        cycles = _cycles:value(),
        phase = PHASE_NAMES[_phase:value()],
        moonphase2 = MOON_PHASE_NAMES[_moonphase:value()],
        moonwaxing = _mooniswaxing:value(),
        totaltimeinphase = _totaltimeinphase:value(),
        remainingtimeinphase = _remainingtimeinphase:value(),
    }

    for i, v in ipairs(_segs) do
        data.segs[PHASE_NAMES[i]] = v:value()
    end

    return data
end end

if _ismastersim then function self:OnLoad(data)
    local totalsegs = 0
    for i, v in ipairs(_segs) do
        v:set(data.segs and data.segs[PHASE_NAMES[i]] or 0)
        totalsegs = totalsegs + v:value()
    end

    if totalsegs ~= NUM_SEGS then
        SetDefaultSegs()
    end

    _cycles:set(data.cycles or 0)

    if PHASES[data.phase] then
        _phase:set(PHASES[data.phase])
    else
        for i, v in ipairs(_segs) do
            if v:value() > 0 then
                _phase:set(i)
                break
            end
        end
    end

    --moonphase deprecated, moonphase2 is paired with waxing
    local moonphase, waxing = data.moonphase2 ~= nil and MOON_PHASES[data.moonphase2] or nil, data.moonwaxing == true
    if moonphase == nil then
        moonphase, waxing = CalculateMoonPhase(_cycles:value())
    end
    _moonphase:set(moonphase)
    _mooniswaxing:set(waxing)
    _totaltimeinphase:set(data.totaltimeinphase or _segs[_phase:value()]:value() * TUNING.SEG_TIME)
    _remainingtimeinphase:set(math.min(data.remainingtimeinphase or _totaltimeinphase:value(), _totaltimeinphase:value()))
end end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    return string.format("%d %s: %2.2f ", _cycles:value() + 1, PHASE_NAMES[_phase:value()], _remainingtimeinphase:value())
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
