--
-- Author: Kenny Dai
-- Date: 2015-10-20 16:15:33
--

--查看来袭的部队信息和驻防到对方城市的部队信息
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameUIAllianceWatchTowerTroopDetail = class("GameUIAllianceWatchTowerTroopDetail", WidgetPopDialog)
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local UIListView = import(".UIListView")
local UIScrollView = import(".UIScrollView")
local Enum = import("..utils.Enum")
local Localize = import("..utils.Localize")
local StarBar = import(".StarBar")
local UILib = import(".UILib")
local Localize_item = import("..utils.Localize_item")

GameUIAllianceWatchTowerTroopDetail.ITEM_TYPE = Enum("DRAGON_INFO","DRAGON_EQUIPMENT","DRAGON_SKILL","SOLIDERS","TECHNOLOGY","BUFF_EFFECT")
GameUIAllianceWatchTowerTroopDetail.DATA_TYPE = Enum("MARCH","HELP_DEFENCE","STRIKE")
local titles = {
    DRAGON_EQUIPMENT = _("龙的装备"),
    DRAGON_SKILL = _("龙的技能"),
    SOLIDERS = _("军事单位"),
    TECHNOLOGY = _("军事科技水平"),
    BUFF_EFFECT = _("战争增益"),
}

function GameUIAllianceWatchTowerTroopDetail:ctor(event_data,watchTowerLevel,isFromEnemy,data_type,isCheckOtherHelpTroop)
    GameUIAllianceWatchTowerTroopDetail.super.ctor(self,824,_("部队详情"))
    self.event_data = event_data
    self.watchTowerLevel = watchTowerLevel
    self.isFromEnemy = isFromEnemy
    self.isCheckOtherHelpTroop = isCheckOtherHelpTroop
    self.data_type = data_type
end

function GameUIAllianceWatchTowerTroopDetail:GetWatchTowerLevel()
    return self.watchTowerLevel
end


function GameUIAllianceWatchTowerTroopDetail:GetDataType()
    return self.data_type
end

function GameUIAllianceWatchTowerTroopDetail:IsFromEnemy()
    return self.isFromEnemy
end

function GameUIAllianceWatchTowerTroopDetail:IsCheckOtherHelpTroop()
    return self.isCheckOtherHelpTroop
end

function GameUIAllianceWatchTowerTroopDetail:GetEventData()
    return self.event_data
end


function GameUIAllianceWatchTowerTroopDetail:onEnter()
    GameUIAllianceWatchTowerTroopDetail.super.onEnter(self)
    local listBg = display.newScale9Sprite("background_568x120.png", 0,0,cc.size(568,754),cc.rect(15,10,538,100))
        :align(display.CENTER_BOTTOM, self.body:getContentSize().width/2, 30)
        :addTo(self.body)

    self.listView = UIListView.new {
        viewRect = cc.rect(10, 12, 548,730),
        direction = UIScrollView.DIRECTION_VERTICAL,
    }:addTo(listBg)
    self:RefreshListView()
end

function GameUIAllianceWatchTowerTroopDetail:RequestPlayerHelpedByTroops()
    NetManager:getHelpDefenceTroopDetailPromise(self:GetUserId(),self:GetEventData().id):done(function(msg)
        self.event_data = msg
        self:RefreshListView()
    end)
end


function GameUIAllianceWatchTowerTroopDetail:RefreshListView()
    self.listView:removeAllItems()
    local item = self:GetItem(self.ITEM_TYPE.DRAGON_INFO,self:GetEventData())
    self.listView:addItem(item)
    item = self:GetItem(self.ITEM_TYPE.DRAGON_EQUIPMENT,self:GetEventData())
    self.listView:addItem(item)
    if  self:GetDataType() ~= self.DATA_TYPE.STRIKE then
        item = self:GetItem(self.ITEM_TYPE.SOLIDERS,self:GetEventData())
        self.listView:addItem(item)
    end
    item = self:GetItem(self.ITEM_TYPE.DRAGON_SKILL,self:GetEventData())
    self.listView:addItem(item)
    if self:GetEventData().militaryTechs then
        item = self:GetItem(self.ITEM_TYPE.TECHNOLOGY,self:GetEventData())
        self.listView:addItem(item)
    end
    if self:GetEventData().militaryBuffs then
        item = self:GetItem(self.ITEM_TYPE.BUFF_EFFECT,self:GetEventData())
        self.listView:addItem(item)
    end
    self.listView:reload()
