local Widget = require "widgets/widget"
local SanityBadge = require "widgets/sanitybadge"
local HealthBadge = require "widgets/healthbadge"
local HungerBadge = require "widgets/hungerbadge"
local ImageButton = require "widgets/imagebutton"

local PercentBadge = require "widgets/percentbadge"
local FaceBadge = require "widgets/facebadge"

local Text = require "widgets/text"
local ResurrectButton = require "widgets/resurrectbutton"

local PopupDialogScreen 	= require("screens/popupdialog") --OH, I NEED THIS ONE
-- local PopupDialogScreen 	= require("screens/redux/popupdialog") --OH SNAP, THIS ONE USES THE UPDATED VERSION INSTEAD... HMM.. DO I WANT TO KEEP THE OLD ONE?
-- local PopupDialogScreenTall = require("screens/popupdialogtall") --NOW THIS CUSTOM ONE 11-25-18   --WE NEVER GOT AROUND TO USING THIS


--DISPLAYS THE PERCENT BADGES AND SUCH
--NO LONGER HOLDS ALL THE MENU STUFF BECAUSE I MOVED IT TO ITS OWN WIDGET LIKE A NORMAL PERSON


local StatusDisplays = Class(Widget, function(self, owner)
    Widget._ctor(self, "Status")
    self.owner = owner
	
    self.heart2 = self:AddChild(PercentBadge(owner)) --HealthBadge
	
	--1-1-21 OH FINE, WE CAN ADD THE GUTTED BADGES BACK IN FOR THE SAKE OF MOD COMPATIBILITY...
	self.brain = self:AddChild(SanityBadge(owner))
	self.brain:Hide()
	self.stomach = self:AddChild(HungerBadge(owner))
	self.stomach:Hide()
	self.heart = self:AddChild(HealthBadge(owner))
	self.heart:Hide()
	
	
	
	
	--9-12-17 DST CHANGE -LETS TRY GIVING THESE BADGES A USERNAME BENEATH THEM.
	self.title = self.heart2:AddChild(Text(BODYTEXTFONT, 25))
    self.title:SetPosition(20, -40, 0)
    -- self.title:SetString(tostring(self.owner.userid))
	
	--11-27-20 WE CAN DO BETTER THAN THIS!
	local playertitle = (self.owner.components.stats and self.owner.components.stats.displayname) or self.owner:GetDisplayName()
	self.title:SetString(tostring(playertitle))
	
	
	self.lives = self:AddChild(FaceBadge(owner))
	self.lives:SetPosition(60,15,0)
	-- self.lives:SetPercent("x3")
	self:LivesDelta() --TO SET THEM UP TO BEGIN WITH
    
    --self.heart2:SetPercent(self.owner.components.health:GetPercent(), self.owner.components.health.maxhealth, self.owner.components.health:GetPenaltyPercent())
	
	-- if self.components and self.components.percent then
		-- -- self.heart2:SetPercent(self.owner.components.percent:GetPercent(), self.owner.components.percent.maxpercent, self.owner.components.health:GetPenaltyPercent())
    -- end
	
	
	-- self.resurrectbutton = self:AddChild(HealthBadge(owner)) --@@DSTCHANGE@@@@@ --DUMMY BUTTON
	
	self.resurrectbutton = self:AddChild(ResurrectButton(owner)) --OKAY FINE WHATEVER, A REAL ONE
	self.resurrectbutton:Hide()
	--
	-- self.perc1 = self:AddChild(PercentBadge(owner))
    -- --self.heart2:SetPosition(38,-32,0)
    -- self.perc1:SetPosition(-400,-40,0)
	
	-- --self.perc1:SetPercent(self.owner.components.health:GetPercent(), self.owner.components.health.maxhealth, self.owner.components.health:GetPenaltyPercent())
	
	-- self.perc2 = self:AddChild(PercentBadge(owner))
    -- --self.heart2:SetPosition(38,-32,0)
    -- self.perc2:SetPosition(-2200,-40,0)
	
    -- self.inst:ListenForEvent("healthdelta", function(inst, data)  self:HealthDelta2(data) end, self.owner)
    -- self.inst:ListenForEvent("hungerdelta", function(inst, data) self:HungerDelta(data) end, self.owner)
    -- self.inst:ListenForEvent("sanitydelta", function(inst, data) self:SanityDelta(data) end, self.owner)
	
	--self.inst:ListenForEvent("percentdelta", function(inst, data) self:PercentDelta(data) end, self.owner)
	self.inst:ListenForEvent("percentdelta", function(inst, data) self:HealthDelta2(data) end, self.owner)
	
	self.inst:ListenForEvent("livesdelta", function(inst, data) self:LivesDelta(data) end, self.owner)
	
	--5-10-20 FORCEABLY ALTER THE DISPLAY NAME
	self.inst:ListenForEvent("alterdisplayname", function(inst, data) self:SetDesplayName(data) end, self.owner)
	
	
	
	--10-10-20 WAIT - HOW LONG HAS THIS BEEN UNUSED??? AND ITS JUST BEEN SITTING HERE THIS WHOLE TIME?! WTF MAN WHAT WAS I DOING
	--[[ ------------------------
	--5-14-17 DST CHANGE -- LETS TRY A CUSTOM PERCENT BADGE THAT WILL WORK BETTER FOR CLIENTS
	self.heart22 = self:AddChild(HealthBadge(owner))
    -- self.heart2:SetPosition(38,-32,0)
    self.heart22:SetPosition(40,20,0)
	self.heart22:Hide() --THIS WAS STUPID ANYWAYS
	
	self.owner:DoPeriodicTask(0, function()
		self:HealthDeltaDirty(self.owner) --YA LIKE THAT? USING THE DST TERMINOLOGY FOR STUFF >:3C
	end)
	-----------------------------]]
	
	--5-21-17 DST CHANGE, ANOTHER THING I THINK I NEED TO SLAP ON
	self.onpercentdelta = nil	--NOPE. DOESNT WORK
	if self.onpercentdelta == nil then
        self.onpercentdelta = function(owner, data) self:HealthDelta2(data) end
        self.inst:ListenForEvent("percentdelta", self.onpercentdelta, self.owner)
        -- self:SetHealthPercent(self.owner.replica.percent:GetPercent())
    end
	
	
	
	--8-31-17 NOW REMOVING THIS BECAUSE IM LEAVING IT IN MODMAIN
	--[[
	--5-22-17 HERE I GO AGAIN -- THROWING THIS HERE TO CATCH THE FN CALLED BY THE PARTY HEALTH HUD MOD
	--call upon any player healthdelta
	self.owner.UpdateBadges= function()
		--update badges
		for i, v in ipairs(AllPlayers) do
			local percent = v.customhpbadgepercent and (v.customhpbadgepercent:value())/100 or 0
			-- local max = v.customhpbadgemax and v.customhpbadgemax:value() or 0
			-- local debuff = v.customhpbadgedebuff and v.customhpbadgedebuff:value() or 0
			-- self.badgearray[i]:SetPercent(percent,max,debuff)
			-- self.badgearray[i]:SetName(v:GetDisplayName())
			
			self.heart2:SetPercent(percent)
		end
		GLOBAL.ThePlayer.UpdateBadgeVisibility()
	end
	]]
	
	
	
	--8-31-17 ACTUALLY LETS JUST RETRY THE ABOVE FN BUT WITH A NEW VERSION
	self.owner.UpdateBadges= function()
		-- print("SELF.OWNER.UPDATEBADGES! GENERAL")
		--update badges
		--10-10-20 DO WE ACTUALLY EVEN NEED THIS WHOLE THING?... LETS FIND OUT  --YES WE CERTAINLY DO
		for i, v in ipairs(AllPlayers) do
			
			v:PushEvent("percentdelta", {myself=v})
			v:PushEvent("livesdelta")
			
		end
		
		--1-1-22 LET'S NOT GET AHEAD OF OURSELVES HERE, BUT IT'S AN IDEA!...
		--
		if self.temperature then
			self.temperature:Hide()
			self.tempbadge:Hide()
			
		end
		
		-- self.owner:PushEvent("percentdelta", {myself=self.owner})
		-- self.owner:PushEvent("livesdelta")
	end
	
	--1-18-22 A STUPID WORKAROUND FOR A STUPID INCOMPATIBILITY
	self.owner:DoTaskInTime(0.5, function()
		if self.temperature then
			self.temperature:Hide()
			self.tempbadge:Hide()
		end
		-- if self.health then
			-- self.health:SetPosition(0, 0)
		-- end
		if self.maxnum then
			self.maxnum:Hide()
		end
		if self.bg then
			self.bg:Hide()
		end
	end)
	
end)




