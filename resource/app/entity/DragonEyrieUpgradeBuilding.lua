--
-- Author: Danny He
-- Date: 2014-09-17 09:22:12
--
local config_function            = GameDatas.BuildingFunction.dragonEyrie
local config_levelup             = GameDatas.BuildingLevelUp.dragonEyrie
local config_intInit             = GameDatas.PlayerInitData.intInit
local ResourceManager            = import(".ResourceManager")
local UpgradeBuilding            = import(".UpgradeBuilding")
local DragonEyrieUpgradeBuilding = class("DragonEyrieUpgradeBuilding", UpgradeBuilding)
local DragonManager              = import(".DragonManager")


function DragonEyrieUpgradeBuilding:ctor(building_info)
    DragonEyrieUpgradeBuilding.super.ctor(self,building_info)
    self:SetDragonManager(DragonManager.new())
end
function DragonEyrieUpgradeBuilding:IsNeedToUpdate()
    return true
end
function DragonEyrieUpgradeBuilding:OnTimer(current_time)
    DragonEyrieUpgradeBuilding.super.OnTimer(self,current_time)
    self:GetDragonManager():OnTimer(current_time)
end

function DragonEyrieUpgradeBuilding:EnergyMax()
    return config_function[self:GetEfficiencyLevel()].energyMax
end

function DragonEyrieUpgradeBuilding:OnUserDataChanged(...)
    DragonEyrieUpgradeBuilding.super.OnUserDataChanged(self, ...)

    local user_data, current_time, location_info, sub_location,deltaData = ...
    self:GetDragonManager():OnUserDataChanged(user_data, current_time, deltaData,self:GetTotalHPRecoveryPerHourInfo())
end


function DragonEyrieUpgradeBuilding:SetDragonManager(manager)
    self.dragon_manger_ = manager
end

function DragonEyrieUpgradeBuilding:GetDragonManager()
    return self.dragon_manger_ 
end
-- 检查当前能否解锁一条龙
function DragonEyrieUpgradeBuilding:CheckIfHateDragon()
    return self:GetDragonManager():GetHatedCount() < config_function[self:GetLevel()].dragonCount
end
-- 解锁下一条龙的龙巢等级
function DragonEyrieUpgradeBuilding:GetNextHateLevel()
    local current_count = config_function[self:GetLevel()].dragonCount
    for i=self:GetLevel() + 1,#config_function do
        if config_function[i].dragonCount > current_count then
            return i
        end
    end
end
--withBuff 
function DragonEyrieUpgradeBuilding:GetTotalHPRecoveryPerHour(dragon_type)
    local info = self:GetTotalHPRecoveryPerHourInfo()
    if info[dragon_type] then
        return info[dragon_type]
    else
        return 0
    end
end

function DragonEyrieUpgradeBuilding:GetTotalHPRecoveryPerHourInfo()
    local terrains_info = 
    {
        redDragon = "desert",
        greenDragon = "grassLand",
        blueDragon = "iceField"
    }
    local hprecoveryperhour = self:GetHPRecoveryPerHourWithoutBuff()
    local common_buff = DataUtils:GetDragonHpBuffTotal()
    local terrain_buff = config_intInit['dragonHpRecoverTerrainAddPercent'].value / 100
    local hprecoveryperhour_info = {
        redDragon = 0,
        greenDragon = 0,
        blueDragon = 0
    }

    for dragon_type,terrain in pairs(terrains_info) do
        if terrain == User:Terrain() then
            hprecoveryperhour_info[dragon_type] =  math.floor(hprecoveryperhour * (1 + common_buff + terrain_buff))
        else
            hprecoveryperhour_info[dragon_type] =  math.floor(hprecoveryperhour * (1 + common_buff ))
        end
    end
    return hprecoveryperhour_info
end

function DragonEyrieUpgradeBuilding:GetHPRecoveryPerHourWithoutBuff()
    local hprecoveryperhour = config_function[self:GetEfficiencyLevel()].hpRecoveryPerHour
    return hprecoveryperhour
end
function DragonEyrieUpgradeBuilding:GetNextLevelHPRecoveryPerHour()
    return config_function[self:GetNextLevel()].hpRecoveryPerHour
end
--Fix bug KOD-175
function DragonEyrieUpgradeBuilding:ResetAllListeners()
    DragonEyrieUpgradeBuilding.super.ResetAllListeners(self)
    self:GetDragonManager():ClearAllListener()
end

return DragonEyrieUpgradeBuilding


