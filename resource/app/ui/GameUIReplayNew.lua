local UILib = import("..ui.UILib")
local Localize = import("..utils.Localize")
local window = import("..utils.window")
local promise = import("..utils.promise")
local cocos_promise = import("..utils.cocos_promise")
local BattleObject = import(".BattleObject")
local Wall = import(".Wall")
local Corps = import(".Corps")
local UILib = import(".UILib")
local WidgetSoldier = import("..widget.WidgetSoldier")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local UIListView = import("..ui.UIListView")
local Enum = import("..utils.Enum")
local GameUIReplayNew = UIKit:createUIClass('GameUIReplayNew')
local timer = app.timer
local tags = Enum("SPEED_TAG", "SPEED_TAG1", "SPEED_TAG2", "LEFT_TAG1", "RIGHT_TAG1")
local SPEED_TAG  = tags.SPEED_TAG
local SPEED_TAG1 = tags.SPEED_TAG1
local SPEED_TAG2 = tags.SPEED_TAG2
local LEFT_TAG1  = tags.LEFT_TAG1
local RIGHT_TAG1 = tags.RIGHT_TAG1


local function iter(a, i)
    local v1 = a[i]
    i = i + 1
    local v2 = a[i]
    if v2 then
        return i, v1, v2
    end
end

local function tuple_ipairs(a)
    return iter, a, 0
end


