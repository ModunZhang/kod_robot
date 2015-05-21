GameUtils = {

    }
local NORMAL = GameDatas.Soldiers.normal
local SPECIAL = GameDatas.Soldiers.special
local soldier_vs = GameDatas.ClientInitGame.soldier_vs
local string = string
local pow = math.pow
local ceil = math.ceil
local sqrt = math.sqrt
local floor = math.floor
local modf = math.modf
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local round = function(v)
    return floor(v + 0.5)
end
function GameUtils:GetVSFromSoldierName(name1, name2)
    return soldier_vs[self:GetSoldierTypeByName(name1)][self:GetSoldierTypeByName(name2)]
end
function GameUtils:GetSoldierTypeByType(type_)
    for k, v in pairs(NORMAL) do
        if k == type_ then
            return v.type
        end
    end
    for k, v in pairs(SPECIAL) do
        if k == type_ then
            return v.type
        end
    end
end
function GameUtils:GetSoldierTypeByName(name)
    for k, v in pairs(NORMAL) do
        if v.name == name then
            return v.type
        end
    end
    for k, v in pairs(SPECIAL) do
        if v.name == name then
            return v.type
        end
    end
    return name
end
function GameUtils:formatTimeStyle1(time)
    local seconds = floor(time) % 60
    time = time / 60
    local minutes = floor(time)% 60
    time = time / 60
    local hours = floor(time)
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

function GameUtils:formatTimeStyle2(time)
    return os.date("%Y-%m-%d %H:%M:%S",time)
end

function GameUtils:formatTimeStyle3(time)
    return os.date("%Y/%m/%d/ %H:%M:%S",time)
end

function GameUtils:formatTimeStyle4(time)
    return os.date("%y-%m-%d %H:%M",time)
end
function GameUtils:formatTimeStyle5(time)
    time = time / 60
    local minutes = floor(time)% 60
    time = time / 60
    local hours = floor(time)
    return string.format("%02d:%02d", hours, minutes)
end

function GameUtils:formatNumber(number)
    local num = tonumber(number)
    local r = 0
    local format = "%d"
    if num >= 1000000000--[[math.pow(10,9)]] then
        r = num/1000000000--[[math.pow(10,9)]]
        local _,decimals = modf(r)
        if decimals ~= 0 then
            format = "%.2fB"
        else
            format = "%dB"
        end
    elseif num >= 1000000--[[math.pow(10,6)]] then
        r = num/1000000--[[math.pow(10,6)]]
        local _,decimals = modf(r)
        if decimals ~= 0 then
            format = "%.2fM"
        else
            format = "%dM"
        end
    elseif num >= 1000--[[math.pow(10,3)]] then
        r = num/1000--[[math.pow(10,3)]]
        local _,decimals = modf(r)
        if decimals ~= 0 then
            format = "%.2fK"
        else
            format = "%dK"
        end
    else
        r = num
    end
    return string.format(format,r)
end

function GameUtils:formatTimeAsTimeAgoStyle( time )
    local timeText = nil
    if(time <= 0) then
        timeText = _("刚刚")
    elseif(time == 1) then
        timeText = _("1秒前")
    elseif(time < 60) then
        timeText = string.format(_("%d秒前"), time)
    elseif(time == 60) then
        timeText = _("1分钟前")
    elseif(time < 3600) then
        time = math.ceil(time / 60)
        timeText = string.format(_("%d分钟前"), time)
    elseif(time == 3600) then
        timeText = _("1小时前")
    elseif(time < 86400) then
        time = math.ceil(time / 3600)
        timeText = string.format(_("%d小时前"), time)
    elseif(time == 86400) then
        timeText = _("1天前")
    else
        time = math.ceil(time / 86400)
        timeText = string.format(_("%d天前"), time)
    end

    return timeText
end

function GameUtils:getUpdatePath(  )
    return device.writablePath .. "update/" .. ext.getAppVersion() .. "/"
end

