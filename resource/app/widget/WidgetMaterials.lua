local UIListView = import("..ui.UIListView")
local window = import("..utils.window")
local WidgetMaterialBox = import("..widget.WidgetMaterialBox")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetMaterialDetails = import("..widget.WidgetMaterialDetails")
local MaterialManager = import("..entity.MaterialManager")
local WidgetRoundTabButtons = import("..widget.WidgetRoundTabButtons")
local BUILDING_MATERIALS = {
    "blueprints" ,
    "tools",
    "tiles" ,
    "pulley" ,
}

local TECHNOLOGY_MATERIALS = {
    "saddle",
    "bowTarget",
    "ironPart",
    "trainingFigure",
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
        viewRect = cc.rect(0, 0,568, 675),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    })
    list_node:align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20):addTo(self)
    self.material_listview = list
    self:CreateSelectButton()
    self.building:AddUpgradeListener(self)
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
function WidgetMaterials:CreateItemWithListView(material_type,materials,notClean)
    local list_view = self.material_listview
    if not notClean then
        list_view:removeAllItems()
        self.material_box_table = {}
    end
    local material_map = self.city:GetMaterialManager():GetMaterialMap()[material_type]
    local rect = list_view:getViewRect()
    local origin_x = - rect.width / 2
    local unit_width ,unit_height = 130 , 166
    local gap_x = (568 - unit_width * 4) / 3
    local row_item = display.newNode()
    local row_count = 0
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
    local material_1 , material_2 = self:GetMateriasl(m_type)
    if material_1 then
        self:CreateItemWithListView(m_type,material_1)
    end
    if material_2 then
        self:CreateItemWithListView(MaterialManager.MATERIAL_TYPE.TECHNOLOGY,material_2,true)
    end
end
function WidgetMaterials:GetMateriasl( m_type )
    if m_type == MaterialManager.MATERIAL_TYPE.BUILD then
        return BUILDING_MATERIALS,TECHNOLOGY_MATERIALS
    end
    if m_type == MaterialManager.MATERIAL_TYPE.DRAGON then
        return DRAGON_MATERIALS
    end
    if m_type == MaterialManager.MATERIAL_TYPE.SOLDIER then
        return SOLDIER_METARIALS
    end
end
function WidgetMaterials:OpenMaterialDetails(material_type,material_name,num)
    UIKit:newWidgetUI("WidgetMaterialDetails",material_type,material_name,num):AddToCurrentScene()
end
function WidgetMaterials:CreateSelectButton()
    self.dropList = WidgetRoundTabButtons.new(
        {
            {tag = "1",label = _("特殊兵种"),default = true},
            {tag = "2",label = _("建筑&科技")},
            {tag = "3",label = _("龙")},
        },
        function(tag)
            if tag == '1' then
                self:SelectOneTypeMaterials(MaterialManager.MATERIAL_TYPE.SOLDIER)
            end
            if tag == '2' then
                self:SelectOneTypeMaterials(MaterialManager.MATERIAL_TYPE.BUILD)
            end
            if tag == '3' then
                self:SelectOneTypeMaterials(MaterialManager.MATERIAL_TYPE.DRAGON)
            end
        end
    )
    self.dropList:align(display.TOP_CENTER,window.cx,window.top-86):addTo(self,2)

end


function WidgetMaterials:OnMaterialsChanged(material_manager,material_type,changed_table)
    for k,v in pairs(changed_table) do
        if self.material_box_table[material_type] and self.material_box_table[material_type][k] then
            self.material_box_table[material_type][k]:SetNumber(v.new.."/"..self.building:GetMaxMaterial())
        end
    end
end

return WidgetMaterials






