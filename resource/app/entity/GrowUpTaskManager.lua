local GrowUpTasks = GameDatas.GrowUpTasks
local Enum = import("..utils.Enum")
local Localize = import("..utils.Localize")
local NotifyItem = import(".NotifyItem")
local GrowUpTaskManager = class("GrowUpTaskManager")
local CATEGORY = Enum("BUILD", "DRAGON", "TECHNOLOGY", "SOLDIER", "EXPLORE")
GrowUpTaskManager.TASK_CATEGORY = CATEGORY
local ipairs = ipairs
local category_map = {
    [CATEGORY.BUILD] = {
        "cityBuild"
    },
    [CATEGORY.DRAGON] = {
        "dragonLevel",
        "dragonStar",
        "dragonSkill",
    },
    [CATEGORY.TECHNOLOGY] = {
        "productionTech",
        "militaryTech",
        "soldierStar",
    },
    [CATEGORY.SOLDIER] = {
        "soldierCount",
    },
    [CATEGORY.EXPLORE] = {
        "pveCount",
        "attackWin",
        "strikeWin",
        "playerKill",
        "playerPower",
    }
}
local category_localize = {
    [CATEGORY.BUILD] = _("城市建设"),
    [CATEGORY.DRAGON] = _("培养巨龙"),
    [CATEGORY.TECHNOLOGY] = _("研发科技"),
    [CATEGORY.SOLDIER] = _("招募部队"),
    [CATEGORY.EXPLORE] = _("冒险与征服")
}
local resource_map = {
    "gem",
    "exp",
    "coin",
    "food",
    "wood" ,
    "iron" ,
    "stone",
}


local rewards_icon_map = {
    gem = "gem_icon_62x61.png",
    exp = "upgrade_experience_icon.png",
    coin = "res_coin_81x68.png",
    food = "res_food_91x74.png",
    wood = "res_wood_82x73.png",
    iron = "res_iron_91x63.png",
    stone = "res_stone_88x82.png",
}


-- resource
local resource_meta = {}
resource_meta.__index = resource_meta
function resource_meta:Desc()
    return Localize.fight_reward[self.name]
end
function resource_meta:CountDesc()
    return GameUtils:formatNumber(self.count)
end
function resource_meta:Icon()
    return rewards_icon_map[self.name]
end
-------


local function get_rewards(config)
    local rewards = {}
    for _,v in ipairs(resource_map) do
        if config[v] > 0 then
            table.insert(rewards, setmetatable({type = "resources", name = v, count = config[v]}, resource_meta))
        end
    end
    return NotifyItem.new(unpack(rewards))
end
-- cityBuild
local cityBuild_meta = {}
cityBuild_meta.__index = cityBuild_meta
function cityBuild_meta:Title()
    local config = self:Config()
    return string.format(_("将%s升级到等级%d"), Localize.building_name[config.name], config.level)
end
function cityBuild_meta:Desc()
    return Localize.building_description[self:Config().name]
end
function cityBuild_meta:GetRewards()
    return get_rewards(self:Config())
end
function cityBuild_meta:Config()
    return GrowUpTasks[self:TaskType()][self.id]
end
function cityBuild_meta:TaskType()
    return "cityBuild"
end
function cityBuild_meta:BuildingType()
    return self:Config().name
end

----------------------

local dragonLevel_meta = {}
dragonLevel_meta.__index = dragonLevel_meta
function dragonLevel_meta:Title()
    local config = self:Config()
    return string.format(_("将%s升级到等级%d"), Localize.dragon[config.type], config.level)
end
function dragonLevel_meta:Desc()
    return Localize.dragon_buffer[self:Config().type]
end
function dragonLevel_meta:GetRewards()
    return get_rewards(self:Config())
end
function dragonLevel_meta:Config()
    return GrowUpTasks[self:TaskType()][self.id]
end
function dragonLevel_meta:TaskType()
    return "dragonLevel"
end
----------------------


-- 龙星级
local dragonStar_meta = {}
dragonStar_meta.__index = dragonStar_meta
function dragonStar_meta:Title()
    local config = self:Config()
    return string.format(_("将%s提升到星级%d"), Localize.dragon[config.type], config.star)
end
function dragonStar_meta:Desc()
    return Localize.dragon_buffer[self:Config().type]
