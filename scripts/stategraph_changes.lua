

local require = GLOBAL.require
local StateGraphInstance = require "stategraph"

--1-1-22 ALRIGHT, SO IT'S NOT PERFECT YET. DARN
--THE OLD BLOCK_STOP STATE CURRENTLY INHERITS THE BLOCKSTUN FRAMES FROM THE TIMEOUT OF THE BLOCK_STUNNED STATE
--(UNTIL I SLAPPED AN ONUPDATE IN THERE TO FORCE IT MANUALLY COUNT THE FRAMES)
--SO THERE'S THAT HOTFIX, BUT I WOULD GUESS THAT ANY OTHER STATES THAT USE THE ONTIMEOUT FEATURE PROBABLY SHARE THIS BUG (WHICH IS LUCKILY, VERY FEW)

AddGlobalClassPostConstruct("stategraph", "StateGraphInstance", function(self)
	
	self.pauseonupdaters = false --4-7-19 YEP. I'M ADDING STUPID STUFF
	
	self.inhitstun = false --4-7-19 
	
	--4-8-19 FORCE AN ONUPDATE FOR A STATEGRAPH WHEN THEIR TIMERS ARE SET FAR PAST THE END OF THEIR HITLAG
	function self:ForceUpdate() --LOL STATEGRAPH STUFF IS SO HARD TO FIND, ADDING FNS IS THE ONLY WAY I KNOW HOW TO ACCESS IT
		self:Update()
	end
	
	
	--YOU DUNCE THIS ISNT THE VERSION IVE BEEN USING. IT WAS AN ENTITYSCRIPT FN
	--12-22 HMMM... LET ME TRY THIS AGAIN
	function self:PauseStateGraph(timetowait)
		if self.sg then
			--SGManager:RemoveInstance(self.sg)
			-- SGManager:Sleep(self.sg, 3)
			SGManager:Sleep(self.sg, timetowait)
			-- print("TIME TO DIE", timetowait)
			--self.sg = nil
		end
		--4-7-19 ACTUALLY WAIT, I HAVE A SLIGHTLY LESS STUPID IDEA
		self.inhitstun = true --AND I'LL EDIT THE ONUPDATE FN TO SKIP THE UPDATE WHILE THIS IS SET TO TRUE. -4-7-19
		--4-7-19 UNLIKE REGULAR "Time_to_sleep" VALUES, THIS CAN ONLY BE SET BY HITSTUN, AND NOT RANDOM LAG SPIKES
	end
	
	
	--4-7-19 AND ANOTHER ONE BECAUSE I CAN'T FIND WHERE THIS VARIABLE IS ACTUALLY GOING
	function self:UnPauseStateGraphRRRRR()
		self.inhitstun = false --AND I'LL EDIT THE ONUPDATE FN TO SKIP THE UPDATE WHILE THIS IS SET TO TRUE. -4-7-19
		--4-7-19 UNLIKE REGULAR "Time_to_sleep" VALUES, THIS CAN ONLY BE SET BY HITSTUN, AND NOT RANDOM LAG SPIKES
	end
	
	
	
	
	
	
	function self:Update()
		local dt = 0
		if self.lastupdatetime then
			dt = GLOBAL.GetTime() - self.lastupdatetime --+ GetTickTime()
		end
		
		self.lastupdatetime = GLOBAL.GetTime()
		-- self:UpdateState(dt) --HMM... WHAT IF WE ADDED A FEILD TO THIS AND MOVED IT DOWN?
		
		self.inhitstun = self.inst.inhitstun or false
		
		--I DON'T THINK THIS CAN HAPPEN HERE OR ELSE THE TIME TO SLEEP WILL UPDATE
		-- if not self.inhitstun then --EASY ENOUGH, RIGHT?
			-- -- self.lastupdatetime = GLOBAL.GetTime() --NO, THIS WILL CATCH IT RIGHT BACK UP TO WHERE IT STARTED!
			-- self:UpdateState(dt)
		-- else
			-- -- print("SKIPPING FOR HITSTUN", time_to_sleep/GLOBAL.FRAMES)
		-- end
		
		
		-- print("TIME: ", 
			-- self.currentstate.name, 
			-- self.currentstate.timeline[self.timelineindex] and self.currentstate.timeline[self.timelineindex].time/GLOBAL.FRAMES, 
			-- math.floor(self.timeinstate/GLOBAL.FRAMES)
		-- )
	   
		local time_to_sleep = nil
		if self.timelineindex and self.currentstate.timeline and self.currentstate.timeline[self.timelineindex] then
			time_to_sleep = self.currentstate.timeline[self.timelineindex].time - self.timeinstate
			--print("FIRST TIME TO SLEEP:", time_to_sleep/GLOBAL.FRAMES)
			-- = 3.99999947845   --ITS A ROUNDING ERROR ISNT IT... =_=   4-14-20
			--OKAY, GUESS WE GOTTA HELP IT OUT A BIT. HERES THE PROPER WAY TO ROUNDING
			-- time_to_sleep = math.floor(time_to_sleep+0.5) --WAIT THIS ISNT QUITE RIGHT- OH!!
			--WAIT NO!... THE REAL TIME_TO_SLEEP ISNT IN FRAMES, ITS A DECIMAL IN UNITS OF 0.033333... 
			--OKAY SO DOES THAT MEAN ITS NOT A ROUNDING ERROR?
			--NO IM PRETTY SURE IT WAS STILL A ROUNDING ERROR BECAUSE IT WOULD STILL WAIT 3 FRAMES INSTEAD OF FOR FOR VALUES LIKE 3.999 BUT IM NOT SURE HOW TO ROUND THAT INTO DECIMALS OF 0.0333
			--4-14-20 OKAY YOU KNOW WHAT. I GIVE. AT LEAST FOR NOW, LETS JUST TAKE THE COWARDS WAY OUT
			time_to_sleep = 0
		end
		
		-- print("FIRST TIME TO SLEEP:", time_to_sleep/GLOBAL.FRAMES)
		
		-- !!!!!!  =========  !!!!! HOLDUP...  4-14-20
		-- IF WORSE COMES TO WORSE. SETTING TIMETOWAIT TO A CONSTANT 0 WILL FIX EVERYTHING, AT THE COST OF SLIGHT PREFORMANCE 
		
			
		
		--TIMEOUTS ARE PRETTY MUCH UNUSED AT THE MOMENT, BUT THEY COULD COME INTO PLAY LATER
		if self.timeout and (not time_to_sleep or time_to_sleep > self.timeout) then
			time_to_sleep = self.timeout
		end
		
		
		--4-7-19 --ALLFRAME = BOOLEAN TO DETERMINE IF WE SHOULD PUSH ONUPDATE FNS ON ALL FRAMES, I GUESS
		-- self:UpdateState(dt, allframe)
		
		
		
		-- self.inhitstun = self.inst.inhitstun or false
		
		if not self.inhitstun then --EASY ENOUGH, RIGHT?
			-- self.lastupdatetime = GLOBAL.GetTime() --NO, THIS WILL CATCH IT RIGHT BACK UP TO WHERE IT STARTED!
			self:UpdateState(dt)
		else
			-- print("SKIPPING FOR HITSTUN", time_to_sleep/GLOBAL.FRAMES)
		end
		
			
		--THIS IS THE PART WE WANT TO CHANGE. DON'T LET AN ONPUDATE FN THROW OFF OUR TIMELINE!! RETURN TIME_TO_SLEEP FIRST!
		-- if self.currentstate.onupdate then
			-- return 0
		-- elseif time_to_sleep then
			-- return time_to_sleep
			
		--4-7-19 LIKE THIS!
		-- if time_to_sleep then
			-- print("SLEEP", time_to_sleep)
			-- return time_to_sleep
		-- elseif self.currentstate.onupdate then --ACTUALLY, I DON'T THINK WE EVEN WAN'T THIS PART AT ALL!
			-- print("ONUPDATE", 0)
			-- return 0						   --SCRATCH THAT WE TOTALLY NEED IT, WALKING BREAKS WITHOUT IT
			
			--OKAY THIS HASN'T WORKED OUT SO HOT. LETS TRY SOMETHING ELSE
			-- print("STUNNED?", self.inhitstun)
		-- if time_to_sleep and self.currentstate.onupdate == nil then
			-- -- print("TIME TO SLEEP", time_to_sleep)
			-- return time_to_sleep
		-- elseif self.currentstate.onupdate and self.inhitstun then --IF IN ONUPDATE AND HITSTUNNED, 
			-- return time_to_sleep
		-- elseif self.currentstate.onupdate then
			-- return 0
			
			
		--4-18-19 LESS MESSY VERSION OF THE ABOVE
		-- if self.inhitstun or (time_to_sleep and not self.currentstate.onupdate) then
			-- -- print("TIME TO SLEEP", time_to_sleep)
			-- return time_to_sleep
		-- elseif self.currentstate.onupdate ~= nil then
			-- return 0
			
		--4-22-19 --SIGH/ OKAY, WHAT IF HITSTUN ACTUALLY RETURNS 0 NOW THAT THE NORMAL TIME ADVANCE HAS BEEN DECLAWED?
		if self.inhitstun then
			return 0
		elseif (time_to_sleep and not self.currentstate.onupdate) then
			--print("TIME TO SLEEP", math.floor(time_to_sleep/GLOBAL.FRAMES))
			return time_to_sleep
			--4-14-20 RESEARCH REPORT: TIMETOSLEEP:
			--TIMETOSLEEP IS USED FOR NON ONUPDATE STATES TO DETERMINE HOW MANY FRAMES TO WAIT INBETWEEN EACH UPDATE, ACCORDING TO THE LENGTH OF TIME BETWEEN EACH TIMEEVENT.
			--IF TIMETOSLEEP CALCULATIONS ARE OFF, IT CAN CAUSE TIMEEVENTS TO FIRE LATE SINCE IT MIGHT BE ASLEEP WHEN IT COMES TO THE FRAME IT NEEDS TO FIRE ON
			--IF IT OVERSHOOTS THE FRAME IT WAS SUPPOSED TO FIRE ON, (IF TIMEINSTATE IS GREATER THAN THE EVENT) IT WILL FIRE AS SOON AS THE GENERAL UPDATE RUNS AGAIN, EVEN FIRING MULTIPLE EVENTS IF MORE THAN ONE WAS SKIPPED
		elseif self.currentstate.onupdate ~= nil then
			return 0
		else
			return nil
		end
	end
	
	
	--4-9-19 KEEP THE NATURAL TIME OF A STATE WITHOUT DOING THE REST OF THE TASKS
	--[[
	function self:KeepTime(dt)
		if not self.currentstate then 
			return
		end

		self.timeinstate = self.timeinstate + dt
	end
	]]
	
	
	--THIS NEEDS TO BE DONE TOO
	function self:UpdateState(dt)
		if not self.currentstate then 
			return
		end
		
		-- print("COOL MATH", math.floor(3.82))
		
		--4-11-19 HEY HO HOLD UP IF WE'RE IN HITLAG, DON' PROGRESS OUR PLAYER'S TIMELINE
		local hitlagging = self.inst.inhitstun
		if hitlagging then
			dt = 0 --DT = EXACT TIME PASSED BETWEEN PREVIOUS UPDATE
		end
		-- print("COOL MATH", math.floor(self.timeinstate/GLOBAL.FRAMES), math.floor(dt/GLOBAL.FRAMES), hitlagging)
		-- 4-14-20 OKAY, ACCORDING TO THE READOUTS, TIMEINSTATE DOESNT SEEM TO BE CORRECT --OH WAIT ACTUALLY LET ME MOVE IT DOWN FIRST
		
		self.timeinstate = self.timeinstate + dt
		local startstate = self.currentstate
		
		--4-14-20 ITLL PROBABLY BE MORE ACCURATE DOWN HERE
		--print("COOL MATH", math.floor(self.timeinstate/GLOBAL.FRAMES), math.floor(dt/GLOBAL.FRAMES))
		--OKAY, NOW TIMEINSTATE SEEMS TO BE CORRECT AND IT IS UPDATING PROPERLY GIVEN THE NUMBER OF FRAMES PASSED SINCE THIS LAST RAN - HOWEVER -
		-- - DESPITE KNOWING THE ACCURATE TIME IN STATE, THIS PART OF THE CODE IS NOT RUNNING WHEN IT NEEDS TO, 
		-- INSTEAD ITS RUNNING AT FRAMES LIKE 13, 16, 21 INSTEAD OF 10, 15, 20 WHEN WE WANT IT TO.
		
		
		if self.timeout then
			self.timeout = self.timeout - dt
			if self.timeout <= (1/30) then
				self.timeout = nil
				if self.currentstate.ontimeout then
					self.currentstate.ontimeout(self.inst)
					if startstate ~= self.currentstate then
						return
					end
				end
			end
		end
		
		--ACTUALLY!! REMOVE IT ENTIRELY. I MISUNDERSTOOD HOW THIS WORKS. THIS FN DOESNT RUN EVERY FRAME, I HAVE TO MOVE THIS ELSEWHERE
		--4-7-19 YEA!... MAYBE...
			-- if self.currentstate.onupdate ~= nil then
				-- print("GOT AN ONUPDATE HERE!!!")
				-- self.currentstate.onupdate(self.inst, dt)
			-- end
		-- print("MY TIMELINE INDEX IS:  ", self.timelineindex)
		while self.timelineindex and self.currentstate.timeline[self.timelineindex] and self.currentstate.timeline[self.timelineindex].time <= self.timeinstate do

			local idx = self.timelineindex
			self.timelineindex = self.timelineindex + 1
			if self.timelineindex > #self.currentstate.timeline then
				self.timelineindex = nil
			end
			
			local old_time = self.timeinstate
			local extra_time = self.timeinstate - self.currentstate.timeline[idx].time
			self.currentstate.timeline[idx].fn(self.inst) --PRETTY SURE THIS IS THE FRAME TASK
			--OH SNAP IS THIS A WAY TO MANUALLY CALL FRAME TASKS IF WE WANTED TO?
			
			--4-11-19 HEY HO HOLD UP IF WE'RE IN HITLAG, DON' PROGRESS OUR PLAYER'S TIMELINE
			if hitlagging then
				extra_time = 0
			end
			
			--4-14-20 AT ONE POINT I TRIED TO REMOVE THIS AND... IT DIDNT SEEM TO CHANGE ANYTHING???
			if startstate ~= self.currentstate or old_time > self.timeinstate then
				--print("UPDATING! EXTRA TIME?: ", extra_time)
				--print("EXTRA STATS: ", startstate, self.currentstate, old_time, self.timeinstate)
				self:Update(extra_time)
				return 0
			end
		end
		
		--IF THIS HAPPENS DOWN HERE, ONUPDATE FNS WILL GET CUT OFF HALF THE TIME. MOVE IT UP THERE
		--YOU KNOW WHAT, OKAY, IT CAN HAPPEN DOWN HERE. BUT NOT IF WE'RE HITLAGGING
		if self.currentstate.onupdate ~= nil and not hitlagging then
			self.currentstate.onupdate(self.inst, dt)
		end
	end
end)





