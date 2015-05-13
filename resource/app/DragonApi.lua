--
-- Author: Kenny Dai
-- Date: 2015-05-07 21:13:42
--

local DragonApi = {}

-- 孵化龙
function DragonApi:HatchDragon()
    local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    local dragonEvents = {}
    dragon_manager:IteratorDragonEvents(function ( dragonEvent )
        table.insert(dragonEvents, dragonEvent)
    end)
    -- 没有已孵化的龙
    if dragon_manager:NoDragonHated() and #dragonEvents == 0 then
        local hate_dragon_type = {"redDragon","blueDragon","greenDragon"}
        local dragon_type = hate_dragon_type[math.random(3)]
        print("没有已孵化的龙 孵化第一条龙",dragon_type)
        return NetManager:getHatchDragonPromise(dragon_type)
    end
    if #dragonEvents > 0 then
        local dragonEvent = dragonEvents[1]
        print("加速孵化")
        local speedUp_item_name = "speedup_"..math.random(8)
        print("使用"..speedUp_item_name.."加速dragonHatchEvents".." ,id:",dragonEvent:Id())
        return NetManager:getBuyAndUseItemPromise(speedUp_item_name,{[speedUp_item_name] = {
            eventType = "dragonHatchEvents",
            eventId = dragonEvent:Id()
        }})
    else
        for __,dragon in pairs(dragon_manager:GetDragons()) do
            if not dragon:Ishated() then
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
    if dragon_manager:NoDragonHated() then
        return
    end
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
function DragonApi:MakeEquipment()
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
        local map_equipments = {}
        for k,v in pairs(EQUIPMENTS) do
            if v.maxStar < 5  then
                table.insert(map_equipments, v)
            end
        end
        -- 随机制造一个
        local equip_type = map_equipments[math.random(#map_equipments)].name
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
            material_manager:IteratorDragonMaterialsByType(function (m_name,m_count)
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

return {
    setRun,
    HatchDragon,
    SetDefenceDragon,
    MakeEquipment,
}








