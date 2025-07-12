local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local easing = require("easing")


--THE BIG OL "GAME SET" THAT APPEARS ON SCREEN WHEN A MATCH ENDS

local GameSet = Class(Widget, function(self, owner) --WE DONT NEED AN OWNER
-- local TestScreen = Class(Screen, function(self, title, text, buttons)
    -- self.owner = owner
    Widget._ctor(self, "GameSet")
	
	self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    self.proot:SetPosition(0,0,0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)
	
	
    -- self:SetScaleMode(SCALEMODE_FIXEDPROPORTIONAL)
	self:SetScaleMode(SCALEMODE_PROPORTIONAL)
	

	
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
    self.title:SetString(STRINGS.SMSH.JUMBO_GAMESET) --"GAME SET"
	
	
	self.subtitle = self.proot:AddChild(Text(BODYTEXTFONT, 80))
    self.subtitle:SetPosition(0, -100, 0)
    self.subtitle:SetString(STRINGS.SMSH.JUMBO_WINNER .. tostring(owner.gamesetnetvar:value())) --"WINNER: "
	
	
	-- self.title = self.proot:AddChild(Text(BODYTEXTFONT, 150))
    -- self.title:SetPosition(0, -20, 0)
    -- self.title:SetString("Winner")
	
end)




function GameSet:TurnOn()
	self.targetalpha = 1
	self.ease_time = 2
	self.startalpha = 0
	self.t = 0
	self.alpha = 0
	self:StartUpdating()
	--DST CHANGE-- DOES THIS WORK FROM HERE?? ALL CLIENTS NEED TO RUN THIS
	-- TheSim:SetTimeScale(0.25)
end

function GameSet:TurnOff()
	self.targetalpha = 0
	self.ease_time = 1
	self.startalpha = 1
	self.t = 0
	self.alpha = 1
	self:Hide()
end

function GameSet:OnUpdate(dt)
	self.t = self.t + dt
	self.alpha = easing.outCubic( self.t, self.startalpha, self.targetalpha-self.startalpha, self.ease_time ) 
	-- self.anim:GetAnimState():SetMultColour(1,1,1,self.alpha) --10-7-17 WHAT IS THIS??? STOP THIS
	if self.alpha <= 0 then
		self:Hide()	
		-- self:StopUpdating()
	else
		self:Show()

	end
end

return GameSet
