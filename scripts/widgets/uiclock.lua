--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"
local UIAnim = require "widgets/uianim"
local easing = require "easing"

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local NUM_SEGS = 16
local DAY_COLOUR = Vector3(254 / 255, 212 / 255, 86 / 255)
local DUSK_COLOUR = Vector3(165 / 255, 91 / 255, 82 / 255)
local CAVE_DAY_COLOUR = Vector3(174 / 255, 195 / 255, 108 / 255)
local CAVE_DUSK_COLOUR = Vector3(113 / 255, 127 / 255, 108 / 255)
local DARKEN_PERCENT = .75

--------------------------------------------------------------------------
--[[ Constructor ]]
--------------------------------------------------------------------------

local UIClock = Class(Widget, function(self)
    Widget._ctor(self, "Clock")

    --Member variables
    self._cave = TheWorld ~= nil and TheWorld:HasTag("cave")
    self._caveopen = nil
    self._lastsinkhole = nil --cache last known sinkhole for optimization
    self._moonanim = nil
    self._anim = nil
    self._face = nil
    self._segs = {}
    self._daysegs = nil
    self._rim = nil
    self._hands = nil
    self._text = nil
    self._showingcycles = nil
    self._cycles = nil
    self._phase = nil
    self._moonphase = nil
    self._mooniswaxing = nil
    self._time = nil

    local basescale = 1
    self:SetScale(basescale, basescale, basescale)
    self:SetPosition(0, 0, 0)

    if not self._cave then
        self._moonanim = self:AddChild(UIAnim())
        self._moonanim:GetAnimState():SetBank("moon_phases_clock")
        self._moonanim:GetAnimState():SetBuild("moon_phases_clock")
        self._moonanim:GetAnimState():PlayAnimation("hidden")

        self._anim = self:AddChild(UIAnim())
        self._anim:GetAnimState():SetBank("clock01")
        self._anim:GetAnimState():SetBuild("clock_transitions")
        self._anim:GetAnimState():PlayAnimation("idle_day", true)
    end

    self._face = self:AddChild(Image("images/hud.xml", "clock_NIGHT.tex"))
    self._face:SetClickable(false)

    local segscale = .4
    for i = 1, NUM_SEGS do
        local seg = self:AddChild(Image("images/hud.xml", "clock_wedge.tex"))
        seg:SetScale(segscale, segscale, segscale)
        seg:SetHRegPoint(ANCHOR_LEFT)
        seg:SetVRegPoint(ANCHOR_BOTTOM)
        seg:SetRotation((i - 1) * (360 / NUM_SEGS))
        seg:SetClickable(false)
        table.insert(self._segs, seg)
    end

    if self._cave then
        self._rim = self:AddChild(UIAnim())
        self._rim:GetAnimState():SetBank("clock01")
        self._rim:GetAnimState():SetBuild("cave_clock")
        self._rim:GetAnimState():PlayAnimation("on")

        self._hands = self:AddChild(Widget("clockhands"))
        self._hands._img = self._hands:AddChild(Image("images/hud.xml", "clock_hand.tex"))
        self._hands._img:SetClickable(false)
        self._hands._animtime = nil
    else
        self._rim = self:AddChild(Image("images/hud.xml", "clock_rim.tex"))
        self._rim:SetClickable(false)

        self._hands = self:AddChild(Image("images/hud.xml", "clock_hand.tex"))
        self._hands:SetClickable(false)
    end

    self._text = self:AddChild(Text(BODYTEXTFONT, 33 / basescale))
    self._text:SetPosition(5, 0 / basescale, 0)

    --Default initialization
    self:UpdateWorldString()
    self:OnClockSegsChanged({ day = NUM_SEGS })

    --Register events
    self.inst:ListenForEvent("clocksegschanged", function(inst, data) self:OnClockSegsChanged(data) end, TheWorld)
    self.inst:ListenForEvent("cycleschanged", function(inst, data) self:OnCyclesChanged(data) end, TheWorld)
    if not self._cave then
        self.inst:ListenForEvent("phasechanged", function(inst, data) self:OnPhaseChanged(data) end, TheWorld)
        self.inst:ListenForEvent("moonphasechanged2", function(inst, data) self:OnMoonPhaseChanged2(data) end, TheWorld)
    end
    self.inst:ListenForEvent("clocktick", function(inst, data) self:OnClockTick(data) end, TheWorld)
end)

--------------------------------------------------------------------------
--[[ Member functions ]]
--------------------------------------------------------------------------

