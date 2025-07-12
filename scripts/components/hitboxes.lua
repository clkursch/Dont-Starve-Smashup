local Hitboxes = Class(function(self,inst)
	self.inst = inst
	self.explosiverange = 2
	self.explosivedamage = 2
	self.buildingdamage = 2
	
	self.xoffset = 0
	self.yoffset = 0
	self.zoffset = 0
	self.sizemult = 1
	
	self.xknockback = 1
	self.yknockback = 1
	self.highlight = 0
	self.blockdamage = 1
	self.blockstun = 1
	self.hitstun = 1
	
	self.lingerframes = 20
	self.active = true
	self.readyfornewmove = true
	
	self.perc = 1
	self.weight = 100
	self.dam = 12
	self.rawdam = 12
	self.scale = 90 / 100
	self.base = 32
	self.rate = 1
	self.kbangle = 45
	
	self.emphasis = 0
	self.priority = 0
	self.property = 0
	
	self.blocked = false
	
	self.xprojectilespeed = 2
	self.yprojectilespeed = 2
	
	-- self.noobtable = {}
	-- self.scrubtable = {} --lol
	--ALRIGHT ALRIGHT, CAN WE PLEASE GIVE THESE TABLES SOME ACTUAL NON-JOKE NAMES??
	self.pyschecktable = {} --THIS TABLE CONTAINS EVERY VALID PHYSICS OBJECT THIS HITBOX HAS COLLIDED WITH ON THIS FRAME.
	self.hitconfirmedtable = {} --CONTAINS ENTITIES THAT WE HAVE CONFIRMED HIT AND ARE GOING TO RECEIVE DAMAGE/KB AND STUFF ON THIS FRAME
	
	
	-------------------------
	self.visible = false --false --true
	
	self.extray = 0
	self.extrax = 0
	--self.inst.components.hurtboxutil.owner = nil --1-18-20 I WANT TO GET RID OF THIS AND MOVE IT OVER TO HURTBOXUTIL IF I CAN
	
	self.onhitfn = nil
	self.onposthitfn = nil
	self.oncollidefn = nil
	self.blockdam = 0 --THE REAL "EXTRA" BLOCKDAMAGE. THE OTHER ONE IS JUST BASED OFF RAW DAMAGE
	self.chipdam = nil
	
	self.suction = 0
	self.sucpx = 0
	self.sucpy = 0
	
	self.hitfxsprite = nil
	self.hitfxsound = nil
	
	self.ycenter = 0 --3-1 TO HELP POSITION HITSPLASHES NOW THAT HOTBOXES ARE ANCHORED FROM THE BOTTOM INSTEAD OF THE CENTER
	
	--1-1-2018 -NEW TO ACCOUNT FOR TILE OFFSET IN STAGE GENERATION -REUSEABLE
	-- if TheWorld.Map:GetTileCenterPoint(0, 0, 0) == 0 then --8-31-21 THAT WAS FOR X AXIS YOU FOOL
	self.ztileoffset = TheWorld.Map:GetTileAxisOffset("z")
	
	
	--5-13-18 -- HITBOXES CAN BE KILLED AT ANY TIME. BUT IF THE PHYSICS ENGINE DETECTS THEM COMING INTO CONTACT WITH A VALID TARGET, IT IS REVOKED UNTIL THE ATTACK FINISHES
	self.inst.permissiontodie = true
	self.lifespan = 1
	--5-31-18 --LETS TRY THIS TOO
	self.isactive = false --WHEN NOT ACTIVE, HITBOX WILL NOT COLLIDE OR DO ANYTHING, BUT HAVE NOT BEEN REMOVED YET
	--OKAY SO NOW THIS CAN BE FALSE BY DEFAULT, SO THAT HEARTBEATS WONT RUN IT BEFORE ITS STATS ARE INITIATED
	
	--6-7-18 --HITBOXES 3.0
	-- A HITBOX REGISTERING A VALID OPPONENT WILL NOW CANCEL A HITBOX'S ABILITY TO DIE DURING THAT FRAME
	-- THIS GREATLY REDUCES THE NUMBER OF PHANTOM-WHIFS FOR HITBOXES THAT ARE ONLY 1 FRAME LONG. BUT IS NOT 100% EFFETIVE
	-- FOR LAG SPIKES THAT ARE LONGER THAN 1 FRAME, IT IS STILL POSSIBLE FOR HITBOXES TO SPAWN AND DIE OFF BEFORE PHYSICS COLLISION EVER DETECTS ANYTHING
	--^^^ BOTTLECAPS NOW TAKE CARE OF THIS
	
	--5-13-18 IT BEGINS...
	self.inst:StartUpdatingComponent(self) --THIS TAKES TWO WHOLE FRAMES TO START UP??? --LET ANOTHER COMPONENT HANDLE THE IMPORTANT UPDATING
	
	--6-17-18 NOW CANCEL OUT THE HURTOXES'S COMPONENTS VERSION OF ONUPDATE, WHICH WILL OVERRIDE OUR OWN POSITION IF IT IS ALLOWED TO CONTINUE UPDATING
	if self.inst.components.hurtboxes then
		self.inst.components.hurtboxes:DisablePositionUpdating()
	end
end)


