local function getAniNameFromAnimationFileName(file_name)
    local i, j = string.find(file_name, "[%w_]*%.")
    return string.sub(file_name, i, j - 1)
end
local function getAniNameFromAnimationFiles(animation_files)
    local anis = {}
    for i, v in pairs(animation_files) do
        anis[i] = LuaUtils:table_map(v, function(k, file_name)
            return k, getAniNameFromAnimationFileName(file_name)
        end)
    end
    return anis
end

local PLAYER_ICON = {
    [0] = "Icon_empireRise_91x117.png", -- 系统头像
    "player_icon_1.png",
    "player_icon_2.png",
    "player_icon_3.png",
    "player_icon_4.png",
    "player_icon_5.png",
    "player_icon_6.png",
    -- 以上为默认解锁头像
    "player_icon_7.png",
    "player_icon_8.png",
    "player_icon_9.png",
    "player_icon_10.png",
    "player_icon_11.png",
}
local UI_ANIMATION_FILES = {
    "animations/win.ExportJson"
}

local BUILDING_ANIMATIONS_FILES = {
    watchTower = {
        "animations/liaowangta.ExportJson"
    },
    barracks = {
        "animations/bingyin.ExportJson",
        "animations/bingyin_1.ExportJson"
    },
    tradeGuild = {
        "animations/maoyihanghui.ExportJson",
    },
    mill = {
        "animations/mofang.ExportJson",
    },
    townHall = {
        "animations/shizhenting.ExportJson",
    },
    academy = {
        "animations/xueyuan.ExportJson",
    },
    hospital = {
        "animations/yiyuan.ExportJson",
    },
    warehouse = {
        "animations/ziyuancangku.ExportJson",
    },
    hammer = {
        "animations/chuizi.ExportJson",
    },
    airShip = {
        "animations/feiting.ExportJson",
    },
    citizen = {
        "animations/caodi_nan.ExportJson",
        "animations/caodi_nv.ExportJson",
        "animations/xuedi_nan.ExportJson",
        "animations/xuedi_nv.ExportJson",
        "animations/shadi_nan.ExportJson",
        "animations/shadi_nv.ExportJson",
    },
    bird = {
        "animations/gezi.ExportJson",
    },
    box = {
        "animations/lanse.ExportJson",
        "animations/lvse_box.ExportJson",
        "animations/zise_box.ExportJson",
        "animations/mu_box.ExportJson",
        "animations/tong_box.ExportJson",
        "animations/yin_box.ExportJson",
        "animations/jin_box.ExportJson",
        "animations/Box_guang.ExportJson",
    }
}
local BUILDING_ANIMATIONS = getAniNameFromAnimationFiles(BUILDING_ANIMATIONS_FILES)
local RESOURCE = {
    blood = "heroBlood_3_128x128.png",
    food = "res_food_91x74.png",
    wood = "res_wood_82x73.png",
    stone = "res_stone_88x82.png",
    iron = "res_iron_91x63.png",
    coin = "res_coin_81x68.png",
    wallHp = "gate_1.png",
    gem = "gem_icon_62x61.png",
}
local MATERIALS = {
    blueprints = "blueprints_128x128.png",
    tools =  "tools_128x128.png",
    tiles = "tiles_128x128.png",
    pulley = "pulley_128x128.png",
    trainingFigure = "trainingFigure_128x128.png",
    bowTarget = "bowTarget_128x128.png",
    saddle = "saddle_128x128.png",
    ironPart = "ironPart_128x128.png",
}
local DRAGON_MATERIAL_PIC_MAP = {
    ["ingo_1"] = "ironIngot_128x128.png",
    ["ingo_2"] = "steelIngot_128x128.png",
    ["ingo_3"] = "mithrilIngot_128x128.png",
    ["ingo_4"] = "blackIronIngot_128x128.png",
    ["redSoul_2"] = "redSoul_2_128x128.png",
    ["redSoul_3"] = "redSoul_3_128x128.png",
    ["redSoul_4"] = "redSoul_4_128x128.png",
    ["blueSoul_2"] = "blueSoul_2_128x128.png",
    ["blueSoul_3"] = "blueSoul_3_128x128.png",
    ["blueSoul_4"] = "blueSoul_4_128x128.png",
    ["greenSoul_2"] = "greenSoul_2_128x128.png",
    ["greenSoul_3"] = "greenSoul_3_128x128.png",
    ["greenSoul_4"] = "greenSoul_4_128x128.png",
    ["redCrystal_1"] = "flawedRedCrystal_128x128.png",
    ["redCrystal_2"] = "redCrystal_128x128.png",
    ["redCrystal_3"] = "flawlessRedCrystal_128x128.png",
    ["redCrystal_4"] = "perfectRedCrystal_128x128.png",
    ["blueCrystal_1"] = "flawedBlueCrystal_128x128.png",
    ["blueCrystal_2"] = "blueCrystal_128x128.png",
    ["blueCrystal_3"] = "flawlessBlueCrystal_128x128.png",
    ["blueCrystal_4"] = "perfectBlueCrystal_128x128.png",
    ["greenCrystal_1"] = "flawedGreenCrystal_128x128.png",
    ["greenCrystal_2"] = "greenCrystal_128x128.png",
    ["greenCrystal_3"] = "flawlessGreenCrystal_128x128.png",
    ["greenCrystal_4"] = "perfectGreenCrystal_128x128.png",
    ["runes_1"] = "ancientRunes_128x128.png",
    ["runes_2"] = "elementalRunes_128x128.png",
    ["runes_3"] = "pureRunes_128x128.png",
    ["runes_4"] = "titanRunes_128x128.png",
}
local SOLDIER_METARIAL = {
    ["heroBones"] = "heroBones_128x128.png",
    ["magicBox"] = "magicBox_128x128.png",
    ["holyBook"] = "magicBox_128x128.png",
    ["brightAlloy"] = "magicBox_128x128.png",
    ["soulStone"] = "soulStone_128x128.png",
    ["deathHand"] = "deathHand_128x128.png",
    ["confessionHood"] = "magicBox_128x128.png",
    ["brightRing"] = "magicBox_128x128.png",
}
local EQUIPMENT = {
    ["redCrown_s1"] = "redCrown_s1_128x128.png",
    ["redCrown_s2"] = "redCrown_s2_128x128.png",
    ["redCrown_s3"] = "redCrown_s3_128x128.png",
    ["redCrown_s4"] = "redCrown_s4_128x128.png",
    ["blueCrown_s1"] = "blueCrown_s1_128x128.png",
    ["blueCrown_s2"] = "blueCrown_s2_128x128.png",
    ["blueCrown_s3"] = "blueCrown_s3_128x128.png",
    ["blueCrown_s4"] = "blueCrown_s4_128x128.png",
    ["greenCrown_s1"] = "greenCrown_s1_128x128.png",
    ["greenCrown_s2"] = "greenCrown_s2_128x128.png",
    ["greenCrown_s3"] = "greenCrown_s3_128x128.png",
    ["greenCrown_s4"] = "greenCrown_s4_128x128.png",
    ["redChest_s2"] = "redChest_s2_128x128.png",
    ["redChest_s3"] = "redChest_s3_128x128.png",
    ["redChest_s4"] = "redChest_s4_128x128.png",
    ["blueChest_s2"] = "blueChest_s2_128x128.png",
    ["blueChest_s3"] = "blueChest_s3_128x128.png",
    ["blueChest_s4"] = "blueChest_s4_128x128.png",
    ["greenChest_s2"] = "greenChest_s2_128x128.png",
    ["greenChest_s3"] = "greenChest_s3_128x128.png",
    ["greenChest_s4"] = "greenChest_s4_128x128.png",
    ["redSting_s2"] = "redSting_s2_128x128.png",
    ["redSting_s3"] = "redSting_s3_128x128.png",
    ["redSting_s4"] = "redSting_s4_128x128.png",
    ["blueSting_s2"] = "blueSting_s2_128x128.png",
    ["blueSting_s3"] = "blueSting_s3_128x128.png",
    ["blueSting_s4"] = "blueSting_s4_128x128.png",
    ["greenSting_s2"] = "greenSting_s2_128x128.png",
    ["greenSting_s3"] = "greenSting_s3_128x128.png",
    ["greenSting_s4"] = "greenSting_s4_128x128.png",
    ["redOrd_s2"] = "redOrd_s2_128x128.png",
    ["redOrd_s3"] = "redOrd_s3_128x128.png",
    ["redOrd_s4"] = "redOrd_s4_128x128.png",
    ["blueOrd_s2"] = "blueOrd_s2_128x128.png",
    ["blueOrd_s3"] = "blueOrd_s3_128x128.png",
    ["blueOrd_s4"] = "blueOrd_s4_128x128.png",
    ["greenOrd_s2"] = "greenOrd_s2_128x128.png",
    ["greenOrd_s3"] = "greenOrd_s3_128x128.png",
    ["greenOrd_s4"] = "greenOrd_s4_128x128.png",
    ["redArmguard_s1"] = "redArmguard_s1_128x128.png",
    ["redArmguard_s2"] = "redArmguard_s2_128x128.png",
    ["redArmguard_s3"] = "redArmguard_s3_128x128.png",
    ["redArmguard_s4"] = "redArmguard_s4_128x128.png",
    ["blueArmguard_s1"] = "blueArmguard_s1_128x128.png",
    ["blueArmguard_s2"] = "blueArmguard_s2_128x128.png",
    ["blueArmguard_s3"] = "blueArmguard_s3_128x128.png",
    ["blueArmguard_s4"] = "blueArmguard_s4_128x128.png",
    ["greenArmguard_s1"] = "greenArmguard_s1_128x128.png",
    ["greenArmguard_s2"] = "greenArmguard_s2_128x128.png",
    ["greenArmguard_s3"] = "greenArmguard_s3_128x128.png",
    ["greenArmguard_s4"] = "greenArmguard_s4_128x128.png",
}

