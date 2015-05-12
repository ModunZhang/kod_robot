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

return {
    setRun,
    HatchDragon,
    SetDefenceDragon,
}



