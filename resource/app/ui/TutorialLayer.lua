local cocos_promise = import("..utils.cocos_promise")
local promise = import("..utils.promise")
local Arrow = import(".Arrow")
local TutorialLayer = class('TutorialLayer', function()
    return display.newNode()
end)

function TutorialLayer:ctor(obj)
    self.left = display.newColorLayer(cc.c4b(255, 0, 0, 100)):addTo(self, 0)
    self.right = display.newColorLayer(cc.c4b(255, 0, 0, 100)):addTo(self, 0)
    self.top = display.newColorLayer(cc.c4b(255, 0, 0, 100)):addTo(self, 0)
    self.bottom = display.newColorLayer(cc.c4b(255, 0, 0, 100)):addTo(self, 0)
    -- self.left = display.newLayer():addTo(self, 0)
    -- self.right = display.newLayer():addTo(self, 0)
    -- self.top = display.newLayer():addTo(self, 0)
    -- self.bottom = display.newLayer():addTo(self, 0)
    local left, right, top, bottom = self.left, self.right, self.top, self.bottom
    for _, v in pairs{ left, right, top, bottom } do
        v:setContentSize(cc.size(display.width, display.height))
    end
    -- self.arrow = Arrow.new():addTo(self):hide()
    self:Reset()
    self:SetTouchObject(obj)
    self:setLocalZOrder(3000)
end
function TutorialLayer:Enable()
    self.count = self.count + 1
    if self.count > 0 then
        for _, v in pairs{ self.left, self.right, self.top, self.bottom } do
            v:setTouchEnabled(true)
        end
    end
    return self
end
function TutorialLayer:Disable()
    self.count = self.count - 1
    if self.count <= 0 then
        for _, v in pairs{ self.left, self.right, self.top, self.bottom } do
            v:setTouchEnabled(false)
        end
    end
    return self
end
function TutorialLayer:Reset()
    self.count = 0
    for _, v in pairs{ self.left, self.right, self.top, self.bottom } do
        v:setTouchEnabled(false)
    end
    self.object = nil
    self.world_rect = nil
    return self
end
function TutorialLayer:SetTouchObject(obj)
    self.object = obj
    if obj then
        self:UpdateClickedRegion(self:GetClickedRect())
    end
    return self
end
function TutorialLayer:SetTouchRect(world_rect)
    self.world_rect = world_rect
    return self
end
function TutorialLayer:UpdateClickedRegion(rect)
    self.left:pos(rect.x - display.width, 0)
    self.right:pos(rect.x + rect.width, 0)
    self.top:pos(0, rect.y + rect.height)
    self.bottom:pos(0, rect.y - display.height)
end
function TutorialLayer:GetClickedRect()
    if self.world_rect then
        return self.world_rect
    elseif self.object then
        return self.object:getCascadeBoundingBox()
    else
        return cc.rect(0, 0, display.width, display.height)
    end
end
-- function TutorialLayer:DeferShow(control, angle, offset_x, offset_y)
--     local rect = control:getCascadeBoundingBox()
--     local x = rect.x + rect.width * 0.5
--     local y = rect.y + rect.height * 0.5
--     self.arrow:OnPositionChanged(x, y)
--     self.arrow:Set(angle, offset_x, offset_y):show()
--     self:Enable():SetTouchObject(control)
--     return cocos_promise.defer(function() return control end)
-- end
-- function TutorialLayer:DefferHide()
--     self.arrow:hide()
--     return cocos_promise.defer()
-- end

return TutorialLayer



