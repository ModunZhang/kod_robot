--
-- Author: Danny He
-- Date: 2014-11-13 15:47:07
--
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameUIShireFightEvent = class("GameUIShireFightEvent",WidgetPopDialog)
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIListView = import(".UIListView")
local AllianceShrine = import("..entity.AllianceShrine")
local Alliance = import("..entity.Alliance")
local Dragon_head_image = import(".UILib").dragon_head
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")
local GameUtils = GameUtils
function GameUIShireFightEvent:ctor(fight_event,allianceShrine)
    GameUIShireFightEvent.super.ctor(self,790,_("事件详情"),window.top - 50)
    self.fight_event = fight_event
    self.allianceShrine_ = allianceShrine
    self:GetAllianceShrine():AddListenOnType(self,AllianceShrine.LISTEN_TYPE.OnFightEventTimerChanged)
    self:GetAllianceShrine():GetAlliance():AddListenOnType(self,Alliance.LISTEN_TYPE.OnAttackMarchEventTimerChanged)
    self:GetAllianceShrine():GetAlliance():AddListenOnType(self,Alliance.LISTEN_TYPE.OnAttackMarchEventDataChanged)
    self:GetAllianceShrine():AddListenOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsChanged)
    self:GetAllianceShrine():AddListenOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsRefresh)
    self.event_bind_to_label = {}
end

function GameUIShireFightEvent:onEnter()
    GameUIShireFightEvent.super.onEnter(self)
    self:BuildUI()
end

function GameUIShireFightEvent:OnFightEventTimerChanged(event)
    if event:Id() == self:GetFightEvent():Id() then
        self.time_label:setString(string.format(_("派兵时间 %s"),GameUtils:formatTimeStyle1(event:GetTime())))
    end
end

function GameUIShireFightEvent:OnAttackMarchEventDataChanged(change_map)
    if change_map.added or change_map.removed then
        self.popultaion_label:setString(#self:GetFightEvent():PlayerTroops())
        self:RefreshListView()
    end
end

function GameUIShireFightEvent:OnShrineEventsChanged(change_map)
    if change_map.removed then
        local id_ = self:GetFightEvent():Id()
        for _,v in ipairs(change_map.removed) do
            if id_ == v:Id() then
                self:LeftButtonClicked()
                break
            end
        end
    end
end

function GameUIShireFightEvent:OnShrineEventsRefresh()
    local id_ = self:GetFightEvent():Id()
    local event = self:GetAllianceShrine():GetShrineEventById(id_)
    if not event then
        self:LeftButtonClicked()
    end
end

function GameUIShireFightEvent:OnAttackMarchEventTimerChanged(event)
    if self.event_bind_to_label[event:Id()] then
        self.event_bind_to_label[event:Id()]:setString(GameUtils:formatTimeStyle1(event:GetTime()) .. "后到达")
    end
end

function GameUIShireFightEvent:onCleanup()
    self:GetAllianceShrine():RemoveListenerOnType(self,AllianceShrine.LISTEN_TYPE.OnFightEventTimerChanged)
    self:GetAllianceShrine():RemoveListenerOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsChanged)
    self:GetAllianceShrine():RemoveListenerOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsRefresh)
    self:GetAllianceShrine():GetAlliance():RemoveListenerOnType(self,Alliance.LISTEN_TYPE.OnAttackMarchEventTimerChanged)
    self:GetAllianceShrine():GetAlliance():RemoveListenerOnType(self,Alliance.LISTEN_TYPE.OnAttackMarchEventDataChanged)
    self.event_bind_to_label = nil
    GameUIShireFightEvent.super.onCleanup(self)
end

function GameUIShireFightEvent:GetAllianceShrine()
    return self.allianceShrine_
end


