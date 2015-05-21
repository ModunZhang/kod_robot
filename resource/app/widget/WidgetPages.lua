local WidgetPushButton = import(".WidgetPushButton")

local WidgetPages = class("WidgetPages", function ()
    return display.newSprite("shire_stage_title_564x58.png")
end)

function WidgetPages:ctor(params)
    self.page = params.page -- 页数
    self.titles = params.titles -- 标题 type -> table
    self.cb = params.cb or function ()end -- 回调
    self.current_page = params.current_page or 1
    self.icon_image = params.icon

    -- 标题icon
    local icon
    if self.icon_image then
        local image_name = type(self.icon_image) == 'table' and self.icon_image[self.current_page] or self.icon_image
        icon = cc.ui.UIImage.new(image_name):addTo(self)
            :align(display.LEFT_CENTER, 70, 29)
        self.icon = icon
    end
    self.title_label = UIKit:ttfLabel({
        text = "",
        size = 20,
        color = 0xffedae,
        shadow = true
    })
        :align(display.LEFT_BOTTOM,icon and icon:getContentSize().width + 80 or 74,20)
        :addTo(self)
    if params.fixed_title_position then
        self.title_label:pos(params.fixed_title_position.x,params.fixed_title_position.y)
    end
    local page_label = UIKit:ttfLabel({
        text = "/"..self.page,
        size = 20,
        color = 0xffedae,
        shadow = true
    })
        :align(display.RIGHT_BOTTOM,480,20)
        :addTo(self)
    self.current_page_label = UIKit:ttfLabel({
        text = self.current_page,
        size = 20,
        color = 0xffedae,
        shadow = true
    })
        :align(display.RIGHT_BOTTOM,page_label:getPositionX() - page_label:getContentSize().width,20)
        :addTo(self)

    self.left_button = cc.ui.UIPushButton.new(
        {normal = "shrine_page_btn_normal_52x44.png",pressed = "shrine_page_btn_light_52x44.png",disabled="shrine_page_btn_disable_52x44.png"},
        {scale9 = false}
    ):addTo(self):align(display.LEFT_CENTER,9,31)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:ChangePage_(-1)
            end
        end)
    local icon = display.newSprite("shrine_page_control_26x34.png")
    icon:setFlippedX(true)
    icon:addTo(self.left_button):pos(26,0)

    self.right_button = cc.ui.UIPushButton.new(
        {normal = "shrine_page_btn_normal_52x44.png",pressed = "shrine_page_btn_light_52x44.png",disabled="shrine_page_btn_disable_52x44.png"},
        {scale9 = false}
    ):addTo(self):align(display.RIGHT_CENTER,559,31)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:ChangePage_(1)
            end
        end)
    display.newSprite("shrine_page_control_26x34.png")
        :addTo(self.right_button)
        :pos(-26,0)
    self:SelectPage(self.current_page)
end
--翻页 false ->left true->right
function WidgetPages:ChangePage_(page_change)
    local to_page = 1
    local change = self.current_page + page_change
    if page_change>0 then
        to_page = change >= self.page and self.page or change
    else
        to_page = change <= 1 and 1 or change
    end

    self.title_label:setString(self.titles[to_page])
    self.current_page = to_page
    self.current_page_label:setString(to_page)
    if self.icon and type(self.icon_image) == 'table' then
        self.icon:setTexture(self.icon_image[to_page])
    end
    local l_enable = to_page ~= 1
    local r_enable = to_page ~= self.page
    self.left_button:setButtonEnabled(l_enable)
    self.right_button:setButtonEnabled(r_enable)
    self.cb(to_page)
end
function WidgetPages:SelectPage(page)
    self.title_label:setString(self.titles[page])
    self.left_button:setButtonEnabled(page ~= 1)
    self.right_button:setButtonEnabled(page ~= self.page)
    self.current_page = page
    self.cb(page)
end
function WidgetPages:ResetOneTitle(title,index)
    self.titles[index] = title
    if index == self.current_page then
        self.title_label:setString(title)
    end
    return self
end

function WidgetPages:GetTitleLabel()
    return self.title_label
end
return WidgetPages







