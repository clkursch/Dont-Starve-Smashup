

--THIS COMPONENT NAME IS SOMEWHAT MISLEADING.
--THIS IS A COMPONENT FOR ANY ENTITY CAPABLE OF SPAWNING HITBOXES. IT HANDLES THE CREATION OF HITBOXES, BUT NOT THEIR INTERACTIONS WITH OTHER OBJECTS.

--THE COMPONENT FOR HITBOXES THEMSELVES IS "HITBOXES.LUA"


--VAUGELY BASED OFF OF EXPLOSIVE.LUA, THOUGH VERY LITTLE REMAINS OF THE ORIGINAL FUNCTION CODE
local Hitbox = Class(function(self,inst)
	self.inst = inst
	self.explosiverange = 2
	self.explosivedamage = 2 
	self.buildingdamage = 2  
	self.lightonexplode = true
	self.onexplodefn = nil
	self.onignitefn = nil
	
	self.yexplosiverange = nil
	
	self.xoffset = 0
	self.yoffset = 0
	self.zoffset = 0

	self.sizemult = 1
	if self.inst.components.stats then
		self.sizemult = self.inst.components.stats.sizemultiplier
	end
	
	-- self.doflash = nil
	-- self.highlight = 0
	self.blockdamage = 1
	self.blockstun = 1
	self.hitstun = 1
	
	self.lingerframes = 20
	self.active = true
	self.readyfornewmove = true
	
	self.perc = 1
	self.dam = 12
	self.rawdam = 12
	self.scale = 90 / 100  --NEEDS TO BE DEVIDED BY 100
	self.base = 32
	self.rate = 1
	self.kbangle = 45 
	
	self.emphasis = 0
	self.priority = 0
	self.property = 0
	
	self.setknockback = 0
	
	self.xprojectilespeed = 2
	self.yprojectilespeed = 2
	
	self.opponent = nil
	
	self.aironlyfn = nil
	
	self.blockdam = 0
	self.chipdam = 0
	
	------------------------ --1-9 HITBOXES 2.0
	self.visible = true
	
	self.hitboxtable = {}
	self.scored = {} --LIST OF ENEMY HURTBOXES WE'VE INTERACTED WITH IN THIS FRAME (so we don't run onhit-functions more than once per frame)
	
	self.onhitfn = nil
	self.prehitfn = nil --10-28-17 
	self.onposthitfn = nil --12-15-16 BECAUSE ENTERING HITLAG CAN SOMETIMES CANCEL OUT ANY ONHIT FUNCTIONS
	self.oncollidefn = nil
	
	self.suction = 0
	self.sucpx = 0
	self.sucpy = 0
	
	self.hitfxsprite = nil
	self.hitfxsound = nil
	
	self.bank = nil
	self.build = nil
	self.anim = nil
	
	self.tempboxtable = {} --1-31-17 NEW TABLE FOR AI FEARBOXES (THAT NEVER GOT IMPLIMENTED)
	
	
	--5-31-18 -OKAY, SINCE HITBOX UPDATERS ARE SO SLOW TO START UP, WE'LL LET THIS COMPONENT BE THE HEARTBEAT FOR THEM
	self.inst:StartUpdatingComponent(self)  --BUT... THIS CAN HAPPEN AN ENTIRE TICK AFTER THE HITBOX HAS ALREADY SPAWNED, AND THATS NO FUN
end)


--5-31-18
function Hitbox:OnUpdate(dt) 
	for k,v in pairs(self.hitboxtable) do
		v.components.hitboxes:OnHeartbeat(dt) --SINCE HITBOXES COMPONENT IS TOO SLOW TO START UP, WE HAVE TO RUN ONUPDATE FOR THEM
		-- v.components.hitboxes:RollToHit() --AND WHAT IF WE JUST... ALSO...  --NAH. JUST LET THESE WALL UPDATE. ITS NOT WORTH IT
	end
	
	for k,v in pairs(self.tempboxtable) do --THESE GUYS TOO.
		v.components.hitboxes:OnHeartbeat(dt)
	end
	-- print("IM UPDATING")
end


local frame_delay = 1 --1-9 LETS KEEP A CONSISTANT NUMBER. LOWERING FROM 3 TO 1 TO PREVENT EARLY ANIMATION BUGS AND STUFF


function Hitbox:SetBaseKnockback(basekb)
    self.base = basekb
end

function Hitbox:SetAngle(kbangle)
    self.kbangle = kbangle
end

function Hitbox:SetGrowth(growth)
    self.scale = growth
end

function Hitbox:SetDamage(damage)
    self.dam = damage
	self.rawdam = damage
end



