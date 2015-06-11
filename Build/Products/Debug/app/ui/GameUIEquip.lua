--
-- Author: gaozhou
-- Date: 2014-08-18 14:33:28
--
local EQUIPMENTS = GameDatas.DragonEquipments.equipments
local Localize = import("..utils.Localize")
local MaterialManager = import("..entity.MaterialManager")
local window = import("..utils.window")
local UILib = import(".UILib")
local WidgetTips = import("..widget.WidgetTips")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetTimerProgress = import("..widget.WidgetTimerProgress")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetMakeEquip = import("..widget.WidgetMakeEquip")
local GameUIEquip = class("GameUIEquip")



function GameUIEquip:OnBeginMakeEquipmentWithEvent(black_smith, event)
    self.tips:setVisible(false)
    self.timer:setVisible(true)
    self:OnMakingEquipmentWithEvent(black_smith, event, app.timer:GetServerTime())
    self.gameui:LeftButtonClicked()
end
function GameUIEquip:OnMakingEquipmentWithEvent(black_smith, event, current_time)
    if self.title:isVisible() then
        if self.tips:isVisible() then
            self.tips:setVisible(false)
        end
        if not self.timer:isVisible() then
            self.timer:setVisible(true)
        end
        self.timer:SetDescribe(string.format(_("正在制作装备 %s"), Localize.equip[event:Content()]))
        self.timer:SetProgressInfo(GameUtils:formatTimeStyle1(event:LeftTime(current_time)), event:Percent(current_time))
    end
end
function GameUIEquip:OnEndMakeEquipmentWithEvent(black_smith, event, equipment)
    self.tips:setVisible(true)
    self.timer:setVisible(false)
end
function GameUIEquip:OnMaterialsChanged(material_manager, material_type, changed)
    if MaterialManager.MATERIAL_TYPE.EQUIPMENT == material_type then
        if self.list_node:isVisible() then
            for k, v in pairs(changed) do
                if self.equip_map[k] then
                    self.equip_map[k]:SetNumber(v.new)
                end
            end
        end
    elseif MaterialManager.MATERIAL_TYPE.DRAGON == material_type then
        for k, v in pairs(self.equip_map) do
            v:CheckMaterials()
        end
    end
end




local STAR_BG = {
    "box_104x104_1.png",
    "box_104x104_2.png",
    "box_104x104_3.png",
    "box_104x104_4.png",
}
function GameUIEquip:ctor(gameui, black_smith)
    self.gameui = gameui
    self.equip_map = {}
    self.black_smith_city = black_smith:BelongCity()
    self.black_smith = black_smith
