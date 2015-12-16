local WidgetPushButton = import(".WidgetPushButton")
local UILib = import("..ui.UILib")

local WidgetMaterialBox = class("WidgetMaterialBox", function()
    return display.newNode()
end)

function WidgetMaterialBox:ctor(material_key,material_name,cb,is_has_i_icon)
    local material_bg = WidgetPushButton.new({normal = "back_ground_130x166.png"}):align(display.LEFT_BOTTOM):addTo(self)
    if cb then
        material_bg:onButtonClicked(cb)
    end
        
    self.material_bg = material_bg
    local rect = material_bg:getCascadeBoundingBox()

    -- 图标背景框
    local icon_bg = display.newSprite("box_118x118.png"):addTo(material_bg)
        :align(display.CENTER, rect.width/2, 97)

    local material = cc.ui.UIImage.new(self:GetMaterialImage(material_key,material_name)):addTo(icon_bg)
        :align(display.CENTER, icon_bg:getContentSize().width/2, icon_bg:getContentSize().height/2):scale(100/128)
    if is_has_i_icon then
        cc.ui.UIImage.new("goods_26x26.png"):addTo(icon_bg,2)
            :align(display.BOTTOM_LEFT, 4, 4)
    end

    self.number_bg = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(118,36),cc.rect(15,10,136,64)):addTo(material_bg)
        :align(display.BOTTOM_CENTER, rect.width/2, 4)
        :hide()
    local number_bg = self.number_bg 

    local size = number_bg:getContentSize()
    self.number = UIKit:ttfLabel({
        text = "",
        size = 22,
        color = 0x403c2f
    }):addTo(number_bg):align(display.CENTER, size.width / 2, size.height/2)


    self.second_number = UIKit:ttfLabel({
        size = 22,
        color = 0x007c23,
    }):addTo(number_bg):hide()
    :align(display.LEFT_CENTER, size.width / 2, size.height/2)
end
function WidgetMaterialBox:GetButton()
    return self.material_bg
end
function WidgetMaterialBox:SetNumber(number)
    self.number_bg:show()
    self.number:setString(number)
    return self
end
function WidgetMaterialBox:SetSecondNumber(number)
    if number then
        self.number:align(display.RIGHT_CENTER)
        self.second_number:show():setString(number)
    else
        self.number:align(display.CENTER)
        self.second_number:hide()
    end
    return self
end

function WidgetMaterialBox:GetMaterialImage(material_key,material_name)
    local metarial = ""
    if material_key == "buildingMaterials" or 
        material_key == "technologyMaterials" then
        metarial = "materials"
    elseif material_key == "dragonMaterials"  then
        metarial = "dragon_material_pic_map"
    elseif material_key == "soldierMaterials"  then
        metarial = "soldier_metarial"
    elseif material_key == "dragonEquipments" then 
        metarial = "equipment"
    end
    return UILib[metarial][material_name]
end


return WidgetMaterialBox









