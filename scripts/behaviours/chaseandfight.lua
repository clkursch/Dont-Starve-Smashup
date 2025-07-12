ChaseAndFight = Class(BehaviourNode, function(self, inst, max_chase_time, give_up_dist, max_attacks, findnewtargetfn, walk)
    BehaviourNode._ctor(self, "ChaseAndFight")
    self.inst = inst
    self.findnewtargetfn = findnewtargetfn
    self.max_chase_time = max_chase_time
    self.give_up_dist = give_up_dist
    self.max_attacks = max_attacks
    self.numattacks = 0
    self.walk = walk
	
	
	-------7-23
	self.chosenattack = "dashattack" --"dashattack"
	self.chosenside = "none"
	self.calcframes = 4
	self.calcxpos = 1
	self.calcypos = 0
	self.calcrange = 2
	self.calcrangey = 0 --VALUE OF ZERO USES REGULAR RANGE
	
	self.autoswing = "none" --1-26-17 TO SOLVE THE PROBLEM OF ACTIVATING MOVES THAT SHOULD COME OUT INSTANTLY BUT NOT ON CHOOSEATTACK
	
	self.dashattackmod = 0
	self.fspecialmod = 0
	self.grabmod = 0
	self.baitsmashmod = 0
	
	--1-21-17
	self.jumpinconfidence = 0
	self.divebombfear = 0
	
	--1-3-17 TO TEST IF WHIFFED
	self.swung = true
	self.hit = false
	self.idlelock = false
	self.endonswing = true --1-15-22
	
	self.acc_add = 2 --3-7-17 ADDITIVE ACCURACY MODIFIER FOR DUMBER AI
	
    -- we need to store this function as a key to use to remove itself later
    self.onattackfn = function(inst, data)
        -- self:OnAttackOther(data.target) 
		self:OnAttackOther() 
    end

    self.inst:ListenForEvent("on_hit", self.onattackfn) --onattackother
    self.inst:ListenForEvent("onmissother", self.onattackfn)
	
	-----------------
	self.onattackedfn = function(inst, data)
        self:OnAttacked()
    end
	
	self.onhitshieldfn = function(inst, data)
        self:OnHitShield()
    end
	
	self.onpunishedfn = function(inst, data)
        self:OnPunished()
    end
	
	self.onswingfn = function(inst, data)
        self:DebugPrint("!!I'M TAKING A SWING!", self.endonswing)
		self.swung = true
		if self.endonswing == true then
			self.status = SUCCESS
			self.inst:RemoveTag("going_in")
		end
		self.inst.components.aifeelings.punishblockedmove = false
    end
	
	--11-29-20 LETS EXPAND THIS IDEA OF RESETTING MOVES ON LANDING AFTER AN AIREAL
	--BUT ACTUALLY, LETS TRY EDITING THE XISTING ONE FIRST
	-- self.onhitshieldfn = function(inst, data)
        -- self:OnHitShield()
    -- end
	
	self.onreadyforactionfn = function(inst, data) --8-6 SOMETHING STUPID SO THAT I CAN CALL FUNCTIONS ON RETURN TO IDLE STATE
        -- self:OnReadyForAction()
    end
	
	self.inst:ListenForEvent("attacked", self.onattackedfn)
	self.inst:ListenForEvent("hit_shield", self.onhitshieldfn) --8-27
	self.inst:ListenForEvent("on_punished", self.onpunishedfn)
	self.inst:ListenForEvent("on_swing", self.onswingfn) --1-15-22
	-- self.inst:ListenForEvent("readyforaction", self.onreadyforactionfn) --8-6 SOMETHING STUPID SO THAT I CAN CALL FUNCTIONS ON RETURN TO IDLE STATE 
	-- ^^^^ OKAY THIS HAD TO BE INIT ON BRAIN STARTUP BECAUSE IT NEEDS TO BE ACTIVATED ONLY ONCE, BUT CANT BE REMOVED WHEN LEAVING THE NODE --1-3-17
	
	-- self.inst:ListenForEvent("throwattack", function(inst) self.swung = true end) --1-4-17 THAT WAS EASY --BUT WILL THIS STACK LIKE THE OTHERS DID?? --TODOLIST
	self.anchor = TheSim:FindFirstEntityWithTag("anchor") --DST
	
	--10-5-21 SETTING THIS TO TRUE WILL ENABLE THE STANDARD AI DEBUG PRINTS
	self.debugprint = AIDEBUGPRINT
end)


--10-5-21 ARTIFICIAL WILSON USES THIS TO METHOD TO DEBUG PRINT AND ITS HONESTLY GENIUS
function ChaseAndFight:DebugPrint(output, output2) --STEALING IT AND ADDING MY OWN FLAIR
	if self.debugprint == true then
		print("ChaF: " .. output .. (tostring(output2 or "")))
	end
end
 
function ChaseAndFight:__tostring()
    return string.format("target %s", tostring(self.inst.components.combat.target))
end

function ChaseAndFight:InitAction() --HAPPENS ONLY ONCE SO THAT EVENTLISTENERS DON'T PILE UP ON EACH OTHER
    self.inst:ListenForEvent("readyforaction", self.onreadyforactionfn) --INITS IT ONLY ONCE
	self.inst:ListenForEvent("throwattack", function(inst) self.swung = true end) --1-4-17 THAT WAS EASY
	-- self.inst:ListenForEvent("ground_check", function(inst) self.swung = true end)
	
	self.inst:ListenForEvent("ground_check", function(inst)  --11-29-20 LETS REVAMP THIS TO PROPERLY RESET AFTER AN AIREAL ASSAULT ENDS
		if self.swung == true then
			self.status = SUCCESS
			self.inst.components.aifeelings:GetAttackNode().status = SUCCESS
			self:DebugPrint("==ENDING AIR ASSAULT==")
		end
	end) 
	
end


--2-27-17
function ChaseAndFight:SkillCheck(skill)
	return self.inst.components.aifeelings.ailevel
end


function ChaseAndFight:OnStop()
    self.inst:RemoveEventCallback("onattackother", self.onattackfn)
    self.inst:RemoveEventCallback("onmissother", self.onattackfn)
	
	--DONT FORGET TO REMOVE THE EVENT LISTENERS SO THEY DONT HAPPEN EVEN WHEN BEHAVIOR ISNT ACTIVE. --VERY SMART KLEI~
	self.inst:RemoveEventCallback("attacked", self.onattackedfn)
    self.inst:RemoveEventCallback("hit_shield", self.onhitshieldfn)
	-- self.inst:RemoveEventCallback("readyforaction", self.onreadyforactionfn) --12-29-16 LETS TRY GETTING RID OF THIS AND SEE WHAT HAPPENS... --1-3-17 OH... I MEAN IT WORKS. BUT IT ULSO MULTIPLIES IT EVERY TIME
	self.idlelock = false
end

function ChaseAndFight:OnAttackOther(target)
	local opponent = self.inst.components.stats.opponent
	if not opponent.components.launchgravity:GetIsAirborn() then --9-6 GET MORE CONFIDENT. LESS LIKELY TO BLOCK AND WILL FOLLOW UP MORE ATTACKS
		self.inst.components.aifeelings.blockapproachmod = self.inst.components.aifeelings.blockapproachmod - 10 
	end
	
	self:DebugPrint("LANDED A HIT")
	
	if self.chosenattack == "jumpin" and self.chosenside == "highapproach" then
		-- THAT SHOULD TEACH THEM. WE CAN EASE OFF A BIT
		self:DebugPrint("THAT SHOULD TEACH THEM! HIGH APPROACH PAID OFF")
		self.inst.components.aifeelings.highapproachmod = self.inst.components.aifeelings.highapproachmod / 2
	end
	
	self.hit = true
	self.idlelock = false
end



--1-21-17
function ChaseAndFight:OnPunished(target)
	
	local opponent = self.inst.components.stats.opponent
	-- self.inst.components.talker:Say("I GOT COUNTERED! ")
	-- print("I GOT COUNTERED! ", self.chosenattack)
	
	if self.inst:HasTag("going_in") then
		if self.inst.components.launchgravity:GetIsAirborn()  then
			if self.chosenattack == "followup" or self.chosenattack == "jumpin" then
				-- self.inst.components.talker:Say("THIS WAS A BAD IDEA!")
				self.jumpinconfidence = self.jumpinconfidence - 5
			end
			
			--IF WE JUST TRIED APPROACHING HIGH AND GOT PUNISHED FOR IT, MAYBE TRY A BIT LESS OF THAT
			if self.chosenattack == "jumpin" and self.chosenside == "highapproach" then
				self:DebugPrint("OW! MAYBE HIGHAPPROACH WAS A BAD IDEA")
				self.inst.components.aifeelings.highapproachmod = self.inst.components.aifeelings.highapproachmod / 2
			end
			
		elseif opponent.components.launchgravity:GetIsAirborn() and not self.inst.components.launchgravity:GetIsAirborn() then
			if self.chosenattack == "followup" then
				self.divebombfear = self.divebombfear + 5
			end	
		end
		
	end
	
	--1-17-22 IF  THEY'RE JUST STUNLOCKING US WITH RAPID JABS OR PROJECTILES, TRY APPROACHING HIGH
	if (opponent.sg and opponent.sg:HasStateTag("spammy")) then
		self.inst.components.aifeelings.highapproachmod = self.inst.components.aifeelings.highapproachmod + 2
		self.jumpinconfidence = self.jumpinconfidence +1
		self:DebugPrint("OW! I SHOULD JUMP OVER THAT NEXT TIME")
	elseif opponent:HasTag("projectile") then
		local projectilestats = opponent.components.projectilestats
		if projectilestats.xprojectilespeed > 3 and projectilestats.yprojectilespeed < 1 then
			self:DebugPrint("OW! I SHOULD JUMP OVER THAT NEXT TIME")
			self.inst.components.aifeelings.highapproachmod = self.inst.components.aifeelings.highapproachmod + 10
			self.jumpinconfidence = self.jumpinconfidence + 5
		end
	end
	
	self.inst.components.aifeelings.punishblockedmove = false
	self.inst:RemoveTag("going_in")
