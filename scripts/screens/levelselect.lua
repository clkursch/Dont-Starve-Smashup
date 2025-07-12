local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text" --I NEED TO BORROW THIS
local Grid = require "widgets/grid" --AND THIS
local TEMPLATES = require "widgets/redux/templates"
local UIAnim = require "widgets/uianim"
local Puppet = require "widgets/skinspuppet"
local Button = require "widgets/button"

local PopupDialogScreen 	= require("screens/popupdialog") --OH, I NEED THIS ONE
local Screen = require "widgets/screen"


--8-18-20 FINALLY SEPERATING THIS OUT FROM THE STATUSDISPLAYS LIKE A NORMAL PERSON
--1-19-22 TAKING ANOTHER STEP AND SEPERATING THESE MENUS OUT AS SCREENS


-- local SmashMenus = Class(Widget, function(self, owner)
    --Widget._ctor(self, "Status")
    --self.owner = owner
local LevelSelect = Class(Screen, function(self, profile)
	Screen._ctor(self, "LevelSelect")
	self.profile = profile
	
	
	
	local servergamemode = TUNING.SMASHUP.SERVERGAMEMODE
	local displaycontrolmenu = false
	
	--11-26-20 CHECK BY SERVERGAMEMODE INSTEAD.
	if servergamemode == 1 then --1 = ANYONES CHOICE
		displaycontrolmenu = true
	end
	
	--5-25-20 JUST A TEST
	if TheNet:GetIsServerAdmin() then
		-- print("IM AN ADMIN. SHOW ME THE MENU", self.owner:HasTag("autospawn"))
		displaycontrolmenu = true
	end
	
	
	--1-19-22 OK, GOT IT. THIS IS MANDITORY
	self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0,15,0)
    -- self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	
	--TheFrontEnd:PopScreen() 
	-- self.denselectmenu:Show() --8-15-20 I MADE A SHINY NEW MENU FOR THIS
	-- self.denselectmenu = self:GenerateDenSelect() --8-18-20 AND THEN I KILLED IT AND MADE A BETTER ONE
	-- self.lang_grid:SetFocus()
	-- TheFrontEnd:PushScreen(self.denselectmenu)
	self.denselectmenu = self:_BuildLevelSelect()
	
	
	self.default_focus = self.denselectmenu
	
	-- self.denselectmenu:SetFocus()
end)


--8-18-20 RISE MY NEW CLONE. TO RECOGNIZE NEW NETVARS ATTACHED TO THE ANCHOR
function LevelSelect:GenerateDenSelect()
	--self.denselectmenu:Kill() --KILL THE OLD ONE
	self.denselectmenu = self:AddChild(self:_BuildLevelSelect()) --MAKE A NEW ONE
	return self.denselectmenu
	-- return self:AddChild(self:_BuildLevelSelect())
end



--8-4-20 STEPPING THINGS UP A NOTCH FOR THE HORDE MODE
--AND BY THAT I MEAN STEALING KLEIS NEW IMPROVED MENU BUILDING FUNCTIONS



local function BuildSectionTitle(text, region_size)
    local title_root = Widget("title_root")
    -- local title = title_root:AddChild(Text(HEADERFONT, 70))
	local title = title_root:AddChild(Text(CHATFONT_OUTLINE, 70))
	
    title:SetRegionSize(region_size, 70)
    title:SetString(text)
    title:SetColour(UICOLOURS.GOLD_SELECTED)

    local titleunderline = title_root:AddChild( Image("images/frontend_redux.xml", "achievements_divider_top.tex") )
    titleunderline:SetScale(1.5, 1.5)
    titleunderline:SetPosition(0, -20)

    return title_root
end



--OK BUT I WANT SPECIAL BUTTONS. IMAGE BUTTONS ARE ALWAYS FUN.
-- self.fixed_root:AddChild(ImageButton("images/avatars.xml", "avatar_bg.tex"))
	-- local denbutton = self.fixed_root:AddChild(ImageButton("images/avatars.xml", "avatar_bg.tex"))
--8-8-20 FORGET THIS. TOO COMPLICATED. DOING THINGS THE STUPID WAY LIKE I ALWAYS DO.

