local SpriteConfig = import(".SpriteConfig")
local UILib = import("..ui.UILib")
local Sprite = import(".Sprite")
local UpgradingSprite = class("UpgradingSprite", Sprite)
----

function UpgradingSprite:GetWorldPosition()
    return self:convertToWorldSpace(cc.p(self:GetSpriteOffset())),
        self:convertToWorldSpace(cc.p(self:GetSpriteTopPosition()))
end
function UpgradingSprite:GetCurrentLocation()
    if self:GetEntity():GetType() == "wall" then
        return 21
    elseif self:GetEntity():GetType() == "tower" then
        return 22
    end
    local City = self:GetEntity():BelongCity()
    local tile = City:GetTileWhichBuildingBelongs(self:GetEntity())
    if City:IsFunctionBuilding(self:GetEntity()) then
        return tile.location_id
    else
        local houseLocation = tile:GetBuildingLocation(self:GetEntity())
        return tile.location_id, houseLocation
    end
end
function UpgradingSprite:UpgradeBegin()
    self:StartBuildingAnimation()
end

function UpgradingSprite:UpgradeFinished()
    self:RefreshSprite()
    self:StopBuildingAnimation()
    local running_scene = display.getRunningScene()
    if iskindof(running_scene, "MyCityScene") and self:GetEntity():IsHouse() then
        local _,tp = self:GetWorldPosition()
        local reses = UtilsForBuilding:GetHouseResType(self:GetEntity():GetType())
        for i,resType in ipairs(string.split(reses, ",")) do
            running_scene:GetHomePage():ShowResourceAni(resType, tp)
        end
    end
end
function UpgradingSprite:StartBuildingAnimation()
    if self.building_animation then return end
    local sequence = transition.sequence{
        cc.TintTo:create(0.8, 180, 180, 180),
        cc.TintTo:create(0.8, 255, 255, 255)
    }
    self:stopAllActions()
    self.building_animation = self:runAction(cc.RepeatForever:create(sequence))

    self.hammer_animation = ccs.Armature:create("chuizi"):addTo(self, 1):scale(0.6):align(display.CENTER):pos(self:GetSpriteOffset())
    self.hammer_animation:getAnimation():playWithIndex(0)
end
function UpgradingSprite:StopBuildingAnimation()
    self:stopAllActions()
    self:setColor(display.COLOR_WHITE)
    self.building_animation = nil

    if self.hammer_animation then
        self.hammer_animation:removeFromParent()
        self.hammer_animation = nil
    end
    -- self.level_bg:pos(self:GetSpriteTopPosition())
end
-- function UpgradingSprite:CheckCondition()
--     if not self.level_bg then return end
--     local building = self:GetEntity():GetRealEntity()
--     local level = building:GetLevel()
--     local canUpgrade = building:CanUpgrade()
--     self.level_bg:setVisible(level > 0)
--     self.text_field:setString(level)
--     self.can_level_up:setVisible(canUpgrade)
--     self.can_not_level_up:setVisible(not canUpgrade)
-- end
function UpgradingSprite:ctor(city_layer, entity)
    self.config = SpriteConfig[entity:GetType()]
    local x, y = city_layer:GetLogicMap():ConvertToMapPosition(entity:GetLogicPosition())
    UpgradingSprite.super.ctor(self, city_layer, entity, x, y)
    local User = entity:BelongCity():GetUser()

    -- if entity:GetType() == "wall" then
    --     if entity:IsGate() then
    --         self:CreateLevelNode()
    --     end
    -- else
    --     self:CreateLevelNode()
    -- end
    if UtilsForBuilding:GetBuildingEventByLocation(User, self:GetCurrentLocation()) then
        if entity:GetType() ~= "wall" then
            self:UpgradeBegin()
        elseif entity:IsGate() then
            self:UpgradeBegin()
        end
    end
    -- scheduleAt(self, function()
    --     self:CheckCondition()
    -- end)
    -- self:CreateBase()
