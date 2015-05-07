local WidgetUIBackGround = import(".WidgetUIBackGround")
local TITLE_COLOR = {
     "title_blue_600x56.png",
     "title_green_600x52.png",
     "title_yellow_600x52.png",
     "title_red_600x52.png",
     "title_purple_600x52.png",
}
local WidgetBackgroundWithTopTitle = class("WidgetBackgroundWithTopTitle", function(height, title ,color)
    local back_ground = WidgetUIBackGround.new({height=height}):align(display.CENTER)
    local size = back_ground:getContentSize()
    local title_blue = cc.ui.UIImage.new(TITLE_COLOR[color])
        :addTo(back_ground, 2)
        :align(display.CENTER, size.width / 2, height+12)

    back_ground.title_label = UIKit:ttfLabel({
        text = title,
        size = 24,
        color = 0xffedae
    }):addTo(title_blue, 2):align(display.CENTER, title_blue:getContentSize().width/2, title_blue:getContentSize().height/2)
    return back_ground
end)
WidgetBackgroundWithTopTitle.TITLE_COLOR = {
    BLUE =1,
    GREEN =2,
    YELLOW =3,
    RED =4,
    PURPLE =5,
}
function WidgetBackgroundWithTopTitle:SetTitle(title)
    if self.title_label:getString() ~= title then
        self.title_label:setString(title)
    end
end


return WidgetBackgroundWithTopTitle

