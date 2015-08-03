local Sprite = import(".Sprite")
local FairGroundSprite = class("FairGroundSprite", Sprite)

function FairGroundSprite:ctor(city_layer, x, y)
    FairGroundSprite.super.ctor(self, city_layer, nil, city_layer:GetLogicMap():ConvertToMapPosition(x, y))
    -- self:CreateBase()
end
function FairGroundSprite:IsContainPointWithFullCheck(x, y, world_x, world_y)
    return { logic_clicked = false, sprite_clicked = self:IsContainWorldPoint(world_x, world_y)}
end
function FairGroundSprite:GetEntity()
    return {
        GetType = function()
            return "FairGround"
        end,
        GetLogicPosition = function()
            return -1, -1
        end,
        IsHouse = function()
            return false
        end
    }
end
function FairGroundSprite:GetSpriteFile()
    return "Fairground.png"
end
function FairGroundSprite:GetSpriteOffset()
    return 80, 130
end
function FairGroundSprite:GetMidLogicPosition()
    return self:GetLogicMap():ConvertToLogicPosition(self:getPosition())
end
function FairGroundSprite:CreateBase()
    self:GenerateBaseTiles(6, 9)
end


return FairGroundSprite










