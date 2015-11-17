local UILib = import("..ui.UILib")
local Localize = import("..utils.Localize")
local SpriteConfig = import(".SpriteConfig")
local WithInfoSprite = import(".WithInfoSprite")
local MonsterSprite = class("MonsterSprite", WithInfoSprite)
local soldier_config = {
    ["swordsman"] = {
        {"heihua_bubing_2", 4},
        {"heihua_bubing_2", 4},
        {"heihua_bubing_3", 4},
    },
    ["ranger"] = {
        {"heihua_gongjianshou_2", 4},
        {"heihua_gongjianshou_2", 4},
        {"heihua_gongjianshou_3", 4},
    },
    ["lancer"] = {
        {"heihua_qibing_2", 2},
        {"heihua_qibing_2", 2},
        {"heihua_qibing_3", 2},
    },
    ["catapult"] = {
        {"heihua_toushiche_2", 1},
        {"heihua_toushiche_2", 1},
        {"heihua_toushiche_3", 1},
    },

    -----
    ["sentinel"] = {
        {"heihua_shaobing_2", 4},
        {"heihua_shaobing_2", 4},
        {"heihua_shaobing_3", 4},
    },
    ["crossbowman"] = {
        {"heihua_nugongshou_2", 4},
        {"heihua_nugongshou_2", 4},
        {"heihua_nugongshou_3", 4},
    },
    ["horseArcher"] = {
        {"heihua_youqibing_2", 2},
        {"heihua_youqibing_2", 2},
        {"heihua_youqibing_3", 2},
    },
    ["ballista"] = {
        {"heihua_nuche_2", 1},
        {"heihua_nuche_2", 1},
        {"heihua_nuche_3", 1},
    },


    ["skeletonWarrior"] = {
        {"kulouyongshi", 4},
        {"kulouyongshi", 4},
        {"kulouyongshi", 4},
    },
    ["skeletonArcher"] = {
        {"kulousheshou", 4},
        {"kulousheshou", 4},
        {"kulousheshou", 4},
    },
    ["deathKnight"] = {
        {"siwangqishi", 2},
        {"siwangqishi", 2},
        {"siwangqishi", 2},
    },
    ["meatWagon"] = {
        {"jiaorouche", 1},
        {"jiaorouche", 1},
        {"jiaorouche", 1},
    },
}
local position_map = {
    [1] = {
        {x = 0, y = -10}
    },
    [2] = {
        {x = -10, y = -10},
        {x = 10, y = -30},
    },
    [4] = {
        {x = 0, y = 0},
        {x = -25, y = -15},
        {x = 25, y = -15},
        {x = 0, y = -30},
    }
}
function MonsterSprite:ctor(city_layer, entity, is_my_alliance, alliance)
    -- 不加此行会报错
    self.entity = entity
    MonsterSprite.super.ctor(self, city_layer, entity, false, alliance)
end
function MonsterSprite:CreateSprite()
    local soldier_type, star = unpack(string.split(self:GetBuildingInfo().name, '_'))
    local ani,count = unpack(soldier_config[soldier_type][tonumber(star)])
    local node = display.newNode()
    for _,v in ipairs(position_map[count]) do
        UIKit:CreateIdle45Ani(ani):pos(v.x, v.y):addTo(node)
    end
    return node
end
function MonsterSprite:GetInfo()
    local info = self:GetBuildingInfo()
    local level = info.level
    local soldier_type = unpack(string.split(info.name, '_'))
    return level, Localize.soldier_name[soldier_type]
end
local LOCK_TAG = 11201
function MonsterSprite:Flash(time)
    self:Lock()
end
function MonsterSprite:Lock()
    if not self:GetSprite():getChildByTag(LOCK_TAG) then
    local sprite = display.newSprite("tmp_monster_circle.png")
        :addTo(self:GetSprite(), -1, LOCK_TAG):pos(0, -10):scale(1.3)
        sprite:runAction(
            cc.RepeatForever:create(
                transition.sequence{
                    cc.ScaleTo:create(1/2, 1.5),
                    cc.ScaleTo:create(1/2, 1.3),
                }
            )
        )
        sprite:setColor(cc.c3b(255,60,0))
    end
end
function MonsterSprite:Unlock()
    self:GetSprite():removeChildByTag(LOCK_TAG)
end
function MonsterSprite:GetBuildingInfo()
    return self.alliance:FindAllianceMonsterInfoByObject(self:GetEntity())
end



---
function MonsterSprite:CreateBase()
    self:GenerateBaseTiles(1, 1)
end
function MonsterSprite:newBatchNode(w, h)
    local start_x, end_x, start_y, end_y = self:GetLocalRegion(w, h)
    local base_node = display.newBatchNode("grass_80x80_.png", 10)
    local map = self:GetLogicMap()
    for ix = start_x, end_x do
        for iy = start_y, end_y do
            display.newSprite(base_node:getTexture()):addTo(base_node):pos(map:ConvertToLocalPosition(ix, iy)):scale(2)
        end
    end
    return base_node
end
return MonsterSprite


