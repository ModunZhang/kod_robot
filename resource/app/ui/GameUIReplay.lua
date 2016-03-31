local UILib = import(".UILib")
local window = import("..utils.window")
local promise = import("..utils.promise")
local Localize = import("..utils.Localize")
local cocos_promise = import("..utils.cocos_promise")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local GameUIReplay = UIKit:createUIClass('GameUIReplay')
local SPEED_TAG = 1190
local RESULT_TAG = 112
local BATTLE_OBJECT_TAG = 137
local isTroops = function(troops)
    assert(troops)
    return troops.IsTroops
end
function GameUIReplay:ctor(report, callback, skipcallback)
    assert(report.IsFightWithBlackTroops)

    assert(report.GetAttackTargetTerrain)
    
    assert(report.GetFightAttackName)
    assert(report.GetFightDefenceName)

    assert(report.IsDragonFight)
    assert(report.GetAttackDragonLevel)
    assert(report.GetDefenceDragonLevel)
    assert(report.GetFightAttackDragonRoundData)
    assert(report.GetFightDefenceDragonRoundData)
    assert(report.CouldAttackDragonUseSkill)
    assert(report.CouldDefenceDragonUseSkill)

    assert(report.IsSoldierFight)
    assert(report.GetOrderedAttackSoldiers)
    assert(report.GetOrderedDefenceSoldiers)
    assert(report.GetSoldierRoundData)
    
    assert(report.IsFightWall)
    if report:IsFightWall() then
        assert(report.GetFightAttackWallRoundData)
        assert(report.GetFightDefenceWallRoundData)
    end

    assert(report.GetReportResult)
    self.report = report
    self.callback = callback
    self.skipcallback = skipcallback
    self:BuildUI()
end
function GameUIReplay:onEnter()
    self:StartReplay()
end
function GameUIReplay:onExit()
    GameUIReplay.super.onExit(self)
    if type(self.callback) == "function" then
        self.callback(self)
    end
end
function GameUIReplay:RefreshSpeed()
    for _,v in ipairs(self.ui_map.effectNode:getChildren()) do
        if v:getTag() == BATTLE_OBJECT_TAG then
            v:getAnimation():setSpeedScale(self.speed)
        end
    end
    for _,v in ipairs(self.ui_map.soldierBattleNode:getChildren()) do
        if v:getTag() == BATTLE_OBJECT_TAG then
            v:RefreshSpeed()
        end
    end
    for _,v in ipairs(self.ui_map.dragonSkillNode:getChildren()) do
        if v:getTag() == BATTLE_OBJECT_TAG then
            v:RefreshSpeed()
        end
    end
    for _,v in ipairs(self.ui_map.dragonBattleNode:getChildren()) do
        if v:getTag() == BATTLE_OBJECT_TAG then
            v:RefreshSpeed()
        end
    end
    local speed = self.ui_map.timerNode:getActionByTag(SPEED_TAG)
    if speed then
        speed:setSpeed(self.speed)
    end
end
function GameUIReplay:MovingTimeForAttack()
    return 2
end
function GameUIReplay:MoveSpeed()
    return 100
end
function GameUIReplay:WallPosition()
    return self:DefencePosition() + 200, display.cy
end
function GameUIReplay:AttackPosition()
    return 100
end
function GameUIReplay:DefencePosition()
    return 608 - 100
end
function GameUIReplay:TopPositionByRow(row)
    return 910 - 200 - (row-1) * 105
end
function GameUIReplay:GetDragonBuff(hp, hpMax)
    local hpPercent = hp / hpMax * 100
    for i,buff in pairs(GameDatas.Dragons.dragonBuff) do
        if hpPercent > buff.hpFrom and hpPercent <= buff.hpTo then
            return buff.buffPercent * 100
        end
    end
    return 0
