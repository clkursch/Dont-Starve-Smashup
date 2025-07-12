local assets=
{
	Asset("ANIM", "anim/background_image.zip"),
}

local function fn()  --DSTCHANGES Sim
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork() 
    
    inst.AnimState:SetBank("background_image")
    inst.AnimState:SetBuild("background_image")
    inst.AnimState:PlayAnimation("idle")

	inst.AnimState:SetAddColour(0.2, 0.2, 0.2, 1) 
	
	-- 12-16-17 SLOWLY FADE THE SKYBOX COLOR AS NIGHT FALLS -DST CHANGE
	local function UpdateSkyColor(sky, tint) 
		sky.AnimState:SetMultColour(0.52*tint, 0.82*tint, 1*tint, 1) 
		-- !!!! THE GAME SEES A SIGNIFICANT FPS DROP IF THE SKYBOX IS INVISIBLE. A SOLID BLACK DOES DOES THE SAME THING WITHOUT DROPPING PERFORMANCE
	end
		
	inst.entity:AddLightWatcher() -- !!!! THESE ARE VERY RESOURCE INTENSIVE!!! ---  OR ARE THEY??
	
	inst:DoPeriodicTask(0.5, function() 	
		local light = inst.LightWatcher:GetLightValue()
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		-- print("LIGHT ", light)
		if  light < 0.5 and light > 0.02 then
			UpdateSkyColor(inst, light - 0.05) --COME ON NOW, DO WE REALLY NEED 6?...
		elseif light > 0.5 then --light > 0.7 and light < 0.9 then	--CHANING THIS TO JU
			UpdateSkyColor(inst, 1) --SET EM ALL BACK TO NORMAL INSTANTLY
		end
	end)
	
	
	
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	
	inst.persists = false

    return inst
end

return Prefab( "common/inventory/background", fn, assets) 
