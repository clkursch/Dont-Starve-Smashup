Dest = Class(function(self, inst, world_offset)
    self.inst = inst
    self.world_offset = world_offset
end)

local PATHFIND_PERIOD = 1
local PATHFIND_MAX_RANGE = 40

local STATUS_CALCULATING = 0
local STATUS_FOUNDPATH = 1
local STATUS_NOPATH = 2

local NO_ISLAND = 127

local ARRIVE_STEP = .15


--ADDED
local JUMPIN = false

function Dest:IsValid()
    if self.inst then
        if not self.inst:IsValid() then
            return false
        end
    end
    
    return true

end

function Dest:__tostring()
    if self.inst then
        return "Going to Entity: " .. tostring(self.inst)
    elseif self.world_offset then
        return "Heading to Point: " .. tostring(self.world_offset)
    else
        return "No Dest"
    end
    
end

function Dest:GetPoint()
    local pt = nil
    
    if self.inst and self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner then
        return self.inst.components.inventoryitem.owner.Transform:GetWorldPosition()
    elseif self.inst then
        return self.inst.Transform:GetWorldPosition()
    elseif self.world_offset then
        return self.world_offset.x,self.world_offset.y,self.world_offset.z
    else
        return 0, 0, 0
    end
end



local LocoMotor_OLD = Class(function(self, inst)
    self.inst = inst
    self.dest = nil
    self.atdestfn = nil
    self.bufferedaction = nil
    self.arrive_step_dist = ARRIVE_STEP
    self.arrive_dist = ARRIVE_STEP
    self.walkspeed = TUNING.WILSON_WALK_SPEED -- 4
    self.runspeed = TUNING.WILSON_RUN_SPEED -- 6
    self.bonusspeed = 0
    self.throttle = 0.1
	self.creep_check_timeout = 0
	self.slowmultiplier = 0.6
	self.fastmultiplier = 1.3
	
	self.groundspeedmultiplier = 1.0
    self.enablegroundspeedmultiplier = true
	self.isrunning = false
	
	self.wasoncreep = false
	self.triggerscreep = true
	
	--WHAT WAS I EVEN DOING??
	self.AIRBORN = false
	
	self.dashspeed = TUNING.WILSON_RUN_SPEED
end)


function LocoMotor_OLD:TempGroundTile() --OH, THIS WAS AN ACTUAL REAL FUNCTION. I JUST GUTTED IT
	return false
end

function LocoMotor_OLD:StopMoving() --11-10-20 DOES.. THIS WORK?? WHATEVER IM LEAVING IT HERE
	self.isrunning = false
end

function LocoMotor_OLD:SetSlowMultiplier(m)
	self.slowmultiplier = m
end

function LocoMotor_OLD:SetTriggersCreep(triggers)
	self.triggerscreep = triggers
end

function LocoMotor_OLD:EnableGroundSpeedMultiplier(enable)
    self.enablegroundspeedmultiplier = enable
    if not enable then
        self.groundspeedmultiplier = 1
    end
end

function LocoMotor_OLD:GetWalkSpeed()
    return (self.walkspeed + self:GetBonusSpeed()) * self:GetSpeedMultiplier()
end

function LocoMotor_OLD:GetRunSpeed()
    return (self.runspeed  + self:GetBonusSpeed()) * self:GetSpeedMultiplier()
end

function LocoMotor_OLD:GetBonusSpeed()
    return self.bonusspeed
end



function LocoMotor_OLD:GetSpeedMultiplier()
	local inv_mult = 1.0
	return inv_mult * self.groundspeedmultiplier*self.throttle
end


function LocoMotor_OLD:GetDashSpeed()
    return (self.dashspeed  + self:GetBonusSpeed()) * self:GetSpeedMultiplier()
end


function LocoMotor_OLD:UpdateGroundSpeedMultiplier()
	
	--[[
	self.groundspeedmultiplier = 1
    local ground = GetWorld()
	local oncreep = ground ~= nil and ground.GroundCreep:OnCreep(self.inst.Transform:GetWorldPosition())
	local x,y,z = self.inst.Transform:GetWorldPosition()
	if oncreep then
        -- if this ever needs to happen when self.enablegroundspeedmultiplier is set, need to move the check for self.enablegroundspeedmultiplier above
	    if self.triggerscreep and not self.wasoncreep then
	        local triggered = ground.GroundCreep:GetTriggeredCreepSpawners(x, y, z)
	        for _,v in ipairs(triggered) do
	            v:PushEvent("creepactivate", {target = self.inst})
	        end
	        self.wasoncreep = true
	    end
		self.groundspeedmultiplier = self.slowmultiplier
	else
        self.wasoncreep = false
		if self.fasteronroad then
            --print(self.inst, "UpdateGroundSpeedMultiplier check road" )
			if RoadManager and RoadManager:IsOnRoad( x,0,z ) then
				self.groundspeedmultiplier = self.fastmultiplier
			elseif ground ~= nil then
				local tile = ground.Map:GetTileAtPoint(x,0,z)		
				if tile and tile == GROUND.ROAD then
					self.groundspeedmultiplier = self.fastmultiplier
				end
			end
		end
	end
	--]]
	
