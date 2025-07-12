


local TUNING = GLOBAL.TUNING
local distsq = GLOBAL.distsq
local Vector3 = GLOBAL.Vector3
local FRAMES = GLOBAL.FRAMES

--SOME LOCALS FROM THE ORIGINAL VERSION
local PATHFIND_PERIOD = 1
local PATHFIND_MAX_RANGE = 40

local STATUS_CALCULATING = 0
local STATUS_FOUNDPATH = 1
local STATUS_NOPATH = 2

local NO_ISLAND = 127

local ARRIVE_STEP = .15



--OK IT'S TIME I STARTED CLEANING SOME OF THESE UP.
AddComponentPostInit("locomotor", function(self)
	
	self.dashspeed = TUNING.WILSON_RUN_SPEED
	self.creep_check_timeout = 0 --PART OF THE ORIGINAL
	self.bonusspeed = 0 --PART OF THE ORIGINAL, NO LONGER USED
	
	self.UpdateGroundSpeedMultiplier = function(self)
		--GUTTED
	end
	
	self.TempGroundTile = function(self)
		--GUTTED
	end
	
	self.StopMoving = function(self)
		self.isrunning = false
		-- self.inst.Physics:Stop() --DON'T ACTUALLY STOP- YES IT DOES WHAT AM I TALKING ABOUT
	end
	
	
	self.GetDashSpeed = function(self)
		return (self.dashspeed ) * self:GetSpeedMultiplier() --THIS INCLUDES THE THROTTLE  --+ self:GetBonusSpeed() -DOESNT EXIST ANYMORE
	end
	
	
	self.RunForward = function(self)
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
		-- print("MYVEL RUNNING: ", vx, self:GetRunSpeed())
		
		--THE +1 IS BURNED IN FROM THE VERY BEGINNING :/ MY B
		-- self.inst.Physics:SetMotorVel(self:GetDashSpeed()+1,vy,0)
		self.inst.Physics:SetMotorVel(self:GetRunSpeed()+1,vy,0)
		
		-- self.inst:StartUpdatingComponent(self)
		--4-17-21 THE MODERN DST CODE USES THIS INSTEAD... SHOULD WE GIVE IT A TRY? LETS DO IT
		self:StartUpdatingInternal()
	end
	
	
	self.DashForward = function(self)
		--self.isrunning = true
		if self.inst.components.launchgravity then
			
			-- self.throttle = self.throttle + 0.3
			-- if self.throttle >= 1 then
				-- self.throttle = 1
			-- end
			--1-14-22 NAH MAN. THROTTLE 1
			self.throttle = 1
			
			local accspeed = 1 --im sorry
			local x,y,z = self.inst.Physics:GetMotorVel()
			local vx, vy = self.inst.Physics:GetVelocity()
			-- print("MYVEL DASHING: ", vx, self:GetDashSpeed())
			self.inst.Physics:SetMotorVel((self:GetDashSpeed() + accspeed),vy,0)
		else
			self.inst.Physics:SetMotorVel(self:GetRunSpeed(),0,0)
			print("JUST ANOTHER NOTE TO DELETE LATER")
		end
		-- self.inst:StartUpdatingComponent(self)
		self:StartUpdatingInternal() --4-17-21
	end
	
	
	
	self.Stop = function(self)
		--Print(VERBOSITY.DEBUG, "LocoMotor:Stop", self.inst.prefab)
		self.isrunning = false
		self.dest = nil
		self:ResetPath()
		self.lastdesttile = nil
		--self.arrive_step_dist = 0

		--self:SetBufferedAction(nil)
		self.wantstomoveforward = false
		self.wantstorun = false
		
		if self.inst.components.jumper then
			self:StopMoving()
		end

		self.inst:PushEvent("locomote")
		-- self.inst:StopUpdatingComponent(self)
		self:StopUpdatingInternal() --4-17-21
	end
	
	
	--DO WE NEED THESE TWO?? --YES WE DO. OTHERWISE IT OVERWRITES OUR THROTTLE
	self.RunInDirection = function(self, direction, throttle)
		--NO DONT DO THIS TWICE
		--self.throttle = throttle or 1
		
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
		self:StartUpdatingInternal()
	end
	
	
	--THIS IS HARDLY DIFFERENT FROM RUNINDIRECTION() AT ALL...
	self.DashInDirection = function(self, direction, throttle)
		--4-27-21 I GUESS WE DO IT TWICE HERE THOUGH?
		--self.throttle = self.throttle + 0.3
	
		-- if self.throttle >= 1 then
			-- self.throttle = 1
		-- end
		
		--1-14-22 NAH IF WE DASH, THROTTLE = 1
		self.throttle = 1
		
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
		self:StartUpdatingInternal()
	end
	
	
	
	
	
	
	--AND NOW FOR THE BIG LISTENFORFULLHOP
	--11-20, FACES THE OPPOSITE WAY
	self.TurnAround = function(self, initiald) --11-7-17 ADDING AN OPTIONAL FIELD TO DISTIGUISH INITIAL DIRECTION TO FIX PROBLEMS CAUSED BY WALKING TURNING YOU AROUND TWICE
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
	self.FaceTarget = function(self, target)
		if not target:IsValid() then
			return end
		
		local enposx, enposy, enposz = target.Transform:GetWorldPosition()
		
		self.inst:ForceFacePoint(enposx, enposy, enposz)
	end

	--8-19  A NEW ATTEMPT TO TRY AND AVOID CHEAT TURNING --IT FEELS KIND OF POINTLESS
	self.FaceTargetIfPossible = function(self, target)
		if not target:IsValid() then
			return end
			
		local enposx, enposy, enposz = self.inst.components.stats.opponent.Transform:GetWorldPosition()
		if self.inst.sg:HasStateTag("running") or not self.inst.sg:HasStateTag("busy") then
			self.inst:ForceFacePoint(enposx, enposy, enposz)
		end
	end


	--1-11 --THIS DOESNT WORK-fixed! 	--12-23-18 OH WELL HEY THAT EXPLAINS WHY HIS FSPEC IS ALL MESSED UP AS RECOVERY
	self.FaceCenterStage = function(self) 
		
		--12-23-18 COME ON LETS FIX THIS DUMB THING
		local stageposx = 0
		local stageposy = 0
		local stageposz = 0
		self.inst:ForceFacePoint(stageposx, stageposy, stageposz)
	end


	--12-15 TARGET FACES THE SAME DIRECTION YOU ARE FACING
	self.FaceWithMe = function(self, target)
		local currentrot = self.inst.Transform:GetRotation()
		target.Transform:SetRotation(currentrot)
	end

	--12-15 TARGET FACES THE OPPOSITE DIRECTION AS THE DIRECTION YOU ARE FACING
	self.FaceAwayWithMe = function(self, target)
		local currentrot = self.inst.Transform:GetRotation()
		target.Transform:SetRotation(currentrot+180)
	end
	
	--1-27-22 FACE LEFT OR RIGHT, PLAIN AND SIMPLE.
	self.FaceDirection = function(self, dir)
		--local currentrot = self.inst.Transform:GetRotation()
		if dir == "left" then
			self.inst.Transform:SetRotation(0)
		elseif dir == "right" then
			self.inst.Transform:SetRotation(180)
		else
			-- print("REQUESTED TO FACE INVALID DIRECTION!")
		end
	end

	self.TeleportToSelf = function(self, target)
		local pos = Vector3(self.inst.Transform:GetWorldPosition())
		local currentrot = self.inst.Transform:GetRotation()
		target.Transform:SetPosition((pos.x), (pos.y), (pos.z))
		target.Transform:SetRotation(currentrot+180)
	end

	self.Teleport = function(self, x, y, z)
		local pos = Vector3(self.inst.Transform:GetWorldPosition())
		local dir = self.inst.components.launchgravity:GetRotationValue()
		self.inst.Transform:SetPosition((pos.x+(x*dir)), (pos.y+y), (pos.z))
	end


	self.SlowFall = function(self, newfallspeed, duration)
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
	-- self.IsTargetOffstage(target)
		
		-- local enposx, enposy, enposz = self.inst.components.stats.opponent.Transform:GetWorldPosition()

		-- if mypos <= (self.anchor.components.gamerules.lledgepos + 3) or mypos >= (self.anchor.components.gamerules.rledgepos - 3) then
	-- end


	--REPLACES PHYSICS WITH A FORCED DIRECTIONAL MOVEMENT FOR THE NUMBER OF FRAMES GIVEN
	self.Motor = function(self, xvel, yvel, duration)
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
					
				if duration == 0 then
					self.inst.motortask:Cancel()
					-- self.inst.Physics:ClearMotorVelOverride() --DO WE NEED THIS?? --8-6 I GUESS THE ANSWER IS YES!! OR ELSE HAROLD'S F SPECIAL NEVER STOPS
					self.inst:RemoveTag("motoring") --10-7-18 --SHOULDNT I ALSO ADD THIS HERE?? WELL... I WILL. JUST IN CASE
				end
			end
		end)
		
		self.inst:DoTaskInTime((duration+2)*FRAMES, function(inst) --8-7 HM. THIS COULD CAUSE PROBLEMS IN THE FUTURE IF LONG MOTORS ARE INTERUPTED AND MOTORING IS NOT REMOVED... OH WELL. 
			self.inst:RemoveTag("motoring")
		end)
		
	end
	
	
	
	
	
	
	--AND HERES THE MAIN ONE--
	--SOO... THIS IS STILL BASED OFF THE SINGLEPLAYER VERSION, I THINK? DO WE WANT TO TRY AND MERGE THIS WITH THE EXISTING ONE?
	--NAH. LETS JUST LEAVE IT AS IS FOR NOW, AS LONG AS IT WORKS. DON'T WANT ANY UPDATES CHECKING FOR NEW COMPONENTS THAT WON'T EXIST
	self.OnUpdate = function(self, dt)

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
				--12-21-21 GETTING RID OF THIS BECAUSE I'M PRETTY SURE THIS IS ONLY FOR DRAGWALKING. ALSO GETWORLD() WILL DEF CRASH THE GAME
				--[[ 
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
				]]

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
	
	
end)



-- function LocoMotor:TempGroundTile() --OH, THIS WAS AN ACTUAL REAL FUNCTION. I JUST GUTTED IT
	-- return false
-- end

-- function LocoMotor:StopMoving() --11-10-20 DOES.. THIS WORK?? WHATEVER IM LEAVING IT HERE
	-- self.isrunning = false
-- end