--8-25-19 OH BOY HERE WE GO AGAIN 
-- LETS SEE IF WE CAN MOVE THESE COMMONSTATE CHANGES INTO SOMEWHERE MORE COMPATIBLE THAT WONT BREAK WITH EVERY UPDATE
--local ExtraCommonStates = require "stategraphs/commonstates"

local FRAMES = GLOBAL.FRAMES --SO WE DONT HAVE TO DO THIS A MILLION TIMES
local State = GLOBAL.State
local TimeEvent = GLOBAL.TimeEvent --YESS. YESSSS
local EventHandler = GLOBAL.EventHandler
local Action = GLOBAL.Action --I DONT EVEN USE ACTIONS BUT WHATEVER
local ActionHandler = GLOBAL.ActionHandler

require "stategraphs/commonstates"



--DO YOU THINK WE CAN ACCESS THOSE ARRAYS FROM ALL THE WAY OUT HERE? LETS FIND OUT --OH SNAP IT WORKED :U AS LONG AS YOU REFERENCE THE TABLES GLOBALY
GLOBAL.CommonHandlers.OnRespawn = function()
    return EventHandler("respawn", function(inst)
		inst.sg:GoToState("respawn_platform")
	end)
end

--7-29-17 I THINK YOU CAN ACTUALLY JUST COPY/PASTE THESE COMMON STATE FILES BETWEEN VERSIONS. THEY LOOK THE SAME
GLOBAL.CommonStates.AddFrozenStates2 = function(states)

    local frozensm = State{
        name = "frozen",
        tags = {"busy", "frozen", "no_air_transition", "nolandingstop", "reducedairacceleration", "holdupdude"}, --NEEDS SOMETHING TO PREVENT GOING TO HIT STATE FROM TRIGGERING ONEXIT EARLY
        
        onenter = function(inst)
			
			local opponent = inst
				-- projectile.components.stats.opponent.sg:GoToState("ragdoll", "flinch2") --THIS WONT WORK IF WE WE HIT THEM PHYSICALLY OURSELVES
				inst.AnimState:PlayAnimation("flinch2")
				inst.AnimState:SetTime(3*FRAMES)
				
				inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
				-- inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
				--10-17-20 AM I BLIND??? THE GIANT PUDDLE FILE IS RIGHT HERE
				-- inst.components.hitbox:MakeFX("full", 1.5, 0, -0.3,   3.0, 3.0,   1, 50, 0,  0, 0, 0,   0, "ice_puddle", "ice_puddle")
				
				local xpos, ypos = inst.Transform:GetWorldPosition()
				--1-11-22 GIVE WES A BREAK. NORMALIZE FALLING SPEED
				inst.components.stats.fallingspeed = 0.8
				
				inst.AnimState:Pause()
				
				inst.AnimState:SetAddColour(82/255,115/255,124/255, 1)
				
				inst.components.hitbox:MakeFX("icechunk", 0, 0.5, 0.3,   1.1, 1.1,   0.6, 23, 0,  0, 0, 0,   1)
				
        end,
        
        onexit = function(inst)
            -- inst.AnimState:ClearOverrideSymbol("swap_frozen")
			if not inst.sg:HasStateTag("holdupdude") then --10-17-20 WTF IS THIS STATE TAG NAME?? DID I REALLY DO THIS?
				inst.AnimState:SetAddColour(0,0,0,1)
				inst.AnimState:Resume()
				inst.components.stats.fallingspeed = 1.2
				inst.components.stats:ResetFallingSpeed()
			end
        end,
		
		
		timeline=
        {
			TimeEvent(3*FRAMES, function(inst)
					inst.AnimState:SetAddColour(82/255,115/255,124/255, 1)
					inst.sg:RemoveStateTag("holdupdude")
			end),

			TimeEvent(30*FRAMES, function(inst)
				inst.AnimState:Resume()
				inst.components.stats:ResetFallingSpeed() --1-11-22
				inst.sg:GoToState("rebound", 5)
				inst.components.hitbox:MakeFX("huge", 0, 1.3, 0.3,   0.5, 0.5,   1, 20, 0,  0, 0, 0,   0, "frozen_shatter", "frozen_shatter")
				inst.components.hitbox:MakeFX("huge", 0, 0, 0.3,   0.5, 0.5,   1, 20, 0,  0, 0, 0,   0, "frozen_shatter", "frozen_shatter")
				inst.components.launchgravity:Launch(0, 12, 0)
				
			end),

			TimeEvent(380*FRAMES, function(inst)
				inst.sg:GoToState("idle")
			end),
        },
		
        events=
        {   
            -- EventHandler("onthaw", function(inst) inst.sg:GoToState("thaw") end ),        
        },
    }
	
    table.insert(states, frozensm)    
    -- table.insert(states, thaw)    
