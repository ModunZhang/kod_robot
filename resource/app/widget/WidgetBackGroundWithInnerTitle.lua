local WidgetUIBackGround = import(".WidgetUIBackGround")
local TITLE_COLOR = {
    "title_blue_554x34.png",
    "title_red_556x34.png",
}
local WidgetBackGroundWithInnerTitle = class("WidgetBackGroundWithInnerTitle", function(height, title ,color)
    local back_ground = WidgetUIBackGround.new({height=height,width=568},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
        :align(display.CENTER)
    local size = back_ground:getContentSize()
    local title_blue = cc.ui.UIImage.new(TITLE_COLOR[color])
        :addTo(back_ground, 2)
        :align(display.TOP_CENTER, size.width / 2, height-6)

    back_ground.title_label = UIKit:ttfLabel({
        text = title,
        size = 22,
        color = 0xffedae
    }):addTo(title_blue, 2):align(display.CENTER, title_blue:getContentSize().width/2, title_blue:getContentSize().height/2)
    return back_ground
end)
WidgetBackGroundWithInnerTitle.TITLE_COLOR = {
    BLUE =1,
    RED =2,
}
function WidgetBackGroundWithInnerTitle:SetTitle(title)
    self.title_label:setString(title)
end


return WidgetBackGroundWithInnerTitle


