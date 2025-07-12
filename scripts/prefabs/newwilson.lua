
local MakePlayerCharacter = require "prefabs/player_common"


local assets = {

	Asset( "ANIM", "anim/player_basic.zip" ),
	Asset( "ANIM", "anim/newwilson.zip" ),
	Asset( "ANIM", "anim/newwilsonblue.zip" ),
	-- Asset( "ANIM", "anim/newwilsongrey.zip" ),
	-- Asset( "ANIM", "anim/newwilsonyellow.zip" ),
	Asset( "ANIM", "anim/newwilsongreen.zip" ),
	Asset( "ANIM", "anim/newwilsonpurple.zip" ),
}

local function onswaphurtboxes(inst, data)
--print("DATA", data)
	inst.components.hurtboxes:ResetHurtboxes()
	if data == "idle" then
		-- inst.components.hurtboxes:CreateHurtbox(1.8, 0.01, 1.8)
		-- inst.components.hurtboxes:CreateHurtbox(1.8, 0, 1)
		-- inst.components.hurtboxes:CreateHurtbox(1.2, 0, 0.25)
		
		--OK LETS TRY A MORE INTUITIVE VERSION
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.45, 1.15)
	end
	if data == "leanf" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.45, 0.6)
		inst.components.hurtboxes:SpawnHurtbox(.2, 1.1, 0.45, 0.5)
		
	end
	--GUESS WE DIDNT EVEN USE THIS ONE
	-- if data == "walking" then
		-- inst.components.hurtboxes:CreateHurtbox(1.8, 0.2, 1.8)
		-- inst.components.hurtboxes:CreateHurtbox(2, 0.1, 1)
		-- inst.components.hurtboxes:CreateHurtbox(1.2, -0.25, 0.25)
		-- inst.components.hurtboxes:CreateHurtbox(1.2, 0.25, 0.25)
	-- end
	--AND THEN WE BROUGHT IT BACK
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
end



-- This initializes for both clients and the host
local common_postinit = function(inst) 
	inst:AddTag("wilson")
	
	inst.components.stats.altskins = NEWWILSON_SKINS --8-31-20 MAKING THIS A GLOBAL TABLE SO IT CAN BE ADDED ONTO EXTERNALLY
	
	inst.components.stats.bankname = "newwilson"  --"newwilson" 
	inst.components.stats.buildname = NEWWILSON_SKINS[1]
	
	inst.components.stats.facepath = "minimap/minimap_data.xml"
	inst.components.stats.facefile = "wilson.png"

	inst.components.stats.sizemultiplier = 1
	inst.Transform:SetScale(inst.components.stats.sizemultiplier,inst.components.stats.sizemultiplier,inst.components.stats.sizemultiplier)
	
	-- inst.components.stats.stategraphname = "SGnewwilson" --SGbrawlerv1- NOT ANYMORE!!!
	inst:SetStateGraph("SGnewwilson")
	
	-- choose which sounds this character will play
	inst.soundsname = "wilson"
end

-- This initializes for the host only
local master_postinit = function(inst)

	
	inst.components.stats.gravity = 0.87
	inst.components.stats.fallingspeed = 1.5
	inst.components.stats.weight = 98
	
	--3-25-19 LETS TEST SOME SLIGHTLY LOWERED JUMP HEIGHTS
	inst.components.stats.jumpheight = 18 --20 
	inst.components.stats.doublejumpheight = 20 --20 
	
	
	inst.components.hurtboxes:CreateLedgeGrabBox(0.4, 1.7, 1.5, 0.5, 0)
	inst.components.hurtboxes:SpawnPlayerbox(0, 0.7, 0.35, 0.7, 0)
	
	
	inst.components.locomotor.runspeed = 1.2 * 5 --6
	inst.components.locomotor.dashspeed = 1.6 * 5 --MARIOS   

	inst:ListenForEvent("swaphurtboxes", function(inst, data)
		onswaphurtboxes(inst, data.preset)
	end)
	
	inst:ListenForEvent("boomerang_catch", function()
		inst.components.stats.storagevar5 = 0 --TIME BETWEEN BOOMERANG THROWS
	end)
	
	inst.soundsname = "wilson"
end



return MakePlayerCharacter("newwilson", nil, assets, common_postinit, master_postinit, nil)
