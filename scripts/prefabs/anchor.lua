local assets=
{
	Asset("ANIM", "anim/nitre.zip"),
}


--8-17-20 WAIT I HAD IT ALL WRONG. THIS ALL SHOULD HAPPEN ON THE ANCHOR BECAUSE CLIENTS CANT ACCESS HORDE COMPONENTS
local function UnlockNewTier(inst, tier) --THE FUNCTION TO CALL FROM ELSEWHERE TO UPDATE THE VALUE --WAIT BUT THIS IS A LOCAL FN...
    inst._unlockteir:set(tier)
    onunlocktierdirty(inst)
end

--8-17-20 MY FIRST SAVE/LOADING NETVAR I GUESS. I HOPE IM DOING THIS RIGHT
local function onsave(inst, data)
    --THIS NON-UNDERSCORE VERSION IS USED ONLY FOR SAVING AND LOADING PURPOSES
	data.unlockteir = inst._unlockteir ~= nil and inst._unlockteir:value() or nil --WELL IT BETTER NOT BE NIL BUT OK
end

local function onload(inst, data)
	if data ~= nil and data.unlockteir then --WE HAVE TO MAKE SURE WE'VE ACTUALLY SAVED THE GAME ONCE
		inst._unlockteir:set(data.unlockteir)
	else --OR MAYBE WE SHOULD SET IT OURSELVES? WE WANT IT AS 1 BY DEFAULT
		inst._unlockteir:set(1) --8-18-20
	end
end

--8-17-20 SO NOW IT GETS CALLED HERE... BUT WILL THIS APPLY TO ALL PLAYERS?
-- local function onunlocktierdirty(inst)
	-- ThePlayer.UnlockTier() --8-16-20
	-- print("PUSHING THE UNLOCKTIER() FN FOR THEPLAYER")
-- end

local function onbeginsessiondirty(inst)
	for k, v in ipairs(AllPlayers) do
		v.EnableSessionStart() --8-21-20 UPDATES THE SESSION START BUTTON
    end
	
end


   --ALRIGHT. THIS ISNT WORKING
--local function fn(Sim)
local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork() --DSTCHANGES
	
	
	--3-13-17 LETS TRY CREATING THE ANCHOR IN HERE, BECAUSE COMPONENTS AND STUFF CANT BE ADDED TO ALL CLIENTS AFTER POST-INIT
	inst:AddTag("anchor") --@@DSTCHANGE@@
	inst:AddComponent("gamerules")
	
	inst.entity:AddLight()
	-- inst.Light:SetIntensity(.15) --.8
	inst.Light:SetIntensity(.3)
	inst.Light:SetRadius(1.0) --.5
	inst.Light:SetFalloff(0.2) --0.65
	inst.Light:SetColour(255 / 255, 255 / 255, 236 / 255)
	inst.Light:Enable(false)
	
	
	--8-18-20
	inst._unlockteir = net_byte(inst.GUID, "unlocktiervar.tier", "unlocktierdirty")
	--I GUESS THIS DEFAULTS TO 0 INSTEAD OF NIL
	
	--8-21-20 UPDATE/ENABLE/DISABLE THE BEGIN SESSION BUTTON
	inst._sessionready = net_bool(inst.GUID, "doesthismatter", "onbeginsessiondirty")
	inst:ListenForEvent("onbeginsessiondirty", --ongamesetdirty)
	-- inst._sessionready = net_bool(inst.GUID, "doesthismatter", 
		function() 
			for k, v in ipairs(AllPlayers) do
				if v.EnableSessionStart then
					v.EnableSessionStart() --8-21-20 UPDATES THE SESSION START BUTTON
				end
			end
			-- print("AM I ACTUALLY READY?")
		end
	)
	
	--9-29-20 DETERMINES IF THE BONUS CHARACTER IS SELECTABLE OR NOT FROM THE CHARACTER SELECT SCREEN
	inst._bonusfighteron = net_bool(inst.GUID, "idontthinkso", "doweneedone")
	--DO WE ACTUALLY NEED AN EVENT LISTENER FOR THIS?? I THINK WE JUST NEED TO STORE THE VALUE.
	
	inst.entity:SetPristine()
	
	
	if not TheWorld.ismastersim then
        -- inst:DoTaskInTime(0, onunlocktierdirty) --8-17-20 BUT UPDATE THIS FIRST.
		return inst
    end
	
	
	--9-3-17 LETS ADD SOME MATCH-STATE STUFF IN HERE
	if TheWorld.ismastersim then
		
		--6-9-18 -ALRIGHT, LETS GET THIS STARTED
		inst:AddComponent("hordes")
		
		
		--MAKE THIS THE VERSION REMEMBERED BY THE SERVER 8-17-20
		-- inst._unlockteir = net_byte(inst.GUID, "unlocktiervar.tier", "unlocktierdirty")
		--THIS WILL ALSO NEED TO SAVE AND LOAD WITH THE SAVE FILE
		inst.OnSave = onsave
		inst.OnLoad = onload
		
		--IT HAS TO HAVE A DEFAULT
		if inst._unlockteir:value() == nil or inst._unlockteir:value() == 0 then
			inst._unlockteir:set(1)
			-- print("SETTING THE UNLOCK TIER!", inst._unlockteir:value())
		end
		-- print("UNLOCK TIER!", inst._unlockteir:value())
		
		--BY DEFAULT WE ARENT READY. WE DONT NEED TO SAVE THIS VALUE
		inst._sessionready:set(false)
		
		
		--9-23-20 BONUS FIGHTER UNLOCK LOGIC
		inst:DoTaskInTime(0, function() --HUH. SO IT TURNS OUT "ONLOAD()" HASNT RUN BY THE TIME WE GET HERE. 
			--MEANING WE NEED TO DELAY THIS LOGIC UNTIL ONLOAD CAN RUN AND LOAD THE UNLOCKTIER VALUE IN THE SAVE FILE
			--1 FRAME IS ENOUGH TO DO IT, BUT IT'S NOT 100% EFFECTIVE... SOMETIMES OUR SMASHMENU LOADS BEFORE THIS VALUE CAN BE PROPERLY SET.
			--AT THE VERY LEAST, IT WILL ALWAYS BE UPDATED BY THE NEXT TIME WE LOAD IN A CHARACTER. SO FOR NOW, THAT'S GOOD ENOUGH FOR ME.
			local unlockval = TUNING.SMASHUP.BONUSFIGHTER --SET IN THE MOD SETTINGS
			if unlockval == 1 then --NEVER PLAYABLE
				inst._bonusfighteron:set(false)
			elseif unlockval == 3 then --ALWAYS PLAYABLE
				inst._bonusfighteron:set(true)
			elseif unlockval == 2 then --UNLOCKABLE
				if inst._unlockteir:value() >= 3 then
					inst._bonusfighteron:set(true) --ONLY UNLOCK IF THEY'RE 3RD TIER UNLOCK OR HIGHER
					--11-28-20 BUT COULD I ALSO JUST... DO THIS INSTEAD?
					TUNING.SMASHUP.BONUSFIGHTER = 3 --I MEAN, IT'S NOT LIKE WE'RE GOING TO RE-LOCK HIM
				else
					inst._bonusfighteron:set(false)
				end
			end
		end)
	end
	
    return inst
end


return Prefab( "anchor", fn, assets) 