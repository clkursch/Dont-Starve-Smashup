local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Button = require "widgets/button"
local ImageButton = require "widgets/imagebutton"
local TEMPLATES = require "widgets/templates"


--11-9-17- DST CHANGE
--	--	HEY HEY HEY KIDS, ITS ME AGAIN, HERE TO HIJACK THESE EXISTING FILES AND EDIT LIKE 3 LINES TO UNBREAK UPDATE CHANGES

local SCROLL_REPEAT_TIME = .15
local MOUSE_SCROLL_REPEAT_TIME = 0

-- local CharacterSelect = Class(Widget, function(self, owner, character, cbPortraitSelected, additionalCharacters)
--DST CHANGE - OH, RIGHT, NOW THE ORDER AND NUMBER OF FIELDS WILL BE DIFFERENT BECAUSE LOBBYSCREEN IS DIFFERENT TOO. I'LL PULL THE LIST FROM THE REDUX VERSION
local CharacterSelect = Class(Widget, function(self, owner, character_widget_ctor, character_widget_size, character_description_getter_fn, default_character, cbPortraitHighlighted, cbPortraitSelected, additionalCharacters)
	self.owner = owner
	Widget._ctor(self, "CharacterSelect")

	self.OnPortraitSelected = cbPortraitSelected

	self.proot = self:AddChild(Widget("ROOT"))
    
    self:BuildCharactersList(additionalCharacters or {})
    self:SetPortrait()

    self.repeat_time = (TheInput:ControllerAttached() and SCROLL_REPEAT_TIME) or MOUSE_SCROLL_REPEAT_TIME
    self:StartUpdating()
end)

function CharacterSelect:OnUpdate(dt)
	if self.repeat_time > -.01 then
        self.repeat_time = self.repeat_time - dt
    end
end

function CharacterSelect:WrapIndex(index)
	local new_index = index
	if new_index < 1 then 
		new_index = #self.characters + new_index
	end
	
	if new_index > #self.characters then 
		new_index = new_index - #self.characters
	end	
	return new_index
end

function CharacterSelect:BuildCharactersList(additionalCharacters)
	
	self.heroportrait = self.proot:AddChild(Image())
    self.heroportrait:SetScale(.85)
    self.heroportrait:SetPosition(15, 15)
    
    self.leftsmallportrait = self.proot:AddChild(ImageButton( "bigportraits/wilson.xml", "wilson_none.tex" ))
    self.leftsmallportrait:SetScale(.3)
    self.leftsmallportrait:SetPosition(-545, 0)
    self.leftsmallportrait.image:SetTint(1,1,1,.4)
    self.leftsmallportrait.focus_scale = {1.05,1.05,1.05}
    self.leftsmallportrait:SetOnClick( function()
   										self.characterIdx = self:WrapIndex( self.characterIdx - 2 )
   										self:SetPortrait()
   									end)

	self.leftportrait = self.proot:AddChild(ImageButton( "bigportraits/wilson.xml", "wilson_none.tex" ))
    self.leftportrait:SetScale(.55)
    self.leftportrait:SetPosition(-345, 0)
    self.leftportrait.image:SetTint(1,1,1,.6)
    self.leftportrait.focus_scale = {1.05,1.05,1.05}
    self.leftportrait:SetOnClick( function()
   										self.characterIdx = self:WrapIndex( self.characterIdx - 1 )
   										self:SetPortrait()
   									end)
    
	self.rightportrait = self.proot:AddChild(ImageButton( "bigportraits/wilson.xml", "wilson_none.tex" ))
    self.rightportrait:SetScale(.55)
    self.rightportrait:SetPosition(370, 0)
    self.rightportrait.image:SetTint(1,1,1,.6)
    self.rightportrait.focus_scale = {1.05,1.05,1.05}
    self.rightportrait:SetOnClick( function()
   										self.characterIdx = self:WrapIndex( self.characterIdx + 1 )
   										self:SetPortrait()
   									end)
    
    self.rightsmallportrait = self.proot:AddChild(ImageButton( "bigportraits/wilson.xml", "wilson_none.tex" ))
    self.rightsmallportrait:SetScale(.3)
    self.rightsmallportrait:SetPosition(570, 0)
    self.rightsmallportrait.image:SetTint(1,1,1,.4)
    self.rightsmallportrait.focus_scale = {1.05,1.05,1.05}
    self.rightsmallportrait:SetOnClick( function()
   										self.characterIdx = self:WrapIndex( self.characterIdx + 2 )
   										self:SetPortrait()
   									end)

    --self.portrait_shadow = self.panel:AddChild(Image("images/frontend.xml", "char_shadow.tex"))
	--self.portrait_shadow:SetPosition(0, -110)
	--self.portrait_shadow:SetScale(1.2)


	self.characters = ExceptionArrays(GetActiveCharacterList(), MODCHARACTEREXCEPTIONS_DST)
	for i = 1, #additionalCharacters do 
		table.insert(self.characters, additionalCharacters[i])
	end
	
	self.characterIdx = 1

    self.left_arrow = self.proot:AddChild(ImageButton("images/lobbyscreen.xml", "DSTMenu_PlayerLobby_arrow_paper_L.tex", "DSTMenu_PlayerLobby_arrow_paperHL_L.tex", nil, nil, nil, {1,1}, {0,0}))
    self.left_arrow:SetScale(.6)
   	self.left_arrow:SetPosition(-195, -15)
   	self.left_arrow:SetOnClick( function()
   									self.characterIdx = self:WrapIndex( self.characterIdx - 1 )
   									self:SetPortrait()
   								end)

   	self.right_arrow = self.proot:AddChild(ImageButton("images/lobbyscreen.xml", "DSTMenu_PlayerLobby_arrow_paper_R.tex", "DSTMenu_PlayerLobby_arrow_paperHL_R.tex", nil, nil, nil, {1,1}, {0,0}))
   	self.right_arrow:SetScale(.6)
   	self.right_arrow:SetPosition(200, -15)
   	self.right_arrow:SetOnClick( function()
   									self.characterIdx = self:WrapIndex( self.characterIdx + 1 )
   									self:SetPortrait()
   								end)

   	if TheInput:ControllerAttached() then 
   		self.left_arrow:SetClickable(false)
   		self.right_arrow:SetClickable(false)
   	end

end

function CharacterSelect:SetPortrait()
	local herocharacter = self.characters[self.characterIdx]
	local leftsmallcharacter = self.characters[self:WrapIndex( self.characterIdx - 2 )]
	local leftcharacter = self.characters[self:WrapIndex( self.characterIdx - 1 )]
	local rightcharacter = self.characters[self:WrapIndex( self.characterIdx + 1 )]
	local rightsmallcharacter = self.characters[self:WrapIndex( self.characterIdx + 2 )]

	if herocharacter ~= nil then
		
		local skin = "_none"

		-- get correct skin here if bases are enabled 
		-- if not table.contains(DST_CHARACTERLIST, herocharacter) then  --DST CHANGE AH HA!! FOUND YA YOU SNEAKY 
			-- self.heroportrait:SetTexture("bigportraits/" .. herocharacter..".xml", herocharacter .. ".tex")
		-- else
			-- self.heroportrait:SetTexture("bigportraits/" .. herocharacter..".xml", herocharacter .. skin .. ".tex", herocharacter .. ".tex")
		-- end

		-- Slightly hacky way of dealing with mod characters. This function doesn't take a default image and mod characters don't have the 
		-- "_none" appended.

		--DST CHANGE -ALL OF YOU MUST GO. 
		-- self.leftsmallportrait:SetTextures("bigportraits/" .. leftsmallcharacter..".xml", leftsmallcharacter .. ((PREFAB_SKINS[leftsmallcharacter] and skin) or "") .. ".tex")
		-- self.leftportrait:SetTextures("bigportraits/" .. leftcharacter..".xml", leftcharacter .. ((PREFAB_SKINS[leftcharacter] and skin) or "") .. ".tex")
		-- self.rightportrait:SetTextures("bigportraits/" .. rightcharacter..".xml", rightcharacter .. ((PREFAB_SKINS[rightcharacter] and skin) or "") .. ".tex")
		-- self.rightsmallportrait:SetTextures("bigportraits/" .. rightsmallcharacter..".xml", rightsmallcharacter .. ((PREFAB_SKINS[rightsmallcharacter] and skin) or "") .. ".tex")
		
		self.herocharacter = herocharacter
	end

	-- if self.OnPortraitSelected then 
		-- self.OnPortraitSelected()
	-- end
	if self.OnPortraitSelected then --DST CHANGE - HERES ONE THAT MORE CLOSELY RESEMBLES THE NEW REDUX VERSION...
		-- if w.face.herocharacter then --IT LOOKS LIKE THE CHARACTER WE ARE LOOKING FOR IS CHARACTER 0 ON THE CHARACTER TABLE, WHICH WOULD BE WILSON
			-- self.OnPortraitSelected(w.face.herocharacter)
		-- end
		self.OnPortraitSelected(0)
	end
end

function CharacterSelect:Scroll(dir)
	if dir < 0 then 
		self.characterIdx = self:WrapIndex(self.characterIdx - 1)
	    self:SetPortrait()
	elseif dir > 0 then 
		self.characterIdx = self:WrapIndex(self.characterIdx + 1)
	    self:SetPortrait()
	else
		self:SetPortrait()
	end
end

function CharacterSelect:SelectRandomCharacter()
	for k,v in ipairs(self.characters) do
		if v == "random" then
			self.characterIdx = k
			self:SetPortrait()
		end
	end
end

function CharacterSelect:GetCharacter()
	return self.characters[self.characterIdx]
end

return CharacterSelect