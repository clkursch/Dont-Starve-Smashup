
local MakePlayerCharacter = require "prefabs/player_common"


local assets = {

        Asset( "ANIM", "anim/player_basic.zip" ),
		Asset( "ANIM", "anim/newmaxwell.zip" ),
		Asset( "ANIM", "anim/newmaxwellskin.zip" ),
		-- Asset( "ANIM", "anim/newmaxwellblue.zip" ), --COMPILE ERROR
		-- Asset( "ANIM", "anim/newmaxwellred.zip" ), --COMPILE ERROR
		Asset( "ANIM", "anim/newmaxwellbrown.zip" ),
		
		Asset( "ANIM", "anim/newmaxwellclone.zip" ),
		Asset( "ANIM", "anim/shadow_figures.zip" ), --EXTRA FX FOR MAXWELL
}




local function onswaphurtboxes(inst,data )
	
	--EH, ONE DAY I'LL COME BACK HERE AND DO HIT HURTBOXES THE RIGHT WAY
	--MOST OF HIS PRESETS USE THE CONFUSING LEGACY METHOD OF SPAWNING HURTBOXES
	
	inst.components.hurtboxes:ResetHurtboxes()
	if data == "idle" then
		inst.components.hurtboxes:CreateHurtbox(2, 0, 2) --THE MIDDLE/ARMS
		-- inst.components.hurtboxes:CreateHurtbox(1.5, 0, 1) --2
		-- inst.components.hurtboxes:CreateHurtbox(1.2, 0, 0.25)
		-- inst.components.hurtboxes:CreateHurtbox(1.2, 0, 0.25, 1)
		-- inst.components.hurtboxes:CreateHurtbox(0, 2.5, 0.4, 0.6)
		inst.components.hurtboxes:CreateHurtbox(0.35, 0, 0.4, 1.8) --THE ENTIRE TORSO/HEAD
		-- inst.components.hurtboxes:CreateHurtbox(1.8, 0, 3)
	end
	if data == "blocking" then --HE NEEDS A SEPERATE ONE FOR BLOCKING BECAUSE HE GETS SHORTER
		inst.components.hurtboxes:CreateHurtbox(2.3, -0.1, 2)
		inst.components.hurtboxes:CreateHurtbox(2, 0, 1)
		inst.components.hurtboxes:CreateHurtbox(1.5, 0, 0.35)
		-- inst.components.hurtboxes:CreateHurtbox(1.8, 0, 3)
	end
	if data == "leanf" then
		-- print("WOWIE")
		inst.components.hurtboxes:CreateHurtbox(1.8, 0.2, 1.8)
		inst.components.hurtboxes:CreateHurtbox(2, 0.1, 1)
		inst.components.hurtboxes:CreateHurtbox(1.2, 0, 0.25)
		--inst.components.hurtboxes:CreateHurtbox(1.2, 2, 0.25)
	end
	if data == "walking" then
		inst.components.hurtboxes:CreateHurtbox(0.4, 0, 0.3, 1.8) --IDLE BUT SLIGHTLY WIDER
	end
	if data == "dashing" then
		inst.components.hurtboxes:CreateHurtbox(0.6, 0.25, 0.3, 1.7) --THE ENTIRE TORSO/HEAD
	end
	if data == "ducking" then
		inst.components.hurtboxes:CreateHurtbox(1.8, 0.6, 1)
		-- inst.components.hurtboxes:CreateHurtbox(1.8, 0, 0.25)
		inst.components.hurtboxes:CreateHurtbox(0.7, 0.15, 0.1, 0.5)
	end
	
	--TODOLIST --CLEANUPLIST -- MAKE IT SO THAT SIZE ISNT DECLARED FIRST
	if data == "sliding" then
		inst.components.hurtboxes:CreateHurtbox(1.8, -0.5, 1.5)
		inst.components.hurtboxes:CreateHurtbox(1.8, -0.2, 0.8)
		inst.components.hurtboxes:CreateHurtbox(1.2, -0.25, 0.25)
		inst.components.hurtboxes:CreateHurtbox(1.2, 0.25, 0.25)
	end

	if data == "grounded" then
		inst.components.hurtboxes:CreateHurtbox(1.2, 0.0, 0.25)
		inst.components.hurtboxes:CreateHurtbox(1.2, 0.6, 0.25)
		inst.components.hurtboxes:CreateHurtbox(1.2, -0.5, 0.25)
		inst.components.hurtboxes:CreateHurtbox(1.2, -1.2, 0.25)
	end
	if data == "air_idle" then
		-- inst.components.hurtboxes:CreateHurtbox(2.0, 0.25, 1.2)
		-- inst.components.hurtboxes:CreateHurtbox(1.2, -0.4, 0.9) --2
		inst.components.hurtboxes:CreateHurtbox(2.0, 0.25, 0.20)
		--KIND OF AN IMPORTANT PRESET, SO WE'LL UPDATE THIS ONE
		inst.components.hurtboxes:SpawnHurtbox(0.15, 0.0, 0.5, 1.0)
	end
	if data == "landing" then
		inst.components.hurtboxes:CreateHurtbox(2.0, 0.4, 1)
		inst.components.hurtboxes:CreateHurtbox(1.2, -0.4, 0.2)
		inst.components.hurtboxes:CreateHurtbox(2.8, 0.3, 0.5)
	end
	if data == "fair" then
		inst.components.hurtboxes:CreateHurtbox(2.6, 0.3, 1.7)
		inst.components.hurtboxes:CreateHurtbox(1.5, -0.4, 0.9) 
		inst.components.hurtboxes:CreateHurtbox(2.0, 0.25, 0.5)
	end
	
	if data == "lunge" then
		inst.components.hurtboxes:CreateHurtbox(2, 0.5, 1.3) --head
		-- inst.components.hurtboxes:CreateHurtbox(1.8, 0, 0.25)
		inst.components.hurtboxes:CreateHurtbox(0.7, -0.1, 0.1, 0.5)
	end
	
	if data == "hitstun1" then
		inst.components.hurtboxes:CreateHurtbox(2.2, -0.3, 1.8)
		inst.components.hurtboxes:CreateHurtbox(1.8, 0, 1) --2
		inst.components.hurtboxes:CreateHurtbox(1.2, 0.1, 0.25)
	end
	if data == "hitstun2" then
		inst.components.hurtboxes:CreateHurtbox(2.2, -1, 1.0)
		inst.components.hurtboxes:CreateHurtbox(2, 0, 1) --2
		inst.components.hurtboxes:CreateHurtbox(1.8, 0.1, 0.25)
	end
	if data == "hitstun3" then
		inst.components.hurtboxes:CreateHurtbox(2.2, -0.3, 1.8)
		inst.components.hurtboxes:CreateHurtbox(1.8, 0, 1) --2
		inst.components.hurtboxes:CreateHurtbox(1.3, 0.55, 0.65)
	end
	if data == "ledge_hanging" then
		inst.components.hurtboxes:CreateHurtbox(1.2, 0.12, -1)
		inst.components.hurtboxes:CreateHurtbox(1.2, 0, -0.35)
	end
	if data == "ftilt" then
		inst.components.hurtboxes:CreateHurtbox(0.6, -0.35, 0.3, 1.5) --THE ENTIRE TORSO/HEAD
		-- inst.components.hurtboxes:CreateHurtbox(2, 0.25, 0.8) --bit of leg
	end
