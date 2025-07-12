
local MakePlayerCharacter = require "prefabs/player_common"


local assets = {

        --Asset( "ANIM", "anim/player_basic.zip" ),
		--Asset( "ANIM", "anim/smashtemplate.zip" ),
		--Asset( "ANIM", "anim/reflectorbox.zip" ), --SINCE HE USES THIS IN HIS ANIMATIONS
		-- Asset( "ANIM", "anim/smashtemplateblue.zip" ), --DOESNT EXIST DUMMY

}

local function onswaphurtboxes(inst, data)
	inst.components.hurtboxes:ResetHurtboxes()
	if data == "idle" then
		inst.components.hurtboxes:CreateHurtbox(2.5, 0, 0.6)
		inst.components.hurtboxes:SpawnPlayerbox(0, 0, 0.35, 0.7, 0)
	end

	if data == "ducking" then
		inst.components.hurtboxes:CreateHurtbox(2.3, 0, 0.5)
		inst.components.hurtboxes:SpawnPlayerbox(0, 0, 0.35, 0.7, 0)
	end
	
	if data == "ledge_hanging" then
		inst.components.hurtboxes:CreateHurtbox(1.2, 0.12, -1)
		inst.components.hurtboxes:CreateHurtbox(1.2, 0, -0.35)
	end
end




-- This initializes for both clients and the host
local common_postinit = function(inst) 
	
	inst.components.stats.altskins = SPIDER_PLAYER_SKINS
	inst.components.stats.bankname = "spiderfighter"   
	-- inst.components.stats.buildname = SPIDER_PLAYER_SKINS[1] --"spider_fighter_build"
	--spider_warrior_build
	
	-- inst.AnimState:SetBank(inst.components.stats.bankname)
	-- inst.AnimState:SetBuild(inst.components.stats.buildname)
	
	inst.components.stats.facepath = "minimap/minimap_data.xml"
	inst.components.stats.facefile = "spiderden.png"

	inst.components.stats.sizemultiplier = 0.85 
	inst.Transform:SetScale(inst.components.stats.sizemultiplier,inst.components.stats.sizemultiplier,inst.components.stats.sizemultiplier)
	
	-- inst.components.stats.stategraphname = "SGspider_player" 
	inst:SetStateGraph("SGspider_player")
		
	-- choose which sounds this character will play
	inst.soundsname = "wilson"
end

-- This initializes for the host only
local master_postinit = function(inst)

	
	inst.components.stats.gravity = 1
	inst.components.stats.fallingspeed = 1.5 
	--inst.components.stats.fastfallingspeedincrease = 0.15  --MELEE SPACIES HAVE A MUCH LOWER FASTFALL INCREASE
	--inst.components.stats.basefallingspeed = 3.1 --OH... ITS CUZ YOU NEED THIS ONE TOO...
	inst.components.stats.weight = 85   --MARIO: 98
	--inst.components.stats.air_friction = 0.02 --MELEE FALCO
	
	inst.components.stats.jumpheight = 19 --20 DEFAULT
	inst.components.stats.doublejumpheight = 21 --20 DEFAULT
	inst.components.stats.shorthopheight = 13 --12 DEFAULT
	inst.components.stats.air_speed = 1.15 * 5 --1.05 * 5
	
	
	inst.components.hurtboxes:CreateLedgeGrabBox(0.4, 1.7, 1.5, 0.5, 0)
	inst.components.hurtboxes:SpawnPlayerbox(0, 0.7, 0.35, 0.7, 0)
	
	
	inst.components.locomotor.runspeed = 1.3 * 5 --6
	inst.components.locomotor.dashspeed = 1.8 * 5 --MARIOS: 1.6  

	inst:ListenForEvent("swaphurtboxes", function(inst, data)
		onswaphurtboxes(inst, data.preset)
	end)
	
	
	-- a minimap icon must be specified
	inst.MiniMapEntity:SetIcon( "smashtemplate.tex" )
	inst.soundsname = "wilson"
	
	--10-21-18 FOR CHARACTER SPECIFIC LANDING ACTIONS.
	--ADDITIONAL CODE THAT WILL RUN WHEN YOUR CHARACTER HITS THE GROUND (or grabs a ledge)
	inst.components.launchgravity.onlandingfn = function() 

	end
	
	
end



return MakePlayerCharacter("spider_player", nil, assets, common_postinit, master_postinit, nil)
