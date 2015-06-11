local Enum = import("..utils.Enum")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPopDialog = import("..widget.WidgetPopDialog")

local GameUIWriteMail = class("GameUIWriteMail",WidgetPopDialog)
GameUIWriteMail.SEND_TYPE = Enum("PERSONAL_MAIL","ALLIANCE_MAIL")

local PERSONAL_MAIL = GameUIWriteMail.SEND_TYPE.PERSONAL_MAIL
local ALLIANCE_MAIL = GameUIWriteMail.SEND_TYPE.ALLIANCE_MAIL

function GameUIWriteMail:ctor(send_type,contacts)
    GameUIWriteMail.super.ctor(self,768,_("发邮件"))
    self:DisableAutoClose()
    self.send_type = send_type
    self.contacts = contacts

    -- bg
    local write_mail = self.body
    local r_size = write_mail:getContentSize()

    -- 收件人
    self.addressee_title_label = UIKit:ttfLabel(
        {
            text = contacts and _("收件人")..":      "..contacts.name,
            size = 20,
            color = 0x615b44
        }):align(display.LEFT_CENTER,58, r_size.height-70)
        :addTo(write_mail)
    -- 主题
    local subject_title_label = cc.ui.UILabel.new(
        {cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("主题："),
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.RIGHT_CENTER,120, r_size.height-120)
        :addTo(write_mail)

    self.editbox_subject = cc.ui.UIInput.new({
        UIInputType = 1,
        image = "input_box.png",
        size = cc.size(422,40),
        font = UIKit:getFontFilePath(),
    })
    local editbox_subject = self.editbox_subject
    editbox_subject:setPlaceHolder(string.format(_("最多可输入%d字符"),140))
    editbox_subject:setMaxLength(137)
    editbox_subject:setFont(UIKit:getEditBoxFont(),22)
    editbox_subject:setFontColor(cc.c3b(0,0,0))
    editbox_subject:setPlaceholderFontColor(cc.c3b(204,196,158))
    editbox_subject:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    editbox_subject:align(display.LEFT_TOP,150, r_size.height-100):addTo(write_mail)

    -- 分割线
    display.newScale9Sprite("dividing_line.png",r_size.width/2, r_size.height-160,cc.size(594,2),cc.rect(10,2,382,2)):addTo(write_mail)
    -- 内容
    cc.ui.UILabel.new(
        {cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("内容："),
            font = UIKit:getFontFilePath(),
            size = 20,
            dimensions = cc.size(410,24),
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.LEFT_CENTER,58,r_size.height-180)
        :addTo(write_mail)
    -- 回复的邮件内容
    self.textView = ccui.UITextView:create(cc.size(580,472),display.newScale9Sprite("background_88x42.png"))
    local textView = self.textView
    textView:addTo(write_mail):align(display.CENTER_BOTTOM,r_size.width/2,76)
    textView:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    textView:setFont(UIKit:getEditBoxFont(), 24)
    textView:setMaxLength(1000)

    textView:setFontColor(cc.c3b(0,0,0))

    -- 发送按钮
    local send_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("发送"),
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)})

    send_label:enableShadow()
    self.send_button = WidgetPushButton.new(
        {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(send_label)
        :addTo(write_mail):align(display.CENTER, write_mail:getContentSize().width-120, 40)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:SendMail(contacts and contacts.id, self.editbox_subject:getText(), self.textView:getText())
            end
        end)
    textView:setRectTrackedNode(self.send_button)

end
function GameUIWriteMail:SendMail(addressee,title,content)
    if not title or string.trim(title)=="" then
        UIKit:showMessageDialog(_("主人"),_("请填写邮件主题"))
        return
    elseif not content or string.trim(content)=="" then
        UIKit:showMessageDialog(_("主人"),_("请填写邮件内容"))
        return
    end
    if self.send_type == PERSONAL_MAIL then
        if not addressee or string.trim(addressee)=="" then
            UIKit:showMessageDialog(_("主人"),_("请填写正确的收件人ID"))
            return
        end
        NetManager:getSendPersonalMailPromise(addressee, title, content,self.contacts):done(function(result)
            self:removeFromParent()
            return result
        end)
    elseif self.send_type == ALLIANCE_MAIL then
        NetManager:getSendAllianceMailPromise(title, content):done(function(result)
            self:removeFromParent()
        end)
    end
end


-- -- 收件人ID
function GameUIWriteMail:SetAddressee( addressee )
    self.addressee_title_label:setString( _("收件人")..":      "..addressee)
    return self
end
-- 邮件主题
function GameUIWriteMail:SetSubject( subject )
    self.editbox_subject:setText(subject)
    return self
end
-- 邮件内容
function GameUIWriteMail:SetContent( content )
    self.textView:setText(content)
    return self
end

return GameUIWriteMail








   







