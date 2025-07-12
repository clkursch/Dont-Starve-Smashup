local Hurtboxes = Class(function(self,inst)
	self.inst = inst
	
	self.xoffset = 0
	self.yoffset = 0
	self.zoffset = 0
	
	self.numberofhurtboxes = 1
	-- self.inst.components.hurtboxutil.owner = nil --HOPING TO REPLACE THIS WITH HURTBOXUTIL.OWNER
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
	
	self.ledgegrabboxtable = {} --1-8 I ACCEPT YOUR CHALLENGE. TODAY I SET OUT TO MASTER TABLES
	self.hurtboxtable = {}
	self.temphurtboxtable = {}
	
	self.mainplayerbox = nil
	
	--11-24-20 COPIED FROM HITBOXES.LUA. DONT YOU JUST LOVE THIS "FEATURE"
	-- if TheWorld.Map:GetTileCenterPoint(0, 0, 0) == 0 then
	--8-31-21 THAT WAS FOR X AXIS YOU FOOL
	self.ztileoffset = TheWorld.Map:GetTileAxisOffset("z")
	
	--6-7-18   
	self.inst:StartUpdatingComponent(self)
end)


--10-27-20 THE DISTANCE IN THE BG HURTBOXES SIT TO MAKE SPRITES MORE VISIBLE IN FRONT OF THEM
local zdist = 0 --0.2


--6-17-18 --A DISABLE SWITCH TO STOP THIS COMPONENTS "UPDATEPOSITION" FN FROM OVERWRITING THE HITBOX'S VERSION
function Hurtboxes:DisablePositionUpdating()
	self.inst:StopUpdatingComponent(self)
end

--12-3
function Hurtboxes:SetOwner(owner)
    self.inst.components.hurtboxutil.owner = owner
end

function Hurtboxes:GetOwner()
    return self.inst.components.hurtboxutil.owner
end



--OUR ONUPDATE FN WILL ADD THESE "EXTRA" VALUES ONTO THE USUAL COORDINATES WHEN UPDATING POSITION
function Hurtboxes:ShiftHurtboxes(xshift, yshift)
	self.extrax = self.extrax + xshift
	self.extray = self.extray + yshift

end


function Hurtboxes:Initialize(box, xpos, ypos, size, ysize, frames, property)  --ALSO OUT OF ORDER
	local owner = self.inst
	
	if property and property == 1 then --WAIT, HOW CAN A HURTBOX BE DISJOINTED?...
		box:AddTag("disjointed")
	end
	
	
	
	--1-15 THE ACTUAL PHYSICS COLLISION SIZE APPLIER
	if ysize and ysize ~= 0 then
		box.Transform:SetScale(size*4,ysize*4,1)
		--11-7-16 I THINK I NEED TO DOUBLE Y SCALE --PERFECT
		box.Physics:SetCylinder(size, (ysize*2))
		box.AnimState:PlayAnimation("box")
	elseif size and size ~= 0 then  --7-18 PUT THIS HERE SO THAT CUSTOM SHAPED BOXES (LIKE PLAYEBOX) CAN BE INITIALIZED WITHOUT BEING RESIZED BY ENTERING A ZERO IN AS THE SIZE
		box.Transform:SetScale(size*1,size,1)
		box.Physics:SetSphere(size/4) --MUUUCH better
	end
	
	
	box.components.hurtboxutil:SetOwner(owner)
	box.components.hurtboxutil.xoffset = self.xoffset + xpos + self.extrax
	box.components.hurtboxutil.yoffset = self.yoffset + ypos + self.extray
	
	-- box.components.hurtboxes:PlaceIntoPosition(box) --5-20-19 --THERE. NOW IT WON'T UPDATE EVERY BOX JUST BECAUSE WE SPAWNED ONE
	--6-5-19 ACTUALLY HERE I JUST UPDATED THIS FUNCTION TO NOW BE ONLY A SINGLE USE INDIVIDUAL HURTBOX POSITION SPAWNER
	self:UpdatePosition(box)
	
	--SPECIFYING FRAMES WILL GIVE A LIFESPAN TO THE HURTBOX AND MAKE IT DISSAPEAR AFTER THE SPECIFIED TIME
	if frames and frames ~= 0 then
		box:DoTaskInTime((frames)*FRAMES, function(box) 
		box:Remove()
	end)
	end
	
	

