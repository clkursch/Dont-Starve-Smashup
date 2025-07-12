local Blocker = Class(function(self, inst)
    self.inst = inst
    self.consuming = false
    
    self.maxfuel = 7.5  --70.5
    self.currentfuel = 7.5 --70.5
    self.rate = 1   --PER SECOND
    
    self.sections = 1
    self.sectionfn = nil
    self.period = 0.1
    self.bonusmult = 1
    self.depleted = nil
	
	self.gaurdstall = 0
	
	self.inst:StartUpdatingComponent(self)
end)

function Blocker:SetGaurdEndurance()
	self.maxfuel = 7.5
    self.currentfuel = 7.5
end

function Blocker:MakeEmpty()
	if self.currentfuel > 0 then
		self:DoDelta(-self.currentfuel)
	end
end

function Blocker:SetDepletedFn(fn)
    self.depleted = fn
end

function Blocker:IsEmpty()
    return self.currentfuel <= 0
end


function Blocker:GetCurrentSection()
    if self:IsEmpty() then
        return 0
    else
        return math.min( math.floor(self:GetPercent()* self.sections)+1, self.sections)
    end
end

function Blocker:ChangeSection(amount)
    local fuelPerSection = self.maxfuel / self.sections
    self:DoDelta((amount * fuelPerSection)-1)
end




function Blocker:SetUpdateFn(fn)
    self.updatefn = fn
end

function Blocker:GetDebugString()

    local section = self:GetCurrentSection()
    
    return string.format("%s %2.2f/%2.2f (-%2.2f) : section %d/%d %2.2f", self.consuming and "ON" or "OFF", self.currentfuel, self.maxfuel, self.rate, section, self.sections, self:GetSectionPercent())
end

function Blocker:AddThreshold(percent, fn)
    table.insert(self.thresholds, {percent=percent, fn=fn})
    --table.sort(self.thresholds, function(l,r) return l.percent < r.percent)
end

function Blocker:GetSectionPercent()
    local section = self:GetCurrentSection()
    return (self:GetPercent() - (section - 1)/self.sections) / (1/self.sections)
end


function Blocker:GetPercent()
    if self.maxfuel > 0 then 
        return math.min(1, self.currentfuel / self.maxfuel)
    else
        return 0
    end
end

function Blocker:SetPercent(amount)
    local target = (self.maxfuel * amount)
    self:DoDelta(target - self.currentfuel)
end

function Blocker:StartConsuming()
    -- self.consuming = true		--3-2-17 REMOVING THIS!!! NEW SYSTEM UPDATES BY FRAME AND SIMPLY TESTS FOR THE "BLOCKING" STATE TAG
    -- if self.task == nil then
        -- self.task = self.inst:DoPeriodicTask(self.period, function() self:DoUpdate(self.period) end)
    -- end
	-- self:DoUpdate(self.period)
end




function Blocker:DoDelta(amount)
    local oldsection = self:GetCurrentSection()
    
    self.currentfuel = math.max(0, math.min(self.maxfuel, self.currentfuel + amount) )
    
    local newsection = self:GetCurrentSection()
    
    if oldsection ~= newsection then
        if self.sectionfn then
            self.sectionfn(newsection,oldsection)
        end
        if self.currentfuel <= 0 and self.depleted then
            --self.depleted(self.inst)
        end
    end
    
    self.inst:PushEvent("percentusedchange", {percent = self:GetPercent()})    
end




--3-1-17 YOU KNOW IT MIGHT BE TIME FOR A MAKEOVER
function Blocker:OnUpdate( dt )
	local gaurdpercent = self:GetPercent()
	local rbcol = gaurdpercent
	-- print("WHAT ARE THE GAURD PERCENTS??", self:GetPercent(), self.maxfuel, self.currentfuel)
	
    -- if self.consuming then
	if self.inst.sg and self.inst.sg:HasStateTag("blocking") then
		self.consuming = true
        self:DoDelta(-dt*self.rate)
		self.gaurdstall = 0
		
		
		if self.inst.components.hoverbadge and TheWorld.ismastersim then --12-9-17 MAKE THIS MASTERSIM ONLY TOO??? HECK, I DONT KNOW -DST CHANGE --DONT THINK IT HELPED
			-- self.inst.components.hoverbadge:SetBadgeSprite("hunger", "hunger", "block") --(bank, build, case) 
			self.inst.components.hoverbadge:SetBadgeSprite("status_shield", {0.09, 0.09, 0.95, 1}, "block") --(bank, build, case) 
			-- self.inst.components.hoverbadge:SetBadgeSprite("healthm", "healthm", "block") --(bank, build, case) 
			self.inst.components.hoverbadge:SetTopperPercent((1-(rbcol)), 0)
		end
		
		if self:IsEmpty() then --JUST PUT THIS IN HERE. DONT BREAK SHIELD IF NOT BLOCKING
			self.inst.sg:GoToState("brokegaurd")
		end
	else
		self.gaurdstall = self.gaurdstall + 0.1
	end
	
	
	if not self.inst.sg:HasStateTag("blocking") and self.consuming then --3-1-17 SHOULDNT THIS JUST BE BLOCKING???
		self.consuming = false
		if self.inst.components.hoverbadge then
			self.inst.components.hoverbadge:ForceHide()
		end
	end
	
    
    if self.updatefn then
        self.updatefn(self.inst)
    end
	
	
	--GAURD REGEN
	if self.gaurdstall >= 2 then
		self:DoDelta(-(-dt*self.rate) / 3)
		if self.gaurdstall >= 4 then
			self:DoDelta(-(-dt*self.rate) / 4)
			if self.gaurdstall >= 8 then
				self:DoDelta(-(-dt*self.rate) / 2)
			end
		end
	end

end


return Blocker
