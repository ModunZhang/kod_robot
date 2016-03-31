local WidgetPushButton = import(".WidgetPushButton")
local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetUseItems = import(".WidgetUseItems")
local UILib = import("..ui.UILib")

local BUY_AND_USE = 1
local USE = 2
local boxes = {
    city ={"box_buff_1.png","box_buff_1.png"},
    war ={"box_buff_2.png","box_buff_2.png"},
}
local WidgetBuffBox = class("WidgetBuffBox", function ()
    local node = display.newNode()
    node:setNodeEventEnabled(true)
    return node
end)

function WidgetBuffBox:ctor(params)
    local width,height = 136,190
    local buff_category = params.buff_category
    local buff_type = params.buff_type
    self.buff_type = buff_type
    self:setContentSize(cc.size(width,height))
    local buff_btn = WidgetPushButton.new(
        {normal = boxes[buff_category][1],pressed = boxes[buff_category][2]})
        :addTo(self)
        :align(display.CENTER, width/2, height/2+15)
        :onButtonClicked(function ( event )
            WidgetUseItems.new():Create({
                item_name = buff_type.."_1"
            }):AddToCurrentScene()
        end)
    -- buff icon
    local buff_icon = display.newSprite(UILib.buff[buff_type],0,12,{class=cc.FilteredSpriteWithOne})
        :addTo(buff_btn)
    buff_icon:scale(102/math.max(buff_icon:getContentSize().width,buff_icon:getContentSize().height))
    self.buff_icon = buff_icon
    local buff_active = display.newSprite("buff_active_123x125.png"):addTo(self)
        :align(display.CENTER, width/2, height/2+27)
    local seq_1 = transition.sequence{
        cc.RotateTo:create(2, -180),
        cc.RotateTo:create(2, -360)
    }
    buff_active:runAction(cc.RepeatForever:create(seq_1))
    self.buff_active = buff_active
    -- 信息框
    local info_bg = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(130,30),cc.rect(15,10,136,64))
        :align(display.CENTER, width/2, 15)
        :addTo(self)
    self.info_label = UIKit:ttfLabel(
        {
            size = 20,
        }):align(display.CENTER, info_bg:getContentSize().width/2 ,info_bg:getContentSize().height/2)
        :addTo(info_bg)
    self:SetActived(UtilsForItem:IsItemEventActive(User, buff_type))
end
function WidgetBuffBox:SetActived(isActive, time)
    if not isActive then
        local my_filter = filter
        local filters = my_filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1})
        self.buff_icon:setFilter(filters)
        self.buff_active:hide()
    else
        self.buff_icon:clearFilter()
        self.buff_active:show()
    end
    self:SetInfo(isActive and GameUtils:formatTimeStyle1(time) or _("未激活"),UIKit:hex2c4b(isActive and 0x007c23 or 0x403c2f))
end
function WidgetBuffBox:SetInfo(info,color)
    self.info_label:setString(info)
    if color then
        self.info_label:setColor(color)
    end
    return self
end
function WidgetBuffBox:onEnter()
    self:scheduleAt(function()
        self:SetActived(UtilsForItem:IsItemEventActive(User, self.buff_type))
    end)
end
return WidgetBuffBox














