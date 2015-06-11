local UIListView = import(".UIListView")
local UIAutoClose = import(".UIAutoClose")

local FullScreenPopDialogUI = class("FullScreenPopDialogUI", UIAutoClose)

function FullScreenPopDialogUI:ctor(listener,user_data)
    self.__user_data__ = user_data or os.time()
    FullScreenPopDialogUI.super.ctor(self,{type=UIKit.UITYPE.MESSAGEDIALOG})
    self:Init(listener)
end

function FullScreenPopDialogUI:Init(listener)
    -- bg
    local bg = display.newSprite("back_ground_608x350.png", display.cx, display.top - 480)
    self:addTouchAbleChild(bg)
    local size = bg:getContentSize()
    -- title bg
    local title_bg =display.newSprite("title_blue_600x56.png", size.width/2, size.height+10):addTo(bg)
    -- title label
    self.title = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "title",
        font = UIKit:getFontFilePath(),
        size = 24,
        color = UIKit:hex2c3b(0xffedae)
    }):align(display.CENTER,title_bg:getContentSize().width/2,title_bg:getContentSize().height/2):addTo(title_bg)
    -- npc image
    display.newSprite("Npc.png"):align(display.LEFT_BOTTOM, -50, -14):addTo(bg)
    -- 对话框 bg
    local tip_bg = display.newSprite("back_ground_342x228.png", 406,210):addTo(bg)
    self.tip_bg= tip_bg
    -- 称谓label
    cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("主人").."!",
        font = UIKit:getFontFilePath(),
        size = 24,
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.LEFT_TOP,14,210):addTo(tip_bg)

    -- close button
    self.close_btn = cc.ui.UIPushButton.new({normal = "X_1.png",pressed = "X_2.png"})
        :align(display.CENTER, size.width-30, size.height+16):addTo(bg)

    self.close_btn:onButtonClicked(function(event)
        if event.name == "CLICKED_EVENT" then
            self:removeFromParent()
            if listener then
                listener()
            end
        end
    end)

    -- 默认加入ok button
    self:CreateOKButton()
end

function FullScreenPopDialogUI:SetTitle(title)
    self.title:setString(title)
    return self
end

function FullScreenPopDialogUI:SetPopMessage(message)
    local message_label = UIKit:ttfLabel({
        text = message,
        size = 20,
        color = 0x403c2f,
        align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
        dimensions = cc.size(310, 0),
    })
    local w,h =  message_label:getContentSize().width,message_label:getContentSize().height
    -- 提示内容
    local  listview = UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(14,10, w, 170),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(self.tip_bg)
    local item = listview:newItem()
    item:setItemSize(w,h)
    item:addContent(message_label)
    listview:addItem(item)
    listview:reload()
    return self
end

function FullScreenPopDialogUI:CreateOKButton(params)
    if self.ok_button then
        self.ok_button:removeFromParent(true)
    end
    local params = params or {}
    local listener,btn_name = params.listener,params.btn_name
    local btn_images = params.btn_images
    local name = btn_name or _("确定")
    local ok_button = cc.ui.UIPushButton.new(btn_images or {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({text =name, size = 24, color = 0xffedae,shadow=true}))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:removeFromParent()
                if listener then
                    listener()
                end
            end
        end):align(display.CENTER, display.cx+200, display.top-610):addTo(self)
    self.ok_button = ok_button
    return self
end

function FullScreenPopDialogUI:CreateCancelButton(params)
    local params = params or {}
    local listener,btn_name = params.listener,params.btn_name
    local name = btn_name or _("取消")
    local ok_button = cc.ui.UIPushButton.new({normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({text =name, size = 24, color = 0xffedae,shadow=true}))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:removeFromParent()
                if listener then
                    listener()
                end
            end
        end):align(display.CENTER, display.cx+6, display.top-610):addTo(self)
    return self
end

function FullScreenPopDialogUI:CreateNeeds(params)
    local icon = params.icon
    local value = params.value
    local color = params.color
    local image_icon = icon or "gem_icon_62x61.png"
    local icon_image = display.newScale9Sprite(image_icon, display.cx-30, display.top-610):addTo(self)
    icon_image:setScale(30/icon_image:getContentSize().height)
    self.needs_label = UIKit:ttfLabel({
        text = value.."",
        size = 24,
        color = color or 0x403c2f
    }):align(display.LEFT_CENTER,display.cx+10,display.top-610):addTo(self)
    return self
end
function FullScreenPopDialogUI:SetNeedsValue(value)
    if self.needs_label then
        self.needs_label:setString(value)
    end
    return self
end
function FullScreenPopDialogUI:VisibleXButton(visible)
    self.close_btn:setVisible(visible)
    return self
end

function FullScreenPopDialogUI:GetUserData()
    return self.__user_data__
end


function FullScreenPopDialogUI:onCleanup()
    print("onCleanup->",self.__cname)
    if UIKit:isMessageDialogShow(self) then
         UIKit:removeMesssageDialog(self)
    end
end
return FullScreenPopDialogUI















