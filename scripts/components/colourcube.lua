--------------------------------------------------------------------------
--[[ ColourCube ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local easing = require("easing")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local IDENTITY_COLOURCUBE = "images/colour_cubes/identity_colourcube.tex"

--DST CHANGE @@@@@
--8-5-17 CHANGING ALL THE COLORCUBE THINGS TO THE IDENTITY COLORCUBE, LIKE DARKZEROS THING DID FOR THE SINGLEPLAYER ONE

local INSANITY_COLOURCUBES =
{
    day = "images/colour_cubes/insane_day_cc.tex",
    dusk = "images/colour_cubes/insane_dusk_cc.tex",
    night = "images/colour_cubes/insane_night_cc.tex",
    full_moon = "images/colour_cubes/insane_night_cc.tex",
}

local SEASON_COLOURCUBES =
{
    autumn =
    {
        day = IDENTITY_COLOURCUBE, --"images/colour_cubes/day05_cc.tex",
        dusk = "images/colour_cubes/dusk03_cc.tex",
        night = "images/colour_cubes/night03_cc.tex",
        full_moon = "images/colour_cubes/purple_moon_cc.tex"
    },
    winter =
    {
        day = "images/colour_cubes/snow_cc.tex",
        dusk = "images/colour_cubes/snowdusk_cc.tex",
        night = "images/colour_cubes/night04_cc.tex",
        full_moon = "images/colour_cubes/purple_moon_cc.tex"
    },
    spring =
    {
        day = IDENTITY_COLOURCUBE, --"images/colour_cubes/spring_day_cc.tex",
        dusk = "images/colour_cubes/spring_dusk_cc.tex",
        night = "images/colour_cubes/spring_dusk_cc.tex",--"images/colour_cubes/spring_night_cc.tex",
        full_moon = "images/colour_cubes/purple_moon_cc.tex"
    },
    summer =
    {
        day = IDENTITY_COLOURCUBE, --"images/colour_cubes/summer_day_cc.tex",
        dusk = "images/colour_cubes/summer_dusk_cc.tex",
        night = "images/colour_cubes/summer_night_cc.tex",
        full_moon = "images/colour_cubes/purple_moon_cc.tex"
    },
}

local CAVE_COLOURCUBES =
{
    night = "images/colour_cubes/caves_default.tex",
}

local PHASE_BLEND_TIMES =
{
    day = 4,
    dusk = 6,
    night = 8,
    full_moon = 8,
}

local SEASON_BLEND_TIME = 10
local DEFAULT_BLEND_TIME = .25

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _iscave = inst:HasTag("cave")
local _phase = _iscave and "night" or "day"
local _fullmoonphase = nil
local _season = "autumn"
local _ambientcctable = _iscave and CAVE_COLOURCUBES or SEASON_COLOURCUBES.autumn
local _insanitycctable = INSANITY_COLOURCUBES
local _ambientcc = { _ambientcctable[_phase], _ambientcctable[_phase] }
local _insanitycc = { _insanitycctable[_phase], _insanitycctable[_phase] }
local _overridecc = nil
local _overridecctable = nil
local _overridephase = nil
local _remainingblendtime = 0
local _totalblendtime = 0
local _fxtime = 0
local _fxspeed = 0
local _activatedplayer = nil --cached for activation/deactivation only, NOT for logic use
local _colourmodifier = nil

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function ShouldSkipBlend()
    return _activatedplayer == nil or TheFrontEnd:GetFadeLevel() >= 1
end

local function GetCCPhase()
    return (_overridephase and _overridephase.fn and _overridephase.fn())
        or (_iscave and "night")
        or (_phase == "night" and _fullmoonphase or _phase)
end

local function GetInsanityPhase()
    return (_iscave and "night")
        or (_phase == "night" and _fullmoonphase or _phase)
end

local function Blend(time)
    local ambientcctarget = _ambientcctable[GetCCPhase()] or IDENTITY_COLOURCUBE
    local insanitycctarget = _insanitycctable[GetInsanityPhase()] or IDENTITY_COLOURCUBE

    if _overridecc ~= nil then
        _ambientcc[2] = ambientcctarget
        _insanitycc[2] = insanitycctarget
        return
    end

    local newtarget = _ambientcc[2] ~= ambientcctarget or _insanitycc[2] ~= insanitycctarget

    if _remainingblendtime <= 0 then
        --No blends in progress, so we can start a new blend
        if newtarget then
            _ambientcc[1] = _ambientcc[2]
            _ambientcc[2] = ambientcctarget
            _insanitycc[1] = _insanitycc[2]
            _insanitycc[2] = insanitycctarget
            _remainingblendtime = time
            _totalblendtime = time
            PostProcessor:SetColourCubeData(0, _ambientcc[1], _ambientcc[2])
            PostProcessor:SetColourCubeData(1, _insanitycc[1], _insanitycc[2])
            PostProcessor:SetColourCubeLerp(0, 0)
        end
    elseif newtarget then
        --Skip any blend in progress and restart new blend
        if _remainingblendtime < _totalblendtime then
            _ambientcc[1] = _ambientcc[2]
            _insanitycc[1] = _insanitycc[2]
            PostProcessor:SetColourCubeLerp(0, 0)
        end
        _ambientcc[2] = ambientcctarget
        _insanitycc[2] = insanitycctarget
        _remainingblendtime = time
        _totalblendtime = time
        PostProcessor:SetColourCubeData(0, _ambientcc[1], _ambientcc[2])
        PostProcessor:SetColourCubeData(1, _insanitycc[1], _insanitycc[2])
    elseif _remainingblendtime >= _totalblendtime and time < _totalblendtime then
        --Same target, but hasn't ticked yet, so switch to the faster time
        _remainingblendtime = time
        _totalblendtime = time
    end

    if _remainingblendtime > 0 and ShouldSkipBlend() then
        _remainingblendtime = 0
        PostProcessor:SetColourCubeLerp(0, 1)
    end
end

local function UpdateAmbientCCTable(blendtime)
    _ambientcctable = _overridecctable or (_iscave and CAVE_COLOURCUBES or SEASON_COLOURCUBES[_season]) or SEASON_COLOURCUBES.autumn
    Blend(blendtime)
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnOverridePhaseEvent(inst)
    -- just naively force an update when an override event happens
    UpdateAmbientCCTable(_overridephase and _overridephase.blendtime or DEFAULT_BLEND_TIME)
end

local function OnSanityDelta(player, data)
    local distortion = 1 - easing.outQuad(data.newpercent, 0, 1, 1)
    if player ~= nil and player:HasTag("dappereffects") then
        distortion = distortion * distortion
    end
    PostProcessor:SetColourCubeLerp(1, distortion)
    PostProcessor:SetDistortionFactor(1 - distortion)
    _fxspeed = easing.outQuad(1 - data.newpercent, 0, .2, 1)
end

local function OnOverrideCCTable(player, cctable)
    _overridecctable = cctable
    UpdateAmbientCCTable(DEFAULT_BLEND_TIME)
end

local function OnOverrideCCPhaseFn(player, fn)
    local blendtime = nil
    if _overridephase ~= nil then
        if _overridephase.blendtime ~= nil then
            blendtime = _overridephase.blendtime
        end
        for i,event in ipairs(_overridephase.events) do
            inst:RemoveEventCallback(event, OnOverridePhaseEvent)
        end
    end
    _overridephase = fn
    if _overridephase ~= nil then
        if _overridephase.blendtime ~= nil then
            -- We take the shorter blendtime when transitioning between overrides
            -- This makes the molehat always transition snappily
            blendtime = blendtime ~= nil and math.min(blendtime, _overridephase.blendtime) or _overridephase.blendtime
        end
        for i,event in ipairs(_overridephase.events) do
            inst:ListenForEvent(event, OnOverridePhaseEvent)
        end
    end
    UpdateAmbientCCTable(blendtime or DEFAULT_BLEND_TIME)
end

local function OnPlayerActivated(inst, player)
    if _activatedplayer == player then
        return
    elseif _activatedplayer ~= nil and _activatedplayer.entity:IsValid() then
        inst:RemoveEventCallback("sanitydelta", OnSanityDelta, _activatedplayer)
        inst:RemoveEventCallback("ccoverrides", OnOverrideCCTable, player)
        inst:RemoveEventCallback("ccphasefn", OnOverrideCCPhaseFn, player)
    end
    _activatedplayer = player
    inst:ListenForEvent("sanitydelta", OnSanityDelta, player)
    inst:ListenForEvent("ccoverrides", OnOverrideCCTable, player)
    inst:ListenForEvent("ccphasefn", OnOverrideCCPhaseFn, player)
    if player.replica.sanity ~= nil then
        OnSanityDelta(player, { newpercent = player.replica.sanity:GetPercent() })
    end
    OnOverrideCCTable(player, player.components.playervision ~= nil and player.components.playervision:GetCCTable() or nil)
    OnOverrideCCPhaseFn(player, player.components.playervision ~= nil and player.components.playervision:GetCCPhaseFn() or nil)
end

local function OnPlayerDeactivated(inst, player)
    inst:RemoveEventCallback("sanitydelta", OnSanityDelta, player)
    inst:RemoveEventCallback("ccoverrides", OnOverrideCCTable, player)
    inst:RemoveEventCallback("ccphasefn", OnOverrideCCPhaseFn, player)
    OnSanityDelta(player, { newpercent = 1 })
    OnOverrideCCTable(player, nil)
    if player == _activatedplayer then
        _activatedplayer = nil
    end
end

local function OnPhaseChanged(inst, phase)
    if _phase ~= phase then
        _phase = phase

        local blendtime = PHASE_BLEND_TIMES[GetCCPhase()]
        if blendtime ~= nil then
            Blend(blendtime)
        end
    end
end

local function OnMoonPhaseChanged2(inst, data)
    local moonphase = data.moonphase == "full" and "full_moon" or nil
    if _fullmoonphase ~= moonphase then
        _fullmoonphase = moonphase

        local blendtime = PHASE_BLEND_TIMES[GetCCPhase()]
        if blendtime ~= nil then
            Blend(blendtime)
        end
    end
end

local OnSeasonTick = not _iscave and function(inst, data)
    _season = data.season
    UpdateAmbientCCTable(SEASON_BLEND_TIME)
end or nil

local function OnOverrideColourCube(inst, cc)
    if _overridecc ~= cc then
        _overridecc = cc

        if cc ~= nil then
            PostProcessor:SetColourCubeData(0, cc, cc)
            PostProcessor:SetColourCubeData(1, cc, cc)
            PostProcessor:SetColourCubeLerp(0, 1)
            PostProcessor:SetColourCubeLerp(1, 0)
        else
            PostProcessor:SetColourCubeData(0, _ambientcc[2], _ambientcc[2])
            PostProcessor:SetColourCubeData(1, _insanitycc[2], _insanitycc[2])
        end
    end
end

local function OnOverrideColourModifier(inst, mod)
    if _colourmodifier ~= mod then
        _colourmodifier = mod
        PostProcessor:SetColourModifier(mod or 1)
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Channel 0: ambient colour cube
--Channel 1: insanity colour cube
PostProcessor:SetColourCubeData(0, _ambientcc[1], _ambientcc[2])
PostProcessor:SetColourCubeData(1, _insanitycc[1], _insanitycc[2])
PostProcessor:SetColourCubeLerp(0, 1)
PostProcessor:SetColourCubeLerp(1, 0)
PostProcessor:SetDistortionRadii(0.5, 0.685)

--Register events
inst:ListenForEvent("playeractivated", OnPlayerActivated)
inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)
inst:ListenForEvent("phasechanged", OnPhaseChanged)
inst:ListenForEvent("moonphasechanged2", OnMoonPhaseChanged2)
if not _iscave then
    inst:ListenForEvent("seasontick", OnSeasonTick)
end
inst:ListenForEvent("overridecolourcube", OnOverrideColourCube)
inst:ListenForEvent("overridecolourmodifier", OnOverrideColourModifier)

inst:StartUpdatingComponent(self)

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

function self:OnUpdate(dt)
    if _overridecc == nil then
        if _remainingblendtime > dt and not ShouldSkipBlend() then
            _remainingblendtime = _remainingblendtime - dt
            PostProcessor:SetColourCubeLerp(0, 1 - _remainingblendtime / _totalblendtime)
        elseif _remainingblendtime > 0 then
            _remainingblendtime = 0
            PostProcessor:SetColourCubeLerp(0, 1)
        end
    end

    _fxtime = _fxtime + dt * _fxspeed
    -- PostProcessor:SetEffectTime(_fxtime)
	--7-15-21 IT LOOKS LIKE THEY CHANGED THE NAME OF THIS FUNCTION IN AN UPDATE.
	--THE UPDATE ADDS ALL THE LUNACY EFFECTS, BUT WE'LL NEVER NEED THOSE SO I'M JUST LEAVING IT OUT
	PostProcessor:SetDistortionEffectTime(_fxtime)
end

function self:LongUpdate(dt)
    self:OnUpdate(_remainingblendtime)
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    return string.format("override: %s overridefn: %s blendtime: %.2f\n\tambient: %s -> %s\n\tsanity: %s -> %s",
        _overridecc ~= nil and "true" or "false",
        _overridephase ~= nil and "true" or "false",
        _remainingblendtime,
        _ambientcc[1], _ambientcc[2],
        _insanitycc[1], _insanitycc[2]
    )
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
