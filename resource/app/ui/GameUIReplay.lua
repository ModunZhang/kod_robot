local Localize = import("..utils.Localize")
local window = import("..utils.window")
local promise = import("..utils.promise")
local cocos_promise = import("..utils.cocos_promise")
local BattleObject = import(".BattleObject")
local Effect = import(".Effect")
local Wall = import(".Wall")
local Corps = import(".Corps")
local UILib = import(".UILib")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetProgress = import("..widget.WidgetProgress")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetSoldierInBattle = import("..widget.WidgetSoldierInBattle")
local GameUIReplay = UIKit:createUIClass('GameUIReplay')

-- 攻击者默认在左边
local new_battle = {
    {
        left = {soldier = "lancer", star = 1, count = 1000, damage = 90, morale = 100, decrease = 20},
        right = {soldier = "catapult", star = 1, count = 100, damage = 80, morale = 100, decrease = 80},
        defeatAll = true,
        defeat = "right"
    },
    {
        left = {soldier = "lancer", star = 1, count = 1000, damage = 90, morale = 100, decrease = 20},
        right = {soldier = "catapult", star = 1, count = 100, damage = 80, morale = 100, decrease = 80},
        defeatAll = false,
        defeat = "right"
    },
-- {
--     left = {soldier = "lancer", count = 1000, damage = 90, morale = 100, decrease = 20},
--     right = {damage = 10, decrease = 10},
--     defeat = "right"
-- },
-- {
--     left = {damage = 90, decrease = 30},
--     right = {soldier = "wall", count = 1000, damage = 80, morale = 100, decrease = 90},
--     defeat = "right"
-- },
}
local function decode_battle_from_report(report)
    local attacks = report:GetFightAttackSoldierRoundData()
    local defends = report:GetFightDefenceSoldierRoundData()
    if report:IsFightWall() then
        assert(report.GetFightAttackWallRoundData)
        assert(report.GetFightDefenceWallRoundData)
        for i, v in ipairs(report:GetFightAttackWallRoundData()) do
            attacks[#attacks + 1] = v
        end
        for i, v in ipairs(report:GetFightDefenceWallRoundData()) do
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
        if attacker.soldierName ~= "wall" and defender.soldierName ~= "wall" then
            defeatAll = (((attacker.morale - attacker.moraleDecreased) <= 20
                or (attacker.soldierCount - attacker.soldierDamagedCount) <= 0) or not attacker.isWin)
                and (((defender.morale - defender.moraleDecreased) <= 20
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

function GameUIReplay:ctor(report, callback)
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
    assert(report.GetAttackDragonLevel)
    self.report = report
    self.callback = callback
    GameUIReplay.super.ctor(self)

    UILib.loadDragonAnimation()
    UILib.loadSolidersAnimation()

    local manager = ccs.ArmatureDataManager:getInstance()
    manager:addArmatureFileInfo(DEBUG_GET_ANIMATION_PATH("animations/paizi.ExportJson"))

    self.timer_node = display.newNode():addTo(self)
end
function GameUIReplay:OnMoveInStage()
    GameUIReplay.super.OnMoveInStage(self)
    display.newColorLayer(UIKit:hex2c4b(0x7a000000)):addTo(self)
    local back_width = 608
    local back_width_half = back_width / 2
    local back_height = 938
    local back_height_half = back_height / 2
    -- 背景
    local back_ground = WidgetUIBackGround.new({height = back_height})
        :addTo(self):align(display.CENTER, window.cx, window.cy)



    local rect = cc.rect(back_width_half - 590/2, back_height - 388 - 10, 590, 388)
    local clip = display.newClippingRegionNode(rect):addTo(back_ground)

    local battle = display.newNode():addTo(clip)
        :pos(back_width_half - 590/2, back_height - 388 - 10)
    self.battle = battle
    local battle_bg = cc.ui.UIImage.new("battle_bg_grass_772x388.png")
        :addTo(battle):align(display.CENTER, rect.width / 2, rect.height / 2)
    self.battle_bg = battle_bg
    self.damge_node = display.newNode():addTo(self.battle, 2)




    -- 按钮
    self.pass = cc.ui.UIPushButton.new(
        {normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("跳过"),
        size = 24,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(back_ground):align(display.CENTER, back_width - 100, 50)
        :onButtonClicked(function(event)
            self:ShowResult()
            self.close:show()
        end)

    self.close = cc.ui.UIPushButton.new(
        {normal = "yellow_btn_up_149x47.png",pressed = "yellow_btn_down_149x47.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("关闭"),
        size = 24,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(back_ground):align(display.CENTER, back_width - 100, 50)
        :onButtonClicked(function(event)
            self:LeftButtonClicked()
        end):hide()


    self.speedUp = cc.ui.UIPushButton.new(
        {normal = "yellow_btn_up_149x47.png",pressed = "yellow_btn_down_149x47.png"},
        {scale9 = false}
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("加速"),
        size = 24,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(back_ground):align(display.CENTER, 100, 50)
        :onButtonClicked(function(event)
            if self:Speed() == 1 then
                self.speedUp:setButtonLabelString(_("2x倍速"))
                self:SpeedUp(2)
            elseif self:Speed() == 2 then
                self.speedUp:setButtonLabelString(_("4x倍速"))
                self:SpeedUp(4)
            elseif self:Speed() == 4 then
                self.speedUp:setButtonLabelString(_("加速"))
                self:SpeedUp(1)
            end
        end)


    -- title
    local title = cc.ui.UIImage.new("background_288x60.png")
        :addTo(back_ground):pos(5, back_height - 65)
    self.left_name = cc.ui.UILabel.new({
        text = self.report:GetFightAttackName(),
        font = UIKit:getFontFilePath(),
        size = 22,
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.CENTER, 288/2, 60/2)
        :addTo(title)
    local title = cc.ui.UIImage.new("background_288x60.png")
        :addTo(back_ground):pos(back_width - 288 - 5, back_height - 65):flipX(true)
    self.right_name = cc.ui.UILabel.new({
        text = self.report:GetFightDefenceName(),
        font = UIKit:getFontFilePath(),
        size = 22,
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.CENTER, 288/2, 60/2)
        :addTo(title)

    local unit_bg = cc.ui.UIImage.new("unit_name_bg_blue_276x48.png")
        :addTo(back_ground):pos(7, back_height - 65 - 39)
    self.left_soldier = cc.ui.UILabel.new({
        text = "",
        font = UIKit:getFontFilePath(),
        size = 20,
        color = UIKit:hex2c3b(0xffedae)
    }):align(display.CENTER, 276/2, 48/2)
        :addTo(unit_bg)

    local unit_bg = cc.ui.UIImage.new("unit_name_bg_red_276x48.png")
        :addTo(back_ground):pos(back_width - 276 - 7, back_height - 65 - 39)
    self.right_soldier = cc.ui.UILabel.new({
        text = "",
        font = UIKit:getFontFilePath(),
        size = 20,
        color = UIKit:hex2c3b(0xffedae)
    }):align(display.CENTER, 276/2, 48/2)
        :addTo(unit_bg)


    local vs_background_114x114 = cc.ui.UIImage.new("vs_background_114x114.png")
        :addTo(back_ground):align(display.CENTER, back_width_half, back_height - 114/2)
    cc.ui.UIImage.new("vs_73x47.png")
        :addTo(vs_background_114x114):align(display.CENTER, 114/2, 114/2)


    local unit_info_bg = cc.ui.UIImage.new("background_blue_342x70.png")
        :addTo(back_ground):align(display.LEFT_TOP, 10, back_height - 388 - 13)
    self.left_count = cc.ui.UILabel.new({
        text = "",
        font = UIKit:getFontFilePath(),
        size = 20,
        color = UIKit:hex2c3b(0xffedae)
    }):align(display.LEFT_CENTER, 10, 53)
        :addTo(unit_info_bg)

    self.left_category = cc.ui.UILabel.new({
        text = "",
        font = UIKit:getFontFilePath(),
        size = 20,
        color = UIKit:hex2c3b(0xffedae)
    }):align(display.RIGHT_CENTER, 240, 53)
        :addTo(unit_info_bg)


    local progress = WidgetProgress.new(UIKit:hex2c3b(0xffedae), "progress_bg_224x30.png", "progress_224x30.png", {
        icon_bg = "icon_bg_38x40.png",
        icon = "icon_32x34.png",
        bar_pos = {x = 0,y = 0}
    }):addTo(unit_info_bg):align(display.LEFT_CENTER, 20, 20)

    self.left_progress = progress

    self.left_morale = cc.ui.UILabel.new({
        text = "",
        font = UIKit:getFontFilePath(),
        size = 20,
        color = UIKit:hex2c3b(0xffedae)
    }):align(display.LEFT_CENTER, 50, 20)
        :addTo(unit_info_bg)

    local unit_info_bg = cc.ui.UIImage.new("background_red_342x70.png")
        :addTo(back_ground):align(display.RIGHT_TOP, back_width - 10, back_height - 388 - 13)

    self.right_count = cc.ui.UILabel.new({
        text = "",
        font = UIKit:getFontFilePath(),
        size = 20,
        color = UIKit:hex2c3b(0xffedae)
    }):align(display.RIGHT_CENTER, 342 - 10, 53)
        :addTo(unit_info_bg)

    self.right_category = cc.ui.UILabel.new({
        text = "",
        font = UIKit:getFontFilePath(),
        size = 20,
        color = UIKit:hex2c3b(0xffedae)
    }):align(display.LEFT_CENTER, 342 - 240, 53)
        :addTo(unit_info_bg)

    local progress = WidgetProgress.new(UIKit:hex2c3b(0xffedae), "progress_bg_224x30.png", "progress_224x30.png", {
        icon_bg = "icon_bg_38x40.png",
        icon = "icon_32x34.png",
        bar_pos = {x = 0,y = 0}
    }):addTo(unit_info_bg):align(display.LEFT_CENTER, 342 - 20, 20)
    progress:setScaleX(-1)
    self.right_progress = progress

    self.right_morale = cc.ui.UILabel.new({
        text = "",
        font = UIKit:getFontFilePath(),
        size = 20,
        color = UIKit:hex2c3b(0xffedae)
    }):align(display.RIGHT_CENTER, 342 - 50, 20)
        :addTo(unit_info_bg)

    cc.ui.UIImage.new("line_600x30.png")
        :addTo(back_ground):align(display.CENTER, back_width_half, back_height - 388)
    local bg = cc.ui.UIImage.new("back_ground_82x82.png")
        :addTo(back_ground):align(display.CENTER, back_width_half, back_height - 388 - 48)
    local size = bg:getContentSize()
    self.strong = display.newSprite("vs_strong.png"):addTo(bg):pos(size.width / 2, size.height /2):hide()
    self.weak = display.newSprite("vs_weak.png"):addTo(bg):pos(size.width / 2, size.height /2):hide()

    local battle = decode_battle_from_report(self.report)
    -- local battle = new_battle
    dump(battle)

    local x, y = bg:getPosition()
    self.list_view = self:CreateVerticalListViewDetached(0, 80, back_ground:getContentSize().width, y - 82 / 2):addTo(back_ground)
    local attacker_soldiers = self.report:GetOrderedAttackSoldiers()
    local defencer_soldiers = self.report:GetOrderedDefenceSoldiers()
    defencer_soldiers[#defencer_soldiers + 1] = self.report:IsFightWall() and {name = "wall", star = 1} or nil
    local round = {}
    for i = 1, math.max((#attacker_soldiers),(#defencer_soldiers)) do
        local left, right = attacker_soldiers[i], defencer_soldiers[i]
        table.insert(round, {left = left, right = right})
    end
    local left_corps = {}
    local right_corps = {}
    for i, dual in ipairs(round) do
        local item, left, right = self:CreateItemWithListView(self.list_view, dual)
        table.insert(left_corps, left)
        table.insert(right_corps, right)
        self.list_view:addItem(item)
    end
    self.list_view:reload()

    self.left_corps = left_corps
    self.right_corps = right_corps
    self.left_round = 0
    self.right_round = 0
    self.left_morale_max = 0
    self.right_morale_max = 0
    self.left_morale_cur = self.left_morale_max
    self.right_morale_cur = self.right_morale_max

    if self.report:IsDragonFight() then
        self:PlayDragonBattle():next(function()
            return self:PlaySoldierBattle(decode_battle(battle))
        end):next(function()
            self:ShowResult()
        end):catch(function(err)
            dump(err:reason())
        end)
    else
        self:PlaySoldierBattle(decode_battle(battle)):next(function()
            self:ShowResult()
        end):catch(function(err)
            dump(err:reason())
        end)
    end
    app:GetAudioManager():PlayGameMusic("AllianceBattleScene")
end
function GameUIReplay:ShowResult()
    if not self.showed_result then
        if self.report:GetReportResult() then
            display.newSprite("victory_459x194.png"):addTo(self):pos(window.cx, window.cy + 250)
            app:GetAudioManager():PlayeEffectSoundWithKey("BATTLE_VICTORY")
        else
            display.newSprite("defeat_469x263.png"):addTo(self):pos(window.cx, window.cy + 250)
            app:GetAudioManager():PlayeEffectSoundWithKey("BATTLE_DEFEATED")
        end
        self.showed_result = true
    end
    self.pass:hide()
    self.close:show()
    self:Stop()
end
function GameUIReplay:onExit()
    GameUIReplay.super.onExit(self)
    app:GetAudioManager():PlayGameMusic()
    if type(self.callback) == "function" then
        self.callback()
    end
end
function GameUIReplay:PlayDragonBattle()
    local report = self.report
    local attack_dragon = report:GetFightAttackDragonRoundData()
    local defend_dragon = report:GetFightDefenceDragonRoundData()

    self.dragon_battle = self:NewDragonBattle()
    local dp = promise.new(self:Delay(0.1)):next(function()
        return self:Performance(0.5, function(percent)
            if attack_dragon then
                self.left_dragon:SetHp(attack_dragon.hp - percent * attack_dragon.hpDecreased, attack_dragon.hpMax)
            end
            if defend_dragon then
                self.right_dragon:SetHp(defend_dragon.hp - percent * defend_dragon.hpDecreased, defend_dragon.hpMax)
            end
        end)
    end):next(self:Delay(0.8))
        :next(function()
            local left_p
            if attack_dragon then
                left_p = self.left_dragon:ShowResult(attack_dragon.isWin)
            end
            local right_p
            if defend_dragon then
                right_p = self.right_dragon:ShowResult(defend_dragon.isWin)
            end
            return left_p or right_p
        end)
        :next(self:Delay(0.8))
        :next(function()
            if attack_dragon and self.left_dragon then
                self.left_dragon:ShowBuff()
            end
            if defend_dragon and self.right_dragon then
                self.right_dragon:ShowBuff()
            end
            return self:Performance(0.5, function(percent)
                if attack_dragon then
                    local d = attack_dragon.isWin and 100 or 50
                    self.left_dragon:SetBuff(string.format("BUFF + %d%%", math.floor(percent * d)))
                end
                if defend_dragon then
                    local d = defend_dragon.isWin and 100 or 50
                    self.right_dragon:SetBuff(string.format("BUFF + %d%%", math.floor(percent * d)))
                end
            end)
        end)
        :next(self:Delay(0.8))
        :next(function()
            local p = promise.new()
            self.dragon_battle:getAnimation():setMovementEventCallFunc(function(armatureBack, movementType, movementID)
                if movementType == ccs.MovementEventType.complete then
                    p:resolve(self)
                end
            end)
            self.dragon_battle:getAnimation():play("Animation2", -1, 0)
            self.dragon_battle:getAnimation():setSpeedScale(self:Speed())
            return p
        end)
        :next(self:Delay(0.8))

    promise.new():next(self:Delay(0.2)):next(function()
        if self.dragon_battle then
            self.dragon_battle:getAnimation():play("Animation1", -1, 0)
            self.dragon_battle:getAnimation():setSpeedScale(self:Speed())
            app:GetAudioManager():PlayeEffectSoundWithKey("BATTLE_DRAGON")
        end
    end):resolve()
    --

    self.dragon_battle:getAnimation():setMovementEventCallFunc(function(armatureBack, movementType, movementID)
        if movementType == ccs.MovementEventType.complete then
            dp:resolve(self)
        end
    end)

    return dp
end
function GameUIReplay:PlaySoldierBattle(soldier_battle)
    local rounds = promise.new()
    for i, round in ipairs(soldier_battle) do
        rounds:next(function()
            local pa
            for _, v in ipairs(round) do
                local left, right = unpack(v)
                local left_action = self:DecodeStateBySide(left, true)
                local right_action = self:DecodeStateBySide(right, false)
                if not pa then
                    pa = promise.all(left_action:resolve(self.left), right_action:resolve(self.right))
                else
                    pa:next(function(result)
                        local left, right = unpack(result)
                        return promise.all(left_action:resolve(left), right_action:resolve(right))
                    end)
                end
            end
            return pa
        end)
    end
    return cocos_promise.defferPromise(rounds)
end
function GameUIReplay:NewDragonBattle()
    local report = self.report
    local attack_dragon = report:GetFightAttackDragonRoundData()
    local defend_dragon = report:GetFightDefenceDragonRoundData()
    local dragon_battle = ccs.Armature:create("paizi"):addTo(self.battle):align(display.CENTER, 275, 155)

    local left_bone = dragon_battle:getBone("Layer4")
    local left_dragon = self:NewDragon(true):addTo(left_bone):pos(-360, -50)
    left_bone:addDisplay(left_dragon, 0)
    left_bone:changeDisplayWithIndex(0, true)
    self.left_dragon = left_dragon
    self.left_dragon:SetHp(attack_dragon.hp, attack_dragon.hpMax)

    local is_pve_battle = self.report.IsPveBattle
    local right_bone = dragon_battle:getBone("Layer5")
    local right_dragon = self:NewDragon(nil, is_pve_battle):addTo(right_bone):pos(238, -82)
    right_bone:addDisplay(right_dragon, 0)
    right_bone:changeDisplayWithIndex(0, true)
    self.right_dragon = right_dragon
    self.right_dragon:SetHp(defend_dragon.hp, defend_dragon.hpMax)
    return dragon_battle
end
local dragon_ani_map = {
    redDragon   = {   "red_long", 100, 0, 0.6},
    blueDragon  = {  "blue_long", 100, 0, 0.6},
    greenDragon = { "green_long", 100, 0, 0.6},
    blackDragon = {    "heilong", 100,50,   1},
}
function GameUIReplay:NewDragon(is_left, is_pve_battle)
    local node = display.newNode()
    local game_ui_replay = self
    function node:Init()
        local dragon_type = "redDragon"
        if is_left then
            local attack_dragon = game_ui_replay.report:GetFightAttackDragonRoundData()
            dragon_type = attack_dragon.dragonType
        else
            local defend_dragon = game_ui_replay.report:GetFightDefenceDragonRoundData()
            dragon_type = defend_dragon.dragonType
        end
        self.name = cc.ui.UILabel.new({
            text = string.format("%s(等级%d)", Localize.dragon[dragon_type], game_ui_replay.report:GetAttackDragonLevel()),
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0xffedae)
        }):align(display.CENTER, 45, 180)
            :addTo(self)

        self.progress = display.newProgressTimer("progress_bar_262x16.png", display.PROGRESS_TIMER_BAR)
        :addTo(self):align(display.LEFT_CENTER, is_left and -85 or 170, 158):setScaleX(is_left and 0.975 or -0.975)
        self.progress:setBarChangeRate(cc.p(1,0))
        self.progress:setMidpoint(cc.p(0,0))

        self.hp = cc.ui.UILabel.new({
            text = "",
            font = UIKit:getFontFilePath(),
            size = 14,
            color = UIKit:hex2c3b(0xffedae)
        }):align(display.CENTER, 45, 160)
            :addTo(self)


        self.result = cc.ui.UILabel.new({
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x00be36)
        }):align(display.CENTER, is_left and 120 or -35, -55)
            :addTo(self):hide()

        self.buff = cc.ui.UILabel.new({
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x00be36)
        }):align(display.CENTER, is_left and 20 or 80, -55)
            :addTo(self):hide()
        local ani_name, left_x, right_x, scale = unpack(dragon_ani_map[dragon_type])
        local dragon = ccs.Armature:create(ani_name)
            :addTo(self):align(display.CENTER, is_left and left_x or right_x, 60):scale(0.6)
        dragon:getAnimation():play("idle", -1, -1)
        dragon:setScale(is_left and scale or - scale, scale)
    end
    function node:SetName()
        return self
    end
    function node:SetHp(cur, total)
        self.hp:setString(string.format("%d/%d", math.floor(cur), math.floor(total)))
        self.progress:setPercentage(cur / total * 100)
        return self
    end
    function node:SetReulst(is_win)
        local color = is_win and UIKit:hex2c3b(0x00be36) or UIKit:hex2c3b(0xff0000)
        self.result:setColor(color)
        self.buff:setColor(color)
        self.result:setString(is_win and "WIN" or "LOSE")
        return self
    end
    function node:ShowResult(is_win)
        local p = promise.new()
        self:SetReulst(is_win)
        transition.scaleTo(self.result:scale(3):show(), {
            scale = 1,
            time = 0.15,
            onComplete = function()
                p:resolve()
            end})
        return p
    end
    function node:SetBuff(buff)
        self.buff:setString(buff)
        return self
    end
    function node:ShowBuff()
        self.buff:show()
        return self
    end
    node:Init()
    return node
end
function GameUIReplay:NewWall(x)
    return Wall.new(self):addTo(self.battle_bg):pos(x, 150)
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
function GameUIReplay:NewCorps(soldier, star, x, y, is_pve_battle)
    local arrange = soldier_arrange[soldier]
    return Corps.new(soldier, star, arrange.row, arrange.col, nil, nil, is_pve_battle, self):addTo(self.battle):pos(x, y)
end
function GameUIReplay:NewEffect(soldier, is_left, x, y)
    if soldier == "wall" then return end
    local arrange = soldier_arrange[soldier]
    local w = is_left and 100 or -100
    local effect = Effect.new(soldier, arrange.row, arrange.col):addTo(self.battle):pos(x + w, y)
    if is_left then
        effect:turnRight()
    else
        effect:turnLeft()
    end
    effect:OnAnimationPlayEnd("attack_1", function()
        effect:removeFromParent()
    end)
    effect:PlayAnimation("attack_1", 0)
end
function GameUIReplay:DecodeStateBySide(side, is_left)
    local height = 130
    local len = 230
    local left_start = {x = -100, y = height}
    local left_end = {x = left_start.x + len, y = height}
    local right_start = {x = 700, y = height}
    local right_end = {x = right_start.x - len, y = height}
    local action
    local state = side.state
    local is_pve_battle = self.report.IsPveBattle
    if state == "enter" then
        if is_left then
            if side.soldier == "wall" then
                self.left = self:NewWall(50)
                action = promise.new(function(wall)
                    self:NextSoldierBySide("left")
                    return wall
                end):next(BattleObject:TurnRight()):next(function()
                    return promise.new(GameUIReplay:MoveBattleBgBy(90))
                        :next(function()
                            return self.left
                        end):resolve(self.battle_bg)
                end)
            else
                self.left = self:NewCorps(side.soldier, side.star, left_start.x, left_start.y)
                action = BattleObject:Do(function(corps)
                    self:NextSoldierBySide("left")
                    return corps
                end):next(BattleObject:MoveTo(2, left_end.x, left_end.y))
                    :next(BattleObject:BreathForever())
            end
            self.left_category:setString(Localize.getSoldierCategoryByName(side.soldier))
            self.left_soldier:setString(Localize.soldier_name[side.soldier])
            self.left_count:setString(side.count)

            self.left_morale_max = side.morale
            self.left_morale_cur = self.left_morale_max
            local percent = (self.left_morale_cur / self.left_morale_max) * 100
            self.left_morale:setString(percent.."%")
            self.left_progress:SetProgressInfo("", percent)
        else
            if side.soldier == "wall" then
                self.right = self:NewWall(730)
                action = promise.new(function(wall)
                    self:NextSoldierBySide("right")
                    return wall
                end):next(BattleObject:TurnLeft()):next(function()
                    return promise.new(GameUIReplay:MoveBattleBgBy(-90))
                        :next(function()
                            return self.right
                        end):resolve(self.battle_bg)
                end)
            else
                self.right = self:NewCorps(side.soldier, side.star, right_start.x, right_start.y, is_pve_battle)
                action = BattleObject:Do(function(corps)
                    self:NextSoldierBySide("right")
                    return corps
                end):next(BattleObject:TurnLeft())
                    :next(BattleObject:MoveTo(2, right_end.x, right_end.y))
                    :next(BattleObject:BreathForever())
            end
            self.right_category:setString(Localize.getSoldierCategoryByName(side.soldier))
            self.right_soldier:setString(Localize.soldier_name[side.soldier])
            self.right_count:setString(side.count)

            self.right_morale_max = side.morale
            self.right_morale_cur = self.right_morale_max
            local percent = (self.right_morale_cur / self.right_morale_max) * 100
            self.right_morale:setString(percent.."%")
            self.right_progress:SetProgressInfo("", percent)
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
        action = BattleObject:Do(function(corps)
            if is_left then
                self.left_count:setString(tonumber(self.left_count:getString()) - side.damage)

                self.left_morale_cur = self.left_morale_cur - side.decrease
                local percent = (self.left_morale_cur / self.left_morale_max) * 100
                self.left_morale:setString(percent.."%")
                self.left_progress:SetProgressInfo("", percent)
            else
                self.right_count:setString(tonumber(self.right_count:getString()) - side.damage)

                self.right_morale_cur = self.right_morale_cur - side.decrease
                local percent = (self.right_morale_cur / self.right_morale_max) * 100
                self.right_morale:setString(percent.."%")
                self.right_progress:SetProgressInfo("", percent)
            end
            local x,y = corps:getPosition()
            self:PlayDamageCount(side.damage, x, y)
            return corps
        end):next(BattleObject:HitOnce()):next(function(corps)
            BattleObject:Do(BattleObject:BreathForever()):resolve(corps)
            return corps
        end)
    elseif state == "move" then
        action = BattleObject:Do(BattleObject:Move())
    elseif state == "defeat" then
        action = BattleObject:Do(function(corps)
            self:SetCurrentSoldierStateBySide(is_left and "left" or "right", "defeated")
            return corps
        end):next(BattleObject:Defeat()):next(function(corps)
            if corps == self.left then
                self.left = nil
            elseif corps == self.right then
                self.right = nil
            end
            corps:removeFromParent()
            return corps
        end)
    else
        assert(false, "不支持这个动作!")
    end
    return action
end
function GameUIReplay:CreateItemWithListView(list_view, dual)
    local gap = 10
    local row_item = display.newNode()
    local left, right = dual.left, dual.right
    local left_item, right_item
    if left then
        left_item = WidgetSoldierInBattle.new("back_ground_284x128.png",
            {side = "blue", soldier = left.name, star = left.star}):addTo(row_item)
            :align(display.CENTER, -284/2 - gap, 0)
    end
    if right then
        right_item = WidgetSoldierInBattle.new("back_ground_284x128.png",
            {side = "red", soldier = right.name, star = right.star, is_pve_battle = self.report.IsPveBattle}):addTo(row_item)
            :align(display.CENTER, 284/2 + gap, 0)
    end
    -- row_item:setContentSize(cc.size(284 * 2, 128))
    local item = list_view:newItem()
    item:addContent(row_item)
    item:setItemSize(284 * 2, 128)
    return item, left_item, right_item
end
function GameUIReplay:SetCurrentSoldierStateBySide(side, status)
    if side == "left" then
        self.left_corps[self.left_round]:SetUnitStatus(status)
    elseif side == "right" then
        self.right_corps[self.right_round]:SetUnitStatus(status)
    else
        assert(false)
    end
end
function GameUIReplay:NextSoldierBySide(side)
    if side == "left" then
        self.left_round = self.left_round + 1
        self.left_corps[self.left_round]:SetUnitStatus("fighting")
    elseif side == "right" then
        self.right_round = self.right_round + 1
        self.right_corps[self.right_round]:SetUnitStatus("fighting")
    else
        assert(false)
    end
    if self.right_round > 0 and self.left_round > 0 then
        self:ShowSoldierVSStatus(self.left_corps[self.left_round]:GetSoldierName(),
            self.right_corps[self.right_round]:GetSoldierName())
    end
end
function GameUIReplay:ShowSoldierVSStatus(soldier_name_left, soldier_name_right)
    self:ShowStrongOrWeak(GameUtils:GetVSFromSoldierName(soldier_name_left, soldier_name_right))
end
function GameUIReplay:ShowStrongOrWeak(vs)
    if vs == "strong" then
        self.strong:setVisible(true)
        self.weak:setVisible(false)
    elseif vs == "weak" then
        self.strong:setVisible(false)
        self.weak:setVisible(true)
    else
        self.strong:hide()
        self.weak:hide()
    end
end
local timer = app.timer
local SPEED_TAG = 1
local PERFORMANCE_TAG = 2
function GameUIReplay:SpeedUp(speed)
    self.speed = speed or 1
    local a1 = self.timer_node:getActionByTag(SPEED_TAG)
    if a1 then
        a1:setSpeed(self:Speed())
    end
    local a2 = self.timer_node:getActionByTag(PERFORMANCE_TAG)
    if a2 then
        a2:setSpeed(self:Speed())
    end
    local a3 = self.battle_bg:getActionByTag(SPEED_TAG)
    if a3 then
        a3:setSpeed(self:Speed())
    end
    for i,v in ipairs(self.damge_node:getChildren()) do
        local a = v:getActionByTag(SPEED_TAG)
        if a then
            a:setSpeed(self:Speed())
        end
    end

    if self.dragon_battle then
        self.dragon_battle:getAnimation():setSpeedScale(self:Speed())
    end
    if self.left then
        self.left:RefreshSpeed()
    end
    if self.right then
        self.right:RefreshSpeed()
    end
end
function GameUIReplay:Stop()
    for i,v in ipairs(self.damge_node:getChildren()) do
        v:stopAllActions()
    end
    self.timer_node:stopAllActions()
    self.battle_bg:stopAllActions()
    if self.dragon_battle then
        self.dragon_battle:getAnimation():stop()
    end
    if self.left then
        self.left:Stop()
    end
    if self.right then
        self.right:Stop()
    end
end
function GameUIReplay:Speed()
    return self.speed or 1
end
function GameUIReplay:PlayDamageCount(count, x, y)
    local label = UIKit:ttfLabel({
        text = "-"..count,
        size = 30,
        color = 0xff0000,
    }):addTo(self.damge_node):pos(x, y)

    local speed = cc.Speed:create(transition.sequence({
        -- cc.Spawn:create({cc.MoveBy:create(0.5, cc.p(0, 20)), cc.FadeTo:create(0.5, 0)}),
        cc.MoveBy:create(0.6, cc.p(0, 20)),
        cc.RemoveSelf:create(),
    }), self:Speed())
    speed:setTag(SPEED_TAG)
    label:runAction(speed)
end
function GameUIReplay:MoveBattleBgBy(x)
    return function(battle_bg)
        local p = promise.new()
        local speed = cc.Speed:create(transition.sequence({
            cc.MoveBy:create(1, cc.p(x, 0)),
            cc.CallFunc:create(function()
                p:resolve(battle_bg)
            end),
        }), self:Speed())
        speed:setTag(SPEED_TAG)
        battle_bg:runAction(speed)
        return p
    end
end
function GameUIReplay:PromiseOfDelay(time, func)
    local p = promise.new(func)
    local speed = cc.Speed:create(transition.sequence({
        cc.DelayTime:create(time),
        cc.CallFunc:create(function()
            p:resolve()
        end),
    }), self:Speed())
    speed:setTag(SPEED_TAG)
    self.timer_node:runAction(speed)
    return p
end
function GameUIReplay:Delay(time)
    return function(obj)
        return self:PromiseOfDelay(time, function() return obj end)
    end
end
function GameUIReplay:Performance(time, func)
    local p = promise.new()
    local start_time = timer:GetServerTime()
    local speed = cc.Speed:create(
        cc.RepeatForever:create(
            transition.sequence({
                cc.DelayTime:create(0.05),
                cc.CallFunc:create(function()
                    local t = timer:GetServerTime() - start_time
                    if t > time then
                        func(1)
                        p:resolve()
                        self.timer_node:stopActionByTag(PERFORMANCE_TAG)
                    else
                        if type(func) == "function" then
                            func(t / time)
                        end
                    end
                end)
            })
        ),  self:Speed())
    speed:setTag(PERFORMANCE_TAG)
    self.timer_node:runAction(speed)
    return p
end


return GameUIReplay