---------------------------------------------------------- Google Translator
-- text :将要翻译的文本
-- cb :回调函数,有两个参数 function(result,errText) 如果翻译成功 result将返回翻译后的结果errText为nil，如果失败result为nil，errText为错误描述
-- 设置vpn测试！
function GameUtils:Google_Translate(text,cb)
    local params = {
        client="p",
        sl="auto",
        tl=self:ConvertLocaleToGoogleCode(),
        ie="UTF-8",
        oe="UTF-8",
        q=text
    }
    local request = network.createHTTPRequest(function(event)
        local request = event.request
        local eventName = event.name
        if eventName == "completed" then
            if request:getResponseStatusCode() ~= 200 then
                cb(nil,request:getResponseString())
                return
            end
            local content = json.decode(request:getResponseData())
            local r = ""
            if content.sentences and type(content.sentences) == 'table' then
                for _,v in ipairs(content.sentences) do
                    r = r .. v.trans
                end
                print("Google Translator::::::-------------------------------------->",r)
                cb(r,nil)
            else
                cb(nil,"")
            end
        elseif eventName == "progress" then
        else
            cb(nil,eventName)
        end
    end, "http://translate.google.com/translate_a/t", "POST")
    for k,v in pairs(params) do
        local val = string.urlencode(v)
        request:addPOSTValue(k, val)
    end
    request:start()
end

-- https://sites.google.com/site/tomihasa/google-language-codes
function GameUtils:ConvertLocaleToGoogleCode()
    local locale = self:getCurrentLanguage()
    if  locale == 'en_US' then
        return "en"
    elseif locale == 'zh_Hans' then
        return "zh-CN"
    elseif locale == 'pt' then
        return "pt-BR"
    elseif locale == 'zh_Hant' then
        return "zh-TW"
    else
        return locale
    end
end

-----------------------
-- get method
function GameUtils:Baidu_Translate(text,cb)
    local params = {
        from="auto",
        to='zh',
        client_id='FTxAZwkrHChliZjT3g2ZYpHr',
        q=text
    }
    local str = ""
    for k,v in pairs(params) do
        local  val = string.urlencode(v)
        str = str .. k .. "=" .. val .. "&"
    end
    local request = network.createHTTPRequest(function(event)
        local request = event.request
        local eventName = event.name
        if eventName == "completed" then
            if request:getResponseStatusCode() ~= 200 then
                print("Baidu Translator::::::-------------------------------------->StatusCode error!")
                cb(nil,request:getResponseString())
                return
            end
            local content = json.decode(request:getResponseData())
            local r = ""
            if content.trans_result and type(content.trans_result) == 'table' then
                for _,v in ipairs(content.trans_result) do
                    r = r .. v.dst
                end
                print("Baidu Translator::::::-------------------------------------->",r)
                cb(r,nil)
            else
                print("Baidu Translator::::::-------------------------------------->format error!")
                cb(nil,"")
            end
        elseif eventName == "progress" then
        else
            cb(nil,eventName)
        end
    end, "http://openapi.baidu.com/public/2.0/bmt/translate?" .. str, "GET")
    request:setTimeout(10)
    request:start()
end

function GameUtils:ConvertLocaleToBaiduCode()
    --[[
    中文  zh  英语  en
    日语  jp  韩语  kor
    西班牙语    spa 法语  fra
    泰语  th  阿拉伯语    ara
    俄罗斯语    ru  葡萄牙语    pt
    粤语  yue 文言文 wyw
    白话文 zh  自动检测    auto
    德语  de  意大利语    it
    ]]--

    local localCode  = self:getCurrentLanguage()
    if localCode == 'en_US'  or localCode == 'zh_Hant' then
        localCode = 'en'
    elseif localCode == 'zh_Hans' then
        localCode = 'zh'
    elseif localCode == 'fr' then
        localCode = 'fra'
    elseif localCode == 'es' then
        localCode = 'spa'
    elseif localCode == 'ko' then
        localCode = 'kor'
    elseif localCode == 'ja' then
        localCode = 'jp'
    elseif localCode == 'ar' then
        localCode = 'ara'
    end
    return localCode

end

