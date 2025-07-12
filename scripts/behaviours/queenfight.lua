QueenFight = Class(BehaviourNode, function(self, inst, max_chase_time, give_up_dist, max_attacks, findnewtargetfn, walk)
    BehaviourNode._ctor(self, "QueenFight")
    self.inst = inst
    self.findnewtargetfn = findnewtargetfn
    self.max_chase_time = max_chase_time
    self.give_up_dist = give_up_dist
    self.max_attacks = max_attacks
    self.numattacks = 0
    self.walk = walk
	
	--DID I REALLY NEED ALL THIS CODE JUST TO THROW ON A SLUGGISH ATTACKER LIKE THE QUEEN??...
	
	
	-------7-23
	self.chosenattack = "dashattack"
	self.calcframes = 1
	self.calcxpos = 3
	self.calcypos = 0
	self.calcrange = 2
	self.calcrangey = 0 --VALUE OF ZERO USES REGULAR RANGE
	
	
	--8-23
	self.dashattackmod = 0
	self.fspecialmod = 0
	self.grabmod = 0
	self.baitsmashmod = 0
	
	self.swung = true
    
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
	
	self.onreadyforactionfn = function(inst, data) --8-6 SOMETHING STUPID SO THAT I CAN CALL FUNCTIONS ON RETURN TO IDLE STATE
        self:OnReadyForAction()
    end
	
	self.inst:ListenForEvent("attacked", self.onattackedfn)
	self.inst:ListenForEvent("hit_shield", self.onhitshieldfn) --8-27
	self.inst:ListenForEvent("readyforaction", self.onreadyforactionfn) --8-6 SOMETHING STUPID SO THAT I CAN CALL FUNCTIONS ON RETURN TO IDLE STATE
	
	self.anchor = TheSim:FindFirstEntityWithTag("anchor") --DST
end)

function QueenFight:__tostring()
    return string.format("target %s", tostring(self.inst.components.combat.target))
end


function QueenFight:OnStop()
    self.inst:RemoveEventCallback("onattackother", self.onattackfn)
    self.inst:RemoveEventCallback("onmissother", self.onattackfn)
	
	--DONT FORGET TO REMOVE THE EVENT LISTENERS SO THEY DONT HAPPEN EVEN WHEN BEHAVIOR ISNT ACTIVE. --VERY SMART KLEI~
	self.inst:RemoveEventCallback("attacked", self.onattackedfn)
    self.inst:RemoveEventCallback("hit_shield", self.onhitshieldfn)
	-- self.inst:RemoveEventCallback("readyforaction", self.onreadyforactionfn)
end

function QueenFight:OnAttackOther(target)
    -- -WE'VE NER USED THIS
end

function QueenFight:OnHitShield(target)
    self.inst.components.aifeelings.oppshieldtendancy = self.inst.components.aifeelings.oppshieldtendancy + 1
end


--8-14 --TO TEST IF ENTITY IS FACING A SELECTED TARGET
function QueenFight:IsTargetFacingTarget(target1, target2)

	local enpos = target2.Transform:GetWorldPosition() --self.inst.components.stats.opponent.Transform:GetWorldPosition()
	local mypos = target1.Transform:GetWorldPosition() --self.inst.Transform:GetWorldPosition()

    -- if mypos*self.inst.components.launchgravity:GetRotationValue() >= enpos*1 then
	if mypos*target1.components.launchgravity:GetRotationValue() >= enpos*target1.components.launchgravity:GetRotationValue() then
		return false
	else
		return true
	end
end



--7-25 -TO SEE IF HE SHOULD BAIT SMASH
function QueenFight:ShouldReactToAttacker(target)
	-- print("CONGRATULATIONS ON YOUR NEWBORN!", self:DistFromEnemy("horizontal"))

    if self:DistFromEnemy("horizontal") >= 0 and self:DistFromEnemy("horizontal") <= 65 then
	
		--if self:CalculateTrajectory(self.calcframes, self.calcrange, self.calcxpos) then
		
		-- print("ITS A MAILBOX!")
		
		self.chosenattack = "baitsmash"
		self.calcframes = 1
		self.calcrange = 1
		self.calcxpos = 1.6
		self.calcypos = 0
		
	return true
	end
	
	-- self.status = SUCCESS
end