end
function dragonStar_meta:GetRewards()
    return get_rewards(self:Config())
end
function dragonStar_meta:Config()
    return GrowUpTasks[self:TaskType()][self.id]
end
function dragonStar_meta:TaskType()
    return "dragonStar"
end
----------------------

-- 龙技能
local dragonSkill_meta = {}
dragonSkill_meta.__index = dragonSkill_meta
function dragonSkill_meta:Title()
    local config = self:Config()
    return string.format(_("将%s技能%s提升到等级%d"), Localize.dragon[config.type], Localize.dragon_skill[config.name], config.level)
end
function dragonSkill_meta:Desc()
    return Localize.dragon_skill_effection[self:Config().name]
end
function dragonSkill_meta:GetRewards()
    return get_rewards(self:Config())
end
function dragonSkill_meta:Config()
    return GrowUpTasks[self:TaskType()][self.id]
end
function dragonSkill_meta:TaskType()
    return "dragonSkill"
end
----------------------


-- 生产科技
local productionTech_meta = {}
productionTech_meta.__index = productionTech_meta
function productionTech_meta:Title()
    local config = self:Config()
    return string.format(_("将%s科技研发到等级%d"), Localize.productiontechnology_name[config.name], config.level)
end
function productionTech_meta:Desc()
    return Localize.productiontechnology_buffer[self:Config().name]
end
function productionTech_meta:GetRewards()
    return get_rewards(self:Config())
end
function productionTech_meta:Config()
    return GrowUpTasks[self:TaskType()][self.id]
end
function productionTech_meta:TaskType()
    return "productionTech"
end
----------------------

-- 生产科技
local militaryTech_meta = {}
militaryTech_meta.__index = militaryTech_meta
function militaryTech_meta:Title()
    local config = self:Config()
    return string.format(_("将%s科技研发到等级%d"), Localize.getMilitaryTechnologyName(config.name), config.level)
end
function militaryTech_meta:Desc()
    return Localize.getMilitaryTechnologyName(self:Config().name)
end
function militaryTech_meta:GetRewards()
    return get_rewards(self:Config())
end
function militaryTech_meta:Config()
    return GrowUpTasks[self:TaskType()][self.id]
end
function militaryTech_meta:TaskType()
    return "militaryTech"
end
----------------------

-- 士兵星级
local soldierStar_meta = {}
soldierStar_meta.__index = soldierStar_meta
function soldierStar_meta:Title()
    local config = self:Config()
    return string.format(_("将%s提升到星级%d"), Localize.soldier_name[config.name], config.star)
end
function soldierStar_meta:Desc()
    return Localize.soldier_name[self:Config().name]
end
function soldierStar_meta:GetRewards()
    return get_rewards(self:Config())
end
function soldierStar_meta:Config()
    return GrowUpTasks[self:TaskType()][self.id]
end
function soldierStar_meta:TaskType()
    return "soldierStar"
end
----------------------


-- 士兵星级
local soldierCount_meta = {}
soldierCount_meta.__index = soldierCount_meta
function soldierCount_meta:Title()
    local config = self:Config()
    return string.format(_("招募%s个%s"), config.count, Localize.soldier_name[config.name])
end
function soldierCount_meta:Desc()
    return Localize.soldier_name[self:Config().name]
end
function soldierCount_meta:GetRewards()
    return get_rewards(self:Config())
end
function soldierCount_meta:Config()
    return GrowUpTasks[self:TaskType()][self.id]
end
function soldierCount_meta:TaskType()
    return "soldierCount"
end
----------------------

-- pve探索
local pveCount_meta = {}
pveCount_meta.__index = pveCount_meta
function pveCount_meta:Title()
    return string.format(_("探索步数达到%d"), self:Config().count)
end
function pveCount_meta:Desc()
    return string.format(_("探索步数达到%d描述"), self:Config().count)
end
function pveCount_meta:GetRewards()
    return get_rewards(self:Config())
end
function pveCount_meta:Config()
    return GrowUpTasks[self:TaskType()][self.id]
end
function pveCount_meta:TaskType()
    return "pveCount"
end
----------------------

-- 攻击胜利
local attackWin_meta = {}
attackWin_meta.__index = attackWin_meta
function attackWin_meta:Title()
    return string.format(_("攻击玩家获胜%d次"), self:Config().count)