-- Translate Main
function GameUtils:Translate(text,cb)
    if text == "" then
        cb(" ")
        return
    end
    local language = self:getCurrentLanguage()
    if language == 'zh_Hant' or language == 'zh_Hans' then
        self:Baidu_Translate(text,cb)
    else
        if type(self.reachableGoogle)  == nil then
            if network.isHostNameReachable("www.google.com") then
                self.reachableGoogle = true
                self:Google_Translate(text,cb)
            else
                self.reachableGoogle = false
                self:Baidu_Translate(text,cb)
            end
        elseif self.reachableGoogle then
            self:Google_Translate(text,cb)
        else
            self:Baidu_Translate(text,cb)
        end
    end
end


--ver 2.2.4
function GameUtils:getCurrentLanguage()
    local mapping = {
        "en_US",
        "zh_Hans",
        "fr",
        "it",
        "de",
        "es",
        "nl", -- dutch
        "ru",
        "ko",
        "ja",
        "hu",
        "pt",
        "ar",
        "zh_Hant"
    }
    return mapping[cc.Application:getInstance():getCurrentLanguage() + 1]
end

function GameUtils:Event_Handler_Func(events,add_func,edit_func,remove_func)
    local not_hanler = function(...)end
    add_func = add_func or not_hanler
    remove_func = remove_func or not_hanler
    edit_func = edit_func or not_hanler

    local added,edited,removed = {},{},{}
    for _,event in ipairs(events) do
        if event.type == 'add' then
            local result = add_func(event.data)
            if result then table.insert(added,result) end
        elseif event.type == 'edit' then
            local result = edit_func(event.data)
            if result then table.insert(edited,result) end
        elseif event.type == 'remove' then
            local result = remove_func(event.data)
            if result then  table.insert(removed,result) end
        end
    end
    return {added,edited,removed} -- each of return is a table
end


function GameUtils:pack_event_table(t)
    local ret = {}
    local added,edited,removed = unpack(t)
    if #added > 0 then ret.added = checktable(added) end
    if #edited > 0 then ret.edited = checktable(edited) end
    if #removed > 0 then ret.removed = checktable(removed) end
    return ret
end
-- DeltaData--> entity
function GameUtils:Handler_DeltaData_Func(data,add_func,edit_func,remove_func)
    local not_hanler = function(...)end
    add_func = add_func or not_hanler
    remove_func = remove_func or not_hanler
    edit_func = edit_func or not_hanler
    local added,edited,removed = {},{},{}
    for data_type,item in pairs(data) do
        if data_type == 'add' then
            for __,v in ipairs(item) do
                local result = add_func(v)
                if result then table.insert(added,result) end
            end
        elseif data_type == 'edit' then
            for __,v in ipairs(item) do
                local result = edit_func(v)
                if result then table.insert(edited,result) end
            end
        elseif data_type == 'remove' then
            for __,v in ipairs(item) do
                local result = remove_func(v)
                if result then table.insert(removed,result) end
            end
        end
    end
    return {added,edited,removed} -- each of return is a table
end


function GameUtils:parseRichText(str)
    str = string.gsub(str, "\n", "\\n")
    str = string.gsub(str, '"', "\"")
    str = string.gsub(str, "'", "\'")
    local items = {}
    local str_array = string.split(str, "{")
    for i, v in ipairs(str_array) do
        if #v > 0 then
            local inner_str_array = string.split(v, "}")
            if #inner_str_array > 1 then
                for i, v in ipairs(inner_str_array) do
                    if #v > 0 then
                        table.insert(items, v)
                        if #inner_str_array ~= i then
                            table.insert(items, "}")
                        end
                    end
                end
            else
                table.insert(items, v)
            end
        end
        if i ~= #str_array then
            table.insert(items, "{")
        end
    end
    for i, v in ipairs(items) do
        if v == "{" then
            local str_func = {}
            table.insert(str_func, v)
            local next_char = table.remove(items, i + 1)
            while next_char do
                table.insert(str_func, next_char)
                if next_char == "}" then
                    break
                end
                next_char = table.remove(items, i + 1)
            end
            table.insert(str_func, 1, "return ")
            local f, err_msg = loadstring(table.concat(str_func, ""))
            local success, result = pcall(f)
            if not success then
                print(err_msg)
            else
                items[i] = result
            end
        end
    end
    return items
