React = Class(BehaviourNode, function(self, inst, max_chase_time, give_up_dist, max_attacks, findnewtargetfn, walk)
    BehaviourNode._ctor(self, "React")
    self.inst = inst
	
	self.caution = 0
	
	--1-31-17 --TABLES FOR REACTING TO VISIBLE FEARS
	self.projs = {}
	self.fears = {}
	
	self.scaried = false
	self.scaried2 = false --THE SECOND PHASE OF SCARIED USED FOR THE VISITER
	
	
	--WAIT DONT WE ALREADY HAVE A VERSION OF THIS IN DEFENDSELF?... EH WHATEVER
	self.onblockedfn = function(inst, data)
        self:OnBlocked()
    end
	
	self.inst:ListenForEvent("block_hit", self.onblockedfn)
	
	self.debugprint = AIDEBUGPRINT
end)

function React:DebugPrint(output) --STEALING IT AND ADDING MY OWN FLAIR
	if self.debugprint == true then
		print("ReacT: " .. output)
	end
end

function React:__tostring()
    return string.format("target %s", tostring(self.inst.components.combat.target))
end

function React:SkillCheck()
	return self.inst.components.aifeelings.ailevel
end



function React:InitAction() --HAPPENS ONLY ONCE SO THAT EVENTLISTENERS DON'T PILE UP ON EACH OTHER
    
	local reacttime = 6 --THE DEFAULT FOR HAROLD
	-- local reacttime = 4 --OKAY BUT HE WAS STILL WAY TOO SLOW
	
	if self:SkillCheck() <= 3 then 
		reacttime = 25
	elseif self:SkillCheck() <= 5 then 
		reacttime = 15
	elseif self:SkillCheck() <= 7 then
		reacttime = 10
	end
	
	--DEFINES HOW OFTEN THE FEAR-CHECKER RUNS AND RE RUNS TO DECIDE WHEN TO BLOCK SOMETHING LARGE ON SCREEN
	self.inst:DoPeriodicTask((reacttime*(FRAMES)), function() 
		self:SearchForProjectiles()
	end)
	
end


function React:OnStop()
	--DONT FORGET TO REMOVE THE EVENT LISTENERS SO THEY DONT HAPPEN EVEN WHEN BEHAVIOR ISNT ACTIVE. --VERY SMART KLEI~
	self.inst:RemoveEventCallback("block_hit", self.onblockedfn)
end

function React:OnBlocked()
	-- self.inst:RemoveTag("wantstoblock")
	
	-- self.status = SUCCESS
	-- print("I HAD A SHIELD")
	-- -- self.status = SUCCESS
end

