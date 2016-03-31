local GameUIReplay = import(".GameUIReplay")
local GameUIReplayFte = class("GameUIReplayFte", GameUIReplay)



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
        local rect = self.ui_map.dragonBattleWhite:getCascadeBoundingBox()
        return UIKit:newGameUI("GameUIBattleFte", rect, 
            _("巨龙对决"), 
            _("对比攻防双方巨龙的力量,力量高者获胜,胜方享有100%增益加成,负方为50%增益加成,若巨龙在对决中阵亡,buff加成为0"))
        :AddToCurrentScene(true):PromiseOfFte()
    elseif state == "soldierFight" then
        local rect = self.ui_map.soldierBattleWhite:getCascadeBoundingBox()
        return UIKit:newGameUI("GameUIBattleFte", rect, 
            _("部队厮杀"), 
            _("每回合对比攻防兵种的战斗力(单位兵种战斗力 x 数量),战斗力高的一方获胜可继续留在场上,负方则会失去继续作战的机会"))
        :AddToCurrentScene(true):PromiseOfFte()
    end
end


return GameUIReplayFte



