local promise = import("..utils.promise")
local MapLayer = class("MapLayer", function(...)
    return display.newLayer():align(display.BOTTOM_LEFT):setNodeEventEnabled(true)
end)

local SPEED = 10
local min = math.min
local max = math.max
local abs = math.abs
----
function MapLayer:ctor(scene, min_scale, max_scale)
    self.scene = scene
    self.min_scale = min_scale
    self.max_scale = max_scale
    self.target_position = nil
    self.target_scale = nil
    local node = display.newNode():addTo(self)
    node:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(dt)
        local target_position = self.target_position
        if target_position then
            local x, y, speed = unpack(target_position)
            local scene_mid_point = self:getParent():convertToNodeSpace(cc.p(display.cx, display.cy))
            local new_scene_mid_point = self:ConverToParentPosition(x, y)
            local dx, dy = scene_mid_point.x - new_scene_mid_point.x, scene_mid_point.y - new_scene_mid_point.y
            local normal = cc.pNormalize({x = dx, y = dy})
            local current_x, current_y = self:getPosition()
            local new_x, new_y = current_x + normal.x * speed, current_y + normal.y * speed
            local tx, ty = current_x + dx, current_y + dy
            if (tx - current_x) * (tx - new_x) <= 0 and (ty - current_y) * (ty - new_y) <= 0 then
                new_x, new_y = tx, ty
                self:FinishMoveTo()
            else
                target_position[3] = speed * 0.98 > 8 and speed * 0.98 or 8
            end
            local is_collide = self:setPosition(cc.p(new_x, new_y))
            if is_collide then
                self:FinishMoveTo()
            end
        end
        local target_scale = self.target_scale
        if target_scale then
            local start_scale, end_scale = unpack(target_scale)
            local dt = end_scale - start_scale
            local old_scale = self:getScale()
            local newscale = old_scale + 0.01 * (dt > 0 and 1 or -1)
            if (end_scale - newscale) * dt <= 0 then
                self:ZoomTo(end_scale)
                target_scale = nil
            else
                self:ZoomTo(newscale)
            end
        end
    end)
    node:scheduleUpdate()
end
function MapLayer:onEnter()

end
function MapLayer:onExit()

end
function MapLayer:ConverToParentPosition(x, y)
    local world_point = self:convertToWorldSpace(cc.p(x, y))
    return self:getParent():convertToNodeSpace(world_point)
end
function MapLayer:MoveToPosition(map_x, map_y, speed_)
    if map_x and map_y then
        self.target_position = {map_x, map_y, speed_ or SPEED}
    else
        self.target_position = nil
    end
end
function MapLayer:FinishMoveTo()
    self.target_position = nil
    if self.move_callback then
        self.move_callback()
        self.move_callback = nil
    end
end
function MapLayer:StopMoveAnimation()
    self.target_position = nil
    self.move_callback = nil
end
function MapLayer:GetLogicMap()
    return nil
end
function MapLayer:PromiseOfMove(map_x, map_y, speed_)
    local scene_mid_point = self:getParent():convertToNodeSpace(cc.p(display.cx, display.cy))
    local len = cc.pGetLength(scene_mid_point, cc.p(map_x, map_y))
    self:MoveToPosition(map_x, map_y, speed_ or len)
    local p = promise.new()
    self.move_callback = function()p:resolve()end
    return p
end
function MapLayer:StopScaleAnimation()
    self.target_scale = nil
end
function MapLayer:ZoomToByAnimation(scale)
    self.target_scale = { self:getScale(), scale }
end
------zoom
function MapLayer:ZoomBegin()
    self.scale_current = self:getScale()
    return self
end
function MapLayer:ZoomTo(scale, x1, y1, x2, y2)
    self:ZoomBegin()
    self:ZoomBy(scale / self:getScale(), (x1 and x2) and (x1 + x2) * 0.5 or display.cx, (y1 and y2) and (y1 + y2) * 0.5 or display.cy)
    self:ZoomEnd()
    return self
end
function MapLayer:ZoomBy(scale, x, y)
    local scale_point = self:convertToNodeSpace(cc.p(x, y))
    self:setScale(min(max(self.scale_current * scale, self.min_scale), self.max_scale))
    local scene_mid_point = self:getParent():convertToWorldSpace(cc.p(x, y))
    local new_scene_mid_point = self:ConverToParentPosition(scale_point.x, scale_point.y)
    local cur_x, cur_y = self:getPosition()
    local new_position = cc.p(cur_x + scene_mid_point.x - new_scene_mid_point.x, cur_y + scene_mid_point.y - new_scene_mid_point.y)
    self:setPosition(new_position)
    self.scene:OnSceneScale()
    return self
