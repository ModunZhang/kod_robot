--
-- Author: Kenny Dai
-- Date: 2015-05-08 19:47:52
--
local window = import("..utils.window")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetRoundTabButtons = import("..widget.WidgetRoundTabButtons")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetAllianceHelper = import("..widget.WidgetAllianceHelper")
local WidgetPushButton = import("..widget.WidgetPushButton")
local Alliance_Manager = Alliance_Manager
local GameUIAllianceInfo = class("GameUIAllianceInfo", WidgetPopDialog)
local Localize = import("..utils.Localize")
local UILib = import(".UILib")
local NetService = import('..service.NetService')
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")

function GameUIAllianceInfo:ctor(alliance_id,default_tab,serverId)
    GameUIAllianceInfo.super.ctor(self,710,_("联盟信息"),window.top - 140)
    self.alliance_id = alliance_id
    self.serverId = serverId or User.serverId
    self.default_tab = default_tab or "Info"
    self.alliance_ui_helper = WidgetAllianceHelper.new()
end

function GameUIAllianceInfo:GetAllianceData()
    return self.alliance_data
end

function GameUIAllianceInfo:setAllianceData(data)
    self.alliance_data = data
    table.sort( self.alliance_data.memberList, function(a,b)
        local isOnline_a = (type(a.online) == 'boolean' and a.online) and true or false
        local isOnline_b = (type(b.online) == 'boolean' and b.online) and true or false
        if isOnline_a == isOnline_b then
            return a.power > b.power
        else
            return isOnline_a
        end
    end)
end

function GameUIAllianceInfo:filterMemberList(title)
    local memebers = self:GetAllianceData().memberList
    local filter_data = LuaUtils:table_filter(memebers,function(k,v)
        return v.title == title
    end)

    local result = {}
    if LuaUtils:table_empty(filter_data) then
        table.insert(result,{data_type = 2 , data = "__empty"})
    else
        --player
        table.foreach(filter_data,function(k,v)
            table.insert(result,{data_type = 2 , data = v})
        end)
        table.sort(result, function(a,b)
            local a_data,b_data = a.data, b.data
            local isOnline_a = type(a_data.online) == 'boolean' and a_data.online
            local isOnline_b = type(b_data.online) == 'boolean' and b_data.online
            if isOnline_a == isOnline_b then
                return a_data.power > b_data.power
            else
                return isOnline_a
            end
        end)
    end
    table.insert(result, 1, {data_type = 1 , data = title})
    return result
end

