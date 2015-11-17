local WidgetWithBlueTitle = import(".WidgetWithBlueTitle")
local WidgetProgress = import(".WidgetProgress")
local WidgetUIBackGround = import(".WidgetUIBackGround")
local WidgetTimerProgress = import(".WidgetTimerProgress")
local WidgetPushButton = import(".WidgetPushButton")

local WidgetTimerProgressStyleTwo = class("WidgetTimerProgressStyleTwo", WidgetTimerProgress)

function WidgetTimerProgressStyleTwo:ctor(height,title)
    local height = height == nil and 272 or height
    local back_ground_351x96 =WidgetWithBlueTitle.new(height,title)
    local describe_bg = WidgetUIBackGround.new({width = 556,height = 56},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :addTo(back_ground_351x96):align(display.CENTER,304,160)
    self.describe = cc.ui.UILabel.new({
        size = 22,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(describe_bg, 2):align(display.LEFT_CENTER, 15, 28)


    self.progress = WidgetProgress.new():addTo(back_ground_351x96, 2):align(display.LEFT_CENTER, 50, 70)

    self.button = WidgetPushButton.new(
        {normal = "green_btn_up_148x76.png", pressed = "green_btn_down_148x76.png"},
        {scale9 = false},
        {
            disabled = {name = "GRAY", params = {0.2, 0.3, 0.5, 0.1}}
        }
    ):setButtonLabel(UIKit:ttfLabel({
        text = _("加速"),
        size = 24,
        color = 0xfff3c7,
        shadow = true}))
        :addTo(back_ground_351x96, 2)
        :align(display.CENTER, 608 - 90, 70)
    back_ground_351x96:addTo(self)
    self.back_ground = back_ground_351x96
end

return WidgetTimerProgressStyleTwo