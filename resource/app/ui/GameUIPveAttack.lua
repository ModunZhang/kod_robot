local UILib = import(".UILib")
local Localize = import("..utils.Localize")
local Localize_pve = import("..utils.Localize_pve")
local window = import("..utils.window")
local WidgetUseItems = import("..widget.WidgetUseItems")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local GameUIPveAttack = class("GameUIPveAttack", WidgetPopDialog)
local stages = GameDatas.PvE.stages
local sections = GameDatas.PvE.sections
local special = GameDatas.Soldiers.special
local titles = {
    _("战斗胜利"),
    _("龙在战斗中胜利"),
    _("第一轮击败敌军"),
}



function GameUIPveAttack:ctor(user, pve_name)
    self.user = user
    self.pve_name = pve_name
    local level,index = unpack(string.split(pve_name, "_"))
    self.titlename = string.format(_("第%d章-第%d节"), tonumber(level), tonumber(index))
    if self.user:IsPveBoss(self.pve_name) then
        if self.user:IsPveBossPassed(self.pve_name) then
            GameUIPveAttack.super.ctor(self, 300, self.titlename, window.top - 300,nil,{color = UIKit:hex2c4b(0x00000000)})
        else
            GameUIPveAttack.super.ctor(self, 480, self.titlename, window.top - 160,nil,{color = UIKit:hex2c4b(0x00000000)})
        end
    else
        GameUIPveAttack.super.ctor(self,680, self.titlename, window.top - 160,nil,{color = UIKit:hex2c4b(0x00000000)})
    end
    self.__type  = UIKit.UITYPE.BACKGROUND
end
function GameUIPveAttack:OnMoveInStage()
    if self.user:IsPveBoss(self.pve_name) then
        self:BuildBossUI()
    else
        self:BuildNormalUI()
    end
    self:RefreshUI()
    display.newNode():addTo(self):schedule(function()
        self:RefreshUI()
    end, 1)
    GameUIPveAttack.super.OnMoveInStage(self)
