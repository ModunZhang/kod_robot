local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local TouchJudgment = class("TouchJudgment")
local move_judgment_distance = 20
function TouchJudgment:ctor(touch_handle)
    assert(type(touch_handle.OnTouchBegan) == "function")
    assert(type(touch_handle.OnTouchEnd) == "function")
    assert(type(touch_handle.OnTouchMove) == "function")
    assert(type(touch_handle.OnTouchClicked) == "function")
    assert(type(touch_handle.OnTouchExtend) == "function")
    self.touch_handle = touch_handle
    self.time = 0
    self.resistance_time = 1000
    self.time_has_resisted = 0
    self.resist_factor = 0.9
    self.has_reduced_factor = 1
    self.expire_time = 400
    self.time_has_expired = 0
    self.one_touch_array = {}
    self.one_touch_begin = nil

    local touch_node = display.newNode():addTo(touch_handle)
    touch_node:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(dt)
        local millisecond = dt * 1000
        self.time = self.time + millisecond
        self:UpdateExpireTime(millisecond)
        self:UpdateResistanceTime(millisecond)
    end)
    touch_node:scheduleUpdate()
end
function TouchJudgment:UpdateExpireTime(millisecond)
    if #self.one_touch_array > 0 then
        self.time_has_expired = self.time_has_expired + millisecond
        if self.time_has_expired > self.expire_time then
            self.time_has_expired = 0
            table.remove(self.one_touch_array, 1)
        end
    end
end
function TouchJudgment:UpdateResistanceTime(millisecond)
    local is_resistance_time_over = not self.speed
    if is_resistance_time_over then
        return
    end
    self.time_has_resisted = self.time_has_resisted + millisecond
    if self.time_has_resisted < self.resistance_time then
        self.has_reduced_factor = self.resist_factor * self.has_reduced_factor
        local old_speed_x = self.speed.x
        local old_speed_y = self.speed.y
        local new_speed_x = self.has_reduced_factor * old_speed_x
        local new_speed_y = self.has_reduced_factor * old_speed_y
        if self.has_reduced_factor < 0.02 then
            self.time_has_resisted = self.resistance_time
        end
        self.touch_handle:OnTouchExtend(old_speed_x, old_speed_y, new_speed_x, new_speed_y, millisecond, self.has_reduced_factor < 0.02)
    else
        self:ResetTouch()
    end
end
function TouchJudgment:OnTouchBegan(pre_x, pre_y, x, y)
    self:ResetTouch()
    table.insert(self.one_touch_array, {x = x, y = y, time = self.time})
    self.one_touch_begin = {x = x, y = y, time = self.time}
    self.touch_handle:OnTouchBegan(pre_x, pre_y, x, y)
end
function TouchJudgment:ResetTouch()
    self.one_touch_array = {}
    self.has_reduced_factor = 1
    self.time_has_resisted = 0
    self.time_has_expired = 0
    self.speed = nil
end
function TouchJudgment:OnTouchMove(pre_x, pre_y, x, y)
    -- print("collectgarbage", collectgarbage("count"))
    local find = false
    for _, v in ipairs(self.one_touch_array) do
        if v.time == self.time then
            find = true
            break
        end
    end
    if not find then
        if pre_x ~= x and pre_y ~= y then -- fix difference move event
            table.insert(self.one_touch_array, {x = x, y = y, time = self.time})
            if #self.one_touch_array > 3 then
                table.remove(self.one_touch_array, 1)
            end
        end
    end
    self.touch_handle:OnTouchMove(pre_x, pre_y, x, y)
    local touch = self.one_touch_begin
    if touch then
        local is_finger_moved = math.abs(touch.x - x) > move_judgment_distance or math.abs(touch.y - y) > move_judgment_distance
        if is_finger_moved then
            self.one_touch_begin = nil
        end
    end
end
function TouchJudgment:OnTouchEnd(pre_x, pre_y, x, y)
    self:OnTouchOver(pre_x, pre_y, x, y)
    local is_click = false
    if self.one_touch_begin then
        local begin_x, begin_y = self.one_touch_begin.x, self.one_touch_begin.y
        local dx = x - begin_x
        local dy = y - begin_y
        if math.sqrt(dx * dx + dy * dy) < move_judgment_distance then
            is_click = true
        end
    end
    self.touch_handle:OnTouchEnd(pre_x, pre_y, x, y, self.speed, is_click)
    if is_click then
        self.touch_handle:OnTouchClicked(pre_x, pre_y, x, y)
    end
end
function TouchJudgment:OnTouchCancelled(pre_x, pre_y, x, y)
    self:OnTouchOver(pre_x, pre_y, x, y)
    self.touch_handle:OnTouchCancelled(pre_x, pre_y, x, y)
end
function TouchJudgment:OnTouchOver(pre_x, pre_y, x, y)
    if #self.one_touch_array <= 2 then
        self:ResetTouch()
        return
    end
    local vt = {}
    local array = self.one_touch_array
    for i, _ in ipairs(array) do
        local dt = array[i + 1].time - array[i].time
        table.insert(vt, { x = array[i + 1].x - array[i].x, y = array[i + 1].y - array[i].y, dt = dt})
        if i == 2 then
            break
        end
    end
    self.speed = { x = (vt[1].x + vt[2].x) / 2, y = (vt[1].y + vt[2].y) / 2, dt = (vt[1].dt + vt[2].dt) / 2.0 }
    self.speed.x = self.speed.x / self.speed.dt
    self.speed.y = self.speed.y / self.speed.dt
    self.one_touch_array = {}
    self.one_touch_begin = nil
end
function TouchJudgment:ResetSpeed()
    self.speed = nil
end

return TouchJudgment























