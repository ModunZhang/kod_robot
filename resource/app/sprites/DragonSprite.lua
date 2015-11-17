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
    self:AddAnimationCallbackTo(self.sprite)
    self:PlayAnimation("fly")
end
local anchor_map = {
    greenDragon = cc.p(0.435,0.5),
    redDragon = cc.p(0.5,0.5),
    blueDragon = cc.p(0.432,0.51),
}
function DragonSprite:CreateSprite(dragonType)
    local dragon_animation
    if dragonType == "greenDragon" then
        dragon_animation = "green_long"
    elseif dragonType == "redDragon" then
        dragon_animation = "red_long"
    elseif dragonType == "blueDragon" then
        dragon_animation = "blue_long"
    else
        return display.newNode()
    end
    local armature = ccs.Armature:create(dragon_animation)
    armature:setAnchorPoint(anchor_map[dragonType])
    armature:setScaleX(-1.1)
    armature:setScaleY(1.1)
    armature:getAnimation():setMovementEventCallFunc(handler(self, self.OnAnimationCallback))

    self.idle_count = 0
    self.dragonType = dragonType
    return armature
end
function DragonSprite:OnAnimationStart(animation_name)
    if animation_name == "fly" then
        self.idle_count = 0
    end
end
function DragonSprite:OnAnimationComplete(animation_name)
end
function DragonSprite:OnAnimationEnded(animation_name)
    if animation_name == "idle" then
        self.idle_count = self.idle_count + 1
        local count = 10
        if self.idle_count > count then
            if math.random(123456789) % count < self.idle_count - count then
                self:PlayAnimation("fly")
            end
        else
            self:PlayAnimation("idle")
        end
    elseif animation_name == "fly" then
        self:PlayAnimation("idle")
    end
end


return DragonSprite


























