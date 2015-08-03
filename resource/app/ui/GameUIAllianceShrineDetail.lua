--
-- Author: Danny He
-- Date: 2014-11-11 11:39:41
--
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameUIAllianceShrineDetail = class("GameUIAllianceShrineDetail",WidgetPopDialog)
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIListView = import(".UIListView")
local WidgetSoldierBox = import("..widget.WidgetSoldierBox")
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")
local WidgetShrineRewardsInfo = import("..widget.WidgetShrineRewardsInfo")
local AllianceShrine = import("..entity.AllianceShrine")
local UILib = import(".UILib")
local Localize = import("..utils.Localize")
function GameUIAllianceShrineDetail:ctor(shrineStage,allianceShrine,isActivate)
    local HEIGHT = 738
    self.isActivate_ = isActivate or false
    self.shrineStage_ = shrineStage
    self.allianceShrine_ = allianceShrine
    if self:IsActivate() then
        self:GetAllianceShrine():AddListenOnType(self,AllianceShrine.LISTEN_TYPE.OnPerceotionChanged)
        self:GetAllianceShrine():AddListenOnType(self,AllianceShrine.LISTEN_TYPE.OnFightEventTimerChanged)
        self:GetAllianceShrine():AddListenOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsChanged)
        self:GetAllianceShrine():AddListenOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsRefresh)
    else
        HEIGHT = 600 -- 修改背景高度
    end
    GameUIAllianceShrineDetail.super.ctor(self,HEIGHT,self:GetShrineStage():GetDescStageName(),window.top - 82,"title_red_600x56.png")
end

function GameUIAllianceShrineDetail:GetAllianceShrine()
    return self.allianceShrine_
end
--是否有激活操作
function GameUIAllianceShrineDetail:IsActivate()
    return self.isActivate_
end

function GameUIAllianceShrineDetail:OnMoveOutStage()
    if self:IsActivate() then
        self.allianceShrine_:RemoveListenerOnType(self,AllianceShrine.LISTEN_TYPE.OnPerceotionChanged)
        self.allianceShrine_:RemoveListenerOnType(self,AllianceShrine.LISTEN_TYPE.OnFightEventTimerChanged)
        self.allianceShrine_:RemoveListenerOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsChanged)
        self.allianceShrine_:RemoveListenerOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsRefresh)
    end
    GameUIAllianceShrineDetail.super.OnMoveOutStage(self)
end

function GameUIAllianceShrineDetail:OnShrineEventsRefresh()
    self:OnShrineEventsChanged()
end

function GameUIAllianceShrineDetail:OnShrineEventsChanged( change_map )
    self:RefreshStateLable()
end

function GameUIAllianceShrineDetail:RefreshStateLable()
    local event = self:GetAllianceShrine():GetShrineEventByStageName(self:GetShrineStage():StageName())
    if event then
        self.insight_icon:hide()
        self.state_label:setString(_("正在进行") .. "\n" .. GameUtils:formatTimeStyle1(event:GetTime()))
    else
        self.state_label:hide()
    end
end

function GameUIAllianceShrineDetail:OnFightEventTimerChanged(event)
    if event:StageName() == self:GetShrineStage():StageName() then
        if event:GetTime() > 1 then -- 有误差 1s
            self.insight_icon:hide()
            self.state_label:setString(_("正在进行") .. "\n" .. GameUtils:formatTimeStyle1(event:GetTime()))
            self.state_label:show()
        else
            self.insight_icon:show()
            self.state_label:hide()
        end
    end
end

function GameUIAllianceShrineDetail:OnPerceotionChanged()
    local resource = self:GetAllianceShrine():GetPerceptionResource()
    self.event_button:setButtonEnabled(resource:GetResourceValueByCurrentTime(app.timer:GetServerTime()) >= self:GetShrineStage():NeedPerception())
end

function GameUIAllianceShrineDetail:onEnter()
    GameUIAllianceShrineDetail.super.onEnter(self)
    self:BuildUI()
end

