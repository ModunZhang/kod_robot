

local offset = function(x, y)
    return {x = x, y = y}
end
local function create_flip_none()
    return {x = false, y = false}
end
local function create_flip_x()
    return {x = true, y= false}
end
local function create_flip_y()
    return {x = false, y= true}
end
local function create_flip_both()
    return {x = true, y= true}
end
local shadow = function(shadow_png, shadow_offset, shadow_scale)
    return {png = shadow_png, offset = shadow_offset, scale = shadow_scale}
end
local FLIP = true
local NOT_FLIP = false
local value_return = function(value)
    return value
end
local scale = value_return
local level = value_return


local decorator = function(deco_type, deco_name, offset, scale, always)
    return {deco_type = deco_type, deco_name = deco_name, offset = offset or {}, scale = scale, always = always}
end
local function create_config(b, e, png, offset, scale, ...)
    return {
        ["begin"] = b,
        ["ending"] = e,
        ["png"] = png,
        ["offset"] = offset == nil and offset(0, 0) or offset,
        ["scale"] = scale == nil and 1 or scale,
        ["decorator"] = {...}
    }
end



local MAX_LEVEL = math.huge
local MIN_LEVEL = - 9999999
local SpriteConfig = {}
local function create_building_config(building_config, ...)
    local building_type = building_config[1]
    table.remove(building_config, 1)
    local static_images = building_config
    local config = {}
    for i, v in ipairs({...}) do
        table.insert(config, v)
    end
    assert(SpriteConfig[building_type] == nil, "重复初始化建筑配置表")

    function config:GetConfigByLevel(level)
        for i, v in ipairs(self) do
            if v.begin <= level and level <= v.ending then
                return v, i
            end
        end
        assert(false, "没有找到建筑配置表")
    end
    function config:GetAnimationConfigsByLevel(level)
        local config = self:GetConfigByLevel(level)
        local r = {}
        for _,v in ipairs(config.decorator) do
            if v.always then
                table.insert(r, v)
            end
        end
        return r
    end
    function config:GetStaticImagesByLevel(level)
        return  static_images
    end
    SpriteConfig[building_type] = config
end




local function smoke(x, y, s)
    s = s or 0.8
    smoke_offset_x = 276*0.5*s
    smoke_offset_y = 274*0.5*s
    return decorator("animation", "yan", offset(x + smoke_offset_x, y + smoke_offset_y), scale(s))
end


create_building_config(
    {"other_keep"}
    ,create_config(MIN_LEVEL, level(1), "other_keep_1.png", offset(60, 225), scale(1))
    ,create_config(level(2), level(5), "other_keep_2.png", offset(60, 245), scale(1))
    ,create_config(level(6), MAX_LEVEL, "other_keep_3.png", offset(60, 285), scale(1))
)
create_building_config(
    {"my_keep"}
    ,create_config(MIN_LEVEL, level(1), "my_keep_1.png", offset(60, 225), scale(1))
    ,create_config(level(2), level(5), "my_keep_2.png", offset(60, 245), scale(1))
    ,create_config(level(6), MAX_LEVEL, "my_keep_3.png", offset(60, 285), scale(1))
)

