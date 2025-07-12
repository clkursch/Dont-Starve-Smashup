local assets=
{
	Asset("ANIM", "anim/background_image.zip"),
}

local function fn()  --DSTCHANGES Sim
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    --MakeInventoryPhysics(inst)
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork() --DSTCHANGES
    
	
	
	
	
	
	--12-23-17 OKAY, LETS BRING THESE BACK HERE
	
	-- 12-16-17 SLOWLY FADE THE SKYBOX COLOR AS NIGHT FALLS -DST CHANGE
	-- local function UpdateSkyColor(sky, tint) 
		-- sky.AnimState:SetMultColour(0.82*tint, 0.92*tint, 1*tint, 1) 
		-- -- !!!! THE GAME SEES A SIGNIFICANT FPS DROP IF THE SKYBOX IS INVISIBLE. A SOLID BLACK DOES DOES THE SAME THING WITHOUT DROPPING PERFORMANCE
	-- end
		
	inst.entity:AddLightWatcher() -- !!!! THESE ARE VERY RESOURCE INTENSIVE!!! ---  OR ARE THEY??
	
	inst:DoPeriodicTask(0.5, function() 	
		local light = inst.LightWatcher:GetLightValue()
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		-- print("LIGHT ", light)
		
		if  light < 0.5 and light > 0.02 then
			-- UpdateSkyColor(inst, light - 0.05) --COME ON NOW, DO WE REALLY NEED 6?...
			if anchor then
				anchor.Light:Enable(true) --AND TURN THIS BOY ON TOO
			end
			
		elseif light > 0.5 then --light > 0.7 and light < 0.9 then	--CHANING THIS TO JU
			-- UpdateSkyColor(inst, 1) --SET EM ALL BACK TO NORMAL INSTANTLY
			if anchor then
				anchor.Light:Enable(false) --AND TURN THE PORCH LIGHT BACK OFF
			end
		end
	end)
	
	
	--WHEN I LAST LEFT OFF, I HADNT FINISHED IMPLIMENTING THIS NEW PREFAB YET
	
	
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	
	inst.entity:AddLightWatcher()	--THIS IS SO SILLY
	
	inst.LightWatcher:SetLightThresh(.7) --.075
	inst.LightWatcher:SetDarkThresh(.3) --0.05
	
	inst:AddComponent("grue")
	
	inst:AddTag("the_night")
	inst:AddTag("force_postupdate") --THE MASTER POSTUPDATER NEEDS TO BE UPDATED TO INCLUDE THIS!! DST CHANGE
	
	print("LIGHTSENSOR ADDED")
	
	
	
	inst.persists = false

    return inst
end

return Prefab( "common/inventory/lightsensor", fn, assets) 
