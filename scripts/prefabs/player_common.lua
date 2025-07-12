local easing = require("easing")
local PlayerHud = require("screens/playerhud")

local JumboScreen = require "widgets/jumbotron" --10-8-17 
local SMControls = require "widgets/smcontrols" --7-1-20 OH WE ACTUALLY DO USE THIS LOL. ITS FOR THE "CONTROLS" BUTTON IN THE TOPLEFT
--8-18-20 TACKING ON ALL OF THE BASIC MENUS 
local SMMenus = require "widgets/smashmenus"
local FighterHud = require("screens/fighterhud") --1-3-22
	
-- local TestScreen = require "widgets/testscreen" --DEPRECIATED
-- local FighterSelect = require "widgets/fighterselect" --ALSO DEPRECIATED
local FighterSelect = require "screens/fighterselectscreen"

--SO YEA, THIS IS A VERSION OF PLAYERCOMMON FROM LIKE 2017, WITH BITS AND PEICES FROM THE NEWER VERSION FOR COMPATIBILITY--
--MOST OF THE CORE GAME FUNCTIONS ARE LEFT IN SIMPLY FOR THE SAKE OF NOT BREAKING ANYTHING

--MAYBE AT SOME POINT I SHOULD SCRUB OUT MOST OF THE UNUSED COMPONENTS SO IT'S LESS LIKELY TO BREAK FROM UPDATES...
--SOMEDAY... NOT TODAY 

local USE_MOVEMENT_PREDICTION = false --SETTING TO ALWAYS FALSE BECAUSE I WOULD RATHER DIE, THANKS

local screen_fade_time = .4

local DEFAULT_PLAYER_COLOUR = { 1, 1, 1, 1 }


--SLAPPING SOME NEW FNS IN THAT ARE JUST NEEDED FOR COMPATABILITY
local fns = {}

function fns.EnableBoatCamera(inst, enable)
    inst:PushEvent("enableboatcamera", enable)
end

--1-25-22 OH, SO THAT'S WHERE THE GIFT POPUP WENT...
fns.ShowPopUp = function(inst, popup, show, ...)
    if TheWorld.ismastersim and inst.userid then
        SendRPCToClient(CLIENT_RPC.ShowPopup, inst.userid, popup.code, popup.mod_name, show, ...)
    end
end


--11-14-21 CRASH FIX
function fns.EnableLoadingProtection(inst)
    --GUTTED
end

function fns.DisableLoadingProtection(inst)
    --GUTTED
end

------

local function giveupstring(combat, target)
    return GetString(combat.inst, "COMBAT_QUIT", target ~= nil and target:HasTag("prey") and not target:HasTag("hostile") and "PREY" or nil)
end

local function battlecrystring(combat, target)
    return nil
end

local function GetStatus(inst, viewer)
    return nil
end

local function TryDescribe(descstrings, modifier)
    return descstrings ~= nil and (
            type(descstrings) == "string" and
            descstrings or
            descstrings[modifier] or
            descstrings.GENERIC
        ) or nil
end

local function TryCharStrings(inst, charstrings, modifier)
    return charstrings ~= nil and (
            TryDescribe(charstrings.DESCRIBE[string.upper(inst.prefab)], modifier) or
            TryDescribe(charstrings.DESCRIBE.PLAYER, modifier)
        ) or nil
end

local function GetDescription(inst, viewer)
    local modifier = inst.components.inspectable:GetStatus(viewer) or "GENERIC"
    return string.format(
            TryCharStrings(inst, STRINGS.CHARACTERS[string.upper(viewer.prefab)], modifier) or
            TryCharStrings(inst, STRINGS.CHARACTERS.GENERIC, modifier),
            inst:GetDisplayName()
        )
end

local TALLER_TALKER_OFFSET = Vector3(0, -700, 0)
local DEFAULT_TALKER_OFFSET = Vector3(0, -400, 0)
local function GetTalkerOffset(inst)
    local rider = inst.replica.rider
    return (rider ~= nil and rider:IsRiding() or inst:HasTag("playerghost"))
        and TALLER_TALKER_OFFSET
        or DEFAULT_TALKER_OFFSET
end

local DEFAULT_FROSTYBREATHER_OFFSET = Vector3(.3, 1.15, 0)
local function GetFrostyBreatherOffset(inst)
    return DEFAULT_FROSTYBREATHER_OFFSET
end

local function CanUseTouchStone(inst, touchstone)
    --GUTTED
    return false
end

local function GetTemperature(inst)
	--GUTTED
    return TUNING.STARTING_TEMP
end

local function IsFreezing(inst)
    --GUTTED
    return false
end

local function IsOverheating(inst)
    --GUTTED
    return false
end

local function GetMoisture(inst)
	--GUTTED
    return 0
end

local function GetMaxMoisture(inst)
    --GUTTED
    return 100
end

local function GetMoistureRateScale(inst)
    return RATE_SCALE.NEUTRAL
end

local function GetSandstormLevel(inst) --POST PORTAL UPDATE
    return inst.player_classified ~= nil and inst.player_classified.sandstormlevel:value() / 7 or 0
end
local function IsCarefulWalking(inst)
    return inst.player_classified ~= nil and inst.player_classified.iscarefulwalking:value()
end

local function ShouldKnockout(inst)
    return DefaultKnockoutTest(inst) and not inst.sg:HasStateTag("yawn")
end

local function ShouldAcceptItem(inst, item)
    if inst:HasTag("playerghost") then
        return item.prefab == "reviver"
    else
        return item.components.inventoryitem ~= nil
    end
end

local function OnGetItem(inst, giver, item)
    --GUTTED
end

local function DropItem(inst, target, item)
    --GUTTED
end

local function DropWetTool(inst, data)
    --GUTTED
end

local function FrozenItems(item)
    return item:HasTag("frozen")
end

local function OnStartFireDamage(inst)
    --GUTTED
end

local function OnStopFireDamage(inst)
    --GUTTED
end

--NOTE: On server we always get before lose attunement when switching effigies.
local function OnGotNewAttunement(inst, data)
    --GUTTED
end

local function OnAttunementLost(inst, data)
    --GUTTED
end

--------------------------------------------------------------------------
--Audio events
--------------------------------------------------------------------------

local function OnGotNewItem(inst, data)
    if data.slot ~= nil or data.eslot ~= nil then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/collect_resource")
    end
end

local function OnEquip()
    TheFocalPoint.SoundEmitter:PlaySound("dontstarve/wilson/equip_item")
end

local function OnPickSomething(inst, data)
    if data.object ~= nil and data.object.components.pickable ~= nil and data.object.components.pickable.picksound ~= nil then
        --Others can hear this
        inst.SoundEmitter:PlaySound(data.object.components.pickable.picksound)
    end
end

local function OnDropItem(inst)
    --Others can hear this
    inst.SoundEmitter:PlaySound("dontstarve/common/dropGeneric")
end

--------------------------------------------------------------------------
--Action events
--------------------------------------------------------------------------

local function OnActionFailed(inst, data)
    if inst.components.talker ~= nil
        and (data.reason ~= nil or
            not data.action.autoequipped or
            inst.components.inventory.activeitem == nil) then
        --V2C: Added edge case to suppress talking when failure is just due to
        --     action equip failure when your inventory is full.
        --     Note that action equip fail is an indirect check by testing
        --     whether your active slot is now empty or not.
        --     This is just to simplify making it consistent on client side.
        inst.components.talker:Say(GetActionFailString(inst, data.action.action.id, data.reason))
    end
end

local function OnWontEatFood(inst, data)
    --GUTTED
end

local function OnWork(inst, data)
    DropWetTool(inst, data)
end

--------------------------------------------------------------------------
--Temperamental events
--------------------------------------------------------------------------

local function OnStartedFire(inst, data)
    --GUTTED
end

--------------------------------------------------------------------------
--PVP events
--------------------------------------------------------------------------

local function OnAttackOther(inst, data)
    --GUTTED
end

local function OnAreaAttackOther(inst, data)
    --GUTTED
end

local function OnKilled(inst, data)
    --GUTTED
end

--------------------------------------------------------------------------

local function RegisterActivePlayerEventListeners(inst)
    --HUD Audio events
    inst:ListenForEvent("gotnewitem", OnGotNewItem)
    inst:ListenForEvent("equip", OnEquip)
end

local function UnregisterActivePlayerEventListeners(inst)
    --HUD Audio events
    inst:RemoveEventCallback("gotnewitem", OnGotNewItem)
    inst:RemoveEventCallback("equip", OnEquip)
end

local function RegisterMasterEventListeners(inst)
    --Audio events
    inst:ListenForEvent("picksomething", OnPickSomething)
    inst:ListenForEvent("dropitem", OnDropItem)

    --Speech events
    inst:ListenForEvent("actionfailed", OnActionFailed)
    inst:ListenForEvent("wonteatfood", OnWontEatFood)
    inst:ListenForEvent("working", OnWork)

    --Temperamental events
    inst:ListenForEvent("onstartedfire", OnStartedFire)

    --PVP events
    inst:ListenForEvent("onattackother", OnAttackOther)
    inst:ListenForEvent("onareaattackother", OnAreaAttackOther)
    inst:ListenForEvent("killed", OnKilled)
