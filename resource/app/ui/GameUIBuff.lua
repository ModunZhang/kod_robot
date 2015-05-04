local window = import("..utils.window")
local WidgetBackGroundWithInnerTitle = import("..widget.WidgetBackGroundWithInnerTitle")
local WidgetBuffBox = import("..widget.WidgetBuffBox")
local GameUIBuff = UIKit:createUIClass('GameUIBuff', "GameUIWithCommonHeader")

function GameUIBuff:ctor(city)
    GameUIBuff.super.ctor(self, city, _("增益"))
end

function GameUIBuff:OnMoveInStage()
    GameUIBuff.super.OnMoveInStage(self)
    local list_view ,listnode=  UIKit:commonListView({
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(0, 0, 568, 845),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    listnode:addTo(self:GetView()):align(display.BOTTOM_CENTER,window.cx,window.bottom+40)
    self.list = list_view
    self:CityBuff()
    self:WarBuff()
    list_view:reload()
end
function GameUIBuff:CityBuff()
    local content = self:CreateItem(_("城市增益效果"),WidgetBackGroundWithInnerTitle.TITLE_COLOR.BLUE)
    self:InitBuffs(ItemManager:GetAllCityBuffTypes(),content,"city")

end
function GameUIBuff:WarBuff()
    local content = self:CreateItem(_("战争增益效果"),WidgetBackGroundWithInnerTitle.TITLE_COLOR.RED)
    self:InitBuffs(ItemManager:GetAllWarBuffTypes(),content,"war")
end
function GameUIBuff:CreateItem(title,title_color)
    local list = self.list
    local item = list:newItem()
    local item_width,item_height = 568,650
    item:setItemSize(item_width,item_height)
    local content = WidgetBackGroundWithInnerTitle.new(650,title,title_color)
    item:addContent(content)
    list:addItem(item)
    return content
end
function GameUIBuff:InitBuffs(buffs,container,category)
    local total_width = 568
    local edge_distance = 19
    local buff_width ,buff_height= 136,190
    local margin_x = (total_width - 2*edge_distance - 3*buff_width)/2
    local origin_x = edge_distance + buff_width/2
    local origin_y = 510
    local gap_y = buff_height + 10
    for i,v in ipairs(buffs) do
        WidgetBuffBox.new({
            buff_category = category,
            buff_type = v,
        }):addTo(container)
            :align(display.CENTER,origin_x + ((i-1)%3)*(margin_x+buff_width),origin_y - math.floor((i-1)/3)*gap_y)
    end
end

function GameUIBuff:onExit()
    GameUIBuff.super.onExit(self)
end

return GameUIBuff





