local Sprite = import(".Sprite")
local BirdSprite = class("BirdSprite", Sprite)

function BirdSprite:ctor(city_layer, x, y)
    BirdSprite.super.ctor(self, city_layer, nil, x, y)
    self:GetSprite():getAnimation():playWithIndex(0, -1)
    self:Refly()
end
function BirdSprite:Refly()
    local size = self:show():GetMapLayer():getContentSize()
    local points
    if math.random(2) > 1 then
        self:pos(0,0)
        self:GetSprite():setScaleX(-1) -- 往右飞
        points = {
            cc.p(math.random(500) - 250, 0),
            cc.p(math.random(size.width) - 500, size.height/2),
            cc.p(size.width, size.height),
        }
    else
        self:pos(size.width,0)
        self:GetSprite():setScaleX(1) -- 往左飞
        points = {
            cc.p(math.random(500) - 250, 0),
            cc.p(math.random(size.width) - 500, size.height/2),
            cc.p(-size.width, size.height),
        }
    end
    self:stopAllActions()
    self:runAction(transition.sequence({
        cc.BezierBy:create(math.random(25,30), points),
        cc.CallFunc:create(function() self:hide() end),
        cc.DelayTime:create(math.random(30,60)),
        cc.CallFunc:create(function() self:Refly() end)
    }))
end
function BirdSprite:CreateSprite()
    return ccs.Armature:create("gezi"):align(display.CENTER)
end
function BirdSprite:GetSpriteOffset()
    return 0,0
end
function BirdSprite:GetMidLogicPosition()
    return 0,0
end

return BirdSprite














