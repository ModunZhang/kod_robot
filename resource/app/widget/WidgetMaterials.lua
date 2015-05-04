local UIListView = import("..ui.UIListView")
local window = import("..utils.window")
local WidgetMaterialBox = import("..widget.WidgetMaterialBox")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetMaterialDetails = import("..widget.WidgetMaterialDetails")
local MaterialManager = import("..entity.MaterialManager")
local WidgetDropList = import("..widget.WidgetDropList")
local BUILDING_MATERIALS = {
    "blueprints" ,
    "tools",
    "tiles" ,
    "pulley" ,
}

local DRAGON_MATERIALS = {
    "ingo_1" ,
    "ingo_2" ,
    "ingo_3" ,
    "ingo_4",
    "redSoul_2" ,
    "redSoul_3" ,
    "redSoul_4" ,
    "blueSoul_2" ,
    "blueSoul_3" ,
    "blueSoul_4" ,
    "greenSoul_2",
    "greenSoul_3",
    "greenSoul_4" ,
    "redCrystal_1",
    "redCrystal_2" ,
    "redCrystal_3" ,
    "redCrystal_4" ,
    "blueCrystal_1" ,
    "blueCrystal_2" ,
    "blueCrystal_3",
    "blueCrystal_4" ,
    "greenCrystal_1" ,
    "greenCrystal_2" ,
    "greenCrystal_3" ,
    "greenCrystal_4" ,
    "runes_1" ,
    "runes_2" ,
    "runes_3" ,
    "runes_4" ,
}
local SOLDIER_METARIALS = {
    "heroBones" ,
    "magicBox" ,
    "soulStone" ,
    "deathHand" ,
}
local EQUIPMENT = {
    "redCrown_s1" ,
    "redCrown_s2" ,
    "redCrown_s3" ,
    "redCrown_s4" ,
    "blueCrown_s1",
    "blueCrown_s2",
    "blueCrown_s3",
    "blueCrown_s4",
    "greenCrown_s1",
    "greenCrown_s2",
    "greenCrown_s3",
    "greenCrown_s4",
    "redChest_s2" ,
    "redChest_s3" ,
    "redChest_s4" ,
    "blueChest_s2",
    "blueChest_s3",
    "blueChest_s4" ,
    "greenChest_s2",
    "greenChest_s3",
    "greenChest_s4",
    "redSting_s2" ,
    "redSting_s3" ,
    "redSting_s4" ,
    "blueSting_s2" ,
    "blueSting_s3" ,
    "blueSting_s4" ,
    "greenSting_s2" ,
    "greenSting_s3" ,
    "greenSting_s4" ,
    "redOrd_s2" ,
    "redOrd_s3",
    "redOrd_s4" ,
    "blueOrd_s2" ,
    "blueOrd_s3" ,
    "blueOrd_s4" ,
    "greenOrd_s2",
    "greenOrd_s3" ,
    "greenOrd_s4" ,
    "redArmguard_s1" ,
    "redArmguard_s2" ,
    "redArmguard_s3" ,
    "redArmguard_s4" ,
    "blueArmguard_s1",
    "blueArmguard_s2" ,
    "blueArmguard_s3" ,
    "blueArmguard_s4" ,
    "greenArmguard_s1",
    "greenArmguard_s2",
    "greenArmguard_s3" ,
    "greenArmguard_s4" ,
}
local WidgetMaterials = class("WidgetMaterials", function ()
    return display.newLayer()
end)

function WidgetMaterials:ctor(city,building)
    self:setNodeEventEnabled(true)
    self.city = city
    self.building = building
    city:GetMaterialManager():AddObserver(self)
end

function WidgetMaterials:onExit()
    self.city:GetMaterialManager():RemoveObserver(self)
    self.building:RemoveUpgradeListener(self)
end

function WidgetMaterials:onEnter()
    local list,list_node = UIKit:commonListView({
        viewRect = cc.rect(0, 0,568, 690),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    })
    list_node:align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20):addTo(self)
    self.material_listview = list
    self:CreateSelectButton()
    self.building:AddUpgradeListener(self)
    dump(self.material_box_table)
