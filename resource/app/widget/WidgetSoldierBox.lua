local UIPushButton = cc.ui.UIPushButton
local UILib = import("..ui.UILib")
local StarBar = import("..ui.StarBar")
local WidgetPushButton = import(".WidgetPushButton")
local WidgetSoldierBox = class("WidgetSoldierBox", function()
    return display.newNode()
end)
local NORMAL = GameDatas.Soldiers.normal
local SPECIAL = GameDatas.Soldiers.special

function WidgetSoldierBox:ctor(soldier_png, cb)
    self.soldier_bg = WidgetPushButton.new({normal = "back_ground_130x166.png",
        pressed = "back_ground_130x166.png"}):addTo(self)
        :onButtonClicked(cb)
        :align(display.CENTER, 0,0)

    local rect = self.soldier_bg:getCascadeBoundingBox()

    local number_bg = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(118,36),cc.rect(15,10,136,64)):addTo(self.soldier_bg)
        :align(display.CENTER, 0, - rect.height / 2 +28)

    local size = number_bg:getContentSize()
    self.number = cc.ui.UILabel.new({
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x423f32)
    }):addTo(number_bg):align(display.CENTER, size.width / 2, size.height / 2)
end

function WidgetSoldierBox:SetSoldier(soldier_type, star)
    star = checknumber(star)
    local soldier_ui_config = UILib.soldier_image[soldier_type][star]
    if soldier_ui_config then
        if self.soldier then
            self.soldier_bg:removeChild(self.soldier)
        end
        if self.soldier_color_bg then
            self.soldier_bg:removeChild(self.soldier_color_bg)
        end
        self.soldier_color_bg = display.newSprite(UILib.soldier_color_bg_images[soldier_type], nil, nil, {class=cc.FilteredSpriteWithOne}):addTo(self.soldier_bg)
            :align(display.CENTER, 0, 20):scale(104/128)
        self.soldier = display.newSprite(soldier_ui_config, nil, nil, {class=cc.FilteredSpriteWithOne}):addTo(self.soldier_bg)
            :align(display.CENTER, 0, 20)
        self.soldier:scale(104/self.soldier:getContentSize().height)

        self.soldier_star_bg = display.newSprite("tmp_back_ground_102x22.png"):addTo(self.soldier_bg):align(display.BOTTOM_CENTER,0, -28)
        display.newSprite("i_icon_20x20.png"):addTo(self.soldier_star_bg):align(display.LEFT_CENTER,0, 11)
        self.soldier_star = StarBar.new({
            max = 3,
            bg = "Stars_bar_bg.png",
            fill = "Stars_bar_highlight.png",
            num = star,
            margin = 5,
            direction = StarBar.DIRECTION_HORIZONTAL,
            scale = 0.8,
        }):addTo(self.soldier_star_bg):align(display.LEFT_CENTER,18, 11)
        display.newSprite("box_soldier_128x128.png"):addTo(self.soldier):align(display.CENTER, self.soldier:getContentSize().width/2, self.soldier:getContentSize().height-64)
    end
    return self
end
function WidgetSoldierBox:SetNumber(number)
    if type(number) == 'string' then
        self.number:setString(number)
    elseif type(number) == 'number' then
        self.number:setString(string.formatnumberthousands(number))
    end
    return self
end
function WidgetSoldierBox:Enable(b)
    if b then
        self.soldier:clearFilter()
        self.soldier_color_bg:clearFilter()
        self.soldier_star_bg:show()
    else
        self.soldier:setFilter(filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1}))
        self.soldier_color_bg:setFilter(filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1}))
        self.soldier_star_bg:hide()
    end
    return self
end
function WidgetSoldierBox:SetCondition(text)
    self.number:setString(text)
    return self
end
function WidgetSoldierBox:IsLocked()
    return self.soldier:getFilter()
end
function WidgetSoldierBox:align(anchorPoint, x, y)
    self.soldier_bg:align(anchorPoint)
    if x and y then self:setPosition(x, y) end
    return self
end
function WidgetSoldierBox:alignByPoint(point, x, y)
    self.soldier_bg:setAnchorPoint(point)
    if x and y then self:setPosition(x, y) end
    return self
end
function WidgetSoldierBox:SetButtonListener( cb )
    self.soldier_bg:removeAllEventListeners()
    self.soldier_bg:onButtonClicked(cb)
end

return WidgetSoldierBox