end

--------------------------------------------------------------------------
--Construction/Destruction helpers
--------------------------------------------------------------------------

local function AddActivePlayerComponents(inst)
    inst:AddComponent("playertargetindicator")
    inst:AddComponent("playerhearing")
end

local function RemoveActivePlayerComponents(inst)
    inst:RemoveComponent("playertargetindicator")
    inst:RemoveComponent("playerhearing")
end

local function ActivateHUD(inst)
    
	
	--HM WHAT IF I... OH WAIT I'M ACTUALLY A MORON. THE CAPITAL HUD IS THE SAME AS "hud"
	--[[
	local hud = PlayerHud()
    TheFrontEnd:PushScreen(hud)
    if TheFrontEnd:GetFocusWidget() == nil then
        hud:SetFocus()
    end
    TheCamera:SetOnUpdateFn(not TheWorld:HasTag("cave") and function(camera) hud:UpdateClouds(camera) end or nil)
    hud:SetMainCharacter(inst)
	
	hud.fumeover:Kill() --DST??? --YEA, I GUESS IT WORKS
	hud.bloodover:Kill() --GET RID OF THIS ONE TOO, GEEZ ITS ANNOYING
	]]
	
	local hud = FighterHud()
    TheFrontEnd:PushScreen(hud)
    if TheFrontEnd:GetFocusWidget() == nil then
        hud:SetFocus()
    end
	hud:SetMainCharacter(inst)
	--1-3-22
	local hudpanel = inst.HUD.smashpanel --inst.HUD.controls.sidepanel
	
	--11-16-17 LETS GIVE REMOVING THE CLOCK ANOTHER SHOT
	-- inst.HUD.controls.clock:Hide() --FINALLY, JESUS
	inst.HUD.controls.status.heart2:Hide() --ALMOST...
	inst.HUD.controls.status.lives:Hide() --THEEEERE WE GO. ALL CLEANED UP!!
	inst.HUD.controls.inv:Hide() --5-4-20 DONT FORGET THIS! --HEY WAIT WHY DOESN'T THIS WORK??
	--6-30 AND ALSO THE CLOCK HANDS BECAUSE IM TOO BAD AT MATH TO FIX THEM
	-- inst.HUD.controls.clock._hands:Hide() --HECK THIS DOESNT WORK EITHER???
	
	--8-25-20 ITS ABOUT TIME WE UPDATED OUR FIGHTER SELECT SCREEN
	--[[ REPLACING WITH A SCREEN!
	inst:DoTaskInTime(0.5, function() 
		--10-14-21 HEY! THE ACTUAL SELECT SCREEN DOESN'T POP UP UNTIL 1.2 SECONDS AFTER SPAWNING...
		--WE COULD FIX OUR LITTLE "BONUSFIGHTER VALUE" ISSUE BY DELAYING APPLYING THIS WIDGET UNTIL THAT VALUE IS SET!
		hudpanel.fighterselect = hudpanel:AddChild(FighterSelect(inst))
		hudpanel.fighterselect:Hide()
		hudpanel.fighterselect:MoveToBack()
	end)
	]]
	
	
	--11-23-21 THOSE DARK CORNERS ARE REALLY GETTING ON MY NERVES 
	--[[
	inst:DoTaskInTime(0.5, function() 
		-- TheFrontEnd:HideTopFade()
		-- TheFrontEnd.vigoverlay:Hide()
		-- TheFrontEnd:SetFadeLevel(0)
		-- inst.HUD.vig:SetScale(0.2, 0.2, 0.2)
		-- inst.HUD.vig:SetScaleMode(SCALEMODE_FILLSCREEN)
		-- inst.HUD.vig:GetAnimState():SetAddColour(1,1,1,1) --GOD, I WAS BEGINNING TO THINK YOU WERENT ACTUALLY REAL. YOU ALMOST HAD ME TOO.
		inst.HUD.vig:GetAnimState():SetMultColour(0,0,0,0) --FINALLY. JEEZ... WHY WERE YOU LIKE THE FINAL BOSS
		--THIS THING SERIOUSLY UPDATES EVERY SINGLE FRAME TO RE-ENABLE ITSELF, WHAT A PSYCO
	end)
	]]
	
	
	
	
	local jumboscreen = hudpanel:AddChild(JumboScreen(inst))
	jumboscreen:Hide()
	
	--10-17-17
	local smcontrols = hudpanel:AddChild(SMControls(inst)) --owner
	
	--WE NEED A SEC FOR THE SERVER TO SORT OUT THE "AUTOSPAWN" TAG
	inst:DoTaskInTime(0.5, function() 
		--inst.HUD.controls.status:AddChild(SMMenus(inst))
		hudpanel.ssmmenu = hudpanel:AddChild(SMMenus(inst))
		hudpanel.ssmmenu:MoveToBack()
		-- print("APPLYING SMASHMENUS. BUTTONS SHOULD BE VISIBLE NOW.")
	end)
	
	
	--1-20-22 SINCE THIS WHOLE FN SHOULD SUPPOSEDLY ONLY ACTIVATE FOR THE CLIENT, LETS PUT SOME CLIENT-ONLY LISTENERS IN HERE.
	inst:ListenForEvent("show_select_screen", function(inst, data)
		-- print("SELECT SCREEN EVENT!", data.teams)
		TheFrontEnd:PushScreen(FighterSelect(inst, data.teams))
	end)
	
	
	-- inst:AddComponent("giftreceiver") --THIS IS A TERRIBLE IDEA
	
	--1-24-22 ?? GIFT STUFF I GUESS?
	inst:ListenForEvent("ms_opengift", function(inst)
		if inst.components.giftreceiver ~= nil then
			inst.components.giftreceiver:OnStartOpenGift()
			-- print("OPEN DA GIFT??")
			-- if not TheWorld.ismastersim then
                -- SendRPCToServer(RPC.OpenGift)
            -- elseif inst.components.giftreceiver ~= nil then
                -- inst.components.giftreceiver:OpenNextGift()
            -- end
			inst:ShowPopUp(POPUPS.GIFTITEM, true)
		end
	end)
	
	
	--10-11-17 CAN WE JUST THROW THIS IN HERE IN THE RARE CASE THAT THE CLIENT'S PC WAS TOO SLOW TO REGISTER THE UN-SLOWING OF TIME AFTER THE GAME-SET?
	TheSim:SetTimeScale(1)
end

local function DeactivateHUD(inst)
    TheCamera:SetOnUpdateFn(nil)
    TheFrontEnd:PopScreen(inst.HUD)
    inst.HUD = nil
end

local function ActivatePlayer(inst)
    inst.activatetask = nil

    TheWorld.minimap.MiniMap:DrawForgottenFogOfWar(true)
    if inst.player_classified ~= nil then
        inst.player_classified.MapExplorer:ActivateLocalMiniMap()
    end

    inst:PushEvent("playeractivated")
    TheWorld:PushEvent("playeractivated", inst)
	
	--11-28-17 MAYBE SETTING PLAYERCONTROLLER SETTINGS UP HERE BELOW ACTIVATEPLAYER WILL MAKE THEM LESS LIKELY TO BE SKIPPED
	inst.components.playercontroller:SetCanUseMap(false) --GOD PLEASE DONT LET THEM PULL UP THE MAP
	inst.components.playercontroller:EnableMapControls(false) --12-7-17 APPARENTLY AN UPDATE BROKE THIS, AND NOW WE HAVE TO FIX IT
end

local function DeactivatePlayer(inst)
    if inst.activatetask ~= nil then
        inst.activatetask:Cancel()
        inst.activatetask = nil
        return
    end

    if inst == ThePlayer then
        -- For now, clients save their local minimap reveal cache
        -- and we need to trigger this here as well as on network
        -- disconnect.  On migration, we will hit this code first
        -- whereas normally we will hit the one in disconnection.
        if not TheWorld.ismastersim then
            SerializeUserSession(inst)
        end
    end

    inst:PushEvent("playerdeactivated")
    TheWorld:PushEvent("playerdeactivated", inst)
end

--------------------------------------------------------------------------

local function OnPlayerJoined(inst)
    inst.jointask = nil

    -- "playerentered" is available on both server and client.
    -- - On clients, this is pushed whenever a player entity is added
    --   locally because it has come into range of your network view.
    -- - On servers, this message is identical to "ms_playerjoined", since
    --   players are always in network view range once they are connected.
    TheWorld:PushEvent("playerentered", inst)
    if TheWorld.ismastersim then
        TheWorld:PushEvent("ms_playerjoined", inst)
        --V2C: #spawn #despawn
        --     This was where we used to announce player joined.
        --     Now we announce as soon as you login to the lobby
        --     and not when you connect during shard migrations.
        --TheNet:Announce(string.format(STRINGS.UI.NOTIFICATION.JOINEDGAME, inst:GetDisplayName()), inst.entity, true, "join_game")

        --Register attuner server listeners here as "ms_playerjoined"
        --will trigger relinking saved attunements, and we don't want
        --to hit the callbacks to spawn fx for those
        inst:ListenForEvent("gotnewattunement", OnGotNewAttunement)
        inst:ListenForEvent("attunementlost", OnAttunementLost)
        inst._isrezattuned = inst.components.attuner:HasAttunement("remoteresurrector")
    end
