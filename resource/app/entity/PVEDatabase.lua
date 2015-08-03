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
        self.pve_maps[i] = PVEMap.new(self, i):LoadProperty()
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
    local is_fully_update = deltaData == nil
    local is_delta_update = not is_fully_update and deltaData.pve and deltaData.pve.floors
    local pve = userData.pve
    if is_fully_update then
        for _,v in ipairs(pve.floors) do
            self.pve_maps[v.level]:Load(v)
        end
    elseif is_delta_update then
        local floors = deltaData.pve.floors
        for i,v in ipairs(floors.add or {}) do
            self.pve_maps[v.level]:Load(v)
        end
        for i,v in ipairs(floors.edit or {}) do
            self.pve_maps[v.level]:Load(v)
        end
    end
    local location = pve.location
    local is_switch_floor = self.char_floor ~= location.z
    local is_pos_changed = self.char_x ~= location.x or self.char_y ~= location.y
    local location = pve.location
    self.char_x = location.x
    self.char_y = location.y
    self.char_floor = location.z
    if type(self.location_handle) == "function" then
        self.location_handle:OnLocationChanged(is_pos_changed, is_switch_floor)
    end
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

--------
local pve_wanted = GameDatas.ClientInitGame.pve_wanted
function PVEDatabase:GetTarget()
    local name_key, count_key, target_key, coin_key = self:GetPveTaskKeys()
    local user_default = cc.UserDefault:getInstance()
    local name = user_default:getStringForKey(name_key)
    return {
        name = name,
        count = user_default:getIntegerForKey(count_key),
        target = user_default:getIntegerForKey(target_key),
        coin = user_default:getIntegerForKey(coin_key),
    }, #name > 0
end
function PVEDatabase:NewTarget(name, count)
    local old,ok = self:GetTarget()
    local wanted = pve_wanted[self.user:GetCurrentPVEMap():GetIndex()]
    local soldierName, count, coin = "swordsman", 100, 2500
    
    local soldiers = {}
    for k,v in pairs(wanted) do
        if k == "coin" then
            coin = v
        elseif k ~= "floor" then
            if not ok or (ok and k ~= old.name) then
                table.insert(soldiers, {name = k, count = v})
            end
        end
    end
    local wanted_soldier = soldiers[math.random(#soldiers)]


    local name_key, count_key, target_key, coin_key = self:GetPveTaskKeys()
    local user_default = cc.UserDefault:getInstance()
    user_default:setStringForKey(name_key, wanted_soldier.name)
    user_default:setIntegerForKey(count_key, 0)
    user_default:setIntegerForKey(target_key, wanted_soldier.count)
    user_default:setIntegerForKey(coin_key, coin)
    user_default:flush()
end
function PVEDatabase:IncKillCount(count)
    local name_key, count_key, target_key = self:GetPveTaskKeys()
    local user_default = cc.UserDefault:getInstance()
    if #user_default:getStringForKey(name_key) > 0 then
        local kill_count = user_default:getIntegerForKey(count_key)
        local kill_target = user_default:getIntegerForKey(target_key)
        kill_count = kill_count + count > kill_target and kill_target or (kill_count + count)
        user_default:setIntegerForKey(count_key, kill_count)
        user_default:flush()
    end
end
function PVEDatabase:GetPveTaskKeys()
    local id = DataManager:getUserData()._id
    return id.."_pve_task",
        id.."_pve_task_count",
        id.."_pve_task_target_count",
        id.."_pve_task_coin"
end


return PVEDatabase








