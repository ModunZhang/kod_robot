local WidgetWithBlueTitle = import("..widget.WidgetWithBlueTitle")
local UIListView = import('.UIListView')
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetSoldierBox = import("..widget.WidgetSoldierBox")
local WidgetTimerProgressStyleTwo = import("..widget.WidgetTimerProgressStyleTwo")
local WidgetTreatSoldier = import("..widget.WidgetTreatSoldier")
local GameUITreatSoldierSpeedUp = import(".GameUITreatSoldierSpeedUp")

local window = import("..utils.window")
local GameUIHospital = UIKit:createUIClass('GameUIHospital',"GameUIUpgradeBuilding")
GameUIHospital.SOLDIERS_NAME = {
    [1] = "swordsman_1",
    [2] = "ranger_1",
    [3] = "lancer_1",
    [4] = "catapult_1",
    [5] = "sentinel_1",
    [6] = "crossbowman_1",
    [7] = "horseArcher_1",
    [8] = "ballista_1",
    [9] = "swordsman_2",
    [10] = "ranger_2",
    [11] = "lancer_2",
    [12] = "catapult_2",
    [13] = "sentinel_2",
    [14] = "crossbowman_2",
    [15] = "horseArcher_2",
    [16] = "ballista_2",
    [17] = "swordsman_3",
    [18] = "ranger_3",
    [19] = "lancer_3",
    [20] = "catapult_3",
    [21] = "sentinel_3",
    [22] = "crossbowman_3",
    [23] = "horseArcher_3",
    [24] = "ballista_3",
-- [9] = "skeletonWarrior",
-- [10] = "skeletonArcher",
-- [11] = "deathKnight",
-- [12] = "meatWagon",
-- [13] = "priest",
-- [14] = "demonHunter",
-- [15] = "paladin",
-- [16] = "steamTank",
}

GameUIHospital.HEAL_NEED_RESOURCE_TYPE ={
    COIN = 1,
}

local COIN = GameUIHospital.HEAL_NEED_RESOURCE_TYPE.COIN

function GameUIHospital:ctor(city,building,default_tab)
    GameUIHospital.super.ctor(self,city,_("医院"),building,default_tab)
    self.heal_resource_item_table = {}
    self.treat_soldier_boxes_table = {}
end

function GameUIHospital:CreateBetweenBgAndTitle()
    GameUIHospital.super.CreateBetweenBgAndTitle(self)

    -- 加入治愈heal_layer
    self.heal_layer = display.newLayer():addTo(self:GetView())
end

function GameUIHospital:OnMoveInStage()
    self:CreateTabButtons({
        {
            label = _("治愈"),
            tag = "heal",
        },
    },function(tag)
        if tag == 'heal' then
            self.heal_layer:setVisible(true)
        else
            self.heal_layer:setVisible(false)
        end
    end):pos(window.cx, window.bottom + 34)

    -- 创建伤兵数量占最大伤兵数量比例条
    self:CreateCasualtyRateBar()
    -- 创建伤兵列表
    self:CresteCasualtySoldiersListView()
    -- 创建治愈所有伤病栏UI
    self:CreateHealAllSoldierItem()
    -- 创建加速治愈框
    self:CreateSpeedUpHeal()
    local User = self.city:GetUser()
    User:AddListenOnType(self, "soldierStars")
    User:AddListenOnType(self, "woundedSoldiers")
    User:AddListenOnType(self, "treatSoldierEvents")
    User:AddListenOnType(self, "buildingEvents")
    GameUIHospital.super.OnMoveInStage(self)

    scheduleAt(self, function()
        local event = User.treatSoldierEvents[1]
        if event then
            local treat_count = 0
            for k,v in pairs(event.soldiers) do
                treat_count = treat_count + v.count
            end
            self:SetTreatingSoldierNum(treat_count)
            local time, percent = UtilsForEvent:GetEventInfo(event)
            self.timer:SetProgressInfo(GameUtils:formatTimeStyle1(time), percent)
            self.treate_all_soldiers_item:hide()
            self.timer:show()
        end
    end)
end