--7-23
function QueenFight:ChooseAttack()
    -- print ("ROLLING THE DICE")
	-- self.inst.components.talker:Say("ROLLING THE DICE")
	
	-- if self:ShouldReactToAttacker() then
		-- return end
	
	self.calcrangey = 0 --8-25 TO REFRESH VALUES FOR LEGACY MOVES THAT DO NOT USE A Y RANGE
	self.inst.components.stats.jumpspec = "full"
	
	local opponent = self.inst.components.stats.opponent
	
	if not opponent:IsValid() then --9-6 SAME AS THE ABOVE REALLY
		self.status = SUCCESS
	return end
	
	
	
	
	--QUEEN!!!! THIS IS THE ONLY THING THAT ACTUALLY MATTERS HERE. 6-27-18
	
	--ANY CLASSIC BOSS HAS GOTTA HAVE STAGES! LETS GIVE THIS BIG GIRL BADDER ATTACKS THE LOWER HER HEALTH IS.
	local boss_health = (1 - self.inst.components.percent:GetHPPercent()) * 100 --HEALTH ON A SCALE OF 0 TO 100 (REGARDLESS OF HER ACTUAL HP AMOUNT)
	local boss_stage = 0 --AT FIRST...
	
	if boss_health <= 30 then
		boss_stage = 2	--TECHNICALLY STAGE 3
	elseif boss_health <= 75 then
		boss_stage = 1
	else
		boss_stage = 0
	end
	-- print("WHATS THE BOSS HEALTH?", boss_health, boss_stage)
	-- local boss_stage = 2 --JUST FOR TESTING
	
	--EH... ITS JUST THE QUEEN. JUST GO WITH WHAT WORKED. TOO LAZY TO IMPROVE THE OLD FORMULA
	local percstab = 35
	local perclongstab = 10+(10 * (boss_stage)) --VARIABLES MULTIPLIED BY HER BOSS_STAGE MEAN SHE'S MORE LIKELY TO USE THEM AT HIGHER STAGES
	local percdualstab = 10+(5 * (boss_stage)) --MEANING SHE WON'T USE THESE IN HER EARLIEST STAGES
	local perctriostab = 0+(25 * (boss_stage)) --7-1-20 LETS BRING THIS BACK!! FLURRY ATTACK
	local percjumpin = 15 
	
	
	--TO ADD A NEW ATTACK TO THE BANK, IT MUST BE INSERTED    -UP ABOVE    -DICE ROLL TOTAL BELOW   -.SELF LIST IN AIFEELINGS AS A MOD  -MOD IN STATEGRAPH TOO PROBABLY
	
	
	--CANCLERS THAT REMOVE CERTAIN MOVES FROM THE POOL IF NOT ELLIGABLE
	if self:DistFromEnemy("horizontal") >= 35 then --LONG RANGE
		percjumpin = percjumpin + 10 + (10 * boss_stage) --VARIABLES MULTIPLIED BY HER BOSS_STAGE MEAN SHE'S MORE LIKELY TO USE THEM AT HIGHER STAGES
		percdualstab = percdualstab/2
	end
	
	if self:DistFromEnemy("vertical") > 10 and self:DistFromEnemy("horizontal") < 15 then
		percjumpin = percjumpin + 10 + (5 * boss_stage)
		percdualstab = percdualstab + (10 * boss_stage)
	end
	
	--ARE THEY BEHIND US?
	if self:DistFromEnemy("horizontal") < 15 then
		if not self:IsTargetFacingTarget(self.inst, opponent) then
			percdualstab = percdualstab + (20 * boss_stage)
		else
			perclongstab = perclongstab + 10
		end
	end
	
	
	local perctotal = percstab + perclongstab + percdualstab + perctriostab + percjumpin
	local diceroll = math.random(perctotal)
	
	if diceroll <= (percstab) then
		self.chosenattack = "dashattack"
		self.calcframes = 10
		self.calcxpos = 1.2 + math.random(-1,1)
		self.calcypos = 0
		self.calcrange = 2
	elseif diceroll <= (percstab + perclongstab) then
		self.chosenattack = "longstab"
		self.calcframes = 5
		self.calcxpos = 1.8 + math.random(-1,1)
		self.calcypos = 0
		self.calcrange = 2
	elseif diceroll <= (percstab + perclongstab + percdualstab) then
		self.chosenattack = "dualstab"
		self.calcframes = 10
		self.calcxpos = 1.2 + math.random(-1,1)
		self.calcypos = 0
		self.calcrange = 2
	elseif diceroll <= (percstab + perclongstab + percdualstab + perctriostab) then
		self.chosenattack = "triostab"
		self.calcframes = 10
		self.calcxpos = 1.2 + math.random(-1,1)
		self.calcypos = 0
		self.calcrange = 2
	elseif diceroll <= (percstab + perclongstab + percdualstab + perctriostab + percjumpin) then
		-- self.inst.components.talker:Say("SELF-CHOSEN")
		self.chosenattack = "jumpin" 
		self.calcframes = 30
		self.calcxpos = 2
		self.calcypos = -3
		self.calcrange = 2
	else
		--SOMETHIN DUN MESSED UP. TRY IT AGAIN
		self:ChooseAttack()
	end
	
	
	--[[
	--7-17-18 TURN THIS OFF WHEN NOT USING IT!!!
	if math.random() < (1.4) then --0.4 
		
		--THE BASIC. SIMPLE YET EFFECTIVE
		self.chosenattack = "dashattack"
		self.calcframes = 10
		self.calcxpos = 1.2 + math.random(-1,1)
		self.calcypos = 0
		self.calcrange = 2
		
		--THE LONG BOI. DONT STAND TOO CLOSE!
		if math.random() < (0.5) then
			self.chosenattack = "longstab"
			self.calcframes = 5
			self.calcxpos = 1.8 + math.random(-1,1)
			self.calcypos = 0
			self.calcrange = 2
		end
	
	else
	
		self.chosenattack = "jumpin" 
		self.calcframes = 30
		self.calcxpos = 2
		self.calcypos = -3
		self.calcrange = 2
	end
	]]
	
	
	--2-24-17
	-- self.inst.components.spiderspawner:HaveKids() --ENABLE THIS. THIS WAS THE PART THAT MADE KIDS
	--7-1-20 HERE WE CAN MAKE THIS BETTER
	if self.inst.components.spiderspawner:WantsToHaveKids() then
		self.chosenattack = "dspecial" 
	end
	
	
	
	--UNLESS WE IN THE AIR. U SURE AS HECK BETTER NOT DO ANYTHING OTHER THAN JUMP
	if self.inst.components.launchgravity:GetIsAirborn() then
		-- self.inst.components.talker:Say("EMERGENCY JUMP") --NO YOU CANT KEEP YOUR VOICELINES
		self.chosenattack = "jumpin" 
		self.calcframes = 30
		self.calcxpos = 2
		self.calcypos = -3
		self.calcrange = 2
	end
	
	
