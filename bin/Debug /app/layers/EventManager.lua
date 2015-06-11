local EventManager = class("EventManager")
---
local DEBUG_TOUCH = false
if DEBUG_TOUCH then
    function EventManager:RemoveTouch(touch_id)
        if self.cursors[touch_id] then
            do
                self.cursors[touch_id]:removeSelf() -- 调试触摸时打开
            end
            self.cursors[touch_id] = nil
        end
    end
    function EventManager:RemoveAllTouches()
        do
            table.foreach(self.cursors, function(_, cursor) cursor:removeSelf() end) -- 调试触摸时打开
        end
        self.cursors = {}
    end
    function EventManager:add_touches(points)
        local add_count = 0
        table.foreach(points, function(id, point)
            do
                local cursor = display.newSprite("Cursor.png"):pos(point.x, point.y):scale(1.2):addTo(self.running_scene, 100000)
                self:PushTouch(id, cursor) -- 调试触摸时打开
            end
            add_count = add_count + 1
        end)
        return add_count
    end
    function EventManager:two_touch_began(points)
        table.foreach(points, function(id, point)
            if self.one_touch_id == id then
                self.one_touch_handle:OnOneTouch(0, 0, point.x, point.y, "cancelled")
                self.one_touch_id = nil
                return true
            end
        end)

        local points = {}
        for id, cursor in pairs(self:AllTouches()) do
            do
                local x, y = cursor:getPosition()
                table.insert(points, {id = id, x = x, y = y}) -- 调试触摸时打开
            end
        end
        if #points >= 2 then
            self.scale_id_1 = points[1].id
            self.scale_id_2 = points[2].id
            local x1, y1 = points[1].x, points[1].y
            local x2, y2 = points[2].x, points[2].y
            self.two_touch_handle:OnTwoTouch(x1, y1, x2, y2, "began")
        end
    end
    function EventManager:touch_moving(event_points)
        local points = {}
        local count = 0
        table.foreach(event_points, function(id, point)
            local cursor = self.cursors[id]
            if cursor then
                do
                    local rect = cc.rect(display.left, display.bottom, display.width, display.height)
                    if cc.rectContainsPoint(rect, cc.p(point.x, point.y)) then
                        cursor:setPosition(point.x, point.y)
                        cursor:setVisible(true)
                    else
                        cursor:setVisible(false)
                    end -- 调试触摸时打开
                end
            end
            if self.scale_id_1 == id or
                self.scale_id_2 == id then
                table.insert(points, {id = id, x = point.x, y = point.y })
            end
            count = count + 1
        end)

        local is_only_one_finger_moving = #points == 1
        if is_only_one_finger_moving then
            local point = self:try_to_find_another_point_by_moving_touch(points[1])
            if point then
                table.insert(points, point)
            end
        end

        local is_two_finger_moving = #points == 2
        if is_two_finger_moving then
            local x1, y1 = points[1].x, points[1].y
            local x2, y2 = points[2].x, points[2].y
            self.two_touch_handle:OnTwoTouch(x1, y1, x2, y2, "moved")
        end
        local is_only_one_finger_on_screen = count == 1 and #points == 0
        if is_only_one_finger_on_screen then
            self:one_touch_moving(event_points)
        end
    end
    function EventManager:try_to_find_another_point_by_moving_touch(has_get_point)
        -- 试图获取另一个点
        local id = has_get_point.id == self.scale_id_1 and self.scale_id_2 or self.scale_id_1
        local cursor = self:GetTouchById(id)
        if cursor then
            do
                local x, y = cursor:getPosition()
                return { id = id, x = x, y = y } -- 调试触摸时打开
            end
        end
        return nil
    end