end
function WidgetMaterials:OnBuildingUpgradingBegin()
end
function WidgetMaterials:OnBuildingUpgradeFinished(building)
    for i,v in pairs(self.material_box_table) do
        local material_map = self.city:GetMaterialManager():GetMaterialMap()[i]
        for k,m in pairs(v) do
            m:SetNumber(material_map[k].."/"..building:GetMaxMaterial())
        end
    end
end
function WidgetMaterials:OnBuildingUpgrading()
end
function WidgetMaterials:CreateItemWithListView(material_type,materials)
    local list_view = self.material_listview
    list_view:removeAllItems()
    local material_map = self.city:GetMaterialManager():GetMaterialMap()[material_type]
    local rect = list_view:getViewRect()
    local origin_x = - rect.width / 2
    local unit_width ,unit_height = 130 , 166
    local gap_x = (568 - unit_width * 4) / 3
    local row_item = display.newNode()
    local row_count = 0
    self.material_box_table = {}
    self.material_box_table[material_type]={}
    for i,material_name in ipairs(materials) do
        local material_box = WidgetMaterialBox.new(material_type,material_name,function ()
            self:OpenMaterialDetails(material_type,material_name,material_map[material_name].."/"..self.building:GetMaxMaterial())
        end,true):addTo(row_item):SetNumber(material_map[material_name].."/"..self.building:GetMaxMaterial())
            :pos(origin_x + (unit_width + gap_x) * row_count , -unit_height/2)
        self.material_box_table[material_type][material_name] = material_box
        row_count = row_count + 1
        if row_count>3 or i==#materials then
            local item = list_view:newItem()
            item:addContent(row_item)
            item:setItemSize(548, unit_height)
            list_view:addItem(item)
            row_count=0
            row_item = display.newNode()
        end
    end
    LuaUtils:outputTable("self.material_box_table", self.material_box_table)
    list_view:reload()
end
function WidgetMaterials:SelectOneTypeMaterials(m_type)
    self:CreateItemWithListView(m_type,self:GetMateriasl(m_type))
end
function WidgetMaterials:GetMateriasl( m_type )
    if m_type == MaterialManager.MATERIAL_TYPE.BUILD then
        return BUILDING_MATERIALS
    end
    if m_type == MaterialManager.MATERIAL_TYPE.DRAGON then
        return DRAGON_MATERIALS
    end
    if m_type == MaterialManager.MATERIAL_TYPE.SOLDIER then
        return SOLDIER_METARIALS
    end
    if m_type == MaterialManager.MATERIAL_TYPE.EQUIPMENT then
        return EQUIPMENT
    end
end
function WidgetMaterials:OpenMaterialDetails(material_type,material_name,num)
    UIKit:newWidgetUI("WidgetMaterialDetails",material_type,material_name,num):AddToCurrentScene()
end
function WidgetMaterials:CreateSelectButton()
    self.dropList = WidgetDropList.new(
        {
            {tag = "1",label = "工具材料",default = true},
            {tag = "2",label = "龙的装备材料"},
            {tag = "3",label = "招募特殊兵种的材料"},
            {tag = "4",label = "龙的装备"},
        },
        function(tag)
            if tag == '1' then
                self:SelectOneTypeMaterials(MaterialManager.MATERIAL_TYPE.BUILD)
            end
            if tag == '2' then
                self:SelectOneTypeMaterials(MaterialManager.MATERIAL_TYPE.DRAGON)
            end
            if tag == '3' then
                self:SelectOneTypeMaterials(MaterialManager.MATERIAL_TYPE.SOLDIER)
            end
            if tag == '4' then
                self:SelectOneTypeMaterials(MaterialManager.MATERIAL_TYPE.EQUIPMENT)
            end
        end
    )
    self.dropList:align(display.TOP_CENTER,window.cx,window.top-96):addTo(self,2)

end


function WidgetMaterials:OnMaterialsChanged(material_manager,material_type,changed_table)
    for k,v in pairs(changed_table) do
        if self.material_box_table[material_type] and self.material_box_table[material_type][k] then
            self.material_box_table[material_type][k]:SetNumber(v.new.."/"..self.building:GetMaxMaterial())
        end
    end
end

return WidgetMaterials