function GameUIHospital:onExit()
    local User = self.city:GetUser()
    User:RemoveListenerOnType(self, "soldierStars")
    User:RemoveListenerOnType(self, "woundedSoldiers")
    User:RemoveListenerOnType(self, "treatSoldierEvents")
    User:RemoveListenerOnType(self, "buildingEvents")
    GameUIHospital.super.onExit(self)
end
function GameUIHospital:OnUserDataChanged_buildingEvents()
    self:SetProgressCasualtyRateLabel()
end
function GameUIHospital:CreateHealAllSoldierItem()
    self.treate_all_soldiers_item = WidgetWithBlueTitle.new(250, _("治愈所有伤兵")):addTo(self.heal_layer)
        :pos(window.cx,window.top-750)
    local bg_size = self.treate_all_soldiers_item:getContentSize()
    -- 治愈伤病需要使用的4种资源和数量（矿，石头，木材，食物）
    local function createResourceItem(resource_icon,need,current)
        local item = display.newNode()
        local icon = display.newSprite(resource_icon):addTo(item):align(display.LEFT_BOTTOM)
        icon:setScale(32/icon:getContentSize().width)
        item.current_value = UIKit:ttfLabel(
            {
                text = GameUtils:formatNumber(current),
                size = 20,
                color = current < need and 0x7e0000 or 0x403c2f
            }):addTo(item):align(display.LEFT_CENTER, 40, 15)
        item.need_value = cc.ui.UILabel.new(
            {
                UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
                text = "/"..GameUtils:formatNumber(need),
                font = UIKit:getFontFilePath(),
                size = 20,
                color = UIKit:hex2c3b(0x403c2f)
            }):addTo(item):align(display.LEFT_CENTER, item.current_value:getPositionX()+item.current_value:getContentSize().width, 15)
        local item_size =cc.size(40 + item.current_value:getContentSize().width + item.need_value:getContentSize().width ,30)
        item:setContentSize(item_size)
        return item
    end
    local item_width = 116
    local gap_x = (bg_size.width - 4*item_width)/5
    local User = self.city:GetUser()
    local soldiers = {}
    for k,v in pairs(User.woundedSoldiers) do
        table.insert(soldiers,{name=k,count=v})
    end
    local treat_coin = User:GetTreatCoin(soldiers)
    local total_coin = User:GetResValueByType("coin")
    local resource_icons = {
        [COIN]  = {total_coin,treat_coin,"res_coin_81x68.png"},
    }
    -- 资源背景框
    local resource_bg = WidgetUIBackGround.new({width = 556,height = 56},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :addTo(self.treate_all_soldiers_item):align(display.CENTER,self.treate_all_soldiers_item:getContentSize().width/2,160)
    for k,v in pairs(resource_icons) do
        self.heal_resource_item_table[k] = createResourceItem(v[3],v[2],v[1]):addTo(self.treate_all_soldiers_item):align(display.CENTER,bg_size.width/2, 160)
    end

    -- 立即治愈和治愈按钮
    local btn_bg = UIKit:commonButtonWithBG(
        {
            w=250,
            h=65,
            style = UIKit.BTN_COLOR.GREEN,
            labelParams = {text = _("立即治愈")},
            listener = function ()
                if app:GetGameDefautlt():IsOpenGemRemind() then
                    UIKit:showConfirmUseGemMessageDialog(_("提示"),string.format(_("是否消费%s金龙币"),
                        string.formatnumberthousands(self.treat_all_now_need_gems)
                    ), function()
                        self:TreatNowListener()
                        app:GetAudioManager():PlayeEffectSoundWithKey("INSTANT_TREATE_SOLDIER")
                    end,true,true)
                else
                    self:TreatNowListener()
                    app:GetAudioManager():PlayeEffectSoundWithKey("INSTANT_TREATE_SOLDIER")
                end
            end,
        }
    ):pos(bg_size.width/2-150, 95)
        :addTo(self.treate_all_soldiers_item)

    self.treat_all_now_button = btn_bg.button

    local btn_bg = UIKit:commonButtonWithBG(
        {
            w=185,
            h=65,
            style = UIKit.BTN_COLOR.YELLOW,
            labelParams = {text = _("治愈")},
            listener = function ()
                self:TreatListener()
                app:GetAudioManager():PlayeEffectSoundWithKey("TREATE_SOLDIER")
            end,
        }
    ):pos(bg_size.width/2+180, 95)
        :addTo(self.treate_all_soldiers_item)
    self.treat_all_button = btn_bg.button
    local User = self.city:GetUser()
    self.treat_all_now_button:setButtonEnabled(User:GetTreatCitizen()>0)
    self.treat_all_button:setButtonEnabled(User:GetTreatCitizen()>0)
    -- 立即治愈所需金龙币
    display.newSprite("gem_icon_62x61.png", bg_size.width/2 - 260, 40):addTo(self.treate_all_soldiers_item):setScale(0.5)
    self.heal_now_need_gems_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        font = UIKit:getFontFilePath(),
        size = 20,
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.LEFT_CENTER,bg_size.width/2 - 240,40):addTo(self.treate_all_soldiers_item)
    self:SetTreatAllSoldiersNowNeedGems()
    --治愈所需时间
    display.newSprite("hourglass_30x38.png", bg_size.width/2+100, 40):addTo(self.treate_all_soldiers_item):setScale(0.6)
    self.heal_time = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        font = UIKit:getFontFilePath(),
        size = 18,
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.LEFT_CENTER,bg_size.width/2+125,50):addTo(self.treate_all_soldiers_item)

    -- 科技减少治愈时间
    self.buff_reduce_time = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "(-00:00:00)",
        font = UIKit:getFontFilePath(),
        size = 18,
        color = UIKit:hex2c3b(0x068329)
    }):align(display.LEFT_CENTER,bg_size.width/2+120,30):addTo(self.treate_all_soldiers_item)
    self:SetTreatAllSoldiersTime()
