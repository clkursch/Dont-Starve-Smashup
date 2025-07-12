local BottleCapUtil = Class(function(self,inst)
	self.inst = inst
	self.partner = nil 
	 
	self.inst.Physics:SetCollisionCallback(function(inst, object)
		self:OnCollision(inst, object)
	end)
	
	self:OnUpdate()
	self.inst:StartUpdatingComponent(self)
end)

--IS THIS EVEN SOMETHING YOU MAKE A COMPONENT FOR? OR AM I SUPPOSED TO JUST TRY AND FIT THIS ONTO THE OBJECT ITSELF?


function BottleCapUtil:OnCollision(inst, object)

	if not (self.partner and self.partner:IsValid()) or not object then
		return end
	
	--THE SECOND WE MAKE COLLISION WITH OUR PARTNER, WE'RE GOOD
	if object == self.partner then
		self.partner.components.hurtboxutil.bottlecap = nil
		self.inst:Remove() --OUR WORK HERE IS DONE. CAO~
	end
	
end



function BottleCapUtil:OnUpdate(dt)
	if not (self.partner and self.partner:IsValid()) then
		return end
		
	--MAKE SURE WE'RE ALWAYS ATTACHED TO OUR PARTNER SO THE COLLISION CAN HAPPEN
	local partner = self.partner
	local x, y, z = partner.Transform:GetWorldPosition()
	
	self.inst.Transform:SetPosition( x, y, z )
end


return BottleCapUtil