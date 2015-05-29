local WidgetWithBlueTitle = import("..widget.WidgetWithBlueTitle")
local UIListView = import('.UIListView')
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetSoldierBox = import("..widget.WidgetSoldierBox")
local WidgetTimerProgressStyleTwo = import("..widget.WidgetTimerProgressStyleTwo")
local WidgetTreatSoldier = import("..widget.WidgetTreatSoldier")
local SoldierManager = import("..entity.SoldierManager")
local GameUITreatSoldierSpeedUp = import(".GameUITreatSoldierSpeedUp")
local HospitalUpgradeBuilding = import("..entity.HospitalUpgradeBuilding")

local window = import("..utils.window")
local GameUIHospital = UIKit:createUIClass('GameUIHospital',"GameUIUpgradeBuilding")
GameUIHospital.SOLDIERS_NAME = {
    [1] = "swordsman",
    [2] = "ranger",
    [3] = "lancer",
    [4] = "catapult",
    [5] = "sentinel",
    [6] = "crossbowman",
    [7] = "horseArcher",
    [8] = "ballista",
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

    self.city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.TREAT_SOLDIER_CHANGED)
    self.city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_CHANGED)
    self.building:AddHospitalListener(self)
    self.building:AddUpgradeListener(self)

    GameUIHospital.super.OnMoveInStage(self)
end

function GameUIHospital:onExit()
    self.building:RemoveHospitalListener(self)
    self.building:RemoveUpgradeListener(self)
    self.city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.TREAT_SOLDIER_CHANGED)
    self.city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_CHANGED)
    GameUIHospital.super.onExit(self)
end
function GameUIHospital:OnBuildingUpgradingBegin( ... )
end
function GameUIHospital:OnBuildingUpgradeFinished( ... )
    self:SetProgressCasualtyRateLabel()
end
function GameUIHospital:OnBuildingUpgrading( ... )
end
function GameUIHospital:OnBeginTreat(hospital, event)
    self:OnTreating(hospital, event, app.timer:GetServerTime())
end

function GameUIHospital:OnTreating(hospital, event, current_time)
    local treat_count = 0
    local soldiers = event:GetTreatInfo()
    for k,v in pairs(soldiers) do
        treat_count = treat_count + v.count
    end
    self:SetTreatingSoldierNum(treat_count)
    self.timer:SetProgressInfo(GameUtils:formatTimeStyle1(event:LeftTime(current_time)),event:Percent(current_time))
    self.treate_all_soldiers_item:hide()
    self.timer:show()
end

function GameUIHospital:OnEndTreat(hospital, event, soldiers, current_time)
    self.treate_all_soldiers_item:show()
    self.timer:hide()
end

