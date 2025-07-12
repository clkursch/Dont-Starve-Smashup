DefendSelf = Class(BehaviourNode, function(self, inst, hunterparams, see_dist, safe_dist, fn, runhome)
    BehaviourNode._ctor(self, "DefendSelf")
    self.inst = inst
	
	-- self.timetoblock = 1
	-- self.timeblockstarted = 0
	-- punishblockedmove = false --7-14
	------- --7-5 STUFF
	self.distfromenemy = 0
	self.blockscary = false --7-12-17 SOMETHING EASIER
	
	self.onblockedfn = function(inst, data)
        -- self:OnBlocked()
		self.inst.components.aifeelings.punishblockedmove = true --1-16-22 THIS MAKES MUCH MORE SENSE
    end
	
	self.ontargetnewstatefn = function(inst, data) --7-14
        self.inst.components.aifeelings.punishblockedmove = false
    end
	
	self.onfinishrollingfn = function(inst, data)
        self:OnFinishRolling()
    end
	
	self.inst:ListenForEvent("block_hit", self.onblockedfn)
	self.inst:ListenForEvent("targetnewstate", self.ontargetnewstatefn) --7-14
	self.inst:ListenForEvent("finishrolling", self.onfinishrollingfn) --8-14 --TO DECIDE WHAT TO DO AFTER ROLLING
	
	self.anchor = TheSim:FindFirstEntityWithTag("anchor") --DST
	self.debugprint = AIDEBUGPRINT
end)

function DefendSelf:__tostring()
    -- return string.format("RUNAWAY %f from: %s", self.safe_dist, tostring(self.hunter))
	return string.format("RUNAWAY %f from: %s")
end

--10-5-21 ARTIFICIAL WILSON USES THIS TO METHOD TO DEBUG PRINT AND ITS HONESTLY GENIUS
function DefendSelf:DebugPrint(output, output2) --STEALING IT AND ADDING MY OWN FLAIR
	if self.debugprint == true then
		print("DefS: " .. output.. (output2 or ""))
	end
end



function DefendSelf:OnStop()
	--DONT FORGET TO REMOVE THE EVENT LISTENERS SO THEY DONT HAPPEN EVEN WHEN BEHAVIOR ISNT ACTIVE. --VERY SMART KLEI~
	self.inst:RemoveEventCallback("block_hit", self.onblockedfn)
	-- self.inst:RemoveEventCallback("finishrolling", self.onfinishrollingfn) --12-28-16 ADDING THIS. I DONT THINK IT WAS NEEDED TO FIX THE PROBLEM I WAS TRYING TO, SHOULD I LEAVE IT HERE?
	self.inst.components.aifeelings.punishblockedmove = false --12-29-16 
end



--2-27-17
function DefendSelf:SkillCheck()
	return self.inst.components.aifeelings.ailevel
end


--8-14 --TO TEST IF ENTITY IS FACING A SELECTED TARGET
function DefendSelf:IsTargetFacingTarget(target1, target2)

	local enpos = target2.Transform:GetWorldPosition() --self.inst.components.stats.opponent.Transform:GetWorldPosition()
	local mypos = target1.Transform:GetWorldPosition() --self.inst.Transform:GetWorldPosition()
	
    -- if mypos*self.inst.components.launchgravity:GetRotationValue() >= enpos*self.inst.components.launchgravity:GetRotationValue() then
	if target1.components.launchgravity and (mypos*target1.components.launchgravity:GetRotationValue() >= enpos*target1.components.launchgravity:GetRotationValue()) then
		return false
	else
		return true
	end
end


--1-16-22 WHAT THE HECK IS THIS??? THIS THING SUCKS. GET RID OF IT
--[[
function DefendSelf:OnBlocked()
	-- self.inst.components.talker:Say("MISSED ME!")
	local timetonotice = math.random(0.20,0.30)
	
	if self:SkillCheck() <= 5 then --LOWER BLOCK REACTION TIME FOR DUMBER LEVELS
		timetonotice = math.random(2,3)
	elseif self:SkillCheck() <= 7 then
		timetonotice = math.random(0.5,1)
	end
	
	local timetonotice = math.random(5.2,5.3)
	self.inst:DoTaskInTime(timetonotice, function(inst) --REPLACING THE ABOVE WITH THIS NEW VERSION THAT INCLUDES REACTION TIME
		self.inst:RemoveTag("wantstoblock")
		self.inst:RemoveTag("blockoverride")
		-- self.inst.components.talker:Say("SAFE TO UNBLOCK?")
		self:DebugPrint("SAFE TO UNBLOCK? UNBLOCKING")
		self.inst.components.aifeelings.punishblockedmove = true --3-4-17 MOVED THIS UP INTO THE REACTION TIME THING --IT STILL FEELS WAY TOO FAST?...
		self.inst:RemoveTag("braceyourself")
	end )
	
	-- self.inst.components.aifeelings.punishblockedmove = true --3-4-17 MOVED THIS UP INTO THE REACTION TIME THING BECAUSE HE WOULD STILL REACT TOO FAST 
	--print("I HAD A SHIELD")
	-- self.status = SUCCESS
	-- self.inst:RemoveTag("braceyourself") --THIS TOO
end
]]

