local Enum = import("..utils.Enum")
local property = import("..utils.property")
local AllianceMember = class("AllianceMember")
local allianceRight = GameDatas.ClientInitGame.allianceRight

property(AllianceMember, "id")
property(AllianceMember, "level", 0)
property(AllianceMember, "kill", 0)
property(AllianceMember, "power", 0)
property(AllianceMember, "loyalty", 0)
property(AllianceMember, "lastLoginTime", 0)
property(AllianceMember, "icon", "")
property(AllianceMember, "title")
property(AllianceMember, "name")
property(AllianceMember, "helpTroopsCount")
property(AllianceMember, "wallHp")
property(AllianceMember, "wallLevel")
property(AllianceMember, "keepLevel")
property(AllianceMember, "isProtected")
property(AllianceMember, "lastRewardData")
property(AllianceMember, "lastThreeDaysKillData")

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
AllianceMember.COLLECT_TYPE = Enum("WOOD",
    "STONE",
    "IRON",
    "FOOD",
    "COIN")

function AllianceMember:ctor(id)
    self.id = id
    self.location = {x = 0, y = 0}
    self.donateStatus = {}
    self.allianceExp = {}
end
function AllianceMember:IsArchon()
    return self:Title() == "archon"
end
function AllianceMember:IsTitleHighest()
    return self:Title() == titles_enum[#titles_enum - 1]
end
function AllianceMember:TitleUpgrade()
    local cur = self:Title()
    return titles_enum[titles_enum[cur] + 1] or cur
end
function AllianceMember:IsTitleLowest()
    return self:Title() == titles_enum[1]
end
function AllianceMember:GetDonateStatus()
    return self.donateStatus
end
function AllianceMember:GetAllianceExp()
    return self.allianceExp
end
function AllianceMember:GetWoodCollectLevel()
    return self:GetCollectLevelByType(AllianceMember.COLLECT_TYPE.WOOD)
end
function AllianceMember:GetStoneCollectLevel()
    return self:GetCollectLevelByType(AllianceMember.COLLECT_TYPE.STONE)
end
function AllianceMember:GetIronCollectLevel()
    return self:GetCollectLevelByType(AllianceMember.COLLECT_TYPE.IRON)
end
function AllianceMember:GetFoodCollectLevel()
    return self:GetCollectLevelByType(AllianceMember.COLLECT_TYPE.FOOD)
end
function AllianceMember:GetCoinCollectLevel()
    return self:GetCollectLevelByType(AllianceMember.COLLECT_TYPE.COIN)
end
function AllianceMember:get_collect_config( collectType )
    local exp = self.allianceExp[collect_type[collectType]]
    local config = GameDatas.PlayerVillageExp[collect_exp_config[collectType]]
    for i = #config,1,-1 do
        if exp>=config[i].expFrom then
            return config[i]
        end
    end
end
function AllianceMember:GetCollectLevelByType(collectType)
    local exp = self.allianceExp[collect_type[collectType]]
    local config = GameDatas.PlayerVillageExp[collect_exp_config[collectType]]
    for i = #config,1,-1 do
        if exp>=config[i].expFrom then
            return i
        end
    end
end
function AllianceMember:GetCollectExpsByType(collectType)
    local exp = self.allianceExp[collect_type[collectType]]
    return exp,self:get_collect_config(collectType).expTo
end
function AllianceMember:GetCollectEffectByType(collectType)
    return self:get_collect_config(collectType).effect
end
function AllianceMember:GetWoodCollectLevelUpExp()
    return self:GetCollectLevelUpExpByType(AllianceMember.COLLECT_TYPE.WOOD)
end
function AllianceMember:GetStoneCollectLevelUpExp()
    return self:GetCollectLevelUpExpByType(AllianceMember.COLLECT_TYPE.STONE)
end
function AllianceMember:GetIronCollectLevelUpExp()
    return self:GetCollectLevelUpExpByType(AllianceMember.COLLECT_TYPE.IRON)
end
function AllianceMember:GetFoodCollectLevelUpExp()
    return self:GetCollectLevelUpExpByType(AllianceMember.COLLECT_TYPE.FOOD)
end
function AllianceMember:GetCoinCollectLevelUpExp()
    return self:GetCollectLevelUpExpByType(AllianceMember.COLLECT_TYPE.COIN)
end
function AllianceMember:GetCollectLevelUpExpByType(collectType)
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
function AllianceMember:IsTitleEqualOrGreaterThan(eq_title)
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
function AllianceMember:TitleDegrade()
    local cur = self:Title()
    return titles_enum[titles_enum[cur] - 1] or cur
end
function AllianceMember:DecodeFromJson(data)
    local member = AllianceMember.new(data.id)
    for k, v in pairs(data) do
        member[k] = v
        print("DecodeFromJson",k,v)
        if k == "lastThreeDaysKillData" then
            dump(v)
        end
    end
    return member
end
function AllianceMember:IsSameDataWith(member)
    return not self:IsDifferentWith(member)
end
function AllianceMember:IsDifferentWith(member)
    if not member then return false end
    for _, v in ipairs{
        "level",
        "kill",
        "power",
        "loyalty",
        "lastlogintime",
        "icon",
        "title",
        "name",
        "isProtected"
    } do
        if self[v] ~= member[v] then
            return true
        end
    end
    for _, key in ipairs{
        "location",
        "donateStatus",
        "allianceExp",
    } do
        local value = member[key]
        for k, v in pairs(self[key]) do
            if v ~= value[k] then
                return true
            end
        end
    end
    return false
end
function AllianceMember:IsTheSamePerson(member)
    return self:IsTheSameId(member:Id())
end
function AllianceMember:IsTheSameId(id)
    return self:Id() == id
end
function AllianceMember:GetTitleLevel()
    return titles_enum[self:Title()]
end
function AllianceMember.Title2Level(title)
    return titles_enum[title]
end
--权限判定函数
--------------------------------------------------------------------------
--名称 简称 旗帜 地形 语言
function AllianceMember:CanEditAlliance()
    -- return self:IsArchon()
    return allianceRight[self:Title()].CanEditAlliance
end
--移交盟主
function AllianceMember:CanGiveUpArchon()
    -- return self:IsArchon()
    return allianceRight[self:Title()].CanGiveUpArchon
end
--修改职位名称
function AllianceMember:CanEditAllianceMemeberTitle()
    -- return self:IsArchon()
    return allianceRight[self:Title()].CanEditAllianceMemeberTitle
end
--移动/拆除联盟地图上的东东
function AllianceMember:CanEditAllianceObject()
    -- return self:GetTitleLevel() >= self.Title2Level('general')
    return allianceRight[self:Title()].CanEditAllianceObject
end
--圣地事件
function AllianceMember:CanActivateShirneEvent()
    -- return self:GetTitleLevel() >= self.Title2Level('general')
    return allianceRight[self:Title()].CanActivateShirneEvent
end
--联盟GVG
function AllianceMember:CanActivateGVG()
    -- return self:GetTitleLevel() >= self.Title2Level('general')
    return allianceRight[self:Title()].CanActivateGVG
end
--在联盟商店的道具目录中补充高级道具
function AllianceMember:CanAddAdvancedItemsToAllianceShop()
    -- return self:GetTitleLevel() >= self.Title2Level('quartermaster')
    return allianceRight[self:Title()].CanAddAdvancedItemsToAllianceShop
end

function AllianceMember:CanEditAllianceNotice()
    -- return self:GetTitleLevel() >= self.Title2Level('quartermaster')
    return allianceRight[self:Title()].CanEditAllianceNotice
end

function AllianceMember:CanSendAllianceMail()
    -- return self:GetTitleLevel() >= self.Title2Level('quartermaster')
    return allianceRight[self:Title()].CanSendAllianceMail
end

function AllianceMember:CanUpgradeAllianceBuilding()
    -- return self:GetTitleLevel() >= self.Title2Level('quartermaster')
    return allianceRight[self:Title()].CanUpgradeAllianceBuilding
end

function AllianceMember:CanInvatePlayer()
    -- return self:GetTitleLevel() >= self.Title2Level('supervisor')
    return allianceRight[self:Title()].CanInvatePlayer
end

function AllianceMember:CanHandleAllianceApply()
    -- return self:GetTitleLevel() >= self.Title2Level('supervisor')
    return allianceRight[self:Title()].CanHandleAllianceApply
end
function AllianceMember:CanKickOutMember(target_current_title)
    -- return self:GetTitleLevel() >= self.Title2Level('supervisor'),self:GetTitleLevel() > self.Title2Level(target_current_title)
    return allianceRight[self:Title()].CanKickOutMember,self:GetTitleLevel() > self.Title2Level(target_current_title)
end
function AllianceMember:CanUpgradeMemberLevel(target_target_title)
    -- return self:GetTitleLevel() >= self.Title2Level('supervisor'),self:GetTitleLevel() > self.Title2Level(target_target_title)
    return allianceRight[self:Title()].CanUpgradeMemberLevel,self:GetTitleLevel() > self.Title2Level(target_target_title)
end
function AllianceMember:CanDemotionMemberLevel(target_current_title)
    -- return self:GetTitleLevel() >= self.Title2Level('supervisor'),self:GetTitleLevel() > self.Title2Level(target_current_title)
    return allianceRight[self:Title()].CanDemotionMemberLevel,self:GetTitleLevel() > self.Title2Level(target_current_title)
end
function AllianceMember:CanEditAllianceDesc()
    -- return self:GetTitleLevel() >= self.Title2Level('supervisor')
    return allianceRight[self:Title()].CanEditAllianceDesc
end
function AllianceMember:CanEditAllianceJoinType()
    -- return self:GetTitleLevel() >= self.Title2Level('supervisor')
    return allianceRight[self:Title()].CanEditAllianceJoinType
end
function AllianceMember:CanBuyAdvancedItemsFromAllianceShop()
    -- return self:GetTitleLevel() >= self.Title2Level('elite')
    return allianceRight[self:Title()].CanBuyAdvancedItemsFromAllianceShop
end
function AllianceMember:CanActivateAllianceRevenge()
    -- return self:GetTitleLevel() >= self.Title2Level('general')
    return allianceRight[self:Title()].CanActivateAllianceRevenge
end
return AllianceMember