local EFFECT_ANIMATION_FILES = {
    ranger = {
        "animations/swordsman_effect/Swordsman_effects.ExportJson",
    },
    crossbowman = {
        "animations/swordsman_effect/Swordsman_effects.ExportJson",
    },
    catapult = {
        "animations/catapult_effect/Catapult1effects.ExportJson",
    },
    ballista = {
        "animations/catapult_effect/Catapult1effects.ExportJson",
    },
    lancer = {
        "animations/lancer_effect/Lancer_effects.ExportJson",
    },
    horseArcher = {
        "animations/lancer_effect/Lancer_effects.ExportJson",
    },
    swordsman = {
        "animations/swordsman_effect/Swordsman_effects.ExportJson",
    },
    sentinel = {
        "animations/swordsman_effect/Swordsman_effects.ExportJson",
    },
    wall = {
        "animations/swordsman_effect/Swordsman_effects.ExportJson",
    }
}
local SOLDIER_ANIMATION_FILES = {
    ranger = {
        "animations/gongjianshou_1.ExportJson",
        "animations/gongjianshou_2.ExportJson",
        "animations/gongjianshou_3.ExportJson",
    },
    crossbowman = {
        "animations/nugongshou_1.ExportJson",
        "animations/nugongshou_2.ExportJson",
        "animations/nugongshou_3.ExportJson",
    },
    catapult = {
        "animations/toushiche.ExportJson",
        "animations/toushiche_2.ExportJson",
        "animations/toushiche_3.ExportJson",
    },
    ballista = {
        "animations/nuche_1.ExportJson",
        "animations/nuche_2.ExportJson",
        "animations/nuche_3.ExportJson",
    },
    lancer = {
        "animations/qibing_1.ExportJson",
        "animations/qibing_2.ExportJson",
        "animations/qibing_3.ExportJson",
    },
    horseArcher = {
        "animations/youqibing_1.ExportJson",
        "animations/youqibing_2.ExportJson",
        "animations/youqibing_3.ExportJson",
    },
    swordsman = {
        "animations/bubing_1.ExportJson",
        "animations/bubing_2.ExportJson",
        "animations/bubing_3.ExportJson",
    },
    sentinel = {
        "animations/shaobing_1.ExportJson",
        "animations/shaobing_2.ExportJson",
        "animations/shaobing_3.ExportJson",
    },
    skeletonWarrior = {
        "animations/kulouyongshi.ExportJson",
    },
    skeletonArcher = {
        "animations/kulousheshou.ExportJson",
    },
    deathKnight = {
        "animations/siwangqishi.ExportJson",
    },
    meatWagon = {
        "animations/jiaorouche.ExportJson",
    },
    wall = {
        "animations/chengqiang_1.ExportJson",
    },
    shrine = {
        "animations/shengdi.ExportJson",
    }
}
local SOLDIER_IMAGES = {
    ranger = {
        "ranger_1.png",
        "ranger_2.png",
        "ranger_3.png",
    },
    catapult = {
        "catapult_1.png",
        "catapult_2.png",
        "catapult_3.png",
    },
    lancer = {
        "lancer_1.png",
        "lancer_2.png",
        "lancer_3.png",
    },
    swordsman = {
        "swordsman_1.png",
        "swordsman_2.png",
        "swordsman_3.png",
    },
    sentinel = {
        "sentinel_1.png",
        "sentinel_2.png",
        "sentinel_3.png",
    },
    crossbowman = {
        "crossbowman_1.png",
        "crossbowman_2.png",
        "crossbowman_3.png",
    },
    horseArcher = {
        "horseArcher_1.png",
        "horseArcher_2.png",
        "horseArcher_3.png",
    },
    ballista = {
        "ballista_1.png",
        "ballista_2.png",
        "ballista_3.png",
    },

    skeletonWarrior = {
        "skeletonWarrior.png",
        "skeletonWarrior.png",
        "skeletonWarrior.png",
    },
    skeletonArcher = {
        "skeletonArcher.png",
        "skeletonArcher.png",
        "skeletonArcher.png",
    },
    deathKnight = {
        "deathKnight.png",
        "deathKnight.png",
        "deathKnight.png",
    },
    meatWagon = {
        "meatWagon.png",
        "meatWagon.png",
        "meatWagon.png",
    },
    priest = {
        "skeletonWarrior.png",
        "skeletonWarrior.png",
        "skeletonWarrior.png",
    },
    demonHunter = {
        "skeletonArcher.png",
        "skeletonArcher.png",
        "skeletonArcher.png",
    },
    paladin = {
        "deathKnight.png",
        "deathKnight.png",
        "deathKnight.png",
    },
    steamTank = {
        "meatWagon.png",
        "meatWagon.png",
        "meatWagon.png",
    },
    wall = {
        "gate_1.png",
        "gate_2.png",
        "gate_3.png",
    }
}
local SOLDIER_COLOR_BG_IMAGES = {
    wall = "blue_bg_128x128.png",
    ranger = "blue_bg_128x128.png",
    catapult = "yellow_bg_128x128.png",
    lancer = "blue_bg_128x128.png",
    swordsman = "blue_bg_128x128.png",
    sentinel = "blue_bg_128x128.png",
    crossbowman = "blue_bg_128x128.png",
    horseArcher = "blue_bg_128x128.png",
    ballista = "yellow_bg_128x128.png",
    skeletonWarrior = "green_bg_128x128.png",
    skeletonArcher = "green_bg_128x128.png",
    deathKnight = "green_bg_128x128.png",
    meatWagon = "green_bg_128x128.png",
    priest = "green_bg_128x128.png",
    demonHunter = "green_bg_128x128.png",
    paladin = "green_bg_128x128.png",
    steamTank = "green_bg_128x128.png",
}
local BLACK_SOLDIER_IMAGES = {
    ranger = {
        "ranger_1.png",
        "b_ranger_2.png",
        "b_ranger_3.png",
    },
    catapult = {
        "catapult_1.png",
        "b_catapult_2.png",
        "b_catapult_3.png",
    },
    lancer = {
        "lancer_1.png",
        "b_lancer_2.png",
        "b_lancer_3.png",
    },
    swordsman = {
        "swordsman_1.png",
        "b_swordsman_2.png",
        "b_swordsman_3.png",
    },
    sentinel = {
        "sentinel_1.png",
        "b_sentinel_2.png",
        "b_sentinel_3.png",
    },
    crossbowman = {
        "crossbowman_1.png",
        "b_crossbowman_2.png",
        "b_crossbowman_3.png",
    },
    horseArcher = {
        "horseArcher_1.png",
        "b_horseArcher_2.png",
        "b_horseArcher_3.png",
    },
    ballista = {
        "ballista_1.png",
        "b_ballista_2.png",
        "b_ballista_3.png",
    },

    skeletonWarrior = {
        "skeletonWarrior.png",
        "skeletonWarrior.png",
        "skeletonWarrior.png",
    },
    skeletonArcher = {
        "skeletonArcher.png",
        "skeletonArcher.png",
        "skeletonArcher.png",
    },
    deathKnight = {
        "deathKnight.png",
        "deathKnight.png",
        "deathKnight.png",
    },
    meatWagon = {
        "meatWagon.png",
        "meatWagon.png",
        "meatWagon.png",
    },
    wall = {
        "gate_1.png",
        "gate_2.png",
        "gate_3.png",
    }
}
local DRAGON_ANIMATIONS_FILES = {
    redDragon = {
        "animations/red_long.ExportJson"
    },
    blueDragon = {
        "animations/blue_long.ExportJson"
    },
    greenDragon = {
        "animations/green_long.ExportJson"
    }
}
local DECORATOR_IMAGE = {
    grassLand = {
        decorate_lake_1 = "lake_1_grassLand.png",
        decorate_lake_2 =  "lake_2_grassLand.png",
        decorate_mountain_1 =  "hill_1_grassLand.png",
        decorate_mountain_2 =  "hill_2_grassLand.png",
        decorate_tree_1 =  "tree_1_grassLand.png",
        decorate_tree_2 =  "tree_2_grassLand.png",
        decorate_tree_3 =  "tree_3_grassLand.png",
        decorate_tree_4 =  "tree_4_grassLand.png",
    },
    iceField = {
        decorate_lake_1 = "lake_1_iceField.png",
        decorate_lake_2 =  "lake_2_iceField.png",
        decorate_mountain_1 =  "hill_1_iceField.png",
        decorate_mountain_2 =  "hill_2_iceField.png",
        decorate_tree_1 =  "tree_1_iceField.png",
        decorate_tree_2 =  "tree_2_iceField.png",
        decorate_tree_3 =  "tree_3_iceField.png",
        decorate_tree_4 =  "tree_4_iceField.png",
    },
    desert = {
        decorate_lake_1 = "lake_1_desert.png",
        decorate_lake_2 =  "lake_2_desert.png",
        decorate_mountain_1 =  "hill_1_desert.png",
        decorate_mountain_2 =  "hill_2_desert.png",
        decorate_tree_1 =  "tree_1_desert.png",
        decorate_tree_2 =  "tree_2_desert.png",
        decorate_tree_3 =  "tree_3_desert.png",
        decorate_tree_4 =  "tree_4_desert.png",
    },
}
local DRAGON_HEAD = {
    blueDragon = "Dragon_blue_113x128.png",
    redDragon = "redDragon.png",
    greenDragon = "greenDragon.png"
}
local BUFF = {
    masterOfDefender = "masterOfDefender_128x128.png",
    quarterMaster = "quarterMaster_128x128.png",
    fogOfTrick = "fogOfTrick_128x128.png",
    woodBonus = "woodBonus_128x128.png",
    stoneBonus = "stoneBonus_128x128.png",
    ironBonus = "ironBonus_128x128.png",
    foodBonus = "foodBonus_128x128.png",
    coinBonus = "coinBonus_128x128.png",
    citizenBonus = "citizenBonus_128x128.png",
    dragonExpBonus = "dragonExpBonus_128x128.png",
    troopSizeBonus = "troopSizeBonus_128x128.png",
    dragonHpBonus = "dragonHpBonus_128x128.png",
    marchSpeedBonus = "marchSpeedBonus_128x128.png",
    unitHpBonus = "unitHpBonus_128x128.png",
    infantryAtkBonus = "infantryAtkBonus_128x128.png",
    archerAtkBonus = "archerAtkBonus_128x128.png",
    cavalryAtkBonus = "cavalryAtkBonus_128x128.png",
    siegeAtkBonus = "siegeAtkBonus_128x128.png",
}

