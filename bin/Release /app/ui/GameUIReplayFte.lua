local GameUIReplayNew = import(".GameUIReplayNew")
local GameUIReplayFte = class("GameUIReplayFte", GameUIReplayNew)



function GameUIReplayFte:ctor(...)
    GameUIReplayFte.super.ctor(self, ...)
    self.count = 0
end
function GameUIReplayFte:OnMoveInStage()
	GameUIReplayFte.super.OnMoveInStage(self)
	self.ui_map.pass:setButtonEnabled(false)
end
function GameUIReplayFte:OnHandle(state)
    if state == "dragonFight" then
        local rect = self.ui_map.top:getCascadeBoundingBox()
        rect.x, rect.y, rect.width, rect.height = rect.x + 30, rect.y + 100, rect.width - 60, rect.height - 200
        return UIKit:newGameUI("GameUIBattleFte", rect, _("巨龙对决"), _("对比攻防双方巨龙的力量,力量高者获胜,胜方享有100%增益加成,负方为50%增益加成,若巨龙在对决中阵亡,buff加成为0")):AddToCurrentScene(true):PromiseOfFte()
    elseif state == "rightDefeat" then
        local rect = self.ui_map.top:getCascadeBoundingBox()
        rect.x, rect.y, rect.width, rect.height = rect.x + 30, rect.y + 20, rect.width - 60, rect.height - 120
        if self.count == 0 then
            self.count = 1
            return UIKit:newGameUI("GameUIBattleFte", rect, _("部队厮杀"), _("每回合对比攻防兵种的战斗力(单位兵种战斗力 x 数量),战斗力高的一方获胜可继续留在场上,负方则会失去继续作战的机会")):AddToCurrentScene(true):PromiseOfFte()
        elseif self.count == 1 then
            rect.x, rect.y, rect.width, rect.height = rect.x + 75, rect.y, rect.width - 150, rect.height - 320
            self.count = 2
            return UIKit:newGameUI("GameUIBattleFte", rect, _("士气受损"), _("当兵中受到攻击时,会根据损失的单位数量降低士气,当士气降至0时,无论该兵种胜负都会下场")):AddToCurrentScene(true):PromiseOfFte()
        end
    end
end


return GameUIReplayFte



