local UILib = import(".UILib")
local Localize = import("..utils.Localize")
local window = import("..utils.window")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameUIPveSweep = class("GameUIPveSweep", WidgetPopDialog)

local titles = {
    _("战斗胜利"),
    _("龙在战斗中胜利"),
    _("一个兵种击败敌军"),
}


function GameUIPveSweep:ctor()
    GameUIPveSweep.super.ctor(self,654,_("扫荡"),window.top - 150)
end
function GameUIPveSweep:onEnter()
    GameUIPveSweep.super.onEnter(self)
    local size = self:GetBody():getContentSize()
    local bg = display.newScale9Sprite("back_ground_398x97.png",size.width/2,size.height-60,cc.size(556,58),cc.rect(10,10,378,77)):addTo(self:GetBody())
    display.newSprite("sweep_128x128.png"):addTo(bg):scale(0.35):pos(35, 58/2)

    UIKit:ttfLabel({
        text = _("当前数量"),
        size = 22,
        color = 0x615b44,
    }):addTo(bg):align(display.LEFT_CENTER,60,58/2)



    local list,list_node = UIKit:commonListView_1({
        viewRect = cc.rect(0, 0, 550, 400),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    })
    list.touchNode_:setTouchEnabled(false)
    list_node:addTo(self:GetBody()):pos(20, size.height - 530)
    for i = 1, 5 do
        local item = list:newItem()
        local content = self:GetListItem(i,titles[i])
        item:addContent(content)
        item:setItemSize(600,80)
        list:addItem(item)
    end
    list:reload()


    self:CreateSweepButton("-5"):addTo(self:GetBody()):align(display.CENTER, 100,size.height - 580)
    self:CreateSweepButton("-1"):addTo(self:GetBody()):align(display.CENTER, size.width - 100,size.height - 580)
end
function GameUIPveSweep:CreateSweepButton(title)
    local s = cc.ui.UIPushButton.new(
        {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(UIKit:ttfLabel({
        text = _("扫荡") ,
        size = 20,
        color = 0xffedae,
        shadow = true
    })):setButtonLabelOffset(0, 15)

    local num_bg = display.newSprite("alliance_title_gem_bg_154x20.png"):addTo(s):align(display.CENTER, 0, -10):scale(0.8)
    local size = num_bg:getContentSize()
    display.newSprite("sweep_128x128.png"):addTo(num_bg):align(display.CENTER, 20, size.height/2):scale(0.4)
    UIKit:ttfLabel({
        text = title,
        size = 18,
        color = 0xffd200,
    }):align(display.CENTER, size.width/2, size.height/2):addTo(num_bg)
    return s
end
function GameUIPveSweep:GetListItem(index)
    local bg = display.newScale9Sprite(string.format("back_ground_548x40_%d.png", index % 2 == 0 and 1 or 2)):size(600,80)
    UIKit:ttfLabel({
        -- text = title,
        size = 20,
        color = 0x403c2f,
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
    }):addTo(bg):align(display.LEFT_CENTER,30,20)

    -- local ax = bg:getContentSize().width - 50
    -- for i = 1, 3 do
    --     display.newSprite(index >= i and "alliance_shire_star_60x58_1.png" or "alliance_shire_star_60x58_0.png")
    --         :addTo(bg):pos(ax - (i-1) * 35, 20):scale(0.6)
    -- end
    return bg
end


return GameUIPveSweep