end
function GameUIPveAttack:BuildNormalUI()
    local size = self:GetBody():getContentSize()
    self.items = {}
    local sbg = display.newSprite("pve_bg.png"):addTo(self:GetBody()):pos(size.width/2, size.height - 55)
    display.newSprite("tmp_pve_star_bg.png"):addTo(sbg):pos(size.width/2 - 60, 35):scale(0.8)
    self.items[1] = display.newSprite("tmp_pve_star.png"):addTo(sbg):pos(size.width/2 - 60, 35):scale(0.8)

    display.newSprite("tmp_pve_star_bg.png"):addTo(sbg):pos(size.width/2, 35)
    self.items[2] = display.newSprite("tmp_pve_star.png"):addTo(sbg):pos(size.width/2, 35)

    display.newSprite("tmp_pve_star_bg.png"):addTo(sbg):pos(size.width/2 + 60, 35):scale(0.8)
    self.items[3] = display.newSprite("tmp_pve_star.png"):addTo(sbg):pos(size.width/2 + 60, 35):scale(0.8)


    local star = self.user:GetPveSectionStarByName(self.pve_name)
    local list,list_node = UIKit:commonListView_1({
        viewRect = cc.rect(0, 0, 550, 120),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    })
    list.touchNode_:setTouchEnabled(false)
    list_node:addTo(self:GetBody()):pos(20, size.height - 245)
    for i = 1, 3 do
        local item = list:newItem()
        local content = self:GetListItem(i,titles[i])
        item:addContent(content)
        item:setItemSize(600,40)
        list:addItem(item)
    end
    list:reload()
    self.list = list

    self.widgets = display.newNode():addTo(self:GetBody())

    display.newSprite("tmp_label_line.png"):addTo(self.widgets):align(display.RIGHT_CENTER, size.width/2 - 85, size.height - 270):flipX(true)
    display.newSprite("tmp_label_line.png"):addTo(self.widgets):align(display.LEFT_CENTER, size.width/2 + 85, size.height - 270)
    UIKit:ttfLabel({
        text = _("几率掉落"),
        size = 20,
        color = 0x403c2f,
    }):addTo(self.widgets):align(display.CENTER, size.width/2, size.height - 270)

    WidgetUIBackGround.new({width = 568,height = 140},
        WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :addTo(self.widgets):pos((size.width - 568) / 2, size.height - 430)

    local rewards = LuaUtils:table_map(string.split(sections[self.pve_name].rewards, ","), function(k,v)
        local type,name = unpack(string.split(v, ":"))
        return k, {type = type, name = name}
    end)
    dump(rewards,"rewards")
    local skipw = 1.5
    local count = 10
    local w = (count - skipw * 2) / (#rewards - 1)
    for i,v in ipairs(rewards) do
        local png
        if v.type == "resources" then
            png = UILib.resource[v.name]
        elseif v.type == "soldierMaterials" then
            png = UILib.soldier_metarial[v.name]
        end
        display.newSprite(png)
            :addTo(
                display.newSprite("box_118x118.png"):addTo(self.widgets)
                    :pos(size.width*(skipw + (i-1) * w) / count, size.height - 360)
            ):pos(118/2, 118/2):scale(100/128)
    end


    self.label = UIKit:ttfLabel({
        text = string.format(_("今日可挑战次数: %d/%d"), self.user:GetFightCountByName(self.pve_name), sections[self.pve_name].maxFightCount),
        size = 22,
        color = 0x615b44,
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
    }):addTo(self:GetBody()):align(display.LEFT_CENTER,25,size.height - 460)

    display.newSprite("sweep_128x128.png"):addTo(self:GetBody()):align(display.CENTER,40,size.height - 510):scale(0.25)
    local label = UIKit:ttfLabel({
        text = _("拥有扫荡劵 : "),
        size = 22,
        color = 0x615b44,
    }):addTo(self:GetBody()):align(display.LEFT_CENTER,70,size.height - 510)

    local User = self.user
    self.sweep_label = UIKit:ttfLabel({
        text = User:GetItemCount("sweepScroll"),
        size = 22,
        color = User:GetItemCount("sweepScroll") > 0 and 0x615b44 or 0x7e00000,
    }):addTo(self:GetBody()):align(display.LEFT_CENTER,70 + label:getContentSize().width,size.height - 510)


    self.sweep_all = self:CreateSweepButton():setButtonLabelString(_("扫荡全部"))
        :align(display.CENTER, 100, size.height - 580):addTo(self:GetBody())
        :onButtonClicked(function()
            self:CheckMaterials(function()
                self:Sweep(self.user:GetPveLeftCountByName(self.pve_name))
            end)
        end)

    self.sweep_once = self:CreateSweepButton():setButtonLabelString(_("扫荡一次"))
        :align(display.CENTER, size.width/2, size.height - 580):addTo(self:GetBody())
        :onButtonClicked(function(event)
            self:CheckMaterials(function()
                self:Sweep(1)
            end)
        end)
    self.attack = self:CreateAttackButton():align(display.CENTER, size.width - 100,size.height - 580)
    UIKit:ttfLabel({
        text = _("关卡三星通关后，可使用扫荡"),
        size = 18,
        color = 0x615b44,
    }):addTo(self:GetBody()):align(display.CENTER,size.width/2,size.height - 640)
end
function GameUIPveAttack:BuildBossUI()
    local size = self:GetBody():getContentSize()
    local w,h = size.width, size.height
    display.newSprite("alliance_item_flag_box_126X126.png")
        :align(display.CENTER, 95, h - 110)
        :scale(136/126):addTo(self:GetBody())

    display.newSprite("pve_moonGate.png")
    :addTo(self:GetBody()):pos(95, h - 110):scale(0.8)

    UIKit:ttfLabel({
        text = _("你能感觉到一个一场强大的生物驻守在这里, 阻挡着你继续前进, 但想要前往下一关卡必须击败它。"),
        size = 18,
        color = 0x615b44,
        dimensions = cc.size(350,0)
    }):align(display.LEFT_TOP, 180, h - 40):addTo(self:GetBody())

    self.widgets = display.newNode():addTo(self:GetBody())

    display.newSprite("tmp_label_line.png"):addTo(self.widgets):align(display.RIGHT_CENTER, size.width/2 - 85, size.height - 200):flipX(true)
    display.newSprite("tmp_label_line.png"):addTo(self.widgets):align(display.LEFT_CENTER, size.width/2 + 85, size.height - 200)
    UIKit:ttfLabel({
        text = _("几率掉落"),
        size = 20,
        color = 0x403c2f,
    }):addTo(self.widgets):align(display.CENTER, size.width/2, size.height - 200)


    WidgetUIBackGround.new({width = 568,height = 140},
        WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :addTo(self.widgets):pos((size.width - 568) / 2, size.height - 370)

    local rewards = LuaUtils:table_map(string.split(sections[self.pve_name].rewards, ","), function(k,v)
        local type,name = unpack(string.split(v, ":"))
        return k, {type = type, name = name}
    end)
    local skipw = 1.5
    local count = 10
    local w = (count - skipw * 2) / (#rewards - 1)
    for i,v in ipairs(rewards) do
        local png
        if v.type == "items" then
            png = UILib.item[v.name]
        elseif v.type == "soldierMaterials" then
            png = UILib.soldier_metarial[v.name]
        end
        display.newSprite(png)
            :addTo(
                display.newSprite("box_118x118.png"):addTo(self.widgets)
                    :pos(size.width*(skipw + (i-1) * w) / count, size.height - 300)
            ):pos(118/2, 118/2):scale(100/128)
    end


    if self.user:IsPveBossPassed(self.pve_name) then
        UIKit:ttfLabel({
            text = _("已通关"),
            size = 22,
            color = 0x007c23,
        }):addTo(self:GetBody()):align(display.CENTER, size.width/2, size.height - 200)
    end



    self.tp = cc.ui.UIPushButton.new(
        {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"},
        {scale9 = false}
    ):addTo(self:GetBody())
        :align(display.CENTER, size.width/2,
            self.user:IsPveBossPassed(self.pve_name) and
            size.height - 250 or size.height - 420)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("传送") ,
            size = 22,
            color = 0xffedae,
            shadow = true
        })):onButtonClicked(function(event)
        app:EnterPVEScene(self.user:GetNextStageByPveName(self.pve_name))
        end)


    self.txt1 = UIKit:ttfLabel({
        text = _("每次消耗体力:"),
        size = 20,
        color = 0x403c2f,
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
    }):addTo(self:GetBody()):align(display.LEFT_CENTER,20,size.height - 420)


    self.txt2 = UIKit:ttfLabel({
        text = string.format("-%d", sections[self.pve_name].staminaUsed),
        size = 20,
        color = 0x7e0000,
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
    }):addTo(self:GetBody()):align(display.LEFT_CENTER,20 + self.txt1:getContentSize().width + 20,size.height - 420)

    self.button = self:CreateAttackButton():align(display.CENTER, size.width - 100,size.height - 420)
end
local hide = function(obj)
    if obj then obj:hide() end
end
local show = function(obj)
    if obj then obj:show() end
end
function GameUIPveAttack:RefreshUI()
    local User = self.user
    if self.user:IsPveBoss(self.pve_name) then
        if self.user:IsPveBossPassed(self.pve_name) then
            if self.user:HasNextStageByPveName(self.pve_name) then
                show(self.tp)
            else
                hide(self.tp)
            end
            hide(self.txt1)
            hide(self.txt2)
            hide(self.button)
            hide(self.widgets)
        else
            hide(self.tp)
            show(self.txt1)
            show(self.txt2)
            show(self.button)
            show(self.widgets)
        end
    else
        local star = self.user:GetPveSectionStarByName(self.pve_name)
        for i,v in ipairs(self.items) do
            v:setVisible(i <= star)
        end
        self.sweep_label:setColor(UIKit:hex2c4b(User:GetItemCount("sweepScroll") > 0 and 0x615b44 or 0x7e00000))
        self.sweep_label:setString(User:GetItemCount("sweepScroll"))
        self.label:setString(string.format(_("今日可挑战次数: %d/%d"), self.user:GetFightCountByName(self.pve_name), sections[self.pve_name].maxFightCount))
        self.sweep_all:setButtonEnabled(star >= 3)
        self.sweep_all.label:setColor(UIKit:hex2c4b(User:GetItemCount("sweepScroll") >= self.user:GetPveLeftCountByName(self.pve_name) and 0xffedae or 0x7e00000))
        self.sweep_all.label:setString(string.format("-%d", self.user:GetPveLeftCountByName(self.pve_name)))
        self.sweep_once.label:setColor(UIKit:hex2c4b(User:GetItemCount("sweepScroll") >= 1 and 0xffedae or 0x7e00000))
        self.sweep_once:setButtonEnabled(star >= 3)
        local strength = self.user:GetResValueByType("stamina")
        self.attack.label:setColor(UIKit:hex2c4b(strength >= sections[self.pve_name].staminaUsed and 0xffedae or 0x7e00000))
    end
end
function GameUIPveAttack:CreateSweepButton()
    local s = cc.ui.UIPushButton.new(
        {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png", disabled = "gray_btn_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(UIKit:ttfLabel({
        size = 20,
        color = 0xffedae,
        shadow = true
    })):setButtonLabelOffset(0, 15)
    local num_bg = display.newSprite("alliance_title_gem_bg_154x20.png"):addTo(s):align(display.CENTER, 0, -10):scale(0.8)
    local size = num_bg:getContentSize()
    display.newSprite("sweep_128x128.png"):addTo(num_bg):align(display.CENTER, 20, size.height/2):scale(0.4)
    s.label = UIKit:ttfLabel({
        text = "-1",
        size = 20,
        color = 0xff0000,
    }):align(display.CENTER, size.width/2, size.height/2):addTo(num_bg)
    return s
end
function GameUIPveAttack:CreateAttackButton()
    local size = self:GetBody():getContentSize()

    local button = cc.ui.UIPushButton.new(
        {
            normal = "red_btn_up_148x58.png",
            pressed = "red_btn_down_148x58.png",
            disabled = 'gray_btn_148x58.png'
        },
        {scale9 = false}
    ):addTo(self:GetBody())
        :align(display.RIGHT_CENTER, size.width - 20,size.height - 510)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("进攻") ,
            size = 20,
            color = 0xffedae,
            shadow = true
        })):setButtonLabelOffset(0, 15)
        :onButtonClicked(function(event)
            if self.user:GetPveLeftCountByName(self.pve_name) <= 0 then
                UIKit:showMessageDialog(_("提示"),_("已达今日最大挑战次数!"))
                return
            end
            if not self.user:HasAnyStamina(sections[self.pve_name].staminaUsed) then
                WidgetUseItems.new():Create({
                    item_name = "stamina_1"
                }):AddToCurrentScene()
                return
            end
            -- event.target:setTouchEnabled(false)
            self:Attack()
            -- self:UseStrength(function()
            -- event.target:setTouchEnabled(true)
            -- end, sections[self.pve_name].staminaUsed):addTo(event.target)
        end)
    local num_bg = display.newSprite("alliance_title_gem_bg_154x20.png"):addTo(button):align(display.CENTER, 0, -10):scale(0.8)
    local size = num_bg:getContentSize()
    display.newSprite("dragon_lv_icon.png"):addTo(num_bg):align(display.CENTER, 20, size.height/2)
    button.label = UIKit:ttfLabel({
        text = "-"..sections[self.pve_name].staminaUsed,
        size = 20,
        color = self.user:HasAnyStamina(sections[self.pve_name].staminaUsed) and 0xffedae or 0xff0000,
    }):align(display.CENTER, size.width/2, size.height/2):addTo(num_bg)
    return button
end
function GameUIPveAttack:Attack()
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
            local task = City:GetRecommendTask()
            if task then
                if task:TaskType() == "explore" then
                    City:SetBeginnersTaskFlag(task:Index())
                end
            end
            local be_star = self.user:GetPveSectionStarByName(self.pve_name)

            NetManager:getAttackPveSectionPromise(self.pve_name, dragonType, soldiers):done(function()
                display.getRunningScene():GetSceneLayer():RefreshPve()
            end):done(function(response)
                local report = self:DecodeReport(response.msg.fightReport, dragon, soldiers)
                local dragon = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager():GetDragon(dragonType)
                dragonParam.new_exp = dragon:Exp()
                dragonParam.new_level = dragon:Level()
                dragonParam.star = self:GetStarByReport(report)
                if response.get_func then
                    dragonParam.reward = response.get_func()
                end

                local pve_name = self.pve_name
                local user = self.user
                dragonParam.callback = function()
                    if user:IsPveBoss(pve_name) and user:GetPveSectionStarByName(pve_name) > 0 then
                        UIKit:newGameUI("GameUIPveAttack", user, pve_name):AddToCurrentScene(true)
                        return
                    end

                    local userdefault = cc.UserDefault:getInstance()
                    local level,index = tonumber((unpack(string.split(pve_name, "_")))), 1
                    local stage,key = stages[string.format("%d_%d", level, index)], DataManager:getUserData()._id.."_pve_stage_"..string.format("%d_%d", level, index)
                    while stage do
                        if user:GetStageStarByIndex(level) >= tonumber(stage.needStar) and
                            not user:IsStageRewardedByName(stage.stageName) and
                            not userdefault:getBoolForKey(key)
                        then
                            userdefault:setBoolForKey(key, true)
                            userdefault:flush()

                            UIKit:newGameUI("GameUIPveReward", level, function()
                                if dragonParam.star > 0 and be_star <= 0 then
                                    display.getRunningScene():GetSceneLayer():MoveAirship(true)
                                end
                            end):AddToCurrentScene(true)
                            return
                        end
                        index = index + 1
                        stage,key = stages[string.format("%d_%d", level, index)], DataManager:getUserData()._id.."_pve_stage_"..string.format("%d_%d", level, index)
                    end
                    --
                    if dragonParam.star > 0 and be_star <= 0 then
                        display.getRunningScene():GetSceneLayer():MoveAirship(true)
                    end
                end
                
                local is_show = false
                UIKit:newGameUI("GameUIReplay", report, function(replayui)
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
            end)
        end,{isPVE = true}):AddToCurrentScene(true)
end
function GameUIPveAttack:BuyAndUseSweepScroll(count)
    local User = self.user
    local need_buy = count - User:GetItemCount("sweepScroll")
    assert(need_buy > 0)
    local required_gems = UtilsForItem:GetItemInfoByName("sweepScroll").price * need_buy
    local dialog = UIKit:showMessageDialog()
    dialog:SetTitle(_("补充道具"))
    dialog:SetPopMessage(_("您当前没有足够的扫荡劵,是否花费金龙币购买补充并使用"))
    dialog:CreateOKButtonWithPrice(
        {
            listener = function()
                if self.user:GetGemValue() < required_gems then
                    UIKit:showMessageDialog(_("提示"),_("金龙币不足")):CreateOKButton(
                        {
                            listener = function ()
                                UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                            end,
                            btn_name= _("前往商店")
                        })
                else
                    NetManager:getBuyItemPromise("sweepScroll", need_buy, false):done(function()
                        self:UseSweepScroll(count)
                    end)
                end
            end,
            btn_images = {normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"},
            price = required_gems
        }
    ):CreateCancelButton()
end
function GameUIPveAttack:UseSweepScroll(count)
    NetManager:getUseItemPromise("sweepScroll", {sweepScroll = {sectionName = self.pve_name, count = count}}):done(function(response)
        for i,v in ipairs(response.msg.playerData) do
            if v[1] == "__rewards" then
                UIKit:newGameUI("GameUIPveSweep", v[2]):AddToCurrentScene(true)
                return
            end
        end
    end):always(function()
        self:RefreshUI()
    end)
end
function GameUIPveAttack:UseStrength(func, num)
    local icon = display.newSprite("dragon_lv_icon.png")
    icon:runAction(transition.sequence{
        cc.Spawn:create(cc.MoveBy:create(0.3, cc.p(0, 100)), cc.FadeOut:create(0.4)),
        cc.CallFunc:create(func),
        cc.RemoveSelf:create(),
    })
    UIKit:ttfLabel({
        text = string.format("-%d", num),
        size = 22,
        color = 0x7e0000,
    }):addTo(icon):align(display.LEFT_CENTER,40,30)
    return icon
end
function GameUIPveAttack:Sweep(count)
    if self.user:GetPveLeftCountByName(self.pve_name) <= 0 then
        UIKit:showMessageDialog(_("提示"),_("已达今日最大挑战次数!"))
        return
    end
    if not self.user:HasAnyStamina(sections[self.pve_name].staminaUsed * count) then
        WidgetUseItems.new():Create({
            item_name = "stamina_1"
        }):AddToCurrentScene()
        return
    end
    if self.user:GetItemCount("sweepScroll") >= count then
        self:UseSweepScroll(count)
    else
        self:BuyAndUseSweepScroll(count)
    end
end
function GameUIPveAttack:CheckMaterials(func)
    local is_special
    local troops = string.split(sections[self.pve_name].troops, ",")
    for i,v in ipairs(troops) do
        local name = unpack(string.split(v, "_"))
        if special[name] then
            is_special = true
            break
        end
    end
    if is_special and User:IsMaterialOutOfRange("soldierMaterials") then
        local dialog = UIKit:showMessageDialogWithParams({
            title = _("提示"),
            content = string.format(_("当前材料库房中的%s材料已满，你可能无法获得此次扫荡所得的材料奖励。是否仍要扫荡？"), _("士兵")),
            ok_callback = func,
            ok_btn_images = {normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"},
            ok_string = _("强行扫荡"),
            cancel_callback = function () end,
            cancel_btn_images = {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"}
        })
    else
        func()
    end
end


function GameUIPveAttack:GetListItem(index,title)
    local bg = display.newScale9Sprite(string.format("back_ground_548x40_%d.png", index % 2 == 0 and 1 or 2)):size(600,40)
    UIKit:ttfLabel({
        text = title,
        size = 20,
        color = 0x403c2f,
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
    }):addTo(bg):align(display.LEFT_CENTER,90,20)

    bg.star = display.newSprite("tmp_pve_star.png"):addTo(bg):pos(55, 20):scale(0.5)
    return bg
end


function GameUIPveAttack:GetStarByReport(report)
    local star = 0
    star = star + (report:GetReportResult() and 1 or 0)
    if report:GetReportResult() then
        star = star + (report:GetFightAttackDragonRoundData().isWin and 1 or 0)

        local is_first_round_win = #report:GetSoldierRoundData() == 1
        for i,v in ipairs(report:GetSoldierRoundData()[1].attackResults) do
            if not v.isWin then
                is_first_round_win = false
            end
        end
        star = star + (is_first_round_win and 1 or 0)
    end
    return star
end
function GameUIPveAttack:DecodeReport(report, dragon, attack_soldiers)
    local user = self.user
    local titlename = self.titlename
    local pve_name = self.pve_name
    local troops = string.split(sections[pve_name].troops, ",")
    local _,_,level = unpack(string.split(troops[1], ":"))
    table.remove(troops, 1)
    local defence_soldiers = LuaUtils:table_map(troops, function(k,v)
        local name,star,count = unpack(string.split(v, ":"))
        return k, {name = name, star = tonumber(star), count = count}
    end)
    function report:IsFightWithBlackTroops()
        return true
    end
    function report:GetFightAttackName()
        return user.basicInfo.name
    end
    function report:GetFightDefenceName()
        return titlename
    end
    function report:IsDragonFight()
        return true
    end
    function report:GetFightAttackDragonRoundData()
        return self.playerDragonFightData
    end
    function report:GetFightDefenceDragonRoundData()
        return self.sectionDragonFightData
    end
    function report:GetFightAttackSoldierRoundData()
        return self.playerSoldierRoundDatas
    end
    function report:GetFightDefenceSoldierRoundData()
        return self.sectionSoldierRoundDatas
    end
    function report:CouldAttackDragonUseSkill()
        local attackRoundDragon = self:GetFightAttackDragonRoundData()
        return attackRoundDragon.hp - attackRoundDragon.hpDecreased > 0
    end
    function report:CouldDefenceDragonUseSkill()
        local defenceRoundDragon = self:GetFightDefenceDragonRoundData()
        return defenceRoundDragon.hp - defenceRoundDragon.hpDecreased > 0
    end
    function report:IsSoldierFight()
        return true
    end
    function report:GetSoldierRoundData()
        return  self.roundDatas
    end
    function report:IsFightWall()
        return false
    end
    function report:GetOrderedAttackSoldiers()
        return attack_soldiers
    end
    function report:GetOrderedDefenceSoldiers()
        return defence_soldiers
    end
    function report:GetReportResult()
        local roundDatas = self:GetSoldierRoundData()
        for i,v in ipairs(roundDatas[#roundDatas].attackResults) do
            if not v.isWin then
                return false
            end
        end
        return true
    end
    function report:GetAttackDragonLevel()
        return dragon:Level()
    end
    function report:GetDefenceDragonLevel()
        return level
    end
    function report:GetAttackTargetTerrain()
        return sections[pve_name].terrain
    end
    function report:IsAttackCamp()
        return true
    end
    return report
end


    

return GameUIPveAttack
































