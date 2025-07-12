local Percent = Class(function(self, inst)
    self.inst = inst
    self.maxpercent = 999 --1300
    self.minpercent = 0
    --self.currentpercent = self.maxpercent
	self.currentpercent = 0
    self.invincible = false
	self.hpmode = false --HP INSTEAD OF PERCENT 2-16-17
	self.maxhp = 50
    
    self.vulnerabletoheatdamage = true
	self.takingfiredamage = false
	self.takingfiredamagetime = 0
	self.fire_damage_scale = 1
	self.nofadeout = false
	self.penalty = 0
    self.absorb = 0

    self.canmurder = true
    self.canheal = true
	
end)

function Percent:SetInvincible(val)
    self.invincible = val
    self.inst:PushEvent("invincibletoggle", {invincible = val})
end

function Percent:OnSave()    
    return 
    {
		percent = self.currentpercent,
		penalty = self.penalty > 0 and self.penalty or nil
	}
end



local FIRE_TIMEOUT = .5
local FIRE_TIMESTART = 1.0

function Percent:DoFireDamage(amount, doer)
	if not self.invincible and self.fire_damage_scale > 0 then
		if not self.takingfiredamage then
			self.takingfiredamage = true
			self.takingfiredamagestarttime = GetTime()
			self.inst:StartUpdatingComponent(self)
			self.inst:PushEvent("startfiredamage")
            ProfileStatsAdd("onfire")
		end
		
		local time = GetTime()
		self.lastfiredamagetime = time
		
		if time - self.takingfiredamagestarttime > FIRE_TIMESTART and amount > 0 then
			self:DoDelta(-amount*self.fire_damage_scale, false, "fire")
            self.inst:PushEvent("firedamage")		
		end
	end
end


function Percent:OnUpdate(dt)
	local time = GetTime()
	
	if time - self.lastfiredamagetime > FIRE_TIMEOUT then
		self.takingfiredamage = false
		self.inst:StopUpdatingComponent(self)
		self.inst:PushEvent("stopfiredamage")
        ProfileStatsAdd("fireout")
	end
end

function Percent:DoRegen()
    --print(string.format("Percent:DoRegen ^%.2g/%.2fs", self.regen.amount, self.regen.period))
    if not self:IsDead() then
        self:DoDelta(self.regen.amount, true, "regen")
    else
        --print("    can't regen from dead!")
    end
end

function Percent:StartRegen(amount, period, interruptcurrentregen)
    --print("Percent:StopRegen", amount, period)

    -- We don't always do this just for backwards compatibility sake. While unlikely, it's possible some modder was previously relying on
    -- the fact that StartRegen didn't stop the existing task. If they want to continue using that behavior, they now just need to add
    -- a "false" flag as the last parameter of their StartRegen call. Generally, we want to restart the task, though.
    if interruptcurrentregen == nil or interruptcurrentregen == true then
        self:StopRegen()
    end

    --print("Percent:StopRegen", amount, period)
    if not self.regen then
        self.regen = {}
    end
    self.regen.amount = amount
    self.regen.period = period

    if not self.regen.task then
        --print("   starting task")
        self.regen.task = self.inst:DoPeriodicTask(self.regen.period, function() self:DoRegen() end)
    end
end

function Percent:SetAbsorbAmount(amount)
    self.absorb = amount
end

function Percent:StopRegen()
    --print("Percent:StopRegen")
    if self.regen then
        if self.regen.task then
            --print("   stopping task")
            self.regen.task:Cancel()
            self.regen.task = nil
        end
        self.regen = nil
    end
end

function Percent:GetPenaltyPercent()
	return (self.penalty*TUNING.EFFIGY_HEALTH_PENALTY)/ self.maxpercent
end


function Percent:GetPercent()
    --return self.currentpercent / self.maxpercent
	--return self.currentpercent
	return self.currentpercent --/ 100
end

function Percent:IsInvincible()
    return self.invincible
end

function Percent:GetDebugString()
    local s = string.format("%2.2f / %2.2f", self.currentpercent, self.maxpercent - self.penalty*TUNING.EFFIGY_HEALTH_PENALTY)
    if self.regen then
        s = s .. string.format(", regen %.2f every %.2fs", self.regen.amount, self.regen.period)
    end
    return s
end


function Percent:SetMaxPercent(amount)
    self.maxpercent = amount
    self.currentpercent = amount
end

function Percent:SetMinPercent(amount)
    self.minpercent = amount
end

function Percent:IsHurt()
    return self.currentpercent < (self.maxpercent - self.penalty*TUNING.EFFIGY_HEALTH_PENALTY)
end

function Percent:GetMaxPercent()
    return (self.maxpercent - self.penalty*TUNING.EFFIGY_HEALTH_PENALTY)
end

function Percent:Kill()
    if self.currentpercent > 0 then
        self:DoDelta(-self.currentpercent)
    end
end

function Percent:IsDead()
    return false  --self.currentpercent <= 0  --NAAAAH WE LIVIN
end


