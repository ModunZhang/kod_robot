local UILib = import(".UILib")
local Localize = import("..utils.Localize")
local window = import("..utils.window")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameUIPveSelect = class("GameUIPveSelect", WidgetPopDialog)

function GameUIPveSelect:ctor()
    GameUIPveSelect.super.ctor(self,700,_("选择关卡"),window.top - 150)
end
function GameUIPveSelect:onEnter()
    GameUIPveSelect.super.onEnter(self)
    local size = self:GetBody():getContentSize()

    local list,list_node = UIKit:commonListView_1({
        viewRect = cc.rect(0, 0, 550, 600),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    })
    list_node:addTo(self:GetBody()):pos(20, size.height - 660)



    for i = 1, 20 do
        local item = list:newItem()
        local content = self:GetListItem(i)
        item:addContent(content)
        item:setItemSize(600,100)
        list:addItem(item)
    end
    list:reload()
end
function GameUIPveSelect:GetListItem(index)
    local bg = display.newScale9Sprite(string.format("back_ground_548x40_%d.png", index % 2 == 0 and 1 or 2)):size(600,100)
    UIKit:ttfLabel({
        text = _("北方塔院"),
        size = 24,
        color = 0x403c2f,
    }):addTo(bg):align(display.LEFT_CENTER,60,100*3/4)

    local num_bg = display.newSprite("back_ground_96x30.png"):addTo(bg):align(display.LEFT_CENTER,60,100*1/3)
    local size = num_bg:getContentSize()
    UIKit:ttfLabel({
        text = _("22/60"),
        size = 20,
        color = 0xffedae,
    }):addTo(num_bg):align(display.CENTER, size.width/2, size.height/2)
    display.newSprite("alliance_shire_star_60x58_1.png"):addTo(bg):pos(60,100*1/3):scale(0.7)


    UIKit:ttfLabel({
        text = _("通关"),
        size = 20,
        color = 0x007c23,
    }):addTo(bg):align(display.CENTER,548 - 60,100*3/4)

    cc.ui.UIPushButton.new(
        {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"}
    ):setButtonLabel(UIKit:ttfLabel({
        text = _("传送") ,
        size = 24,
        color = 0xffedae,
        shadow = true
    })):addTo(bg):align(display.CENTER,548 - 60,100*1/3)

    

    return bg
end


return GameUIPveSelect







