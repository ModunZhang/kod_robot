local Sprite = import(".Sprite")
local BarracksSoldierSprite = class("BarracksSoldierSprite", Sprite)

local min = math.min
local soldier_config = {
    ----
    ["swordsman"] = {
        {"bubing_1", 0, 10, 0.8},
        {"bubing_2", -10, 5, 0.8},
        {"bubing_3", 0, 0, 0.8},
    },
    ["ranger"] = {
        {"gongjianshou_1", 0, 10, 0.8},
        {"gongjianshou_2", 0, 10, 0.8},
        {"gongjianshou_3", 0, 10, 0.8},
    },
    ["lancer"] = {
        {"qibing_1", 0, 10, 0.8},
        {"qibing_2", 0, 10, 0.8},
        {"qibing_3", 0, 10, 0.8},
    },
    ["catapult"] = {
        {  "toushiche", 0, 10, 0.8},
        {"toushiche_2", 0, 10, 0.8},
        {"toushiche_3", 0, 10, 0.8},
    },

    -----
    ["sentinel"] = {
        {"shaobing_1", 0, 10, 0.8},
        {"shaobing_2", 0, 10, 0.8},
        {"shaobing_3", 0, 10, 0.8},
    },
    ["crossbowman"] = {
        {"nugongshou_1", 0, 10, 0.8},
        {"nugongshou_2", 0, 10, 0.8},
        {"nugongshou_3", 10, 10, 0.8},
    },
    ["horseArcher"] = {
        {"youqibing_1", 0, 10, 0.8},
        {"youqibing_2", 0, 10, 0.8},
        {"youqibing_3", 0, 10, 0.8},
    },
    ["ballista"] = {
        {"nuche_1", 0, 10, 0.8},
        {"nuche_2", 0, 10, 0.8},
        {"nuche_3", 0, 10, 0.8},
    },
    ----
    ["skeletonWarrior"] = {
        {"kulouyongshi", 0, 10, 0.8},
        {"kulouyongshi", 0, 10, 0.8},
        {"kulouyongshi", 0, 10, 0.8},
    },
    ["skeletonArcher"] = {
        {"kulousheshou", 30, 5, 0.8},
        {"kulousheshou", 30, 5, 0.8},
        {"kulousheshou", 30, 5, 0.8},
    },
    ["deathKnight"] = {
        {"siwangqishi", 0, 5, 0.8},
        {"siwangqishi", 0, 5, 0.8},
        {"siwangqishi", 0, 5, 0.8},
    },
    ["meatWagon"] = {
        {"jiaorouche", 0, 10, 0.8},
        {"jiaorouche", 0, 10, 0.8},
        {"jiaorouche", 0, 10, 0.8},
    },
}


function BarracksSoldierSprite:ctor(city_layer, soldier_type, star)
    self.soldier_type = soldier_type
    self.soldier_star = star
    self.path = {
        {x = 6, y = 27},
        {x = 9, y = 27},
        {x = 9, y = 9},
        {x = 4, y = 9},
        {x = 4, y = 10},
    }
    local start_point = table.remove(self.path, 1)
    BarracksSoldierSprite.super.ctor(self, city_layer, nil, city_layer:GetLogicMap():ConvertToMapPosition(start_point.x, start_point.y))
    self:setPosition(self:GetLogicMap():ConvertToMapPosition(start_point.x, start_point.y))
    self:UpdateVelocityByPoints(start_point, self.path[1])


    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(dt)
        dt = min(dt, 0.05)
        self:Update(dt)
    end)
    self:scheduleUpdate()

    -- self:CreateBase()
end
function BarracksSoldierSprite:PlayAnimation(animation)
    self.sprite:getAnimation():play(animation)
end
function BarracksSoldierSprite:CreateSprite()
    local ani_name,_,_,s = unpack(soldier_config[self.soldier_type][self.soldier_star])
    local armature = ccs.Armature:create(ani_name):scale(s)
    armature:setAnchorPoint(display.ANCHOR_POINTS[display.CENTER])
    return armature
end
function BarracksSoldierSprite:TurnEast()
    self:GetSprite():setScaleX(self:GetSprite():getScaleY())
    self:PlayAnimation("move_45")
end
function BarracksSoldierSprite:TurnWest()
    self:GetSprite():setScaleX(-self:GetSprite():getScaleY())
    self:PlayAnimation("move_-45")
end
function BarracksSoldierSprite:TurnNorth()
    self:GetSprite():setScaleX(-self:GetSprite():getScaleY())
    self:PlayAnimation("move_45")
end
function BarracksSoldierSprite:TurnSouth()
    self:GetSprite():setScaleX(self:GetSprite():getScaleY())
    self:PlayAnimation("move_-45")
end
function BarracksSoldierSprite:GetSpriteOffset()
    local _,x,y = unpack(soldier_config[self.soldier_type][self.soldier_star])
    return x,y
end
function BarracksSoldierSprite:GetMidLogicPosition()
    return self:GetLogicMap():ConvertToLogicPosition(self:getPosition())
end
function BarracksSoldierSprite:CreateBase()
    self:GenerateBaseTiles(1, 1)
end
local function wrap_point_in_table(...)
    local arg = {...}
    return {x = arg[1], y = arg[2]}
end
local cc = cc
function BarracksSoldierSprite:UpdateVelocityByPoints(start_point, end_point)
    local speed = 150
    local logic_map = self:GetLogicMap()
    local spt = wrap_point_in_table(logic_map:ConvertToMapPosition(start_point.x, start_point.y))
    local ept = wrap_point_in_table(logic_map:ConvertToMapPosition(end_point.x, end_point.y))
    local dir = cc.pSub(ept, spt)
    local distance = cc.pGetLength(dir)
    self.speed = {x = speed * dir.x / distance, y = speed * dir.y / distance}
    local degree = math.deg(cc.pGetAngle(dir,cc.p(1,-1)))
    if degree < 0 and degree > -15 then
        self:TurnEast()
    elseif degree < -50 and degree > -90 then
        self:TurnSouth()
    elseif degree > 100 and degree < 120 then
        self:TurnNorth()
    else
        self:TurnWest()
    end
end
function BarracksSoldierSprite:Speed()
    return self.speed
end
function BarracksSoldierSprite:Update(dt)
    if #self.path == 0 then return end

    local x, y = self:getPosition()

    local speed = self:Speed()
    local nx, ny = x + speed.x * dt, y + speed.y * dt

    local point = self.path[1]
    local ex, ey = self:GetLogicMap():ConvertToMapPosition(point.x, point.y)

    if speed.x * (ex - nx) + speed.y * (ey - ny) < 0 then
        if #self.path <= 1 then
            self:unscheduleUpdate()
            self:runAction(
                transition.sequence{
                    cc.FadeOut:create(0.5),
                    cc.CallFunc:create(function()
                        self:GetMapLayer():RefreshMyCitySoldierCount()
                    end),
                    cc.RemoveSelf:create(),
                }
            )
            return
        end
        local path = self.path
        self:UpdateVelocityByPoints(path[1], path[2])
        nx, ny = ex, ey
        table.remove(path, 1)
    end
    self:setPosition(nx, ny)
end

return BarracksSoldierSprite