--THESE ARE SUPER OUTDATED AN UNUSED. BUT I HAD USED THEM IN SO MANY PLACES, IT'S TOO HARD TO GET RID OF THEM ALL
--===============================
function Hitbox:SetKnockback(xknockback, yknockback)
    -- self.xknockback = xknockback
	-- self.yknockback = yknockback
end

function Hitbox:SetHitLag(hitlag)--(dur, scl)
    self.hitlag = hitlag + 0.1  --TO PREVENT IT FROM GOING BELOW THE MAXIMUM STARTUP AND GET CAUGHT IN INFINITE HITLAGE
end
function Hitbox:SetCamShake(camshake)--(dur, scl)
    self.camshake = camshake
end
function Hitbox:DoFlash(bool)
	self.doflash = bool
end
function Hitbox:SetHighlight(highval)
	self.highlight = highval
end
--===============================




function Hitbox:SetBlockDamage(blockdamage)
	-- self.blockdamage = blockdamage
	self.blockdam = blockdamage / 10 --12-26-21 REPLACING WITH (HOPEFULLY) THE CORRECT VERSION
end

function Hitbox:SetSize(xsize, ysize) --1-14 ADJUSTING FOR BOXES
	self.explosiverange = xsize, ysize
	if ysize then
		self.yexplosiverange = ysize
	else
		self.yexplosiverange = nil
	end
end

function Hitbox:SetProjectileSpeed(xspeed, yspeed)
	self.xprojectilespeed = xspeed
	self.yprojectilespeed = yspeed
end

function Hitbox:SetProjectileDuration(duration)
	self.projectileduration = duration
end


function Hitbox:SetPriority(priority)
	self.priority = priority
end

function Hitbox:AddEmphasis(num)
	self.emphasis = num
end

function Hitbox:SetLingerFrames(frames)
	self.lingerframes = frames + 1 --9-4 ADDING TO THE LINGER FRAMES
end

function Hitbox:MakeDisjointed()
	self.property = 1
end

function Hitbox:MakeRogue()
	self.property = 2
end

function Hitbox:MakeGroundOnly()
	self.property = 3
end

function Hitbox:AddSuction(power, sucpx, sucpy)
	self.suction = power --(0-1)
	self.sucpx = sucpx
	self.sucpy = sucpy
end

function Hitbox:SetHitFX(sprite, sound) --4-11
	self.hitfxsprite = sprite
	self.hitfxsound = sound
	
	if sprite == "default" then --11-10-16 SPECIFIC HIT FX OVERRIDES
		self.hitfxsprite = nil
	end
	if sound == "default" then
		self.hitfxsound = nil
	end
end



function Hitbox:FinishMove()
	self.active = false
	self.readyfornewmove = false
	
	self:RemoveAllHitboxes()
end

function Hitbox:ResetMove()
	self.readyfornewmove = true
	self.onhitfn = nil
	self.prehitfn = nil
	self.onposthitfn = nil
	self.chipdam = 0
	self.suction = 0
	self.hitfxsprite = nil
	self.hitfxsound = nil
	self.property = 0 --RIGHT?? 7-8-17
	self.priority = 0 --2-10-22 HOW DID I MISS THIS ONE??
end 

function Hitbox:AddNewHit()
	self.active = true
	self.scored = {}
	
	--4-6-19 MY DUDE, YOU DON'T NEED THIS MULTIPLE TIMES. IT'S CLEARED UP THERE
	-- for k,v in pairs(self.scored) do
		-- --v:Remove() --OKAY LETS NOT DELETE WILSON
		-- self.scored = {}
	-- end
	
	for k,v in pairs(self.hitboxtable) do --IDK WHY I NEED THIS BUT THIS FIXED IT --2-2 OR SOMETHING
			v.components.hitboxes.pyschecktable = {}
	end
		
end


function Hitbox:AddDamage(damage)
    self.dam = self.dam + damage
	self.rawdam = self.dam
end

function Hitbox:MultiplyDamage(ammount)
    self.dam = self.dam * ammount     --FOR CHARGING SMASHES:   1 * (1.025 ^ 15) = 1.44
	self.rawdam = self.dam
end



