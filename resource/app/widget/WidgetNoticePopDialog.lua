--
-- Author: Kenny Dai
-- Date: 2016-02-18 10:31:05
--
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")

local WidgetNoticePopDialog = UIKit:createUIClass("WidgetNoticePopDialog", "UIAutoClose")

function WidgetNoticePopDialog:ctor(height,title_text,y,title_bg, param)
    WidgetNoticePopDialog.super.ctor(self, param)
    self.body = display.newScale9Sprite("background_notice_128x128_1.png", 0, 0,cc.size(608,height),cc.rect(30,30,68,68))
            :align(display.TOP_CENTER,display.cx,y or display.top-140)
    local body = self.body
    self:addTouchAbleChild(body)
    local rb_size = body:getContentSize()
    local title = display.newSprite(title_bg or "background_red_558x42.png"):align(display.CENTER, rb_size.width/2, rb_size.height-35)
        :addTo(body)
    self.title_sprite = title
    self.title_label = UIKit:ttfLabel({
        text = title_text,
        size = 24,
        color = 0xfed36c,
    }):align(display.CENTER, title:getContentSize().width/2, title:getContentSize().height/2+2)
        :addTo(title)
    
end

function WidgetNoticePopDialog:GetBody()
    return self.body
end

function WidgetNoticePopDialog:SetTitle(title)
    self.title_label:setString(title)
    return self
end
function WidgetNoticePopDialog:onEnter()
    WidgetNoticePopDialog.super.onEnter(self)
end
function WidgetNoticePopDialog:onExit()
    WidgetNoticePopDialog.super.onExit(self)
end
return WidgetNoticePopDialog