function LevelSelect:_BuildLangButton(densize, level, locked)
    
	local puppet_root = self.root:AddChild(Widget("puppet_root"))
	puppet_root:SetPosition(0, -250)
	
	local frame = puppet_root:AddChild(Widget("frame"))
    -- frame.bg = frame:AddChild(Image(GetPlayerPortraitAtlasAndTex()))
	frame.bg = frame:AddChild(ImageButton(GetPlayerPortraitAtlasAndTex()))
    frame:SetScale(.85)
	-- self.frame.bg:SetHoverText( GetSkinName(item_key), { font = UIFONT, offset_x = 0, offset_y = 40, colour = GetColorForItem(item_key) } )
	-- frame.bg:SetHoverText( "TEST1", { font = UIFONT, offset_x = 0, offset_y = 40, colour = { 0.718, 0.824, 0.851, 1 }}) --, colour = GetColorForItem(item_key) } )
	frame.bg:SetClickable(true)
	puppet_root:SetClickable(true)
	
	puppet_root.focus_forward = frame.bg
	
	
	local puppet = puppet_root:AddChild(Puppet()) --CORNER_DUDE'S DISTANT COUSIN
    puppet:SetScale(1.5)
    puppet:SetClickable(false)
    puppet:SetPosition(0, -40) -- -70
    puppet:AddShadow()
	--self.puppet:SetVAlign(ANCHOR_MIDDLE)
	
	--MAKE THE STAGE UNSELECTABLE IF NOT UNLOCKED YET
	if locked then --"LOCKED"
		frame.bg:SetClickable(false)
		puppet.animstate:SetMultColour(0.3,0.3,0.3,1)
		puppet:SetClickable(true) --SO HOVERTEXT WORKS
		puppet:SetHoverText( STRINGS.SMSH.UI_LOCKED, { font = UIFONT, offset_x = 0, offset_y = 40, colour = { 0.718, 0.824, 0.851, 1 }}) --"LOCKED"
	end
	
	-- puppet_root.OnGainFocus = function()
		-- print("doo doo")
		-- puppet:SetScale(1.6)
    -- end
    -- puppet_root.OnLoseFocus = function()
        -- puppet:SetScale(1.5)
    -- end
	
	
	local playername = puppet_root:AddChild(Text(CHATFONT_OUTLINE, 40))
    playername:SetPosition(0, -120)
    playername:SetHAlign(ANCHOR_MIDDLE)
	-- playername:SetString(btntext)
	playername:SetString(STRINGS.SMSH.UI_TIER..level) --"TIER "
	
	-- self.puppet.animstate:SetBank("wilson")
	puppet.animstate:SetBank("spider_cocoon")
	puppet.animstate:SetBuild("spider_cocoon")
	puppet.animstate:PlayAnimation(densize, true) --"cocoon_medium"
	puppet.animstate:HideSymbol("bedazzled_flare") --9-7-21 WHY IS THIS ON BY DEFAULT >:(
	
	
	frame.bg:SetOnClick(function()
        local anchor = TheSim:FindFirstEntityWithTag("anchor")
		-- anchor.components.gamerules.hordemode = true
		-- anchor.components.hordes:StartHordeMode()
		-- anchor.components.hordes:NextWave()
		-- print("HORDE BUTTON PRESSED")
		--LOL NOT QUITE
		-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["gen_menu_handler"], "horde")
		
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setservergamemode"], "HORDE") 
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["gen_menu_handler"], "horde"..level) --THIS NO LONGER AUTO-STARTS WHEN CLICKED. NEEDS A BEGIN SESSION
		print("CLICKING THE DEN BUTTON! TWO RPC HANDLERS ", level)
		
		-- if self.denselectmenu then
			-- self.denselectmenu:Kill() --9-27-20 THE CANCEL BUTTON USED TO DO THIS, BUT WE KILLED THAT BUTTON
		-- end
		TheFrontEnd:PopScreen()  --IT'S A SCREEN NOW!
    end)
	
	puppet_root:SetScale(.85)
	
    return puppet_root
	-- return frame.bg
end