end




--7-19
function QueenFight:DistFromEnemy(dir)
	--JUST CALL THE REAL ONE
	return self.inst.components.aifeelings:DistFromEnemy(dir)
end



--7-20 CALCULATE ENEMY POSITION    --MAYBE SOME OTHER TIME...
function QueenFight:CalculateTrajectory(frames, range, xoffset)
    local opponent = self.inst.components.stats.opponent or self.anchor
	
	local myposx, myposy = self.inst.Transform:GetWorldPosition()
	local oppx, oppy = opponent.Transform:GetWorldPosition() --or GetPlayer().Transform:GetWorldPosition()
	local oppvelx, oppvely = opponent.Physics:GetVelocity()
	local myvelx, myvely = self.inst.Physics:GetVelocity()
	
		
		
	local xdetection = ((oppvelx + myvelx) * 0.35 * -frames) --* self.inst.components.launchgravity:GetRotationValue()))
	local ydetection = ((oppvely + myvely) * 0.35 * frames)
	
	
	local xdistance = -((myposx + (xoffset* self.inst.components.launchgravity:GetRotationValue())) - oppx)
	
	if (xdistance <= (xdetection + range) and xdistance >= (xdetection - range)) then --and (distsq(0, myposy, 0, oppy) <= (ydetection + range) and distsq(0, myposy, 0, oppy) >= (ydetection - range)) then
	-- if (distsq(myposx, 0, oppx, 0) - range <= (xdetection + 0) and distsq(myposx, 0, oppx, 0) + range >= (xdetection - 0)) then --and (distsq(0, myposy, 0, oppy) <= (ydetection + range) and distsq(0, myposy, 0, oppy) >= (ydetection - range)) then
	
		return true --"grab_range"
	else
		return false
	end
	
	
end



--8-19 
function QueenFight:DriftTowardOpp(backwards)

	local myposx, myposy = self.inst.Transform:GetWorldPosition()
	local oppx, oppy = self.inst.components.stats.opponent.Transform:GetWorldPosition()
	
	self.inst:RemoveTag("holdleft")
	self.inst:RemoveTag("holdright")
	
	if myposx >= oppx then
		self.inst:AddTag("holdright")
	else
		self.inst:AddTag("holdleft")
	end
	