local ALLIANCE_TITLE_ICON = {
    general = "5_23x24.png",
    quartermaster = "4_32x24.png",
    supervisor = "3_35x24.png",
    elite = "2_23x24.png",
    member = "1_11x24.png",
    archon = "alliance_item_leader_39x39.png"
}
local ITEM = {
    movingConstruction = "movingConstruction_101x101.png",
    torch = "torch_101x101.png",
    changePlayerName = "changePlayerName_128x128.png",
    changeCityName = "changeCityName_128x128.png",
    retreatTroop = "retreatTroop_128x128.png",
    moveTheCity = "moveTheCity_101x101.png",
    dragonExp_1 = "dragonExp_1_128x128.png",
    dragonExp_2 = "dragonExp_2_128x128.png",
    dragonExp_3 = "dragonExp_3_128x128.png",
    dragonHp_1 = "dragonHp_1_128x128.png",
    dragonHp_2 = "dragonHp_2_128x128.png",
    dragonHp_3 = "dragonHp_3_128x128.png",
    heroBlood_1 = "heroBlood_1_128x128.png",
    heroBlood_2 = "heroBlood_2_128x128.png",
    heroBlood_3 = "heroBlood_3_128x128.png",
    stamina_1 = "stamina_1_128x128.png",
    stamina_2 = "stamina_2_128x128.png",
    stamina_3 = "stamina_3_128x128.png",

    speedup_1 = "speedup_1_128x128.png",
    speedup_2 = "speedup_2_128x128.png",
    speedup_3 = "speedup_3_128x128.png",
    speedup_4 = "speedup_4_128x128.png",
    speedup_5 = "speedup_5_128x128.png",
    speedup_6 = "speedup_6_128x128.png",
    speedup_7 = "speedup_7_128x128.png",
    speedup_8 = "speedup_8_128x128.png",
    warSpeedupClass_1 = "warSpeedup_1_128x128.png",
    warSpeedupClass_2 = "warSpeedup_2_128x128.png",

    dragonChest_1 = "dragonChest_1_128x128.png",
    dragonChest_2 = "dragonChest_2_128x128.png",
    dragonChest_3 = "dragonChest_3_128x128.png",
    chest_1 = "chest_1_128x128.png",
    chest_2 = "chest_2_128x128.png",
    chest_3 = "chest_3_128x128.png",
    chest_4 = "chest_4_128x128.png",
    casinoTokenClass_1 = "casinoTokenClass_1_128x128.png",
    casinoTokenClass_2 = "casinoTokenClass_2_128x128.png",
    casinoTokenClass_3 = "casinoTokenClass_3_128x128.png",
    casinoTokenClass_4 = "casinoTokenClass_4_128x128.png",
    casinoTokenClass_5 = "casinoTokenClass_5_128x128.png",

    masterOfDefender_1 = "masterOfDefender_1_128x128.png",
    masterOfDefender_2 = "masterOfDefender_2_128x128.png",
    masterOfDefender_3 = "masterOfDefender_3_128x128.png",

    woodClass_1 = "woodClass_1_128x128.png",
    woodClass_2 = "woodClass_2_128x128.png",
    woodClass_3 = "woodClass_3_128x128.png",
    woodClass_4 = "woodClass_4_128x128.png",
    woodClass_5 = "woodClass_5_128x128.png",
    woodClass_6 = "woodClass_6_128x128.png",
    woodClass_7 = "woodClass_7_128x128.png",
    stoneClass_1 = "stoneClass_1_128x128.png",
    stoneClass_2 = "stoneClass_2_128x128.png",
    stoneClass_3 = "stoneClass_3_128x128.png",
    stoneClass_4 = "stoneClass_4_128x128.png",
    stoneClass_5 = "stoneClass_5_128x128.png",
    stoneClass_6 = "stoneClass_6_128x128.png",
    stoneClass_7 = "stoneClass_7_128x128.png",
    ironClass_1 = "ironClass_1_128x128.png",
    ironClass_2 = "ironClass_2_128x128.png",
    ironClass_3 = "ironClass_3_128x128.png",
    ironClass_4 = "ironClass_4_128x128.png",
    ironClass_5 = "ironClass_5_128x128.png",
    ironClass_6 = "ironClass_6_128x128.png",
    ironClass_7 = "ironClass_7_128x128.png",
    foodClass_1 = "foodClass_1_128x128.png",
    foodClass_2 = "foodClass_2_128x128.png",
    foodClass_3 = "foodClass_3_128x128.png",
    foodClass_4 = "foodClass_4_128x128.png",
    foodClass_5 = "foodClass_5_128x128.png",
    foodClass_6 = "foodClass_6_128x128.png",
    foodClass_7 = "foodClass_7_128x128.png",
    coinClass_1 = "coinClass_1_128x128.png",
    coinClass_2 = "coinClass_2_128x128.png",
    coinClass_3 = "coinClass_3_128x128.png",
    coinClass_4 = "coinClass_4_128x128.png",
    coinClass_5 = "coinClass_5_128x128.png",
    coinClass_6 = "coinClass_6_128x128.png",
    coinClass_7 = "coinClass_7_128x128.png",
    gemClass_1 = "gemClass_1_128x128.png",
    gemClass_2 = "gemClass_2_128x128.png",
    gemClass_3 = "gemClass_3_128x128.png",

    siegeAtkBonus_1 = "siegeAtkBonus_1_128x128.png",
    siegeAtkBonus_2 = "siegeAtkBonus_2_128x128.png",
    siegeAtkBonus_3 = "siegeAtkBonus_3_128x128.png",
    unitHpBonus_1 = "unitHpBonus_1_128x128.png",
    unitHpBonus_2 = "unitHpBonus_2_128x128.png",
    unitHpBonus_3 = "unitHpBonus_3_128x128.png",
    cavalryAtkBonus_1 = "cavalryAtkBonus_1_128x128.png",
    cavalryAtkBonus_2 = "cavalryAtkBonus_2_128x128.png",
    cavalryAtkBonus_3 = "cavalryAtkBonus_3_128x128.png",
    archerAtkBonus_1 = "archerAtkBonus_1_128x128.png",
    archerAtkBonus_2 = "archerAtkBonus_2_128x128.png",
    archerAtkBonus_3 = "archerAtkBonus_3_128x128.png",
    infantryAtkBonus_1 = "infantryAtkBonus_1_128x128.png",
    infantryAtkBonus_2 = "infantryAtkBonus_2_128x128.png",
    infantryAtkBonus_3 = "infantryAtkBonus_3_128x128.png",
    marchSpeedBonus_1 = "marchSpeedBonus_1_128x128.png",
    marchSpeedBonus_2 = "marchSpeedBonus_2_128x128.png",
    marchSpeedBonus_3 = "marchSpeedBonus_3_128x128.png",
    dragonHpBonus_1 = "dragonHpBonus_1_128x128.png",
    dragonHpBonus_2 = "dragonHpBonus_2_128x128.png",
    dragonHpBonus_3 = "dragonHpBonus_3_128x128.png",
    dragonExpBonus_1 = "dragonExpBonus_1_128x128.png",
    dragonExpBonus_2 = "dragonExpBonus_2_128x128.png",
    dragonExpBonus_3 = "dragonExpBonus_3_128x128.png",
    troopSizeBonus_1 = "troopSizeBonus_1_128x128.png",
    troopSizeBonus_2 = "troopSizeBonus_2_128x128.png",
    troopSizeBonus_3 = "troopSizeBonus_3_128x128.png",
    citizenBonus_1 = "citizenBonus_1_128x128.png",
    citizenBonus_2 = "citizenBonus_2_128x128.png",
    citizenBonus_3 = "citizenBonus_3_128x128.png",
    citizenClass_1 = "citizenClass_1_128x128.png",
    citizenClass_2 = "citizenClass_2_128x128.png",
    citizenClass_3 = "citizenClass_3_128x128.png",
    coinBonus_1 = "coinBonus_1_128x128.png",
    coinBonus_2 = "coinBonus_2_128x128.png",
    coinBonus_3 = "coinBonus_3_128x128.png",
    foodBonus_1 = "foodBonus_1_128x128.png",
    foodBonus_2 = "foodBonus_2_128x128.png",
    foodBonus_3 = "foodBonus_3_128x128.png",
    ironBonus_1 = "ironBonus_1_128x128.png",
    ironBonus_2 = "ironBonus_2_128x128.png",
    ironBonus_3 = "ironBonus_3_128x128.png",
    stoneBonus_1 = "stoneBonus_1_128x128.png",
    stoneBonus_2 = "stoneBonus_2_128x128.png",
    stoneBonus_3 = "stoneBonus_3_128x128.png",
    woodBonus_1 = "woodBonus_1_128x128.png",
    woodBonus_2 = "woodBonus_2_128x128.png",
    woodBonus_3 = "woodBonus_3_128x128.png",
    fogOfTrick_1 = "fogOfTrick_1_128x128.png",
    fogOfTrick_2 = "fogOfTrick_2_128x128.png",
    fogOfTrick_3 = "fogOfTrick_3_128x128.png",
    quarterMaster_1 = "quarterMaster_1_128x128.png",
    quarterMaster_2 = "quarterMaster_2_128x128.png",
    quarterMaster_3 = "quarterMaster_3_128x128.png",
    vipPoint_1 = "vipPoint_1_128x128.png",
    vipPoint_2 = "vipPoint_2_128x128.png",
    vipPoint_3 = "vipPoint_3_128x128.png",
    vipPoint_4 = "vipPoint_4_128x128.png",
    vipActive_1 = "vipActive_1_128x128.png",
    vipActive_2 = "vipActive_2_128x128.png",
    vipActive_3 = "vipActive_3_128x128.png",
    vipActive_4 = "vipActive_4_128x128.png",
    vipActive_5 = "vipActive_5_128x128.png",
    chestKey_2 = "chestKey_2_128x128.png",
    chestKey_3 = "chestKey_3_128x128.png",
    chestKey_4 = "chestKey_4_128x128.png",
    restoreWall_1 = "restoreWall_1_128x128.png",
    restoreWall_2 = "restoreWall_2_128x128.png",
    restoreWall_3 = "restoreWall_3_128x128.png",
}