function Hitbox:MakeFX(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
	--1-6-22 ADDING A FAILSAFE FOR THE OCASIONALY LATE CLANK FX SPAWNER
	if not (self.inst and self.inst:IsValid()) then
		return end
	
	local fx = SpawnPrefab("fight_fx")
	local pos = Vector3(self.inst.Transform:GetWorldPosition())
	local pointdir = 0
	
	--6-30-17 THIS HAS BEEN NEEDED FOR A WHILE... KIND OF A SILLY WAY TO DO IT THOUGH.
	self.inst.components.stats.lastfx = fx --BASCIALLY YOU NEED TO USE THIS REFERENCE IMMEDIATELY OR ELSE IT COULD GO STALE... THIS IS A BAD IDEA
	
	if not r then
		r = 0
		g = 0
		b = 0
	end
	
	
	if fxname == "ground_crack" then
		fx.AnimState:SetOrientation( ANIM_ORIENTATION.OnGround )
	end
	
	if not glow then
		glow = 0
	end
	
	-- if self.inst.components.launchgravity:GetRotationValue() == 1 then
	if xsize <= 0 then
		pointdir = 180
	end
	
	
	--3-1 BUILDS AND BANKS
	if build then
		fx.AnimState:SetBank(bank)
		fx.AnimState:SetBuild(build)
	else
		fx.AnimState:SetBank("fight_fx")
		fx.AnimState:SetBuild("fight_fx")
	end
	
	fx.Transform:SetRotation((self.inst.Transform:GetRotation() - pointdir)) --4-18 MOVED THIS UP A LIL TO FIX THE SINGLE FRAME FLIP BUG
	
	
    fx.AnimState:PlayAnimation(fxname)
	fx.AnimState:SetMultColour((alpha + r),(alpha + g),(alpha + b),alpha)
	fx.AnimState:SetAddColour(glow,glow,glow,glow)
	
	
	--JUST DISABLING FOR NOW SO IT DOESNT GET ANNOYING
	fx.Transform:SetPosition((pos.x + (xoffset*self.inst.components.launchgravity:GetRotationValue())), (pos.y + yoffset + 0), (pos.z + zoffset))
	fx.Transform:SetScale(xsize,ysize,1)
	
	
	--3-1 STICKING
	if stick and (stick == 1 or stick == 2) then  --11-10-16 
		
		--4-25-17 THE NEW VERSION THAT UPDATES SMOOTHLY~
		fx:AddComponent("fxutil")
		fx.components.fxutil.owner = self.inst
		fx.components.fxutil.xoffset = xoffset
		fx.components.fxutil.yoffset = yoffset
		fx.components.fxutil.currentstate = self.inst.sg.currentstate.name --SO IT CAN KNOW WHEN A NEW STATE IS ENTERED
		fx:AddTag("fx_wallupdate")
		
	end
	
	
	fx:DoTaskInTime(duration*FRAMES, function(inst)
		-- fx.AnimState:SetMultColour(0.3,0.3,0.3,0.3) --10-27-16 OKAY, IT'S TIME I FIXED THIS
		fx.AnimState:SetMultColour(((alpha+r)/3),((alpha+g)/3),((alpha+b)/3),(alpha /3)) --THERE WE GO!!
		local gv = 0
		inst.AnimState:SetAddColour(gv,gv,gv,gv) --JUST MAKE A 4TH SPRITE ALREADY. IT'LL LOOK GOOD
		
		--11-10-16 ALRIGHT IM BEING A LAZY DOOFUS AND MAKING IT SO THAT STICK=2 IS A SHORTCUT TO HAVE DURATION CUT INSTANTLY INSTEAD OF FADE
		if stick and stick == 2 then  --11-10-16 
			fx:Remove()
		end
		
	end)
	fx:DoTaskInTime((duration+2)*FRAMES, function(inst)
		fx:Remove()
	end)
end


--9-8 TO MAKE AN INST BLINK A CERTAIN COLOR FOR A GIVEN DURATION  (WHY TF DID I PUT THIS IN THE HITBOX COMPONENT???)
function Hitbox:Blink(inst, duration, r, g, b, glow, alpha) --I MIGHT ADD ADDITIONAL VARIABLES FOR GLOW COLORS
	
	-- 11-2-24 THERE FIXED IT
	inst.components.visualsmanager:Blink(inst, duration, r, g, b, glow, alpha)
end





function Hitbox:GetOpponent()
	return self.opponent
end


--2-1
function Hitbox:SetOnHit(fn)
	self.onhitfn = fn
end

--10-28-17
function Hitbox:SetOnPreHit(fn)
	self.prehitfn = fn
end

--12-15-16
function Hitbox:SetOnPostHit(fn)
	self.onposthitfn = fn
end

function Hitbox:SetOnCollide(fn)
	self.oncollidefn = fn
end

function Hitbox:SetShieldDamage(damage) --FUNCTION IS UNUSED? 
    self.blockdam = damage / 10
end
function Hitbox:SetChipDamage(damage)
    self.chipdam = damage
end

--10-10-16
function Hitbox:SetProperty(prop) --10-10-16  TOOK ME LONG ENOUGH, GEEZ
    self.property = prop --11-8-16 WHY...DOES THIS NOT WORK???...
end


--HITBOX 1.0 SUCKED. POOFING IT AWAY. MOVING MOST OF THE DAMAGE RELATED CODE TO HITBOXES.LUA

--1-9 THE BEGINNING OF HITBOXES 2.0
function Hitbox:RemoveAllHitboxes()
		for k,v in pairs(self.hitboxtable) do
			v:Remove()
		end
		for k,v in pairs(self.tempboxtable) do
			v:Remove()
		end
		self.tempboxtable = {}  --4-6-19 THERE, ONLY NEED THIS ONCE
		self.scored = {} --4-6-19 ALL OF THESE! WE SHOULD ONLY NEED ONCE?? 
		self.hitboxtable = {}
end


function Hitbox:SetOwner(owner)
    self.owner = owner
end

function Hitbox:InitializeHitbox(box, xpos, ypos, ycenter)  --ALSO OUT OF ORDER --1-15 LIKE EVERYTHING AFTER YPOS ISNT USED --3-1 ADDING YCENTER FOR HITSPLASH POSITIONING
	local owner = self.inst
	
	if self.priority ~= 0 then
		box.components.hitboxes:SetPriority(self.priority)
	end
	
	local xtra = 0
	local ytra = 0
	
	box.components.hurtboxutil:SetOwner(owner)
	box.components.hitboxes.lingerframes = self.lingerframes

	--6-17-18 --THINGS SEEM TO BE GETTING A LITTLE SCREWY HERE, HITBOXES CHANGING POSITION AFTER THE FIRST FRAME. LETS TRY AND SOLIDIFY THEIR POSITIONAL DATA
	box.components.hitboxes.xoffset = self.xoffset + xpos --+ self.extrax
	box.components.hitboxes.yoffset = self.yoffset + ypos --+ self.extray
	
	box.components.hitboxes.blockdamage = self.blockdamage
	box.components.hitboxes.blockstun = self.blockstun
	box.components.hitboxes.hitstun = self.hitstun
	box.components.hitboxes.priority = self.priority 
	self.priority = 0 --PUTS IT BACK ONCE ITS DONE
	
	if self.property < 0 then --2-8-17 FOR ALL-PURPOSE DISJOINTING
		box:AddTag("disjointed")
		self.property = -self.property
		if VISIBLEHITBOXES == true then
			box.AnimState:SetMultColour(0.25,0.0,0.0,0.8)
		end
	end
	box.components.hitboxes.property = self.property 
	if self.property == 1 then
		box:AddTag("disjointed")
		if VISIBLEHITBOXES == true then
			box.AnimState:SetMultColour(0.25,0.0,0.0,0.8)
		end
	elseif self.property == 2 then
		box:AddTag("rogue")
	elseif self.property == 3 then
		box:AddTag("groundedonly")
	end
	self.property = 0 --PUTS IT BACK ONCE ITS DONE
	
	box.components.hitboxes.dam = self.dam
	box.components.hitboxes.scale = self.scale
	box.components.hitboxes.base = self.base
	box.components.hitboxes.rate = self.rate
	box.components.hitboxes.kbangle = self.kbangle
	
	box.components.hitboxes.onhitfn = self.onhitfn
	box.components.hitboxes.prehitfn = self.prehitfn
	box.components.hitboxes.onposthitfn = self.onposthitfn
	box.components.hitboxes.oncollidefn = self.oncollidefn
	box.components.hitboxes.blockdam = self.blockdam
	box.components.hitboxes.chipdam = self.chipdam
	box.components.hitboxes.emphasis = self.emphasis
	box.components.hitboxes.suction = self.suction
	box.components.hitboxes.sucpx = self.sucpx
	box.components.hitboxes.sucpy = self.sucpy
	box.components.hitboxes.hitfxsprite = self.hitfxsprite
	box.components.hitboxes.hitfxsound = self.hitfxsound
	
	box.components.hitboxes.ycenter = ycenter
	self.emphasis = 0
	
	
	box.components.hitboxes:Init()
	

	--11-3-20 I FOUND THE SECRET TO MAKING THESE PHYSICS OBJECTS MOVABLE WITH A MASS OF 0! THEY NEED TO HAVE A COLLISIONCALLBACK FN AND THEN TURN PHYSICS OFF AND ON AGAIN
	--BUT DONT GIVE THEM A NEW COLLISIONCALLBACK FN IF THEY ALREADY HAVE ONE! IT WILL REPLACE THE OLD ONE
	-- box.Physics:SetCollisionCallback(function(inst, object) 
		--AH HA!! SO IT NEEDS A COLLISION CALLBACK!... I THOUGHT THEY ALL HAD THOSE THOUGH.
	-- end)
	box.Physics:SetActive(false) 
	box.Physics:SetActive(true)
	
	box.components.hitboxes:UpdatePosition()
	
	--6-12-20 UPDATE THE BOTTLECAP'S POSITION TOO
	if box.components.hurtboxutil.bottlecap then
		box.components.hurtboxutil.bottlecap.components.bottlecap_util:OnUpdate()
	end
	
end



function Hitbox:SpawnHitbox(xpos, ypos, zpos, size, shape)  --ZPOS DOESN'T ACTUALLY DO ANYTHING //SHRUG
	--11-4-17 DST CHANGE- SOME CRAZY CHECKER TO TELL LANDING DETECTION TO HOLD-UP FOR JUUUST A MOMENT IN CASE HITBOXES HAVEN'T FINISHED DOING THEIR THING YET
	self.inst:AddTag("notclearforlanding") --OKAY, COOL. BUT NOW HOW WILL IT GET REMOVED?
	
	--[[ 1-12-20 OKAY, IT'S BEEN A LITTLE WHILE SINCE I WAS BACK HERE. DO I REMEBER HOW TO MESS AROUND WITH THIS? 
	-- if not self.ledgegrabbox1 then 
		-- self.ledgegrabbox1 = SpawnPrefab("hitsphere")
		local newhitbox = SpawnPrefab("hitsphere") --IT IS TIME TO TST WHAT YOU'VE LEARNED
		-- local newhitbox = SpawnPrefab("hitsphere2") --6-6-18 --LETS TRY SOMETHING A LITTLE BETTER SUITED
		-- print("TOAST")
		-- local thehurtbox1 = self.hitsphere
		newhitbox:AddTag("hitbox")  ----6-6-18 @@@@ COMMENTING OUT FOR CUSTOM HITBOX PREFAB TESTING
		newhitbox:RemoveTag("hurtbox")  ----6-6-18 @@@@ COMMENTING OUT FOR CUSTOM HITBOX PREFAB TESTING
		-- newhitbox:AddComponent("hitboxes")  ----6-17-18 !!TOTALLY DIFFERENT IDEA, REMOVING HURTBOX COMPONENT ENTIRELY SO IT CAN BE RE-ADDED-... NO NO NO, DONT DO THAT
		newhitbox:AddComponent("hitboxes")  ----6-6-18 @@@@ COMMENTING OUT FOR CUSTOM HITBOX PREFAB TESTING
		-- print("TOAST")
		
		]]--
		
	--1-12-20 OKAY, WE SHOULD TRY TO NORMALIZE THESE HITBOXES RIGHT? IM KINDA SHAKING THE FOUNDATION HERE WITH THIS
	local newhitbox = SpawnPrefab("hitbox")
	table.insert(self.hitboxtable, newhitbox)
	newhitbox.components.hurtboxutil:SetOwner(self.inst)

	--6-12-20 INTRODUCTION OF "BOTTLECAPS" OR DUMMY PHYSICS COLLISION PARTNERS TO ENSURE ALL HITBOXES COLLIDE WITH AT LEAST ONE OBJECT BEFORE THEY ARE ELIGIBLE TO BE REMOVED
	local bottlecap = SpawnPrefab("bottlecap")
	newhitbox.components.hurtboxutil.bottlecap = bottlecap
	bottlecap.components.bottlecap_util.partner = newhitbox
	
	local nypos = ypos
	
	if self.yexplosiverange and self.yexplosiverange ~= nil then
		newhitbox.Physics:SetCylinder(self.explosiverange, (self.yexplosiverange*2))  --7-18 I GUESS YEXPLOSIVERANGE HAS TO BE DOULBED TO ACCOUNT FOR THE FACT RADIUS DOUBLES ITSELF
		newhitbox.Transform:SetScale((self.explosiverange*4),(self.yexplosiverange*4), 1)
		newhitbox.AnimState:PlayAnimation("box")
		nypos = nypos - (self.yexplosiverange/2) 
	else
		newhitbox.Physics:SetSphere(self.explosiverange*1)
		newhitbox.Transform:SetScale((self.explosiverange*4),(self.explosiverange*4), (self.explosiverange*4))
		nypos = nypos - (self.explosiverange/2)
	end
	
	
	if self.inst:HasTag("projectile") then --1-28 I GUESS THIS FIXED PROJECTILE HITBOX COLLISION STUFF? SOMEHOW? BUT THEN WHY WAS IT COLIDING WITH OTHER PROJECTILES FINE BEFORE
		newhitbox.components.hitboxes.explosiverange = self.explosiverange
	end
	

	self:InitializeHitbox(newhitbox, xpos, nypos, ypos) --3-1 REDOING WITH YCENTER TO HELP HITSPLASHES APPEAR IN THE RIGHT SPOT, AND BC THE REST ISNT USED
end





--2-8 THROWIN THIS HERE TOO --TODOLIST, FIX THIS SO YOU DONT GRAB TEAMMATES
local function IsFoe(inst, object) --1-11 A MUCH NICER CONDENSED VERSION OF THE "ISNOTSELF" CHECKER
	
	--7-9-19 OKAY LETS FIND EVERYONE'S OWNER -FIRST- NOW THAT THESE CAN COME FROM DIFFERENT SOURCES DEPENDING ON IF ITS A HITBOX OR HURTBOX
	local function FindOwner(pet)
		if pet.components.hitboxes then
			return pet.components.hurtboxutil.owner
		elseif pet.components.hurtboxutil then
			return pet.components.hurtboxutil.owner
		else
			return nil end
	end
	
	local my_owner = FindOwner(inst) 
	local opponent = FindOwner(object) --7-9-19 GOTTA GET IT FROM HERE NOW, SINCE WE COULD BE CHECKING A HITBOX OR A HURTBOX
	
	
	local is_not_self = opponent ~= my_owner --inst.components.hurtboxutil.owner --CHANGING SOME TO HURTBOXES --BUT I DON'T THINK THAT'S RIGHT? THEY SHOULD CHECK THEM ALL
	local doesnt_belongs_to_self = (my_owner.components.stats.master ~= opponent) and (opponent.components.stats.master ~= my_owner)
	local is_not_on_same_team = (my_owner.components.stats.team ~= opponent.components.stats.team) or not my_owner.components.stats.team
	local is_not_related = (my_owner.components.stats.master ~= opponent.components.stats.master) or not my_owner.components.stats.master or not opponent.components.stats.master
	--7-15-18 WHY WAS "is_not_on_same_team" COMMENTED OUT? WAS THERE A REASON?... WELL, IM TURNING IT BACK ON, BECAUSE WE NEED IT
	
	return is_not_self and doesnt_belongs_to_self and is_not_on_same_team and is_not_related
end






function Hitbox:SpawnGrabbox(xmove, ymove, zmove, reference) 
	
	-- local grabbox = SpawnPrefab("hurtbox") --LETS USE THE SHINY NEW PREFAB TOO
	local grabbox = SpawnPrefab("grabbox")
	--WAIT, LACK OF FORESIGHT... IF GRABBOXES ONLY TOUCH GRABBOXES, BUT THEY SHOULD ALSO COUNT AS HURTBOXES... OH WAIT THIS AINT GONNA WORK IS IT?
	--6-22-19 OH WAIT! NEVERMIND, LOOK AT THIS! LOOKS LIKE I CAN JUST ADD ON COLLISION GROUPS TO TOUCH?...
	

	grabbox.Physics:CollidesWith(32) --THIS ONE IS FOR HITBOXES/HURTBOXES
	--SO... IF I START WITH A HURTBOX AND ADD PLAYERBOX COLLOSION ONTO IT, NOTHING HAPPENS
	--BUT IF I START WITH A PLAYERBOX AND ADD HURTBOX COLLISION, IT WORKS FINE?... YOU KNOW WHAT IM JUST GOING TO MOVE ON AND NOT QUESTION IT
	
	local function OnCollide(inst, object)
		if not (object and object:HasTag("playerbox")) then   --6-9-20 WHAT DO YOU MEAN "NIL OBJECT" HOW DID YOU EVEN GET A COLLISION CALLBACK WITHOUT AN OBJECT TO COLIDE WITH?!?
			return end	--6-10-19  NOT A PLAYERBOX?? DONT EVEN BOTHER WITH THE REST
		
		local opponent = object.components.hurtboxutil:GetOwner()
		local owner = inst.components.hurtboxutil.owner
		
		if object:HasTag("playerbox") and IsFoe(inst, object) and not (opponent.sg:HasStateTag("intangible") or opponent.sg:HasStateTag("grounded") or opponent.sg:HasStateTag("nograbbing") or opponent:HasTag("nograbbing") or opponent.components.stats:IsInvuln()) then
			
			owner.components.stats.opponent = opponent --3-17, TO REFRESH OPPONENT REFERENCE FOR THROWS
			opponent.components.stats.opponent = owner --12-30-31 AND VICE-VERSA
			
			if owner.sg:HasStateTag("grabbing") then
				--12-22-18 WE NEED BETTER SUCTION ON THESE GRABS
				local myx, myy, myz = owner.Transform:GetWorldPosition()
				local gravvalue = owner.components.launchgravity:GetRotationValue() 
				-- print ("GRAVVALUE", gravvalue)
				myx = myx + ((xmove*1.5) * gravvalue) --THIS IS WHERE WE WANT THEM TO GO (and we dont care about Y, that should always be 0)
				local theirx, theiry = opponent.Transform:GetWorldPosition()
				
				--NOW MOVE THEIR BUTT WHERE WE WANT THEM TO BE (ON THE FLOOR IN FRONT OF US) AND FREEZE
				opponent.Transform:SetPosition(myx, myy, myz)
				opponent.components.launchgravity:Launch(0, 0, 0) --APPARENTLY THIS WASN'T ALREADY HAPPENING?
				opponent:RemoveTag("listenforfullhop") --1-16-22 THEY GOT GRABBED, DONT LET EM CONTINUE THE JUMP
				
				--1-8-22 THIS SHOULD PROBABLY HAPPEN AFTER WE'VE ALREADY MOVED THEM
				opponent:ForceFacePoint(owner.Transform:GetWorldPosition())
				opponent:PushEvent("on_punished") --8-23 REFERS TO BEING HIT OR GRABBED
				opponent.sg:GoToState("grabbed")
				owner.sg:GoToState("grabbing")
				
				--CONSIDER ADDING THESE TAGS ONCE SUCTION WORKS WELL ENOUGH
				owner:AddTag("refresh_softpush") --THE SOFTPUSH DETECTION EATS THESE TAGS ONCE THEY'RE DETECTED
				opponent:AddTag("refresh_softpush")
				
				--DOUBLE CHECK THAT WE HAVEN'T BEEN HIT BY ANYTHING
				owner:DoTaskInTime(1*FRAMES, function()
					if not owner.sg:HasStateTag("grabbing") then
						opponent.sg:GoToState("rebound", 10)
					end
				end)
				
			end
		end
	end
	
	
	
	-- MAKING THEM TEMP HURTBOXES
	-- self.inst.components.hurtboxes:SpawnTempHurtbox((xmove*self.inst.components.launchgravity:GetRotationValue()), ymove, (self.explosiverange*4), ((self.yexplosiverange or 0)*4), self.lingerframes , self.property, grabbox)
	self.inst.components.hurtboxes:SpawnTempHurtbox((xmove), ymove, (self.explosiverange*4), ((self.yexplosiverange or 0)*4), 3, self.property, grabbox)
	--6-8-18 BETTER THAN SETTING THE TEMPFRAMES, GIVE IT'S HITBOXES COMPONENT A LIFESPAN!!
	-- grabbox.components.hitboxes.lifespan = self.lingerframes --DST CHANGE 
	--6-10-19 LOL I LIKE THE IDEA BUT I DON'T THINK I REALIZED THE TEMPHITBOX LIFESPAN HAS BEEN OVERWRITING IT THIS WHOLE TIME. THATS OK THESE DONT EVEN USE HITSTUN SO WHO GIVES A STARVE.
	
	grabbox.Physics:SetCollisionCallback(OnCollide)
end



--2-11
function Hitbox:SetProjectileAnimation(bank, build, animation)
    self.bank = bank
	self.build = build
	self.anim = animation
end


function Hitbox:SpawnProjectile(xmove, ymove, zmove, reference)
	local projectile = SpawnPrefab("basicprojectile")  --("wilson") --("spider")
	--local x, y, z = self.inst.Transform:GetWorldPosition()
	
	--12-14-16 WORKAROUND ALLOWING OFFSET HITBOXES FOR PROJECTILES THAT AREN'T CENTERED ON THE ANIMATION PLANE //SHRUGS AT KLEI DEVS
	local xhitboxoffset = 0
	local yhitboxoffset = 0
	
	if reference then --2-8 I WONDER IF THIS WILL WORK...
		projectile:Remove() --11-2-20 GET RID OF THE OLD ONE FIRST SO IT DOESNT STICK AROUND --FINALLY THIS FIXED IT
		projectile = reference
		
		xhitboxoffset = reference.components.projectilestats.xhitboxoffset
		yhitboxoffset = reference.components.projectilestats.yhitboxoffset
	end
	
	
	projectile.AnimState:SetBank(self.bank)
	projectile.AnimState:SetBuild(self.build)
	projectile.AnimState:PlayAnimation(self.anim, true)
	
	
	--DONT NEED ANY OF THE BELOW STUFF BECAUSE NOW I GOT DIRECTIONALVALUE
	local pos = Vector3(self.inst.Transform:GetWorldPosition())
	
	xmove = xmove * self.inst.components.launchgravity:GetRotationValue()
	
	projectile.Transform:SetPosition((pos.x + xmove - 0.1), (pos.y + ymove + 1), (pos.z + zmove))
	projectile:ForceFacePoint((pos.x + xmove + (1* self.inst.components.launchgravity:GetRotationValue())), (pos.y + ymove + 1), (pos.z + zmove))  --POINTDIR SEEMS TO BE CRASHING THE GAME
	--IF I CAN JUST GET FACE DIRECTION WORKING THEN i WONT NEED TO WORRY ABOUT CHANGING VELOCITY WHEN FACING AWAY
	
	if not projectile.components.hitbox then
		projectile:AddComponent("hitbox") --1-28
	end
	
	projectile.components.hitbox:SetDamage(self.dam)
	projectile.components.hitbox:SetAngle(self.kbangle)
	projectile.components.hitbox:SetBaseKnockback(self.base)
	projectile.components.hitbox:SetGrowth(self.scale)
	-- projectile.components.hitbox:SetHitLag(self.hitlag) --NO YOU DUM DUM
	-- projectile.components.hitbox:SetCamShake(self.camshake)
	-- projectile.components.hitbox:SetHighlight(self.highlight)
	-- projectile.components.hitbox:DoFlash(self.doflash)
	if self.yexplosiverange and self.yexplosiverange ~= 0 then
		projectile.components.hitbox:SetSize(self.explosiverange, self.yexplosiverange)
	else
		projectile.components.hitbox:SetSize(self.explosiverange)
	end
	

	projectile.components.hitbox:SetLingerFrames(self.lingerframes)
	projectile.components.hitbox:SetOnHit(self.onhitfn)
	projectile.components.hitbox:SetOnPreHit(self.prehitfn)
	projectile.components.hitbox:SetOnPostHit(self.onposthitfn)
	projectile.components.projectilestats:SetProjectileDuration(self.projectileduration) --12-8-17 REUSEABLE -NOW SETS PROJECTILE LIFESPAN IN PROJECTILESTATS
	projectile.components.hitbox.property = self.property --3-29 IM AN IDIOT I ALWAYS FORGET TO SET THESE UP  --NVM IM JUST GONNA DO IT THE OLD FASHIONED WAY
	if self.suction ~= 0 then
		projectile.components.hitbox:AddSuction(self.suction, self.sucpx, self.sucpy)
	end
	
	if self.hitfxsprite ~= nil then
		projectile.components.hitbox:SetHitFX(self.hitfxsprite, self.hitfxsound)
	end
	
	--1-11 TRYING A SMARTER METHOD TO PREVENT SELF HITTING PROJECTILES
	-- projectile:AddComponent("stats") --IT SHOULD ALREADY HAVE STATS
	projectile.components.stats.master = self.inst
	
	--2-23-17 --PREVENTS PROJECTILES FROM TEAMMATES FROM HITTING EACH OTHER
	if self.inst.components.stats.team then
		projectile.components.stats.team = self.inst.components.stats.team
	end

	projectile.components.projectilestats:SetProjectileSpeed(self.xprojectilespeed, self.yprojectilespeed)
	projectile.components.projectilestats.master = self.inst
	
	projectile.components.hitbox:SetSize(self.explosiverange, self.yexplosiverange)
	projectile.components.hitbox:SpawnHitbox(xhitboxoffset, yhitboxoffset, 0) --12-14-16
	for k,v in pairs (projectile.components.hitbox.hitboxtable) do
		v.components.hitboxes:RollToHit()
	end
	
end



--1-31-17 --NEVER QUITE FINISHED THESE, BUT THE AI SEEMS OKAY WITHOUT THEM
--THEY WERE MEANT TO BE BIG INVISIBLE (TO PLAYERS) DANGER ZONES PLACED IN BY MOVES THAT WOULD HAVE AN OBVIOUS "DON'T STAND THERE UNLESS YOU CRAVE DEATH" ZONE LIKE WICKER'S METEOR
function Hitbox:SpawnAIFearBox(box, xpos, ypos, ycenter, frames) 
	local owner = self.inst
	
	box:RemoveTag("hurtbox")
	box:RemoveTag("hitbox")
	box:AddTag("fearbox")
	box:AddComponent("stats")
	box:AddComponent("launchgravity")
	box:AddComponent("locomotor")
	box.components.hurtboxutil.owner = self.inst
	
	box.components.hurtboxes:UpdatePosition(1, xpos, ypos)
	box:DoPeriodicTask(0, function() 
		box.components.hurtboxes:UpdatePosition(1, xpos, ypos)  --(SIZE, X, Y)
	end)
	
	--BECAUSE APPARENTLY JUST THROWING XPOS AND YPOS IN DOESNT WORK
	box.components.hurtboxes.xoffset = xpos
	box.components.hurtboxes.yoffset = ypos
	
	box:DoTaskInTime(frames*FRAMES, function()
		box:Remove()
	end)
	
	table.insert(self.tempboxtable, box)
end


return Hitbox