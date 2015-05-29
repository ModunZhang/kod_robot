--
-- Author: Danny He
-- Date: 2014-10-06 18:18:26
--
local Enum = import("..utils.Enum")
local window = import('..utils.window')
local UIScrollView = import(".UIScrollView")
local UIListView = import(".UIListView")
local WidgetBackGroundTabButtons = import("..widget.WidgetBackGroundTabButtons")
local GameUIAlliance = UIKit:createUIClass("GameUIAlliance","GameUIWithCommonHeader")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")
local contentWidth = window.width - 80
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetAllianceCreateOrEdit = import("..widget.WidgetAllianceCreateOrEdit")
local GameUIAllianceNoticeOrDescEdit = import(".GameUIAllianceNoticeOrDescEdit")
local Localize = import("..utils.Localize")
local NetService = import('..service.NetService')
local Alliance_Manager = Alliance_Manager
local User = User
local Alliance = import("..entity.Alliance")
local WidgetAllianceHelper = import("..widget.WidgetAllianceHelper")
local Flag = import("..entity.Flag")
local GameUIWriteMail = import('.GameUIWriteMail')
local UILib = import(".UILib")
local UICheckBoxButton = import(".UICheckBoxButton")
local UICanCanelCheckBoxButtonGroup = import('.UICanCanelCheckBoxButtonGroup')
local GameUtils = GameUtils
GameUIAlliance.COMMON_LIST_ITEM_TYPE = Enum("JOIN","INVATE","APPLY")
local JOIN_LIST_PAGE_SIZE = 10
--
--------------------------------------------------------------------------------
function GameUIAlliance:ctor(default_tab)
    GameUIAlliance.super.ctor(self,City,_("联盟"))
    self.alliance_ui_helper = WidgetAllianceHelper.new()
    self.default_tab = default_tab or "join"
end

function GameUIAlliance:OnAllianceBasicChanged(alliance, changed_map)
    if Alliance_Manager:GetMyAlliance():IsDefault() then return end
    if self.tab_buttons:GetSelectedButtonTag() == 'overview' then
        if changed_map.flag then
            self:RefreshFlag()
        else
            self:RefreshOverViewUI()
        end
    end
    if self.tab_buttons:GetSelectedButtonTag() == 'infomation' then
        self:RefreshInfomationView()
    end
end

function GameUIAlliance:OnJoinEventsChanged(alliance)

end

function GameUIAlliance:OnEventsChanged(alliance)
    if self.tab_buttons:GetSelectedButtonTag() == 'overview' then
        self:RefreshEventListView()
    end
end

function GameUIAlliance:OnMemberChanged(alliance)
    if self.tab_buttons:GetSelectedButtonTag() == 'overview' then
        self:RefreshOverViewUI()
    end
end

function GameUIAlliance:OnOperation(alliance,operation_type)
    self:RefreshMainUI()
end

function GameUIAlliance:AddListenerOfMyAlliance()
    local myAlliance = Alliance_Manager:GetMyAlliance()
    myAlliance:AddListenOnType(self, Alliance.LISTEN_TYPE.BASIC)
    -- join or quit
    myAlliance:AddListenOnType(self, Alliance.LISTEN_TYPE.OPERATION)
    myAlliance:AddListenOnType(self, Alliance.LISTEN_TYPE.MEMBER)
    myAlliance:AddListenOnType(self, Alliance.LISTEN_TYPE.EVENTS)
    myAlliance:AddListenOnType(self, Alliance.LISTEN_TYPE.JOIN_EVENTS)
end

function GameUIAlliance:Reset()
    self.createScrollView = nil
    self.joinNode = nil
    self.invateNode = nil
    self.applyNode = nil
    self.overviewNode = nil
    self.memberListView = nil
    self.informationNode = nil
    self.currentContent = nil
    self.member_list_bg = nil
end

function GameUIAlliance:OnMoveInStage()
    GameUIAlliance.super.OnMoveInStage(self)
    self:RefreshMainUI()
    self:AddListenerOfMyAlliance()
end

function GameUIAlliance:RefreshMainUI()
    self:Reset()
    self.main_content:removeAllChildren()
    if Alliance_Manager:GetMyAlliance():IsDefault() then
        self:CreateNoAllianceUI()
    else
        self:CreateHaveAlliaceUI()
    end
end

function GameUIAlliance:CreateBetweenBgAndTitle()
    self.main_content = display.newNode():addTo(self:GetView()):pos(window.left,window.bottom_top)
    self.main_content:setContentSize(cc.size(window.width,window.betweenHeaderAndTab))
end

function GameUIAlliance:OnMoveOutStage()
    local myAlliance = Alliance_Manager:GetMyAlliance()
    myAlliance:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.BASIC)
    -- join or quit
    myAlliance:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.OPERATION)
    myAlliance:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.MEMBER)
    myAlliance:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.EVENTS)
    myAlliance:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.JOIN_EVENTS)
    GameUIAlliance.super.OnMoveOutStage(self)
end

------------------------------------------------------------------------------------------------
---- I did not have a alliance
------------------------------------------------------------------------------------------------

function GameUIAlliance:CreateNoAllianceUI()
    self.tab_buttons = self:CreateTabButtons(
        {
            {
                label = _("创建"),
                tag = "create",
                default = self.default_tab == 'create'
            },
            {
                label = _("加入"),
                tag = "join",
                default = self.default_tab == 'join'
            },
            {
                label = _("邀请"),
                tag = "invite",
                default = self.default_tab == 'invite'
            },
            {
                label = _("申请"),
                tag = "apply",
                default = self.default_tab == 'apply'
            },
        },
        function(tag)
            --call common tabButtons event
            if self["NoAllianceTabEvent_" .. tag .. "If"] then
                if self.currentContent then
                    self.currentContent:hide()
                end
                self.currentContent = self["NoAllianceTabEvent_" .. tag .. "If"](self)
                assert(self.currentContent)
                self.currentContent:show()
            end
        end
    ):pos(window.cx, window.bottom + 34)
end

-- TabButtons event

--1 main
function GameUIAlliance:NoAllianceTabEvent_createIf()
    if self.createScrollView then
        return self.createScrollView
    end
    local basic_setting = WidgetAllianceCreateOrEdit.new()

    local scrollView = UIScrollView.new({
        viewRect = cc.rect(0,10,window.width,window.betweenHeaderAndTab),
    })
        :addScrollNode(basic_setting:pos(55,0))
        :setDirection(UIScrollView.DIRECTION_VERTICAL)
        :addTo(self.main_content)
    scrollView:fixResetPostion(3)
    self.createScrollView = scrollView
    return self.createScrollView
end

--2.join
function GameUIAlliance:NoAllianceTabEvent_joinIf()
    self.join_list_page = 1
    if self.joinNode then
        self:GetJoinList()
        return self.joinNode
    end
    local joinNode = display.newNode():addTo(self.main_content)
    self.joinNode = joinNode
    local searchIcon = display.newSprite("alliacne_search_29x33.png"):addTo(joinNode)
        :align(display.LEFT_TOP,40,self.main_content:getCascadeBoundingBox().height - 30)
    local function onEdit(event, editbox)
        if event == "return" then
            self:SearchAllianAction(self.editbox_tag_search:getText())
        end
    end

    local editbox_tag_search = cc.ui.UIInput.new({
        UIInputType = 1,
        image = "input_box.png",
        size = cc.size(510,48),
        listener = onEdit,
    })

    editbox_tag_search:setPlaceHolder(_("搜索联盟标签"))
    editbox_tag_search:setPlaceholderFontColor(UIKit:hex2c3b(0xccc49e))
    editbox_tag_search:setMaxLength(3)
    editbox_tag_search:setFont(UIKit:getEditBoxFont(),18)
    editbox_tag_search:setFontColor(cc.c3b(0,0,0))
    editbox_tag_search:setReturnType(cc.KEYBOARD_RETURNTYPE_SEARCH)
    editbox_tag_search:setInputMode(cc.EDITBOX_INPUT_MODE_ASCII_CAPABLE)
    editbox_tag_search:align(display.LEFT_TOP,searchIcon:getPositionX()+searchIcon:getContentSize().width+10,self.main_content:getCascadeBoundingBox().height - 10):addTo(joinNode)
    self.editbox_tag_search = editbox_tag_search
    local list,list_node = UIKit:commonListView({
        direction = UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0, 0,568,680),
        async = true,
    })
    list_node:addTo(joinNode):pos((window.width - 568)/2,30)
    list:setDelegate(handler(self, self.JoinListsourceDelegate))
    self.joinListView = list
    self:GetJoinList()
    return joinNode
end