end


--11-19-17 FIRST TEST OF THE NEW CUSTOM SKINNER, WHICH AUTO SWITCHES TO A DIFFERENT SKIN IF A DITTO IS PRESENT
local function Reskinner(inst)
    local ents = TheSim:FindEntities(0,0,0, 100, {"player"})
	for k, v in pairs(ents) do --SEARCH THROUGH ALL CURRENT PLAYERS ON SCREEN
		-- if v.prefab == inst.prefab then  --HAS TO SEARCH SPECIFICALLY FOR "NEWMAXWELL", BECAUSE OUR PREFAB NAME ISNT DEFINED YET
		if v.prefab == "newmaxwell" then --IF ANY OF THEM ARE THE SAME PLAYER AS US
			inst.components.stats.buildname = "newmaxwellskin" --GIVE OURSELVES THIS OTHER SKIN
		end
		print("PINK IS STILL DAPPER, RIGHT??",  v.prefab, inst.prefab)
	end
end



-- This initializes for both clients and the host
local common_postinit = function(inst) 
	
	inst.components.stats.bankname = "newmaxwell"  --"newwilson" 
	inst.components.stats.buildname = "newmaxwell"
	inst.components.stats.altskins = NEWMAXWELL_SKINS --NAMES OF ANY SKINS
	
	-- Reskinner(inst) --11-19-17 CHECK FOR AUTO-RESKIN
	
	-- inst.AnimState:SetBank(inst.components.stats.bankname)
	-- inst.AnimState:SetBuild(inst.components.stats.buildname)
	
	
	inst.components.stats.facepath = "minimap/minimap_data.xml"
	inst.components.stats.facefile = "waxwell.png"

	inst.components.stats.sizemultiplier = 1
	inst.Transform:SetScale(inst.components.stats.sizemultiplier,inst.components.stats.sizemultiplier,inst.components.stats.sizemultiplier)
	
	-- inst.components.stats.stategraphname = "SGnewmaxwell"
	inst:SetStateGraph("SGnewmaxwell")
	
	inst:DoPeriodicTask(0.4, function() 
		if inst:HasTag("heel") then
			inst.components.hitbox:MakeFX("glint", 0, 2.2, 0.2,   1.7, 1.7,   1.0, 8, 0.0,  -1, -1, -1,   2) 
		end
	end)
	
	-- choose which sounds this character will play
	inst.soundsname = "wilson"
	-- Minimap icon
end

-- This initializes for the host only
local master_postinit = function(inst)

	
	inst.components.stats.gravity = 0.87
	inst.components.stats.fallingspeed = 1.5
	inst.components.stats.weight = 98
	
	inst.Physics:SetFriction(.7) --OH RIGHT. DONT FORGET THESE FOR THE OTHER CHARACTERS
	inst.Physics:SetCapsule(0.25, 1)
	
	
	-- inst.components.hurtboxes:CreateLedgeGrabBox(0.4, 1.7, 1.5, 0.5, 0)
	inst.components.hurtboxes:CreateLedgeGrabBox(0.4, 2.2, 1.5, 0.8, 0) --REUSEABLE - CHANGED MAXWELL'SGRABBOX HIEGHT
	inst.components.hurtboxes:SpawnPlayerbox(0, 0.7, 0.35, 1.7, 0)
	
	
	inst.components.locomotor.runspeed = 0.9 * 5 --1.1
	inst.components.locomotor.dashspeed = 1.4 * 5 --1.5 
	
	
	-- inst.components.hurtboxes:CreateHurtbox(1.2, -2, 0.25)
	
	inst:ListenForEvent("swaphurtboxes", function(inst, data)
			onswaphurtboxes(inst, data.preset)
		end)
		
	--1-30-22 TO INCREASE THE KB OF THE FLAMES
	inst:DoPeriodicTask(5, function()
		inst.components.stats.storagevar4 = math.max(inst.components.stats.storagevar4 - 1, -1)
	end)
	
	
	-- a minimap icon must be specified
	inst.soundsname = "wilson"
	
end



return MakePlayerCharacter("newmaxwell", nil, assets, common_postinit, master_postinit, nil)