end


--UNUSED IN SMASHUP, AS FAR AS I'M AWARE
function LocoMotor_OLD:WalkForward()
	
	self.isrunning = false
	if self.inst.components.launchgravity then
		local accspeed = 1
		local x,y,z = self.inst.Physics:GetMotorVel()
		local vx, vy = self.inst.Physics:GetVelocity()
		
		self.inst.Physics:SetMotorVel((self:GetRunSpeed() + accspeed),vy,0)
	else
		self.inst.Physics:SetMotorVel(self:GetWalkSpeed(),0,0)
	end
    self.inst:StartUpdatingComponent(self)
end

function LocoMotor_OLD:RunForward()
	self.isrunning = true
	
	--6-8-20 DANG, MY 2016 SELF REALLY KNEW HOW TO MAKE A MESS OF CODE. LETS TRY THIS AGAIN.
	-- self.throttle = self.throttle + 0.3
	self.throttle = self.throttle + 0.1
	if self.throttle <= 0.5 then --INCREASE THE THROTTLE FASTER IF BELOW HALF SPEED
		self.throttle = self.throttle + 0.1
	end
	
	if self.throttle >= 1 then
		self.throttle = 1
	end
	
	local vx, vy = self.inst.Physics:GetVelocity()
	
	--THE +1 IS BURNED IN FROM THE VERY BEGINNING :/ MY B
	self.inst.Physics:SetMotorVel(self:GetDashSpeed()+1,vy,0)
	
	
	--[[
	if self.inst.components.launchgravity then
	
	
	--print("RUNNING RUNNING RUNNING")
	
		-- accspeed = self.inst.components.launchgravity:GetAccelerationLeft()
		accspeed = 1 --6-8-20 WHATEVER THIS WAS WAS OLD AND POINTLESS BUT ITS BURNED INTO THE GAME NOW AT A CONSTANT 1
		
	
		--self.inst.Physics:SetMotorVel(self:GetRunSpeed(), self.inst.components.highjumper.GetFallingSpeed(), 0)
		-- local x,y,z = self.inst.Physics:GetMotorVel() --UNUSED
		--xvel,yvel,zvel = self.inst.Physics:GetMotorVel()
		
		local vx, vy = self.inst.Physics:GetVelocity()
		
		-- local airealmov = self.inst.components.jumper:GetAirealMovementSpeed() --UNUSED
		--print(airealmov)
		
		--self.inst.Physics:SetMotorVel(self:GetRunSpeed(),vy,0)
		self.inst.Physics:SetMotorVel((self:GetRunSpeed() + accspeed),vy,0)
		--self.inst.Physics:SetMotorVel(((self:GetRunSpeed() + airealmov)+ accspeed),vy,0)
		
		-- self.inst:DoTaskInTime(0.1, function()
			-- self.inst.Physics:SetMotorVel((self:GetRunSpeed() + accspeed),vy,0)
		-- end)
		
		
		--print(x,y,z)
		--print(vx,vy)
		--print("speed"GetMotorSpeed())
	else
		self.inst.Physics:SetMotorVel(self:GetRunSpeed(),0,0)
		print("JUST ANOTHER NOTE TO DELETE LATER")
	end
	]]
    self.inst:StartUpdatingComponent(self)
end


function LocoMotor_OLD:DashForward()
	--self.isrunning = true
	if self.inst.components.launchgravity then
	
		self.throttle = self.throttle + 0.3
		
		if self.throttle >= 1 then
			self.throttle = 1
		end
		
		local accspeed = 1 --im sorry
		local x,y,z = self.inst.Physics:GetMotorVel()
		local vx, vy = self.inst.Physics:GetVelocity()
		self.inst.Physics:SetMotorVel((self:GetDashSpeed() + accspeed),vy,0)
	else
		self.inst.Physics:SetMotorVel(self:GetRunSpeed(),0,0)
		print("JUST ANOTHER NOTE TO DELETE LATER")
	end
    self.inst:StartUpdatingComponent(self)
end

