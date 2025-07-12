
local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
		Asset( "ANIM", "anim/player_basic.zip" ),
		Asset( "ANIM", "anim/newwoodie.zip" ),
		Asset( "ANIM", "anim/newwoodieskin.zip" ),
		Asset( "ANIM", "anim/newwoodiecyan.zip" ),
	Asset( "ANIM", "anim/newwoodiegrey.zip" ),
}


local function onswaphurtboxes(inst, data)
--print("DATA", data)
	inst.components.hurtboxes:ResetHurtboxes()
	if data == "idle" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.5, 1.15)
	end
	if data == "leanf" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.45, 0.6)
		inst.components.hurtboxes:SpawnHurtbox(.2, 1.1, 0.45, 0.5)
	end
	if data == "walking" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.5, 1.15)
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
		inst.components.hurtboxes:SpawnHurtbox(-0.40, 0.6, 0.45)
	end

	if data == "grounded" then
		inst.components.hurtboxes:SpawnHurtbox(-0.3, 0.0, 1.15, 0.28)
	end
	if data == "air_idle" then
		inst.components.hurtboxes:SpawnHurtbox(0.05, -0.1, 0.5, 0.9)
	end
	if data == "landing" then
		inst.components.hurtboxes:SpawnHurtboxTemp(0.35, 0.75, 0.45, 0, 4)
		inst.components.hurtboxes:SpawnHurtbox(0.15, 0.0, 0.7, 0.60)
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
	end
	if data == "ledge_hanging" then
		inst.components.hurtboxes:SpawnHurtbox(-0.2, -1.7, 0.3, 0.7)
	end
end


--CUSTOM SKINNER, WHICH AUTO SWITCHES TO A DIFFERENT SKIN IF A DITTO IS PRESENT
local function Reskinner(inst)
    local ents = TheSim:FindEntities(0,0,0, 100, {"player"})
	for k, v in pairs(ents) do --SEARCH THROUGH ALL CURRENT PLAYERS ON SCREEN
		if v.prefab == "newwoodie" then --IF ANY OF THEM ARE THE SAME PLAYER AS US
			inst.components.stats.buildname = "newwoodieskin" --GIVE OURSELVES THIS OTHER SKIN
		end
	end
end


-- This initializes for both clients and the host
local common_postinit = function(inst) 
	inst:AddTag("woodie")
	
	inst.components.stats.bankname = "newwoodie"  --"newwilson" 
	inst.components.stats.buildname = "newwoodie"
	
	-- Reskinner(inst) --11-19-17 CHECK FOR AUTO-RESKIN
	inst.components.stats.altskins = NEWWOODIE_SKINS --{"newwoodieskin"} --NAMES OF ANY SKINS
	
	-- inst.AnimState:SetBank(inst.components.stats.bankname)
	-- inst.AnimState:SetBuild(inst.components.stats.buildname)
	
	
	
	inst.components.stats.facepath = "minimap/minimap_data.xml"
	inst.components.stats.facefile = "woodie.png"

	inst.components.stats.sizemultiplier = 1.1 --FOR WOODIE
	inst.Transform:SetScale(inst.components.stats.sizemultiplier,inst.components.stats.sizemultiplier,inst.components.stats.sizemultiplier)
	
	
	-- inst.components.stats.stategraphname = "SGnewwoodie" --NEW FOR PLAYER SPAWNING
	inst:SetStateGraph("SGnewwoodie")
	
	
	-- choose which sounds this character will play
	inst.soundsname = "woodie"
	-- Minimap icon
	
	
	--11-24-21 CREATE A LUCY AND PUT IT IN OUR INVENTORY --NO NO, I KNEW THIS WAS A DUMB IDEA
	-- inst:DoTaskInTime(0.5, function() 
		-- local itslucy = SpawnPrefab("lucy")
		-- inst.components.inventory:GiveItem(itslucy)
		-- inst.components.stats.storagevar3 = itslucy --AND NOW WE CAN REFERENCE IT WITHIN OUR STATEGRAPH!
	-- end)
end

-- This initializes for the host only
local master_postinit = function(inst)

	
	inst.components.stats.gravity = 0.87
	inst.components.stats.fallingspeed = 1.5
	inst.components.stats.weight = 98
	
	inst.components.stats.jumpheight = 18 --WOODIE JUMPS A LIL LOWER
	
	inst.components.hurtboxes:CreateLedgeGrabBox(0.4, 1.7, 1.5, 0.5, 0)
	inst.components.hurtboxes:SpawnPlayerbox(0, 0.7, 0.35, 0.7, 0)
	
	
	inst.components.locomotor.runspeed = 1.1 * 5
	inst.components.locomotor.dashspeed = 1.5 * 5

	inst:ListenForEvent("swaphurtboxes", function(inst, data)
		onswaphurtboxes(inst, data.preset)
	end)
	
	-- a minimap icon must be specified
	inst.soundsname = "woodie"
end

--11-24-21 GONNA TRY SOMETHING KINDA WEIRD. GIVING FIGHTER WOODIE THE LUCY ITEM IN HIS INVENTORY SO IT CAN TALK
-- local start_inv = {	--ACTUALLY, LETS TRY AND SPAWN IT POST-LOAD SO WE CAN REFERENCE IT EASIER
	-- "lucy",
-- }

return MakePlayerCharacter("newwoodie", nil, assets, common_postinit, master_postinit, nil)