end



--3-14
function QueenFight:OnAttacked() --THIS ISN'T ON ATTACKED!! THIS IS ON HIT! WHEN HE HITS THE OPPONENT!
    self.inst:RemoveTag("going_in")
	-- self.inst:AddTag("escape") --DONT THINK I EVEN USE THIS --8-16
	-- self.inst.components.talker:Say("OUCH!")
	-- self:ChooseAttack()
	
	if not self.inst.components.launchgravity:GetIsAirborn() then
		self.inst.components.aifeelings.blockapproachmod = self.inst.components.aifeelings.blockapproachmod + 10
	end
	
	
	self.status = SUCCESS
end


--8-6
function QueenFight:OnReadyForAction()
    self.inst:RemoveTag("notreadyforaction")
	-- self.inst.components.talker:Say("OUCH!")
	-- self:ChooseAttack()
	self.status = SUCCESS
	--8-4-18 -THIS IS THE OOOOLD METHOD. LETS PASTE THE MODERN METHOD IN HERE
	-- if not self.inst.sg:HasStateTag("idle") and not self.inst.components.launchgravity:GetIsAirborn() then
		-- self:ChooseAttack()
	-- end
	-- print("READY FOR ACTION")
	
	--8-4-18
	if not (self.inst.sg:HasStateTag("jumping") or self.inst.components.launchgravity:GetIsAirborn()) then 
		-- if (self.swung == true and self.hit == false) then    --and self.swung == false then   <THE RIG
			-- -- self.inst:RemoveTag("going_in")
			-- self.status = SUCCESS
			-- self.inst.brain:ForceRefresh() --1-18-17
			
			-- self:ChooseAttack() --1-19-17 WELL WAIT! WE STILL NEED TO CHOOSE A NEW ATTACK TOO, OR ELSE HE'LL JUST CIRCLE AROUND WITH THE SAME ATTACK
			-- print("ITS TIME TO CHOOSE")
		-- else --if not self.inst.components.launchgravity:GetIsAirborn() then
			-- print("I'M READY TO PICK AN ATTACK!")
			-- if self.inst.sg:HasStateTag("idle") and self.idlelock == false then
				-- self:ChooseAttack() --LETS TRY PUTTING THIS IN HERE INSTEAD
				-- self.idlelock = true
			-- else
				-- print("IVE ALREADY ROLLED ONCE!")
			-- end
		-- end
		
		--8-4-18 OKAY, LETS TRY SOMETHING A LITTLE SIMPLER...
		if (self.swung == true) then
			self:ChooseAttack()
		end
		self.swung = false
		self.hit = false
		-- print("DISABLING SWUNG")
	end
end