end

function GameUIAllianceWatchTowerTroopDetail:GetItem(ITEM_TYPE,item_data)
    local item = self.listView:newItem()
    local height,sub_line = 0,0
    if ITEM_TYPE == self.ITEM_TYPE.DRAGON_INFO then
        sub_line = 3
        height   = sub_line * 38
    elseif ITEM_TYPE == self.ITEM_TYPE.DRAGON_EQUIPMENT then
        if self:CanShowDragonEquipment() then
            sub_line = #item_data.dragon.equipments
            height = sub_line * 36
            height = height == 0 and 36 or height
        else
            height = 36
        end
    elseif ITEM_TYPE == self.ITEM_TYPE.SOLIDERS then
        if self:CanShowSoliderName() then
            sub_line = #item_data.soldiers
            height   = sub_line * 36
        else
            height = 36
        end
    elseif ITEM_TYPE == self.ITEM_TYPE.BUFF_EFFECT then
        if self:CanShowTechnologyAndBuffEffect() then
            sub_line = #item_data.militaryBuffs
            height   = sub_line * 36
        else
            height = 36
        end
    elseif ITEM_TYPE == self.ITEM_TYPE.TECHNOLOGY then
        if self:CanShowTechnologyAndBuffEffect() then
            sub_line = #item_data.militaryTechs
            height   = sub_line * 36
        else
            height = 36
        end
    elseif ITEM_TYPE == self.ITEM_TYPE.DRAGON_SKILL then
        sub_line = #item_data.dragon.skills
        height = sub_line * 36
        height = height == 0 and 36 or height
    end
    local bg = display.newScale9Sprite("transparent_1x1.png"):size(548,height + 38)
    local title_bar = display.newSprite("alliance_member_title_548x38.png"):addTo(bg):align(display.LEFT_TOP, 0, height + 38)
    if ITEM_TYPE == self.ITEM_TYPE.DRAGON_INFO then
        local dragon_name = self:CanShowDragonType() and Localize.dragon[item_data.dragon.type] or '?'
        UIKit:ttfLabel({
            text = dragon_name,
            size = 20,
            color= 0xffedae
        }):align(display.LEFT_CENTER, 20, 19):addTo(title_bar)
        if self:CanShowDragonLevelAndStar() then
            local star_bar = StarBar.new({
                max = 4,
                bg = "Stars_bar_bg.png",
                fill = "Stars_bar_highlight.png",
                num = item_data.dragon.star,
            }):addTo(title_bar):align(display.RIGHT_CENTER,538,19)
        end
        local y = 0
        local dragon_hp = self:CanShowDragonHP() and item_data.dragon.hp .. "/" .. self:GetDragonMaxHP() or "?"
        self:GetSubItem(ITEM_TYPE,1,{_("生命值"),dragon_hp}):addTo(bg):align(display.RIGHT_BOTTOM, 547, y)
        y = y + 38
        local dragon_strength = self:CanShowDragonStrength() and (self:GetDragonStrength() or 0) or "?"
        self:GetSubItem(ITEM_TYPE,2,{_("力量"),dragon_strength}):addTo(bg):align(display.RIGHT_BOTTOM, 547, y)
        y = y + 38
        local dragon_level = self:CanShowDragonLevelAndStar() and item_data.dragon.level or "?"
        self:GetSubItem(ITEM_TYPE,3,{_("等级"),dragon_level}):addTo(bg):align(display.RIGHT_BOTTOM, 547, y)
        local dragon_png = UILib.dragon_head[item_data.dragon.type]
        if self:CanShowDragonType() and dragon_png then
            local icon_bg = display.newSprite("dragon_bg_114x114.png", 65, 60):addTo(bg):scale(98/114)
            display.newSprite(dragon_png, 57, 60):addTo(icon_bg)
        else
            display.newSprite("unknown_dragon_icon_112x112.png", 65, 60):addTo(bg):scale(98/112)
        end
    else
        UIKit:ttfLabel({
            text = titles[self.ITEM_TYPE[ITEM_TYPE]],
            size = 20,
            color= 0xffedae,
        }):addTo(title_bar):align(display.CENTER, 274, 19)
        if ITEM_TYPE == self.ITEM_TYPE.DRAGON_EQUIPMENT then
            if self:CanShowDragonEquipment() then
                if #item_data.dragon.equipments > 0 then
                    local y = 0
                    for i,v in ipairs(item_data.dragon.equipments) do
                        self:GetSubItem(ITEM_TYPE,i,{Localize.equip[v.name],v.star}):addTo(bg):align(display.LEFT_BOTTOM,0, y)
                        y = y + 36
                    end
                else
                    self:GetTipsItem(_("无")):addTo(bg):align(display.LEFT_BOTTOM, 0, 0)
                end
            else
                self:GetTipsItem():addTo(bg):align(display.LEFT_BOTTOM, 0, 0)
            end
        elseif ITEM_TYPE == self.ITEM_TYPE.SOLIDERS then
            if self:CanShowSoliderName() then
                local y = 0
                for i,v in ipairs(item_data.soldiers) do
                    local name = string.format(_("[%d星]%s"),v.star,Localize.soldier_name[v.name])
                    if not self:CanShowSoliderStar() then
                        name = Localize.soldier_name[v.name]
                    end
                    self:GetSubItem(ITEM_TYPE,i,{name,v.count}):addTo(bg):align(display.LEFT_BOTTOM,0, y)
                    y = y + 36
                end
            else
                self:GetTipsItem():addTo(bg):align(display.LEFT_BOTTOM, 0, 0)
            end
        elseif ITEM_TYPE == self.ITEM_TYPE.BUFF_EFFECT then
            if self:CanShowTechnologyAndBuffEffect() then
                local y = 0
                for i,v in ipairs(item_data.militaryBuffs) do
                    local name = Localize_item.item_category_name[v.type]
                    self:GetSubItem(ITEM_TYPE,i,{name,_("已激活")}):addTo(bg):align(display.LEFT_BOTTOM,0, y)
                    y = y + 36
                end
            else
                self:GetTipsItem():addTo(bg):align(display.LEFT_BOTTOM, 0, 0)
            end
        elseif ITEM_TYPE == self.ITEM_TYPE.TECHNOLOGY then
            if self:CanShowTechnologyAndBuffEffect() then
                local y = 0
                for i,v in ipairs(item_data.militaryTechs) do
                    local name = Localize.getMilitaryTechnologyName(v.name)
                    self:GetSubItem(ITEM_TYPE,i,{name,"Lv"..v.level}):addTo(bg):align(display.LEFT_BOTTOM,0, y)
                    y = y + 36
                end
            else
                self:GetTipsItem():addTo(bg):align(display.LEFT_BOTTOM, 0, 0)
            end
        elseif ITEM_TYPE == self.ITEM_TYPE.DRAGON_SKILL then
            if #item_data.dragon.skills >0 then
                local y = 0
                for i,v in ipairs(item_data.dragon.skills) do
                    local val_str = '?'
                    if self:CanShowDragonSkill() then
                        val_str = _("等级") .. ":" .. v.level
                    end
                    self:GetSubItem(ITEM_TYPE,i,{Localize.dragon_skill[v.name],val_str}):addTo(bg):align(display.LEFT_BOTTOM,0, y)
                    y = y + 36
                end
            else
                self:GetTipsItem(_("无")):addTo(bg):align(display.LEFT_BOTTOM, 0, 0)
            end
        end
    end
    item:addContent(bg)
    item:setItemSize(548,height + 38)
    return item
