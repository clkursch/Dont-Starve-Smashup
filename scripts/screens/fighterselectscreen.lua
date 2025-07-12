local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local easing = require("easing")
local ImageButton = require "widgets/imagebutton"
local TEMPLATES = require "widgets/redux/templates"

-- local ServerGameMode = require "widgets/servergamemode"
local PopupDialogScreen 	= require("screens/popupdialog")
local Grid = require "widgets/grid" --AND THIS
local ChatSidebar = require "widgets/redux/chatsidebar"

--THIS IS THE CHARACTER SELECT SCREEN
--(THAT I REALLY NEED TO RENAME)

--"WHAT'S A CLASS? IS IT LIKE A COMPONENT?" ~ME, UNFORTUNATELY

-- local FighterSelect = Class(Widget, function(self, owner) --WE DONT NEED AN OWNER
local FighterSelectScreen = Class(Screen, function(self, owner, teamsenabled)
    self.owner = owner
    Screen._ctor(self, "FighterSelectScreen")
	
	
	
	--HAH, THEY REALLY JUST SHOVE A BLACK SQUARE ON SCREEN??
	self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.black:SetTint(0,0,0,.60)	
	
	
	
	self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    self.proot:SetPosition(0,0,0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)
	
	self.pane = self.proot:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tiny.tex")) --
    self.pane:SetVRegPoint(ANCHOR_MIDDLE)
    self.pane:SetHRegPoint(ANCHOR_MIDDLE)
	self.pane:SetScale(1,0.6,0.8)
	self.pane:SetPosition(0,-10,0)
	
	self.playerselect_title = self.pane:AddChild(Text(BUTTONFONT, 65))
	-- self.playerselect_title:SetString( "SELECT A CHARACTER" )
	self.playerselect_title:SetString( STRINGS.SMSH.UI_SELECT_CHAR )
	
	self.playerselect_title:SetColour(BLACK)
	self.playerselect_title:SetPosition(0,100,0)
	-- self.playerselect_title:SetVAnchor(ANCHOR_TOP)
	
	
	self.anim = self:AddChild(UIAnim())
    -- self:SetScaleMode(SCALEMODE_FIXEDPROPORTIONAL)
	-- self:SetScaleMode(SCALEMODE_PROPORTIONAL)
	
	-- self:SetClickable(false)
    -- self.anim:GetAnimState():SetBank("fire_over")
    -- self.anim:GetAnimState():SetBuild("fire_over")
    -- self.anim:GetAnimState():PlayAnimation("anim", true)
	self.anim:GetAnimState():SetBank("newwilson")
    self.anim:GetAnimState():SetBuild("newwilson")
    self.anim:GetAnimState():PlayAnimation("idle", true)
	-- print("NOW LISTEN CLOSELY", self.anim:GetAnimState():GetBank("newwilson")) --NOPE
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
	self.anim:GetAnimState():SetMultColour(1,1,1,0)
	
	-- self:SetClickable(true)
	
	--[[ IDK WHAT ALL THESE ARE FOR
	self.tracking_mouse = true
	TheInputProxy:SetCursorVisible(true)
	self.active = true
	TheInput:ClearCachedController()
	TheInput:EnableMouse(true) --7-29-17 OH. THIS MAKES THINGS EASIER
	]]
	
	--7-3-18 --IF LOCALSPAWN MODE IS ACTIVE, THEN THIS SCREEN WILL ONLY SET WHAT LOCALPLAYER IS SET TO SPAWN WHEN THE GAME STARTS, AND NOTHING ELSE
	self.localspawnmode = false
	self.chosenp2 = false
	
	
	--SOMETHING SIMPLER....
	if TheWorld.ismastersim then
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		if anchor.components.gamerules.localp2mode == true then --IF LOCALP2 EXISTS BUT HASNT CHOSEN YET, THEN
			self.localspawnmode = true --LET PLAYER 2 PICK FIRST
			-- self.owner.jumbotronheader:set("Select Player 2's Character")
			
		elseif anchor.components.gamerules.localp2mode == false then --IF P2 HAS JUST CHOSEN, THEN
			self.localspawnmode = false --NOW LET PLAYER 1 PICK
			-- self.owner.jumbotronheader:set("Select Player 2's Character")
		end
	end
	
	--FIND OUT IF THE BONUS FIGHTER HAS BEEN UNLOCKED/ENABLED --9-23-20
	local anchor = TheSim:FindFirstEntityWithTag("anchor") --OK, SLOW COMPUTERS BEWARE, WE NEED TO ACCESS THE ANCHOR FOR THIS VALUE
	local bonusfighter = false --THE VALUE THAT DETERMINES IF THE UNLOCKABLE FIGHTER IS SELECTABLE OR NOT
	if not anchor then
		--GUESS HE'S STAYING UNSELECTABLE
	else
		--GRAB HIS SELECTABILITY FROM THE ANCHOR
		bonusfighter = anchor._bonusfighteron:value()
		-- print("AM I UNLOCKED??", anchor._bonusfighteron:value())
	end
	
	--10-13-21 OKAY, SO THE BONUSFIGHTERVALUE DIDN'T WORK SO HOT ON DEDICATED SERVERS. LETS TRY SOMETHING ELSE.
	-- print("ATTEMPT TWO OF BONUSFIGHTER VALUES", self.owner.unlockstatusnetvar:value())
	if self.owner.unlockstatusnetvar:value() >= 3 then --THIS VALUE SHOULD BE PASSED TO US AS SOON AS WE JOIN THE SERVER
		bonusfighter = true
	end
	
	self.root = self:AddChild(Widget("root")) --THIS IS GETTING OUT OF HAND
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	
	self.fixed_root = self.root:AddChild(Widget("root"))
    self.fixed_root:SetPosition(-RESOLUTION_X/2, -RESOLUTION_Y/2, 0)
	
	
	-- self.buttonpos = -200
	-- self.buttonpos = -400 --USED TO BE THIS
	self.buttonpos = -(3.0 * (RESOLUTION_X/10)) 
	self.buttonposy = (RESOLUTION_Y/2) - 50 
	-- self.rowdampen = 0 
	
	local buttondummytable = {} --A TABLE THAT WE CAN USE TO REMOVE ALL THE PLAYER PREFABS WE SPAWN IN ORDER TO MAKE THE BUTTONS
	local selectedchar = false --UNTIL THEY SELECT ONE
	local choserandom = false
	local softlockready = false
	local selectedfighter = "NEWWILSON" --1-12-22 WELL THIS IS AWKWARD. BUT THIS ONE STORES WHICH FIGHTER THEY CHOSE
	

	--5-26-20 LETS TAKE A MORE PRACTICAL APPROACH
	local iconcount = 0
	local rowcount = 0
	
	--12-29-21 MAKE A TEMPORARY LIST OF VALID CHARACTERS FOR THE RANDOM CHARACTER OPTION.
	local validrandos = {}
	for k,v in pairs(MODCHARACTERLIST) do
		if STRINGS.CHARACTER_QUOTES[tostring(v)] == "NOTPLAYABLE" 
			or (tostring(v) == "spectator2")
			or (tostring(v) == "random")
			or (tostring(v) == "spider_player" and bonusfighter == false)
			then
			-- print("INVALID CHARACTER!", v)
		else
			table.insert(validrandos, v)
			-- print("VALID CHARACTER!", v)
		end
	end
	
	
	-- CONSTRUCT THE MODCHARACTERLIST
	for k,v in pairs(MODCHARACTERLIST) do
			--10-15-17 IF CHARACTER IS LISTED AS UNPLAYABLE, DO NOT ADD THEM TO THE SELECT SCREEN
		if STRINGS.CHARACTER_QUOTES[tostring(v)] == "NOTPLAYABLE" 
			or (tostring(v) == "spectator2" and self.localspawnmode == true)
			or (tostring(v) == "spider_player" and bonusfighter == false) -- TUNING.SMASHUP.BONUSFIGHTER == 1) --9-19-20
			--ADD THE UNLOCKABLE CHECK LATER
			then
			--DO NOTHING!!
		else
			iconcount = iconcount + 1
			local newbutton = self.fixed_root:AddChild(ImageButton("images/avatars.xml", "avatar_bg.tex"))
			
			--5-26-20 A MUCH MORE PRACTICAL APPROACH USING NORMAL MATH LIKE A NORMAL PERSON
			if iconcount > 5 then
				iconcount = 1
				rowcount = rowcount + 1
				
				self.buttonposy = self.buttonposy - 150
				self.buttonpos = -(3 * (RESOLUTION_X/10))
			end
			
			
			local dabuttonx = self.buttonpos + ((RESOLUTION_X/10) * iconcount) --( k - self.rowdampen)
			local dabuttony = self.buttonposy
			
			newbutton:SetPosition( (RESOLUTION_X/2) + dabuttonx, dabuttony)
			
			--9-28-20 A WEIRD SOFTLOCK CAN OCCUR IF YOU INSTANTLY SELECT A CHARACTER AFTER BEING RESPAWNED. LETS ADD A DELAY TO PREVENT THAT
			-- newbutton:SetClickable(false)
			-- self.owner:DoTaskInTime(2.5, function(inst) newbutton:SetClickable(true) end )
			newbutton:SetClickable(true)
			
			
			-- print("PULL MY STRINGS", (STRINGS.CHARACTER_QUOTES[v]), (STRINGS.CHARACTER_QUOTES[tostring(v)]))
			
			
			--DST CHANGE - BETTER LOOKING BUTTONS 9-25-17
			local framebg = newbutton:AddChild(Image("images/avatars.xml", "avatar_frame_white.tex"))
			-- local framebg = newbutton:AddChild(Image("images/avatars.xml", "avatar_wilson.tex", "avatar_unknown.tex"))
			-- local framebg = newbutton:AddChild(Image("images/avatars.xml", (STRINGS.CHARACTERS.GENERIC.DESCRIBE.."."..tostring(v)..".tex"), "avatar_unknown.tex"))
			-- local framebg = newbutton:AddChild(Image("images/avatars.xml", (STRINGS.CHARACTERS.GENERIC.DESCRIBE.v), "avatar_unknown.tex"))
			-- local framebg = newbutton:AddChild(Image("images/avatars.xml", ((STRINGS.CHARACTERS.GENERIC.DESCRIBE.v) or "avatar_unknown.tex"), "avatar_unknown.tex"))
			-- local framebg = newbutton:AddChild(Image("images/avatars.xml", ((STRINGS.CHARACTER_QUOTES[tostring(v)]) or "avatar_mod.tex"), "avatar_mod.tex"))
			-- print("MY XML IS", (STRINGS.CHARACTERS.GENERIC.DESCRIBE[tostring(v)]))
			--5-27-20 NEW METHOD THAT ALLOWS PLAYERS TO CHOOSE CUSTOM XML FILE LOCATIONS AS WELL
			local framebg = newbutton:AddChild(Image(((STRINGS.CHARACTERS.GENERIC.DESCRIBE[tostring(v)]) or "images/avatars.xml"), 
				((STRINGS.CHARACTER_QUOTES[tostring(v)]) or "avatar_mod.tex"), "avatar_mod.tex"))
			
			
			--5-23-20 LETS ACTUALLY DISPLAY THE NAMES
			local fighter_name = newbutton:AddChild(Text(UIFONT, 30))
			fighter_name:SetString((STRINGS.CHARACTER_NAMES[tostring(v)]) or "Fighter")
			fighter_name:SetPosition(0,60,0)
			
			
			--DST CHANGE -9-25-17 -HEY LOOK AT THIS!! SOME SORT OF AUTOMATED METHOD OF CREATING DST BUTTONS
			newbutton:SetOnClick( function() 
				choserandom = false
				--5-26-20 SPECIAL BUTTONS:
				if tostring(v) == "random" then --RANDOM CHARACTER
					---12-29-21 THIS VERSION CORRECTLY SELECTS VALID CHARACTERS (thnx loopsandfroots lol)
					local replacementchar = validrandos[math.random(#validrandos)]
					-- print("CHARACTER REPLACED:", replacementchar, #validrandos)
					v = replacementchar
					choserandom = true
					self.skinspinner:Hide()
					self.puppet:Hide()
				end
				
				--SPECTATOR:
				if tostring(v) == "spectator2" then
					-- print("WILLINGLY CHOSE SPECTATOR")
					SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["bail_charselect"])
				end
				
				
				
				--7-4-18 --OKAY, LETS GET A LITTLE CRAZY WITH THIS. BUT ONLY WORRY ABOUT THIS IF ITS HOST. BECAUSE LOCAL MULTIPLAYER WILL ONLY BE ON HOST
				if TheWorld.ismastersim then
					local anchor = TheSim:FindFirstEntityWithTag("anchor")
					if anchor.components.gamerules.localp2mode == true and self.chosenp2 == false then --IF LOCALP2 EXISTS BUT HASNT CHOSEN YET, THEN
						self.localspawnmode = true --LET PLAYER 2 PICK FIRST
						-- self.owner.jumbotronheader:set("Select Player 2's Character")
					elseif anchor.components.gamerules.localp2mode == true and self.chosenp2 == true then --IF P2 HAS JUST CHOSEN, THEN
						self.localspawnmode = false --NOW LET PLAYER 1 PICK
						-- self.owner.jumbotronheader:set("Select Player 1's Character")
					end
				end
				
				
				if self.localspawnmode == true and self.chosenp2 == false then --7-3-18 --IF ONLY SELECTING THE LOCAL_P2 PLAYER
					-- if self.chosenp2 == false then
						self:PrepareToSpawnDude(v)
						self.localspawnmode = false
						self.chosenp2 = true
						--self:Hide()
						--self.owner:PushEvent("show_select_screen")
						--1-20-22 DO THIS INSTEAD OF RECREATING THE SCREEN
						self.owner.jumbotronheader:set("Select Player 1")
				else
					--[[
					SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["confirmcharselect"]) 
					selectedchar = true
					self:Hide() 
					self.owner.jumbotronheader:set(STRINGS.SMSH.JUMBO_WAITING4PLYRS) --"Waiting for other players..."
					-- print("WHO? MY NAME IS ", tostring(v))  --v.prefab
					Reincarne = tostring(v)
					]]
					selectedchar = true
					selectedfighter = tostring(v)
					--AND CHANGE OUR PUPPET'S SKIN TO MATCH, I GUESS
					local buildstring = selectedfighter.."_SKINS"
					-- self.skinspinner.spinner.text = "1" --SET THE INDEX BACK TO 1
					self.skinspinner.spinner:SetSelectedIndex(1)
					self.skinspinner:OnControl()
					if softlockready then
						self.confirmbutton:SetClickable(true)
						self.confirmbutton:OnEnable()
					end
					self.confirmbutton:SetFocus()
				end
			end)
			
			--1-19-22 FORGET ALL THAT POSITIONING
			table.insert(buttondummytable, newbutton)
			
		end	
	end
	
	-- self.default_focus = self.root
	
	
	--1-19-22 DOING THINGS THE GRID WAY INSTEAD BECAUSE THAT WORKS WITH CONTROLLERS.
	self.fightergrid = self.root:AddChild(Grid())
	-- self.root:SetVAnchor(ANCHOR_MIDDLE)
    -- self.fightergrid:SetHAnchor(ANCHOR_MIDDLE)
	-- self.fightergrid:SetVRegPoint(ANCHOR_MIDDLE)
    -- self.fightergrid:SetHRegPoint(ANCHOR_MIDDLE)
	
	local button_width = 110
    local button_height = 140
	self.fightergrid:SetPosition(-(RESOLUTION_X/6), -50)
    self.fightergrid:FillGrid(5, button_width, button_height, buttondummytable)
	
    
    -- self.root.focus_forward = self.fightergrid
	self.default_focus = self.fightergrid
	-- self.fightergrid:SetFocus()
	
	local frame = self.fixed_root:AddChild(Widget("frame"))
    -- frame.bg = frame:AddChild(Image(GetPlayerPortraitAtlasAndTex()))
	frame:SetScale(0.75)
	frame.bg = frame:AddChild(ImageButton(GetPlayerPortraitAtlasAndTex()))
	frame.bg:SetClickable(false)
	frame:SetPosition(200, 350)
	
	
	
	
	local startbtns = {}
	
	
	
	--====1-12-22 LETS GIVE A SKIN SELECT A TRY=====
	self.puppet = frame:AddChild(UIAnim())
	self.puppet:GetAnimState():SetBank("newwilson")
    self.puppet:GetAnimState():SetBuild("newwilson")
    self.puppet:GetAnimState():PlayAnimation("idle", true)
	self.puppet:GetAnimState():Pause()
	self.puppet:SetPosition(0, -130)
	self.puppet:SetScale(0.8)
	self.puppet:Hide()
																	--text, min, max, label_width, widget_width, height, spacing, CHATFONT, 20
	self.skinspinner = frame:AddChild(TEMPLATES.LabelNumericSpinner("Skin:", 1,   10,      100,         100,      40,     6   , CHATFONT, 50))
	self.skinspinner:Hide()
	self.skinspinner:SetPosition(0,-250)
	-- self.skinspinner:SetFocusChangeDir(MOVE_DOWN, self.confirmbutton)
	table.insert(startbtns, self.skinspinner)
	
	local skinnumber = nil --WHAT WILL END UP GETTING PASSED TO OUR REINCARNE
	
	-- self.skinspinner.spinner.OnControl = function() --WELL YEA BUT THIS ALSO BREAKS THE ORIGINAL FUNCTION --( _, control, down)
	--IM GONNA TRY SOMETHING WEIRD. SOMETHING I SAW THE SMARTCROCKPOT DO WITH CAMERA CONTROLS TO "APPEND" AN EXISTING FUNCTION
	local old_oncontrol = self.skinspinner.OnControl
	self.skinspinner.OnControl = function(inst, control, down, ...)
		old_oncontrol(inst, control, down, ...)
		
		-- local skinnumber = inst.skinspinner.spinner:GetSelectedIndex() 
		skinnumber = inst.spinner:GetSelectedIndex() 
		local buildstring = string.upper(selectedfighter).."_SKINS"
		local bankstring = selectedfighter
		local idleanim = "idle"
		-- print("SKINDEX", skinnumber, buildstring, buildstring[1], [tostring(buildstring)])
		-- local testring = {NEWWILSON_SKINS}
		-- local testring = {"NEWWILSON_".."SKINS"}
		-- local testring = STRINGS["NEWWILSON_".."SKINS"]
		-- local testring = GLOBEREF["NEWWILSON_".."SKINS"]
		-- print("SKINDEX", skinnumber, buildstring, NEWWILSON_SKINS[1], testring[1][1])
		-- print("SKINDEX", skinnumber, buildstring, NEWWILSON_SKINS[1], STRINGS[buildstring][1])
		-- print("SKINDEX", skinnumber, testring[1], GLOBEREF[buildstring][skinnumber])
		
		--A LAZY EXCEPTION FOR THE ODD ONE OUT
		if selectedfighter == "spider_player" then
			bankstring = "spiderfighter"
			buildstring = "SPIDER_PLAYER_SKINS"
		end
		
		if selectedfighter == "newwicker" then
			bankstring = "newwilson" --WAIT WTF? WOW I DIDNT KNOW THAT
			idleanim = "wickeridle"
		end
		
		-- if GLOBEREF[tostring(buildstring)] then
		if not (selectedfighter == "spectator2" ) then
			if teamsenabled then
				self.teamspinner:Show()
			end
			
			if choserandom == true then
				return end --1-26-22 DON'T SHOW THE SKIN SELECTION IF WE WENT RANDOM
				
			inst.spinner.max = #GLOBEREF[buildstring]
			self.skinspinner:Show()
			self.puppet:Show()
			
			-- print("PREPARING TO APPLY SKIN ", buildstring[skinnumber], tostring(buildstring[skinnumber]))
			-- print("PREPARING TO APPLY SKIN ", buildstring, skinnumber, GLOBEREF[buildstring][skinnumber])
			-- puppet.animstate:SetBuild("spider_fighter_build")
			self.puppet:GetAnimState():SetBank(bankstring)
			self.puppet:GetAnimState():SetBuild(GLOBEREF[buildstring][skinnumber])
			self.puppet:GetAnimState():PlayAnimation(idleanim, true)
			
			-- local w,h = TheSim:GetScreenSize()
			-- TheInputProxy:SetOSCursorPos(-w+1, -h+1)
			-- self.skinspinner:SetFocus()
		else
			self.skinspinner:Hide()
			self.puppet:Hide()
		end
	
	end
	
	
	--1-20-22 FOR TEAM SELECTION
	local teamspinner_options = {
		{text = STRINGS.SMSH.TEAM_RED, data = "red"}, --"Red"
		{text = STRINGS.SMSH.TEAM_RANDOM, data = "auto"}, --"Random"
		{text = STRINGS.SMSH.TEAM_BLUE, data = "blue"}, --"Blue"
	}
	--I BELEIVE.. THIS SHOULD BE KEPT UP TO DATE CLIENTSIDE TOO...
	if teamsenabled then
		-- print("TEAM BATTLES ARE ENABLED! SELECT A TEAM")
		self.teamspinner = frame:AddChild(TEMPLATES.LabelSpinner(STRINGS.SMSH.TEAM_NAME..":", teamspinner_options,      100,         200,      40,     6   , CHATFONT, 50))
		self.teamspinner:Hide()
		self.teamspinner:SetPosition(0,-300)
		self.teamspinner.spinner:SetSelectedIndex(2)
		table.insert(startbtns, self.teamspinner)
		-- self.teamspinner:SetFocusChangeDir(MOVE_UP, self.skinspinner)
		-- self.teamspinner:SetFocusChangeDir(MOVE_DOWN, self.confirmbutton)
		--local w = TEMPLATES.LabelSpinner(labeltext, spinnerdata, label_width, widget_width, height, spacing, CHATFONT, 50)
	end
	
	
	
	
	--1-12-22 OK NOW WE NEED A NEW NEW BUTTON TO CONFIRM OUR CHARACTER
	self.confirmbutton = frame:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
	-- self.confirmbutton:SetPosition( (RESOLUTION_X/2) -100, self.buttonposy - 120)
	self.confirmbutton:SetPosition( 0, -350)
	self.confirmbutton:SetText(STRINGS.SMSH.UI_OK)
	-- self.confirmbutton:SetFocusChangeDir(MOVE_UP, self.skinspinner)
	table.insert(startbtns, self.confirmbutton)
	
	--9-28-20 A WEIRD SOFTLOCK CAN OCCUR IF YOU INSTANTLY SELECT A CHARACTER AFTER BEING RESPAWNED. LETS ADD A DELAY TO PREVENT THAT
	self.confirmbutton:SetClickable(false)
	self.confirmbutton:OnDisable()
	self.owner:DoTaskInTime(2.5, function(inst) 
		if selectedchar then
			self.confirmbutton:SetClickable(true)
			self.confirmbutton:OnEnable()
		end
		softlockready = true
	end )
	
	self.confirmbutton:SetOnClick( function() 
		local teamdata = "auto"
		if self.teamspinner then
			teamdata = self.teamspinner.spinner:GetSelected().data --WHY DOESNT THIS WORK???
			-- teamdata = teamspinner_options[self.teamspinner:GetSelectedIndex()].data
		end
		
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["confirmcharselect"], teamdata) 
		selectedchar = true
		-- self:Hide() 
		self.owner.jumbotronheader:set(STRINGS.SMSH.JUMBO_WAITING4PLYRS) --"Waiting for other players..."
		Reincarne = selectedfighter
		Skinchoice = skinnumber
		TheFrontEnd:PopScreen()
	end)
	
	
	self.modhint = frame:AddChild(Text(BUTTONFONT, 40))
	self.modhint:SetString( "See the mod page for info on adding your own skins") 
	self.modhint:SetColour(WHITE)
	self.modhint:SetPosition(0,-400,0)
	table.insert(startbtns, self.modhint)
	
	
	--WE NEED TO ALIGN THIS A BIT NEATER
	self.start_grid = frame:AddChild(Grid())
	-- self.start_grid:SetHAnchor(ANCHOR_LEFT)
	-- self.start_grid:SetVAnchor(ANCHOR_TOP)
	self.start_grid:SetPosition(0, -250, 0)
	local button_width = 100
    local button_height = 60
	self.start_grid:FillGrid(1, button_width, button_height, startbtns)
	
	
	
	
	
	--5-3-17 DST CHANGE--- HEY THIS IS PROBABLY AN EASIER WAY TO DO IT ANYWAYS
	--self.inst:ListenForEvent("show_select_screen", function(inst) 
	--1-20-22 IN THIS VERSION, WE WANT IT TO SHOW RIGHT AWAY. NO HIDING
	-- self:Show()
	if self.localspawnmode == true and self.chosenp2 == false then
		self.owner.jumbotronheader:set(STRINGS.SMSH.UI_SELECT_P2) --"Select Player 2's Character"
	elseif self.localspawnmode == true and self.chosenp2 == true then
		self.owner.jumbotronheader:set(STRINGS.SMSH.UI_SELECT_P1) --"Select Player 1's Character"
	else
		self.owner.jumbotronheader:set(STRINGS.SMSH.UI_SELECT_CHAR) --"Select Character"
	end
	self.fightergrid:SetFocus()
	--end, self.owner)
	-- self.inst:ListenForEvent("show_select_screen", function(inst) self:TurnOn() end, self.owner)
	
	--7-3-18 --DST CHANGE --HERES ONE THAT LETS THE PLAYERS USE THE SELECT SCREEN TO PICK THE LOCAL P2 THAT WILL SPAWN.
	self.inst:ListenForEvent("select_local_p2", function(inst) 
		self.localspawnmode = true
		self.chosenp2 = false
		self:Show()
		-- self.owner.jumbotronheader:set("Select Player 2's Character")
	end, self.owner)
	
	--7-4-18 --SET THE VARIABLES, BUT DONT ACTUALLY SHOW THE SCREEN YET
	self.inst:ListenForEvent("set_local_p2", function(inst) 
		self.localspawnmode = true
		self.chosenp2 = false
	end, self.owner)
	
	
	
	--5-22-20 KICK PLAYERS OUT OF THE MENU IF THEY TOOK TOO LONG AND PLAYERS ARE WAITING FOR THEM 
	self.inst:ListenForEvent("force_end_charselect_dirty", function(inst) 
		-- self:Hide() 
		if selectedchar == false then
			SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["bail_charselect"]) --TELL THE SERVER WE NEVER CHOSE
			self.owner.jumbotronheader:set(STRINGS.SMSH.UI_TIME_UP) --"Time Expired" --TELL THEM THEY TOOK TOO LONG. DUMMY
			-- print("CHARACTER SELECT TIME EXPIRED")
		end
		TheFrontEnd:PopScreen()
	end, self.owner)
	
	
	--5-22-20 IN CASE OF EMERGENCY - SET OUR REINCARNE BACK TO SPECTATOR
	-- self.inst:ListenForEvent("revert_charselect_dirty", function(inst) 
		-- Reincarne = "spectator"
		-- print("CHARACTER SELECT REVERTED")
	-- end, self.owner)
	
	
	--10-14-21 OKAY, ONE LAST TRY ON THIS THING.
	-- self.inst:ListenForEvent("unlock_bonuschar", function(inst) 
		-- --NO NO, THAT WOULDN'T WORK... THE MENU BUTTONS ARE GENERATED AT INITIALIZATION. WE'D HAVE TO DELAY THE MENU BUILD UNTIL THIS VALUE IS SET SOMEHOW...
	-- end, self.owner)
	
	
	
	--9-5-17 OH MAN IT WOULD BE REALLY CONVENIENT IF THIS WORKED --PROBABLY WONT
	-- self.inst:ListenForEvent("hide_select_screen", function(inst) self:hide() end, self.owner)
	
	--!! ALRIGHT YOU LITTLE CRAP, LETS SEE YOU GET AROUND THIS ONE-
	-- self.owner.components.stats.hudref =  --OH WAIT... FINE. YOU WIN THIS ROUND
	
	
	--[[
	--6-9-17 A CUSTOM BUTTON FOR THE KIRTLE- AKA TAPJUMP
	self.kirtbutton = self:AddChild(ImageButton())
	self.kirtbutton:SetHAnchor(ANCHOR_RIGHT)
	self.kirtbutton:SetVAnchor(ANCHOR_TOP)
	self.kirtbutton:SetPosition(-175, -75, 0)
	local btnscale = 1.2
	self.kirtbutton:SetScale(btnscale,btnscale,btnscale)
	
	self.kirtbutton:SetClickable(true)
	self.kirtbutton:SetText(STRINGS.SMSH.CTRLS_TAPJ_OFF) --"Tap-Jump: OFF"
	-- self.kirtbutton:SetOnClick( function() SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["rectrler"]) end)
	
	
	
	--10-7-17 LETS MAKE THESE CONTROLS MORE FLEXIBLE.
	local tapjumppreference = Preftapjump
	
	if tapjumppreference then
		-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["rectrler"], tapjumppreference) --MAKE SURE TO RE-SEND CONTROLS FOR NEW-SPAWNS TO PICK UP
		-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["rectrler"], tapjumppreference) --IN FACT, WE GOTTA SEND EM TWICE, TO DOUBLE TOGGLE AND CANCEL OUT THE TOGGLES
		--OKAY WOW ALL WE REALLY NEEDED WAS TO WAIT A SEC BEFORE REAPPLYING THE PREFERENCES. NOW DONE IN PLAYERCOMMON
		if Preftapjump == "on" then
			self.kirtbutton:SetText(STRINGS.SMSH.CTRLS_TAPJ_ON) --"Tap-Jump: ON"
		end
	end
	
	self.kirtbutton:SetOnClick( function() 
		if Preftapjump == "off" then
			Preftapjump = "on"
			self.kirtbutton:SetText(STRINGS.SMSH.CTRLS_TAPJ_ON) --"Tap-Jump: ON"
		else
			Preftapjump = "off"
			self.kirtbutton:SetText(STRINGS.SMSH.CTRLS_TAPJ_OFF) --"Tap-Jump: OFF"
		end
		
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["rectrler"], Preftapjump) 
	end)
	
	
	--8-25-20 DONT KNOW WHY I DONT JUST PUT THE ENTIRE CONTROLS PANEL HERE TOO
	self.controlbtn = self:AddChild(ImageButton()) --WHATS THE DIFF BETWEEN ADDING TO SELF OR FIXED ROOT?
	self.controlbtn:SetHAnchor(ANCHOR_RIGHT)
	self.controlbtn:SetVAnchor(ANCHOR_TOP)
	self.controlbtn:SetPosition(-175, -150, 0)
	self.controlbtn:SetScale(btnscale,btnscale,btnscale)
	self.controlbtn:SetClickable(true)
	
	self.controlbtn:SetText(STRINGS.SMSH.UI_CONTROLS) --"Controls"
	self.controlbtn:SetOnClick( function() 
		self.owner:PushEvent("controlscreendirty")
	end)
	]]
	
	--8-25-20
	local servergamemode = TUNING.SMASHUP.SERVERGAMEMODE
	--NEVERMIND, WE DONT HAVE ACCESS TO THAT ENTIRE MENU FROM HERE. LETS JUST MAKE IT A "END GAME" BUTTON INSTEAD
	--SERIOUSLY, I HOPE YOUR PLAYERS ALL UNDERSTAND THIS CONCEPT, BECAUSE THIS IS SUPER EASY TO ABUSE AND GRIEF
	-- print("SERVER GAMEMODE: ", servergamemode, TheNet:GetIsServerAdmin(), anchor.components.gamerules.matchstate)
	if (servergamemode == 1) or (servergamemode == 2 and TheNet:GetIsServerAdmin()) then
		self.gamemodebtn = self:AddChild(ImageButton())
		self.gamemodebtn:SetHAnchor(ANCHOR_RIGHT)
		self.gamemodebtn:SetVAnchor(ANCHOR_TOP)
		self.gamemodebtn:SetPosition(-175, -75, 0)
		local btnscale = 1.2
		self.gamemodebtn:SetScale(btnscale,btnscale,btnscale)
		self.gamemodebtn:SetClickable(true)
		self.gamemodebtn:SetText(STRINGS.SMSH.UI_END_GAME) --"End Game"
		-- self.gamemodebtn.text:SetScale(.85)
		
		self.gamemodebtn:SetOnClick( function() 
			-- local text = "Exit to lobby and select a new game mode? \n"
			-- text = text .. "Any queued players will lose their spot in line. \n"
			local text = STRINGS.SMSH.UI_EXIT_LOBBY_DESC
			
			local message = PopupDialogScreen( STRINGS.SMSH.UI_ARE_YOU_SURE, text, {  --"Are you sure?"
				{text=STRINGS.SMSH.UI_END_GAME, cb = function() 
					TheNet:Announce(self.owner:GetDisplayName().." ended the game")
					SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setservergamemode"], "PRACTICE") 
					TheFrontEnd:PopScreen() 
				end},
				{text=STRINGS.SMSH.UI_CANCEL, cb = function() 
					TheFrontEnd:PopScreen()  --JUST CLOSE THE MENU
				end}
			} )
			TheFrontEnd:PushScreen( message )
		end)
		
		--1-20-22 OK THIS STOPPED WORKING FOR SOME REASON SO I'M GOING TO DISABLE IT FOR NOW
		if TheWorld.ismastersim then
			local anchor = TheSim:FindFirstEntityWithTag("anchor")
			if not anchor then 
				return end --FOR THOSE SLOW CLIENTS THAT CANT KEEP UP
			if anchor.components.gamerules.matchstate == "lobby" then
				self.gamemodebtn:Hide() --WE'RE ALREADY IN LOBBY. DONT SHOW THIS
			end
		end
	end
	
	
	
	--2-6-22 OK BUT WHAT IF I BECAME MORE...
	-- self.croot = self:AddChild(Widget("root"))
	-- self.chat_sidebar = self.croot:AddChild(ChatSidebar())
	-- self.chat_sidebar:SetHAnchor(ANCHOR_RIGHT)
	-- self.chat_sidebar:SetVAnchor(ANCHOR_MIDDLE)
	-- local scale = 1.4
	-- self.chat_sidebar:SetScale(scale,scale,scale)
	-- SetPosition(lcol-5, -375)
	
	self.croot = self:AddChild(TEMPLATES.ScreenRoot())
	self.chat_sidebar = self.croot:AddChild(ChatSidebar())
	local lcol = RESOLUTION_X/4 --2
	self.chat_sidebar:SetPosition(lcol-5, -375)
	local scale = 0.9
	self.chat_sidebar:SetScale(scale,scale,scale)
	
	self.time_to_refresh = .25 --REFRESH_INTERVAL