end

function GameUtils:formatTimeStyleDayHour(time,min_day)
    min_day = min_day or 1
    if time > 86400*min_day then
        return string.format(_("%d天%d小时"),math.floor(time/86400),math.floor(time%86400/3600))
    else
        return GameUtils:formatTimeStyle1(time)
    end
end



local normal_soldier = GameDatas.Soldiers.normal
local special_soldier = GameDatas.Soldiers.special
local DragonFightBuffTerrain = {
    redDragon = "grassLand",
    blueDragon = "desert",
    greenDragon = "iceField"
}
local function getSoldiersConfig(soldier_name, soldier_star)
    local soldier_config = special_soldier[soldier_name]
    if not soldier_config then
        soldier_config = normal_soldier[string.format("%s_%d", soldier_name, soldier_star)]
    end
    assert(soldier_config)
    return soldier_config
end
-- 如果是pve得话就没有龙
local function getPlayerSoldierAtkBuff(soldierName, soldierStar, dragon, terrain, is_dragon_win)
    if not dragon then
        return 0
    end
    local itemBuff = 0
    local skillBuff = 0
    local equipmentBuff = 0
    local soldierType = getSoldiersConfig(soldierName, soldierStar).type

    if ItemManager:IsBuffActived(soldierType.."AtkBonus") then
        itemBuff = 0.3
    end

    if DragonFightBuffTerrain[dragon:Type()] == terrain then
        local skill = dragon:GetSkillByName(soldierType.."Enhance")
        if skill then
            skillBuff = skill:GetEffect()
        end
    end

    local equipmentBuff_key = soldierType.."AtkAdd"
    for _,v in ipairs(dragon:GetAllEquipmentBuffEffect()) do
        local k,buff = unpack(v)
        if k == equipmentBuff_key then
            equipmentBuff = buff
            break
        end
    end

    return (itemBuff + skillBuff + equipmentBuff) * (is_dragon_win and 1 or 0.5)
end
-- 如果是pve得话就没有龙
local function getPlayerSoldierHpBuff(soldierName, soldierStar, dragon, terrain, is_dragon_win)
    if not dragon then
        return 0
    end
    local itemBuff = 0
    local skillBuff = 0
    local equipmentBuff = 0

    if ItemManager:IsBuffActived("unitHpBonus") then
        itemBuff = 0.3
    end

    local soldierType = getSoldiersConfig(soldierName, soldierStar).type

    if DragonFightBuffTerrain[dragon:Type()] == terrain then
        local skill = dragon:GetSkillByName(soldierType.."Enhance")
        if skill then
            skillBuff = skill:GetEffect()
        end
    end

    local equipmentBuff_key = soldierType.."HpAdd"
    for _,v in ipairs(dragon:GetAllEquipmentBuffEffect()) do
        local k,buff = unpack(v)
        if k == equipmentBuff_key then
            equipmentBuff = buff
            break
        end
    end
    return (itemBuff + skillBuff + equipmentBuff) * (is_dragon_win and 1 or 0.5)