end
function GameUIAllianceWatchTowerTroopDetail:GetTipsItem(tips)
    local item = display.newScale9Sprite(string.format("back_ground_548x40_%d.png",1)):size(547,36)
    UIKit:ttfLabel({
        text = tips or _("巨石阵等级不足,暂时不能查看"),
        size = 20,
        color= 0x615b44
    }):align(display.CENTER, 273, 19):addTo(item)
    return item
end

function GameUIAllianceWatchTowerTroopDetail:GetDragonStrength()
    local dragon = self:GetEventData().dragon
    return DataUtils:getDragonTotalStrengthFromJson(dragon.star,dragon.level,dragon.skills,dragon.equipments)
end

function GameUIAllianceWatchTowerTroopDetail:GetDragonMaxHP()
    local dragon = self:GetEventData().dragon
    return DataUtils:getDragonMaxHp(dragon.star,dragon.level,dragon.skills,dragon.equipments)
end

function GameUIAllianceWatchTowerTroopDetail:GetSubItem(ITEM_TYPE,index,item_data)
    local height = ITEM_TYPE == self.ITEM_TYPE.DRAGON_INFO and 38 or 36
    local width  = ITEM_TYPE == self.ITEM_TYPE.DRAGON_INFO and 420 or 546
    local item = display.newScale9Sprite(string.format("back_ground_548x40_%d.png", (index - 1) % 2 == 0 and 1 or 2)):size(width,height)
    local title_label = UIKit:ttfLabel({
        text = item_data[1],
        size = 20,
        color= 0x615b44
    }):align(display.LEFT_CENTER, 12, 19):addTo(item)
    if ITEM_TYPE == self.ITEM_TYPE.DRAGON_INFO then
        local val_label = UIKit:ttfLabel({
            text = item_data[2],
            size = 20,
            color= 0x403c2f
        }):align(display.LEFT_CENTER, title_label:getPositionX()+title_label:getContentSize().width + 20, 19):addTo(item)
    elseif ITEM_TYPE == self.ITEM_TYPE.DRAGON_EQUIPMENT then
        local star_bar = StarBar.new({
            max = 4,
            bg = "Stars_bar_bg.png",
            fill = "Stars_bar_highlight.png",
            num = item_data[2],
            scale = 0.8
        }):addTo(item):align(display.RIGHT_CENTER,526,19)
    elseif ITEM_TYPE == self.ITEM_TYPE.TECHNOLOGY or ITEM_TYPE == self.ITEM_TYPE.BUFF_EFFECT then
        local val_label = UIKit:ttfLabel({
            text = item_data[2],
            size = 20,
            color= 0x403c2f
        }):align(display.RIGHT_CENTER,526, 19):addTo(item)
    elseif ITEM_TYPE == self.ITEM_TYPE.SOLIDERS then
        local val_label = UIKit:ttfLabel({
            text = self:FileterSoliderCount(item_data[2]),
            size = 20,
            color= 0x403c2f
        }):align(display.RIGHT_CENTER,526, 19):addTo(item)
    elseif ITEM_TYPE == self.ITEM_TYPE.DRAGON_SKILL then
        local val_label = UIKit:ttfLabel({
            text = item_data[2],
            size = 20,
            color= 0x403c2f
        }):align(display.RIGHT_CENTER,526, 19):addTo(item)
    end
    return item
