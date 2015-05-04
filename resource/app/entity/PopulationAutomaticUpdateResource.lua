local AutomaticUpdateResource = import(".AutomaticUpdateResource")
local PopulationAutomaticUpdateResource = class("PopulationAutomaticUpdateResource", AutomaticUpdateResource)


function PopulationAutomaticUpdateResource:ctor()
    PopulationAutomaticUpdateResource.super.ctor(self)
    self.resoure_low_limit = 0
end
function PopulationAutomaticUpdateResource:GetTotalLimit()
    return self:GetLowLimitResource() + self:GetValueLimit()
end
function PopulationAutomaticUpdateResource:GetNoneAllocatedByTime(current_time)
    return self:GetResourceValueByCurrentTime(current_time)
end
function PopulationAutomaticUpdateResource:SetValueLimit(limit)
    PopulationAutomaticUpdateResource.super.SetValueLimit(self, limit - self:GetLowLimitResource())
end
function PopulationAutomaticUpdateResource:GetLowLimitResource()
    return self.resoure_low_limit
end
function PopulationAutomaticUpdateResource:SetLowLimitResource(value)
    self.resoure_low_limit = value
end


return PopulationAutomaticUpdateResource







