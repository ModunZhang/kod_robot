local AnimationSprite = import(".AnimationSprite")
local DragonSprite = class("DragonSprite", AnimationSprite)

function DragonSprite:ctor(map_layer, tarrain)
    AnimationSprite.super.ctor(self, map_layer, nil, 0, 0)
    self:ReloadSpriteCauseTerrainChanged(tarrain)
end
function DragonSprite:SetPositionWithZOrder()

end
function DragonSprite:GetLogicZorder()
    return 1
end
function DragonSprite:ReloadSpriteCauseTerrainChanged(terrain)
    if self.sprite then
        self.sprite:removeFromParent()
    end
    self.sprite = self:CreateSprite(terrain):addTo(self)
    self:AddAnimationCallbackTo(self.sprite)
    self:PlayAnimation("fly")
end
function DragonSprite:CreateSprite(terrain)
    local dragon_animation
    if terrain == "grassLand" then
        dragon_animation = "green_long"
    elseif terrain == "desert" then
        dragon_animation = "red_long"
    elseif terrain == "iceField" then
        dragon_animation = "blue_long"
    end
    local armature = ccs.Armature:create(dragon_animation)
    armature:setAnchorPoint(display.ANCHOR_POINTS[display.CENTER])
    armature:setScaleX(-1)
    armature:getAnimation():setMovementEventCallFunc(handler(self, self.OnAnimationCallback))

    self.idle_count = 0
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


