local SOLDIER_ANIMATIONS = getAniNameFromAnimationFiles(SOLDIER_ANIMATION_FILES)
local SOLDIER_EFFECT_ANIMATIONS = getAniNameFromAnimationFiles(EFFECT_ANIMATION_FILES)
local DRAGON_ANIMATIONS = getAniNameFromAnimationFiles(DRAGON_ANIMATIONS_FILES)

local ALLIANCE_BUILDING = {
    palace = "alliance_palace.png",
    shrine = "alliance_shrine.png",
    shop = "alliance_shop.png",
    orderHall = "alliance_orderHall.png",
    moonGate = "alliance_moonGate.png",
}
local OTHER_ALLIANCE_BUILDING = setmetatable({
    palace = "other_palace.png",
    shop = "other_shop.png",
    orderHall = "other_orderHall.png",
}, {__index = ALLIANCE_BUILDING})

local DAILY_TASK_ICON = {
    empireRise = "Icon_empireRise_91x117.png",
    conqueror = "Icon_conqueror_104x117.png",
    brotherClub = "Icon_brotherClub_122x124.png",
    growUp = "Icon_growUp_108x115.png"
}
local PVEDefine = import("..entity.PVEDefine")
local SpriteConfig = import("..sprites.SpriteConfig")
local PVE = {
    [PVEDefine.START_AIRSHIP] = {"image", "pve_char.png", 1},
    [PVEDefine.WOODCUTTER] = {"image", SpriteConfig["woodcutter"]:GetConfigByLevel(1).png},
    [PVEDefine.QUARRIER] = {"image", SpriteConfig["quarrier"]:GetConfigByLevel(1).png},
    [PVEDefine.MINER] = {"image", SpriteConfig["miner"]:GetConfigByLevel(1).png},
    [PVEDefine.FARMER] = {"image", SpriteConfig["farmer"]:GetConfigByLevel(1).png},
    [PVEDefine.CAMP] = {"animation", "yewaiyindi"},
    [PVEDefine.CRASHED_AIRSHIP] = {"image", "crashed_airship_80x70.png"},
    [PVEDefine.CONSTRUCTION_RUINS] = {"image", "ruin_1.png"},
    [PVEDefine.KEEL] = {"image", "keel_189x86.png"},
    [PVEDefine.WARRIORS_TOMB] = {"image", "warriors_tomb_80x72.png"},
    [PVEDefine.OBELISK] = {"animation", "zhihuishi"},
    [PVEDefine.ANCIENT_RUINS] = {"image", "alliance_shrine.png", 0.8},
    [PVEDefine.ENTRANCE_DOOR] = {"image", ALLIANCE_BUILDING.moonGate},
    [PVEDefine.TREE] = {"image", "tree_1_grassLand.png", 0.5, grassLand = "tree_1_grassLand.png", iceField = "tree_1_iceField.png", desert = "tree_1_desert.png"},
    [PVEDefine.HILL] = {"image", "tree_1_grassLand.png", 0.5, grassLand = "hill_2_grassLand.png", iceField = "hill_2_iceField.png", desert = "hill_2_desert.png"},
    [PVEDefine.LAKE] = {"image", "tree_1_grassLand.png", 0.5, grassLand = "lake_2_grassLand.png", iceField = "lake_2_iceField.png", desert = "lake_2_desert.png"},
}
local PVE_ANIMATION_FILES = {
    "animations/lanse.ExportJson",
    
    "animations/yewaiyindi.ExportJson",
    "animations/zhihuishi.ExportJson",

    "animations/heihua_bubing_2.ExportJson",
    "animations/heihua_bubing_3.ExportJson",
    "animations/heihua_gongjianshou_2.ExportJson",
    "animations/heihua_gongjianshou_3.ExportJson",
    "animations/heihua_nuche_2.ExportJson",
    "animations/heihua_nuche_3.ExportJson",
    "animations/heihua_nugongshou_2.ExportJson",
    "animations/heihua_nugongshou_3.ExportJson",
    "animations/heihua_qibing_2.ExportJson",
    "animations/heihua_qibing_3.ExportJson",
    "animations/heihua_shaobing_2.ExportJson",
    "animations/heihua_shaobing_3.ExportJson",
    "animations/heihua_toushiche_2.ExportJson",
    "animations/heihua_toushiche_3.ExportJson",
    "animations/heihua_youqibing_2.ExportJson",
    "animations/heihua_youqibing_3.ExportJson",
    "animations/heilong.ExportJson",
}

