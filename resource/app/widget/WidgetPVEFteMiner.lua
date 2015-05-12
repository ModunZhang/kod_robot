local WidgetPVEMiner = import("..widget.WidgetPVEMiner")
local WidgetPVEFteMiner = class("WidgetPVEFteMiner", WidgetPVEMiner)


function WidgetPVEFteMiner:ctor(...)
    WidgetPVEFteMiner.super.ctor(self, ...)
    self.__type  = UIKit.UITYPE.BACKGROUND
end


-- fte
local mockData = import("..fte.mockData")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
function WidgetPVEFteMiner:PormiseOfFte()
    local ui = self
    function ui:Fight()
        local enemy = self:GetObject():GetNextEnemy()
        UIKit:newGameUI('GameUIPVEFteSendTroop',
            enemy.soldiers,-- pve 怪数据
            function(dragonType, soldiers)
                local dragon = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager():GetDragon(dragonType)
                local attack_dragon = {
                    level = dragon:Level(),
                    dragonType = dragonType,
                    currentHp = dragon:Hp(),
                    hpMax = dragon:GetMaxHP(),
                    strength = dragon:TotalStrength(),
                    vitality = dragon:TotalVitality(),
                    dragon = dragon
                }
                local attack_soldier = LuaUtils:table_map(soldiers, function(k, v)
                    return k, {
                        name = v.name,
                        star = v.star,
                        count = v.count
                    }
                end)

                local report = GameUtils:DoBattle(
                    {dragon = attack_dragon, soldiers = attack_soldier},
                    {dragon = enemy.dragon, soldiers = enemy.soldiers},
                    self:GetObject():GetMap():Terrain()
                )

                if report:IsAttackWin() then
                    self:Search()
                    local rewards = self:GetObject():IsLast() and enemy.rewards + self:GetObject():GetNpcRewards() or enemy.rewards
                    UIKit:newGameUI("GameUIReplayNew", report, function()
                        if report:IsAttackWin() then
                            GameGlobalUI:showTips(_("获得奖励"), rewards)
                        end
                    end):AddToCurrentScene(true)

                    mockData.FightWithNpc()
                else
                    UIKit:newGameUI("GameUIReplayNew", report):AddToCurrentScene(true)
                end
            end):AddToCurrentScene(true)
    end


    local r = self.btns[1]:getCascadeBoundingBox()
    self:GetFteLayer():SetTouchObject(self.btns[1])

    WidgetFteArrow.new(_("点击进攻")):addTo(self:GetFteLayer())
        :TurnUp():align(display.TOP_CENTER, r.x + r.width/2, r.y - 10)

    return UIKit:PromiseOfOpen("GameUIPVEFteSendTroop")
        :next(function(ui)
            self:GetFteLayer():removeFromParent()
            return ui:PormiseOfFte()
        end):next(function()
        return self:PromiseOfExit()
        end)
end
function WidgetPVEFteMiner:PromiseOfExit()
    local r = self.btns[2]:getCascadeBoundingBox()
    self:GetFteLayer():SetTouchObject(self.btns[2])

    WidgetFteArrow.new(_("点击离开")):addTo(self:GetFteLayer())
        :TurnRight():align(display.RIGHT_CENTER, r.x - 20, r.y + r.height/2)

    return UIKit:PromiseOfClose("WidgetPVEFteMiner")
end


return WidgetPVEFteMiner