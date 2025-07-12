local assets=
{
	Asset("ANIM", "anim/visible_hitbox.zip"),
	Asset("ANIM", "anim/fight_fx.zip"),
	--4-14-20 --I THINK WE NEED TO LOAD THIS IN IF WE WANT TO USE IT ON FX HOVERBADGES
	Asset("PKGREF", "anim/effigy_topper.zip"), 
	-- Asset("ANIM", "anim/health.zip"),
	Asset("PKGREF", "anim/health.zip"),
	Asset("ANIM", "anim/status_health.zip"),
}


local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    --MakeInventoryPhysics(inst)
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork() 
	
	inst.Transform:SetTwoFaced() --1-21-22 THIS SHOULD PROBABLY GO UP HERE
	
	inst.AnimState:SetBank("fight_fx")
    inst.AnimState:SetBuild("fight_fx")
    -- inst.AnimState:PlayAnimation("lucy_archwoosh")
	
	inst.persists = false
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	--BeActive(inst) --THIS WAS DOING LITERALLY NOTHING. 
	
    return inst
end

return Prefab( "common/inventory/fight_fx", fn, assets) 