end

--数据过滤
function GameUIAllianceWatchTowerTroopDetail:CanShowDragonType()
    if self:IsCheckOtherHelpTroop() then
        return self:GetWatchTowerLevel() >= 13
    elseif self:IsFromEnemy() then
        return self:GetWatchTowerLevel() >=2
    else
        return true
    end
end

function GameUIAllianceWatchTowerTroopDetail:CanShowDragonLevelAndStar()
    if self:IsCheckOtherHelpTroop() then
        return self:GetWatchTowerLevel() >= 13
    elseif self:IsFromEnemy() then
        return self:GetWatchTowerLevel() >= 2
    else
        return true
    end
end


function GameUIAllianceWatchTowerTroopDetail:CanShowDragonHP()
    if self:IsCheckOtherHelpTroop() then
        return self:GetWatchTowerLevel() >= 14
    elseif self:IsFromEnemy() then
        return self:GetWatchTowerLevel() >= 4
    else
        return true
    end
end

function GameUIAllianceWatchTowerTroopDetail:CanShowDragonStrength()
    if self:IsCheckOtherHelpTroop() then
        return self:GetWatchTowerLevel() >= 14
    elseif self:IsFromEnemy() then
        return self:GetWatchTowerLevel() >= 4
    else
        return true
    end
end

