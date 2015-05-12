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



local GameUIAllianceInfo = class("GameUIAllianceInfo", WidgetPopDialog)

function GameUIAllianceInfo:ctor(alliance,default_tab)
    GameUIAllianceInfo.super.ctor(self,710,_("联盟信息"),window.top - 140)
    self.alliance = alliance
    self.default_tab = default_tab
    self.alliance_ui_helper = WidgetAllianceHelper.new()
end

function GameUIAllianceInfo:onExit()
    GameUIAllianceInfo.super.onExit(self)
end
function GameUIAllianceInfo:onEnter()
    GameUIAllianceInfo.super.onEnter(self)
    local centent_layer =display.newLayer():addTo(self:GetBody())
    centent_layer:setContentSize(cc.size(608,698))
    self.centent_layer = centent_layer

    WidgetRoundTabButtons.new({
        {tag = "info",label = _("信息"),default = self.default_tab == "info"},
        {tag = "contact",label = _("联系盟主"),default = self.default_tab == "contact"},
        {tag = "members",label = _("成员列表"),default = self.default_tab == "members"},
    }, function(tag)
        self:OnTabButtonClicked(tag)
    end,2):align(display.BOTTOM_CENTER,304,10):addTo(self:GetBody())

end
function GameUIAllianceInfo:OnTabButtonClicked( tag )
    self.centent_layer:removeAllChildren()
    if tag == "info" then
        self:LoadInfo()
    elseif tag == "contact" then
        self:LoadContact()
    elseif tag == "members" then
        self:LoadMembers()
    end
end
function GameUIAllianceInfo:LoadInfo()
    local layer = self.centent_layer
    local l_size = layer:getContentSize()
    local flag_box = display.newScale9Sprite("alliance_item_flag_box_126X126.png")
        :size(100,100)
        :addTo(layer)
        :align(display.LEFT_TOP, 30, l_size.height - 20)

    -- local flag_sprite = self.alliance_ui_helper:CreateFlagWithRhombusTerrain(terrain,Flag.new():DecodeFromJson(flag_info))
    -- flag_sprite:addTo(flag_box)
    -- flag_sprite:pos(50,40)

    local titleBg = display.newScale9Sprite("title_blue_430x30.png",0,0, cc.size(438,30), cc.rect(10,10,410,10))
        :addTo(layer)
        :align(display.RIGHT_TOP,l_size.width-30, l_size.height - 20)
    local nameLabel = UIKit:ttfLabel({
        text = "alliance name", -- alliance name
        -- text = string.format("[%s] %s",alliance.tag,alliance.name), -- alliance name
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
        text = "alliance.power",
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
        :addTo(layer)
        :align(display.LEFT_TOP,titleBg:getPositionX() - titleBg:getContentSize().width, titleBg:getPositionY() - titleBg:getContentSize().height -12)
    local leaderLabel = UIKit:ttfLabel({
        text = "alliance.archon",
        size = 22,
        color = 0x403c2f
    }):addTo(layer):align(display.LEFT_TOP,leaderIcon:getPositionX()+leaderIcon:getContentSize().width+15, leaderIcon:getPositionY()-4)
    local buttonNormalPng,buttonHighlightPng,buttonText
    -- if alliance.joinType == 'all' then
    --     buttonNormalPng = "yellow_btn_up_148x58.png"
    --     buttonHighlightPng = "yellow_btn_down_148x58.png"
    --     buttonText = _("加入")

    -- else
    buttonNormalPng = "blue_btn_up_148x58.png"
    buttonHighlightPng = "blue_btn_down_148x58.png"
    buttonText = _("申请")
    -- end

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

            end)
        :addTo(layer)

    local desc_bg = WidgetUIBackGround.new({height=308,width=550},WidgetUIBackGround.STYLE_TYPE.STYLE_3)
        :align(display.CENTER_TOP, l_size.width/2,l_size.height - 220)
        :addTo(layer)

    local killTitleLabel = UIKit:ttfLabel({
        text = "＜联盟中设置的联盟描述＞＜联盟中设置的联盟描述＞＜联盟中设置的联盟描述＞＜联盟中设置的联盟描述＞＜联盟中设置的联盟描述＞＜联盟中设置的联盟描述＞＜联盟中设置的联盟描述＞＜联盟中设置的联盟描述＞＜联盟中设置的联盟描述＞",
        size = 20,
        color = 0x615b44,
        dimensions = cc.size(530,0)
    }):addTo(desc_bg):align(display.CENTER, desc_bg:getContentSize().width/2,desc_bg:getContentSize().height/2)
end

function GameUIAllianceInfo:LoadContact()
    local layer = self.centent_layer
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
        text = "alliance.other_archon", -- language
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
    editbox_subject:setPlaceHolder(_("最多可输入140字符"))
    editbox_subject:setMaxLength(140)
    editbox_subject:setFont(UIKit:getEditBoxFont(),22)
    editbox_subject:setFontColor(cc.c3b(0,0,0))
    editbox_subject:setPlaceholderFontColor(cc.c3b(204,196,158))
    editbox_subject:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    editbox_subject:align(display.LEFT_CENTER,subject_title:getPositionX() + 10,subject_title:getPositionY()):addTo(layer)

    -- 分割线
    local line =display.newScale9Sprite("dividing_line_584x1.png", l_size.width/2, subject_title:getPositionY() - 35,cc.size(594,1)):addTo(layer)
    -- 内容
    UIKit:ttfLabel(
        {
            text = _("内容").." : ",
            size = 20,
            color = 0x615b44
        }):align(display.LEFT_CENTER,30,line:getPositionY() - 20)
        :addTo(layer)
    -- 回复的邮件内容
    local textView = ccui.UITextView:create(cc.size(558,352),display.newScale9Sprite("background_580X472.png"))
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
                self:SendMail(contacts and contacts.id, editbox_subject:getText(), textView:getText())
            end
        end)
    textView:setRectTrackedNode(send_button)
end
function GameUIAllianceInfo:SendMail(addressee,title,content)
    if not title or string.trim(title)=="" then
        UIKit:showMessageDialog(_("陛下"),_("请填写邮件主题"))
        return
    elseif not content or string.trim(content)=="" then
        UIKit:showMessageDialog(_("陛下"),_("请填写邮件内容"))
        return
    end
    if not addressee or string.trim(addressee)=="" then
        UIKit:showMessageDialog(_("陛下"),_("请填写正确的收件人ID"))
        return
    end
    NetManager:getSendPersonalMailPromise(addressee, title, content,self.contacts):done(function(result)
        self:removeFromParent()
        return result
    end)

end
function GameUIAllianceInfo:LoadMembers()
    local layer = self.centent_layer
    local l_size = layer:getContentSize()
    

end
return GameUIAllianceInfo