function UIClock:UpdateDayString(override) --12-22-17 DST CHANGE- LETS GIVE THIS BOI A NEW FACE
    
	--12-22-17
	if override then	--IT JUST CHECKS FOR MATCHTIME. IF IT GETS IT, NOTHING ELSE IS DISPLAYED. IF NOT, EVERYTHING ELSE IS
		self._text:SetString(tostring(override))
	else
		if self._cycles ~= nil then
			local cycles_lived = ThePlayer.Network:GetPlayerAge()
			self._text:SetString(STRINGS.UI.HUD.CLOCKSURVIVED.."\n"..tostring(cycles_lived).." "..(cycles_lived == 1 and STRINGS.UI.HUD.CLOCKDAY or STRINGS.UI.HUD.CLOCKDAYS))
		end
		self._showingcycles = false
	end
end

function UIClock:UpdateWorldString()
    if self._cycles ~= nil then
		--Todo(Peter):get rid of this platform branch and use the same subfmt on all platforms.
		if PLATFORM == "WIN32_RAIL" then
        	local day_text = subfmt(STRINGS.UI.HUD.WORLD_CLOCKDAY_V2,{day_count = self._cycles + 1})
	    	self._text:SetString(day_text)
		else
			self._text:SetString(STRINGS.UI.HUD.WORLD_CLOCKDAY.." "..tostring(self._cycles + 1))
		end
    end
    self._showingcycles = true
end

function UIClock:ShowMoon()
    local moon_syms =
    {
        full = "moon_full",
        quarter = self._mooniswaxing and "moon_quarter_wax" or "moon_quarter",
        new = "moon_new",
        threequarter = self._mooniswaxing and "moon_three_quarter_wax" or "moon_three_quarter",
        half = self._mooniswaxing and "moon_half_wax" or "moon_half",
    }

    -- self._moonanim:GetAnimState():OverrideSymbol("swap_moon", "moon_phases", moon_syms[self._moonphase] or "moon_full")
    
	--12-17-17 WHO CARES ABOUT MOON PHASE. LETS JUST GET A CRESCENT MOON TO SIGNIFY ITS NIGHT
	self._moonanim:GetAnimState():OverrideSymbol("swap_moon", "moon_phases", "moon_quarter_wax" or "moon_full")
    
	
	if self._phase ~= nil then
        self._moonanim:GetAnimState():PlayAnimation("trans_out")
        self._moonanim:GetAnimState():PushAnimation("idle", true)
    else
        self._moonanim:GetAnimState():PlayAnimation("idle", true)
    end
end

function UIClock:IsCaveClock()
    return self._cave
end

local function CalculateLightRange(light, iscaveclockopen)
    return light:GetCalculatedRadius() * math.sqrt(1 - light:GetFalloff()) + (iscaveclockopen and 1 or -1)
end

function UIClock:UpdateCaveClock(owner)
    if self._lastsinkhole ~= nil and
        self._lastsinkhole:IsValid() and
        self._lastsinkhole.Light:IsEnabled() and
        self._lastsinkhole:IsNear(owner, CalculateLightRange(self._lastsinkhole.Light, self._caveopen)) then
        -- Still near last found sinkhole, can skip FineEntity =)
        self:OpenCaveClock()
        return
    end

    self._lastsinkhole = FindEntity(owner, 20, function(guy) return guy:IsNear(owner, CalculateLightRange(guy.Light, self._caveopen)) end, { "sinkhole", "lightsource" })

    if self._lastsinkhole ~= nil then
        self:OpenCaveClock()
    else
        self:CloseCaveClock()
    end
end

function UIClock:OpenCaveClock()
    if not self._cave or self._caveopen == true then
        return
    elseif self._caveopen == nil then
        self._rim:GetAnimState():PlayAnimation("on")
        self._hands._img:SetScale(1, 1, 1)
        self._hands._img:Show()
    else
        self._rim:GetAnimState():PlayAnimation("open")
        self._rim:GetAnimState():PushAnimation("on", false)
        self._hands._animtime = 0
        self:StartUpdating()
    end
    self._caveopen = true
end

function UIClock:CloseCaveClock()
    if not self._cave or self._caveopen == false then
        return
    elseif self._caveopen == nil then
        self._rim:GetAnimState():PlayAnimation("off")
        self._hands._img:Hide()
    else
        self._rim:GetAnimState():PlayAnimation("close")
        self._rim:GetAnimState():PushAnimation("off", false)
        self._hands._animtime = 0
        self:StartUpdating()
    end
    self._caveopen = false
end

--------------------------------------------------------------------------
--[[ Event handlers ]]
--------------------------------------------------------------------------

function UIClock:OnGainFocus()
    UIClock._base.OnGainFocus(self)
    self:UpdateDayString()
    return true
end

function UIClock:OnLoseFocus()
    UIClock._base.OnLoseFocus(self)
    self:UpdateWorldString()
    return true
end

