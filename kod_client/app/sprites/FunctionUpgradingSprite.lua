local SpriteConfig = import(".SpriteConfig")
local UpgradingSprite = import(".UpgradingSprite")
local FunctionUpgradingSprite = class("FunctionUpgradingSprite", UpgradingSprite)

-- function FunctionUpgradingSprite:OnUserDataChanged_buildingEvents(userData, deltaData)
--     FunctionUpgradingSprite.super.OnUserDataChanged_buildingEvents(self, userData, deltaData)
--     if deltaData("buildingEvents.add") 
--     or deltaData("buildingEvents.remove") then
--         self:OnTileChanged(self:GetEntity():BelongCity())
--     end
-- end
function FunctionUpgradingSprite:OnTileLocked(city)
    self:OnTileChanged(city)
end
function FunctionUpgradingSprite:OnTileUnlocked(city)
    self:OnTileChanged(city)
end
function FunctionUpgradingSprite:OnTileChanged(city)
    local current_tile = city:GetTileByLocationId(city:GetLocationIdByBuilding(self:GetEntity()))
    if current_tile:IsUnlocked() then return self:show() end
    if self:GetEntity():IsUpgrading() then return self:show() end
    if current_tile:NeedWalls() and not self:GetEntity():IsUnlocking() then
        return self:show()
    end
    if not city:IsTileCanbeUnlockAt(current_tile.x, current_tile.y) then
        return self:hide()
    end
    return self:hide()
end
function FunctionUpgradingSprite:ctor(city_layer, entity, city)
    FunctionUpgradingSprite.super.ctor(self, city_layer, entity)
    self:OnTileChanged(city)
end
function FunctionUpgradingSprite:GetSpriteTopPosition()
    local x,y = FunctionUpgradingSprite.super.GetSpriteTopPosition(self)
    local type_ = self:GetEntity():GetType()
    if type_ == "keep" then
        return x - 30, y - 50
    elseif type_ == "watchTower" then
        return x - 30, y - 50
    end
    return x,y
end



return FunctionUpgradingSprite