end


--1-21-17
function ChaseAndFight:JumpinConfPercent() --RETURNS A NUMBER BETWEEN 0-1 BASED ON CONFIDENCE (FOR RANDOMIZERS)
	math.clamp(self.jumpinconfidence, -20, 20)
	return ((self.jumpinconfidence + 20)/40)
end

function ChaseAndFight:DivebombFearPercent() --RETURNS A NUMBER BETWEEN 0-1
	math.clamp(self.divebombfear, -20, 20)
	return ((self.divebombfear + 20)/40)
end


function ChaseAndFight:AtLowPercent() --RETURNS A NUMBER BETWEEN 0-1 BASED ON CONFIDENCE (FOR RANDOMIZERS)
	local opponent = self.inst.components.stats.opponent
	if opponent and opponent:IsValid() then
		if opponent.components.percent.currentpercent <= 35 then
			return 1
		else
			return 0
		end
	else
		return 0
	end
end

function ChaseAndFight:AtKillPercent() --RETURNS 1 IF THE OPPONENT IS NEAR KILL PERCENT
	local opponent = self.inst.components.stats.opponent
	if opponent and opponent:IsValid() and opponent.components.percent then --THIS IS SILLY, WHY WOULD THE OPPONENT EXIST BUT NOT HAVE PERCENT?? IN SMASHUP, APPARENTLY
		if opponent.components.percent.currentpercent >= 100 then
			return 1
		else
			return 0
		end
	else
		return 0
	end
end



function ChaseAndFight:OnHitShield(target)
    self.inst.components.aifeelings.oppshieldtendancy = self.inst.components.aifeelings.oppshieldtendancy + 1
	self.hit = false
end


--8-14 --TO TEST IF ENTITY IS FACING A SELECTED TARGET
function ChaseAndFight:IsTargetFacingTarget(target1, target2)

	local enpos = target2.Transform:GetWorldPosition() --self.inst.components.stats.opponent.Transform:GetWorldPosition()
	local mypos = target1.Transform:GetWorldPosition() --self.inst.Transform:GetWorldPosition()

    -- if mypos*self.inst.components.launchgravity:GetRotationValue() >= enpos*1 then
	if mypos*target1.components.launchgravity:GetRotationValue() >= enpos*target1.components.launchgravity:GetRotationValue() then
		-- print("OOPS I PASSED EM")
		return false
	else
		return true
	end
end



--1-3-17 --NEW FUNCTION TO FACE OPPONENT, AND PIVOT DASH IF RUNNING
function ChaseAndFight:ChaseTarget()
	
	if self.inst.components.launchgravity:GetIsAirborn() then
		return end
					
	if self.inst.sg:HasStateTag("running") then
		if not self:IsTargetFacingTarget(self.inst, self.inst.components.stats.opponent) then
			self.inst.sg:GoToState("pivot_dash")
		end
	else
		-- self.inst.components.locomotor:FaceTarget(self.inst.components.stats.opponent)
		self.inst.components.locomotor:FaceTargetIfPossible(self.inst.components.stats.opponent)
		if not self.inst.sg:HasStateTag("busy") then
			self.inst:PushEvent("dash")
		end
	end
end



--7-25 -TO SEE IF HE SHOULD BAIT SMASH
function ChaseAndFight:ShouldReactToAttacker(target)
    if self:DistFromEnemy("horizontal") >= 0 and self:DistFromEnemy("horizontal") <= 65 then
		self.chosenattack = "baitsmash"
		self.calcframes = 1
		self.calcrange = 1
		self.calcxpos = 1.6
		self.calcypos = 0
		
	return true
	end
end




