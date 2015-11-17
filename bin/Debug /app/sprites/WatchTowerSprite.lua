local Sprite = import(".Sprite")
local WatchTowerSprite = class("WatchTowerSprite", Sprite)

function WatchTowerSprite:ctor(city_layer, x, y)
    self.logic_x, self.logic_y = x, y
    WatchTowerSprite.super.ctor(self, city_layer, nil, city_layer:GetLogicMap():ConvertToMapPosition(x, y))
    -- self:CreateBase()
    local p = self.sprite:getAnchorPointInPoints()
    local armature = ccs.Armature:create("liaowangta")
                     :addTo(self.sprite):align(display.CENTER, p.x, p.y)
    local animation = armature:getAnimation()
    animation:setSpeedScale(2)
    animation:playWithIndex(0)
end
function WatchTowerSprite:IsContainPointWithFullCheck(x, y, world_x, world_y)
    return { logic_clicked = false, sprite_clicked = self:IsContainWorldPoint(world_x, world_y)}
end
function WatchTowerSprite:GetEntity()
    return {
        GetType = function()
            return "watchTower"
        end,
        GetLogicPosition = function()
            return self.logic_x, self.logic_y
        end,
        GetMidLogicPosition = function()
            return self.logic_x, self.logic_y
        end,
        IsHouse = function()
            return false
        end
    }
end
function WatchTowerSprite:GetSpriteFile()
    return "watchTower.png"
end
function WatchTowerSprite:GetSpriteOffset()
    return 35, 160
end
function WatchTowerSprite:GetMidLogicPosition()
    return self:GetLogicMap():ConvertToLogicPosition(self:getPosition())
end
function WatchTowerSprite:CreateBase()
    self:GenerateBaseTiles(5, 5)
end


return WatchTowerSprite













