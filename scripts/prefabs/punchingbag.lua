
local MakePlayerCharacter = require "prefabs/player_common"


local assets = {

        Asset( "ANIM", "anim/player_basic.zip" ),
		Asset( "ANIM", "anim/punchingbag.zip" ),

}


local function onswaphurtboxes(inst, data)
--print("DATA", data)
	inst.components.hurtboxes:ResetHurtboxes()
	if data == "idle" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.45, 1.15)
	end
	if data == "dashing" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.5, 0.5)
		inst.components.hurtboxes:SpawnHurtbox(.45, 1.0, 0.55, 0.45)
		
	end
	if data == "ducking" then
		inst.components.hurtboxes:SpawnHurtbox(0.05, 0.0, 0.5, 0.7)
	end
	
	if data == "sliding" then
		inst.components.hurtboxes:SpawnHurtbox(-0.1, 0.0, 0.55, 0.45)
		-- inst.components.hurtboxes:SpawnHurtbox(0.7, 0.0, 0.2)
		inst.components.hurtboxes:SpawnHurtbox(-0.40, 0.6, 0.45)
	end

	if data == "grounded" then
		inst.components.hurtboxes:SpawnHurtbox(-0.3, 0.0, 1.15, 0.28)
	end
	if data == "air_idle" then
		inst.components.hurtboxes:SpawnHurtbox(0.05, -0.1, 0.5, 0.9) --not bad...
	end
	if data == "landing" then
		--CAN I DO THIS HERE??
		inst.components.hurtboxes:SpawnHurtboxTemp(0.35, 0.75, 0.45, 0, 4)
		inst.components.hurtboxes:SpawnHurtbox(0.15, 0.0, 0.67, 0.60) 
	end
	if data == "fair" then
		inst.components.hurtboxes:SpawnHurtbox(0.3, 0.3, 0.7, 0.7)
	end
	
	if data == "hitstun1" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.45, 0.6)
		inst.components.hurtboxes:SpawnHurtbox(-0.2, 1.2, 0.45, 0.5)
	end
	if data == "hitstun2" then
		inst.components.hurtboxes:SpawnHurtbox(-0.3, 0.7, 1.0, 0.4)
		inst.components.hurtboxes:SpawnHurtbox(0.4, 0.0, 0.4)
		
	end
	if data == "hitstun3" then
		inst.components.hurtboxes:SpawnHurtbox(0.2, 0.2, 0.7, 0.8)
		-- inst.components.hurtboxes:SpawnHurtbox(-0.2, 1.2, 0.45, 0.5)
	end
	if data == "ledge_hanging" then
		inst.components.hurtboxes:SpawnHurtbox(-0.2, -1.7, 0.3, 0.7)
	end
	--inst.components.launchgravity:GetRotationFunction()
end



local function CheckForRecovery(inst)
    
	
	
end



-- This initializes for both clients and the host
local common_postinit = function(inst) 
	inst:AddTag("autorespawn")
	inst:AddTag("punchingbag")
	
	inst.components.stats.bankname = "punchingbag"  --"newwilson" 
	inst.components.stats.buildname = "punchingbag"
	
	inst.components.stats.altskins = {"punchingbag"}
	
	-- inst.AnimState:SetBank(inst.components.stats.bankname)
	-- inst.AnimState:SetBuild(inst.components.stats.buildname)
	
	inst.components.stats.facepath = "minimap/minimap_data.xml"
	inst.components.stats.facefile = "resurrect.png" --4-3-19 MUCH BETTER  "scarecrow.png"

	inst.components.stats.sizemultiplier = 1.0
	inst.Transform:SetScale(inst.components.stats.sizemultiplier,inst.components.stats.sizemultiplier,inst.components.stats.sizemultiplier)
	
	-- inst.components.stats.stategraphname = "SGpunchingbag"
	inst:SetStateGraph("SGpunchingbag")
	
	-- inst:PushEvent("alterdisplayname", {name="Training Dummy"}) --11-27-20 THIS SUCKED. LETS TRY SOMETHING ELSE
	inst.components.stats.displayname = "Training Dummy" --11-27-20
	
	
	-- choose which sounds this character will play
	inst.soundsname = "wilson"
	-- Minimap icon
	inst.MiniMapEntity:SetIcon( "resurrect.tex" )
