local assets=
{
	Asset("ANIM", "anim/visible_hitbox.zip"),
	Asset("ANIM", "anim/fight_fx.zip"),
}


local function BeActive(inst)
   
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	
	--12-31-21 
	if not anchor then
		-- print("HOST CAMPREFAB WAS UNABLE TO FIND ANCHOR!")
		return end
	
	local x1, y1, z1 = anchor.Transform:GetWorldPosition()
	
	local center_stage = x1
	local bottom_stage = y1
   
	inst:DoPeriodicTask(0, function(inst)
		
		anchor = TheSim:FindFirstEntityWithTag("anchor")
		if not anchor then
			-- anchor = ThePlayer --I GUESS??
			return
		end
		
		
		--11-1-16 GONNA TRY SOMETHING FANCY WITH THE CAMERA
		local maxleft = center_stage - 64 -- -100
		local maxright = center_stage + 64
		local maxleftplayer = anchor --ThePlayer --DST CHANGE-- YEA THIS CANT STAY LIKE THIS
		local maxrightplayer = anchor 
		
		local maxlow = bottom_stage - 60 --HM.. HOW ABOUT FOR Y VALUES??? FORGET THIS MAXPLAYER STUFF, JUST TAKE THE VALUES
		local maxhigh = bottom_stage + 60
		
		local nplayers = 0 --TESTS NUMBER OF PLAYERS ON SCREEN BC I'D RATHER JUST HAVE THE CAMERA FREEZE WHEN SOMEONE GETS KO'D
		for k,v in pairs(anchor.components.gamerules.livingplayers) do --HAHAAAAA IT WORKS!  CHANGE PLAYER TO THE ANCHOR
			if v:IsValid() then --!!DONT FORGET THIS PART
				local x, y, z = v.Transform:GetWorldPosition()
				if x >= maxleft then
					maxleft = x
					maxleftplayer = v
				end
				
				if x <= maxright then
					maxright = x
					maxrightplayer = v
				end
				
				if y <= maxhigh then
					maxhigh = y
				end
				
				if y >= maxlow then
					maxlow = y
				end
				
				nplayers = nplayers + 1
			end
		end
		
		local player1 = maxleftplayer
		local player2 = maxrightplayer
		
		--1-16-22 THIS WOULD HAVE BEEN AN EASY ADDITION TO SAVE A LOT OF WEIRD CAMER ANGLES A LONG TIME AGO
		maxleft = math.clamp(maxleft, -27, 27)
		maxright = math.clamp(maxright, -27, 27)
		maxlow = math.clamp(maxlow, -12, 12)
		maxhigh = math.clamp(maxhigh, -17, 17)
		
		local x1 = maxleft
		local y1 = maxlow
		local x2 = maxright
		local y2 = maxhigh
		

		if nplayers > 0 and not anchor.components.gamerules.freezecam == true then --11-11-16 ADDING FREEZE TEST
			local x1rr, y1rr, z1 = player1.Transform:GetWorldPosition() --OH WAIT, I STILL NEED ONLY THE Z VALUES
			local x2rr, y2rr, z2 = player2.Transform:GetWorldPosition()
			
			local xoffset = ((x2 - x1) /2)
			local yoffset = ((y2 - y1) /2)
			local zoffset = ((z2 - z1) /2)
			
			
			local x = x1 + xoffset
			local y = y1 + yoffset
			
			if xoffset <= 0 then
				xoffset = xoffset
			else
				xoffset = -xoffset --12-4 OH MY GOD I AM JUST REAL DUMB.  --WAIT NOOO IT DOESNT WORK --WAIT YES IT DOES. IT JUST NEEDS Y TOO
				yoffset = -yoffset --THIS JUST SWITCHES WHICH SIDE THE ERROR IS ON
			end
			if yoffset <= -0 then
				yoffset = yoffset
			else
				yoffset = -yoffset
			end
			
			local distoffset = ((xoffset + ((yoffset)*2)) /1) * 1.5
			
			
			--12-3-17 ACTUALLY... LETS TRY A LITTLE COMPETITION. ONLY THE AXIS WITH THE LARGEST OFFSET WILL BE COUNTED TOWARD DISTANCE OFFSET >:3c
			local xdiffoffset = ((xoffset + ((0)*2)) /1) * 1.5
			local ydiffoffset = ((0 + ((yoffset)*2)) /1) * 1.5 --ACTUALLY, THIS FEELS KIND OF JARRING... LETS ADD JUST A TIIINY BIT OF THE OTHER AXIS TO IT
			--SINCE WE ONLY NEED TO ZOOM OUT BASED ON WHICH AXIS NEEDS TO BE ZOOMED OUT ON
			if xdiffoffset <= ydiffoffset then
				distoffset = xdiffoffset  --PERFECT!~
			else
				distoffset = ydiffoffset
			end
			
			
			if distoffset < -27 then --1-11-22 WAIT CAMDIST IS NEGATIVE, IM STUPID
				distoffset = -27
			end
			
			--12-3-17 IM GONNA TRY AND DO SOMETHING ABOUT THESE WEIRD CAMERA SHIFTS AT EXTREME DISTANCES
			local distanceslack = 0 
			local xdistanceslack = 0--WHICHEVER ONE OF THESE IS HIGHER WILL END UP BEING THE ONLY ONE USER
			local ydistanceslack = 0--EITHER X OR Y
			-- PAST A CERTAIN POINT, THE CAMERA WONT GO ANY HIGHER. BUT WILL CONTINUE TO ZOOM OUT THE HIGHER WE GO. SO WE NEED TO COUNT HIGHT AND REDUCE ZOOM
			if y >= (bottom_stage + 10) - (-distoffset/4) then
				ydistanceslack = (y - ((bottom_stage + 10) - (-distoffset/4))) * 1.0 --12-17-17 CHANGING TO *1. THE *3 MULT MAKES IT ZOOM IN SUPER CLOSE WHEN BOTH ARE TOP SCREEN
			elseif  y <= (bottom_stage - 4) + (-distoffset/4) then --5 THESE BOUNDS ARE TAKEN FROM DOWN BELOW, SO IF YOU CHANGE THEM, MAKE SURE TO CHANGE BOTH
				ydistanceslack = (((bottom_stage - 4) + (-distoffset/4)) - y) * 0.5
			end
			
			--OKAY, NOW LETS TRY THE X AXIS
			local cambounds = 15--21
			if x >= (center_stage + cambounds) - (-distoffset/2) then
				xdistanceslack = (x - ((center_stage + cambounds) - (-distoffset/2))) / 2
			elseif x <= (center_stage - (cambounds)) + (-distoffset/2) then
				--x = (center_stage - (cambounds)) + (-distoffset/2)
			end
			
			local z = z1 + distoffset + ydistanceslack
			
			if distoffset <= 0 then
				z = z1 - distoffset - ydistanceslack
			end
			-- print("CAMDIST: ", distoffset, ydistanceslack)
			
			
			local cambounds = 18
			
			--12-28 REDOING
			if x >= (center_stage + cambounds) - (-xdiffoffset/2) then
				x = (center_stage + cambounds) - (-xdiffoffset/2)
			elseif x <= (center_stage - (cambounds)) + (-xdiffoffset/2) then
				x = (center_stage - (cambounds)) + (-xdiffoffset/2)
			end
			
			--3-17, OKAY ^^^^ GONNA TRY AND MAKE THAT FOR BOTTOM STAGE TOO... HOPE I DONT MESS IT UP --COOL I DIDNT BREAK IT
			if y >= (bottom_stage + 10) - (-distoffset/4) then
				y = (bottom_stage + 10) - (-distoffset/4) --4-14 REDUCING FROM 11 TO 10
			elseif  y <= (bottom_stage - 4) + (-distoffset/4) then --5 SEEMS LIKE A GOOD BOTTOM BOUNDS
				y = (bottom_stage - 4) + (-distoffset/4)	--12-3-17 CHANGING IT TO 4 BECAUSE ITS JUST HIGH ENOUGH TO PREVENT THE TILES FROM SHOWING
			end
			
			y = y + 0.5 --11-10-16 CAN I JUST BUMP THE CAMERA UP A LITTLE?? FOR THE TALL PEOPLE?
			
			inst.Transform:SetPosition( x, y, z )
		end
	end)