end



--6-7-18 --SINCE THE DOPERIODICTASK SEEMS TO BE FAILING, ITS TIME TO TAKE A NEW APPROACH...
function Hurtboxes:OnUpdate(dt)
	-- self:UpdatePosition() --SIZE HAS NOTHING TO DO WITH IT ANYMORE
	self:UpdateAllPositions() --FOR EVERYONE!
	-- print("ME OWNER", self.inst.components.hurtboxutil.owner)
end


--NO, UPDATE EACH POSITION ONE AT A TIME
--SEEMS KINDA WEIRD HOW POSITION UPDATING IS DONE SO DIFFERENTLY BETWEEN HITBOX AND HURTBOXES. BUT HONESTLY, I THINK THIS VERSION MAKES MORE SENSE (AND LESS LAG)
function Hurtboxes:UpdateAllPositions()

	local getdir = -self.inst.components.launchgravity:GetRotationValue() --WAY MORE EFFECIANT THAN CHECKING FOR "LEFT" OR "RIGHT"  
	local x, y, z = self.inst.Transform:GetWorldPosition() --OUR OWNER'S POS
	z = z - zdist		--THE HITBOXES THEMSELVES ALL DISPLAY SLIGHTLY IN FRONT OF THE CHARACTERS (SO THEYRE VISIBLE WHEN.. UH ..VISIBLE)
	local velx, vely = self.inst.Physics:GetVelocity()
	local physicsenabled = self.inst.Physics:IsActive()
	
	--MOVE THOSE HURTBOXES
	local function MoveBoxes(box, x, y, z, extrax, extray, velx, vely)
		if not box:IsValid() then return end
		z = self.ztileoffset - zdist --8-28-21 THESE SHOULD REALLY BE AT Z = 0...
		--OH RIGHT. IT'S NOT ALWAYS 0. IT'S WEIRD LIKE THAT. WE SHOULD REALLY MAKE THIS A FUNCTION
		
		local xoffset = box.components.hurtboxutil.xoffset
		local yoffset = box.components.hurtboxutil.yoffset
		
		local xshift = (xoffset + extrax) * getdir
		local yshift = y + yoffset + extray
		
		--AND THEN JUST DO IT. NOTHIN TO IT
		box.Transform:SetPosition( x - xshift, yshift, z )
		
		if physicsenabled then --ONLY APPLY VELOCITY IF PHYSICS IS ENABLED
			box.Physics:SetVel(velx, vely, 0)
		else
			box.Physics:SetVel(0, 0, 0)
		end
	end
	
	-- MoveBoxes(v, owner, x, y, z, self.extrax, self.extray, velx, vely)
		
	
	for k,v in pairs(self.hurtboxtable) do
		-- self:UpdatePosition(v)
		MoveBoxes(v, x, y, z, self.extrax, self.extray, velx, vely)
	end
	for k,v in pairs(self.temphurtboxtable) do
		MoveBoxes(v, x, y, z, self.extrax, self.extray, velx, vely)
	end
	
	for k,v in pairs(self.ledgegrabboxtable) do
		MoveBoxes(v, x, y, z, self.extrax, self.extray, velx, vely)
	end
	
	--AND SELF.MAINPLAYERBOX?..  --IIRC, THERE WAS AT LEAST MORE THAN 1 REASON WE DON'T ALLOW MORE THAN ONE OF THESE. MIGHT BE BETTER TO KEEP IT THIS WAY
	if self.mainplayerbox and self.mainplayerbox:IsValid() then
		MoveBoxes(self.mainplayerbox, x, y, z, self.extrax, self.extray, velx, vely)
	end
end




--10-27-20 OK, MY OLD METHOD IS DUMB AND UNINTUATIVE. IM KEEPING THE LEGACY FUNCTION BUT CREATING A CLEANER VERSION FOR MODDERS
function Hurtboxes:SpawnHurtbox(xpos, ypos, xsize, ysize, reference)
	
	local xsize = xsize
	local ysize = ysize or 0

	if ysize and ysize ~= 0 then
		ysize = ysize
		--THESE ARE LITERALLY JUST UNDOING THE WEIRD MATH IN THE NEXT FORMULA
		ypos = ypos + (ysize/4) --HEY, WOULD YOU LOOK AT THAT. SPACES PERFECTLY IF WE IGNORE ALL THAT DUMB STUFF
	else
		xsize = xsize * 4
		ypos = ypos + (xsize/4)
	end
	
	--AND THEN PASS IT ONTO THE LEGACY VERSION... HONESTLY THE NEW ONE IS SO MUCH BETTER, BUT IM AFRAID I HAVE TOO MUCH BUILT INTO LEGACY TO CHANGE IT ALL
	self:CreateHurtbox(xsize, xpos, ypos, ysize, reference)
