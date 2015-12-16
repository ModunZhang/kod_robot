local Resource = import(".Resource")
local AutomaticUpdateResource = class("AutomaticUpdateResource", Resource)
local function clamp(a,b,x)
    return x < a and a or (x > b and b or x)
end
local floor = math.floor
function AutomaticUpdateResource:ctor()
    AutomaticUpdateResource.super.ctor(self)
    self.update_time = 0
    self.resource_production_per_hour = 0
end
function AutomaticUpdateResource:GetProductionPerHour()
    return self.resource_production_per_hour
end
function AutomaticUpdateResource:SetProductionPerHour(current_time, resource_production_per_hour)
    if self.resource_production_per_hour ~= resource_production_per_hour then
        self:UpdateResource(current_time, self:GetResourceValueByCurrentTime(current_time))
        self.resource_production_per_hour = resource_production_per_hour
    end
end
function AutomaticUpdateResource:AddResourceByCurrentTime(current_time, value)
    assert(value >= 0)
    self:UpdateResource(current_time, self:GetResourceValueByCurrentTime(current_time) + value)
end
function AutomaticUpdateResource:ReduceResourceByCurrentTime(current_time, value)
    assert(value >= 0)
    local left_resource = self:GetResourceValueByCurrentTime(current_time) - value
    if left_resource >= 0 then
        self:UpdateResource(current_time, left_resource)
    else
        assert(false, "扣除值错误")
    end
end
function AutomaticUpdateResource:UpdateResource(current_time, value)
    self.update_time = current_time
    self:SetValue(value)
end
function AutomaticUpdateResource:GetResourceValueByCurrentTime(time)
    local cv = self.resource_value
    local lv = self.resource_value_limit
    local rpph = self.resource_production_per_hour
    local trv = cv + (time - self.update_time) * rpph * 0.00027777777777778 --[[ 1 / 3600 = 0.00027777777777778]]
    return floor(clamp(
        0, 
        rpph >= 0 and ((cv >= lv and trv >= lv) and cv or lv) or math.huge, 
        trv
        ))
end

return AutomaticUpdateResource