end
function GameUIReplay:Setup()
    self.isFightWall = false
    self.roundCount = 1
    self.dualCount = 1
    self.hurtCount = 0
    self.fightWallCount = 0

    self.ui_map.attackName:setString(self.report:GetFightAttackName())
    self.ui_map.defenceName:setString(self.report:GetFightDefenceName())

    if self.report:IsDragonFight() then
        local attackDragonType = self.report:GetFightAttackDragonRoundData().type
        self.attackDragon = UIKit:CreateSkillDragon(attackDragonType, true, self):hide()
        :addTo(self.ui_map.dragonSkillNode,0,BATTLE_OBJECT_TAG):pos(display.cx-100, display.cy)

        self.ui_map.attackDragonLabel:setString(Localize.dragon[attackDragonType])
        self.ui_map.attackDragonIcon:setTexture(UILib.dragon_head[attackDragonType])

        local defenceDragonType = self.report:GetFightDefenceDragonRoundData().type
        self.defenceDragon = UIKit:CreateSkillDragon(defenceDragonType, false, self):hide()
        :addTo(self.ui_map.dragonSkillNode,0,BATTLE_OBJECT_TAG):pos(display.cx+100, display.cy)

        self.ui_map.defenceDragonLabel:setString(Localize.dragon[defenceDragonType])
        self.ui_map.defenceDragonIcon:setTexture(UILib.dragon_head[defenceDragonType])
    end

    self.attackTroops = {}
    for i,v in ipairs(self.report:GetOrderedAttackSoldiers()) do
        self.attackTroops[i] = UIKit:CreateFightTroops(v.name, {
            isleft = true,
        },self):addTo(self.ui_map.soldierBattleNode,0,BATTLE_OBJECT_TAG)
        :pos(self:AttackPosition(), self:TopPositionByRow(i))
        :FaceCorrect():Idle()

        self:CreateSoldierCountBox(self.attackTroops[i].infoNode)
        :pos(-30, -20):SetSoldierCount(self:GetSoldierCount(true, 1, i, false))
    end

    self.defenceTroops = {}
    if self.report:IsSoldierFight() then
        for i,v in ipairs(self.report:GetOrderedDefenceSoldiers()) do
            self.defenceTroops[i] = UIKit:CreateFightTroops(v.name, {
                isleft = false,
                ispve = self.report:IsFightWithBlackTroops(),
            },self):addTo(self.ui_map.soldierBattleNode,0,BATTLE_OBJECT_TAG) 
            :pos(self:DefencePosition(), self:TopPositionByRow(i))
            :FaceCorrect():Idle()

            self:CreateSoldierCountBox(self.defenceTroops[i].infoNode)
            :pos(30, -20):SetSoldierCount(self:GetSoldierCount(false, 1, i, false))
        end
    else
        local wallName = string.format("wall_%d", self.report:GetWallData().wall.level)
        self.defenceTroops[1] = UIKit:CreateFightTroops(wallName, {isleft = false,},self)
                                :addTo(self.ui_map.soldierBattleNode,0,BATTLE_OBJECT_TAG)
                                :pos(self:WallPosition()):FaceCorrect()
    end
end
function GameUIReplay:CreateSoldierCountBox(infoNode)
    local box = display.newSprite("replay_attack_number_bg.png")
    :addTo(infoNode)
    
    local point = box:getAnchorPointInPoints()
    local size = box:getContentSize()
    box.count = UIKit:ttfLabel({
        size = 16,
        color = 0xffedae,
    }):addTo(box):align(display.CENTER,point.x,point.y)

    function box:SetSoldierCount(count)
        self.count:setString(GameUtils:formatNumber(count))
        return self
    end
    
    infoNode.soldierCount = box
    return box
end
function GameUIReplay:GetSoldierCount(isattack, round, dualCount, ishurt)
    if ishurt then
        local roundData = self.report:GetSoldierRoundData()
        local results = isattack 
                        and roundData[round].attackResults 
                        or roundData[round].defenceResults
        return results[dualCount].soldierCount - results[dualCount].soldierDamagedCount
    else
        return (isattack and 
            self.report:GetOrderedAttackSoldiers() or 
            self.report:GetOrderedDefenceSoldiers())[dualCount].count
    end
end
function GameUIReplay:GetSoldierHurtCount(isattack, round, dualCount)
    local roundData = self.report:GetSoldierRoundData()
    local results = isattack 
                    and roundData[round].attackResults 
                    or roundData[round].defenceResults
    return results[dualCount].soldierDamagedCount
end
function GameUIReplay:Start()
    if not self.report:IsSoldierFight() then
        self:OnStartRound()
        return
    end
	local attackLevel = self.report:GetAttackDragonLevel()
	local attackRoundDragon = self.report:GetFightAttackDragonRoundData()
    local attackIncrease = self:GetDragonBuff(attackRoundDragon.hp - attackRoundDragon.hpDecreased, attackRoundDragon.hpMax)

    local defenceLevel = self.report:GetDefenceDragonLevel()
    local defenceRoundDragon = self.report:GetFightDefenceDragonRoundData()
    local defenceIncrease = self:GetDragonBuff(defenceRoundDragon.hp - defenceRoundDragon.hpDecreased, defenceRoundDragon.hpMax)

    local dragonBattle = UIKit:CreateDragonBattle({
        isleft = true,
        dragonType = attackRoundDragon.type,
        level = attackLevel,
        hpMax = attackRoundDragon.hpMax,
        hp = attackRoundDragon.hp,
        hpDecreased = attackRoundDragon.hpDecreased,
        isWin = attackRoundDragon.isWin,
        increase = attackIncrease,
    }, {
        isleft = false,
        dragonType = defenceRoundDragon.type,
        level = defenceLevel,
        hpMax = defenceRoundDragon.hpMax,
        hp = defenceRoundDragon.hp,
        hpDecreased = defenceRoundDragon.hpDecreased,
        isWin = defenceRoundDragon.isWin,
        increase = defenceIncrease,
    }, self):addTo(self.ui_map.dragonBattleNode, 0, BATTLE_OBJECT_TAG)
    :pos(display.cx, display.height - 300)

    local TIME_PER_HUNDRED_PERCENT = 1 / 100

    local attackToPercent = (attackRoundDragon.hp - attackRoundDragon.hpDecreased) / attackRoundDragon.hpMax * 100
    local attackStepPercent = math.abs(attackToPercent - dragonBattle:GetAttackDragon():GetPercent())


    local defenceToPercent = (defenceRoundDragon.hp - defenceRoundDragon.hpDecreased) / defenceRoundDragon.hpMax * 100
    local defenceStepPercent = math.abs(defenceToPercent - dragonBattle:GetDefenceDragon():GetPercent())

    dragonBattle:PromsieOfFight()
    :next(function()
        return self:OnHandle("dragonFight")
    end)
    :next(function()
        return promise.all(
        	dragonBattle:GetAttackDragon()
        	:PromiseOfProgressTo(TIME_PER_HUNDRED_PERCENT * attackStepPercent, attackToPercent), 
        	dragonBattle:GetDefenceDragon()
        	:PromiseOfProgressTo(TIME_PER_HUNDRED_PERCENT * defenceStepPercent, defenceToPercent))
    end)
    :next(function()
    	return dragonBattle:PromiseOfShowBuff()
    end)
    :next(function()
    	return dragonBattle:PromsieOfHide()
    end)
    :next(function()
        return self:OnHandle("soldierFight")
    end)
    :next(function()
    	self:OnStartRound()
    end)