end


--10-27-20 ALSO DOING ONE FOR TEMP HURTBOXES BC IM LAZY --OH THESE ONES WERE ACTUALLY IN AN AGGREABLE ORDER. TOO BAD THE YPOS FORMULAS ARE STILL THERE
function Hurtboxes:SpawnHurtboxTemp(xpos, ypos, xsize, ysize, frames)
	
	local xsize = xsize
	local ysize = ysize or 0

	if ysize and ysize ~= 0 then
		ysize = ysize
		--THESE ARE LITERALLY JUST UNDOING THE WEIRD MATH IN THE NEXT FORMULA
		ypos = ypos + (ysize/4) --HEY, WOULD YOU LOOK AT THAT. SPACES PERFECTLY IF WE IGNORE ALL THAT DUMB STUFF
	else
		xsize = xsize * 4
		ypos = ypos + (xsize/4)
	end
	
	--AND THEN PASS IT ONTO THE LEGACY VERSION... HONESTLY THE NEW ONE IS SO MUCH BETTER, BUT IM AFRAID I HAVE TOO MUCH BUILT INTO LEGACY TO CHANGE IT ALL
	self:SpawnTempHurtbox(xpos, ypos, xsize, ysize, frames) --, property, reference)
end








--1-14 RECREATING HURTBOX SPAWNER TO NOT BE STUPID
function Hurtboxes:CreateHurtbox(size, xpos, ypos, ysize, reference)  --WARNING!!!!! THESE ARE ALL MIXED UP AND DIFFERENT
		-- local newhurtbox = SpawnPrefab("hitsphere") 
		--5-13-19  LETS GIVE THESE HURTBOX PREFABS A TRY~
		local newhurtbox = SpawnPrefab("hurtbox")
		
		if reference then --2-8 SAME DEAL-  ADDING REFERENCE TESTER FOR ADVANCED HURTBOXES
			newhurtbox:Remove() --6-5-19 DELETE THE OLD ONE FIRST!! 
			newhurtbox = reference
		end
	
		
		table.insert(self.hurtboxtable, newhurtbox)

		
		if ysize and ysize ~= 0 then
			-- yhight = ysize
			newhurtbox.Physics:SetCylinder(size, ysize)
			-- newhurtbox.Transform:SetScale((size*4),(ysize*4), 1) --11-7-16 ALRIGHT, BOX SIZE DOES NOT MATCH ACTUAL HURTBOX HIGHT. I GOTTA FIX THIS.
			newhurtbox.Transform:SetScale((size*4),(ysize*4), 1)
			newhurtbox.AnimState:PlayAnimation("box_old") --box
			
			-- ypos = ypos - (ysize/4)  --3-2 SAME THING I DID TO HITBOXES TO RESTORE THEIR CORRECT DECISION FROM BOTTOM ANCHORED
			ypos = ypos - (ysize/4)   --3-15 WAIT I SEEM TO HAVE OVERSHOT IT? WERE THEY ALREADY IN THE RIGHT POSITION? REMOVING THESE TWO
			self:Initialize(newhurtbox, xpos, ypos, size, ysize)
		else
			newhurtbox.Physics:SetSphere(size)
			newhurtbox.Transform:SetScale((size*4),(size*4), 1)
			ypos = ypos - (size/4)
			self:Initialize(newhurtbox, xpos, ypos, size)
		end
		
		--1-22 --NEW HURTBOX COLISIONS
		-- newhurtbox.Physics:SetCollisionCallback(OnHurtboxCollide) --1-28 REMOVING TO LOWER LAG
		
end