function ChaseAndFight:ChooseAttack()
    self:DebugPrint("CHOOSING A NEW ATTACK...--------------------------", "SKILL CHECK = "..tostring(self:SkillCheck()))
	-- self.inst.components.talker:Say("ROLLING THE DICE!")
	
	self.calcrangey = 0 --8-25 TO REFRESH VALUES FOR LEGACY MOVES THAT DO NOT USE A Y RANGE
	self.inst.components.stats.jumpspec = "full"
	self.inst.components.aifeelings.tempfear = 0
	self.chosenside = "none"
	self.autoswing = "none"
	self.endonswing = true
	
	local opponent = self.inst.components.stats.opponent
	if not opponent:IsValid() then
		self.status = SUCCESS
		return end
		

	--8-22 CHANCE BANK
	
	local feelings = self.inst.components.aifeelings --AT THIS POINT IT FEELS LIKE I SHOULD HAVE JUST USED COMPONENTS INSTEAD OF BEHAVIORS
	
	local percdashattack = 35 + feelings.dashattackmod
	local percfspecial = 35 + feelings.fspecialmod
	-- local percgrab = (20 + feelings.grabmod) * (self.inst.components.aifeelings.oppshieldtendancy / 2) --KIND OF A STRANGE FORMULA I KNOW BUT LETS TRY IT OUT
	local percgrab = (20 + feelings.grabmod) + (10 * (self.inst.components.aifeelings.oppshieldtendancy / 2))
	local percbaitsmash = 10 --+ feelings.baitsmashmod --IF OPPONENT IN KNOCKBACK - 25
	local percjumpin = 75 + feelings.jumpinmod  --WHY DOES THIS NEED TO BE SO HIGH FOR HIM TO ACTUALLY START USING IT????? --30
	local percrawfsmash = 20 + feelings.rawfsmashmod + 20*self:AtKillPercent() --!!!!!!!!!!!!!!!!!!!!!
	local percdashingusmash = 18 + feelings.dashingusmashmod + 15*self:AtKillPercent()
	local percblockapproach = 50 + feelings.blockapproachmod
	local percfollowdescent = 0 --1-27-17
	local perctaunt = 0 --JUST STAND THERE AND TAUNT LIKE AN IDIOT
	local percsleep = 0 --EVEN MORE DUMB. JUST TAKE A NAP
	local percnspecial = 30
	local percbair = 10 + (20*self:AtKillPercent()) --20*KILLPERCENT MEANS THAT THE BASE CHANCE WILL INCREASE BY 20 WHEN OPPONENT IS AT KILL PERCENT
	--OOOH DO A BACKWARDS SHORTHOP FAIR ONE
	--ADD A JUMPUP OPTION THAT DOESNT ACTUALLY JUMP, BUT FOLLOWS THE OPPONENT AND USMASHES WHERE THEY WILL LAND
	
	--1-17-22 DETERMINE IF THEY SHOULD APPROACH HIGH OR NOT TO EVADE PROJECTILE SPAM OR STUNLOCKS
	local highapproach = self.inst.components.aifeelings.highapproachmod 
	
	
	--TO ADD A NEW ATTACK TO THE BANK, IT MUST BE INSERTED    -UP ABOVE    -DICE ROLL TOTAL BELOW   -.SELF LIST IN AIFEELINGS AS A MOD  -MOD IN STATEGRAPH TOO PROBABLY
	
	
	--CANCLERS THAT REMOVE CERTAIN MOVES FROM THE POOL IF NOT ELIGIBLE
	if self:DistFromEnemy("horizontal") >= 35 then --LONG RANGE
		-- self.inst.components.talker:Say("LONG RANGE")
		percfspecial = percfspecial + 10
		percdashattack = percdashattack + 10
		percbaitsmash = 0 --dont be a dummy
		percjumpin = percjumpin + 20
		percrawfsmash = 0
		percnspecial = percnspecial + 35
	
	elseif self:DistFromEnemy() >= 10 then --MID RANGE --16
		-- self.inst.components.talker:Say("MID RANGE")
		if math.random() <= 0.7 then
			self.inst.components.stats.jumpspec = "short"
		end
		percrawfsmash = percrawfsmash / 2
		-- percfspecial = percfspecial + 10
		-- percdashattack = percdashattack + 10
		
	elseif self:DistFromEnemy() >= 2.8 then --CLOSE RANGE --8 --6
		-- self.inst.components.talker:Say("CLOSE RANGE")
		percjumpin = 0
		percbaitsmash = percbaitsmash + 8
		percfspecial = percfspecial - 10
		percnspecial = 0
		if self.inst.components.aifeelings:IsOpponentApproaching() then
			percbaitsmash = percbaitsmash + 5
		end
		highapproach = 0
	
	elseif self:DistFromEnemy("horizontal") < 2.8 and self:DistFromEnemy("vertical") < 2 then --POINT BLANK
		-- self.inst.components.talker:Say("POINT BLANK")
		percjumpin = 0
		-- percbaitsmash = percbaitsmash + 10 --WAIT WHAT?
		--percrawfsmash = percrawfsmash + 10
		percfspecial = percfspecial / 4
		percnspecial = 0
		self.chosenattack = "closecombat"
		highapproach = 0
	end
	
	
	if self.chosenattack == "closecombat" and self:SkillCheck() >= 5 then --LEVEL 5 AND OVER CAN DO THE CLOSE COMBAT SCRIPT
		self:DebugPrint("THE RESULTS ARE IN: CHOSENATTACK = closecombat")
		return end
	
	
	
	if self:DistFromEnemy("vertical") > 10 and self:DistFromEnemy("horizontal") < 15 then
		-- percjumpin = 1000
		percjumpin = percjumpin + (100 * self:JumpinConfPercent())
		percfollowdescent = percfollowdescent + 45 + (100 * self:DivebombFearPercent())
	end
	
	
	--9-1
	if self:DistFromEnemy("vertical") > 15 and self:DistFromEnemy("horizontal") < 15 and self.inst.components.aifeelings:IsOpponentApproaching() then --9-8 ADDED CHECK FOR APPROACH SO HE USUALLY FAIRS RUNNING TARGETS
		self.inst.components.stats.jumpspec = "full"
		-- self.chosenattack = "jumpup" 
	end
	
	
	-- percblockapproach = 5000
	
	
	--12-31-16 FINALLY CRACKED INTO BEHAVIOR NODES!!! --THIS IS TO PREVENT HIM PUNISHING WITH A SHIELD BASH
	--[[
	for i,node in ipairs(self.inst.brain.bt.root.children) do
		-- if node.name == "DefendSelf" then --OHHHH ITS TECHNICALY IN A PARALELL NODE --WAIT...NOITS NOT...
		if node.name == "Parallel" and node.children[1].name == "Defend" then
			-- print("I HAVE NODE-I-DEA!...", node.children[1].timetoblock)  --print("I HAVE NODE-I-DEA!...", node[i].punishblockedmove)
			-- print("IF YOURE IN THE TUNNEL", self.inst.brain.bt.root.children[i].children[1].punishblockedmove)
			if node.children[2].punishblockedmove == true then --AAAAAAH ITS THE SECOND CHILD.
				percblockapproach = 0
				percbaitsmash = 0
			end
		end
	end
	]]
	--1-16-22 THIS IS A MILLION TIMES SIMPLER
	if self.inst.components.aifeelings.punishblockedmove == true then
		percblockapproach = 0
		percbaitsmash = 0
	end
	
	--SKILL LIMITER:
	if self:SkillCheck() <= 3 then
		-- percjumpin = 10 + (feelings.jumpinmod * 2) --HEAVIER WEIGHTED MODIFIERS SINCE THESE SPIDERS WONT LAST LONG ANYWAYS
		percjumpin = 12 + (feelings.jumpinmod / 2) --FORGET THAT MAN, THEY SPAM THAT WAAY TOO OFTEN
		percdashattack = 35 + feelings.dashattackmod
		-- perctaunt = 20
		--MAKE THEM MORE DOPEY THE MORE SPIDERS THERE ARE ON SCREEN
		local brothers = self.anchor.components.gamerules:CountPlayersWithTag("spider") --NUMBER OF SPIDERS ON STAGE
		local sleepers = self.anchor.components.gamerules:CountPlayersWithTag("sleeping") --IDK IF THIS COUNTS NPCS?
		-- print("SLEEPERS OUT THERE:", sleepers, brothers)
		-- perctaunt = 30 + ((-1 + brothers) * 20) --TOO TAUNTY
		perctaunt = math.clamp(20 + ((-1 + brothers) * 15),  0, 75)
		percsleep = 0 + math.clamp(((-1 + (brothers - sleepers)) * 5), 0, 15) --CANNOT BE LESS THAN 0, OR MORE THAN 15
		
		percfspecial = 0
		percgrab = 3
		percbaitsmash = 0
		percrawfsmash = 3
		percdashingusmash = 0
		percblockapproach = 0
		percfollowdescent = 0 
		percnspecial = 3
		percbair = 0
		highapproach = highapproach / 2
		
		self.inst.components.stats.jumpspec = "full"  --THEY STILL SEEM TO SHORTHOP FAIR?? FIND WHAT IS CAUSING THIS (did i ever fix this?)
		
		
	elseif self:SkillCheck() <= 5 then
		-- percjumpin = 10 + feelings.jumpinmod
		-- percdashattack = 35 + feelings.dashattackmod
		perctaunt = 20
		
		-- percfspecial = 0
		percgrab = percgrab / 2
		percbaitsmash = percbaitsmash / 2
		percrawfsmash = percrawfsmash / 2
		percdashingusmash = percdashingusmash / 3
		-- percblockapproach = percblockapproach / 
		percfollowdescent = percfollowdescent / 3
		-- percnspecial = 3
		percbair = percbair / 3
		
		--CLOSE COMBAT HAPPENS FOR LVL 5 AND ABOVE
		
	elseif self:SkillCheck() <= 7 then
		-- percjumpin = 10 + feelings.jumpinmod
		-- percdashattack = 35 + feelings.dashattackmod
		perctaunt = 10
		-- percfspecial = 0
		percgrab = percgrab / 1.5
		percbaitsmash = percbaitsmash / 1.5
		percrawfsmash = percrawfsmash / 1.5
		percdashingusmash = percdashingusmash / 2
		-- percblockapproach = percblockapproach / 
		percfollowdescent = percfollowdescent / 2
		-- percnspecial = 3
		percbair = percbair / 3
	end
	
	
	--1-3-22 PUT SOME CLAMPS ON THIS TO MAKE SURE NO NEGATIVES EXIST
	percdashattack = math.clamp(math.ceil(percdashattack), 0, 200)
	percfspecial = math.clamp(math.ceil(percfspecial), 0, 200)
	percgrab = math.clamp(math.ceil(percgrab), 0, 200)
	percbaitsmash = math.clamp(math.ceil(percbaitsmash), 0, 200)
	percjumpin = math.clamp(math.ceil(percjumpin), 0, 200)
	percrawfsmash = math.clamp(math.ceil(percrawfsmash), 0, 200)
	percdashingusmash = math.clamp(math.ceil(percdashingusmash), 0, 200)
	percblockapproach = math.clamp(math.ceil(percblockapproach), 0, 200)
	
	highapproach = math.clamp(math.ceil(highapproach), -10, 50) --NOT REALLY "NEEDED" FOR THIS ONE BUT PROBABLY GOOD TO HAVE
	
	--RANGE TESTER
	-- self.inst.components.hitbox:SetSize(0.2)
	-- self.inst.components.hitbox:SetLingerFrames(20) --2
	-- self.inst.components.hitbox:SpawnHitbox(math.sqrt(35), -1, 0)
	-- self.inst.components.hitbox:SpawnHitbox(math.sqrt(10), -1, 0)
	-- self.inst.components.hitbox:SpawnHitbox(math.sqrt(2.8), -1, 0)
	-- self.inst.components.hitbox:SpawnHitbox(math.sqrt(1), -1, 0)
	
	-- self.inst.components.hitbox:SetSize(0.35)
				-- self.inst.components.hitbox:SetLingerFrames(30) --2
	
	-- self.inst.components.hitbox:SpawnHitbox(math.sqrt(15), math.sqrt(0), 0)
	-- self.inst.components.hitbox:SpawnHitbox(math.sqrt(0), math.sqrt(15), 0)
	-- self.inst.components.hitbox:SpawnHitbox(math.sqrt(40), math.sqrt(0), 0)
	-- self.inst.components.hitbox:SpawnHitbox(math.sqrt(0), math.sqrt(20), 0)
	
	
	--I THINK ITS TIME WE GOT RIDDA THIS --1-21-17
	-- if opponent.sg:HasStateTag("tumbling") or opponent:HasTag("juggled") then 
		-- percjumpin = percjumpin + 100
		-- percgrab = 0
		-- percbaitsmash = 0
		
		-- -- percdashingusmash = 1000
		-- -- self.inst:PushEvent("dash")
		-- -- self.inst:DoTaskInTime(0.1, function(inst) self.inst:PushEvent("singlejump") end )
	-- end
	
	-- percfspecial = 2000
	-- percgrab = percgrab + 2000 --JUST FOR TESTING!! --TESTING COMPLETE
	
	local perctotal = percdashattack + percfspecial + percbaitsmash + percgrab + percjumpin + percrawfsmash + percdashingusmash + percblockapproach + percfollowdescent + perctaunt + percnspecial + percbair + percsleep
	
	-- if perctotal <= 0 then --1-4-17 THERE MAYBE THIS +1 WILL STOP THE "EMPTY INTERVAL" CRASH. ARE YOU HAPPY?
		-- self:ChooseAttack()
		-- return end
	--1-3-22 NO, THIS SHOULD NEVER BE A THING. IF PERCTOTAL IS LESS THAN 0 THEN IT WILL ALWAYS BE. THROW AN ERROR.
	assert(perctotal > 0, "AI ChooseAttack returned an invalid pool of results: "..tostring(perctotal).." - Please report this bug on the mod workshop page.")
	
	
	local diceroll = math.random(0, perctotal)
	-- print("ROLLING THE DICE -------------", diceroll, perctotal)
	
	--1-17-22 DETERMINE THE CHANCE TO APPROACH HIGH
	if math.random(0, 40) < highapproach then
		self.chosenside = "highapproach"
	end
	
	
	local accuracy = 1 --3-7-17 A VARIABLE THAT AFFECTS HOW ACCURATE THEIR ATACKS WILL BE !!THE HIGHER THE NUMBER, THE LOWER THE ACCURACY!!
	
	if diceroll <= (percdashattack) then
		-- self.inst.components.talker:Say("ITS A LIVIN")
	-- self.inst:PushEvent("throwattack")
		-- CalculateTrajectory(1, 2, 3)
		self.chosenattack = "dashattack"
		-- self.inst:AddTag("stayinghome")
		self.calcframes = 10
		self.calcxpos = 1.2 + math.random(-1*accuracy,1*accuracy)
		self.calcypos = 0
		self.calcrange = 1 + self.acc_add
		self.calcrangey = 2 + self.acc_add
		
		if self:SkillCheck() <= 3 then --7-5-18 GIVE BABY SPIDERS SOMETHING MORE FITTING
			self.calcframes = 5
			self.calcxpos = 0.5 + math.random(-0.8,0.8)
			self.calcypos = 0
			self.calcrange = 1.5 --+ self.acc_add
			self.calcrangey = 1  --+ self.acc_add
		end
	elseif diceroll <= (percdashattack + percfspecial) then --0.45
		self.chosenattack = "fspecial"
		self.calcframes = 1
		self.calcxpos = 3 + math.random(-2*accuracy,2*accuracy)
		self.calcypos = 0
		self.calcrange = 5
	elseif diceroll <= (percdashattack + percfspecial + percbaitsmash) then --and self:DistFromEnemy("horizontal") <= 60 then --THIS COULD CAUSE PROBLEMS
		self.chosenattack = "baitsmash"
		self.calcframes = 1
		self.calcxpos = 1.2 + math.random(-0.5*accuracy,0.5*accuracy)
		self.calcypos = 0
		self.calcrange = 1.5
		self.endonswing = false --1-15-22
		-- self.autoswing = "fsmash"
		-- self.status = SUCCESS
		-- self.inst.components.talker:Say("1000 ON BLACK")
		-- if self:ShouldReactToAttacker() then
			-- return end
	
	elseif diceroll <= (percdashattack + percfspecial + percbaitsmash + percgrab) then
		-- self.inst:PushEvent("throwattack", {key = "block"})
		self.chosenattack = "grab"
		self.calcframes = 3
		self.calcxpos = 0.4 + math.random(-0.2*accuracy,0*accuracy) --LOWERING GRAB RANGE BECAUSE HE GRABS WAY TOO EARLY --0.5
		self.calcypos = 0
		self.calcrange = 0.5 + self.acc_add
	elseif diceroll <= (percdashattack + percfspecial + percbaitsmash + percgrab + percjumpin) then --and self:DistFromEnemy("horizontal") >= 45 then
		self.chosenattack = "jumpin" 
		-- self.inst:AddTag("stayinghome")
		self.calcframes = 5 --30 NEVER WORKS WELL  --00000000--7-9-17 OK SO HOLD UP..... YOU TELLIN ME THESE RANGE CALUES ARENT USED AT ALL?? ITS ALL STATIC, SET DOWN BELOW
		self.calcxpos = 2
		self.calcypos = 0 -- -3
		self.calcrange = 1 +self.acc_add  --2
		self.endonswing = false --1-15-22
		if self.inst.components.stats.jumpspec == "short" then --8-25 FOR SHORTHOP NAIRS
			self.calcframes = 5
			self.calcxpos = 1.0
			self.calcypos = 0
			self.calcrange = 2
			self.calcrangey = 5 + self.acc_add
		end
	elseif diceroll <= (percdashattack + percfspecial + percbaitsmash + percgrab + percjumpin + percrawfsmash) then
		self.inst:PushEvent("throwattack", {key = "fsmash"})
		-- self.inst.components.talker:Say("RAW FSMASH")
	elseif diceroll <= (percdashattack + percfspecial + percbaitsmash + percgrab + percjumpin + percrawfsmash + percdashingusmash) then
		self.chosenattack = "dashingusmash" 
		self.calcframes = 6
		self.calcxpos = 0.5 + math.random(-0.3*accuracy,0.1*accuracy)
		self.calcypos = 0
		self.calcrange = 0.8 + self.acc_add
		self.calcrangey = 1.5 + self.acc_add
		-- self.inst.components.talker:Say("RAW USMASH")
	elseif diceroll <= (percdashattack + percfspecial + percbaitsmash + percgrab + percjumpin + percrawfsmash + percdashingusmash + percblockapproach) then
		self.chosenattack = "blockapproach" 
		self.calcframes = 10
		self.calcxpos = 1.6 + math.random(-0.5*accuracy,0.5*accuracy)
		self.calcypos = 0
		self.calcrange = 2 
		-- self.inst.components.talker:Say("RAW USMASH")
	elseif diceroll <= (percdashattack + percfspecial + percbaitsmash + percgrab + percjumpin + percrawfsmash + percdashingusmash + percblockapproach + percfollowdescent) then
		self.chosenattack = "followdescent" 
		if math.random() < (0.7 - (self:JumpinConfPercent() / 2) - (self.inst.components.aifeelings:ConfidencePercent() / 3)) then
			self.chosenside = "block" -- ^^^ DUPLICATE OF THE FOLLOWUP DETECTOR BELOW
		end
	elseif diceroll <= (percdashattack + percfspecial + percbaitsmash + percgrab + percjumpin + percrawfsmash + percdashingusmash + percblockapproach + percfollowdescent + perctaunt) then
		self.chosenattack = "taunt" 
		
	elseif diceroll <= (percdashattack + percfspecial + percbaitsmash + percgrab + percjumpin + percrawfsmash + percdashingusmash + percblockapproach + percfollowdescent + perctaunt + percnspecial) then
		-- self.inst:PushEvent("throwattack", {key = "fspecial"})
		self.chosenattack = "nspecial"
		self.calcframes = 8
		self.calcxpos = 5 + math.random(-2*accuracy,2*accuracy)
		self.calcypos = 0
		self.calcrange = 1
		self.calcrangey = 6
	elseif diceroll <= (percdashattack + percfspecial + percbaitsmash + percgrab + percjumpin + percrawfsmash + percdashingusmash + percblockapproach + percfollowdescent + perctaunt + percnspecial + percbair) then
		self.chosenattack = "bair"  --NOT SO SURE IF THIS WILL WORK
		self.calcframes = 5 --THIS WAS PROBABLY FOR BAIR --YEA THIS SEEMS ABOUT RIGHT
		self.calcxpos = -1.5
		self.calcypos = 0
		self.calcrange = 1
		self.calcrangey = 2
	elseif diceroll <= (percdashattack + percfspecial + percbaitsmash + percgrab + percjumpin + percrawfsmash + percdashingusmash + percblockapproach + percfollowdescent + perctaunt + percnspecial + percbair + percsleep) then
		self.chosenattack = "sleep"  --6-30-18 LOL. GOOD USE OF AN ATTACK SLOT --MOSTLY FOR LOW LEVEL SPIDERS IN HORDE MODE TO PREVENT SPIDERS FROM OVERRUNING PLAYERS IN LARGE NUMBERS 
		
	else
		-- self.inst.components.talker:Say("RE-ROLL!")
		self:DebugPrint("RE-ROLLING")
		self:ChooseAttack()
	end
	
	
	
	
	if self:SkillCheck() <= 3 then
		self:DebugPrint("BABY RESULTS ARE IN: CHOSENATTACK =", self.chosenattack)
		return end
	
	
	
	
	--SEPERATE FUNCTION FOR DETERMINING HOW TO FOLLOW UP       --7-9-17 ADDING AN "AUTOFOLLOWUP" THING FOR THROW COMBOS
	if opponent:HasTag("juggled") or opponent.sg:HasStateTag("helpless") or self.inst:HasTag("autofollowup") then   --1-6-17   --sg:HasStateTag("tumbling")
		
		if self.inst:HasTag("autofollowup") or (self:DistFromEnemy("vertical") > 5 and math.random() < (0.3 + (self:JumpinConfPercent() / 2))) then
			-- if self:DistFromEnemy("vertical") > 5 and opponent.components.jumper.lastkbangle >= 75 and math.random() < (0.7) then --1-19-17 ADDED TEST FOR ANGLE
				--(0.55%   +0.25)
			self.chosenattack = "followup" 
			self.calcframes = 5
			self.calcxpos = 1.5
			self.calcypos = -0.5
			self.calcrange = 1.5
			self.calcrangey = 2.0 + self.acc_add
			self.endonswing = false --1-15-22
			
			self.inst:RemoveTag("autofollowup")
			-- self.inst.components.talker:Say("AUTOFOLLOWUP! ok now leave")
		
		elseif math.random() < (0.7 - (self:JumpinConfPercent() / 2) - (self.inst.components.aifeelings:ConfidencePercent() / 3)) then
			
			self.chosenattack = "followdescent"
			self.chosenside = "block" 
			
		else
			self.chosenattack = "followdescent"
			self.endonswing = false
			if self.inst.components.aifeelings:CalculateTrajectory(20, 6, 0.5, 8, 1) then
				self.chosenside = "fspec"
			end
		
		end
	end
	
	
	self:DebugPrint("THE RESULTS ARE IN: CHOSENATTACK = ", self.chosenattack)
