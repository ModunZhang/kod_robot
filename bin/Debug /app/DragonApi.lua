--
-- Author: Kenny Dai
-- Date: 2015-05-07 21:13:42
--

local DragonApi = {}

-- 孵化龙
function DragonApi:HatchDragon()
    local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()

    for __,dragon in pairs(dragon_manager:GetDragons()) do
        if not dragon:Ishated() then
            if City:GetFirstBuildingByType("dragonEyrie"):CheckIfHateDragon() then
                print(" 孵化更多龙",dragon:Type())
                return NetManager:getHatchDragonPromise(dragon:Type())
            end
        end
    end
end
-- 驻防龙
function DragonApi:SetDefenceDragon()
    local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    -- 没有已孵化的龙
    -- if dragon_manager:NoDragonHated() then
    --     return
    -- end
    -- 已经有龙驻防
    if dragon_manager:GetDefenceDragon() then
        return
    end
    for __,dragon in pairs(dragon_manager:GetDragons()) do
        if dragon:Ishated() then
            return NetManager:getSetDefenceDragonPromise(dragon:Type())
        end
    end
end
-- 打造龙的装备
function DragonApi:MakeEquipment(force_equip_type)
    -- 铁匠铺是否已解锁
    if not app:IsBuildingUnLocked(9) then
        return
    end
    local black_smith = City:GetBuildingByLocationId(9)
    if black_smith:IsMakingEquipment() then
        -- 加速
        -- 随机使用事件加速道具
        local making_event = black_smith:GetMakeEquipmentEvent()
        local speedUp_item_name = "speedup_"..math.random(8)
        print("使用"..speedUp_item_name.."加速制造装备 ,id:",making_event:Id())
        return NetManager:getBuyAndUseItemPromise(speedUp_item_name,{[speedUp_item_name] = {
            eventType = "dragonEquipmentEvents",
            eventId = making_event:Id()
        }})
    else
        -- 制造装备
        local isFinishNow = math.random(2) == 2
        local city = City
        local EQUIPMENTS = GameDatas.DragonEquipments.equipments
        local equip_type
        if force_equip_type then
            equip_type = force_equip_type
        else

            local map_equipments = {}
            for k,v in pairs(EQUIPMENTS) do
                if v.maxStar < 5  then
                    table.insert(map_equipments, v)
                end
            end
            -- 随机制造一个
            equip_type = map_equipments[math.random(#map_equipments)].name
        end

        local equip_config = EQUIPMENTS[equip_type]
        local material_manager = city:GetMaterialManager()
        local matrials = LuaUtils:table_map(string.split(equip_config.materials, ","), function(k, v)
            return k, string.split(v, ":")
        end)
        local is_material_enough = true
        for k,v in pairs(matrials) do
            if not is_material_enough then
                break
            end
            material_manager:IteratorDragonMaterials(function (m_name,m_count)
                if m_name == v[1] then
                    if tonumber(v[2]) > m_count then
                        is_material_enough = false
                    end
                end
            end)
        end
        if not is_material_enough  then
            return
        end
        print("制造龙的装备->",equip_type)
        if not isFinishNow then
            return NetManager:getMakeDragonEquipmentPromise(equip_type)
        else
            return NetManager:getInstantMakeDragonEquipmentPromise(equip_type)
        end
    end
end

function DragonApi:LoadEquipment()
    local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    local hate_dragons = {}
    for k,dragon in pairs(dragon_manager:GetDragons()) do
        if dragon:Ishated() then
            table.insert(hate_dragons, dragon)
        end
    end

    if not LuaUtils:table_empty(hate_dragons) then
        local dragon = hate_dragons[math.random(#hate_dragons)]
        -- 没有装备完所有部位
        if not dragon:IsAllEquipmentsLoaded() then
            -- 当前已有的所有装备
            local all_equipments = City:GetMaterialManager():GetEquipmentMaterias()
            for k,equi in pairs(dragon:Equipments()) do
                -- 没有装备该部位
                if not equi:IsLoaded() and not equi:IsLocked() then
                    if all_equipments[equi:GetCanLoadConfig().name] > 0 then
                        print("装备龙装备",equi:Type(),equi:Body(),equi:GetCanLoadConfig().name)
                        return NetManager:getLoadDragonEquipmentPromise(equi:Type(),equi:Body(),equi:GetCanLoadConfig().name)
                    else
                        print("发现没有对应位置的装备，则制造一个",equi:GetCanLoadConfig().name)
                        return self:MakeEquipment(equi:GetCanLoadConfig().name)
                    end
                end
            end
        end
    end
end
-- 重置装备属性
function DragonApi:ResetEqui()
    local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    local hate_dragons = {}
    for k,dragon in pairs(dragon_manager:GetDragons()) do
        if dragon:Ishated() then
            table.insert(hate_dragons, dragon)
        end
    end

    if not LuaUtils:table_empty(hate_dragons) then
        local dragon = hate_dragons[math.random(#hate_dragons)]
        local loaded_equi = {}
        for k,equi in pairs(dragon:Equipments()) do
            -- 该部位已装备
            if equi:IsLoaded() then
                table.insert(loaded_equi, equi)
            end
        end
        if not LuaUtils:table_empty(loaded_equi) then
            local reset_equi = loaded_equi[math.random(#loaded_equi)]
            -- 当前已有的所有装备
            local all_equipments = City:GetMaterialManager():GetEquipmentMaterias()
            if all_equipments[reset_equi:GetCanLoadConfig().name] > 0 then
                print("重置装备属性",reset_equi:Type(),reset_equi:Body(),reset_equi:GetCanLoadConfig().name)
                return NetManager:getResetDragonEquipmentPromise(reset_equi:Type(),reset_equi:Body())
            end
        end
    end
end
function DragonApi:EnhanceDragonEquipment()
    local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    local hate_dragons = {}
    for k,dragon in pairs(dragon_manager:GetDragons()) do
        if dragon:Ishated() then
            table.insert(hate_dragons, dragon)
        end
    end

    if not LuaUtils:table_empty(hate_dragons) then
        local dragon = hate_dragons[math.random(#hate_dragons)]
        local loaded_equi = {}
        for k,equi in pairs(dragon:Equipments()) do
            -- 该部位已装备且没有升到最大星级
            if equi:IsLoaded() and not equi:IsReachMaxStar() then
                table.insert(loaded_equi, equi)
            end
        end
        if not LuaUtils:table_empty(loaded_equi) then
            local enhance_equi = loaded_equi[math.random(#loaded_equi)]
            -- 当前已有的所有装备
            local all_equipments = City:GetMaterialManager():GetEquipmentMaterias()
            -- 省事,直选一个装备强化，以避免使用过多装备强化，超出范围
            local equipments = {}
            for k,v in pairs(all_equipments) do
                if v > 0 then
                    table.insert(equipments, {name = k,count = v})
                    break
                end
            end
            if not LuaUtils:table_empty(equipments) then
                print("强化装备属性",enhance_equi:Type(),enhance_equi:Body(),enhance_equi:GetCanLoadConfig().name)
                return NetManager:getEnhanceDragonEquipmentPromise(enhance_equi:Type(),enhance_equi:Body(),equipments)
            end
        end
    end
end
function DragonApi:DragonAddExp()
    local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    local hate_dragons = {}
    for k,dragon in pairs(dragon_manager:GetDragons()) do
        if dragon:Ishated() then
            table.insert(hate_dragons, dragon)
        end
    end

    if not LuaUtils:table_empty(hate_dragons) then
        local dragon = hate_dragons[math.random(#hate_dragons)]
        return NetManager:getBuyAndUseItemPromise("dragonExp_3",{["dragonExp_3"] = {
            dragonType = dragon:Type()
        }})
    end
end
function DragonApi:AddBlood()
    local blood = City:GetResourceManager():GetBloodResource():GetValue()
    return NetManager:getBuyAndUseItemPromise("heroBlood_3",{})
end
function DragonApi:UpgradeDragonStar()
    local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    local upgrade_dragons = {}
    for k,dragon in pairs(dragon_manager:GetDragons()) do
        if dragon:Ishated() and dragon:IsReachPromotionLevel() and dragon:EquipmentsIsReachMaxStar() and dragon:Star() < 4 then
            table.insert(upgrade_dragons, dragon)
        end
    end

    if not LuaUtils:table_empty(upgrade_dragons) then
        local dragon = upgrade_dragons[math.random(#upgrade_dragons)]
        print("龙升星 ",dragon:Type())
        return NetManager:getUpgradeDragonStarPromise(dragon:Type())
    end
end
function DragonApi:UpgradeDragonDragonSkill()
    local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    local hate_dragons = {}
    for k,dragon in pairs(dragon_manager:GetDragons()) do
        if dragon:Ishated() then
            table.insert(hate_dragons, dragon)
        end
    end

    if not LuaUtils:table_empty(hate_dragons) then
        local dragon = hate_dragons[math.random(#hate_dragons)]
        local can_upgrade_skills = {}
        for k,skill in pairs(dragon:Skills()) do
            -- 技能已解锁且没有升到最大等级
            if not skill:IsMaxLevel() and not skill:IsLocked() then
                table.insert(can_upgrade_skills, skill)
            end
        end
        if not LuaUtils:table_empty(can_upgrade_skills) then
            local upgrade_skill = can_upgrade_skills[math.random(#can_upgrade_skills)]

            local blood = City:GetResourceManager():GetBloodResource():GetValue()
            local cost = upgrade_skill:GetBloodCost()
            if blood < cost then
                return self:AddBlood()
            else
                local star = upgrade_skill:Star()
                local need_star = DataUtils:GetDragonSkillUnLockStar(upgrade_skill:Name())
                if  star >= need_star then
                    print("升级龙技能",upgrade_skill:Type(),upgrade_skill:Key())
                    return NetManager:getUpgradeDragonDragonSkillPromise(upgrade_skill:Type(),upgrade_skill:Key())
                end
            end
        end
    end
end
local function setRun()
    app:setRun()
end

local function HatchDragon()
    local p = DragonApi:HatchDragon()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function SetDefenceDragon()
    local p = DragonApi:SetDefenceDragon()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function MakeEquipment()
    local p = DragonApi:MakeEquipment()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function LoadEquipment()
    local p = DragonApi:LoadEquipment()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function ResetEqui()
    local p = DragonApi:ResetEqui()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function EnhanceDragonEquipment()
    local p = DragonApi:EnhanceDragonEquipment()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function UpgradeDragonDragonSkill()
    local p = DragonApi:UpgradeDragonDragonSkill()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end

return {
    setRun,
    HatchDragon,
    SetDefenceDragon,
    MakeEquipment,
    LoadEquipment,
    ResetEqui,
    EnhanceDragonEquipment,
    UpgradeDragonDragonSkill,
}