--TEMP HURTBOXES ARE HURTBOXES THAT LAST LIMITED FRAMES OR REMOVE THEMSELVES AT THE END OF A STATE (RIGHT? I THINK SO. ITS BEEN A FEW YEARS SINCE IVE VISITED THIS FUNCTION)
function Hurtboxes:SpawnTempHurtbox(xpos, ypos, size, ysize, frames, property, reference) --NO THEY'RE FINE NOW, ALL IN ORDER.   --WARNING!!!!! THESE ARE ALL MIXED UP AND DIFFERENT FROM THE PERMINANT ONES --(size, xpos, ypos, frames)
	
		local newhurtbox = nil -- = SpawnPrefab("hurtbox")
		
		if reference then --2-8 SAME DEAL-  ADDING REFERENCE TESTER FOR ADVANCED HURTBOXES THAT GET REFERENCED OUTSIDE OF THIS FILE
			--newhurtbox:Remove() -- --6-9-18 GET RID OF THE OLD ONE, OR ELSE IT WILL JUST BE SITTING INACTIVE IN THE MIDDLE OF THE WORLD -REUSEABLE
			newhurtbox = reference
		-- end
		else
			newhurtbox = SpawnPrefab("hurtbox")
		end
		
		table.insert(self.temphurtboxtable, newhurtbox)

		if ysize and ysize ~= 0 then
			-- yhight = ysize
			newhurtbox.Physics:SetCylinder(size, (ysize*2)) --7-18 DOUBLING PHYSICAL Y SIZE BC ITS NOT DOUBLED LIKE RADIUS IS
			newhurtbox.Transform:SetScale((size*4),(ysize*4), 1)
			if self.visible then
				newhurtbox.AnimState:PlayAnimation("box")
			end
			
			ypos = ypos - (ysize/4)
			self:Initialize(newhurtbox, xpos, ypos, size, ysize)
		else
			newhurtbox.Physics:SetSphere(size)
			newhurtbox.Transform:SetScale((size*4),(size*4), 1)
			
			ypos = ypos - (size/4)
			self:Initialize(newhurtbox, xpos, ypos, size)
		end
		
		newhurtbox:DoTaskInTime(frames*FRAMES, function()
			-- newhurtbox:Remove()
			--6-22-19 NOOOPE GOTTA GET MORE CRAFTY THAN THAT. REMOVE THE TABLE REFERENCE TOO! (WONDER WHAT HAPPENED TO THE OLD ONES...)
			self:RemoveTempHurtbox(newhurtbox)
		end)
		-- self:Initialize(newhurtbox, xpos, ypos, size)
end

function Hurtboxes:ResetHurtboxes()
	self.extrax = 0
	self.extray = 0
	--[[
	for k,v in pairs(self.temphurtboxtable) do
			-- table.remove(self.temphurtboxtable, k)
			v:Remove()
			self.temphurtboxtable = {}
	end
	-- print("THEY HAVE BEEN EXTERMINATED")
	]]
	--5-13-19 WOW DUDE JUST WOW. WHAT DID YOU DO TO THIS THING?? THIS IS NOT HOW YOU EMPTY TABLES. COME ON, JUST- .. JUST REDO THIS FROM SCRATCH
	for k,v in pairs(self.hurtboxtable) do
		v:Remove()
		self.hurtboxtable[k] = nil
	end
	self.hurtboxtable = {}
	
	for k,v in pairs(self.temphurtboxtable) do
		v:Remove()
		self.temphurtboxtable[k] = nil
	end
	self.temphurtboxtable = {}
	--5-13-19  THERE. ALL CLEANED UP
	--FOR REAL THOUGH HOW WAS THIS EVEN FUNCTIONING BEFORE THIS??... THIS HAS GOT TO BE YEARS OLD
end

function Hurtboxes:ResetTempHurtboxes()
	self.extrax = 0
	self.extray = 0
	
	--AT LEAST THAT ONE DIDN'T LOOK LIKE SPHAGETTI
	for k,v in pairs(self.temphurtboxtable) do
		v:Remove()
		self.temphurtboxtable[k] = nil
	end
	self.temphurtboxtable = {}
end

--6-22-19 REMOVE A SPECIFIC TEMP HURTBOX BY REFERENCE (HANDY COPYSNIP FROM GAMERULES)
function Hurtboxes:RemoveTempHurtbox(boxref)  
	local boxref = boxref 
	
	for k,v in pairs(self.temphurtboxtable) do
		if v == boxref then --IS THIS THE ONE WE WANT KILLED?
			self.temphurtboxtable[k] = nil --REMOVE IT FROM THAT SLOT ON THE TABLE
		end
		v:Remove() --THEN DELETE IT!
	end
