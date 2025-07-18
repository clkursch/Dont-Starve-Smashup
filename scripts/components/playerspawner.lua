

--10-10-20 IM BACK!
--WOW THIS VERSION IN REALLY ALL THE WAY FROM 2017???
--ITS ACTUALLY HARDLY CHANGED SINCE THEN, SO I GUESS THATS GOOD
--I THINK THIS RIP WAS ACTUALLY NESCESARY BECAUSE I HAD TO CHANGE A LOCAL FUNTION

--------------------------------------------------------------------------
--[[ PlayerSpawner class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "PlayerSpawner should not exist on client")

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local easing = require("easing")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local MODES =
{
    fixed = "Fixed",
    scatter = "Scatter",
}

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _mode = "fixed"
local _masterpt = nil
local _openpts = {}
local _usedpts = {}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function GetNextSpawnPosition()
    if next(_openpts) == nil then
        print("No registered spawn points")
        return 0, 0, 0
    end

    local nextpoint
    if _mode == "scatter" then
        local nexti = math.min(math.floor(easing.inQuart(math.random(), 1, #_openpts, 1)), #_openpts)
        nextpoint = _openpts[nexti]
        table.remove(_openpts, nexti)
        table.insert(_usedpts, nextpoint)
    else --default to "fixed"
        if _masterpt == nil then
            print("No master spawn point")
            _masterpt = _openpts[1]
        end
        nextpoint = _masterpt
        for i, v in ipairs(_openpts) do
            if v == nextpoint then
                table.remove(_openpts, i)
                table.insert(_usedpts, nextpoint)
                break
            end
        end
    end

    if next(_openpts) == nil then
        local swap = _openpts
        _openpts = _usedpts
        _usedpts = swap
    end

    local x, y, z = nextpoint.Transform:GetWorldPosition()
    return x, 0, z
end

local function PlayerRemove(player, deletesession, migrationdata, readytoremove)
    if readytoremove then
        player:OnDespawn()
        if deletesession then
            DeleteUserSession(player)
        else
            player.migration = migrationdata ~= nil and {
                worldid = TheShard:GetShardId(),
                portalid = migrationdata.portalid,
                sessionid = TheWorld.meta.session_identifier,
            } or nil
            SerializeUserSession(player)
        end
        player:Remove()
        if migrationdata ~= nil then
            TheShard:StartMigration(migrationdata.player.userid, migrationdata.worldid)
        end
    else
        player:DoTaskInTime(0, PlayerRemove, deletesession, migrationdata, true)
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnPlayerDespawn(inst, player, cb)
    if player.components and player.components.playercontroller then --9-14-17 DST-ADDING THIS!!!! NON-PLAYER FIGHTERS ALL CRASH WHEN DESPAWNED.
		player.components.playercontroller:Enable(false)
	end
    player.components.locomotor:StopMoving()
    player.components.locomotor:Clear()

    --Portal FX
    local fx = SpawnPrefab("spawn_fx_medium")
    if fx ~= nil then
        fx.Transform:SetPosition(player.Transform:GetWorldPosition())
    end

    --After colour tween, remove player via task, because
    --we don't want to remove during component update loop
    player.components.colourtweener:StartTween({ 0, 0, 0, 1 }, 13 * FRAMES, cb or PlayerRemove)
end

local function OnPlayerDespawnAndDelete(inst, player)
    OnPlayerDespawn(inst, player, function(player) PlayerRemove(player, true) end)
end

local function OnPlayerDespawnAndMigrate(inst, data)
    OnPlayerDespawn(inst, data.player, function(player) PlayerRemove(player, false, data) end)
end

local function OnSetSpawnMode(inst, mode)
    if mode ~= nil or MODES[mode] ~= nil then
        _mode = mode
    else
        _mode = "fixed"
        print('Set spawn mode "'..tostring(mode)..'" -> defaulting to Fixed mode')
    end
end

local function UnregisterSpawnPoint(spawnpt)
    if spawnpt == nil then
        return
    elseif _masterpt == spawnpt then
        _masterpt = nil
    end
    table.removearrayvalue(_openpts, spawnpt)
    table.removearrayvalue(_usedpts, spawnpt)
end

local function OnRegisterSpawnPoint(inst, spawnpt)
    if spawnpt == nil or
        _masterpt == spawnpt or
        table.contains(_openpts, spawnpt) or
        table.contains(_usedpts, spawnpt) then
        return
    elseif _masterpt == nil and spawnpt.master then
        _masterpt = spawnpt
    end
    table.insert(_openpts, spawnpt)
    inst:ListenForEvent("onremove", UnregisterSpawnPoint, spawnpt)
end

local function UnregisterMigrationPortal(portal)
    if portal == nil then return end
    --print("Unregistering portal["..tostring(portal.components.worldmigrator.id).."]")
    table.removearrayvalue(ShardPortals, portal)
end

local function OnRegisterMigrationPortal(inst, portal)
    assert(portal.components.worldmigrator ~= nil, "Tried registering a migration prefab that wasn't a migrator!")
    --print("Registering portal["..tostring(portal.components.worldmigrator.id).."]")

    if portal == nil or table.contains(ShardPortals, portal) then return end

    table.insert(ShardPortals, portal)
    inst:ListenForEvent("onremove", UnregisterMigrationPortal, portal)
end

local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

local function GetDestinationPortalLocation(player)
    local portal = nil
    if player.migration.worldid ~= nil and player.migration.portalid ~= nil then
        for i, v in ipairs(ShardPortals) do
            local worldmigrator = v.components.worldmigrator
            if worldmigrator ~= nil and worldmigrator:IsDestinationForPortal(player.migration.worldid, player.migration.portalid) then
                portal = v
                break
            end
        end
    end

    if portal ~= nil then
        print("Player will spawn close to portal #"..tostring(portal.components.worldmigrator.id))
        local pos = portal:GetPosition()
        local start_angle = math.random() * PI * 2
        local rad = portal.Physics ~= nil and portal.Physics:GetRadius() + .5 or .5
        local offset = FindWalkableOffset(pos, start_angle, rad, 8, false, true, NoHoles)

        --V2C: Do this after caching physical values, since it might remove itself
        --     and spawn in a new "opened" version, making "portal" invalid.
        portal.components.worldmigrator:ActivatedByOther()

        if offset ~= nil then
            return pos.x + offset.x, 0, pos.z + offset.z
        end
        return pos.x, 0, pos.z
    else
        print("Player will spawn at default location")
        return GetNextSpawnPosition()
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

-- inst:ListenForEvent("ms_playerdespawn", OnPlayerDespawn) 
--10-10-20 OKAY HEAR ME OUT. A FIND-ALL-IN-FILES SEARCH FOR ms_playerdespawn SHOWS ITS ONLY USED WHEN PLAYERS DISCONNECT...
--SO... MAYBE IT WOULDNT HURT IF WE JUST KINDA. REROUTED IT~  TO MAKE SURE PLAYER'S "PLAYER" ISNT SAVED WHEN THEY LEAVE THE SERVER
--SURE THIS COULD HAVE WEIRD OUTCOMES IF ITS USED ANYWHERE ELSE. BUT I THINK PUSHEVENTS ARE PRETTY MUCH ONLY LUA THINGS... RIGHT?
inst:ListenForEvent("ms_playerdespawn", OnPlayerDespawnAndDelete)  --REROUTING!
inst:ListenForEvent("ms_playerdespawnanddelete", OnPlayerDespawnAndDelete)
inst:ListenForEvent("ms_playerdespawnandmigrate", OnPlayerDespawnAndMigrate)
inst:ListenForEvent("ms_setspawnmode", OnSetSpawnMode)
inst:ListenForEvent("ms_registerspawnpoint", OnRegisterSpawnPoint)
inst:ListenForEvent("ms_registermigrationportal", OnRegisterMigrationPortal)

--------------------------------------------------------------------------
--[[ Deinitialization ]]
--------------------------------------------------------------------------

function self:OnRemoveEntity()
    while #ShardPortals > 0 do
        table.remove(ShardPortals)
    end
end

--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Public member functions ]]
function self:SpawnAtNextLocation(inst, player)
    local x, y, z = GetNextSpawnPosition()
    self:SpawnAtLocation(inst, player, x, y, z)
end
 
function self:SpawnAtLocation(inst, player, x, y, z, isloading)
    -- if migrating, resolve map location
    if player.migration ~= nil then
        -- make sure we're not just back in our
        -- origin world from a failed migration
        if player.migration.worldid ~= TheShard:GetShardId() then
            x, y, z = GetDestinationPortalLocation(player)
            for i, v in ipairs(player.migrationpets) do
                if v:IsValid() then
                    if v.Physics ~= nil then
                        v.Physics:Teleport(x, y, z)
                    elseif v.Transform ~= nil then
                        v.Transform:SetPosition(x, y, z)
                    end
                end
            end
        end
        player.migration = nil
        player.migrationpets = nil
    end

    print(string.format("Spawning player at: [%s] (%2.2f, %2.2f, %2.2f)", isloading and "Load" or MODES[_mode], x, y, z))
    player.Physics:Teleport(x, y, z)
    if player.components.areaaware ~= nil then
        player.components.areaaware:UpdatePosition(x, y, z)
    end

    -- Spawn a light if it's dark
    if not inst.state.isday and #TheSim:FindEntities(x, y, z, 4, { "spawnlight" }) <= 0 then
        SpawnPrefab("spawnlight_multiplayer").Transform:SetPosition(x, y, z)
    end

    -- Portal FX, disable/give control to player if they're loading in
    if isloading or _mode ~= "fixed" then
        player.AnimState:SetMultColour(0,0,0,1)
        player:Hide()
        player.components.playercontroller:Enable(false)
        local fx = SpawnPrefab("spawn_fx_medium")
        if fx ~= nil then
            fx.entity:SetParent(player.entity)
        end
        player:DoTaskInTime(6*FRAMES, function(inst)
            player:Show()
			--1-14-22 I'M PRETTY SURE THIS WAS CAUSING THE STRANGE GLOWING RED BUG WHEN CHARGING SMASHES
			player.AnimState:SetMultColour(1,1,1,1) --JUST DO THIS INSTEAD
            -- player.components.colourtweener:StartTween({1,1,1,1}, 19*FRAMES, function(player)
                player.components.playercontroller:Enable(true)
            -- end)
        end)
    else
        TheWorld:PushEvent("ms_newplayercharacterspawned", { player = player, mode = isloading and "Load" or MODES[_mode] })
    end
end

self.GetAnySpawnPoint = GetNextSpawnPosition

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