function GameUIAllianceInfo:RefreshListDataSource()
    local data = self:filterMemberList("general")
    local next_data = self:filterMemberList("quartermaster")
    table.insertto(data, next_data, #data + 1)
    next_data = self:filterMemberList("supervisor")
    table.insertto(data, next_data, #data + 1)
    next_data = self:filterMemberList("elite")
    table.insertto(data, next_data, #data + 1)
    next_data = self:filterMemberList("member")
    table.insertto(data, next_data, #data + 1)
    dump(data)
    self.list_dataSource = data
end

function GameUIAllianceInfo:GetAllianceArchonData()
    for __,v in ipairs(self:GetAllianceData().memberList) do
        if v.title == 'archon' then
            return v
        end
    end
end

function GameUIAllianceInfo:GetAllianceArchonName()
    return self:GetAllianceArchonData().name
end

function GameUIAllianceInfo:onExit()
    GameUIAllianceInfo.super.onExit(self)
end
function GameUIAllianceInfo:onEnter()
    GameUIAllianceInfo.super.onEnter(self)
    NetManager:getAllianceInfoPromise(self.alliance_id, self.serverId):done(function(response)
        if response.success and response.msg.allianceData then
            self:setAllianceData(response.msg.allianceData)
            self:BuildUI()
        end
    end):fail(function ()
        if self.LeftButtonClicked then
            self:LeftButtonClicked()
        end
    end)

end

function GameUIAllianceInfo:BuildUI()
    WidgetRoundTabButtons.new({
        {tag = "Info",label = _("信息"),default = self.default_tab == "Info"},
        {tag = "Contact",label = _("联系盟主"),default = self.default_tab == "Contact"},
        {tag = "Members",label = _("成员列表"),default = self.default_tab == "Members"},
    }, function(tag)
        self:OnTabButtonClicked(tag)
    end,1):align(display.BOTTOM_CENTER,304,10):addTo(self:GetBody()):zorder(200)
end

function GameUIAllianceInfo:OnTabButtonClicked( tag )
    local method = string.format("Load%s",tag)
    if self[method] then
        if self.current_content then
            self.current_content:hide()
        end
        self.current_content = self[method](self)
        self.current_content:show()
    end
end
function GameUIAllianceInfo:LoadInfo()
    if self.info_layer then return self.info_layer end
    local layer = display.newLayer():addTo(self:GetBody())
    layer:size(608,698)
    self.info_layer = layer
    local alliance_data = self:GetAllianceData()
    local l_size = layer:getContentSize()
    local flag_box = display.newScale9Sprite("alliance_item_flag_box_126X126.png")
        :size(100,100)
        :addTo(layer)
        :align(display.LEFT_TOP, 30, l_size.height - 20)
    local flag_sprite = self.alliance_ui_helper:CreateFlagWithRhombusTerrain(alliance_data.terrain,alliance_data.flag)
    flag_sprite:addTo(flag_box)
    flag_sprite:pos(50,40)

    local titleBg = display.newScale9Sprite("title_blue_430x30.png",0,0, cc.size(438,30), cc.rect(10,10,410,10))
        :addTo(layer)
        :align(display.RIGHT_TOP,l_size.width-30, l_size.height - 20)
    local nameLabel = UIKit:ttfLabel({
        text = string.format("[%s] %s",alliance_data.tag,alliance_data.name), -- alliance name
        size = 22,
        color = 0xffedae
    }):addTo(titleBg):align(display.LEFT_CENTER,10, 15)
    local info_bg = WidgetUIBackGround.new({height=82,width=556},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :align(display.LEFT_TOP, flag_box:getPositionX(),l_size.height - 126)
        :addTo(layer)
    local memberTitleLabel = UIKit:ttfLabel({
        text = _("成员"),
        size = 20,
        color = 0x615b44
    }):addTo(info_bg):align(display.LEFT_TOP,10,info_bg:getContentSize().height - 10)

    local memberValLabel = UIKit:ttfLabel({
        text = string.format("%d/%d",alliance_data.members,alliance_data.membersMax), --count of members
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_TOP,memberTitleLabel:getPositionX() + memberTitleLabel:getContentSize().width + 10, memberTitleLabel:getPositionY())


    local fightingTitleLabel = UIKit:ttfLabel({
        text = _("战斗力"),
        size = 20,
        color = 0x615b44
    }):addTo(info_bg):align(display.LEFT_TOP, 320, memberTitleLabel:getPositionY())

    local fightingValLabel = UIKit:ttfLabel({
        text = string.formatnumberthousands(alliance_data.power),
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_TOP, fightingTitleLabel:getPositionX() + fightingTitleLabel:getContentSize().width + 10, fightingTitleLabel:getPositionY())


    local languageTitleLabel = UIKit:ttfLabel({
        text = _("国家"),
        size = 20,
        color = 0x615b44
    }):addTo(info_bg):align(display.LEFT_BOTTOM,memberTitleLabel:getPositionX(),10)
    local languageValLabel = UIKit:ttfLabel({
        text = Localize.alliance_language[alliance_data.country], -- language
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_BOTTOM,languageTitleLabel:getPositionX() + languageTitleLabel:getContentSize().width + 10,10)


    local killTitleLabel = UIKit:ttfLabel({
        text = _("击杀"),
        size = 20,
        color = 0x615b44,
        align = ui.TEXT_ALIGN_RIGHT,
    }):addTo(info_bg):align(display.LEFT_BOTTOM, fightingTitleLabel:getPositionX(),10)

    local killValLabel = UIKit:ttfLabel({
        text = string.formatnumberthousands(alliance_data.kill),
        size = 20,
        color = 0x403c2f
    }):addTo(info_bg):align(display.LEFT_BOTTOM, killTitleLabel:getPositionX() + killTitleLabel:getContentSize().width + 10, 10)

    local leaderIcon = display.newSprite("alliance_item_leader_39x39.png")
        :addTo(layer)
        :align(display.LEFT_TOP,titleBg:getPositionX() - titleBg:getContentSize().width, titleBg:getPositionY() - titleBg:getContentSize().height -12)
    local leaderLabel = UIKit:ttfLabel({
        text = self:GetAllianceArchonName() or  "",
        size = 22,
        color = 0x403c2f
    }):addTo(layer):align(display.LEFT_TOP,leaderIcon:getPositionX()+leaderIcon:getContentSize().width+15, leaderIcon:getPositionY()-4)
    local buttonNormalPng,buttonHighlightPng,buttonText
    if alliance_data.joinType == 'all' then
        buttonNormalPng = "yellow_btn_up_148x58.png"
        buttonHighlightPng = "yellow_btn_down_148x58.png"
        buttonText = _("加入")

    else
        buttonNormalPng = "blue_btn_up_148x58.png"
        buttonHighlightPng = "blue_btn_down_148x58.png"
        buttonText = _("申请")
    end

    local button = WidgetPushButton.new({normal = buttonNormalPng,pressed = buttonHighlightPng,disabled = "grey_btn_148x58.png"})
        :setButtonLabel(
            UIKit:ttfLabel({
                text = buttonText,
                size = 20,
                shadow = true,
                color = 0xfff3c7
            })
        )
        :align(display.RIGHT_TOP,titleBg:getPositionX(),titleBg:getPositionY() - titleBg:getContentSize().height -10)
        :addTo(layer)
    button:setButtonEnabled(Alliance_Manager:GetMyAlliance():IsDefault() and User.serverId ~= self.serverId )
    button:onButtonClicked(function(event)
        self:OnJoinActionClicked(alliance_data.joinType,button)
    end)

    local desc_bg = WidgetUIBackGround.new({height=308,width=550},WidgetUIBackGround.STYLE_TYPE.STYLE_3)
        :align(display.CENTER_TOP, l_size.width/2,l_size.height - 220)
        :addTo(layer)

    local desc = alliance_data.desc
    if not desc or desc == json.null then
        desc = _("联盟未设置联盟描述")
    end
    local killTitleLabel = UIKit:ttfLabel({
        text =  desc,
        size = 20,
        color = 0x615b44,
        dimensions = cc.size(530,0),
        align = cc.TEXT_ALIGNMENT_CENTER,
    }):addTo(desc_bg):align(display.CENTER, desc_bg:getContentSize().width/2,desc_bg:getContentSize().height/2)

    return layer
end

function GameUIAllianceInfo:OnJoinActionClicked(joinType,sender)
    if joinType == 'all' then --如果是直接加入
        if User.serverId ~= self.serverId then
            UIKit:showMessageDialog(_("提示"),_("不能加入其他服务器的联盟"))
            return
    end
    local alliance = self:GetAllianceData()
    if alliance.members == alliance.membersMax then
        UIKit:showMessageDialog(_("提示"),
            _("联盟人数已达最大"))
        return
    end
    NetManager:getJoinAllianceDirectlyPromise(self:GetAllianceData().id):fail(function()

        end):done(function()
        GameGlobalUI:showTips(_("提示"),string.format(_("加入%s联盟成功!"),self:GetAllianceData().name))
        self:LeftButtonClicked()
        end)
    else
        if User.serverId ~= self.serverId then
            UIKit:showMessageDialog(_("提示"),_("不能申请加入其他服务器的联盟"))
            return
        end
        NetManager:getRequestToJoinAlliancePromise(self:GetAllianceData().id):done(function()
            UIKit:showMessageDialog(_("申请成功"),
                string.format(_("您的申请已发送至%s,如果被接受将加入该联盟,如果被拒绝,将收到一封通知邮件."),self:GetAllianceData().name),
                function()end)
            sender:setButtonEnabled(false)
        end):fail(function()
            end)
    end
    --
end
function GameUIAllianceInfo:LoadContact()
    if self.mail_layer then return self.mail_layer end
    local layer = display.newLayer():addTo(self:GetBody())
    layer:size(608,698)
    self.mail_layer = layer
    local l_size = layer:getContentSize()
    local receiver_title = UIKit:ttfLabel({
        text = _("收件人").." : ",
        size = 20,
        color = 0x615b44,
    }):addTo(layer):align(display.RIGHT_CENTER,120 , l_size.height - 45)
    local receiver_bg = WidgetUIBackGround.new({height=40,width=446},WidgetUIBackGround.STYLE_TYPE.STYLE_8)
        :align(display.LEFT_CENTER, receiver_title:getPositionX() + 10,receiver_title:getPositionY())
        :addTo(layer)
    local other_archon = UIKit:ttfLabel({
        text = self:GetAllianceArchonName(), -- language
        size = 20,
        color = 0x403c2f
    }):addTo(receiver_bg):align(display.LEFT_CENTER,10,receiver_bg:getContentSize().height/2)

    local subject_title = UIKit:ttfLabel({
        text = _("主题").." : ",
        size = 20,
        color = 0x615b44,
    }):addTo(layer):align(display.RIGHT_CENTER,120 , l_size.height - 95)

    local editbox_subject = cc.ui.UIInput.new({
        UIInputType = 1,
        image = "input_box.png",
        size = cc.size(446,40),
        font = UIKit:getFontFilePath(),
    })
    editbox_subject:setPlaceHolder(string.format(_("最多可输入%d字符"),140))
    editbox_subject:setMaxLength(140)
    editbox_subject:setFont(UIKit:getEditBoxFont(),22)
    editbox_subject:setFontColor(cc.c3b(0,0,0))
    editbox_subject:setPlaceholderFontColor(cc.c3b(204,196,158))
    editbox_subject:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    editbox_subject:align(display.LEFT_CENTER,subject_title:getPositionX() + 10,subject_title:getPositionY()):addTo(layer)

    -- 分割线
    local line = display.newScale9Sprite("dividing_line.png",l_size.width/2, subject_title:getPositionY() - 35,cc.size(594,2),cc.rect(10,2,382,2)):addTo(layer)

    -- 内容
    UIKit:ttfLabel(
        {
            text = _("内容").." : ",
            size = 20,
            color = 0x615b44
        }):align(display.LEFT_CENTER,30,line:getPositionY() - 20)
        :addTo(layer)
    -- 回复的邮件内容
    local textView = ccui.UITextView:create(cc.size(558,352),display.newScale9Sprite("background_88x42.png"))
    textView:addTo(layer):align(display.CENTER_TOP,l_size.width/2,line:getPositionY() - 40)
    textView:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    textView:setFont(UIKit:getEditBoxFont(), 24)
    textView:setMaxLength(1024)

    textView:setFontColor(cc.c3b(0,0,0))

    -- 发送按钮
    local send_label = UIKit:ttfLabel({
        text = _("发送"),
        size = 20,
        color = 0xfff3c7})

    send_label:enableShadow()
    local send_button = WidgetPushButton.new(
        {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(send_label)
        :addTo(layer):align(display.CENTER, l_size.width-100, 130)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:SendMail(self:GetAllianceArchonData().id, editbox_subject:getText(), textView:getText())
            end
        end)

    textView:setRectTrackedNode(send_button)
    return self.mail_layer
end
function GameUIAllianceInfo:SendMail(addressee,title,content)
    if not title or string.trim(title)=="" then
        UIKit:showMessageDialog(_("主人"),_("请填写邮件主题"))
        return
    elseif not content or string.trim(content)=="" then
        UIKit:showMessageDialog(_("主人"),_("请填写邮件内容"))
        return
    end
    if not addressee or string.trim(addressee)=="" then
        UIKit:showMessageDialog(_("主人"),_("请填写正确的收件人ID"))
        return
    end
    if User:Id() == addressee then
        UIKit:showMessageDialog(_("主人"),_("不能给自己发送邮件"))
        return
    end
    local ar_data = self:GetAllianceArchonData()
    NetManager:getSendPersonalMailPromise(addressee, title, content,{
        id = ar_data.id,
        name = ar_data.name,
        icon = ar_data.icon,
        allianceTag = self:GetAllianceData().tag,
    }):done(function(result)
        self:removeFromParent()
        return result
    end)

end
function GameUIAllianceInfo:LoadMembers()
    if self.member_layer then return self.member_layer  end
    local layer = display.newLayer():addTo(self:GetBody())
    layer:size(608,698)
    self.member_layer = layer
    local alliance_data = self:GetAllianceData()
    local archon_data = self:GetAllianceArchonData()
    local list,list_node = UIKit:commonListView({
        viewRect = cc.rect(0, 0,560,394),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        async = true,
    },nil,nil,true)
    self.memberListView = list
    list_node:addTo(layer):pos((self:GetBody():getContentSize().width - 560)/2,100)
    self.memberListView:setDelegate(handler(self, self.sourceDelegate))

    list:onTouch(handler(self, self.listviewListener))
    local box = display.newScale9Sprite("alliance_item_flag_box_126X126.png")
        :size(126,134)
        :addTo(layer)
        :align(display.LEFT_TOP,22,664)
    WidgetPushTransparentButton.new(cc.rect(0,0,560,134)):addTo(layer):align(display.LEFT_TOP,22,664):onButtonClicked(function()
        UIKit:newGameUI("GameUIAllianceMemberInfo",false,archon_data.id,nil,self.serverId):AddToCurrentScene(true)
    end)
    local title_bar =  display.newScale9Sprite("title_blue_430x30.png",0,0, cc.size(428,30), cc.rect(10,10,410,10))
        :addTo(layer)
        :align(display.LEFT_TOP, 154, 664)
    local title_label = UIKit:ttfLabel({
        text = archon_data.name,
        size = 22,
        color= 0xffedae,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):addTo(title_bar):align(display.LEFT_CENTER,5, 15)
    local line_2 = display.newScale9Sprite("dividing_line.png",0,0,cc.size(428,2),cc.rect(10,2,382,2))
        :addTo(layer)
        :align(display.LEFT_BOTTOM,title_bar:getPositionX(),536)

    local powerIcon = display.newSprite("dragon_strength_27x31.png")
        :align(display.LEFT_BOTTOM,line_2:getPositionX() + 5,line_2:getPositionY()+5)
        :addTo(layer)
    local powerLabel = UIKit:ttfLabel({
        text = string.formatnumberthousands(archon_data.power),
        size = 22,
        color = 0x403c2f,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):addTo(layer):align(display.LEFT_BOTTOM,powerIcon:getPositionX()+powerIcon:getContentSize().width+10,powerIcon:getPositionY())
    if Alliance_Manager:GetMyAlliance():GetMemeberById(archon_data.id) then
        local isOnline = (type(archon_data.online) == 'boolean' and archon_data.online) and true or false
        local time_str = _("在线")
        if not isOnline then
            time_str = _("最后登录:") .. NetService:formatTimeAsTimeAgoStyleByServerTime(archon_data.lastLogoutTime)
        end
        UIKit:GetPlayerCommonIcon(archon_data.icon,isOnline):addTo(box):pos(63,67)
        local loginLabel = UIKit:ttfLabel({
            text = time_str,
            size = 22,
            color = 0x403c2f,
            align = cc.TEXT_ALIGNMENT_RIGHT,
        }):addTo(layer):align(display.BOTTOM_RIGHT,line_2:getPositionX() + 428,line_2:getPositionY() + 5)
    else
        UIKit:GetPlayerCommonIcon(archon_data.icon,true):addTo(box):pos(63,67)
    end
    local line_1 = display.newScale9Sprite("dividing_line.png",0,0,cc.size(428,2),cc.rect(10,2,382,2))
        :addTo(layer)
        :align(display.LEFT_BOTTOM,title_bar:getPositionX(),572)

    local display_title,imageName = self:GetAllianceTitleAndLevelPng("archon")
    local title_icon = display.newSprite(imageName)
        :align(display.LEFT_BOTTOM, line_1:getPositionX(), line_1:getPositionY() + 5)
        :addTo(layer)
    local archon_title_label = UIKit:ttfLabel({
        text = display_title,
        size = 22,
        color= 0x403c2f,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):align(display.LEFT_BOTTOM, title_icon:getPositionX()+title_icon:getContentSize().width + 10,title_icon:getPositionY()):addTo(layer)

    local view_detail = display.newSprite("alliacne_search_29x33.png"):align(display.RIGHT_BOTTOM,line_1:getPositionX() + 428,line_1:getPositionY()+4):addTo(layer)

    self:RefreshMemberList()
    return self.member_layer
end

function GameUIAllianceInfo:GetAllianceTitleAndLevelPng(title)
    local titles = Localize.alliance_title
    local final_title = titles[title]
    if string.sub(final_title, 1, 2) == "__" then
        final_title = Localize.alliance_title[title]
    end
    return final_title,UILib.alliance_title_icon[title]
end

function GameUIAllianceInfo:RefreshMemberList()
    self:RefreshListDataSource()
    self.memberListView:reload()
end


function GameUIAllianceInfo:GetMemberItemContent()
    local node = display.newNode():size(560,78)
    local content_title = display.newSprite("title_blue_554x34.png"):align(display.LEFT_BOTTOM, 0, 0):addTo(node)
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

function GameUIAllianceInfo:GetPlayerIconSprite()

    local bg = display.newSprite("dragon_bg_114x114.png", nil, nil, {class=cc.FilteredSpriteWithOne})
    local icon = display.newSprite(UIKit:GetPlayerIconImage(1), nil, nil, {class=cc.FilteredSpriteWithOne}):addTo(bg):align(display.CENTER,56,65)
    bg.icon = icon
    return bg
end

function GameUIAllianceInfo:FillDataToAllianceItem(list_data,content,item)
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
            real_content.info_sprite:show()

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

function GameUIAllianceInfo:sourceDelegate(listView, tag, idx)
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

function GameUIAllianceInfo:listviewListener(event)
    local listView = event.listView
    if "clicked" == event.name then
        local item = event.item
        if not item then return end
        local list_data = self.list_dataSource[item.idx_]
        if list_data.data_type == 2 and list_data.data ~= '__empty' then
            local data = list_data.data
            UIKit:newGameUI("GameUIAllianceMemberInfo",false,data.id,nil,self.serverId):AddToCurrentScene(true)
        end
    end
end
return GameUIAllianceInfo









