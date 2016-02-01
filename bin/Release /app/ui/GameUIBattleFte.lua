local promise = import("..utils.promise")
local WidgetMaskFilter = import("..widget.WidgetMaskFilter")
local GameUIBattleFte = UIKit:createUIClass('GameUIBattleFte', "UIAutoClose")

function GameUIBattleFte:ctor(woldRect, title, text)
    GameUIBattleFte.super.ctor(self, {color = UIKit:hex2c4b(0x00ffffff)})
    self.pp = promise.new()
    self.__type  = UIKit.UITYPE.BACKGROUND
    local w = 640

    self:addTouchAbleChild(display.newNode())
    local mask = WidgetMaskFilter.new():addTo(self):pos(display.cx, display.cy)
    local leftp = self:convertToNodeSpace(woldRect)
    local rightp = self:convertToNodeSpace(cc.p(woldRect.x + woldRect.width, woldRect.y + woldRect.height))
    local x,y,w,h = leftp.x, leftp.y, rightp.x - leftp.x, rightp.y - leftp.y
    mask:FocusOnRect(cc.rect(x,y,w,h))
    display.newScale9Sprite("pve_mark_box.png"):addTo(self):pos(x + w/2,y + h/2):size(w + 34, h + 34)

    self:DisableAutoClose(true)

    local content = UIKit:ttfLabel({
        size = 22,
        color= 0xffedae,
        dimensions = cc.size(400,100),
        text = text
    })
    local size = content:getContentSize()
    local header_sp = display.newSprite("tips_bg_header_640x140.png"):align(display.TOP_CENTER, display.cx - 15, leftp.y - 30):addTo(self,2)
    self.clipeNode = display.newClippingRegionNode(cc.rect(0,0,display.width,header_sp:getPositionY()-18)):addTo(self,1)
    local h = size.height + 150
    self.content_sp = display.newScale9Sprite("tips_bg_content_1_640x140.png", display.cx, header_sp:getPositionY()-h, cc.size(w, h)):addTo(self.clipeNode):align(display.BOTTOM_CENTER)
    UIKit:ttfLabel({
        size = 30,
        color= 0xffedae,
        text = title
    }):align(display.CENTER, w/2, h - 50):addTo(self.content_sp)
    content:align(display.TOP_CENTER, w/2, h - 80):addTo(self.content_sp)
    
    self:performWithDelay(function()
        display.newSprite("fte_next_arrow.png"):addTo(self.content_sp)
            :pos(self.content_sp:getContentSize().width/2, 40):rotation(90):runAction(cc.RepeatForever:create(
            transition.sequence{
                cc.MoveBy:create(0.5, cc.p(0,-10)),
                cc.MoveBy:create(0.5, cc.p(0,10))
            }))
        self:DisableAutoClose(false)
    end, 1)
end
function GameUIBattleFte:PromiseOfFte()
    return self.pp
end
function GameUIBattleFte:onExit()
    local pp = self.pp
    GameUIBattleFte.super.onExit(self)
    pp:resolve()
end

return GameUIBattleFte