end
function attackWin_meta:Desc()
    return string.format(_("攻击玩家获胜%d次描述"), self:Config().count)
end
function attackWin_meta:GetRewards()
    return get_rewards(self:Config())
end
function attackWin_meta:Config()
    return GrowUpTasks[self:TaskType()][self.id]
end
function attackWin_meta:TaskType()
    return "attackWin"
end
----------------------

-- 攻击胜利
local strikeWin_meta = {}
strikeWin_meta.__index = strikeWin_meta
function strikeWin_meta:Title()
    return string.format(_("突袭玩家获胜%d次"), self:Config().count)
end
function strikeWin_meta:Desc()
    return string.format(_("突袭玩家获胜%d次描述"), self:Config().count)
end
function strikeWin_meta:GetRewards()
    return get_rewards(self:Config())
end
function strikeWin_meta:Config()
    return GrowUpTasks[self:TaskType()][self.id]
end
function strikeWin_meta:TaskType()
    return "strikeWin"
end
----------------------


-- 攻击胜利
local playerKill_meta = {}
playerKill_meta.__index = playerKill_meta
function playerKill_meta:Title()
    return string.format(_("击杀积分达到%d"), self:Config().kill)
end
function playerKill_meta:Desc()
    return string.format(_("击杀积分达到%d描述"), self:Config().kill)
end
function playerKill_meta:GetRewards()
    return get_rewards(self:Config())
end
function playerKill_meta:Config()
    return GrowUpTasks[self:TaskType()][self.id]
end
function playerKill_meta:TaskType()
    return "playerKill"
end
----------------------

-- power
local playerPower_meta = {}
playerPower_meta.__index = playerPower_meta
function playerPower_meta:Title()
    return string.format(_("power值到达%d"), self:Config().power)
end
function playerPower_meta:Desc()
    return string.format(_("power值到达%d描述"), self:Config().power)
end
function playerPower_meta:GetRewards()
    return get_rewards(self:Config())
end
function playerPower_meta:Config()
    return GrowUpTasks[self:TaskType()][self.id]
end
function playerPower_meta:TaskType()
    return "playerPower"
end
----------------------

local meta_map = {
    cityBuild = cityBuild_meta,
    dragonLevel = dragonLevel_meta,
    dragonStar = dragonStar_meta,
    dragonSkill = dragonSkill_meta,
    productionTech = productionTech_meta,
    militaryTech = militaryTech_meta,
    soldierStar = soldierStar_meta,
    soldierCount = soldierCount_meta,
    pveCount = pveCount_meta,
    attackWin = attackWin_meta,
    strikeWin = strikeWin_meta,
    playerKill = playerKill_meta,
    playerPower = playerPower_meta,
}
local find_gap = function(tag, diff_field)
    local a = GrowUpTasks[tag]
    if not diff_field then
        return #a + 1
    end
    for i = 0, #a do
        local before,current = a[i], a[i+1]
        if before then
            if not current or (current and before[diff_field] ~= current[diff_field]) then
                return before.index
            end
        end
    end
    assert(false)
end
local config_gap_map = {
    cityBuild = find_gap("cityBuild", "name"),
    dragonLevel = find_gap("dragonLevel", "type"),
    dragonStar = find_gap("dragonStar", "type"),
    dragonSkill = find_gap("dragonSkill", "name"),
    productionTech = find_gap("productionTech", "name"),
    militaryTech = find_gap("militaryTech", "name"),
    soldierStar = find_gap("soldierStar", "name"),
    soldierCount = find_gap("soldierCount", "name"),
    pveCount = find_gap("pveCount"),
    attackWin = find_gap("attackWin"),
    strikeWin = find_gap("strikeWin"),
    playerKill = find_gap("playerKill"),
    playerPower = find_gap("playerPower"),
}


---

---
local category_meta = {}
category_meta.__index = category_meta
function category_meta:Title()
    return category_localize[self.category]
end
function category_meta:Desc()
    return string.format("%s (%.2f%%)", self:Title(), self.available * 100)
end
---------



function GrowUpTaskManager:ctor()
    self.growUpTasks = {}
    for k,v in pairs(GameDatas.GrowUpTasks) do
        self.growUpTasks[k] = {}
    end