function LocoMotor_OLD:FlyForward() --3-15, THIS DOESNT EVEN DO ANYTHING ANYMORE, DOES IT
	self.isrunning = true
	if self.inst.components.launchgravity then
	
		-- accspeed = self.inst.components.launchgravity:GetAccelerationLeft()
		
	
		--self.inst.Physics:SetMotorVel(self:GetRunSpeed(), self.inst.components.highjumper.GetFallingSpeed(), 0)
		local x,y,z = self.inst.Physics:GetMotorVel()
		--xvel,yvel,zvel = self.inst.Physics:GetMotorVel()
		
		local vx, vy = self.inst.Physics:GetVelocity()
		
		local flybackx = 0
		local doopy = nil
		

	else
		self.inst.Physics:SetMotorVel(self:GetRunSpeed(),0,0)
	end
    self.inst:StartUpdatingComponent(self)
end

function LocoMotor_OLD:Clear()
    --Print(VERBOSITY.DEBUG, "LocoMotor_OLD:Clear", self.inst.prefab)
    self.dest = nil
    self.atdestfn = nil
    self.wantstomoveforward = nil
    self.wantstorun = nil
    self.bufferedaction = nil
    --self:ResetPath()
end

function LocoMotor_OLD:ResetPath()
    --Print(VERBOSITY.DEBUG, "LocoMotor_OLD:ResetPath", self.inst.prefab)
    self:KillPathSearch()
    self.path = nil
end

function LocoMotor_OLD:KillPathSearch()
    --Print(VERBOSITY.DEBUG, "LocoMotor_OLD:KillPathSearch", self.inst.prefab)
    if self:WaitingForPathSearch() then
        GetWorld().Pathfinder:KillSearch(self.path.handle)
    end
end

function LocoMotor_OLD:SetReachDestinationCallback(fn)
    self.atdestfn = fn
end

function LocoMotor_OLD:PushAction(bufferedaction, run, try_instant)
	if not bufferedaction then return end
	
    --self.throttle = 1
    local success, reason = bufferedaction:TestForStart()
    if not success then
        self.inst:PushEvent("actionfailed", {action = bufferedaction, reason = reason})
        return
    end
    
    self:Clear()
    if bufferedaction.action == ACTIONS.WALKTO then
        if bufferedaction.target then
            self:GoToEntity(bufferedaction.target, bufferedaction, run)
        elseif bufferedaction.pos then
            self:GoToPoint(bufferedaction.pos, bufferedaction, run)
        end
    elseif bufferedaction.action.instant then
        self.inst:PushBufferedAction(bufferedaction)
    else
        if bufferedaction.target then
            self:GoToEntity(bufferedaction.target, bufferedaction, run)
        elseif bufferedaction.pos then
            self:GoToPoint(bufferedaction.pos, bufferedaction, run)
        else
            self.inst:PushBufferedAction(bufferedaction)
        end
    end

end


function LocoMotor_OLD:GoToEntity(inst, bufferedaction, run)
    self.dest = Dest(inst)
    --self.throttle = 1
    
    self:SetBufferedAction(bufferedaction)
    self.wantstomoveforward = true
    
    if bufferedaction and bufferedaction.distance then
		self.arrive_dist = bufferedaction.distance
	else
        self.arrive_dist = ARRIVE_STEP

		if inst.Physics then
			self.arrive_dist = self.arrive_dist + ( inst.Physics:GetRadius() or 0)
		end

		if self.inst.Physics then
			self.arrive_dist = self.arrive_dist + (self.inst.Physics:GetRadius() or 0)
		end
	end

    if self.directdrive then
        if run then
            self:RunForward()
        else
            self:WalkForward()
        end
    else
        self:FindPath()
    end
    
    self.wantstorun = run
    --self.arrive_step_dist = ARRIVE_STEP
    self.inst:StartUpdatingComponent(self)    
end

function LocoMotor_OLD:GoToPoint(pt, bufferedaction, run) 
    self.dest = Dest(nil, pt)
    --self.throttle = 1

    if bufferedaction and bufferedaction.distance then
		self.arrive_dist = bufferedaction.distance
	else
		self.arrive_dist = ARRIVE_STEP
	end
    --self.arrive_step_dist = ARRIVE_STEP
    self.wantstorun = run
    
    if self.directdrive then
        if run then
            self:RunForward()
        else
            self:WalkForward()
        end
    else
        self:FindPath()
    end
    self.wantstomoveforward = true
    self:SetBufferedAction(bufferedaction)
    self.inst:StartUpdatingComponent(self) 
end


function LocoMotor_OLD:SetBufferedAction(act)
    if self.bufferedaction then
        self.bufferedaction:Fail()
    end
    self.bufferedaction = act
end

