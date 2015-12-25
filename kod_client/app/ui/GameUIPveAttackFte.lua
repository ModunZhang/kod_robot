local GameUIPveAttack = import(".GameUIPveAttack")
local GameUIPveAttackFte = class("GameUIPveAttackFte", GameUIPveAttack)
local mockData = import("..fte.mockData")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
local sections = GameDatas.PvE.sections
function GameUIPveAttackFte:ctor(...)
    GameUIPveAttackFte.super.ctor(self, ...)
    self:DisableAutoClose()
end

local fightReport1 = {
    playerDragonFightData = {
        type = "greenDragon",
        hpMax = 116,
        hp = 116,
        isWin = true,
        hpDecreased = 15
    },
    sectionDragonFightData = {
        type = "blueDragon",
        hpMax = 116,
        hp = 116,
        isWin = false,
        hpDecreased = 22
    },
    playerSoldierRoundDatas = {{
        soldierName = "swordsman_1",
        morale = 100,
        soldierCount = 100,
        soldierWoundedCount = 2,
        soldierStar = 1,
        isWin = true,
        soldierDamagedCount = 2,
        moraleDecreased = 2
    }, {
        soldierName = "swordsman_1",
        morale = 98,
        soldierCount = 98,
        soldierWoundedCount = 2,
        soldierStar = 1,
        isWin = true,
        soldierDamagedCount = 2,
        moraleDecreased = 32
    }, {
        soldierName = "swordsman_1",
        morale = 66,
        soldierCount = 96,
        soldierWoundedCount = 1,
        soldierStar = 1,
        isWin = true,
        soldierDamagedCount = 1,
        moraleDecreased = 66
    }, {
        soldierName = "ranger_1",
        morale = 100,
        soldierCount = 100,
        soldierWoundedCount = 1,
        soldierStar = 1,
        isWin = true,
        soldierDamagedCount = 1,
        moraleDecreased = 1
    }},
    sectionSoldierRoundDatas = {{
        soldierName = "lancer_1",
        morale = 5,
        soldierCount = 5,
        soldierWoundedCount = 0,
        soldierStar = 1,
        isWin = false,
        soldierDamagedCount = 3,
        moraleDecreased = 3
    }, {
        soldierName = "ranger_1",
        morale = 8,
        soldierCount = 8,
        soldierWoundedCount = 0,
        soldierStar = 1,
        isWin = false,
        soldierDamagedCount = 5,
        moraleDecreased = 5
    }, {
        soldierName = "catapult_1",
        morale = 2,
        soldierCount = 2,
        soldierWoundedCount = 0,
        soldierStar = 1,
        isWin = false,
        soldierDamagedCount = 2,
        moraleDecreased = 2
    }, {
        soldierName = "swordsman_1",
        morale = 3,
        soldierCount = 3,
        soldierWoundedCount = 0,
        soldierStar = 1,
        isWin = false,
        soldierDamagedCount = 2,
        moraleDecreased = 2
    }}
}


local fightReport2 = {
    playerDragonFightData = {
        type = "greenDragon",
        hpMax = 116,
        hp = 116,
        isWin = true,
        hpDecreased = 15
    },
    sectionDragonFightData = {
        type = "blueDragon",
        hpMax = 116,
        hp = 116,
        isWin = false,
        hpDecreased = 22
    },
    playerSoldierRoundDatas = {{
        soldierName = "swordsman_1",
        morale = 100,
        soldierCount = 100,
        soldierWoundedCount = 2,
        soldierStar = 1,
        isWin = true,
        soldierDamagedCount = 2,
        moraleDecreased = 2
    }, {
        soldierName = "swordsman_1",
        morale = 98,
        soldierCount = 98,
        soldierWoundedCount = 1,
        soldierStar = 1,
        isWin = true,
        soldierDamagedCount = 1,
        moraleDecreased = 16
    }, {
        soldierName = "swordsman_1",
        morale = 82,
        soldierCount = 97,
        soldierWoundedCount = 2,
        soldierStar = 1,
        isWin = true,
        soldierDamagedCount = 2,
        moraleDecreased = 82
    }, {
        soldierName = "ranger_1",
        morale = 100,
        soldierCount = 100,
        soldierWoundedCount = 1,
        soldierStar = 1,
        isWin = true,
        soldierDamagedCount = 1,
        moraleDecreased = 1
    }},
    sectionSoldierRoundDatas = {{
        soldierName = "catapult_1",
        morale = 7,
        soldierCount = 7,
        soldierWoundedCount = 0,
        soldierStar = 1,
        isWin = false,
        soldierDamagedCount = 2,
        moraleDecreased = 2
    }, {
        soldierName = "swordsman_1",
        morale = 11,
        soldierCount = 11,
        soldierWoundedCount = 0,
        soldierStar = 1,
        isWin = false,
        soldierDamagedCount = 3,
        moraleDecreased = 3
    }, {
        soldierName = "lancer_1",
        morale = 4,
        soldierCount = 4,
        soldierWoundedCount = 0,
        soldierStar = 1,
        isWin = false,
        soldierDamagedCount = 3,
        moraleDecreased = 3
    }, {
        soldierName = "ranger_1",
        morale = 4,
        soldierCount = 4,
        soldierWoundedCount = 0,
        soldierStar = 1,
        isWin = false,
        soldierDamagedCount = 4,
        moraleDecreased = 4
    }}
}