function UIClock:OnClockSegsChanged(data)
    local day = data.day or 0
    local dusk = data.dusk or 0
    local night = data.night or 0
    -- assert(day + dusk + night == NUM_SEGS, "invalid number of time segs") --GIT THIS OUTTA HERE -DST CHANGE 12-17-17

    local dark = true
    for k, seg in pairs(self._segs) do
        
		--12-20-17 MOVE OVER, I'M HIJACKING THIS THING -DST CHANGE
		--[[
		if k > day + dusk then
            seg:Hide()
        else
            seg:Show()

            local color
            if k <= day then
                color = self._cave and CAVE_DAY_COLOUR or DAY_COLOUR 
            else
                color = self._cave and CAVE_DUSK_COLOUR or DUSK_COLOUR
            end

            if dark then
                color = color * DARKEN_PERCENT
            end
            dark = not dark

            seg:SetTint(color.x, color.y, color.z, 1)
        end
		]]
		
		--DOIN THINGS LAZY. TIMER WILL ALWAYS SHOW THE SAME CONFIG, (EXCEPT IN INFINATE MODE)
		
		if data.dusk == 0 and data.night == 0 then --IF THERE AINT NO NIGHT, JUST MAKE THE WHOLE THING DAY
			
			seg:Show()
			local color = self._cave and CAVE_DAY_COLOUR or DAY_COLOUR 
			if dark then	--ALRIGHT, ALRIGHT, THEY CAN KEEP THE DARK PATTERN THING IF THEY WANT
                color = color * DARKEN_PERCENT
            end
            dark = not dark

            seg:SetTint(color.x, color.y, color.z, 1)
			
			
		elseif k <= 14 then	--ELSE, DO THE SPECIFIED 3/4 PIE TIMER.
            seg:Show()
			local color 
			
			--FIRST 12 SEGMENTS ARE ALWAYS DAY, AND THE NEXT 2 ARE DUSK
			if k <= 12 then
				color = self._cave and CAVE_DAY_COLOUR or DAY_COLOUR 
			else
				color = self._cave and CAVE_DUSK_COLOUR or DUSK_COLOUR
			end
			
			if dark then	--ALRIGHT, ALRIGHT, THEY CAN KEEP THE DARK PATTERN THING IF THEY WANT
                color = color * DARKEN_PERCENT
            end
            dark = not dark

            seg:SetTint(color.x, color.y, color.z, 1)
		
		else
			seg:Hide() --ITS NIGHT!! WHICH IS THE BACKGROUND IMAGE, SO DONT EVEN SHOW ANYTHING
		end
		
		
		
    end
    self._daysegs = day
end

function UIClock:OnCyclesChanged(cycles)
    self._cycles = cycles
    if self._showingcycles then
        self:UpdateWorldString()
    else
        self:UpdateDayString()
    end
end

function UIClock:OnPhaseChanged(phase)
    if self._phase == phase then
        return
    end

    if self._phase == "night" then
        self._moonanim:GetAnimState():PlayAnimation("trans_in")
    end

    if phase == "day" then
        if self._phase ~= nil then
            self._anim:GetAnimState():PlayAnimation("trans_night_day")
            self._anim:GetAnimState():PushAnimation("idle_day", true)
        else
            self._anim:GetAnimState():PlayAnimation("idle_day", true)
        end
    elseif phase == "dusk" then
        if self._phase ~= nil then
            self._anim:GetAnimState():PlayAnimation("trans_day_dusk")
            self._anim:GetAnimState():PushAnimation("idle_dusk", true)
        else
            self._anim:GetAnimState():PlayAnimation("idle_dusk", true)
        end
    elseif phase == "night" then
        if self._phase ~= nil then
            self._anim:GetAnimState():PlayAnimation("trans_dusk_night")
            self._anim:GetAnimState():PushAnimation("idle_night", true)
        else
            self._anim:GetAnimState():PlayAnimation("idle_night", true)
        end
        self:ShowMoon()
    end

    self._phase = phase
end

function UIClock:OnMoonPhaseChanged2(data)
    -- if self._moonphase == data.moonphase and self._mooniswaxing == data.waxing then
        -- return
    -- end

    --self._moonphase = data.moonphase
    -- self._mooniswaxing = data.waxing

    -- if self._phase == "night" then
        -- self:ShowMoon()
    -- end
end