end




--7-19
function ChaseAndFight:DistFromEnemy(dir)
	--JUST CALL THE REAL ONE
	return self.inst.components.aifeelings:DistFromEnemy(dir)
end



--7-20 CALCULATE ENEMY POSITION    --MAYBE SOME OTHER TIME...
function ChaseAndFight:CalculateTrajectory(frames, range, xoffset)
    local opponent = self.inst.components.stats.opponent
	if not opponent and opponent:IsValid() then
		return false end
	
	local myposx, myposy = self.inst.Transform:GetWorldPosition()
	local oppx, oppy = opponent.Transform:GetWorldPosition() --or GetPlayer().Transform:GetWorldPosition()
	local oppvelx, oppvely = opponent.Physics:GetVelocity()
	local myvelx, myvely = self.inst.Physics:GetVelocity()
	
	-- print("WHAT DO YOU MEAN NIL VALUE", frames, opponent, oppy)	
	
	-- print("CALCULATE X TRAJECTORY", distsq(myposx, 0, oppx, 0), (((oppvelx + myvelx) * 0.35 * frames) + 0))	
	-- print("CALCULATE Y TRAJECTORY", distsq(0, myposy, 0, oppy), (((oppvely + myvely) * 0.35 * frames) + 0))	
	
	
	-- if distsq(myposx, 0, oppx, 0) <= 3 then
	-- if distsq((myposx + (1 * self.inst.components.launchgravity:GetRotationValue())), 0, oppx, 0) <= oppvelx then
	-- if distsq(myposx, 0, oppx, 0) <= ((oppvelx + myvelx) * 0.35 * frames) and distsq(0, myposy, 0, oppy) <= ((oppvely + myvely) * 0.35 * frames) then
	-- if distsq(myposx, 0, oppx, 0) <= (((oppvelx + myvelx) * 0.35 * frames) + range) and distsq(0, myposy, 0, oppy) <= (((oppvely + myvely) * 0.35 * frames) + 0) then
		-- self.inst:AddTag("wantstojab")
		
		
	local xdetection = ((oppvelx + myvelx) * 0.35 * -frames) --* self.inst.components.launchgravity:GetRotationValue()))
	-- local xdetection = ((myvelx + oppvelx) * 0.35 * -frames)
	-- local xdetection = ((myvelx + oppvelx) * 0.35 * -frames) --#4
	-- local xdetection = (distsq(oppvelx, 0, myvelx, 0) * 0.35 * frames)  --#3   
	-- local xdetection = (self.inst:distnorm(oppvelx, 0, myvelx, 0) * 0.35 * frames)
	local ydetection = ((oppvely + myvely) * 0.35 * frames)
	
	
	-- local xdistance = (distsq(myposx, 0, oppx, 0))
	-- local xdistance = (self.inst:distnorm(myposx, 0, oppx, 0))
	-- local xdistance = -(myposx - oppx)  --HUH... I GUESS IT WORKS. 7-23   #3
	-- local xdistance = (myposx - oppx) --#4
	
	local xdistance = -((myposx + (xoffset* self.inst.components.launchgravity:GetRotationValue())) - oppx)
	
	
	-- print("CALCULATE X RANGE", xdetection, xdistance) --(xdetection + range), (xdetection - range)) --distsq(myposx, 0, oppx, 0), (((oppvelx + myvelx) * 0.35 * frames) + range))	
	-- print("CALCULATE Y RANGE", (ydetection + range), (ydetection - range))
	
	------------------- FOR VISUAL REPRESENTATION ONLY. DISABLE WHEN NOT IN USE
				-- self.inst.components.hitbox:SetDamage(17)
				-- self.inst.components.hitbox:SetAngle(361)
				-- self.inst.components.hitbox:SetBaseKnockback(24)
				-- self.inst.components.hitbox:SetGrowth(95)
				-- self.inst.components.hitbox:SetSize(0.35)
				-- self.inst.components.hitbox:SetLingerFrames(0) --2
				-- self.inst.components.hitbox:SpawnHitbox(((xdetection + range)/4), 3, 0)
				-- self.inst.components.hitbox:SpawnHitbox(((xdetection - range)/4), 3, 0)
				
				-- -- self.inst.components.hitbox:SpawnHitbox((distsq(myposx, 0, oppx, 0) / 4), 4, 0)
				-- self.inst.components.hitbox:SpawnHitbox((xdistance / 4), 4, 0)
	
	
	if (xdistance <= (xdetection + range) and xdistance >= (xdetection - range)) then --and (distsq(0, myposy, 0, oppy) <= (ydetection + range) and distsq(0, myposy, 0, oppy) >= (ydetection - range)) then
	-- if (distsq(myposx, 0, oppx, 0) - range <= (xdetection + 0) and distsq(myposx, 0, oppx, 0) + range >= (xdetection - 0)) then --and (distsq(0, myposy, 0, oppy) <= (ydetection + range) and distsq(0, myposy, 0, oppy) >= (ydetection - range)) then
	
		return true --"grab_range"
	else
		return false
	end
	
	
