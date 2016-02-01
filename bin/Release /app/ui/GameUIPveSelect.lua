local UILib = import(".UILib")
local Localize_pve = import("..utils.Localize_pve")
local window = import("..utils.window")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameUIPveSelect = class("GameUIPveSelect", WidgetPopDialog)

function GameUIPveSelect:ctor(level)
    GameUIPveSelect.super.ctor(self,700,_("选择关卡"),window.top - 150)
    self.level = level
end
function GameUIPveSelect:onEnter()
    GameUIPveSelect.super.onEnter(self)
    local size = self:GetBody():getContentSize()

    local list,list_node = UIKit:commonListView_1({
        viewRect = cc.rect(0, 0, 550, 600),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    })
    list_node:addTo(self:GetBody()):pos(20, size.height - 660)



    for i = 1, 24 do
        local item = list:newItem()
        local content = self:GetListItem(i)
        item:addContent(content)
        item:setItemSize(600,100)
        list:addItem(item)
    end
    list:reload()
    local total_len = 24 * 100
    local y = 600 - (total_len - (self.level - 3) * 100)
    y = y < 600 - total_len and 600 - total_len or y
    list:getScrollNode():setPositionY(y > 0 and 0 or y)
end
function GameUIPveSelect:GetListItem(index)
    local bg = display.newScale9Sprite(string.format("back_ground_548x40_%d.png", index % 2 == 0 and 1 or 2)):size(600,100)
    UIKit:ttfLabel({
        text = string.format(_("第%d章"), index),
        size = 24,
        color = 0x403c2f,
    }):addTo(bg):align(display.LEFT_CENTER,60,100*3/4)

    local num_bg = display.newSprite("back_ground_96x30.png"):addTo(bg):align(display.LEFT_CENTER,60,100*1/3)
    local size = num_bg:getContentSize()
    UIKit:ttfLabel({
        text = string.format("%d/%d", User:GetStageStarByIndex(index), User:GetStageTotalStars()),
        size = 20,
        color = 0xffedae,
    }):addTo(num_bg):align(display.CENTER, size.width/2, size.height/2)

    local sbg = display.newSprite("tmp_pve_star_bg.png"):addTo(bg):pos(60,38):scale(0.7)
    local size = sbg:getContentSize()
    display.newSprite("tmp_pve_star.png"):addTo(sbg):pos(size.width/2, size.height/2)

    local txt, color
    if User:IsStageEnabled(index) then
        if User:IsStagePassed(index) then
            txt = _("通关")
            color = 0x007c23
        else
            txt = _("未通关")
            color = 0x7e0000
        end
    else
        txt = _("未解锁")
        color = 0x615b44
    end

    UIKit:ttfLabel({
        text = txt,
        size = 20,
        color = color,
    }):addTo(bg):align(display.CENTER,548 - 60,100*3/4)

    cc.ui.UIPushButton.new(
        {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png", disabled = 'gray_btn_148x58.png'}
    ):setButtonLabel(UIKit:ttfLabel({
        text = _("传送") ,
        size = 24,
        color = 0xffedae,
        shadow = true
    })):addTo(bg):align(display.CENTER,548 - 60,100*1/3)
    :setButtonEnabled(User:IsStageEnabled(index) and self.level ~= index)
    :onButtonClicked(function()
        app:EnterPVEScene(index)
    end)

    

    return bg
end


return GameUIPveSelect