local function loadUIAnimation()
    local manager = ccs.ArmatureDataManager:getInstance()
    for _,file in pairs(UI_ANIMATION_FILES) do
        manager:addArmatureFileInfo(DEBUG_GET_ANIMATION_PATH(file))
    end
end

local function loadBuildingAnimation()
    local manager = ccs.ArmatureDataManager:getInstance()
    for _,all_files in pairs(BUILDING_ANIMATIONS_FILES) do
        for _,ani_file in pairs(all_files) do
            manager:addArmatureFileInfo(DEBUG_GET_ANIMATION_PATH(ani_file))
        end
    end
end
local function unLoadBuildingAnimation()
-- local manager = ccs.ArmatureDataManager:getInstance()
-- for _,all_files in pairs(BUILDING_ANIMATIONS_FILES) do
--     for _,ani_file in pairs(all_files) do
--         manager:removeArmatureFileInfo(ani_file)
--     end
-- end
end
--
local function loadSolidersAnimation()
    local manager = ccs.ArmatureDataManager:getInstance()
    for _,all_files in pairs(SOLDIER_ANIMATION_FILES) do
        for _,ani_file in pairs(all_files) do
            manager:addArmatureFileInfo(DEBUG_GET_ANIMATION_PATH(ani_file))
        end
    end
