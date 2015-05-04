--
-- Author: Danny He
-- Date: 2014-09-17 09:22:12
--
local config_function = GameDatas.BuildingFunction.dragonEyrie
local config_levelup = GameDatas.BuildingLevelUp.dragonEyrie
local ResourceManager = import(".ResourceManager")
local UpgradeBuilding = import(".UpgradeBuilding")
local DragonEyrieUpgradeBuilding = class("DragonEyrieUpgradeBuilding", UpgradeBuilding)
local DragonManager = import(".DragonManager")


function DragonEyrieUpgradeBuilding:ctor(building_info)
    DragonEyrieUpgradeBuilding.super.ctor(self,building_info)
    self:SetDragonManager(DragonManager.new())
end


function DragonEyrieUpgradeBuilding:OnTimer(current_time)
    DragonEyrieUpgradeBuilding.super.OnTimer(self,current_time)
    self:GetDragonManager():OnTimer(current_time)
end

function DragonEyrieUpgradeBuilding:EnergyMax()
    return config_function[self:GetEfficiencyLevel()].energyMax
end

function DragonEyrieUpgradeBuilding:OnUserDataChanged(user_data, current_time, location_id,sub_location,deltaData)
    DragonEyrieUpgradeBuilding.super.OnUserDataChanged(self,user_data, current_time, location_id, sub_location, deltaData)
    self:GetDragonManager():OnUserDataChanged(user_data, current_time, deltaData,self:GetHPRecoveryPerHour())
end


function DragonEyrieUpgradeBuilding:SetDragonManager(manager)
    self.dragon_manger_ = manager
end

function DragonEyrieUpgradeBuilding:GetDragonManager()
    return self.dragon_manger_ 
end
--withBuff 
function DragonEyrieUpgradeBuilding:GetHPRecoveryPerHour(withBuff)
    local hprecoveryperhour = config_function[self:GetEfficiencyLevel()].hpRecoveryPerHour
    if withBuff == false then return hprecoveryperhour end
    hprecoveryperhour = math.floor(hprecoveryperhour * (1 + DataUtils:GetDragonHpBuffTotal()))
    return hprecoveryperhour
end

function DragonEyrieUpgradeBuilding:GetHPRecoveryPerHourWithoutBuff()
    return self:GetHPRecoveryPerHour(false)
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


