local WidgetPushButton = import(".WidgetPushButton")
local MaterialManager = import("..entity.MaterialManager")
local UILib = import("..ui.UILib")

local WidgetMaterialBox = class("WidgetMaterialBox", function()
    return display.newNode()
end)

function WidgetMaterialBox:ctor(material_type,material_name,cb,is_has_i_icon)
    local material_bg = WidgetPushButton.new({normal = "back_ground_130x166.png"}):align(display.LEFT_BOTTOM):addTo(self)
    if cb then
        material_bg:onButtonClicked(cb)
    end
        
    local rect = material_bg:getCascadeBoundingBox()

    -- 图标背景框
    local icon_bg = display.newSprite("box_118x118.png"):addTo(material_bg)
        :align(display.CENTER, rect.width/2, 97)

    local material = cc.ui.UIImage.new(self:GetMaterialImage(material_type,material_name)):addTo(icon_bg)
        :align(display.CENTER, icon_bg:getContentSize().width/2, icon_bg:getContentSize().height/2):scale(100/128)
    if is_has_i_icon then
        cc.ui.UIImage.new("draong_eq_i_25x25.png"):addTo(icon_bg,2)
            :align(display.BOTTOM_LEFT, 4, 4)
    end

    self.number_bg = cc.ui.UIImage.new("back_ground_118x36.png"):addTo(material_bg)
        :align(display.BOTTOM_CENTER, rect.width/2, 4)
        :hide()
    local number_bg = self.number_bg 

    local size = number_bg:getContentSize()
    self.number = UIKit:ttfLabel({
        text = "",
        size = 22,
        color = 0x403c2f
    }):addTo(number_bg):align(display.CENTER, size.width / 2, size.height/2)

end
function WidgetMaterialBox:SetNumber(number)
    self.number_bg:show()
    self.number:setString(number)
    return self
end

function WidgetMaterialBox:GetMaterialImage(material_type,material_name)
    local metarial = ""
    if material_type == MaterialManager.MATERIAL_TYPE.BUILD then
        metarial = "materials"
    elseif material_type == MaterialManager.MATERIAL_TYPE.DRAGON  then
        metarial = "dragon_material_pic_map"
    elseif material_type == MaterialManager.MATERIAL_TYPE.SOLDIER  then
        metarial = "soldier_metarial"
    elseif material_type == MaterialManager.MATERIAL_TYPE.EQUIPMENT  then 
        metarial = "equipment"
    end
    return UILib[metarial][material_name]
end


return WidgetMaterialBox