end
local function unLoadSolidersAnimation()
    local manager = ccs.ArmatureDataManager:getInstance()
    for _,all_files in pairs(SOLDIER_ANIMATION_FILES) do
        for _,ani_file in pairs(all_files) do
            manager:removeArmatureFileInfo(DEBUG_GET_ANIMATION_PATH(ani_file))
        end
    end
end

local function loadPveAnimation()
    local manager = ccs.ArmatureDataManager:getInstance()
    for _,ani_file in pairs(PVE_ANIMATION_FILES) do
        manager:addArmatureFileInfo(DEBUG_GET_ANIMATION_PATH(ani_file))
    end
end
local function unLoadPveAnimation()
    local manager = ccs.ArmatureDataManager:getInstance()
    for _,all_files in pairs(PVE_ANIMATION_FILES) do
        manager:removeArmatureFileInfo(DEBUG_GET_ANIMATION_PATH(ani_file))
    end
end

local function loadDragonAnimation()
    local manager = ccs.ArmatureDataManager:getInstance()
    for _, anis in pairs(DRAGON_ANIMATIONS_FILES) do
        for _, v in pairs(anis) do
            manager:addArmatureFileInfo(DEBUG_GET_ANIMATION_PATH(v))
        end
    end
end
local function unLoadDragonAnimation()
    local manager = ccs.ArmatureDataManager:getInstance()
    for _, anis in pairs(DRAGON_ANIMATIONS_FILES) do
        for _, v in pairs(anis) do
            manager:removeArmatureFileInfo(DEBUG_GET_ANIMATION_PATH(v))
        end
    end