end
function GameUIEquip:Init()
    self.title = self:InitEquipmentTitle()

    self.list_view, self.list_node = UIKit:commonListView({
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(0, 0, 568, 650),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    self.list_node:addTo(self.gameui:GetView())
        :align(display.BOTTOM_CENTER, window.cx, window.bottom_top + 20)

    self.black_smith_city:GetMaterialManager():AddObserver(self)
    self.black_smith:AddBlackSmithListener(self)
end
function GameUIEquip:UnInit()
    self.black_smith_city:GetMaterialManager():RemoveObserver(self)
    self.black_smith:RemoveBlackSmithListener(self)
end
function GameUIEquip:InitEquipmentTitle()
    local node = display.newNode():addTo(self.gameui:GetView())
    self.tips = WidgetTips.new(_("建造队列空闲"), _("请选择一个装备进行制造")):addTo(node)
        :align(display.CENTER, display.cx, display.top - 140)
        :show()

    self.timer = WidgetTimerProgress.new(549, 108):addTo(node)
        :align(display.CENTER, display.cx, display.top - 140)
        :hide()
        :OnButtonClicked(function(event)
            UIKit:newGameUI("GameUIBlackSmithSpeedUp", self.black_smith):AddToCurrentScene(true)
        end)
    return node
end
--
function GameUIEquip:HideAll()
    self.title:hide()
    self.list_view:hide()
    self.list_node:hide()
end
function GameUIEquip:SwitchToDragon(dragon_type)
    self.title:show()
    self.list_node:show()
    self.list_view:show()
    self.list_view:removeAllItems()
    local equip_map = {}
    for i,v in ipairs(self:GetDragonEquipmentsByType(dragon_type)) do
        local item = self:CreateItemWithListViewByEquipments(self.list_view, v.equipments, v.title, equip_map, i)
        self.list_view:addItem(item)
    end
    local materials_manager = self.black_smith_city:GetMaterialManager()
    for k,v in pairs(equip_map) do
        v:SetNumber(materials_manager:GetEquipmentMaterias()[k])
    end
    self.equip_map = equip_map

    for i,item in ipairs(self.list_view.items_) do
        if i == 1 then
            local enable = self.black_smith:GetLevel() >= 1
            item.equip_node:setVisible(enable)
            item.unlock_label:setVisible(not enable)
        elseif i == 2 then
            local enable = self.black_smith:GetLevel() >= 10
            item.equip_node:setVisible(enable)
            item.unlock_label:setVisible(not enable)
        elseif i == 3 then
            local enable = self.black_smith:GetLevel() >= 20
            item.equip_node:setVisible(enable)
            item.unlock_label:setVisible(not enable)
        elseif i == 4 then
            local enable = self.black_smith:GetLevel() >= 30
            item.equip_node:setVisible(enable)
            item.unlock_label:setVisible(not enable)
        end
    end
    self.list_view:reload()

    local event = self.black_smith:GetMakeEquipmentEvent()
    self.tips:setVisible(event:IsEmpty())
    self.timer:setVisible(event:IsMaking())
    if event:IsMaking() then
        local current_time = app.timer:GetServerTime()
        self.timer:SetDescribe(string.format(_("正在制作装备 %s"), Localize.equip[event:Content()]))
        self.timer:SetProgressInfo(GameUtils:formatTimeStyle1(event:LeftTime(current_time)), event:Percent(current_time))
    end
end
function GameUIEquip:CreateDragonEquipmentsByType(dragon_type)
    local equip_map = {}
    local list_view ,listnode=  UIKit:commonListView({
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(0, 0, 568, 650),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    listnode:addTo(self.gameui:GetView()):align(display.BOTTOM_CENTER,window.cx,window.bottom_top + 20)

    for i,v in ipairs(self:GetDragonEquipmentsByType(dragon_type)) do
        local item = self:CreateItemWithListViewByEquipments(list_view, v.equipments, v.title, equip_map, i)
        list_view:addItem(item)
    end
    list_view:reload()
    return list_view, equip_map,listnode
end
local sort_map = {
    ["crown"] = 1,
    ["chest"] = 2,
    ["sting"] = 3,
    ["orb"] = 4,
    ["armguardLeft,armguardRight"] = 5
}
function GameUIEquip:GetDragonEquipmentsByType(dragon_type)
    local dragon_equipments = {}
    local MAX_SUIT = 4
    for i = 1, MAX_SUIT do
        table.insert(dragon_equipments, {
            title = Localize.equip_suit[dragon_type][i],
            equipments = {}
        })
    end
    for _,v in pairs(EQUIPMENTS) do
        if v.usedFor == dragon_type and dragon_equipments[v.maxStar] then
            table.insert(dragon_equipments[v.maxStar].equipments, v)
        end
    end
    for _,v in pairs(dragon_equipments) do
        table.sort(v.equipments, function(a, b)
            return sort_map[a.category] < sort_map[b.category]
        end)
    end
    return dragon_equipments
end
local color_map = {
    0xededed,
    0x27d400,
    0x00a8ff,
    0xe400ff,
    0xe400ff,
    0xe400ff,
}
local unlock_str = {
    string.format(_("铁匠铺升级到%d级解锁"), 1),
    string.format(_("铁匠铺升级到%d级解锁"), 10),
    string.format(_("铁匠铺升级到%d级解锁"), 20),
    string.format(_("铁匠铺升级到%d级解锁"), 30),
    string.format(_("铁匠铺升级到%d级解锁"), 40),
}
function GameUIEquip:CreateItemWithListViewByEquipments(list_view, equipments, title, equip_map, level)
    local equip_map = equip_map == nil and {} or equip_map
    -- 背景
    local back_ground = WidgetUIBackGround.new({width=568,height=188},WidgetUIBackGround.STYLE_TYPE.STYLE_2):align(display.CENTER)

    -- title blue
    local pos = back_ground:getAnchorPointInPoints()
    local title_blue = cc.ui.UIImage.new("title_blue_554x34.png"):addTo(back_ground)
    title_blue:align(display.CENTER, pos.x, back_ground:getContentSize().height - title_blue:getContentSize().height/2-6)

    -- title label
    UIKit:ttfLabel({
        text = title,
        size = 24,
        color = color_map[level],
    }):addTo(title_blue):align(display.CENTER, title_blue:getContentSize().width/2, title_blue:getContentSize().height/2)

    local unit_len, origin_y, gap_x = 104, 76, 8
    local len = #equipments
    local total_len = len * unit_len + (len - 1) * gap_x
    local origin_x = pos.x - total_len / 2 + unit_len / 2
    local equip_node = display.newNode():addTo(back_ground)
    for i, v in ipairs(equipments) do
        equip_map[v.name] = self:CreateEquipmentByType(v.name):addTo(equip_node)
            :align(display.CENTER, origin_x + (unit_len + gap_x) * (i - 1), origin_y)
            :SetNumber(0)
    end

    local item = list_view:newItem()
    item.equip_node = equip_node
    item.unlock_label = UIKit:ttfLabel({
        text = unlock_str[level],
        size = 22,
        color = 0x603c2f,
    }):addTo(back_ground):align(display.CENTER, pos.x, pos.y)
    item:addContent(back_ground)
    item:setItemSize(back_ground:getContentSize().width, back_ground:getContentSize().height + 10)
    return item
end

function GameUIEquip:CreateEquipmentByType(equip_type)
    local equip_config = EQUIPMENTS[equip_type]
    -- 装备按钮
    local equipment_btn = WidgetPushButton.new(
        {normal = "back_ground_104x132.png"})
        :onButtonClicked(function(event)
            UIKit:newWidgetUI("WidgetMakeEquip", equip_type, self.black_smith, self.black_smith_city):AddToCurrentScene()
        end)
    local bg = STAR_BG[equip_config.maxStar]
    local eq_bg = cc.ui.UIImage.new(bg):addTo(equipment_btn)
        :align(display.CENTER,0,14)
    -- 装备图标
    cc.ui.UIImage.new(UILib.equipment[equip_type]):addTo(eq_bg)
        :align(display.CENTER,eq_bg:getContentSize().width/2,eq_bg:getContentSize().height/2):scale(0.62)

    -- number bg
    local number_bg_100x40 = display.newScale9Sprite("back_ground_166x84.png", 0,0,cc.size(102,30),cc.rect(15,10,136,64))
        :addTo(equipment_btn)
        :align(display.CENTER, 0, - 104 / 2 +2)

    -- number label
    local pos = number_bg_100x40:getAnchorPointInPoints()
    local number_label = cc.ui.UILabel.new({
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(number_bg_100x40):align(display.CENTER, pos.x, pos.y)


    equipment_btn.tips_green = display.newSprite("green_tips_icon_22x22.png")
        :addTo(equipment_btn):align(display.RIGHT_TOP, 104/2, 132/2)


    local materials_manager = self.black_smith_city:GetMaterialManager()
    function equipment_btn:SetNumber(number)
        number_label:setString(number)
        return self
    end
    function equipment_btn:CheckMaterials()
        self.tips_green:setVisible(materials_manager:IsAbleToMakeEquipmentByType(equip_type))
        return self
    end


    return equipment_btn:CheckMaterials()
end

return GameUIEquip




