local fightReport3 = {
    playerDragonFightData = {
        type = "greenDragon",
        hpMax = 276,
        hp = 213,
        isWin = true,
        hpDecreased = 15
    },
    sectionDragonFightData = {
        type = "blueDragon",
        hpMax = 116,
        hp = 116,
        isWin = false,
        hpDecreased = 22
    },
    playerSoldierRoundDatas = {{
        soldierName = "swordsman_1",
        morale = 100,
        soldierCount = 100,
        soldierWoundedCount = 7,
        soldierStar = 1,
        isWin = false,
        soldierDamagedCount = 7,
        moraleDecreased = 7
    }, {
        soldierName = "swordsman_1",
        morale = 93,
        soldierCount = 93,
        soldierWoundedCount = 2,
        soldierStar = 1,
        isWin = true,
        soldierDamagedCount = 2,
        moraleDecreased = 32
    }, {
        soldierName = "swordsman_1",
        morale = 61,
        soldierCount = 91,
        soldierWoundedCount = 2,
        soldierStar = 1,
        isWin = true,
        soldierDamagedCount = 2,
        moraleDecreased = 61
    }, {
        soldierName = "ranger_1",
        morale = 100,
        soldierCount = 100,
        soldierWoundedCount = 2,
        soldierStar = 1,
        isWin = true,
        soldierDamagedCount = 2,
        moraleDecreased = 2
    }},
    sectionSoldierRoundDatas = {{
        soldierName = "skeletonArcher",
        morale = 8,
        soldierCount = 8,
        soldierWoundedCount = 0,
        soldierStar = 3,
        isWin = true,
        soldierDamagedCount = 1,
        moraleDecreased = 3
    }, {
        soldierName = "meatWagon",
        morale = 3,
        soldierCount = 3,
        soldierWoundedCount = 0,
        soldierStar = 3,
        isWin = false,
        soldierDamagedCount = 1,
        moraleDecreased = 1
    }, {
        soldierName = "skeletonWarrior",
        morale = 4,
        soldierCount = 4,
        soldierWoundedCount = 0,
        soldierStar = 3,
        isWin = false,
        soldierDamagedCount = 1,
        moraleDecreased = 1
    }, {
        soldierName = "deathKnight",
        morale = 1,
        soldierCount = 1,
        soldierWoundedCount = 0,
        soldierStar = 3,
        isWin = false,
        soldierDamagedCount = 1,
        moraleDecreased = 1
    }}
}

--
function GameUIPveAttackFte:Find()
    return self.attack
end
function GameUIPveAttackFte:PormiseOfFte()
    local r = self:Find():getCascadeBoundingBox()
    self:GetFteLayer():SetTouchObject(self:Find())

    WidgetFteArrow.new(_("点击进攻")):addTo(self:GetFteLayer())
        :TurnUp():align(display.TOP_CENTER, r.x + r.width/2, r.y - 10)

    self:Find():removeEventListenersByEvent("CLICKED_EVENT")
    self:Find():onButtonClicked(function()
        local soldiers = string.split(sections[self.pve_name].troops, ",")
        table.remove(soldiers, 1)
        UIKit:newGameUI('GameUIPVEFteSendTroop',
            LuaUtils:table_map(soldiers, function(k,v)
                local name,star = unpack(string.split(v, ":"))
                return k, {name = name, star = tonumber(star)}
            end),
            function(dragonType, soldiers)
                local dragon = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager():GetDragon(dragonType)
                local param = {
                    dragonType = dragon:Type(),
                    old_exp = dragon:Exp(),
                    new_exp = dragon:Exp(),
                    old_level = dragon:Level(),
                    new_level = dragon:Level(),
                    reward = {},
                }


                local report
                if self.pve_name == "1_1" then
                    report = fightReport1
                    param.reward = {{type = "resources", name = "food", count = 1}}
                elseif self.pve_name == "1_2" then
                    report = fightReport2
                    param.reward = {{type = "resources", name = "wood", count = 1}}
                elseif self.pve_name == "1_3" then
                    report = fightReport3
                    param.reward = {{type = "soldierMaterials", name = "deathHand", count = 2}}
                end
                mockData.FightWithNpc(self.pve_name)
                display.getRunningScene():GetSceneLayer():RefreshPve()
                report.playerDragonFightData.type = dragonType
                -- UIKit:newGameUI("GameUIReplayNew", self:DecodeReport(report, dragon, soldiers), function()
                --     self:performWithDelay(function()
                --         self:LeftButtonClicked()
                --         display.getRunningScene():GetSceneLayer():MoveAirship(true)
                --     end, 0)
                -- end):AddToCurrentScene(true)

                local dragon = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager():GetDragon(dragonType)
                param.new_exp = dragon:Exp()
                param.new_level = dragon:Level()
                param.star = 3
                param.callback = function()
                    display.getRunningScene():GetSceneLayer():MoveAirship(true)
                end
                local is_show = false
                UIKit:newGameUI(self.pve_name == "1_1" and "GameUIReplayFte" or "GameUIReplayNew", self:DecodeReport(report, dragon, soldiers), function()
                    if not is_show then
                        is_show = true
                        UIKit:newGameUI("GameUIPveSummary", param):AddToCurrentScene(true)
                        self:performWithDelay(function() self:LeftButtonClicked() end, 0)
                    end
                end, function(replayui)
                    replayui:LeftButtonClicked()
                    if not is_show then
                        is_show = true
                        UIKit:newGameUI("GameUIPveSummary", param):AddToCurrentScene(true)
                        self:performWithDelay(function() self:LeftButtonClicked() end, 0)
                    end
                end):AddToCurrentScene(true)

            end):AddToCurrentScene(true)
    end)

    return UIKit:PromiseOfOpen("GameUIPVEFteSendTroop")
        :next(function(ui)
            self:GetFteLayer():removeFromParent()
            return ui:PormiseOfFte(self.pve_name == "1_1")
        end):next(function()
        return UIKit:PromiseOfClose("GameUIPveAttackFte")
        end):next(function()
            return UIKit:PromiseOfClose("GameUIPveSummary")
        end)
end
return GameUIPveAttackFte










