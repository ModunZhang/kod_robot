local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetAllianceBuildingUpgrade = import("..widget.WidgetAllianceBuildingUpgrade")
local GameUIAlliancePalace = UIKit:createUIClass('GameUIAlliancePalace', "GameUIAllianceBuilding")
local UIListView = import(".UIListView")
local NetService = import('..service.NetService')
local Alliance = import("..entity.Alliance")
local WidgetInfoWithTitle = import("..widget.WidgetInfoWithTitle")
local WidgetInfoNotListView = import("..widget.WidgetInfoNotListView")
local Localize = import("..utils.Localize")
local WidgetInfo = import("..widget.WidgetInfo")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetSliderWithInput = import("..widget.WidgetSliderWithInput")

function GameUIAlliancePalace:ctor(city,default_tab,building)
    GameUIAlliancePalace.super.ctor(self, city, _("联盟宫殿"),default_tab,building)
    self.default_tab = default_tab
    self.building = building
    self.alliance = Alliance_Manager:GetMyAlliance()
end

function GameUIAlliancePalace:OnMoveInStage()
    GameUIAlliancePalace.super.OnMoveInStage(self)
    self:CreateTabButtons({
        {
            label = _("奖励"),
            tag = "impose",
            default = "impose" == self.default_tab,
        },
        {
            label = _("信息"),
            tag = "info",
            default = "info" == self.default_tab,
        },
    }, function(tag)
        if tag == 'impose' then
            self:InitImposePart()
            self.impose_layer:setVisible(true)
        else
            self.impose_layer:setVisible(false)
            self.impose_layer:Clear()
        end
        if tag == 'info' then
            self.info_layer:setVisible(true)
            self:InitInfoPart()
        else
            self.info_layer:setVisible(false)
            self.info_layer:Clear()
        end
    end):pos(window.cx, window.bottom + 34)

    local alliance = self.alliance
    alliance:AddListenOnType(self,"basicInfo")
    alliance:AddListenOnType(self,"members")
end
function GameUIAlliancePalace:CreateBetweenBgAndTitle()
    GameUIAlliancePalace.super.CreateBetweenBgAndTitle(self)
    local parent = self
    -- impose_layer
    local impose_layer = display.newLayer():addTo(self:GetView())
    function impose_layer:Clear()
        self:removeAllChildren()
        parent.current_honour = nil
        parent.award_menmber_listview = nil
    end
    self.impose_layer = impose_layer
    -- info_layer
    local info_layer = display.newLayer():addTo(self:GetView())
    function info_layer:Clear()
        self:removeAllChildren()
    end
    self.info_layer = info_layer
end
function GameUIAlliancePalace:onExit()
    local alliance = self.alliance
    alliance:RemoveListenerOnType(self,"basicInfo")
    alliance:RemoveListenerOnType(self,"members")
    GameUIAlliancePalace.super.onExit(self)
end

-- 初始化奖励部分
function GameUIAlliancePalace:InitImposePart()
    local layer = self.impose_layer
    UIKit:ttfLabel({
        text = _("联盟荣耀"),
        size = 24,
        color = 0x514d3e,
    }):align(display.LEFT_CENTER, window.left+60,window.top_bottom-20):addTo(layer)

    -- 荣耀值
    self.current_honour = self:GetHonourNode():addTo(layer):align(display.CENTER,window.right-100, window.top_bottom-5)

    self.sort_member = self:GetSortMembers()
    -- 可发放奖励成员列表
    local list,list_node = UIKit:commonListView({
        async = true, --异步加载
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0, 0,568,window.betweenHeaderAndTab-80),
    })
    list:setRedundancyViewVal(168)
    list:setDelegate(handler(self, self.DelegateAwardList))
    list:reload()
    list_node:addTo(layer):align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20)
    self.award_menmber_listview = list
end
function GameUIAlliancePalace:GetSortMembers()
    -- 按照当前击杀排序后的 members列表
    local alliance = self.alliance
    local members = alliance:GetAllMembers()
    local sort_member = {}
    for k,v in pairs(members) do
        table.insert(sort_member, v)
    end
    table.sort(sort_member,function (a,b)
        return self:GetLastThreeDaysKill(a:LastThreeDaysKillData()) > self:GetLastThreeDaysKill(b:LastThreeDaysKillData())
    end)
    return sort_member