create_building_config(
    {"keep"}
    ,create_config(MIN_LEVEL, level(1), "keep_1.png", offset(60, 225), scale(1), decorator("image", "keep_1_d.png", offset(124, -100)))
    ,create_config(level(2), level(5), "keep_2.png", offset(60, 245), scale(1), decorator("image", "keep_2_d.png", offset(126, -126)))
    ,create_config(level(6), MAX_LEVEL, "keep_3.png", offset(60, 285), scale(1), decorator("image", "keep_3_d.png", offset(121, -167)))
)
create_building_config(
    {"dragonEyrie"}
    ,create_config(MIN_LEVEL, MAX_LEVEL, "dragonEyrie.png", offset(45, 158), scale(1))
)
create_building_config(
    {"watchTower", "#root/liaowangta/00000.png"}
    ,create_config(MIN_LEVEL, MAX_LEVEL, "watchTower.png", offset(50, 180), scale(1), decorator("animation", "liaowangta", nil, nil, true))
)
create_building_config(
    {"warehouse", "#root/ziyuancangku/00000.png"}
    ,create_config(MIN_LEVEL, MAX_LEVEL, "warehouse.png", offset(-5, 105), scale(1), decorator("animation", "ziyuancangku", nil, nil, true))
)
create_building_config(
    {"toolShop"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "toolShop.png", offset(20, 100), scale(1), smoke(100, 147))
)
create_building_config(
    {"materialDepot"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "materialDepot.png", offset(20, 100), scale(1))
)
create_building_config(
    {"armyCamp"}
    ,create_config(MIN_LEVEL, MAX_LEVEL, "armyCamp.png", offset(20, 100), scale(1))
)
create_building_config(
    {"barracks", "#root/bingying/qizi/00000.png"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "barracks.png", offset(20, 120), scale(1), decorator("animation", "bingyin_1"), decorator("animation", "bingyin", nil, nil, true))
)
create_building_config(
    {"blackSmith"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "blackSmith.png", offset(20, 100), scale(1), smoke(17, 181), smoke(28, 196))
)
create_building_config(
    {"foundry"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "foundry.png", offset(20, 120), scale(1), smoke(45, 203), smoke(69, 170))
)
create_building_config(
    {"stoneMason"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "stoneMason.png", offset(20, 100), scale(1))
)
create_building_config(
    {"lumbermill"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "lumbermill.png", offset(20, 100), scale(1))
)
create_building_config(
    {"mill", "#root/mofang/00000.png"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "mill.png", offset(20, 100), scale(1), decorator("animation", "mofang", nil, nil, true))
)
create_building_config(
    {"hospital"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "hospital.png", offset(40, 100), scale(1), decorator("animation", "yiyuan"))
)
create_building_config(
    {"townHall"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "townHall.png", offset(20, 140), scale(1), decorator("animation", "shizhenting"))
)
create_building_config(
    {"tradeGuild", "#root/maoyihanghui/000.png"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "tradeGuild.png", offset(20, 100), scale(1), decorator("animation", "maoyihanghui", nil, nil, true))
)
create_building_config(
    {"academy"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "academy.png", offset(20, 120), scale(1), decorator("animation", "xueyuan"))
)
create_building_config(
    {"workshop"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "workShop.png", offset(20, 130), scale(1), smoke(19, 181))
)
create_building_config(
    {"trainingGround"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "trainingGround.png", offset(20, 100), scale(1))
)
create_building_config(
    {"hunterHall"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "hunterHall.png", offset(20, 100), scale(1))
)
create_building_config(
    {"stable"}
    ,create_config(MIN_LEVEL, 0, "locked_tile.png", offset(20, 120), scale(1))
    ,create_config(1, MAX_LEVEL, "stable.png", offset(20, 130), scale(1))
)
-- 装饰小屋
create_building_config(
    {"dwelling"}
    ,create_config(MIN_LEVEL, level(1), "dwelling_1.png", offset(0, 50), scale(1))
    ,create_config(level(2), level(2), "dwelling_2.png", offset(0, 60), scale(1))
    ,create_config(level(3), MAX_LEVEL, "dwelling_3.png", offset(0, 60), scale(1))
)
create_building_config(
    {"farmer"}
    ,create_config(MIN_LEVEL, level(1), "farmer_1.png", offset(0, 50), scale(1))
    ,create_config(level(2), level(2), "farmer_2.png", offset(0, 50), scale(1))
    ,create_config(level(3), MAX_LEVEL, "farmer_3.png", offset(0, 50), scale(1))
)
create_building_config(
    {"woodcutter"}
    ,create_config(MIN_LEVEL, level(1), "woodcutter_1.png", offset(0, 50), scale(1))
    ,create_config(level(2), level(2), "woodcutter_2.png", offset(0, 60), scale(1))
    ,create_config(level(3), MAX_LEVEL, "woodcutter_3.png", offset(0, 70), scale(1))
)
create_building_config(
    {"quarrier"}
    ,create_config(MIN_LEVEL, level(1), "quarrier_1.png", offset(0, 50), scale(1))
    ,create_config(level(2), level(2), "quarrier_2.png", offset(0, 60), scale(1))
    ,create_config(level(3), MAX_LEVEL, "quarrier_3.png", offset(0, 70), scale(1))
)
create_building_config(
    {"miner"}
    ,create_config(MIN_LEVEL, level(1), "miner_1.png", offset(0, 50), scale(1))
    ,create_config(level(2), level(2), "miner_2.png", offset(0, 50), scale(1))
    ,create_config(level(3), MAX_LEVEL, "miner_3.png", offset(0, 50), scale(1))
)

-- walls
create_building_config(
    {"wall"}
    ,create_config(MIN_LEVEL, level(1), "gate_1.png", offset(0, 100), scale(1))
    ,create_config(level(2), level(2), "gate_2.png", offset(0, 100), scale(1))
    ,create_config(level(3), MAX_LEVEL, "gate_3.png", offset(0, 100), scale(1))
)
create_building_config(
    {"tower"}
    ,create_config(MIN_LEVEL, level(1), "tower_none_1.png", offset(0, 100), scale(1))
    ,create_config(level(2), level(2), "tower_none_2.png", offset(0, 100), scale(1))
    ,create_config(level(3), MAX_LEVEL, "tower_none_3.png", offset(0, 100), scale(1))
)

-- village
create_building_config(
    {"coinVillage"}
    ,create_config(MIN_LEVEL, level(3), "dwelling_1.png", offset(0, 50), scale(1))
    ,create_config(level(4), level(6), "dwelling_2.png", offset(0, 60), scale(1))
    ,create_config(level(7), MAX_LEVEL, "dwelling_3.png", offset(0, 60), scale(1))
)
create_building_config(
    {"foodVillage"}
    ,create_config(MIN_LEVEL, level(3), "farmer_1.png", offset(0, 50), scale(1))
    ,create_config(level(4), level(6), "farmer_2.png", offset(0, 50), scale(1))
    ,create_config(level(7), MAX_LEVEL, "farmer_3.png", offset(0, 50), scale(1))
)
create_building_config(
    {"woodVillage"}
    ,create_config(MIN_LEVEL, level(3), "woodcutter_1.png", offset(0, 50), scale(1))
    ,create_config(level(4), level(6), "woodcutter_2.png", offset(0, 60), scale(1))
    ,create_config(level(7), MAX_LEVEL, "woodcutter_3.png", offset(0, 70), scale(1))
)
create_building_config(
    {"stoneVillage"}
    ,create_config(MIN_LEVEL, level(3), "quarrier_1.png", offset(0, 50), scale(1))
    ,create_config(level(4), level(6), "quarrier_2.png", offset(0, 60), scale(1))
    ,create_config(level(7), MAX_LEVEL, "quarrier_3.png", offset(0, 70), scale(1))
)
create_building_config(
    {"ironVillage"}
    ,create_config(MIN_LEVEL, level(3), "miner_1.png", offset(0, 50), scale(1))
    ,create_config(level(4), level(6), "miner_2.png", offset(0, 50), scale(1))
    ,create_config(level(7), MAX_LEVEL, "miner_3.png", offset(0, 50), scale(1))
)

return SpriteConfig
























