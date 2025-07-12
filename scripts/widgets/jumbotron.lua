local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local easing = require("easing")


local Jumbotron = Class(Widget, function(self, owner)
-- local TestScreen = Class(Screen, function(self, title, text, buttons)
    self.owner = owner
    Widget._ctor(self, "Jumbotron")
	
	
	
	
	self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    self.proot:SetPosition(0,0,0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)
	
	-- self.bg = self.proot:AddChild(Image("images/globalpanels.xml", "small_dialog.tex"))
    -- self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    -- self.bg:SetHRegPoint(ANCHOR_MIDDLE)
	-- self.bg:SetScale(1.2,1.2,1.2)
	
	
	
	
	
    -- self:SetScaleMode(SCALEMODE_FIXEDPROPORTIONAL)
	self:SetScaleMode(SCALEMODE_PROPORTIONAL)
	
	-- self:SetClickable(false)
	
	--WHY IS THIS HERE??? GET OUT OF HERE
	-- self.anim = self:AddChild(UIAnim())
    -- self.anim:GetAnimState():SetBank("fire_over")
    -- self.anim:GetAnimState():SetBuild("fire_over")
    -- self.anim:GetAnimState():PlayAnimation("anim", true)
	-- self.anim:GetAnimState():SetBank("newwilson")
    -- self.anim:GetAnimState():SetBuild("newwilson")
    -- self.anim:GetAnimState():PlayAnimation("idle", true)
	-- self.anim:GetAnimState():SetMultColour(1,1,1,0)
	
    -- self:SetHAnchor(ANCHOR_LEFT)
    -- self:SetVAnchor(ANCHOR_TOP)
	self:SetHAnchor(ANCHOR_MIDDLE)
    self:SetVAnchor(ANCHOR_MIDDLE)
	self:SetPosition(-200,0,0)
	self:SetScale(0.5,0.5,0.5)
    self.targetalpha = 1 --0
    self.startalpha = 1 --0
    self.alpha = 1 --0
    -- self:Hide()
    self.ease_time = .4
    self.t = 0
	
	
	
	
	--title	
    self.title = self.proot:AddChild(Text(BODYTEXTFONT, 150))
    self.title:SetPosition(0, 50, 0)
	self.title:SetScale(1.2,1.2,1.2)
    self.title:SetString("TEXT HERE")
	
	
	--header
	self.header = self.proot:AddChild(Text(BODYTEXTFONT, 150))
    self.header:SetPosition(0, (RESOLUTION_Y/4), 0)
	self.header:SetScale(0.6,0.6,0.6)
    self.header:SetString("TEXT HERE")
	
	
	-- self.subtitle = self.proot:AddChild(Text(BODYTEXTFONT, 80))
    -- self.subtitle:SetPosition(0, -100, 0)
    -- self.subtitle:SetString("WINNER: " .. tostring(owner.gamesetnetvar:value()))
	
	
	self.owner.ShowJumboMessage= function()
		
		--11-9-21 DON'T WANT JUMBOTRON STUFF SHOWING UP IN TRAILERS
		if TRAILERMODE then
			return end
		
		self:TurnOn()
		-- self:Show()
		self.title:Show()
		
		self:QuickText(self.owner.jumbotronmessage:value(), self.title) --NOW PASSES IN WHICH TEXT TO CHANGE
		
		if self.owner.messagehidetask then  --IF THERES ALREADY A TASK TO HIDE IT, CANCEL THE OLD ONE FIRST
			self.owner.messagehidetask:Cancel()
		end
		
		self.owner.messagehidetask = self.owner:DoTaskInTime(2, function()
			-- self:TurnOff()
			self.title:Hide()
		end)
	end
	
	
	--A SIMILAR FN BUT WITH SMALLER FONT NEAR THE TOP OF THE SCREEN
	self.owner.ShowJumboHeaderMessage= function()
		--11-9-21 DON'T WANT JUMBOTRON STUFF SHOWING UP IN TRAILERS
		if TRAILERMODE then
			return end
		
		self:TurnOn()
		self.header:Show()
		
		self:QuickText(self.owner.jumbotronheader:value(), self.header)
		
		if self.owner.headerhidetask then  --IF THERES ALREADY A TASK TO HIDE IT, CANCEL THE OLD ONE FIRST
			self.owner.headerhidetask:Cancel()
		end
		
		self.owner.headerhidetask = self.owner:DoTaskInTime(4, function()
			-- self:TurnOff()
			self.header:Hide()
		end)
	end
	
	self.title:Hide()
	self.header:Hide()
	
end)


function Jumbotron:QuickText(message, banner)
	self.targetalpha = 1
	self.ease_time = 2
	self.startalpha = 0
	self.t = 0
	self.alpha = 0
	
	-- self.title:SetString(tostring(message))
	banner:SetString(tostring(message))
	
	-- self:StartUpdating()
end


-- function Jumbotron:QuickSubText(message)
	-- self.targetalpha = 1
	-- self.ease_time = 2
	-- self.startalpha = 0
	-- self.t = 0
	-- self.alpha = 0
	
	-- self.title:SetString(tostring(message))
	
	-- self:StartUpdating()
-- end


function Jumbotron:TurnOn()
	self.targetalpha = 1
	self.ease_time = 2
	self.startalpha = 0
	self.t = 0
	self.alpha = 0
	self:Show()
	-- self:StartUpdating()
	--DST CHANGE-- DOES THIS WORK FROM HERE?? ALL CLIENTS NEED TO RUN THIS
	-- TheSim:SetTimeScale(0.25)
end

function Jumbotron:TurnOff()
	self.targetalpha = 0
	self.ease_time = 1
	self.startalpha = 1
	self.t = 0
	self.alpha = 1
	self:Hide()
end

function Jumbotron:OnUpdate(dt)
	
	--[[
	self.t = self.t + dt
	self.alpha = easing.outCubic( self.t, self.startalpha, self.targetalpha-self.startalpha, self.ease_time ) 
	-- self.anim:GetAnimState():SetMultColour(1,1,1,self.alpha) --10-7-17 WHAT IS THIS??? STOP THIS
	if self.alpha <= 0 then
		self:Hide()	
		-- self:StopUpdating()
	else
		self:Show()

	end
	]]
end

return Jumbotron
