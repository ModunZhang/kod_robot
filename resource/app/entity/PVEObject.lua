local NotifyItem = import(".NotifyItem")
local PVEDefine = import(".PVEDefine")
local PVEObject = class("PVEObject")
local pve_dragon = GameDatas.ClientInitGame.pve_dragon
local pve_normal = GameDatas.ClientInitGame.pve_normal
local pve_elite = GameDatas.ClientInitGame.pve_elite
local pve_boss = GameDatas.ClientInitGame.pve_boss
local pve_npc = GameDatas.ClientInitGame.pve_npc
local pve_func = GameDatas.ClientInitGame.pve_func
local dragonLevel = GameDatas.Dragons.dragonLevel
local random = math.random
local randomseed = math.randomseed
local TOTAL = {
    [PVEDefine.START_AIRSHIP] = 0,
    [PVEDefine.WOODCUTTER] = 3,
    [PVEDefine.QUARRIER] = 3,
    [PVEDefine.MINER] = 3,
    [PVEDefine.FARMER] = 3,
    [PVEDefine.CAMP] = 2,
    [PVEDefine.CRASHED_AIRSHIP] = 2,
    [PVEDefine.CONSTRUCTION_RUINS] = 1,
    [PVEDefine.KEEL] = 1,
    [PVEDefine.WARRIORS_TOMB] = 1,
    [PVEDefine.OBELISK] = 1,
    [PVEDefine.ANCIENT_RUINS] = 1,
    [PVEDefine.ENTRANCE_DOOR] = 1,
    [PVEDefine.TREE] = 0,
    [PVEDefine.HILL] = 0,
    [PVEDefine.LAKE] = 0,
    [PVEDefine.TRAP] = 0,
}

local normal_map = {
    [PVEDefine.WOODCUTTER] = true,
    [PVEDefine.QUARRIER] = true,
    [PVEDefine.MINER] = true,
    [PVEDefine.FARMER] = true,
    [PVEDefine.TRAP] = true,
}
local elite_map = {
    [PVEDefine.CAMP] = true,
    [PVEDefine.CRASHED_AIRSHIP] = true,
}

function PVEObject:ctor(x, y, searched, type, map)
    self.x = x
    self.y = y
    self.searched = searched or 0
    self.type = type
    self.map = map
end
function PVEObject:GetMap()
    return self.map
end
function PVEObject:Floor()
    return self.map:GetIndex()
end
function PVEObject:SetType(type)
    self.type = type
end
function PVEObject:Type()
    return self.type
end
function PVEObject:Position()
    return self.x, self.y
end
function PVEObject:GetNextEnemy()
    return self:GetEnemyByIndex(self.searched + 1)
end
function PVEObject:GetEnemyByIndex(index)
    return self:DecodeToEnemy(self:GetEnemyInfo(index))
end
function PVEObject:GetEnemyInfo(index)
    local unique = self.type == PVEDefine.TRAP and random(#pve_normal) or self.x * self.y * (index + self.type)
    if normal_map[self.type] then
        return pve_normal[unique % #pve_normal + 1]
    elseif elite_map[self.type] then
        return pve_elite[unique % #pve_elite + 1]
    elseif self.type == PVEDefine.ENTRANCE_DOOR then
        return pve_boss[self:Floor()]
    end
end
function PVEObject:DecodeToEnemy(raw_data)
    local raw_dragon
    local cur_floor_dragon_config = pve_dragon[self:Floor()]
    if normal_map[self.type] then
        raw_dragon = cur_floor_dragon_config.normal_dragon_star_level
    elseif elite_map[self.type] then
        raw_dragon = cur_floor_dragon_config.elite_dragon_star_level
    else
        raw_dragon = cur_floor_dragon_config.boss_dragon_star_level
    end
    local is_not_boss = normal_map[self.type] or elite_map[self.type]
    local dragonType,star,level = unpack(string.split(raw_dragon, "_"))
    level = tonumber(level)
    local strength, vitality = dragonLevel[level].strength, dragonLevel[level].vitality
    local soldiers_raw = string.split(raw_data.soldiers, ";")
    return {
        dragon = {
            level = level,
            dragonType = dragonType,
            strength = strength,
            vitality = vitality,
            currentHp = vitality * 4,
            totalHp = vitality * 4,
            hpMax = vitality * 4,
        },
        soldiers = LuaUtils:table_map(soldiers_raw, function(k, v)
            local soldierType, count = unpack(string.split(v, ","))
            count = tonumber(count)
            local name, star = unpack(string.split(soldierType, "_"))
            return k, {
                name = name,
                star = tonumber(star),
                count = is_not_boss and pve_func.soldiers.countFunc(self:Floor(), count) or count,
            }
        end),
        rewards = self:DecodeToRewards(raw_data.rewards, pve_func.rewards.countFunc),
    }
end
local m = getmetatable(NotifyItem)
function PVEObject:GetNpcRewards(select)
    for k, v in pairs(PVEDefine) do
        if v == self.type then
            assert(pve_npc[k])
            local rewards = self:DecodeToRewards(pve_npc[k].rewards)
            if pve_npc[k].rewards_type == "all" then
                return rewards
            elseif pve_npc[k].rewards_type == "select" then
                return setmetatable({rewards[select]}, m)
            elseif pve_npc[k].rewards_type == "random" then
                local p = 0
                for _, reward in ipairs(rewards) do
                    p = p + reward.probability
                end
                local p = random(p)
                for _, reward in ipairs(rewards) do
                    if p > reward.probability then
                        p = p - reward.probability
                    else
                        return setmetatable({reward}, m)
                    end
                end
            else
                assert(false)
            end
        end
    end
    assert(false)
end
function PVEObject:DecodeToRewards(raw, func)
    func = func or function(_,count) return count end
    local is_not_boss = normal_map[self.type] or elite_map[self.type]
    local rewards_raw = string.split(raw, ";")
    local r = LuaUtils:table_map(rewards_raw, function(k, v)
        local rtype, rname, count, probability = unpack(string.split(v, ","))
        count = tonumber(count)
        probability = probability or 100
        probability = tonumber(probability)
        return k, {
            type = rtype,
            name = rname,
            count = is_not_boss and func(self:Floor(), count) or count,
            probability = probability
        }
    end)
    return setmetatable(r, m)
end
function PVEObject:IsAttackAble()
    return normal_map[self.type] or elite_map[self.type]
end
function PVEObject:IsUnSearched()
    return self:Searched() == 0
end
function PVEObject:IsSearched()
    return self:Searched() >= self:Total() and self:Searched() > 0
end
function PVEObject:SearchNext()
    self.searched = self.searched + 1
end
function PVEObject:IsBoss()
    return not (normal_map[self.type] or elite_map[self.type])
end
function PVEObject:IsLast()
    return self:Left() == 0
end
function PVEObject:Left()
    return self:Total() - self:Searched()
end
function PVEObject:Searched()
    return self.searched
end
function PVEObject:Total()
    return self:TotalByType(self.type)
end
function PVEObject:TotalByType(type)
    return TOTAL[type]
end
function PVEObject:IsEntranceDoor()
    return self.type == PVEDefine.ENTRANCE_DOOR
end
function PVEObject:Dump()
    return string.format("[%d,%d,%d]", self.x, self.y, self.searched)
end

return PVEObject



