-- tag ~= nil -->search
function GameUIAlliance:GetJoinList(tag)
    if tag and string.len(tag) >  0 then
        NetManager:getSearchAllianceByTagPromsie(tag):done(function(response)
            if not response.msg or not response.msg.allianceDatas then return end
            if response.msg.allianceDatas  then
                self.join_list_data_source = response.msg.allianceDatas
                self:RefreshJoinListView()
            end
        end)
    else
        if self.isLoadingJoin then return end
        self.isLoadingJoin = true
        NetManager:getFetchCanDirectJoinAlliancesPromise(0):done(function(response)
            if not response.msg or not response.msg.allianceDatas then return end
            if response.msg.allianceDatas then
                self.join_list_data_source = response.msg.allianceDatas
                self:RefreshJoinListView()
            end
        end):always(function()
            self.isLoadingJoin = false
        end)
    end
end

function GameUIAlliance:GetMoreJoinListData()
    if self.isLoadingJoin or string.len(self.editbox_tag_search:getText()) ~= 0 then return end
    self.isLoadingJoin = true
    self.join_list_page = self.join_list_page + 1
    NetManager:getFetchCanDirectJoinAlliancesPromise(JOIN_LIST_PAGE_SIZE * (self.join_list_page - 1)):done(function(response)
        if not response.msg or not response.msg.allianceDatas then return end
        if response.msg.allianceDatas then
            table.insertto(self.join_list_data_source, response.msg.allianceDatas)
        end
    end):always(function()
        self.isLoadingJoin = false
    end):fail(function()
        self.join_list_page = self.join_list_page - 1
    end)
end

function GameUIAlliance:JoinListsourceDelegate(listView, tag, idx)
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #self.join_list_data_source
    elseif cc.ui.UIListView.CELL_TAG == tag then
        if idx % JOIN_LIST_PAGE_SIZE == 0 and #self.join_list_data_source - idx < JOIN_LIST_PAGE_SIZE then
            self:GetMoreJoinListData()
        end
        local item
        local content
        item = self.joinListView:dequeueItem()
        local data = self.join_list_data_source[idx]
        if not item then
            item = self.joinListView:newItem()
            content = self:GetJoinListItemContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        self:RefreshJoinListContent(data,content,idx)
        item:setItemSize(568,206)
        return item
    else
    end
end

function GameUIAlliance:RefreshJoinListContent(alliance,content,idx)
    content.nameLabel:setString(string.format("[%s] %s",alliance.tag,alliance.name))
    content.memberValLabel:setString(string.format("%s/%s",alliance.members,alliance.membersMax))
    content.fightingValLabel:setString(string.formatnumberthousands(alliance.power))
    content.languageValLabel:setString(alliance.language)
    content.killValLabel:setString(alliance.kill)
    content.leaderLabel:setString(alliance.archon)
    local terrain = alliance.terrain
    local flag_info = alliance.flag
    if content.flag_sprite then
        content.flag_sprite:removeSelf()
    end
    local flag_sprite = self.alliance_ui_helper:CreateFlagWithRhombusTerrain(terrain,Flag.new():DecodeFromJson(flag_info))
    flag_sprite:addTo(content.flag_box):pos(50,40)
    content.flag_sprite = flag_sprite
    if content.flag_button then
        content.flag_button:removeSelf()
    end
    local flag_button = WidgetPushTransparentButton.new(cc.rect(0,0,100,100)):addTo(content.flag_box):align(display.LEFT_BOTTOM,0,0):onButtonClicked(function()
        self:OnJoinListGetAllianceInfoButtonClicked(idx)
    end)
    content.flag_button = flag_button
    if content.action_button then
        content.action_button:removeSelf()
    end
    if alliance.joinType == 'all' then
        local join_button = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"}):setButtonLabel(UIKit:ttfLabel({text = _("加入"),
            size = 20,
            shadow = true,
            color = 0xfff3c7
        })):align(display.RIGHT_TOP,558,156):addTo(content)
            :onButtonClicked(function(event)
                self:OnJoinListActionButtonClicked(idx)
            end)
        content.action_button = join_button
    else
        local apply_button = WidgetPushButton.new({normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"}):setButtonLabel(UIKit:ttfLabel({text = _("申请"),
            size = 20,
            shadow = true,
            color = 0xfff3c7
        })):align(display.RIGHT_TOP,558,156):addTo(content)
            :onButtonClicked(function(event)
                self:OnJoinListActionButtonClicked(idx)
            end)
        content.action_button = apply_button
    end
end

function GameUIAlliance:OnJoinListActionButtonClicked(idx)
    local alliance = self.join_list_data_source[idx]
    if not alliance then return end
    if  alliance.joinType == 'all' then --如果是直接加入
        NetManager:getJoinAllianceDirectlyPromise(alliance.id):fail(function()
            self:SearchAllianAction(self.editbox_tag_search:getText())
        end):done(function()
        GameGlobalUI:showTips(_("提示"),string.format(_("加入%s联盟成功!"),alliance.name))
        end)
    else
        NetManager:getRequestToJoinAlliancePromise(alliance.id):done(function()
            UIKit:showMessageDialog(_("申请成功"),
                string.format(_("您的申请已发送至%s,如果被接受将加入该联盟,如果被拒绝,将收到一封通知邮件."),alliance.name),
                function()end)
        end):fail(function()
            self:SearchAllianAction(self.editbox_tag_search:getText())
        end)
    end
end

function GameUIAlliance:OnJoinListGetAllianceInfoButtonClicked(idx)
    local data = self.join_list_data_source[idx]
    if data and data.id then
        UIKit:newGameUI("GameUIAllianceInfo",data.id):AddToCurrentScene(true)
    end
