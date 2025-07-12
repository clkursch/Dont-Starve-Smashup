local assets=
{
	Asset("ANIM", "anim/nitre.zip"), --HI
}

--function GetOpponent(ents)
function GetOpponent(inst)
	--12-5. WAIT THIS IS GETTING CALLED? UM OKAY
	inst = crashthegameplz
	return inst.components.hurtboxutil:GetOwner()
end

function GetSelf(inst)
 --OKAY NOW THIS IS JUST SILLY
	return inst
end


--local function fn(Sim)
local function hitsphere()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    --MakeInventoryPhysics(inst)
    -- inst.entity:AddSoundEmitter() --THESE DON'T NEED TO MAKE SOUND
	
	--1-9 GIVING ALL OF THEM PHYSICS
	inst.entity:AddPhysics()
	inst.Physics:SetMass(0) 
	inst.Physics:SetSphere(1)
	-- self.inst.Physics:SetFriction(1) 
	-- inst.Physics:SetCollisionGroup(COLLISION.SANITY) --HOW ABOUT I JUST MAKE THEM ALL SANITY FOR CONSISTANCY
	inst.Physics:SetCollisionGroup(199) -- OFF! --4-6-19  
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(199) --OFF! --4-6-19 (AND ON THAT DAY I REALIZED HOW COLLISION GROUPS DONT WORK)
	
    -- inst.AnimState:SetBank("nitre")
    -- inst.AnimState:SetBuild("nitre")
	-- inst.AnimState:PlayAnimation("idle")
	
	inst.AnimState:SetBank("visible_hitbox")
    inst.AnimState:SetBuild("visible_hitbox")
    -- inst.AnimState:PlayAnimation("yellow")
	inst.AnimState:PlayAnimation("circle")

	inst.AnimState:SetMultColour(0,0,0,0) --INVISIBLE
	-- inst.AnimState:SetMultColour(0.8,0.0,0.0,0.8) --VISIBLE
	inst:AddComponent("hurtboxes") --12-3 MMM MAYBE NOT  
	--6-17-18 YES, THESE STILL NEED TO BE THERE, SINCE IT STORES INFO ABOUT IT'S OWNER, AND IT'S OWN DAMAGE PROTOCOL IF NOT DISJOINTED
	
	inst:AddTag("hurtbox") --1-14 TODOLIST EVENTUALLY REMOVE THIS BECAUSE ITS MAKING EVERYTHING ELSE A HURTBOX
	inst:AddComponent("hitbox") --12-8
	
	inst.persists = false --GET ALL THESE OBJECTS OFF THE SCREEN
	
    return inst
end







local function CommonHitbox()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    --MakeInventoryPhysics(inst)
    -- inst.entity:AddSoundEmitter() --THESE DON'T NEED TO MAKE SOUND
	
	--1-9 GIVING ALL OF THEM PHYSICS
	inst.entity:AddPhysics()
	inst.Physics:SetMass(0) 
	inst.Physics:SetSphere(1)
	-- self.inst.Physics:SetFriction(1) 
	-- inst.Physics:SetCollisionGroup(COLLISION.SANITY) --HOW ABOUT I JUST MAKE THEM ALL SANITY FOR CONSISTANCY
	--DON'T SET THESE! LET THE INDIVIDUAL BOX PREFABS CHOOSE WHAT TO SET THEM AS!
	
	--10-31-20 
	-- inst.Physics:SetMass(1) --ENABLING MASS >0 ALLOWS YOU TO USE Physics:SetVel() ON THEM
	--WAIT, BUT IT ALSO ENABLES ACTUAL PHYSICAL COLLISION, PUSHING OVERLAPPING BOXES AWAY...
	--GUESS WE CAN'T ENABLE THEM THEN  :(  SUCKS TO SUCK
	
	inst.persists = false --GET ALL THESE OBJECTS OFF THE SCREEN
	
    return inst
end