function LevelSelect:_BuildLevelSelect()
    -- local languagesRoot = Widget("ROOT")
	local languagesRoot = self.root --APPARENTLY THIS FIXED IT???? I GUESS??? MAN IDK
	
	--8-18-20 CLIENTSIDE ISNT SO GOOD AT FINDING THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	if not anchor then
		return languagesRoot --IF WE CANT FIND THE ANCHOR, JUST RETURN AN EMPTY ROOT
	end
    
    languagesRoot:SetPosition(0,0)
	--CENTERED PLEASE
	languagesRoot:SetHAnchor(ANCHOR_MIDDLE)
	languagesRoot:SetVAnchor(ANCHOR_MIDDLE)
    
    local button_width = 430
    local button_height = 45

    -- self.langtitle = languagesRoot:AddChild(BuildSectionTitle(STRINGS.UI.OPTIONS.LANG_TITLE, 200))
    -- self.langtitle:SetPosition(92, 160)
	
	self.dentitle = languagesRoot:AddChild(BuildSectionTitle("LEVEL SELECT", 800))
    self.dentitle:SetPosition(0, 320)

    self.langButtons = {}

    self.lang_grid = languagesRoot:AddChild(Grid())
    -- self.lang_grid:SetPosition(-125, 90)
    -- for _,id in pairs(LOC.GetLanguages()) do
        -- table.insert(self.langButtons, self:_BuildLangButton(button_width, button_height, id))
    -- end
	
	local button_width = 250
    local button_height = 45
	
	--8-18-20 THIS IS WHERE WE PRY THE UNLOCKTEIR FROM THE ANCHOR. HOPEFULLY THIS UPDATES ACCURATELY CLIENTSIDE
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local unlocktier = anchor._unlockteir:value()
	-- print("THE UNLOCK TIER IS", unlocktier)
	
	self.lang_grid:SetPosition(-300, 30)
	table.insert(self.langButtons, self:_BuildLangButton("cocoon_small", "1", false))
	table.insert(self.langButtons, self:_BuildLangButton("cocoon_medium", "2", (unlocktier < 2)))
	table.insert(self.langButtons, self:_BuildLangButton("cocoon_large", "3", (unlocktier < 3)))
    self.lang_grid:FillGrid(3, button_width, button_height, self.langButtons)
    
    languagesRoot.focus_forward = self.lang_grid --SO FOCUSING ON THIS CHILD WILL SET THE FOCUS TO THE GRID (I THINK)
	
	-- self.lang_grid:SetFocus() --1-18-22
	
	--YOU KNOW, SOMETIMES PLAYERS CAN BE SOFTLOCKED BY CANCELING DEPENDING ON WHEN THE PLAYER CLICKS THIS
	--SINCE WE ADDED THE END-GAME BUTTON TO THE CHAR SELECT SCREEN, LETS JUST GET RID OF THIS ONE TO PREVENT SHENANIGAINS
	--[[
	--HAVE A CANCEL BUTTON  --MAYBE A SILLY BUTTON
	self.cancelbtn = languagesRoot:AddChild(ImageButton("images/global_redux.xml", "button_carny_xlong_normal.tex", "button_carny_xlong_hover.tex", "button_carny_xlong_disabled.tex", "button_carny_xlong_down.tex"))
        self.cancelbtn.image:SetScale(.7)
        self.cancelbtn:SetFont(CHATFONT)
	-- self.cancelbtn = languagesRoot:AddChild(Button())
	self.cancelbtn:SetHAnchor(ANCHOR_MIDDLE)
	self.cancelbtn:SetVAnchor(ANCHOR_MIDDLE)
	self.cancelbtn:SetPosition(0, -220, 0)
	self.cancelbtn:SetClickable(true)
	
	self.cancelbtn:SetText("Cancel")
	-- self.cancelbtn:SetScale(1.2, 1.2, 1.2)
	
	self.cancelbtn:SetOnClick( function() 
		-- self.denselectmenu:Hide()
		-- TheFrontEnd:PopScreen(self.denselectmenu)
		-- self.denselectmenu:Close() --WE JUST WANT IT GONE SO WE CAN REGENERATE IT
		-- self.denselectmenu:Hide() --IS THIS HOW IM SUPPOSED TO DO IT THOUGH??
		-- self:RemoveChild(self.denselectmenu) --SO WILL THIS CLEAN IT ALL UP PROPERLY THOUGH?
		
		-- for i,v in ipairs(self.langButtons) do
            -- v.cb() --THE HECK IS CB??
        -- end
		self.denselectmenu:Kill() --DIE
	end)
	]]

    return languagesRoot
end











--8-15-20
function LevelSelect:BuildPostGameOptions()
	local text = nil
		
	local menu_message = PopupDialogScreen( "Wave Complete", text, { --HEY, LETS GIVE THE REDUX VERSION A SHOT
		
		--[[
		{text="Retry", cb = function() 
			SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["gen_menu_handler"], "retry_horde") 
		end},
		
		{text="Change Fighter", cb = function() 
			self.postgameselect:Hide()
			-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["gen_menu_handler"], "retry_horde") 
			self.owner:PushEvent("show_select_screen") 
		end},
		]]
		
		{text=STRINGS.SMSH.UI_QUIT, cb = function()  --"Quit"
			SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["gen_menu_handler"], "quit_horde")
			SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setservergamemode"], "PRACTICE") --10-3-20 
			-- TheFrontEnd:PopScreen()  --NO THIS DELETES THE ENTIRE HUD
			self.postgameselect:Hide()
		end},
		
		{text=STRINGS.SMSH.UI_LEVEL_SELECT, cb = function() --"Level Select"
			-- self.denselectmenu:Show()
			self.denselectmenu = self:GenerateDenSelect()
			self.postgameselect:Hide()
			--JUST KNOW, IF THEY CLICK CANCEL HERE... THEYRE BONED
		end}
		
	},
	nil, nil, "light")
	
	-- self.cancelbtn:SetOnClick( function() 
		-- self.denselectmenu:Hide()
	-- end)

    return menu_message
end


return LevelSelect