function StatusDisplays:HealthDelta(data)
	--GUTTED
end



function StatusDisplays:HealthDelta2(data)
	-- self.heart2:SetDamagePercent(data.newpercent, self.owner.components.health.maxhealth,self.owner.components.health:GetPenaltyPercent()) 
	if data.myself and data.myself.components.percent.hpmode then
		local hp = data.myself.components.percent.maxhp - data.newpercent
		local maxhp = data.myself.components.percent.maxhp
		if hp < 0 then hp = 0 end
		-- self.heart2:SetDamagePercent(hp, 0, "HP")
		-- self.heart2:SetPercent((0 + (data.newpercent/120)), 120, (hp/data.myself.components.percent.maxhp))
		self.heart2:SetPercent((1-(hp/maxhp)), maxhp, 1-(hp/maxhp))
	else
		-- self.heart2:SetDamagePercent(data.newpercent, self.owner.components.health.maxhealth,"%") 
		-- self.heart2:SetDamagePercent(data.newpercent, 0, "%", 0) 
		-- self.heart2:SetDamagePercent(data.newpercent, 100, 50)
		-- self.heart2:SetPercent((0 + (data.newpercent/120)), 120, 0) --DST CHANGE IT USED TO BE THIS ONE
		
		--DST CHANGE 10-4-17 - OH BOY GOTTA THROW THIS ON THERE FOR THE NPC OBJECTS WITHOUT HEALTH BARS (TENTICALS)
		if not data.myself then return end
		
		-- print("CHANGING THE PERCENT METER TO --- ", data.myself.customhpbadgepercent:value())
		--9-1-17 DST CHANGE THIS IS THE NEW VERSION
		self.heart2:SetPercent((0 + (data.myself.customhpbadgepercent:value()/120)), 120, 0) 
		
		-- self.heart2:SetPercent((0 + (data.newpercent/120)), "%", 0)
	end
	
	-- self.heart2:SetPercent(0.5, 0.12, 0)
	-- self.heart2:SetPercent((0 + (data.newpercent/120)), 120, 0.5)  
	--^^^ SO... IT SETS THE HALTHBADGE'S PERCENT, AND THEN THE HEALTHBADGE SETS THE BADGE'S PERCENT?...
	
	
	-- self.heart2:SetDamagePercent(data.newpercent, 20, "%") 
	-- self.heart2:SetDamagePercent(100, 20, "%") 
	
	
	--DO WE EVEN NEED THIS?? LIKE, AT ALL?? NO. JUS GET RID OF IT
	-- if data.oldpercent > .33 and data.newpercent <= .33 then
		-- self.heart2:StartWarning()
	-- else
		-- self.heart2:StopWarning()
	-- end
	
	-- if not data.overtime then
		-- if data.newpercent > data.oldpercent then
			-- -- self.heart2:PulseGreen()
			-- -- TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_up")
		-- elseif data.newpercent < data.oldpercent then
			-- --TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_down") --11-20 REMOVING CUZ IT'S ANNOYING 
			-- --self.heart2:PulseRed()
		-- end
	-- end
