local window = import("..utils.window")
local TouchJudgment = import("..layers.TouchJudgment")
local WidgetDragons = class("WidgetDragons",function()
    return display.newNode()
end)
local filter = filter

local math = math
local pos = {624 * 0.5, 250, 0.0}
local radius = 300.0
local back_height = 300
local getinfo = function(angle)
    local r = math.rad(angle)
    local tmp_z = math.cos(r) * radius
    local bs = tmp_z < 0 and (1 - math.abs(tmp_z) / radius * 0.5) or 1
    local x = math.sin(r) * -radius * bs + pos[1]
    local fs = tmp_z > 0 and 1.2 or 1
    local z = tmp_z * fs + pos[3] + radius
    local y = pos[2] + (1 - (z / (2 * radius))) * back_height
    local ratio = z / (2 * radius)
    local f = 0.2
    local s = f + ratio * (1-f)
    local f = 1.0 - ratio
    local b = (1.0 - ratio) * 4
    return x, y, z, s, math.min(b * 2.0, 10)
end
local sign = function(n)
    return n >= 0 and 1 or -1
end
local edge = function(t, n)
    return n >= t and 1 or 0
end
function WidgetDragons:ctor(callbacks)
    self.scrollable = true
    self:setNodeEventEnabled(true)
    callbacks = checktable(callbacks)
    self.OnLeaveIndexEvent = callbacks.OnLeaveIndexEvent
    self.OnEnterIndexEvent = callbacks.OnEnterIndexEvent
    self.OnTouchClickEvent = callbacks.OnTouchClickEvent
    self.touch_judgment = TouchJudgment.new(self)
    local back_node = display.newScale9Sprite("dragon_animate_bg_624x606.png"):size(624,606):addTo(self)
        :align(display.CENTER)
    back_node:setTouchEnabled(true)
    back_node:setTouchSwallowEnabled(true)
    back_node:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    back_node:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        local touch_type = event.name
        local pre_x, pre_y, x, y = event.prevX, event.prevY, event.x, event.y
        if touch_type == "began" then
            self.touch_judgment:OnTouchBegan(pre_x, pre_y, x, y)
        elseif touch_type == "moved" then
            self.touch_judgment:OnTouchMove(pre_x, pre_y, x, y)
        elseif touch_type == "ended" then
            self.touch_judgment:OnTouchEnd(pre_x, pre_y, x, y)
        end
        return true
    end)

    self.angle = 0
    self.target_angle = nil
    self.items = {}
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(dt)
        self:UpdatePosition(dt)
    end)
    self:scheduleUpdate()

    self.dragon1 = display.newSprite("eyrie_584x547.png", nil, nil, {class=cc.FilteredSpriteWithOne}):addTo(back_node)
    self.dragon2 = display.newSprite("eyrie_584x547.png", nil, nil, {class=cc.FilteredSpriteWithOne}):addTo(back_node)
    self.dragon3 = display.newSprite("eyrie_584x547.png", nil, nil, {class=cc.FilteredSpriteWithOne}):addTo(back_node)
    table.insert(self.items, self.dragon1)
    table.insert(self.items, self.dragon2)
    table.insert(self.items, self.dragon3)
end

function WidgetDragons:onEnter()
    -- self:OnEnterIndex(math.abs(0))
end

function WidgetDragons:SetScrollable(scrollable)
    self.scrollable = scrollable
end

function WidgetDragons:IsScrollable()
    return self.scrollable
end

function WidgetDragons:onExit()
    self.touch_judgment:destructor()
end
local auto_speed = 200
function WidgetDragons:UpdatePosition(dt)
    if self.target_angle then
        local left_angle = self.target_angle - self.angle
        local march_angle = dt * auto_speed * sign(left_angle)
        local a = self.angle + march_angle
        if sign(self.target_angle - a) == sign(left_angle) then
            self.angle = a
        elseif (self.target_angle % 120) ~= 0 then
            self:AutoRotation()
        else
            self.angle = self.target_angle
            self.target_angle = nil
            self:OnEnterIndex(self:IndexByAngle(self.angle))
        end
    end
    for i, dragon in ipairs(self.items) do
        local x, y, z, s, b = getinfo(self.angle - 120 * (i - 1))
        dragon:pos(x, y):scale(s):setLocalZOrder(z)
    end