end)



function FighterSelectScreen:ReceiveChatMessage(...)
    self.chat_sidebar:ReceiveChatMessage(...)
end

function FighterSelectScreen:OnFocusMove(dir, down)
    if self.chat_sidebar:IsChatting() then
        -- Don't allow focus moving when chatting because WASD moves focus.
        return true
    end
    return FighterSelectScreen._base.OnFocusMove(self, dir, down)
end

function FighterSelectScreen:DoFocusHookups()
	-- self.panel:SetFocusChangeDir(MOVE_LEFT, self.chat_sidebar.chatbox)
    self.chat_sidebar:SetFocusChangeDir(MOVE_RIGHT, self.panel)
    self.chat_sidebar:DoFocusHookups()
end

function FighterSelectScreen:OnUpdate(dt)
    if self.time_to_refresh > dt then
        self.time_to_refresh = self.time_to_refresh - dt
    else
        self.time_to_refresh = .25 --REFRESH_INTERVAL
        self.chat_sidebar:Refresh()
    end

	-- if self.panel ~= nil and self.panel.OnUpdate ~= nil then
		-- self.panel:OnUpdate(dt)
	-- end

end




--1-24-22 OKAY, I HAVE NO IDEA HOW WELL THIS WILL WORK BUT, LETS SEE IF WE CAN REPLACE THIS SIDE MENU WITH PRESSING THE ESCAPE KEY.
--RIPPED THIS CHUNK OUT OF THE ARTIFICIAL WILSON MOD
function FighterSelectScreen:OnControl(control, down)
	if FighterSelectScreen._base.OnControl(self,control, down) then return true end
	
	if down then return end
	if control == CONTROL_PAUSE or control == CONTROL_CANCEL or control == CONTROL_MENU_MISC_3 then
		-- self:Close()
		
		
		--8-25-20
		local servergamemode = TUNING.SMASHUP.SERVERGAMEMODE
		--NEVERMIND, WE DONT HAVE ACCESS TO THAT ENTIRE MENU FROM HERE. LETS JUST MAKE IT A "END GAME" BUTTON INSTEAD
		--SERIOUSLY, I HOPE YOUR PLAYERS ALL UNDERSTAND THIS CONCEPT, BECAUSE THIS IS SUPER EASY TO ABUSE AND GRIEF
		-- print("SERVER GAMEMODE: ", servergamemode, TheNet:GetIsServerAdmin(), anchor.components.gamerules.matchstate)
		if (servergamemode == 1) or (servergamemode == 2 and TheNet:GetIsServerAdmin()) then
			
			-- local text = "Exit to lobby and select a new game mode? \n"
			-- text = text .. "Any queued players will lose their spot in line. \n"
			local text = STRINGS.SMSH.UI_EXIT_LOBBY_DESC
			
			local message = PopupDialogScreen( STRINGS.SMSH.UI_ARE_YOU_SURE, text, {  --"Are you sure?"
				{text=STRINGS.SMSH.UI_END_GAME, cb = function() 
					TheNet:Announce(self.owner:GetDisplayName().." ended the game")
					TheFrontEnd:PopScreen() 
					SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setservergamemode"], "PRACTICE") 
				end},
				{text=STRINGS.SMSH.UI_CANCEL, cb = function() 
					TheFrontEnd:PopScreen()  --JUST CLOSE THE MENU
				end}
			} )
			TheFrontEnd:PushScreen( message )
			
		end
		
		
		
		return true
	end
