local Event = class("Event")


function Event:Init()
    self:Reset()
end
function Event:Reset()
    self.finished_time = 0
end
function Event:Percent(current_time)
    local start_time = self:StartTime()
    local elapse_time = current_time - start_time
    local total_time = self.finished_time - start_time
    return elapse_time * 100.0 / total_time
end
function Event:ElapseTime(current_time)
    return current_time - self:StartTime()
end
function Event:LeftTime(current_time)
    return self.finished_time - current_time
end
function Event:StartTime()
    return 0
end
function Event:FinishTime()
    return self.finished_time
end
function Event:UpdateFinishTime(current_time)
    self.finished_time = current_time
end
function Event:IsEmpty()
    return self.finished_time == 0
end
function Event:IsRunning()
    return self.finished_time ~= 0
end



return Event

