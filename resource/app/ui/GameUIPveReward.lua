local UILib = import(".UILib")
local Localize = import("..utils.Localize")
local window = import("..utils.window")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameUIPveReward = class("GameUIPveReward", WidgetPopDialog)

function GameUIPveReward:ctor()
    GameUIPveReward.super.ctor(self,500,_("获取奖励"),window.top - 150)
end
function GameUIPveReward:onEnter()
    GameUIPveReward.super.onEnter(self)
    local size = self:GetBody():getContentSize()

    local list,list_node = UIKit:commonListView_1({
        viewRect = cc.rect(0, 0, 550, 400),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    })
    list.touchNode_:setTouchEnabled(false)
    list_node:addTo(self:GetBody()):pos(20, size.height - 460)



    for i = 1, 4 do
        local item = list:newItem()
        local content = self:GetListItem(i)
        item:addContent(content)
        item:setItemSize(600,100)
        list:addItem(item)
    end
    list:reload()
end
function GameUIPveReward:GetListItem(index)
    local bg = display.newScale9Sprite(string.format("back_ground_548x40_%d.png", index % 2 == 0 and 1 or 2)):size(600,100)
    
    display.newSprite("alliance_shire_star_60x58_1.png"):addTo(bg):pos(60,100*3/4):scale(0.7)


    UIKit:ttfLabel({
        text = "14",
        size = 20,
        color = 0x403c2f,
    }):addTo(bg):align(display.CENTER,60,100*1/3)

    cc.ui.UIPushButton.new(
        {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"}
    ):setButtonLabel(UIKit:ttfLabel({
        text = _("领取") ,
        size = 24,
        color = 0xffedae,
        shadow = true
    })):addTo(bg):align(display.CENTER,548 - 60,100*1/2)

    

    return bg
end


return GameUIPveReward