end
function WidgetDragons:IndexByAngle(angle)
    local mang = math.mod(angle, 360)
    local cur = sign(mang) > 0 and math.floor(mang / 120) or 3 + math.floor(mang / 120)
    return math.abs(cur)
end
function WidgetDragons:RoundAngle()
	return self.angle >= 0 and math.floor(self.angle / 360) * 360 or math.ceil(self.angle / 360) * 360
end
function WidgetDragons:Next()
	self.target_angle = self.angle + 120
end
function WidgetDragons:Before()
    self.target_angle = self.angle - 120
end
function WidgetDragons:OnLeaveIndex(index)
    if self.OnLeaveIndexEvent then
        self.OnLeaveIndexEvent(index)
    end
end
function WidgetDragons:OnEnterIndex(index)
    self.cur_index = index
    if self.OnEnterIndexEvent then
        self.OnEnterIndexEvent(index)
    end
end
function WidgetDragons:OnTouchBegan(pre_x, pre_y, x, y)
    if not self:IsScrollable() then return end
    self:StopAuto()
end
function WidgetDragons:OnTouchEnd(pre_x, pre_y, x, y)
    if not self:IsScrollable() then return end
    local speed = self.touch_judgment.speed
    if speed then
        self:SlipABit(speed)
    else
        self:AutoRotation()
    end
end
function WidgetDragons:OnTouchCancelled(pre_x, pre_y, x, y)

end
function WidgetDragons:OnTouchMove(pre_x, pre_y, x, y)
    if not self:IsScrollable() then return end
    self:Move(x - pre_x)
    if self.cur_index then
        self:OnLeaveIndex(self.cur_index)
        self.cur_index = nil
    end
end
function WidgetDragons:OnTouchClicked(pre_x, pre_y, x, y)
    -- self:AutoRotation()
    if self.OnTouchClickEvent then
        local index = self:CheckIndexOfClicked(x,y)
        if index > 0 then self.OnTouchClickEvent(index - 1) end
    end
end

function WidgetDragons:CheckIndexOfClicked(x,y)
    for index,v in ipairs(self:GetItems()) do
        if v:getCascadeBoundingBox():containsPoint(cc.p(x, y)) then
            return index
        end
    end
    return -1
end

function WidgetDragons:OnTouchExtend(old_speed_x, old_speed_y, new_speed_x, new_speed_y, millisecond)

end
function WidgetDragons:Move(len)
    self.angle = self.angle - len * 0.1
end
function WidgetDragons:SlipABit(speed)
    local radps = - speed.x / speed.dt
    local modify_radps = math.min(math.abs(radps), 0.5) * sign(radps)
    local ratio = math.abs(modify_radps) / 0.5
    local target = self.angle + edge(0, sign(radps)) * 120 - self.angle % 120
    self.target_angle = target
end
function WidgetDragons:StopAuto()
    self.target_angle = nil
end
function WidgetDragons:AutoRotation()
    local cur_angle = math.mod(self.angle, 360)
    if math.abs(math.mod(cur_angle, 120)) == 0 then
        return
    end
    local is_cur = math.abs(math.mod(cur_angle, 120)) <= 60
    local sign = cur_angle >= 0 and 1 or -1
    if sign > 0 then
        local round = math.floor(self.angle / 360)
        local target_angle = is_cur and math.floor(cur_angle / 120) * 120 or math.floor(cur_angle / 120 + 1) * 120
        self.target_angle = target_angle + round * 360
    else
        local round = math.floor(self.angle / 360 + 1)
        local target_angle = is_cur and math.floor(cur_angle / 120 + 1) * 120 or math.floor(cur_angle / 120) * 120
        self.target_angle = target_angle + round * 360
    end
end

--
function WidgetDragons:GetItems()
    return self.items
end

function WidgetDragons:GetItemByIndex(index)
    assert(index >=0 and index < 3)
    return self.items[index+1]
end



return WidgetDragons