end

local function ConfigurePlayerLocomotor(inst)
    inst.components.locomotor:SetSlowMultiplier(0.6)
    inst.components.locomotor.pathcaps = { player = true, ignorecreep = true } -- 'player' cap not actually used, just useful for testing
    inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED -- 4
    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED -- 6
    inst.components.locomotor.fasteronroad = false --12-3-21 NO, WE DON'T WANT INVISIBLE SPEED PATCHES ON THE STAGE
    inst.components.locomotor:SetTriggersCreep(not inst:HasTag("spiderwhisperer"))
end

local function ConfigureGhostLocomotor(inst)
    --GUTTED
end

local function OnCancelMovementPrediction(inst)
    inst.components.locomotor:Clear()
    inst:ClearBufferedAction()
    inst.sg:GoToState("idle", "cancel")
end

local function EnableMovementPrediction(inst, enable)
	--GUTTED
end

--Always on the bottom of the stack
local function PlayerActionFilter(inst, action)
    return not action.ghost_exclusive
end

--Pushed/popped when dying/resurrecting
local function GhostActionFilter(inst, action)
    return action.ghost_valid
end

local function ConfigurePlayerActions(inst)
    if inst.components.playeractionpicker ~= nil then
        inst.components.playeractionpicker:PopActionFilter(GhostActionFilter)
    end
end

local function ConfigureGhostActions(inst)
    --GUTTED
end

local function SetGhostMode(inst, isghost)
    --GUTTED
end

local function OnSetOwner(inst)
    inst.name = inst.Network:GetClientName()
    inst.userid = inst.Network:GetUserID()
    inst.playercolour = inst.Network:GetPlayerColour()
    if TheWorld.ismastersim then
        TheNet:SetIsClientInWorld(inst.userid, true)
        inst.player_classified.Network:SetClassifiedTarget(inst)
    end

    if inst ~= nil and (inst == ThePlayer or TheWorld.ismastersim) then
        if inst.components.playercontroller == nil then
            EnableMovementPrediction(inst, Profile:GetMovementPredictionEnabled())
            inst:AddComponent("playeractionpicker")
            inst:AddComponent("playercontroller")
            inst:AddComponent("playervoter")
            inst:AddComponent("playermetrics")
            inst.components.playeractionpicker:PushActionFilter(PlayerActionFilter, -99)
        end
    elseif inst.components.playercontroller ~= nil then
        inst:RemoveComponent("playeractionpicker")
        inst:RemoveComponent("playercontroller")
        inst:RemoveComponent("playervoter")
        inst:RemoveComponent("playermetrics")
        DisableMovementPrediction(inst)
    end

    if inst == ThePlayer then
        if inst.HUD == nil then
            ActivateHUD(inst)
            AddActivePlayerComponents(inst)
            RegisterActivePlayerEventListeners(inst)
            inst.activatetask = inst:DoTaskInTime(0, ActivatePlayer)
			--ThePlayer.HUD.controls.inv:Hide() --5-4-20 DONT FORGET THIS!
			ThePlayer.HUD.controls.item_notification:Hide() --12-3-21 THE GIFT POPUP HAS TO GO AS WELL.
        end
    elseif inst.HUD ~= nil then
        UnregisterActivePlayerEventListeners(inst) --BEGONE
        RemoveActivePlayerComponents(inst)
        DeactivateHUD(inst)
        DeactivatePlayer(inst)
    end
end



--8-28-19 SO WHAT EXACTLY IS THIS FOR? NIGHTMARE STUFF? PROBABLY MOON STUFF NOW. 
--DON'T KNOW. DON'T CARE. GAURDS, OFF WITH ITS HEAD
-- local function OnChangeArea(inst, area)
    -- if area.tags and table.contains(area.tags, "Nightmare") then
        -- inst.components.playervision:SetNightmareVision(true)
    -- else
        -- inst.components.playervision:SetNightmareVision(false)
    -- end
-- end

local function AttachClassified(inst, classified)
    inst.player_classified = classified
    inst.ondetachclassified = function() inst:DetachClassified() end
    inst:ListenForEvent("onremove", inst.ondetachclassified, classified)
end

local function DetachClassified(inst)
    inst.player_classified = nil
    inst.ondetachclassified = nil
end

local function OnRemoveEntity(inst)
    if inst.jointask ~= nil then
        inst.jointask:Cancel()
    end
	
	inst:AddTag("lockcontrols")

    if inst.player_classified ~= nil then
        if TheWorld.ismastersim then
            inst.player_classified:Remove()
            inst.player_classified = nil
            if inst.ghostenabled then
                inst.Network:RemoveUserFlag(USERFLAGS.IS_GHOST)
            end
            inst.Network:RemoveUserFlag(USERFLAGS.CHARACTER_STATE_1)
            inst.Network:RemoveUserFlag(USERFLAGS.CHARACTER_STATE_2)
        else
            inst.player_classified._parent = nil
            inst:RemoveEventCallback("onremove", inst.ondetachclassified, inst.player_classified)
            inst:DetachClassified()
        end
    end

    --RemoveByValue(AllPlayers, inst)
	table.removearrayvalue(AllPlayers, inst) --11-25-17 OH!! IT SEEMS THE NEW PLAYERCOMMON NOW USES THIS INSTEAD. MIGHT AS WELL JOIN THEM.
	-- print("--REMOVING ENTITY!!!!")
	-- print("REMOVING ENTITY", inst.Network:GetUserID())
	--SO I GUESS IF YOURE HOSTING LOCALLY, THIS PART NEVER GETS THE CHANCE TO RUN IF YOU DISCONNECT

    -- "playerexited" is available on both server and client.
    -- - On clients, this is pushed whenever a player entity is removed
    --   locally because it has gone out of range of your network view.
    -- - On servers, this message is identical to "ms_playerleft", since
    --   players are always in network view range until they disconnect.
    TheWorld:PushEvent("playerexited", inst)
    if TheWorld.ismastersim then
        TheWorld:PushEvent("ms_playerleft", inst)
        TheNet:SetIsClientInWorld(inst.userid, false)
    end

    if inst.HUD ~= nil then
        DeactivateHUD(inst)
    end

    if inst == ThePlayer then
        UnregisterActivePlayerEventListeners(inst)
        RemoveActivePlayerComponents(inst) --1-26-22 AND THEN TRY RENABLING IT --11-27-17 WELL... I MEAN, LETS JUST TRYYYYY REMOVING IT AND SEE IF ANYTHING BREAKS
        DeactivatePlayer(inst)
    end
	
	--DST--
	-- inst.components.hurtboxes:Unsubscribe()
	-- inst.components.hurtboxes:ResetHurtboxes()
	inst.components.hurtboxes:RemoveAllHurtboxes() --DST -CONVERTABLE-- REUSEABLE
	
	if inst.components.hoverbadge then --6-10-18 OH YEA. GET RID OF THESE THINGS TOO
		inst.components.hoverbadge:RemoveAllBadges()
	end
end

--------------------------------------------------------------------------
--Death/Ghost stuff
--------------------------------------------------------------------------


--Player has completed death sequence
local function OnPlayerDied(inst, data)
    --GUTTED
end

--Player has initiated death sequence
local function OnPlayerDeath(inst, data)
    --GUTTED
end

local function DoActualRez(inst, source, item)
    --GUTTED
end

local function DoRezDelay(inst, source, delay)
    --GUTTED
end

local function DoMoveToRezSource(inst, source, delay)
    --GUTTED
end

local function OnRespawnFromGhost(inst, data)
    --GUTTED
end

local function OnMakePlayerGhost(inst, data)
    --GUTTED
end

local function OnSave(inst, data)
    data.is_ghost = inst:HasTag("playerghost") or nil

    --Shard stuff
    data.migration = inst.migration
	--GUTTED

    if inst._OnSave ~= nil then
        inst:_OnSave(data)
    end
end

local function OnPreLoad(inst, data)
    --Shard stuff
    inst.migration = data ~= nil and data.migration or nil
    inst.migrationpets = inst.migration ~= nil and {} or nil

    if inst._OnPreLoad ~= nil then
        inst:_OnPreLoad(data)
    end
end

local function OnLoad(inst, data)
    --If this character is being loaded then it isn't a new spawn
    inst.OnNewSpawn = nil
    inst._OnNewSpawn = nil

    if data ~= nil then
        --GUTTED
    end
	
	--10-10-20 IF WE LOAD INTO THE GAME AND WE ARENT THE DEFAULT CHARACTER... SWITCH US BACK I GUESS.
	--MMMM THIS SEEMS LIKE A REALLY STUPID WAY TO DO THIS.
	--IS THIS EVEN A SERVER-ONLY THING?? DONT WANT CLIENTS PUSHING THIS I DONT THINK	
	-- if inst.prefab == "spectator" then
		-- print("YEP, I SURE AM A SPECTATOR")
	-- else
		-- print("---HEY!! IM NOT A SPECTATOR!! ---")
		-- inst:DoTaskInTime(1, function(inst)  
			-- TheWorld:PushEvent("ms_playerdespawnanddelete", inst)
		-- end)
		 
	-- end

    if inst._OnLoad ~= nil then
        inst:_OnLoad(data)
    end
