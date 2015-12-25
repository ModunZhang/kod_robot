local promise = import("..utils.promise")
local cocos_promise = import("..utils.cocos_promise")
local UILib = import(".UILib")
local BattleObject = import(".BattleObject")
local Corps = class("Corps", BattleObject)

local normal = GameDatas.Soldiers.normal
local special = GameDatas.Soldiers.special

local soldier_config = {
    ["swordsman_1"] = {"bubing_1_90", -90, -150, 0.8},
    ["swordsman_2"] = {"bubing_2_90", -80, -135, 0.8},
    ["swordsman_3"] = {"bubing_3_90", -80, -130, 0.8},

    ["ranger_1"] = {"gongjianshou_1_90", -90, -150, 0.8},
    ["ranger_2"] = {"gongjianshou_2_90", -75, -145, 0.8},
    ["ranger_3"] = {"gongjianshou_3_90", -75, -145, 0.8},
    
    ["lancer_1"] = {"qibing_1_90", -70, -150, 0.8},
    ["lancer_2"] = {"qibing_2_90", -70, -150, 0.8},
    ["lancer_3"] = {"qibing_3_90", -50, -150, 0.8},
    
    ["catapult_1"] = {  "toushiche_90", 30, -80, 1},
    ["catapult_2"] = {"toushiche_2_90", 30, -80, 1},
    ["catapult_3"] = {"toushiche_3_90", 20, -80, 1},

    ["sentinel_1"] = {"shaobing_1_90", -60, -140, 0.8},
    ["sentinel_2"] = {"shaobing_2_90", -60, -140, 0.8},
    ["sentinel_3"] = {"shaobing_3_90", -60, -140, 0.8},

    ["crossbowman_1"] = {"nugongshou_1_90", -90, -160, 0.8},
    ["crossbowman_2"] = {"nugongshou_2_90", -90, -160, 0.8},
    ["crossbowman_3"] = {"nugongshou_3_90", -105, -160, 0.8},
   
    ["horseArcher_1"] = {"youqibing_1_90", -70, -140, 0.8},
    ["horseArcher_2"] = {"youqibing_2_90", -60, -140, 0.8},
    ["horseArcher_3"] = {"youqibing_3_90", -60, -140, 0.8},
    
    ["ballista_1"] = {"nuche_1_90", 75, -100, 1},
    ["ballista_2"] = {"nuche_2_90", 85, -95, 1},
    ["ballista_3"] = {"nuche_3_90", 90, -80, 1},

    ----
    ["skeletonWarrior"] = {"kulouyongshi_90", -80, -160, 0.8},
    ["skeletonArcher"] = {"kulousheshou_90", -100, -150, 0.8},
    ["deathKnight"] = {"siwangqishi_90", -70, -145, 0.8},
    ["meatWagon"] = {"jiaorouche_90", 20, -100, 0.8},
}
local pve_soldier_config = {
    ["swordsman_1"] = {"bubing_1_90", -90, -150, 0.8},
    ["swordsman_2"] = {"heihua_bubing_2_90", -100, -150, 0.8},
    ["swordsman_3"] = {"heihua_bubing_3_90", -100, -145, 0.8},

    ["ranger_1"] = {"gongjianshou_1_90", -90, -150, 0.8},
    ["ranger_2"] = {"heihua_gongjianshou_2_90", -125, -150, 0.8},
    ["ranger_3"] = {"heihua_gongjianshou_3_90", -70, -145, 0.8},
    
    ["lancer_1"] = {"qibing_1_90", -70, -150, 0.8},
    ["lancer_2"] = {"heihua_qibing_2_90", -100, -150, 0.8},
    ["lancer_3"] = {"heihua_qibing_3_90", -50, -150, 0.8},
    
    ["catapult_1"] = {  "toushiche_90", 30, -80, 1},
    ["catapult_2"] = {"heihua_toushiche_2_90", 20, -100, 1},
    ["catapult_3"] = {"heihua_toushiche_3_90", 20, -100, 1},

    ["sentinel_1"] = {"shaobing_1_90", -60, -140, 0.8},
    ["sentinel_2"] = {"heihua_shaobing_2_90", -110, -130, 0.8},
    ["sentinel_3"] = {"heihua_shaobing_3_90", -110, -130, 0.8},

    ["crossbowman_1"] = {"nugongshou_1_90", -90, -160, 0.8},
    ["crossbowman_2"] = {"heihua_nugongshou_2_90", -110, -160, 0.8},
    ["crossbowman_3"] = {"heihua_nugongshou_3_90", -105, -150, 0.8},
   
    ["horseArcher_1"] = {"youqibing_1_90", -70, -140, 0.8},
    ["horseArcher_2"] = {"heihua_youqibing_2_90", -70, -140, 0.8},
    ["horseArcher_3"] = {"heihua_youqibing_3_90", -65, -140, 0.8},
    
    ["ballista_1"] = {"nuche_1_90", 75, -100, 1},
    ["ballista_2"] = {"heihua_nuche_2_90", 0, -130, 1},
    ["ballista_3"] = {"heihua_nuche_3_90", 20, -120, 1},
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
    self.star =star
    
    local corps_config = is_pve_soldier and pve_soldier_config or soldier_config
    local cur_config = corps_config[self.soldier]
    print("self.soldier=",self.soldier)
    dump(cur_config,"cur_config")
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
        self:PlayAnimation("move_90")
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