local function destroy(inst)
	local time_to_erode = 1
	local tick_time = TheSim:GetTickTime()

	if inst.DynamicShadow then
        inst.DynamicShadow:Enable(false)
    end

	inst:StartThread( function()
		local ticks = 0
		while ticks * tick_time < time_to_erode do
			local erode_amount = ticks * tick_time / time_to_erode
			inst.AnimState:SetErosionParams( erode_amount, 0.1, 1.0 )
			ticks = ticks + 1
			Yield()
		end
		inst:Remove()
	end)
end

function Percent:SetPercent(percent, cause)
    self:SetVal(self.maxpercent*percent, cause)
    self:DoDelta(0)
end

function Percent:OnProgress()
	self.penalty = 0
end

function Percent:SetVal(val, cause)
    local old_percent = self:GetPercent()

    self.currentpercent = val
    if self.currentpercent > self:GetMaxPercent() then
        self.currentpercent = self:GetMaxPercent()
    end

    if self.minpercent and self.currentpercent < self.minpercent then
        self.currentpercent = self.minpercent
        self.inst:PushEvent("minpercent", {cause=cause})
    end
    if self.currentpercent < 0 then  --CHANGED BOTH TO 1 --AAAND BACK TO ZERO
        self.currentpercent = 0
    end

    local new_percent = self:GetPercent()
    
	
	--NOOOPE DONT DO THIS
	--[[
    if old_percent > 0 and new_percent <= 0 or self:GetMaxPercent() <= 0 then
        self.inst:PushEvent("death", {cause=cause})

        GetWorld():PushEvent("entity_death", {inst = self.inst, cause=cause} )

		if not self.nofadeout then
			self.inst:AddTag("NOCLICK")
			self.inst.persists = false
			self.inst:DoTaskInTime(2, destroy)
		end
    end
	]]
end


function Percent:DoDamage(amount, overtime, cause, ignore_invincible)
	amount = -amount

    if self.redirect then
        self.redirect(self.inst, amount, overtime, cause)
        return
    end

    if not ignore_invincible and (self.invincible or self.inst.is_teleporting == true) then
        return
    end
    
    if amount > 0 then --CHANGED TO GREATER THAN BECAUSE HP WORKS DIFFERENTLY IN SMASH BROS
        amount = amount - (amount * self.absorb)
    end

    local old_percent = self:GetPercent()
    self:SetVal(self.currentpercent + amount, cause)
    local new_percent = self:GetPercent()
	
	--DST CHANGE- 9-1-17 ADDING NETVARS TO ALLOW CLIENTS TO GRAB THEIR OWN HEALTH INFO FOR THEIR HUDS
	if self.inst.customhpbadgepercent and TheWorld.ismastersim then
		self.inst.customhpbadgepercent:set(new_percent) --9-1-17 LETS TRY THIS
	else
		-- print("NO CUSTOMHPBADGE DETECTED")
	end
	
    self.inst:PushEvent("percentdelta", {oldpercent = old_percent, newpercent = self:GetPercent(), overtime=overtime, cause=cause, myself=self.inst})

    if METRICS_ENABLED and self.inst == ThePlayer and cause and cause ~= "debug_key" then
        if amount > 0 then
            ProfileStatsAdd("healby_" .. cause, math.floor(amount))
            FightStat_Heal(math.floor(amount))
        end
    end

    if self.ondelta then
		self.ondelta(self.inst, old_percent, self:GetPercent())
    end
	
	
	--2-16-17
	if self.hpmode == true then
		-- print("VERSES MODE", self:GetPercent(), self.maxhp)
		if self:GetPercent() >= self.maxhp then
			self.inst:PushEvent("outofhp")
		end
	end
	
	
	--DST CHANGE-- HERE WE GO BUDDY, THE "REAL" DUMB STUFF
	-- local x, y, z = self.inst.Transform:GetWorldPosition()
	-- self.inst.components.stats.healthrock.Physics:Teleport(x, self:GetPercent(), z-5)
	
	-- print(self.currentpercent)
	
end

--2-1 --WAIT ISNT THIS THE SAME THING BUT WITHOUT CALLING COMBAT SIDE?...
function Percent:DoSilentDamage(amount, overtime, cause, ignore_invincible)
	amount = -amount

    if self.redirect then
        self.redirect(self.inst, amount, overtime, cause)
        return
    end

    if not ignore_invincible and (self.invincible or self.inst.is_teleporting == true) then
        return
    end
    
    if amount < 0 then
        amount = amount - (amount * self.absorb)
    end

    local old_percent = self:GetPercent()
    self:SetVal(self.currentpercent + amount, cause)
    local new_percent = self:GetPercent()
	
	self.inst:PushEvent("percentdelta", {oldpercent = old_percent, newpercent = self:GetPercent(), overtime=overtime, cause=cause})

	if self.ondelta then
		self.ondelta(self.inst, old_percent, self:GetPercent())
    end
	
	-- print(self.currentpercent)

end


--2-22-17
function Percent:GetHPPercent() --FOR THE HOVERBADGES SET BY HITBOXES ONLY!!!
	
	if self.hpmode then
		-- return (1 - (self.currentpercent/self.maxhp))
		return ((self.currentpercent/self.maxhp))
	else
		return (self.currentpercent/120)
	end
end


function Percent:Respawn(percent)
	
	self:DoDelta( percent or 10 )
    self.inst:PushEvent( "respawn", {} )
end

return Percent