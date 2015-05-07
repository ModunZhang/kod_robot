local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetUIBackGround = import(".WidgetUIBackGround")
local WidgetPushButton = import(".WidgetPushButton")

local WidgetBuyBuildingQueue = class("WidgetBuyBuildingQueue", WidgetPopDialog)
function WidgetBuyBuildingQueue:ctor()
    WidgetBuyBuildingQueue.super.ctor(self,310,_("购买建造队列"),display.top - 300)
    local body = self.body
    local size = body:getContentSize()
    local width,height = size.width,size.height

    self:CreateBuyItem():align(display.TOP_CENTER,width/2,height-20):addTo(body)
    self:CreateBuyItem():align(display.BOTTOM_CENTER,width/2,20):addTo(body)
end

function WidgetBuyBuildingQueue:CreateBuyItem()
    local body = self.body
    local size = body:getContentSize()
    local width,height = size.width,size.height
    local item = WidgetUIBackGround.new({width = 580,height=128},WidgetUIBackGround.STYLE_TYPE.STYLE_4)
    local box = display.newSprite("box_blue_138x138.png"):addTo(item):align(display.LEFT_CENTER,-10,item:getContentSize().height/2)
    local icon = cc.ui.UIImage.new("help_64x72.png"):addTo(box):align(display.CENTER, box:getContentSize().width/2, box:getContentSize().height/2)
    local price_bg = display.newSprite("vip_bg_2.png"):addTo(box):align(display.BOTTOM_CENTER, box:getContentSize().width/2, 6)
    local gem_icon = display.newSprite("gem_icon_62x61.png"):addTo(price_bg):align(display.CENTER, 20, price_bg:getContentSize().height/2):scale(0.7)
    local price_label = UIKit:ttfLabel({
        text = "998",
        size = 22,
        color = 0xffd200
    }):align(display.LEFT_CENTER,price_bg:getContentSize().width/2-10,price_bg:getContentSize().height/2)
        :addTo(price_bg)

    UIKit:ttfLabel({
        text = "NO. X",
        size = 24,
        color = 0x514d3e
    }):align(display.LEFT_CENTER,140,110)
        :addTo(item)

    UIKit:ttfLabel({
        text = "首冲￥99.99，永久赠送1条建筑队列",
        size = 20,
        color = 0x615b44,
        dimensions = cc.size(200,60)
    }):align(display.LEFT_TOP,140,70)
        :addTo(item)

    WidgetPushButton.new(
        {normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"}
        ,{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })
        :addTo(item)
        :align(display.CENTER, item:getContentSize().width - 80, 40)
        :setButtonEnabled(false)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("购买使用"),
            size = 24,
            color = 0xffedae,
            shadow = true
            }))
        :onButtonClicked(function ( event )
            if event.name == "CLICKED_EVENT" then
            end
        end)
    return item
end

return WidgetBuyBuildingQueue