function GameUIHospital:CreateHealAllSoldierItem()
    self.treate_all_soldiers_item = WidgetWithBlueTitle.new(272, _("治愈所有伤兵")):addTo(self.heal_layer)
        :pos(window.cx,window.top-740)
    local bg_size = self.treate_all_soldiers_item:getContentSize()
    -- 治愈伤病需要使用的4种资源和数量（矿，石头，木材，食物）
    local function createResourceItem(resource_icon,num)
        local item = display.newNode()
        local item_size =cc.size(116,30)
        item:setContentSize(item_size)
        local icon = display.newSprite(resource_icon):addTo(item):align(display.LEFT_BOTTOM)
        icon:setScale(32/icon:getContentSize().width)
        item.need_value = cc.ui.UILabel.new(
            {
                UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
                text = GameUtils:formatNumber(num),
                font = UIKit:getFontFilePath(),
                size = 20,
                color = UIKit:hex2c3b(0x403c2f)
            }):addTo(item):align(display.LEFT_CENTER, 40, item_size.height/2)
        return item
    end
    local item_width = 116
    local gap_x = (bg_size.width - 4*item_width)/5
    local soldiers = {}
    for k,v in pairs(self.city:GetSoldierManager():GetTreatSoldierMap()) do
        table.insert(soldiers,{name=k,count=v})
    end
    local total_coin = self.city:GetSoldierManager():GetTreatResource(soldiers)
    local resource_icons = {
        [COIN]  = {total_coin,"res_coin_81x68.png"},
    }
    -- 资源背景框
    local resource_bg = WidgetUIBackGround.new({width = 556,height = 56},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :addTo(self.treate_all_soldiers_item):align(display.CENTER,self.treate_all_soldiers_item:getContentSize().width/2,180)
    for k,v in pairs(resource_icons) do
        self.heal_resource_item_table[k] = createResourceItem(v[2],v[1]):addTo(self.treate_all_soldiers_item):pos(bg_size.width/2-40, 165)
    end

    -- 立即治愈和治愈按钮
    local btn_bg = UIKit:commonButtonWithBG(
        {
            w=250,
            h=65,
            style = UIKit.BTN_COLOR.GREEN,
            labelParams = {text = _("立即治愈")},
            listener = function ()
                self:TreatNowListener()
                app:GetAudioManager():PlayeEffectSoundWithKey("INSTANT_TREATE_SOLDIER")
            end,
        }
    ):pos(bg_size.width/2-150, 110)
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
    ):pos(bg_size.width/2+180, 110)
        :addTo(self.treate_all_soldiers_item)
    self.treat_all_button = btn_bg.button

    self.treat_all_now_button:setButtonEnabled(self.city:GetSoldierManager():GetTotalTreatSoldierCount()>0)
    self.treat_all_button:setButtonEnabled(self.city:GetSoldierManager():GetTotalTreatSoldierCount()>0)
    -- 立即治愈所需金龙币
    display.newSprite("gem_icon_62x61.png", bg_size.width/2 - 260, 50):addTo(self.treate_all_soldiers_item):setScale(0.5)
    self.heal_now_need_gems_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        font = UIKit:getFontFilePath(),
        size = 20,
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.LEFT_CENTER,bg_size.width/2 - 240,50):addTo(self.treate_all_soldiers_item)
    self:SetTreatAllSoldiersNowNeedGems()
    --治愈所需时间
    display.newSprite("hourglass_30x38.png", bg_size.width/2+100, 50):addTo(self.treate_all_soldiers_item):setScale(0.6)
    self.heal_time = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        font = UIKit:getFontFilePath(),
        size = 18,
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.LEFT_CENTER,bg_size.width/2+125,60):addTo(self.treate_all_soldiers_item)
    self:SetTreatAllSoldiersTime()

    -- 科技减少治愈时间
    self.buff_reduce_time = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "(-00:00:00)",
        font = UIKit:getFontFilePath(),
        size = 18,
        color = UIKit:hex2c3b(0x068329)
    }):align(display.LEFT_CENTER,bg_size.width/2+120,40):addTo(self.treate_all_soldiers_item)
end

function GameUIHospital:TreatListener()
    local soldiers = {}
    local treat_soldier_map = self.city:GetSoldierManager():GetTreatSoldierMap()
    for k,v in pairs(treat_soldier_map) do
        if v>0 then
            table.insert(soldiers,{name=k,count=v})
        end
    end
    local treat_fun = function ()
        NetManager:getTreatSoldiersPromise(soldiers)
    end
    local isAbleToTreat =self.building:IsAbleToTreat(soldiers)
    if #soldiers<1 then
        UIKit:showMessageDialog(_("提示"),_("没有伤兵需要治愈"))
    elseif City:GetUser():GetGemResource():GetValue()< self.building:GetTreatGems(soldiers) then
        UIKit:showMessageDialog(_("提示"),_("没有足够的金龙币补充资源"))
            :CreateOKButton(
                {
                    listener = function ()
                        UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                        self:LeftButtonClicked()
                    end,
                    btn_name= _("前往商店")
                })
    elseif isAbleToTreat==HospitalUpgradeBuilding.CAN_NOT_TREAT.TREATING_AND_LACK_RESOURCE then
        UIKit:showMessageDialog(_("提示"),_("正在治愈，资源不足"))
            :CreateOKButton(
                {
                    listener = treat_fun
                }
            )
            :CreateNeeds({value = self.building:GetTreatGems(soldiers)})
    elseif isAbleToTreat==HospitalUpgradeBuilding.CAN_NOT_TREAT.LACK_RESOURCE then
        UIKit:showMessageDialog(_("提示"),_("资源不足，是否花费金龙币补足"))
            :CreateOKButton({
                listener = treat_fun
            })
            :CreateNeeds({value = self.building:GetTreatGems(soldiers)})
    elseif isAbleToTreat==HospitalUpgradeBuilding.CAN_NOT_TREAT.TREATING then
        UIKit:showMessageDialog(_("提示"),_("正在治愈，是否花费魔法石立即完成"))
            :CreateOKButton({
                listener = treat_fun
            })
            :CreateNeeds({value = self.building:GetTreatGems(soldiers)})
    else
        treat_fun()
    end
