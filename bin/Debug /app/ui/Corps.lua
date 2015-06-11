local promise = import("..utils.promise")
local cocos_promise = import("..utils.cocos_promise")
local UILib = import(".UILib")
local BattleObject = import(".BattleObject")
local Corps = class("Corps", BattleObject)

local normal = GameDatas.Soldiers.normal
local special = GameDatas.Soldiers.special

local soldier_config = {
    ["swordsman"] = {
        {"bubing_1", -90, -150, 0.8},
        {"bubing_2", -80, -135, 0.8},
        {"bubing_3", -80, -130, 0.8},
    },
    ["ranger"] = {
        {"gongjianshou_1", -90, -150, 0.8},
        {"gongjianshou_2", -75, -145, 0.8},
        {"gongjianshou_3", -75, -145, 0.8},
    },
    ["lancer"] = {
        {"qibing_1", -70, -150, 0.8},
        {"qibing_2", -70, -150, 0.8},
        {"qibing_3", -50, -150, 0.8},
    },
    ["catapult"] = {
        {  "toushiche", 30, -80, 1},
        {"toushiche_2", 30, -80, 1},
        {"toushiche_3", 20, -80, 1},
    },

    -----
    ["sentinel"] = {
        {"shaobing_1", -60, -140, 0.8},
        {"shaobing_2", -60, -140, 0.8},
        {"shaobing_3", -60, -140, 0.8},
    },
    ["crossbowman"] = {
        {"nugongshou_1", -90, -160, 0.8},
        {"nugongshou_2", -90, -160, 0.8},
        {"nugongshou_3", -105, -160, 0.8},
    },
    ["horseArcher"] = {
        {"youqibing_1", -70, -140, 0.8},
        {"youqibing_2", -60, -140, 0.8},
        {"youqibing_3", -60, -140, 0.8},
    },
    ["ballista"] = {
        {"nuche_1", 75, -100, 1},
        {"nuche_2", 85, -95, 1},
        {"nuche_3", 90, -80, 1},
    },
    ----
    ["skeletonWarrior"] = {
        {"kulouyongshi", -80, -160, 0.8},
        {"kulouyongshi", -80, -160, 0.8},
        {"kulouyongshi", -80, -160, 0.8},
    },
    ["skeletonArcher"] = {
        {"kulousheshou", -100, -150, 0.8},
        {"kulousheshou", -100, -150, 0.8},
        {"kulousheshou", -100, -150, 0.8},
    },
    ["deathKnight"] = {
        {"siwangqishi", -70, -145, 0.8},
        {"siwangqishi", -70, -145, 0.8},
        {"siwangqishi", -70, -145, 0.8},
    },
    ["meatWagon"] = {
        {"jiaorouche", 20, -100, 0.8},
        {"jiaorouche", 20, -100, 0.8},
        {"jiaorouche", 20, -100, 0.8},
    },
}
local pve_soldier_config = {
    ["swordsman"] = {
        {"bubing_1", -90, -150, 0.8},
        {"heihua_bubing_2", -100, -150, 0.8},
        {"heihua_bubing_3", -100, -145, 0.8},
    },
    ["ranger"] = {
        {"gongjianshou_1", -90, -150, 0.8},
        {"heihua_gongjianshou_2", -125, -150, 0.8},
        {"heihua_gongjianshou_3", -70, -145, 0.8},
    },
    ["lancer"] = {
        {"qibing_1", -70, -150, 0.8},
        {"heihua_qibing_2", -100, -150, 0.8},
        {"heihua_qibing_3", -50, -150, 0.8},
    },
    ["catapult"] = {
        {  "toushiche", 30, -80, 1},
        {"heihua_toushiche_2", 20, -100, 1},
        {"heihua_toushiche_3", 20, -100, 1},
    },

    -----
    ["sentinel"] = {
        {"shaobing_1", -60, -140, 0.8},
        {"heihua_shaobing_2", -110, -130, 0.8},
        {"heihua_shaobing_3", -110, -130, 0.8},
    },
    ["crossbowman"] = {
        {"nugongshou_1", -90, -160, 0.8},
        {"heihua_nugongshou_2", -110, -160, 0.8},
        {"heihua_nugongshou_3", -105, -150, 0.8},
    },
    ["horseArcher"] = {
        {"youqibing_1", -70, -140, 0.8},
        {"heihua_youqibing_2", -70, -140, 0.8},
        {"heihua_youqibing_3", -65, -140, 0.8},
    },
    ["ballista"] = {
        {"nuche_1", 75, -100, 1},
        {"heihua_nuche_2", 0, -130, 1},
        {"heihua_nuche_3", 20, -120, 1},
    },
}
setmetatable(pve_soldier_config, {
    __index = soldier_config
})
local AUDIO_TAG = 11
local function return_x_y_by_index(start_x, start_y, width, height, row_max, col_max, index)
    local unit_height = height / row_max
    local unit_width = width / col_max
    local cur_row = row_max - index % row_max - 1
    local cur_col = math.floor(index / row_max)
    return start_x + (cur_col + 0.5) * unit_width, start_y + (cur_row + 0.5) * unit_height