function LocoMotor_OLD:Stop()
	
	--11-10-20 ALRIGHT, WOW I CLEARLY HAD NO IDEA WHAT I WAS DOING WHEN I MADE THIS, BUT WHATEVER. IT WORKS FINE NOW, NOT GONNA TOUCH IT
	if self.inst.components.jumper then
		self.AIRBORN = self.inst.components.launchgravity:GetIsAirborn()
	end
	
    Print(VERBOSITY.DEBUG, "LocoMotor_OLD:Stop", self.inst.prefab)
	self.isrunning = false
    self.dest = nil
    self:ResetPath()
    self.lastdesttile = nil
    --self.arrive_step_dist = 0

    --self:SetBufferedAction(nil)
    self.wantstomoveforward = false
    self.wantstorun = false
	
    
	if self.inst.components.jumper and not self.AIRBORN then
		self:StopMoving()    --LEL, WHO NEEDS THIS??? WE'LL NEVER STOP MOVING wait this could be a bad idea
	end

    self.inst:PushEvent("locomote")
    self.inst:StopUpdatingComponent(self)
end

function LocoMotor_OLD:WalkInDirection(direction, should_run)
    --Print(VERBOSITY.DEBUG, "LocoMotor_OLD:WalkInDirection ", self.inst.prefab)
	self:SetBufferedAction(nil)
    if not self.inst.sg or self.inst.sg:HasStateTag("canrotate") then
        self.inst.Transform:SetRotation(direction)
    end
            
    self.wantstomoveforward = true
    self.wantstorun = should_run
    self:ResetPath()
    self.lastdesttile = nil
    
    if self.directdrive then
        self:WalkForward()
    end
    self.inst:PushEvent("locomote")
    self.inst:StartUpdatingComponent(self)
    
end


function LocoMotor_OLD:RunInDirection(direction, throttle)
    --Print(VERBOSITY.DEBUG, "LocoMotor_OLD:RunInDirection ", self.inst.prefab)
	--print("I SAID VERBOSITY YOU DAFT MORON")
    
	--NO DONT DO THIS TWICE
    --self.throttle = throttle or 1
	-- self.throttle = self.throttle + 0.3
	
	-- if self.throttle >= 1 then
		-- self.throttle = 1
	-- end
	--print("THROTTLE", self.throttle)
    
    self:SetBufferedAction(nil)
    self.dest = nil
    self:ResetPath()
    self.lastdesttile = nil

    if not self.inst.sg or self.inst.sg:HasStateTag("canrotate") then
        self.inst.Transform:SetRotation(direction)
    end
            
    self.wantstomoveforward = true
    self.wantstorun = true

    if self.directdrive then
        self:RunForward()
    end
    self.inst:PushEvent("locomote")
    self.inst:StartUpdatingComponent(self)
end

function LocoMotor_OLD:DashInDirection(direction, throttle)
    --Print(VERBOSITY.DEBUG, "LocoMotor_OLD:RunInDirection ", self.inst.prefab)
    
    --self.throttle = throttle or 1
	-- self.throttle = 1
	self.throttle = self.throttle + 0.3
	
	if self.throttle >= 1 then
		self.throttle = 1
	end
    
    self:SetBufferedAction(nil)
    self.dest = nil
    self:ResetPath()
    self.lastdesttile = nil

    if not self.inst.sg or self.inst.sg:HasStateTag("canrotate") then
        self.inst.Transform:SetRotation(direction)
    end
            
    self.wantstomoveforward = true
    self.wantstorun = true

    if self.directdrive then
        self:RunForward()
    end
    self.inst:PushEvent("locomote")
    self.inst:StartUpdatingComponent(self)
end




--11-20, FACES THE OPPOSITE WAY
function LocoMotor_OLD:TurnAround(initiald) --11-7-17 ADDING AN OPTIONAL FIELD TO DISTIGUISH INITIAL DIRECTION TO FIX PROBLEMS CAUSED BY WALKING TURNING YOU AROUND TWICE
	--projectile:ForceFacePoint((pos.x - self.xoffset + pointdir), (pos.y + self.yoffset + 1), (pos.z + self.zoffset))
	
	local currentrot = self.inst.Transform:GetRotation()
	-- print("TURNING AROUND ONLY ONCE-------", self.inst.Transform:GetRotation())
	
	--11-7-17 REUSEABLE
	if initiald then
		currentrot = initiald
		-- print("STEP ON THE GRASS")
	end
	
	if currentrot <= - 90 or currentrot >= 90 then --1-6 LOL I WONDER IF THIS WILL FIX IT. --YEP IT DID
		currentrot = -180
	else
		currentrot = 0
	end
		
	self.inst.Transform:SetRotation(currentrot + 180)
	-- print("TURNING AROUND THE SECOND TIME", self.inst.Transform:GetRotation())
end

--7-6 --FACES A TARGET
function LocoMotor_OLD:FaceTarget(target)
	if not target:IsValid() then
		return end
	
	local enposx, enposy, enposz = target.Transform:GetWorldPosition()
	
	self.inst:ForceFacePoint(enposx, enposy, enposz)
end