function GameUIAllianceShrineDetail:BuildUI()
    local background = self:GetBody()
    if self:IsActivate() then
        local desc_label = UIKit:ttfLabel({
            text = _("注:一场战斗中,每名玩家只能派出一支部队"),
            size = 20,
            color = 0x980101
        }):align(display.BOTTOM_CENTER,304,20):addTo(background)
        local event_button = WidgetPushButton.new({
            normal = "yellow_btn_up_186x66.png",
            pressed = "yellow_btn_down_186x66.png",
        },{scale9 = false},{disabled = {name = "GRAY", params = {0.2, 0.3, 0.5, 0.1}}})
            :align(display.RIGHT_BOTTOM, 570,desc_label:getPositionY() + 50)
            :addTo(background)
            :setButtonLabel("normal", UIKit:commonButtonLable({
                text = _("激活事件"),
                color = 0xfff3c7
            }))
            :onButtonClicked(function()
                self:OnEventButtonClicked()
            end)
        self.event_button = event_button
        local resource = self:GetAllianceShrine():GetPerceptionResource()
        event_button:setButtonEnabled(resource:GetResourceValueByCurrentTime(app.timer:GetServerTime()) >= self:GetShrineStage():NeedPerception())
        local insight_icon = display.newSprite("insight_icon_40x44.png")
            :align(display.RIGHT_BOTTOM,570 - event_button:getCascadeBoundingBox().width - 120,desc_label:getPositionY() + 60)
            :addTo(background)
        local need_insight_title_label = UIKit:ttfLabel({
            text = _("需要感知力"),
            size = 18,
            color = 0x6d6651
        }):addTo(insight_icon):align(display.LEFT_TOP,insight_icon:getContentSize().width,45)

        local need_insight_val_title = UIKit:ttfLabel({
            text = string.formatnumberthousands(self:GetShrineStage():NeedPerception()),
            color = 0x403c2f,
            size  = 24
        }):addTo(insight_icon):align(display.LEFT_BOTTOM,insight_icon:getContentSize().width, -5)
        self.insight_icon = insight_icon
        self.state_label = UIKit:ttfLabel({
            text = _("正在进行") .. "\n" .. "00:01:55",
            size = 24,
            color = 0x288400,
        }):align(display.RIGHT_BOTTOM,event_button:getPositionX() - event_button:getCascadeBoundingBox().width - 20,event_button:getPositionY())
            :addTo(background)
        self:RefreshStateLable()
    end
    --begin listview
    local items_box_x,items_box_y = 0,0
    if self:IsActivate() then
        items_box_x,items_box_y = background:getContentSize().width/2,self.event_button:getPositionY()+self.event_button:getCascadeBoundingBox().height+10
    else
        items_box_x,items_box_y = background:getContentSize().width/2,20
    end

    local items_box = WidgetShrineRewardsInfo.new({
        title = _("事件完成奖励"),
        h = 186,
        info = self:GetShrineStage()
    }):addTo(background)
        :align(display.BOTTOM_CENTER,items_box_x,items_box_y)

    local soldier_x,soldier_y = 14,self:IsActivate() and items_box:getPositionY()+342+10 or 210
    local info_box = display.newScale9Sprite("background_568x120.png", 0,0,cc.size(568,142),cc.rect(15,10,538,100))
        :align(display.LEFT_BOTTOM,19,soldier_y+5):addTo(background)
    self.info_list = UIListView.new({
        viewRect = cc.rect(11,10, 546, 122),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }):addTo(info_box,2)
    self:RefreshInfoListView()
    UIKit:ttfLabel({
        text = _("敌方部队阵容"),
        size = 20,
        color = 0x403c2f
    }):align(display.TOP_CENTER,304,soldier_y+370):addTo(background)
    self.soldier_list =  UIListView.new({
        viewRect = cc.rect(info_box:getPositionX(),info_box:getPositionY()+info_box:getContentSize().height+20, info_box:getContentSize().width, 180),
        direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL,
    }):addTo(background)
    self:RefreshSoldierListView()
end

function GameUIAllianceShrineDetail:GetInfoData()
    local stage = self:GetShrineStage()
    local r = {}
    r[1] = {"dragon_strength_27x31.png",_("敌方总战斗力"),stage:EnemyPower()}
    r[2] = {"res_citizen_88x82.png",_("建议玩家数量"),stage:SuggestPlayer()}
    r[3] = {"dragon_strength_27x31.png",_("建议部队战斗力"),"> " .. stage:SuggestPower()}
    return r
end

function GameUIAllianceShrineDetail:GetInfoListItem(index,image,title,val)
    local bg = display.newScale9Sprite(string.format("back_ground_548x40_%d.png",index%2==0 and 1 or 2)):size(544,40)
    local icon = display.newSprite(image):align(display.LEFT_CENTER,5,20):addTo(bg,2)
    if index == 2 then
        icon:scale(0.4)
        icon:pos(4,20)
    end
    UIKit:ttfLabel({
        text = title,
        color = 0x5d563f,
        size = 20
    }):align(display.LEFT_CENTER, 40, 20):addTo(bg,2)

    UIKit:ttfLabel({
        text = val,
        color = 0x403c2f,
        size = 20,
        align = cc.TEXT_ALIGNMENT_RIGHT,
    }):align(display.RIGHT_CENTER, 540, 20):addTo(bg,2)
    return bg
end

function GameUIAllianceShrineDetail:RefreshInfoListView()
    self.info_list:removeAllItems()

    for i,v in ipairs(self:GetInfoData()) do
        local item = self.info_list:newItem()
        local content = self:GetInfoListItem(i,v[1],v[2],v[3])
        item:addContent(content)
        item:setItemSize(544,40)
        self.info_list:addItem(item)
    end
    self.info_list:reload()
end

function GameUIAllianceShrineDetail:IsNotDragon(stageTroop)
    local name = stageTroop.type or ""
    if name == 'blueDragon'
        or "redDragon" == name
        or "dragon" == name
        or "greenDragon" == name then
        return false
    end
    return true
end


function GameUIAllianceShrineDetail:RefreshSoldierListView()
    self.soldier_list:removeAllItems()
    for _,v in ipairs(self:GetShrineStage():Troops()) do
        if self:IsNotDragon(v) then
            local item = self.soldier_list:newItem()
            local content = WidgetSoldierBox.new("",function()end)
            content:SetSoldier(v.type,v.star)
            content:SetNumber(v.count)
            item:addContent(content)
            item:setItemSize(content:getCascadeBoundingBox().width+12,content:getCascadeBoundingBox().height)
            self.soldier_list:addItem(item)
        end
    end
    self.soldier_list:reload()
end

function GameUIAllianceShrineDetail:GetShrineStage()
    return self.shrineStage_
end

function GameUIAllianceShrineDetail:OnEventButtonClicked()
    local member = self:GetAllianceShrine():GetAlliance():GetSelf()
    if member:CanActivateShirneEvent() then
        NetManager:getActivateAllianceShrineStagePromise(self:GetShrineStage():StageName()):done(function()
            self:LeftButtonClicked()
        end)
    else
        UIKit:showMessageDialog(_("提示"),_("您没有此操作权限"), function()end)
    end
end

return GameUIAllianceShrineDetail