end

function GameUIHospital:TreatListener()
    local User = self.city:GetUser()
    local soldiers = {}
    local treat_soldier_map = User.woundedSoldiers
    for k,v in pairs(treat_soldier_map) do
        if v>0 then
            table.insert(soldiers,{name=k,count=v})
        end
    end
    local treat_fun = function ()
        NetManager:getTreatSoldiersPromise(soldiers)
    end
    local isAbleToTreat, reason = User:CanTreat(soldiers)
    if #soldiers<1 then
        UIKit:showMessageDialog(_("提示"),_("没有伤兵需要治愈"))
    elseif City:GetUser():GetGemValue() < User:GetNormalTreatGems(soldiers) then
        UIKit:showMessageDialog(_("提示"),_("没有足够的金龙币补充资源"))
            :CreateOKButton(
                {
                    listener = function ()
                        UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                        self:LeftButtonClicked()
                    end,
                    btn_name= _("前往商店")
                })
    elseif reason == "treating_and_lack_resource" then
        UIKit:showMessageDialog(_("提示"),_("正在治愈，资源不足"))
            :CreateOKButtonWithPrice(
                {
                    listener = treat_fun,
                    price = User:GetNormalTreatGems(soldiers)
                }
            )
            :CreateCancelButton()
    elseif reason == "lack_resource" then
        UIKit:showMessageDialog(_("提示"),_("资源不足，是否花费金龙币补足"))
            :CreateOKButtonWithPrice({
                listener = treat_fun,
                price = User:GetNormalTreatGems(soldiers)
            })
            :CreateCancelButton()
    elseif reason == "treating" then
        UIKit:showMessageDialog(_("提示"),_("正在治愈，是否花费魔法石立即完成"))
            :CreateOKButtonWithPrice({
                listener = treat_fun,
                price = User:GetNormalTreatGems(soldiers)
            })
            :CreateCancelButton()
    else
        treat_fun()
    end
end
function GameUIHospital:TreatNowListener()
    local soldiers = {}
    local treat_soldier_map = self.city:GetUser().woundedSoldiers
    for k,v in pairs(treat_soldier_map) do
        if v>0 then
            table.insert(soldiers,{name=k,count=v})
        end
    end
    local treat_fun = function ()
        NetManager:getInstantTreatSoldiersPromise(soldiers)
    end
    if #soldiers<1 then
        UIKit:showMessageDialog(_("提示"),_("没有伤兵需要治愈"))
    elseif self.treat_all_now_need_gems > City:GetUser():GetGemValue() then
        UIKit:showMessageDialog(_("提示"),_("金龙币不足")):CreateOKButton(
            {
                listener = function ()
                    UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                    self:LeftButtonClicked()
                end,
                btn_name= _("前往商店")
            })
    else
        treat_fun()
    end