end


local function OnSleepIn(inst)
    --GUTTED
end

local function OnWakeUp(inst)
    --GUTTED
end

--Player cleanup usually called just before save/delete
--just before the the player entity is actually removed
local function OnDespawn(inst)
    if inst._OnDespawn ~= nil then
        inst:_OnDespawn()
    end

    inst:OnWakeUp()
    --
	-- print("--DESPAWNING!!!!")
	DeleteUserSession(inst) --10-10-20
	-- TheNet:DeleteUserSession(inst.Network:GetUserID())
	--10-11-20 ^^^ I FEEL LIKE THAT SHOULD HAVE WORKED, BUT IT DOESNT ACTUALLY SEEM TO DO ANYTHING?...
	--OH WAIT, IT DID WORK!! IT JUST DOESNT WORK IF THE LOCAL HOST DISCONNECTS. BUT THIS JUST SO HAPPENS TO WORK FOR US

    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:Enable(false)
    end
    inst.components.locomotor:StopMoving()
    inst.components.locomotor:Clear()
	
	
	--9-16-17 REMOVE ALL OF THE PLAYER'S LIVES AND KO THEM AS THEY WALK OUT THE DOOR
	inst.components.stats.lives = 0  --WILL THIS WORK?? WILL THE MASTERSIM SEE THIS? --I GUESS IT DOES
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	anchor.components.gamerules:KOPlayer(inst, "silent") --GET EM OUTTA HERE
	anchor.components.gamerules:CleanOpponentList(inst) --1-30-21 THIS SHOULD HOPEFULLY FIX STALE COMPONENT ISSUES WHEN DISCONNECTING DURING A GRAB
	
	anchor.components.gamerules:LobbyGuestList(inst.Network:GetUserID(), "remove") --GET EM OUTTA HERE
	-- TheNet:Announce("REMOVING FROM THE GUEST LIST " ..  tostring(inst.Network:GetUserID()))
	-- print("DESPAWNING", inst.Network:GetUserID())
end

--------------------------------------------------------------------------
--Pet stuff
--------------------------------------------------------------------------

local function DoEffects(pet)
    SpawnPrefab(pet:HasTag("flying") and "spawn_fx_small_high" or "spawn_fx_small").Transform:SetPosition(pet.Transform:GetWorldPosition())
end

local function OnSpawnPet(inst, pet)
    --GUTTED
end

local function OnDespawnPet(inst, pet)
    --GUTTED
end

--------------------------------------------------------------------------
--HUD/Camera/FE interface
--------------------------------------------------------------------------

local function IsActionsVisible(inst)
    --V2C: This flag is a hack for hiding actions during sleep states
    --     since controls and HUD are technically not "disabled" then
    return inst.player_classified ~= nil and inst.player_classified.isactionsvisible:value()
end

local function IsHUDVisible(inst)
    return inst.player_classified.ishudvisible:value()
end

local function ShowActions(inst, show)
    if TheWorld.ismastersim then
        inst.player_classified:ShowActions(show)
    end
end

local function ShowHUD(inst, show)
    if TheWorld.ismastersim then
        inst.player_classified:ShowHUD(show)
    end
end

local function ShowWardrobePopUp(inst, show, target)
    --GUTTED
end

local function ShowGiftItemPopUp(inst, show)
    if TheWorld.ismastersim then
        inst.player_classified:ShowGiftItemPopUp(show) --11-24-21 SORRY LOL, THIS IS TOO DISTRACTING
    end
end


--DST CHANGE 5-13-17 -- TESTING SCREEN DUPLICATE OF THE GIFT POPUP VERSION!! IT WORKED!!!
local function ShowSelectScreenPopUp(inst, show)
    if TheWorld.ismastersim then
		if inst.player_classified then --DST CHANGE 9-3-17 JUST SOME WORKAROUND THAT WORKS
			inst.player_classified:ShowSelectScreenPopUp(show)
		end
    end
end

--DST CHANGE 12-6-17 ACTIVATE THE PRE-ROUND CAMERA CINNEMATIC ZOOM
-- local function DoCameraBump()
    -- TheCamera:RoundStartBump()
-- end


local function SetCameraDistance(inst, distance)
    if TheWorld.ismastersim then
        inst.player_classified.cameradistance:set(distance or 0)
    end
end

local function SetCameraZoomed(inst, iszoomed)
    if TheWorld.ismastersim then
        inst.player_classified.iscamerazoomed:set(iszoomed)
    end
end

local function SnapCamera(inst)
    if TheWorld.ismastersim then
        --Forces a netvar to be dirty regardless of value
        inst.player_classified.camerasnap:set_local(true)
        inst.player_classified.camerasnap:set(true)
    end
end

local function ShakeCamera(inst, mode, duration, speed, scale, source, maxDist)
    if source ~= nil and maxDist ~= nil then
        local distSq = inst:GetDistanceSqToInst(source)
        local k = math.max(0, math.min(1, distSq / (maxDist * maxDist)))
        scale = easing.outQuad(k, scale, -scale, 1)
    end

    --normalize for net_byte
    duration = math.floor((duration >= 16 and 16 or duration) * 16 + .5) - 1
    speed = math.floor((speed >= 1 and 1 or speed) * 256 + .5) - 1
    scale = math.floor((scale >= 8 and 8 or scale) * 32 + .5) - 1

    if scale > 0 and speed > 0 and duration > 0 then
        if TheWorld.ismastersim then
            --Forces a netvar to be dirty regardless of value
            inst.player_classified.camerashakemode:set_local(mode)
            inst.player_classified.camerashakemode:set(mode)
            --
            inst.player_classified.camerashaketime:set(duration)
            inst.player_classified.camerashakespeed:set(speed)
            inst.player_classified.camerashakescale:set(scale)
        end
        if inst.HUD ~= nil then
            -- TheCamera:Shake(
                -- mode,
                -- (duration + 1) / 16,
                -- (speed + 1) / 256,
                -- (scale + 1) / 32
            -- )
        end
		
		--DST CHANGE!!! LETS TRY SOMETHING A LITTLE UNORTHADOX
		-- EVERY PLAYER SHARES THE SAME CAMERA VIEW RIGHT?? IF ONE SCREEN SHAKES, LETS JUST SHAKE THEM ALL!
		-- for i, v in ipairs(AllPlayers) do
			-- v:ShakeCamera("FULL", duration, speed, scale / 2)
		-- end---- to here
		-- ShakeAllCameras(0, duration, speed, scale) --OH... THATS CONVENIENT  --TOO BAD IT DOESNT WORK DEDICATED
		
    end
end

local function ScreenFade(inst, isfadein, time, iswhite)
    if TheWorld.ismastersim then
        --truncate to half of net_smallbyte, so we can include iswhite flag
        time = time ~= nil and math.min(31, math.floor(time * 10 + .5)) or 0
        inst.player_classified.fadetime:set(iswhite and time + 32 or time)
        inst.player_classified.isfadein:set(isfadein)
    end
end

local function ScreenFlash(inst, intensity)
    if TheWorld.ismastersim then
        --normalize for net_tinybyte
        intensity = math.floor((intensity >= 1 and 1 or intensity) * 8 + .5) - 1
        if intensity >= 0 then
            --Forces a netvar to be dirty regardless of value
            inst.player_classified.screenflash:set_local(intensity)
            inst.player_classified.screenflash:set(intensity)
            TheWorld:PushEvent("screenflash", (intensity + 1) / 8)
        end
    end
end

--------------------------------------------------------------------------

local function ApplyScale(inst, source, scale)
    --GUTTED
end



