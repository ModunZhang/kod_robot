local PVEMap = import(".PVEMap")
local PVEDatabase = class("PVEDatabase")

local MAX_FLOOR = 24
local TRAP_NPC_STEPS = 10
function PVEDatabase:ctor(user)
    self.user = user
    self.char_x = 12
    self.char_y = 12
    self.char_floor = 1
    self.next_enemy_step = TRAP_NPC_STEPS
    self.pve_maps = {}
    for i = 1, MAX_FLOOR do
        self.pve_maps[i] = PVEMap.new(self, i)
        -- :LoadProperty()
    end
end
function PVEDatabase:MapLen()
    return #self.pve_maps
end
function PVEDatabase:GetRewardedList()
    return DataManager:getUserData().pve.rewardedFloors
end
function PVEDatabase:SetLocationHandle(location_handle)
    self.location_handle = location_handle
end
function PVEDatabase:ResetLocationHander()
    self.location_handle = nil
end
function PVEDatabase:OnUserDataChanged(userData, deltaData)
    -- local is_fully_update = deltaData == nil
    -- local is_delta_update = not is_fully_update and deltaData.pve and deltaData.pve.floors
    -- local pve = userData.pve
    -- if is_fully_update then
    --     for _,v in ipairs(pve.floors) do
    --         self.pve_maps[v.level]:Load(v)
    --     end
    -- elseif is_delta_update then
    --     local floors = deltaData.pve.floors
    --     for i,v in ipairs(floors.add or {}) do
    --         self.pve_maps[v.level]:Load(v)
    --     end
    --     for i,v in ipairs(floors.edit or {}) do
    --         self.pve_maps[v.level]:Load(v)
    --     end
    -- end
    -- local location = pve.location
    -- local is_switch_floor = self.char_floor ~= location.z
    -- local is_pos_changed = self.char_x ~= location.x or self.char_y ~= location.y
    -- local location = pve.location
    -- self.char_x = location.x
    -- self.char_y = location.y
    -- self.char_floor = location.z
    -- if type(self.location_handle) == "function" then
    --     self.location_handle:OnLocationChanged(is_pos_changed, is_switch_floor)
    -- end
end
function PVEDatabase:ReduceNextEnemyStep()
    self.next_enemy_step = self.next_enemy_step - 1
end
function PVEDatabase:ResetNextEnemyCounter()
    self.next_enemy_step = TRAP_NPC_STEPS
end
function PVEDatabase:IsInTrap()
    return self.next_enemy_step == 0
end
function PVEDatabase:EncodeLocation()
    return {
        x = self.char_x,
        y = self.char_y,
        z = self.char_floor,
    }
end
function PVEDatabase:GetCharPosition()
    return self.char_x, self.char_y, self.char_floor
end
function PVEDatabase:SetCharPosition(x, y, floor)
    self.char_x, self.char_y, self.char_floor = x, y, floor or self.char_floor
end
function PVEDatabase:GetMapByIndex(index)
    return self.pve_maps[index]
end
function PVEDatabase:ResetAllMapsListener()
    self:ResetLocationHander()
    for k,v in pairs(self.pve_maps) do
        v:RemoveAllObserver()
    end
end


return PVEDatabase




