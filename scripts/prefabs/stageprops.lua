local assets=
{
	Asset("ANIM", "anim/nitre.zip"), --A CLASSIC~
}



--local function fn(Sim)
local function ledgegate()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	
	inst.entity:AddPhysics()
	inst.Physics:SetMass(0) 
	-- inst.Physics:SetRectangle(0.4, 2, 7) --2-21-17 /SCREAM/ ITS A GOD DANG RECANGLE AAKFJGASLKDFG
	inst.Physics:SetCylinder(0.4, 2) --DSTCHANGES@@@ WHY DOES RECTANGLE NOT WORK :c
	inst.Physics:SetFriction(0) 
	inst.Physics:SetRestitution(1) 
	
	inst.Physics:SetCollisionGroup(COLLISION.LIMITS) 
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.CHARACTERS) 
	
	--[[
	inst.AnimState:SetBank("visible_hitbox")
    inst.AnimState:SetBuild("visible_hitbox")
    -- inst.AnimState:PlayAnimation("yellow")
	inst.AnimState:PlayAnimation("circle")

	inst.AnimState:SetMultColour(0,0,0,0) --INVISIBLE
	-- inst.AnimState:SetMultColour(0.8,0.0,0.0,0.8) --VISIBLE
    ]]
	
	inst:AddTag("floor") --LOL
	
	inst.persists = false --GET ALL THESE OBJECTS OFF THE SCREEN
	
    return inst
end


return Prefab( "ledgegate", ledgegate) --NO ANIMATION. MAKE THESE MF INVISIBLE