end


--DST CHANGE--
function StatusDisplays:SetHealthPercent(perc) --JUST FOR THIS WHINY F ^^^
	self.heart2:SetPercent((0 + (perc/120)), 120, 0)
end


--DST CHANGE-- MIGHT NOT KEEP THIS
function StatusDisplays:HealthDeltaDirty(inst) --DATA
	-- self.heart2:SetDamagePercent(data.newpercent, self.owner.components.health.maxhealth,self.owner.components.health:GetPenaltyPercent()) 
	-- if data.myself and data.myself.components.percent.hpmode then
		-- self.heart2:SetPercent((0 + (data.newpercent/120)), 120, 0)
	-- end
	
	self.heart3:SetPercent((0 + (inst.components.percent:GetPercent()/120)), 120, 0)
	-- self.heart22:SetPercent((0 + (0.5/120)), 120, 0)
	
	
	-- inst.components.percent.hpmode = true
	-- self.heart2:SetPercent(0, 0, 0)
	-- self.heart2.anim:GetAnimState():SetPercent("anim", 0)
end


function StatusDisplays:LivesDelta(data)
	if self.owner.components and self.owner.components.stats then
		-- self.lives:SetPercent("x" .. (tostring(self.owner.components.stats.lives)))
		-- self.lives:SetPercent("x" .. (tostring(self.owner.customhpbadgelives:value())))
		
		--9-23-17 DST CHANGE FOR LOBBY MODE - SHOW ~ LIVES WHEN IN LOBBY
		local tail = self.owner.customhpbadgelives:value()
		if tail == 11 then
			tail = " ~"
		end
		self.lives:SetPercent("x" .. (tostring(tail)))
		
		--10-19-17 DST CHANGE - REUSEABLE - IF THEY RAN OUT OF LIVES, BLACK OUT THEIR PERCENT BADGE.
		if tail == 0 then
			self.heart2:SetPercent((0 + (0)), 120, 1)
		end
	end
end


--5-10-20 OPTION TO FORCEABLY RENAME A FIGHTER'S NAME IN THE DISPLAY
function StatusDisplays:SetDesplayName(data) --TO USE THIS - PUSH EVENT WITH DATA.NAME = "ur name here"
	self.title:SetString(tostring(data.name))
end

function StatusDisplays:HungerDelta(data)

	
end

function StatusDisplays:SanityDelta(data)

end


function StatusDisplays:SetGhostMode()
	--@@@@DSTCHANGE@@@@@
end

function StatusDisplays:GetResurrectButton()
	return self.resurrectbutton
	--@@@@DSTCHANGE@@@@@
end

function StatusDisplays:HideStatusNumbers()
    --@@@@DSTCHANGE@@@@@
end

function StatusDisplays:ShowStatusNumbers()
    --@@@@DSTCHANGE@@@@@
end


return StatusDisplays