end






--DANG. JUST LOOK AT THIS FOSSIL... YOU KNOW, I MIGHT JUST LEAVE IT IN HERE. FOR FUNSIES.   --IM LAUGHING WHY IS SIZE A PART OF THIS
function Hurtboxes:UpdatePositionRRRR(size, xpos, ypos) --(ownery, thehurtbox)
	--local owner = self:GetOwner()
	--print("OWNER", ownery)
	--local owner = TheSim:FindFirstEntityWithTag(owner)
	
-- if self:GetOwner() then
	local owner = self.inst.components.hurtboxutil.owner
	if owner and owner:IsValid() then --IS VALID

	--[[
		--12-16 ON FINISHING A MOVE, REVERTS ALL REMAINING CLASHBOXES INTO REGULAR HURTBOXES
		if self.inst:HasTag("clashbox") and not owner.components.hitbox.active then
			--self:ResetTempHurtboxes()
			self.inst:RemoveTag("clashbox")
		end
		
		if self.inst:HasTag("clashbox") then
			-- self.inst.AnimState:SetMultColour(1,0.5,0,1) --MAKE THEM INVISABLE
			-- print("YOU LISTENING????")
		end
		
		if self.inst:HasTag("disjointed") then
			-- self.inst.AnimState:SetMultColour(0,0,0,1) --MAKE THEM INVISABLE
			-- print("YOU LISTENING????")
		end
		
		if self.inst:HasTag("ledgebox") or self.inst:HasTag("ledgegrabbox") then
			-- self.inst.AnimState:SetMultColour(0,0.2,1,0.4) --MAKE THEM INVISABLE
			-- print("YOU LISTENING????")
		end
		
			
		if owner.sg and owner.sg:HasStateTag("intangible") and self.visible == true then
			-- self.inst.AnimState:SetMultColour(0.3,0.3,0.3,0.3) 
		elseif self.visible == true then
			self.inst.AnimState:SetMultColour(0.6,0.6,0.6,0.6)
		end
		]]
		
		
		--3-22 FOR PLAYERBOX CONTACT STUFF
		if self.inst:HasTag("playerbox") then
			-- self.inst.AnimState:SetMultColour(1,0.5,0,1) --MAKE THEM INVISABLE
			if self.contact == 0 then
				self.contact = 2 --2 IS LIKE HASNT BEEN TOUCHING IN A WHILE
			elseif self.contact == 1 then
				self.contact = 0
			end
		end

		--local x, y, z = self.inst.Transform:GetWorldPosition()
		--self.getdir = self.inst.components.launchgravity:GetRotationFunction()
		
			-- local x, y, z = owner.Transform:GetWorldPosition()
			-- self.getdir = owner.components.launchgravity:GetRotationFunction()
		
		--local x, y, z = owner
		--self.getdir = "left"
		--local getdir = "left"
		
		--12-10
		-- local x, y, z = nil
		-- -- if owner.Transform and owner.components and owner.components.hurtboxes and owner.components.hurtboxutil:GetOwner() then
		-- if owner.Transform and owner.components and owner.components.hurtboxes then --and owner.components.hurtboxutil:GetOwner() then
		-- x, y, z = owner.Transform:GetWorldPosition()
		-- end


		--local x, y, z = self.inst.Transform:GetWorldPosition()
		--self.getdir = owner.components.launchgravity:GetRotationFunction()
		local getdir = owner.components.launchgravity:GetRotationFunction()
		local x, y, z = owner.Transform:GetWorldPosition()
		-- if self.inst:HasTag("clashbox") then
			-- -- self.extrax = 0
			-- -- self.extray = 0
		-- end
		
		z = z - 0.2
		
		--THESE ARE SUPPOSED TO WORK. WHY DON'T THEY
		--local x, y, z = self.inst.owner.Transform:GetWorldPosition()
		-- local posthing = self.inst.owner.Transform:GetWorldPosition()
		--self.inst.getdir = self.inst.owner.components.launchgravity:GetRotationFunction()
		
		--self.inst.Transform:SetScale(size,size,size)

				-- self.hurtbox2.components.hurtboxes.xoffset = self.xoffset + xpos
				-- self.hurtbox2.components.hurtboxes.yoffset = self.yoffset + ypos
		
		
		if getdir == "left" and not self.inst:HasTag("clashbox") and not self.inst:HasTag("noshift") then 
			self.extrax = -self.extrax --12-7
			--self.xoffset = -self.xoffset
			--self.hurtbox.Transform:SetPosition( x-self.xoffset, y+self.yoffset, z )
			--GetPlayer().hurtbox.Transform:SetPosition( x-self.xoffset, y+self.yoffset, z )
			--thehurtbox.Transform:SetPosition( x-self.xoffset, y+self.yoffset, z )
			
			-- self.hurtbox.Transform:SetPosition( x+self.xoffset, y+self.yoffset, z )
			self.inst.Transform:SetPosition( x+self.xoffset+self.extrax, y+self.yoffset+self.extray, z )
			-- self.inst.Transform:SetPosition( x+self.xoffset+0, y+self.yoffset+0, z )

		elseif not self.inst:HasTag("clashbox") and not self.inst:HasTag("noshift") then
			--self.xoffset = self.xoffset
			--self.hurtbox.Transform:SetPosition( x+self.xoffset, y+self.yoffset, z )
			self.inst.Transform:SetPosition( x-self.xoffset+self.extrax, y+self.yoffset+self.extray, z )
			-- self.inst.Transform:SetPosition( x-self.xoffset+0, y+self.yoffset+0, z )
		
		elseif self.inst:HasTag("clashbox") then
			self.inst.Transform:SetPosition( x-self.xoffset+self.extrax, y+self.yoffset+self.extray, z ) --?????? HOW?? --WAAAAIT!! NOW Y VALUES ARE MESSED UP... --NVM FIXED IT IN RESETTEMPHURTBOXES
			-- print("IM A LITTLE TEA CUP")
		else --1-4 FO OTHER BOXES I GUESS?????
			self.inst.Transform:SetPosition( x-self.xoffset+self.extrax, y+self.yoffset+self.extray, z )
		end
		--self.yoffset = ypos
		
		--print(self.xoffset)
		
		--1-25 
		local velx, vely = owner.Physics:GetVelocity()
		self.inst.Physics:SetVel(velx, vely, 0)
		
		-- self.hurtbox.Transform:SetPosition( x+self.xoffset, y+self.yoffset, z )
		
	-- else
		-- self.inst:Remove()
	end
