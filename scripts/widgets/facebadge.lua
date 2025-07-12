local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"
local ImageButton = require "widgets/imagebutton"
local Image = require "widgets/image"
local Text = require "widgets/text"

local FaceBadge = Class(Badge, function(self, owner)
	Badge._ctor(self, "face", owner)

	-- self.sanityarrow = self.underNumber:AddChild(UIAnim())
	-- self.sanityarrow:GetAnimState():SetBank("sanity_arrow")
	-- self.sanityarrow:GetAnimState():SetBuild("sanity_arrow")
	-- self.sanityarrow:GetAnimState():PlayAnimation("neutral")
	-- self.sanityarrow:SetClickable(false)

	
	-- self.topperanim = self.underNumber:AddChild(UIAnim())
	-- self.topperanim:GetAnimState():SetBank("effigy_topper")
	-- self.topperanim:GetAnimState():SetBuild("effigy_topper")
	-- self.topperanim:GetAnimState():PlayAnimation("anim")
	-- self.topperanim:SetClickable(false)
	
	
	
	-- self.minimapBtn = self:AddChild(ImageButton(HUD_ATLAS, "map_button.tex"))
	-- self.minimapBtn = self:AddChild(Image(HUD_ATLAS, "esctemplate.tex"))
	-- self.minimapBtn = self:AddChild(ImageButton(HUD_ATLAS, "esctemplate.tex"))
	-- self.minimapBtn = self:AddChild(Image("images/map_icons/esctemplate.xml", "esctemplate.tex"))
	-- self.minimapBtn = self:AddChild(Image("images/selectscreen_portraits.xml", "wilson.tex"))
	-- self.minimapBtn = self:AddChild(Image("minimap/minimap_data.xml", "wilson.png"))
	if self.owner.components.stats then
		self.minimapBtn = self:AddChild(Image(self.owner.components.stats.facepath, self.owner.components.stats.facefile))
		self.minimapBtn:SetScale(0.7,0.7,0.7)
	end
	
    
	-- self.minimapBtn:SetOnClick( function() self:ToggleMap() end )
	-- self.minimapBtn:SetTooltip(STRINGS.UI.HUD.MAP)
	
	self.num = self:AddChild(Text(BODYTEXTFONT, 33))
    self.num:SetHAlign(ANCHOR_MIDDLE)
    -- self.num:SetPosition(40, 0, 0)
	self.num:SetPosition(0, -35, 0)
	
	-- self:StartUpdating() --OH? I NEVER EVEN NOTICED THIS BEFORE
end)


function FaceBadge:SetPercent(val)
	-- Badge.SetPercent(self, val, max)

	-- penaltypercent = penaltypercent or 0
	-- self.topperanim:GetAnimState():SetPercent("anim", penaltypercent)
	
	-- Badge.SetString(self, val)
	
	self.num:SetString(tostring(val))
end	



function FaceBadge:OnUpdate(dt)
	
	-- local down = self.owner.components.temperature:IsFreezing() or self.owner.components.hunger:IsStarving() or self.owner.components.health.takingfiredamage
	

	-- local anim = down and "arrow_loop_decrease_most" or "neutral"

	-- if anim and self.arrowdir ~= anim then
		-- self.arrowdir = anim
		-- self.sanityarrow:GetAnimState():PlayAnimation(anim, true)
	-- end
	
end

return FaceBadge