--8-19  A NEW ATTEMPT TO TRY AND AVOID CHEAT TURNING --IT FEELS KIND OF POINTLESS
function LocoMotor_OLD:FaceTargetIfPossible(target)
	if not target:IsValid() then
		return end
		
	local enposx, enposy, enposz = self.inst.components.stats.opponent.Transform:GetWorldPosition()
	if self.inst.sg:HasStateTag("running") or not self.inst.sg:HasStateTag("busy") then
		self.inst:ForceFacePoint(enposx, enposy, enposz)
	end
end


--1-11 --THIS DOESNT WORK-fixed! 	--12-23-18 OH WELL HEY THAT EXPLAINS WHY HIS FSPEC IS ALL MESSED UP AS RECOVERY
function LocoMotor_OLD:FaceCenterStage() 
	
	--12-23-18 COME ON LETS FIX THIS DUMB THING
	local stageposx = 0
	local stageposy = 0
	local stageposz = 0
	self.inst:ForceFacePoint(stageposx, stageposy, stageposz)
end


--12-15 TARGET FACES THE SAME DIRECTION YOU ARE FACING
function LocoMotor_OLD:FaceWithMe(target)
	local currentrot = self.inst.Transform:GetRotation()
	target.Transform:SetRotation(currentrot)
end

--12-15 TARGET FACES THE OPPOSITE DIRECTION AS THE DIRECTION YOU ARE FACING
function LocoMotor_OLD:FaceAwayWithMe(target)
	local currentrot = self.inst.Transform:GetRotation()
	target.Transform:SetRotation(currentrot+180)
end

function LocoMotor_OLD:TeleportToSelf(target)
	local pos = Vector3(self.inst.Transform:GetWorldPosition())
	local currentrot = self.inst.Transform:GetRotation()
	target.Transform:SetPosition((pos.x), (pos.y), (pos.z))
	target.Transform:SetRotation(currentrot+180)
end

function LocoMotor_OLD:Teleport(x, y, z)
	local pos = Vector3(self.inst.Transform:GetWorldPosition())
	local dir = self.inst.components.launchgravity:GetRotationValue()
	self.inst.Transform:SetPosition((pos.x+(x*dir)), (pos.y+y), (pos.z))
end


function LocoMotor_OLD:SlowFall(newfallspeed, duration)
	local duration = duration--*FRAMES
	self.inst.components.stats.fallingspeed = newfallspeed
	self.inst.slowfalltask = self.inst:DoPeriodicTask(0*FRAMES, function()
		
		duration = duration - 1--(1*FRAMES)
			
		if duration == 0 then
			self.inst.components.stats:ResetFallingSpeed()
			self.inst.slowfalltask:Cancel()
			-- self.inst.Physics:ClearMotorVelOverride() --DO WE NEED THIS??
		end
	end)
end


--10-21-20
-- function LocoMotor_OLD:IsTargetOffstage(target)
	
	-- local enposx, enposy, enposz = self.inst.components.stats.opponent.Transform:GetWorldPosition()

	-- if mypos <= (self.anchor.components.gamerules.lledgepos + 3) or mypos >= (self.anchor.components.gamerules.rledgepos - 3) then
-- end


--REPLACES PHYSICS WITH A FORCED DIRECTIONAL MOVEMENT FOR THE NUMBER OF FRAMES GIVEN
function LocoMotor_OLD:Motor(xvel, yvel, duration)
	local duration = duration--*FRAMES
	self.inst:RemoveTag("listenforfullhop") --10-20-17 LISTENFORFULLHOP CHECK -REUSEABLE
	
	--10-20-18 IF WE'VE ALREADY GOT A MOTOR RUNNING, CANCEL IT! -REUSEABLE
	if self.inst.motortask then 
		self.inst.motortask:Cancel()
	end
	
	self.inst.motortask = self.inst:DoPeriodicTask(0*FRAMES, function(inst)
		if not self.inst:HasTag("hitfrozen") then --10-7-18 DONT REDUCE IF PLAYER IS IN HITLAG! -REUSEABLE
			-- self.inst.Physics:SetMotorVelOverride(xvel,yvel,0)
			self.inst.Physics:SetMotorVel(xvel,yvel,0)
			
			duration = duration - 1--(1*FRAMES)
			
			self.inst:AddTag("motoring")
			
			-- local xmotor,ymotor,zmotor = self.inst.Physics:GetMotorVel()
			-- print("I CANT BELEIVE IT. YOUTUBE ACTUALLY CLEANED UP THEIR COMMENTS", xmotor,ymotor)
				
			if duration == 0 then
				self.inst.motortask:Cancel()
				-- self.inst.Physics:ClearMotorVelOverride() --DO WE NEED THIS?? --8-6 I GUESS THE ANSWER IS YES!! OR ELSE HAROLD'S F SPECIAL NEVER STOPS
				-- print("WHY WOULD YOU BETRAY ME LIKE THIS?")
				self.inst:RemoveTag("motoring") --10-7-18 --SHOULDNT I ALSO ADD THIS HERE?? WELL... I WILL. JUST IN CASE
			end
		end
	end)
	
	self.inst:DoTaskInTime((duration+2)*FRAMES, function(inst) --8-7 HM. THIS COULD CAUSE PROBLEMS IN THE FUTURE IF LONG MOTORS ARE INTERUPTED AND MOTORING IS NOT REMOVED... OH WELL. 
		self.inst:RemoveTag("motoring")
	end)
	