--7-6
function DefendSelf:ReactToHit()
	-- self.inst.components.talker:Say("OW!")
	
	if self:SkillCheck() <= 3 then
		return end
	
	self.inst:AddTag("wantstoblock")

	--TRY ADDING WANTS TO JUMP IF IN AIR --8-11
	if self.inst.components.launchgravity:GetIsAirborn() then
	
	end
end


-- 8-14
function DefendSelf:OnFinishRolling()
	
	local opponent = self.inst.components.stats.opponent
	local punishchance = 0.0
	local defendchance = 0.0 --OOPS I DIDNT ACTUALLY USE THIS
	
	if self:IsTargetFacingTarget(self.inst, opponent) then
		punishchance = punishchance + 0.2
	else
		punishchance = punishchance - 0.2
	end
	
	if self:IsTargetFacingTarget(opponent, self.inst) then
		punishchance = punishchance - 0.2
	else
		punishchance = punishchance + 0.4
	end
	
	if self.inst.components.aifeelings.punishblockedmove then
		punishchance = punishchance + 0.3  -- + 0.2 
	else
		-- punishchance = punishchance - 0.2
	end
	
	--9-5 !!!! LEFT OFF HERE!!!!! UNSURE IF THESE ARE WORKING AND THE DODGEFN STILL SEEMS TO NO BE WORKING PROPERLY!!
	--BUG HAROLD STOPS BLOCKING AFTER THE INITIAL BACKWORDS ROLL
	
	--THERE IS A 50% CHANCE TO PUNISH, BUT ALTERNATIVELY, VARIABLES CAN CAUSE CERTAIN PASS/FAIL SITUATIONS
	if math.random() < (0.5 + punishchance -0.17 + (self.inst.components.aifeelings:ConfidencePercent() / 4)) then 
		self:DebugPrint("HIYA! PUNISHING AFTER A DODGE ROLL!")
		self.inst:RemoveTag("wantstoblock")
		self.inst.components.aifeelings:GetAttackNode():ChooseAttack()
		self.status = FAILED
		-- self.inst.components.talker:Say("BATON PASS")
	else
		self:DebugPrint("HIYA! ROLLING AGAIN AFTER A DODGE ROLL!")
		self:Dodgefn() --JUST CONTINUE GETTING OUTTA THERE
	end
	
end



-- function DefendSelf:ShouldDropSheild()
	-- return (GetTime() - self.timeblockstarted) > self.timetoblock --(GetTime() - self.timelastattacked) > self.shieldtime
-- end


function DefendSelf:Blockfn()
	-- self.timeblockstarted = GetTime()
	self.inst:AddTag("wantstoblock")
end