end
function GameUIHospital:TreatNowListener()
    local soldiers = {}
    local treat_soldier_map = self.city:GetSoldierManager():GetTreatSoldierMap()
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
    elseif self.treat_all_now_need_gems>City:GetUser():GetGemResource():GetValue() then
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
            self.heal_resource_item_table[v].need_value:setString(GameUtils:formatNumber(params[v]))
        end
    end
end

-- 设置立即治愈所有伤兵需要魔法石数量
function GameUIHospital:SetTreatAllSoldiersNowNeedGems()
    local total_treat_time = self.city:GetSoldierManager():GetTreatAllTime()
    local soldiers = {}
    for k,v in pairs(self.city:GetSoldierManager():GetTreatSoldierMap()) do
        table.insert(soldiers,{name=k,count=v})
    end
    local total_coin = self.city:GetSoldierManager():GetTreatResource(soldiers)
    local bur_resource_gems = DataUtils:buyResource({coin=total_coin},{})
    local buy_time = DataUtils:getGemByTimeInterval(total_treat_time)
    self.treat_all_now_need_gems = buy_time+bur_resource_gems
    self.heal_now_need_gems_label:setString(""..self.treat_all_now_need_gems)
end
-- 设置普通治愈需要时间
function GameUIHospital:SetTreatAllSoldiersTime()
    self.heal_time:setString(GameUtils:formatTimeStyle1(self.city:GetSoldierManager():GetTreatAllTime()))
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
    -- pro:setPercentage(0/self.building:GetMaxCasualty())
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
    self.heal_layer.ProgressTimer:setPercentage(self.city:GetSoldierManager():GetTotalTreatSoldierCount()/self.building:GetMaxCasualty() * 100)
end
-- 设置伤兵比例条文本框
function GameUIHospital:SetProgressCasualtyRateLabel()
    self.heal_layer.casualty_rate_label:setString(self.city:GetSoldierManager():GetTotalTreatSoldierCount().."/"..self.building:GetMaxCasualty())
end

