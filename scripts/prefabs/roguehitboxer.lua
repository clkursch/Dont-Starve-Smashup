local assets=
{
	Asset("ANIM", "anim/nitre.zip"),
}

-- THIS OBJECT WILL FUNCTION AS A ROGUE GHOST PLAYER TO SPAWN HITBOXES AS A NEUTRAL 3RD PARTY, LIKE FOR GRUE


local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	-- inst.Physics:ClearCollisionMask()
	inst.Physics:SetActive(false)
	
    -- inst.AnimState:SetBank("nitre")
    -- inst.AnimState:SetBuild("nitre")
	-- inst.AnimState:PlayAnimation("idle")

	
	inst:SetStateGraph("SGprojectile")
	-- inst.sg:AddStateTag("intangible")
	
	--12-15-17 WE NEED A ROUGE HITBOX SPAWNER FOR WORLD EVENT HITBOXES, LIKE GRUE.
	inst:AddComponent("stats")
	inst:AddComponent("hitbox")
	inst:AddComponent("launchgravity")
	
	inst:AddTag("roguehitboxspawner")
	
	-- inst.entity:AddLightWatcher()	--THIS IS SO SILLY
	
	-- inst.LightWatcher:SetLightThresh(.7) --.075
	-- inst.LightWatcher:SetDarkThresh(.3) --0.05
	
	
	-- inst.entity:AddLight()
	-- inst.Light:SetIntensity(.1) --.8
	-- inst.Light:SetRadius(1.0) --.5
	-- inst.Light:SetFalloff(0.2) --0.65
	-- inst.Light:SetColour(255 / 255, 255 / 255, 236 / 255)
	-- inst.Light:Enable(true)
	
	
	
	-- inst:AddComponent("grue")
	
	-- inst:AddTag("the_night")
	inst:AddTag("force_postupdate") --THE MASTER POSTUPDATER NEEDS TO BE UPDATED TO INCLUDE THIS!! DST CHANGE
	
	
	inst.entity:SetPristine()
	
	
	if not TheWorld.ismastersim then
        return inst
    end
	
	inst.persists = false --YEA AND THIS

    return inst
end


return Prefab( "roguehitboxer", fn, assets) 
