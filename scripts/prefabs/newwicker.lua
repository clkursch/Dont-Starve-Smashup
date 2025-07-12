
local MakePlayerCharacter = require "prefabs/player_common"


local assets = {
        -- Asset( "ANIM", "anim/player_basic.zip" ),
		Asset( "ANIM", "anim/newwickerbottom.zip" ),
		Asset( "ANIM", "anim/newwickerbottomskin.zip" ),
		Asset( "ANIM", "anim/newwickerbottomgrey.zip" ), --COMPILE ERROR
		Asset( "ANIM", "anim/newwickerbottomblack.zip" ), --COMPILE ERROR
}

local function onswaphurtboxes(inst, data)
--print("DATA", data)
	inst.components.hurtboxes:ResetHurtboxes()
	if data == "idle" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.4, 1.15) --A BIT SMALLER
	end
	if data == "leanf" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.45, 0.6)
		inst.components.hurtboxes:SpawnHurtbox(.2, 1.1, 0.45, 0.5)
	end
	if data == "walking" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.45, 1.15)
	end
	if data == "dashing" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.5, 0.5)
		inst.components.hurtboxes:SpawnHurtbox(.2, 1.0, 0.55, 0.55)
	end
	if data == "ducking" then
		inst.components.hurtboxes:SpawnHurtbox(0.05, 0.0, 0.5, 0.7)
	end
	if data == "sliding" then
		inst.components.hurtboxes:CreateHurtbox(1.8, -0.5, 1.0)
		inst.components.hurtboxes:CreateHurtbox(1.8, -0.2, 0.8)
		inst.components.hurtboxes:CreateHurtbox(1.2, -0.25, 0.25)
		inst.components.hurtboxes:CreateHurtbox(1.2, 0.25, 0.25)
	end
	
	if data == "forward" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.65, 0.5)
		inst.components.hurtboxes:SpawnHurtbox(.4, 0.9, 0.6, 0.5)
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
		if v.prefab == "newwicker" then --IF ANY OF THEM ARE THE SAME PLAYER AS US
			inst.components.stats.buildname = "newwickerbottomskin" --GIVE OURSELVES THIS OTHER SKIN
		end
	end
end



-- This initializes for both clients and the host
local common_postinit = function(inst) 
	
	inst.components.stats.altskins = NEWWICKER_SKINS
	inst.components.stats.bankname = "newwilson"  --SKELETON
	inst.components.stats.buildname = "newwickerbottom" --SPRITES
	
	-- Reskinner(inst) --11-19-17 CHECK FOR AUTO-RESKIN
	
	-- inst.AnimState:SetBank(inst.components.stats.bankname)
	-- inst.AnimState:SetBuild(inst.components.stats.buildname)
	
	-- inst.components.stats.altskins = {"newwickerbottomskin"}
	
	inst.components.stats.facepath = "minimap/minimap_data.xml"
	inst.components.stats.facefile = "wickerbottom.png"

	inst.components.stats.sizemultiplier = 1
	inst.Transform:SetScale(inst.components.stats.sizemultiplier,inst.components.stats.sizemultiplier,inst.components.stats.sizemultiplier)
	
	-- inst.components.stats.stategraphname = "SGnewwickerbottom"
	inst:SetStateGraph("SGnewwickerbottom")
	
	
	-- choose which sounds this character will play
	inst.soundsname = "wilson"
	-- Minimap icon
end

-- This initializes for the host only
local master_postinit = function(inst)

	
	inst.components.stats.gravity = 0.77 --0.87
	inst.components.stats.fallingspeed = 1.5
	inst.components.stats.weight = 80 --TAKING HER DOWN FROM 98 BECAUSE SHE NEEDS SOME SORT OF NERF 10-20-17
	
	inst.components.stats.jumpheight = 17 --SLIGHTLY LOWER BECAUSE OF FLOATINESS
	inst.components.stats.doublejumpheight = 18
	
	
	inst.components.hurtboxes:CreateLedgeGrabBox(0.4, 1.7, 1.5, 0.5, 0)
	-- inst.components.hurtboxes:SpawnPlayerbox(0, 0, 0.35, 1, 0)
	inst.components.hurtboxes:SpawnPlayerbox(0, 0.7, 0.35, 0.7, 0)
	
	--ZELDA'S, MAYBE
	inst.components.locomotor.runspeed = 0.95 * 5 
	inst.components.locomotor.dashspeed = 1.3 * 5 
	inst.components.stats.air_speed = 1.05 * 5

	inst:ListenForEvent("swaphurtboxes", function(inst, data)
		onswaphurtboxes(inst, data.preset)
	end)
	
	
	-- a minimap icon must be specified
	inst.soundsname = "wilson"
	
	--NUMBER OF TENTACLES SHE CAN SPAWN PER LIFE
	inst.components.stats.storagevar1 = 3 
	inst:ListenForEvent("onko", function() 
		inst.components.stats.storagevar1 = 3 
	end)
	
	
	inst:DoTaskInTime(0.2, function() 

		
	end)
	
end



return MakePlayerCharacter("newwicker", nil, assets, common_postinit, master_postinit, nil)
