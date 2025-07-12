require "behaviours/chaseandfight"
-- require "behaviours/dumbfight"
require "behaviours/recoverdumb"
require "behaviours/defendself"
require "behaviours/react"
require "behaviours/edgegaurd"
require "behaviours/search"
require "behaviours/escapekb"
require "behaviours/getup"


local MAX_CHASE_TIME = 80


local DumbSpiderBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
	
	self.reactiontime = 0.40
end)



function DumbSpiderBrain:OnStart()
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
			--MAKE A SEPERATE ONE FOR LEDGEGAURDING
			
			-- WhileNode( function() return not self.inst:HasTag("going_in") end, "Defend", DefendSelf(self.inst, "Defend")),
			
			-- DumbFight(self.inst, MAX_CHASE_TIME),
			ChaseAndFight(self.inst, MAX_CHASE_TIME), --LETS GIVE IT A WHIRL

            -- DoAction(self.inst, function() return EatFoodAction(self.inst) end ),
			--ALRIGHT, WHO WAS DOWN HERE TRYING TO EAT FOOD
        },self.reactiontime) --0.20   -0.35--1
    
    
    self.bt = BT(self.inst, root)
    
         
end


function DumbSpiderBrain:ForceRefresh()

	self.bt.root.period = 0
	self.bt:Update()
	self.bt.root.period = 0.40
	
end


function DumbSpiderBrain:OnInitializationComplete()

	--8-11
	self.inst:DoPeriodicTask(0*FRAMES, function()   --0.35
		self.inst:RemoveTag("wantstoblock") --IT DOESN'T DEFEND ITSELF, SO ONCE IT GETS HIT, IT WILL TRY AND BLOCK FOREVER
	end)
	
	
	
	local nemisis = self.inst.components.aifeelings:FindNearestEnemy() --2-7-17
	if nemisis then
		self.inst.components.stats.opponent = nemisis
		-- nemisis.components.stats.opponent = self.inst
		if nemisis.components.stats then --TO FIX A BUG IN CASE OPPONENT IS TEMP AND DOESNT HAVE STATS
			nemisis.components.stats.opponent = self.inst 
		end
	end
	
	--1-3-17
	self.inst.components.aifeelings:GetAttackNode():InitAction() --HAH!! IT WORKS

end

-- return SpiderBrain
return DumbSpiderBrain



