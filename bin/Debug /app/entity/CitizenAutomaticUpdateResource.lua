local AutomaticUpdateResource = import(".AutomaticUpdateResource")
local CitizenAutomaticUpdateResource = class("CitizenAutomaticUpdateResource", AutomaticUpdateResource)


function CitizenAutomaticUpdateResource:ctor()
    CitizenAutomaticUpdateResource.super.ctor(self)
    self.resoure_low_limit = 0
end
function CitizenAutomaticUpdateResource:GetTotalLimit()
    return self:GetLowLimitResource() + self:GetValueLimit()
end
function CitizenAutomaticUpdateResource:GetNoneAllocatedByTime(current_time)
    return self:GetResourceValueByCurrentTime(current_time)
end
function CitizenAutomaticUpdateResource:SetValueLimit(limit)
    CitizenAutomaticUpdateResource.super.SetValueLimit(self, limit - self:GetLowLimitResource())
end
function CitizenAutomaticUpdateResource:GetLowLimitResource()
    return self.resoure_low_limit
end
function CitizenAutomaticUpdateResource:SetLowLimitResource(value)
    self.resoure_low_limit = value
end


return CitizenAutomaticUpdateResource