end



function LocoMotor_OLD:GetDebugString()
    local pathtile_x = -1
    local pathtile_y = -1
    local tile_x = -1
    local tile_y = -1
    local ground = GetWorld()
    if ground then
        pathtile_x, pathtile_y = ground.Pathfinder:GetPathTileIndexFromPoint(self.inst.Transform:GetWorldPosition())
        tile_x, tile_y = ground.Map:GetTileCoordsAtPoint(self.inst.Transform:GetWorldPosition())
    end

    local speed = self.wantstorun and "RUN" or "WALK"
    return string.format("%s [%s] [%s] (%u, %u):(%u, %u) +/-%2.2f", speed, tostring(self.dest), tostring(self.bufferedaction), tile_x, tile_y, pathtile_x, pathtile_y, self.arrive_step_dist or 0) 
end

function LocoMotor_OLD:HasDestination()
    return self.dest ~= nil
end

function LocoMotor_OLD:SetShouldRun(should_run)
    self.wantstorun = should_run
end

function LocoMotor_OLD:WantsToRun()
    return self.wantstorun == true
end

function LocoMotor_OLD:WantsToMoveForward()
    return self.wantstomoveforward == true
end

function LocoMotor_OLD:WaitingForPathSearch()
    return self.path and self.path.handle
end