end



local IAP_PACKAGE_IMAGE = {
    product_1 = {
        content = "store_item_red_610x514.png",
        logo = "gem_logo_592x139_1.png",
        desc = "store_desc_black_335x92.png",
        npc  = "store_npc_1_109x130.png",
        more = {normal = "store_more_red_button_n_584x34.png",pressed = "store_more_red_button_l_584x34.png"},
        small_content = "store_item_content_red_s_588x186.png",
        light_position = {x = 200 ,y= 70}
    },
    product_2 = {
        content = "store_item_black_610x514.png",
        logo = "gem_logo_592x139_2.png",
        desc = "store_desc_red_282x92.png",
        more = {normal = "store_more_black_button_n_584x34.png",pressed = "store_more_black_button_l_584x34.png"},
        small_content = "store_item_content_black_s_588x186.png",
        light_position = {x = 320 ,y= 70}
    },
    product_3 = {
        content = "store_item_black_610x514.png",
        logo = "gem_logo_592x139_3.png",
        desc = "store_desc_red_282x92.png",
        more = {normal = "store_more_black_button_n_584x34.png",pressed = "store_more_black_button_l_584x34.png"},
        small_content = "store_item_content_black_s_588x186.png",
        light_position = {x = 320 ,y= 70}
    },
    product_4 = {
        content = "store_item_black_610x514.png",
        logo = "gem_logo_592x139_4.png",
        desc = "store_desc_red_282x92.png",
        more = {normal = "store_more_black_button_n_584x34.png",pressed = "store_more_black_button_l_584x34.png"},
        small_content = "store_item_content_black_s_588x186.png",
        light_position = {x = 320 ,y= 70}
    },
    product_5 = {
        content = "store_item_red_610x514.png",
        logo = "gem_logo_592x139_5.png",
        desc = "store_desc_black_335x92.png",
        npc  = "store_npc_2_171x130.png",
        more = {normal = "store_more_red_button_n_584x34.png",pressed = "store_more_red_button_l_584x34.png"},
        small_content = "store_item_content_red_s_588x186.png",
        light_position = {x = 200 ,y= 70}
    },
}

local ACTIVITY_IMAGE_CONFIG = {
    EVERY_DAY_LOGIN = "activity_logo_589x138.png",
    CONTINUITY = "gem_logo_592x139_3.png",
    FIRST_IN_PURGURE = "gem_logo_592x139_4.png",
    PLAYER_LEVEL_UP = "gem_logo_592x139_1.png"
}

local PRODUC_TIONTECHS_IMAGE = {
    crane = "crane_128x128.png",
    stoneCarving = "stoneCarving_128x128.png",
    forestation = "forestation_128x128.png",
    fastFix = "fastFix_128x128.png",
    ironSmelting = "ironSmelting_128x128.png",
    cropResearch = "cropResearch_128x128.png",
    reinforcing = "reinforcing_128x128.png",
    seniorTower = "seniorTower_128x128.png",
    beerSupply = "beerSupply_128x128.png",
    rescueTent = "rescueTent_128x128.png",
    colonization = "colonization_128x128.png",
    negotiation = "negotiation_128x128.png",
    trap = "trap_128x128.png",
    hideout = "hideoud_128x128.png",
    logistics = "logistics_128x128.png",
    healingAgent = "healingAgent_128x128.png",
    sketching = "sketching_128x128.png",
    mintedCoin = "mintedcoin_128x128.png",

}




local GET_DRAGON_EQUIPMENT_IMAGE = function(dragon_name,body_name,star)
    local __,__,color_str = string.find(dragon_name, "(%a+)Dragon")
    local body_str = ""
    if "armguardLeft" == body_name or "armguardRight" == body_name then
        body_str = "Armguard"
    elseif "crown" == body_name then
        body_str  = "Crown"
    elseif "orb" == body_name then
        body_str  = "Ord"
    elseif "chest" ==  body_name then
        body_str  = "Chest"
    elseif "sting" == body_name then
        body_str  = "Sting"
    end
    assert(body_str ~= '',"body_name错误")
    local equipment_key = color_str .. body_str .. "_s" .. star
    return EQUIPMENT[equipment_key]
end