end




--FOR A CORE HITBOX ONUPDATE FUNCTION, I SURE DIDN'T TAKE VERY GOOD CARE OF THIS BEFORE TODAY
--OH WAIT YOU KNOW WHAT? BECAUSE OF THESE CHANGES, I HAVE TO CHANGE THIS ONE TOO DONT I. OH YEA. SO NOW INSTEAD OF PER-BOX, THIS RUNS ON EACH BOX PER-PLAYER
function Hurtboxes:UpdatePosition(boxref) --(ownery, thehurtbox)
	
	
	local box = boxref
	if not (box and box:IsValid()) then --IS VALID
		return end
	
	local boxponents = box.components.hurtboxutil --LOL. IDK WHAT TO CALL THIS VARIABLE NAME 
	--3-22 FOR PLAYERBOX CONTACT STUFF --MOVED THIS TO HURTBOXUTIL
	
	local getdir = -self.inst.components.launchgravity:GetRotationValue() --WAY MORE EFFECIANT THAN CHECKING FOR "LEFT" OR "RIGHT"  
	local x, y, z = self.inst.Transform:GetWorldPosition()
	
	--z = z - 0.2		--THE HITBOXES THEMSELVES ALL DISPLAY SLIGHTLY IN FRONT OF THE CHARACTERS (SO THEYRE VISIBLE WHEN.. UH ..VISIBLE)
	-- z = 0 - zdist --10-21-20 MIGHT AS WELL PUT THEM ALL IN THE SAME PLACE
	z = self.ztileoffset - zdist --11-24-20 EXCEPT THE "SAME PLACE" ISNT ALWAYS THE SAME DEPENDING ON THE Z AXIS THE MAP GENERATES ON :/
	--WE SHOULDN'T NEED A "NOSHIFT" TAG BECAUSE GRABLEDGE ANIMATIONS SHOULD RESET ALL HITBOX SHIFTING ON GRABBING A LEDGE
	
	--HERE THIS VERSION DOESN'T DO LIKE 6 POINTLESS IF STATEMENTS
	local xshift = (boxponents.xoffset + self.extrax) * getdir  --6-5-19 SELF.EXTRAX/EXTRAY IS A REAL VARIABLE THAT SHOULD STAY ON OUR PLAYER, THOUGH
	local yshift = y + boxponents.yoffset + self.extray
	
	--AND THEN JUST DO IT. NOTHIN TO IT
	box.Transform:SetPosition( x - xshift, yshift, z )
	
	--11-3-20 I FOUND THE SECRET TO MAKING THESE PHYSICS OBJECTS MOVABLE WITH A MASS OF 0! THEY NEED TO HAVE A COLLISIONCALLBACK FN AND THEN TURN PHYSICS OFF AND ON AGAIN
	box.Physics:SetCollisionCallback(function(inst, object) 
		-- --AH HA!! SO IT NEEDS A COLLISION CALLBACK!... I THOUGHT THEY ALL HAD THOSE THOUGH.
	end)
	box.Physics:SetActive(false) 
	box.Physics:SetActive(true)
	
	--1-25 
	local velx, vely = self.inst.Physics:GetVelocity()
	box.Physics:SetVel(velx, vely, 0)
	--10-21-20 SO DO THESE ACTUALLY MOVE?? //SHRUG/