end
function GrowUpTaskManager:CompleteTasksByType(type_)
    return self.growUpTasks[type_]
end
function GrowUpTaskManager:GetFirstCompleteTasks()
    local r = {}
    for category,v in ipairs(CATEGORY) do
        for _,v in ipairs(self:GetFirstCompleteTasksByCategory(category)) do
            table.insert(r, v)
        end
    end
    return r
end
local type_map = {
    dragonLevel = true,
    dragonStar = true
}
local index_map = {
    pveCount = true,
    attackWin = true,
    strikeWin = true,
    playerPower = true,
    playerKill = true,
}
function GrowUpTaskManager:GetFirstCompleteTasksByCategory(category)
    local r = {}
    for _,tag in ipairs(category_map[category]) do
        local mark_map = {}
        local tasks = {}
        for i,v in ipairs(self.growUpTasks[tag]) do tasks[i] = v end
        table.sort(tasks, function(a, b) return a.id < b.id end)
        for _,v in ipairs(tasks) do
            local category_name = v.name
            if type_map[tag] then
                category_name = v.type
            elseif index_map[tag] then
                category_name = v.index
            end
            if not v.rewarded and not mark_map[category_name] then
                mark_map[category_name] = true
                table.insert(r, setmetatable(v, meta_map[tag]))
                if index_map[tag] then
                    break
                end
            end
        end
    end
    return r
end
function GrowUpTaskManager:GetAvailableTasksGroup()
    local r = {}
    for category,v in ipairs(CATEGORY) do
        table.insert(r, self:GetAvailableTasksByCategory(category))
    end
    return r
end
function GrowUpTaskManager:GetAvailableTasksByCategory(category)
    local r = {}
    local p = 0
    if category == CATEGORY.BUILD then
        local r1,count1,total1 = self:GetAvailableTaskByTag("cityBuild", function(available, is_init, cur, next_task)
            local name = cur.name
            if is_init then
                available[name] = cur.id
            else
                if next_task and next_task.name == name then
                    available[name] = next_task.id
                else
                    available[name] = nil
                end
            end
        end)
        table.sort(r1, function(a, b)
            return a.id < b.id
        end)
        r = r1
        p = count1 / total1
    elseif category == CATEGORY.DRAGON then
        local r1,count1,total1 = self:GetAvailableTaskByTag("dragonLevel", function(available, is_init, cur, next_task)
            local type = cur.type
            if is_init then
                available[type] = cur.id
            else
                if next_task and next_task.type == type then
                    available[type] = next_task.id
                else
                    available[type] = nil
                end
            end
        end)
        local r2,count2,total2 = self:GetAvailableTaskByTag("dragonStar", function(available, is_init, cur, next_task)
            local type = cur.type
            if is_init then
                available[type] = cur.id
            else
                if next_task and next_task.type == type then
                    available[type] = next_task.id
                else
                    available[type] = nil
                end
            end
        end)
        local r3,count3,total3 = self:GetAvailableTaskByTag("dragonSkill", function(available, is_init, cur, next_task)
            local name = cur.type.."_"..cur.name
            if is_init then
                available[name] = cur.id
            else
                if next_task and next_task.name == name then
                    available[name] = next_task.id
                else
                    available[name] = nil
                end
            end
        end)
        local dragons = {
            redDragon = {
                dragonLevel = {}, dragonStar = {}, dragonSkill = {}
            },
            greenDragon = {
                dragonLevel = {}, dragonStar = {}, dragonSkill = {}
            },
            blueDragon = {
                dragonLevel = {}, dragonStar = {}, dragonSkill = {}
            },
        }
        for _,v in ipairs(r1) do
            table.insert(dragons[v.type].dragonLevel, v)
        end
        for _,v in ipairs(r2) do
            table.insert(dragons[v.type].dragonStar, v)
        end
        for _,v in ipairs(r3) do
            table.insert(dragons[v.type].dragonSkill, v)
        end
        for _,v in pairs(dragons) do
            table.sort(v.dragonSkill, function(a,b)
                return a.id < b.id
            end)
        end
        for _,dragon_type in ipairs{"redDragon", "greenDragon", "blueDragon"} do
            local dragon = dragons[dragon_type]
            for _,v in ipairs(dragon.dragonLevel) do
                table.insert(r, v)
            end
            for _,v in ipairs(dragon.dragonStar) do
                table.insert(r, v)
            end
            for _,v in ipairs(dragon.dragonSkill) do
                table.insert(r, v)
            end
        end
        p = (count1 + count2 + count3) / (total1 + total2 + total3)
    elseif category == CATEGORY.TECHNOLOGY then
        local count, total = 0, 0
        for i,tag in ipairs(category_map[category]) do
            local r1,count1,total1 = self:GetAvailableTaskByTag(tag, function(available, is_init, cur, next_task)
                if is_init then
                    available[cur.name] = cur.id
                else
                    if next_task and next_task.name == cur.name then
                        available[cur.name] = next_task.id
                    else
                        available[cur.name] = nil
                    end
                end
            end)
            table.sort(r1, function(a, b)
                return a.id < b.id
            end)
            for _,v in ipairs(r1) do
                table.insert(r, v)
            end
            count = count + count1
            total = total + total1
        end
        p = count / total
    elseif category == CATEGORY.SOLDIER then
        local r1,count1,total1 = self:GetAvailableTaskByTag("soldierCount", function(available, is_init, cur, next_task)
            if is_init then
                available[cur.name] = cur.id
            else
                if next_task and next_task.name == cur.name then
                    available[cur.name] = next_task.id
                else
                    available[cur.name] = nil
                end
            end
        end)
        table.sort(r1, function(a, b)
            return a.id < b.id
        end)
        r = r1
        p = count1 / total1
    elseif category == CATEGORY.EXPLORE then
        local count, total = 0, 0
        for i,tag in ipairs(category_map[category]) do
            local r1,count1,total1 = self:GetAvailableTaskByTag(tag, function(available, is_init, cur, next_task)
                if is_init then
                    if cur.id == 0 then
                        available[1] = cur.id
                    end
                elseif next_task then
                    available[1] = next_task.id
                elseif available[1] == 0 then
                    available[1] = nil
                end
            end)
            table.sort(r1, function(a, b)
                return a.id < b.id
            end)
            for _,v in ipairs(r1) do
                table.insert(r, v)
            end
            count = count + count1
            total = total + total1
        end
        p = count / total
    end
    return setmetatable({tasks = r, available = p, category = category}, category_meta)