end
function Corps:ctor(soldier, star, row, col, width, height, is_pve_soldier, ui_replay)
    Corps.super.ctor(self, ui_replay)
    self.soldier = soldier
    self.config = special[self.soldier] or normal[self.soldier.."_"..star]
    self.star = self.config.star
    
    local corps_config = is_pve_soldier and pve_soldier_config or soldier_config
    local cur_config = corps_config[self.soldier][self.star]
    local ani_name, start_x, start_y,_ = unpack(cur_config)

    width = width or 180
    height = height or 240
    local row_max = row or 4
    local col_max = col or 2
    local t = {}
    for i = 0, col_max * row_max - 1 do
        local armature = ccs.Armature:create(ani_name):addTo(self):scale(1)
        :pos(return_x_y_by_index(start_x, start_y, width, height, row_max, col_max, i))
        table.insert(t, armature)
    end
    self.corps = t
    for _, v in pairs(self.corps) do
        v:getAnimation():setMovementEventCallFunc(handler(self, self.OnAnimationCallback))
        break
    end
end
function Corps:PlayAnimation(ani, loop_time)
    if ani == "attack" then
        app:GetAudioManager():PlayeAttackSoundBySoldierName(self.soldier)
    end
    for _, v in pairs(self.corps) do
        v:getAnimation():play(ani, -1, loop_time or -1)
        v:getAnimation():setSpeedScale(self:Speed())
    end
end
function Corps:StopAnimation()
    for _, v in pairs(self.corps) do
        v:getAnimation():gotoAndPause(0)
    end
end
function Corps:breath(is_forever)
    if self.config.type == "siege" then
        self:StopAnimation()
        return cocos_promise.defer(function()
            return self
        end)
    else
        self:PlayAnimation("idle_90", is_forever and -1 or 0)
        local p = promise.new()
        self:OnAnimationPlayEnd("idle_90", function()
            p:resolve(self)
        end)
        return p
    end
end
function Corps:turnLeft()
    self:setScaleX(-1)
    return self
end
function Corps:turnRight()
    self:setScaleX(1)
    return self
end
function Corps:GetSoldierConfig()
    return special[self.soldier] or normal[self.soldier.."_"..self.star]
end
function Corps:move(time, x, y)
    local config = self:GetSoldierConfig()
    local type_ = config.type
    local function step()
        app:GetAudioManager():PlaySoldierStepEffectByType(type_)
    end
    local speed = cc.Speed:create(
        transition.sequence{
            cc.CallFunc:create(step),
            cc.DelayTime:create(0.5),
            cc.CallFunc:create(step),
            cc.DelayTime:create(0.5),
            cc.CallFunc:create(step),
            cc.DelayTime:create(0.5),
            cc.CallFunc:create(step),
            cc.DelayTime:create(0.5),
            cc.CallFunc:create(step)
        }, self:Speed())
    speed:setTag(AUDIO_TAG)
    self:runAction(speed)
    return Corps.super.move(self, time, x, y)
end
function Corps:Stop()
    Corps.super.Stop(self)
    for _, v in pairs(self.corps) do
        v:getAnimation():stop()
    end
end
function Corps:RefreshSpeed()
    Corps.super.RefreshSpeed(self)
    local a = self:getActionByTag(AUDIO_TAG)
    if a then
        a:setSpeed(self:Speed())
    end
    for _, v in pairs(self.corps) do
        v:getAnimation():setSpeedScale(self:Speed())
    end
end
return Corps










