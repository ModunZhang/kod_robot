local WidgetPushButton = import("..widget.WidgetPushButton")
local UIListView = import(".UIListView")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local Alliance = import("..entity.Alliance")
local Localize = import("..utils.Localize")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local intInit = GameDatas.PlayerInitData.intInit

local HELP_EVENTS = "help_events"
local GameUIHelp = class("GameUIHelp", WidgetPopDialog)

function GameUIHelp:ctor()
    GameUIHelp.super.ctor(self,766,_("协助加速"),display.top-100)
    self.alliance = Alliance_Manager:GetMyAlliance()
    self.help_events_items = {}
end

function GameUIHelp:onEnter()
    local body = self.body
    local rb_size = body:getContentSize()

    local desc_bg = display.newScale9Sprite("back_ground_398x97.png", rb_size.width/2, rb_size.height-70,cc.size(556,88),cc.rect(15,10,368,77))
        :addTo(body)

    -- 协助加速介绍
    UIKit:ttfLabel(
        {
            text = _("帮助联盟成员加速并获得联盟忠诚值，激活VIP后能够提升为盟友加速效果"),
            size = 20,
            align = cc.ui.TEXT_ALIGN_CENTER,
            dimensions = cc.size(360,0),
            color = 0x403c2f
        }):align(display.CENTER, desc_bg:getContentSize().width/2, desc_bg:getContentSize().height/2)
        :addTo(desc_bg)

    -- 当天帮助加速获得的忠诚度进度条
    local bar = display.newSprite("progress_bar_540x40_1.png"):addTo(body):pos(rb_size.width/2+10, rb_size.height-156)
    local progressFill = display.newSprite("progress_bar_540x40_3.png")
    self.ProgressTimer = cc.ProgressTimer:create(progressFill)
    local pro = self.ProgressTimer
    pro:setType(display.PROGRESS_TIMER_BAR)
    pro:setBarChangeRate(cc.p(1,0))
    pro:setMidpoint(cc.p(0,0))
    pro:align(display.LEFT_BOTTOM, 0, 0):addTo(bar)
    self.loyalty_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        font = UIKit:getFontFilePath(),
        align = ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0xfff3c7),
    }):addTo(bar):align(display.LEFT_CENTER, 30, bar:getContentSize().height/2)
    self:SetLoyalty()
    local pro_head_bg = display.newSprite("back_ground_43x43.png", 0, bar:getContentSize().height/2):addTo(bar)
    display.newSprite("loyalty_128x128.png",pro_head_bg:getContentSize().width/2,pro_head_bg:getContentSize().height/2):addTo(pro_head_bg):scale(42/128)

    -- 帮助列表
    local list,list_node = UIKit:commonListView_1({
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0, 0,547,456),
    })
    list_node:addTo(body):align(display.BOTTOM_CENTER, rb_size.width/2,90)

    self.help_listview = list

    self:InitHelpEvents()
    -- 全部帮助按钮
    local help_all_button = WidgetPushButton.new(
        {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"}
    ):setButtonLabel(UIKit:ttfLabel({text = _("全部帮助"), size = 22, color = 0xfff3c7,shadow = true}))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                NetManager:getHelpAllAllianceMemberSpeedUpPromise():done(function ()
                        GameGlobalUI:showTips(_("提示"),_("协助加速成功"))
                end)
            end
        end):addTo(body):pos(rb_size.width/2, 50)
    help_all_button:setVisible(self:IsAbleToHelpAll())
    self.help_all_button = help_all_button
    self.alliance:AddListenOnType(self, "helpEvents")
    User:AddListenOnType(self, "countInfo")
end
function GameUIHelp:IsAbleToHelpAll()
    for k,item in pairs(self.help_events_items) do
        if item:IsAbleToHelp() then
            return true
        end
    end
    return false
end
function GameUIHelp:SetLoyalty()
    self.loyalty_label:setString(_("每日获得最大忠诚度：")..User.countInfo.todayLoyaltyGet.."/"..intInit.maxLoyaltyGetPerDay.value)
    self.ProgressTimer:setPercentage(math.floor(User.countInfo.todayLoyaltyGet/10000*100))
end
function GameUIHelp:InitHelpEvents()
    local help_events = self.alliance:GetCouldShowHelpEvents()
    if help_events then
        self.help_listview:removeAllItems()
        self.help_events_items = {}
        for k,event in pairs(help_events) do
            self:InsertItemToList(event)
        end
        self.help_listview:reload()
    end
end
function GameUIHelp:InsertItemToList(help_event)
    -- 当前玩家的求助事件需要置顶
    local item = self:CreateHelpItem(help_event)
    if User:Id() == help_event.playerData.id then
        self.help_listview:addItem(item,1)
    else
        self.help_listview:addItem(item)
    end
end
function GameUIHelp:IsHelpedByMe(helpedMembers)
    local _id = User:Id()
    for k,id in pairs(helpedMembers) do
        if id == _id then
            return true
        end
    end
end
function GameUIHelp:IsHelpedToMaxNum(event)
    return #event.eventData.helpedMembers == event.eventData.maxHelpCount
end
function GameUIHelp:RefreshUI(help_events)
    for k,item in pairs(self.help_events_items) do
        -- 帮助事件已经结束，删除列表中对应的帮助项
        local flag = true
        local flag_1 = true

        for _,v in pairs(help_events) do
            if v:Id()==k then
                -- 帮助过的需要删除
                if not self:IsHelpedByMe(v.eventData.helpedMembers) or not self:IsHelpedToMaxNum(v) then
                    flag = false
                end
            end
        end

        if flag then
            self:DeleteHelpItem(k)
        end
    end
    for k,event in pairs(help_events) do
        if not self.help_events_items[event:Id()] then
            self:InsertItemToList(event)
            self.help_listview:reload()
        end
    end
