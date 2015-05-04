local WidgetCitizen = class("WidgetCitizen", function ()
    return display.newNode()
end)

local window = import("..utils.window")
local WidgetUseItems = import(".WidgetUseItems")
local ResourceManager = import("..entity.ResourceManager")
WidgetCitizen.CITIZEN_TYPE = {
    CITIZEN = 5,
    FOOD = 4,
    WOOD = 3,
    IRON = 2,
    STONE = 1
}
local STONE = 1
local IRON = 2
local WOOD = 3
local FOOD = 4
local CITIZEN = 5
local items = {
    [CITIZEN] = {
        production_text = _("空闲城民"),
        production_per_hour_text = _("城民增长"),
        tag_color = "green_head_42x98.png",
        tag_icon = "res_citizen_88x82.png",
        tag_icon_scale = 0.3
    },
    [FOOD] = {
        production_text = _("农夫"),
        production_per_hour_text = _("粮食产量"),
        tag_color = "yellow_head_42x98.png",
        tag_icon = "res_food_91x74.png",
        tag_icon_scale = 0.25
    },
    [WOOD] = {
        production_text = _("伐木工"),
        production_per_hour_text = _("木材产量"),
        tag_color = "brown_head_42x98.png",
        tag_icon = "res_wood_82x73.png",
        tag_icon_scale = 0.25
    },
    [IRON] = {
        production_text = _("矿工"),
        production_per_hour_text = _("矿产产量"),
        tag_color = "blue_head_42x98.png",
        tag_icon = "res_iron_91x63.png",
        tag_icon_scale = 0.25
    },
    [STONE] = {
        production_text = _("石匠"),
        production_per_hour_text = _("石料产量"),
        tag_color = "grey_head_42x98.png",
        tag_icon = "res_stone_88x82.png",
        tag_icon_scale = 0.25
    }
}
local function return_item_info(res_type)
    return items[res_type]
end


function WidgetCitizen:ctor(city)
    self:setNodeEventEnabled(true)

    self.city = city
    local iconBg = cc.ui.UIImage.new("back_ground_43x43.png")
        :pos(window.left + 45, window.top - 140)
        :addTo(self)

    cc.ui.UIImage.new("res_citizen_88x82.png")
        :addTo(iconBg):scale(0.45)

    cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("上限"),
        font = UIKit:getFontFilePath(),
        size = 16,
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x29261c),
        valign = cc.ui.UILabel.TEXT_VALIGN_CENTER
    }):addTo(self)
        :align(display.LEFT_CENTER, window.left + 100, window.top - 100)

    self.max_citizen_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "10000",
        font = UIKit:getFontFilePath(),
        size = 20,
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x29261c),
        valign = cc.ui.UILabel.TEXT_VALIGN_CENTER
    }):addTo(self)
        :align(display.LEFT_CENTER, window.left + 100, window.top - 124)

    local citizen_num_bg = cc.ui.UIImage.new("citizen_num_bg_170x714.png")
        :addTo(self)
        :pos(window.left + 45, window.top - 150 - 702)

    local tips_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("提示：预留一定的空闲城民，兵营将这些空闲城民训练成士兵"),
        font = UIKit:getFontFilePath(),
        size = 20,
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x29261c),
        valign = cc.ui.UILabel.TEXT_VALIGN_CENTER
    }):addTo(self)
        :align(display.LEFT_CENTER, window.left + 45, window.top - 150 - 702 - 10)


    self.citizen_ui = {}
    self.citizen_ui[CITIZEN] = cc.ui.UIImage.new("green_line_130x1.png"):addTo(citizen_num_bg)
    self.citizen_ui[FOOD] = cc.ui.UIImage.new("yellow_line_130x1.png"):addTo(citizen_num_bg)
    self.citizen_ui[WOOD] = cc.ui.UIImage.new("brown_line_130x1.png"):addTo(citizen_num_bg)
    self.citizen_ui[IRON] = cc.ui.UIImage.new("blue_line_130x1.png"):addTo(citizen_num_bg)
    self.citizen_ui[STONE] = cc.ui.UIImage.new("grey_line_130x1.png"):addTo(citizen_num_bg)


    self.citizen_number = {}
    local end_pos = window.top - 260
    local count = #self.citizen_ui
    for i, v in pairs(self.citizen_ui) do

        local item_info = return_item_info(i)

        local cur_pos = end_pos - (count - i) * 110 - (i~=CITIZEN and 150 or 0)

        local res_info_bg = cc.ui.UIImage.new("res_info_bg_392x106.png"):addTo(self):pos(window.left + 215, cur_pos)

        cc.ui.UIImage.new("dividing_line_352x2.png"):addTo(res_info_bg):pos(0, 53)

        cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = item_info.production_text,
            font = UIKit:getFontFilePath(),
            size = 20,
            align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
            color = UIKit:hex2c3b(0x797154),
            valign = cc.ui.UILabel.TEXT_VALIGN_CENTER
        }):addTo(res_info_bg):align(display.LEFT_CENTER, 50, 70)

        cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = item_info.production_per_hour_text,
            font = UIKit:getFontFilePath(),
            size = 20,
            align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
            color = UIKit:hex2c3b(0x797154),
            valign = cc.ui.UILabel.TEXT_VALIGN_CENTER
        }):addTo(res_info_bg):align(display.LEFT_CENTER, 50, 25)

        local production = cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = 100,
            font = UIKit:getFontFilePath(),
            size = 20,
            align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
            color = UIKit:hex2c3b(0x29261c),
            valign = cc.ui.UILabel.TEXT_VALIGN_CENTER
        }):addTo(res_info_bg):align(display.RIGHT_CENTER, 350, 70)

        local productionPerHour = cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = "100/h",
            font = UIKit:getFontFilePath(),
            size = 20,
            align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
            color = UIKit:hex2c3b(0x29261c),
            valign = cc.ui.UILabel.TEXT_VALIGN_CENTER
        }):addTo(res_info_bg):align(display.RIGHT_CENTER, 350, 25)

        local head = cc.ui.UIImage.new(item_info.tag_color):addTo(res_info_bg):pos(4, 4)
        local res_bg = cc.ui.UIImage.new("res_bg_37x41.png"):addTo(head):align(display.CENTER, 20, 53)
        local res_bg_pos = res_bg:getAnchorPointInPoints()
        cc.ui.UIImage.new(item_info.tag_icon):addTo(res_bg):scale(item_info.tag_icon_scale):align(display.CENTER, res_bg_pos.x, res_bg_pos.y)

        if i == CITIZEN then
            local add_btn = cc.ui.UIPushButton.new(
                {normal = "add_btn_up_30x88.png",pressed = "add_btn_down_30x88.png"})
                :addTo(res_info_bg):pos(375, 53)
                :onButtonClicked(function(event)
                    WidgetUseItems.new():Create({item_type = WidgetUseItems.USE_TYPE.BUFF,item_name="citizenBonus_1"})
                        :AddToCurrentScene()
                end)
            cc.ui.UIImage.new("add_18x19.png"):addTo(add_btn):align(display.CENTER, 0, 0)
        end

        self.citizen_number[i] = {production, productionPerHour}
    end
