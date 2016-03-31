local GameUIPveAttack = import(".GameUIPveAttack")
local GameUIPveAttackFte = class("GameUIPveAttackFte", GameUIPveAttack)
local mockData = import("..fte.mockData")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
local sections = GameDatas.PvE.sections
function GameUIPveAttackFte:ctor(...)
    GameUIPveAttackFte.super.ctor(self, ...)
    self:DisableAutoClose()
end
local function get_dragon_type()
    for k,v in pairs(DataManager:getUserData().dragons) do
        if v.star > 0 then
            return k
        end
    end
    assert(false)
end

local attackDragonSkilled1
if get_dragon_type() == "redDragon" then
    attackDragonSkilled1 = {0}
elseif get_dragon_type() == "blueDragon" then
    attackDragonSkilled1 = {0}
elseif get_dragon_type() == "greenDragon" then
    attackDragonSkilled1 = {0}
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
    ["roundDatas"] = {
                [1] = {
                    ["attackResults"] = {
                        [1] = {
                            ["soldierName"] = "swordsman_1",
                            ["soldierWoundedCount"] = 1,
                            ["soldierStar"] = 1,
                            ["isWin"] = true,
                            ["soldierDamagedCount"] = 1,
                            ["soldierCount"] = 33,
                        }
,
                    }
,
                    ["defenceResults"] = {
                        [1] = {
                            ["soldierName"] = "swordsman_1",
                            ["soldierWoundedCount"] = 0,
                            ["soldierStar"] = 1,
                            ["isWin"] = false,
                            ["soldierDamagedCount"] = 2,
                            ["soldierCount"] = 5,
                        }
,
                    }
,
                    attackDragonSkilled = attackDragonSkilled1,
                    defenceDragonSkilled = {}
,
                }
,
            }
}


local attackDragonSkilled2
if get_dragon_type() == "redDragon" then
    attackDragonSkilled2 = {0}
elseif get_dragon_type() == "blueDragon" then
    attackDragonSkilled2 = {0,1,0}
elseif get_dragon_type() == "greenDragon" then
    attackDragonSkilled2 = {0,1}
end

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
    ["roundDatas"] = {
                [1] = {
                    ["attackResults"] = {
                        [1] = {
                            ["soldierName"] = "swordsman_1",
                            ["soldierWoundedCount"] = 1,
                            ["soldierStar"] = 1,
                            ["isWin"] = true,
                            ["soldierDamagedCount"] = 1,
                            ["soldierCount"] = 33,
                        }
,
                        [2] = {
                            ["soldierName"] = "swordsman_1",
                            ["soldierWoundedCount"] = 2,
                            ["soldierStar"] = 1,
                            ["isWin"] = true,
                            ["soldierDamagedCount"] = 2,
                            ["soldierCount"] = 33,
                        }
,
                    }
,
                    ["defenceResults"] = {
                        [1] = {
                            ["soldierName"] = "swordsman_1",
                            ["soldierWoundedCount"] = 0,
                            ["soldierStar"] = 1,
                            ["isWin"] = false,
                            ["soldierDamagedCount"] = 2,
                            ["soldierCount"] = 8,
                        }
,
                        [2] = {
                            ["soldierName"] = "ranger_1",
                            ["soldierWoundedCount"] = 0,
                            ["soldierStar"] = 1,
                            ["isWin"] = false,
                            ["soldierDamagedCount"] = 3,
                            ["soldierCount"] = 8,
                        }
,
                    }
,
                    attackDragonSkilled = attackDragonSkilled2,
                    defenceDragonSkilled = {},
                }
,
            }
}

local attackDragonSkilled3
if get_dragon_type() == "redDragon" then
    attackDragonSkilled3 = {0}
elseif get_dragon_type() == "blueDragon" then
    attackDragonSkilled3 = {0,0,0}
elseif get_dragon_type() == "greenDragon" then
    attackDragonSkilled3 = {0}
end
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
    ["roundDatas"] = {
                [1] = {
                    ["attackResults"] = {
                        [1] = {
                            ["soldierName"] = "swordsman_1",
                            ["soldierWoundedCount"] = 2,
                            ["soldierStar"] = 1,
                            ["isWin"] = true,
                            ["soldierDamagedCount"] = 2,
                            ["soldierCount"] = 33,
                        }
,
                    }
,
                    ["defenceResults"] = {
                        [1] = {
                            ["soldierName"] = "skeletonWarrior",
                            ["soldierWoundedCount"] = 0,
                            ["soldierStar"] = 3,
                            ["isWin"] = false,
                            ["soldierDamagedCount"] = 1,
                            ["soldierCount"] = 4,
                        }
,
                    }
,
                    attackDragonSkilled = attackDragonSkilled3,
                    defenceDragonSkilled = {},
                }
,
            }
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
        local enemies = string.split(sections[self.pve_name].troops, ",")
        table.remove(enemies, 1)
        UIKit:newGameUI('GameUISendTroopNew',
            function(dragonType, soldiers)
                local dragon = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager():GetDragon(dragonType)
                local dragonParam = {
                    dragonType = dragon:Type(),
                    old_exp = dragon:Exp(),
                    new_exp = dragon:Exp(),
                    old_level = dragon:Level(),
                    new_level = dragon:Level(),
                    reward = {},
                }

                local fightReport
                if self.pve_name == "1_1" then
                    fightReport = fightReport1
                    dragonParam.reward = {{type = "resources", name = "food", count = 1}}
                elseif self.pve_name == "1_2" then
                    fightReport = fightReport2
                    dragonParam.reward = {{type = "resources", name = "wood", count = 1}}
                elseif self.pve_name == "1_3" then
                    fightReport = fightReport3
                    dragonParam.reward = {{type = "soldierMaterials", name = "deathHand", count = 2}}
                end
                mockData.FightWithNpc(self.pve_name)
                display.getRunningScene():GetSceneLayer():RefreshPve()
                fightReport.playerDragonFightData.type = dragonType

                local report = self:DecodeReport(fightReport, dragon, soldiers)
                local dragon = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager():GetDragon(dragonType)
                dragonParam.new_exp = dragon:Exp()
                dragonParam.new_level = dragon:Level()
                dragonParam.star = 3
                dragonParam.callback = function()
                    display.getRunningScene():GetSceneLayer():MoveAirship(true)
                end

                local is_show = false
                UIKit:newGameUI(self.pve_name == "1_1" and "GameUIReplayFte" or "GameUIReplay", report, function()
                    if not is_show then
                        is_show = true
                        UIKit:newGameUI("GameUIPveSummary", dragonParam):AddToCurrentScene(true)
                        self:performWithDelay(function() self:LeftButtonClicked() end, 0)
                    end
                end, function(replayui)
                    replayui:LeftButtonClicked()
                    if not is_show then
                        is_show = true
                        UIKit:newGameUI("GameUIPveSummary", dragonParam):AddToCurrentScene(true)
                        self:performWithDelay(function() self:LeftButtonClicked() end, 0)
                    end
                end):AddToCurrentScene(true)

            end, {isPVE = true}):AddToCurrentScene(true)
    end)

    return UIKit:PromiseOfOpen("GameUISendTroopNew")
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