end


-- This initializes for the host only
local master_postinit = function(inst)
	
	inst:SetStateGraph("SGpunchingbag")
	
	inst.components.stats.gravity = 0.87
	inst.components.stats.fallingspeed = 1.5
	inst.components.stats.weight = 98
	
	
	inst.components.hurtboxes:CreateLedgeGrabBox(0.4, 1.7, 1.5, 0.5, 0)
	-- inst.components.hurtboxes:SpawnPlayerbox(0, 0, 0.35, 1, 0)
	inst.components.hurtboxes:SpawnPlayerbox(0, 0.7, 0.35, 0.7, 0)
	
	
	inst.components.locomotor.runspeed = 1.1 * 5 --6
	inst.components.locomotor.dashspeed = 1.6 * 5 --MARIOS   

	
	
	-- a minimap icon must be specified
	inst.MiniMapEntity:SetIcon( "resurrect.tex" )
	inst.soundsname = "wilson"
	
	
	inst:ListenForEvent("swaphurtboxes", function(inst, data)
		onswaphurtboxes(inst, data.preset)
	end)
	
	
	
	local recoverangle = "high"
	local choserecovery = false
	
	--SWAPS BETWEEN HIGH AND LOW TO MIX IT UP A BIT
	inst:DoPeriodicTask(2, function() --THIS IS KIND OF A WEIRD WAY TO DO IT BUT OH WELL
		if math.random() >= 0.5 then
			recoverangle = "low"
		else
			recoverangle = "high"
		end
	end)
	
	
	--MINI BRAIN
	inst:DoPeriodicTask(0.1, function() 
		
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		
		local center_stage = anchor.components.gamerules.center_stage
		local mypos, myposy = inst.Transform:GetWorldPosition()
		
		
		if inst.components.launchgravity:GetIsAirborn() and mypos <= (anchor.components.gamerules.lledgepos + 0) or mypos >= (anchor.components.gamerules.rledgepos - 0) then --7-31
			inst:RemoveTag("holdleft")
			inst:RemoveTag("holdright")
			--self.status = RUNNING
			
			-- if math.random() >= 0.6 and choserecovery == false then
				-- recoverangle = "high"
			-- end
			-- choserecovery = true
			
			--[[
			else
				-- self.status = FAILED
				recoverangle = "low" --IS LOW BY DEFAULT
				choserecovery = false
			end
			]]--
		
			-- end

			-- if self.status == RUNNING then
			
			
			local center_stage = anchor.components.gamerules.center_stage
			-- local mypos, myposy = inst.Transform:GetWorldPosition()
			local myvelx, myvely = inst.Physics:GetVelocity()
			
			if mypos <= center_stage then
				inst:AddTag("holdleft")
			else
				inst:AddTag("holdright")
			end
			
			
			if myposy <= -3 or (recoverangle == "high" and myposy <= 12 ) then --12-28-16 JUMP EARLY IF RECOVERING HIGH.
				inst:PushEvent("jump")   
				
				--NO UP-SPECIAL RECOVERY. TOO STUPID TO DO THAT (SO ARE MOST BEGINNER SMASH PLAYERS. SO NOW ITS EVEN)
				if inst.components.jumper.currentdoublejumps == 0 and myvely < 0 and myposy <= (-3 + math.random(-1, 1)) then
					inst:PushEvent("throwspecial", {key = "up"})
				end
				
			end
		
		
		else
			inst:RemoveTag("holdleft")
			inst:RemoveTag("holdright")
		end
		
	end)
	
end



return MakePlayerCharacter("punchingbag", nil, assets, common_postinit, master_postinit, nil)