--9-29-20 NEW UNIVERSAL RESKINNER FUNCTION
--CUSTOM SKINNER, WHICH AUTO SWITCHES TO A DIFFERENT SKIN IF A DITTO IS PRESENT
local function Reskinner(inst, name) --NEED TO PASS IN OUR NAME BECAUSE OUR PREFAB NAME HASNT BEEN DEFINED YET
	if not inst.components.stats.skinnum then
		return end
		
	--1-31-22 IF WE'RE ONLINE, GATHER EVERYONE'S CURRENT SKIN DATA AND UPDATE OUR RECORDS SO THEY'RE CURRENT
	for k, v in pairs(AllPlayers) do --SEARCH THROUGH ALL CURRENT PLAYERS ON SCREEN
		if v.skinnumnetvar and v.skinnumnetvar:value() ~= nil then
			-- v.components.stats.skinnum = v.skinnumnetvar:value()
		end
	end
	
	
	--1-13-22 FIRST, IF ANYONE CHOSE THE SAME SKIN AS US, SET OUR SKINNUM BACK TO 1 SO WE CAN LOOP THROUGH THE REST
	for k, v in pairs(AllPlayers) do --SEARCH THROUGH ALL CURRENT PLAYERS ON SCREEN
		if v ~= inst and v.prefab == name and v.components.stats.skinnum == inst.components.stats.skinnum then 
			inst.components.stats.skinnum = 1
		end
	end
	
	--NOW WE CAN LOOP THROUGH THE REMAINING SKINS AND SEE WHICH ONES ARE STILL AVAILABLE
	local reskinloop = true
	while reskinloop == true do
		reskinloop = false
		local openslot = true
		for k, v in pairs(AllPlayers) do --SEARCH THROUGH ALL CURRENT PLAYERS ON SCREEN
			--IF ANY OF THEM ARE THE SAME PLAYER AS US AND HAVE THE SAME SKIN   --GOTTA CHECK NAME BECAUSE INST.PREFAB ISNT REGISTERED YET
			-- print("SKINFO", v, v.prefab, v.components.stats.skinnum, inst.components.stats.skinnum,  v ~= inst)
			if v ~= inst and v.prefab == name and v.components.stats.skinnum == inst.components.stats.skinnum then 
				-- inst.components.stats.buildname = "newwes_blue" --GIVE OURSELVES THIS OTHER SKIN
				inst.components.stats.skinnum = inst.components.stats.skinnum + 1 
				openslot = false
				-- print("THATS MY SKIN")
			end
		end
		if openslot == true then
			reskinloop = false --DONT GO BACK FOR ANOTHER ROUND!
		end
	end
	
	--MAKE SURE WE HAVE ENOUGH SKINS TO ASSIGN TO PLAYER NUMBERS
	if inst.components.stats.skinnum > #inst.components.stats.altskins then
		inst.components.stats.skinnum = math.random(1, #inst.components.stats.altskins) --1-3-22 IF NOT, RANDOMIZE IT
	end
	
	--SHOULD BE SET IN OUR CHARACTER PREFAB FILE
	inst.components.stats.buildname = inst.components.stats.altskins[inst.components.stats.skinnum]
	inst.AnimState:SetBank(inst.components.stats.bankname)
	inst.AnimState:SetBuild(inst.components.stats.buildname)
	
	--1-31-22 SEND OUT THE NETVAR SO EVERYONE ELSE CAN SEE OUR PICK, I THINK
	--[[
	if inst.skinnumnetvar and inst.skinnamenetvar:value() ~= nil then 
		inst.skinnumnetvar:set(inst.components.stats.skinnum)
		inst.skinnamenetvar:set(inst.components.stats.buildname)
		inst:DoTaskInTime(0.4, function() 
			print("APPLYING THE SERVER'S SKIN", inst, inst.skinnamenetvar:value())
			inst.AnimState:SetBuild(inst.skinnamenetvar:value())
		end)
	end
	]]
end

--------------------------------------------------------------------------

local function MakePlayerCharacter(name, customprefabs, customassets, common_postinit, master_postinit, starting_inventory)
    local assets =
    {
        Asset("SOUND", "sound/sfx.fsb"),
        Asset("SOUND", "sound/wilson.fsb"),

        Asset("IMAGE", "images/colour_cubes/ghost_cc.tex"),
        Asset("IMAGE", "images/colour_cubes/mole_vision_on_cc.tex"),
        Asset("IMAGE", "images/colour_cubes/mole_vision_off_cc.tex"),
        Asset("INV_IMAGE", "skull_"..name),
		
		--DST ADDING:
		-- Asset( "ANIM", "anim/esctemplate.zip" ),
		Asset( "ANIM", "anim/newwilson.zip" ),
    }
	
	--3-7-19 --OKAY SUDDENLY THE GAME UPDATES AND MY CLOTHING_ASSETS.TXT FILE IS FULL OF CLOTHES THAT DONT EXIST? SOLUTION: WE DONT NEED THIS
    -- local clothing_assets = require("clothing_assets")
    -- for _, clothing_asset in pairs(clothing_assets) do
        -- table.insert(assets, clothing_asset)
    -- end

    local prefabs =
    {
        "brokentool",
        "frostbreath",
        "reticule",
        "mining_fx",
        "mining_ice_fx",
        "die_fx",
        "ghost_transform_overlay_fx",
        "attune_out_fx",
        "attune_in_fx",
        "attune_ghost_in_fx",
        "staff_castinglight",
        "hauntfx",
        "emote_fx",
        "tears",
        "shock_fx",
        "splash",
        "globalmapicon",

        -- Player specific classified prefabs
        "player_classified",
        "inventory_classified",
    }
	
	if customassets ~= nil then
        for i, v in ipairs(customassets) do
            table.insert(assets, v)
        end
    end

    local function fn()
        local inst = CreateEntity()

        table.insert(AllPlayers, inst)

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddLight()
        inst.entity:AddLightWatcher()
        inst.entity:AddNetwork()

        -- inst.Transform:SetFourFaced()
		inst.Transform:SetTwoFaced()

        inst.AnimState:SetBank("wilson")
        inst.AnimState:SetBuild(name) --do we still need to do this or can we assume that the skinner will be setting the appropriate build?
        inst.AnimState:PlayAnimation("idle")

        inst.DynamicShadow:SetSize(1.3, .6)

        inst.MiniMapEntity:SetIcon(name..".png")
        inst.MiniMapEntity:SetPriority(10)
        inst.MiniMapEntity:SetCanUseCache(false)
        inst.MiniMapEntity:SetDrawOverFogOfWar(true)

        --Default to electrocute light values
        inst.Light:SetIntensity(.8)
        inst.Light:SetRadius(.5)
        inst.Light:SetFalloff(.65)
        inst.Light:SetColour(255 / 255, 255 / 255, 236 / 255)
        inst.Light:Enable(false)

        inst.LightWatcher:SetLightThresh(.075)
        inst.LightWatcher:SetDarkThresh(.05)

        MakeCharacterPhysics(inst, 75, .5)

        inst:AddTag("player")
        inst:AddTag("scarytoprey")
        inst:AddTag("character")
        inst:AddTag("lightningtarget")

        inst.AttachClassified = AttachClassified
        inst.DetachClassified = DetachClassified
        inst.OnRemoveEntity = OnRemoveEntity
        inst.CanExamine = nil -- Can be overridden; Needs to be on client as well for actions
        inst.ActionStringOverride = nil -- Can be overridden; Needs to be on client as well for actions
        inst.CanUseTouchStone = CanUseTouchStone -- Didn't want to make touchstonetracker a networked component
        inst.GetTemperature = GetTemperature -- Didn't want to make temperature a networked component
        inst.IsFreezing = IsFreezing -- Didn't want to make temperature a networked component
        inst.IsOverheating = IsOverheating -- Didn't want to make temperature a networked component
        inst.GetMoisture = GetMoisture -- Didn't want to make moisture a networked component
        inst.GetMaxMoisture = GetMaxMoisture -- Didn't want to make moisture a networked component
        inst.GetMoistureRateScale = GetMoistureRateScale -- Didn't want to make moisture a networked component
		--POST PORTAL UPDATE VVV
		--inst.GetSandstormLevel = GetSandstormLevel -- OUTDATED
		-- inst.GetStormLevel = GetStormLevel --THE NEW VERSION. BUT WE'RE REPLACING
		inst.GetStormLevel = function() --8-28-21, JUST RETURN 0 ALWAYS
			return 0
		end
		inst.EnableBoatCamera = fns.EnableBoatCamera
		inst.ShowPopUp = fns.ShowPopUp --1-27-22
		
        inst.IsCarefulWalking = IsCarefulWalking -- Didn't want to make carefulwalking a networked component
        inst.EnableMovementPrediction = EnableMovementPrediction
        inst.ShakeCamera = ShakeCamera
        inst.SetGhostMode = SetGhostMode
        inst.IsActionsVisible = IsActionsVisible

        inst.foleysound = nil --Characters may override this in common_postinit
        inst.playercolour = DEFAULT_PLAYER_COLOUR --Default player colour used in case it doesn't get set properly
        inst.ghostenabled = GetGhostEnabled(TheNet:GetServerGameMode())

        inst.jointask = inst:DoTaskInTime(0, OnPlayerJoined)
        inst:ListenForEvent("setowner", OnSetOwner)

        inst:AddComponent("talker")
        inst.components.talker:SetOffsetFn(GetTalkerOffset)

        inst:AddComponent("frostybreather")
        inst.components.frostybreather:SetOffsetFn(GetFrostyBreatherOffset)

        inst:AddComponent("playervision")
        inst:AddComponent("areaaware")
        -- inst:ListenForEvent("changearea", OnChangeArea) --CRASHES US POST-MOON WHEN LANDING IN STUFF WHERE WATER WOULD BE
        inst:AddComponent("attuner")
        --attuner server listeners are not registered until after "ms_playerjoined" has been pushed

		--9-21-17 OH RIGHT... I CAN JUST MOVE THIS. --MOVING DOWN LOWER
        -- if common_postinit ~= nil then
            -- common_postinit(inst)
        -- end
		
		
		-- fn2(inst) --DST TEST CHANGE 5-7  //SIGH/ OKAY, COME BACK TO THIS LATER --NETVAR NET_VARIABLE STUFF--
		
		
		
		
		
		
		
		
		--3-14-17 HEEEEEEERES PICKLE >:3c
		inst:AddTag("fighter")
		
		inst:DoTaskInTime(0.2, function()
			inst.AnimState:SetBank(inst.components.stats.bankname)		--A TOAST, TO THE NEW KING~    									...ME
			inst.AnimState:SetBuild(inst.components.stats.buildname) 	--PRETTY SURE ALL THEIR ANIMBANK STUFF IS SET BY NOW RIGHT?
		end)
		-- inst.AnimState:SetBuild("invisible") --HAVE THEM INCAPACITATED BY DEFAULT
		-- inst:SetStateGraph("SGbooscary") --WAIT THEY CAN STILL RUN LIKE THIS???
		inst:SetStateGraph("SGprojectile") --9-18
		
		inst:AddComponent("stats")
		inst:AddComponent("hitbox")
		inst:AddComponent("hurtboxes")
		inst:AddComponent("percent")
		inst:AddComponent("launchgravity")
		inst:AddComponent("jumper")
		inst.components.jumper:ApplyGroundChecker() --1-25-22 JUST DO IT RIGHT AWAY
		-- inst:DoTaskInTime(0, function()
			-- inst.components.jumper:ApplyGroundChecker()
		-- end)
		inst:AddComponent("visualsmanager") --10-19-17 A SHINY NEW ONE!~ 
		
		inst:AddTag("lockcontrols") --10-8-17 TO KEEP THEM FROM BREAKING ANYTHING WHILE LOADING IN
		
		--1-5-22 NOW ADD THIS DOWN HERE SO THINGS QUIT CRASHING SO FAST
		inst:AddComponent("keydetector")
		
		--9-21-17 THIS IS A MUCH BETTER SPOT FOR IT
        if common_postinit ~= nil then
            common_postinit(inst)
        end
		
		--9-29-20 WE USED TO DO RESKINS LOCALLY AT THE VERY BEGINNING OF COMMON POSTINIT. BUT THIS IS A BETTER PLACE
		Reskinner(inst, name)
		
		--9-4-17 TELEPORT THEM STRAIT TO THE CENTER OF THE WORLD TO KEEP THEM IN-BOUNDS
		inst.Physics:Teleport(0,1,-2) --DO IT BEFORE ANYTHING ELSE IS INITIALIZED SO THEY AREN'T KO'D
		
		local anchor = TheSim:FindFirstEntityWithTag("anchor") --I HOPE ANCHOR EXISTS BY NOW --NO WAIT WE CANT HAVE IT CHECK ANCHOR
		
		inst:AddComponent("locomotor") -- MOVING UP HERE 
		
		--LETS TRY SPAWNING THEM LIKE THIS
		inst:DoTaskInTime(1.2, function()
			local anchor = TheSim:FindFirstEntityWithTag("anchor")
			
			-- print("PLAYER SPAWNING IN HERE. HERES SOME STATS", (tostring(inst:GetDisplayName())), (tostring(inst)), (anchor and anchor.components.gamerules.matchstate))
			
			--9-12-17 MOVING IT HERE
			if inst:HasTag("spectator") and not inst:HasTag("dummynpc") and not inst:HasTag("forcewilson") then
				--BASICALLY, INCAPACITATE THEM IF THEY ARE SPECTATING
				inst:SetStateGraph("SGprojectile") --9-18
				inst.components.hurtboxes:RemoveAllHurtboxes() --5-31-20 THEY WONT NEED THESE
				-- inst:AddComponent("playercontroller_1") --//SIGH/ BUT I GUESS THIS STILL HAS TO HAPPEN SO THAT KEYPRESSES DONT CRASH THE GAME
				-- inst:AddComponent("keydetector")
				inst.Physics:Teleport(0, 1, -2)
			else
			
			
				if inst:HasTag("autospawn") then --9-18-17 IF PLAYER IS FIRST TO JOIN ALONE, AUTOSPAWN AS WILSON
					
					--10-14-21 SPECTATOR PREFAB IS A THING OF THE PAST. WE USE DefaultFighter NOW, SO THEY SHOULD JUST SPAWN IN AS WILSON
					--9-24-17 IF PLAYER IS A SPECTATOR JOINING LOBBY MODE, FORCE THEM TO TURN INTO WILSON. --10-24-20 BUT IF THEY ALREADY HAVE A CHARACTER, LET THEM KEEP IT.
					if inst.prefab == "spectator2" and inst:HasTag("forcewilson") then
						inst:SetStateGraph("SGnewwilson") 	--SPECTATOR PREFAB ALREADY INHERITS WILSON'S STATS BY DEFAULT, JUST THROW HIS SKIN OVER IT
						inst.AnimState:SetBank("newwilson") 
						inst.AnimState:SetBuild("newwilson") --ALRIGHT BUT THEN ALL LOBBY MODE WILSONS ARE RED. LETS FIX THAT
						inst.components.stats.altskins = NEWWILSON_SKINS
						inst.components.stats.buildname = "newwilson"
						inst.components.stats.bankname = "newwilson"
						Reskinner(inst, name) --1-3-22 RUN THE RESKINNER, BUT MANUALLY PASS IN NEWWILSON
					end
					inst:RemoveTag("lockcontrols") --10-8-17
					--THE REST IS TAKEN CARE OF BY THE NEW SYSTEM. NO NEED TO DO ANYTHING ELSE FOR AUTOSPAWN
					
				elseif inst:HasTag("customspawn") then --9-20-17 IF ENTITY WILL BE SPAWNED IN SOME SPECIAL WAY MANUALLY (MAXCLONES)
					-- inst:AddComponent("playercontroller_1") --OH YEA, STILL NEED THIS...
					-- inst:AddComponent("keydetector") 
					-- inst:DoPeriodicTask(0, function() inst.components.playercontroller_1:UpdateKeys(inst) end)
					inst.components.keydetector:InitiateKeys(inst) --1-5-22 REPLACING THE LINE ABOVE WITH SOMETHING BETTER
						return --THEN JUST FLAT OUT SKIP THE REST OF THE SPAWNING PROCESS
				end
				
				inst.components.keydetector:InitiateKeys(inst)
				
				
				if anchor then --9-13-17 JUST HAVE IT RUN THIS PART IF ANCHOR EXISTS. DONT JUST SKIP EVERYTHING AFTER IT THO
				
					local x, y, z = anchor.Transform:GetWorldPosition()
					anchor.components.gamerules:SpawnPlayer(inst, x, y, z) --YEA SURE
					
					if not inst.components.keydetector then
						-- inst:AddComponent("playercontroller_1") --THIS NEEDS TO HAPPEN AFTER THE PLAYER HAS BEEN FORMALY "SPAWNED" BY THE ANCHOR
						-- inst:AddComponent("keydetector") 
						-- inst:DoPeriodicTask(0, function() --THIS IS REALLY DUMB BUT I DON'T KNOW HOW ELSE TO DO IT
							-- inst.components.playercontroller_1:UpdateKeys(inst) --SENDS THE SPECIFIC PLAYER TO BE UPDATED
						-- end)
						-- inst.components.keydetector:InitiateKeys(inst) --1-5-22 I FOUND A BETTER WAY TO DO IT
					end
				
				else --9-16-17 REPLACING WITH ELSE SO THAT CLIENT CAN RE-RUN THIS AFTER ANCHOR FINISHES SPAWNING
					print("ANCHOR DIDN'T EXIST, SO I SKIPPED IT", GetTime())
					--6-2-20 WOW, APPARENTLY SOME COMPUTERS WILL OCASIONALY STILL MISS THIS. OK LETS MAKE A PROPER RETRY LOOP
					inst.spawntask = inst:DoPeriodicTask(1.2, function()
						
						local anchor = TheSim:FindFirstEntityWithTag("anchor") --THANK GOD THIS WORKED, UGH.
						print("DOES ANCHOR EXIST NOW?", anchor, GetTime())
						if not anchor then  --SLOWPOKE COMPUTER. END HERE AND RETRY IN A SEC
							print("WOW, ANCHOR STILL NOT DETECTED. TRY AGAIN")
							return end 
						
						local x, y, z = anchor.Transform:GetWorldPosition()
						anchor.components.gamerules:SpawnPlayer(inst, x, y, z)
						inst.spawntask:Cancel() --AND END THE SPAWNTASK SO IT DOESNT LOOP
						inst.spawntask = nil
					end)
				end
				
				if inst.components.playercontroller then
					inst.components.playercontroller:SetCanUseMap(false) --12-7-17 --THIS NEEDS TO BE TURNED OFF FIRST, I THINK??
					inst.components.playercontroller:Deactivate() --4-4 LETS TRY THIS
				end
			end
			
			
			if inst:HasTag("showselectscreen") then --9-16-17 DETERMINED BY GAMELOGIC --WORKS NICE c:
				-- inst:PushEvent("show_select_screen", {teams = (TUNING.SMASHUP.TEAMS > 1)})   --HUH??.... THIS STILL SHOWS UP CORRECTLY?...
				inst:PushEvent("show_select_screen", {teams = (inst.smashteamsnetvar:value() > 1)})
				--9-27-17 MOVING OUTSIDE THIS IF STATEMENT BECAUSE EVEN SPECTATORS NEED TO CHECK IF THEY NEED A SELECT SCREEN!! 
			end
			
			if inst:HasTag("waitinline") then --10-15-17
				inst.jumbotronheader:set("Game Full. Waiting in line") --THIS VERSION DOESNT TELL THE LINE POSITION, FOR SIMPLICITY REASONS
			end
		end)
		
		
		inst:DoTaskInTime(5, function()
			if inst.components.playercontroller then
				--A LOOOOOONG TIME AFTER STARTUP --DISABLED FOR TESTING
				inst.components.playercontroller:Deactivate() 
				inst.components.playercontroller:SetCanUseMap(false) --12-7-17 --THIS NEEDS TO BE TURNED OFF FIRST, I THINK??
			end
		end)
		
		
		
		--10-6-17 LAST STEP.
		inst:AddComponent("blocker")
		inst.components.blocker:SetGaurdEndurance()
		inst:DoTaskInTime(0.5, function() --11-26-17 DOES IT WORK BETTER IF WE ADD AN EXTRA SECOND TO IT? --NO
			inst:AddComponent("hoverbadge")
			inst.components.hoverbadge:TestBadge()
		end)
		
	
		
		--6-6-20 HEY THE CLIENTS CONTROL PREFERENCES ARENT APPLYING, SO LETS DO THIS UP HERE INSTEAD  --YEA THIS WORKED. WOW, HOW LONG HAD THIS BEEN BROKEN???
		--10-7-17 HAS TO RE-APPLY ANY KEY PREFFERENCES (LIKE TAPJUMP) AFTER THE CONTROLS HAVE BEEN APPLIED
		inst:DoTaskInTime(0.5, function()
			if not inst:HasTag("cpu") then --4-3-19 CPUS DONT HAVE THESE
				SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["rectrler"], Preftapjump) 
				SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["reautodash"], Prefautodash) 
				SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["retiltstick"], Preftiltstick) 
				
				--1-12-22 LETS SEE IF THIS IS A GOOD SPOT TO APPLY OUR CHOSEN SKIN
				SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["skinselector"], Skinchoice) 
				inst.components.stats.skinnum = Skinchoice --THIS ONES FOR CLIENTS TO SEE THEIR SKIN
				--THEN WE JUST NEED TO WAIT A FEW MOMENTS AND REAPPLY THE RESKINNER AGAIN
				-- print("REAPPLYING NEW SKIN CHOICE", inst, Skinchoice)
				
				
				--6-8-20 CLIENTS ONLY NEED THESE ON THEMSELVES
				if inst == ThePlayer then
					--[[ 1-13-22 MAKING THINGS LESS STUPID BY MOVING THIS TO KEYDETECTOR BECAUSE ONLY THE CLIENT SHOULD EVER NEED TO KNOW THIS
					--4-4-19 HERE. IF YOU'RE GONNA DO SOMETHING STUPID, AT LEAST MAKE IT SOMETHING STUPID THAT WORKS
					inst:DoPeriodicTask(4, function()   --EVERY 4 (I GUESS?) SECONDS, CHECK AGAIN FOR IF WE'RE USING A CONTROLLER 
						if inst.components.keydetector then
							local controllercheck = TheInput:ControllerAttached()
							inst.components.keydetector.controllerbound = controllercheck
							-- print("HERE'S MY CONTROLLER CHECK", controllercheck, inst)
							SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["controllerchecker"], controllercheck) --6-9-20 GUESS SERVERS NEED THIS TOO
						end
					end)
					]]
					
					--[[ 1-13-22 THIS TURNED OUT TO BE CAUSING A METRIC TON OF LAG FOR SENDING THIS MUCH DATA TO THE HOST. REDOING
					--HORIZONTAL UPDATES WITH RESPECT TO STICK MOVEMENT MAY ALSO BE CONTRIBUTING TO LAG, BUT PROBABLY LESS SO
					--4-23-20 TRYING SOMETHING DUMB WITH CONTROLS HERE. A CONSTANT CHECK FOR ANALOG VALUES
					inst:DoPeriodicTask(0, function()
						if inst.components.keydetector and inst.components.keydetector.controllerbound then
							local upanalog = TheInput:GetAnalogControlValue(CONTROL_MOVE_UP)
							--THESE VALUES DONT UPDATE PROPERLY FROM THE CLIENT WHEN RUN FROM HERE. RUN EVERYTHING FROM THE RPC INSTEAD
							SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["upanalogchecker"], upanalog) --6-9-20
						end
					end)
					]]
				end
			end
		end)
		
		inst:DoTaskInTime(1, function()
			Reskinner(inst, name) --THIS HAS TO HAPPEN WITH YET ANOTHER DELAY BECAUSE RPCs EFFECTS ARE DELAYED
		end)
		
		
		

        --trader (from trader component) added to pristine state for optimization
        inst:AddTag("trader")

        --debuffable (from debuffable component) added to pristine state for optimization
        inst:AddTag("debuffable")

        --Sneak these into pristine state for optimization
        inst:AddTag("_health")
        inst:AddTag("_hunger")
        inst:AddTag("_sanity")
        inst:AddTag("_builder")
        inst:AddTag("_combat")
        inst:AddTag("_moisture")
        inst:AddTag("_sheltered")
        inst:AddTag("_rider")

        inst.userid = ""
		
		--NEEDED FOR AN UPDATE - MAYBE I SHOULD JUST UPDATE THE ENTIRETY OF PLAYERCOMMON... NAH
		inst._sharksoundparam = net_float(inst.GUID, "localplayer._sharksoundparam","sharksounddirty")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then  --ANYTHING BELOW THIS LINE DOESNT ACTIVATE FOR ANYONE OTHER THAN THE HOST. I THINK.
            return inst
        end

        inst.persists = false --handled in a special way

        --Remove these tags so that they can be added properly when replicating components below
        inst:RemoveTag("_health")
        inst:RemoveTag("_hunger")
        inst:RemoveTag("_sanity")
        inst:RemoveTag("_builder")
        inst:RemoveTag("_combat")
        inst:RemoveTag("_moisture")
        inst:RemoveTag("_sheltered")
        inst:RemoveTag("_rider")

        if inst.ghostenabled then
            inst.Network:RemoveUserFlag(USERFLAGS.IS_GHOST)
        end
        inst.Network:RemoveUserFlag(USERFLAGS.CHARACTER_STATE_1)
        inst.Network:RemoveUserFlag(USERFLAGS.CHARACTER_STATE_2)

        inst.player_classified = SpawnPrefab("player_classified") ---!!!!! LOOK AT THIS!!!! WHAT IS THIS?? COULD THIS BE THE DIFFERENCE?...
        inst.player_classified.entity:SetParent(inst.entity)
		
		-- if not TheWorld.ismastersim then  --LETS JUST.... SEE WHAT HAPPENS --HONESTLY, DIDNT SEEM LIKE MUCH
            -- return inst
        -- end
		
        inst:ListenForEvent("death", OnPlayerDeath)
        if inst.ghostenabled then
            --Ghost events (Edit stategraph to push makeplayerghost instead of makeplayerdead to enter ghost state)
            inst:ListenForEvent("makeplayerghost", OnMakePlayerGhost)
            inst:ListenForEvent("respawnfromghost", OnRespawnFromGhost)
            inst:ListenForEvent("ghostdissipated", OnPlayerDied)
        else
            inst:ListenForEvent("playerdied", OnPlayerDied)
        end

        inst:AddComponent("bloomer")
        -- inst:AddComponent("birdattractor") --7-15-21 HEY, WE SHOULD PROBABLY TURN THIS OFF

        inst:AddComponent("maprevealable")
        inst.components.maprevealable:SetIconPriority(10)

        -- inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph 
								--DST SMASHUP- YOU CANT TELL ME WHAT TO DO >:3c
        ConfigurePlayerLocomotor(inst)

        inst:AddComponent("combat")
        inst.components.combat:SetDefaultDamage(TUNING.UNARMED_DAMAGE)
        inst.components.combat.GetGiveUpString = giveupstring
        inst.components.combat.GetBattleCryString = battlecrystring
        inst.components.combat.hiteffectsymbol = "torso"
        inst.components.combat.pvp_damagemod = TUNING.PVP_DAMAGE_MOD -- players shouldn't hurt other players very much
        inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD)
        inst.components.combat:SetRange(2)

        MakeMediumBurnableCharacter(inst, "torso")
        inst.components.burnable:SetBurnTime(TUNING.PLAYER_BURN_TIME)
        inst.components.burnable.nocharring = true

        MakeLargeFreezableCharacter(inst, "torso")
        inst.components.freezable:SetResistance(4)
        inst.components.freezable:SetDefaultWearOffTime(TUNING.PLAYER_FREEZE_WEAR_OFF_TIME)

        inst:AddComponent("inventory")
        --players handle inventory dropping manually in their stategraph
        inst.components.inventory:DisableDropOnDeath()
		
		
		-- inst.HUD.controls.inv:Hide()

        inst:AddComponent("bundler")

        -- Player labeling stuff
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus
        inst.components.inspectable.getspecialdescription = GetDescription

        -- Player avatar popup inspection
        inst:AddComponent("playerinspectable")

        inst:AddComponent("temperature")
        inst.components.temperature.usespawnlight = true

        inst:AddComponent("moisture")
        inst:AddComponent("sheltered")
		
		--1-2-18 ADDING THESE IN
		-- inst:AddComponent("stormwatcher") --8-28-21 REPLACING WITH THE GetStormLevel() FN BELOW
		inst:AddComponent("carefulwalker")
		inst:AddComponent("skilltreeupdater") --3-22-23 -THIS IS A GUESS, HOPE IT FIXES THE CRASH
		

        -------

        inst:AddComponent("health")
        inst.components.health:SetMaxHealth(TUNING.WILSON_HEALTH)
        inst.components.health.nofadeout = true
		
		

        inst:AddComponent("hunger")
        inst.components.hunger:SetMax(TUNING.WILSON_HUNGER)
        inst.components.hunger:SetRate(0) --TUNING.WILSON_HUNGER_RATE  --9-30-29 GET THIS OUT OF HERE
        inst.components.hunger:SetKillRate(TUNING.WILSON_HEALTH/TUNING.STARVE_KILL_TIME)
		
		--8-6-17 DSTCHANGE HEY GUESS WHAT, NO HEALTH ALLOWED --ok nevermind
		-- inst.components.health:SetMaxHealth(0)
		-- -- inst.components.hunger:SetMax(0)
		-- -- inst.components.hunger:SetKillRate(100)
		-- inst.components.health.currenthealth = 0
		

        inst:AddComponent("sanity")
        inst.components.sanity:SetMax(TUNING.WILSON_SANITY)

        -- inst:AddComponent("builder") --LEGACY

        -------

        inst:AddComponent("wisecracker")
        inst:AddComponent("distancetracker")

        inst:AddComponent("catcher")

        inst:AddComponent("playerlightningtarget")

        inst:AddComponent("trader")
        inst.components.trader:SetAcceptTest(ShouldAcceptItem)
        inst.components.trader.onaccept = OnGetItem
        inst.components.trader.deleteitemonaccept = false

        -------

        inst:AddComponent("eater")
        inst:AddComponent("leader")
        inst:AddComponent("age")
        inst:AddComponent("rider")

        inst:AddComponent("petleash")
        inst.components.petleash:SetMaxPets(1)
        inst.components.petleash:SetOnSpawnFn(OnSpawnPet)
        inst.components.petleash:SetOnDespawnFn(OnDespawnPet)

        inst:AddComponent("grue")
        inst.components.grue:SetSounds("dontstarve/charlie/warn","dontstarve/charlie/attack")

        inst:AddComponent("pinnable")
        inst:AddComponent("debuffable")
        inst.components.debuffable:SetFollowSymbol("headbase", 0, -200, 0)

        inst:AddComponent("grogginess")
        inst.components.grogginess:SetResistance(3)
        inst.components.grogginess:SetKnockOutTest(ShouldKnockout)

        inst:AddComponent("colourtweener")
        inst:AddComponent("touchstonetracker")

        inst:AddComponent("skinner")
        inst:AddComponent("giftreceiver")

        inst:AddInherentAction(ACTIONS.PICK)
        inst:AddInherentAction(ACTIONS.SLEEPIN)
        inst:AddInherentAction(ACTIONS.CHANGEIN)

        -- inst:SetStateGraph("SGwilson") --3-15 MOVING

        RegisterMasterEventListeners(inst)

        --HUD interface
        inst.IsHUDVisible = IsHUDVisible
        inst.ShowActions = ShowActions
        inst.ShowHUD = ShowHUD
        inst.ShowWardrobePopUp = ShowWardrobePopUp
        inst.ShowGiftItemPopUp = ShowGiftItemPopUp
        inst.SetCameraDistance = SetCameraDistance
        inst.SetCameraZoomed = SetCameraZoomed
        inst.SnapCamera = SnapCamera
        inst.ScreenFade = ScreenFade
        inst.ScreenFlash = ScreenFlash
		
		-- inst.DoCameraBump = DoCameraBump

        --Other
        inst._scalesource = nil
        inst.ApplyScale = ApplyScale
		
		
		
		
		
		--------------//SLICE -----------------
		--5-13-17 FROM LIKE 25 LINES UP, TRYING TO REPLICATE THE GETGIFTITEM MENU FOR THE SELECT SCREEN
		inst.ShowSelectScreenPopUp = ShowSelectScreenPopUp --OH RIGHT, INST THIS LIKE A NETVAR OR SOMETHING?
		inst.Transform:SetTwoFaced()
		
		
		--9-30-20 DUNNO HOW IMPORTANT THESE ARE. CLIENTSIDE KEEPS WHINING ABOUT THEM ALREADY EXISTING THO
		if not inst.components.hitbox then
			inst:AddComponent("hitbox")
			inst:AddComponent("hurtboxes")
			inst:AddComponent("percent")
			inst.components.percent:DoDamage(100)
			-- inst:AddComponent("colourtweener")
		end
		
		
		--10-29-17 LETS TRY THIS, MAYBE IT NEEDS TO ONLY BE SERVER SIDE, BC CLIENTSIDE CANT SEE SGTAGS --AAAYYYY!!! IT WORKED!!
		inst.components.visualsmanager:CustomUpdate(inst) --KICKSTART IT
		

		--CHARACTER PHYSICS
		inst.Physics:SetDamping(0.0)  --11-13 CHANGING TO ZERO TO SEE IF GRAVITY REACTS BETTER  --0.1
		inst.Physics:SetFriction(.7)
		inst.Physics:SetMass(0.9)
		inst.Physics:SetRestitution(0) --PREVENTING CHARACTER BOUNCE
		inst.Physics:SetCapsule(0.25, 1) 
		
		
		
		--COLLISION TYPE ON LINE 523 OF CONSTANTS
		inst.Physics:ClearCollisionMask()
		-- inst.Physics:CollidesWith(COLLISION.WORLD) --ENABLING FOR NOW SO PLAYERS DONT FALL OFFSCREEN -DST
		inst.Physics:CollidesWith(COLLISION.OBSTACLES)
		
		if inst.DynamicShadow then
			inst.DynamicShadow:Enable(false)
		end

		
		inst.soundsname = "wilson"--"willow"

		-- Minimap icon
		inst.MiniMapEntity:SetIcon( "wilson.tex" )

		-- PRETTY SURE I DON'T NEED TO DECLARE ALL THIS HERE
		-- inst.components.locomotor.walkspeed = 4
		-- inst.components.locomotor.runspeed = 1.1 * 5--0.9 * 5 --ZELDAS: 0.87    --1.1 * 5 --MARIOS
		-- inst.components.locomotor.dashspeed = 1.6 * 5 --1.3 * 5 --ZELDAS  --1.6 * 5  --1.6 MARIO   --10  --TODOLIST  SET THESE VALUES IN STATS.LUA INSTEAD
		-- inst:ListenForEvent("ground_check", function(inst) inst:RemoveTag("potionhopped") end) --A SPECIAL LISTENER FOR WILSON FOR HIS DOWN B HOPPING
		

        if master_postinit ~= nil then
            master_postinit(inst)
        end

        --V2C: sleeping bag hacks
        inst.OnSleepIn = OnSleepIn
        inst.OnWakeUp = OnWakeUp

        inst._OnSave = inst.OnSave
        inst._OnPreLoad = inst.OnPreLoad
        inst._OnLoad = inst.OnLoad
        inst._OnDespawn = inst.OnDespawn
        inst.OnSave = OnSave
        inst.OnPreLoad = OnPreLoad
        inst.OnLoad = OnLoad
        inst.OnDespawn = OnDespawn
		

        if starting_inventory ~= nil and #starting_inventory > 0 then
            --Will be triggered from SpawnNewPlayerOnServerFromSim
            --only if it is a new spawn
            inst._OnNewSpawn = inst.OnNewSpawn
            inst.OnNewSpawn = function()
                if inst.components.inventory ~= nil then
                    inst.components.inventory.ignoresound = true
                    for i, v in ipairs(starting_inventory) do
                        inst.components.inventory:GiveItem(SpawnPrefab(v))
                    end
                    inst.components.inventory.ignoresound = false
                end
                if inst._OnNewSpawn ~= nil then
                    inst:_OnNewSpawn()
                    inst._OnNewSpawn = nil
                end
            end
        end

        inst:ListenForEvent("startfiredamage", OnStartFireDamage)
        inst:ListenForEvent("stopfiredamage", OnStopFireDamage)
		
		--11-14-22 CRASH FIX
		inst.EnableLoadingProtection = fns.EnableLoadingProtection
        inst.DisableLoadingProtection = fns.DisableLoadingProtection

        TheWorld:PushEvent("ms_playerspawn", inst)

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return MakePlayerCharacter
