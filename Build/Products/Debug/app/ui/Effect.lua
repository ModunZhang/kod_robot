local promise = import("..utils.promise")
local UILib = import(".UILib")
local BattleObject = import(".BattleObject")
local Effect = class("Effect", BattleObject)


function Effect:ctor(soldier, row, col)
	Effect.super.ctor(self)
    local start_x, start_y = -90, -120
    local width, height = - start_x * 2, - start_y * 2
    local function return_x_y_by_index(row_max, col_max, index)
        local unit_height = height / row_max
        local unit_width = width / col_max
        local cur_row = row_max - index % row_max - 1
        local cur_col = math.floor(index / row_max)
        return start_x + (cur_col + 0.5) * unit_width, start_y + (cur_row + 0.5) * unit_height
    end
    local row_max = row or 4
    local col_max = col or 2
    local t = {}
    local ani = UILib.soldier_effect[soldier][1] or "Swordsman_effects"
    for i = 0, col_max * row_max - 1 do
        print(UILib.soldier_effect[soldier][1])
        local armature = ccs.Armature:create(ani):addTo(self):scale(0.5):pos(return_x_y_by_index(row_max, col_max, i))
        table.insert(t, armature)
    end
    self.effects = t
    for _, v in pairs(self.effects) do
        v:getAnimation():setMovementEventCallFunc(handler(self, self.OnAnimationCallback))
        break
    end
end
function Effect:PlayAnimation(ani, loop_time)
    for _, v in pairs(self.effects) do
        v:getAnimation():play(ani, -1, loop_time or -1)
    end
end
function Effect:turnLeft()
    self:setScaleX(-1)
end
function Effect:turnRight()
    self:setScaleX(1)
end
return Effect







