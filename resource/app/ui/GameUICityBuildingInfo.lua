--
-- Author: Kenny Dai
-- Date: 2015-05-14 17:47:43
--
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local Localize = import("..utils.Localize")
local Localize_item = import("..utils.Localize_item")
local UIListView = import(".UIListView")
local GameUICityBuildingInfo = class("GameUICityBuildingInfo", WidgetPopDialog)

local AllianceBuilding = GameDatas.AllianceBuilding

-- 每个建筑详情列数和宽度
local building_details_map = {
    ["keep"] = {
        {130,  		130, 		130, 		130			   },
        {_("等级"), _("战斗力"),_("可解锁地块"),_("可协助加速") },
        {"level",  	"power", 	"unlock", "beHelpedCount"},
    },
    ["watchTower"] = {
        {90,			130,		300},
        {_("等级"), _("战斗力"),_("瞭望塔效果")},
        {"level",  	"power"},
    },
    ["warehouse"] = {
        {90,		100,		200,			130		  },
        {_("等级"), _("战斗力"),_("资源存储上限"),_("暗仓保护") },
        {"level",  	"power", 	"maxWood"},
    },
    ["dragonEyrie"] = {
        {90,		130,			300				},
        {_("等级"), _("战斗力"),_("巨龙生命值恢复每小时")},
        {"level",  	"power", 	"hpRecoveryPerHour"},
    },
    ["toolShop"] = {
        {90,			130,			300},
        {_("等级"), _("战斗力"),_("制造工具数量")},
        {"level",  	"power", 	"production"},
    },
    ["materialDepot"] = {
        {90,			130,			300},
        {_("等级"), _("战斗力"),_("材料存储上限")},
        {"level",  	"power", 	"maxMaterial"},
    },
    ["barracks"] = {
        {90,			100,		200,			130},
        {_("等级"), _("战斗力"),_("最大招募"),_("新解锁士兵") },
        {"level",  	"power", 	"maxRecruit"},
    },
    ["blackSmith"] = {
        {90,130,300},
        {_("等级"), _("战斗力"),_("提升炼制速度")},
        {"level",  	"power"},
    },
    ["foundry"] = {
        {90,			100,		200,			130},
        {_("等级"), _("战斗力"),_("增加矿工小屋"),_("增加铁矿保护") },
        {"level",  	"power", 	"houseAdd"},
    },
    ["stoneMason"] = {
        {90,			100,		200,			130},
        {_("等级"), _("战斗力"),_("增加石匠小屋"),_("增加石料保护") },
        {"level",  	"power", 	"houseAdd"},
    },
    ["lumbermill"] = {
        {90,			100,		200,			130},
        {_("等级"), _("战斗力"),_("增加木工小屋"),_("增加木材保护") },
        {"level",  	"power", 	"houseAdd"},
    },
    ["mill"] = {
        {90,			100,		200,			130},
        {_("等级"), _("战斗力"),_("增加农夫小屋"),_("增加粮食保护") },
        {"level",  	"power", 	"houseAdd"},
    },
    ["hospital"] = {
        {90,			130,		300},
        {_("等级"), _("战斗力"),_("容纳伤兵上限")},
        {"level",  	"power", 	"maxCitizen"},
    },
    ["townHall"] = {
        {90,			100,		200,		130},
        {_("等级"), _("战斗力"),_("增加住宅"),_("提升任务奖励") },
        {"level",  	"power", 	"houseAdd"},
    },
    ["tradeGuild"] = {
        {90,			100,		200,			130},
        {_("等级"), _("战斗力"),_("运输车总量"),_("运输车生产") },
        {"level",  	"power", 	"maxCart", 	"cartRecovery"},
    },
    ["academy"] = {
        {90,			130,		300},
        {_("等级"), _("战斗力"),_("提升科技研发速度")},
        {"level",  	"power"},
    },
    ["hunterHall"] = {
        {90,			130,		300},
        {_("等级"), _("战斗力"),_("提升弓手招募速度")},
        {"level",  	"power"},
    },
    ["trainingGround"] = {
        {90,			130,		300},
        {_("等级"), _("战斗力"),_("提升步兵招募速度")},
        {"level",  	"power"},
    },
    ["stable"] = {
        {90,			130,		300},
        {_("等级"), _("战斗力"),_("提升骑兵招募速度")},
        {"level",  	"power"},
    },
    ["workshop"] = {
        {90,			130,		300},
        {_("等级"), _("战斗力"),_("提升攻城机械招募速度")},
        {"level",  	"power"},
    },
    ["tower"] = {
        {90,			100,		200,			130},
        {_("等级"), _("战斗力"),_("城墙攻击"),_("城墙防御") },
        {"level",  	"power"    ,"infantry" ,"defencePower"},
    },
    ["wall"] = {
        {90,			100,		200,			130},
        {_("等级"), _("战斗力"),_("耐久度"),_("耐久度恢复每小时") },
        {"level",  	"power"    ,"wallHp" ,"wallRecovery"},
    },
    ["dwelling"] = {
        {90,			100,		200,			130},
        {_("等级"), _("战斗力"),_("城民上限"),_("银币产出每小时") },
        {"level",  	"power"    ,"citizen" ,"production"},
    },
    ["woodcutter"] = {
        {90,			130,		300},
        {_("等级"), _("战斗力"),_("木材产出每小时")},
        {"level",  	"power"    ,"production" },
    },
    ["quarrier"] = {
        {90,			130,		300},
        {_("等级"), _("战斗力"),_("石料产出每小时")},
        {"level",  	"power"    ,"production" },
    },
    ["miner"] = {
        {90,			130,		300},
        {_("等级"), _("战斗力"),_("铁矿产出每小时")},
        {"level",  	"power"    ,"production" },
    },
    ["farmer"] = {
        {90,			130,		300},
        {_("等级"), _("战斗力"),_("粮食产出每小时")},
        {"level",  	"power"    ,"production" },
    },

    ["orderHall"] = {
        {90,			130,		300},
        {_("等级"), _("战斗力"),_("村落定期生成数量")},
        {"level",  	"power"    ,"woodVillageCount" },
    },
    ["palace"] = {
        {90,			130,		300},
        {_("等级"), _("战斗力"),_("联盟成员")},
        {"level",  	"power"    ,"memberCount" },
    },
    ["shop"] = {
        {90,		130,			300},
        {_("等级"), _("战斗力"),_("可进货道具")},
        {"level",  	"power"},
    },
    ["shrine"] = {
        {90,		100,		200,			130},
        {_("等级"), _("战斗力"),_("感知力上限"),_("感知力恢复每小时")},
        {_("level"), _("power"),_("perception"),_("pRecoveryPerHour")},
    },
}

