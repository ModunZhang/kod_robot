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
GameUIAlliance.COMMON_LIST_ITEM_TYPE = Enum("JOIN","INVATE","APPLY")

--
--------------------------------------------------------------------------------
function GameUIAlliance:ctor()
    GameUIAlliance.super.ctor(self,City,_("联盟"))
    self.alliance_ui_helper = WidgetAllianceHelper.new()
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
        if not Alliance_Manager.open_alliance then
            self:CreateAllianceTips()
        end
    else
        self:CreateHaveAlliaceUI()
    end
end

function GameUIAlliance:CreateBetweenBgAndTitle()
    self.main_content = display.newNode():addTo(self:GetView()):pos(window.left,window.bottom_top)
    self.main_content:setContentSize(cc.size(window.width,window.betweenHeaderAndTab))
end

-- function GameUIAlliance:OnMoveInStage()
--     GameUIAlliance.super.OnMoveInStage(self)
--     self:AddListenerOfMyAlliance()
-- end

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

            },
            {
                label = _("加入"),
                tag = "join",
                default = true,
            },
            {
                label = _("邀请"),
                tag = "invite",
            },
            {
                label = _("申请"),
                tag = "apply",
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

function GameUIAlliance:CreateAllianceTips()
    Alliance_Manager.open_alliance = true
    local shadowLayer = display.newColorLayer(UIKit:hex2c4b(0x7a000000))
        :addTo(self:GetView())
    local backgroundImage = WidgetUIBackGround.new({height=542}):addTo(shadowLayer):pos(window.left+20,window.top - 700)
    local titleBar = display.newSprite("title_blue_600x56.png")
        :pos(backgroundImage:getContentSize().width/2, backgroundImage:getContentSize().height+8)
        :addTo(backgroundImage)
    local mainTitleLabel = UIKit:ttfLabel({
        text = _("创建联盟"),
        size = 24,
        color= 0xffedae
    })
        :addTo(titleBar)
        :align(display.CENTER,titleBar:getContentSize().width/2,titleBar:getContentSize().height/2)
    UIKit:closeButton()
        :align(display.BOTTOM_RIGHT,titleBar:getContentSize().width,0)
        :addTo(titleBar)
        :onButtonClicked(function(event)
            shadowLayer:removeFromParent()
        end)
    local title_bg = display.newSprite("green_title_639x39.png")
        :addTo(backgroundImage)
        :align(display.LEFT_TOP, -15, titleBar:getPositionY()-titleBar:getContentSize().height/2-5)
    UIKit:ttfLabel({
        text = _("联盟的强大功能！"),
        size = 24,
        color= 0xffeca5,
        shadow=true,
    }):addTo(title_bg):align(display.CENTER,title_bg:getContentSize().width/2,title_bg:getContentSize().height/2+5)

    local list_bg = display.newScale9Sprite("box_bg_546x214.png")
        :size(572,354)
        :addTo(backgroundImage)
        :align(display.TOP_CENTER, backgroundImage:getContentSize().width/2, title_bg:getPositionY() - title_bg:getContentSize().height - 5)
    local btn_bg = UIKit:commonButtonWithBG(
        {
            w=185,
            h=65,
            style = UIKit.BTN_COLOR.YELLOW,
            labelParams ={
                text = _("确定"),
                size = 20,
                color = 0xfff3c7,
            },
            listener = function ()
                shadowLayer:removeFromParent(true)
            end,
        }
    ):pos(backgroundImage:getContentSize().width/2,50)
        :addTo(backgroundImage)
    closeButton = btn_bg.button

    local scrollView = UIListView.new {
        viewRect = cc.rect(13,10, 546, 334),
        direction = UIScrollView.DIRECTION_VERTICAL,
        alignment = UIListView.ALIGNMENT_LEFT,
    }:addTo(list_bg)

    local tips = {_("将城市迁入联盟领地，受到联盟保护"),_("将城市迁入联盟领地，受到联盟保护"),_("将城市迁入联盟领地，受到联盟保护"),_("将城市迁入联盟领地，受到联盟保护"),_("将城市迁入联盟领地，受到联盟保护"),_("将城市迁入联盟领地，受到联盟保护"),_("将城市迁入联盟领地，受到联盟保护")}
    for i,v in ipairs(tips) do
        local item = scrollView:newItem()
        local content = display.newNode()
        local png = string.format("resource_item_bg%d.png",i % 2)
        display.newScale9Sprite(png):size(546,48):align(display.LEFT_BOTTOM,0,0):addTo(content)
        local star = display.newSprite("alliance_star_23x23.png"):addTo(content):align(display.LEFT_BOTTOM, 10, 10)
        UIKit:ttfLabel({
            text = v,
            size = 20,
            color = 0x403c2f,
            align = cc.TEXT_ALIGNMENT_LEFT
        }):addTo(content):align(display.LEFT_BOTTOM, star:getPositionX()+star:getContentSize().width+10, star:getPositionY()-2)
        item:addContent(content)
        item:setItemSize(546,48)
        scrollView:addItem(item)
    end
    scrollView:reload()
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
        image = "alliance_editbox_575x48.png",
        size = cc.size(510,48),
        listener = onEdit,
    })

    editbox_tag_search:setPlaceHolder(_("搜索联盟标签"))
    editbox_tag_search:setPlaceholderFontColor(UIKit:hex2c3b(0xccc49e))
    editbox_tag_search:setMaxLength(600)
    editbox_tag_search:setFont(UIKit:getEditBoxFont(),18)
    editbox_tag_search:setFontColor(cc.c3b(0,0,0))
    editbox_tag_search:setReturnType(cc.KEYBOARD_RETURNTYPE_SEARCH)
    editbox_tag_search:align(display.LEFT_TOP,searchIcon:getPositionX()+searchIcon:getContentSize().width+10,self.main_content:getCascadeBoundingBox().height - 10):addTo(joinNode)
    self.editbox_tag_search = editbox_tag_search
    local list,list_node = UIKit:commonListView({
        direction = UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(20, 0,608,680),
    })
    list_node:addTo(joinNode):pos(15,30)
    self.joinListView = list
    self:GetJoinList()
    return joinNode