--1-12-20 UMM, WHY DONT I HAVE ONE FOR HITBOXES YET???
local function hitbox()
	local inst = CommonHitbox() --GETTIN FANCY WITH IT~
	
	--4096 IS SANITY, THE LAST OF THE 3 FREE COLLISION GROUPS  -5-13-19
	local collisiongroup = 4096
	inst.Physics:SetCollisionGroup(collisiongroup) 
	-- inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(collisiongroup) 
	-- inst.Physics:CollidesWith(8) 
	
	
    if VISIBLEHITBOXES == true then
		inst.AnimState:SetBank("visible_hitbox")
		inst.AnimState:SetBuild("visible_hitbox")
		-- inst.AnimState:PlayAnimation("yellow")
		inst.AnimState:PlayAnimation("circle")
		inst.AnimState:SetMultColour(0.8,0.0,0.0,0.8) --VISIBLE
    end
	
	--1-18-20 OKAY. I'M TRYING TO MAKE THIS COMPONENT UNIVERSAL FOR ALL BOX-TYPES SO THAT "SELF.OWNER" CAN BE STORED THERE
	inst:AddComponent("hurtboxutil")
	
	-- inst:AddComponent("hitboxes") --HITBOXES NEED TO INITIALIZE BEFORE THE HURTBOX COMPONENT
	--inst:AddComponent("hurtboxes") --STILL NEEDS TO BE THERE, UNFORTUNATELY, FOR SELF.OWNER    --1-18-20 -HOW ABOUT NOW??
	inst:AddComponent("hitboxes") --OR WAIT, MAYBE ITS THE OTHER WAY AROUND?
	
	--OH MAYBE I FORGOT THIS?
	inst:AddTag("hitbox")
	
    return inst
end



local function hurtbox()
	local inst = CommonHitbox() --GETTIN FANCY WITH IT~
	
	--4096 IS SANITY, THE LAST OF THE 3 FREE COLLISION GROUPS  -5-13-19
	local collisiongroup = 4096
	inst.Physics:SetCollisionGroup(collisiongroup) 
	-- inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(collisiongroup) 
	-- inst.Physics:CollidesWith(8) 
	
	
    if VISIBLEHURTBOXES == true then
		inst.AnimState:SetBank("visible_hitbox")
		inst.AnimState:SetBuild("visible_hitbox")
		-- inst.AnimState:PlayAnimation("yellow")
		inst.AnimState:PlayAnimation("circle")

		inst.AnimState:SetMultColour(1,1,0,0.8) --INVISIBLE
		-- inst.AnimState:SetMultColour(0.8,0.0,0.0,0.8) --VISIBLE
    end
	
	-- inst:AddComponent("hurtboxes") --12-3 MMM MAYBE NOT  
	--1-17-20  ...WAIT WHY THE HECK DID WE TURN THIS OFF??? --OH RIGHT BECAUSE ITS FOR HURTBOX SPAWNERS
	
	inst:AddComponent("hurtboxutil") --5-13-19 NOW WE'RE TALKIN!
	
	inst:AddTag("hurtbox")
	
	
	-- inst.persists = false --GET ALL THESE OBJECTS OFF THE SCREEN
	
    return inst
end




-- local MISC_BOXES_ENABLED = false
-- if GetModConfigData("VisibleBoxes") == 5 then
	-- MISC_BOXES_ENABLED = true
-- end


--FOR SOFT-COLLISION AND GRABBABLE BOXES
local function playerbox()
	local inst = CommonHitbox() --GETTIN FANCY WITH IT~
	
	local collisiongroup = 8
	inst.Physics:SetCollisionGroup(collisiongroup) 
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(collisiongroup) 
	
	if VISIBLEHURTBOXES == true and VISIBLEMISCBOXES then
		inst.AnimState:SetBank("visible_hitbox")
		inst.AnimState:SetBuild("visible_hitbox")
		inst.AnimState:PlayAnimation("box")
		inst.AnimState:SetMultColour(1,1,1,0.8) --VISIBLE
    end
	
	inst:AddComponent("hurtboxutil")

	--THE ONLY UNIQUE THING ABOUT THESE, I GUESS (BESIDES COLLISIONGROUP)
	inst:AddTag("playerbox")
	

	inst.persists = false --GET ALL THESE OBJECTS OFF THE SCREEN
    return inst
end




--LEDGE-GRAB BOX
local function ledgegrabbox()
	local inst = CommonHitbox()
	
	local collisiongroup = 32
	inst.Physics:SetCollisionGroup(collisiongroup) 
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(collisiongroup) 
	
	inst:AddComponent("hurtboxutil")

	--THE ONLY UNIQUE THING ABOUT THESE, I GUESS (BESIDES COLLISIONGROUP)
	inst:AddTag("ledgegrabbox")
	
	
	if VISIBLEHURTBOXES == true and VISIBLEMISCBOXES then
		inst.AnimState:SetBank("visible_hitbox")
		inst.AnimState:SetBuild("visible_hitbox")
		-- inst.AnimState:PlayAnimation("yellow")
		inst.AnimState:PlayAnimation("circle")

		inst.AnimState:SetMultColour(0.0,0.1,0.8,0.3) --VISIBLE
    end
	
	--OKAY SO WEHN I SET IT FROM WITHIN THE ENTITY SETUP ITSELF IT BREAKS IT??? WHY DOES IT WORK FOR THE LEDGEBOX??
	-- inst.Physics:SetCollisionCallback(function(inst, object) 
		-- print("SPAWN ME LEDGE")
	-- end)
	

	inst.persists = false
    return inst