end
function GrowUpTaskManager:GetAvailableTaskByTag(tag, func)
    func = func or function()end
    local r = {}
    local available_map = {}
    local config = GrowUpTasks[tag]
    -- 默认初始化第一个任务
    local gap = config_gap_map[tag]
    for i = 0, #config, gap do
        func(available_map, true, config[i])
    end

    -- 找到未完成的任务id
    for i,v in ipairs(self.growUpTasks[tag]) do
        func(available_map, false, v, config[v.id + 1])
    end

    -- 找到未完成的任务
    local count = 0
    for k,v in pairs(available_map) do
        local t = config[v]
        count = count + (gap - t.index + 1)
        table.insert(r, setmetatable(t, meta_map[tag]))
    end
    return r, #config + 1 - count, #config + 1
end
function GrowUpTaskManager:GetCompleteTaskCount()
    local count = 0
    for _,category in pairs(self.growUpTasks) do
        for _,task in ipairs(category) do
            if not task.rewarded then
                count = count + 1
            end
        end
    end
    return count
end
function GrowUpTaskManager:OnUserDataChanged(userData, deltaData)
    local is_fully_update = deltaData == nil
    local is_delta_update = not is_fully_update and deltaData.growUpTasks
    if is_fully_update or is_delta_update then
        self.growUpTasks = userData.growUpTasks
        if GrowUpTaskManager.reward_callback and self:IsGetAnyCityBuildRewards() then
            GrowUpTaskManager.reward_callback()
            GrowUpTaskManager.reward_callback = nil
        end
        return true
    end
end
function GrowUpTaskManager:IsGetAnyCityBuildRewards()
    for i,v in ipairs(self:CompleteTasksByType("cityBuild")) do
        if v.id >= 0 and v.rewarded then
            return true
        end
    end
end
local promise = import("..utils.promise")
function GrowUpTaskManager:PromiseOfGetCityBuildRewards()
    local p = promise.new()
    GrowUpTaskManager.reward_callback = function()
        p:resolve()
    end
    return p
end



return GrowUpTaskManager