end

function GameUIHelp:DeleteHelpItem(id)
    if self.help_events_items[id] then
        self.help_listview:removeItem(self.help_events_items[id])
        self.help_events_items[id] = nil
    end
end
function GameUIHelp:GetHelpEventDesc( eventData )
    local type = eventData.type
    local name = eventData.name
    if type == "buildingEvents"
        or type == "houseEvents"
    then
        return _("正在升级")..Localize.building_name[name].._("等级")..eventData.level
    elseif type == "militaryTechEvents" then
        local names = string.split(name, "_")
        if names[2] == "hpAdd" then
            return string.format(_("研发%s血量增加 等级 %d"),Localize.soldier_category[names[1]],eventData.level)
        end
        return string.format(_("研发%s对%s的攻击到 等级 %d"),Localize.soldier_category[names[1]],Localize.soldier_category[names[2]],eventData.level)
    elseif type == "soldierStarEvents" then
        return string.format(_("晋升%s的星级 star %d"),Localize.soldier_name[name],eventData.level)
    elseif type == "materialEvents" then
        return _("未处理")
    elseif type == "soldierEvents" then
        return _("未处理")
    elseif type == "treatSoldierEvents" then
        return _("未处理")
    elseif type == "dragonEquipmentEvents" then
        return _("未处理")
    elseif type == "dragonHatchEvents" then
        return _("未处理")
    elseif type == "dragonDeathEvents" then
        return _("未处理")
    elseif type == "productionTechEvents" then
        return string.format(_("正在研发%s到 Level %d"),Localize.productiontechnology_name[name],eventData.level)
    end
end
function GameUIHelp:CreateHelpItem(event)
    local playerData = event.playerData
    local eventData = event.eventData

    local item = self.help_listview:newItem()
    item.eventId = event.id
    local item_width, item_height = 547,114
    item:setItemSize(item_width, item_height)

    local body_image = self.which_bg and "back_ground_548x40_1.png" or "back_ground_548x40_2.png"
    self.which_bg = not self.which_bg
    local bg = display.newScale9Sprite(body_image,0,0,cc.size(item_width, item_height),cc.rect(10,10,528,20))

    local bg_size = bg:getContentSize()
    display.newSprite("people.png"):addTo(bg):pos(28, bg_size.height-20)
    -- 玩家名字
    local name_label = UIKit:ttfLabel({
        text = playerData.name,
        size = 22,
        color = 0x403c2f,
    }):addTo(bg):align(display.LEFT_CENTER, 50, bg_size.height-20)
    -- 请求帮助事件
    UIKit:ttfLabel({
        text = self:GetHelpEventDesc(eventData),
        size = 18,
        color = 0x615b44,
    }):addTo(bg):align(display.LEFT_TOP, 18, bg_size.height-40)
    -- 此条事件被帮助次数进度条
    local bar = display.newSprite("progress_bar_364x40_1.png"):addTo(bg):pos(200,28)
    local progressFill = display.newSprite("progress_bar_364x40_3.png")
    local ProgressTimer = cc.ProgressTimer:create(progressFill)
    local pro = ProgressTimer
    pro:setType(display.PROGRESS_TIMER_BAR)
    pro:setBarChangeRate(cc.p(1,0))
    pro:setMidpoint(cc.p(0,0))
    pro:align(display.LEFT_BOTTOM, 0, 0):addTo(bar)


    local helpedMembers = eventData.helpedMembers
    local maxHelpCount = eventData.maxHelpCount
    pro:setPercentage(math.floor(#helpedMembers/maxHelpCount*100))
    local help_label = UIKit:ttfLabel({
        text = _("帮助").." "..#helpedMembers.."/"..maxHelpCount,
        size = 18,
        align = ui.TEXT_ALIGN_CENTER,
        color = 0xfff3c7,
        shadow = true,
    }):addTo(bar):align(display.LEFT_CENTER, 30, bar:getContentSize().height/2)
    -- 帮助按钮
    if User:Id() ~= playerData.id then
        local help_button = WidgetPushButton.new(
            {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"}
        ):setButtonLabel(UIKit:ttfLabel({text = _("帮助"), size = 22, color = 0xfff3c7,shadow = true,}))
            :onButtonClicked(function(e)
                if e.name == "CLICKED_EVENT" then
                    NetManager:getHelpAllianceMemberSpeedUpPromise(event.id):done(function ( )
                        GameGlobalUI:showTips(_("提示"),_("协助加速成功"))
                    end)
                end
            end):addTo(bg):pos(470, 34)
    end
    item:addContent(bg)

    self.help_events_items[event.id] = item

    function item:SetHelp(event)
        help_label:setString(_("帮助").." "..#event.eventData.helpedMembers.."/"..event.eventData.maxHelpCount)
        ProgressTimer:setPercentage(math.floor(#event.eventData.helpedMembers/event.eventData.maxHelpCount*100))
        return item
    end

    function item:IsAbleToHelp()
        return User:Id() ~= event.playerData.id
    end

    return item
end
function GameUIHelp:OnAllianceDataChanged_helpEvents()
    self:InitHelpEvents()
    self.help_all_button:setVisible(self:IsAbleToHelpAll())
end
function GameUIHelp:OnUserDataChanged_countInfo()
    self:SetLoyalty()
end
function GameUIHelp:onExit()
    self.alliance:RemoveListenerOnType(self, "helpEvents")
    User:RemoveListenerOnType(self, "countInfo")
end

return GameUIHelp