end

-- tag ~= nil -->search
function GameUIAlliance:GetJoinList(tag)
    if tag then
        NetManager:getSearchAllianceByTagPromsie(tag):done(function(response)
            if not response.msg or not response.msg.allianceDatas then return end
            if response.msg.allianceDatas  then
                self:RefreshJoinListView(response.msg.allianceDatas)
            end
        end)
    else
        NetManager:getFetchCanDirectJoinAlliancesPromise():done(function(response)
            if not response.msg or not response.msg.allianceDatas then return end
            if response.msg.allianceDatas then
                self:RefreshJoinListView(response.msg.allianceDatas)
            end
        end)
    end
end

function GameUIAlliance:RefreshJoinListView(data)
    assert(data)
    self.joinListView:removeAllItems()
    for i,v in ipairs(data) do
        local newItem = self:getCommonListItem_(self.COMMON_LIST_ITEM_TYPE.JOIN,v)
        self.joinListView:addItem(newItem)
    end
    self.joinListView:reload()
end

function GameUIAlliance:SearchAllianAction(tag)
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
    if listType == self.COMMON_LIST_ITEM_TYPE.JOIN then
        targetListView = self.joinListView
    elseif listType == self.COMMON_LIST_ITEM_TYPE.INVATE then
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

    local titleBg = display.newScale9Sprite("alliance_event_type_cyan_222x30.png",0,0, cc.size(438,30), cc.rect(7,7,190,16))
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


    if listType == self.COMMON_LIST_ITEM_TYPE.JOIN then
        local leaderIcon = display.newSprite("alliance_item_leader_39x39.png")
            :addTo(bg)
            :align(display.LEFT_TOP,titleBg:getPositionX() - titleBg:getContentSize().width, titleBg:getPositionY() - titleBg:getContentSize().height -12)
        local leaderLabel = UIKit:ttfLabel({
            text = alliance.archon,
            size = 22,
            color = 0x403c2f
        }):addTo(bg):align(display.LEFT_TOP,leaderIcon:getPositionX()+leaderIcon:getContentSize().width+15, leaderIcon:getPositionY()-4)
        local buttonNormalPng,buttonHighlightPng,buttonText
        if alliance.joinType == 'all' then
            buttonNormalPng = "yellow_btn_up_148x58.png"
            buttonHighlightPng = "yellow_btn_down_148x58.png"
            buttonText = _("加入")

        else
            buttonNormalPng = "blue_btn_up_148x58.png"
            buttonHighlightPng = "blue_btn_down_148x58.png"
            buttonText = _("申请")
        end

        WidgetPushButton.new({normal = buttonNormalPng,pressed = buttonHighlightPng})
            :setButtonLabel(
                UIKit:ttfLabel({
                    text = buttonText,
                    size = 20,
                    shadow = true,
                    color = 0xfff3c7
                })
            )
            :align(display.RIGHT_TOP,titleBg:getPositionX(),titleBg:getPositionY() - titleBg:getContentSize().height -10)
            :onButtonClicked(function(event)
                self:commonListItemAction(listType,item,alliance)
            end)
            :addTo(bg)
        -- nameLabel:setString(alliance.name)
        memberValLabel:setString(string.format("%s/%s",alliance.members,alliance.membersMax))
        fightingValLabel:setString(alliance.power)
        languageValLabel:setString(alliance.language)
        killValLabel:setString(alliance.kill)

    elseif listType == self.COMMON_LIST_ITEM_TYPE.INVATE then

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
        -- nameLabel:setString(alliance.name)
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
    if listType == self.COMMON_LIST_ITEM_TYPE.JOIN then
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
    elseif  listType == self.COMMON_LIST_ITEM_TYPE.APPLY then
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
        return self.overviewNode end
    self.ui_overview = {}
    local overviewNode = display.newNode():addTo(self.main_content)

    local events_bg = display.newSprite("alliance_events_bg_540x356.png")
        :addTo(overviewNode):align(display.CENTER_BOTTOM, window.width/2,10)

    local eventListView = UIListView.new {
        viewRect = cc.rect(0, 12, 540,340),
        direction = UIScrollView.DIRECTION_VERTICAL,
    }:addTo(events_bg)
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
        :pos(18,events_title:getPositionY()+events_title:getContentSize().height+10)
    local titileBar = display.newScale9Sprite("alliance_event_type_cyan_222x30.png",0,0, cc.size(438,30), cc.rect(7,7,190,16))
        :addTo(headerBg):align(display.TOP_RIGHT, headerBg:getContentSize().width - 10, headerBg:getContentSize().height - 20)
    local flag_box = display.newScale9Sprite("alliance_item_flag_box_126X126.png"):size(134,134)
        :align(display.TOP_LEFT,20, headerBg:getContentSize().height - 20):addTo(headerBg)
    self.flag_box = flag_box
    self.ui_overview.nameLabel = UIKit:ttfLabel({
        text = string.format("[%s] %s",Alliance_Manager:GetMyAlliance():Tag(),Alliance_Manager:GetMyAlliance():Name()),
        size = 24,
        color = 0xffedae,
    }):align(display.LEFT_CENTER,10,15):addTo(titileBar)

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
        text = _("语言"),
        size = 20,
        color = 0x615b44,
    }):addTo(headerBg)
        :align(display.LEFT_BOTTOM,tagLabel:getPositionX(),line_0:getPositionY() + 2)
    local languageLabelVal = UIKit:ttfLabel({
        text = Localize.alliance_language[Alliance_Manager:GetMyAlliance():DefaultLanguage()],
        size = 20,
        color = 0x403c2f,
    })
        :addTo(headerBg)
        :align(display.RIGHT_BOTTOM,languageLabelVal:getPositionX(),languageLabel:getPositionY())
    self.ui_overview.languageLabelVal = languageLabelVal
    self.overviewNode = overviewNode
    return self.overviewNode