end

function WidgetCitizen:UpdateData()
    local city = self.city
    citizen_array = {}
    local resource_manager = city:GetResourceManager()
    citizen_array[CITIZEN] = resource_manager:GetPopulationResource():GetNoneAllocatedByTime(app.timer:GetServerTime())
    citizen_array[FOOD] = city:GetCitizenByType("farmer")
    citizen_array[WOOD] = city:GetCitizenByType("woodcutter")
    citizen_array[IRON] = city:GetCitizenByType("miner")
    citizen_array[STONE] = city:GetCitizenByType("quarrier")
    self:SetMaxCitizen(resource_manager:GetPopulationResource():GetTotalLimit())
    self:OnCitizenChanged(citizen_array)
end
function WidgetCitizen:OnCitizenChanged(citizen_array)
    local total_counts = self:GetCitizenCounts(citizen_array)
    local total_gap = total_counts > 0 and self:GetCitizenUIGap() * (total_counts - 1) or 0
    local actual_length = self:GetCitizenUILength() - total_gap
    local current_height = self:GetCitizenUIBegin()
    for citizen_type, number in ipairs(citizen_array) do
        local bar_ui = self.citizen_ui[citizen_type]
        if number > 0 then
            bar_ui:setVisible(true)
            local current_length = (number / self.citizen_max) * actual_length
            bar_ui:setLayoutSize(130, current_length):pos(20, current_height)
            current_height = current_height + current_length + self:GetCitizenUIGap()
        else
            bar_ui:setVisible(false)
        end
    end

    local resource_manager = self.city:GetResourceManager()
    for k, v in pairs(self.citizen_number) do
        local production = string.format("%d", citizen_array[k])
        local productionPerHour
        if k == CITIZEN then
            local population = resource_manager:GetPopulationResource()
            productionPerHour = population:GetProductionPerHour()
            production = string.format("%d/%d", production, population:GetValueLimit())
        elseif k == FOOD then
            productionPerHour = resource_manager:GetFoodResource():GetProductionPerHour()
        elseif k == WOOD then
            productionPerHour = resource_manager:GetWoodResource():GetProductionPerHour()
        elseif k == IRON then
            productionPerHour = resource_manager:GetIronResource():GetProductionPerHour()
        elseif k == STONE then
            productionPerHour = resource_manager:GetStoneResource():GetProductionPerHour()
        end
        v[1]:setString(production)
        v[2]:setString(string.format("%d/h",productionPerHour))
    end
end
function WidgetCitizen:SetMaxCitizen(citizen_max)
    self.citizen_max = citizen_max
    self.max_citizen_label:setString(citizen_max)
end
function WidgetCitizen:GetCitizenCounts(citizen_array)
    local counts = 0
    for k, v in pairs(citizen_array) do
        if v > 0 then
            counts = counts + 1
        end
    end
    return counts
end
function WidgetCitizen:GetCitizenUIGap()
    return 5
end
function WidgetCitizen:GetCitizenUILength()
    return self:GetCitizenUIEnd() - self:GetCitizenUIBegin()
end
function WidgetCitizen:GetCitizenUIBegin()
    return 15
end
function WidgetCitizen:GetCitizenUIEnd()
    return 688
end
function WidgetCitizen:OnUpgradingBegin(building)
    self:OnUpgradingFinished(building)
end
function WidgetCitizen:OnUpgrading(building)

end
function WidgetCitizen:OnUpgradingFinished(building)
    if self:isVisible() then
        self:UpdateData()
    end
end
function WidgetCitizen:OnResourceChanged(resource_manager)
    if self:isVisible() then
        self:UpdateData()
    end
end

function WidgetCitizen:onEnter()
    self.city:AddListenOnType(self, self.city.LISTEN_TYPE.UPGRADE_BUILDING)

    self.city:GetResourceManager():AddObserver(self)
    self:OnResourceChanged(self.city:GetResourceManager())
end

function WidgetCitizen:onExit()
    self.city:GetResourceManager():RemoveObserver(self)
    self.city:RemoveListenerOnType(self, self.city.LISTEN_TYPE.UPGRADE_BUILDING)
end
return WidgetCitizen