function GameUIHospital:CresteCasualtySoldiersListView()
    self.soldiers_listview = UIListView.new{
        -- bgColor = cc.c4b(200, 200, 0, 170),
        bgScale9 = true,
        viewRect = cc.rect(window.cx-274, window.top-600, 547, 465),
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
    local treat_soldier_map = City:GetSoldierManager():GetTreatSoldierMap()
    local row_count = -1
    for i, soldier_name in ipairs({
        "swordsman", "ranger", "lancer", "catapult",
        "sentinel", "crossbowman", "horseArcher", "ballista",
        "skeletonWarrior", "skeletonArcher", "deathKnight", "meatWagon",
    }) do
        local soldier_number = treat_soldier_map[soldier_name] or 0
        row_count = row_count + 1
        local soldier = WidgetSoldierBox.new("",function ()
            if soldier_number>0 then
                local widget = WidgetTreatSoldier.new(soldier_name,
                    self.city:GetSoldierManager():GetStarBySoldierType(soldier_name),
                    soldier_number)
                    :addTo(self,1000)
                    :align(display.CENTER, window.cx, 500 / 2)
                    :OnBlankClicked(function(widget)
                        City:GetResourceManager():RemoveObserver(widget)
                        widget:removeFromParent()
                    end)
                    :OnNormalButtonClicked(function(widget)
                        City:GetResourceManager():RemoveObserver(widget)
                        widget:removeFromParent()
                    end)
                    :OnInstantButtonClicked(function(widget)
                        City:GetResourceManager():RemoveObserver(widget)
                        widget:removeFromParent()
                    end)
                City:GetResourceManager():AddObserver(widget)
                City:GetResourceManager():OnResourceChanged()
            end
        end):addTo(row_item)
            :alignByPoint(cc.p(0.5,0.5), origin_x + (unit_width + gap_x) * row_count + unit_width / 2, 0)
        soldier:SetSoldier(soldier_name,self.city:GetSoldierManager():GetStarBySoldierType(soldier_name))
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
    self.timer = WidgetTimerProgressStyleTwo.new(nil, _("治愈伤兵")):addTo(self.heal_layer)
        :align(display.CENTER, window.cx, window.top-740)
        :OnButtonClicked(function(event)
            UIKit:newGameUI("GameUITreatSoldierSpeedUp", self.building):AddToCurrentScene(true)
        end)
    local treat_event = self.building:GetTreatEvent()
    if treat_event:IsTreating() then
        self.timer:show()
        local treat_count = 0
        local soldiers = treat_event:GetTreatInfo()
        for k,v in pairs(soldiers) do
            treat_count = treat_count + v.count
        end
        self:SetTreatingSoldierNum(treat_count)
        self.timer:SetProgressInfo(GameUtils:formatTimeStyle1(treat_event:LeftTime(app.timer:GetServerTime())),treat_event:Percent(app.timer:GetServerTime()))
    else
        self.timer:hide()
    end

end
--设置正在治愈的伤兵数量label
function GameUIHospital:SetTreatingSoldierNum( treat_soldier_num )
    self.timer:SetDescribe(string.format(_("正在治愈%d人口的伤兵"),treat_soldier_num))
end

function GameUIHospital:OnTreatSoliderCountChanged(soldier_manager, treat_soldier_changed)
    for k,soldier_type in pairs(treat_soldier_changed) do
        local changed_treat_soldier_num = soldier_manager:GetTreatCountBySoldierType(soldier_type)
        self.treat_soldier_boxes_table[soldier_type]:SetNumber(changed_treat_soldier_num)
        self.treat_soldier_boxes_table[soldier_type]:Enable(changed_treat_soldier_num>0)
        if changed_treat_soldier_num>0 then
            self.treat_soldier_boxes_table[soldier_type]:SetButtonListener(function ()
                local widget = WidgetTreatSoldier.new(soldier_type,
                    1,
                    changed_treat_soldier_num)
                    :addTo(self,1000)
                    :align(display.CENTER, window.cx, 500 / 2)
                    :OnBlankClicked(function(widget)
                        City:GetResourceManager():RemoveObserver(widget)
                        widget:removeFromParent()
                    end)
                    :OnNormalButtonClicked(function(widget)
                        City:GetResourceManager():RemoveObserver(widget)
                        widget:removeFromParent()
                    end)
                    :OnInstantButtonClicked(function(widget)
                        City:GetResourceManager():RemoveObserver(widget)
                        widget:removeFromParent()
                    end)
                City:GetResourceManager():AddObserver(widget)
                City:GetResourceManager():OnResourceChanged()
            end)
        else
            self.treat_soldier_boxes_table[soldier_type]:SetButtonListener(function ()end)
        end
        local soldiers = {}
        for k,v in pairs(self.city:GetSoldierManager():GetTreatSoldierMap()) do
            table.insert(soldiers,{name=k,count=v})
        end
        local total_coin = soldier_manager:GetTreatResource(soldiers)
        self:SetTreatAllSoldiersNeedResources({
            [COIN] = total_coin
        })
        self:SetTreatAllSoldiersNowNeedGems()
        self:SetTreatAllSoldiersTime()
    end
    self:SetProgressCasualtyRateLabel()
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

    self.treat_all_now_button:setButtonEnabled(self.city:GetSoldierManager():GetTotalTreatSoldierCount()>0)
    self.treat_all_button:setButtonEnabled(self.city:GetSoldierManager():GetTotalTreatSoldierCount()>0)


end
function GameUIHospital:OnSoliderStarCountChanged(soldier_manager,star_changed_map)
    for i,v in pairs(star_changed_map) do
        if self.treat_soldier_boxes_table[v] then
            self.treat_soldier_boxes_table[v]:SetSoldier(v, soldier_manager:GetStarBySoldierType(v))
        end
    end
end
return GameUIHospital



















































