local FXutil = Class(function(self, inst)
    self.inst = inst

	--------------------------------
	self.owner = nil --WHEREVER THE FX'S POSITION WILL BE ANCHORED FROM
	self.stick = 0
	self.currentstate = nil
	
	self.x = 0 --PROBABLY DON'T NEED THESE
	self.y = 0
	self.z = 0
	
	self.xoffset = 0
	self.yoffset = 0
	self.zoffset = 0
	
end)


function FXutil:UpdatePosition() --THIS WILL BE CALLED BY THE WALL UPDATER, SO IT MUST BE ABLE TO RUN WITH NO INPUT VARIABLES
	if self.owner and self.owner:IsValid() and self.inst:IsValid() then
		local getdir = self.owner.components.launchgravity:GetRotationFunction()
		local x, y, z = self.owner.Transform:GetWorldPosition()
		
		self.inst.Transform:SetPosition( x+(self.xoffset*self.owner.components.launchgravity:GetRotationValue()), y+self.yoffset, z+self.zoffset )
		
		--DETERMINE IF A NEW STATE HAS BEEN ENTERED
		if self.owner.sg.currentstate.name ~= self.currentstate then
			self.inst:Remove() 
		end
	end
end


return FXutil
