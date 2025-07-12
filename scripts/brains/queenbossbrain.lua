require "behaviours/queenfight" --NICE TRY B)
require "behaviours/recover"
require "behaviours/defendself"
require "behaviours/react"
require "behaviours/edgegaurd"
require "behaviours/search"
require "behaviours/escapekb"
require "behaviours/getup"


local MAX_CHASE_TIME = 80

local DAMAGE_UNTIL_SHIELD = 50
local SHIELD_TIME = 3
local AVOID_PROJECTILE_ATTACKS = false

local QueenBossBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


function QueenBossBrain:OnStart()
    local root =
        PriorityNode(
        {
			WhileNode( function() return self.inst.components.launchgravity:GetIsAirborn() end, "Recover", Recover(self.inst, "Recover")),
			
			-- DefendSelf(self.inst, "Defend"),
			
			Search(self.inst, "doesthisdoanything"), --TO PREVENT THE GAME FROM CRASHING WHEN OPPONENT DISAPPEARS
			
			-- Escapekb(self.inst), --ATTEMPTS TO ESCAPE FROM COMBOS AND AVOID GETTING HIT IN THE AIR
			
			GetUp(self.inst), --JUST TO GET UP OFF OF THE GROUND
			
			-- React(self.inst, "React"), --7-26 --ADDED TO ALLOW CPU TO CANCEL THEIR APPROACH TO DEFEND THEMSELVES INSTEAD
			EdgeGaurd(self.inst, "EdgeGaurd"), --8-7 GIVES THE CPU SOMETHING TO DO WHILE OPPONENT IS OFF EDGE AS TO NOT JUMP OFF AFTER THEM
			
			-- WhileNode( function() return not self.inst:HasTag("going_in") end, "Defend", DefendSelf(self.inst, "Defend")),
			
			QueenFight(self.inst, MAX_CHASE_TIME),
			
        },0.20) --0.35--1
    
    
    self.bt = BT(self.inst, root)
end

function QueenBossBrain:OnInitializationComplete()
	--1-28-17 THIS HAS TO HAPPEN FIRST BECAUSE THE SEARCH NODE HASN'T RUN YET 
	local nemisis = self.inst.components.aifeelings:FindNearestEnemy() --2-7-17
	if nemisis then
		self.inst.components.stats.opponent = nemisis
		if nemisis.components.stats then --TO FIX A BUG IN CASE OPPONENT IS TEMP AND DOESNT HAVE STATS
			nemisis.components.stats.opponent = self.inst 
		end
	end
	
end

return QueenBossBrain