end
local function createPlayerSoldiersForFight(soldiers, dragon, terrain, is_dragon_win)
    return LuaUtils:table_map(soldiers, function(k, soldier)
        local soldier_man = City:GetSoldierManager()
        -----
        local config = getSoldiersConfig(soldier.name, soldier.star)
        local atkBuff = getPlayerSoldierAtkBuff(soldier.name, soldier.star, dragon, terrain, is_dragon_win)
        -- var atkWallBuff = self.getDragonAtkWallBuff(dragon)
        local hpBuff = getPlayerSoldierHpBuff(soldier.name, soldier.star, dragon, terrain, is_dragon_win)
        local techBuffToInfantry = soldier_man:GetMilitaryTechsByName(config.type.."_".."infantry"):GetAtkEff()
        local techBuffToArcher = soldier_man:GetMilitaryTechsByName(config.type.."_".."archer"):GetAtkEff()
        local techBuffToCavalry = soldier_man:GetMilitaryTechsByName(config.type.."_".."cavalry"):GetAtkEff()
        local techBuffToSiege = soldier_man:GetMilitaryTechsByName(config.type.."_".."siege"):GetAtkEff()
        local techBuffHpAdd = soldier_man:GetMilitaryTechsByName(config.type.."_".."hpAdd"):GetAtkEff()
        local vipAttackBuff = User:GetVIPSoldierAttackPowerAdd()
        local vipHpBuff = User:GetVIPSoldierHpAdd()
        -- dump(hpBuff, "hpBuff")
        -- dump(vipHpBuff, "vipHpBuff")
        -- dump(atkBuff, "atkBuff")
        -- dump(vipAttackBuff, "vipAttackBuff")
        -- dump(techBuffToInfantry, "techBuffToInfantry")
        -- dump(techBuffToArcher, "techBuffToArcher")
        -- dump(techBuffToCavalry, "techBuffToCavalry")
        -- dump(techBuffToSiege, "techBuffToSiege")
        return k, {
            name = soldier.name,
            star = soldier.star,
            type = config.type,
            currentCount = soldier.count,
            totalCount = soldier.count,
            woundedCount = 0,
            power = config.power,
            hp = math.floor(config.hp * (1 + hpBuff + techBuffHpAdd + vipHpBuff)),
            morale = 100,
            round = 0,
            attackPower = {
                infantry = math.floor(config.infantry * (1 + atkBuff + techBuffToInfantry + vipAttackBuff)),
                archer = math.floor(config.archer * (1 + atkBuff + techBuffToArcher + vipAttackBuff)),
                cavalry = math.floor(config.cavalry * (1 + atkBuff + techBuffToCavalry + vipAttackBuff)),
                siege = math.floor(config.siege * (1 + atkBuff + techBuffToSiege + vipAttackBuff)),
            }
        }
    end)
end
local function createDragonForFight(dragon)
    return {
        level = dragon.level,
        dragonType = dragon.dragonType,
        currentHp = dragon.currentHp,
        totalHp = dragon.currentHp,
        hpMax = dragon.hpMax,
        strength = dragon.strength,
        vitality = dragon.vitality,
    }