end
function UpgradingSprite:DestorySelf()
    self:removeFromParent()
end
function UpgradingSprite:InitLabel(entity)
    local label = ui.newTTFLabel({ text = "text" , x = 0, y = 0 })
    self:addChild(label, 101)
    label:setPosition(cc.p(self:GetSpriteOffset()))
    label:setFontSize(50)
    self.label = label
    level = entity:GetLevel()
    label:setString(entity:GetType().." "..level)
end
function UpgradingSprite:GetSpriteFile()
    local config = self:GetCurrentConfig()
    return config.png, config.scale
end
function UpgradingSprite:GetSpriteOffset()
    local offset = self:GetCurrentConfig().offset
    return offset.x, offset.y
end
function UpgradingSprite:RefreshSprite()
    self.config = SpriteConfig[self.entity:GetType()]
    UpgradingSprite.super.RefreshSprite(self)
end
function UpgradingSprite:CreateSprite()
    local config = self:GetCurrentConfig()
    local sprite_file, scale = self:GetSpriteFile()
    local sprite = display.newSprite(sprite_file, nil, nil, {class=cc.FilteredSpriteWithOne})
        :scale(scale == nil and 1 or scale)
        :flipX(self:GetFlipX())
    local p = sprite:getAnchorPointInPoints()
    local ani_array = {}
    for _, v in ipairs(config.decorator) do
        if v.deco_type == "image" then
            display.newSprite(v.deco_name):addTo(sprite):pos(p.x + v.offset.x, p.y + v.offset.y)
        elseif v.deco_type == "animation" then
            local offset = v.offset
            local armature = ccs.Armature:create(v.deco_name):addTo(sprite):
                scale(v.scale or 1):align(display.CENTER, offset.x or p.x, offset.y or p.y)
            local animation = armature:getAnimation()
            animation:setSpeedScale(2)
            animation:playWithIndex(0)
            ani_array[#ani_array + 1] = armature
        end
    end
    self.ani_array = ani_array
    return sprite
end
function UpgradingSprite:GetAniArray()
    return self.ani_array
end
function UpgradingSprite:GetCurrentConfig()
    if self.config then
        return self.config:GetConfigByLevel(self:GetEntity():GetRealEntity():GetLevel())
    else
        return nil
    end
end
function UpgradingSprite:GetLogicZorder()
    if self:GetEntity():GetType() == "keep" then
        return 1
    elseif self:GetEntity():GetType() == "dragonEyrie" then
        return 2
    end
    local x, y = self:GetLogicPosition()
    return self:GetMapLayer():GetZOrderBy(self, x, y)
end
function UpgradingSprite:GetCenterPosition()
    return self:GetLogicMap():ConvertToMapPosition(self:GetEntity():GetMidLogicPosition())
end
-- function UpgradingSprite:CreateLevelNode()
--     self.level_bg = display.newNode():addTo(self, 1000):pos(self:GetSpriteTopPosition())
--     self.level_bg:setCascadeOpacityEnabled(true)
--     self.can_level_up = cc.ui.UIImage.new("can_level_up.png"):addTo(self.level_bg):show()
--     self.can_not_level_up = cc.ui.UIImage.new("can_not_level_up.png"):addTo(self.level_bg):pos(0,-10):hide()
--     self.text_field = UIKit:ttfLabel({
--         size = 16,
--         color = 0xfff1cc,
--     }):addTo(self.level_bg):align(display.CENTER, 10, 18)
--     self.text_field:setSkewY(-30)
-- end
-- function UpgradingSprite:ShowLevelUpNode()
--     self.level_bg:stopAllActions()
--     self.level_bg:fadeTo(0.5, 255)
-- end
-- function UpgradingSprite:HideLevelUpNode()
--     self.level_bg:stopAllActions()
--     self.level_bg:fadeTo(0.5, 0)
-- end
return UpgradingSprite

