end



--8-19 
function ChaseAndFight:DriftTowardOpp(xoffset, backwards)

	local myposx, myposy = self.inst.Transform:GetWorldPosition()
	local oppx, oppy = self.inst.components.stats.opponent.Transform:GetWorldPosition()
	local xdrift = 0
	
	if xoffset then
		xdrift = xoffset
	end
	
	self.inst:RemoveTag("holdleft")
	self.inst:RemoveTag("holdright")
	
	if (myposx + (xdrift*self.inst.components.launchgravity:GetRotationValue())) >= (oppx) then
		self.inst:AddTag("holdright")
	else
		self.inst:AddTag("holdleft")
	end
	
	--1-4-17 TO DRIFT AWAY FROM OPPONENTS INSTEAD
	if backwards and backwards == "away" then
		self.inst:RemoveTag("holdleft")
		self.inst:RemoveTag("holdright")
		-- print("'ERE WE GO", (myposx - (xdrift*self.inst.components.launchgravity:GetRotationValue())))
		if (myposx + (xdrift*self.inst.components.launchgravity:GetRotationValue())) >= oppx then
			self.inst:AddTag("holdleft")
			-- print("'ERE WE GO- LEFT")
		else
			self.inst:AddTag("holdright")
			-- print("'ERE WE GO- RIGHT")
		end
	end
	
	--IF APPROACHING DESTINATION, JUST CHILL --1-5-17
	if math.abs(math.abs(myposx + (xdrift*self.inst.components.launchgravity:GetRotationValue())) - math.abs(oppx)) <= 1 and self.inst.components.aifeelings:IsOpponentApproaching() then --THIS IS KINDA SILLY
		self.inst:RemoveTag("holdleft")
		self.inst:RemoveTag("holdright")
	end
	-- print("DRIFTING TOWARDS OPPONENT", self.inst:HasTag("holdleft"), self.inst:HasTag("holdright"), backwards)
end



--THIS IS CALLED WHEN HE GETS HIT BY AN ATTACK 1-15-22
function ChaseAndFight:OnAttacked()
    self.inst:RemoveTag("going_in")
	
	if not self.inst.components.launchgravity:GetIsAirborn() then
		self.inst.components.aifeelings.blockapproachmod = self.inst.components.aifeelings.blockapproachmod + 10
	end
	
	if self.status == RUNNING then
		self.status = SUCCESS
	end
end



function ChaseAndFight:OnReadyForAction()
    self.inst:RemoveTag("notreadyforaction")
	
	--1-3-17
	--[[
	if not (self.inst.sg:HasStateTag("jumping") or self.inst.components.launchgravity:GetIsAirborn()) then 
		if (self.swung == true and self.hit == false) then    --and self.swung == false then   <THE RIG
			-- print("RESETTING BRAIN!!!!")
			self.inst:RemoveTag("going_in")
			self.status = SUCCESS
			self.inst.brain:ForceRefresh() --1-18-17
			self:DebugPrint("I THINK I MISSED. LET'S PICK ANOTHER ATTACK ")
			self:ChooseAttack() --1-19-17 WELL WAIT! WE STILL NEED TO CHOOSE A NEW ATTACK TOO, OR ELSE HE'LL JUST CIRCLE AROUND WITH THE SAME ATTACK
			
		else --if not self.inst.components.launchgravity:GetIsAirborn() then
			-- print("I'M READY TO PICK AN ATTACK!")
			self:DebugPrint("HERE I AM! I'M READY TO PICK AN ATTACK ")
			if self.inst.sg:HasStateTag("idle") and self.idlelock == false then
				self:ChooseAttack() --LETS TRY PUTTING THIS IN HERE INSTEAD
				self.idlelock = true
			else
				-- print("IVE ALREADY ROLLED ONCE!")
				self:DebugPrint("I'VE ALREADY PICKED MY ATTACK! idlelock?", self.idlelock)
			end
		end
		self.swung = false
		self.hit = false --1-15-22 WHY DO WE CARE ABOUT THIS??? IDEK
	end
	]]
	
	if (self.swung == false) then    --and self.swung == false then   <THE RIG
		self:DebugPrint("I'VE ALREADY PICKED MY ATTACK! idlelock?", self.idlelock)
	else --if not self.inst.components.launchgravity:GetIsAirborn() then
		-- print("I'M READY TO PICK AN ATTACK!")
		if not self.inst.components.launchgravity:GetIsAirborn() then
			self:DebugPrint("HERE I AM! I'M READY TO PICK AN ATTACK ")
			self:ChooseAttack()
		else
			self:DebugPrint("IM IN THE AIR! NOT A GOOD TIME TO CHOOSE AN ATTACK ")
		end
	end
	
end