function LocoMotor_OLD:OnUpdate(dt)

    if not self.inst:IsValid() then
        --Print(VERBOSITY.DEBUG, "OnUpdate INVALID", self.inst.prefab)
        self:ResetPath()
		self.inst:StopUpdatingComponent(self)	
		return
    end
    
	if self.enablegroundspeedmultiplier then
		self.creep_check_timeout = self.creep_check_timeout - dt
		if self.creep_check_timeout < 0 then
			self:UpdateGroundSpeedMultiplier()
			self.creep_check_timeout = .5
		end
	end
    
    
    --Print(VERBOSITY.DEBUG, "OnUpdate", self.inst.prefab)
    if self.dest then
        --Print(VERBOSITY.DEBUG, "    w dest")
        if not self.dest:IsValid() or (self.bufferedaction and not self.bufferedaction:IsValid()) then
            self:Clear()
            return
        end
        
        -- if self.inst.components.health and self.inst.components.health:IsDead() then
            -- self:Clear()
            -- return
        -- end
        
        local destpos_x, destpos_y, destpos_z = self.dest:GetPoint()
        local mypos_x, mypos_y, mypos_z= self.inst.Transform:GetWorldPosition()
        local dsq = distsq(destpos_x, destpos_z, mypos_x, mypos_z)

		local run_dist = self:GetRunSpeed()*dt*.5
        if dsq <= math.max(run_dist*run_dist, self.arrive_dist*self.arrive_dist) then
            --Print(VERBOSITY.DEBUG, "REACH DEST")
            self.inst:PushEvent("onreachdestination", {target=self.dest.inst, pos=Point(destpos_x, destpos_y, destpos_z)})
            if self.atdestfn then
                self.atdestfn(self.inst)
            end

            if self.bufferedaction and self.bufferedaction ~= self.inst.bufferedaction then
            
                if self.bufferedaction.target and self.bufferedaction.target.Transform then
                    self.inst:FacePoint(self.bufferedaction.target.Transform:GetWorldPosition())
                end
                self.inst:PushBufferedAction(self.bufferedaction)
            end
            self:Stop()    --@@COULD THIS BE THE ANSWER???   --NOPE
            self:Clear()
        else
            --Print(VERBOSITY.DEBUG, "LOCOMOTING")
            if self:WaitingForPathSearch() then
                local pathstatus = GetWorld().Pathfinder:GetSearchStatus(self.path.handle)
                --Print(VERBOSITY.DEBUG, "HAS PATH SEARCH", pathstatus)
                if pathstatus ~= STATUS_CALCULATING then
                    --Print(VERBOSITY.DEBUG, "PATH CALCULATION complete", pathstatus)
                    if pathstatus == STATUS_FOUNDPATH then
                        --Print(VERBOSITY.DEBUG, "PATH FOUND")
                        local foundpath = GetWorld().Pathfinder:GetSearchResult(self.path.handle)
                        if foundpath then
                            --Print(VERBOSITY.DEBUG, string.format("PATH %d steps ", #foundpath.steps))

                            if #foundpath.steps > 2 then
                                self.path.steps = foundpath.steps
                                self.path.currentstep = 2

                                -- for k,v in ipairs(foundpath.steps) do
                                --     Print(VERBOSITY.DEBUG, string.format("%d, %s", k, tostring(Point(v.x, v.y, v.z))))
                                -- end

                            else
                                --Print(VERBOSITY.DEBUG, "DISCARDING straight line path")
                                self.path.steps = nil
                                self.path.currentstep = nil
                            end
                        else
                            Print(VERBOSITY.DEBUG, "EMPTY PATH")
                        end
                    else
                        if pathstatus == nil then
                            Print(VERBOSITY.DEBUG, string.format("LOST PATH SEARCH %u. Maybe it timed out?", self.path.handle))
                        else
                            Print(VERBOSITY.DEBUG, "NO PATH")
                        end
                    end

                    GetWorld().Pathfinder:KillSearch(self.path.handle)
                    self.path.handle = nil
                end
            end

            if not self.inst.sg or self.inst.sg:HasStateTag("canrotate") then
                --Print(VERBOSITY.DEBUG, "CANROTATE")
                local facepos_x, facepos_y, facepos_z = destpos_x, destpos_y, destpos_z

                if self.path and self.path.steps and self.path.currentstep < #self.path.steps then
                    --Print(VERBOSITY.DEBUG, "FOLLOW PATH")
                    local step = self.path.steps[self.path.currentstep]
                    local steppos_x, steppos_y, steppos_z = step.x, step.y, step.z

                    --Print(VERBOSITY.DEBUG, string.format("CURRENT STEP %d/%d - %s", self.path.currentstep, #self.path.steps, tostring(steppos)))

                    local step_distsq = distsq(mypos_x, mypos_z, steppos_x, steppos_z)
                    if step_distsq <= (self.arrive_step_dist)*(self.arrive_step_dist) then
                        self.path.currentstep = self.path.currentstep + 1

                        if self.path.currentstep < #self.path.steps then
                            step = self.path.steps[self.path.currentstep]
                            steppos_x, steppos_y, steppos_z = step.x, step.y, step.z

                            --Print(VERBOSITY.DEBUG, string.format("NEXT STEP %d/%d - %s", self.path.currentstep, #self.path.steps, tostring(steppos)))
                        else
                            --Print(VERBOSITY.DEBUG, string.format("LAST STEP %s", tostring(destpos)))
                            steppos_x, steppos_y, steppos_z = destpos_x, destpos_y, destpos_z
                        end
                    end
                    facepos_x, facepos_y, facepos_z = steppos_x, steppos_y, steppos_z
                end

                local x,y,z = self.inst.Physics:GetMotorVel()
                if x < 0 then
                    --Print(VERBOSITY.DEBUG, "SET ROT", facepos)
	                local angle = self.inst:GetAngleToPoint(facepos_x, facepos_y, facepos_z)
                    self.inst.Transform:SetRotation(180 + angle)
                else
                    --Print(VERBOSITY.DEBUG, "FACE PT", facepos)
                    self.inst:FacePoint(facepos_x, facepos_y, facepos_z)
                end

            end
            
            self.wantstomoveforward = self.wantstomoveforward or not self:WaitingForPathSearch()
        end
    end
	
	local is_moving = self.inst.sg and self.inst.sg:HasStateTag("moving")  
	
    local is_running = self.inst.sg and self.inst.sg:HasStateTag("running")
	
	local is_blocking = self.inst.sg and self.inst.sg:HasStateTag("blocking")  --@@@@@@
    local should_locomote = (not is_moving ~= not self.wantstomoveforward) or (is_moving and (not is_running ~= not self.wantstorun)) -- 'not' is being used on this line as a cast-to-boolean operator
    -- if not self.inst:IsInLimbo() and should_locomote and not is_blocking then --then  --ADDING NOTBLOCKING 10-14 @@@@
	if not self.inst:IsInLimbo() and should_locomote and not is_blocking and not self.inst.sg:HasStateTag("busy") then --3-21 CHANGIN IT UP, ADDING A BUSY DETECTOR HELPED FIX THE LANDING RUNSTOP BUG
        self.inst:PushEvent("locomote")
    elseif not self.wantstomoveforward and not self:WaitingForPathSearch() then
        self:ResetPath()
        self.inst:StopUpdatingComponent(self)
    end
	

	
    
	local cur_speed = self.inst.Physics:GetMotorSpeed()
	if cur_speed > 0 then
		
		local speed_mult = self:GetSpeedMultiplier()
		local desired_speed = self.isrunning and self.runspeed or self.walkspeed
		if self.dest and self.dest:IsValid() then
			local destpos_x, destpos_y, destpos_z = self.dest:GetPoint()
			local mypos_x, mypos_y, mypos_z = self.inst.Transform:GetWorldPosition()
			local dsq = distsq(destpos_x, destpos_z, mypos_x, mypos_z)
			if dsq <= .25 then
				speed_mult = math.max(.33, math.sqrt(dsq))
			end
		end
		
		
		--OH SNAP, IM CHANGING THIS CODE 			--2-21-17 OH MAN, THIS TAKES ME BACK. WASNT THIS THE FIRST CHANGE OF CODE I EVER MADE?? I THINK IT WAS. THE GOOD OL' DAYS
		
		--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		
		--self.inst.Physics:SetMotorVel((desired_speed + self.bonusspeed) * speed_mult, 0, 0)
		--self.inst.Physics:SetMotorVel((desired_speed + self.bonusspeed) * speed_mult, self.inst.components.highjumper.GetFallingSpeed(), 0)
		
		if self.inst.components.launchgravity then
			--accspeed = self.inst.components.launchgravity:GetAccelerationLeft()
			-- :/ COME ON MAN
		else
			self.inst.Physics:SetMotorVel((desired_speed + self.bonusspeed) * speed_mult, 0, 0)
		end
	end
end

function LocoMotor_OLD:FindPath()
    --Print(VERBOSITY.DEBUG, "LocoMotor_OLD:FindPath", self.inst.prefab)

    --if self.inst.prefab ~= "wilson" then return end
    
    if not self.dest:IsValid() then
        return
    end

    local p0 = Vector3(self.inst.Transform:GetWorldPosition())
    local p1 = Vector3(self.dest:GetPoint())
    local dist = math.sqrt(distsq(p0, p1))
    --Print(VERBOSITY.DEBUG, string.format("    %s -> %s distance %2.2f", tostring(p0), tostring(p1), dist))

    -- if dist > PATHFIND_MAX_RANGE then
    --     Print(VERBOSITY.DEBUG, string.format("TOO FAR to pathfind %2.2f > %2.2f", dist, PATHFIND_MAX_RANGE))
    --     return
    -- end

    local ground = GetWorld()
    if ground then
        --Print(VERBOSITY.DEBUG, "GROUND")

        local desttile_x, desttile_y = ground.Pathfinder:GetPathTileIndexFromPoint(p1.x, p1.y, p1.z)
        --Print(VERBOSITY.DEBUG, string.format("    dest tile %d, %d", desttile_x, desttile_y))

        if desttile_x and desttile_y and self.lastdesttile then
            --Print(VERBOSITY.DEBUG, string.format("    last dest tile %d, %d", self.lastdesttile.x, self.lastdesttile.y))
            if desttile_x == self.lastdesttile.x and desttile_y == self.lastdesttile.y then
                --Print(VERBOSITY.DEBUG, "SAME PATH")
                return
            end
        end

        self.lastdesttile = {x = desttile_x, y = desttile_y}

        --Print(VERBOSITY.DEBUG, string.format("CHECK LOS for [%s] %s -> %s", self.inst.prefab, tostring(p0), tostring(p1)))

        local isle0 = ground.Map:GetIslandAtPoint(p0:Get())
        local isle1 = ground.Map:GetIslandAtPoint(p1:Get())
        --print("Islands: ", isle0, isle1)

        if isle0 ~= NO_ISLAND and isle1 ~= NO_ISLAND and isle0 ~= isle1 then
            --print("NO PATH (different islands)", isle0, isle1)
            self:ResetPath()
        elseif ground.Pathfinder:IsClear(p0.x, p0.y, p0.z, p1.x, p1.y, p1.z, self.pathcaps) then
            --print("HAS LOS")
            self:ResetPath()
        else
            --print("NO LOS - PATHFIND")

            -- while chasing a moving target, the path may get reset frequently before any search completes
            -- only start a new search if we're not already waiting for the previous one to complete OR 
            -- we already have a completed path we can keep following until new search returns
            if (self.path and self.path.steps) or not self:WaitingForPathSearch() then

                self:KillPathSearch()

                local handle = ground.Pathfinder:SubmitSearch(p0.x, p0.y, p0.z, p1.x, p1.y, p1.z, self.pathcaps)
                if handle then
                    --Print(VERBOSITY.DEBUG, string.format("PATH handle %d ", handle))

                    --if we already had a path, just keep following it until we get our new one
                    self.path = self.path or {}
                    self.path.handle = handle

                else
                    Print(VERBOSITY.DEBUG, "SUBMIT PATH FAILED")
                end
            end
        end

    end
end


return LocoMotor_OLD