function GameUIShireFightEvent:BuildUI()
    local background = self:GetBody()
    local info_button = WidgetPushButton.new({
        normal = "yellow_btn_up_148x58.png",
        pressed = "yellow_btn_down_148x58.png"
    }):align(display.LEFT_BOTTOM,26,22):addTo(background):setButtonLabel("normal",UIKit:commonButtonLable({text = _("信息"),})):onButtonClicked(function()
        self:InfomationButtonClicked()
    end)
    local dispath_button = WidgetPushButton.new({
        normal = "yellow_btn_up_148x58.png",
        pressed = "yellow_btn_down_148x58.png",
        disabled= "grey_btn_148x58.png",
    }):align(display.RIGHT_BOTTOM,580,22):addTo(background):setButtonLabel("normal",UIKit:commonButtonLable({text = _("派兵")})):onButtonClicked(function()
        self:DispathSoliderButtonClicked()
    end)
    self.dispath_button = dispath_button
    local list,list_node = UIKit:commonListView({
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0,0,568,508),
    -- bgColor = UIKit:hex2c4b(0x7a000000),
    })
    list_node:addTo(background):align(display.CENTER_BOTTOM, background:getContentSize().width/2, 94)
    self.info_list = list
    local tips_box = WidgetUIBackGround.new({width = 556,height = 106},WidgetUIBackGround.STYLE_TYPE.STYLE_5):addTo(background):align(display.BOTTOM_CENTER, 304, 660)
    UIKit:ttfLabel({
        text = _("参与联盟GVE活动获得的奖励，击杀数量越高奖励越丰富，派出的部队会在战斗结束后返回。根据到达的先后顺序进行战斗排序"),
        dimensions = cc.size(510,82),
        size = 20,
        color = 0x615b44
    }):align(display.CENTER,287,51):addTo(tips_box)

    local icon_bg = display.newSprite("back_ground_43x43.png")
        :align(display.LEFT_TOP, 20, 650)
        :addTo(background):scale(0.7)
    display.newSprite("hourglass_30x38.png"):align(display.CENTER, 22, 22):addTo(icon_bg)

    self.time_label = UIKit:ttfLabel({
        text =  string.format(_("派兵时间 %s"),GameUtils:formatTimeStyle1(self:GetFightEvent():GetTime())),
        size = 22,
        color = 0x403c2f
    }):align(display.LEFT_TOP,icon_bg:getPositionX()+icon_bg:getContentSize().width*0.7+10,icon_bg:getPositionY()):addTo(background)

    local population_icon = display.newSprite("res_citizen_88x82.png"):scale(0.35):align(display.RIGHT_TOP,550,icon_bg:getPositionY()+2):addTo(background)
    self.popultaion_label = UIKit:ttfLabel({
        text = #self:GetFightEvent():PlayerTroops(),
        size = 22,
        color = 0x403c2f
    }):align(display.LEFT_TOP, population_icon:getPositionX()+5,population_icon:getPositionY()-3):addTo(background)
    self:RefreshListView()
end


function GameUIShireFightEvent:RefreshListView()
    self.info_list:removeAllItems()

    for i,v in ipairs(self:GetFightEvent():PlayerTroops()) do
        local item = self:GetListItem(true,v)
        self.info_list:addItem(item)
    end

    -- dump(self:GetAllianceShrine():GetAlliance():GetAttackMarchEvents("shrine"))
    for i,v in ipairs(self:GetAllianceShrine():GetAlliance():GetAttackMarchEvents("shrine")) do
        if v:DefenceShrineData().shrineEventId == self:GetFightEvent():Id() then
            local item = self:GetListItem(false,v)
            self.info_list:addItem(item)
        end
    end
    self.info_list:reload()