function ChaseAndFight:Visit()
    -- print("VISITING CHASEANDFIGHT", self.status)
    if self.status == READY then
		-- print("VISITING CHASEANDFIGHT")
		--[[
		if not (self.inst.sg:HasStateTag("blocking") or self.inst.sg:HasStateTag("grounded")) then --or self.inst.sg:HasStateTag("tumbling")) then
			self.status = RUNNING --ALWAYS REDY    --1-2-17 RPLACING TRYINGTOBLOCK WITH BLOCKING SO THAT CHASEANDFIGHT CAN KICK IN BY THE TIME SHIELD HAS DROPPED
			self:DebugPrint("VISITING CHASE AND FIGHT ")
			
		else --1-15-22 WELL DON'T JUST STAND THERE!!
			self:DebugPrint("WE VISITED CHASEANDFIGHT BUT WE WEREN'T QUITE READY YET... ")
			self.status = READY
		end
		]]
		self:DebugPrint("VISITING CHASE AND FIGHT")
		self.status = RUNNING --1-15-22
		
		--1-15-22 OK I SEE, THIS PART ALSO GETS RUN ON EVERY FRAME THAT WE AREN'T "BUSY"
		self:OnReadyForAction()
		--1-15-22 THIS USED TO ALWAYS ALSO RUN WHEN NOT BUSY, AS SET ON LINE 68
        
    end

	
    if self.status == RUNNING then
        -- self:DebugPrint("CHASE AND FIGHT: ", self.chosenattack)
		
		
		--1-15-22
		-- self.inst.components.aifeelings:GetAttackNode().status == RUNNING
		if self.inst:HasTag("wantstoblock") then
			self:DebugPrint("OK, WE ACTUALLY DO WANT TO BLOCK THOUGH: ")
			self.swung = true
			self.inst:RemoveTag("going_in")
			self.status = SUCCESS
			return end
		
		--1-15-22 LETS JUST TRY SOMETHING...
		if self.inst.sg:HasStateTag("tryingtoblock") then
			self:DebugPrint("WE'RE STILL HOLDING SHIELD! JUST GIVE US A SEC...: ", self.chosenattack)
			return end
		
		--IT'S TRUE WE SHOULDN'T BE RUNNING THIS WHILE ACTIVELY TRYING TO BLOCK. BUT OF COURSE IT'S GOING TO COME UP AS WE'RE DROPPING SHIELD
		if self.inst.sg:HasStateTag("grounded") or self.inst.sg:HasStateTag("hanging") then 
			self.inst:RemoveTag("going_in")
			self.status = SUCCESS
			self:DebugPrint("!!!ON THE GROUND!!!!")
			return end
	   
        if not (self.inst.components.stats.opponent and self.inst.components.stats.opponent:IsValid()) then 
            self.status = FAILED
			self:DebugPrint("!!!INVALID OPPONENT!!!!")
			return end
			
		-- else  --7-21 CHANGING TO PREVENT CRASHING RELATED TO TARGET
			
		--3-8 CUSTOM TESTERS
		local enpos = self.inst.components.stats.opponent.Transform:GetWorldPosition() --9-2 TO HOPEFULLY STOP CHASEANDFIGHT WHILE OVER EDGE
		local mypos, myposy = self.inst.Transform:GetWorldPosition()
		local myvelx, myvely = self.inst.Physics:GetVelocity()
		
		if enpos <= (self.anchor.components.gamerules.lledgepos - 3) or enpos >= (self.anchor.components.gamerules.rledgepos + 3) then
			self:DebugPrint("MY OPPONENT IS OFFSTAGE?")
			--1-17-17 ANOTHER TRY
			if self.inst.components.aifeelings:IsSafeToEdgeChase() then
				self:DriftTowardOpp()
				if self.inst.components.aifeelings:CalculateTrajectory(4, 0, -0.5, 2, 1) and self.inst.components.launchgravity:GetIsAirborn() then --(frames, xpos, ypos, range)
					-- self.inst.components.talker:Say("HERE COMES DAS BOOT!")
					self:DebugPrint("OFFSTAGE DUNK")
					self.inst:PushEvent("throwattack", {key = "down"})
				end
			else
				self:DebugPrint("NEVERMIND, IT'S NOT SAFE TO LEDGE CHASE")
				self.inst:RemoveTag("going_in") 
				self.status = FAILED
				-- print("THE END HAS RETURNED -------------")
				-- return end
			end
			
			if self.inst.components.aifeelings:CalculateTrajectory(15, 4, 8, 1, 5, "still") and not self.inst.sg:HasStateTag("savejump") then
				self:DebugPrint("IM GOING FOR THE DUNK! HERE'S THE JUMP!")
				self.inst:AddTag("going_in")
				self.inst:PushEvent("jump")
				-- self.inst.components.talker:Say("CHEEKY EDJ SECOND JUMP")
			end
			
			if self.chosenattack == "dair" then
				return end
			
		end
			
			
		local opponent = self.inst.components.stats.opponent
	
	
		self.inst:AddTag("going_in") --TO TELL BRAIN NOT TO BLOCK UNTIL FINISHED
		
		
		--1-26-17 MOVE ACTIVATES THE SECOND THIS NODE RUNS
		if self.autoswing ~= "none" then
			self.inst:PushEvent("throwattack", {key = self.autoswing})
			self.autoswing = "none"
			self:DebugPrint("THROWATTACK!: AUTOSWING", self.autoswing)
			-- print("THIS THING AINT ON AUTO PILOT")
			return end
				
				
		
		if self.chosenattack == "taunt" then --LOL
			self.inst:PushEvent("taunt")
			-- self.chosenattack = "dashattack" --1-15-22 IDK WHY WE SET THESE TO SOMETHING ELSE
			-- self:ChooseAttack()
			-- self.status = SUCCESS
			self:DebugPrint("THROWATTACK!: TAUNTING")
			return end
		-- end
		
		if self.chosenattack == "sleep" then --LOL
			self.inst:PushEvent("sleep")
			-- self.chosenattack = "dashattack"
			-- self:ChooseAttack()
			-- self.status = SUCCESS
			return end
		
		
		if self.chosenattack == "nspecial" then
			-- self.inst:PushEvent("taunt")
			self.inst.components.locomotor:FaceTargetIfPossible(self.inst.components.stats.opponent)
			self.inst:PushEvent("throwspecial", {key = "nspecial"})
			self:DebugPrint("THROWATTACK!: NSPECIAL")
			-- self.chosenattack = "dashattack"
			-- self:ChooseAttack()
			-- self.status = SUCCESS
			return end
		
			
				------------1-7-17 NEW CLOSE-QUARTERS COMBAT CALCULATOR -------------
		if self.chosenattack == "closecombat" then
			self:DebugPrint("THROWATTACK!: CLOSE COMBAT!")
			if self:DistFromEnemy() >= 2.2 then
				self.chosenattack = "dashattack" --OHHH, IT HAS TO BE RE-NAMED BEFORE ROLLING OR ELSE IT WON'T RE-CHOOSE
				self:ChooseAttack() --TOO FAR AWAY, ROLL AGAIN
			end
					
			--THIS BIT WAS JUST TAKEN FROM THE POST-ROLL IN DEFEND NODE
			local punishchance = 0.0
			
			if self.inst.components.aifeelings.punishblockedmove == true then
				punishchance = punishchance + 0.4
			end
			
			if self:IsTargetFacingTarget(self.inst, opponent) then
				punishchance = punishchance + 0.2
			end
			
			if self:IsTargetFacingTarget(opponent, self.inst) then
				punishchance = punishchance - 0.2
			end
			
			
			--7-9-17 IF TARGET IS AT KILL PERCENT, JUST START THROWING OUT SMASH ATTACKS
			if math.random() < (0.05 + (self:AtKillPercent() / 4)) then
				self.inst:PushEvent("throwattack", {key = "fsmash"})
				self:DebugPrint("THROWATTACK!: YOLO POINT BLANK SMASH ATTACK")
			end
			
			
			-- !!!!!!!!00000  HAVE HIM TEST IF HE WAS HIT BY A LAGGY AERIAL AND THEN UPSMASH OUT OF SHIELD 00000!!!!!!! --
			
			if opponent.sg:HasStateTag("hanging") then
				self.inst:PushEvent("throwattack", {key = "down"})
				return end
			-- end
			
							
			if self:DistFromEnemy() <= 1.7 and math.random() < (0.8) then --TEMPORARY SUPER POINT BLANK
				
				local diroperator = 0 --USED TO REMOVE OPTIONS IF FACING THE WRONG WAY
				
				
				if not self.inst.components.aifeelings:IsTargetFacingTarget(self.inst, opponent) == true then
					
					if math.random() < (0.5 + (self:AtLowPercent() / 2)) and self:DistFromEnemy() <= 1 then
						self.inst:PushEvent("throwattack", {key = "up"})
					else
					
						self.inst.components.stats.jumpspec = "short"
						self.inst:PushEvent("singlejump")
						self.inst:PushEvent("throwattack", {key = "backward"})
						-- self.inst.components.talker:Say("CLOSE COMBAT!")
						-- self.inst:DoTaskInTime(0.1, function(inst) self.inst:PushEvent("throwattack", {key = "backward"}) end )
					end
					diroperator = 0.6
				end
				
				
				if math.random() < (0.6 - diroperator) then
					--EITHER JAB OR FTILT
					if math.random() < (0.66) then 
						self.inst:PushEvent("throwattack")
					else
						self.inst:PushEvent("throwattack", {key = "down"})
					end
				elseif math.random() < (0.75 - diroperator) and self:IsTargetFacingTarget(self.inst, self.inst.components.stats.opponent) then
					self.inst:PushEvent("throwattack", {key = "block"})
				else
					self.inst.components.stats.jumpspec = "short"
					self.inst:PushEvent("singlejump")
					self.inst:DoTaskInTime(0.1, function(inst) self.inst:PushEvent("throwattack") end )
				end
			else
			
				if self:IsTargetFacingTarget(self.inst, self.inst.components.stats.opponent) then
					self.inst:PushEvent("throwattack", {key = "down"})
				else
					self.inst:PushEvent("throwattack", {key = "backward"})
				end
			end
		end
		
		
			
			
			
		if self.inst.components.launchgravity and self.inst.components.launchgravity:GetIsAirborn() then
			-- self:DebugPrint("I'M IN THE AIR")
			self.inst:RemoveTag("holdleft") --1-30-17 TO STOP ANY PREVIOUS MOVEMENT ATTEMPTS
			self.inst:RemoveTag("holdright")
			
			if self.chosenattack == "jumpin" or self.chosenattack == "followup" then
				--7-9-17 OKAY, HAROLD IS NOT VERY GOOD AT LANDING AREALS ON GROUNDED OPPONENTS FROM HIGH UP. LETS FIX THAT. --OH OK. I SEE HOW IT IS. SO THIS JUST ISNT USED AT ALL, IS IT??
				local yadjust = 0 --A VARIABLE TO TUNE HIS VERTICAL TARGETING BASED ON FALLING SPEED
				-- if not opponent.components.launchgravity:GetIsAirborn() then
					-- if self.inst.components.launchgravity:GetVertSpeed() <= -1 then
						-- -- yadjust = -100 -- c:
						-- self.inst.components.talker:Say("A LITTLE LOWER NOW...")
					-- elseif self.inst.components.launchgravity:GetVertSpeed() >= 1 then
						-- -- yadjust = 100 -- c:
						-- self.inst.components.talker:Say("A LITTLE HIGHER NOW...")
					-- end
				-- end
				--7-9-17 000000000  YOU KNOW WHAT, NEVERMIND, HE'S GOOD ENOUGH NOW. I'LL LEAVE THE VARIABLES IN IN CASE I CHANGE MY MIND THOUGH 0000000
				
				
				if self:SkillCheck() <= 3 then --2-27-17 LOW LEVEL CAN ONLY FORWARD AIR  --7-1-18 -AT LEAST FIX THESE
					-- if self.inst.components.aifeelings:CalculateTrajectory(self.calcframes, self.calcxpos, self.calcypos+yadjust, self.calcrange, self.calcrangey) then
					if self.inst.components.aifeelings:CalculateTrajectory(5, 1+(self.acc_add/2), 0, 2, 1+(self.acc_add/2)) then
						self.inst:PushEvent("throwattack", {key = "forward"})
						-- self.swung = true --7-1-18 --FOR THE LOVE OF GOD, STOP SPAMMING THESE
						-- self.inst.components.talker:Say("IM GONNA JUMP")
					
					--EH, SURE. AND UP-AIRS TOO.
					elseif self.inst.components.aifeelings:CalculateTrajectory(4, 0, 1.5+(self.acc_add/2)+yadjust, 0.5+self.acc_add, 0.5+self.acc_add) then  --1-14-17 CLEANED ALL THESE UP SO THEY WORK MUCH BETTER
						self.inst:PushEvent("throwattack", {key = "up"})
						-- self.swung = true
					end
					
				else
				
					-- if self.inst.components.aifeelings:CalculateTrajectory(5, 1, 0, 2, 3) then	
					-- if self.inst.components.aifeelings:CalculateTrajectory(5, 1+(self.acc_add/2), 0+yadjust, 2, 3+(self.acc_add/2)) then	--3-7-17 ADDING ACCURACY MODIFIERS FOR LOWER LEVELS
					if self.inst.components.aifeelings:CalculateTrajectory(5, 1+(self.acc_add/2), 1+yadjust, 2, 1+(self.acc_add/2)) then	 --7-9-17OH?? IS IT ALL STATIC??
						self.inst:PushEvent("throwattack", {key = "forward"})
						-- self.swung = true
						self:DebugPrint("FORWARD AIR")
					
					elseif self.inst.components.aifeelings:CalculateTrajectory(4, 0, 1.5+(self.acc_add/2)+yadjust, 0.5+self.acc_add, 0.5+self.acc_add) then  --1-14-17 CLEANED ALL THESE UP SO THEY WORK MUCH BETTER
						self.inst:PushEvent("throwattack", {key = "up"})
						-- self.swung = true
						self:DebugPrint("UP AIR")
						
					elseif self.inst.components.aifeelings:CalculateTrajectory(2, -1.5, 0.5+yadjust, 1+self.acc_add) then
						self.inst:PushEvent("throwattack", {key = "backward"})
						-- self.swung = true
						self:DebugPrint("BACK AIR")
					
					elseif self.inst.components.aifeelings:CalculateTrajectory(2, 0, 0.5+yadjust, 1.5+self.acc_add) then --or self:DistFromEnemy() <= 10 then  --(frames, xoffset, yoffset, range)
						self.inst:PushEvent("throwattack")
						-- self.swung = true
						self:DebugPrint("NAIR")
					end
				end
			
			
			elseif self.chosenattack == "bair" then --1-3-17
				if self.inst.components.aifeelings:CalculateTrajectory(self.calcframes, self.calcxpos, self.calcypos, self.calcrange, self.calcrangey) then
					self.inst:PushEvent("throwattack", {key = "backward"})
				end
			end
			
		end --1-26-17 vvv AND AT LAST, GETTING RID OF THIS TAIL THAT ONLY DASHES, ENDING CONFLICT BETWEEN DASHING DURING ATTACKS
		
			
		--1-14-17 LETS JUST MAKE FOLLOWUP IT'S OWN ATTACK CHOICE AND LEAVE JUMPIN ALONE
		if self.chosenattack == "followup" then
			
			if not self.inst.components.launchgravity:GetIsAirborn() then
				self:ChaseTarget()
			end
			
			--1-14-17 THE NEW WEIRD ATTAMPTS FOR FOLLOWUP IMPROVEMENTS
			if (self.inst.components.aifeelings:CalculateTrajectory(15, 4, 8, 1, 5) or self.inst.components.aifeelings:CalculateTrajectory(10, 0, 8, 4, 5)) and not self.inst.components.launchgravity:GetIsAirborn() then
				self.inst.components.stats.jumpspec = "full"
				self.inst:PushEvent("singlejump")
			elseif self.inst.components.aifeelings:CalculateTrajectory(15, 0, 8, 2, 5) and not self.inst.components.launchgravity:GetIsAirborn() then
				self.inst.components.stats.jumpspec = "full"
				self.inst:PushEvent("singlejump")
			elseif self.inst.components.aifeelings:CalculateTrajectory(15, 0, 6, 1, 1) and not self.inst.sg:HasStateTag("savejump") then
				self.inst:PushEvent("jump")
				self.inst:PushEvent("throwattack", {key = "up"}) --GOOD, GOOD B) 
				self:DebugPrint("JUGGLING UAIR!")
			-- end
			
			elseif self.inst.components.aifeelings:CalculateTrajectory(10, 6, -1, 2, 2) and not self.inst.components.launchgravity:GetIsAirborn() then
				self.chosenattack = "dashingusmash" 
				self.calcframes = 6
				self.calcxpos = 0.5 + math.random(-0.2,0.2)
				-- self.calcxpos = 0 + math.random(-0.3,0.3)
				self.calcypos = 0
				self.calcrange = 1.0+self.acc_add
				-- self.inst.components.talker:Say("SWITCHING GEARS")
			elseif not opponent.components.launchgravity:GetIsAirborn() then
				self:ChooseAttack() --OPPONENT HIT THE GROUND, CANCEL IT
			end
			-- print("is this thing on??")
			self:DriftTowardOpp()
		end
		
		
		if self.chosenattack == "jumpin" then
			
			--1-14-17 THE NEW WEIRD ATTAMPTS FOR FOLLOWUP IMPROVEMENTS --AH YES!! THIS IS SUCH A BIG IMPROVEMENT
			if not self.inst.components.launchgravity:GetIsAirborn() then
			
				self:ChaseTarget()
				-- self.inst.components.talker:Say("LIKE A MAJESTIC EAGLE")
			
				if not opponent.components.launchgravity:GetIsAirborn() then
					if self.inst.components.aifeelings:CalculateTrajectory(4, 2, 0, 3, 1, 4) and self:IsTargetFacingTarget(self.inst, self.inst.components.stats.opponent) then --LETS JUST MAKE IT AUTO-SHORTHOP IF TOO CLOSE  --and self.inst.components.stats.jumpspec == "short" then
						self.inst.components.stats.jumpspec = "short" --(4, 3.5, 0, 1)
						self.inst:PushEvent("singlejump")
					elseif self.inst.components.aifeelings:CalculateTrajectory(15, 5.5, 0, 1.5, 7) and self.inst.components.stats.jumpspec ~= "short" then --3-4-17 IM GOING TO McLOSE IT OVER THIS NOT== THING
						self.inst.components.stats.jumpspec = "full" --(8, 5.5, 0, 1.5) --(5, 5, 0, 6, 1.5)
						self.inst:PushEvent("singlejump")
					elseif self:DistFromEnemy("horizontal") < 2 then
						self:ChooseAttack() --TOO CLOSE, MUST HAVE MESSED UP
					end
				
				elseif self.inst.components.aifeelings:CalculateTrajectory(15, 4, 8, 1, 5) then
					self.inst.components.stats.jumpspec = "full"
					self.inst:PushEvent("singlejump")
				elseif self.inst.components.aifeelings:CalculateTrajectory(15, 0, 8, 2, 5) then
					self.inst.components.stats.jumpspec = "full"
					self.inst:PushEvent("singlejump")
				
				end
				
			elseif self.inst.components.launchgravity:GetIsAirborn() then
				if self.inst.components.aifeelings:CalculateTrajectory(15, 0, 6, 1, 1+self.acc_add) and not self.inst.sg:HasStateTag("savejump") and self:SkillCheck() >= 4 then
					self.inst:PushEvent("jump")
					self.inst:PushEvent("throwattack", {key = "up"}) --GOOD, GOOD B) 
					self:DebugPrint("ANOTHER UAIR?")
				end
				self:DriftTowardOpp()
				
				
				--1-17-22 IF WE'RE TRYING TO APPROACH HIGH, JUMP AGAIN BEFORE WE HIT THE GROUND.
				if self.chosenside == "highapproach" then
					self:DebugPrint("--I'M APPROACHING HIGH WITH THE INTENT OF LANDING ON MY ENEMY!")
					if myvely < 3 and self:DistFromEnemy("vertical") < 10 and self:DistFromEnemy("horizontal") > 15 then
						if self.inst.components.jumper.currentdoublejumps > 0 then
							self:DebugPrint("I HAVE TO JUMP TO CONTINUE APPROACHING HIGH!")
							self.inst:PushEvent("jump")
						elseif self:SkillCheck() >= 5 then
							self:DebugPrint("I HAVE TO LUNGE TO CONTINUE APPROACHING HIGH!")
							self.inst:PushEvent("throwspecial", {key = "forward"})
						end
					end
				end
			end
			
			
		--1-3-17 LETS GIVE THIS BOI A BACK-AIR
		elseif self.chosenattack == "bair" then
		
		--4-18-17 DONT FORGET TO HAVE HIM ACTUALLY CHASE HIM WHEN THE MOVE IS SELECTED
			if not self.inst.components.launchgravity:GetIsAirborn() then
				self:ChaseTarget()
			end
		
			if self.inst.components.stats.jumpspec == "short" then
			
				if self:DistFromEnemy("horizontal") <= 10 then
					-- self.inst.components.locomotor:FaceTargetIfPossible(self.inst.components.stats.opponent)
					-- self.inst.components.locomotor:TurnAround()
					if not self.inst.components.launchgravity:GetIsAirborn() and (self.inst.sg:HasStateTag("can_ood")) then  ---and not self.inst.sg:HasStateTag("no_running") then
						self.inst.components.locomotor:FaceTargetIfPossible(self.inst.components.stats.opponent)
						self.inst.sg:GoToState("pivot_dash")
						self.inst.components.stats.jumpspec = "short"
						self.inst:PushEvent("singlejump")
					end
					
					
				end
			elseif self:DistFromEnemy("horizontal") > 10 and not self.inst.components.launchgravity:GetIsAirborn() then --45
				if self:DistFromEnemy("horizontal") <= 65 then
					if not self.inst.components.launchgravity:GetIsAirborn() and (self.inst.sg:HasStateTag("can_ood")) then
						self.inst.components.locomotor:FaceTargetIfPossible(self.inst.components.stats.opponent)
						self.inst.sg:GoToState("pivot_dash")
						self.inst:PushEvent("singlejump")
					end
					
				end
			elseif not self.inst.components.launchgravity:GetIsAirborn() then
				self:DebugPrint("JUMPIN FAILED, RE-ROLLING")
				self:ChooseAttack() --PREVENTS HIM FROM AWKWARDLY RUNNING PAST YOU TO GET TO A BETTER JUMP POSITION TO JUMP AT YOU FROM
			end
			
			if self.swung == false then
				self:DriftTowardOpp(-1.8) --AIM FOR SLIGHTLY IN FRONT OF HIM
			else
				self:DriftTowardOpp(0, "away") --1-4-17 MAKE HIM DRIFT BACK LIKE I DO 
			end
			
			
			
		--7-25 BAITSMASH
		elseif self.chosenattack == "baitsmash" then
			-- print("TAKE THE BAIT", self.inst.components.aifeelings.tempfear)
			if self.inst.sg:HasStateTag("scary") then
				local oppvelx, oppvely = opponent.Physics:GetVelocity()
				if self.inst.components.aifeelings:IsOpponentApproaching() and not (oppvelx >= -0.2 and oppvelx <= 0.2)  then --3-4-17 NAND ALSO NOT STANDING STILL
					self.inst.components.aifeelings.tempfear = self.inst.components.aifeelings.tempfear - 0.1
				else
					self.inst.components.aifeelings.tempfear = self.inst.components.aifeelings.tempfear + 0.15
				end
				
				if not self.inst.components.aifeelings:IsOpponentApproaching() and math.random() < (0.1 + (self.inst.components.aifeelings:ConfidencePercent() / 100) + (self.inst.components.aifeelings.tempfear / 10)) then
					self.inst:RemoveTag("chargesmash") --IS THIS EVEN USED??
					self.inst:PushEvent("throwsmash")
					-- self.inst.components.talker:Say("THEYRE NOT FALLING FOR IT")
					self.chosenattack = "none"
				end
				
				if self.inst.components.aifeelings:CalculateTrajectory(self.calcframes, self.calcxpos, self.calcypos, self.calcrange, self.calcrangey) then
				--or self:DistFromEnemy() <= 10
					-- self.inst.components.talker:Say("YOU FELL FOR IT!!!")
					self.inst:RemoveTag("chargesmash")
					self.inst:PushEvent("throwsmash")
					self.chosenattack = "none"
				end
			else
				self.inst:PushEvent("throwattack", {key = "fsmash"}) --8-29 ALRIGHT, THIS SEEMS TO HAVE FIXED IT
				self.inst:AddTag("chargesmash")
			end
			
			if self.inst.sg.currentstate.name == "fsmash" then
				self.chosenattack = "none"
			end
			
			
		elseif self.chosenattack ~= "followdescent" and self.inst.sg:HasStateTag("dashing") and self.inst.components.aifeelings:CalculateTrajectory(self.calcframes, self.calcxpos, 0, self.calcrange, self.calcrangey) then
		
			self:DebugPrint("==APPROACHING FOR ATTACK==", self.chosenattack)
			-- if math.random() < --[[ Chance to proc ]] (0.5) then
			if self.chosenattack == "dashattack" then
				self.inst:PushEvent("throwattack")
				-- self.inst.sg:GoToState("jab1")
				--11-28-20 MAYBE WE SHOULD REFRESH THESE
				self:DebugPrint("--DASHATTACK")
				-- self.swung = true
				-- self.status = SUCCESS
			elseif self.chosenattack == "fspecial" then
				-- self.inst:PushEvent("throwattack", {key = "fspecial"})
				self.inst:PushEvent("throwspecial", {key = "forward"})
				self:DebugPrint("--FSPECIAL")
				-- self.swung = true
				-- self.status = SUCCESS
			elseif self.chosenattack == "dashingusmash" then
				-- self.inst:PushEvent("throwattack", {key = "usmash"})
				self.inst:PushEvent("cstick_up")
				-- self.swung = true
				self:DebugPrint("--DASHING USMASH!")
			elseif self.chosenattack == "blockapproach" then
				self.inst:RemoveTag("going_in")
				self.inst:AddTag("braceyourself")
				self.inst:AddTag("wantstoblock")
				self.inst:DoTaskInTime(1.0, function(inst) self.inst:RemoveTag("braceyourself") end ) --0.5
				self.inst:PushEvent("block_key")
				self.swung = true --THIS ONE WE CAN KEEP BECAUSE OUR SHILED WONT COUNT AS SWUNG
				self:DebugPrint("--SHIELD BASH")
				-- self.inst.components.talker:Say("SHIELD BASH!")
				self.status = SUCCESS
			elseif self.chosenattack == "grab" then
				-- self.inst.components.talker:Say("YOINK!")
				self.inst:PushEvent("throwattack", {key = "block"})
				self:DebugPrint("--GRAB")
				-- self.swung = true
				-- self.status = SUCCESS
			else
				-- self.inst.components.talker:Say("NO ATTACK SELECTED")
				self:DebugPrint("NO ATTACK SELECTED!", self.chosenattack)
			end
			
			-- self:ChooseAttack()
			
		else
			-- print("WONT KNOW TILL WE GET THERE")
			
			--1-21-17 FOR BETTER JUGGLE-CHASING (NON-AIR)
			if self.chosenattack == "followdescent" then 
				
				self:DebugPrint("FOLLOWDESCENT WITH A SIDE OF", self.chosenside)
				
				if self.chosenside == "fspec" then --IF IN RANGE, JUST AUTO THROW FSPECIAL
					self.inst:PushEvent("throwspecial", {key = "forward"})
					self.chosenside = "none" --AND LIVE  --(lol he used to use this over edges didnt he)
					-- self.swung = true
				-- end
				
				elseif self.chosenside == "block" then --GIVE SELF PLENTY OF TIME TO BLOCK IN CASE OPPONENT FASTFALLS
					if opponent.components.launchgravity:GetVertSpeed() <= 3 and self:DistFromEnemy("horizontal") < 3 then
						--WHEN I LAST LEFT OFF, STOLE ALL THIS FROM EDGAURD
						self.inst:RemoveTag("going_in")
						self.inst:AddTag("braceyourself")
						self.inst:AddTag("blockoverride")
						self.inst:AddTag("wantstoblock")
						self.inst:DoTaskInTime(0.8, function(inst) 
							self.inst:RemoveTag("braceyourself") 
							self.inst:RemoveTag("wantstoblock")
							self.inst:RemoveTag("blockoverride")
						end )
						self.inst:PushEvent("block_key")
						self.status = SUCCESS
						self:DebugPrint("DIVE BOMBERS")
						-- self.chosenside = "none" 
					end
					if not opponent.components.launchgravity:GetIsAirborn() then
						self:ChooseAttack()
					end
				
				elseif self.inst.components.aifeelings:CalculateTrajectory(6, 0.3, 0.6, 1.5) and not self.inst.sg:HasStateTag("dashing") then
					self.inst:PushEvent("throwattack", {key = "up"})
					-- self.swung = true --1-15-22 REMOVING ALL THESE TO BE AUTOMATED AND ONLY RUN WHEN HE'S ACTUALLY SWUNG
				
				elseif self.inst.components.aifeelings:CalculateTrajectory(6, 1.2, 0.5, 2, 0.5) then
					self.inst:PushEvent("throwattack")
					-- self.swung = true
					
				elseif self.inst.components.aifeelings:CalculateTrajectory(4, -1.2, 0.5, 1.3) then
					self.inst:PushEvent("throwattack", {key = "backward"})
					-- self.swung = true

				elseif self.inst.components.aifeelings:CalculateTrajectory(6, 0.5, 0, 1.5) then
					self.inst:PushEvent("cstick_up")
					-- self.swung = true
				end
				
				if not opponent:HasTag("juggled") then
					self:ChooseAttack()
				end
			end
			
			
			-- print("HERE'S WHERE I'M CHASING FROM")
			self:ChaseTarget() --1-3-17 A NEW VERSION OF THE ABOVE
			
			
			--9-1 SO HE DOESN'T WIBBLE AROUND WHEN ENEMY IS HIGH UP ABOVE HIM
			if self:DistFromEnemy("vertical") > 10 and self:DistFromEnemy("horizontal") < 4 and not self.inst.components.launchgravity:GetIsAirborn() then --and not self.chosenattack == "jumpin" then
				-- self.inst.components.talker:Say("HOWS THE WEATHER UP THERE?")
				if self.chosenattack == "followdescent" then --"blockapproach" then
					self:DebugPrint("THIS GUY IS TAKING FOREVER TO COME DOWN. STOP FOR A SEC")
					-- self.status = SUCCESS --1-21-17 THERE! NOW HE WILL STILL FOLLOW YOU, BUT WONT WIBBLE SO FRANTICALLY WHEN UNDERNEATH
					self.inst:PushEvent("dash_stop") --1-16-22 OK BUT NOW YOU MIGHT MISS HIM ALTOGETHER
					if math.random() < (0.35) then  --7-9-17 OKAY, GIVE HIM A BIT OF A CHANCE TO JUST PICK A NEW ATTACK IF THEYRE LIKE WAAAAY UP THERE
						self:ChooseAttack()
						-- self.inst.components.talker:Say("OK, IM GETTING BORED")
					end
				-- else
				elseif self.chosenattack == "dashattack" or self.chosenattack == "fspecial" or self.chosenattack == "blockapproach" or self.chosenattack == "closecombat" then
					self:DebugPrint("ENEMY RIGHT ABOVE US, RE-ROLLING")
					self:ChooseAttack() --THIS WILL PICK A MORE APPROPRIATE ATTACK OPTION FROM HERE
				end
			end
			
		end
		
		
		if self.chosenattack == "dair" or self.chosenattack == "none" then
			self:ChooseAttack() --1-19-17 HOPEFULLY THIS SHOULD REMOVE THE PROBLEM
		end
	
	end
	
	
	--THESE SITUATIONS SHOULD BE HANDLED BY OTHER BEHAVIORS!
	--[[
	if (self.inst.sg:HasStateTag("tryingtoblock") or self.inst.sg:HasStateTag("grounded")) then --or self.inst.sg:HasStateTag("tumbling")) then
		self.inst:RemoveTag("going_in")
		self.status = SUCCESS
	end
	]]
		
    -- end
end