end


--LEDGE-BOX (THE ONES PLACED ON THE CORNERS OF THE STAGE)
local function ledgebox()
	local inst = CommonHitbox()
	
	local collisiongroup = 32
	inst.Physics:SetCollisionGroup(collisiongroup) 
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(collisiongroup) 
	
	inst:AddTag("ledge")
	
	--WE ACTUALLY HAVE A UNIVERSAL SPECIFIC SIZE FOR THESE ONES
	inst.Physics:SetSphere(0.25)


	--WHY DONT WE JUST TURN THESE OFF PERMINANTLY
	--[[
		inst.AnimState:SetBank("visible_hitbox")
		inst.AnimState:SetBuild("visible_hitbox")
		inst.AnimState:PlayAnimation("yellow")
		inst.AnimState:SetMultColour(0,1,0,1) --VISIBLE
    ]]
	
	--THESE ARE ALWAYS ACTIVE, SO LETS JUST SET UP COLLISION CALLBACKS AND GET IT OUT OF THE WAY
	inst.Physics:SetCollisionCallback(function(inst, object) --NOW THAT I KNOW WHAT I'M DOING, LETS GET A LITTLE FANCIER~
		if object and object.components.hurtboxutil then --4-1-19 NICE c:
			object.components.hurtboxutil.owner:PushEvent("grab_ledge", {ledgeref = inst})
			--I WOULD PUT SOMETHING ELSE TO TRY AND LIMIT RUNS PER FRAME, BUT... DONT WANT TO LAG PAST A LEDGE. IM OK WITH SPAMMING THIS EVENT PUSH
		end
	end)
	
    return inst
end




--JUST GRAB BOXES, BECAUSE COMBINING HURTBOXES AND PLAYERBOXES OUT IN THE WILD DOESNT WORK FOR SOME REASON
local function grabbox()
	local inst = CommonHitbox()
	
	local collisiongroup = 8
	inst.Physics:SetCollisionGroup(collisiongroup) 
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(collisiongroup)
	inst.Physics:CollidesWith(32)  --FOR HURTBOXES (OR REALLY, FOR HITBOXES TO COLLIDE WITH THEM)
	
	if VISIBLEHURTBOXES == true then
		inst.AnimState:SetBank("visible_hitbox")
		inst.AnimState:SetBuild("visible_hitbox")
		inst.AnimState:PlayAnimation("box")
		inst.AnimState:SetMultColour(1,1,1,0.8) --VISIBLE
    end
	
	inst:AddComponent("hurtboxutil")
	--inst:AddTag("playerbox")

    return inst
end



--6-12-20 EXPERIMENTAL NEW FEATURE. DUMMY PHYSICS COLLIDERS TO PAIR WITH EACH HITBOX SPAWN TO ENSURE THEY DONT SKIP COLLISIONS 
local function bottlecap()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	-- inst.entity:AddAnimState()
	inst.entity:AddPhysics()
	inst.Physics:SetMass(0) 
	inst.Physics:SetSphere(0.1)
	
	local collisiongroup = 4096 --
	inst.Physics:SetCollisionGroup(collisiongroup) 
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(collisiongroup)
	-- inst.Physics:CollidesWith(4096)  
	
	inst:AddComponent("bottlecap_util") --I MADE A COMPONENT FOR IT, I GUESS
	
	inst.persists = false
    return inst
end


-- return Prefab( "hitsphere", fn, assets)
--OH YEA THATS RIGHT. THERE ARE A WHOLE BUNCH OF DIFFERENT KINDS
return Prefab( "hitsphere", hitsphere, assets), --LEGACY VERSION, WITH A BUNCH OF CRAP ATTACHED. READY TO BE TOSSED ONTO WHATEVER MISC SPAWNERS
 Prefab( "hitbox", hitbox, assets),
 Prefab( "hurtbox", hurtbox, assets),
 Prefab( "playerbox", playerbox, assets),
 Prefab( "ledgegrabbox", ledgegrabbox, assets),
 Prefab( "ledgebox", ledgebox, assets),
 Prefab( "grabbox", grabbox, assets),
 Prefab( "bottlecap", bottlecap, assets)
  
