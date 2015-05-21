--                 "id": "X1x8lpX35",
--                 "lastThreeDaysKillData": [],
--                 "loyalty": 0,
--                 "power": 478,
--                 "status": "normal",
--                 "mapId": "XyiX0nnNn5",
--                 "icon": "playerIcon_default.png",
--                 "language": "cn",
--                 "isProtected": false,
--                 "kill": 0,
--                 "wallHp": 124,
--                 "wallLevel": 1,
--                 "name": "player_Xk8g6Xhq",
--                 "lastRewardData": null,
--                 "keepLevel": 3,
--                 "title": "archon",
--                 "helpedByTroopsCount": 0,
--                 "donateStatus": {
--                     "wood": 1,
--                     "gem": 1,
--                     "iron": 1,
--                     "coin": 1,
--                     "stone": 1,
--                     "food": 1
--                 },
--                 "lastLoginTime": 1427768779105,
--                 "allianceExp": {
--                     "woodExp": 0,
--                     "ironExp": 0,
--                     "stoneExp": 0,
--                     "foodExp": 0,
--                     "coinExp": 0
--                 }
local Enum = import("..utils.Enum")
local property = import("..utils.property")
local allianceRight = GameDatas.ClientInitGame.allianceRight
local memberMeta = {}
memberMeta.__index = memberMeta

property(memberMeta, "id")
property(memberMeta, "mapId")
property(memberMeta, "level", 0)
property(memberMeta, "name")
property(memberMeta, "language")
property(memberMeta, "title")
property(memberMeta, "icon", "")
property(memberMeta, "lastLoginTime", 0)
property(memberMeta, "status", "normal")
property(memberMeta, "kill", 0)
property(memberMeta, "power", 0)
property(memberMeta, "loyalty", 0)
property(memberMeta, "isProtected")
property(memberMeta, "keepLevel")
property(memberMeta, "terrain")
property(memberMeta, "wallLevel")
property(memberMeta, "wallHp")
property(memberMeta, "donateStatus")
property(memberMeta, "helpTroopsCount", 0)
property(memberMeta, "helpedByTroopsCount", 0)
property(memberMeta, "lastRewardData")
property(memberMeta, "lastThreeDaysKillData")

local titles_enum = Enum("member",
    "elite",
    "supervisor",
    "quartermaster",
    "general",
    "archon")
local collect_type  = {"woodExp",
    "stoneExp",
    "ironExp",
    "foodExp",
    "coinExp"}
local collect_exp_config  = {"wood",
    "stone",
    "iron",
    "food",
    "coin"}
local COLLECT_TYPE = Enum("WOOD",
    "STONE",
    "IRON",
    "FOOD",
    "COIN")


function memberMeta.new(x, y)
    return setmetatable({
        x = x,
        y = y
    }, memberMeta)
end
function memberMeta:DecodeFromJson(json)
    return setmetatable(json, memberMeta)
end
function memberMeta:GetType()
    return "none"
end
function memberMeta:GetLogicPosition()
    return self.x, self.y
end
function memberMeta:IsArchon()
    return self:Title() == "archon"