function React:SearchForProjectiles(target)
	
	local myposx, myposy, myposz = self.inst.Transform:GetWorldPosition()
	-- local ents = TheSim:FindEntities(myposx, myposy, myposz, radius, musttags, canttags, mustoneoftags)
	-- local projs = TheSim:FindEntities(myposx, myposy, myposz, 25, {"projectile"})
	-- self.projs = TheSim:FindEntities(myposx, myposy, myposz, 25, {"projectile"})
	
	for k,v in pairs(self.projs) do
        if v:IsValid() then --and v:HasTag("projectile") 
            -- print("THERES A PROJECTILE!!!!")
			
			if self.inst.components.aifeelings:CalculateTrajectory(3, 0, 0, 3, 2, "none", v) and self.inst.components.aifeelings:IsSafeToEdgeAct() then
				-- self.inst.sg:GoToState("block")
				self.inst:PushEvent("block_key")
				self.inst:AddTag("wantstoblock")
			end
        end
        -- if num_helpers >= maxnum then
            -- break --BREAK?? HMM, THIS COULD BE USEFUL. ESPECIALLY FOR THAT HITBOX BUG
        -- end
    end
	
	
	-- self.fears = TheSim:FindEntities(myposx, myposy, myposz, 25, {"fearbox"})
	for k,v in pairs(self.fears) do
		if v:IsValid() then --and v:HasTag("projectile") 
			if self.inst.components.aifeelings:CalculateTrajectory(3, 0, 0, 3, 2, "none", v) and self.inst.components.aifeelings:IsSafeToEdgeAct() then
				-- self.inst.sg:GoToState("block")
				self.inst:PushEvent("block_key")
				self.inst:AddTag("wantstoblock")
			end
        end
    end
	
	self.projs = TheSim:FindEntities(myposx, myposy, myposz, 25, {"projectile"})
	self.fears = TheSim:FindEntities(myposx, myposy, myposz, 25, {"fearbox"})
	
	
	
	if self.scaried == true then
		if math.random() < ((self.inst.components.aifeelings:ConfidencePercent() / 2)) then --RIGGED
			self.scaried = false --IGNORE IT. GO THROUGH ANOTHER TWO LOOPS THEN RE-THINK THE DECISION
		else
			self:DebugPrint("!!!EEK! SOMETHING SPOOKED ME. CANCELING ATTACK NODE")
			self.inst.components.aifeelings:GetAttackNode().status = SUCCESS
			self:ReactToScary()
			self.scaried2 = true
		end
		if self.inst.sg:HasStateTag("blocking") then 
			self.status = FAILED --LET DEFENDSELF TAKE OVER
			if self.inst.components.aifeelings:GetDefendNode() then
				self.inst.components.aifeelings:GetDefendNode().status = READY --2-1-17 INTERESTING. I FOUND A WAY TO JUMP TO A SPECIFIC NODE IN THE BRAIN (BECAUSE IT WOULDNT GO BY ITSELF)
				self.inst.components.aifeelings:GetDefendNode():Visit()
			end
			-- print("DO YER THANG GIRL")
		end
	else
		-- self.status = FAILED
		-- self.inst:RemoveTag("wantstoblock") --WHEN I LEFT OFF, HE WAS GOING TO CHASEANDFIGHT WHILE CHARGING SMASHES
		-- self.inst:AddTag("going_in")
		self.status = SUCCESS --SUCCESS --FAILED
		self.scaried2 = false 
		-- self.inst.components.aifeelings:GetAttackNode().status = SUCCESS
	end
	
	if self.inst.components.stats.opponent.sg:HasStateTag("scary") and math.random() < (0.5) then --7-13-17 ADDING THE CHANCE TO FAIL THE SCARY CHECK
		self.scaried = true
		-- self:ReactToScary()
	elseif not self.inst.components.stats.opponent.sg:HasStateTag("scary") then
		self.scaried = false
	end
	
	-- print("MONSTERS UNDER THE BED?", self.scaried)
end





function React:ReactToScary()
	-- self.inst.components.talker:Say("EEP! I'M SCARED!")
	
    local opponent = self.inst.components.stats.opponent
		
	self.inst:RemoveTag("going_in")
	
	if self:DistFromEnemy("horizontal") < 25 then --20 
		self.inst:PushEvent("halt")
		self.inst:AddTag("wantstoblock")
		-- self.status = SUCCESS --ONWARD TO DEFENDSELF!
		-- self.inst.components.talker:Say("I BETTER BLOCK THAT!")
		self.inst.components.aifeelings:GetDefendNode().blockscary = true --7-12-17
	elseif self:DistFromEnemy("horizontal") < 50 then
		self.inst:RemoveTag("wantstoblock")
		self.inst:PushEvent("halt")
	else
		self.inst:RemoveTag("wantstoblock")
	end
	
	-- self.status = SUCCESS
end






--7-19
function React:DistFromEnemy(dir)
	--JUST CALL THE REAL ONE
	return self.inst.components.aifeelings:DistFromEnemy(dir)
end



-- 7-12-17  --A JUMP AWAY FROM THE OPPONENT TO AVOID GETTING SMASHED
function React:EvadeJump()
	
	--1-16-22 DON'T DRIFT BACKWARDS IF WE ARE OFFSTAGE! THAT COULD KILL US
	if not self.inst.components.aifeelings:IsOffstage() then
		if self.inst.components.aifeelings:IsTargetFacingTarget(self.inst, self.inst.components.stats.opponent) then
			self.inst.components.jumper.jumpdir = "backward"
		else
			self.inst.components.jumper.jumpdir = "forward"
		end
	end
	
	self.inst:PushEvent("jump")
	-- self.inst.components.talker:Say("JUMP OVER THAT!!!")
	self.status = RUNNING
	
	self.inst:DoTaskInTime( 0, function() --SO IT WONT STAY ALL THE WAY TO HIS NEXT JUMP  --THIS IS ACTUALLY THE ONLY EXISTING USE OF THIS JUMPDIR METHOD RIGHT NOW
		self.inst.components.jumper.jumpdir = "none"
	end)