end
function GameUIAlliance:GetJoinListItemContent()
    local bg = WidgetUIBackGround.new({width = 568,height = 206},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local flag_box = display.newScale9Sprite("alliance_item_flag_box_126X126.png")
        :size(100,100)
        :addTo(bg)
        :align(display.LEFT_TOP, 6, bg:getContentSize().height - 10)
    display.newSprite("info_26x26.png"):align(display.LEFT_BOTTOM, 0, 0):addTo(flag_box):scale(0.7)
    bg.flag_box = flag_box

    local titleBg = display.newScale9Sprite("title_blue_430x30.png",0,0, cc.size(438,30), cc.rect(10,10,410,10))
        :addTo(bg)
        :align(display.RIGHT_TOP,bg:getContentSize().width-10, bg:getContentSize().height - 10)
    local nameLabel = UIKit:ttfLabel({
        text = "name",
        size = 22,
        color = 0xffedae
    }):addTo(titleBg):align(display.LEFT_CENTER,10, 15)
    local info_bg = UIKit:CreateBoxPanelWithBorder({height = 82})
        :align(display.LEFT_BOTTOM, flag_box:getPositionX(),10)
        :addTo(bg)
    local memberTitleLabel = UIKit:ttfLabel({
        text = _("成员"),
        size = 20,
        color = 0x615b44
    }):addTo(info_bg):align(display.LEFT_TOP,10,info_bg:getContentSize().height - 10)

    local memberValLabel = UIKit:ttfLabel({
        text = "14/50", --count of members
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_TOP,70, memberTitleLabel:getPositionY())


    local fightingTitleLabel = UIKit:ttfLabel({
        text = _("战斗力"),
        size = 20,
        color = 0x615b44
    }):addTo(info_bg):align(display.LEFT_TOP, 340, memberTitleLabel:getPositionY())

    local fightingValLabel = UIKit:ttfLabel({
        text = "power",
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_TOP, 430, fightingTitleLabel:getPositionY())


    local languageTitleLabel = UIKit:ttfLabel({
        text = _("语言"),
        size = 20,
        color = 0x615b44
    }):addTo(info_bg):align(display.LEFT_BOTTOM,memberTitleLabel:getPositionX(),10)

    local languageValLabel = UIKit:ttfLabel({
        text = "alliance.language", -- language
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_BOTTOM,memberValLabel:getPositionX(),10)


    local killTitleLabel = UIKit:ttfLabel({
        text = _("击杀"),
        size = 20,
        color = 0x615b44,
        align = ui.TEXT_ALIGN_RIGHT,
    }):addTo(info_bg):align(display.LEFT_BOTTOM, fightingTitleLabel:getPositionX(),10)

    local killValLabel = UIKit:ttfLabel({
        text = "alliance.kill",
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_BOTTOM, fightingValLabel:getPositionX(), 10)

    local leaderIcon = display.newSprite("alliance_item_leader_39x39.png")
        :addTo(bg)
        :align(display.LEFT_TOP,titleBg:getPositionX() - titleBg:getContentSize().width, titleBg:getPositionY() - titleBg:getContentSize().height -12)
    local leaderLabel = UIKit:ttfLabel({
        text = "alliance.archon",
        size = 22,
        color = 0x403c2f
    }):addTo(bg):align(display.LEFT_TOP,leaderIcon:getPositionX()+leaderIcon:getContentSize().width+15, leaderIcon:getPositionY()-4)
    bg.nameLabel = nameLabel
    bg.memberValLabel = memberValLabel
    bg.fightingValLabel = fightingValLabel
    bg.languageValLabel = languageValLabel
    bg.killValLabel = killValLabel
    bg.leaderLabel = leaderLabel
    return bg
end

function GameUIAlliance:RefreshJoinListView()
    self.joinListView:reload()
end

function GameUIAlliance:SearchAllianAction(tag)
    if tag then tag = string.trim(tag) end
    self:GetJoinList(tag)
end

--3.invite
function GameUIAlliance:NoAllianceTabEvent_inviteIf()
    if self.invateNode then
        self:RefreshInvateListView()
        return self.invateNode
    end
    local invateNode = display.newNode():addTo(self.main_content)
    self.invateNode = invateNode
    local list,list_node = UIKit:commonListView({
        viewRect = cc.rect(0, 0,608,710),
        direction = UIScrollView.DIRECTION_VERTICAL,
    })
    list_node:addTo(invateNode):pos(15,30)
    UIKit:ttfLabel({
        text = _("下列联盟邀请你加入"),
        size = 22,
        color= 0x615b44,
        align = cc.TEXT_ALIGNMENT_CENTER
    }):align(display.BOTTOM_CENTER,window.cx,760):addTo(invateNode)
    self.invateListView = list
    self:RefreshInvateListView()
    return invateNode
end

function GameUIAlliance:RefreshInvateListView()
    local list = User:InviteToAllianceEvents()
    self.invateListView:removeAllItems()
    for i,v in ipairs(list) do
        local item = self:getCommonListItem_(self.COMMON_LIST_ITEM_TYPE.INVATE,v)
        self.invateListView:addItem(item)
    end
    self.invateListView:reload()
end

function GameUIAlliance:NoAllianceTabEvent_applyIf()
    if self.applyNode then
        self:RefreshApplyListView()
        return self.applyNode
    end
    local applyNode = display.newNode():addTo(self.main_content)
    self.applyNode = applyNode
    local list,list_node = UIKit:commonListView({
        viewRect = cc.rect(0, 0,608,710),
        direction = UIScrollView.DIRECTION_VERTICAL,
    })
    list_node:addTo(applyNode):pos(15,30)
    self.applyListView = list
    UIKit:ttfLabel({
        text = _("下列等待联盟审批"),
        size = 22,
        color= 0x615b44,
        align = cc.TEXT_ALIGNMENT_CENTER
    }):align(display.BOTTOM_CENTER,window.cx,760):addTo(applyNode)
    self:RefreshApplyListView()
    return applyNode
end

function GameUIAlliance:RefreshApplyListView()
    local list = User:RequestToAllianceEvents()
    self.applyListView:removeAllItems()
    for i,v in ipairs(list) do
        local item = self:getCommonListItem_(self.COMMON_LIST_ITEM_TYPE.APPLY,v)
        self.applyListView:addItem(item)
    end
    self.applyListView:reload()
end

function GameUIAlliance:getAllianceArchonName( alliance )
    for _,v in ipairs(alliance.members) do
        if v.title == 'archon' then
            return v.name
        end
    end
end


--  listType:join appy invate
function GameUIAlliance:getCommonListItem_(listType,alliance)
    local targetListView = nil
    local item = nil
    local terrain,flag_info = nil,nil
    terrain = alliance.terrain
    flag_info = alliance.flag
    if listType == self.COMMON_LIST_ITEM_TYPE.INVATE then
        targetListView = self.invateListView
    else
        targetListView = self.applyListView
    end

    local item = targetListView:newItem()
    local bg = WidgetUIBackGround.new({width = 568,height = 206},WidgetUIBackGround.STYLE_TYPE.STYLE_2)

    local flag_box = display.newScale9Sprite("alliance_item_flag_box_126X126.png")
        :size(100,100)
        :addTo(bg)
        :align(display.LEFT_TOP, 6, bg:getContentSize().height - 10)

    local flag_sprite = self.alliance_ui_helper:CreateFlagWithRhombusTerrain(terrain,Flag.new():DecodeFromJson(flag_info))
    flag_sprite:addTo(flag_box)
    flag_sprite:pos(50,40)
    display.newSprite("info_26x26.png"):align(display.LEFT_BOTTOM, 0, 0):addTo(flag_box):scale(0.7)
    WidgetPushTransparentButton.new(cc.rect(0,0,100,100)):addTo(flag_box):align(display.LEFT_BOTTOM,0,0):onButtonClicked(function()
        UIKit:newGameUI("GameUIAllianceInfo",alliance.id):AddToCurrentScene(true)
    end)
    local titleBg = display.newScale9Sprite("title_blue_430x30.png",0,0, cc.size(438,30), cc.rect(10,10,410,10))
        :addTo(bg)
        :align(display.RIGHT_TOP,bg:getContentSize().width-10, bg:getContentSize().height - 10)
    local nameLabel = UIKit:ttfLabel({
        text = string.format("[%s] %s",alliance.tag,alliance.name), -- alliance name
        size = 22,
        color = 0xffedae
    }):addTo(titleBg):align(display.LEFT_CENTER,10, 15)
    local info_bg = UIKit:CreateBoxPanelWithBorder({height = 82})
        :align(display.LEFT_BOTTOM, flag_box:getPositionX(),10)
        :addTo(bg)
    local memberTitleLabel = UIKit:ttfLabel({
        text = _("成员"),
        size = 20,
        color = 0x615b44
    }):addTo(info_bg):align(display.LEFT_TOP,10,info_bg:getContentSize().height - 10)

    local memberValLabel = UIKit:ttfLabel({
        text = "14/50", --count of members
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_TOP,70, memberTitleLabel:getPositionY())


    local fightingTitleLabel = UIKit:ttfLabel({
        text = _("战斗力"),
        size = 20,
        color = 0x615b44
    }):addTo(info_bg):align(display.LEFT_TOP, 340, memberTitleLabel:getPositionY())

    local fightingValLabel = UIKit:ttfLabel({
        text = alliance.power,
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_TOP, 430, fightingTitleLabel:getPositionY())


    local languageTitleLabel = UIKit:ttfLabel({
        text = _("语言"),
        size = 20,
        color = 0x615b44
    }):addTo(info_bg):align(display.LEFT_BOTTOM,memberTitleLabel:getPositionX(),10)

    local languageValLabel = UIKit:ttfLabel({
        text = alliance.language, -- language
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_BOTTOM,memberValLabel:getPositionX(),10)


    local killTitleLabel = UIKit:ttfLabel({
        text = _("击杀"),
        size = 20,
        color = 0x615b44,
        align = ui.TEXT_ALIGN_RIGHT,
    }):addTo(info_bg):align(display.LEFT_BOTTOM, fightingTitleLabel:getPositionX(),10)

    local killValLabel = UIKit:ttfLabel({
        text = alliance.kill,
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_BOTTOM, fightingValLabel:getPositionX(), 10)

    if listType == self.COMMON_LIST_ITEM_TYPE.INVATE then
        local argreeButton = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
            :setButtonLabel(
                UIKit:ttfLabel({
                    text = _("同意"),
                    size = 20,
                    shadow = true,
                    color = 0xfff3c7
                })
            )
            :align(display.RIGHT_TOP,titleBg:getPositionX(),titleBg:getPositionY() - titleBg:getContentSize().height -10)
            :onButtonClicked(function(event)
                self:commonListItemAction(listType,item,alliance,2)
            end)
            :addTo(bg)
        local rejectButton = WidgetPushButton.new({normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"})
            :setButtonLabel(
                UIKit:ttfLabel({
                    text = _("拒绝"),
                    size = 20,
                    shadow = true,
                    color = 0xfff3c7
                })
            )
            :align(display.RIGHT_TOP,argreeButton:getPositionX() - 148 - 20, argreeButton:getPositionY())
            :onButtonClicked(function(event)
                self:commonListItemAction(listType,item,alliance,1)
            end)
            :addTo(bg)
        memberValLabel:setString(string.format("%s/%s",alliance.members,alliance.membersMax))
    elseif listType == self.COMMON_LIST_ITEM_TYPE.APPLY then
        local leaderIcon = display.newSprite("alliance_item_leader_39x39.png")
            :addTo(bg)
            :align(display.LEFT_TOP,titleBg:getPositionX() - titleBg:getContentSize().width, titleBg:getPositionY() - titleBg:getContentSize().height -12)
        local leaderLabel = UIKit:ttfLabel({
            text = alliance.archon,
            size = 22,
            color = 0x403c2f
        }):addTo(bg):align(display.LEFT_TOP,leaderIcon:getPositionX()+leaderIcon:getContentSize().width+15, leaderIcon:getPositionY()-4)

        local cancel_button = WidgetPushButton.new({normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"})
            :setButtonLabel(
                UIKit:ttfLabel({
                    text = _("撤销"),
                    size = 20,
                    shadow = true,
                    color = 0xfff3c7
                })
            )
            :align(display.RIGHT_TOP,titleBg:getPositionX(), titleBg:getPositionY() - titleBg:getContentSize().height -10)
            :onButtonClicked(function(event)
                self:commonListItemAction(listType,item,alliance)
            end)
            :addTo(bg)
        memberValLabel:setString(string.format("%s/%s",alliance.members,alliance.membersMax))
        fightingValLabel:setString(alliance.power)
        languageValLabel:setString(alliance.language)
        killValLabel:setString(alliance.kill)
    end
    item:addContent(bg)
    item:setItemSize(bg:getContentSize().width,bg:getContentSize().height)
    return item
end


function GameUIAlliance:commonListItemAction( listType,item,alliance,tag)
    if  listType == self.COMMON_LIST_ITEM_TYPE.APPLY then
        NetManager:getCancelJoinAlliancePromise(alliance.id):done(function()
            self:RefreshApplyListView()
        end)
    elseif listType == self.COMMON_LIST_ITEM_TYPE.INVATE then
        -- tag == 1 -> 拒绝
        NetManager:getHandleJoinAllianceInvitePromise(alliance.id,tag~=1):done(function()
            if tag == 1 then
                self:RefreshInvateListView()
            else
                GameGlobalUI:showTips(_("提示"),string.format(_("加入%s联盟成功!"),alliance.name))
            end
        end):fail(function(msg)
            if tag ~= 1 then -- 同意
                local code = msg.errcode and msg.errcode[1].code or nil
                if code then
                    if UIKit:getErrorCodeKey(code) == 'allianceNotExist' then
                        self:commonListItemAction(listType,item,alliance,1)
                    end
                end
            end
        end)
    end
end

------------------------------------------------------------------------------------------------
---- I have join in a alliance
------------------------------------------------------------------------------------------------
function GameUIAlliance:CreateHaveAlliaceUI()
    self.tab_buttons = self:CreateTabButtons(
        {
            {
                label = _("总览"),
                tag = "overview",
                default = true,
            },
            {
                label = _("成员"),
                tag = "members",
            },
            {
                label = _("信息"),
                tag = "infomation",
            }
        },
        function(tag)
            if self['HaveAlliaceUI_' .. tag .. 'If'] then
                if self.currentContent then
                    self.currentContent:hide()
                end
                self.currentContent = self["HaveAlliaceUI_" .. tag .. "If"](self)
                self.currentContent:show()
            end
        end
    ):pos(window.cx, window.bottom + 34)
end

--总览
function GameUIAlliance:HaveAlliaceUI_overviewIf()
    if self.overviewNode then
        self:RefreshEventListView()
        self:RefreshOverViewUI()
        return self.overviewNode end
    self.ui_overview = {}
    local overviewNode = display.newNode():addTo(self.main_content)

    local events_bg = display.newScale9Sprite("back_ground_540x64.png",0 , 0,cc.size(540,356),cc.rect(15,10,510,44))
        :addTo(overviewNode):align(display.CENTER_BOTTOM, window.width/2,10)

    local eventListView = UIListView.new {
        viewRect = cc.rect(10, 12, 520,340),
        direction = UIScrollView.DIRECTION_VERTICAL,
        async = true,
    }:addTo(events_bg)
    eventListView:setDelegate(handler(self, self.EventListViewsourceDelegate))
    self.eventListView = eventListView
    self:RefreshEventListView()

    local events_title = display.newSprite("alliance_evnets_title_548x50.png")
        :addTo(overviewNode):align(display.CENTER_BOTTOM,window.width/2,events_bg:getPositionY()+events_bg:getContentSize().height)
    UIKit:ttfLabel({
        text = _("事件记录"),
        size = 22,
        color = 0xffedae,
    }):addTo(events_title):align(display.CENTER,events_title:getContentSize().width/2,events_title:getContentSize().height/2)

    local headerBg  = WidgetUIBackGround.new({height=376,isFrame="yes"}):addTo(overviewNode,-1)
        :pos(16,events_title:getPositionY()+events_title:getContentSize().height+10)
    local titileBar = display.newScale9Sprite("title_blue_430x30.png",0,0, cc.size(438,30), cc.rect(10,10,410,10))
        :addTo(headerBg):align(display.TOP_RIGHT, headerBg:getContentSize().width - 10, headerBg:getContentSize().height - 20)
    local language_sprite = display.newSprite(string.format("#%s",UILib.alliance_language_frame[Alliance_Manager:GetMyAlliance():DefaultLanguage()]))
        :align(display.RIGHT_CENTER, 410,15)
        :addTo(titileBar)
        :scale(0.5)
    self.ui_overview.language_sprite = language_sprite
    local flag_box = display.newScale9Sprite("alliance_item_flag_box_126X126.png"):size(134,134)
        :align(display.TOP_LEFT,20, headerBg:getContentSize().height - 20):addTo(headerBg)
    self.flag_box = flag_box
    self.ui_overview.nameLabel = UIKit:ttfLabel({
        text = string.format("[%s] %s",Alliance_Manager:GetMyAlliance():Tag(),Alliance_Manager:GetMyAlliance():Name()),
        size = 24,
        color = 0xffedae,
    }):align(display.LEFT_CENTER,10,17):addTo(titileBar)

    self.ui_overview.my_alliance_flag = self.alliance_ui_helper:CreateFlagWithRhombusTerrain(Alliance_Manager:GetMyAlliance():Terrain(),Alliance_Manager:GetMyAlliance():Flag())
        :addTo(flag_box)
        :pos(70,50):scale(1.5)
    display.newSprite("info_26x26.png"):align(display.LEFT_BOTTOM, 0, 0):addTo(flag_box)
    WidgetPushTransparentButton.new(cc.rect(0,0,134,134))
        :align(display.LEFT_BOTTOM,0,0)
        :addTo(flag_box)
        :onButtonClicked(handler(self, self.OnAllianceSettingButtonClicked))


    local notice_bg = display.newSprite("alliance_notice_box_580x184.png")
        :addTo(headerBg):align(display.CENTER_BOTTOM,headerBg:getContentSize().width/2, 20)

    local noticeView = UIListView.new {
        viewRect =  cc.rect(24,16,534,120),
        direction = UIScrollView.DIRECTION_VERTICAL,
    }:addTo(notice_bg)
    self.ui_overview.noticeView = noticeView

    self:RefreshNoticeView()

    local notice_button = WidgetPushButton.new({normal = "alliance_notice_button_normal_310x36.png",pressed = "alliance_notice_button_highlight_310x36.png"})
        :setButtonLabel('normal',UIKit:ttfLabel({
            text = _("联盟公告"),
            size = 22,
            color = 0xffedae,
        })
        )
        :onButtonClicked(function(event)
            if not Alliance_Manager:GetMyAlliance():GetSelf():CanEditAllianceNotice() then
                UIKit:showMessageDialog(_("提示"), _("您没有此操作权限"), function()end)
                return
            end
            UIKit:newGameUI('GameUIAllianceNoticeOrDescEdit',GameUIAllianceNoticeOrDescEdit.EDIT_TYPE.ALLIANCE_NOTICE)
                :AddToCurrentScene(true)
        end)
        :setButtonLabelOffset(0,4)
        :addTo(notice_bg)
        :align(display.TOP_CENTER,292,181)
    display.newSprite("alliance_notice_icon_26x26.png"):addTo(notice_button):pos(70,-18)


    local line_2 = display.newSprite("dividing_line.png")
        :addTo(headerBg)
        :align(display.LEFT_BOTTOM,titileBar:getPositionX() - titileBar:getContentSize().width + 10,flag_box:getPositionY() - flag_box:getContentSize().height+2)
    local languageLabel = UIKit:ttfLabel({
        text = _("在线人数"),
        size = 20,
        color = 0x615b44,
    }):addTo(headerBg):align(display.LEFT_BOTTOM,line_2:getPositionX()+5,line_2:getPositionY() + 2)
    local m_count,m_online,m_maxCount = Alliance_Manager:GetMyAlliance():GetMembersCountInfo()
    local languageLabelVal =  UIKit:ttfLabel({
        text = m_online,
        size = 20,
        color= 0x403c2f,
        align= cc.TEXT_ALIGNMENT_RIGHT
    }):addTo(headerBg):align(display.RIGHT_BOTTOM,line_2:getPositionX()+line_2:getContentSize().width - 5,languageLabel:getPositionY())
    self.ui_overview.online_count_label = languageLabelVal


    local line_1 = display.newSprite("dividing_line.png")
        :addTo(headerBg)
        :align(display.LEFT_BOTTOM,titileBar:getPositionX() - titileBar:getContentSize().width + 10,line_2:getPositionY()+30)

    local tagLabel = UIKit:ttfLabel({
        text = _("联盟人数"),
        size = 20,
        color = 0x615b44,
    }):addTo(headerBg)
        :align(display.LEFT_BOTTOM,languageLabel:getPositionX(),line_1:getPositionY() + 2)

    local tagLabelVal = UIKit:ttfLabel({
        text = string.format("%s/%s",m_count,m_maxCount),
        size = 20,
        color = 0x403c2f,
    })
        :addTo(headerBg)
        :align(display.RIGHT_BOTTOM,languageLabelVal:getPositionX(),tagLabel:getPositionY())
    self.ui_overview.memberCountLabel = tagLabelVal

    local line_0 =  display.newSprite("dividing_line.png")
        :addTo(headerBg)
        :align(display.LEFT_BOTTOM,line_1:getPositionX(),line_1:getPositionY()+30)
    local languageLabel = UIKit:ttfLabel({
        text = _("联盟战斗力"),
        size = 20,
        color = 0x615b44,
    }):addTo(headerBg)
        :align(display.LEFT_BOTTOM,tagLabel:getPositionX(),line_0:getPositionY() + 2)
    local languageLabelVal = UIKit:ttfLabel({
        text = string.formatnumberthousands(Alliance_Manager:GetMyAlliance():Power()),
        size = 20,
        color = 0x403c2f,
    })
        :addTo(headerBg)
        :align(display.RIGHT_BOTTOM,languageLabelVal:getPositionX(),languageLabel:getPositionY())
    self.ui_overview.powerLabel = languageLabelVal
    self.overviewNode = overviewNode
    return self.overviewNode
end

function GameUIAlliance:RefreshNoticeView()
    local notice_str = Alliance_Manager:GetMyAlliance():Notice() 
    if notice_str == json.null or string.len(notice_str) == 0 then
        notice_str = _("未设置联盟公告")
    end

    local textLabel = UIKit:ttfLabel({
        dimensions = cc.size(530, 0),
        text = notice_str,
        size = 20,
        color = 0x615b44,
        align=cc.TEXT_ALIGNMENT_CENTER
    })
    local content = display.newNode()
    content:size(534,textLabel:getContentSize().height)
    textLabel:addTo(content):align(display.CENTER, 267, textLabel:getContentSize().height/2)
    self.ui_overview.noticeView:removeAllItems()
    local textItem = self.ui_overview.noticeView:newItem()
    textItem:addContent(content)
    textItem:setItemSize(537,content:getContentSize().height)
    self.ui_overview.noticeView:addItem(textItem)
    self.ui_overview.noticeView:reload()
end

function GameUIAlliance:GetEventItemByIndexAndEvent()
    local content = display.newNode():size(520,84)
    local bg0 = display.newScale9Sprite("back_ground_548x40_1.png",0,0,cc.size(520,84),cc.rect(10,10,528,20)):addTo(content):align(display.LEFT_BOTTOM, 0, 0)
    local bg1 = display.newScale9Sprite("back_ground_548x40_2.png",0,0,cc.size(520,84),cc.rect(10,10,528,20)):addTo(content):align(display.LEFT_BOTTOM, 0, 0)
    local normal = display.newScale9Sprite("title_blue_430x30.png",0,0,cc.size(222,30),cc.rect(10,10,410,10)):addTo(content):align(display.LEFT_TOP, 0,70)
    local important = display.newSprite("alliance_event_type_green_222x30.png"):addTo(content):align(display.LEFT_TOP, 0,70)
    local war = display.newSprite("title_red_166x30.png",0,0,cc.size(222,30),cc.rect(10,10,146,10)):addTo(content):align(display.LEFT_TOP, 0,70)
    local title_label = UIKit:ttfLabel({
        text = "title",
        size = 20,
        color = 0xffedae
    }):addTo(content):align(display.LEFT_CENTER,10,55)
    local time_label = UIKit:ttfLabel({
        text = "time",
        size = 18,
        color = 0x615b44
    }):addTo(content):align(display.LEFT_BOTTOM,10, 5)
    local content_label = UIKit:ttfLabel({
        text = "content",
        size = 20,
        color = 0x403c2f,
        dimensions = cc.size(300, 60)
    }):align(display.LEFT_CENTER,0,0)
    content_label:pos(normal:getPositionX()+normal:getContentSize().width + 10,42):addTo(content)
    content.bg0 = bg0
    content.bg1 = bg1
    content.normal = normal
    content.important = important
    content.war = war
    content.title_label = title_label
    content.time_label = time_label
    content.content_label = content_label
    return content
end

function GameUIAlliance:RefreshEventsListItem(content,data,idx)
    content[string.format("bg%d",idx % 2)]:hide()
    for __,v in ipairs({"normal","important","war"}) do
        if v == data.category then
            content[v]:show()
        else
            content[v]:hide()
        end
    end
    content.title_label:setString(data.key or "")
    content.time_label:setString(GameUtils:formatTimeStyle2(data.time/1000))
    content.content_label:setString( self:GetEventContent(data))
end

function GameUIAlliance:GetAllianceDiyTitle(title)
    local titles = Alliance_Manager:GetMyAlliance():GetTitles()
    return titles[title] or Localize.alliance_title[title]
end

function GameUIAlliance:GetEventContent(event)
    local event_type = event.type
    local params_,params = event.params,{}
    for _,v in ipairs(params_) do
        if 'promotionDown' == event_type or 'promotionUp' == event_type then
            if Localize.alliance_title[v] then
                v = self:GetAllianceDiyTitle(v)
            end
        elseif 'language' == event_type then
            if Localize.alliance_language[v] then
                v = Localize.alliance_language[v]
            end
        elseif 'terrain' == event_type then
            if Localize.terrain[v] then
                v = Localize.terrain[v] 
            end
        elseif 'upgrade' == event_type then
            if Localize.building_name[v] then
                v = Localize.building_name[v]
            end
        end
        table.insert(params, v)
    end
    return string.format(Localize.alliance_events[event_type],unpack(params))
end

function GameUIAlliance:RefreshFlag()
    if not self.flag_box then return end
    if self.ui_overview and self.tab_buttons:GetSelectedButtonTag() == 'overview'  then
        local alliance_data = Alliance_Manager:GetMyAlliance()
        if self.ui_overview.my_alliance_flag then
            local x,y = self.ui_overview.my_alliance_flag:getPosition()
            self.ui_overview.my_alliance_flag:removeFromParent()
            self.ui_overview.my_alliance_flag = self.alliance_ui_helper:CreateFlagWithRhombusTerrain(Alliance_Manager:GetMyAlliance():Terrain(),Alliance_Manager:GetMyAlliance():Flag())
                :addTo(self.flag_box)
                :pos(x,y)
                :scale(1.5)
        end
    end
end

function GameUIAlliance:RefreshOverViewUI()
    if self.ui_overview and self.tab_buttons:GetSelectedButtonTag() == 'overview'  then
        local alliance_data = Alliance_Manager:GetMyAlliance()
        local m_count,m_online,m_maxCount = alliance_data:GetMembersCountInfo()
        self.ui_overview.nameLabel:setString(string.format("[%s] %s",alliance_data:Tag(),alliance_data:Name()))
        self.ui_overview.memberCountLabel:setString(string.format("%s/%s",m_count,m_maxCount))
        self.ui_overview.online_count_label:setString(m_online)
        self.ui_overview.powerLabel:setString(string.formatnumberthousands(alliance_data:Power()))
        self.ui_overview.language_sprite:setSpriteFrame(UILib.alliance_language_frame[alliance_data:DefaultLanguage()])
        self:RefreshNoticeView()
    end
end

function GameUIAlliance:RefreshEventListView()
    self.event_list_data_source = clone(Alliance_Manager:GetMyAlliance():Events())
    table.sort( self.event_list_data_source, function(a,b)
        return a.time > b.time
    end)
    self.eventListView:reload()
end

function GameUIAlliance:EventListViewsourceDelegate(listView, tag, idx)
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #self.event_list_data_source
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        local data = self.event_list_data_source[idx]
        item = self.eventListView:dequeueItem()
        if not item then
            item = self.eventListView:newItem()
            content = self:GetEventItemByIndexAndEvent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        self:RefreshEventsListItem(content,data,idx)
        content:size(520,84)
        item:setItemSize(520,84)
        return item
    else
    end
end
function GameUIAlliance:OnAllianceSettingButtonClicked(event)
    local my_alliance = Alliance_Manager:GetMyAlliance()
    local my_alliance_status = my_alliance:Status()
    if (my_alliance_status == 'prepare' or my_alliance_status == 'fight') then
        UIKit:showMessageDialog(_("提示"), _("联盟对战期不能修改联盟信息"), function()end)
        return
    end

    if not my_alliance:GetSelf():CanEditAlliance() then
        UIKit:showMessageDialog(_("提示"), _("您没有此操作权限"), function()end)
        return
    end
    UIKit:newGameUI('GameUIAllianceBasicSetting',true):AddToCurrentScene(true)
end

--成员
--------------
function GameUIAlliance:MembersListonTouch(event)
    if event.name == 'SCROLLVIEW_EVENT_BOUNCE_TOP' and not self.need_refresh then
        if math.ceil(event.disY) >= 70 then
            self.need_refresh = true
        end
        self.refresh_label:hide()
    elseif "scrollEnd" == event.name and self.need_refresh then
        self.refresh_label:hide()
        self.memberListView:removeAllItems()
        UIKit:WaitForNet(0)
        self:RefreshMemberList()
        self:performWithDelay(function()
            UIKit:NoWaitForNet()
            self.need_refresh = false
        end, 0.3)
    elseif "top_distance_changed" == event.name then
        if math.ceil(event.disY) > 40 then
            self.refresh_label:show()
        else
            self.refresh_label:hide()
        end
    elseif "clicked" == event.name then
        local item = event.item
        if not item then return end
        local list_data = self.list_dataSource[item.idx_]
        local data = list_data.data
        if list_data.data_type == 2 and list_data.data ~= '__empty' and User:Id() ~= data.id then
            UIKit:newGameUI("GameUIAllianceMemberInfo",true,data.id,function()
                if self.tab_buttons:GetSelectedButtonTag() == 'members' then
                    self:RefreshMemberList()
                end
            end):AddToCurrentScene(true)
        elseif list_data.data_type == 1 then
            self:OnAllianceTitleClicked(data)
        end
    end
end
function GameUIAlliance:HaveAlliaceUI_membersIf()
    if not self.member_list_bg then
        self.member_list_bg = display.newNode():size(568,784):addTo(self.main_content)
            :align(display.CENTER_TOP, window.width/2, window.betweenHeaderAndTab)
        local list,list_node = UIKit:commonListView({
            viewRect = cc.rect(0, 0,560,618),
            direction = UIScrollView.DIRECTION_VERTICAL,
            async = true,
            trackTop = true,
        })
        list:onTouch(handler(self, self.MembersListonTouch))
        list:setDelegate(handler(self, self.MembersListsourceDelegate))
        self.refresh_label = UIKit:ttfLabel({
            text = _("下拉刷新"),
            size = 18,
            color= 0x615b44
        }):align(display.CENTER, 284, 590):addTo(self.member_list_bg):hide()
        self.memberListView = list
        list_node:addTo(self.member_list_bg):pos(5,10)
        local box = display.newScale9Sprite("alliance_item_flag_box_126X126.png")
            :size(126,134)
            :addTo(self.member_list_bg)
            :align(display.LEFT_TOP,5,784)
        self.member_list_bg.player_icon_box = box
        self.member_list_bg.view_archon_info_button_really = WidgetPushTransparentButton.new(cc.rect(0,0,560,100)):addTo(self.member_list_bg):align(display.LEFT_BOTTOM,5,650):onButtonClicked(function()
            local archon = Alliance_Manager:GetMyAlliance():GetAllianceArchon()
            self:OnPlayerDetailButtonClicked(archon:Id())
        end)
        local title_bar =  display.newScale9Sprite("title_blue_430x30.png",0,0, cc.size(428,30), cc.rect(10,10,410,10))
            :addTo(self.member_list_bg)
            :align(display.LEFT_TOP, 136, 782)
        local title_label = UIKit:ttfLabel({
            text = "",
            size = 22,
            color= 0xffedae,
            align = cc.TEXT_ALIGNMENT_LEFT,
        }):addTo(title_bar):align(display.LEFT_CENTER,5, 15)
        self.member_list_bg.title_label = title_label

        local button = display.newSprite("info_16x33.png"):addTo(title_bar):align(display.RIGHT_CENTER, 400, 15):scale(0.7)
        WidgetPushTransparentButton.new(cc.rect(0,0,428,30)):addTo(title_bar):align(display.LEFT_BOTTOM,0,0):onButtonClicked(function()
            self:OnAllianceTitleClicked("archon")
        end)
        local line_2 = display.newScale9Sprite("dividing_line.png",0,0,cc.size(428,2),cc.rect(10,2,382,2))
            :addTo(self.member_list_bg)
            :align(display.LEFT_BOTTOM,title_bar:getPositionX(),650)

        local powerIcon = display.newSprite("dragon_strength_27x31.png")
            :align(display.LEFT_BOTTOM,line_2:getPositionX() + 5,line_2:getPositionY()+5)
            :addTo(self.member_list_bg)
        local powerLabel = UIKit:ttfLabel({
            text = "",
            size = 22,
            color = 0x403c2f,
            align = cc.TEXT_ALIGNMENT_LEFT,
        }):addTo(self.member_list_bg):align(display.LEFT_BOTTOM,line_2:getPositionX()+40,powerIcon:getPositionY())
        self.member_list_bg.powerLabel = powerLabel
        local loginLabel = UIKit:ttfLabel({
            text = "",
            size = 22,
            color = 0x403c2f,
            align = cc.TEXT_ALIGNMENT_RIGHT,
        }):addTo(self.member_list_bg):align(display.BOTTOM_RIGHT,554,line_2:getPositionY() + 5)
        self.member_list_bg.loginLabel = loginLabel
        local line_1 = display.newScale9Sprite("dividing_line.png",0,0,cc.size(428,2),cc.rect(10,2,382,2))
            :addTo(self.member_list_bg)
            :align(display.LEFT_BOTTOM,title_bar:getPositionX(),688)

        local display_title,imageName = self:GetAllianceTitleAndLevelPng("archon")
        local title_icon = display.newSprite(imageName)
            :align(display.LEFT_BOTTOM, line_1:getPositionX(), line_1:getPositionY() + 5)
            :addTo(self.member_list_bg)
        self.member_list_bg.archon_title_label = UIKit:ttfLabel({
            text = display_title,
            size = 22,
            color= 0x403c2f,
            align = cc.TEXT_ALIGNMENT_LEFT,
        }):align(display.LEFT_BOTTOM, line_2:getPositionX()+40,title_icon:getPositionY()):addTo(self.member_list_bg)

        self.member_list_bg.view_archon_info_button = WidgetPushButton.new({normal = "alliacne_search_29x33.png"})
            :align(display.RIGHT_BOTTOM,554,line_1:getPositionY()+4)
            :addTo(self.member_list_bg)
            :onButtonClicked(function()

                end)
    end
    self:RefreshMemberList()
    return self.member_list_bg
end

function GameUIAlliance:RefreshMemberListIf()
    if self.tab_buttons:GetSelectedButtonTag() == 'members' then
        self:RefreshMemberList()
    end
end


function GameUIAlliance:GetMemberItemContent()
    local node = display.newNode():size(560,78)
    local content_title = display.newSprite("title_blue_554x34.png"):align(display.LEFT_BOTTOM, 0, 0):addTo(node)
    local button = display.newSprite("info_16x33.png"):align(display.RIGHT_CENTER,545,17):addTo(content_title):scale(0.7)
    node.content_title = content_title
    local title_label= UIKit:ttfLabel({
        text = "title",
        size = 22,
        color = 0xffedae,
    }):addTo(content_title):align(display.LEFT_CENTER,268, 17)
    content_title.title_label = title_label
    for key,v in pairs(UILib.alliance_title_icon) do
        local num_sp = display.newSprite(v):addTo(content_title):align(display.RIGHT_CENTER,258,17)
        content_title[key] = num_sp
    end
    local content_memeber = WidgetUIBackGround.new({width = 558,height = 66},WidgetUIBackGround.STYLE_TYPE.STYLE_4)
        :align(display.LEFT_BOTTOM,0, 6):addTo(node)
    node.content_memeber = content_memeber

    local empty_label = UIKit:ttfLabel({
        text = _("<空>"),
        size = 22,
        color= 0x615b44
    }):align(display.CENTER, 279, 33):addTo(content_memeber)
    content_memeber.empty_label = empty_label

    local player_icon = self:GetPlayerIconSprite():scale(0.5):align(display.LEFT_CENTER,15, 33):addTo(content_memeber)
    content_memeber.player_icon = player_icon

    local nameLabel = UIKit:ttfLabel({
        text = "",
        size = 20,
        color = 0x403c2f,
        dimensions = cc.size(175,30),
        ellipsis = true
    }):addTo(content_memeber):align(display.LEFT_CENTER,player_icon:getPositionX()+player_icon:getCascadeBoundingBox().width + 5,33)

    content_memeber.nameLabel = nameLabel
    local lvLabel =  UIKit:ttfLabel({
        text = "",
        size = 20,
        color = 0x615b44,
    }):addTo(content_memeber):align(display.LEFT_CENTER,nameLabel:getPositionX()+ 180, 33)
    content_memeber.lvLabel = lvLabel
    local powerIcon = display.newSprite("dragon_strength_27x31.png"):align(display.LEFT_CENTER,nameLabel:getPositionX()+255,33)
        :addTo(content_memeber)
    content_memeber.powerIcon = powerIcon
    local powerLabel = UIKit:ttfLabel({
        text = "12323",
        size = 22,
        color = 0x403c2f,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):addTo(content_memeber):align(display.LEFT_CENTER,powerIcon:getPositionX()+35,33)
    content_memeber.powerLabel = powerLabel

    local info_sprite = display.newSprite("alliacne_search_29x33.png"):align(display.RIGHT_CENTER,548,33):addTo(content_memeber)
    content_memeber.info_sprite = info_sprite
    return node
end


function GameUIAlliance:FillDataToAllianceItem(list_data,content,item)
    local real_content
    local data = list_data.data
    if list_data.data_type == 1 then -- title
        content.content_memeber:hide()
        content.content_title:show()
        real_content = content.content_title
        local title,__ = self:GetAllianceTitleAndLevelPng(data)
        real_content.title_label:setString(title)
        for k,__ in pairs(UILib.alliance_title_icon) do
            if k == data then
                real_content[k]:show()
            else
                real_content[k]:hide()
            end
        end
        content:size(560,46)
        item:setItemSize(560,46)
    else
        content.content_memeber:show()
        content.content_title:hide()
        real_content = content.content_memeber
        if data == '__empty' then
            real_content.empty_label:show()
            real_content.player_icon:hide()
            real_content.nameLabel:hide()
            real_content.lvLabel:hide()
            real_content.powerIcon:hide()
            real_content.powerLabel:hide()
            real_content.info_sprite:hide()
        else
            real_content.empty_label:hide()
            real_content.player_icon:show()
            real_content.nameLabel:show()
            real_content.lvLabel:show()
            real_content.powerIcon:show()
            real_content.powerLabel:show()
            if data:Id() == User:Id() then
                real_content.info_sprite:hide()
            else
                real_content.info_sprite:show()
            end

            real_content.nameLabel:setString(data.name)
            real_content.lvLabel:setString(string.format("LV %d",User:GetPlayerLevelByExp(data.levelExp)))
            real_content.powerLabel:setString(string.formatnumberthousands(data.power))

            local isOnline = (type(data.online) == 'boolean' and data.online) and true or false
            real_content.player_icon.icon:setTexture(UIKit:GetPlayerIconImage(data.icon))
            if isOnline then
                real_content.player_icon.icon:clearFilter()
                real_content.player_icon:clearFilter()
            else
                if not real_content.player_icon.icon:getFilter() then
                    real_content.player_icon.icon:setFilter(filter.newFilter("CUSTOM", json.encode({frag = "shaders/ps_discoloration.fs",shaderName = "ps_discoloration"})))
                    real_content.player_icon:setFilter(filter.newFilter("CUSTOM", json.encode({frag = "shaders/ps_discoloration.fs",shaderName = "ps_discoloration"})))
                end
            end
        end
        content:size(560,78)
        item:setItemSize(560,78)
    end
end

function GameUIAlliance:MembersListsourceDelegate(listView, tag, idx)
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #self.list_dataSource
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        local data = self.list_dataSource[idx]
        item = self.memberListView:dequeueItem()
        if not item then
            item = self.memberListView:newItem()
            content = self:GetMemberItemContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        self:FillDataToAllianceItem(data,content,item)
        return item
    else
    end
end
function GameUIAlliance:RefreshMembersListDataSource()
    self.data_members = clone(Alliance_Manager:GetMyAlliance():GetAllMembers())
    table.sort(self.data_members, function(a,b)
        local isOnline_a = (type(a.online) == 'boolean' and a.online) and true or false
        local isOnline_b = (type(b.online) == 'boolean' and b.online) and true or false
        if isOnline_a == isOnline_b then
            return a.power > b.power
        else
            return isOnline_a
        end
    end)
    local data = self:filterMemberList("general")
    local next_data = self:filterMemberList("quartermaster")
    table.insertto(data,next_data)
    next_data = self:filterMemberList("supervisor")
    table.insertto(data,next_data)
    next_data = self:filterMemberList("elite")
    table.insertto(data,next_data)
    next_data = self:filterMemberList("member")
    table.insertto(data,next_data)
    self.list_dataSource = data
end


function GameUIAlliance:filterMemberList(title)
    local filter_data = LuaUtils:table_filter(self.data_members,function(k,v)
        return v:Title() == title
    end)

    local result = {{data_type = 1 , data = title}}
    if LuaUtils:table_size(filter_data) == 0 then
        table.insert(result,{data_type = 2 , data = "__empty"})
    else
        --player
        table.foreach(filter_data,function(k,v)
            table.insert(result,{data_type = 2 , data = v})
        end)
    end
    return result
end


function GameUIAlliance:GetPlayerIconSprite()
    local bg = display.newSprite("dragon_bg_114x114.png", nil, nil, {class=cc.FilteredSpriteWithOne})
    local icon = display.newSprite(UIKit:GetPlayerIconImage(1), nil, nil, {class=cc.FilteredSpriteWithOne}):addTo(bg):align(display.CENTER,56,65)
    bg.icon = icon
    return bg
end

function GameUIAlliance:RefreshMemberList()
    if not self.memberListView then return end
    if self.member_list_bg.player_icon then
        self.member_list_bg.player_icon:removeFromParent()
    end
    local archon = Alliance_Manager:GetMyAlliance():GetAllianceArchon()
    local isOnline = (type(archon.online) == 'boolean' and archon.online) and true or false
    self.member_list_bg.player_icon = UIKit:GetPlayerCommonIcon(archon.icon,isOnline)
        :addTo(self.member_list_bg.player_icon_box):pos(63,67)
    self.member_list_bg.title_label:setString(string.format("%s Lv %s",archon:Name(),User:GetPlayerLevelByExp(archon.levelExp)))
    self.member_list_bg.powerLabel:setString(string.formatnumberthousands(archon.power))
    if archon.online then
        self.member_list_bg.loginLabel:setString(_("在线"))
    else
        self.member_list_bg.loginLabel:setString(_("最后登录:") .. NetService:formatTimeAsTimeAgoStyleByServerTime(archon.lastLoginTime))
    end
    local display_title,___ = self:GetAllianceTitleAndLevelPng("archon")
    self.member_list_bg.archon_title_label:setString(display_title)
    self.member_list_bg.view_archon_info_button:setVisible(User:Id() ~= archon:Id())
    self.member_list_bg.view_archon_info_button_really:setButtonEnabled(User:Id() ~= archon:Id())
    self:RefreshMembersListDataSource()
    self.memberListView:reload()
end

function GameUIAlliance:GetAllianceTitleAndLevelPng(title)
    local alliance = Alliance_Manager:GetMyAlliance()
    return alliance:GetTitles()[title],UILib.alliance_title_icon[title]
end

function GameUIAlliance:OnAllianceTitleClicked( title )
    UIKit:newGameUI('GameUIAllianceTitle',title):AddToCurrentScene(true)
end

function GameUIAlliance:OnPlayerDetailButtonClicked(memberId)
    UIKit:newGameUI('GameUIAllianceMemberInfo',true,memberId,function()
        if self.tab_buttons:GetSelectedButtonTag() == 'members' then
            self:RefreshMemberList()
        end
    end):AddToCurrentScene(true)
end
-- 信息
function GameUIAlliance:HaveAlliaceUI_infomationIf()
    if self.informationNode then
        self:RefreshDescView()
        return self.informationNode
    end
    local informationNode = WidgetUIBackGround.new({height=384,isFrame = "yes"}):addTo(self.main_content):pos(16,window.betweenHeaderAndTab - 394)
    self.informationNode = informationNode
    local notice_bg = display.newSprite("alliance_notice_box_580x184.png")
        :align(display.CENTER_TOP,304,395)
        :addTo(informationNode)



    local descView = UIListView.new {
        viewRect =  cc.rect(24,16,534,120),
        direction = UIScrollView.DIRECTION_VERTICAL,
    }:addTo(notice_bg)
    self.descListView = descView

    local notice_button = WidgetPushButton.new({normal = "alliance_notice_button_normal_310x36.png",pressed = "alliance_notice_button_highlight_310x36.png"})
        :setButtonLabel('normal',UIKit:ttfLabel({
            text = _("联盟描述"),
            size = 22,
            color = 0xffedae,
        })
        )
        :onButtonClicked(function(event)
            if not Alliance_Manager:GetMyAlliance():GetSelf():CanEditAllianceDesc() then
                UIKit:showMessageDialog(_("提示"), _("您没有此操作权限"), function()end)
                return
            end
            UIKit:newGameUI('GameUIAllianceNoticeOrDescEdit',GameUIAllianceNoticeOrDescEdit.EDIT_TYPE.ALLIANCE_DESC)
                :AddToCurrentScene(true)
        end)
        :addTo(notice_bg)
        :align(display.TOP_CENTER,292,181)
    display.newSprite("alliance_notice_icon_26x26.png"):addTo(notice_button):pos(70,-18)
    local checkbox_image = {
        off = "checkbox_unselected.png",
        off_pressed = "checkbox_unselected.png",
        off_disabled = "checkbox_unselected.png",
        on = "checkbox_selectd.png",
        on_pressed = "checkbox_selectd.png",
        on_disabled = "checkbox_selectd.png",

    }
    self.joinTypeButton = UICanCanelCheckBoxButtonGroup.new(display.TOP_TO_BOTTOM)
        :addButton(UICheckBoxButton.new(checkbox_image)
            :setButtonLabel(UIKit:ttfLabel({text = _("允许玩家立即加入联盟"),size = 20,color = 0x615b44}))
            :setButtonLabelOffset(40, 0)
            :align(display.LEFT_CENTER)
            :setButtonSelected(Alliance_Manager:GetMyAlliance():JoinType() == "all"))
        :addButton(UICheckBoxButton.new(checkbox_image)
            :setButtonLabel(UIKit:ttfLabel({text = _("玩家仅能通过申请或者邀请的方式加入"),size = 20,color = 0x615b44}))
            :setButtonLabelOffset(40, 0)
            :align(display.LEFT_CENTER)
            :setButtonSelected(Alliance_Manager:GetMyAlliance():JoinType() ~= "all"))
        :onButtonSelectChanged(handler(self, self.OnAllianceJoinTypeButtonClicked))
        :addTo(informationNode)
        :setButtonsLayoutMargin(26,0,0,0)
        :setLayoutSize(557, 54)
        :pos(notice_bg:getPositionX() - notice_bg:getContentSize().width/2,notice_bg:getPositionY() - notice_bg:getContentSize().height/2 - 118)
        :setCheckButtonStateChangeFunction(function(group,currentSelectedIndex,oldIndex)
            if  not Alliance_Manager:GetMyAlliance():GetSelf():CanEditAllianceJoinType() then
                UIKit:showMessageDialog(_("提示"), _("您没有此操作权限"), function()end)
                return false
            end
            if currentSelectedIndex ~= oldIndex then
                local title = _("允许玩家立即加入联盟")
                if currentSelectedIndex ~= 1 then
                    title = _("玩家仅能通过申请或者邀请的方式加入")
                end
                UIKit:showMessageDialog(_("提示"),
                    _("你将设置联盟加入方式为") .. title,
                    function()
                        self.joinTypeButton:sureSelectedButtonIndex(currentSelectedIndex)
                    end,
                    function()end)
            end
            return false
        end)

    local x,y = 37,-125
    local button_imags = {"alliance_sign_out_62x56.png","alliance_invitation_62x56.png","alliance_apply_62x56.png","alliance_group_mail_62x56.png"}
    local button_texts = {_("退出联盟"),_("邀请加入"),_("审批申请"),_("群邮件")}
    for i=1,4 do
        local button = cc.ui.UIPushButton.new({normal = 'alliance_button_n_132x98.png',pressed = "alliance_button_h_132x98.png"}):align(display.LEFT_BOTTOM,132*(i-1) + x, y)
            :addTo(informationNode)
            :onButtonClicked(function(event)
                self:OnInfoButtonClicked(i)
            end)
            :setButtonLabel("normal",UIKit:ttfLabel({text = button_texts[i],size = 18,color = 0xffedae}))
            :setButtonLabelOffset(0, -30)
        display.newSprite(button_imags[i]):addTo(button):pos(66,59)
    end
    self:RefreshDescView()
    return self.informationNode
end

function GameUIAlliance:IsOperateButtonEnable(index)
    local member = Alliance_Manager:GetMyAlliance():GetSelf()
    local enable = true
    if index == 2 then
        enable = member:CanInvatePlayer()
    elseif index == 3 then
        enable = member:CanHandleAllianceApply()
    elseif index == 4 then
        enable = member:CanSendAllianceMail()
    end
    return enable
end

function GameUIAlliance:SelectJoinType()
    if Alliance_Manager:GetMyAlliance():JoinType() == "all" then
        self.joinTypeButton:sureSelectedButtonIndex(1,true)
    else
        self.joinTypeButton:sureSelectedButtonIndex(2,true)
    end
end

function GameUIAlliance:RefreshDescView()
    local describe_str = Alliance_Manager:GetMyAlliance():Describe()
    if describe_str == json.null or string.len(describe_str) == 0 then
        describe_str = _("未设置联盟描述")
    end
    local textLabel = UIKit:ttfLabel({
        dimensions = cc.size(530, 0),
        text = describe_str,
        size = 20,
        color = 0x615b44,
        align=cc.TEXT_ALIGNMENT_CENTER
    })
    local content = display.newNode()
    content:size(534,textLabel:getContentSize().height)
    textLabel:addTo(content):align(display.CENTER, 267, textLabel:getContentSize().height/2)
    self.descListView:removeAllItems()
    local textItem = self.descListView:newItem()
    textItem:addContent(content)
    textItem:setItemSize(534,content:getContentSize().height)
    self.descListView:addItem(textItem)
    self.descListView:reload()
end

function GameUIAlliance:OnAllianceJoinTypeButtonClicked(event)
    local join_type = "all"
    if event.selected ~= 1 then
        join_type = "audit"
    end
    NetManager:getEditAllianceJoinTypePromise(join_type)
end


function GameUIAlliance:RefreshInfomationView()
    self:RefreshDescView()
    self:SelectJoinType()
end

function GameUIAlliance:OnInfoButtonClicked(tag)
    if not self:IsOperateButtonEnable(tag) then
        UIKit:showMessageDialog(_("提示"), _("您没有此操作权限"), function()end)
        return
    end
    if tag == 1 then
        if Alliance_Manager:GetMyAlliance():GetSelf():IsArchon() and Alliance_Manager:GetMyAlliance():GetMembersCount() > 1 then
            UIKit:showMessageDialog(_("提示"),_("仅当联盟成员为空时,盟主才能退出联盟"), function()end)
            return
        end
        UIKit:showMessageDialog(_("退出联盟"),
            _("您必须在没有部队在外行军的情况下，才可以退出联盟。退出联盟会损失当前未打开的联盟礼物。"),
            function()
                NetManager:getQuitAlliancePromise():done()
            end)
    elseif tag == 2 then
        self:CreateInvateUI()
    elseif tag == 3 then
        UIKit:newGameUI("GameAllianceApproval"):AddToCurrentScene(true)
    elseif tag == 4 then -- 邮件
        local mail = GameUIWriteMail.new(GameUIWriteMail.SEND_TYPE.ALLIANCE_MAIL)
        mail:SetTitle(_("联盟邮件"))
        mail:SetAddressee(_("发送联盟所有成员"))
        mail:addTo(self)
    end
end

function GameUIAlliance:CreateInvateUI()
    local layer = UIKit:shadowLayer()
    local bg = WidgetUIBackGround.new({height=200}):addTo(layer):pos(window.left+20,window.cy-20)
    local title_bar = display.newSprite("title_blue_600x56.png")
        :addTo(bg)
        :align(display.CENTER_BOTTOM, 304,185)

    local closeButton = UIKit:closeButton()
        :addTo(title_bar)
        :align(display.BOTTOM_RIGHT,title_bar:getContentSize().width, 0)
        :onButtonClicked(function ()
            layer:removeFromParent(true)
        end)
    UIKit:ttfLabel({
        text = _("邀请加入联盟"),
        size = 22,
        color = 0xffedae
    }):addTo(title_bar):align(display.CENTER, 300, 28)

    UIKit:ttfLabel({
        text = _("邀请玩家加入"),
        size = 20,
        color = 0x615b44
    }):addTo(bg):align(display.LEFT_TOP, 30,150)

    local editbox = cc.ui.UIInput.new({
        UIInputType = 1,
        image = "input_box.png",
        size = cc.size(422,40),
    })
    editbox:setFont(UIKit:getEditBoxFont(),18)
    editbox:setFontColor(cc.c3b(0,0,0))
    editbox:setMaxLength(20)
    editbox:setPlaceHolder(_("输入邀请的玩家ID"))
    editbox:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    editbox:align(display.RIGHT_TOP,588,158):addTo(bg)
    WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
        :setButtonLabel(
            UIKit:commonButtonLable({
                text = _("发送"),
                color = 0xffedae
            })
        )
        :onButtonClicked(function(event)
            local playerID = string.trim(editbox:getText())
            if string.utf8len(playerID) == 0 or string.utf8len(playerID) > 20 then
                UIKit:showMessageDialog(_("提示"), _("非法的玩家ID"), function()end)
                return
            end
            NetManager:getInviteToJoinAlliancePromise(playerID):done(function(result)
                layer:removeFromParent(true)
                UIKit:showMessageDialog(_("提示"), _("邀请发送成功"), function()end)
            end)
        end)
        :addTo(bg):align(display.RIGHT_BOTTOM,editbox:getPositionX(), 30)

    layer:addTo(self)
end


return GameUIAlliance