function GameUICityBuildingInfo:ctor(building)
    -- 建筑配置文件
    local config , building_name,building_level
    if building.__cname and string.find(building.__cname,"UpgradeBuilding") then
        building_name = building:GetType()
        config = building:GetFunctionConfig()[building_name]
        building_level = building:GetLevel()
    else
        building_name = building.name
        config = AllianceBuilding[building_name]
        building_level = building.level
    end
    self.config = config
    self.building_name = building_name
    self.building_level = building_level
    GameUICityBuildingInfo.super.ctor(self,674,Localize.building_name[building_name])
    self.building = building
end

function GameUICityBuildingInfo:onEnter()
    GameUICityBuildingInfo.super.onEnter(self)
    local building = self.building
    local body = self:GetBody()
    local b_size = body:getContentSize()
    -- 总览介绍
    local total_title_bg = WidgetUIBackGround.new({width = 556 , height = 106},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :align(display.TOP_CENTER, b_size.width/2, b_size.height - 30)
        :addTo(body)
    UIKit:ttfLabel({
        text = Localize.building_description[self.building_name],
        size = 20,
        color = 0x615b44,
        dimensions = cc.size(520,0)
    }):align(display.CENTER, total_title_bg:getContentSize().width/2, total_title_bg:getContentSize().height/2)
        :addTo(total_title_bg)

    -- 详细信息

    local list_node = WidgetUIBackGround.new({width = 540,height = 490},WidgetUIBackGround.STYLE_TYPE.STYLE_6)

    list_node:addTo(body):align(display.TOP_CENTER, b_size.width/2, total_title_bg:getPositionY() - total_title_bg:getContentSize().height - 20)

    local building_name = self.building_name
    local building_level = self.building_level
    local config = self.config


    if building_name then
        local item_width = 520
        local list_info = building_details_map[building_name]
        local gap = list_info[1]
        local titles = list_info[2]
        local attrs = list_info[3]
        local line_x = 0
        self.gap = gap
        self.attrs = attrs
        -- 标题
        local content, max_height = self:CreateContent(titles,nil,0x615b44,"upgrade_resources_background_3.png")
        content:align(display.TOP_CENTER, list_node:getContentSize().width/2, list_node:getContentSize().height-10)
            :addTo(list_node)

        local list = UIListView.new({
            async = true, --异步加载
            direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
            viewRect = cc.rect(0, 0,item_width,468 - max_height),
        -- bgColor = UIKit:hex2c4b(0x7a002200),
        }):addTo(list_node):pos(10,12)
        list:setRedundancyViewVal(list:getViewRect().height)
        list:setDelegate(handler(self, self.sourceDelegate))
        list:reload()
        for i=1,#gap do
            -- 分割线
            if i < #gap then
                line_x = line_x + gap[i]
                display.newSprite("line_1x473.png",10+line_x,list_node:getContentSize().height/2)
                    :addTo(list_node)
            end
        end
    end
end

function GameUICityBuildingInfo:onExit()
    GameUICityBuildingInfo.super.onExit(self)
end
function GameUICityBuildingInfo:sourceDelegate(listView, tag, idx)
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #self.config
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:CreateDetails()
            item:addContent(content)
        else
            content = item:getContent()
        end
        content:SetData(idx)

        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        return item
    else
    end
end
function GameUICityBuildingInfo:CreateDetails()
    local content = display.newNode()
    local parent = self
    function content:SetData(idx)
        self:removeAllChildren()
        local details = {}
        for i,v in ipairs(parent.attrs) do
            local value = parent.config[idx][v]
            if tolua.type(value) == "number" then
                value = string.formatnumberthousands(value)
            end
            table.insert(details, value)
        end
        if parent.building_name == "watchTower" then
            local watchTower = GameDatas.ClientInitGame.watchTower
            table.insert(details, string.format(Localize.building_description["watchTower_"..idx],watchTower[idx].waringMinute))
        elseif parent.building_name == "warehouse" then
            local value = parent.config[idx][parent.attrs[3]]/10
            if tolua.type(value) == "number" then
                value = string.formatnumberthousands(value)
            end
            table.insert(details, value)
        elseif parent.building_name == "barracks" then
            local unlockedSoldiers_current = string.split(parent.config[idx].unlockedSoldiers, ",")
            if idx > 1 then
                local unlockedSoldiers_perious = parent.config[idx-1].unlockedSoldiers
                for i,v in ipairs(unlockedSoldiers_current) do
                    if not string.find(unlockedSoldiers_perious,v) then
                        table.insert(details, Localize.soldier_name[v])
                    end
                end
            else
                for i,v in ipairs(unlockedSoldiers_current) do
                    table.insert(details, Localize.soldier_name[v])
                end
            end
        elseif parent.building_name == "blackSmith" or parent.building_name == "townHall"
            or parent.building_name == "academy"
            or parent.building_name == "hunterHall"
            or parent.building_name == "trainingGround"
            or parent.building_name == "stable"
            or parent.building_name == "workshop"
        then
            local value = (parent.config[idx].efficiency * 100) .. "%"
            table.insert(details, value)
        elseif parent.building_name == "foundry" or
            parent.building_name == "stoneMason" or
            parent.building_name == "lumbermill" or
            parent.building_name == "mill"
        then
            local value = (parent.config[idx].protection * 100) .. "%"
            table.insert(details, value)
        elseif parent.building_name == "shop" then
            local itemsUnlock = string.split(parent.config[idx].itemsUnlock,",")
            local items = ""
            for i,v in ipairs(itemsUnlock) do
                items = items .. Localize_item.item_name[v] .. (i < #itemsUnlock and "\n" or "")
            end
            table.insert(details, items)
        end

        local temp = parent:CreateContent(details,idx)
        self:setContentSize(temp:getContentSize())
        temp:addTo(self):align(display.CENTER, temp:getContentSize().width/2, temp:getContentSize().height/2)
    end

    return content
end
function GameUICityBuildingInfo:CreateContent(content,index,color,image)
    local temp_labels = {} -- 创建出所有label，找出高度最高的
    local max_height = 0
    local list_width = 0
    local gap = self.gap
    for i = 1,#gap do
        list_width = list_width + gap[i]
        local x = list_width - gap[i]/2
        -- 每个label居中，宽度小于设定列宽 10
        local label = UIKit:ttfLabel({
            text = content[i] or "",
            size = 20,
            color = (index and index == self.building_level and 0xffedae) or (color or 0x403c3f),
            dimensions = cc.size(gap[i]-10,0),
            align = cc.TEXT_ALIGNMENT_CENTER,
        }):align(display.CENTER)
        label:setPositionX(x)
        max_height = math.max(label:getContentSize().height,max_height)
        table.insert(temp_labels, label)
    end
    max_height = max_height + 20
    local bg_image = image or (index and index == self.building_level and "back_ground_520x48.png") or (index%2 == 1 and "back_ground_548x40_1.png" or "back_ground_548x40_2.png")

    local content = display.newScale9Sprite(bg_image):size(520,max_height)
    for i,v in ipairs(temp_labels) do
        v:addTo(content)
        v:setPositionY(max_height/2)
    end
    return content , max_height
end

return GameUICityBuildingInfo























