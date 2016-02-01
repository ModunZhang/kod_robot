local cocos_promise = import("..utils.cocos_promise")
local promise = import("..utils.promise")
local UILib = import(".UILib")
local BattleObject = import(".BattleObject")
local Wall = class("Wall", BattleObject)

function Wall:ctor(ui_replay)
    Wall.super.ctor(self, ui_replay)
    self.wall = ccs.Armature:create("chengqiang_1"):addTo(self):align(display.CENTER, 0 ,0)
    self.wall:getAnimation():setMovementEventCallFunc(handler(self, self.OnAnimationCallback))
end
function Wall:PlayAnimation(ani, loop_time)
    self.wall:getAnimation():play(ani, -1, loop_time or -1)
    self.wall:getAnimation():setSpeedScale(self:Speed())
end
function Wall:hit()
    self:PlayAnimation("Animation1", 0)
    local p = promise.new()
    self:OnAnimationPlayEnd("Animation1", function()
        p:resolve(self)
    end)
    return p
end
function Wall:attack()
    self:PlayAnimation("Animation2", 0)
    app:GetAudioManager():PlayeAttackSoundBySoldierName("ranger")
    local p = promise.new()
    self:OnAnimationPlayEnd("Animation2", function()
        p:resolve(self)
    end)
    return p
end
function Wall:turnLeft()
    self:setScaleX(1)
end
function Wall:turnRight()
    self:setScaleX(-1)
end
function Wall:breath()
    return cocos_promise.defer()
end
function Wall:Stop()
    Wall.super.Stop(self)
    self.wall:getAnimation():stop()
end
function Wall:RefreshSpeed()
    Wall.super.RefreshSpeed(self)
    self.wall:getAnimation():setSpeedScale(self:Speed())
end
return Wall









