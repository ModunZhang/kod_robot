local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")

local WidgetPopDialog = UIKit:createUIClass("WidgetPopDialog", "UIAutoClose")

function WidgetPopDialog:ctor(height,title_text,y,title_bg)
    WidgetPopDialog.super.ctor(self)
    self.body = WidgetUIBackGround.new({height=height,isFrame="no"}):align(display.TOP_CENTER,display.cx,y or display.top-140)
    local body = self.body
    self:addTouchAbleChild(body)
    local rb_size = body:getContentSize()
    local title = display.newSprite(title_bg or "title_blue_600x52.png"):align(display.CENTER, rb_size.width/2, rb_size.height+10)
        :addTo(body)
    self.title_label = UIKit:ttfLabel({
        text = title_text,
        size = 22,
        color = 0xffedae,
    }):align(display.CENTER, title:getContentSize().width/2, title:getContentSize().height/2+2)
        :addTo(title)
    -- close button
    self.close_btn = WidgetPushButton.new({normal = "X_1.png",pressed = "X_2.png"})
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:LeftButtonClicked()
            end
        end):align(display.CENTER, rb_size.width-34,rb_size.height+14):addTo(body)
end

function WidgetPopDialog:GetBody()
    return self.body
end
function WidgetPopDialog:DisableCloseBtn()
    self.close_btn:setVisible(false)
    return self
end
function WidgetPopDialog:SetTitle(title)
    self.title_label:setString(title)
    return self
end
function WidgetPopDialog:onEnter()
    WidgetPopDialog.super.onEnter(self)
end
function WidgetPopDialog:onExit()
    WidgetPopDialog.super.onExit(self)
end
return WidgetPopDialog

