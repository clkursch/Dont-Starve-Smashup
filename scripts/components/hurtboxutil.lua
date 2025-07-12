local HurtboxUtil = Class(function(self,inst)
	self.inst = inst
	
	self.xoffset = 0
	self.yoffset = 0
	self.zoffset = 0
	
	self.owner = nil
	self.existing = true
	
	
	self.sizemult = 1
	if self.inst.components.stats then
		self.sizemult = self.inst.components.stats.sizemultiplier
	end
	
	self.visible = false --true
	
	self.extrax = 0
	self.extray = 0
	
	self.contact = 0
	self.softpushdirection = 1
	
	self.bottlecap = nil --6-12-20
	
	--6-7-18   
	-- self.inst:StartUpdatingComponent(self)
end)



--1-18-20   OKAY, NEW DECISION ABOUT THIS COMPONENT-
-- I THINK I'M GOING TO MAKE THIS COMPONENT FOR BOTH HURTBOXES AND HITBOXES
-- SPECIFICALLY SO "SELF.OWNER" IS EASIER TO GRAB FROM ALL TYPES OF BOXES 
-- (IS THAT IT?? IS THAT THE ONLY REASON TO COMBINE THE USE OF THIS COMPONENT??)
-- (WHAT WAS THE POINT OF THIS COMPONENT IN THE FIRST PLACE?? WHO SPAWNS THESE AGAIN?? HITBOX COMPONENTS ARE VASTLY DIFFERENT BUT THERES BARELY ANYTHING IN HERE)
-- (ACTUALLY I GUESS THAT MAKES SENSE. HURTBOXES DON'T REALLY "DO" MUCH. JUST EXIST AND MOVE AROUND, WHILE HITBOXES CALCULATE ALL SORTS OF DAMAGE FOR HITTING THINGS)
-- AND HURTBOX POSITION UPDATING IS DONE FROM THE PLAYER'S CODE ITSELF. WHICH IS A BETTER METHOD THAN THE WAY WE DO IT WITH HITBOXES


-- self.xknockback = 5
-- self.yknockback = 5

--6-17-18 --A DISABLE SWITCH TO STOP THIS COMPONENTS "UPDATEPOSITION" FN FROM OVERWRITING THE HITBOX'S VERSION
function HurtboxUtil:DisablePositionUpdating()
	self.inst:StopUpdatingComponent(self)
end


--12-3   --5-20-19 WOW WE STILL USE THIS???
function HurtboxUtil:SetOwner(owner)
    self.owner = owner
end

function HurtboxUtil:GetOwner()
    return self.owner
end



--1-14 SOFT COLLISION PLAYER BOXES
function HurtboxUtil:OnSoftCollision(inst, object)

--6-9-29 OKAY, SOME GROUND RULES FOR THE HURTBOXUTIL SHIFT:
-- "OWNER" IS NOW FOR US
-- "CONTACT" SHOULD STILL BELONG TO THE OLD COMPONENT "HURTBOXES" (IF FOR WHATEVER REASON WE EVER HAVE MORE THAN ONE HURTBOX... OR... SHOULD IT?)
-- ACTUALLY NO I CHANGED MY MIND, "CONTACT" WILL ALSO BELONG TO US OR ELSE COLLISION WILL GET REAL WEIRD IF ENEMIES ARE ONLY TOUCHING ONE OF MULTIPLE PLAERBOXES
-- SO UH. JUST TRY NOT TO HAVE MULTIPLE PLAYERBOXES OFTEN. THATS HOW ITS DESIGNED TO BE USED ANYWAYS

if not self.owner:IsValid() or not object then --3-30 ADDED TEST FOR OBJECT AS WELL BECAUSE IT WAS CRASHING?? DID THIS EVEN FIX IT??
	return end
	
	
	if self.owner:HasTag("heavy") then --6-17-18 FOR STRUCTURES LIKE SPIDER DENS THAT SHOULD PUSH PLAYERS AWAY, BUT NOT GET PUSHED THEMSELVES
		return end --DONT EVEN DO ANYTHING PAST THIS
		
		
	local opponent = object.components.hurtboxutil.owner
	
	if not opponent:IsValid() then --ALWAYS GOOD TO MAKE SURE OUR ENEMY EXISTS BEFORE HITTING THEM
			return end
		
		
	if object:HasTag("playerbox") and not (opponent.sg:HasStateTag("intangible") or self.owner.sg:HasStateTag("intangible")) then
		
		--7-1-18 --I HOPE ALL THESE WON'T GET TOO RESOURCE INTENSIVE 
		--LET BABYS WALK FREELY PAST THE QUEEN AND DENS
		if self.owner:HasTag("ignore_heavy_boxes") and opponent:HasTag("heavy") then
			return end
			
			
		--3-2-17 AN ATTEMPT TO FIX BACKWARD THROWS AT LEDGES THAT CAUSE ENEMIES TO SLIDE OUT OF GRASP --IT WORKS
		if (opponent:HasTag("refresh_softpush") or self.owner:HasTag("refresh_softpush")) then
			self.contact = 2
			object.components.hurtboxutil.contact = 2 --BE A GENTLEMAN AND SET THEIR CONTACT VALUE TO TRUE AS WELL
			opponent:RemoveTag("refresh_softpush")	--KEEP IN MIND, "REFRESH_SOFTPUSH" WILL NOT WORK IF IN CONTACT WITH MORE THAN 1 ENEMY PLAYERBOX
			self.owner:RemoveTag("refresh_softpush")
		end
		
		
		if self.contact == 2 then
			local xpos = self.owner.Transform:GetWorldPosition()
			local xpos2 = opponent.Transform:GetWorldPosition()
			if xpos > xpos2 then
				self.softpushdirection = -1
				-- self.owner.AnimState:SetAddColour(1,0,1,1) --FOR TESTING
			elseif xpos < xpos2 then --5-13-19 CHECK BOTH FOR LESS THAN AND GREATER THAN SO THAT IF ==, THEY WONT MOVE AT ALL. PREVENT THAT AKWARD DOUBLE LEFT SLIDE
				self.softpushdirection = 1
				-- self.owner.AnimState:SetAddColour(0,1,1,1) --FOR TESTING
			end
			
		end
		self.contact = 1
		
		
		local xpos, g1, g2 = self.owner.Transform:GetWorldPosition()
		local xpos2, g3, g4 = opponent.Transform:GetWorldPosition()
		local shove = (1/(xpos-xpos2))
		if shove <= 0 then
			shove = -shove
		end
		if shove >= 2.5 then
			shove = 2.5
		end
		local vx, vy = self.owner.Physics:GetVelocity()
		if vx >= 2 or vx <= -2 then
			shove = 0
		end
		
		--4-27-17 LETS TONE DOWN THE SOFTPUSHING FOR AIREAL OPPONENTS
		if self.owner.components.launchgravity:GetIsAirborn() then
			shove = shove / 3 
		end
		
		self.owner.components.launchgravity:PushAwayFrom((0.4 * shove),0,0, opponent, (0.45 * self.softpushdirection)) --PERFECT. --TODOLIST, MAKE THE 0.45 FLUID TO ADJUST FOR WIDER CHARACTERS
	end
end


--7-9-19 JUST GET IT OVER WITH
function HurtboxUtil:InitSoftCollision()
	
	self.inst.Physics:SetCollisionCallback(function(inst, object)
		self:OnSoftCollision(inst, object)
	end)
	
	self.inst:StartUpdatingComponent(self) --START THE ENGINE
end



--7-14-19 IF THIS IS A PLAYERBOX, UPDATE THE "COLLISION" VARIABLE
function HurtboxUtil:OnUpdate(dt)
	
	--7-14-19 THIS IS UNDER THE ASSUMPTION THAT OnUpdate() WILL BE ENABLED FOR PLAYERBOXES ONLY
	--IF YOU ENABLE THIS FOR OTHER HURTBOX TYPES, YOU NEED TO ENABLE CHECKS FOR PLAYERBOX
	--1-18-20 UM, BUT ISNT THIS COMPONENT ALSO FOR NORMAL HURTBOXES? (AND SOON TO BE HITBOXES) MAYBE I SHOULD GET STRAIGHT TO THE POINT
		--OHHH, OKAY WE ONLY RUN THE INITIATOR FOR PLAYERBOXES. SO DON'T WORRY, THIS IS FINE THE WAY IT IS

	-- if self.inst:HasTag("playerbox") then
		if self.contact == 0 then
			self.contact = 2 --2 IS LIKE HASNT BEEN TOUCHING IN A WHILE
		elseif self.contact == 1 then
			self.contact = 0
		end
	-- end
end



return HurtboxUtil