end
function GameUIReplay:OnStartRound()
    self.ui_map.roundLabel:setString(self.roundCount)
    if self.defenceTroops[1]:IsWall() then
        self:OnStartMoveToWall()
    else
        self:OnStartSoldierBattle()
    end
end
function GameUIReplay:OnFinishRound()
    self.roundCount = self.roundCount + 1
    
    local attackTroops = {}
    for _,v in ipairs(self.attackTroops) do
        if not v:isVisible() then
            v:removeFromParent()
        else 
            table.insert(attackTroops, v)
            v.effectsNode:removeAllChildren()
        end
    end
    self.attackTroops = attackTroops

    local defenceTroops = {}
    for i,v in ipairs(self.defenceTroops) do
        if not v:isVisible() then
            v:removeFromParent()
        else 
            table.insert(defenceTroops, v)
            v.effectsNode:removeAllChildren()
        end
    end
    self.defenceTroops = defenceTroops

    if #self.attackTroops > 0 and #self.defenceTroops > 0 then
        self:OnStartRound()
    elseif #self.attackTroops > 0 and not self.isFightWall
    and self.report:IsFightWall() then
        local wallName = string.format("wall_%d", self.report:GetWallData().wall.level)
        self.defenceTroops[1] = UIKit:CreateFightTroops(wallName, {isleft = false,},self)
            :addTo(self.ui_map.soldierBattleNode,0,BATTLE_OBJECT_TAG)
            :pos(self:WallPosition())
            :FaceCorrect()
        self:OnStartMoveToWall()
    else
        self:FinishReplay()
    end
