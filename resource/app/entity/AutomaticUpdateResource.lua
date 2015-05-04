local Resource = import(".Resource")
local AutomaticUpdateResource = class("AutomaticUpdateResource", Resource)
local function clamp(a,b,x)
    return x < a and a or (x > b and b or x)
end
local floor = math.floor
function AutomaticUpdateResource:ctor()
    AutomaticUpdateResource.super.ctor(self)
    self.last_update_time = 0
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
    self.last_update_time = current_time
    self:SetValue(value)
end
function AutomaticUpdateResource:GetResourceValueByCurrentTime(current_time)
    local current_value = self:GetValue()
    local limit_value = self:GetValueLimit()
    local total_resource_value = self:GetResourceValueByCurrentTimeWithoutLimit(current_time)
    local resource_production_per_hour = self.resource_production_per_hour
    local is_over_limit = current_value >= limit_value and total_resource_value >= limit_value
    local is_product_positive = resource_production_per_hour >= 0
    local max_value = is_product_positive and (is_over_limit and current_value or limit_value) or math.huge
    return clamp(0, max_value, total_resource_value)
end
function AutomaticUpdateResource:GetResourceValueByCurrentTimeWithoutLimit(current_time)
    local elapse_time = current_time - self.last_update_time
    local has_been_producted_from_last_update_time = elapse_time * self.resource_production_per_hour / 3600
    local total_resource_value = self:GetValue() + has_been_producted_from_last_update_time
    return floor(total_resource_value)
end

return AutomaticUpdateResource