end
function memberMeta:IsTitleHighest()
    return self:Title() == titles_enum[#titles_enum - 1]
end
function memberMeta:TitleUpgrade()
    local cur = self:Title()
    return titles_enum[titles_enum[cur] + 1] or cur
end
function memberMeta:IsTitleLowest()
    return self:Title() == titles_enum[1]
end
function memberMeta:GetWoodCollectLevel()
    return self:GetCollectLevelByType(memberMeta.COLLECT_TYPE.WOOD)
end
function memberMeta:GetStoneCollectLevel()
    return self:GetCollectLevelByType(memberMeta.COLLECT_TYPE.STONE)
end
function memberMeta:GetIronCollectLevel()
    return self:GetCollectLevelByType(memberMeta.COLLECT_TYPE.IRON)
end
function memberMeta:GetFoodCollectLevel()
    return self:GetCollectLevelByType(memberMeta.COLLECT_TYPE.FOOD)
end
function memberMeta:GetCoinCollectLevel()
    return self:GetCollectLevelByType(memberMeta.COLLECT_TYPE.COIN)
end
function memberMeta:get_collect_config( collectType )
    local exp = self.allianceExp[collect_type[collectType]]
    local config = GameDatas.PlayerVillageExp[collect_exp_config[collectType]]
    for i = #config,1,-1 do
        if exp>=config[i].expFrom then
            return config[i]
        end
    end
end
function memberMeta:GetCollectLevelByType(collectType)
    local exp = self.allianceExp[collect_type[collectType]]
    local config = GameDatas.PlayerVillageExp[collect_exp_config[collectType]]
    for i = #config,1,-1 do
        if exp>=config[i].expFrom then
            return i
        end
    end
end
function memberMeta:GetCollectExpsByType(collectType)
    local exp = self.allianceExp[collect_type[collectType]]
    return exp,self:get_collect_config(collectType).expTo
end
function memberMeta:GetCollectEffectByType(collectType)
    return self:get_collect_config(collectType).percentPerHour
end
function memberMeta:GetWoodCollectLevelUpExp()
    return self:GetCollectLevelUpExpByType(COLLECT_TYPE.WOOD)
end
function memberMeta:GetStoneCollectLevelUpExp()
    return self:GetCollectLevelUpExpByType(COLLECT_TYPE.STONE)
end
function memberMeta:GetIronCollectLevelUpExp()
    return self:GetCollectLevelUpExpByType(COLLECT_TYPE.IRON)
end
function memberMeta:GetFoodCollectLevelUpExp()
    return self:GetCollectLevelUpExpByType(COLLECT_TYPE.FOOD)
end
function memberMeta:GetCoinCollectLevelUpExp()
    return self:GetCollectLevelUpExpByType(COLLECT_TYPE.COIN)
end
function memberMeta:GetCollectLevelUpExpByType(collectType)
    local exp = self.allianceExp[collect_type[collectType]]
    local config = GameDatas.PlayerVillageExp[collect_exp_config[collectType]]
    for i = #config,1,-1 do
        if exp>=config[i].expFrom then
            return config[i].expTo
        end
    end
end
-- 职位权限是否大于等于某个职位
-- @parm eq_title 比较的职位
function memberMeta:IsTitleEqualOrGreaterThan(eq_title)
    local self_title_level , eq_title_level
    for k,v in pairs(titles_enum) do
        if self:Title()==titles_enum[k] then
            self_title_level = k
        end
        if eq_title == titles_enum[k] then
            eq_title_level = k
        end
    end
    return self_title_level >= eq_title_level
end
function memberMeta:TitleDegrade()
    local cur = self:Title()
    return titles_enum[titles_enum[cur] - 1] or cur
end
function memberMeta:IsTheSamePerson(member)
    return self:IsTheSameId(member:Id())
end
function memberMeta:IsTheSameId(id)
    return self:Id() == id
end
function memberMeta:GetTitleLevel()
    return titles_enum[self:Title()]
end
function memberMeta.Title2Level(title)
    return titles_enum[title]
end
--权限判定函数
--------------------------------------------------------------------------
--名称 简称 旗帜 地形 语言
function memberMeta:CanEditAlliance()
    return allianceRight[self:Title()].CanEditAlliance
end
--移交盟主
function memberMeta:CanGiveUpArchon()
    return allianceRight[self:Title()].CanGiveUpArchon
end
--修改职位名称
function memberMeta:CanEditAllianceMemeberTitle()
    return allianceRight[self:Title()].CanEditAllianceMemeberTitle
end
--移动/拆除联盟地图上的东东
function memberMeta:CanEditAllianceObject()
    return allianceRight[self:Title()].CanEditAllianceObject
end
--圣地事件
function memberMeta:CanActivateShirneEvent()
    return allianceRight[self:Title()].CanActivateShirneEvent
end
--联盟GVG
function memberMeta:CanActivateGVG()
    return allianceRight[self:Title()].CanActivateGVG
end
--在联盟商店的道具目录中补充高级道具
function memberMeta:CanAddAdvancedItemsToAllianceShop()
    return allianceRight[self:Title()].CanAddAdvancedItemsToAllianceShop
end
function memberMeta:CanEditAllianceNotice()
    return allianceRight[self:Title()].CanEditAllianceNotice
end
function memberMeta:CanSendAllianceMail()
    return allianceRight[self:Title()].CanSendAllianceMail
end
function memberMeta:CanUpgradeAllianceBuilding()
    return allianceRight[self:Title()].CanUpgradeAllianceBuilding
end
function memberMeta:CanInvatePlayer()
    return allianceRight[self:Title()].CanInvatePlayer
end
function memberMeta:CanHandleAllianceApply()
    return allianceRight[self:Title()].CanHandleAllianceApply
end
function memberMeta:CanKickOutMember(target_current_title)
    return allianceRight[self:Title()].CanKickOutMember,self:GetTitleLevel() > self.Title2Level(target_current_title)
end
function memberMeta:CanUpgradeMemberLevel(target_target_title)
    return allianceRight[self:Title()].CanUpgradeMemberLevel,self:GetTitleLevel() > self.Title2Level(target_target_title)
end
function memberMeta:CanDemotionMemberLevel(target_current_title)
    return allianceRight[self:Title()].CanDemotionMemberLevel,self:GetTitleLevel() > self.Title2Level(target_current_title)
end
function memberMeta:CanEditAllianceDesc()
    return allianceRight[self:Title()].CanEditAllianceDesc
end
function memberMeta:CanEditAllianceJoinType()
    return allianceRight[self:Title()].CanEditAllianceJoinType
end
function memberMeta:CanBuyAdvancedItemsFromAllianceShop()
    return allianceRight[self:Title()].CanBuyAdvancedItemsFromAllianceShop
end
function memberMeta:CanActivateAllianceRevenge()
    return allianceRight[self:Title()].CanActivateAllianceRevenge
end

return memberMeta


