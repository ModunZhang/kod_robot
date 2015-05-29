--
-- Author: Kenny Dai
-- Date: 2015-04-23 14:37:13
--
local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetPushButton = import(".WidgetPushButton")
local UILib = import("..ui.UILib")
local Localize = import("..utils.Localize")
local WidgetSelectPlayerHeadIcon = class("WidgetSelectPlayerHeadIcon", WidgetPopDialog)

function WidgetSelectPlayerHeadIcon:ctor()
    WidgetSelectPlayerHeadIcon.super.ctor(self,644,_("选择头像"))
end

function WidgetSelectPlayerHeadIcon:onEnter()
    WidgetSelectPlayerHeadIcon.super.onEnter(self)
    local body = self:GetBody()
    local size = body:getContentSize()

    local list,list_node = UIKit:commonListView_1({
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0, 0,548,570),
    })
    list_node:addTo(body):align(display.BOTTOM_CENTER, size.width/2,20)
    self.head_icon_list = list
    for key=1,11 do
        self:AddIconOption(key,UILib.player_icon[key])
    end

    self.head_icon_list:reload()
end
function WidgetSelectPlayerHeadIcon:onExit()
    WidgetSelectPlayerHeadIcon.super.onExit(self)
end

function WidgetSelectPlayerHeadIcon:AddIconOption(icon_key,icon)
    local list =  self.head_icon_list
    local item =list:newItem()
    local item_width,item_height = 548, 116
    item:setItemSize(item_width,item_height)
    local body_image = list.which_bg and "back_ground_548x40_1.png" or "back_ground_548x40_2.png"
    local content = display.newScale9Sprite(body_image,0,0,cc.size(item_width,item_height),cc.rect(10,10,528,20))
    list.which_bg = not list.which_bg

    UIKit:GetPlayerCommonIcon(icon_key):addTo(content)
        :pos(60,item_height/2):scale(0.82)

    UIKit:ttfLabel({
        text = Localize.player_icon[icon_key],
        size = 24,
        color = 0x403c2f
    }):align(display.LEFT_CENTER,130,84)
        :addTo(content)
    UIKit:ttfLabel({
        text = Localize.player_icon_unlock[icon_key],
        size = 20,
        color = 0x5c553f,
        dimensions = cc.size(200,0)
    }):align(display.LEFT_CENTER,130,40)
        :addTo(content)

    if User:Icon() ~= icon_key then
        WidgetPushButton.new(
            {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"},
            {scale9 = false},
            {
                disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
            }
        ):setButtonLabel(UIKit:ttfLabel({
            text = _("选择"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                	NetManager:getSetPlayerIconPromise(icon_key)
                	self:LeftButtonClicked()
                end
            end):addTo(content):align(display.RIGHT_CENTER, item_width-10,40)
            :setButtonEnabled(self:CheckUnlock(icon_key))
    else
        UIKit:ttfLabel({
            text = _("已装备"),
            size = 24,
            color = 0x403c2f,
        }):addTo(content):align(display.RIGHT_CENTER,item_width-50,58)
    end


    item:addContent(content)
    list:addItem(item)
end

function WidgetSelectPlayerHeadIcon:CheckUnlock(icon_key)
    -- 前六个默认解锁
    if icon_key < 7 then
        return true
    end
    if icon_key == 7 then -- 刺客
        return User:Kill() >= 1000000
    elseif icon_key == 8 then -- 将军
        return User:Power() >= 1000000
    elseif icon_key == 9 then -- 术士
        return User:GetVipLevel() == 10
    elseif icon_key == 10 then -- 贵妇
        return City:GetFirstBuildingByType("keep"):GetLevel() >= 40
    elseif icon_key == 11 then -- 旧神
        return User:GetPVEDatabase():GetMapByIndex(3):IsComplete()
    end
end

return WidgetSelectPlayerHeadIcon