end


--12-31-21 TIDY UP A BIT. IT MESSY IN HERE
local function SetCameraTarget(inst)
	inst:DoTaskInTime(0.1, function() --11-1-16 ADDING A SLIGHT DELAY TO ALLOW PLAYERS TO ASSUME THEIR RESPECTIVE PLAYER NUMBER TAGS AND SUCH
		TheCamera:SetTarget(inst)
	end)
	
	-- print("CAMERA PREFAB FOUND THE ANCHOR SUCCESFULY")
end



local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    --MakeInventoryPhysics(inst)
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork() --DSTCHANGES
	
	
	inst.persists = false
	
    --[[
    inst.AnimState:SetBank("visible_hitbox")
    inst.AnimState:SetBuild("visible_hitbox")
    inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetMultColour(0.0,0.0,0.0,0) --MAKES CAM PREFAB INVISIBLE
	-- inst.AnimState:SetMultColour(0.3,0.3,0.3,0.3) --MAKES CAM PREFAB VISIBLE
	]]
	
	-- inst:AddComponent("gamerules") --12-24
	-- inst.components.gamerules:ApplyBlastZones(inst) --12-24 WHY DO I PUT ALL THE GAME RELATED STUFF ON THE CAMERA PREFAB???
	
	
	

	inst:AddTag("cameraprefab")
	
	--12-31-21 A LITTLE OVERHAULT TO HOPEFULLY ENSURE THAT THIS PART DOESNT GET SKIPPED --THIS SEEMED TO WORK
	inst.camsnaptask = inst:DoPeriodicTask(0.1, function()
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
	
		if anchor then -- OKAY, CHECK TO SEE IF ANCHOR EXISTS FIRST TO HOPEFULLY FIX FOR CLIENT--
			SetCameraTarget(inst)
			inst.camsnaptask:Cancel() --AND END IT SO IT DOESNT LOOP
			inst.camsnaptask = nil
		else
			-- print("WARNING!!!! ANCHOR NOT FOUND!!!")
		end
	end)
	
	
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
        return inst
    end
	
	
	BeActive(inst) --DO THE THING
	
	
    return inst
end

return Prefab( "common/inventory/cameraprefab", fn, assets) 
