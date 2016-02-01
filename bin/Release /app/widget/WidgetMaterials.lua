local UIListView = import("..ui.UIListView")
local window = import("..utils.window")
local WidgetMaterialBox = import("..widget.WidgetMaterialBox")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetMaterialDetails = import("..widget.WidgetMaterialDetails")
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
    "ingo_1" ,
    "ingo_2" ,
    "ingo_3" ,
    "ingo_4",
    "runes_1" ,
    "runes_2" ,
    "runes_3" ,
    "runes_4" ,
    "redSoul_2" ,
    "redSoul_3" ,
    "redSoul_4" ,
    "blueSoul_2" ,
    "blueSoul_3" ,
    "blueSoul_4" ,
    "greenSoul_2",
    "greenSoul_3",
    "greenSoul_4" ,
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
end
function WidgetMaterials:onEnter()
    local User = self.city:GetUser()
    local list,list_node = UIKit:commonListView({
        viewRect = cc.rect(0, 0,568, 675),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    })
    list_node:align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20):addTo(self)
    self.material_listview = list
    self:CreateSelectButton()
    User:AddListenOnType(self, "dragonMaterials")
    User:AddListenOnType(self, "buildings")
    User:AddListenOnType(self, "soldierMaterials")
    User:AddListenOnType(self, "buildingMaterials")
    User:AddListenOnType(self, "technologyMaterials")
    User:AddListenOnType(self, "buildingEvents")
end
function WidgetMaterials:onExit()
    local User = self.city:GetUser()
    User:RemoveListenerOnType(self, "dragonMaterials")
    User:RemoveListenerOnType(self, "buildings")
    User:RemoveListenerOnType(self, "soldierMaterials")
    User:RemoveListenerOnType(self, "buildingMaterials")
    User:RemoveListenerOnType(self, "technologyMaterials")
    User:RemoveListenerOnType(self, "buildingEvents")
end
function WidgetMaterials:CreateItemWithListView(material_key,materials,notClean)
    local list_view = self.material_listview
    if not notClean then
        list_view:removeAllItems()
        self.material_box_table = {}
    end
    local material_map = self.city:GetUser()[material_key]
    local rect = list_view:getViewRect()
    local origin_x = - rect.width / 2
    local unit_width ,unit_height = 130 , 166
    local gap_x = (568 - unit_width * 4) / 3
    local row_item = display.newNode()
    local row_count = 0
    self.material_box_table[material_key]={}
    local change_line_count = 3
    for i,material_name in ipairs(materials) do
        if string.find(material_name,"redSoul") or string.find(material_name,"blueSoul") or string.find(material_name,"greenSoul") then
            change_line_count = 2
        end
        local material_box = WidgetMaterialBox.new(material_key,material_name,function ()
            self:OpenMaterialDetails(material_key,material_name,material_map[material_name].."/"..self.building:GetMaxMaterial())
        end,true):addTo(row_item):SetNumber(string.formatnumberthousands(material_map[material_name]).."/"..string.formatnumberthousands(self.building:GetMaxMaterial()))
            :pos(origin_x + (unit_width + gap_x) * row_count , -unit_height/2)
        self.material_box_table[material_key][material_name] = material_box
        row_count = row_count + 1
        if row_count > change_line_count or i == #materials then
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
        self:CreateItemWithListView("technologyMaterials",material_2,true)
    end
end
function WidgetMaterials:GetMateriasl( m_type )
    if m_type == "buildingMaterials" then
        return BUILDING_MATERIALS,TECHNOLOGY_MATERIALS
    end
    if m_type == "dragonMaterials" then
        return DRAGON_MATERIALS
    end
    if m_type == "soldierMaterials" then
        return SOLDIER_METARIALS
    end
end
function WidgetMaterials:OpenMaterialDetails(material_key,material_name,num)
    UIKit:newWidgetUI("WidgetMaterialDetails",material_key,material_name,num):AddToCurrentScene()
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
                self:SelectOneTypeMaterials("soldierMaterials")
            end
            if tag == '2' then
                self:SelectOneTypeMaterials("buildingMaterials")
            end
            if tag == '3' then
                self:SelectOneTypeMaterials("dragonMaterials")
            end
        end
    )
    self.dropList:align(display.TOP_CENTER,window.cx,window.top-86):addTo(self,2)

end
function WidgetMaterials:OnUserDataChanged_buildingEvents()
    local User = self.city:GetUser()
    local max = self.city:GetFirstBuildingByType("materialDepot"):GetMaxMaterial()
    for material_key,v in pairs(self.material_box_table) do
        local material_map = User[material_key]
        for k,m in pairs(v) do
            m:SetNumber(
                string.formatnumberthousands(material_map[k])
                .."/"..
                string.formatnumberthousands(max))
        end
    end
end
function WidgetMaterials:OnUserDataChanged_buildings(userData, deltaData)
    local ok,value = deltaData("buildings.location_8")
    if ok then
        local User = self.city:GetUser()
        local max = self.city:GetFirstBuildingByType("materialDepot"):GetMaxMaterial()
        for material_key,v in pairs(self.material_box_table) do
            local material_map = User[material_key]
            for k,m in pairs(v) do
                m:SetNumber(
                    string.formatnumberthousands(material_map[k])
                    .."/"..
                    string.formatnumberthousands(max))
            end
        end
    end
end
function WidgetMaterials:OnUserDataChanged_dragonMaterials(userData, deltaData)
    self:OnMaterialChangedByKey("dragonMaterials", deltaData("dragonMaterials"))
end
function WidgetMaterials:OnUserDataChanged_soldierMaterials(userData, deltaData)
    self:OnMaterialChangedByKey("soldierMaterials", deltaData("soldierMaterials"))
end
function WidgetMaterials:OnUserDataChanged_buildingMaterials(userData, deltaData)
    self:OnMaterialChangedByKey("buildingMaterials", deltaData("buildingMaterials"))
end
function WidgetMaterials:OnUserDataChanged_technologyMaterials(userData, deltaData)
    self:OnMaterialChangedByKey("technologyMaterials", deltaData("technologyMaterials"))
end
function WidgetMaterials:OnMaterialChangedByKey(material_key, ok, value)
    if ok then
        for k,v in pairs(value) do
            if self.material_box_table[material_key] and
                self.material_box_table[material_key][k] then
                self.material_box_table[material_key][k]:SetNumber(
                    string.formatnumberthousands(v)
                    .."/"..
                    string.formatnumberthousands(self.building:GetMaxMaterial())
                )
            end
        end
    end
end




return WidgetMaterials









