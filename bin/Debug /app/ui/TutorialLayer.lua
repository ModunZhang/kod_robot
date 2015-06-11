local WidgetMaskFilter = import("..widget.WidgetMaskFilter")
local cocos_promise = import("..utils.cocos_promise")
local promise = import("..utils.promise")
local TutorialLayer = class('TutorialLayer', function()
    return display.newNode()
end)

function TutorialLayer:ctor(obj)
    if GLOBAL_FTE_DEBUG then
        self.left = display.newColorLayer(cc.c4b(255, 0, 0, 100)):addTo(self, -1)
        self.right = display.newColorLayer(cc.c4b(255, 0, 0, 100)):addTo(self, -1)
        self.top = display.newColorLayer(cc.c4b(255, 0, 0, 100)):addTo(self, -1)
        self.bottom = display.newColorLayer(cc.c4b(255, 0, 0, 100)):addTo(self, -1)
    else
        self.left = display.newLayer():addTo(self, 0)
        self.right = display.newLayer():addTo(self, 0)
        self.top = display.newLayer():addTo(self, 0)
        self.bottom = display.newLayer():addTo(self, 0)
    end
    local left, right, top, bottom = self.left, self.right, self.top, self.bottom
    for _, v in pairs{ left, right, top, bottom } do
        v:setContentSize(cc.size(display.width, display.height))
    end
    self.mask = WidgetMaskFilter.new():addTo(self):pos(display.cx, display.cy)
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
        v:pos(0,0)
        v:setTouchEnabled(true)
    end
    self.object = nil
    self.world_rect = nil
    self.mask:hide()
    self.mask:FocusOnRect()
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
    self:UpdateClickedRegion(self.world_rect)
    return self
end
function TutorialLayer:UpdateClickedRegion(rect)
    self.left:pos(rect.x - display.width, 0)
    self.right:pos(rect.x + rect.width, 0)
    self.top:pos(0, rect.y + rect.height)
    self.bottom:pos(0, rect.y - display.height)

    self.mask:show()
    self.mask:FocusOnRect(rect)
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
function TutorialLayer:RemoveAllOtherChildren()
    for i,v in ipairs(self:getChildren()) do
        if self.left ~= v or self.right ~= v or self.top ~= v or self.bottom ~= v then
            v:removeFromParent()
        end
    end
end


return TutorialLayer