local function decode_battle_from_report(report)
    local attacks = clone(report:GetFightAttackSoldierRoundData())
    local defends = clone(report:GetFightDefenceSoldierRoundData())
    if report:IsFightWall() then
        assert(report.GetFightAttackWallRoundData)
        assert(report.GetFightDefenceWallRoundData)
        for i,v in ipairs(clone(report:GetFightAttackWallRoundData())) do
            attacks[#attacks + 1] = v
        end
        for i,v in ipairs(clone(report:GetFightDefenceWallRoundData())) do
            defends[#defends + 1] = v
        end
    end
    local battle = {}
    local defeat
    for i = 1, #attacks do
        local attacker = attacks[i]
        local defender = defends[i]
        attacker.soldierName = attacker.soldierName or "wall"
        defender.soldierName = defender.soldierName or "wall"
        local defeatAll
        if attacker.soldierName ~= "wall" and defender.soldierName ~= "wall" --[[and #attacks ~= i]] then
            defeatAll = (((attacker.morale - attacker.moraleDecreased) <= 0
                or (attacker.soldierCount - attacker.soldierDamagedCount) <= 0) or not attacker.isWin)
                and (((defender.morale - defender.moraleDecreased) <= 0
                or (defender.soldierCount - defender.soldierDamagedCount) <= 0) or not defender.isWin)
        end
        local left
        local right
        if defeat == "right" then
            left = {
                damage = attacker.soldierDamagedCount or attacker.wallDamagedHp,
                decrease = attacker.moraleDecreased or 0,
            }
        else
            left = {
                soldier = attacker.soldierName,
                star = attacker.soldierStar,
                count = attacker.soldierCount or attacker.wallHp,
                damage = attacker.soldierDamagedCount or attacker.wallDamagedHp,
                morale = attacker.morale or 100,
                decrease = attacker.moraleDecreased or 0,
            }
        end
        if defeat == "left" then
            right = {
                damage = defender.soldierDamagedCount or defender.wallDamagedHp,
                decrease = defender.moraleDecreased or 0,
            }
        else
            right = {
                soldier = defender.soldierName,
                star = defender.soldierStar,
                count = defender.soldierCount or defender.wallHp,
                damage = defender.soldierDamagedCount or defender.wallDamagedHp,
                morale = defender.morale or 100,
                decrease = defender.moraleDecreased or 0,
            }
        end
        defeat = attacker.isWin and "right" or "left"
        if attacker.isWin then
            right.decrease = defender.morale
        else
            left.decrease = attacker.morale
        end
        table.insert(battle, {left = left, right = right, defeat = defeat, defeatAll = defeatAll})
        if defeatAll then
            defeat = nil
        end
    end
    return battle
end
local function decode_battle(raw)
    local rounds = {}
    local left_soldier, right_soldier
    for i, dual in ipairs(raw) do
        local r = {}
        local left, right = dual.left, dual.right
        left_soldier = left.soldier or left_soldier
        right_soldier = right.soldier or right_soldier
        if left.soldier and right.soldier then
            table.insert(r, {
                {soldier = left.soldier, star = left.star, state = "enter", count = left.count, morale = left.morale},
                {soldier = right.soldier, star = right.star, state = "enter", count = right.count, morale = right.morale}
            })
        elseif left.soldier then
            local soldier = left.soldier
            local count = left.count
            local morale = left.morale
            local star = left.star
            if soldier == "wall" then
                table.insert(r, {
                    {soldier = soldier, state = "enter", count = count, morale = morale}, {state = "move"}
                })
                table.insert(r, {{state = "defend"}, {state = "breath"}})
            else
                table.insert(r, {
                    {soldier = soldier, star = star, state = "enter", count = count, morale = morale}, {state = "defend"}
                })
            end
        elseif right.soldier then
            local soldier = right.soldier
            local count = right.count
            local morale = right.morale
            local star = right.star
            if soldier == "wall" then
                table.insert(r, {
                    {state = "move"}, {soldier = soldier, state = "enter", count = count, morale = morale}
                })
                table.insert(r, {{state = "breath"}, {state = "defend"}})
            else
                table.insert(r, {
                    {state = "defend"}, {soldier = soldier, star = star, state = "enter", count = count, morale = morale}
                })
            end
        else
            assert(false)
        end
        if dual.defeat == "left" then
            table.insert(r, {{state = "attack", effect = left_soldier}, {state = "defend"}})
            table.insert(r, {{state = "defend"}, {state = "hurt", damage = right.damage, decrease = right.decrease}})
            table.insert(r, {{state = "defend"}, {state = "attack", effect = right_soldier}})
            table.insert(r, {{state = "hurt", damage = left.damage, decrease = left.decrease}, {state = "defend"}})
            if dual.defeatAll == true then
                table.insert(r, {{state = "defeat"}, {state = "defeat"}})
            else
                table.insert(r, {{state = "defeat"}, {state = "defend"}})
            end
        elseif dual.defeat == "right" then
            table.insert(r, {{state = "defend"}, {state = "attack", effect = right_soldier}})
            table.insert(r, {{state = "hurt", damage = left.damage, decrease = left.decrease}, {state = "defend"}})
            table.insert(r, {{state = "attack", effect = left_soldier}, {state = "defend"}})
            table.insert(r, {{state = "defend"}, {state = "hurt", damage = right.damage, decrease = right.decrease}})
            if dual.defeatAll == true then
                table.insert(r, {{state = "defeat"}, {state = "defeat"}})
            else
                table.insert(r, {{state = "defend"}, {state = "defeat"}})
            end
        else
            assert(false)
        end
        table.insert(rounds, r)
    end
    return rounds
end







local soldier_arrange = {
    swordsman = {row = 4, col = 2},
    sentinel = {row = 4, col = 2},
    skeletonWarrior = {row = 4, col = 2},

    ranger = {row = 4, col = 2},
    crossbowman = {row = 4, col = 2},
    skeletonArcher = {row = 4, col = 2},

    lancer = {row = 3, col = 1},
    horseArcher = {row = 3, col = 1},
    deathKnight = {row = 3, col = 1},

    catapult = {row = 2, col = 1},
    ballista = {row = 2, col = 1},
    meatWagon = {row = 2, col = 1},
}
local function NewCorps(replay_ui, soldier, star, is_pve_soldier)
    local arrange = soldier_arrange[soldier]
    return Corps.new(soldier, star, arrange.row, arrange.col, nil, nil, is_pve_soldier, replay_ui)
end

local function NewWall(replay_ui)
    return Wall.new(replay_ui)
end


local dragon_ani_map = {
    redDragon   = {   "red_long",  90, 0, 0.6, 60},
    blueDragon  = {  "blue_long", 100, 0, 0.6, 60},
    greenDragon = { "green_long", 100, 0, 0.6, 60},
    blackDragon = {    "heilong", 100,60, 0.8, 50},
}
local function newDragon(replay_ui, dragon_type, level)
    local dragon_type = dragon_type or "redDragon"
    local node = display.newNode()

    node.level = UIKit:ttfLabel({
        text = level,
        size = 20,
        color = 0xffedae,
        shadow = true,
    }):align(display.CENTER, -65, 180):addTo(node)

    node.name = UIKit:ttfLabel({
        text = Localize.dragon[dragon_type],
        size = 20,
        color = 0xffedae,
        shadow = true,
    }):align(display.CENTER, 80, 180):addTo(node)

    node.progress = display.newProgressTimer("progress_bar_dragon_hp.png", display.PROGRESS_TIMER_BAR)
        :addTo(node):align(display.LEFT_CENTER, -85, 145)
    node.progress:setBarChangeRate(cc.p(1,0))
    node.progress:setMidpoint(cc.p(0,0))
    -- node.progress:setPercentage(80)

    node.hp = UIKit:ttfLabel({
        size = 15,
        color = 0xffedae,
        shadow = true,
    }):align(display.CENTER, 45, 145):addTo(node):hide()

    node.result = UIKit:ttfLabel({
        size = 20,
        color = 0x00be36,
        shadow = true,
    }):align(display.CENTER, 120, -55):addTo(node,1):hide()

    node.buff = UIKit:ttfLabel({
        size = 20,
        color = 0x00be36,
        shadow = true,
    }):align(display.CENTER, 65, -55):addTo(node,1):hide()

    local ani_name, left_x, right_x, scale, Y = unpack(dragon_ani_map[dragon_type])
    local dragon = ccs.Armature:create(ani_name):scale(0.6)
        :addTo(node):align(display.CENTER, left_x, Y)
    dragon:getAnimation():play("idle", -1, -1)
    dragon:setScale(scale, scale)
    function node:TurnLeft()
        self.name:pos(15, 180)
        self.level:pos(150, 180)
        self.hp:pos(45, 147)
        self.progress:setScaleX(-1)
        self.progress:pos(170, 147)
        self.result:setPositionX(-35)
        self.buff:setPositionX(35)
        dragon:setPositionX(right_x)
        dragon:setScale(- scale, scale)
        return self
    end
    function node:SetHp(cur, total)
        self.hp:show():setString(string.format("%d/%d", math.floor(cur), math.floor(total)))
        self.progress:setPercentage(cur / total * 100)
        return self
    end
    function node:SetReulst(is_win)
        local color = is_win and UIKit:hex2c3b(0x00be36) or UIKit:hex2c3b(0xff0000)
        self.result:setColor(color)
        self.buff:setColor(color)
        self.result:setString(is_win and _("获胜") or _("失败"))
        return self
    end
    function node:ShowIsWin(is_win)
        local p = promise.new()
        self:SetReulst(is_win)
        self.result:scale(3):show()
        local speed = cc.Speed:create(transition.sequence({
            cc.ScaleTo:create(0.15, 1),
            cc.CallFunc:create(function()p:resolve()end),
        }), replay_ui:Speed())
        speed:setTag(SPEED_TAG)
        self.result:runAction(speed)
        return p
    end
    function node:SetBuff(buff)
        self.buff:setString(buff)
        return self
    end
    function node:ShowBuff(is_win)
        self:SetReulst(is_win)
        self.buff:show()
        return self
    end
    function node:RefreshSpeed()
        local a = self.result:getActionByTag(SPEED_TAG)
        if a then
            a:setSpeed(replay_ui:Speed())
        end
    end
    return node
end
local function newDragonBattle(replay_ui, dragonAttack, dragonAttackLevel, dragonDefence, dragonDefenceLevel)
    local dragon_battle = ccs.Armature:create("paizi")
    dragon_battle.result = ccs.Armature:create("paizi"):addTo(dragon_battle, 100):hide()

    local left_bone = dragon_battle:getBone("Layer4")
    local left_dragon = newDragon(replay_ui, dragonAttack.type, dragonAttackLevel):addTo(left_bone):pos(-360, -50)
    left_bone:addDisplay(left_dragon, 0)
    left_bone:changeDisplayWithIndex(0, true)

    local right_bone = dragon_battle:getBone("Layer5")
    local right_dragon = newDragon(replay_ui, dragonDefence.type, dragonDefenceLevel):TurnLeft():addTo(right_bone):pos(238, -82)
    right_bone:addDisplay(right_dragon, 0)
    right_bone:changeDisplayWithIndex(0, true)
    function dragon_battle:GetAttackDragon()
        return left_dragon
    end
    function dragon_battle:GetDefenceDragon()
        return right_dragon
    end
    function dragon_battle:PromiseOfAnimation(animation)
        local p = promise.new()
        animation:setMovementEventCallFunc(function(armatureBack, movementType, movementID)
            if movementType == ccs.MovementEventType.complete then
                p:resolve()
            end
        end)
        return p
    end
    function dragon_battle:PromsieOfFight()
        self:getAnimation():play("Animation1", -1, 0)
        app:GetAudioManager():PlayeEffectSoundWithKey("BATTLE_DRAGON")
        self:RefreshSpeed()
        return self:PromiseOfAnimation(self:getAnimation())
    end
    function dragon_battle:PromsieOfHide()
        self:getAnimation():play("Animation2", -1, 0)
        self:RefreshSpeed()
        return self:PromiseOfAnimation(self:getAnimation()):next(function()
            self:hide()
        end)
    end
    function dragon_battle:RefreshSpeed()
        self:getAnimation():setSpeedScale(replay_ui:Speed())
        self.result:getAnimation():setSpeedScale(replay_ui:Speed())
        left_dragon:RefreshSpeed()
        right_dragon:RefreshSpeed()
        return self
    end
    function dragon_battle:Stop()
        self:getAnimation():stop()
        self.result:getAnimation():stop()
        left_dragon:stopAllActions()
        right_dragon:stopAllActions()
    end
    function dragon_battle:PromiseOfVictory()
        self.result:show():getAnimation():playWithIndex(2, -1, 0)
        self:RefreshSpeed()
        return self:PromiseOfAnimation(self.result:getAnimation())
    end
    function dragon_battle:PromiseOfDefeat()
        self.result:show():getAnimation():playWithIndex(3, -1, 0)
        self:RefreshSpeed()
        return self:PromiseOfAnimation(self.result:getAnimation())
    end
    function dragon_battle:PromiseOfVictoryHide()
        self.result:show():getAnimation():playWithIndex(4, -1, 0)
        self:RefreshSpeed()
        return self:PromiseOfAnimation(self.result:getAnimation())
    end
    function dragon_battle:PromiseOfDefeatHide()
        self.result:show():getAnimation():playWithIndex(5, -1, 0)
        self:RefreshSpeed()
        return self:PromiseOfAnimation(self.result:getAnimation())
    end
    return dragon_battle
end

local function newSoldierInBattle(list_view, is_left)
    local content = display.newSprite("back_ground_284x128.png")
    local s1 = content:getContentSize()
    local title_png = is_left and "soldier_title_attack.png" or "soldier_title_defence.png"
    local title = display.newSprite(title_png):addTo(content):pos(s1.width/2, s1.height - 16)

    local name = UIKit:ttfLabel({
        color = 0xffedae,
        size = 20,
        shadow = true,
    }):addTo(title):align(display.CENTER, s1.width/2, 13)

    local soldier = WidgetSoldier.new("ranger", 1, false):addTo(content):pos(50, 50):scale(88/128)
    display.newScale9Sprite("back_ground_166x84.png",190 , 50,cc.size(178,90),cc.rect(15,10,136,64)):addTo(content)

    local type_ = UIKit:ttfLabel({
        color = 0x403c2f,
        size = 20,
    -- shadow = true,
    }):addTo(content):align(display.LEFT_CENTER, s1.width/2 - 25, 75)

    local status = UIKit:ttfLabel({
        color = 0x007c23,
        size = 22,
    -- shadow = true,
    }):addTo(content):align(display.LEFT_CENTER, s1.width/2 - 25, 35)


    local left, right = is_left and 5 or 0, is_left and 0 or 5
    local item = list_view:newItem()
    item:setMargin({left = left, right = right, top = 0, bottom = 5})
    item:addContent(content)
    item:setItemSize(s1.width, s1.height)


    function item:SetSoldierInfo(soldier_name, star, is_pve_soldier)
        soldier:SetSoldeir(soldier_name, star, is_pve_soldier)
        name:setString(Localize.soldier_name[soldier_name])
        type_:setString(Localize.getSoldierCategoryByName(soldier_name))
        return self
    end
    function item:SetStatus(stats)
        if stats == "waiting" then
            status:setColor(UIKit:hex2c3b(0x403c2f))
            soldier:SetEnable(true)
        elseif stats == "fighting" then
            status:setColor(UIKit:hex2c3b(0x007c23))
            soldier:SetEnable(true)
        elseif stats == "defeated" then
            status:setColor(UIKit:hex2c3b(0x7e0000))
            soldier:SetEnable(false)
        else
            assert(false, "没有状态!")
        end
        status:setString(Localize.soldier_status[stats])
        return self
    end

    return item
end

local report_ = {
    GetFightAttackName = function() return "hello" end,
    GetFightDefenceName = function() return "hello" end,
    IsDragonFight = function() return true end,
    GetAttackDragonLevel = function() return 1 end,
    GetDefenceDragonLevel = function() return 2 end,
    GetFightAttackDragonRoundData = function()
        return {
            type = "redDragon",
            hp = 1000,
            hpDecreased = 90,
            hpMax = 1000,
            isWin = true
        }
    end,
    GetFightDefenceDragonRoundData = function()
        return {
            type = "blackDragon",
            hp = 1000,
            hpDecreased = 90,
            hpMax = 1000,
            isWin = false
        }
    end,
    GetFightAttackSoldierRoundData = function()
        return {
            {
                soldierName = "ranger",
                soldierStar = 3,
                soldierCount = 1000,
                soldierDamagedCount = 20,
                morale = 100,
                moraleDecreased = 20,
                isWin = true,
            },
            {
                soldierName = "ranger",
                soldierStar = 1,
                soldierCount = 980,
                soldierDamagedCount = 20,
                morale = 80,
                moraleDecreased = 20,
                isWin = true,
            },
            {
                soldierName = "ranger",
                soldierStar = 1,
                soldierCount = 960,
                soldierDamagedCount = 20,
                morale = 60,
                moraleDecreased = 20,
                isWin = true,
            },
        }
    end,
    GetFightDefenceSoldierRoundData = function()
        return  {
            {
                soldierName = "ranger",
                soldierStar = 1,
                soldierCount = 100,
                soldierDamagedCount = 20,
                morale = 100,
                moraleDecreased = 20,
                isWin = false,
            },
            {
                soldierName = "swordsman",
                soldierStar = 1,
                soldierCount = 100,
                soldierDamagedCount = 20,
                morale = 100,
                moraleDecreased = 20,
                isWin = false,
            },
            {
                soldierName = "wall",
                soldierStar = 1,
                soldierCount = 100,
                soldierDamagedCount = 20,
                morale = 100,
                moraleDecreased = 0,
                isWin = false,
            },
        }
    end,
    GetOrderedAttackSoldiers = function()
        return {
            {
                name = "ranger",
                star = 3,
                count = 1000,
            },
        }
    end,
    GetOrderedDefenceSoldiers = function()
        return  {
            {
                name = "ranger",
                star = 3,
                count = 100,
            },
            {
                name = "swordsman",
                star = 2,
                count = 100,
            },
            {
                name = "wall",
                star = 1,
                count = 100,
            },
        }
    end,
    GetReportResult = function() return true end,
    IsFightWall = function() return false end,
    IsPveBattle = function() return false end,
    GetAttackTargetTerrain = function() return "iceField" end,
    IsAttackCamp = function() return true end,
}


-- local report1 = {
--     attackCity = {
--         attackTarget = {
--             terrain = "grassLand",
--             id = "41Bltvk5Y7",
--             name = "机器人1000_4",
--             location = {
--                 x = 11,
--                 y = 20
--             },
--             alliance = {
--                 id = "NJ9E-9tQ",
--                 name = "Hestia and Loki",
--                 tag = "HnL",
--                 flag = "8,1,7,19,5"
--             }
--         },
--         attackPlayerData = {
--             fightWithDefenceTroop = {
--                 dragon = {
--                     type = "redDragon",
--                     hpDecreased = 8,
--                     expAdd = 78,
--                     level = 2,
--                     hp = 76
--                 },
--                 soldiers = {{
--                     countDecreased = 20,
--                     name = "ranger",
--                     star = 1,
--                     count = 100
--                 }, {
--                     countDecreased = 0,
--                     name = "swordsman",
--                     star = 1,
--                     count = 96
--                 }},},
--             id = "Eki2AVF7",
--             name = "p_Vygo2ANt7",
--             icon = 4,
--             rewards = {{
--                 type = "resources",
--                 name = "blood",
--                 count = 48
--             }, {
--                 type = "resources",
--                 name = "coin",
--                 count = 6800
--             }, {
--                 type = "resources",
--                 name = "wood",
--                 count = 1356
--             }, {
--                 type = "resources",
--                 name = "stone",
--                 count = 2365
--             }, {
--                 type = "resources",
--                 name = "iron",
--                 count = 2409
--             }, {
--                 type = "resources",
--                 name = "food",
--                 count = 1618
--             }, {
--                 type = "dragonMaterials",
--                 name = "runes_2",
--                 count = 1
--             }},
--             alliance = {
--                 id = "EJ55FtF7",
--                 name = "The Valiant Uranus",
--                 tag = "TVU",
--                 flag = "1,4,8,4,6"
--             },
--             fightWithDefenceWall = {
--                 soldiers = {{
--                     countDecreased = 5,
--                     name = "swordsman",
--                     star = 1,
--                     count = 96
--                 }},}
--         },
--         defencePlayerData = {
--             id = "41Bltvk5Y7",
--             dragon = {
--                 type = "greenDragon",
--                 hpDecreased = 7,
--                 expAdd = 40,
--                 level = 3,
--                 hp = 63
--             },
--             name = "机器人1000_4",
--             icon = 3,
--             rewards = {{
--                 type = "resources",
--                 name = "blood",
--                 count = 35
--             }, {
--                 type = "resources",
--                 name = "coin",
--                 count = -6800
--             }, {
--                 type = "resources",
--                 name = "wood",
--                 count = -1356
--             }, {
--                 type = "resources",
--                 name = "stone",
--                 count = -2365
--             }, {
--                 type = "resources",
--                 name = "iron",
--                 count = -2409
--             }, {
--                 type = "resources",
--                 name = "food",
--                 count = -1618
--             }, {
--                 type = "dragonMaterials",
--                 name = "runes_1",
--                 count = 2
--             }},
--             alliance = {
--                 id = "NJ9E-9tQ",
--                 name = "Hestia and Loki",
--                 tag = "HnL",
--                 flag = "8,1,7,19,5"
--             },
--             soldiers = {{
--                 countDecreased = 29,
--                 name = "swordsman",
--                 star = 1,
--                 count = 57
--             }, {
--                 countDecreased = 10,
--                 name = "ranger",
--                 star = 1,
--                 count = 1
--             }},
--             wall = {
--                 hp = 68,
--                 hpDecreased = 43
--             }
--         },
--         fightWithDefencePlayerReports = {
--             attackPlayerSoldierRoundDatas = {{
--                 soldierName = "ranger",
--                 morale = 100,
--                 soldierCount = 100,
--                 soldierWoundedCount = 5,
--                 soldierStar = 1,
--                 isWin = true,
--                 soldierDamagedCount = 18,
--                 moraleDecreased = 18
--             }, {
--                 soldierName = "ranger",
--                 morale = 82,
--                 soldierCount = 82,
--                 soldierWoundedCount = 0,
--                 soldierStar = 1,
--                 isWin = true,
--                 soldierDamagedCount = 2,
--                 moraleDecreased = 4
--             }},
--             attackPlayerDragonFightData = {
--                 type = "redDragon",
--                 hpMax = 76,
--                 hp = 76,
--                 isWin = false,
--                 hpDecreased = 8
--             },
--             defencePlayerWallRoundDatas = {{
--                 isWin = true,
--                 wallMaxHp = 124,
--                 wallHp = 68,
--                 wallDamagedHp = 43
--             }},
--             defencePlayerDragonFightData = {
--                 type = "greenDragon",
--                 hpMax = 88,
--                 hp = 63,
--                 isWin = true,
--                 hpDecreased = 7
--             },
--             defencePlayerSoldierRoundDatas = {{
--                 soldierName = "swordsman",
--                 morale = 100,
--                 soldierCount = 57,
--                 soldierWoundedCount = 8,
--                 soldierStar = 1,
--                 isWin = false,
--                 soldierDamagedCount = 29,
--                 moraleDecreased = 51
--             }, {
--                 soldierName = "ranger",
--                 morale = 100,
--                 soldierCount = 1,
--                 soldierWoundedCount = 3,
--                 soldierStar = 1,
--                 isWin = false,
--                 soldierDamagedCount = 10,
--                 moraleDecreased = 100
--             }},
--             attackPlayerWallRoundDatas = {{
--                 soldierName = "swordsman",
--                 soldierCount = 96,
--                 soldierWoundedCount = 1,
--                 soldierStar = 1,
--                 isWin = false,
--                 soldierDamagedCount = 5
--             }},}
--     },
--     isSaved = false,
--     type = "attackCity",
--     id = "E13NJstX",
--     index = 8,
--     isRead = true,
--     createTime = "1431351323688"
-- }

-- -- -------------------
-- local Report = import("..entity.Report")
-- User = {
--     Id = function() return 1 end
-- }
function GameUIReplayNew:ctor(report, callback, skipcallback)
    -- report = Report:DecodeFromJsonData(report1)
    assert(report.GetFightAttackName)
    assert(report.GetFightDefenceName)
    assert(report.IsDragonFight)
    assert(report.GetFightAttackDragonRoundData)
    assert(report.GetFightDefenceDragonRoundData)
    assert(report.GetFightAttackSoldierRoundData)
    assert(report.GetFightDefenceSoldierRoundData)
    assert(report.IsFightWall)
    assert(report.GetOrderedAttackSoldiers)
    assert(report.GetOrderedDefenceSoldiers)
    assert(report.GetReportResult)
    assert(report.GetAttackDragonLevel)
    assert(report.GetDefenceDragonLevel)
    assert(report.GetAttackTargetTerrain)
    if report:IsDragonFight() then
        assert(report.IsAttackCamp)
    end
    GameUIReplayNew.super.ctor(self)
    self.report = report
    local soldiers = self.report:GetOrderedDefenceSoldiers()
    if self.report:IsFightWall() then
        local count = self.report:GetFightDefenceWallRoundData()[1].wallMaxHp
        table.insert(soldiers, {name = "wall", star = 1, count = count})
    end
    self.defence_soldiers = soldiers

    self.callback = callback
    self.skipcallback = skipcallback

    for _,v in ipairs(self:GetPreloadImages()) do
        display.addSpriteFrames(DEBUG_GET_ANIMATION_PATH(v.list),DEBUG_GET_ANIMATION_PATH(v.image))
    end

    local manager = ccs.ArmatureDataManager:getInstance()
    manager:addArmatureFileInfo(DEBUG_GET_ANIMATION_PATH("animations/paizi.ExportJson"))
    UILib.loadPveAnimation()
    UILib.loadDragonAnimation()
    UILib.loadSolidersAnimation()
    UILib.loadUIAnimation()
    self.timer_node = display.newNode():addTo(self)
    self.round = 1
end
function GameUIReplayNew:OnMoveInStage()
    self.ui_map = self:BuildUI()
    self.ui_map.battle_background1:setTexture(string.format("back_ground_%s.png", self.report:GetAttackTargetTerrain()))
    self.ui_map.attackName:setString(self.report:GetFightAttackName())
    self.ui_map.defenceName:setString(self.report:GetFightDefenceName())

    for i,v in ipairs(self:GetOrderedAttackSoldiers()) do
        self.ui_map.list_view_attack:addItem(newSoldierInBattle(self.ui_map.list_view_attack, true))
    end
    self.ui_map.list_view_attack:reload()

    for i,v in ipairs(self:GetOrderedDefenceSoldiers()) do
        self.ui_map.list_view_defence:addItem(newSoldierInBattle(self.ui_map.list_view_defence))
    end
    self.ui_map.list_view_defence:reload()

    self.ui_map.speedup:onButtonClicked(function()
        if self.result then
            self:Replay()
        elseif not self.ui_map.speedup.speed then
            self.ui_map.speedup.speed = 2
            self.ui_map.speedup:setButtonLabelString(_("x2"))
            self:SpeedUp(2)
        elseif self.ui_map.speedup.speed == 2 then
            self.ui_map.speedup.speed = 4
            self.ui_map.speedup:setButtonLabelString(_("x4"))
            self:SpeedUp(4)
        elseif self.ui_map.speedup.speed == 4 then
            self.ui_map.speedup.speed = nil
            self.ui_map.speedup:setButtonLabelString(_("x1"))
            self:SpeedUp()
        end
    end)
    self.ui_map.close:onButtonClicked(function()
        self:LeftButtonClicked()
    end)
    self.ui_map.pass:onButtonClicked(function()
        self:ShowResult()
    end)
    self:Replay()

    GameUIReplayNew.super.OnMoveInStage(self)
end
function GameUIReplayNew:onExit()
    GameUIReplayNew.super.onExit(self)
    if type(self.callback) == "function" then
        self.callback(self)
    end
end
function GameUIReplayNew:GetOrderedAttackSoldiers()
    return self.report:GetOrderedAttackSoldiers()
end
function GameUIReplayNew:GetOrderedDefenceSoldiers()
    return self.defence_soldiers
end
function GameUIReplayNew:GetFightAttackSoldierByRound(round)
    local rounds1 = self.report:GetFightAttackSoldierRoundData()
    if rounds1[round] then return rounds1[round] end
    if self.report:IsFightWall() then
        return self.report:GetFightAttackWallRoundData()[round - #rounds1]
    end
    assert(false)
end
function GameUIReplayNew:GetFightDefenceSoldierByRound(round)
    local rounds1 = self.report:GetFightDefenceSoldierRoundData()
    if rounds1[round] then return rounds1[round] end
    if self.report:IsFightWall() then
        return self.report:GetFightDefenceWallRoundData()[round - #rounds1]
    end
    assert(false)
end
function GameUIReplayNew:RefreshSoldierListView(list_view, soldiers, is_pve_soldier)
    for i,v in ipairs(list_view.items_) do
        local cur = soldiers[i]
        local status = cur.status or "waiting"
        v:SetStatus(status):SetSoldierInfo(cur.name, cur.star, is_pve_soldier)
    end
end
function GameUIReplayNew:ShowResult()
    if self.skipcallback then
        self.skipcallback(self)
        return
    end
    if not self.result then
        self.result = ccs.Armature:create("win"):addTo(self, 10):align(display.CENTER, window.cx, window.cy + 250)
        if self.report:GetReportResult() then
            self.result:getAnimation():play("Victory", -1, 0)
            app:GetAudioManager():PlayeEffectSoundWithKey("BATTLE_VICTORY")
        else
            self.result:getAnimation():play("Defeat", -1, 0)
            app:GetAudioManager():PlayeEffectSoundWithKey("BATTLE_DEFEATED")
        end
    end
    self:Stop()
    self.ui_map.speedup:setButtonLabelString(_("回放"))
    self.ui_map.pass:hide()
    self.ui_map.close:show()
end
function GameUIReplayNew:ShowStrongOrWeak()
    local vs = DataUtils:GetVSFromSoldierName(self:TopSoldierLeft().name, self:TopSoldierRight().name)
    if vs == "strong" then
        self.ui_map.arrow_green:show():flipX(false)
    elseif vs == "weak" then
        self.ui_map.arrow_green:show():flipX(true)
    else
        self.ui_map.arrow_green:hide()
    end
end
function GameUIReplayNew:Replay()
    self:Reset()
    self:EnterSoldiersRight()
    self:EnterSoldiersLeft()
    if self.report:IsDragonFight() then
        self:PlayDragonBattle():next(function()
            return self:PlaySoldierBattle(decode_battle(decode_battle_from_report(self.report)))
        end):next(function()
            self:ShowResult()
        end):catch(function(err)
            dump(err:reason())
        end)
    else
        self:PlaySoldierBattle(decode_battle(decode_battle_from_report(self.report))):next(function()
            self:ShowResult()
        end):catch(function(err)
            dump(err:reason())
        end)
    end
end
function GameUIReplayNew:HasDragonBattle()
    return true
end
function GameUIReplayNew:PlayDragonBattle()
    local attack_dragon = self.report:GetFightAttackDragonRoundData()
    local attack_dragon_level = self.report:GetAttackDragonLevel()
    local defend_dragon = self.report:GetFightDefenceDragonRoundData()
    local defend_dragon_level = self.report:GetDefenceDragonLevel()

    dump(attack_dragon)

    self.dragon_battle = newDragonBattle(self, attack_dragon, attack_dragon_level, defend_dragon, defend_dragon_level)
        :addTo(self.ui_map.dragon_node):align(display.CENTER, 275, 155)
    self.dragon_battle:GetAttackDragon():SetHp(attack_dragon.hp, attack_dragon.hpMax)
    self.dragon_battle:GetDefenceDragon():SetHp(defend_dragon.hp, defend_dragon.hpMax)

    local is_win = (self.report:IsAttackCamp() and attack_dragon.isWin) or
        (not self.report:IsAttackCamp() and not attack_dragon.isWin)
    return self:PromiseOfDelay(0.5):next(function()
        return self.dragon_battle:PromsieOfFight():next(function()
                return self:OnHandle("dragonFight")
            end):next(function()
            return is_win and
                self.dragon_battle:PromiseOfVictory() or
                self.dragon_battle:PromiseOfDefeat()
        end):next(function()
            local buff_attack = attack_dragon.isWin and 100 or 50
            local buff_defence = attack_dragon.isWin and 50 or 100
            self.dragon_battle:GetAttackDragon():ShowBuff(attack_dragon.isWin)
            self.dragon_battle:GetDefenceDragon():ShowBuff(not attack_dragon.isWin)
            return self:PormiseOfSchedule(1, function(percent)
                self.dragon_battle:GetAttackDragon()
                    :SetHp(attack_dragon.hp - percent * attack_dragon.hpDecreased, attack_dragon.hpMax)
                    :SetBuff(string.format(_("加成 + %d%%"), math.floor(percent * buff_attack)))
                self.dragon_battle:GetDefenceDragon()
                    :SetHp(defend_dragon.hp - percent * defend_dragon.hpDecreased, defend_dragon.hpMax)
                    :SetBuff(string.format(_("加成 + %d%%"), math.floor(percent * buff_defence)))
            end)
        end):next(self:Delay(1)):next(function()
            return promise.all(is_win and
                self.dragon_battle:PromiseOfVictoryHide() or
                self.dragon_battle:PromiseOfDefeatHide(),
                self.dragon_battle:PromsieOfHide())
        end)
    end)
end
function GameUIReplayNew:PlaySoldierBattle(battle)
    local start_left, end_left, start_right, end_right, Y = -100, 100, 700, 500, 130
    local rounds = promise.new()
    for i, round in ipairs(battle) do
        rounds:next(function()
            local p
            for _, v in ipairs(round) do
                local left, right = unpack(v)
                local left_action = self:DecodeStateBySide(left, true)
                local right_action = self:DecodeStateBySide(right, false)
                if p then
                    p:next(function(result)
                        local left, right = unpack(result)
                        return promise.all(left_action:resolve(left), right_action:resolve(right))
                    end)
                else
                    p = promise.all(left_action:resolve(self.left), right_action:resolve(self.right))
                end
            end
            p:next(self:Delay(1.3)):next(function() self.round = self.round + 1 end)
            return p
        end)
    end
    return cocos_promise.defferPromise(rounds)
end
function GameUIReplayNew:DecodeStateBySide(side, is_left)
    local start_left, end_left, start_right, end_right, Y = -100, 100, 700, 500, 130
    local action
    local state = side.state
    local is_pve_battle = self.report.IsPveBattle
    if state == "enter" then
        if is_left then
            if side.soldier == "wall" then
                self.left = NewWall(self):addTo(self.ui_map.battle_node):pos(50, Y)
                action = promise.new():next(BattleObject:TurnRight()):next(function()
                    return promise.all(self:PromiseOfMoveBattleObj(self.left, 2, 90),
                        self:PromiseOfMoveBattleObj(self.ui_map.battle_background1, 2, 90))
                end):next(function()
                    return self.left
                end)
            else
                self.left = NewCorps(self, side.soldier, side.star)
                    :addTo(self.ui_map.battle_node):pos(start_left, Y)
                action = BattleObject:Do(function(corps)
                    return corps
                end):next(BattleObject:MoveTo(2, end_left, Y))
                    :next(BattleObject:BreathForever())
            end
            self:EnterSoldiersLeft()
        else
            if side.soldier == "wall" then
                self.right = NewWall(self):addTo(self.ui_map.battle_node):pos(650, Y)
                action = promise.new():next(BattleObject:TurnLeft()):next(function()
                    return promise.all(self:PromiseOfMoveBattleObj(self.right, 2, -90),
                        self:PromiseOfMoveBattleObj(self.ui_map.battle_background1, 2, -90))
                end):next(function()
                    return self.right
                end)
            else
                self.right = NewCorps(self, side.soldier, side.star, is_pve_battle):addTo(self.ui_map.battle_node):pos(start_right, Y)
                action = BattleObject:Do():next(BattleObject:TurnLeft())
                    :next(BattleObject:MoveTo(2, end_right, Y))
                    :next(BattleObject:BreathForever())
            end
            self:EnterSoldiersRight()
        end
    elseif state == "attack" then
        action = BattleObject:Do(BattleObject:AttackOnce()):next(function(corps)
            BattleObject:Do(BattleObject:BreathForever()):resolve(corps)
            return corps
        end)
    elseif state == "defend" then
        action = BattleObject:Do(BattleObject:Hold())
    elseif state == "breath" then
        action = BattleObject:Do(BattleObject:BreathForever())
    elseif state == "hurt" then
        action = BattleObject:Do():next(function(corps)
            if is_left then
                return promise.any(corps:hit(), self:HurtSoldierLeft(corps, side.decrease))
                    :next(function() return corps end)
            else
                return promise.any(corps:hit(), self:HurtSoldierRight(corps, side.decrease))
                    :next(function() return corps end)
            end
        end):next(function(corps)
            BattleObject:Do(BattleObject:BreathForever()):resolve(corps)
            return corps
        end)
    elseif state == "move" then
        action = BattleObject:Do(BattleObject:Move(2))
    elseif state == "defeat" then
        action = BattleObject:Do():next(BattleObject:Defeat()):next(function(corps)
            if corps == self.left then
                self.left = nil
                self:SoldierDefeatLeft()
            elseif corps == self.right then
                self.right = nil
                self:SoldierDefeatRight()
                corps:removeFromParent()
                return self:OnHandle("rightDefeat")
            end
            corps:removeFromParent()
            return corps
        end)
    else
        assert(false, "不支持这个动作!")
    end
    return action
end
function GameUIReplayNew:PromiseOfPlayDamage(count, x, y)
    local p = promise.new()
    local speed = cc.Speed:create(transition.sequence({
        cc.MoveBy:create(0.6, cc.p(0, 20)),
        cc.CallFunc:create(function() p:resolve() end),
        cc.RemoveSelf:create(),
    }), self:Speed())
    speed:setTag(SPEED_TAG)

    UIKit:ttfLabel({
        text = "-"..count,
        size = 30,
        color = 0xff0000,
        shadow = true,
    }):addTo(self.ui_map.damage_node)
        :align(display.CENTER, x, y):runAction(speed)
    return p
end
function GameUIReplayNew:HurtSoldierLeft(corps, decrease)
    local round = self:GetFightAttackSoldierByRound(self.round)
    local soldier = self:TopSoldierLeft()
    local soldierCount = round.soldierCount or round.wallHp
    local soldierDamagedCount = round.soldierDamagedCount or round.wallDamagedHp
    local morale = self.ui_map.soldier_morale_attack:GetPercent()
    local moraleDecreased
    if round.moraleDecreased then
        moraleDecreased = decrease / self.ui_map.soldier_count_attack.count * 100
    else
        moraleDecreased = morale
    end
    local x,y = corps:getPosition()
    return promise.all(
        self:PromiseOfPlayDamage(soldierDamagedCount, x, y),
        self.ui_map.soldier_count_attack:PromiseOfProgressTo(0.5, (soldierCount - soldierDamagedCount) / soldier.count * 100),
        self:PormiseOfSchedule(0.5, function(percent)
            local count = math.ceil(soldierCount - soldierDamagedCount * percent)
            self.ui_map.soldier_count_attack:SetText(count.."/"..soldier.count)
        end),
        self:PromiseOfDelay(0.8):next(function()
            return promise.all(
                self.ui_map.soldier_morale_attack:PromiseOfProgressTo(0.5, morale - moraleDecreased),
                self:PormiseOfSchedule2(0.5, function(percent)
                    local count = math.round(morale - moraleDecreased * percent)
                    count = count <= 0 and 0 or count
                    self.ui_map.soldier_morale_attack:SetText(count.."/"..100)
                end)
            )
        end)
    )
end
function GameUIReplayNew:HurtSoldierRight(corps, decrease)
    local round = self:GetFightDefenceSoldierByRound(self.round)
    local soldier = self:TopSoldierRight()
    local soldierCount = round.soldierCount or round.wallHp
    local soldierDamagedCount = round.soldierDamagedCount or round.wallDamagedHp
    local morale = self.ui_map.soldier_morale_defence:GetPercent()
    local moraleDecreased = (decrease or 0) / self.ui_map.soldier_count_defence.count * 100
    if round.wallHp then
        if round.wallDamagedHp == round.wallHp then
            moraleDecreased = morale
        end
    end
    local x,y = corps:getPosition()
    return promise.all(
        self:PromiseOfPlayDamage(soldierDamagedCount, x, y),
        self.ui_map.soldier_count_defence:PromiseOfProgressTo(0.5, (soldierCount - soldierDamagedCount) / soldier.count * 100),
        self:PormiseOfSchedule(0.5, function(percent)
            local count = math.ceil(soldierCount - soldierDamagedCount * percent)
            self.ui_map.soldier_count_defence:SetText(count.."/"..soldier.count)
        end),
        self:PromiseOfDelay(0.8):next(function()
            return promise.all(
                self.ui_map.soldier_morale_defence:PromiseOfProgressTo(0.5, morale - moraleDecreased),
                self:PormiseOfSchedule2(0.5, function(percent)
                    local count = math.round(morale - moraleDecreased * percent)
                    count = count <= 0 and 0 or count
                    self.ui_map.soldier_morale_defence:SetText(count.."/"..100)
                end)
            )
        end)
    )
end
function GameUIReplayNew:EnterSoldiersLeft()
    local top_soldier = self:TopSoldierLeft()
    top_soldier.status = "fighting"
    self.ui_map.soldier_inbattle_attack
        :SetSoldeir(top_soldier.name, top_soldier.star)
        :show():SetEnable(true)
    self.ui_map.soldier_count_attack
        :SetText(top_soldier.count.."/"..top_soldier.count)
        :SetProgress(100):show().count = top_soldier.count
    self.ui_map.soldier_morale_attack
        :SetText("100/100")
        :SetProgress(100):show()

    self:RefreshSoldierListView(self.ui_map.list_view_attack, self.copy_soldiers_attack)

    self:ShowStrongOrWeak()
end
function GameUIReplayNew:EnterSoldiersRight()
    local top_soldier = self:TopSoldierRight()
    top_soldier.status = "fighting"
    self.ui_map.soldier_inbattle_defence
        :SetSoldeir(top_soldier.name, top_soldier.star, self.report.IsPveBattle)
        :show():SetEnable(true)

    self.ui_map.soldier_count_defence
        :SetText(top_soldier.count.."/"..top_soldier.count)
        :SetProgress(100):show().count = top_soldier.count
    self.ui_map.soldier_morale_defence
        :SetText("100/100")
        :SetProgress(100):show()

    self:RefreshSoldierListView(self.ui_map.list_view_defence, self.copy_soldiers_defence, self.report.IsPveBattle)

    self:ShowStrongOrWeak()
end
function GameUIReplayNew:SoldierDefeatLeft()
    self.copy_soldiers_attack[1].status = "defeated"
    local top
    if not self:IsAllDefeated(self.copy_soldiers_attack) then
        top = table.remove(self.copy_soldiers_attack, 1)
        table.insert(self.copy_soldiers_attack, top)
    else
        top = self.copy_soldiers_attack[1]
    end
    self.ui_map.soldier_inbattle_attack
        :SetSoldeir(top.name, top.star):SetEnable(false)
    self:RefreshSoldierListView(self.ui_map.list_view_attack, self.copy_soldiers_attack)
end
function GameUIReplayNew:SoldierDefeatRight()
    self.copy_soldiers_defence[1].status = "defeated"
    local top
    if not self:IsAllDefeated(self.copy_soldiers_defence) then
        top = table.remove(self.copy_soldiers_defence, 1)
        table.insert(self.copy_soldiers_defence, top)
    else
        top = self.copy_soldiers_defence[1]
    end
    self.ui_map.soldier_inbattle_defence
        :SetSoldeir(top.name, top.star, self.report.IsPveBattle):SetEnable(false)
    self:RefreshSoldierListView(self.ui_map.list_view_defence, self.copy_soldiers_defence, self.report.IsPveBattle)
end
function GameUIReplayNew:TopSoldierLeft()
    local first_soldier = self.copy_soldiers_attack[1]
    assert(first_soldier.status ~= "defeated")
    return first_soldier
end
function GameUIReplayNew:TopSoldierRight()
    local first_soldier = self.copy_soldiers_defence[1]
    assert(first_soldier.status ~= "defeated")
    return first_soldier
end
function GameUIReplayNew:GetOriginSoldierInfoLeft(name)
    for _,v in ipairs(self.report:GetOrderedAttackSoldiers()) do
        if v.name == name then
            return v
        end
    end
end
function GameUIReplayNew:GetOriginSoldierInfoRight(name)
    for _,v in ipairs(self:GetOrderedDefenceSoldiers()) do
        if v.name == name then
            return v
        end
    end
end
function GameUIReplayNew:IsAllDefeated(soldiers)
    for _,v in ipairs(soldiers) do
        if v.status ~= "defeated" then
            return false
        end
    end
    return true
end
local DEFAULT_SPEED = 1.5
function GameUIReplayNew:SpeedUp(speed)
    self.speed = speed or DEFAULT_SPEED
    local a = self.timer_node:getActionByTag(SPEED_TAG)
    if a then
        a:setSpeed(self.speed)
    end
    local a = self.timer_node:getActionByTag(SPEED_TAG1)
    if a then
        a:setSpeed(self.speed)
    end
    local a = self.timer_node:getActionByTag(SPEED_TAG2)
    if a then
        a:setSpeed(self.speed)
    end

    local a = self.ui_map.battle_background1:getActionByTag(SPEED_TAG)
    if a then
        a:setSpeed(self:Speed())
    end
    if self.dragon_battle then
        self.dragon_battle:RefreshSpeed()
    end
    if self.left then
        self.left:RefreshSpeed()
    end
    if self.right then
        self.right:RefreshSpeed()
    end
    for _,v in ipairs(self.ui_map.damage_node:getChildren()) do
        local a = v:getActionByTag(SPEED_TAG)
        if a then
            a:setSpeed(self:Speed())
        end
    end
    self.ui_map.soldier_count_attack:RefreshSpeed()
    self.ui_map.soldier_morale_attack:RefreshSpeed()
    self.ui_map.soldier_count_defence:RefreshSpeed()
    self.ui_map.soldier_morale_defence:RefreshSpeed()
end
function GameUIReplayNew:Speed()
    return self.speed or DEFAULT_SPEED
end
function GameUIReplayNew:Reset()
    self:SpeedUp()
    if self.result then
        self.result:removeFromParent()
        self.result = nil
    end
    self.round = 1
    self:Stop()
    self.ui_map.damage_node:removeAllChildren()
    self.ui_map.dragon_node:removeAllChildren()
    self.ui_map.battle_node:removeAllChildren()
    self.left = nil
    self.right = nil
    self.ui_map.battle_background1:pos(0,0)

    self.ui_map.arrow_green:hide()
    self.ui_map.speedup.speed = nil
    self.ui_map.speedup:setButtonLabelString(_("x1"))
    self.ui_map.pass:show()
    self.ui_map.close:hide()

    self.ui_map.soldier_inbattle_attack:hide()
    self.ui_map.soldier_count_attack:hide()
    self.ui_map.soldier_morale_attack:hide()

    self.ui_map.soldier_count_defence:hide()
    self.ui_map.soldier_morale_defence:hide()
    self.ui_map.soldier_inbattle_defence:hide()

    self.copy_soldiers_attack = clone(self.report:GetOrderedAttackSoldiers())
    self:RefreshSoldierListView(self.ui_map.list_view_attack, self.copy_soldiers_attack)
    self.ui_map.list_view_attack:reload()
    self.copy_soldiers_defence = clone(self:GetOrderedDefenceSoldiers())
    self:RefreshSoldierListView(self.ui_map.list_view_defence, self.copy_soldiers_defence, self.report.IsPveBattle)
    self.ui_map.list_view_defence:reload()
end
function GameUIReplayNew:Stop()
    if self.dragon_battle then
        self.dragon_battle:Stop()
    end
    if self.timer_node then
        self.timer_node:stopAllActions()
    end
    for _,v in ipairs(self.ui_map.damage_node:getChildren()) do
        v:stopAllActions()
    end
    self.ui_map.battle_background1:stopAllActions()
    if self.left then
        self.left:Stop()
    end
    if self.right then
        self.right:Stop()
    end
    self.ui_map.soldier_count_attack:Stop()
    self.ui_map.soldier_morale_attack:Stop()

    self.ui_map.soldier_count_defence:Stop()
    self.ui_map.soldier_morale_defence:Stop()
end
function GameUIReplayNew:PromiseOfMoveBattleObj(obj, time, x)
    local p = promise.new()
    local speed = cc.Speed:create(transition.sequence({
        cc.MoveBy:create(time, cc.p(x, 0)),
        cc.CallFunc:create(function() p:resolve() end),
    }), self:Speed())
    speed:setTag(SPEED_TAG)
    obj:runAction(speed)
    return p
end
function GameUIReplayNew:PormiseOfSchedule(time, func)
    local p = promise.new()
    local t = 0
    local dt = 0.01
    local speed = cc.Speed:create(
        cc.RepeatForever:create(
            transition.sequence({
                cc.DelayTime:create(dt),
                cc.CallFunc:create(function()
                    t = t + dt * self:Speed()
                    if t > time then
                        func(1)
                        p:resolve()
                        self.timer_node:stopActionByTag(SPEED_TAG1)
                    else
                        if type(func) == "function" then
                            func(t / time)
                        end
                    end
                end)
            })
        ), self:Speed())
    speed:setTag(SPEED_TAG1)
    self.timer_node:runAction(speed)
    return p
end
function GameUIReplayNew:PormiseOfSchedule2(time, func)
    local p = promise.new()
    local t = 0
    local dt = 0.01
    local speed = cc.Speed:create(
        cc.RepeatForever:create(
            transition.sequence({
                cc.DelayTime:create(dt),
                cc.CallFunc:create(function()
                    t = t + dt * self:Speed()
                    if t > time then
                        func(1)
                        p:resolve()
                        self.timer_node:stopActionByTag(SPEED_TAG2)
                    else
                        if type(func) == "function" then
                            func(t / time)
                        end
                    end
                end)
            })
        ), self:Speed())
    speed:setTag(SPEED_TAG2)
    self.timer_node:runAction(speed)
    return p
end
function GameUIReplayNew:Delay(time)
    return function(obj)
        return self:PromiseOfDelay(time, function() return obj end)
    end
end
function GameUIReplayNew:PromiseOfDelay(time, func)
    local p = promise.new(func)
    local speed = cc.Speed:create(transition.sequence({
        cc.DelayTime:create(time),
        cc.CallFunc:create(function() p:resolve() end),
    }), self:Speed())
    speed:setTag(SPEED_TAG)
    self.timer_node:runAction(speed)
    return p
end

------
function GameUIReplayNew:BuildUI()
    local ui_map = {}
    local clip = display.newClippingRegionNode(cc.rect(0,0, 588, 400))
        :addTo(self):pos(window.left + 25, window.bottom + 580)
    ui_map.battle_background1 = display.newSprite("back_ground_grassLand.png")
        :addTo(clip):align(display.LEFT_BOTTOM)
    ui_map.battle_node = display.newNode():addTo(clip)
    ui_map.damage_node = display.newNode():addTo(clip)
    ui_map.dragon_node = display.newNode():addTo(self, 2)
        :pos(window.left + 27, window.bottom + 590)

    local top = display.newSprite("back_ground_replay_1.png"):addTo(self, 1)
        :align(display.TOP_CENTER, display.cx, window.top)
    ui_map.top = top
    local top_size = top:getContentSize()

    ui_map.attackName = UIKit:ttfLabel({
        color = 0xffedae,
        size = 22,
        shadow = true,
    }):addTo(top):align(display.CENTER, 150, 445)

    ui_map.defenceName = UIKit:ttfLabel({
        color = 0xffedae,
        size = 22,
        shadow = true,
    }):addTo(top):align(display.CENTER, top_size.width - 150, 445)

    UIKit:ttfLabel({
        text = _("进攻方"),
        color = 0xffedae,
        size = 22,
        shadow = true,
    }):addTo(top):align(display.CENTER, 150, 405)

    UIKit:ttfLabel({
        text = _("防守方"),
        color = 0xffedae,
        size = 22,
        shadow = true,
    }):addTo(top):align(display.CENTER, top_size.width - 150, 405)

    display.newSprite("soldier_count_icon.png"):addTo(top):pos(120, 70)
    display.newSprite("soldier_count_icon.png"):addTo(top):pos(top_size.width - 120, 70)

    display.newSprite("soldier_morale_icon.png"):addTo(top):pos(120, 35)
    display.newSprite("soldier_morale_icon.png"):addTo(top):pos(top_size.width - 120, 35)

    ui_map.arrow_green = display.newSprite("strong_vs_arrow_green.png")
        :addTo(top):pos(top_size.width/2, 55)

    ui_map.soldier_inbattle_attack = WidgetSoldier.new("ranger", 1, false):addTo(top)
        :pos(65, 53):scale(74/128)
    ui_map.soldier_inbattle_defence = WidgetSoldier.new("ranger", 1, false):addTo(top)
        :pos(top_size.width - 65, 53):scale(74/128)

    --
    local function newProgress(png, replay_ui)
        local node = display.newNode()
        local progress = display.newProgressTimer(png, display.PROGRESS_TIMER_BAR):addTo(node)
        progress:setBarChangeRate(cc.p(1,0))
        progress:setMidpoint(cc.p(0,0))
        local text = UIKit:ttfLabel({
            color = 0xffedae,
            size = 18,
            shadow = true,
        }):addTo(node):align(display.CENTER)
        function node:align(anchorPoint, x, y)
            progress:align(anchorPoint)
            text:align(anchorPoint)
            return self:pos(x, y)
        end
        function node:FlipX(is_flip)
            progress:setScaleX(is_flip and -1 or 1)
            return self
        end
        function node:SetText(string)
            text:setString(string)
            return self
        end
        function node:SetProgress(percent)
            progress:setPercentage(percent)
            return self
        end
        function node:GetPercent()
            return progress:getPercentage()
        end
        function node:PromiseOfProgressTo(time, percent)
            local p = promise.new()
            local speed = cc.Speed:create(transition.sequence({
                cc.ProgressTo:create(time, percent),
                cc.CallFunc:create(function()p:resolve()end),
            }), replay_ui:Speed())
            speed:setTag(SPEED_TAG)
            progress:runAction(speed)
            return p
        end
        function node:RefreshSpeed()
            local a = progress:getActionByTag(SPEED_TAG)
            if a then
                a:setSpeed(replay_ui:Speed())
            end
            return self
        end
        function node:Stop()
            progress:stopAllActions()
            return self
        end
        return node
    end

    ui_map.soldier_count_attack = newProgress("soldier_bar_count.png", self):addTo(top)
        :align(display.CENTER, 207, 71)

    ui_map.soldier_count_defence = newProgress("soldier_bar_count.png", self):addTo(top)
        :align(display.CENTER, top_size.width - 209, 71):FlipX(true)

    ui_map.soldier_morale_attack = newProgress("soldier_bar_morale.png", self):addTo(top)
        :align(display.CENTER, 207, 37)

    ui_map.soldier_morale_defence = newProgress("soldier_bar_morale.png", self):addTo(top)
        :align(display.CENTER, top_size.width - 209, 37):FlipX(true)

    local bottom = WidgetUIBackGround.new({width = 608,height = 520},WidgetUIBackGround.STYLE_TYPE.STYLE_1)
        :addTo(self, 0)
        :align(display.BOTTOM_CENTER, window.cx, window.bottom)

    local s1 = bottom:getContentSize()
    ui_map.list_view_attack = UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(0, 0, s1.width - 20, s1.height - 120),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    }:addTo(bottom):pos(10, 100):setBounceable(false)

    ui_map.list_view_defence = UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a170000),
        viewRect = cc.rect(0, 0, s1.width - 20, s1.height - 120),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    }:addTo(bottom):pos(10, 100):setBounceable(false)

    ui_map.list_view_layer = display.newLayer()
        -- newColorLayer(cc.c4b(100,100,100,0))
        :addTo(bottom):pos(10, 100)
    ui_map.list_view_layer:setContentSize(cc.size(590,390))
    ui_map.list_view_layer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        ui_map.list_view_attack:onTouch_(event)
        ui_map.list_view_defence:onTouch_(event)
        return true
    end)




    ui_map.speedup = cc.ui.UIPushButton.new(
        {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(
        UIKit:ttfLabel({
            text = _("加速"),
            color = 0xfff3c7,
            size = 24,
            shadow = true,
        })
    ):addTo(bottom):align(display.CENTER, 110, 50)

    ui_map.close = cc.ui.UIPushButton.new(
        {normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(
        UIKit:ttfLabel({
            text = _("关闭"),
            color = 0xfff3c7,
            size = 24,
            shadow = true,
        })
    ):addTo(bottom):align(display.CENTER, s1.width - 110, 50)

    ui_map.pass = cc.ui.UIPushButton.new(
        {normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png", disabled = 'gray_btn_148x58.png'},
        {scale9 = false}
    ):setButtonLabel(
        UIKit:ttfLabel({
            text = _("跳过"),
            color = 0xfff3c7,
            size = 24,
            shadow = true,
        })
    ):addTo(bottom):align(display.CENTER, s1.width - 110, 50)
    return ui_map
end
function GameUIReplayNew:GetPreloadImages()
    return {
        {image = "animations/ui_animation_0.pvr.ccz",list = "animations/ui_animation_0.plist"},
        {image = "animations/ui_animation_1.pvr.ccz",list = "animations/ui_animation_1.plist"},
        {image = "animations/ui_animation_2.pvr.ccz",list = "animations/ui_animation_2.plist"},
    }
end
function GameUIReplayNew:OnHandle()

end


local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUIReplayNew:DoFte()
    local r = self.ui_map.close:getCascadeBoundingBox()
    WidgetFteArrow.new(_("点击关闭")):addTo(self.ui_map.close)
    :TurnDown():align(display.CENTER_BOTTOM, 0, r.height - 20)
end

return GameUIReplayNew









































