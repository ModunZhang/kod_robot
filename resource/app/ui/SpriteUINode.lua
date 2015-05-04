local SpriteUINode = class("SpriteUINode", function()
    return display.newNode()
end)

function SpriteUINode:OnPositionChanged(x, y)
    self:setPosition(self:GetPositionFromWorld(x, y))
end
function SpriteUINode:OnBuildingUpgradingBegin(building, time)
end
function SpriteUINode:OnBuildingUpgradeFinished(building)
end
function SpriteUINode:OnBuildingUpgrading(building, time)
end
function SpriteUINode:OnCheckUpgradingCondition(sprite)

end
function SpriteUINode:GetPositionFromWorld(x, y)
    return self:getParent():convertToNodeSpace(cc.p(x, y))
end
function SpriteUINode:ctor()
    self:InitWidget()
end
function SpriteUINode:InitWidget()
end
function SpriteUINode:DestorySelf()
    self:removeFromParent()
end




return SpriteUINode



