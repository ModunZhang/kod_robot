local Sprite = import(".Sprite")
local AnimationSprite = class("AnimationSprite", Sprite)
function AnimationSprite:ctor(city_layer, entity, x, y)
    AnimationSprite.super.ctor(self, city_layer, entity, x, y)
    assert(self:GetSprite().getAnimation)
    assert(self:GetSprite():getAnimation().play)
    assert(self:GetSprite():getAnimation().stop)
    assert(self:GetSprite():getAnimation().getCurrentMovementID)
    assert(self:GetSprite():getAnimation().setMovementEventCallFunc)
end
function AnimationSprite:CreateSprite()
    assert(false, "在子类实实现动画函数")
end
---- 动画相关
function AnimationSprite:AddAnimationCallbackTo(sprite)
    sprite:getAnimation():setMovementEventCallFunc(handler(self, self.OnAnimationCallback))
end
function AnimationSprite:OnAnimationCallback(armatureBack, movementType, movementID)
    if movementType == ccs.MovementEventType.start then
        self:OnAnimationStart(movementID)
    elseif movementType == ccs.MovementEventType.complete then
        self:OnAnimationComplete(movementID)
    elseif movementType == ccs.MovementEventType.loopComplete then
        self:OnAnimationEnded(movementID)
    end
end
function AnimationSprite:OnAnimationStart(animation_name)
end
function AnimationSprite:OnAnimationComplete(animation_name)
end
function AnimationSprite:OnAnimationEnded(animation_name)
end
function AnimationSprite:PlayAnimation(animation)
    -- self:GetSprite():getAnimation():playWithIndex(0)
    self:GetSprite():getAnimation():play(animation)
end
function AnimationSprite:CurrentAnimation()
    self:GetSprite():getAnimation():getCurrentMovementID()
end


return AnimationSprite