--5-13-18 WHEW, THAT WAS A LONG BREAK. BUT I LEARNED A LOT FROM THAT FIRST PERSON MOD. SPECIFICALLY, HOW TO PROPERLY USE ONUPDATE(DT)
-- function Hitboxes:OnUpdate(dt)
function Hitboxes:OnHeartbeat(dt) --5-31-18 OKAY. NEW IDEA. LETS MAKE HITBOX.LUA THE UPDATING COMPONENT THAT RUNS THE ONUPDATEFN FOR EACH HITBOX, SHALL WE?
	if not self.inst:IsValid() then return end --MY HEART ISNT READY TO BEAT YET (OR I'M ALREADY GONE). WAIT UNTIL I INITIALIZE
	
	if self.isactive then  --6-6-18 OKAY SO WE WANT UPDATEPOSITION TO RUN FIRST, BUT ONLY IF ITS ACTIVE... RIGHT? NO, ACTUALLY
		self:UpdatePosition()
	end
	self:CheckLifespan(dt)
end


--6-7-18 HERE, WE'LL INCLUDE THIS, BUT IT WILL ONLY RUN IN CASES WHERE THE OWNER HAS DIED AND ONLY THE HITBOX REMAINS
function Hitboxes:OnUpdate(dt)
	if not (self.inst.components.hurtboxutil.owner and self.inst.components.hurtboxutil.owner:IsValid()) then
		self.lifespan = 0 --BRING THIS DOWN TO 0. YOUR LIFE IS OVER
		self:CheckLifespan(dt)
	end
end


function Hitboxes:CheckLifespan(dt)
	if self.isactive then --ONLY COUNT DOWN IF ACTIVE
		self.lifespan = self.lifespan - (dt * 30)   --(dt*30) IS ALMOST ALWAYS 1, UNLESS THE GAME IS LAGGING A BIT, THEN IT WILL INCREASE TO COMPENSATE
	end
	
	if self.lifespan <= 0 then
		self.isactive = false
		-- print("READY TO DIE. IS BOTTBLECAP GONE?", self.inst.components.hurtboxutil.bottlecap)
		--ON THE NEXT FRAME, THEY HAVE PERMISSION TO DIE
		if self.inst.permissiontodie == true and (self.inst.components.hurtboxutil.bottlecap == nil) then
			self.inst:Remove() --SAFE TO REMOVE
		end
		self.inst.permissiontodie = true
	end
end


function Hitboxes:RemoveFromScrubTable(player) --12-15-16 FIXING A BUG THAT CAUSED PEIRCING PROJECTILES TO HIT EVERY PREVIOUSLY HIT PLAYER AGAIN EVERY TIME IT HIT A NEW ENEMY
	local player = player 						--MAJORBUG : PIERCING PROJECTILES WILL STILL SOMETIMES JUST NOT REGISTER HITTING OTHER PLAYERS AFTER HITTING ONE
												--DONT FORGET!!! TRY FIXING THIS FUNCTIONS TABLE REMOVAL, AS THIS IS NOT THE PROPER WAY TO DO IT!!!! I CANT DO IT NOW THOUGH, IM BUSY
	for k,v in pairs(self.hitconfirmedtable) do
		if v == player then
			self.hitconfirmedtable[k] = nil --2-16-17 OKAY, THIS IS THE CORRECT WAY --HMM, DOESNT FIX THE NOOB-OVERPOPULATION THOUGH... AH WHATEVER. I'LL COME BACK TO IT LATER
		end
	end
	
end




function Hitboxes:SetOwner(owner)
    self.inst.components.hurtboxutil.owner = owner
end

function Hitboxes:GetOwner()
    return self.inst.components.hurtboxutil.owner
end



function Hitboxes:UpdatePosition()
	
	local owner = self.inst.components.hurtboxutil.owner
	if owner and owner:IsValid() then
		
		local getdir = owner.components.launchgravity:GetRotationFunction()
		local x, y, z = owner.Transform:GetWorldPosition()
		-- z = 0 --10-21-20 MIGHT AS WELL PUT THEM ALL IN THE SAME PLACE
		z = self.ztileoffset --11-24-20 EXCEPT THE "SAME PLACE" ISNT ALWAYS THE SAME DEPENDING ON THE Z AXIS THE MAP GENERATES ON :/
		
		self.inst.Transform:SetPosition( x+(self.xoffset*self.inst.components.hurtboxutil.owner.components.launchgravity:GetRotationValue()), y+self.yoffset, z )
		
		--GIVE THEM A VELOCITY TO MATCH OUR OWNER'S
		local velx, vely = owner.Physics:GetVelocity()
		
		if owner.Physics:IsActive() then --ONLY APPLY VELOCITY IF PHYSICS IS ENABLED
			self.inst.Physics:SetVel(velx, vely, 0)
		else
			self.inst.Physics:SetVel(0, 0, 0)
		end
		
	else
		self.inst:Remove() --THAT OUGHTA DO THE TRICK
	end
end




--1-29 DETERMINES IF TARGET SHOULD RECEIVE DAMAGE (BASED ON IF THE HITBOX IS DISJOINTED OR NOT) AND THEN DOES THE DAMAGE
--[[
local function DetermineIfHitRRRRR(owner, instbox, opponent, opponentbox)
	
	--2-11-18 SOMETIMES INSTBOX IS GONE BEFORE THIS RUNS AND CRASHES THE GAME- FOR POWERSHEILDING VERY QUICK HITBOXES
	if not (instbox and instbox:IsValid()) then return end --
	
	--11-9-21 MAKING THIS CHECK PART OF THE WHOLE THING, SINCE IT SHOULD ALSO APPLY TO GROUND-ONLY ATTACKS
	if not opponentbox:HasTag("disjointed") then
		if (instbox:HasTag("groundedonly") and not opponent.components.launchgravity:GetIsAirborn()) then
			-- print("GROUND ONLY? ------", instbox:HasTag("groundedonly"))
			instbox.components.hitboxes:RollForDamage()
		elseif not instbox:HasTag("groundedonly") then
			-- if not opponentbox:HasTag("disjointed") then
			instbox.components.hitboxes:RollForDamage()
		end
	end
	--THIS DOESNT ACTUALLY RETURN ANYTHING ANYMORE. IT AUTOMATICALLY APPLIES DAMAGE, OR CANCELS ITSELF IF NOT APPLICABLE
	-- return is_not_self and doesnt_belongs_to_self and is_not_on_same_team and is_not_related
end
]]


--1-6-22 ALRIGHT, LETS REDO THIS JUNK FROM SCRATCH
local function DetermineIfHit(owner, instbox, opponent, opponentbox, scoreonly)
	if not (instbox and instbox:IsValid()) then return end --2-11-18 SOMETIMES INSTBOX IS GONE BEFORE THIS RUNS AND CRASHES THE GAME- FOR POWERSHEILDING VERY QUICK HITBOXES
	
	--INVALIDATORS
	if (instbox:HasTag("groundedonly") and opponent.components.launchgravity:GetIsAirborn()) then
		return end
	
	--IF THAT OPPONENTS WAS ALREADY SCORED BY US, ABANDON SHIP. WE SHOULDN'T BE ABLE TO HIT SOMEONE THAT'S ALREADY SCORED
	for k, v in pairs(owner.components.hitbox.scored) do
		if v == opponent then
			return end
	end
	
	--1-17-22 FINALLY SOME INVULN
	if opponent.components.stats:IsInvuln() then
		table.insert(owner.components.hitbox.scored, opponent)
		return end
	
	if not opponentbox:HasTag("disjointed") then
		table.insert(owner.components.hitbox.scored, opponent) --DO WE ONLY WANT TO SCORE PEOPLE WE "HIT?" HARD CALL...
		if scoreonly then return end --IF WE ONLY WANT TO SCORE IT, SKIP THE HITCONFIRM PART
		--IF WE'RE A PROJECTILE, MAKE US CLANK IF VALID.
		if opponent:HasTag("projectile") and (opponent.sg and not (opponent.sg:HasStateTag("noclanking"))) then
			instbox.components.hitboxes:ActivateClank(opponent, (instbox.components.hitboxes.dam+instbox.components.hitboxes.priority))
			opponent.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal") 
			opponent.components.hitbox:MakeFX("shockwave_sideNO", opponentbox.components.hitboxes.xoffset, opponentbox.components.hitboxes.yoffset, 0, 1, 1, 1, 4, 1)
			-- print("--FORCING A PROJECTILE TO CLANK ON TRADE--")
		else
			table.insert(instbox.components.hitboxes.hitconfirmedtable, opponent)
		end
		--THIS WOULD ONLY BE IF THEY HIT US, AND WE DON'T KNOW THAT YET
		--table.insert(opponentbox.components.hitboxes.hitconfirmedtable, owner)
		--table.insert(opponent.components.hitbox.scored, owner)
	end
	
	--instbox.components.hitboxes:RollForDamage()
end


--1-4-22 OKAY, WE NEED SOMETHING TO HANDLE WHEN AND HOW HITBOX COLLISIONS WORK
function Hitboxes:CollideHitboxes(myowner, myhitbox, myopponent, opponentbox) --WE'LL FIGURE IT OUT LATER...
	if not myhitbox:HasTag("disjointed") then
		table.insert(opponent.components.hitbox.scored, myowner) 
		table.insert(myowner.components.hitbox.scored, opponent)
	end
end



local function IsFoe(inst, object) --1-11 A MUCH NICER CONDENSED VERSION OF THE "ISNOTSELF" CHECKER 
	--1-13-20 I THINK IT'S TRYING TO DETECT PLAYERBOXES. SKIP THOSE
	if not object.components.hurtboxutil then 
		return end
	
	--TODOLIST  MAKE THESE THINGS JUST RETURN FALSE IF CONDITION IS NOT MET TO REDUCE LAG
	local opponent = object.components.hurtboxutil:GetOwner()
	local myself = inst.components.hurtboxutil.owner
	
	if opponent and opponent:IsValid() then
		local is_not_self = opponent ~= myself
		local doesnt_belongs_to_self = (myself.components.stats.master ~= opponent) and (opponent.components.stats.master ~= myself)
		local is_not_on_same_team = (myself.components.stats.team ~= opponent.components.stats.team) or not myself.components.stats.team
		local is_not_related = (myself.components.stats.master ~= opponent.components.stats.master) or not myself.components.stats.master or not opponent.components.stats.master
		-- local is_not_uncle = (myself.components.stats.master ~= opponent or myself ~= opponent.components.stats.master) or not myself.components.stats.master or not opponent.components.stats.master
		-- print("WHAT TEAM AM I ON??", myself.components.stats.team, opponent.components.stats.team)
		local is_tangible = not opponent.sg:HasStateTag("intangible") --8-22 ADDING INTANGIBILITY INTO THE MIX --I THINK THIS FIXED IT
		
			
		--2-11 NEW TEST FOR ROGUE HITBOXES THAT CAN HIT ANY OPPONENT EXCEPT THEIR ENTITY (OWNER)
		if inst:HasTag("rogue") then
			return is_not_self
		else
			return is_not_self and doesnt_belongs_to_self and is_not_on_same_team and is_not_related and is_tangible
		end
		
	else
		return false
	end
end

local function IsNotAirborn(inst) --1-23 FASTER WAY TO CHECK IF IS AIRBORN 
	local isair = inst.components.jumper and inst.components.launchgravity:GetIsAirborn()
	return not isair
end





--HITBOXES HAVE COLLIDED WITH A HURTBOX (OR HITBOX) AND NOW TO DETERMINE WHO GETS HIT AND WHO DOESNT
function Hitboxes:RollToHit()

	if not self.inst.components.hurtboxutil.owner:IsValid() then
		return end
	
	
	--FIRST, CHECK ALL HITBOX COLLISIONS
	for k, v in pairs(self.pyschecktable) do
		local object = v --IN THIS FN, "OBJECT" REFERS TO A HITSPHERE WE HAVE COLLIDED WITH
		
		--11-11-21 THIS BIT IS SUPPOSED TO ENSURE WE AREN'T RUNNING THIS FUNCTION FOR THE SAME FIGHTER MULTIPLE TIMES.
		--HOW DOES THIS EVEN WORK?? I DON'T KNOW IF I TRUST MY 2017 SELF. BUT IT SEEMS TO WORK...
		--[[
		for k, v in pairs(self.inst.components.hurtboxutil.owner.components.hitbox.scored) do --1-23 WOOPS FORGOT TO PUT THIS HERE TOO
			if v == object.components.hurtboxutil:GetOwner() or not IsFoe(self.inst, object) then --3-17, LETS SEE IF WE CANT REDUCE SOME OF THIS LAG
				self.pyschecktable = {} --11-4-17 DST CHANGE - TESTING SOME HITBOX CHANGES TO REDUCE NUMBER OF NOOBS. COULD HAVE DIRE CONSEQUENCES --OH SNAP I THINK IT WORKED
				return end
		end
		]]
		--1-6-22 IN FACT, LET ME REDO THIS RIGHT NOW. THIS IS ALL WRONG.
		--DON'T RUN ANYTHING ELSE FOR AN OPPONENT THAT HAS ALREADY BEEN SCORED VIA A PREVIOUS HITSPHERE
		for k2, v2 in pairs(self.inst.components.hurtboxutil.owner.components.hitbox.scored) do
			if v2 == object.components.hurtboxutil:GetOwner() then
				--OH LMAO IT TURNED OUT EXACTLY THE SAME EXCEPT WE DON'T CLEAR THE PYSCHECKTABLE. I THINK THIS IS WHAT WE WANT THOUGH
				return end
		end
		
		
		
		--1-6-22 OBSERVATIONS:
		--[[
			SOMETIMES IT KINDA SEEMS LIKE "DETERMINEIFHIT" SHOULD JUST RUN ONCE AT THE END OF THE FN REGARDLESS OF THE VARIABLES?
			SINCE IT LOOPS THROUGH IPAIRS FOR HITCONFIRMTABLE, IT WONT DO ANYTHING UNLESS WE ADDED TO THE TABLE ANYWAYS
			ALSO I SHOULD LOOK INTO REMOVING THE LOOP ABOVE. IT MIGHTBE CAUSING MULTIHIT ISSUES -ACTUALLY IT MIGHT JUST BE DOING NOTHING
			
			WE SHOULD PROBABLY ONLY CLEAR pyschecktable ON AN OVERPOWER/CLANK SO THAT THE FOLLOWING HURTBOX COLLISION CALCULATOR DOESN'T RUN ANYTHING AFTERWARDS
			-DO WE ONLY WANT TO SCORE OPPONENTS THAT WE HIT? HARD CALL... PROBABLY THOUGH?
			DON'T CLEAR THE PHYSCHECKTABLE FOR FORCE_TRADE MOVES. THESE MOVES (LIKE EXPLOSIONS N STUFF) SHOULD STILL BE ABLE TO HIT HURTBOXES IF THEY'VE TOUCHED HITBOXES
		
			-If we ARE A DISJOINTED NOCLANKING PROJECTILE, I THINK ID LIKE THAT TO COUNT AS UNSTOPPABLE EVEN WITH OVERPOWERING
		]]
		
		
		if object:HasTag("hitbox") and IsFoe(self.inst, object) then 
			local opponent = object.components.hurtboxutil:GetOwner()
			local myowner = self.inst.components.hurtboxutil.owner
			
			local htpriority = object.components.hitboxes.dam + object.components.hitboxes.priority
			local clashthreshold = 9
			
			--10-24-20 WE DONT NEED TO WORRY ABOUT CHECKING FOR NEGATIVES, OUR PROPERTY WAS CHANGED TO POSITIVE BEFORE SPAWNING
			--WOW I REALLY WISH I HAD COMMENTED THIS PART OF THE CODE WITH ACTUAL COMMENTS INSTEAD OF NONSENSE
			
			--10-25-20 CHECK IF THE MOVE IS "NO-CLANK" OR "SPECIAL" PROPERTY
			local self_forcetrade = false
			local opp_forcetrade = false
			if (myowner.sg and myowner.sg:HasStateTag("force_trade")) or self.property == 6 then
				self_forcetrade = true
			end
			if (opponent.sg and opponent.sg:HasStateTag("force_trade")) or object.components.hitboxes.property == 6 then
				opp_forcetrade = true
			end
			
			
			--9-9-18 --REFLECTABLES!! FOR PROJETILES ONLY! IF WE ARE A PROJECTILE AND 
			--GOOD LORD ITS BEEN OVER A YEAR SINCE IVE BEEN TO THIS PART OF TOWN. WHAT A MESS.
			if ((self.property == 7) and opponent:HasTag("projectile") and not opponent:HasTag("no_reflecting")) or (myowner:HasTag("projectile") and object.components.hitboxes.property == 7  and not myowner:HasTag("no_reflecting")) then
				
				--BUT STILL SCORE IT SO IT ISN'T REGISTERED AGAIN
				table.insert(opponent.components.hitbox.scored, myowner) 
				table.insert(myowner.components.hitbox.scored, opponent)		
				
				-- DetermineIfHit(myowner, self.inst, opponent, object) --inst, instbox, opponent, opponentbox
				
				if myowner:HasTag("projectile") and myowner.components.projectilestats then
					myowner.components.projectilestats:OnReflect(opponent) --newmaster
					-- table.insert(opponent.components.hitbox.scored, myowner) --BUT STILL SCORE IT SO IT ISN'T REGISTERED AGAIN	
					--9-9-18 -THIS... COULD HAVE SOME DIRE CONSEQUENCES. LIKE REFLECTED PIERCING PROJECTILES HITTING THE SAME PERSON MULTIPLE TIMES. BUT ITS JUST SUCH AN EASY SOLUTION
					myowner.components.hitbox.scored = {} --OPEN SEASON. EVERYONE IS VIABLE TO GET HIT AGAIN
				elseif opponent:HasTag("projectile") and opponent.components.projectilestats then
					opponent.components.projectilestats:OnReflect(myowner) --SEND IN THE MASTER, NOT THE PROJECTILE
					--9-9-18 -THIS... COULD HAVE SOME DIRE CONSEQUENCES. LIKE REFLECTED PIERCING PROJECTILES HITTING THE SAME PERSON MULTIPLE TIMES. BUT ITS JUST SUCH AN EASY SOLUTION
					opponent.components.hitbox.scored = {} --OPEN SEASON. EVERYONE IS VIABLE TO GET HIT AGAIN
				end

				--AND THEN DO THIS AGAIN, CUZ, YOU KNOW, WE JUST WIPED THEM CLEAN. AND WE DONT WANT THEM TO INSTANTLY HIT EACH OTHER AGAIN
				table.insert(opponent.components.hitbox.scored, myowner) 
				table.insert(myowner.components.hitbox.scored, opponent)		
				
				return end  --ACTUALLY, JUST CANCEL THE MOVE ALTOGETHER
			
			
			--11-8-16 WHEW, WHERE AM I?? I HAVENT BEEN HERE IN ALMOST A YEAR. ANYWAYS...
			--11-8-16 TEST TO SEE IF "SPECIAL" PROPERTY PREVENTS CLASHING. LOOKS LIKE I'M GONNA HAVE TO ADD-
			-- if self.property == 6 then
			-- if self.property == 6 and htpriority >= ((self.dam + self.priority)+clashthreshold) then --2-8-17 NO WAIT, MAKE SURE IT ISN'T OVERPOWERING FIRST
			-- if (self_forcetrade) and htpriority >= ((self.dam + self.priority)-clashthreshold) and not (self_forcetrade and opp_forcetrade) then --2-8-17 NO WAIT, MAKE SURE IT ISN'T OVERPOWERING FIRST
			--10-28-20 ^^^ SO IS THE VALUE CHECKER BAKCWARDS??? THIS PLACE SUCKS MAN, I NEED TO REWRITE THIS
			-- if (self.property == 6 or object.components.hitboxes.property == 6) and htpriority >= ((self.dam + self.priority)-clashthreshold) and not (self.property == 6 and object.components.hitboxes.property == 6) then --2-8-17 NO WAIT, MAKE SURE IT ISN'T OVERPOWERING FIRST
			--OK FORGET EVERYTHING UP THERE, LETS TRY THIS AGAIN BUT WE'LL DO THINGS RIGHT THIS TIME
			--10-28-20 THIS CHECKS TO SEE IF ANY FORCED-TRADES SHOULD BE IGNORED DUE TO BEING OVERPOWERED BY THE OPPOSING HITBOX
			
			--IF FORCE-TRADE
			if (self_forcetrade or opp_forcetrade) then
				
				--IF WE OVERPOWER THEM
				if htpriority <= ((self.dam + self.priority)-clashthreshold) then		
					--WE INSERT OURSELVES HERE BECAUSE WE DON'T WANT THAT HITBOX TO BE ABLE TO REGISTER US AGAIN VIA A DIFFERENT HURTBOX. WE ESSENTIALLY KILLED IT WHEN WE OVERPOWERED IT
					-- table.insert(self.hitconfirmedtable, opponent)
					-- table.insert(opponent.components.hitbox.scored, myowner)
					-- table.insert(myowner.components.hitbox.scored, opponent)
					
					DetermineIfHit(myowner, self.inst, opponent, object) --inst, instbox, opponent, opponentbox
					table.insert(opponent.components.hitbox.scored, myowner) --AND INSERT OURSELVES INTO THEIR SCORED LIST SO THEIR HITBOX DOESN'T HIT US
					opponent:PushEvent("overpowered")
					-- print("OUR FORCETRADE HITBOX OVERPOWERS YOURS", htpriority, ((self.dam + self.priority)-clashthreshold))
					

				
				--SAME AS ABOVE, BUT IF THE OPPONENTS HITBOX IS OVERPOWERING US --11-8-16 IF ITS SPECIAL-CLINKPROOF, JUST STRAIGHT UP IGNORE IT
				elseif htpriority >= ((self.dam + self.priority)+clashthreshold) then --2-8-17 NO WAIT, MAKE SURE IT ISN'T OVERPOWERING FIRST
					DetermineIfHit(opponent, object, myowner, self.inst) --CHECK TO SEE IF THEY HIT US
					table.insert(myowner.components.hitbox.scored, opponent) --BUT STILL SCORE IT SO IT ISN'T REGISTERED AGAIN
					myowner:PushEvent("overpowered")
					print("THEIR FORCETRADE HITBOX OVERPOWERED OURS")
					
				--10-24-20 WHAT IS EVEN GOING ON HERE?? I JUST WANT MY SPECIALBOXES TO TRADE WITH EACH OTHER
				else --NO OVERPOWERING, WE JUST TRADE NOW
					--SO WE JUST TRADE, I GUESS. DON'T WORRY ABOUT CHECKING FOR DISJOINTED, THAT HAPPENS DOWN THERE SOMEWHERE
					-- table.insert(self.hitconfirmedtable, opponent)
					-- table.insert(object.components.hitboxes.hitconfirmedtable, myowner)
					-- table.insert(opponent.components.hitbox.scored, myowner)
					-- table.insert(myowner.components.hitbox.scored, opponent)
					
					DetermineIfHit(myowner, self.inst, opponent, object) --inst, instbox, opponent, opponentbox
					DetermineIfHit(opponent, object, myowner, self.inst)
					-- print("FORCETRADE COLLIDE")
				end
				
			--AND IF NEITHER OF THEM ARE SPECIAL-TYPES, JUST GO ON AS USUAL
			else --if object.components.hitboxes.property ~= 6 and self.property ~= 6 then --11-8-16 HONESTY NOT EVEN SURE IF THIS LINE IS NECESARRY NOW THAT PRIORITY/PROPERTY IS FIXED. BUT IT WORKS, SO LETS JUST LEAVE IT
			
				

				--1-29 ADDIN ONE GIANT IS-NOT-AIRBORN CHECK
				if (IsNotAirborn(myowner) and IsNotAirborn(opponent)) then --and not (myowner:HasTag("projectile") or opponent:HasTag("projectile")) then

					if htpriority <= (self.dam + self.priority) + 9 and htpriority >= (self.dam + self.priority) - 9 then --WITHIN CLASH RANGE --ADDING AND ELSE
						--2-8-17 FOR SPECIAL-NOCLANKS (PROPERTY = 6)  ACT AS IF ALWAYS AERIAL, EVEN ON GROUND. !!CANNOT CLANK!!  NOT THE SAME AS NOCLANK (BOWSERS USMASH, WHICH CAN "CLANK" BUT ANIMATIONS KEEP PLAYING) THEY ALWAYS TRADE, UNLESS OVERPOWERED.   
						--DISJOINTED SPECIAL-CLANK HITBOXES CAN NEVER TAKE DAMAGE. IF OVERPOWERED, THEIR HITOXES ARE DISABLED (ONLY IF OVERPOWERED, NOT IF THEIR DAMAGE IS EQUAL)   SPECIAL-DISJOINTED VS SPECIAL-DISJOINTED; NOTHING HAPPENS. BUT IF THEY TOUCH FLESH THEY WILL STILL DAMAGE
						--MOVED UP HERE SO IT HAPPENS BEFORE THEY ALL GET CANCLED
						myowner.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal")  --12-14 A MUCH BETTER CLANK SOUND. JUST USE THIS ONE
						myowner.components.hitbox:MakeFX("shockwave_sideNO", self.xoffset, self.yoffset, 0, 1, 1, 1, 4, 1)
						--ARE YOU KIDDING ME WITH THIS BS?!? THE ONLY THING CAUSING THE PROBLEM IS THE FILE NAME?? "shockwave_side" JUST IS NOT A VALID FILE NAME??? WHY DO YOU DO THIS TO ME 
						-- self.inst.components.hitbox:MakeFX("ground_bounce_000", 0, 0, 1, 1, 1, 1, 8, 1) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
						
						if myowner.sg and not (myowner.sg:HasStateTag("noclanking")) then
							self:ActivateClank(myowner, (self.dam+self.priority))
						end
						
						if opponent.sg and not (opponent.sg:HasStateTag("noclanking")) then
							self:ActivateClank(opponent, (self.dam+self.priority)) --(inst, rebound)
						end
						
						DetermineIfHit(myowner, self.inst, opponent, object, true) --PASSING IN TRUE FOR CLANK-ONLY
						DetermineIfHit(opponent, object, myowner, self.inst, true) --1-6-22
						-- print("GROUNDED CLANK")
						--[[ 1-6-22 THE ABOVE BLOCK SHOULD COVER PROJECTILES FOR THIS
						if myowner:HasTag("projectile") and opponent:HasTag("projectile") then
							self:ActivateClank(myowner, (self.dam+self.priority)) --(inst, rebound)
							self:ActivateClank(opponent, (self.dam+self.priority))
						end
						if myowner:HasTag("projectile") and not opponent:HasTag("projectile") then
							self:ActivateClank(myowner, (self.dam+self.priority)) --(inst, rebound)
							self:ActivateClank(opponent, (self.dam+self.priority))
						end
						myowner.SoundEmitter:PlaySound("dontstarve/impacts/impact_metal_armour_sharp")
						myowner.SoundEmitter:PlaySound("dontstarve/impacts/impact_metal_armour_dull")	 --HIGHER METAL BONK SOUND	
						
						-- ents = TheSim:FindEntities(0, 0, 0, 0, {"waldo"}) --THEY'LL NEVER FIND HIM
						-- table.insert(opponent.components.hitbox.scored, myowner)
						-- table.insert(myowner.components.hitbox.scored, opponent)
						]]
					
					
					--HITBOX OVERPOWERED. CANCEL THE OPPOSING HITBOX AND PLACE OURSELVES ON THE OPPONENT'S SCORED LIST
					elseif htpriority <= ((self.dam + self.priority)-clashthreshold) then
						--SPECIFICALLY PROJECTILES GET "CLANKED" WHEN THEY ARE OVERPOWERED
						-- if opponent:HasTag("projectile") and (opponent.sg and not (opponent.sg:HasStateTag("noclanking"))) then --5-4-20 ADDING PROJECTILES; TREAT OVERPOWERING PROJECTILES AS A CLANK
							-- self:ActivateClank(opponent, (self.dam+self.priority))
							-- opponent.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal") 
							-- opponent.components.hitbox:MakeFX("shockwave_sideNO", object.components.hitboxes.xoffset, object.components.hitboxes.yoffset, 0, 1, 1, 1, 4, 1)
						-- end
						
						-- table.insert(self.hitconfirmedtable, opponent)
						DetermineIfHit(myowner, self.inst, opponent, object)
						table.insert(opponent.components.hitbox.scored, myowner) --WE DON'T EVEN CHECK TO SEE IF IT'S DISJOINTED. WE OVERPOWERED IT SO WE JUST DO IT
						opponent:PushEvent("overpowered") --5-5-20
						opponent.components.hitbox:FinishMove()
						-- print("OUR GROUNDED HITBOX OVERPOWERED THEM")

					--WHEN DOES THIS EVEN HAPPEN? PRETTY SURE ALMOST ALL OPPONENTS WILL HAVE AN SG
					elseif htpriority >= ((self.dam + self.priority)+clashthreshold) then --+clashthreshold
						print("THEIR GROUNDED HITBOX OVERPOWERED OURS")
						self:ActivateClank(myowner, (self.dam+self.priority))
					end
				
				
					-- self.enemy = opponent
					-- self.pyschecktable = {}
				
				
				--THIS IS A TRADE
				else --FOR IF AIRBORN
					--6-11-20 AIRBORN CLANKS ARE STILL POSSIBLE! SPECIFICALLY FOR HITTING PROJECTILES WITH DISJOINTED AIRIALS
					--[[ 1-6-22 NICE. NEW SYSTEMS SHOULD HANDLE ALL OF THIS
					if myowner:HasTag("projectile") or opponent:HasTag("projectile") then
						--ITS OK TO SEND THE CLANK EVENT TO BOTH OF THEM BECAUSE THE AIREAL OPPONENT SHOULDN'T BE EFFECTED IF IN THE AIR
						myowner.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal") 
						myowner.components.hitbox:MakeFX("shockwave_sideNO", self.xoffset, self.yoffset, 0, 1, 1, 1, 4, 1)
						self:ActivateClank(myowner, (self.dam+self.priority)) --(inst, rebound)
						self:ActivateClank(opponent, (self.dam+self.priority))
					end
				
					-- print("AIR TRADE", self.inst)
					table.insert(self.hitconfirmedtable, opponent)
					table.insert(object.components.hitboxes.hitconfirmedtable, myowner)
					
					table.insert(opponent.components.hitbox.scored, myowner)
					table.insert(myowner.components.hitbox.scored, opponent)
					]]
					DetermineIfHit(myowner, self.inst, opponent, object) --inst, instbox, opponent, opponentbox
					DetermineIfHit(opponent, object, myowner, self.inst)
					-- print("NORMAL AIRBORN TRADE")
				end
			
			end
		end
	end
		
	
	--NEXT, IF WE HAVEN'T ALREADY BEEN SCORED, CHECK ALL HURTBOX COLLISIONS
	for k, v in pairs(self.pyschecktable) do
		local object = v
		if object:HasTag("hurtbox") and IsFoe(self.inst, object) then 
			local opponent = object.components.hurtboxutil:GetOwner()
			local abort = false --12-16-16 
			for k, v in pairs(self.inst.components.hurtboxutil.owner.components.hitbox.scored) do 
				if v == object.components.hurtboxutil:GetOwner() then
					-- return end  --4-20 I THINK THIS MIGHT BE CAUSING THE LIST TO END EARLY CAUSING ONLY ONE PERSON TO GET HIT AT TIMES. --FIXED!!!!
					abort = true --AAAAAAAAY IT WORKED!!!
				end
			end
			
			if not abort then
				-- table.insert(self.hitconfirmedtable, opponent)
				-- table.insert(self.inst.components.hurtboxutil.owner.components.hitbox.scored, opponent) --OHHHH HERES WHERE I WENT WRONG
				
				DetermineIfHit(self.inst.components.hurtboxutil.owner, self.inst, opponent, object) --inst, instbox, opponent, opponentbox
				-- print("HITTING A NORMAL HURTBOX")
			end
		end
	end


	-- WHAT A MESS
	-- self.pyschecktable = {} --1-15
	
	--1-6-22 THE WALLUPDATER IN MODMAIN WILL ALWAYS RUN THIS AFTER 
	-- self:RollForDamage()
end






--1-15 MAKING THIS ON-TICK FUNCTION HANDLE ALL ATTACKING/DAMAGING TO TEST FOR OVERLAPPING BOXES
function Hitboxes:NextStep(inst, object)
	if not self.inst.components.hurtboxutil.owner:IsValid() or (not object) or (not object:IsValid()) or (not object.components.hurtboxutil) then --1-25 ADDING OBJECT TESTED BECAUSE IT CRASHES SOMETIMES
		return end
	
	--1-6-22 TAKE IT ONE STEP FURTHER. DON'T REGISTER THE SAME PHYSICS OBJECT MULTIPLE TIMES IN ONE FRAME
	-- for k, v in pairs(self.pyschecktable) do
		-- if v == object then
			-- return end
	-- end
	
	--THIS IS SO WE DON'T REGISTER THE A PHYSICS OBJECT BELONGING TO AN OPPONENT WE'VE ALREADY SCORED
	for k, v in pairs(self.inst.components.hurtboxutil.owner.components.hitbox.scored) do
		if v == object.components.hurtboxutil:GetOwner() then
			return end
	end
	
	
	--4-6-19 PICKLE THESE... THESE IF-CASES ARE BOTH THE SAME. I DON'T THINK YOU NEED THESE. THIS WOULD PROBABLY SAVE A LOT OF LAG.
	if object:HasTag("hitbox") and IsFoe(self.inst, object) then --1-18 LETS TRY SELF.INST INSTEAD OF JUST INST
		table.insert(self.pyschecktable, object)
	elseif object:HasTag("hurtbox") and IsFoe(self.inst, object) then
		table.insert(self.pyschecktable, object)
		--6-6-18 -- IF AN OPPONENT IS REGISTERED ON THIS FRAME, FORCE THE HITBOX'S DEATH TO BE DELAYED BY 1 FRAME
		self.inst.permissiontodie = false  --DOES THIS ACTUALLY HELP?? IDRK AT THIS POINT
	end
end




function Hitboxes:Init()

	--6-6-18 ACTUALLY, WHY DONT WE JUST... REPLACE IT WITH THIS ANYWAYS. THIS IS MUCH SIMPLER -DST CHANGE
	self.inst.Physics:SetCollisionCallback(function(inst, object) --NOW THAT I KNOW WHAT I'M DOING, LETS GET A LITTLE FANCIER~
		-- self.permissiontodie = false --!! BRILLIANT! IF IT HAS TOUCHED ANYONE AT ALL DURING THE PREVIOUS FRAME. DONT DELETE IT
		self:NextStep(inst, object) --THIS IS PROBABLY REALLY UNNESISARY BUT IM SCARED TO CHANGE THE WAY IT WORKS
	end)
	
	
	if not self.lingerframes then 
		self.lingerframes = 1
	end
	
	-- self.inst:DoTaskInTime((self.lingerframes+0)*FRAMES, function() ---1-11 ADDING +1 TO THE LINGER FRAMES BECAUSE I THINK IT TAKES 1 FRAME TO SPAWN THE HITBOX
	--5-13-18 NO NO NO, THIS WON'T DO. NO TASKINTIMES TO DESTROY OUT HITBOXES. USE AN ONUPDATE INSTEAD
	self.lifespan = self.lingerframes + 0 --5-13-18
	
	--5-31-18 BUT ONUPDATE DOESNT START UNTIL... TWO FRAMES AFTER COMPONENT IS ADDED? THATS NOT COOL. PRETTY USELESS, IN FACT.
	-- self:OnUpdate(1/30)
	
	self.isactive = true --5-31-18 TELL OUR HEART WE'RE READY TO START BEATING
	self:RollToHit()  --YOU KNOW WHAT? IM READY. ROLL FOR DAMAGE TO COVER FOR THAT 1 FRAME STARTUP DELAY
end








--8-26  --NEW AND IMPROVED CLANK FUNCTION THAT INCLUDES ARTIFICIAL HITLAG  --REALLY HOPE THIS DOESNT CAUSE PROBLEMS WITH REAL HITLAG LATER ON
function Hitboxes:ActivateClank(inst, reboundinput)
	--8-25 EXPERIMENTAL BLANK HITLAG TESTING
	self:DoBlankHitlag(inst)
	
	inst:DoTaskInTime(((reboundinput / 2) - 1)*FRAMES, function()
		inst:PushEvent("clank", {rebound = (reboundinput)}) --IT SEEMS TO WORK
	end)
	
end



--8-25 A FUNCTION FOR DOING HITLAG WITHOUT THERE NEEDING TO BE AN ACTUAL HIT
function Hitboxes:DoBlankHitlag(myself, ownerzzz) --CHANGING V TO myenemy
				
	if myself.myhitlagendtask then 
		myself.myhitlagendtask:Cancel()
	end
	
	self.hitlag = ((((self.dam + self.emphasis)/1.5) + 3) / 2)
	local hitlagframes = math.floor(self.hitlag+0.5)*FRAMES
	
	myself:PauseStateGraph(hitlagframes)  
	myself:AddTag("hitpaused") 
	myself.AnimState:Pause()   --10-18 CHANGING THESE 4 myenemyS TO SELF.INST
	myself.Physics:SetActive(false)
	self.hitlag = self.hitlag - 1
	
	
	myself.myhitlagendtask = myself:DoTaskInTime(hitlagframes, function()
		myself.Physics:SetActive(true) 
		myself:UnPauseStateGraph()
		myself.AnimState:Resume()
		
		myself:DoTaskInTime(0, function() 
			myself:RemoveTag("hitpaused")
			myself:RemoveTag("hitfrozen")
		end)
		
		if myself:HasTag("deleteonhit") then
			myself:Remove()
		end
	end)
end




function Hitboxes:SetPriority(priority)
	self.priority = priority
end

function Hitboxes:MakeDisjointed()
	self.property = 1
end







-- THIS FUNCTION IS A DUPLICATE!!! YOU SHOULD USE THE ONE IN HITBOX.LUA INSTEAD
--4-17 !!!!NOTE TO SELF!!!! -- I SHOULD REALLY GET RID OF THIS AND JUST USE THE GOOD ONE IN REGULAR HITBOX.LUA
function Hitboxes:MakeFX(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b)
	
	--11-24-20 SETTING BLANK ANIMATIONS FOR HITSPLASHES IS FINE, BUT IT MAKES THE DEBUG LOG WHINE AND ITS ANNOYING, SO LETS TURN IT OFF.
	if fxname == "none" or fxname == "no_anim" or fxname == "blank" then
		return end --JUST DONT SPAWN THE FX. THEN IT WONT WHINE
	
	local fx = SpawnPrefab("fight_fx")
	local pos = Vector3(self.inst.components.hurtboxutil.owner.Transform:GetWorldPosition())
	local pointdir = 1
	
	if not r then
		r = 0
		g = 0
		b = 0
	end
	
	
	if fxname == "shovel_dirt" then
		fx.AnimState:SetBank("shovel_dirt")
		fx.AnimState:SetBuild("shovel_dirt")
		fxname = "anim"
	end
	if fxname == "ground_crack" then
		fx.AnimState:SetOrientation( ANIM_ORIENTATION.OnGround )
	end
	
	if not glow then
		glow = 0
	end
	
	local getdir = self.inst.components.hurtboxutil.owner.components.launchgravity:GetRotationFunction()
	
	if getdir == "left" then 
		xoffset = xoffset
		pointdir = -12
		if xsize <= 0 then
			pointdir = 12
		end
	else
		xoffset = -xoffset
		pointdir = 12
		if xsize <= 0 then
			pointdir = -12
		end
	end
	

    fx.AnimState:PlayAnimation(fxname)
	fx.AnimState:SetMultColour((alpha + r),(alpha + g),(alpha + b),alpha)
	fx.AnimState:SetAddColour(glow,glow,glow,glow)
	
	
	--JUST DISABLING FOR NOW SO IT DOESNT GET ANNOYING
	fx.Transform:SetPosition((pos.x + (xoffset* 1)), (pos.y + yoffset + 0), (pos.z + zoffset))  --10-18, ADDING +1 TO Y OFFSET TO MAKE UP FOR FEET HURTBOX
	fx:ForceFacePoint((pos.x - pointdir), (pos.y + yoffset), (pos.z)) 
	fx.Transform:SetScale(xsize,ysize,1)
	
	fx:DoTaskInTime(duration*FRAMES, function(inst)
		fx.AnimState:SetMultColour(((alpha+r)/3),((alpha+g)/3),((alpha+b)/3),(alpha /3)) --NOT QUITE... --EH, LETS GO WITH IT. THIS FILE ONLY HANDLES FX FOR HITSPLASHES ANYWAYS
		local gv = 0
		inst.AnimState:SetAddColour(gv,gv,gv,gv) --JUST MAKE A 4TH SPRITE ALREADY. IT'LL LOOK GOOD
	end)
	fx:DoTaskInTime((duration+2)*FRAMES, function(inst)
		fx:Remove()
	end)
end



function Hitboxes:PlayHitsound(inst, quakesize)
	
	
	if self.hitfxsound and self.hitfxsound == "none" then
		--JUST SO WE DON'T FILL THE DEBUG LOG WITH ANNOYING FMOD ERRORS
		return end
		
	if self.hitfxsound then
		-- print("hitfxsound")
		inst.SoundEmitter:PlaySound(self.hitfxsound)
		return end
		
	--12-22-18 -BEFORE TODAY, SOUND WAS BASED ON LAUNCH SPEED. NOW I WANT IT BASED ON DAMAGE
	local hitsize = quakesize or self.hitstun --HOW HEAVY WAS THE HIT?
	
	if hitsize <= 0.18 then --12  --0.18
		-- inst.SoundEmitter:PlaySound("dontstarve/common/place_ground") --MAYBE FOR SHEILDS  --ACTUALLY THIS IS A GREAT SMALL HIT SOUND --PERFECT SMALL SLICE SOUND!!
		-- inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_impact_sleep") --12-16-18 WE ACTUALLY USED TO USE BOTH OF THE ABOVE AT ONCE
		inst.SoundEmitter:PlaySound("smash_sounds/punchsounds/punchtiny") --12-16-18 LETS TRY OUT THESE CUSTOM NEW HITSOUNDS
		
	elseif hitsize <= 0.30 then --18 --0.24
		-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_impact")
		inst.SoundEmitter:PlaySound("smash_sounds/punchsounds/punchsmall")
		
	elseif hitsize <= 0.40 then --28  --0.32
		-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_impact")
		inst.SoundEmitter:PlaySound("smash_sounds/punchsounds/punchhit4")
		
	elseif hitsize <= 0.50 and self.hitstun <= 46 then --34  --0.40
		-- inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
		inst.SoundEmitter:PlaySound("smash_sounds/punchsounds/punchhuge")
		
	else
		--if self.hitstun >= 50 then	--THIS BIG BOY SOUND ONLY GETS TO PLAY IF IT HITS HARD AND FLYS HARD
		--	inst.SoundEmitter:PlaySound("smash_sounds/smashhit/smashhit1") --THE BIG BOY HIT
		--else
		--	inst.SoundEmitter:PlaySound("smash_sounds/punchsounds/punchhuge")
		--end
		--10-1-21 EH, IT WAS A BIT MUCH... LETS JUST KEEP IT SIMPLE
		inst.SoundEmitter:PlaySound("smash_sounds/punchsounds/punchhuge")
	end
end



--2-29 maybe i should start making hitbox features as outside functions instead of cramming them all into one function
-- SUCTION --2-29
function Hitboxes:DoSuction(power, xpoint, ypoint, myself, v)
	
	if not self.inst.components.hurtboxutil.owner:IsValid() then
		return end
	
	local myx, myy, myz = self.inst.components.hurtboxutil.owner.Transform:GetWorldPosition()
	local theirx, theiry = v.Transform:GetWorldPosition()
	
	--DST CHANGE 10-28-17- IF POINTS ARE SET AS NIL, DONT DO ANY SUCTION ON THAT AXIS - REUSEABLE
	if xpoint == nil then
		--TRICK THE CALCULATOR INTO THINKING THEY ARE ALREADY AS CLOSE AS THEY CAN GET
		myx = theirx
		xpoint = 0
	end
	if ypoint == nil then
		myy = theiry  --PRETTY SURE I SPELLED "THIER" WRONG
		ypoint = 0
	end
	
	myx = myx + (xpoint*self.inst.components.hurtboxutil.owner.components.launchgravity:GetRotationValue()) --7-29-17 FIX
	myy = myy + ypoint + (v.components.stats.height / 2)
	
	local suctionpower = self.suction
	
	--7-9-17 --SUCTION WHILE BLOCKING IS TOO HIGH
	if v.sg:HasStateTag("blocking") or v.sg:HasStateTag("armor") or v:HasTag("armor") then
		suctionpower = 0 --12-9-17 OKAY, JABS AND STUFF ARE TAKING TOO MUCH SUCTION. IM REMOVING IT ALTOGETHER --REUSEABLE	
		return end --8-19-18 -IN FACT, IF THIS HAPPENS, DONT RUNNY ANY SORT OF SETPOSITION AT ALL. IT COULD CAUSE AREAL ISSUES, LIKE WITH THE QUEEN
	
	
	local xpoint = (myx - theirx) / (1/suctionpower) 
	local ypoint = (myy - theiry) / (1/suctionpower) 
	
	if not v.components.launchgravity:GetIsAirborn() then --8-19 FIXED IT c:
		ypoint = theiry
	end
	-- print("MAKE LIKE A VACCUM", power, xpoint, ypoint)
	v.Transform:SetPosition((theirx+(xpoint*1)), (theiry + ypoint), myz)
end




--10-28-16 A STUPID ATTEMPT TO MAKE ATTACKER SPRITES APPEAR ON TOP OF ENEMY SPRITES DURING HITLAG
--IT WORKS I GUESS. I STILL WISH THERE WAS A WAY TO JUST FLAT OUT SWAP WHO SHOWS UP IN FRONT AFTER LANDING A HIT  --(I KNOW OF OTHER WAYS NOW. BUT THIS IS HONESTLY FINE)
function Hitboxes:OverlayAttacker(v)
	
	if not v:IsValid() then
		return end
		
	--10-19-20 WILL PROBABLY ONLY BE USED FOR SPIDER DENS, BUT MIGHT AS WELL MAKE IT A UNIVERSAL TAG
	if v:HasTag("ignore_overlay") then
		return end
	
	local theirx, theiry = v.Transform:GetWorldPosition()
	v.Transform:SetPosition(theirx, theiry, -0.2+self.ztileoffset) --MAJOR DST CHANGE!!! REPLACING THE 5.2 WITH 0.2 AS ANCHOR IS NOW AT 000
end

function Hitboxes:UnOverlayAttacker(v)
	if not v:IsValid() then
		return end
	
	if v:HasTag("ignore_overlay") then
		return end
		
	local theirx, theiry = v.Transform:GetWorldPosition()
	v.Transform:SetPosition(theirx, theiry, 0+self.ztileoffset)
end



--1-20-17 FINALLY, ONE EASY-ACCES UNIVERSAL FUNCT  
--TURN TO FACE THE ATTACKER WHEN HIT
function Hitboxes:FaceAttacker(v)
	--UNLESS YOU HAVE ARMOR. THEN DON'T BUDGE
	if (v.sg:HasStateTag("armor") or v:HasTag("armor") or not self.inst.components.hurtboxutil.owner:IsValid()) then
		return end
		
	local angle = self.kbangle --MAYBE ANOTHER DAY...
	
	-- if not (v.sg:HasStateTag("armor") or v:HasTag("armor")) and angle ~= 366 then --12-15 ADDED CHECK FOR AUTOLINK ANGLE --WOW REALLY??? I !HAVE! TO USE "~=" INSTEAT OF "NOT =="
	if angle == 366 then --CHECK FOR AUTOLINK ANGLE
		self.inst.components.hurtboxutil.owner.components.locomotor:FaceAwayWithMe(v)
	else
		if not self.blocked and (((self.inst.components.hurtboxutil.owner.sg and self.inst.components.hurtboxutil.owner.sg:HasStateTag("force_direction")) or self.inst.components.hurtboxutil.owner:HasTag("force_direction")) and not (angle >= 90 and angle <= 270)) then -- 12-30
			self.inst.components.hurtboxutil.owner.components.locomotor:FaceAwayWithMe(v) --WAIT... SHOULDNT THIS BE "V" INSTEAD OF "self.inst.components.hurtboxutil.owner"?... --NO NEVERMIND. ITS SELF.INST AND PASSES V INTO LOCOMOTOR
		else
			if not self.blocked then
				v:ForceFacePoint(self.inst.components.hurtboxutil.owner.Transform:GetWorldPosition())
			end
		end
	end
end



--THIS FUNCTION APPLIES ANY DAMAGE/KNOCKBACK/HITSTUN TASKS AND SUCH THAT ARE ASSOCIATED WITH GETTING HIT
function Hitboxes:RollForDamage()  --11-8-20 RENAMED TO MAKE MORE SENSE
	
	if self.readyfornewmove and not self.active then
		self.active = true
	end
	
	self.pyschecktable = {} --1-6-22 MOVING DOWN HERE
	
	local ldamage = self.dam --I GUESS WE CAN KEEP THIS ONE
    for k,v in pairs(self.hitconfirmedtable) do
	-- if not v:HasTag("waldo") then --11-8-20 HOW LONG HAS THIS BEEN HERE? ._.
	
	--1-6-22 DOING THE HIT! REMOVE FROM THE HITCONFIRM TABLE SO WE DON'T DO IT AGAIN
	self:RemoveFromScrubTable(v)
	
	if not v.sg or not v.sg:HasStateTag("intangible") then --and self.active then
		if self.inst.components.hurtboxutil.owner.components.stats and not (v:HasTag("projectile") or v:HasTag("notarget")) then --7-15-18 DONT SET PROJECTILES AS TARGETS --REUSEABLE
			self.inst.components.hurtboxutil.owner.components.stats.opponent = v
		end
		
		--9-12-17 YET ANOTHER ATTEMPT TO PREVENT MAXCLONES FROM HITING AT THE SAME TIME. I WISH I COULD HAVE DONE THIS UP THERE BUT I GUESS THIS WILL HAVE TO DO
		if self.inst.components.hurtboxutil.owner.components.stats.hitscorepartner then
		local payrent = false --DETERMINES WETHER ROOMATE SHOULD IGNORE THEIR HURTBOXES
		local myopponent = v
		
		for l, w in pairs(self.inst.components.hurtboxutil.owner.components.stats.hitscorepartner.components.hitbox.scored) do --1-23 HOW ABOUT THIS?
			local roommateopponent = w
			if myopponent == roommateopponent then --IF YOUR HITSCORE PARTNER ALSO HAS THIS ENTITY SCORED- CANCEL THE ATTACK
				if self.inst.components.hurtboxutil.owner.sg.currentstate.name == self.inst.components.hurtboxutil.owner.components.stats.hitscorepartner.sg.currentstate.name then
					-- print("HEY WE BOTH HAVE THE SAME ENEMY") --BUT ONLY IF YOU AND YOUR PARTNER ARE USING THE SAME ATTACK
					payrent = true
				end
			end
		end
		
		if payrent == true then
			-- print("YOUR RENT IS OVERDUE")
			table.insert(self.inst.components.hurtboxutil.owner.components.hitbox.scored, v) --SCORE IT TOO SO IT DOESN'T KEEP CHECKING IT
			return end
		end
		
		--1-2-22 PROJECTILES AREN'T FIGHTERS, BUT SOME OF THEM MIGHT HAVE ONHIT FUNCTIONS THEY NEED TO RUN.
		if not v:HasTag("fighter") then
			-- print("--PROJECTILE IS MANUALLY ACTIVATED BY NAMAGE--")
			-- v:PushEvent("on_hitted", {hitbox = self.inst})
			self:ActivateClank(v, (self.dam+self.priority)) --THIS MIGHT BE MORE APPROPRIATE
			self.inst.components.hurtboxutil.owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal") 
			self.inst.components.hurtboxutil.owner.components.hitbox:MakeFX("shockwave_sideNO", self.xoffset, self.yoffset, 0, 1, 1, 1, 4, 1)
		end
		
		if v~=self.inst and v:HasTag("fighter") and self.active then --and self.lingerframes >= 0 @@@  --and not v.sg:HasStateTag("intangible") then
			
			self.lingerframes = 0
			
            -- if v.components.workable and not v:HasTag("busy") then --Haaaaaaack!
                -- v.components.workable:WorkedBy(self.inst, self.buildingdamage)   --1-15-17 AWWW, ISN'T THIS ADORABLE. SOME OF THE LAST REMNANTS OF EXPLOSIVES.LUA THAT THE COMPONENT STARTED OUT AS
            -- elseif v.components.burnable and not v.components.fueled and self.lightonexplode then
                -- --v.components.burnable:Ignite()    --OKAY WE REALLY DONT NEED TO SET EVERYTHING ON FIRE
            -- end

			--5-28-20 HEY IF WHATEVER WE'RE HITTING DOESN'T HAVE A PERCENT COMPONENT, MAYBE DONT DO ANY OF THIS
			if not v.components.percent then
				print("TARGET DOESNT HAVE PERCENT. ABORTING HIT")
				return end
			
			
			
			self.inst.components.hurtboxutil.owner.components.stats.lasttarget = v --7-10 TO ADD NEWSTATE EVENT PUSHER TO TELL AI WHEN TO PUNISH A BLOCKED ATTACK  --SEEMS TO CRASH IF CPU ATTACKS FIRST???? THEFIXLIST
			
			
			--3-22 A BETTER UNIVERSAL "ARE THEY BLOCKING" VALUE TO BE USED
			if v.sg and v.sg:HasStateTag("blocking") then
				self.blocked = true
				v:PushEvent("hit_shield")
			else
				self.blocked = false
			end
			
			
			--3-18 --THIS IS JUST A DUPLICATE OF WHAT TESTS IF THE ATTACK WAS BLOCKED OR NOT. IF CHANGED, MAKE SURE TO CHANGE THE ONE DOWN THERE TOO
			if v.components.hurtboxes and v~=self.inst and not v.sg:HasStateTag("blocking") and not v.sg:HasStateTag("intangible") then  
				v.components.percent:DoDamage(-ldamage) --
				v:PushEvent("on_hitted", {hitbox = self.inst}) --1-15-17 ADDING REFS TO THE ENTIRE HITBOX TO THESE SO DATA CAN BE GRABBED FROM THEM
				v:PushEvent("on_punished") --REFERS TO BEING HIT OR GRABBED (FOR AI)
				self.inst.components.hurtboxutil.owner:PushEvent("on_hit", {hitbox = self.inst})
			end
			
			
			--10-28-17  THE ON-PREHIT FN. ON HIT, DO THINGS BEFORE THE KNOCKBACK HAS EVEN BEEN CALCULATED
			if self.prehitfn then
				self.prehitfn(self.inst.components.hurtboxutil.owner, v, self.dam)
			end
			
			
			--10-10-16 NON-DAMAGING TRIGGER-BOXES
			if self.property == 5 then --THESE STILL PUSH THE ONHIT FUNCTIONS, BUT DO NOTHING ELSE (HOPEFULLY)
				if self.onhitfn then --THIS IS A DUPLICATE OF THE ONHIT FUNCTION THAT PLAYS EARLY FOR TRIGGERBOXES
					self.onhitfn(self.inst.components.hurtboxutil.owner, v, self.dam)
				end
				table.insert(self.inst.components.hurtboxutil.owner.components.hitbox.scored, v)
				return end
			
			
			
			
			
			
			--LETS CALCULATE KNOCKBACK RIIIIIIGHT HERE
			self.perc = v.components.percent:GetPercent()
			if self.blocked == true then --3-23
				self.perc = 0
			end
			--print("PERCENT", self.perc)
			--self.weight = self.inst.components.stats.weight --4-26-20 NOOO!! NO YOU DUMMY DUMB DUMB THIS IS 'OUR' WEIGHT. WE WANT THE ENEMIES
			self.weight = v.components.stats.weight --WOW ONLY TOOK ME 4 YEARS TO REALIZE
			self.rate = 1
			local tempkbangle = self.kbangle
			
			
			
			
			--HERE IT IS. THE KNOCKBACK FORMULA. IT SEEMS ALRIGHT, BUT SOMETIMES IT FEELS OFF. ESPECIALLY WITH VERY LIGHT ATTACKS FEELING LIKE THEY DO WAY TOO MUCH KB
			local KB = (((( ((self.perc/10)+((self.perc*ldamage)/20)) * (200/(self.weight+100)) * 1.4 ) +18 ) *(self.scale/100)) + self.base) *self.rate
			           -- ((((  ((v+bd)/10)   +    (((v+bd)*bd)/20))     *   (200/    (w+100))     *1.4 )+18)    *   (g/100))         +b*r
			-- print("KNOCKBACK", KB)
			
			
			
			--WBKB --2-17-17 SECOND ATTEMPT AT SET KNOCKBACK --SIIIIGH. WHY IS IT SO HIGH
			if self.property == 4 or self.scale == 0 then
				KB = (((( ((self.base * 0.5) + 1) * (200/(self.weight+100)) * 1.4 ) +18 ) *(100/100)) + self.base) *self.rate 
				--https://smashboards.com/threads/melee-knockback-values.334245/   --MENTIONS FORMULA FOR SET KNOCKBACK
			end
			
			-- local velocity = KB*0.03 --WHAT WAS THIS FOR?
			--print(velocity)
			
			--AUTOLINKING --12-15
			if self.kbangle == 366 then
				tempkbangle = self.inst.components.hurtboxutil.owner.components.launchgravity:GetAngle()
			elseif math.abs(self.kbangle) == 361 then
				if KB <= 50 then
					tempkbangle = 0
				else
					tempkbangle = 40
				end
			end
			
			
			
			--12-8
			local unit_multiplier = 5 
			
			self.xknockback = ((KB/unit_multiplier)*math.cos(tempkbangle*DEGREES)) --12-15, CHANGING SELF.KBANGLE TO TEMPANGLE FOR AUTOLINKING
			self.yknockback = ((KB/unit_multiplier)*math.sin(tempkbangle*DEGREES))
			
			
			if self.yknockback <= 0 and ((not v.components.launchgravity:GetIsAirborn()) and not (v.sg and v.sg:HasStateTag("hanging"))) then --11-12-17 ADDED CHECK FOR HANGING
				self.yknockback = -self.yknockback * 0.8
			end
			
			if self.kbangle == 366 then --2-29 --FIXES THE MIRRORED XLAUNCH VALUES FOR 366 ANGLES WHEN MOVING A CERTAIN DIRECTION
				self.xknockback = self.xknockback * self.inst.components.hurtboxutil.owner.components.launchgravity:GetRotationValue()
			end
			
			-- print("FINAL KB", KB)
			-- print("XY KB", self.xknockback, self.yknockback)
			
			local GAME_KNOCKBACK_MULTIPLIER = 0.4 / 2  --SAME KB MULTIPLIER AS MELEE,BRAWL,SMASH4, JUST DEVIDED BY TWO TO ACCOUNT FOR THE HALFED FPS 
			self.hitstun = KB * GAME_KNOCKBACK_MULTIPLIER
			self.blockdamage = ldamage / 10  
			
			--9-29-20 A LOGICAL OVERRIDE; IF THE BASEKNOCBACK WAS SET TO 0, MAKE HITSTUN 0, REGARDLESS OF WHAT THE FORMULA SAYS
			if self.base == 0 then
				self.hitstun = 0
			end
			
			
			--!!!!!!!!!!!!!!!!! IMPORTANT ABOUT TUMBLING AND HITSTUN !!!!!!!!!!!!!!
			--""tumble-threshold of 31 frames of hitstun""

			
			self.hitlag = ((((ldamage + self.emphasis)/1.5) + 3) / 2) --3-30 TESTING EMPASIS AND SLIGHTLY REDUCING HITLAG
			local hitlagframes = math.floor(self.hitlag+0.5)*FRAMES --4-11-19 LETS TRY AND NORMALIZE THIS
			--[[
			if hitlagframes <= (2/30) then hitlagframes = (2/30) end
			--IM STILL PISSED THERES NO JUST REGULAR OLD "MATH.ROUND" FUNCTION. GOTTA ADD 0.5 AND THEN ROUND DOWN LIKE SOME IDIOT
			
			 --11-17-17 MAJOR TESTING SESSION TO FIND OUT THE X-KNOCKBACK BUG WITH EMPHASIS- SLUETH
			if self.hitlag <= 2.2 then  --REUSEABLE- THIS WAS THE SOLUTION, THOUGH IM WORRIED THIS WILL HAVE CONSEQUENCES REGARDING HITSTUN CALCULATIONS WITH NEGATIVE EMPHASIS
				self.hitlag = 2.2 --LIKELY, ATTEMPTING TO USE NEGATIVE EMPHASIS TO MAKE A HITLAG OF 0 WILL CAUSE HITSTUN TO BE REDUCED BY 2.2 FRAMES. --TOFIXLIST2
			end
			--11-8-20 TO CLARIFY, YES, THE MINIMUM HITLAG SHOULD BE 2.2 TO PREVENT... PHYSICS ISSUES? ITS HARD TO EXPLAIN, JUST TRUST ME
			--11-20-22 CHECKING IN HERE. THE "PHYSICS BUG" IS MAXWELL'S BACKTHROW, WHEN PERFORMED QUICKLY, WILL ALMOST COMPLETELY NEGATE THE X LAUNCH VELOCITY OF THE THROW
			]]
			
			--11-20-22 IT LOOKS LIKE KLEI UPDATED THE STATEGRAPH SCHEDULING...
			--MAYBE THE 2.2 MINIMUM ISN'T NEEDED NOW?
			--OKAY, IT ACTUALLY JUST SEEMS TO NEED A 1.0 MINIMUM NOW 
			--BUT NOW WE NEED TO REDUCE IT ALL BY 1 ACROSS THE BOARD TO BE BACK IN LINE WITH OUR PREVIOUS VALUES, IT SEEMS
			hitlagframes = hitlagframes - (1/30)
			if hitlagframes <= (1/30) then hitlagframes = (1/30) end
			
			self.camshake = (self.hitlag + 0) * FRAMES * 2 --12-23-16 trying increased hitlag
			local quakesize = self.camshake --12-22-18 -A TEMPORARY NUMBER WE CAN PASS INTO THE SOUND CHOOSER TO DETERMINE THE SOUND PLAYED
			if self.camshake < 0.4 then	--12-22-18 SAMLL BITS OF CAMSHAKE ON TINY ATTACKS JUST LOOK BAD. ONLY PUT CAMSHAKE ON BIG ATTACKS
				self.camshake = 0
			end
			
			
			
			
			--I HAVE THE UNIVERSAL BLOCK TEST UP THERE SO CHANGE THAT IF YOU CHANGE THIS
			if v.sg and v.sg:HasStateTag("blocking") then
				-- !!! ITS DAMAGE BASED !!! I JUST DID SOME TESTING AND DISCOVERED THAT SMASH4'S SHIELD PUSH IS ONLY DEPENDANT ON DAMAGE, NOT KNOCKBACK.
				self.xknockback = (ldamage / 3) + 3 --12-9-17 - THIS SEEMS ABOUT RIGHT  +3 TO GIVE SMALLER DAMAGE HIGHER PUSHBACK
				
				self.yknockback = 0
				self.inst.components.hurtboxutil.owner:PushEvent("hit_shield") --3-14 
				v:PushEvent("block_hit")
				
				if v.blockstuntask then
					v.blockstuntask:Cancel()
				end
				
				--THE SMASH4 FORMULA FOR BLOCKSTUN IS (X / 1.75) + 2
				self.blockstun = ((ldamage / 1.75) + 2) / 2
				
				if v.sg:HasStateTag("can_parry") then
					self.xknockback = 0
					
					if v:HasTag("projectile") then	--3-24 ADDED THIS TO MIMIC THE WAY SMASH HANDLES POWERSHEILDS.
						self.blockstun = 0 
					else
						self.blockstun = self.blockstun / 2  --SMASH4 REDUCES IT BY 25%. --WILL DEVIDING SELF.HITSTUN ITSELF CHANGE LATER VALUES? I HOPE NOT
					end
					
					v.sg:GoToState("parry", (hitlagframes + (self.blockstun * FRAMES)))
				
				else
					v.components.blocker:DoDelta(-(self.blockdamage + self.blockdam) * 1.2) --BLOCKDAM IS THE "REAL" ADDITIONAL BLOCK DAMAGE
					v.components.percent:DoSilentDamage(-self.chipdam)
					
					v.sg:GoToState("block_stunned", ((self.blockstun+self.hitlag)*FRAMES))
				end
			
			
				
			end
			
			
			--REMOVE PLAYERS ABOLITY TO GET HIT   --IM MOVIN THIS 11-23
			if v.components.hurtboxes and v~=self.inst and not v.sg:HasStateTag("blocking") and not v.sg:HasStateTag("intangible") then  --3-18 !!!! MOVED A COPY UP THERE SO DAMAGE APPLIES FIRST. IF YOU CHANGE THIS FUNC, CHANGE THE ONE UP THERE TOO!!!
				
				local kbdirection = "up"
				if self.kbangle <= 50 then
					kbdirection = "side"
				end
				
				v:RemoveTag("listenforfullhop") --10-20-17 LISTENFORFULLHOP CHECK -REUSEABLE - THEY GOT HIT, DONT LET EM CONTINUE THE JUMP
				self:PlayHitsound(v, quakesize) --6-30-18 --THIS SHOULD ALWAYS PLAY, EVEN IF HITTING ARMOR  --12-22-18 NOW PASSING IN CAMSHAKE SIZE
				
				if (self.hitstun >= 16 or v.sg:HasStateTag("tumbling")) and not (v.sg:HasStateTag("armor") or v:HasTag("armor")) then  --MUCH BETTER 11-23
					v:PushEvent("do_tumble", {hitstun = self.hitstun+self.hitlag, direction = kbdirection}) --12-4
					v:AddTag("juggled") --1-6-17 FOR AI
				elseif self.hitstun > 0 and not (v.sg:HasStateTag("armor") or v:HasTag("armor")) then --9-29-20 ADDING 0 HITSTUN BYPASS SO THAT NON-KB MOVES DONT MAKE YOU FLINCH
					v:PushEvent("attacked", {hitstun = self.hitstun+self.hitlag}) --12-4
				end
            end
			
			
			
			if v.components.launchgravity and not v.sg:HasStateTag("intangible") then
				if v~=self.inst.components.hurtboxutil.owner then
				
					table.insert(self.inst.components.hurtboxutil.owner.components.hitbox.scored, v)
				
					self.highlight = self.hitlag / 12 --4-14 THERE WE GO, A LITTLE BETTER. I WISH THERE WAS A TWEEN THOUGH
					
					if self.hitstun > 0 then
						self:FaceAttacker(v) --^^^ --WHY DO WE FACE ATTACKER SO MANY TIMES?
					end
					
					--3-31-19 THIS REALLY SHOULD HAVE BEEN KNOCKBACK BASED FROM THE START AND NOT VELOCITY BASED
					if self.yknockback <= -9 and (v.components.percent and v.components.percent:GetPercent() >= 100) then --ALSO, ONLY SLAM IF THEY'RE OVER 100% DAMAGED
						-- print("COME ON AND SLAM", self.yknockback)
						v:AddTag("terminal_vel")
					end
				end
				
				
				--11-7-17
				self:DoSuction(self.suction, self.sucpx, self.sucpy, self.inst.components.hurtboxutil.owner, v) --DST CHANGE - MOVING THIS UP OUT OF THE HITLAG TASK
				
				if self.camshake > 0.1 then --12-22-28 CAMSHAKE ONLY LOOKS GOOD IN BIG AMOUNTS ON BIG ATTACKS. LEAVE LITTLE ONES ALONE (its reduced to 0 by now if its less than 4)
					--12-19-18 OK IM TIRED OF THIS WEAK CAMERA SHAKE. LETS GET THINGS BACK TO THE GLORY DAYS
					TheCamera:Shake("FULL", self.camshake*1, .02, (self.camshake*1.5)) --Camera:Shake(type, duration, speed, scale)
				end
				
				
				
				
				local fxyscale = (self.dam / 10) + 0.5
				local fxangler = self.kbangle
				local fxsprite = "sidesplash_med"
				local forcemirror = 1 --3-31-19 FOR ODDLY SPECIFIC SITUATIONS WITH FORCED-DIRECTION KNOCKBACK BEHIND YOU LIKE BACK-AIRS
				--print ("MY ANGLE", self.kbangle)
				
				if self.blocked == true then	--3-24 ADDING THIS SO BLOCKS HITSPLASH LOOKS DIFFERENT. HOPE THIS DOESNT CHANGE HITBOX POS
					fxsprite = "idle"
					self.xoffset = self.xoffset - (self.inst:GetDistanceSqToInst(v) * -0.5) --MAKES A HIT RING INSTEAD OF A HITSPLASH "APROXIMATLEY" WHERE THE ATTACK HIT THE OPPONENT
					self.inst.components.hurtboxutil.owner.components.hitbox:MakeFX(fxsprite, (self.xoffset*1), (self.ycenter), 1, fxyscale, fxyscale, 0.2, 7, 1,  0, 0, 0,   1, "impact", "impact")
					--4-17 MOVED BOTH FX SPAWNERS UP HERE IN THEIR OWN SPOT. NOICE
				else
					if fxangler <= 50 or fxangler >= 300 then 
						fxsprite = "sidesplash_med"
					elseif fxangler <= 75 and self.yknockback >= 20 then 
						fxsprite = "sidesplash_med_upangle"
					-- elseif fxangler == 90 then 
						-- fxsprite = "sidesplash_med_up2"
					elseif fxangler <= 120 and self.yknockback >= 20 then  
						fxsprite = "sidesplash_med_up2"
					elseif fxangler <= 200 and fxangler >= 120  then
						-- fxsprite = "sidesplash_med_downangle" --THIS IS NOT REALLY THE RIGHT ANGLE
						fxsprite = "sidesplash_med" --THIS IS CLOSER. WE'LL SKIP THE UPANGLE FOR BACKWARDS HITS, THIS ONE IS CLOSE ENOUGH
					elseif fxangler <= 280 and fxangler >= 200 then 
						fxsprite = "sidesplash_med_down2"
					else
						fxsprite = "sidesplash_med"
					end
					
					
					-- 9-10 FOR KILL MOVE FX
					if self.xknockback >= 30 or self.yknockback >= 30 then
						fxsprite = "punchwoosh"
					end
					
					--4-11 --FOR CUSTOM HIT FX
					if self.hitfxsprite then
						fxsprite = self.hitfxsprite
					end
					
					--7-8-17 ADDING A MIRROR VARIABLE THAT ALLOWS HITSPLASH TO BE BACKWARDS WHEN HITTING ENEMIES BEHIND YOU
					local mirror = -(self.inst.components.hurtboxutil.owner.components.launchgravity:GetRotationValue() * v.components.launchgravity:GetRotationValue()) --WILL RETURN NEGATIVE IF HIT BACKWARDS
					--IF THE OPPONENT IS BEING HIT BEHIND THEM, THEY WILL ALWAYS BE FACING THE SAME DIRECTION. THUS, MULTIPLYING THEIR FACE VALUES WILL ALWAYS RESULT IN A POSITIVE
					--3-30-19 --FOR FORCED-DIRECTIONAL BACKWARDS HITTING MOVES (like b-air) MOST HITSPLASHES ARE BACKWARDS! IF ANGLE IS BACKWARDS & FORCED DIRECTION, CANCEL THE MIRROR
					if ((fxangler >= 90 and fxangler <= 270) or fxangler < 0) and ((self.inst.components.hurtboxutil.owner.sg and self.inst.components.hurtboxutil.owner.sg:HasStateTag("force_direction")) or self.inst.components.hurtboxutil.owner:HasTag("force_direction")) then
						--5-8-20 ^^^ ADDED FXANGLER CHECK FOR <0 TO MAKE THINGS A LITTLE EASIER (LIKE FOR -361 ANGLES)
						-- mirror = mirror * mirror --SQUARED, TURNING IT BACK TO POSITIVE IF IT WAS NEGATIVE
						forcemirror = -1 --3-31-19
						mirror = forcemirror --5-8-20 UM YEA THIS MAKES WAY MORE SENSE. NOT SURE WHY I MADE THESE TWO SEPERATE THINGS IN THE FIRST PLACE
					end
					
					if fxsprite ~= "none" then --FIRST CHECK TO SEE IF THEY DONT WANT ONE SPAWNED (TO PREVENT BUGS WITH OTHER ONHIT FX SPAWNING STUFF)
						self:MakeFX(fxsprite, (self.xoffset*1), (self.ycenter), 1, (fxyscale*mirror), fxyscale, 0.2, 7, 1)  --NOTE TO SELF, MIGHT EVENTUALLY WANT TO SWITCH THIS ONTO THE OWNERS HITBOX.LUA VERSION
						--3-1 ^^^ REPLACED SELF.YOFFSET WITH YCENTER TO REDUCE Y OFFSET BASED ON SIZE DUE TO RECALCULATED HITBOX POSITION BASED ON SIZE FROM HITBOXES 2.0
					end
				
				
					--2-20-17 MAYBE AN ON-SCREEN HEALTH INDICATOR?
					if v.components.hoverbadge and v.components.percent and v.components.percent.hpmode then
						-- v.components.hoverbadge:SetBadgeSprite("health", "health") --THIS VERSION IS OUTDATED
						v.components.hoverbadge:SetBadgeSprite("status_health", {0.68, 0.09, 0.09, 1})
						-- v.components.hoverbadge:SetTopperPercent((self.perc/100), 60)
						v.components.hoverbadge:SetTopperPercent((v.components.percent:GetHPPercent()/1), 60)
					end
				
				end
				
				
				--11-14-17 CANCELING THE PLAYERS SATE FROM REGRABBING THE LEDGE WITH INTANGIBILITY.
				v:RemoveTag("noledgeinvuln")
				if v.ledgeregrabbingtask then
					v.ledgeregrabbingtask:Cancel()
					v.ledgeregrabbingtask = nil
				end
				
				
				--2-1 --ONHIT FUNCTIONS
				if self.onhitfn then
					self.onhitfn(self.inst.components.hurtboxutil.owner, v, self.dam)
				end
				
				
				--4-13 THE LANDING ANIMATIONS INTERUPTING THE ATTACK ANIMATIONS ARE REALLY BUGGING ME
				self.inst.components.hurtboxutil.owner:AddTag("hitfrozen") --4-20 DONT THINK I NEED THESE ANYMORE???
				v:AddTag("hitfrozen") --9-6-2016 ^^^^^ I DO NOW. LEAVE THEM IN!
				
				
				--4-20 I GUESS IT HAS TO GO UP HERE THEN??
				if v.enemyhitlagendtask then 
					v.enemyhitlagendtask:Cancel()
				end
				if self.inst.components.hurtboxutil.owner.myhitlagendtask then 
					self.inst.components.hurtboxutil.owner.myhitlagendtask:Cancel()
				end
				
				
				
				
				
				--===  HITSTUN TASKS ===--
				
				
				
				
				if v~=self.inst.components.hurtboxutil.owner then

					self.inst.components.hurtboxutil.owner:PauseStateGraph((hitlagframes)) --12-22
					v:PauseStateGraph((hitlagframes)) -- ^^^ 12-22-16 HEH, EXACTLY ONE YEAR, EH?

					if self.hitstun > 0 then
						self:FaceAttacker(v)
					end
				
					self.inst.components.hurtboxutil.owner:AddTag("hitpaused") --12-9
					v:AddTag("hitpaused")
					-- 10-28-16 MAKES ATTACKER SPRITE APPEAR LAYERED OVER THE OTHER SPRITES
					self:OverlayAttacker(v)
					
					--v.components.jumper.di = 0.1 --12-2-21 WAS LITERALLY THE ONLY PLACE THIS VALUE EVER CHANGED, BUT FORGET THAT. I'M GETTING RID OF IT
					v.AnimState:SetAddColour(self.highlight,self.highlight,self.highlight,self.highlight) 
					v.AnimState:Pause()
					v.Physics:SetActive(false)
					
					--DST CHANGE 10-14-17 - CHANGING SO THAT ANIMS DONT PAUSE UNLESS HITSTUN IS STRONG ENOUGH
					-- if self.hitstun >= 20 then --DST CHANGE 10-14-17 -TO PREVENT THE WEIRD FROZEN HITSTUN BUG FOR CLIENTS --OR MAYBE NOT...THIS IS ONLY FOR ATTACKERS! NOT ATTACKEES..
						self.inst.components.hurtboxutil.owner.AnimState:Pause()   --10-18 CHANGING THESE 4 VS TO SELF.INST
					-- end
					self.inst.components.hurtboxutil.owner.Physics:SetActive(false)
				end

				

				
				-- 4-20 A VERY EXPERIMENTAL NEW TASK
				
				self.inst.components.hurtboxutil.owner.myhitlagendtask = self.inst.components.hurtboxutil.owner:DoTaskInTime(hitlagframes, function()
					if v~=self.inst.components.hurtboxutil.owner then
						--6-10-20 FOR ISSUES WHERE TRADES CAUSE HITLAGENDTASKS TO OVERLAP AND UNPAUSE TOO EARLY!
						if not self.inst.components.hurtboxutil.owner.enemyhitlagendtask then --IF WE'VE BEEN HIT, IGNORE THIS TASK IN FAVOR OF THE TASK THAT GIVES US OUR KNOCKBACK
							
						
							self.inst.components.hurtboxutil.owner.Physics:SetActive(true)
							self.inst.components.hurtboxutil.owner:UnPauseStateGraph() 
						
							--4-11-19 WELP. ITS BEEN LIKE 3 YEARS I'VE BEEN USING THIS HITLAG METHOD. YOU'VE SERVED ME WELL BUT YOUVE BEEN REPLACED. FAREWELL, SWEET PRINCE...
							-- self.inst.components.hurtboxutil.owner.sg.timeinstate = self.inst.components.hurtboxutil.owner.sg.timeinstate - ((self.hitlag-frame_delay)*FRAMES) -- -THE HOLY GRAIL OF THE HITLAG FORMULA --4-11-19 DISABLING IN AN ATTEMPTED REPLACEMENT 

							self.inst.components.hurtboxutil.owner:DoTaskInTime(0, function() --IM PUTTING THIS IN THE NEXT TICK BECAUSE JUMPER.LUA IS WHINING AND ITS MESSING UP GROUND COLLISION
								self.inst.components.hurtboxutil.owner:RemoveTag("hitpaused")
								self.inst.components.hurtboxutil.owner:RemoveTag("hitfrozen")
								self.inst.components.hurtboxutil.owner.AnimState:Resume()
							end)
							
					-- else
							-- print("IVE ALREADY GOT A HITLAG TASK!! CANCELING")
							--BUT STILL RUN THAT STUFF BELOW --6-10-20
						end
						
						
						self:UnOverlayAttacker(v)
						
						if self.inst.components.hurtboxutil.owner:HasTag("deleteonhit") then
							self.inst.components.hurtboxutil.owner:Remove()
							self.lifespan = 0 --6-7-18
						end
					end
				end)
				
				
				
				
				
				--12-16-17 MAKING THE HITLAGENDTASKS LOCALS SO THAT HITTING MULTIPLE ENEMIES WONT SHARE THE KNOCKBACK VALUES
				--AND REPLACING ALL OF THE SELF.VARIABLES IN THE TASK WITH THESE NEW LOCALS. --REUSED
				local finalhitlag = self.hitlag
				local finalblocked = self.blocked
				local finalxknockback = self.xknockback * forcemirror --3-31-19 forcemirror FOR SPECIFIC SITUATIONS WITH FORCED DIRECTIONAL BACK-AIRS
				local finalyknockback = self.yknockback
				--2-6-22 PROJECTILES ARE SOMETIMES REMOVED BEFORE THE BLOCKING KB DIRECTION IS CALCULATED, SO THIS IS TO STORE THAT INFO 
				local tempstoredpos = self.inst.components.hurtboxutil.owner.Transform:GetWorldPosition()
				
				v.enemyhitlagendtask = v:DoTaskInTime(hitlagframes, function()
					if v:IsValid() and v~=self.inst.components.hurtboxutil.owner then
					
						--12-22-16 ADDING STATEGRAPH PAUSING TO ENEMIES TOO, SINCE ARMORED MOVES NEED IT 
						v:UnPauseStateGraph() 
						
						if self.hitstun > 0 then
							self:FaceAttacker(v)
						end
						
						--7-31 MOVED THIS DOWN HERE TO SEE IF IT FIXES BROKEN LAUNCH DIRECTION
						if finalblocked == true then 	--3-23 ADDED THIS SO NOW GETTING HIT IN SHIELD WONT TECHNICALL PUT YOU IN THE AIR  
							v.components.launchgravity:PushAwayFrom((finalxknockback), finalyknockback, tempstoredpos, self.inst.components.hurtboxutil.owner) --AHHH, IT JUST NEEDED TO PASS IN THE OPPONENTS REFERENCE SO IT KNEW WHAT DIRECTION TO PUSH IN
						elseif self.hitstun > 0 and not (v.sg:HasStateTag("armor") or v:HasTag("armor")) then --9-29-20 ADDED BYPASS FOR 0 HITSTUN ATTACKS
							v.components.launchgravity:Launch(-finalxknockback, finalyknockback, 0)
							--SO IF A NO-KNOCKBACK HITBOX LANDS, A HITSOUND AND HITSPLASH WILL STILL PLAY. EH, THIS IS FINE I GUESS. YOU CAN ALWAYS OVERWRITE IT, AND THERE ARE REASONS TO WANT THIS ON
						end
						--print("--MY X/Y KNOCKBACK!!!- ", finalxknockback, finalyknockback, self.xknockback, forcemirror)
						
						v.AnimState:SetAddColour(0,0,0,0)  --THIS CAN GO ON BOTH PLAYERS IT DOESNT MATTER
						v.components.jumper:ForceRemoveLedgeGates() --9-1 --THIS FIXES THE PROBLEM WHERE LEDGE GATES PREVENT X KNOCKBACK
						v.Physics:SetActive(true)
						v.AnimState:Resume()
						v:RemoveTag("hitpaused") 
						v.enemyhitlagendtask = nil --6-10-20
						
						--ANOTHER TYPE OF CUSTOM ONHITFN() THAT ACTIVATES RIGHT AS HITSTUN WEARS OFF
						if self.onposthitfn then --12-15-16
							self.onposthitfn(self.inst.components.hurtboxutil.owner, v, self.dam)
						end 
						
						--5-8-20 LETS JUST TAKE CARE OF BACKWARDS FORCED_DIRECTIONAL HITS FOR THEM.
						if forcemirror == -1 then 
							self.inst.components.hurtboxutil.owner.components.locomotor:FaceWithMe(v)
						end
						
						v:DoTaskInTime(0, function() --IM PUTTING THIS IN THE NEXT TICK BECAUSE JUMPER.LUA IS WHINING AND ITS MESSING UP GROUND COLLISION
							v:RemoveTag("hitfrozen")
						end)
					end
				end)
				
				
				
				
				
			end
        end
    end
	end
end



return Hitboxes