end
function GameUIAlliancePalace:DelegateAwardList(  listView, tag, idx )
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #self.sort_member
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:CreateAwardContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        content:SetData(idx)
        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        return item
    elseif UIListView.ASY_REFRESH == tag then
        for i,v in ipairs(listView:getItems()) do
            if v.idx_ == idx then
                local content = v:getContent()
                content:SetData(idx)
                local size = content:getContentSize()
                v:setItemSize(size.width, size.height)
            end
        end
    end
end
function GameUIAlliancePalace:CreateAwardContent()
    local item_width,item_height = 568,168
    local content = WidgetUIBackGround.new({width=item_width,height=item_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local title_bg = display.newScale9Sprite("title_blue_430x30.png",item_width/2,item_height-30,cc.size(550,30),cc.rect(15,10,400,10))
        :addTo(content)
    -- 玩家名字
    local name = UIKit:ttfLabel({
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, 60, title_bg:getContentSize().height/2):addTo(title_bg)
    -- 上次发放奖励时间
    local last_reward_time = UIKit:ttfLabel({
        size = 20,
        color = 0xc0b694,
    }):align(display.RIGHT_CENTER, title_bg:getContentSize().width-30, title_bg:getContentSize().height/2):addTo(title_bg)

    local widget_info = WidgetInfoNotListView.new({
        info={_("最近三日击杀"),""},
        {_("最近奖励"),""},
        w =398
    }):align(display.BOTTOM_LEFT, 10 , 10)
        :addTo(content)

    local palace_ui = self
    function content:SetData(idx,member)
        local index = idx or self.index
        self.index = index
        local member = member or palace_ui.sort_member[index]
        self.member = member
        name:setString(index.."."..member:Name())
        if self.head_icon then
            self.head_icon:removeFromParent(true)
        end
        self.head_icon = UIKit:GetPlayerCommonIcon(member:Icon()):addTo(title_bg):pos(20,title_bg:getContentSize().height/2):scale(0.4)

        local lastRewardData = member:LastRewardData()
        local lastRewardTime = tolua.type(lastRewardData) == "table" and NetService:formatTimeAsTimeAgoStyleByServerTime( lastRewardData.time ) or _("无")
        local lastRewardCount = tolua.type(lastRewardData) == "table" and string.formatnumberthousands(lastRewardData.count) or _("无")
        local lastThreeDaysKill = string.formatnumberthousands(palace_ui:GetLastThreeDaysKill(member:LastThreeDaysKillData()))
        local info={
            {_("最近三日击杀"),lastThreeDaysKill},
            {_("最近奖励"),lastRewardCount},
        }
        widget_info:SetInfo(info)
        last_reward_time:setString(lastRewardTime)
        if palace_ui.alliance:GetSelf():IsArchon() then
            -- 奖励按钮
            if self.button then
                self.button:removeFromParent(true)
            end
            self.button = WidgetPushButton.new({normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"})
                :setButtonLabel(UIKit:ttfLabel({
                    text = _("奖赏"),
                    size = 24,
                    color = 0xffedae,
                    shadow= true
                }))
                :onButtonClicked(function(event)
                    if event.name == "CLICKED_EVENT" then
                        palace_ui:OpenAwardDialog(member)
                    end
                end):align(display.BOTTOM_RIGHT, item_width-10,10):addTo(self)
        end
    end

    function content:GetContentData()
        return self.member
    end
    return content
end

function GameUIAlliancePalace:OpenAwardDialog(member)
    local dialog = WidgetPopDialog.new(282,_("奖励"),window.top-160):addTo(self,201)
    local body = dialog:GetBody()
    local body_size = body:getContentSize()
    local hoour_node = display.newNode():addTo(body):align(display.BOTTOM_LEFT,50,60)
    -- 荣耀值
    local honour_icon = display.newSprite("honour_128x128.png"):align(display.CENTER,50,60):addTo(body):scale(42/128)
    local current_honour_label = UIKit:ttfLabel({
        text = GameUtils:formatNumber(self.alliance.basicInfo.honour),
        size = 22,
        color = 0x403c2f,
    }):addTo(body):align(display.LEFT_CENTER,honour_icon:getPositionX()+20,honour_icon:getPositionY())
    local divide = UIKit:ttfLabel({
        text = "-",
        size = 20,
        color = 0x403c2f,
    }):addTo(body):align(display.CENTER,current_honour_label:getPositionX()+ current_honour_label:getContentSize().width + 6,current_honour_label:getPositionY())

    local deduct_honour_label = UIKit:ttfLabel({
        text = "0",
        size = 22,
        color = 0x7e0000,
    }):addTo(body):align(display.LEFT_CENTER,divide:getPositionX()+6,current_honour_label:getPositionY())
    current_honour_label:hide()
    deduct_honour_label:hide()
    divide:hide()
    honour_icon:hide()

    -- 滑动条部分
    local slider_bg = display.newSprite("back_ground_580x136.png"):addTo(body)
        :align(display.CENTER_TOP,body_size.width/2,body_size.height-30)
    -- title
    UIKit:ttfLabel(
        {
            text = _("增加忠诚值"),
            size = 22,
            color = 0x403c2f,
        }):align(display.LEFT_TOP, 20 ,slider_bg:getContentSize().height-15)
        :addTo(slider_bg)

    -- slider
    local slider = WidgetSliderWithInput.new({max = self.alliance.basicInfo.honour})
        :addTo(slider_bg)
        :align(display.CENTER, slider_bg:getContentSize().width/2,  65)
        :OnSliderValueChanged(function(event)
            local value = math.floor(event.value)
            body.button:setButtonEnabled(value ~= 0)
            deduct_honour_label:setString(GameUtils:formatNumber(value))
            divide:setPositionX(current_honour_label:getPositionX()+ current_honour_label:getContentSize().width + 6)
            deduct_honour_label:setPositionX(divide:getPositionX()+6)
            current_honour_label:setVisible(value ~= 0)
            deduct_honour_label:setVisible(value ~= 0)
            divide:setVisible(value ~= 0)
            honour_icon:setVisible(value ~= 0)
        end)
        :LayoutValueLabel(WidgetSliderWithInput.STYLE_LAYOUT.TOP,75)
    -- icon
    local x,y = slider:GetEditBoxPostion()
    local icon = display.newSprite("loyalty_128x128.png")
        :align(display.CENTER, x-80, y)
        :addTo(slider)
    local max = math.max(icon:getContentSize().width,icon:getContentSize().height)
    icon:scale(40/max)
    --奖赏按钮
    body.button = WidgetPushButton.new({normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png",disabled = "grey_btn_186x66.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("奖赏"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                if self.alliance:GetSelf():IsArchon() then
                    NetManager:getGiveLoyaltyToAllianceMemberPromise(member:Id(),slider:GetValue()):done(function ()
                        GameGlobalUI:showTips(_("提示"),_("发放成功"))
                    end)
                    dialog:LeftButtonClicked()
                else
                    UIKit:showMessageDialog(_("提示"),_("只有盟主拥有权限"))
                end
            end
        end):align(display.BOTTOM_RIGHT, body_size.width-20,30):addTo(body)
    body.button:setButtonEnabled(slider:GetValue() ~= 0)

end
function GameUIAlliancePalace:GetLastThreeDaysKill(lastThreeDaysKillData)
    if not lastThreeDaysKillData then return 0 end
    local today = os.date("%Y",app.timer:GetServerTime()).."-"..tonumber(os.date("%m",app.timer:GetServerTime())).."-"..tonumber(os.date("%d",app.timer:GetServerTime()))
    local yesterday = os.date("%Y",app.timer:GetServerTime()-24 * 60 * 60).."-"..tonumber(os.date("%m",app.timer:GetServerTime()-24 * 60 * 60)).."-"..tonumber(os.date("%d",app.timer:GetServerTime()-24 * 60 * 60))
    local theDayBeforeYesterday = os.date("%Y",app.timer:GetServerTime()-24 * 60 * 60 * 2).."-"..tonumber(os.date("%m",app.timer:GetServerTime()-24 * 60 * 60 * 2)).."-"..tonumber(os.date("%d",app.timer:GetServerTime()-24 * 60 * 60 * 2))
    local kill = 0
    for k,v in pairs(lastThreeDaysKillData) do
        print("v.date",v.date)
        if v.date == today
            or v.date == yesterday
            or v.date == theDayBeforeYesterday
        then
            kill = kill + v.kill
        end
    end
    return kill
end
function GameUIAlliancePalace:GetHonourNode(honour)
    local node = display.newNode()
    node:setContentSize(cc.size(160,36))
    -- 荣耀值
    display.newSprite("honour_128x128.png"):align(display.CENTER, 0, 0):addTo(node):scale(42/128)
    local honour_bg = display.newSprite("back_ground_114x36.png"):align(display.CENTER,80, 0):addTo(node)
    local honour_label = UIKit:ttfLabel({
        text = GameUtils:formatNumber(honour or self.alliance.basicInfo.honour),
        size = 20,
        color = 0x403c2f,
    }):addTo(honour_bg):align(display.CENTER,honour_bg:getContentSize().width/2,honour_bg:getContentSize().height/2)
    function node:RefreshHonour(honour)
        honour_label:setString(GameUtils:formatNumber(honour))
    end
    return node
end
function GameUIAlliancePalace:MapTerrianToIndex(terrian)
    local terrian_type = {
        grassLand=1,
        iceField=2,
        desert=3,
    }
    return terrian_type[terrian]
end
function GameUIAlliancePalace:MapIndexToTerrian(index)
    local terrian_type = {
        "grassLand",
        "iceField",
        "desert",
    }
    return terrian_type[index]
end
function GameUIAlliancePalace:InitInfoPart()
    local layer = self.info_layer

    local bg1 = WidgetUIBackGround.new({
        width = 548,
        height = 322,
    },WidgetUIBackGround.STYLE_TYPE.STYLE_3):align(display.TOP_CENTER,window.cx, window.top-100):addTo(layer)
    local bg_size = bg1:getContentSize()
    -- title
    local title_bg = display.newSprite("title_blue_544x32.png"):addTo(bg1):pos(bg_size.width/2,bg_size.height-20)
    UIKit:ttfLabel({
        text = _("地形定义"),
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, 20, title_bg:getContentSize().height/2):addTo(title_bg)
    UIKit:ttfLabel({
        text = _("需要职位是联盟盟主"),
        size = 20,
        color = 0xb7af8e,
    }):align(display.RIGHT_CENTER, title_bg:getContentSize().width-20, title_bg:getContentSize().height/2):addTo(title_bg)

    -- 草地
    local grass_box = display.newSprite("box_132x132_1.png")
        :align(display.CENTER, 87, 215):addTo(bg1)
    local box_size = grass_box:getContentSize()
    local grass = display.newSprite("icon_grass_132x132.png")
        :align(display.CENTER, box_size.width/2,box_size.height/2):addTo(grass_box)
    -- 沙漠
    local icefield_box = display.newSprite("box_132x132_1.png")
        :align(display.CENTER, 272, 215):addTo(bg1)
    local icefield = display.newSprite("icon_icefield_132x132.png")
        :align(display.CENTER, box_size.width/2,box_size.height/2):addTo(icefield_box)
    -- 雪地
    local desert_box = display.newSprite("box_132x132_1.png")
        :align(display.CENTER, 462, 215):addTo(bg1)
    local desert = display.newSprite("icon_desert_132x132.png")
        :align(display.CENTER, box_size.width/2,box_size.height/2):addTo(desert_box)

    -- 地形介绍
    local terian_intro = UIKit:ttfLabel({
        -- text = _("草地地形能产出绿龙装备材料，每当在自己的领土上完成任务，或者击杀一点战斗力的敌方单位，就由一定几率获得装备材料。"),
        size = 20,
        color = 0x514d3e,
        dimensions = cc.size(520, 0),
    }):align(display.BOTTOM_CENTER, bg1:getContentSize().width/2, 10):addTo(bg1)
    local checkbox_image = {
        off = "checkbox_unselected.png",
        off_pressed = "checkbox_unselected.png",
        off_disabled = "checkbox_unselected.png",
        on = "checkbox_selectd.png",
        on_pressed = "checkbox_selectd.png",
        on_disabled = "checkbox_selectd.png",

    }
    local group = cc.ui.UICheckBoxButtonGroup.new(display.LEFT_TO_RIGHT):addButton(cc.ui.UICheckBoxButton.new(checkbox_image)
        :align(display.LEFT_CENTER))
        :addButton(cc.ui.UICheckBoxButton.new(checkbox_image)
            :align(display.LEFT_CENTER))
        :addButton(cc.ui.UICheckBoxButton.new(checkbox_image)
            :align(display.LEFT_CENTER))
        :setButtonsLayoutMargin(0, 130, 0, 0)
        :onButtonSelectChanged(function(event)
            self.select_terrian_index = event.selected
            local t_name = {
                {
                    _("草地"),
                    _("绿龙"),
                },
                {
                    _("雪地"),
                    _("蓝龙"),
                },
                {
                    _("沙漠"),
                    _("红龙"),
                },
            }
            terian_intro:setString(string.format(_("%s地形能产出%s装备材料，每当在自己的领土上完成任务，或者击杀一点战斗力的敌方单位，就由一定几率获得装备材料。"),t_name[self.select_terrian_index][1],t_name[self.select_terrian_index][2]))
        end)
        :align(display.CENTER, 57 , 90)
        :addTo(bg1)
    self.select_terrian_index = self:MapTerrianToIndex(self.alliance.basicInfo.terrain)
    group:getButtonAtIndex(self.select_terrian_index):setButtonSelected(true)


    -- 消耗荣耀值更换地形
    local need_honour = GameDatas.AllianceInitData.intInit.editAllianceTerrianHonour.value
    self:GetHonourNode(need_honour):addTo(layer):align(display.CENTER,window.cx+30, window.top-454)

    -- 购买使用按钮
    WidgetPushButton.new({normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("修改"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                if need_honour > self.alliance.basicInfo.honour then
                    UIKit:showMessageDialog(_("提示"),_("联盟荣耀值不足"))
                elseif self.alliance.basicInfo.status == "fight" or self.alliance.basicInfo.status == "prepare" then
                    UIKit:showMessageDialog(_("提示"),_("战争期不能修改联盟地形"))
                elseif self:MapIndexToTerrian(self.select_terrian_index) == self.alliance.basicInfo.terrain then
                    UIKit:showMessageDialog(_("提示"),_("选择的新地形与当前地形相同"))
                else
                    if self.alliance:GetSelf():CanEditAlliance() then
                        NetManager:getEditAllianceTerrianPromise(self:MapIndexToTerrian(self.select_terrian_index))
                    else
                        UIKit:showMessageDialog(_("提示"),_("权限不足"))
                    end
                end

            end
        end):align(display.CENTER, window.right -120, window.top-470):addTo(layer)

    local countInfo = self.alliance:CountInfo()
    local info_message = {
        {_("击杀部队人口"),string.formatnumberthousands(countInfo.kill)},
        {_("阵亡部队人口"),string.formatnumberthousands(countInfo.beKilled)},
        {_("击溃城市"),string.formatnumberthousands(countInfo.routCount)},
        {_("联盟战胜利"),string.formatnumberthousands(countInfo.winCount)},
        {_("联盟战失败"),string.formatnumberthousands(countInfo.failedCount)},
        {_("胜率"),countInfo.winCount +countInfo.failedCount~=0 and (math.floor(countInfo.winCount/(countInfo.winCount+countInfo.failedCount)*1000)/10).."%" or "0%"},
    }
    WidgetInfoWithTitle.new({
        info = info_message,
        title = _("信息"),
        h = 306
    }):addTo(layer)
        :align(display.BOTTOM_CENTER, window.cx, window.bottom_top+50)
end
function GameUIAlliancePalace:OnAllianceDataChanged_basicInfo(alliance,deltaData)
    local ok, value = deltaData("basicInfo.honour")
    if ok then
        if self.current_honour then
            self.current_honour:RefreshHonour(value)
        end
    end
end
function GameUIAlliancePalace:OnAllianceDataChanged_members(alliance,deltaData)
    self.sort_member = self:GetSortMembers()
    if deltaData("members.add") then
        if self.award_menmber_listview then
            self.award_menmber_listview:asyncLoadWithCurrentPosition_()
        end
    end
    if deltaData("members.remove") then
        if self.award_menmber_listview then
            self.award_menmber_listview:asyncLoadWithCurrentPosition_()
        end
    end
    if deltaData("members.edit") then
    local ok, value = deltaData("members.edit")
        for k,v in pairs(value) do
            if self.award_menmber_listview then
                for i,listitem in ipairs(self.award_menmber_listview:getItems()) do
                    local content = listitem:getContent()
                    local content_member = content:GetContentData()
                    if content_member:Id() == v:Id() then
                        content:SetData(nil,v)
                    end
                end
            end
        end
    end
end
return GameUIAlliancePalace






