function QueenFight:Visit()
    
    local combat = self.inst.components.combat
    if self.status == READY then
        
        combat:ValidateTarget()
		
		if not (self.inst.sg:HasStateTag("tryingtoblock") or self.inst.sg:HasStateTag("grounded") or self.inst.sg:HasStateTag("tumbling")) then
			self.status = RUNNING --ALWAYS REDY
		end
        
       
        
    end

    if self.status == RUNNING then
        if not self.inst.components.stats.opponent then --combat.target or not combat.target.entity:IsValid() then
            self.status = FAILED
            combat:SetTarget(nil)
			-- self.inst.components.talker:Say("NOBODYS HERE!...")
            -- self.inst.components.locomotor:Stop()
        -- elseif combat.target and combat.target.components.health and combat.target.components.health:IsDead() then
		elseif combat.target and combat.target.components.stats and combat.target.components.stats.alive == false then --4-4-19 THERE. EVERYBODY GOT STATS! NO MORE HEALTH
            self.status = SUCCESS
            combat:SetTarget(nil)
		elseif self.inst.components.stats.opponent then  --7-21 CHANGING TO PREVENT CRASHING RELATED TO TARGET
			combat.target = self.inst.components.stats.opponent
			-- print("QUEENFIGHT")
			--1-15-22 ADDING THIS CHECK TO CANCEL THE ATTACK NODE IF OUR CURRENT TARGET HAS DIED
			if self.inst.components.stats.opponent.components.stats and self.inst.components.stats.opponent.components.stats.alive == false then
				self.inst.components.stats.opponent = nil
				self.status = SUCCESS
				return end
            
			if not combat.target:IsValid() then --7-22 TO PREVENT SOME HARD CRASHES RELATED TO 
				self.status = FAILED
				return end
			
			if not self.inst.components.stats.opponent:IsValid() then --9-6 SAME AS THE ABOVE REALLY
				self.status = SUCCESS
				return end
            
            local hp = Point(combat.target.Transform:GetWorldPosition())
            local pt = Point(self.inst.Transform:GetWorldPosition())
            local dsq = distsq(hp, pt)
            local r= self.inst.Physics:GetRadius()+ (combat.target.Physics and combat.target.Physics:GetRadius() + .1 or 0)
            local running = self.inst.components.locomotor:WantsToRun()
			
			--3-8 CUSTOM TESTERS
			local enpos = self.inst.components.stats.opponent.Transform:GetWorldPosition() --combat.target.Transform:GetWorldPosition() --CHANGE THIS TO GET SUICIDE BORED
			local mypos = self.inst.Transform:GetWorldPosition()
				
				
				
				local enpos = self.inst.components.stats.opponent.Transform:GetWorldPosition()  --9-2 TO HOPEFULLY STOP CHASEANDFIGHT WHILE OVER EDGE
				if enpos <= (self.anchor.components.gamerules.lledgepos - 3) or enpos >= (self.anchor.components.gamerules.rledgepos + 3) then
					-- print("DONT PLAY ON THE RAILING!")
					self.status = FAILED
				end
				
				
				local opponent = self.inst.components.stats.opponent
				
				
				----000000000000000000000-----
				--7-1-20 UM LETS TRY THIS LIKE A NORMAL PERSON AND NOT TREAT WALKING AS A BUSY STATE
				if self.inst.sg:HasStateTag("busy") then
					--IF WE'RE DOING OUR SUPERJUMP, DRIFT TOWARDS THE ENEMY
					if self.chosenattack == "jumpin" and self.inst.components.launchgravity:GetIsAirborn() then
						self:DriftTowardOpp()
						--IF WE'RE ABOUT TO MAKE BABIES, JAB ANYONE WHO GETS CLOSE
					elseif self.chosenattack == "dspecial" and self.swung == true then
						if self:DistFromEnemy("horizontal") <= 15 and self:IsTargetFacingTarget(self.inst, opponent) and self.inst.sg:HasStateTag("can_jab") then
							self.chosenattack = "jab"
							self.inst.sg:GoToState("jab") --ENEMY IS TRYING TO INTERUPT US! PUNCH EM
						else
							self.status = FAILED --ENEMY ISNT CLOSE ENOUGH. KEEP WATCHING
							return end
					else
						--WE'RE DONE HERE. NOTHING TO DO TIL' WE'RE DONE SWINGING
						self.status = SUCCESS
					end
						
				else --IF WE ARENT BUSY
					if self.inst.sg:HasStateTag("dashing") then --IF WE'RE DASHING (WHICH SHOULD BE THE ONLY NON-BUSY STATE FOR HER, SINCE SHE DOESNT IDLE)
						--WE'RE HEADED TOWARD THE TARGET. DONT INTERUPT US
					else
						--WE MUSTV JUST FINISHED AN ATTACK! PICK A NEW ONE.
						self.swung = false
						self:ChooseAttack()
						--AND THEN CONTINUE ON DOWN THERE WITH WHATEVER ATTACK WE'VE CHOSEN
					end
				end
				
				
				
				
                --self.inst.components.locomotor:GoToPoint(hp, nil, shouldRun)
				--RIGHT HERE, 3-3
				-- if mypos.x <= enpos.x then
				local personalspace = 2
				-- if dsq >= -10000 then --personalspace then --7-23 CHANGIN TO 0 BC IDK WHY WE DONT HAVE IT ALWAYS ACTIVE
				
				self.inst:AddTag("going_in") --TO TELL BRAIN NOT TO BLOCK UNTIL FINISHED
			

				
				
				
				
				--7-25 BAITSMASH   --AND ADDING ELSEIF TO THE BELOW FUNCTION
				-- if self.chosenattack == "baitsmash" then --???
					
					
				-- else
				if not self.inst.sg:HasStateTag("busy") and not self.inst.components.launchgravity:GetIsAirborn() then --3-14 HOPE THIS STOPS HIM FROM AIR-RUNNING
						self.inst.components.locomotor:FaceTarget(self.inst.components.stats.opponent)
						self.inst:PushEvent("dash") --NEVERMIND, QUEEN NEEDS TO DASH

				end
					
				-- end
				-- print("WE THERE YET???", self.chosenattack)
				
				
								
				--12-27-16 FOR SPAWNING SPIDERLINGS TO ATTACK
				if self.chosenattack == "dspecial" then
					self.inst.components.locomotor:FaceTarget(self.inst.components.stats.opponent) --FACE THEM FIRST
					self.inst:PushEvent("throwattack", {key = "dspecial"})
					self.swung = true
					-- print("BABEH", self.chosenattack)
				
				
				elseif self.chosenattack == "jumpin" then --and not self.inst.components.launchgravity:GetIsAirborn() then
					if self.inst.components.stats.jumpspec == "short" then
						if self:DistFromEnemy("horizontal") <= 10 then
							self.inst.components.stats.jumpspec = "short"
							self.inst:PushEvent("singlejump")
							self.swung = true
						end
					elseif self:DistFromEnemy("horizontal") > 10 and not self.inst.components.launchgravity:GetIsAirborn() then --45
						if self:DistFromEnemy("horizontal") <= 65 then
							self.inst:PushEvent("singlejump")
							self.swung = true
						end
					else
						--RE-ROLL
						-- print("JUMPIN FAILED, RE-ROLLING")
						-- self:ChooseAttack() --PREVENTS HIM FROM AWKWARDLY RUNNING PAST YOU TO GET TO A BETTER JUMP POSITION TO JUMP AT YOU FROM
						--7-18-18 -NAH, SEE, WE'LL JUMP EVEN IF THEY'RE RIGHT ON TOP OF US. ALSO, QUEEN KEEPS PREMATURELY CHOOSING ATTACKS MID-AIR. STOP THAT
							self.inst:PushEvent("singlejump")
							self.swung = true
					end
					self:DriftTowardOpp()
					
				elseif self.inst.sg:HasStateTag("dashing") and self.inst.components.aifeelings:CalculateTrajectory(self.calcframes, self.calcxpos, 0, self.calcrange, self.calcrangey) then --self:CalculateTrajectory(self.calcframes, self.calcrange, self.calcxpos) then --1,2,3
				
					if self.chosenattack == "dashattack" then
						-- self.inst:PushEvent("throwattack")
						self.inst.sg:GoToState("fsmash_start")
						self.swung = true
						
					elseif self.chosenattack == "longstab" then
						self.inst.sg:GoToState("ftilt")
						self.swung = true
						
					elseif self.chosenattack == "dualstab" then
						self.inst.sg:GoToState("dsmash")
						self.swung = true
						
					elseif self.chosenattack == "triostab" then --7-1-20
						self.inst.sg:GoToState("fspecial")
						self.swung = true
					
					-- elseif self.chosenattack == "fspecial" then
						-- self.inst:PushEvent("throwattack", {key = "fspecial"})
					
					-- elseif self.chosenattack == "dashingusmash" then
						-- self.inst:PushEvent("throwattack", {key = "usmash"})
					
					else
						-- self.inst:PushEvent("throwattack", {key = "block"})
						-- self.inst.components.talker:Say("NO ATTACK SELECTED")
						-- print("NO ATTACK SELECTED!", self.chosenattack)
					end
					
					-- self:ChooseAttack()
				
				else
					self.inst:RemoveTag("holdleft")
					self.inst:RemoveTag("holdright")

					--8-13 or something A MORE COMPLEX FUNCTION TO SEE IF FACING THE RIGHT WAY
					if not self:IsTargetFacingTarget(self.inst, self.inst.components.stats.opponent) and (self.inst.sg:HasStateTag("running") or not self.inst.sg:HasStateTag("busy")) then
						self.inst.components.locomotor:TurnAround()
					end
					
	
					
					
					--9-1 SO HE DOESN'T WIBBLE AROUND WHEN ENEMY IS HIGH UP ABOVE HIM
					if self:DistFromEnemy("vertical") > 10 and self:DistFromEnemy("horizontal") < 15 and not (self.inst.components.launchgravity:GetIsAirborn() or self.chosenattack == "jumpin") then --LETS ADD THAT CHECK FOR JUMPIN BACK IN
						-- print("ENEMY RIGHT ABOVE US, RE-ROLLING")
						self:ChooseAttack()
					end
					
					
				end
        end
    end
end
