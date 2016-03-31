local Sprite = import(".Sprite")
local SoldierSprite = class("SoldierSprite", Sprite)



local soldier_config = {
    swordsman_1 = {count = 4, scale = 0.6},
    swordsman_2 = {count = 4, scale = 0.6},
    swordsman_3 = {count = 4, scale = 0.6},
    ranger_1 = {count = 4, scale = 0.6},
    ranger_2 = {count = 4, scale = 0.6},
    ranger_3 = {count = 4, scale = 0.6},
    lancer_1 = {count = 2, scale = 0.65},
    lancer_2 = {count = 2, scale = 0.65},
    lancer_3 = {count = 2, scale = 0.65},
    catapult_1 = {count = 1, scale = 0.55},
    catapult_2 = {count = 1, scale = 0.55},
    catapult_3 = {count = 1, scale = 0.55},
    sentinel_1 = {count = 4, scale = 0.6},
    sentinel_2 = {count = 4, scale = 0.6},
    sentinel_3 = {count = 4, scale = 0.6},
    crossbowman_1 = {count = 4, scale = 0.6},
    crossbowman_2 = {count = 4, scale = 0.6},
    crossbowman_3 = {count = 4, scale = 0.6},
    horseArcher_1 = {count = 2, scale = 0.7},
    horseArcher_2 = {count = 2, scale = 0.7},
    horseArcher_3 = {count = 2, scale = 0.7},
    ballista_1 = {count = 1, scale = 0.6},
    ballista_2 = {count = 1, scale = 0.6},
    ballista_3 = {count = 1, scale = 0.6},
    skeletonWarrior = {count = 4, scale = 0.6},
    skeletonArcher = {count = 4, scale = 0.6},
    deathKnight = {count = 2, scale = 0.65},
    meatWagon = {count = 1, scale = 0.6},
}
local position_map = {
    [1] = {
        x = 0, 
        y = 31,
        {x = 0, y = 0},
    },
    [2] = {
        x = -15, 
        y = 45,
        {x = -5, y = -15},
        {x = 20, y = -30},
    },
    [4] = {
        x = 0, 
        y = 45,
        {x = 0, y = -5},
        {x = -25, y = -20},
        {x = 25, y = -20},
        {x = 0, y = -35},
    }
}

local normal = GameDatas.Soldiers.normal
local special = GameDatas.Soldiers.special
function SoldierSprite:ctor(city_layer, soldier_type, x, y)
    assert(soldier_type)
    self.soldier_type = soldier_type
    self.x, self.y = x, y
    SoldierSprite.super.ctor(self, city_layer, nil, city_layer:GetLogicMap():ConvertToMapPosition(x, y))


    -- self:CreateBase()
    -- ui.newTTFLabel({text = soldier_type, size = 20, x = 0, y = 100}):addTo(self, 10)
end
function SoldierSprite:CreateSprite()
    local node = display.newNode()
    local s = (soldier_config[self.soldier_type].scale or 1) * 0.8
    for _,v in ipairs(position_map[soldier_config[self.soldier_type].count]) do
        UIKit:CreateSoldierIdle45Ani(self.soldier_type)
        :addTo(node):align(display.CENTER, v.x, v.y):scale(s)
    end
    return node
end
function SoldierSprite:GetLogicPosition()
    return self.x, self.y
end
function SoldierSprite:GetSpriteOffset()
    local config = position_map[soldier_config[self.soldier_type].count]
    return config.x, config.y
end
function SoldierSprite:CreateBase()
    self:GenerateBaseTiles(2, 2)
end
function SoldierSprite:GetSoldierType()
    return self.soldier_type
end
function SoldierSprite:SetPositionWithZOrder(x, y)
    self.x, self.y = self:GetLogicMap():ConvertToLogicPosition(x, y)
    SoldierSprite.super.SetPositionWithZOrder(self, x, y)
end
function SoldierSprite:GetMidLogicPosition()
    return self.x - 1, self.y - 1
end

return SoldierSprite














