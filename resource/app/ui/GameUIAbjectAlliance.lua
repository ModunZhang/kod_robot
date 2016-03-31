--
-- Author: kenny Dai
-- Date: 2016-01-25 14:51:15
--
local GameUIAbjectAlliance = UIKit:createUIClass("GameUIAbjectAlliance","GameUIWithCommonHeader")
local window = import("..utils.window")
local UIListView = import(".UIListView")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")

function GameUIAbjectAlliance:ctor(city)
    GameUIAbjectAlliance.super.ctor(self,city, _("驱逐联盟"))

end

function GameUIAbjectAlliance:onEnter()
    GameUIAbjectAlliance.super.onEnter(self)
    local view = self:GetView()
    local abject_icon = display.newSprite("icon_abject_128x128.png"):align(display.LEFT_TOP, window.left + 50,window.top_bottom):addTo(view)
    local title_bar =  display.newScale9Sprite("title_blue_430x30.png",0,0, cc.size(428,30), cc.rect(10,10,410,10))
        :addTo(view)
        :align(display.LEFT_TOP, abject_icon:getPositionX() + abject_icon:getContentSize().width + 5, abject_icon:getPositionY() - 4)
    local title_label = UIKit:ttfLabel({
        text = "驱逐",
        size = 22,
        color= 0xffedae,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):addTo(title_bar):align(display.LEFT_CENTER,15, 15)


    local period_title_label = UIKit:ttfLabel({
        text = "准备中",
        size = 22,
        color= 0x615b44,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):addTo(view):align(display.LEFT_CENTER,title_bar:getPositionX() + 15, title_bar:getPositionY() - 70)

    local period_label = UIKit:ttfLabel({
        text = "00:00:00",
        size = 22,
        color= 0x7e0000,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):addTo(view):align(display.LEFT_CENTER,period_title_label:getPositionX() + period_title_label:getContentSize().width + 10, period_title_label:getPositionY())


    local content = WidgetUIBackGround.new({width = 556,height= 164},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :align(display.CENTER_TOP,window.cx,abject_icon:getPositionY() - abject_icon:getContentSize().height - 10):addTo(view)
    local  listview = UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(10,10, 536, 144),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(content)
    local item = listview:newItem()
    local content_label = UIKit:ttfLabel({
        text = _("占领王座联盟的国王可以选择本服务器的任意联盟进行驱逐。被驱逐的联盟会强制迁移出原来的位置。此外，被驱逐联盟的所有成员的粮食储备，超过暗仓的部分将全部丢失。"),
        size = 22,
        color= 0x615b44,
        align = cc.TEXT_ALIGNMENT_LEFT,
        dimensions = cc.size(500,0)
    })

    item:addContent(content_label)
    item:setItemSize(content_label:getContentSize().width, content_label:getContentSize().height)
    listview:addItem(item)
    listview:reload()

    local editbox = cc.ui.UIInput.new({
        UIInputType = 1,
        image = "input_box.png",
        size = cc.size(544,48),
    })
    editbox:setFont(UIKit:getEditBoxFont(),18)
    editbox:setFontColor(UIKit:hex2c3b(0xccc49e))
    editbox:setMaxLength(3)
    editbox:setPlaceHolder(_("请填写想要驱逐联盟的TAG"))
    editbox:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    editbox:align(display.CENTER_TOP,window.cx,content:getPositionY() - content:getContentSize().height - 20):addTo(view)

    
    local abject_btn = WidgetPushButton.new({normal = "red_btn_up_186x66.png",pressed = "red_btn_down_186x66.png",disabled = "grey_btn_186x66.png"})
        :setButtonLabel(UIKit:ttfLabel({text = _("驱逐"),
            size = 20,
            shadow = true,
            color = 0xfff3c7
        })):align(display.CENTER,window.cx,editbox:getPositionY() - editbox:getCascadeBoundingBox().size.height - 60):addTo(view)
        :onButtonClicked(function(event)
            end)
        :setButtonEnabled(false)
    UIKit:ttfLabel({
        text = _("只有成为国王之后才能使用驱逐"),
        size = 20,
        color= 0x403c2f,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):addTo(view):align(display.CENTER,window.cx, abject_btn:getPositionY() - abject_btn:getCascadeBoundingBox().size.height/2 - 30)

end

function GameUIAbjectAlliance:onExit()
    GameUIAbjectAlliance.super.onExit(self)
end

return GameUIAbjectAlliance