end
function GameUIHospital:SetTreatAllSoldiersNeedResources(params)
    for k,v in pairs(GameUIHospital.HEAL_NEED_RESOURCE_TYPE) do
        -- 有对应资源需求
        if params[v] then
            -- 得到对应资源框
            local item = self.heal_resource_item_table[v]
            local current_value = item.current_value
            local need_value = item.need_value
            current_value:setString(GameUtils:formatNumber(params[v][2]))
            current_value:setColor(UIKit:hex2c4b(params[v][2] < params[v][1] and 0x7e0000 or 0x403c2f))
            need_value:setString("/"..GameUtils:formatNumber(params[v][1]))
            need_value:setPositionX(current_value:getPositionX()+current_value:getContentSize().width)
            local item_size =cc.size(40 + current_value:getContentSize().width + need_value:getContentSize().width ,30)
            item:setContentSize(item_size)
        end
    end
end

-- 设置立即治愈所有伤兵需要魔法石数量
function GameUIHospital:SetTreatAllSoldiersNowNeedGems()
    local User = self.city:GetUser()
    local total_treat_time = User:GetTreatAllTime()
    local soldiers = {}
    for k,v in pairs(self.city:GetUser().woundedSoldiers) do
        table.insert(soldiers,{name=k,count=v})
    end
    local total_coin = User:GetTreatCoin(soldiers)
    local bur_resource_gems = DataUtils:buyResource({coin=total_coin},{})
    local buy_time = DataUtils:getGemByTimeInterval(total_treat_time)
    self.treat_all_now_need_gems = buy_time+bur_resource_gems
    self.heal_now_need_gems_label:setString(""..self.treat_all_now_need_gems)
end
-- 设置普通治愈需要时间
function GameUIHospital:SetTreatAllSoldiersTime()
    local treat_time = self.city:GetUser():GetTreatAllTime()
    self.heal_time:setString(GameUtils:formatTimeStyle1(treat_time))
    self.buff_reduce_time:setString("(-"..GameUtils:formatTimeStyle1(self.city:GetUser():GetTechReduceTreatTime(treat_time))..")")
end


function GameUIHospital:CreateCasualtyRateBar()
    local bar = display.newSprite("progress_bar_540x40_1.png"):addTo(self.heal_layer):pos(window.cx+10, window.top-110)
    local progressFill = display.newSprite("progress_bar_540x40_2.png")
    self.heal_layer.ProgressTimer = cc.ProgressTimer:create(progressFill)
    local pro = self.heal_layer.ProgressTimer
    pro:setType(display.PROGRESS_TIMER_BAR)
    pro:setBarChangeRate(cc.p(1,0))
    pro:setMidpoint(cc.p(0,0))
    pro:align(display.LEFT_BOTTOM, 0, 0):addTo(bar)
    self:SetProgressCasualtyRate()
    self.heal_layer.casualty_rate_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        -- text = "",
        font = UIKit:getFontFilePath(),
        size = 18,
        align = ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0xfff3c7),
    }):addTo(bar)
    self.heal_layer.casualty_rate_label:setAnchorPoint(cc.p(0,0.5))
    self.heal_layer.casualty_rate_label:pos(self.heal_layer.casualty_rate_label:getContentSize().width/2+30, bar:getContentSize().height/2)
    self:SetProgressCasualtyRateLabel()

    -- 进度条头图标
    display.newSprite("back_ground_43x43.png"):addTo(bar):pos(0, 20)
    display.newSprite("icon_treat_soldier_41x50.png"):addTo(bar):pos(2, 22)
end

-- 设置伤兵比例条
function GameUIHospital:SetProgressCasualtyRate()
    local User = self.city:GetUser()
    self.heal_layer.ProgressTimer:setPercentage(
        User:GetTreatCitizen()
        /
        UtilsForBuilding:GetMaxCasualty(User) * 100
    )
