--
-- Author: Kenny Dai
-- Date: 2015-01-21 10:16:31
--
local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetInfoText = import(".WidgetInfoText")
local WidgetPushButton = import(".WidgetPushButton")
local StarBar = import("..ui.StarBar")
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local UILib = import("..ui.UILib")
local NORMAL = GameDatas.Soldiers.normal

local WidgetSoldierPromoteDetails = class("WidgetSoldierPromoteDetails", WidgetPopDialog)


function WidgetSoldierPromoteDetails:ctor(soldier_type,star,building,can_not_next)
    WidgetSoldierPromoteDetails.super.ctor(self,720,_("兵种晋级"))
    self.soldier_type = soldier_type
    self.star = star
    self.building = building
    self.can_not_next = can_not_next
end

function WidgetSoldierPromoteDetails:onEnter()
    WidgetSoldierPromoteDetails.super.onEnter(self)
    local body = self.body
    local size = body:getContentSize()
    local soldier_type = self.soldier_type
    local star = self.star
    -- 士兵图片
    self:CreateSoldierBox(false):addTo(body):align(display.CENTER, 114, size.height-100)
    self:CreateSoldierBox(true):addTo(body):align(display.CENTER, 494, size.height-100)
    -- line
    display.newScale9Sprite("box_light_70x32.png",size.width/2,size.height-100,cc.size(246,32),cc.rect(10,8,50,16)):addTo(body)

    -- 信息
    local now_config = NORMAL[soldier_type.."_"..star]
    local next_config = NORMAL[soldier_type.."_"..(star+1)]
    local info = {
        {
            {
                text = now_config.infantry,
                size = 22,
                color = 0x403c2f,
            },
            {
                text = _("对步兵的攻击"),
                size = 20,
                color = 0x615b44,
            },
            {
                text = next_config.infantry,
                size = 22,
                color = 0x007c23,
            },
        },
        {
            {
                text = now_config.archer,
                size = 22,
                color = 0x403c2f,
            },
            {
                text = _("对弓手的攻击"),
                size = 20,
                color = 0x615b44,
            },
            {
                text = next_config.archer,
                size = 22,
                color = 0x007c23,
            },
        },
        {
            {
                text = now_config.cavalry,
                size = 22,
                color = 0x403c2f,
            },
            {
                text = _("对骑兵的攻击"),
                size = 20,
                color = 0x615b44,
            },
            {
                text = next_config.cavalry,
                size = 22,
                color = 0x007c23,
            },
        },
        {
            {
                text = now_config.siege,
                size = 22,
                color = 0x403c2f,
            },
            {
                text = _("对攻城器械的攻击"),
                size = 20,
                color = 0x615b44,
            },
            {
                text = next_config.siege,
                size = 22,
                color = 0x007c23,
            },
        },
        {
            {
                text = now_config.wall,
                size = 22,
                color = 0x403c2f,
            },
            {
                text = _("对城墙的攻击"),
                size = 20,
                color = 0x615b44,
            },
            {
                text = next_config.wall,
                size = 22,
                color = 0x007c23,
            },
        },
        {
            {
                text = now_config.hp,
                size = 22,
                color = 0x403c2f,
            },
            {
                text = _("生命值"),
                size = 20,
                color = 0x615b44,
            },
            {
                text = next_config.hp,
                size = 22,
                color = 0x007c23,
            },
        },
        {
            {
                text = now_config.load,
                size = 22,
                color = 0x403c2f,
            },
            {
                text = _("负重"),
                size = 20,
                color = 0x615b44,
            },
            {
                text = next_config.load,
                size = 22,
                color = 0x007c23,
            },
        },
        {
            {
                text = now_config.march,
                size = 22,
                color = 0x403c2f,
            },
            {
                text = _("行军速度"),
                size = 20,
                color = 0x615b44,
            },
            {
                text = next_config.march,
                size = 22,
                color = 0x403c2f,
            },
        },
        {
            {
                text = now_config.citizen,
                size = 22,
                color = 0x403c2f,
            },
            {
                text = _("需要人口"),
                size = 20,
                color = 0x615b44,
            },
            {
                text = next_config.citizen,
                size = 22,
                color = 0x403c2f,
            },
        },
        {
            {
                text = "-"..now_config.consumeFoodPerHour,
                size = 22,
                color = 0x403c2f,
            },
            {
                text = _("维护费费用"),
                size = 20,
                color = 0x615b44,
            },
            {
                text = "-"..next_config.consumeFoodPerHour,
                size = 22,
                color = 0x403c2f,
            },
        },
    }

    WidgetInfoText.new({info = info}):addTo(body):align(display.CENTER_BOTTOM, size.width/2, 100)

    if not self.can_not_next then
        WidgetPushButton.new(
            {normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png"})
            :addTo(body)
            :align(display.CENTER, size.width/2 , 50)
            :setButtonLabel(UIKit:ttfLabel({
                text = _("下一步"),
                size = 24,
                color = 0xfff3c7,
                shadow = true
            }))
            :onButtonClicked(function(event)
                UIKit:newWidgetUI("WidgetPromoteSoldier",soldier_type,self.building:GetType()):AddToCurrentScene()
                self:LeftButtonClicked()
            end)
    end
end
function WidgetSoldierPromoteDetails:CreateSoldierBox(isGray)
    local soldier_type = self.soldier_type
    local star = isGray and self.star +1 or self.star
    local soldier_box = display.newSprite("box_light_148x148.png")
    local blue_bg = display.newSprite(UILib.soldier_color_bg_images[soldier_type], soldier_box:getContentSize().width/2, soldier_box:getContentSize().height/2, {class=cc.FilteredSpriteWithOne}):addTo(soldier_box)

    local soldier_icon = display.newSprite(UILib.soldier_image[soldier_type], soldier_box:getContentSize().width/2, soldier_box:getContentSize().height/2, {class=cc.FilteredSpriteWithOne}):addTo(soldier_box)
    soldier_icon:scale(124/math.max(soldier_icon:getContentSize().width,soldier_icon:getContentSize().height))
    local soldier_star_bg = display.newSprite("tmp_back_ground_102x22.png"):addTo(soldier_icon):align(display.BOTTOM_CENTER,soldier_icon:getContentSize().width/2-16, 0)
    StarBar.new({
        max = 3,
        bg = "Stars_bar_bg.png",
        fill = "Stars_bar_highlight.png",
        num = star,
        margin = 5,
        direction = StarBar.DIRECTION_HORIZONTAL,
        scale = 0.8,
    }):addTo(soldier_star_bg):align(display.CENTER,58, 11)
    if isGray then
        local my_filter = filter
        local filters = my_filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1})
        blue_bg:setFilter(filters)
        soldier_icon:setFilter(filters)
    end

    display.newSprite("box_soldier_128x128.png"):addTo(soldier_box):align(display.CENTER, soldier_box:getContentSize().width/2, soldier_box:getContentSize().height/2)
    return soldier_box
end
function WidgetSoldierPromoteDetails:onExit()
    WidgetSoldierPromoteDetails.super.onExit(self)
end

return WidgetSoldierPromoteDetails