function GameUIAllianceWatchTowerTroopDetail:CanShowDragonSkill()
    if self:IsCheckOtherHelpTroop() then
        return self:GetWatchTowerLevel() >= 19
    elseif self:IsFromEnemy() then
        return self:GetWatchTowerLevel() >= 9
    else
        return true
    end

end

function GameUIAllianceWatchTowerTroopDetail:CanShowSoliderName()
    if self:IsCheckOtherHelpTroop() then
        return self:GetWatchTowerLevel() >= 15
    elseif self:IsFromEnemy() then
        return self:GetWatchTowerLevel() >= 5
    else
        return true
    end

end

function GameUIAllianceWatchTowerTroopDetail:CanShowSoliderStar()
    if self:IsCheckOtherHelpTroop() then
        return self:GetWatchTowerLevel() >= 16
    elseif self:IsFromEnemy() then
        return self:GetWatchTowerLevel() >= 6
    else
        return true
    end

end


function GameUIAllianceWatchTowerTroopDetail:CanShowDragonEquipment()
    if self:IsCheckOtherHelpTroop() then
        return self:GetWatchTowerLevel() >= 18
    elseif self:IsFromEnemy() then
        return self:GetWatchTowerLevel() >= 8
    else
        return true
    end
end

function GameUIAllianceWatchTowerTroopDetail:CanShowTechnologyAndBuffEffect()
    if self:IsFromEnemy() then
        return self:GetWatchTowerLevel() >= 10
    end
end

function GameUIAllianceWatchTowerTroopDetail:FileterSoliderCount(count)
    if self:IsCheckOtherHelpTroop() then
        if  self:GetWatchTowerLevel() >= 20 then
            return GameUtils:formatNumber(count)
        elseif self:GetWatchTowerLevel() >= 17 then
            return self:FuzzyCount(count)
        else
            return "?"
        end
    elseif self:IsFromEnemy() then
        if  self:GetWatchTowerLevel() >= 11 then
            return GameUtils:formatNumber(count)
        elseif self:GetWatchTowerLevel() >= 8 then
            return self:FuzzyCount(count)
        else
            return "?"
        end
    else
        return GameUtils:formatNumber(count)
    end
end
--模糊数据
function GameUIAllianceWatchTowerTroopDetail:FuzzyCount(count)
    count = checkint(count)
    if count >= math.pow(10,6) then
        return "> 1M"
    elseif count >= 500 * math.pow(10,3) then
        return "500K ~ 1M"
    elseif count >= 200 * math.pow(10,3) then
        return "200K ~ 500K"
    elseif count >= 100 * math.pow(10,3) then
        return "100K ~ 200K"
    elseif count >= 50 * math.pow(10,3) then
        return "50K ~ 100K"
    elseif count >= 20 * math.pow(10,3) then
        return "20K ~ 50K"
    elseif count >= 10 * math.pow(10,3) then
        return "10K ~ 20K"
    elseif count >= 5 * math.pow(10,3) then
        return "5K ~ 10K"
    elseif count >= 2 * math.pow(10,3) then
        return "2K ~ 5K"
    elseif count >= math.pow(10,3) then
        return "1K ~ 2K"
    elseif count >= 501 then
        return "501 ~ 1K"
    elseif count >= 201 then
        return "201 ~ 500"
    elseif count >= 101 then
        return "101 ~ 200"
    elseif count >= 0 then
        return "0 ~ 100"
    end
end

return GameUIAllianceWatchTowerTroopDetail