end



GLOBAL.CommonStates.AddRespawnPlatform = function(states)

    local platform = State{
        name = "respawn_platform", 
        tags = {"intangible", "no_air_transition", "busy"}, 
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("idle")
			inst.Physics:SetVel(0, -1, 0)
			-- inst.Physics:Stop()
			inst.Physics:SetActive(false)
			inst.AnimState:SetAddColour(0.3,0.3,0.3,0.3)
			inst:PushEvent("swaphurtboxes", {preset = "idle"}) --EVERYONE SHOULD HAVE ONE OF THESE
			
			--6-30-17 OH WHAT A DUMB IDEA
			inst.components.hitbox:MakeFX("activate", 0, -0.3, -0.2,   0.7, 0.7,   1, 90, 0,  0, 0, 0,   0, "resurrection_stone", "resurrection_stone") 
			--(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
			inst.components.stats.lastfx.AnimState:SetLayer( 3 ) --LAYER_WORLD
			inst.components.stats.lastfx.AnimState:SetTime(9*FRAMES)
			inst.components.stats.lastfx.AnimState:PushAnimation("idle_activate", true)
			
			--DST - FOR THE PUNCHINGBAG
			if inst:HasTag("autorespawn") then
				inst.sg:GoToState("air_idle")
			end
			
		end,
		
		onexit = function(inst, target)
			inst.Physics:SetActive(true)
			inst.AnimState:SetAddColour(0,0,0,0)
			inst.components.stats.spawninvuln = true
			inst:DoTaskInTime(1.2, function(inst)
				inst.components.stats.spawninvuln = false
			end)
        end,
        
        timeline =
        {
			TimeEvent(1*FRAMES, function(inst) 
				inst.Physics:SetActive(false)
			end),
			
			TimeEvent(90*FRAMES, function(inst) 
				inst.sg:GoToState("air_idle")
			end),
        },
		
		events=
        {
            EventHandler("down", function(inst) inst.sg:GoToState("air_idle") end),
			EventHandler("left", function(inst) inst.sg:GoToState("air_idle") end),
			EventHandler("right", function(inst) inst.sg:GoToState("air_idle") end),
			EventHandler("jump", function(inst) inst.sg:GoToState("doublejump") end),
			EventHandler("attack_key", function(inst) 
				-- inst.sg:GoToState("air_idle") 
				inst.sg:RemoveStateTag("busy")
			end),
			EventHandler("throwspecial", function(inst) 
				inst.sg:RemoveStateTag("busy") 
			end),
        },
        
    } --YOU GOTTA REMOVE THIS LITTLE COMMA THATS HERE EVERY TIME
	
    table.insert(states, platform)      
end



GLOBAL.CommonStates.AddDropSpawn = function(states) --ADDED 10-25-17

    local drop_spawn = State{
        name = "drop_spawn",  
        tags = {"intangible", "busy"}, 
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("idle_air")
			inst:PushEvent("swaphurtboxes", {preset = "idle"}) --EVERYONE SHOULD HAVE ONE OF THESE
			inst.Physics:SetVel(0, 0, 0)
			-- inst.Physics:Stop()
			inst.Physics:SetActive(true)
		end,
		
		onexit = function(inst, target)
			if inst.components.locomotor then
				-- inst.components.locomotor:RunForward() --12-26-21 WE DON'T NEED THESE ANYMORE. KLEI FIXED PLAYER PHYSICS SO THEY DON'T SLEEP
			end
        end,
        
        timeline =
        {
			TimeEvent(15*FRAMES, function(inst) 
				-- inst.Physics:SetActive(false)
				if inst.components.locomotor then
					-- inst.components.locomotor:RunForward() --AND ATTEMPT TO GET THEIR PHYSICS WORKING
				end
			end),
			
			TimeEvent(20*FRAMES, function(inst) 
				--MAYBE THIS LITTLE HOP IS ENOUGH TO GET THEM TO HIT THE GROUND PROPERLY
				inst.Physics:SetVel(0, 6, 0)
			end),
			
			TimeEvent(60*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
				-- inst.AnimState:PlayAnimation("idle")
			end),
        },
        
    } --YOU GOTTA REMOVE THIS LITTLE COMMA THATS HERE EVERY TIME
	
    table.insert(states, drop_spawn)      
end