end
local DAMAGE_FACTOR = 0.3
function GameUtils:SoldierSoldierBattle(attackSoldiers, attackWoundedSoldierPercent, attackSoldierMoraleDecreasedPercent, defenceSoldiers, defenceWoundedSoldierPercent, defenceSoldierMoraleDecreasedPercent)
    local attackResults = {}
    local defenceResults = {}
    while #attackSoldiers > 0 and #defenceSoldiers > 0 do
        local attackSoldier = attackSoldiers[1]
        local defenceSoldier = defenceSoldiers[1]
        local attackSoldierType = attackSoldier.type
        local defenceSoldierType = defenceSoldier.type
        local attackTotalPower = attackSoldier.attackPower[defenceSoldierType] * attackSoldier.currentCount
        local defenceTotalPower = defenceSoldier.attackPower[attackSoldierType] * defenceSoldier.currentCount
        local attackDamagedSoldierCount = nil
        local defenceDamagedSoldierCount = nil
        if attackTotalPower >= defenceTotalPower then
            attackDamagedSoldierCount = ceil(defenceTotalPower * DAMAGE_FACTOR / attackSoldier.hp)
            defenceDamagedSoldierCount = ceil(sqrt(attackTotalPower * defenceTotalPower) * 0.5 / defenceSoldier.hp)
        else
            attackDamagedSoldierCount = ceil(sqrt(attackTotalPower * defenceTotalPower) * DAMAGE_FACTOR / attackSoldier.hp)
            defenceDamagedSoldierCount = ceil(attackTotalPower * 0.5 / defenceSoldier.hp)
        end
        if (attackDamagedSoldierCount > attackSoldier.currentCount) then
            attackDamagedSoldierCount = attackSoldier.currentCount
        end
        if (defenceDamagedSoldierCount > defenceSoldier.currentCount) then
            defenceDamagedSoldierCount = defenceSoldier.currentCount
        end
        if (attackSoldier.currentCount >= 50 and attackDamagedSoldierCount > attackSoldier.currentCount * 0.7) then
            attackDamagedSoldierCount = ceil(attackSoldier.currentCount * 0.7)
        end
        if (defenceSoldier.currentCount >= 50 and defenceDamagedSoldierCount > defenceSoldier.currentCount * 0.7) then
            defenceDamagedSoldierCount = ceil(defenceSoldier.currentCount * 0.7)
        end
        --
        local attackWoundedSoldierCount = ceil(attackDamagedSoldierCount * attackWoundedSoldierPercent)
        local defenceWoundedSoldierCount = ceil(defenceDamagedSoldierCount * defenceWoundedSoldierPercent)
        local attackMoraleDecreased = ceil(attackDamagedSoldierCount * pow(2, attackSoldier.round - 1) / attackSoldier.totalCount * 100 * attackSoldierMoraleDecreasedPercent)
        local dfenceMoraleDecreased = ceil(defenceDamagedSoldierCount * pow(2, defenceSoldier.round - 1) / defenceSoldier.totalCount * 100 * defenceSoldierMoraleDecreasedPercent)
        table.insert(attackResults, {
            soldierName = attackSoldier.name,
            soldierStar = attackSoldier.star,
            soldierCount = attackSoldier.currentCount,
            soldierDamagedCount = attackDamagedSoldierCount,
            soldierWoundedCount = attackWoundedSoldierCount,
            morale = attackSoldier.morale,
            moraleDecreased = attackMoraleDecreased > attackSoldier.morale and attackSoldier.morale or attackMoraleDecreased,
            isWin = attackTotalPower >= defenceTotalPower
        })
        table.insert(defenceResults, {
            soldierName = defenceSoldier.name,
            soldierStar = defenceSoldier.star,
            soldierCount = defenceSoldier.currentCount,
            soldierDamagedCount = defenceDamagedSoldierCount,
            soldierWoundedCount = defenceWoundedSoldierCount,
            morale = defenceSoldier.morale,
            moraleDecreased = dfenceMoraleDecreased > defenceSoldier.morale and defenceSoldier.morale or dfenceMoraleDecreased,
            isWin = attackTotalPower < defenceTotalPower
        })
        attackSoldier.round = attackSoldier.round + 1
        attackSoldier.currentCount = attackSoldier.currentCount - attackDamagedSoldierCount
        attackSoldier.woundedCount = attackSoldier.woundedCount + attackWoundedSoldierCount
        attackSoldier.morale = attackSoldier.morale - attackMoraleDecreased

        defenceSoldier.round = defenceSoldier.round + 1
        defenceSoldier.currentCount = defenceSoldier.currentCount - defenceDamagedSoldierCount
        defenceSoldier.woundedCount = defenceSoldier.woundedCount + defenceWoundedSoldierCount
        defenceSoldier.morale = defenceSoldier.morale - dfenceMoraleDecreased


        if attackTotalPower < defenceTotalPower or attackSoldier.morale <= 20 or attackSoldier.currentCount == 0 then
            table.remove(attackSoldiers, 1)
        end
        if attackTotalPower >= defenceTotalPower or defenceSoldier.morale <= 20 or defenceSoldier.currentCount == 0 then
            table.remove(defenceSoldiers, 1)
        end
    end

    local fightResult = true
    if(#attackSoldiers > 0 or (#attackSoldiers == 0 and #defenceSoldiers== 0)) then
        fightResult = true
    else
        fightResult = false
    end

    return attackResults, defenceResults, fightResult
end

function GameUtils:DragonDragonBattle(attackDragon, defenceDragon, effect)
    assert(attackDragon.hpMax)
    assert(attackDragon.strength)
    assert(attackDragon.vitality)
    assert(attackDragon.totalHp)
    assert(attackDragon.currentHp)
    assert(defenceDragon.hpMax)
    assert(defenceDragon.strength)
    assert(defenceDragon.vitality)
    assert(defenceDragon.totalHp)
    assert(defenceDragon.currentHp)
    local attackDragonStrength = attackDragon.strength
    local defenceDragonStrength = defenceDragon.strength
    if effect >= 0 then
        defenceDragonStrength = defenceDragonStrength * (1 - effect)
    else
        attackDragonStrength = attackDragonStrength * (1 + effect)
    end
    local attackDragonHpDecreased
    local defenceDragonHpDecreased
    if attackDragonStrength >= defenceDragonStrength then
        attackDragonHpDecreased = floor(defenceDragonStrength * 0.5)
        defenceDragonHpDecreased = floor(sqrt(attackDragonStrength * defenceDragonStrength) * 0.5)
    else
        attackDragonHpDecreased = floor(sqrt(attackDragonStrength * defenceDragonStrength) * 0.5)
        defenceDragonHpDecreased = floor(attackDragonStrength * 0.5)
    end

    attackDragon.currentHp = attackDragonHpDecreased > attackDragon.currentHp and 0 or attackDragon.currentHp - attackDragonHpDecreased
    defenceDragon.currentHp = defenceDragonHpDecreased > defenceDragon.currentHp and 0 or defenceDragon.currentHp - defenceDragonHpDecreased
    attackDragon.isWin = attackDragonStrength >= defenceDragonStrength
    defenceDragon.isWin = attackDragonStrength < defenceDragonStrength

    return {
        type = attackDragon.dragonType,
        hp = attackDragon.totalHp,
        hpDecreased = attackDragon.totalHp - attackDragon.currentHp,
        hpMax = attackDragon.hpMax,
        isWin = attackDragonStrength >= defenceDragonStrength
    }, {
        type = defenceDragon.dragonType,
        hp = defenceDragon.totalHp,
        hpDecreased = defenceDragon.totalHp - defenceDragon.currentHp,
        hpMax = defenceDragon.hpMax,
        isWin = attackDragonStrength < defenceDragonStrength
    }
end

local intInit = GameDatas.AllianceInitData.intInit
local function getSumPower(soldiersForFight)
    local power = 0
    for i,soldierForFight in ipairs(soldiersForFight) do
        power = power + soldierForFight.power * soldierForFight.totalCount
    end
    return power
end
local fightFix = GameDatas.Dragons.fightFix
local function getEffectPercent(multiple)
    local configs = fightFix
    for _,config in ipairs(configs) do
        if config.multipleMax > multiple then
            return config.effect
        end
    end
    return configs[#configs].effect
end
local function getDragonFightFixedEffect(attackSoldiersForFight, defenceSoldiersForFight)
    local attackSumPower = getSumPower(attackSoldiersForFight)
    local defenceSumPower = getSumPower(defenceSoldiersForFight)
    local effect = attackSumPower >= defenceSumPower and getEffectPercent(attackSumPower / defenceSumPower) or -getEffectPercent(defenceSumPower / attackSumPower)
    return effect
end
local function getPlayerTreatSoldierPercent(dragon)
    if true then return 1.0 end
    local basePercent = 0.3
    local skillBuff = 0
    local equipmentBuff = 0

    local skill = dragon:GetSkillByName("recover")
    if skill then
        skillBuff = skill:GetEffect()
    end

    for _,v in ipairs(dragon:GetAllEquipmentBuffEffect()) do
        local k,buff = unpack(v)
        if k == "recoverAdd" then
            equipmentBuff = buff
            break
        end
    end
    return basePercent + skillBuff + equipmentBuff
end
local function getPlayerSoldierMoraleDecreasedPercent(dragon)
    local basePercent = 1
    local skillBuff = 0

    local skill = dragon:GetSkillByName("insensitive")
    if skill then
        skillBuff = skill:GetEffect()
    end

    return basePercent - skillBuff
end
function GameUtils:DoBattle(attacker, defencer, terrain, enemy_name)
    assert(terrain)
    assert(enemy_name)
    local clone_attacker_soldiers = clone(attacker.soldiers)
    local clone_defencer_soldiers = clone(defencer.soldiers)

    local attacker_dragon = createDragonForFight(attacker.dragon)
    local defencer_dragon = createDragonForFight(defencer.dragon)

    local attacker_soldiers = createPlayerSoldiersForFight(attacker.soldiers, attacker.dragon.dragon, terrain, attacker_dragon.strength > defencer_dragon.strength)
    local defencer_soldiers = createPlayerSoldiersForFight(defencer.soldiers)

    local dragonFightFixedEffect = getDragonFightFixedEffect(attacker_soldiers, defencer_soldiers)
    local attack_dragon, defence_dragon = GameUtils:DragonDragonBattle(attacker_dragon, defencer_dragon, dragonFightFixedEffect)

    local attackWoundedSoldierPercent = getPlayerTreatSoldierPercent(attacker.dragon.dragon)
    local attackSoldierMoraleDecreasedPercent = getPlayerSoldierMoraleDecreasedPercent(attacker.dragon.dragon)
    local attack_soldier, defence_soldier, is_attack_win =
        GameUtils:SoldierSoldierBattle(
            attacker_soldiers, attackWoundedSoldierPercent, attackSoldierMoraleDecreasedPercent,
            defencer_soldiers, 0.4, 1
        )

    local report = {}
    function report:GetAttackKDA()
        -- 龙战损
        local r = {}
        for _, v in ipairs(defence_soldier) do
            local key = v.soldierStar and string.format("%s_%d", v.soldierName, v.soldierStar) or v.soldierName
            r[key] = 0
        end
        for _, v in ipairs(defence_soldier) do
            local key = v.soldierStar and string.format("%s_%d", v.soldierName, v.soldierStar) or v.soldierName
            r[key] = r[key] + v.soldierDamagedCount
        end
        local killScore = 0
        for k, v in pairs(r) do
            local config = normal_soldier[k] or special_soldier[k]
            assert(config, "查无此类兵种。")
            killScore = killScore + v * config.killScore
        end
        local dragon = {
            type = attacker.dragon.dragonType,
            hpDecreased = attack_dragon.hpDecreased,
            expAdd = floor(killScore * intInit.KilledCitizenPerDragonExp.value)
        }
        -- 兵种战损
        local r = {}
        for _, v in ipairs(attack_soldier) do
            r[v.soldierName] = {damagedCount = 0, woundedCount = 0}
        end
        for _, v in ipairs(attack_soldier) do
            local soldier = r[v.soldierName]
            soldier.damagedCount = soldier.damagedCount + v.soldierDamagedCount
            soldier.woundedCount = soldier.woundedCount + v.soldierWoundedCount
        end
        local soldiers = {}
        for k, v in pairs(r) do
            if v.damagedCount > 0 then
                table.insert(soldiers, {name = k, damagedCount = v.damagedCount, woundedCount = v.woundedCount})
            end
        end
        return {dragon = dragon, soldiers = soldiers}
    end
    function report:IsPveBattle()
    end
    function report:GetFightAttackName()
        return User:Name()
    end
    function report:GetFightDefenceName()
        return enemy_name
    end
    function report:IsDragonFight()
        return true
    end
    function report:GetFightAttackDragonRoundData()
        return attack_dragon
    end
    function report:GetFightDefenceDragonRoundData()
        return defence_dragon
    end
    function report:GetFightAttackSoldierRoundData()
        return attack_soldier
    end
    function report:GetFightDefenceSoldierRoundData()
        return defence_soldier
    end
    function report:GetOrderedAttackSoldiers()
        return clone_attacker_soldiers
    end
    function report:GetOrderedDefenceSoldiers()
        return clone_defencer_soldiers
    end
    function report:IsFightWall()
        return false
    end
    function report:IsAttackWin()
        return is_attack_win
    end
    function report:IsAttackCamp()
        return true
    end
    function report:GetReportResult()
        return self:IsAttackWin()
    end
    function report:GetAttackDragonLevel()
        return attacker_dragon.level
    end
    function report:GetDefenceDragonLevel()
        return defencer_dragon.level
    end
    function report:GetAttackTargetTerrain()
        return terrain
    end
    return report
end


return GameUtils




