end
function GameUIShireFightEvent:GetListItem(arrived,obj)
    local item = self.info_list:newItem()
    local content =  WidgetUIBackGround.new({width = 568,height = 190},WidgetUIBackGround.STYLE_TYPE.STYLE_2)

    local icon = display.newSprite("alliance_item_flag_box_126X126.png"):align(display.LEFT_TOP, 12, 141):addTo(content)
    display.newSprite("technology_bg_116x116.png", 63, 63):addTo(icon)
    local title_name = arrived and "title_red_558x34.png" or "title_blue_558x34.png"
    local title_bar = display.newSprite(title_name):align(display.CENTER_TOP, 284, 184):addTo(content)
    display.newSprite("alliacne_search_29x33.png"):align(display.RIGHT_CENTER, 540,17):addTo(title_bar):scale(0.8)
    WidgetPushTransparentButton.new(cc.rect(0,0,558,34)):addTo(title_bar):align(display.LEFT_BOTTOM,0, 0):onButtonClicked(function()
        local member_id
        if arrived then
            member_id = obj.id
        else
            member_id = obj:AttackPlayerData().id
        end
        if member_id then
            UIKit:newGameUI('GameUIAllianceMemberInfo',true,member_id):AddToCurrentScene(true)
        end
    end)
    local playerName = ""
    if arrived then
        playerName = obj.name
    else
        playerName = obj:AttackPlayerData().name
    end
    local dragon_image = ""
    if arrived then
        dragon_image = Dragon_head_image[obj.dragon.type]
    else
        dragon_image = Dragon_head_image[obj:AttackPlayerData().dragon.type]
    end
    display.newSprite(dragon_image):align(display.CENTER,63,68):addTo(icon)
    UIKit:ttfLabel({
        text = playerName,
        color = 0xffedae,
        size = 20,
        shadow = true
    }):align(display.LEFT_CENTER,10,17):addTo(title_bar)
    local icon_bg = display.newSprite("back_ground_43x43.png")
        :align(display.LEFT_BOTTOM, icon:getPositionX()+icon:getContentSize().width + 10, 20)
        :addTo(content):scale(0.7)
    display.newSprite("hourglass_30x38.png"):align(display.CENTER, 22, 22):addTo(icon_bg)
    local time_label_text = ""
    if not arrived then
        time_label_text =  string.format("%s后到达",GameUtils:formatTimeStyle1(obj:GetTime()))
    else
        time_label_text = _("驻扎中")
    end
    local time_label = UIKit:ttfLabel({
        text = time_label_text,
        color = 0x403c2f,
        size = 20
    }):align(display.LEFT_CENTER,icon:getPositionX()+icon:getContentSize().width+50, 35):addTo(content)
    if not arrived then
        self.event_bind_to_label[obj:Id()] = time_label
    end
    local line_2 = display.newScale9Sprite("dividing_line_594x2.png"):size(400,2)
        :align(display.LEFT_BOTTOM, icon:getPositionX()+icon:getContentSize().width+10,70)
        :addTo(content)

    local power_title_label = UIKit:ttfLabel({
        text = _("坐标"),
        size = 20,
        color = 0x615b44
    }):align(display.LEFT_BOTTOM,line_2:getPositionX(),line_2:getPositionY() + 8):addTo(content)
    local location_x,location_y = 0,0
    if arrived then
        location_x,location_y = obj.location.x,obj.location.y
    else
        location_x,location_y = obj:FromLocation().x,obj:FromLocation().y
    end

    local power_val_label =  UIKit:ttfLabel({
        text = location_x .. "," .. location_y,
        size = 20,
        color = 0x403c2f
    }):align(display.RIGHT_BOTTOM,line_2:getPositionX()+line_2:getContentSize().width,power_title_label:getPositionY()):addTo(content)

    local line_1 = display.newScale9Sprite("dividing_line_594x2.png"):size(400,2)
        :align(display.LEFT_BOTTOM,line_2:getPositionX(),line_2:getPositionY()+40):addTo(content)

    local dragon_title_label =  UIKit:ttfLabel({
        text = _("来自"),
        size = 20,
        color = 0x615b44
    }):align(display.LEFT_BOTTOM,line_1:getPositionX(),line_1:getPositionY() + 8):addTo(content)
    local city_name = arrived and obj.name or obj:AttackPlayerData().name
    local dragon_val_label =  UIKit:ttfLabel({
        text = city_name,
        size = 20,
        color = 0x403c2f
    }):align(display.RIGHT_BOTTOM,line_1:getPositionX()+line_1:getContentSize().width,dragon_title_label:getPositionY()):addTo(content)

    item:addContent(content)
    item:setItemSize(568,190)
    return item
end

function GameUIShireFightEvent:GetFightEvent()
    return self.fight_event
end

function GameUIShireFightEvent:GetAllianceShrineLocation()
    local alliance_obj = self:GetAllianceShrine():GetShireObjectFromMap()
    local location = alliance_obj.location
    return location
end

function GameUIShireFightEvent:DispathSoliderButtonClicked()
    if not self:GetAllianceShrine():CheckSelfCanDispathSoldiers() then
        UIKit:showMessageDialog(nil,_("你已经向圣地派遣了部队"))
        return
    end
    UIKit:newGameUI("GameUIAllianceSendTroops",function(dragonType,soldiers,total_march_time,gameuialliancesendtroops)
        if total_march_time >=  self:GetFightEvent():GetTime() then
            UIKit:showMessageDialog(_("提示"),
                _("检测到你的行军时间大于圣地事件时间,可能部队未达到之前，圣地事件已结束。是否继续派兵?"),
                function()
                    NetManager:getMarchToShrinePromose(self:GetFightEvent():Id(),dragonType,soldiers):done(function()
                        app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                    end)
                    gameuialliancesendtroops:LeftButtonClicked()
                end,
                function()
                end)
        else
            NetManager:getMarchToShrinePromose(self:GetFightEvent():Id(),dragonType,soldiers):done(function()
                app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
            end)
            gameuialliancesendtroops:LeftButtonClicked()
        end
    end,{toLocation = self:GetAllianceShrineLocation(),targetIsMyAlliance = true,returnCloseAction = true}):AddToCurrentScene(true)
end

function GameUIShireFightEvent:InfomationButtonClicked()
    UIKit:newGameUI("GameUIAllianceShrineDetail",self:GetFightEvent():Stage(),self:GetAllianceShrine()):AddToCurrentScene(true)
end

return GameUIShireFightEvent