end




function React:Visit()
    
    if self.status == READY then
        -- self:DebugPrint("VISITING REACT")
		local opponent = self.inst.components.stats.opponent
		
		if self.inst.sg:HasStateTag("f_charge") or self.inst:HasTag("stayinghome") then
			self.status = FAILED 
		end
		
		if self.scaried2 then
			self.status = SUCCESS 
		else
			self.status = FAILED 
		end
		
		
		--8-25 TESTING A NEW VERSION OF THE ABOVE FUNCTION WITH A REACTION TIME   
		--CONCLUSION?? DOES IT WORK BETTER??? EHH.. ITS MORE REALISTIC I GUESS BUT HE'S REAL LATE ON THE REACTION TIME
		--12-28-16 YOU KNOW WHAT, I'M JUST GONNA TURN THIS OFF FOR NOW. I THINK IT'S STAGGERING HIS APPROACH AND ITS REAL WEIRD
		--[[
		if self.inst:HasTag("going_in") and not self.inst:HasTag("stayinghome") then
			if self.inst.components.stats.opponent and self.inst.components.stats.opponent.sg:HasStateTag("running") and self.inst.components.aifeelings:IsTargetFacingTarget(self.inst.components.stats.opponent, self.inst) then --"dashing"
				-- print("DASHING THROUGH THE SNOW", self.inst.components.aifeelings:CalculateTrajectory(2, 3, 1, 3))
				if self.inst.components.aifeelings:CalculateTrajectory(20, 1, 0, 3) and self.caution >= 1 and math.random() < (1) then --(frames, xpos, ypos, range)  --(2, 3, 1, 3)
					print("IN A ONE HORSE OPEN SLIEGH") --ITS JULY. STOP THIS
					self.inst:RemoveTag("going_in")
					self.inst:AddTag("wantstoblock")
					self.inst:AddTag("braceyourself")
					-- self.inst.components.aifeelings:AddFear(1)
					self.inst:DoTaskInTime(1, function(inst) self.inst:RemoveTag("braceyourself") end ) --7-29 THIS NEEDS TO BE HERE OR ELSE IT WILL NEVER STOP COWERING IF DEFENDSELF DISTANCE IS NOT REACHED
					self.inst:PushEvent("block_key")
					self.status = SUCCESS --RUNNING --SUCCESS
				end
				
				self.caution = self.caution + 1
			else
				self.caution = 0 --self.caution - 1
			end
		end
		]]
		
		
		local opponent = self.inst.components.stats.opponent
		--A LIST OF STATES THAT THEY COUND'T REALLY HURT US IN
		if opponent.sg:HasStateTag("inknockback") or opponent.sg:HasStateTag("helpless") or opponent.sg:HasStateTag("ll_medium") 
			or opponent.sg:HasStateTag("tryingtoblock") or opponent.sg:HasStateTag("dodging") or opponent.sg:HasStateTag("hanging") 
			or opponent.sg:HasStateTag("grounded") then
			--YOU'RE NOT DANGEROUS TO US AT ALL RIGHT NOW. JUST IGNORE...
			self.status = FAILED
			return end
			
			
		
		if self.inst.components.launchgravity:GetIsAirborn() and not self.inst:HasTag("going_in") then  
			if self.inst.components.aifeelings:CalculateTrajectory(1, 0, 0, 4) then --(frames, xpos, ypos, range)
				--7-12-17
				if self.inst.components.jumper.currentdoublejumps >= 1 and math.random() < (0.8) then
					self:DebugPrint("JUMP OVER THAT TO EVADE!")
					self:EvadeJump() --BASICALLY, JUMP AWAY AND DRIFT BACKWARDS
				elseif math.random() < --[[ Chance to proc ]] (0.8) then
					self.inst:PushEvent("block_key")
					self.inst:RemoveTag("wantstoblock")
					-- self.inst:PushEvent("throwattack")
					self:DebugPrint("ATTEMPTING TO AIRDODGE!")
					self.status = SUCCESS --RUNNING --SUCCESS
				else
					self.inst:PushEvent("throwattack")
				end
			end
		end
    end


	--THIS WILL NEVER RUN
    if self.status == RUNNING then
		--7-12-17 AH, LETS JUST TRY THIS IN HERE AGAIN
		self.inst.components.aifeelings:GetAttackNode():DriftTowardOpp(1, "away")
	end
end