end






--1-8 IT WORKS, I HAVE MASTERED TABLES- wow that only took like maybe 20 minutes
function Hurtboxes:RemoveAllGrabboxes()
		
	for k,v in pairs(self.ledgegrabboxtable) do --DST CONVERTABLE
			v:Remove()
			-- self.hitboxtable = {} --UH...WAS THIS.. A TYPO?... -11-8-17 OH WELL, IT'S WORKED FINE FOR THIS LONG, NO NEED TO QUESTION IT NOW
			--4-1-19  WJSDALJKHGASLKJ OH MY GOD YOU STRAIGHT DUNCE ARE YOU FOR REAL?? THIS IS THE REASON IT RETURNS LIKE 12 HITS WHEN YOU GRAB THE LEDGE
			--UNBELEIVABLE. HOW HAS THIS NOT BEEN NOTICED SOONER???
			-- self.ledgegrabboxtable = {} --4-1-19 --THERE. GOD. ONLY TOOK ME TWO YEARS TO NOTICE THE INFINITE BUILDUP OF GRAB-BOXES
			--!!WAIT NO THATS NOT EVEN THE RIGHT WAY TO-
			self.ledgegrabboxtable[k] = nil  --OKAY HERE. IM PRETTY SURE THIS IS HOW YOU DO IT. god im about to lose my mind
	end
	
	--	now DOUBLE CHECK >_>  ...OKAY... GOOD...
	-- for k,v in pairs(self.ledgegrabboxtable) do
		-- print("ARE YOU GONE?", k,v)
	-- end
end








local function OnCollide2(inst, object)
	--10-21-20 YES, THIS DOES NEED TO BE HERE!!! OTHERWISE THE PHYSICS COLLISION DOESNT INITIALIZE
end




--1-8 YOU KNOW WHAT, NAH LETS MAKE 'EM COLLISION BASED. IT'LL BE LIKE HITBOX 2.0 PRACTICE. I'LL NEED TO LEARN SOONER OR LATER
function Hurtboxes:CreateLedgeGrabBox(xpos, ypos, size, sizey, shape) --OUT OF ORDER. AGAIN. MAN I AM TERRIBLE AT STAYING CONSISTANT
	
	--6-5-19 A MUCH CLEANER VERSION
	if not self.ledgegrabbox1 then 
		local ledgegrabbox1 = SpawnPrefab("ledgegrabbox") --6-5-19
		table.insert(self.ledgegrabboxtable, ledgegrabbox1)
		ledgegrabbox1.components.hurtboxutil:SetOwner(self.inst)
		
		ledgegrabbox1.Transform:SetScale((size*4),(sizey*3), 1)

		self:Initialize(ledgegrabbox1, xpos, ypos, size, sizey)
		
		--DOESNT DO A SINGLE THING BUT IT DOES NEED COLLISION TO BE "ON" FOR THE OTHER END TO COOPERATE, APPARENTLY
		ledgegrabbox1.Physics:SetCollisionCallback(OnCollide2)
	end
	
	
		-- DST- POST PORTAL UPDATE- LEDGEGRABBOX COLLISION JUST... STOPPED WORKING FOR ABSOLTELY NO REASON. 
		-- ITS COLOSION HAS TRANSFERED TO PLAYERBOX BECAUSE ????? I DUNNO, DST REASONS I GUESS
		--10-12-17 DST - AAALLLLLRIGHT. OOKAY. HECC ALL OF THIS. IF THE LEDGE IS NOT GOING TO COOPERATE, THE LEDGEGRAB BOX WILL DO THINGS ON ITS OWN.
		-- ledgegrabbox1.Physics:SetCollisionCallback(OnCollide2) --THIS DOES THE SAME THING AS LEDGEBOX'S COLLISION.
		--4-1-19 ^^ IT SURE DOES, SO WHY ARE WE DOING BOTH!? JUST USE ONE. THE LEDGE BOX IS SIMPLER, DOESNT MOVE, AND NO NEED TO WORRY ABOUT STARTUP TIME AS ITS ALWAYS ACTIVE