end
-- 打城墙
function GameUIReplay:OnStartMoveToWall()
    self.ui_map.roundLabel:setString(self.roundCount)

    local indexes = {1,2,3,4,5,6}
    local flip = false
    while(#indexes > #self.attackTroops) do
        if flip then
            table.remove(indexes, 1)
        else
            table.remove(indexes, #indexes)
        end
        flip = not flip
    end
    for i,v in pairs(self.attackTroops) do
        local tx, ty = self:AttackPosition(), self:TopPositionByRow(indexes[i])
        v:Move(tx, ty, self:MovingTimeForAttack()).effectsNode:removeAllChildren()
    end
    local wall = self.defenceTroops[1]
    local ox,oy = self:WallPosition()
    wall:Move(ox-120, oy, self:MovingTimeForAttack(), function(isend)
        if not isend then
            for i,v in pairs(self.attackTroops) do
                v:Idle()
            end
        else
            self:OnFinishMoveToWall()
        end
    end)
    local originx = self.ui_map.battleBgNode:getPositionX()
    wall:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(dt)
        local ox = self:WallPosition()
        local x  = wall:getPosition()
        self.ui_map.battleBgNode:setPositionX(originx + x - ox)
    end)
    wall:scheduleUpdate()
end
function GameUIReplay:OnFinishMoveToWall()
    self.isFightWall = true
    local wall = self.defenceTroops[1]
    local point = cc.p(wall:getPosition())
    local wp = wall:getParent():convertToWorldSpace(point)
    wp.x = wp.x - 100
    local move_count = 0
    local need_move = false
    local melee_count = 0
    for i,v in pairs(self.attackTroops) do
        if v:IsMelee() then
            melee_count = melee_count + 1
            need_move = true
            local np = v:getParent():convertToNodeSpace(wp)
            local attack_x, attack_y = v:getPosition()
            if np.x ~= attack_x then
                v:Move(np.x, attack_y, self:MovingTimeForAttack(), function(isend)
                    if isend then
                        move_count = move_count + 1
                        if move_count == melee_count then
                            self:OnAttackWall()
                        end
                    end
                end)
            end
        end
    end
    if not need_move then
        self:OnAttackWall()
    end
end
function GameUIReplay:OnAttackWall()
    self.hurtCount = 0
    for i,v in ipairs(self.attackTroops) do
        self:OnAttacking(v, self.defenceTroops[1])
    end
end
function GameUIReplay:OnStartSoldierBattle()
    -- 本轮是士兵对打
    self.dualCount = 1
    local need_move = false
    local need_move_count = 0
    local move_count = 0
    for i,v in ipairs(self.attackTroops) do
        local tx, ty = self:AttackPosition(), self:TopPositionByRow(i)
        local x,y = v:getPosition()
        if (x ~= tx or y ~= ty) and not v:IsWall() then
            need_move_count = need_move_count + 1
            need_move = true
            local move_time = math.abs(ty - y)/self:MoveSpeed()
            v:Move(tx, ty, move_time, function(isend)
                if isend then
                    move_count = move_count + 1
                    if move_count == need_move_count then
                        self:OnFinishAdjustPosition()
                    end
                end
            end)
        end
    end
    for i,v in ipairs(self.defenceTroops) do
        local tx, ty = self:DefencePosition(), self:TopPositionByRow(i)
        local x,y = v:getPosition()
        if (x ~= tx or y ~= ty) and not v:IsWall() then
            need_move_count = need_move_count + 1
            need_move = true
            local move_time = math.abs(ty - y)/self:MoveSpeed()
            v:Move(tx, ty, move_time, function(isend)
                if isend then
                    move_count = move_count + 1
                    if move_count == need_move_count then
                        self:OnFinishAdjustPosition()
                    end
                end
            end)
        end
    end
    if not need_move then
        self:OnFinishAdjustPosition()
    end
end
function GameUIReplay:OnFinishAdjustPosition()
    local round = self.report:GetSoldierRoundData()[self.roundCount]
    if next(round.attackDragonSkilled) and next(round.defenceDragonSkilled) then
        local skill,finish = self:PromisesOfAttackDragonSkill(round)
        promise.all(skill, finish):next(function()
            local skill1,finish1 = self:PromisesOfDefenceDragonSkill(round)
            return promise.all(skill1, finish1)
        end):next(function()
            self:OnStartDual()
        end)
    elseif next(round.attackDragonSkilled) then
        local skill,finish = self:PromisesOfAttackDragonSkill(round)
        promise.all(skill, finish):next(function()
            self:OnStartDual()
        end)
    elseif next(round.defenceDragonSkilled) then
        local skill,finish = self:PromisesOfDefenceDragonSkill(round)
        promise.all(skill, finish):next(function()
            self:OnStartDual()
        end)
    else
        self:OnStartDual()
    end
end
function GameUIReplay:PromisesOfAttackDragonSkill(round)
    local effectedTroops = {}
    for i,v in ipairs(round.attackDragonSkilled) do
        table.insert(effectedTroops, self.defenceTroops[v + 1])
    end

    local skill, finish = promise.new(), promise.new()
    self.attackDragon:show():Attack(function(isend)
        if isend then
            self.attackDragon:hide()
            finish:resolve()
        else
            local p = self:OnDragonAttackTroops(self.attackDragon, effectedTroops)
            p:done(function()
                skill:resolve()
            end)
        end
    end)
    return skill, finish
end
function GameUIReplay:PromisesOfDefenceDragonSkill(round)
    local effectedTroops = {}
    for i,v in ipairs(round.defenceDragonSkilled) do
        table.insert(effectedTroops, self.attackTroops[v + 1])
    end

    local skill, finish = promise.new(), promise.new()
    self.defenceDragon:show():Attack(function(isend)
        if isend then
            self.defenceDragon:hide()
            finish:resolve()
        else
            local p = self:OnDragonAttackTroops(self.defenceDragon, effectedTroops)
            p:done(function()
                skill:resolve()
            end)
        end
    end)
    return skill, finish
end
function GameUIReplay:OnDragonAttackTroops(dragon, allTroops)
    local p = cocos_promise.defer()
    
    local isdefencer = dragon == self.defenceDragon 
    local x = isdefencer and self:AttackPosition() or self:DefencePosition()

    local leftPos = cc.p(-50, 15)
    local rightPos = cc.p(50, 15)

    if dragon.dragonType == "redDragon" then
        p:next(function()
            app:GetAudioManager():PlayDragonSkill(dragon.dragonType)
        end)
        :next(self:Delay(0.08))
        :next(function()
            for i,troop in ipairs(allTroops) do
                local x,y = troop:getPosition()
                UIKit:CreateSkillEffect("fire", isdefencer)
                :pos(x,y):addTo(self.ui_map.effectNode,0,BATTLE_OBJECT_TAG)
                :getAnimation():setSpeedScale(self.speed)
            end
        end)
        :next(self:Delay(0.1))
        :next(function()
            for i,troop in ipairs(allTroops) do
                local point = isdefencer and leftPos or rightPos
                local effect = display.newSprite("replay_debuff_red.png")
                                    :addTo(troop.effectsNode)
                effect:pos(point.x,point.y+(troop.effectsNode:getChildrenCount()-1)*10)

                troop:PromiseOfHurt():next(function() troop:Idle() end)
            end
        end)
        
    elseif dragon.dragonType == "blueDragon" then
        math.randomseed(#allTroops)
        allTroops = randomArray(allTroops)

        local needAddCount = 3 - #allTroops > 0 and (3 - #allTroops) or 0
        local addindexes = {}
        for i = #allTroops + 1, 6 do
            table.insert(addindexes, i)
        end
        addindexes = randomArray(addindexes)

        for i = 1, needAddCount do
            local row = addindexes[i]
            table.insert(allTroops, {x = x, y = self:TopPositionByRow(row)})
        end

        local point = isdefencer and leftPos or rightPos
        for i,troop in ipairs(allTroops) do
            p:next(function()
                app:GetAudioManager():PlayDragonSkill(dragon.dragonType)
            end)
            :next(self:Delay(0.08))
            :next(function()
                local x,y
                if troop.IsTroops then
                    x,y = troop:getPosition()
                else
                    x,y = troop.x, troop.y
                end
                UIKit:CreateSkillEffect("lightning", isdefencer)
                :pos(x,y):addTo(self.ui_map.effectNode,y,BATTLE_OBJECT_TAG)
                :getAnimation():setSpeedScale(self.speed)
            end)
            if troop.IsTroops then
                p:next(self:Delay(0.1))
                :next(function()
                    local effect = display.newSprite("replay_debuff_blue.png")
                                    :addTo(troop.effectsNode)
                    effect:pos(point.x,point.y+(troop.effectsNode:getChildrenCount()-1)*10)
                    troop:PromiseOfHurt():next(function() troop:Idle() end)
                end)
            end
        end
    elseif dragon.dragonType == "greenDragon" then
        local aniarray = {"poison_1", "poison_2", "poison_3"}
        p:next(function()
            app:GetAudioManager():PlayDragonSkill(dragon.dragonType)
        end)
        :next(self:Delay(0.3))
        :next(function()
            math.randomseed(#allTroops)
            for i = 1, 6, 2 do
                UIKit:CreateSkillEffect(aniarray[math.random(#aniarray)], isdefencer)
                :pos(x, self:TopPositionByRow(i))
                :addTo(self.ui_map.effectNode,y,BATTLE_OBJECT_TAG)
                :getAnimation():setSpeedScale(self.speed)
            end
        end)
        :next(self:Delay(0.1))
        :next(function()
            for i = 1, 6, 2 do
                local troop = allTroops[i]
                if allTroops[i] then
                    local point = isdefencer and leftPos or rightPos
                    display.newSprite("replay_debuff_green.png")
                    :addTo(troop.effectsNode):pos(point.x,point.y)
                    troop:PromiseOfHurt():next(function() troop:Idle() end)
                end
            end
        end)
        :next(self:Delay(0.1))
        :next(function()
            app:GetAudioManager():PlayDragonSkill(dragon.dragonType)
        end)
        :next(self:Delay(0.3))
        :next(function()
            math.randomseed(#allTroops)
            for i = 2, 6, 2 do
                UIKit:CreateSkillEffect(aniarray[math.random(#aniarray)], isdefencer)
                :pos(x, self:TopPositionByRow(i))
                :addTo(self.ui_map.effectNode,y,BATTLE_OBJECT_TAG)
                :getAnimation():setSpeedScale(self.speed)
            end
        end)
        :next(self:Delay(0.1))
        :next(function()
            for i = 2, 6, 2 do
                local troop = allTroops[i]
                if allTroops[i] then
                    local point = isdefencer and leftPos or rightPos
                    display.newSprite("replay_debuff_green.png")
                    :addTo(troop.effectsNode):pos(point.x,point.y)
                    troop:PromiseOfHurt():next(function() troop:Idle() end)
                end
            end
        end)
    end
    return p:next(self:Delay(1.5))
end
function GameUIReplay:OnFinishDual()
    self.dualCount = self.dualCount + 1
    local roundData = self.report:GetSoldierRoundData()
    local attackResults = roundData[self.roundCount].attackResults
    local defenceResults = roundData[self.roundCount].defenceResults

    if self.dualCount <= #attackResults 
    and self.dualCount <= #defenceResults then
        self:OnStartDual()
    else
        self:OnFinishRound()
    end
end
function GameUIReplay:OnStartDual()
    self.hurtCount = 0
    local roundData = self.report:GetSoldierRoundData()
    local attackResults = roundData[self.roundCount].attackResults
    local defenceResults = roundData[self.roundCount].defenceResults
    if attackResults[self.dualCount].isWin then
        self:OnFight(self.defenceTroops[self.dualCount], self.attackTroops[self.dualCount])
    else
        self:OnFight(self.attackTroops[self.dualCount], self.defenceTroops[self.dualCount])
    end
end
function GameUIReplay:OnAttackFinished(attackTroop)
    attackTroop:Idle()
    assert(attackTroop.properties.target)
    local target = attackTroop.properties.target

    if self.isFightWall then
        self.fightWallCount = self.fightWallCount + 1
    end

    if isTroops(target) then
    	-- 攻打城墙这两个是必要条件
        if not self.isFightWall or self.fightWallCount == 1 then
            target:PromiseOfHurt():next(function()
            	self:OnHurtFinished(target)
            end)
        end
    else
        for _,v in pairs(target) do
            v:PromiseOfHurt():next(function()
            	self:OnHurtFinished(v)
            end)
        end
    end
    attackTroop.properties.target = nil
end
function GameUIReplay:OnHurtFinished(hurtTroop)
    self.hurtCount = self.hurtCount + 1
    hurtTroop:Idle()

    if not self.isFightWall then
        local isattack = hurtTroop:IsLeft()
        local round = self.roundCount
        local dual = self.dualCount
        hurtTroop.infoNode.soldierCount:SetSoldierCount(
            self:GetSoldierCount(isattack,round,dual,true)
        )
        hurtTroop:ShowHurtCount(self:GetSoldierHurtCount(isattack,round,dual))

        if self.hurtCount == 1 then -- 反击
            hurtTroop:Hold(0.2, function()
                self:OnFight(hurtTroop, hurtTroop.properties.target)
            end)
        else -- 死亡
            local attackTroops = hurtTroop.properties.target
            if attackTroops:IsMelee() and self:IsMoved(attackTroops) then
                hurtTroop:PromiseOfDeath()
                local x,y = self:GetOriginPoint(attackTroops)
                attackTroops:Return(x,y, self:MovingTimeForAttack(), function()
                    attackTroops:FaceCorrect()
                    self:OnFinishDual()
                end)
            else
                hurtTroop:PromiseOfDeath():next(function()
                    self:OnFinishDual()
                end)
            end
            attackTroops.properties.target = nil
            hurtTroop.properties.target = nil
        end
    else
        if hurtTroop:IsWall() then
            self:OnAttacking(hurtTroop, self.attackTroops)
        end
        if self.hurtCount == #self.attackTroops then
            local attackRoundData = self.report:GetFightAttackWallRoundData()
            local pps = {}
            for i,v in pairs(self.attackTroops) do
                local roundData = attackRoundData[i]
                if roundData then 
                    v.infoNode.soldierCount:SetSoldierCount(roundData.soldierCount - roundData.soldierDamagedCount)
                    table.insert(pps, v:PromiseOfShowHurtCount(roundData.soldierDamagedCount))

                    if roundData.soldierCount - roundData.soldierDamagedCount <= 0 then
                        table.insert(pps, v:PromiseOfDeath())
                    end
                end
            end

            local defenceRoundData = self.report:GetFightDefenceWallRoundData()
            local wall = defenceRoundData[1]
            local wallHp = wall.wallHp
            local wallMaxHp = wall.wallMaxHp
            local wallDamagedHp = 0,0,0
            for i,v in ipairs(defenceRoundData) do
                wallDamagedHp = wallDamagedHp + v.wallDamagedHp
            end

            if wallHp - wallDamagedHp <= 0 then
                table.insert(pps, self.defenceTroops[1]:PromiseOfDeath())
            end

            if #pps > 0 then
                promise.all(unpack(pps)):next(function() self:FinishReplay() end)
            else
                self:performWithDelay(function()
                    self:FinishReplay()
                end, 0.1)
            end
        end
    end
end
function GameUIReplay:OnFight(attackTroop, defenceTroop)
    if attackTroop:IsMelee() then
        local point = cc.p(defenceTroop:getPosition())
        local wp = defenceTroop:getParent():convertToWorldSpace(point)
        if attackTroop:IsLeft() then
            wp.x = wp.x - 100
        else
            wp.x = wp.x + 100
        end
        local np = attackTroop:getParent():convertToNodeSpace(wp)
        local attack_x, attack_y = attackTroop:getPosition()
        if np.x ~= attack_x or attack_y ~= np.y then
            attackTroop:Move(np.x, np.y, self:MovingTimeForAttack(), function(isend)
                if isend then
                    self:OnAttacking(attackTroop, defenceTroop)
                end
            end)
            return
        end
    end
    self:OnAttacking(attackTroop, defenceTroop)
end
function GameUIReplay:OnAttacking(attackTroop, defenceTroop)
    attackTroop.properties.target = defenceTroop
    local isrevenge = false
    if isTroops(defenceTroop) then
        defenceTroop.properties.target = attackTroop
        if attackTroop:IsCatapult() then
            isrevenge = math.abs(defenceTroop:getPositionX() - attackTroop:getPositionX()) < 300
        end
    else
        for _,v in pairs(defenceTroop) do
            v.properties.target = attackTroop
        end
    end
    promise.all(attackTroop:PromiseOfAttack(isrevenge)):next(function()
        self:OnAttackFinished(attackTroop)
    end)
end
function GameUIReplay:IsMoved(troops)
    local tx,ty = self:GetOriginPoint(troops)
    local x,y = troops:getPosition()
    return x ~= tx or y ~= ty
end
function GameUIReplay:GetOriginPoint(troops)
    local pos_y = self:TopPositionByRow(self.dualCount)
    local x,y = troops:IsLeft() and self:AttackPosition() or self:DefencePosition(), pos_y
    return x, y
end
function GameUIReplay:Delay(time)
    return function(obj)
        return self:PromiseOfDelay(time, function() return obj end)
    end
end
function GameUIReplay:PromiseOfDelay(time, func)
        local p = promise.new(func)
        local speed = cc.Speed:create(transition.sequence({
            cc.DelayTime:create(time),
            cc.CallFunc:create(function() p:resolve() end),
        }), self.speed)
        speed:setTag(SPEED_TAG)
        self.ui_map.timerNode:runAction(speed)
        return p
    end
function GameUIReplay:Pause()
    for _,v in ipairs(self.ui_map.effectNode:getChildren()) do
        if v:getTag() == BATTLE_OBJECT_TAG then
            v:getAnimation():pause()
        end
    end
    for _,v in ipairs(self.ui_map.soldierBattleNode:getChildren()) do
        if v:getTag() == BATTLE_OBJECT_TAG then
            v:Pause()
        end
    end
    for _,v in ipairs(self.ui_map.dragonSkillNode:getChildren()) do
        if v:getTag() == BATTLE_OBJECT_TAG then
            v:Pause()
        end
    end
    for _,v in ipairs(self.ui_map.dragonBattleNode:getChildren()) do
        if v:getTag() == BATTLE_OBJECT_TAG then
            v:Pause()
        end
    end
    self.ui_map.timerNode:stopAllActions()
end
function GameUIReplay:StartReplay()
    self.ui_map.battleBgNode:pos(0,0)
    self.ui_map.speedup:show()
    self.ui_map.replay:hide()
    self.ui_map.pass:show()
    self.ui_map.close:hide()
    self:ChangeSpeed(0)
    self:removeChildByTag(RESULT_TAG)
    self.ui_map.effectNode:removeAllChildren()
    self.ui_map.soldierBattleNode:removeAllChildren()
    self.ui_map.dragonSkillNode:removeAllChildren()
    self.ui_map.dragonBattleNode:removeAllChildren()
    self:Setup()
    self:Start()
end
function GameUIReplay:FinishReplay()
    if type(self.skipcallback) == "function" then
        self.skipcallback(self)
        return
    end
    local isWin = self.report:GetReportResult()
    local result = ccs.Armature:create("win"):addTo(self, 10, RESULT_TAG)
    result:align(display.CENTER, window.cx, window.cy + 150)
    if isWin then
        result:setAnchorPoint(cc.p(0.48, 0.5))
        app:GetAudioManager():PlayeEffectSoundWithKey("BATTLE_VICTORY")
    else
        result:setAnchorPoint(cc.p(0.5, 0.5))
        app:GetAudioManager():PlayeEffectSoundWithKey("BATTLE_DEFEATED")
    end
    result:getAnimation():play(isWin and "Victory" or "Defeat", -1, 0)

    self.ui_map.speedup:hide()
    self.ui_map.replay:show()
    self.ui_map.pass:hide()
    self.ui_map.close:show()
    self:Pause()
end
function GameUIReplay:ChangeSpeed(speed)
    if speed == 0 then
        self.speed = 1.5
        self.ui_map.speedup:setButtonLabelString(_("加速"))
    elseif self.speed == 1.5 then
        self.speed = 3.0
        self.ui_map.speedup:setButtonLabelString(_("x2"))
    elseif self.speed == 3.0 then
        self.speed = 4.5
        self.ui_map.speedup:setButtonLabelString(_("x4"))
    elseif self.speed == 4.5 then
        self.speed = 1.5
        self.ui_map.speedup:setButtonLabelString(_("加速"))
    end
    self:RefreshSpeed()
end
function GameUIReplay:BuildUI()
    local ui_map = {}
    local bg = WidgetUIBackGround.new({width = 608,height = 910},
                    WidgetUIBackGround.STYLE_TYPE.STYLE_1):addTo(self)
                    :align(display.TOP_CENTER, display.cx, display.height - 10)

    local clipWith, clipHeight = 608-15*2, 910-85*2
    local clip = display.newClippingRegionNode(cc.rect(15,85,clipWith,clipHeight)):addTo(bg)
    
    ui_map.timerNode = display.newNode():addTo(self)
    ui_map.battleBgNode = self:CreateBattleBg():addTo(clip):align(display.LEFT_BOTTOM)
    ui_map.soldierBattleNode = display.newNode():addTo(clip,1)
    ui_map.effectNode = display.newNode():addTo(clip,2)
    ui_map.dragonSkillNode = display.newNode():addTo(clip,3)

    ui_map.dragonBattleNode = display.newNode():addTo(self, 10)

    ui_map.dragonBattleWhite = display.newSprite("click_empty.png")
    :addTo(bg, 11):align(display.TOP_CENTER, 608/2, 910 - 160)

    local size = ui_map.dragonBattleWhite:getContentSize()
    ui_map.dragonBattleWhite:hide()
    :opacity(255):setColor(cc.c3b(255,0,0))
    ui_map.dragonBattleWhite:setScaleX(clipWith/size.width)
    ui_map.dragonBattleWhite:setScaleY(1.8)

    ui_map.soldierBattleWhite = display.newSprite("click_empty.png")
    :addTo(bg, 11):align(display.TOP_CENTER, 608/2, 910 - 110)

    local size = ui_map.soldierBattleWhite:getContentSize()
    ui_map.soldierBattleWhite:hide()
    :opacity(255):setColor(cc.c3b(255,0,0))
    ui_map.soldierBattleWhite:setScaleX(clipWith/size.width)
    ui_map.soldierBattleWhite:setScaleY(0.75)
    

    -- 左右黑边
    local line1 = display.newSprite("line_send_trop_612x2.png")
        :align(display.CENTER_TOP, 608/2, 910 - 85)
        :addTo(bg)
    line1:setScaleX((608-15*2)/612)
    line1:setScaleY((910-85*2)/2)

    -- 上下黑边
    local line1 = display.newSprite("line_send_trop_612x2.png")
        :align(display.CENTER, 608 / 2, 910 / 2)
        :addTo(bg):rotation(90)
    line1:setScaleX((910 - 85*2)/612)
    line1:setScaleY((608-15*2)  /2)
    
    display.newSprite("replay_title_bg.png"):addTo(self)
    :align(display.TOP_CENTER, display.cx, display.height - 10)
    
    display.newSprite("replay_round.png"):addTo(self)
    :pos(display.cx, display.height - 40)
    
    ui_map.roundLabel = UIKit:ttfLabel({
        text = 1,
        size = 36,
        color = 0xffde00,
    }):addTo(self)
    :align(display.CENTER, display.cx, display.height - 65)

    ui_map.attackName = UIKit:ttfLabel({
        text = "attackName",
        size = 22,
        color = 0xffedae,
    }):addTo(self)
    :align(display.CENTER, display.cx - 125, display.height - 35)

    ui_map.defenceName = UIKit:ttfLabel({
        text = "defenceName",
        size = 22,
        color = 0xffedae,
    }):addTo(self)
    :align(display.CENTER, display.cx + 125, display.height - 35)


    ui_map.attackDragonLabel = UIKit:ttfLabel({
        text = "红龙",
        size = 20,
        color = 0xffedae,
    }):addTo(self)
    :align(display.CENTER, display.cx - 125, display.height - 75)

    ui_map.defenceDragonLabel = UIKit:ttfLabel({
        text = "绿龙",
        size = 20,
        color = 0xffedae,
    }):addTo(self)
    :align(display.CENTER, display.cx + 125, display.height - 75)


    ui_map.attackDragonIcon = display.newSprite(UILib.dragon_head.redDragon)
    :addTo(self):scale(0.8)
    :align(display.CENTER, display.cx - 256, display.height - 48)

    ui_map.defenceDragonIcon = display.newSprite(UILib.dragon_head.redDragon)
    :addTo(self):scale(0.8)
    :align(display.CENTER, display.cx + 256, display.height - 48)
    ui_map.defenceDragonIcon:flipX(true)

    ui_map.replay = cc.ui.UIPushButton.new(
        {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(
        UIKit:ttfLabel({
            text = _("回放"),
            color = 0xfff3c7,
            size = 24,
            shadow = true,
        })
    ):addTo(bg):align(display.CENTER, 110, 45)
    :onButtonClicked(function()
        self:StartReplay()
    end):hide()

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
    ):addTo(bg):align(display.CENTER, 110, 45)
    :onButtonClicked(function()
        self:ChangeSpeed()
    end):hide()


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
    ):addTo(bg):align(display.CENTER, 608 - 110, 45)
    :onButtonClicked(function()
        self:LeftButtonClicked()
    end):hide()

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
    ):addTo(bg):align(display.CENTER, 608 - 110, 45)
    :onButtonClicked(function()
        self:FinishReplay()
    end):hide()

    self.ui_map = ui_map
end
function GameUIReplay:CreateBattleBg()
    local terrain = self.report:GetAttackTargetTerrain()
    local bg_node = display.newNode()
    GameUtils:LoadImagesWithFormat(function()
        cc.TMXTiledMap:create(string.format("tmxmaps/alliance_%s1.tmx",terrain))
            :align(display.LEFT_BOTTOM, 0, 0):addTo(bg_node)
    end, cc.TEXTURE2_D_PIXEL_FORMAT_RG_B565)

    local unlock_position = {
        {100,180},
        {100,720},
        {300,600},
        {250,350},
    }
    for i=1,4 do
        display.newSprite(string.format("unlock_tile_surface_%d_%s.png",i,terrain))
            :align(display.LEFT_CENTER, unlock_position[i][1], unlock_position[i][2])
            :addTo(bg_node)
    end
    -- 顶部和底部的树木
    local tree_width = 0 -- 已经填充了的宽度
    local count = 1
    -- 顶部
    while tree_width < 608 do
        count = count > 4 and 1 or count
        local tree = display.newSprite(string.format("tree_%d_%s.png",count,terrain))
            :align(display.LEFT_BOTTOM, tree_width,750)
            :addTo(bg_node)
        tree_width = tree_width + tree:getContentSize().width
        count = count + 1
    end
    -- 底部
    tree_width = 0
    count = 1
    while tree_width < 608 do
        count = count > 4 and 1 or count
        local tree = display.newSprite(string.format("tree_%d_%s.png",count,terrain))
            :align(display.LEFT_TOP, tree_width,140)
            :addTo(bg_node)
        tree_width = tree_width + tree:getContentSize().width
        count = count + 1
    end
    return bg_node
end



local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUIReplay:DoFte()
    local r = self.ui_map.close:getCascadeBoundingBox()
    WidgetFteArrow.new(_("点击关闭")):addTo(self.ui_map.close)
    :TurnDown():align(display.CENTER_BOTTOM, 0, r.height - 20)
end
function GameUIReplay:OnHandle(state)

end

return GameUIReplay