end
-- 设置伤兵比例条文本框
function GameUIHospital:SetProgressCasualtyRateLabel()
    local User = self.city:GetUser()
    self.heal_layer.casualty_rate_label:setString(
        string.formatnumberthousands(User:GetTreatCitizen())
        .."/"..
        string.formatnumberthousands(UtilsForBuilding:GetMaxCasualty(User))
    )
end

function GameUIHospital:CresteCasualtySoldiersListView()
    self.soldiers_listview = UIListView.new{
        -- bgColor = cc.c4b(200, 200, 0, 170),
        bgScale9 = true,
        viewRect = cc.rect(window.cx-274, window.top-625, 547, 490),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL}
        :addTo(self.heal_layer)
    self:CreateItemWithListView(self.soldiers_listview)
end

function GameUIHospital:CreateItemWithListView(list_view)
    local rect = list_view:getViewRect()
    local origin_x = - rect.width / 2
    local unit_width = 130
    local gap_x = (547 - unit_width * 4) / 3
    local row_item = display.newNode()
    local treat_soldier_map = self.city:GetUser().woundedSoldiers
    local row_count = -1
    for i, soldier_name in ipairs({
        "swordsman_1", "ranger_1", "lancer_1", "catapult_1",
        "sentinel_1", "crossbowman_1", "horseArcher_1", "ballista_1",
        "swordsman_2", "ranger_2", "lancer_2", "catapult_2",
        "sentinel_2", "crossbowman_2", "horseArcher_2", "ballista_2",
        "swordsman_3", "ranger_3", "lancer_3", "catapult_3",
        "sentinel_3", "crossbowman_3", "horseArcher_3", "ballista_3",
        "skeletonWarrior", "skeletonArcher", "deathKnight", "meatWagon",
    }) do
        local soldier_number = treat_soldier_map[soldier_name] or 0
        row_count = row_count + 1
        local soldier = WidgetSoldierBox.new("",function ()
            if soldier_number>0 then
                local widget = WidgetTreatSoldier.new(soldier_name,
                    UtilsForSoldier:SoldierStarByName(self.city:GetUser(), soldier_name),
                    soldier_number)
                    :addTo(self,1000)
                    :align(display.CENTER, window.cx, 500 / 2)
                    :OnBlankClicked(function(widget)
                        widget:removeFromParent()
                    end)
                    :OnNormalButtonClicked(function(widget)
                        widget:removeFromParent()
                    end)
                    :OnInstantButtonClicked(function(widget)
                        widget:removeFromParent()
                    end)
                scheduleAt(widget, function()
                    self:RefreshResources()
                end)
            end
        end):addTo(row_item)
            :alignByPoint(cc.p(0.5,0.5), origin_x + (unit_width + gap_x) * row_count + unit_width / 2, 0)
        soldier:SetSoldier(soldier_name,
            UtilsForSoldier:SoldierStarByName(self.city:GetUser(), soldier_name))
        soldier:SetNumber(soldier_number)
        soldier:Enable(soldier_number>0)
        self.treat_soldier_boxes_table[soldier_name] = soldier
        if row_count>2 then
            local item = list_view:newItem()
            item:addContent(row_item)
            item:setItemSize(547, 170)
            list_view:addItem(item)
            row_count=-1
            row_item = display.newNode()
        end
    end
    list_view:reload()
end

function GameUIHospital:CreateSpeedUpHeal()
    self.timer = WidgetTimerProgressStyleTwo.new(250, _("治愈伤兵")):addTo(self.heal_layer)
        :align(display.CENTER, window.cx, window.top-750)
        :OnButtonClicked(function(event)
            UIKit:newGameUI("GameUITreatSoldierSpeedUp", self.building):AddToCurrentScene(true)
        end)
    local event = User.treatSoldierEvents[1]
    if event then
        self.timer:show()
        local treat_count = 0
        for k,v in pairs(event.soldiers) do
            treat_count = treat_count + v.count
        end
        self:SetTreatingSoldierNum(treat_count)
        local time, percent = UtilsForEvent:GetEventInfo(event)
        self.timer:SetProgressInfo(GameUtils:formatTimeStyle1(time), percent)
    else
        self.timer:hide()
    end