function DefendSelf:RandomActions(actions) 
	return actions[math.random(#actions)]
end

function DefendSelf:DistFromEnemy(dir)
	--JUST CALL THE REAL ONE
	return self.inst.components.aifeelings:DistFromEnemy(dir)
end



--7-6 DODGE FUNCTION
function DefendSelf:Dodgefn(situation)   --"SITUATION" CALLS FOR IF YOU WANT TO BUFFER THE MOVE OR JUST DODGE RIGHT NOW
	
	local myposx, myposy = self.inst.Transform:GetWorldPosition() --IF I EVER FIX THE VERTACLE DISTANCE DETECTION, ILL HAVE TO FIX THIS TOO --TODOLIST
	-- local oppx, oppy = GetPlayer().Transform:GetWorldPosition()
	local oppx, oppy = self.inst.components.stats.opponent.Transform:GetWorldPosition()
	
	local opponent = self.inst.components.stats.opponent
	
	if self.inst.components.stats.opponent then
		oppx, oppy = self.inst.components.stats.opponent.Transform:GetWorldPosition()
	else
		self:DebugPrint("NO VALID OPPONENT FOUND ")
		self.status = SUCCESS
		return end
	
	self.distfromenemy = distsq(myposx, 0, oppx, 0) --7-5
	
	
	--9-10
	local dodgedistancemod = 0
	if self.inst.components.aifeelings:IsOpponentApproaching() then
		dodgedistancemod = 2
	end
	
	
	-- if self.inst.sg:HasStateTag("attack") then            --and self.distfromenemy <= 2 then
		if self.distfromenemy <= 10 then --8 maybe
			-- print("THE NOON IS HIGH AND SO AM I", self.distfromenemy <= 6, self:IsTargetFacingTarget(opponent, self.inst))
			self:DebugPrint("DODGEFN! ROLLING AWAY!")
			if self.distfromenemy <= 6 + dodgedistancemod and self:IsTargetFacingTarget(opponent, self.inst) then
				if situation == "buffer" then
					-- self.inst.components.stats:SetMoveBuffer("roll", "forward")
					self.inst.components.stats:SetKeyBuffer("roll", "forward")
				else
					self.inst:PushEvent("roll", {key = "forward"})
				end
			else
				if situation == "buffer" then
					-- self.inst.components.stats:SetMoveBuffer("roll", "backward")
					self.inst.components.stats:SetKeyBuffer("roll", "backward")
				else
					self.inst:PushEvent("roll", {key = "backward"})
				end
			end
			-- print("SETTING MOVE BUFFER")
			self.inst.components.aifeelings.punishblockedmove = true --9-5 SO HE CAN PUNISH AFTER ROLLS TOO
		else
			self.inst.components.stats:ClearMoveBuffer()
			self:DebugPrint("DODGEFN! IM FAR AWAY, I DONT NEED TO ROLL")
			-- print("IM FAR AWAY, I DONT NEED TO ROLL")
		end
	-- end
	
	if not self.inst.components.launchgravity:GetIsAirborn() and self:DistFromEnemy() >= 10 then --5  --9-6
		self.inst:RemoveTag("wantstoblock")
		self:DebugPrint("SUCCESSFULLY DODGED AWAY! WE CAN RELAX NOW ")
		self.status = FAILED
	end
	
end



function DefendSelf:Visit()

    if self.status == READY then
		
		
		
		
		--10-3-20 WE SHOULD ALSO CHECK TO SEE IF WE SHOULD DEFEND FROM SOMEONE ELSE
		if self.inst.components.aifeelings:CheckForAlternateOpponent() then --WILL RETURN TRUE IF WE FIND A BETTER OPPONENT (IT SETS ITSELF)
			--print("I FOUND A CLOSER OPPONENT!") --WE DONT NEED THE PRINT STATEMENT, BUT WE DO NEED THE FUNCTION ABOVE
		end
		self:DebugPrint("VISITING DEFENDSELF: fear:", self.inst.components.aifeelings:ConfidencePercent())-- self.inst.components.aifeelings.fear)
		
		if self:SkillCheck() <= 3 then --TOO DUMB TO BLOCK
			self:DebugPrint("HUR DUR, I DON'T KNOW HOW TO BLOCK")
			self.status = FAILED
			return end
		
		
		--1-15-22
		local defendnode = self.inst.components.aifeelings:GetDefendNode()
		if defendnode and defendnode.status == RUNNING then
			self:DebugPrint("I'M KIND OF BUSY WITH CHASEANDFIGHT RIGHT NOW...")
			self.status = SUCCESS
			return end
		
		if not self.inst.components.stats.opponent:IsValid() then
			self.status = SUCCESS
			return end
		
		local myposx, myposy = self.inst.Transform:GetWorldPosition() --IF I EVER FIX THE VERTACLE DISTANCE DETECTION, ILL HAVE TO FIX THIS TOO --TODOLIST
		local oppx, oppy = self.inst.components.stats.opponent.Transform:GetWorldPosition()
		
		if self.inst.components.stats.opponent then
			oppx, oppy = self.inst.components.stats.opponent.Transform:GetWorldPosition()
		end
		

		if self.inst.sg:HasStateTag("inknockback") then 
			self.inst:AddTag("wantstoblock")
			self:DebugPrint("I'VE BEEN HIT! I WANT TO BLOCK")
			self.status = RUNNING
		
		elseif self.inst.sg:HasStateTag("grounded") then --or self.inst:HasTag("escape") then --8-7 --WAIT SHOULDN'T I GET RID OF THIS??
			self:DebugPrint("I WANT TO GET UP")
			self.status = RUNNING
			
		elseif self.inst.components.aifeelings.punishblockedmove then --MAKE A COUNTERATTACK FUNCION AT SOME POINT 7-14 --TODOLIST
			-- self.inst.components.talker:Say("TIME FOR YOUR PUNISHMENT!")
			self:DebugPrint("TIME TO PUNISH A BLOCKED MOVE!")
			if self:DistFromEnemy() <= 1.6 and math.random() < (0.70) and self:IsTargetFacingTarget(self.inst, self.inst.components.stats.opponent) then --2  --1.6
				-- self.inst.components.talker:Say("COME ERE!")
				-- self.inst:PushEvent("throwattack", {key = "block"})
				-- self.inst.components.stats:SetMoveBuffer("throwattack", "block") -- A MOVE BUFFER???? YOU SHOULD THINK ABOUT GETTING RID OF THESE -12-30-16
				self:DebugPrint("PUNISHING WITH A GRAB! I THINK")
				self.inst.components.stats:SetKeyBuffer("throwattack", "block") --1-15-22 ALRIGHT LETS TRY AND FIX THIS
			else
				
				if math.random() < (0.6 + (self.inst.components.aifeelings:ConfidencePercent() / 4)) then --2-7-17 GIVE HIM A CHANCE TO JUST ROLL AWAY INSTEAD OF PUNISH ALL THE TIME
					self.inst:RemoveTag("wantstoblock") --SAME AS DOWN THERE
					self.inst.components.stats:ClearMoveBuffer() --12-30-16 ALRIGHT. I'LL GIVE MOVEBUFFER ANOTHER SHOT AND JUST FIX THE BUG WITH THIS. BUT IF IT CAUSES PROBLEMS AGAIN, I'M DELETING IT
					self.status = FAILED
					self:DebugPrint("IM TOO FAR AWAY ANYWAYS! LET CHASEANDFIGHT HANDLE THIS", self:DistFromEnemy())
				else
					self:DebugPrint("ON SECOND THOUGHT, IM KINDA SCARED!! LETS ROLL FURTHER AWAY")
					self:Dodgefn("buffer") --2-7-17
					-- self.inst.components.talker:Say("ILL JUST DODGE AWAY")
				end
			end
		
		--1-16-22 OK WHAT EVEN IS THIS THING?? THIS IS WEIRD, GET RID OF IT
		--[[
		elseif self.inst.components.aifeelings.escapemode == true then --7-6
			self.inst:AddTag("wantstoblock")
			self:DebugPrint("DONT HUG ME IM SCARED!", self.inst.components.aifeelings.fear)
			self.inst.components.aifeelings:Tick()
		--]]
		
		elseif (self:DistFromEnemy("horizontal") <= 10 and self:DistFromEnemy("vertical") <= 4) or self.inst:HasTag("braceyourself") then --3
			-- self.inst.components.talker:Say("BLOCKING!")
			self.status = RUNNING
			self:DebugPrint("TOO CLOSE FOR COMFORT! BRACE YOURSELF!")
			self.distfromenemy = distsq(myposx, myposy, oppx, oppy) --7-5
			if self:DistFromEnemy("horizontal") <= 4 and not self.inst:HasTag("blockoverride") then
				self.inst:RemoveTag("braceyourself")
				-- print("NAH I GOT MY BRACES OFF")   --OKAY WHEN DID I PUT THIS DUMB JOKE HERE
			end
			
		elseif self.blockscary == true then --7-12-17 AN ATTEMPT TO FIX THE UN/RE-BLOCKING BUG WITH HAROLD VS LONG RANGE SCARY CHARGING MOVES
			self:DebugPrint("MY SHILED IS LOW! ILL JUST DODGE AWAY")
			if self:DistFromEnemy("horizontal") > 25 or not self.inst.components.stats.opponent.sg:HasStateTag("scary") then
				self.blockscary = false
			end
		else
			-- self.inst.components.talker:Say("UN BLOCKING!")
			self:DebugPrint("I'M FEELING SAFE ENOUGH. END NODE")
			self.inst:RemoveTag("wantstoblock")
			-- self.inst:RemoveTag("braceyourself")
			self.status = FAILED
		end
		
        -- self.status = FAILED
    end

    if self.status == RUNNING then
		
		if self.inst.sg:HasStateTag("dodging") then
			self:DebugPrint("WE'RE IN THE MIDDLE OF DODGING! GIVE US A SEC... ")
			return end
		
		local opponent = self.inst.components.stats.opponent
		
		if self.inst:HasTag("blockoverride") and self.inst.components.blocker:GetPercent() >= 0.4 then  --1-26-17 CURRENTLY USED ONLY FOR BLOCKING DIVE BOMBERS AND NOTHING ELSE
			if not opponent.components.launchgravity:GetIsAirborn() then --2-7-17 WELL, IF ITS ONLY USED FOR DIVE BOMBERS, MIGHT AS WELL TURN IT OFF IF THEYRE ON THE GROUND
				self.inst:RemoveTag("braceyourself")
				self.inst:RemoveTag("blockoverride")
			else
				self:DebugPrint("DIVEBOMB AVERTED. RETURNING TO BASE")
				self.status = SUCCESS
				return end
		end
		
		
		if self.inst.sg:HasStateTag("attack") then 
			self:Dodgefn("buffer")
		end
		
		
		--OPTIONS OUT OF SHIELD!!
		if self.inst.sg:HasStateTag("grounded") then
			self:DebugPrint("RUNNING GETUP OPTIONS!")
			if (self.inst.components.aifeelings:CalculateTrajectory(2, 0, 0, 3) or self:DistFromEnemy("horizontal") <= 10) and math.random() < (0.85) then --(frames, xpos, ypos, range)
					self.inst:PushEvent("attack_key") --GRABS
			elseif (self:DistFromEnemy("horizontal") <= 35 or self.inst:HasTag("braceyourself")) and math.random() < (0.85) then
					self.inst:PushEvent("backward_key")
			elseif (self:DistFromEnemy("horizontal") >= 50) and math.random() < (0.85) then
				self.inst:PushEvent("forward_key")
				
			elseif math.random() < (0.85) then
				self.inst:PushEvent("up")
			end
		end
		
		
		local blockthoughts = 0 --ADDITIONAL VARIABLES THAT AFFECT THE DEFENDING CHANCES
		
		if opponent.sg:HasStateTag("spammy") then --8-11
			blockthoughts = blockthoughts + 0.8
		end
		
		
		--8-8
		if self:DistFromEnemy("horizontal") <= 2 and not (opponent.sg:HasStateTag("spammy") or opponent.sg:HasStateTag("scary")) and not self.inst:HasTag("braceyourself") then
			-- self.inst:PushEvent("throwattack", {key = "block"})
		end
		
		local blockpercent = self.inst.components.blocker:GetPercent()
		-- print("MY PERCENT IS", blockpercent)
		-- print("DIST FROM ENEMY IS", self.distfromenemy)
		self:DebugPrint("CORE DEFENDING MYSELF!")
		if self:DistFromEnemy() >= 5 then
			blockthoughts = blockthoughts - 0.2
		elseif self:DistFromEnemy() >= 12 then
			blockthoughts = blockthoughts - 0.5
		end
		
		if self.inst.components.stats.opponent.sg:HasStateTag("blocking") then  --8-8 NO MORE AWKWARD BLOCK STAREDOWNS
			blockthoughts = blockthoughts - 0.4
		elseif self.inst.components.stats.opponent.sg:HasStateTag("scary") then
			blockthoughts = blockthoughts + 0.4
		end
		
		if not self:IsTargetFacingTarget(opponent, self.inst) then
			blockthoughts = blockthoughts - 0.4
		end
		
		
		--7-5
		if math.random() < --[[ Chance to proc ]] ((blockpercent / 2) + 0.25 + blockthoughts) then    --1-26-17 CHANGING FROM (blockpercent - 0.15 + blockthoughts)
			-- self.timeblockstarted = GetTime()
			-- self.timetoblock = GetRandomWithVariance(1, 0.3)  --1-0.3
			self:Blockfn()
			-- self.inst.components.talker:Say("STRANGER DANGER")
			self:DebugPrint("STRANGER DANGER! CONTINUING TO BLOCK: blockthoughts:", blockthoughts)
			self.inst:AddTag("wantstoblock")
			self.status = SUCCESS
		elseif math.random() < --[[ Chance to proc ]] (0.75) then 
			-- self.inst.components.talker:Say("I'M OUTTA HERE!")
			self:DebugPrint("I'M OUTTA HERE! DODGING AWAY")
			self:Dodgefn()
			self.status = SUCCESS
			
		elseif self:DistFromEnemy() <= 2 then    --1-26-17 WOW, HOW LONG HAS IT BEEN LIKE THIS???  self.distfromenemy <= 2 then 
			self.inst:RemoveTag("wantstoblock")
			-- self.inst.components.talker:Say("COUNTER! I WONT HIDE")
			-- self.inst:PushEvent("throwattack") --1-26-17 GETTING RID OF THIS SO THAT HE CAN CHOOSE HIS OWN ATTACK INSTEAD
			self:DebugPrint("COUNTER! I WON'T HIDE!")
			self.status = FAILED --SO IT WILL JUMP TO CHASEANDFIGHT
		end
		
		
    end
end