end

function GameUIAlliance:RefreshNoticeView()
    local textLabel = UIKit:ttfLabel({
        dimensions = cc.size(530, 0),
        text = string.len(Alliance_Manager:GetMyAlliance():Notice())>0 and Alliance_Manager:GetMyAlliance():Notice() or _("未设置联盟公告"),
        size = 20,
        color = 0x403c2f,
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

function GameUIAlliance:GetEventItemByIndexAndEvent(index,event)
    local item = self.eventListView:newItem()
    local bg = display.newSprite(string.format("alliance_events_bg_520x84_%d.png",index%2))
    local title_bg_image = self:GetEventTitleImageByEvent(event)
    local title_bg = display.newSprite(title_bg_image):addTo(bg):align(display.LEFT_TOP, 0,70)
    UIKit:ttfLabel({
        text = event.key or "",
        size = 20,
        color = 0xffedae
    }):addTo(title_bg):align(display.LEFT_BOTTOM,10,5)

    UIKit:ttfLabel({
        text = GameUtils:formatTimeStyle2(event.time/1000),
        size = 18,
        color = 0x615b44
    }):addTo(bg):align(display.LEFT_BOTTOM,10, 5)
    local contentLabel = UIKit:ttfLabel({
        text = self:GetEventContent(event),
        size = 20,
        color = 0x403c2f,
        dimensions = cc.size(300, 60)
    }):align(display.LEFT_CENTER,0,0)
    contentLabel:pos(title_bg:getPositionX()+title_bg:getContentSize().width + 10,42)
    contentLabel:addTo(bg)
    --end
    item:addContent(bg)
    item:setItemSize(520,84)
    return item
end

function GameUIAlliance:GetEventContent(event)
    local event_type = event.type
    local params_,params = event.params,{}
    for _,v in ipairs(params_) do
        if Localize.alliance_title[v] then
            v = Localize.alliance_title[v]
        end
        table.insert(params, v)
    end
    return string.format(Localize.alliance_events[event_type],unpack(params))
end


function GameUIAlliance:GetEventTitleImageByEvent(event)
    local category = event.category
    if category == 'normal' then
        return "alliance_event_type_cyan_222x30.png"
    elseif category == 'important' then
        return "alliance_event_type_green_222x30.png"
    elseif category == 'war' then
        return "alliance_event_type_red_222x30.png"
    end
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
        self.ui_overview.languageLabelVal:setString(Localize.alliance_language[alliance_data:DefaultLanguage()])
        self:RefreshNoticeView()
    end
end

function GameUIAlliance:RefreshEventListView()
    local events = Alliance_Manager:GetMyAlliance():Events()
    self.eventListView:removeAllItems()
    for i = #events, 1, -1 do
        self.eventListView:addItem(self:GetEventItemByIndexAndEvent(i,events[i]))
    end
    self.eventListView:reload()
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
    end
end
function GameUIAlliance:HaveAlliaceUI_membersIf()
    if not self.member_list_bg then
        self.member_list_bg = display.newNode():size(568,784):addTo(self.main_content)
            :align(display.CENTER_TOP, window.width/2, window.betweenHeaderAndTab)
        local list,list_node = UIKit:commonListView({
            viewRect = cc.rect(0, 0,560,618),
            direction = UIScrollView.DIRECTION_VERTICAL,
            -- bgColor = UIKit:hex2c4b(0x7a000000),
            trackTop = true,
        })
        list:onTouch(handler(self, self.MembersListonTouch))
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
        local title_bar =  display.newScale9Sprite("alliance_event_type_darkblue_222x30.png",0,0, cc.size(428,30), cc.rect(7,7,190,16))
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
        local line_2 = display.newScale9Sprite("dividing_line_594x2.png"):addTo(self.member_list_bg)
            :align(display.LEFT_BOTTOM,title_bar:getPositionX(),650)
            :size(428,2)
        local powerIcon = display.newSprite("dragon_strength_27x31.png")
            :align(display.LEFT_BOTTOM,line_2:getPositionX() + 5,line_2:getPositionY()+5)
            :addTo(self.member_list_bg)
        local powerLabel = UIKit:ttfLabel({
            text = "",
            size = 22,
            color = 0x403c2f,
            align = cc.TEXT_ALIGNMENT_LEFT,
        }):addTo(self.member_list_bg):align(display.LEFT_BOTTOM,powerIcon:getPositionX()+powerIcon:getContentSize().width+10,powerIcon:getPositionY())
        self.member_list_bg.powerLabel = powerLabel
        local loginLabel = UIKit:ttfLabel({
            text = "",
            size = 22,
            color = 0x403c2f,
            align = cc.TEXT_ALIGNMENT_RIGHT,
        }):addTo(self.member_list_bg):align(display.BOTTOM_RIGHT,554,line_2:getPositionY() + 5)
        self.member_list_bg.loginLabel = loginLabel
        local line_1 = display.newScale9Sprite("dividing_line_594x2.png"):addTo(self.member_list_bg)
            :align(display.LEFT_BOTTOM,title_bar:getPositionX(),688)
            :size(428,2)
        local display_title,imageName = self:GetAllianceTitleAndLevelPng("archon")
        local title_icon = display.newSprite(imageName)
            :align(display.LEFT_BOTTOM, line_1:getPositionX(), line_1:getPositionY() + 5)
            :addTo(self.member_list_bg)
        self.member_list_bg.archon_title_label = UIKit:ttfLabel({
            text = display_title,
            size = 22,
            color= 0x403c2f,
            align = cc.TEXT_ALIGNMENT_LEFT,
        }):align(display.LEFT_BOTTOM, title_icon:getPositionX()+title_icon:getContentSize().width + 10,title_icon:getPositionY()):addTo(self.member_list_bg)

        self.member_list_bg.view_archon_info_button = WidgetPushButton.new({normal = "alliacne_search_29x33.png"})
            :align(display.RIGHT_BOTTOM,554,line_1:getPositionY()+4)
            :addTo(self.member_list_bg)
            :onButtonClicked(function()
                local archon = Alliance_Manager:GetMyAlliance():GetAllianceArchon()
                self:OnPlayerDetailButtonClicked(archon:Id())
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
    --list view
    self.memberListView:removeAllItems()

    local item = self:GetMemberItem("general")
    self.memberListView:addItem(item)
    item = self:GetMemberItem("quartermaster")
    self.memberListView:addItem(item)

    item = self:GetMemberItem("supervisor")
    self.memberListView:addItem(item)
    item = self:GetMemberItem("elite")
    self.memberListView:addItem(item)
    item = self:GetMemberItem("member")
    self.memberListView:addItem(item)



    self.memberListView:reload()
end

function GameUIAlliance:GetAllianceTitleAndLevelPng(title)
    local alliance = Alliance_Manager:GetMyAlliance()
    return alliance:GetTitles()[title],UILib.alliance_title_icon[title]
end

--title is alliance title
function GameUIAlliance:GetMemberItem(title)
    local item = self.memberListView:newItem()
    local filter_data = LuaUtils:table_filter(Alliance_Manager:GetMyAlliance():GetAllMembers(),function(k,v)
        return v:Title() == title
    end)
    local data = {}
    table.foreach(filter_data,function(k,v)
        table.insert(data,v)
    end)
    table.sort( data, function(a,b)
        local isOnline_a = (type(a.online) == 'boolean' and a.online) and true or false
        local isOnline_b = (type(b.online) == 'boolean' and b.online) and true or false
        if isOnline_a == isOnline_b then
            return a.power > b.power
        else
            return isOnline_a
        end
    end)
    local header_title,number_image = self:GetAllianceTitleAndLevelPng(title)
    local count = #data
    -- 71 = 66 + 5
    local height = 34 + count * 71 + 15
    if count == 0 then
        height = 120 -- 120 = 34 + 71 + 15
    end
    local node = display.newNode():size(560,height)
    local title_bar = display.newSprite("title_blue_558x34.png"):align(display.LEFT_TOP, 0, height):addTo(node)
    local button = display.newSprite("info_16x33.png")
        :align(display.RIGHT_CENTER,545,17)
        :addTo(title_bar)
        :scale(0.7)
    WidgetPushTransparentButton.new(cc.rect(0,0,560,38)):addTo(title_bar):align(display.LEFT_BOTTOM,0,0):onButtonClicked(function(event)
            self:OnAllianceTitleClicked(title)
        end)
    local title_label= UIKit:ttfLabel({
        text = header_title,
        size = 22,
        color = 0xffedae,
    }):addTo(title_bar):align(display.LEFT_CENTER,268, 17)
    local num = display.newSprite(number_image):addTo(title_bar)
        :align(display.RIGHT_CENTER,258,17)
    local y = height - 39
    if count > 0 then
        for i,v in ipairs(data) do
            local isOnline = (type(v.online) == 'boolean' and v.online) and true or false
            self:GetNormalSubItem(i,v.name,User:GetPlayerLevelByExp(v.levelExp),v.power,v.id,v.icon,isOnline):addTo(node):align(display.LEFT_TOP, 0, y)
            y = y - 71
        end
    else
        local tips = display.newSprite("mission_box_558x66.png"):align(display.LEFT_TOP,0, y):addTo(node)
        UIKit:ttfLabel({
            text = _("<空>"),
            size = 22,
            color= 0x615b44
        }):align(display.CENTER, 279, 33):addTo(tips)
    end
    item:addContent(node)
    item:setItemSize(560,height)
    return item
end

function GameUIAlliance:GetNormalSubItem(index,playerName,level,power,memberId,icon,online)
    local item = display.newSprite("mission_box_558x66.png")
    local icon = UIKit:GetPlayerCommonIcon(icon,online):scale(0.5):align(display.LEFT_CENTER,15, 33):addTo(item)
    local nameLabel = UIKit:ttfLabel({
        text = playerName,
        size = 20,
        color = 0x403c2f,
        dimensions = cc.size(175,30),
        ellipsis = true
    }):addTo(item):align(display.LEFT_CENTER,icon:getPositionX()+icon:getCascadeBoundingBox().width + 5,33)
    local lvLabel =  UIKit:ttfLabel({
        text = "LV " .. level,
        size = 20,
        color = 0x615b44,
    }):addTo(item):align(display.LEFT_CENTER,icon:getPositionX()+icon:getCascadeBoundingBox().width + 180, 33)
    local powerIcon = display.newSprite("dragon_strength_27x31.png"):align(display.LEFT_CENTER,icon:getPositionX()+icon:getCascadeBoundingBox().width+255,33)
        :addTo(item)
    local powerLabel = UIKit:ttfLabel({
        text = string.formatnumberthousands(power),
        size = 22,
        color = 0x403c2f,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):addTo(item):align(display.LEFT_CENTER,powerIcon:getPositionX()+35,33)
    if User:Id()~= memberId then
        display.newSprite("alliacne_search_29x33.png")
            :align(display.RIGHT_CENTER,548,33)
            :addTo(item)
        WidgetPushTransparentButton.new(cc.rect(0,0,558,66))
            :align(display.LEFT_BOTTOM,0,0)
            :addTo(item)
            :onButtonClicked(function()
                 self:OnPlayerDetailButtonClicked(memberId)
            end)
    end
    return item
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
    local informationNode = WidgetUIBackGround.new({height=384,isFrame = "yes"}):addTo(self.main_content):pos(20,window.betweenHeaderAndTab - 394)
    self.informationNode = informationNode
    local notice_bg = display.newSprite("alliance_notice_box_580x184.png")
        :align(display.CENTER_TOP,informationNode:getContentSize().width/2,395)
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
    local button_imags = {"alliance_sign_out_60x54.png","alliance_invitation_60x54.png","alliance_apply_60x54.png","alliance_group_mail_60x54.png"}
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
    local textLabel = UIKit:ttfLabel({
        dimensions = cc.size(530, 0),
        text = string.len(Alliance_Manager:GetMyAlliance():Describe())>0 and Alliance_Manager:GetMyAlliance():Describe() or _("未设置联盟描述"),
        size = 20,
        color = 0x403c2f,
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
    local bg = WidgetUIBackGround.new({height=150}):addTo(layer):pos(window.left+20,window.cy-20)
    local title_bar = display.newSprite("title_blue_600x56.png")
        :addTo(bg)
        :align(display.LEFT_BOTTOM, 0,150-15)

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
    }):addTo(title_bar):align(display.LEFT_BOTTOM, 100, 10)

    UIKit:ttfLabel({
        text = _("邀请玩家加入"),
        size = 20,
        color = 0x615b44
    }):addTo(bg):align(display.LEFT_TOP, 20,150-40)

    local editbox = cc.ui.UIInput.new({
        UIInputType = 1,
        image = "input_box.png",
        size = cc.size(422,40),
    })
    editbox:setFont(UIKit:getEditBoxFont(),18)
    editbox:setFontColor(cc.c3b(0,0,0))
    editbox:setPlaceHolder(_("输入邀请的玩家ID"))
    editbox:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    editbox:align(display.RIGHT_TOP,588,120):addTo(bg)
    WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
        :setButtonLabel(
            UIKit:commonButtonLable({
                text = _("发送"),
                color = 0xffedae
            })
        )
        :onButtonClicked(function(event)
            local playerID = string.trim(editbox:getText())
            if string.len(playerID) == 0 then
                UIKit:showMessageDialog(_("提示"), _("请输入邀请的玩家ID"), function()end)
                return
            end
            NetManager:getInviteToJoinAlliancePromise(playerID):done(function(result)
                layer:removeFromParent(true)
                UIKit:showMessageDialog(_("提示"), _("邀请发送成功"), function()end)
            end)
        end)
        :addTo(bg):align(display.RIGHT_BOTTOM,editbox:getPositionX(), 20)

    layer:addTo(self)
end


return GameUIAlliance

