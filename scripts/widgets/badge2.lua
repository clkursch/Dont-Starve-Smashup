local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local easing = require "easing"
local Widget = require "widgets/widget"

--2-8-22 RENAMING TO "BADGE2" SO HUD MODS DON'T MESS WITH IT'S LAYOUT

local Badge2 = Class(Widget, function(self, anim, owner, tint, iconbuild) --1-1-20 --ADDING THE TWO ADDITIONAL FILEDS FROM THE UPDATE
    
    Widget._ctor(self, "Badge2")
	self.owner = owner
    
    --self:SetHAnchor(ANCHOR_RIGHT)
    --self:SetVAnchor(ANCHOR_TOP)
    self.percent = 1
    self:SetScale(1,1,1)
    
    
    self.pulse = self:AddChild(UIAnim())
    self.pulse:GetAnimState():SetBank("pulse")
    self.pulse:GetAnimState():SetBuild("hunger_health_pulse")

    self.warning = self:AddChild(UIAnim())
    self.warning:GetAnimState():SetBank("pulse")
    self.warning:GetAnimState():SetBuild("hunger_health_pulse")
    self.warning:Hide()

    -- self.anim = self:AddChild(UIAnim())
    -- self.anim:GetAnimState():SetBank(anim)
    -- self.anim:GetAnimState():SetBuild(anim)
    -- self.anim:GetAnimState():PlayAnimation("anim")
	
	--1-1-20 --REPLACING THE ABOVE WITH THE UPDATED CODE FROM KLEI'S NEW BADGE FILE (ALSO HAPPY NEW YEAR :)
    if anim ~= nil then
        self.anim = self:AddChild(UIAnim())
        self.anim:GetAnimState():SetBank(anim)
        self.anim:GetAnimState():SetBuild(anim)
        self.anim:GetAnimState():PlayAnimation("anim")
    else
        --self.bg clashes with existing mods
        self.backing = self:AddChild(UIAnim())
        self.backing:GetAnimState():SetBank("status_meter")
        self.backing:GetAnimState():SetBuild("status_meter")
        self.backing:GetAnimState():PlayAnimation("bg")

        self.anim = self:AddChild(UIAnim())
        self.anim:GetAnimState():SetBank("status_meter")
        self.anim:GetAnimState():SetBuild("status_meter")
        self.anim:GetAnimState():PlayAnimation("anim")
        if tint ~= nil then
            self.anim:GetAnimState():SetMultColour(unpack(tint))
        end

        --self.frame clashes with existing mods
        self.circleframe = self:AddChild(UIAnim())
        self.circleframe:GetAnimState():SetBank("status_meter")
        self.circleframe:GetAnimState():SetBuild("status_meter")
        self.circleframe:GetAnimState():PlayAnimation("frame")
        if iconbuild ~= nil then
            self.circleframe:GetAnimState():OverrideSymbol("icon", iconbuild, "icon")
        end
    end
	
    self.underNumber = self:AddChild(Widget("undernumber"))
    
    self.num = self:AddChild(Text(BODYTEXTFONT, 33))
    self.num:SetHAlign(ANCHOR_MIDDLE)
    self.num:SetPosition(5, 0, 0)
    --self.num:Hide() --DONT DO THAT
    
end)

function Badge2:OnGainFocus()
    -- Badge2._base.OnGainFocus(self)
    -- self.num:Show()
end

function Badge2:OnLoseFocus()
    -- Badge2._base.OnLoseFocus(self)
    -- self.num:Hide() --11-2-16 HAH! git that weak crap outta here
end

function Badge2:SetPercent(val, max) --(val, max)
    val = val or self.percent
    -- max = max or 100
	
    -- self.anim:GetAnimState():SetPercent("anim", 1 - val)  --2-20-17 GUESS WHAT?? TIME TO EDIT THIS TOO.
	-- self.anim:GetAnimState():SetPercent("anim", 0 - (val/120))
	self.anim:GetAnimState():SetPercent("anim", val)
	
	-- print("CHICKEN PAWS???", self.owner, val) --PERFECT >:3c
	
    
	
	-- self.num:SetString(tostring(math.ceil(val*max))) --AND THIS TOO
	-- self.num:SetString((tostring(math.ceil(val*max)))..tostring(tail))
	if self.owner.components.percent.hpmode then
		-- self.num:SetString((tostring(math.ceil(val)))..tostring("hp"))
		--I GOTTA DO THIS ALL AGAIN HERE BC THE PERCENT VALUE HAD TO BE MANIPULATED TO MAKE THE HUD VISUALS WORK
		local hp = self.owner.components.percent.maxhp - self.owner.components.percent.currentpercent
		if hp < 0 then hp = 0 end
		self.num:SetString((tostring(math.ceil(hp)))..tostring("hp"))
	else
		self.num:SetString((tostring(math.ceil(val*max)))..tostring("%"))
	end
            
    self.percent = val
end

function Badge2:SetDamagePercent(val, max, tail)
    val = val or self.percent
    -- max = max or 999 --POINTLESS NOW
	-- local tail = tail or "%"
	local pronoun
	if tail then
		pronoun = tail
	else
		pronoun = "%"
	end
	
    -- self.anim:GetAnimState():SetPercent("anim", 1 - (val/120))   --(val/120)
	-- self.anim:GetAnimState():SetPercent("anim", 0 + (val/120))   --(val/120)
	-- self.anim:GetAnimState():SetPercent("anim", max, 0 - (val/120)) --2-20-17
	-- self.anim:GetAnimState():SetPercent("anim", 100, 0)
	-- self.anim:GetAnimState():SetPercent("anim", val, 0)
	self.anim:GetAnimState():SetPercent("anim", (max - val), 0)
	-- print("SETTING STRING I GUESS")
	--print(val/120)
    --self.num:SetString(tostring(math.ceil(val/max)))
	-- self.num:SetString((tostring(math.ceil(val))).."%")
	self.num:SetString((tostring(math.ceil(val)))..tostring(tail))
            
    self.percent = val
end


function Badge2:SetString(val) 
    
	self.num:SetString(tostring(val))
end

function Badge2:PulseGreen()
    self.pulse:GetAnimState():SetMultColour(0,1,0,1)
	self.pulse:GetAnimState():PlayAnimation("pulse")
end

function Badge2:PulseRed()
    self.pulse:GetAnimState():SetMultColour(1,0,0,1)
	self.pulse:GetAnimState():PlayAnimation("pulse")
end

function Badge2:StopWarning()
	if self.warning.shown then
		self.warning:Hide()
	end
end

function Badge2:StartWarning()
	if not self.warning.shown then
		self.warning:Show()
		self.warning:GetAnimState():SetMultColour(1,0,0,1)
		self.warning:GetAnimState():PlayAnimation("pulse", true)
	end
end

return Badge2