function UIClock:OnClockTick(data)
    if not self._cave and self._time ~= nil then
        local prevseg = math.floor(self._time * NUM_SEGS)
        if prevseg < self._daysegs then
            local nextseg = math.floor(data.time * NUM_SEGS)
            if prevseg ~= nextseg and nextseg < self._daysegs then
                -- self._anim:GetAnimState():PlayAnimation("pulse_day") --NAH. TOO DISTRACTING
                self._anim:GetAnimState():PushAnimation("idle_day", true)
            end
        end
    end

    self._time = data.time
    -- self._hands:SetRotation(self._time * 360) --AH AH AH~ I DONT THINK SO
	
	
	
	
	
	-- print("MY TIME DATA, ", data.time)
	
	
	
	--THIS IS LIKE THE BIGGEST LONGEST MIDDLE-SCHOOL LEVEL MATH PROBLEM IVE EVER HAD TO SOLVE
	if data.matchtimelimit and data.matchtimelimit > 0 then
		
		-- local daytime = data.matchtimelimit - 30	--TOTAL NUMBER OF SECONDS OF DAYLIGHT
		-- local daytime = data.matchtime_current / (data.matchtimelimit - 30)
		local daytime = data.matchtime_current / (data.matchtimelimit - 30)
		
		-- print("AND THEYRE OFF!! ----- ", daytime, data.matchtime_current, (data.matchtimelimit - 0))
	
		if data.matchtime_remaining > 30 then
			self._hands:SetRotation(daytime * 270)
			
		else --if data.matchtime_remaining <= 30 then --FOR DUSK, BASICALLY
			self._hands:SetRotation((( (30 - data.matchtime_remaining) /30) * 45) + 270) 
			
			-- SUBTRACTED FROM 30 BECAUSE IT NEEDS TO START AT 0 AND WORK UP OR ELSE IT WILL TURN BACKWARDS
			-- /30 BECAUSE IT NEEDS TO COME OUT AS A DECIMAL 0.0 TO 1.0
			-- *45 SO THE ANGLE FROM 0 TO 1 ONLY COVERS 45 DEGREES
			-- +270 SO THAT THE ANGLE STARTS AT THE 3/4 MARK WHERE THE DAY TIMER LEFT OFF
			
		end
		
		
		
		--SETS THE TIMER IN MINUTES LEFT
		-- print("COUNTING DOWN THE MINUTES ", math.fmod(data.matchtime_remaining, 60))
		local mmins = math.floor(data.matchtime_remaining / 60) 
		local msecs = math.floor(math.fmod(data.matchtime_remaining, 60))
		if msecs < 10 then 
			msecs = "0"..tostring(msecs) --ADDS A ZERO ONTO THOSE SINGLE DIGIT NUMBERS
		end
		
		local timerstring = tostring(mmins)..":"..tostring(msecs) --THIS IS WHAT WILL SHOW UP IN THE TIMER
		
		
		if data.matchtime_remaining <= 0 then 
			timerstring = STRINGS.SMSH.UI_CLOCK_SUDDEN_DEATH --"sudden".."\n".."death" --SUDDEN DEATH
			-- self._hands:SetRotation(self._time * 360)
		end
		
		
		-- 12-26-17 THIS WILL BE THE DEFAULT FOR IN-BETWEEN GAME TIMERS
		if data.matchtimelimit >= (30*60) then --ANYTHING GREATER THAN 60 MINUTES
			timerstring = STRINGS.SMSH.UI_CLOCK_WAITING --"waiting"
			self:Hide()
		else
			self:Show()
		end
		
		--SHOW THE MATCH TIMER.
		self:UpdateDayString(timerstring)
	else
		self._hands:SetRotation(self._time * 360) --ELSE, JUST DO IT THE NORMAL WAY
	end
	
	

    -- if self._showingcycles then	--EH, WHO NEEDS THIS?
        -- self:UpdateWorldString()
    -- else
        -- self:UpdateDayString()
    -- end
end

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

function UIClock:OnUpdate(dt)
    local k = self._hands._animtime + dt * TheSim:GetTimeScale()
    self._hands._animtime = k

    if self._caveopen then
        local wait_time = 10 * FRAMES
        local grow_time = 5 * FRAMES
        local shrink_time = 3 * FRAMES
        if k >= wait_time then
            k = k - wait_time
            if k < grow_time then
                local scale = easing.outQuad(k, 0, 1, grow_time)
                self._hands._img:SetScale(scale, scale * 1.15, 1)
            else
                k = k - grow_time
                if k < shrink_time then
                    self._hands._img:SetScale(1, easing.inOutQuad(k, 1.1, -.1, shrink_time), 1)
                else
                    self._hands._img:SetScale(1, 1, 1)
                    self._hands._animtime = nil
                    self:StopUpdating()
                end
            end
            self._hands._img:Show()
        end
    else
        local wait_time = 3 * FRAMES
        local shrink_time = 6 * FRAMES
        if k >= wait_time then
            k = k - wait_time
            if k < shrink_time then
                local scale = easing.inQuad(k, 1, -1, shrink_time)
                self._hands._img:SetScale(scale, scale, 1)
            else
                self._hands._img:Hide()
                self._hands._animtime = nil
                self:StopUpdating()
            end
        end
    end
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

return UIClock
