local Sprite = import(".Sprite")
local CitizenSprite = class("CitizenSprite", Sprite)

local scale = 1
function CitizenSprite:ctor(city_layer, city, x, y)
    self.city = city
    self.path = city:FindAPointWayFromTile()
    CitizenSprite.super.ctor(self, city_layer, nil, city_layer:GetLogicMap():ConvertToMapPosition(x, y))
    local start_point = table.remove(self.path, 1)
    self:setPosition(self:GetLogicMap():ConvertToMapPosition(start_point.x, start_point.y))
    self:UpdateVelocityByPoints(start_point, self.path[1])
    -- self:CreateBase()
end
function CitizenSprite:PlayAnimation(animation)
    if animation then
        self.current_animation = animation
    end
    self.sprite:getAnimation():play(self.current_animation)
end
local citizen_map = {
    desert = {"shadi_nan", "shadi_nv"},
    iceField = {"xuedi_nan", "xuedi_nv"},
    grassLand = {"caodi_nan", "caodi_nv"},
}
function CitizenSprite:ReloadSpriteCauseTerrainChanged()
    local x_s = self:GetSprite():getScaleX()
    self.sprite:removeFromParent()
    self.sprite = self:CreateSprite():addTo(self, SPRITE):align(display.CENTER)
    self.sprite:setScaleX(x_s)
    self:PlayAnimation()
end
function CitizenSprite:CreateSprite()
    local ani_name = citizen_map[self:GetMapLayer():Terrain()][math.random(2)]
    local armature = ccs.Armature:create(ani_name)
    armature:setAnchorPoint(display.ANCHOR_POINTS[display.CENTER])
    return armature
end
function CitizenSprite:TurnEast()
    self:GetSprite():setScaleX(scale)
    self:PlayAnimation("45")
end
function CitizenSprite:TurnWest()
    self:GetSprite():setScaleX(-scale)
    self:PlayAnimation("-45")
end
function CitizenSprite:TurnNorth()
    self:GetSprite():setScaleX(-scale)
    self:PlayAnimation("45")
end
function CitizenSprite:TurnSouth()
    self:GetSprite():setScaleX(scale)
    self:PlayAnimation("-45")
end
function CitizenSprite:GetSpriteOffset()
    return 0,0
end
function CitizenSprite:GetMidLogicPosition()
    return self:GetLogicMap():ConvertToLogicPosition(self:getPosition())
end
function CitizenSprite:CreateBase()
    self:GenerateBaseTiles(1, 1)
end
local function wrap_point_in_table(...)
    local arg = {...}
    return {x = arg[1], y = arg[2]}
end
local cc = cc
function CitizenSprite:UpdateVelocityByPoints(start_point, end_point)
    local speed = math.random(10, 15)
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
function CitizenSprite:Speed()
    return self.speed
end
function CitizenSprite:Update(dt)
    local x, y = self:getPosition()

    local speed = self:Speed()
    local nx, ny = x + speed.x * dt, y + speed.y * dt

    local point = self.path[1]
    local ex, ey = self:GetLogicMap():ConvertToMapPosition(point.x, point.y)

    if speed.x * (ex - nx) + speed.y * (ey - ny) < 0 then
        if #self.path <= 1 then
            self.path = self.city:FindAPointWayFromPosition(point.x, point.y)
        end
        local path = self.path
        self:UpdateVelocityByPoints(path[1], path[2])
        nx, ny = ex, ey
        table.remove(path, 1)
    end
    self:setPosition(nx, ny)
end

return CitizenSprite










