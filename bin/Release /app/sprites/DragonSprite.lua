local AnimationSprite = import(".AnimationSprite")
local DragonSprite = class("DragonSprite", AnimationSprite)

function DragonSprite:ctor(map_layer, dragonType)
    AnimationSprite.super.ctor(self, map_layer, nil, 0, 0)
    self:ReloadSpriteCauseTerrainChanged(dragonType)
end
function DragonSprite:GetLogicZorder()
    return 1
end
function DragonSprite:ReloadSpriteCauseTerrainChanged(dragonType)
    if self.dragonType == dragonType and self.dragonType ~= nil then return end
    if self.sprite then
        self.sprite:removeFromParent()
    end
    self.sprite = self:CreateSprite(dragonType):addTo(self)
end
function DragonSprite:CreateSprite(dragonType)
    self.dragonType = dragonType
    if dragonType then
        return UIKit:CreateDragonBreathAni(dragonType, true)
    else
        return display.newNode()
    end
end
function DragonSprite:Pause()
    local amature = self:GetSprite():getChildren()[1]
    if amature then
        amature:getAnimation():stop()
    end
end
function DragonSprite:Resume()
    local amature = self:GetSprite():getChildren()[1]
    if amature then
        amature:getAnimation():playWithIndex(0)
    end
end


return DragonSprite


























