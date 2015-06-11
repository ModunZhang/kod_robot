local WidgetUIBackGround = import(".WidgetUIBackGround")
local WidgetWithBlueTitle = class("WidgetWithBlueTitle", function(height, title)
    local back_ground = WidgetUIBackGround.new({height=height,isFrame="yes"}):align(display.CENTER)
    local size = back_ground:getContentSize()
    local title_blue = cc.ui.UIImage.new("title_blue_586x34.png")
        :addTo(back_ground, 2)
        :align(display.CENTER, size.width / 2, height - 40)

    back_ground.title_label = UIKit:ttfLabel({
        text = title,
        size = 24,
        color = 0xffedae
    }):addTo(title_blue, 2):align(display.CENTER, title_blue:getContentSize().width/2, title_blue:getContentSize().height/2)
    return back_ground
end)
function WidgetWithBlueTitle:SetTitle(title)
	self.title_label:setString(title)
end


return WidgetWithBlueTitle