end
function MapLayer:ZoomEnd()
    self.scale_current = self:getScale()
    return self
end
function MapLayer:GetScaleRange()
    return self.min_scale, self.max_scale
end
-------
local ELASTIC = 30
local abs = math.abs
function MapLayer:MakeElastic()
    local mx, my = self:GetCollideLength()
    if abs(mx) > 0 or abs(my) > 0 then
        local mid = self:convertToNodeSpace(cc.p(display.cx, display.cy))
        self:PromiseOfMove(mid.x - mx, mid.y - my, 10)
        return true
    end
end
function MapLayer:GetCollideLength(length)
    length = length or ELASTIC
    local width,height = self:getContentWidthAndHeight()

    local left_bottom = self:convertToNodeSpace(cc.p(display.left, display.bottom))
    local right_top = self:convertToNodeSpace(cc.p(display.right, display.top))

    local left, bottom, right, top = left_bottom.x, left_bottom.y, right_top.x, right_top.y

    local left_offset = left - length
    local right_offset = width - right - length

    local move_x = left_offset >= 0 and 0 or left_offset
    move_x = move_x + (right_offset >= 0 and 0 or - right_offset)

    local bottom_offset = bottom - length
    local top_offset = height - top - length

    local move_y = bottom_offset >= 0 and 0 or bottom_offset
    move_y = move_y + (top_offset >= 0 and 0 or - top_offset)

    return move_x, move_y, length
end

-------
function MapLayer:GotoMapPositionInMiddle(x, y)
    local scene_mid_point = self:getParent():convertToNodeSpace(cc.p(display.cx, display.cy))
    local new_scene_mid_point = self:ConverToParentPosition(x, y)
    local dx, dy = scene_mid_point.x - new_scene_mid_point.x, scene_mid_point.y - new_scene_mid_point.y
    local current_x, current_y = self:getPosition()
    self:setPosition(cc.p(current_x + dx, current_y + dy))
end
local floor = math.floor
local getmetatable = getmetatable
function MapLayer:setPosition(position)
    local x, y = position.x, position.y
    local super = getmetatable(self)
    super.setPosition(self, position)
    local left_bottom_pos, is_collide1 = self:GetLeftBottomPositionWithConstrain(x, y)
    local right_top_pos, is_collide2 = self:GetRightTopPositionWithConstrain(x, y)
    local rx = x >= 0 and min(left_bottom_pos.x, right_top_pos.x) or max(left_bottom_pos.x, right_top_pos.x)
    local ry = y >= 0 and min(left_bottom_pos.y, right_top_pos.y) or max(left_bottom_pos.y, right_top_pos.y)
    super.setPosition(self, cc.p(rx, ry))
    self.scene:OnSceneMove()
    return is_collide1 or is_collide2
end
function MapLayer:GetLeftBottomPositionWithConstrain(x, y)
    local parent_node = self:getParent()
    local world_position = parent_node:convertToWorldSpace(cc.p(x, y))
    local is_collide_left = world_position.x >= display.left
    local is_collide_bottom = world_position.y >= display.bottom
    world_position.x = is_collide_left and display.left or world_position.x
    world_position.y = is_collide_bottom and display.bottom or world_position.y
    local left_bottom_pos = parent_node:convertToNodeSpace(world_position)
    return left_bottom_pos, is_collide_left or is_collide_bottom
end
function MapLayer:GetRightTopPositionWithConstrain(x, y)
    -- 右上角是否超出
    local parent_node = self:getParent()
    local world_top_right_point = self:convertToWorldSpace(cc.p(self:getContentWidthAndHeight()))
    local scene_top_right_position = parent_node:convertToNodeSpace(world_top_right_point)
    local display_top_right_position = parent_node:convertToNodeSpace(cc.p(display.right, display.top))
    local dx = display_top_right_position.x - scene_top_right_position.x
    local dy = display_top_right_position.y - scene_top_right_position.y
    local is_collide_right = scene_top_right_position.x <= display_top_right_position.x
    local is_collide_top = scene_top_right_position.y <= display_top_right_position.y
    local right_top_pos = {
        x = is_collide_right and x + dx or x,
        y = is_collide_top and y + dy or y
    }
    return right_top_pos, is_collide_right or is_collide_top
end
function MapLayer:getContentWidthAndHeight()
    if not self.content_width or not self.content_height then
        local content_size = self:getContentSize()
        self.content_width, self.content_height = content_size.width, content_size.height
    end
    return self.content_width, self.content_height
end
function MapLayer:getContentSize()
    assert(false, "你应该在子类实现这个函数 getContentSize")
end
return MapLayer
