end


--[[ --UNUSED
function FighterSelectScreen:SpawnADude(dude)
	local p1 = SpawnPrefab(dude)
	local distoffset = 2
	for k,v in pairs(GetPlayer().components.gamerules.livingplayers) do
		distoffset = distoffset -4
	end
	
	local x, y, z = GetPlayer().Transform:GetWorldPosition()
	GetPlayer().components.gamerules:SpawnPlayer(p1, x+distoffset, y, z-5)
end]]


--7-3-18 --WHEN A LOCAL P2 IS CHOSEN, IT WILL SPAWN NEXT ROUND.
function FighterSelectScreen:PrepareToSpawnDude(dude)
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	
	-- anchor.components.gamerules:SpawnLocalP2(dude)  --NOT QUITE YET. JUST TELL THEM WHICH DUDE YOU'D LIKE TO SPAWN, AND IT WILL BE SPAWNED WHEN THE GAME STARTS.
	anchor.components.gamerules.localp2mode = true
	anchor.components.gamerules.p2_reincarne = dude
	--SET P2'S TAPJUMP CONTROLS TO WHATEVER THEY ARE SET TO AT THE MOMENT THEY SELECT THEIR CHARACTER
	Preftapjump_p2 = Preftapjump
	
	-- if anchor.components.gamerules.hordemode == false then --NOT YET! IF ITS HORDE MODE, LET PLAYER1 PICK BEFORE STARTING
		-- anchor.components.gamerules:StageReset() --NOW SET THE STAGE FOR A FIGHT  
	-- end
end


--7-4-18 --UNUSED I THINK??? --UM NO WE DEFINATELY STILL USE THIS, EXCUSE YOU
function FighterSelectScreen:FinalizeDudes()   
	SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["confirmcharselect"]) --TELLS SERVER WE'RE DONE CHOOSING
	-- self:Hide() 
	self.owner.jumbotronheader:set("Waiting for other players...")
	-- print("WHO? MY NAME IS ", tostring(v))  --v.prefab
	Reincarne = tostring(self.p1dude) --DETERMINES WHICH FIGHTER WE WILL RESPAWN AS 
	TheFrontEnd:PopScreen()
end


--[[
function FighterSelectScreen:SpawnQueen()
	local queen = SpawnPrefab("spiderfighter_queen") --spiderfighter_queen
	-- queen:AddComponent("stats")
	local x, y, z = GetPlayer().Transform:GetWorldPosition()
	
	GetPlayer().components.gamerules:SpawnPlayer(queen, x+1, y, z-5)
end]]

return FighterSelectScreen
