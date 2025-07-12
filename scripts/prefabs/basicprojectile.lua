local assets=
{
	Asset("ANIM", "anim/nitre.zip"),
	Asset( "ANIM", "anim/projectile_lucy.zip" ),
	Asset("ANIM", "anim/meteor.zip"),
}


local function onclank(inst) 
	--1-2-22 ADDING "DELETEONCLANK" CHECK FOR EXPLOSIVE PROJECTILES THAT GO TO A UNIQUE DEATH STATE ON CLANK
	
	if inst:HasTag("deleteonclank") then
		inst:Remove()
	end
end



--local function fn(Sim)
local function fn(inst)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    --MakeInventoryPhysics(inst)
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork() --DSTCHANGES
    
    -- inst.AnimState:SetBank("projectile_lucy")
    -- inst.AnimState:SetBuild("projectile_lucy")
    -- inst.AnimState:PlayAnimation("idle")
	
	inst.Transform:SetTwoFaced()
	
	local size = 1.7
	inst.Transform:SetScale(size,size,size)

	MakeGhostPhysics(inst, 75, 0.1)
	inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
	
	inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	
	inst:AddComponent("stats")
	inst:AddComponent("hitbox")
	inst:AddComponent("launchgravity")
	inst:AddComponent("locomotor")
	inst:AddTag("deleteonhit")
	inst:AddTag("deleteonclank") --1-2-22
	inst:AddTag("projectile")
	inst:AddTag("force_direction")
	
	
	-- inst:ListenForEvent("animover", loopanim)  
	--4-21 ^^^^^ WARNING!!!! THIS MEANS THAT THE ANIMATION MUST BE NAMED "IDLE" AT ALL TIMES!!! 
	--I SHOULD REALLY CHANGE THAT. --TODOLIST
	--8-30 WELL GEE, LOOK WHO'S FAULT IT IS THE BOOMERANG'S "SPINLOOP" ANIMATION WONT WORK, YA DINGUS
	
	inst:ListenForEvent("clank", onclank)
	-- inst:ListenForEvent("overpowered", onclank) --5-4-20 IF OVERPOWERED, ACT AS IF IT'S A CLANK
	inst:SetStateGraph("SGprojectile") --8-26 GIVING IT A STATEGRAPH
	
	
	--DST CHANGES
	inst.entity:SetPristine() 

    if not TheWorld.ismastersim then
        return inst
    end
	
	
	if inst.components.hitbox and inst.components.hitbox.oncollidefn then
		inst.Physics:SetCollisionCallback(oncollidefn)
	end
	
	inst:AddComponent("projectilestats")
	inst.Physics:SetMotorVel(inst.components.projectilestats.xprojectilespeed, inst.components.projectilestats.yprojectilespeed, 0)
	
	-- inst.components.projectilestats:BeActive(inst) --12-4-21 COME ON NOW, GET THIS OUT OF HERE. DO IT PROPERLY
	
    return inst
end

return Prefab( "common/inventory/basicprojectile", fn, assets) 
