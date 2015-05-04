local Enum = import("..utils.Enum")
local Observer = import(".Observer")
local Localize = import("..utils.Localize")
local MaterialManager = class("MaterialManager", Observer)
MaterialManager.MATERIAL_TYPE = Enum("BUILD", "TECHNOLOGY","DRAGON", "SOLDIER", "EQUIPMENT")
local MATERIAL_TYPE = MaterialManager.MATERIAL_TYPE
local BUILD = MATERIAL_TYPE.BUILD
local TECHNOLOGY = MATERIAL_TYPE.TECHNOLOGY
local DRAGON = MATERIAL_TYPE.DRAGON
local SOLDIER = MATERIAL_TYPE.SOLDIER
local EQUIPMENT = MATERIAL_TYPE.EQUIPMENT

local dragonEquipments = GameDatas.DragonEquipments.equipments
local soldierMaterials = GameDatas.PlayerInitData.soldierMaterials
local dragonMaterials = GameDatas.PlayerInitData.dragonMaterials
function MaterialManager:ctor()
    MaterialManager.super.ctor(self)
    self.material_map = {}
    self.material_map[BUILD] = {
        ["tiles"] = 0,
        ["pulley"] = 0,
        ["tools"] = 0,
        ["blueprints"] = 0,
    }
    self.material_map[TECHNOLOGY] = {
        ["saddle"] = 0,
        ["bowTarget"] = 0,
        ["ironPart"] = 0,
        ["trainingFigure"] = 0,
    }
    self.material_map[DRAGON] = self:GetTableFromKey__(dragonMaterials)
    self.material_map[SOLDIER] = self:GetTableFromKey__(soldierMaterials)
    self.material_map[EQUIPMENT] = self:GetTableFromKey(dragonEquipments)
end
function MaterialManager:GetTableFromKey(t)
    local r = {}
    for k,_ in pairs(t) do
        if k ~= "level" then
            r[k] = 0
        end
    end
    return r
end
function MaterialManager:GetTableFromKey__(t)
    local r = {}
    for _,v in pairs(t) do
        for k,_ in pairs(v) do
            if  k ~= "level" then
                r[k] = 0
            end
        end
    end
    return r
end
function MaterialManager:GetMaterialMap()
    return self.material_map
end
function MaterialManager:GetMaterialsByType(material_type)
    return self.material_map[material_type]
end
function MaterialManager:IteratorBuildMaterialsByType(func)
    self:IteratorMaterialsByType(BUILD, func)
end
function MaterialManager:IteratorDragonMaterialsByType(func)
    self:IteratorMaterialsByType(DRAGON, func)
end
function MaterialManager:IteratorSoldierMaterialsByType(func)
    self:IteratorMaterialsByType(SOLDIER, func)
end
function MaterialManager:IteratorEquipmentMaterialsByType(func)
    self:IteratorMaterialsByType(EQUIPMENT, func)
end
function MaterialManager:IteratorMaterialsByType(material_type, func)
    for k, v in pairs(self.material_map[material_type]) do
        func(k, v)
    end
end
function MaterialManager:OnUserDataChanged(userData, deltaData)
    local is_fully_update = deltaData == nil
    local materialsMap = {
        [BUILD] = "buildingMaterials",
        [TECHNOLOGY] = "technologyMaterials",
        [DRAGON] = "dragonMaterials",
        [SOLDIER] = "soldierMaterials",
        [EQUIPMENT] = "dragonEquipments",
    }
    for material_type,v in ipairs(materialsMap) do
        local is_delta_update = not is_fully_update and deltaData[v]
        if is_fully_update or is_delta_update then
            print("MaterialManager:OnUserDataChanged", v)
            self:OnMaterialsComing(material_type, userData[v])
        end
    end
end
function MaterialManager:OnMaterialsComing(material_type, materials)
    if not materials then return end
    local changed = {}
    local old_materials = self.material_map[material_type]
    for k, old in pairs(old_materials) do
        local new = materials[k]
        if new and old ~= new then
            old_materials[k] = new
            changed[k] = {old = old, new = new}
        end
    end
    -- 如果是增加材料则弹出提示
    if next(changed) and display.getRunningScene().__cname ~= "MainScene" then
        local get_list = ""
        for k,v in pairs(changed) do
            local add = v.new-v.old
            if add>0 then
                local m_name = Localize.equip_material[k] or Localize.equip[k] or Localize.materials[k] or  k
                get_list = get_list .. m_name .. "X"..add
            end
        end
        if get_list ~="" then
            if material_type == EQUIPMENT then
                GameGlobalUI:showTips(_("制造装备完成"),get_list)
            else
                -- GameGlobalUI:showTips(_("获得材料"),get_list)
            end
        end
    end
    if next(changed) then
        self:NotifyObservers(function(listener)
            listener:OnMaterialsChanged(self, material_type, changed)
        end)
    end
end

return MaterialManager