local DRAGON_SKILL_ICON = {
    infantryEnhance = {
        redDragon = "infantryEnhance_red_128x128.png",
        greenDragon = "infantryEnhance_green_128x128.png",
        blueDragon = "infantryEnhance_blue_128x128.png",
    },
    archerEnhance = {
        redDragon = "archerenhance_red_128x128.png",
        greenDragon = "archerenhance_green_128x128.png",
        blueDragon = "archerenhance_blue_128x128.png",
    },
    dragonBlood = {
        redDragon = "dragonBlood_128x128.png",
        greenDragon = "dragonBlood_128x128.png",
        blueDragon = "dragonBlood_128x128.png",
    },
    cavalryEnhance = {
        redDragon = "cavalryEnhance_red_128x128.png",
        greenDragon = "cavalryEnhance_green_128x128.png",
        blueDragon = "cavalryEnhance_blue_128x128.png",
    },
    siegeEnhance = {
        redDragon = "siegeEnhance_red_128x128.png",
        greenDragon = "siegeEnhance_green_128x128.png",
        blueDragon = "siegeEnhance_blue_128x128.png",
    },
    dragonBreath = {
        redDragon = "dragonbreath_128x128.png",
        greenDragon = "dragonbreath_128x128.png",
        blueDragon = "dragonbreath_128x128.png",
    },
    leadership = {
        redDragon = "leadership_128x128.png",
        greenDragon = "leadership_128x128.png",
        blueDragon = "leadership_128x128.png",
    },
    greedy = {
        redDragon = "greedy_128x128.png",
        greenDragon = "greedy_128x128.png",
        blueDragon = "greedy_128x128.png",
    },
    frenzied = {
        redDragon = "frenzied_128x128.png",
        greenDragon = "frenzied_128x128.png",
        blueDragon = "frenzied_128x128.png",
    },
    recover = {
        redDragon = "recover_128x128.png",
        greenDragon = "recover_128x128.png",
        blueDragon = "recover_128x128.png",
    },
    insensitive = {
        redDragon = "insensitive_128x128.png",
        greenDragon = "insensitive_128x128.png",
        blueDragon = "insensitive_128x128.png",
    },
    earthquake = {
        redDragon = "earthquake_128x128.png",
        greenDragon = "earthquake_128x128.png",
        blueDragon = "earthquake_128x128.png",
    },
    battleHunger = {
        redDragon = "battleHunger_128x128.png",
        greenDragon = "battleHunger_128x128.png",
        blueDragon = "battleHunger_128x128.png",
    }
}
local DAILY_QUESTS_ICON = {
    [0] = "crane_128x128.png",
    "beerSupply_128x128.png",
    "forestation_128x128.png",
    "stoneCarving_128x128.png",
    "ironSmelting_128x128.png",
    "cropResearch_128x128.png",
    "sketching_128x128.png",
    "negotiation_128x128.png",
    "colonization_128x128.png",
    "seniorTower_128x128.png",
}

local my_city_banner = {
    [0] = "city_banner.png",
    [1] = "city_helped_banner.png",
    [2] = "city_helped_banner.png",
    [3] = "city_helped_banner.png",
    [4] = "city_helped_banner.png",
    [5] = "city_helped_banner.png",
}
local enemy_city_banner = {
    [0] = "enemy_city_banner.png",
    [1] = "enemy_city_helped_banner.png",
    [2] = "enemy_city_helped_banner.png",
    [3] = "enemy_city_helped_banner.png",
    [4] = "enemy_city_helped_banner.png",
    [5] = "enemy_city_helped_banner.png",
}

local server_level_image = {
    bronze = "server_level_bronze_112x114.png",
    silver = "server_level_silver_112x114.png",
    gold = "server_level_gold_112x114.png",
    platinum = "server_level_gold_112x114.png",
    diamond = "server_level_gold_112x114.png",
    master = "server_level_gold_112x114.png",
}

local CITY_TERRAIN_ICON = {
    desert = "city_terrain_desert_142x142.png",
    grassLand = "city_terrain_grassLand_142x142.png",
    iceField = "city_terrain_iceField_142x142.png",
}

local ALLIANCE_LANGUAGE_FRAME = {
    all = "all.png",
    en  = "en.png",
    fr  = "fr.png",
    cn  = "cn.png",
    tw  = "tw.png",
    de  = "de.png",
    ko  = "ko.png",
    ja  = "ja.png",
    ru  = "ru.png",
    es  = "es.png",
    pt  = "pt.png",
    it  = "it.png",
}

return {
    resource = RESOURCE,
    soldier_effect = SOLDIER_EFFECT_ANIMATIONS,
    effect_animation_files = EFFECT_ANIMATION_FILES,
    soldier_animation_files = SOLDIER_ANIMATION_FILES,
    soldier_animation = SOLDIER_ANIMATIONS,
    soldier_image = SOLDIER_IMAGES,
    soldier_color_bg_images = SOLDIER_COLOR_BG_IMAGES,
    black_soldier_image = BLACK_SOLDIER_IMAGES,
    dragon_head  = DRAGON_HEAD,
    dragon_animations = DRAGON_ANIMATIONS,
    dragon_animations_files = DRAGON_ANIMATIONS_FILES,
    decorator_image = DECORATOR_IMAGE,
    materials = MATERIALS,
    dragon_material_pic_map = DRAGON_MATERIAL_PIC_MAP,
    soldier_metarial = SOLDIER_METARIAL,
    equipment =EQUIPMENT,
    alliance_title_icon =ALLIANCE_TITLE_ICON,
    buff = BUFF,
    item = ITEM,
    daily_task_icon = DAILY_TASK_ICON,
    building_animations = BUILDING_ANIMATIONS,
    building_animations_files = BUILDING_ANIMATIONS_FILES,
    pve = PVE,
    loadUIAnimation = loadUIAnimation,
    loadBuildingAnimation = loadBuildingAnimation,
    unLoadBuildingAnimation = unLoadBuildingAnimation,
    loadSolidersAnimation = loadSolidersAnimation,
    unLoadSolidersAnimation = unLoadSolidersAnimation,
    loadPveAnimation = loadPveAnimation,
    unLoadPveAnimation = unLoadPveAnimation,
    loadDragonAnimation = loadDragonAnimation,
    unLoadDragonAnimation = unLoadDragonAnimation,
    iap_package_image = IAP_PACKAGE_IMAGE,
    produc_tiontechs_image = PRODUC_TIONTECHS_IMAGE,
    getDragonEquipmentImage = GET_DRAGON_EQUIPMENT_IMAGE,
    alliance_building = ALLIANCE_BUILDING,
    other_alliance_building = OTHER_ALLIANCE_BUILDING,
    dragon_skill_icon = DRAGON_SKILL_ICON,
    daily_quests_icon = DAILY_QUESTS_ICON,
    player_icon = PLAYER_ICON,
    my_city_banner = my_city_banner,
    enemy_city_banner = enemy_city_banner,
    activity_image_config = ACTIVITY_IMAGE_CONFIG,
    server_level_image = server_level_image,
    city_terrain_icon = CITY_TERRAIN_ICON,
    alliance_language_frame = ALLIANCE_LANGUAGE_FRAME,
}