end



--11-16-17 DST CHANGE REUSEABLE - A SLIGHTLY SIMPLER APPROACH TO REPLACING THESE.
function Hurtboxes:ReplaceLedgeGrabBox(xpos, ypos, size, sizey, shape) 
	self:RemoveAllGrabboxes() --LOL THIS IS SO DUMB ALL IT DOES IS SAVE ONE LINE OF CODE
	self:CreateLedgeGrabBox(xpos, ypos, size, sizey, shape) 
end



--1-13 TRYING TO MAKE SOFT-COLISION FOR PLAYERS SO THAT THEY CAN PUSH EACH OTHER AROUND
function Hurtboxes:SpawnPlayerbox(xpos, ypos, size, sizey, shape) --The heck is shape for? 

		if self.mainplayerbox then
			self.mainplayerbox:Remove()
		end
		
		--6-5-19 MAKE IT PRETTIER
		local playerbox = SpawnPrefab("playerbox") 
		self.mainplayerbox = playerbox
		
		
		-- table.insert(self.hitboxtable, playerbox) --NAH, ILL RE-ENABLE THIS IF I DECIDE TO HAVE MORE THAN 1 PLAYERBOX
		self.mainplayerbox.components.hurtboxutil:SetOwner(self.inst)
		-- self.mainplayerbox.Physics:SetCollisionGroup(212) --(COLLISION.OBSTACLES) --212 --HEY, LETS SEE IF I CAN JUST THROW ANY NUMBER ONTO THIS
		-- local collisionmask = 8 --5-13-19 ONE OF THE THREE FREE COLISION GROUPS THAT WONT COLLIDE WITH EACH OTHER. PLAYERBOXES ARE THE LUCKY FELLOWS THAT GET THESE
		-- self.mainplayerbox.Physics:SetCollisionGroup(collisionmask)
		-- self.mainplayerbox.Physics:ClearCollisionMask()
		-- self.mainplayerbox.Physics:CollidesWith(collisionmask) --(COLLISION.CHARACTERS)  --YEP, I CAN! --WONDER WHY THE IN-GAME COLLISION VARIABLES ARE SO FAR APART...
		
		self.mainplayerbox.Physics:SetCapsule((size),(sizey*2))
		self.mainplayerbox.Transform:SetScale((size*4),(sizey*4), 1)

		ypos = ypos - (sizey/4)
		
		self:Initialize(self.mainplayerbox, xpos, ypos, 0, 0) --box, xpos, ypos, size, frames
		-- 7-18 ENTERING A ZERO IN FOR THE SIZE ^^^^^ SO THE INITIALIZATION PROCESS DOESNT RESIZE/RESHAPE IT
		self.mainplayerbox.components.hurtboxutil:InitSoftCollision() 
end



--DST CHANGE- REUSABLE -CONVERTABLE-- TO "TRULY" REMOVE ALL DIFFERENT KINDS OF BOXES WHEN REMOVING THE PLAYER
function Hurtboxes:RemoveAllHurtboxes()
	self:ResetHurtboxes()
	if self.mainplayerbox then --DST CHANGE
		self.mainplayerbox:Remove()
	end
	self:RemoveAllGrabboxes()
end




return Hurtboxes