local Sprite = import(".Sprite")
local RuinSprite = class("RuinSprite", Sprite)
local random = math.random
local ruin_map = {
    "ruin_1.png",
    "ruin_1.png",
    "ruin_2.png",
    "ruin_2.png",
    "ruin_3.png",
}
function RuinSprite:GetWorldPosition()
    return self:convertToWorldSpace(cc.p(self:GetSpriteOffset())),
        self:convertToWorldSpace(cc.p(self:GetSpriteTopPosition()))
end
function RuinSprite:GetSpriteTopPosition()
    local x, y = RuinSprite.super.GetSpriteTopPosition(self)
    return x, y
end
function RuinSprite:ctor(city_layer, entity)
    self.png_index = random(#ruin_map)
    local x, y = city_layer:GetLogicMap():ConvertToMapPosition(entity:GetLogicPosition())
    RuinSprite.super.ctor(self, city_layer, entity, x, y)
end
function RuinSprite:GetSpriteFile()
    return ruin_map[self.png_index]
end
function RuinSprite:GetSpriteOffset()
	if self.png_index == 5 then
		return 0, 40
	end
    return 0, 35
end
function RuinSprite:EnterEditMode()
    self:stopAllActions()
    self:runAction(cc.RepeatForever:create(transition.sequence{
        cc.TintTo:create(0.8, 180, 180, 180),
        cc.TintTo:create(0.8, 255, 255, 255)
    }))
end
function RuinSprite:LeaveEditMode()
	self:stopAllActions()
    self:setColor(display.COLOR_WHITE)
end
function RuinSprite:IsEditMode()
	return self:getNumberOfRunningActions() > 0
end
function RuinSprite:GetWorldPosition()
    return self:convertToWorldSpace(cc.p(self:GetSpriteOffset())),
        self:convertToWorldSpace(cc.p(self:GetSpriteTopPosition()))
end
function RuinSprite:OnSceneMove()
    local world_point, top = self:GetWorldPosition()
    self:NotifyObservers(function(listener)
        listener:OnPositionChanged(world_point.x, world_point.y, top.x, top.y + 30)
    end)
end
return RuinSprite



