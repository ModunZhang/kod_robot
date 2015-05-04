local WidgetWithBlueTitle = import(".WidgetWithBlueTitle")
local WidgetProgress = import(".WidgetProgress")
local WidgetTimerProgress = import(".WidgetTimerProgress")
local WidgetPushButton = import(".WidgetPushButton")

local WidgetTimerProgressStyleThree = class("WidgetTimerProgressStyleThree", WidgetTimerProgress)

function WidgetTimerProgressStyleThree:ctor(height,title)
    local width = width == nil and 549 or width
    local height = height == nil and 100 or height
    local back_ground_556x56 = display.newSprite("back_ground_556x56.png")
    self.describe = cc.ui.UILabel.new({
        size = 22,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(back_ground_556x56):align(display.CENTER, back_ground_556x56:getContentSize().width/2, back_ground_556x56:getContentSize().height/2)


    self.progress = WidgetProgress.new():addTo(back_ground_556x56):align(display.LEFT_CENTER, 20, -36)

    self.button = WidgetPushButton.new(
        {normal = "green_btn_up_148x58.png", pressed = "green_btn_down_148x58.png"},
        {scale9 = false},
        {
            disabled = {name = "GRAY", params = {0.2, 0.3, 0.5, 0.1}}
        }
    ):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("加速"),
        size = 24,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(back_ground_556x56)
        :align(display.CENTER, width - 74, -30)

    back_ground_556x56:addTo(self)
    self.back_ground = back_ground_556x56
end

return WidgetTimerProgressStyleThree