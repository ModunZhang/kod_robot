local Resource = class("Resource")
function Resource:ctor()
    self.resource_value = 0
    self.resource_value_limit = 0
end
function Resource:GetResourceValueByCurrentTime(time)
	return self.resource_value
end
function Resource:GetValue()
    return self.resource_value
end
function Resource:SetValue(value)
    self.resource_value = value
end
function Resource:GetValueLimit()
    return self.resource_value_limit
end
function Resource:SetValueLimit(value)
    self.resource_value_limit = value
end
function Resource:IsOverLimit()
    return self.resource_value > self.resource_value_limit
end



return Resource