else
    function EventManager:RemoveTouch(touch_id)
        if self.cursors[touch_id] then
            self.cursors[touch_id] = nil
        end
    end
    function EventManager:RemoveAllTouches()
        self.cursors = {}
    end
    function EventManager:add_touches(points)
        local add_count = 0
        table.foreach(points, function(id, point)
            self:PushTouch(id, {x = point.x, y = point.y}) --
            add_count = add_count + 1
        end)
        return add_count
    end
    function EventManager:two_touch_began(points)
        table.foreach(points, function(id, point)
            if self.one_touch_id == id then
                self.one_touch_handle:OnOneTouch(0, 0, point.x, point.y, "cancelled")
                self.one_touch_id = nil
                return true
            end
        end)

        local points = {}
        for id, cursor in pairs(self:AllTouches()) do
            table.insert(points, {id = id, x = cursor.x, y = cursor.y})
        end
        if #points >= 2 then
            self.scale_id_1 = points[1].id
            self.scale_id_2 = points[2].id
            local x1, y1 = points[1].x, points[1].y
            local x2, y2 = points[2].x, points[2].y
            self.two_touch_handle:OnTwoTouch(x1, y1, x2, y2, "began")
        end
    end
    function EventManager:touch_moving(event_points)
        local points = {}
        local count = 0
        table.foreach(event_points, function(id, point)
            local cursor = self.cursors[id]
            if cursor then
                cursor.x, cursor.y = point.x, point.y
            end
            if self.scale_id_1 == id or
                self.scale_id_2 == id then
                table.insert(points, {id = id, x = point.x, y = point.y })
            end
            count = count + 1
        end)

        local is_only_one_finger_moving = #points == 1
        if is_only_one_finger_moving then
            local point = self:try_to_find_another_point_by_moving_touch(points[1])
            if point then
                table.insert(points, point)
            end
        end

        local is_two_finger_moving = #points == 2
        if is_two_finger_moving then
            local x1, y1 = points[1].x, points[1].y
            local x2, y2 = points[2].x, points[2].y
            self.two_touch_handle:OnTwoTouch(x1, y1, x2, y2, "moved")
        end

        local is_only_one_finger_on_screen = #points == 0 and count == 1
        if is_only_one_finger_on_screen then
            self:one_touch_moving(event_points)
        end
    end
    function EventManager:try_to_find_another_point_by_moving_touch(has_get_point)
        -- 试图获取另一个点
        local id = has_get_point.id == self.scale_id_1 and self.scale_id_2 or self.scale_id_1
        local cursor = self:GetTouchById(id)
        if cursor then
            return { id = id, x = cursor.x, y = cursor.y }
        end
        return nil
    end
end
-------------------------------------------------------------------

--
function EventManager:ctor(event_handle)
    self.running_scene = event_handle
    self.one_touch_id = nil
    self.scale_id_1 = nil
    self.scale_id_2 = nil
    self.cursors = {}
    self.one_touch_handle = event_handle
    self.two_touch_handle = event_handle
end
function EventManager:PushTouch(touch_id, touch)
    self.cursors[touch_id] = touch
end
function EventManager:GetTouchById(touch_id)
    return self.cursors[touch_id]
end
function EventManager:AllTouches()
    return self.cursors
end
function EventManager:TouchCounts()
    local count = 0
    table.foreach(self.cursors, function(...) count = count + 1 end)
    return count
end
function EventManager:OnEvent(event)
    local is_new_coming_touches = event.name == "began" or event.name == "added"
    local is_moving = event.name == "moved"
    local is_touch_removed = event.name == "removed" or event.name == "cancelled"
    local is_all_removed = true
    local count = self:TouchCounts()
    if is_new_coming_touches then
        count = count + self:add_touches(event.points)
        local is_first_touch_coming = event.name == "began" and count == 1
        local is_two_touch_coming = count == 2
        if is_first_touch_coming then
            self:one_touch_began(event.points)
        elseif is_two_touch_coming then
            self:two_touch_began(event.points)
        end
    elseif is_moving then
        self:touch_moving(event.points)
    elseif is_touch_removed then
        table.foreach(event.points, function(id, point)
            self:RemoveTouch(id)
            if self.one_touch_id == id then
                self.one_touch_handle:OnOneTouch(point.prevX, point.prevY, point.x, point.y, "ended")
                self.one_touch_id = nil
            end
            self:check_two_touches_which_has_removed(id)
        end)
        self:check_two_touches_has_cancelled()
    elseif is_all_removed then
        self:RemoveAllTouches()
    end

    local is_touch_over = event.name == "ended" or event.name == "cancelled"
    local is_last_finger_removed = self.one_touch_id ~= nil
    if is_touch_over then
        if is_last_finger_removed then
            self:one_touch_over(event.points, event.name)
        end
        table.foreach(event.points, function(id, _) self:check_two_touches_which_has_removed(id) end)
        self:check_two_touches_has_cancelled()
    end
end
function EventManager:one_touch_began(points)
    table.foreach(points, function(id, point)
        self.one_touch_id = id
        self.one_touch_handle:OnOneTouch(0, 0, point.x, point.y, "began")
        return true
    end)
end
function EventManager:one_touch_moving(points)
    table.foreach(points, function(id, point)
        self.one_touch_id = id
        self.one_touch_handle:OnOneTouch(point.prevX, point.prevY, point.x, point.y, "moved")
        return true
    end)
end
function EventManager:one_touch_over(points, event_name)
    table.foreach(points, function(id, point)
        if self.one_touch_id == id then
            self.one_touch_handle:OnOneTouch(0, 0, point.x, point.y, event_name)
            return true
        end
    end)
end
function EventManager:check_two_touches_which_has_removed(id)
    if self.scale_id_1 == id then
        self.scale_id_1 = nil
    end
    if self.scale_id_2 == id then
        self.scale_id_2 = nil
    end
end
function EventManager:check_two_touches_has_cancelled()
    local is_scale_cancelled = not self.scale_id_1 or not self.scale_id_2
    if is_scale_cancelled then
        self.scale_id_1 = nil
        self.scale_id_2 = nil
        self.two_touch_handle:OnTwoTouch(0, 0, 0, 0, "ended")
    end
end



return EventManager




















