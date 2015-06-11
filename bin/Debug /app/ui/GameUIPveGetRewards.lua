local GameUIPveGetRewards = UIKit:createUIClass('GameUIPveGetRewards', "UIAutoClose")

function GameUIPveGetRewards:ctor(x, y)
    GameUIPveGetRewards.super.ctor(self)
    self.__type  = UIKit.UITYPE.BACKGROUND

    local manager = ccs.ArmatureDataManager:getInstance()
    manager:addArmatureFileInfo(DEBUG_GET_ANIMATION_PATH("animations/lanse.ExportJson"))

    local node = display.newNode()
    local box = ccs.Armature:create("lanse"):addTo(node)
        :align(display.CENTER, x, y):scale(0.5)
    self:addTouchAbleChild(node)
    self:DisableAutoClose(true)

    local mid = self:convertToNodeSpace(cc.p(display.cx - 50, display.cy))
    local time = 0.4
    local m = transition.create(cc.MoveTo:create(time, mid), {easing = "backOut"})
    local s = transition.create(cc.ScaleTo:create(time, 0.7), {easing = nil})
    box:runAction(transition.sequence{
        cc.Spawn:create(m, s),
        cc.CallFunc:create(function()
            box:getAnimation():playWithIndex(0, -1, 0)
            box:getAnimation():setMovementEventCallFunc(function(armatureBack, movementType, movementID)
                if movementType == ccs.MovementEventType.complete then
                    self:DisableAutoClose(false)
                end
            end)
        end),
    })
end




return GameUIPveGetRewards