end
--设置正在治愈的伤兵数量label
function GameUIHospital:SetTreatingSoldierNum( treat_soldier_num )
    self.timer:SetDescribe(string.format(_("正在治愈%d人口的伤兵"),treat_soldier_num))
end

function GameUIHospital:OnUserDataChanged_treatSoldierEvents(userData, deltaData)
    if deltaData("treatSoldierEvents.remove") then
        self.treate_all_soldiers_item:show()
        self.timer:hide()
    end
end
function GameUIHospital:OnUserDataChanged_soldierStars(userData, deltaData)
    local ok, value = deltaData("soldierStars")
    if ok then
        for soldier_name,star in pairs(value) do
            if self.treat_soldier_boxes_table[soldier_name] then
                self.treat_soldier_boxes_table[soldier_name]
                :SetSoldier(soldier_name, star)
            end
        end
    end
end
function GameUIHospital:OnUserDataChanged_woundedSoldiers(userData, deltaData)
    local User = self.city:GetUser()
    local ok, value = deltaData("woundedSoldiers")
    if ok then
        for soldier_name,count in pairs(value) do
            local changed_treat_soldier_num = User.woundedSoldiers[soldier_name]
            self.treat_soldier_boxes_table[soldier_name]:SetNumber(changed_treat_soldier_num)
            self.treat_soldier_boxes_table[soldier_name]:Enable(changed_treat_soldier_num>0)
            if changed_treat_soldier_num>0 then
                self.treat_soldier_boxes_table[soldier_name]:SetButtonListener(function ()
                    local widget = WidgetTreatSoldier.new(soldier_name,
                        1,
                        changed_treat_soldier_num)
                        :addTo(self,1000)
                        :align(display.CENTER, window.cx, 500 / 2)
                        :OnBlankClicked(function(widget)
                            widget:removeFromParent()
                        end)
                        :OnNormalButtonClicked(function(widget)
                            widget:removeFromParent()
                        end)
                        :OnInstantButtonClicked(function(widget)
                            widget:removeFromParent()
                        end)
                    scheduleAt(widget, function()
                        self:RefreshResources()
                    end)
                end)
            else
                self.treat_soldier_boxes_table[soldier_name]:SetButtonListener(function ()end)
            end
        end
    end
    local soldiers = {}
    for k,v in pairs(User.woundedSoldiers) do
        table.insert(soldiers,{name=k,count=v})
    end
    local treat_coin = User:GetTreatCoin(soldiers)
    local total_coin = User:GetResValueByType("coin")
    self:SetTreatAllSoldiersNeedResources({
        [COIN] = {treat_coin,total_coin}
    })
    self:SetTreatAllSoldiersNowNeedGems()
    self:SetTreatAllSoldiersTime()
    self:SetProgressCasualtyRateLabel()
    self:SetProgressCasualtyRate()
    self.treat_all_now_button:removeAllEventListeners()
    self.treat_all_button:removeAllEventListeners()
    self.treat_all_now_button:onButtonClicked(function (event)
        if event.name == "CLICKED_EVENT" then
            self:TreatNowListener()
        end
    end )
    self.treat_all_button:onButtonClicked(function (event)
        if event.name == "CLICKED_EVENT" then
            self:TreatListener()
        end
    end )

    self.treat_all_now_button:setButtonEnabled(User:GetTreatCitizen()>0)
    self.treat_all_button:setButtonEnabled(User:GetTreatCitizen()>0)
end

function GameUIHospital:RefreshResources()
    local User = self.city:GetUser()
    local soldiers = {}
    for k,v in pairs(self.city:GetUser().woundedSoldiers) do
        table.insert(soldiers,{name=k,count=v})
    end
    local treat_coin = User:GetTreatCoin(soldiers)
    local total_coin = self.city:GetUser():GetResValueByType("coin")
    self:SetTreatAllSoldiersNeedResources({
        [COIN] = {treat_coin,total_coin}
    })
end
return GameUIHospital

























































